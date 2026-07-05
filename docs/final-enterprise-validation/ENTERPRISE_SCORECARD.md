# Final Enterprise Validation — Scorecard

> Score per domain, each line evidence-linked to the checkpoint report that earned it. Scores are
> out of 10, not rounded up for the sake of a nicer-looking number. Compare against
> `docs/certification-v2/SCORECARD_V2.md` (41.2/100 overall, all Go/No-Go verdicts No-Go) — this
> pass covers different, deeper ground (8 new/re-verified domains) rather than re-scoring the same
> axes, so the two scorecards aren't directly additive.

| Domain | Score /10 | Evidence | Why not higher / why not lower |
|---|---|---|---|
| SQL Performance | 7 | `SQL_PERFORMANCE_REPORT.md` | All 5 hot queries index-covered at both 10k and 400k row scale — genuinely good. Not higher: 288 real advisor findings (RLS policy inefficiency) remain open, and 3 unbounded Realtime queries are a real, now-measured (CP6) forward risk. |
| Storage | 8 | `STORAGE_REPORT.md` | RLS access control passed all 5 live exploit attempts. Not higher: no bucket-level size/MIME limits, and the AGENT.md-mandated server-side WebP compression doesn't exist in code. |
| Offline-First / Hive | 7 | `OFFLINE_REPORT.md` | 4 of 5 new fault-injection scenarios proved real resilience (persistence, resume-after-kill, corruption handling, no lost writes). Not higher: one real, reproduced concurrency bug (double-apply on concurrent flush); also, most product-critical flows (bookings, cash payments, status changes) still aren't queued offline at all — a pre-existing, honestly-tracked gap, not new this pass. |
| Realtime | 8 | `REALTIME_REPORT.md` | First-ever deep test, and it held up well under a real forced network drop: fast detection (261ms), fast auto-reconnect (1.5s), zero duplicates, correct burst/multi-subscription/leak behavior. Not higher: `notification_logs` isn't in the Realtime publication at all — a real, concrete functional gap for one screen. |
| Background Jobs | 4 | `BACKGROUND_JOBS_REPORT.md` | One job (`release-expired-bookings`) is safely idempotent by construction. Not higher: a real, live-reproduced duplicate-processing bug in `run-scheduled-actions` (affects 80% of seeded automation actions by type), plus the same category of bug in `schedule-reminders` with no DB-level backstop. |
| Scalability | 6 | `SCALABILITY_REPORT.md` | Real 40× scale-up executed and measured (not projected); the bounded-query path held up well (3× slower for 40× more data). Not higher: the full brief's tiers (100k clients/20k staff/1M bookings) weren't reached, and a real, concrete bulk-write ceiling was found (a per-row trigger capping single-statement inserts around 150k rows). |
| Security | 8 | `SECURITY_REPORT.md` | All 5 prior-pass fixes re-verified live and holding; JWT signature forgery correctly rejected; no secrets in git history or client code. Not higher: 2 of the checkpoint's planned live tests (cross-tenant session replay, rate-limit burst) weren't executed for lack of a real test session — stated honestly rather than assumed passing. |
| Observability | 2 | `OBSERVABILITY_REPORT.md` | Real building blocks exist and work in isolation (Crashlytics, `pg_stat_statements`, `activity_logs`). Scored low because the checkpoint's direct question — "is this production-observable" — is a real, confirmed **no**: the one Edge Function monitoring table doesn't exist in production, no alert of any kind exists, and two health views have zero screen consumers. |

## Overall

**Unweighted average: 6.25/10.** Not presented as a single "enterprise readiness" number, because
the domains aren't equally weighted in real-world consequence — Observability's 2/10 and
Background Jobs' 4/10 matter more to production safety than Storage's 8/10, regardless of the
arithmetic mean. Read the individual scores and their evidence, not the average, when deciding what
to fix first (see `FINAL_ROADMAP.md`).
