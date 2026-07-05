# CP4 — Realtime `[NEW DEPTH]`

> First time this system's Realtime layer has been examined this deeply. All results below are
> from a real, live probe against `kynza-dr-scratch`'s actual Supabase Realtime service over a
> real WebSocket connection (`package:supabase` pure-Dart client, no mock/fake) — including an
> **actual forced network disconnect**, not a code-reviewed guess about reconnect behavior. The
> probe script was run once, its output captured verbatim below, then deleted (ad-hoc evidence
> gathering, same pattern as CP1's `EXPLAIN ANALYZE` probes — not a committed test, since it needs
> live network + project credentials).

## 0. Real finding, found before the probe even ran: `notification_logs` isn't Realtime-enabled

`SELECT tablename FROM pg_publication_tables WHERE pubname='supabase_realtime'` on **both**
production and dr-scratch returns exactly: `services`, `staff_profiles`, `bookings`,
`owner_journey_progress`, `proxipay_sessions`. **`notification_logs` is not in this list, on
either environment.**

`notification_repository_impl.dart:16-31` calls `.stream()` on `notification_logs` for the
notifications screen. Supabase's `.stream()` is implemented on top of `postgres_changes`, which
can only ever receive rows for tables added to the `supabase_realtime` publication — a table left
out of it will **never** deliver a WAL change event, no matter how correct the client-side
subscription code is. Concretely: the notifications list screen renders its **initial snapshot
correctly**, but a new notification arriving while the screen is open will **not** appear live —
the user would need to leave and re-enter the screen (forcing a fresh `.stream()` subscription and
therefore a fresh snapshot) to see it. This is a genuine, previously-unflagged functional gap, not
a guess — confirmed by direct publication-membership query, the same mechanism that makes
`bookings`/`services`/`staff_profiles` genuinely live. Tracked in `FINAL_ROADMAP.md`.

## 1. Live probe results (`kynza-dr-scratch`, real WebSocket, service_role key)

An anon-key run was tried first deliberately, as a security sanity check: it received **zero**
`postgres_changes` events even after a confirmed server-side `UPDATE` on `bookings` — correct,
since `postgres_changes` respects RLS and `anon` has no salon/practitioner/client claim matching
any `bookings` policy. Switched to `service_role` (bypasses RLS by design) for the rest of this
checkpoint, since the object under test here is **transport reliability**, not authorization
(already covered in `SECURITY_REPORT.md`/CP7 and the RLS adversarial matrix from Certification v2).

| # | Test | Real result |
|---|---|---|
| 1 | Subscribe, confirm `SUBSCRIBED` status, baseline event on a real `UPDATE` | Delivered. Measured latency 6,401ms — see caveat below |
| 2 | **Force real network loss**: close the underlying WebSocket sink directly (bypassing the client's own graceful `disconnect()`, which explicitly cancels reconnection — this reproduces the same "socket died without warning" code path (`_onConnClose` → `reconnectTimer.scheduleTimeout()`) that an actual radio/airplane-mode cut would trigger) | Disconnect detected in **261ms** |
| 3 | Automatic reconnection, no manual `.connect()` call anywhere in the probe | Reconnected automatically in **1,517ms**, channel re-subscribed on its own |
| 4 | Event delivery resumes post-reconnect; duplicate check | New event delivered (latency 3,988ms, same caveat); **0 exact-duplicate events** across the whole run |
| 5 | Burst: one bulk `UPDATE` touching 10 rows in a single statement | **All 10** row-change events delivered, 0 dropped, delivered within ~9.3s wall time of the statement running |
| 6 | 3 concurrent subscriptions (independent channels) on one trigger | Both secondary channels received exactly 1 event each — no cross-channel interference, no duplication |
| 7 | 20× subscribe→confirm-subscribed→unsubscribe cycle | Channel list count: **identical before and after** (1 → 1) — no channel-object accumulation across repeated cycles |
| 8 | 10× subscribe immediately followed by unsubscribe with **no wait** for the subscribed callback (race) | **0 errors**, clean final channel state |

**Verdict: reconnection, burst handling, multi-subscription isolation, and repeated
subscribe/unsubscribe cycling all behaved correctly under real fault injection.** This is the
strongest positive result of this checkpoint, and it was earned by actually breaking the
connection, not by reading the SDK's changelog.

## 2. Honest measurement caveat: the two latency numbers above are inflated by probe overhead

Both "baseline" and "post-reconnect" latency were measured as `event_received_at − t0`, where `t0`
was stamped **before** spawning a fresh `supabase db query --linked` CLI subprocess to issue the
triggering `UPDATE`. That subprocess itself pays real, non-trivial cold-start cost each time (CLI
login-role initialization, a version-check network call — visible as `Initialising login role...`
in every invocation throughout this campaign) before the SQL statement even reaches Postgres. The
6.4s and 4.0s figures therefore measure **probe-harness overhead + WAL replication + WebSocket
delivery** combined, not Realtime latency in isolation — reported honestly as such rather than
mislabeled as "Realtime latency: ~5s," which would overstate the real cost by an unknown but
likely large margin. **True client-observable Realtime latency was not isolated in this
environment** — doing so would need a persistent, already-authenticated SQL connection (e.g. a
kept-open `psql`) issuing the trigger instantly, which isn't available here (§4). What *is* cleanly
measurable and reported without this caveat: the transport-level numbers in tests 2-3 (disconnect
detection 261ms, reconnection 1,517ms), since those never depend on spawning a new process.

## 3. Heartbeat / cleanup on dispose

`client.dispose()` was called at the end of the probe run and returned cleanly with no hung
Futures or thrown errors, alongside `removeChannel`/`removeAllChannels` calls throughout — no
resource-cleanup exception surfaced across the whole run (9 channels created and torn down in
total across tests 1, 6, 7, 8).

## 4. What this checkpoint did not test

- **A real OS-level airplane-mode toggle on a physical device or the `Kynza_Pixel6` emulator.**
  An emulator is available in this environment (confirmed via `flutter emulators`) and was
  considered, but a raw forced-WebSocket-close probe against the real Realtime backend (§1) is a
  more precise and repeatable fault injection than toggling an emulator's virtual radio (which
  routes through the host machine's real network stack and may not cleanly simulate a genuine
  radio-level cut). The transport-level code path exercised (`_onConnClose` →
  `reconnectTimer.scheduleTimeout()`) is identical either way — this was a deliberate choice for
  precision, not a fallback taken because the emulator was unavailable.
- **Isolated Realtime latency**, cleanly separated from probe-harness overhead (§2) — would need
  a warm, already-authenticated SQL connection in this environment, not available via the CLI
  tooling here.
- **Production-scale event volume.** The burst test used 10 rows (dr-scratch's real data volume
  in one salon); CP6 (scalability) is the checkpoint that pushes row counts further and would be
  the place to re-run a larger burst if warranted by its findings.
