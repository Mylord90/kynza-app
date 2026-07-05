// supabase/functions/create-platform-backup/index.ts
// Master Plan Execution CP3 — the recurring, whole-database counterpart to
// the one-time manual export in docs/remediation/PHASE_0_BACKUP_CONFIRMED.md
// (which used an ad hoc Node script + ephemeral CLI-provisioned Postgres
// credentials, since this environment has no Docker/pg_dump). This function
// runs the same underlying idea — export every row of every public table —
// as a real, repeatable, cron-driven job instead of a one-time manual
// session, using only the service-role PostgREST client (no direct
// Postgres connection needed).
//
// Cron-only, same X-Cron-Secret gate as run-scheduled-actions/
// schedule-reminders (docs/certification-v2/CP4_EDGE_FUNCTION_REVERIFY.md) —
// this function reads and stores full customer PII, so it must never be
// callable with just the public anon key.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { logError, logInfo, newRequestId } from "../_shared/log.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";

const FN = "create-platform-backup";
const PAGE_SIZE = 1000;
const STORAGE_BUCKET = "kynza-backups";
// A single Edge Function invocation has a bounded compute budget — paging
// through an arbitrarily large table here would blow it (found live this
// pass: kynza-dr-scratch's `bookings` table still holds the 400,001 rows
// from the Final Enterprise Validation scale test, and the function was
// killed with WORKER_RESOURCE_LIMIT trying to page through all of it in
// one call). A table over this cap gets its first N rows backed up plus an
// honest `truncated: true` + real total count in the manifest, rather than
// either hanging the whole job or silently dropping the overflow. Today's
// real production volume (2 salons, 7 users, 5 bookings) is nowhere near
// this cap — this only bites a table that has genuinely grown, the same
// "not urgent, but a real number, not smoothed over" caveat CP4's own DR
// report already applies to restore RTO at scale.
const MAX_ROWS_PER_TABLE = 20000;

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  const cronSecret = Deno.env.get("CRON_SECRET");
  if (!cronSecret || req.headers.get("X-Cron-Secret") !== cronSecret) {
    return jsonResponse({ error: "forbidden" }, 403);
  }

  const requestId = newRequestId();
  logInfo(requestId, FN, "invoked");

  const admin = createServiceRoleClient();
  const startedAt = new Date();

  const { data: job, error: jobError } = await admin
    .from("platform_backup_jobs")
    .insert({ status: "running", started_at: startedAt.toISOString() })
    .select("id")
    .single();
  if (jobError || !job) {
    return jsonResponse({ error: "job_create_failed" }, 500);
  }
  const jobId = job.id as string;

  try {
    const { data: tables, error: tablesError } = await admin.rpc(
      "get_all_public_tables",
    );
    if (tablesError) throw tablesError;

    const timestamp = startedAt.toISOString().replace(/[:.]/g, "-");
    const storagePrefix = `platform/${timestamp}`;
    const manifest: Record<
      string,
      { rowCount: number; byteSize: number; truncated?: boolean; realRowCount?: number }
    > = {};
    let totalRows = 0;
    let totalBytes = 0;

    for (const row of tables as { table_name: string }[]) {
      const tableName = row.table_name;
      // platform_backup_jobs itself is deliberately excluded — backing up
      // the backup-job log is circular and adds no recovery value.
      if (tableName === "platform_backup_jobs") continue;

      const allRows: Record<string, unknown>[] = [];
      let from = 0;
      let truncated = false;
      // Paginate explicitly rather than trusting a single `.select("*")` —
      // PostgREST's default response cap (1000 rows) would otherwise
      // silently truncate any table that grows past it, which is exactly
      // the kind of quiet correctness bug a backup mechanism must not have.
      // Bounded by MAX_ROWS_PER_TABLE (see its own comment) so one
      // unexpectedly huge table can't exhaust this invocation's compute
      // budget and take the whole job down with it.
      while (true) {
        const { data: page, error: pageError } = await admin
          .from(tableName)
          .select("*")
          .range(from, from + PAGE_SIZE - 1);
        if (pageError) throw new Error(`${tableName}: ${pageError.message}`);
        if (!page || page.length === 0) break;
        allRows.push(...page);
        if (page.length < PAGE_SIZE) break;
        from += PAGE_SIZE;
        if (allRows.length >= MAX_ROWS_PER_TABLE) {
          truncated = true;
          break;
        }
      }

      let realRowCount: number | undefined;
      if (truncated) {
        const { count } = await admin
          .from(tableName)
          .select("*", { count: "exact", head: true });
        realRowCount = count ?? undefined;
      }

      const jsonBytes = new TextEncoder().encode(JSON.stringify(allRows));
      const { error: uploadError } = await admin.storage
        .from(STORAGE_BUCKET)
        .upload(`${storagePrefix}/${tableName}.json`, jsonBytes, {
          contentType: "application/json",
          upsert: false,
        });
      if (uploadError) {
        throw new Error(`${tableName} upload: ${uploadError.message}`);
      }

      manifest[tableName] = {
        rowCount: allRows.length,
        byteSize: jsonBytes.byteLength,
        ...(truncated
            ? { truncated: true, realRowCount: realRowCount }
            : {}),
      };
      totalRows += allRows.length;
      totalBytes += jsonBytes.byteLength;
    }

    const manifestBytes = new TextEncoder().encode(
      JSON.stringify({
        exportedAt: startedAt.toISOString(),
        tables: manifest,
        totalTables: Object.keys(manifest).length,
        totalRows,
      }),
    );
    const { error: manifestError } = await admin.storage
      .from(STORAGE_BUCKET)
      .upload(`${storagePrefix}/_manifest.json`, manifestBytes, {
        contentType: "application/json",
        upsert: false,
      });
    if (manifestError) {
      throw new Error(`manifest upload: ${manifestError.message}`);
    }

    await admin
      .from("platform_backup_jobs")
      .update({
        status: "completed",
        completed_at: new Date().toISOString(),
        storage_prefix: storagePrefix,
        tables_exported: Object.keys(manifest).length,
        rows_exported: totalRows,
        total_bytes: totalBytes,
      })
      .eq("id", jobId);

    logInfo(requestId, FN, "completed", {
      jobId,
      tablesExported: Object.keys(manifest).length,
      rowsExported: totalRows,
    });
    return jsonResponse({
      job_id: jobId,
      status: "completed",
      storage_prefix: storagePrefix,
      tables_exported: Object.keys(manifest).length,
      rows_exported: totalRows,
      total_bytes: totalBytes,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    logError(requestId, FN, message, { jobId });
    await admin
      .from("platform_backup_jobs")
      .update({
        status: "failed",
        error_message: message,
        completed_at: new Date().toISOString(),
      })
      .eq("id", jobId);
    return jsonResponse({ error: "backup_failed", detail: message }, 500);
  }
});
