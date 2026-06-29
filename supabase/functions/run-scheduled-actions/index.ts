// supabase/functions/run-scheduled-actions/index.ts
// Cron-driven (every 5 minutes, see the pg_cron migration). Picks up
// automation_action_runs rows that are due: either a delay_seconds
// action whose time has come, or a failed action retrying after
// backoff — both are just "a row with scheduled_at <= now()", so one
// runner handles both concerns with no separate retry code path.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";
import { recordActionRunResult, runAction } from "../_shared/automation_actions.ts";

const MAX_ATTEMPTS = 3;
const BATCH_SIZE = 50;

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const admin = createServiceRoleClient();

    const { data: dueRuns, error: dueError } = await admin
      .from("automation_action_runs")
      .select("id, execution_log_id, action_id, salon_id, context, attempt_count")
      .eq("status", "pending")
      .lte("scheduled_at", new Date().toISOString())
      .lt("attempt_count", MAX_ATTEMPTS)
      .limit(BATCH_SIZE);
    if (dueError) throw dueError;

    let processed = 0;
    for (const run of dueRuns ?? []) {
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