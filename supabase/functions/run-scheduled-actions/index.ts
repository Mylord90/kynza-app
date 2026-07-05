// supabase/functions/run-scheduled-actions/index.ts
// Cron-driven (every 5 minutes, see the pg_cron migration). Picks up
// automation_action_runs rows that are due: either a delay_seconds
// action whose time has come, or a failed action retrying after
// backoff — both are just "a row with scheduled_at <= now()", so one
// runner handles both concerns with no separate retry code path.
//
// CP0 (docs/enterprise-resilience/CONCURRENCY_REPORT.md): rows are claimed
// atomically via claim_pending_action_runs() (`FOR UPDATE SKIP LOCKED`,
// migration 20260705100000) *before* any processing starts, so two
// overlapping invocations (a slow run can overlap the next 5-min tick)
// can never both process the same row — previously a plain
// `SELECT ... WHERE status='pending'` with no claim step, live-reproduced
// to double-process a row on kynza-dr-scratch.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";
import { recordActionRunResult, runAction } from "../_shared/automation_actions.ts";

const MAX_ATTEMPTS = 3;
const BATCH_SIZE = 50;

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  // CP4 finding (docs/certification-v2/CP4_EDGE_FUNCTION_REVERIFY.md): platform-level verify_jwt
  // is satisfied by the public anon key shipped in the app, so it was never actually restricting
  // this "cron-only" function to the real scheduler. Requires a dedicated secret the pg_cron job
  // sends (supabase/migrations/20260704220000_cp11_cron_secret.sql) — never reaches the client.
  const cronSecret = Deno.env.get("CRON_SECRET");
  if (!cronSecret || req.headers.get("X-Cron-Secret") !== cronSecret) {
    return jsonResponse({ error: "forbidden" }, 403);
  }

  try {
    const admin = createServiceRoleClient();

    const { data: claimedRuns, error: claimError } = await admin.rpc(
      "claim_pending_action_runs",
      { p_batch_size: BATCH_SIZE, p_max_attempts: MAX_ATTEMPTS },
    );
    if (claimError) throw claimError;

    let processed = 0;
    for (const run of claimedRuns ?? []) {
      await processRun(admin, run);
      processed += 1;
    }

    return jsonResponse({ status: "processed", count: processed }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    return jsonResponse({ error: "run_scheduled_actions_failed", message }, 500);
  }
});

interface DueRun {
  id: string;
  execution_log_id: string;
  action_id: string;
  salon_id: string;
  context: Record<string, unknown>;
  attempt_count: number;
}

// deno-lint-ignore no-explicit-any
async function processRun(admin: any, run: DueRun) {
  const { data: action } = await admin
    .from("automation_actions")
    .select("id, action_type, params, delay_seconds")
    .eq("id", run.action_id)
    .single();
  if (!action) {
    await admin.from("automation_action_runs").update({
      status: "failed",
      last_error: "action_not_found",
      attempt_count: run.attempt_count + 1,
      executed_at: new Date().toISOString(),
    }).eq("id", run.id);
    return;
  }

  const result = await runAction(admin, action, run.context, run.salon_id);
  const outcome = await recordActionRunResult(admin, run.id, run.attempt_count + 1, result);
  if (outcome === "pending") return; // rescheduled after backoff — execution log not finalized yet.

  await finalizeExecutionLogIfDone(admin, run.execution_log_id);
}

// deno-lint-ignore no-explicit-any
async function finalizeExecutionLogIfDone(admin: any, executionLogId: string) {
  const { count: pendingCount } = await admin
    .from("automation_action_runs")
    .select("id", { count: "exact", head: true })
    .eq("execution_log_id", executionLogId)
    .eq("status", "pending");
  if ((pendingCount ?? 0) > 0) return;

  const { count: failedCount } = await admin
    .from("automation_action_runs")
    .select("id", { count: "exact", head: true })
    .eq("execution_log_id", executionLogId)
    .eq("status", "failed");

  const { count: successCount } = await admin
    .from("automation_action_runs")
    .select("id", { count: "exact", head: true })
    .eq("execution_log_id", executionLogId)
    .in("status", ["success", "skipped"]);

  await admin.from("automation_execution_logs").update({
    status: (failedCount ?? 0) > 0 ? "failed" : "success",
    actions_executed: successCount ?? 0,
    completed_at: new Date().toISOString(),
  }).eq("id", executionLogId);
}