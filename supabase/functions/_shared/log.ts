/// Structured logging + request correlation, closing part of P3-5 (Master
/// Inventory: 0/20 Edge Functions had tracing/correlation-IDs or structured
/// logging). A generated request ID makes it possible to grep a single
/// request's full log trail out of Supabase's aggregated Edge Function
/// logs — today every log line from every concurrent invocation is
/// interleaved with no way to tell them apart.
///
/// Deliberately NOT rolled out to all 22 functions in this pass — P3-5 is
/// explicitly scoped "Large (per-function)" and already deferred by 3 prior
/// passes for that reason. This gives every function a ready-to-adopt,
/// zero-dependency helper; `create-platform-backup` and
/// `calculate-commission` adopt it here as the proof this pattern works,
/// not as the full rollout.
export function newRequestId(): string {
  return crypto.randomUUID();
}

export function logInfo(
  requestId: string,
  functionName: string,
  message: string,
  extra?: Record<string, unknown>,
): void {
  console.log(JSON.stringify({
    level: "info",
    request_id: requestId,
    function: functionName,
    message,
    ...extra,
  }));
}

export function logError(
  requestId: string,
  functionName: string,
  message: string,
  extra?: Record<string, unknown>,
): void {
  console.error(JSON.stringify({
    level: "error",
    request_id: requestId,
    function: functionName,
    message,
    ...extra,
  }));
}
