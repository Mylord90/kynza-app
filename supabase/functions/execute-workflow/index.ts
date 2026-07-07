// supabase/functions/execute-workflow/index.ts
// Trigger → Conditions → Actions. Called from other Edge Functions via
// supabase.functions.invoke() (the only inter-function pattern used in
// this codebase — see create-booking's send-notification call).
//
// Conditions are evaluated as a flat left-to-right fold over `context`
// (no nesting/parentheses — matches automation_conditions' flat,
// order_index-only design): result = cond[0], then for each later
// condition, OR or AND it into the running result per its own
// logical_operator.
//
// delay_seconds=0 actions run inline so the workflow feels synchronous;
// delay_seconds>0 actions are queued into automation_action_runs for
// run-scheduled-actions (cron) to pick up later — same queue handles
// retries via the same "scheduled_at" mechanism.
import { handleOptions, jsonResponse, readBodyGuarded } from "../_shared/cors.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";
import { recordActionRunResult, runAction } from "../_shared/automation_actions.ts";

interface ExecuteWorkflowPayload {
  trigger_type: string;
  salon_id: string;
  context: Record<string, unknown>;
}

interface ConditionRow {
  field: string;
  operator: string;
  value: unknown;
  logical_operator: "AND" | "OR";
  order_index: number;
}

function evaluateCondition(context: Record<string, unknown>, cond: ConditionRow): boolean {
  const actual = context[cond.field];
  switch (cond.operator) {
    case "eq":
      return actual === cond.value;
    case "neq":
      return actual !== cond.value;
    case "gt":
      return Number(actual) > Number(cond.value);
    case "lt":
      return Number(actual) < Number(cond.value);
    case "gte":
      return Number(actual) >= Number(cond.value);
    case "lte":
      return Number(actual) <= Number(cond.value);
    case "in":
      return Array.isArray(cond.value) && cond.value.includes(actual);
    case "contains":
      return typeof actual === "string" && typeof cond.value === "string" &&
        actual.includes(cond.value);
    default:
      return false;
  }
}

function evaluateConditions(context: Record<string, unknown>, conditions: ConditionRow[]): boolean {
  if (conditions.length === 0) return true;
  let result = evaluateCondition(context, conditions[0]);
  for (let i = 1; i < conditions.length; i++) {
    const cond = conditions[i];
    const condResult = evaluateCondition(context, cond);
    result = cond.logical_operator === "OR" ? (result || condResult) : (result && condResult);
  }
  return result;
}

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  const bodyGuard = await readBodyGuarded(req);
  if (!bodyGuard.ok) return bodyGuard.response;

  try {
    const payload: ExecuteWorkflowPayload = JSON.parse(bodyGuard.text);
    if (!payload.trigger_type || !payload.salon_id) {
      return jsonResponse({ error: "missing_fields" }, 400);
    }
    const context = payload.context ?? {};
    const admin = createServiceRoleClient();

    const { data: workflows, error: workflowsError } = await admin
      .from("automation_workflows")
      .select("id, name, priority")
      .eq("salon_id", payload.salon_id)
      .eq("trigger_type", payload.trigger_type)
      .eq("is_active", true)
      .is("deleted_at", null)
      .order("priority", { ascending: false });
    if (workflowsError) throw workflowsError;
    if (!workflows || workflows.length === 0) {
      return jsonResponse({ status: "no_matching_workflows" }, 200);
    }

    const results = [];
    for (const workflow of workflows) {
      const result = await runWorkflow(admin, workflow.id, payload.trigger_type, payload.salon_id, context);
      results.push({ workflowId: workflow.id, ...result });
    }

    return jsonResponse({ status: "processed", results }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    return jsonResponse({ error: "execute_workflow_failed", message }, 500);
  }
});

