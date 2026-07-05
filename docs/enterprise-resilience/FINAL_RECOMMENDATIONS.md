# Final Recommendations — Enterprise Resilience & Reliability Certification

**2026-07-05 · Builds directly on `docs/final-enterprise-validation/FINAL_ROADMAP.md`'s priority
order — updates it with this pass's findings rather than replacing it.**

## What the prior roadmap already had queued (unchanged, still valid)

```
P1   — Approve 4 security migrations + 2 Edge Function deploys
P1.5 — Fix the two concurrency bugs + the observability gap (that roadmap's own addition)
P2   — Recurring backup strategy
P3   — Deploy the 14 feature migrations
P4   — Scalability validation + bottleneck fixes
P5   — Real Android release keystore
P6   — Privacy Policy / ToS / Legal Center / bank details / Data Safety
P7   — Minor remaining debt
```

## What this pass changes about that order

**P1.5 is now done, not just planned.** The prior roadmap's own addition — "fix the two concurrency
bugs" — is exactly what CP0 of this pass executed: both bugs fixed, live-tested, plus 2 more found
by a full audit and fixed too. The observability piece of that same P1.5 line is now a proven,
drafted design (CP6) rather than an open TODO. **What's left of P1.5 is a single action: deploy the
already-drafted, already-tested migrations and Edge Functions**, not more engineering work.

## This pass's own priority additions

```
P0  — NEW, highest priority: deploy this pass's own drafted work
       - Migration 20260705100000 (CP0 atomic-claim architecture)
       - Migration 20260705110000 (CP6 payment dashboard + alerting)
       - Edge Function updates: run-scheduled-actions, schedule-reminders, check-system-alerts (new)
       - The Flutter-side fixes (AtomicClaimService, CircuitBreaker, CMS invalidation) ship the
         next time the app itself is released — no server action needed for those specifically.
       Why P0, not folded into the existing P1/P1.5: every other priority in this list assumes the
       concurrency/observability foundation is live. It isn't yet. Deploying it is now zero
       additional engineering (already built, tested, reviewed) — purely an approval + `supabase
       db push` + `supabase functions deploy` action, per Rule 8's approval gate.

P2.5 — NEW: decide and implement a recurring backup mechanism (CP4)
       The prior roadmap's P2 already named this; CP4 adds urgency and precision: RPO is not "some
       number to reduce," it is currently unbounded and growing by the hour. Recommend: a
       pg_cron-callable variant of the Phase 0 backup script (same read-only export mechanism
       already proven twice — Phase 0 and this pass's CP4 rehearsal), OR a plan upgrade enabling
       Supabase PITR (`pitr_enabled: false` confirmed live today) — a real cost/plan decision for
       Mylord, not an engineering unknown.

P2.6 — NEW: rehearse an emergency restore INTO production (or a full clean-room clone)
       Every restore proof so far (Phase 0, this pass's CP4) has targeted a disposable scratch
       project. Nobody has proven KYNZA can actually recover production itself after losing it.
       Recommend doing this once production has enough real data to make the rehearsal meaningful
       (today's 2-salon/7-user volume makes any such rehearsal a weak proof either way) — track as
       a real milestone tied to a data-volume trigger, not a calendar date.

P5.5 — NEW: build a disk-backed read cache for at least the highest-value business screens
       CP5 found this is one systemic gap (no read-through cache anywhere), not four. Recommend
       starting with whichever screen Mylord's own usage data (once observability is live, P0)
       shows is opened most often while offline/reconnecting — don't guess which screen matters
       most without the telemetry P0 unlocks. Sequenced after P0 deliberately: building this cache
       without live error-rate/usage visibility risks optimizing the wrong screen first.
```

## Recommended combined order

```
P0   — Deploy this pass's drafted migrations/functions (concurrency fixes + alerting)   [NEW]
P1   — Approve 4 security migrations + 2 Edge Function deploys                          [unchanged]
P2.5 — Recurring backup mechanism (upgraded from P2, same substance, more urgency)       [updated]
P3   — Deploy the 14 feature migrations                                                 [unchanged]
P2.6 — Emergency restore-into-production rehearsal, once data volume justifies it        [NEW]
P4   — Scalability validation + bottleneck fixes                                        [unchanged]
P5   — Real Android release keystore                                                    [unchanged]
P5.5 — Disk-backed read cache for offline business continuity, informed by P0's telemetry [NEW]
P6   — Privacy Policy / ToS / Legal Center / bank details / Data Safety                  [unchanged]
P7   — Minor remaining debt                                                              [unchanged]
```

**Why P0 goes first even ahead of the pre-existing P1**: P1's security migrations and P0's
concurrency/observability migrations are independent (touch different tables/functions, confirmed
by reading both sets), so there's no technical reason to sequence one before the other — P0 is
placed first here purely because it's the cheapest, most fully-de-risked action available (zero
new engineering, already proven twice on `kynza-dr-scratch`) and it's what unlocks real production
telemetry, which P5.5 (and any future prioritization decision) then depends on.

## What NOT to do

- Do not treat this pass's fixes as "shipped" in any conversation with stakeholders — they are
  reviewed, tested, and ready, which is different from live. `EXECUTIVE_SUMMARY.md`'s bottom line
  exists specifically to prevent that conflation.
- Do not build the read-through cache (P5.5) before deploying observability (P0) — without live
  error/usage data, it's a guess which screen matters most, and CP5 already shows the gap is
  systemic enough that guessing wrong wastes real effort.
- Do not treat CP4's RTO measurement (~60 seconds for 10 tables/82 rows) as a real production RTO
  estimate — it explicitly is not, per CP4's own stated caveats. Any future capacity-planning
  decision needs a fresh, larger-scale measurement, not a reuse of this pass's number.
