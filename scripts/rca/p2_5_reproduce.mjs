// One-off diagnostic script for the P2-5 RCA (Backend Production Closure follow-up).
// Fires a controlled sequence of oversized-body requests against production Edge Functions
// and records raw, timestamped results to stdout as NDJSON. Read-only from the app's
// perspective: every target function rejects before touching the database when the guard
// fires, and the "success" (bypass) case only reaches functions whose logic errors out
// harmlessly on an authless/malformed call (never mutates data) -- confirmed by code reading
// during Backend Production Closure CP1.
const ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoZGtqZnBnYWtsaHJoZm94bGhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODA4ODksImV4cCI6MjA5NDc1Njg4OX0.RqRpwPRse5i_YVszfnlav7LKbKyMKg4RujfZdspuS5g";
const BASE = "https://hhdkjfpgaklhrhfoxlhj.supabase.co/functions/v1";

const targets = process.argv[2] ? process.argv[2].split(",") : ["calculate-commission", "update-remote-config"];
const attemptsPerTarget = Number(process.argv[3] ?? 10);
const payloadSize = Number(process.argv[4] ?? 150000);
const runLabel = process.argv[5] ?? "run1";

async function attempt(name, seq) {
  const body = JSON.stringify({ key: "x".repeat(payloadSize), booking_id: "x".repeat(payloadSize) });
  const wallClockStart = new Date().toISOString();
  const t0 = performance.now();
  let result;
  try {
    const r = await fetch(`${BASE}/${name}`, {
      method: "POST",
      headers: { apikey: ANON, Authorization: `Bearer ${ANON}`, "Content-Type": "application/json" },
      body,
      signal: AbortSignal.timeout(20000),
    });
    const text = await r.text();
    result = {
      outcome: "responded",
      status: r.status,
      body: text.slice(0, 200),
      edgeRegion: r.headers.get("x-sb-edge-region"),
      denoExecutionId: r.headers.get("x-deno-execution-id"),
      cfRay: r.headers.get("cf-ray"),
      sbRequestId: r.headers.get("sb-request-id"),
      loadMetrics: r.headers.get("endpoint-load-metrics"),
    };
  } catch (e) {
    // Distinguish a genuine abort-on-timeout (the request was in flight for the full
    // duration -- server-side/never-responded) from an immediate network-level failure
    // (DNS/connection reset -- client-side, happens in a few ms) using both the error
    // name and its underlying cause code, not just the message string.
    const failureType = e.name === "TimeoutError" ? "genuine_timeout" : "immediate_network_error";
    result = {
      outcome: "timeout_or_error",
      failureType,
      error: e.message,
      errorName: e.name,
      errorCauseCode: e.cause?.code ?? null,
    };
  }
  const elapsedMs = Math.round(performance.now() - t0);
  const record = {
    run: runLabel,
    target: name,
    seq,
    payloadBytes: Buffer.byteLength(body),
    wallClockStart,
    elapsedMs,
    ...result,
  };
  console.log(JSON.stringify(record));
  return record;
}

const gapMs = Number(process.argv[6] ?? 1000);

(async () => {
  for (const name of targets) {
    for (let i = 1; i <= attemptsPerTarget; i++) {
      await attempt(name, i);
      await new Promise((res) => setTimeout(res, gapMs));
    }
  }
})();