// deno-lint-ignore no-explicit-any
async function runWorkflow(
  admin: any,
  workflowId: string,
  triggerType: string,
  salonId: string,
  context: Record<string, unknown>,
) {
  const startedAtMs = Date.now();
  const { data: conditions } = await admin
    .from("automation_conditions")
    .select("field, operator, value, logical_operator, order_index")
    .eq("workflow_id", workflowId)
    .order("order_index", { ascending: true });

  if (!evaluateConditions(context, conditions ?? [])) {
    // Logged (not just returned in the HTTP response) so the execution
    // log viewer can show *why* an active workflow didn't fire, instead
    // of leaving no trace at all.
    await admin.from("automation_execution_logs").insert({
      workflow_id: workflowId,
      salon_id: salonId,
      trigger_type: triggerType,
      trigger_context: context,
      status: "skipped",
      error_message: "conditions_not_met",
      completed_at: new Date().toISOString(),
      duration_ms: Date.now() - startedAtMs,
    });
    return { status: "skipped", reason: "conditions_not_met" };
  }

  const { data: execLog, error: execLogError } = await admin
    .from("automation_execution_logs")
    .insert({
      workflow_id: workflowId,
      salon_id: salonId,
      trigger_type: triggerType,
      trigger_context: context,
      status: "running",
    })
    .select("id")
    .single();
  if (execLogError) return { status: "failed", error: execLogError.message };

  const { data: actions } = await admin
    .from("automation_actions")
    .select("id, action_type, params, delay_seconds, order_index")
    .eq("workflow_id", workflowId)
    .order("order_index", { ascending: true });

  let actionsExecuted = 0;
  let anyFailed = false;
  let anyPending = false;

  for (const action of actions ?? []) {
    const outcome = await queueAndMaybeRunAction(admin, action, execLog.id, salonId, context);
    if (outcome === "failed") anyFailed = true;
    else if (outcome === "pending") anyPending = true;
    else actionsExecuted += 1;
  }

  let finalStatus: "running" | "failed" | "success" = "success";
  if (anyPending) finalStatus = "running";
  else if (anyFailed) finalStatus = "failed";

  await admin.from("automation_execution_logs").update({
    status: finalStatus,
    actions_executed: actionsExecuted,
    completed_at: anyPending ? null : new Date().toISOString(),
    duration_ms: anyPending ? null : Date.now() - startedAtMs,
  }).eq("id", execLog.id);

  // Supabase's JS `.update()` can't express `count = count + 1` — an
  // atomic increment needs a dedicated RPC (see the migration).
  // Postgrest query builders are thenable but don't implement `.catch()`
  // (only `.functions.invoke()` returns a real Promise) — try/catch
  // instead of `.catch()` chaining, which throws "not a function".
  try {
    await admin.rpc("increment_workflow_execution", { p_workflow_id: workflowId });
  } catch {
    // best-effort counter — never fails the workflow execution itself.
  }

  return { status: finalStatus, actionsExecuted };
}

interface ActionRow {
  id: string;
  action_type: string;
  params: Record<string, unknown>;
  delay_seconds: number;
}

// deno-lint-ignore no-explicit-any
async function queueAndMaybeRunAction(
  admin: any,
  action: ActionRow,
  executionLogId: string,
  salonId: string,
  context: Record<string, unknown>,
): Promise<"success" | "failed" | "pending"> {
  const scheduledAt = new Date(Date.now() + (action.delay_seconds ?? 0) * 1000);
  const { data: run, error: runError } = await admin
    .from("automation_action_runs")
    .insert({
      execution_log_id: executionLogId,
      action_id: action.id,
      salon_id: salonId,
      context,
      scheduled_at: scheduledAt.toISOString(),
    })
    .select("id")
    .single();
  if (runError) return "failed";

  if (action.delay_seconds > 0) return "pending";

  const result = await runAction(admin, action, context, salonId);
  // A first attempt that fails inline still gets retried (3x backoff) —
  // see recordActionRunResult's doc comment for why this can't just
  // mark it "failed" outright.
  const outcome = await recordActionRunResult(admin, run.id, 1, result);
  if (outcome === "skipped" || outcome === "success") return "success";
  return outcome;
}