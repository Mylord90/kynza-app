# Final Roadmap — Confirmation of Mylord's Priority Order + This Pass's Additions

## Mylord's given order, examined against this pass's real findings

```
P1 — Approve 4 security migrations + 2 Edge Function deploys
P2 — Recurring backup strategy
P3 — Deploy the 14 feature migrations
P4 — Scalability validation + bottleneck fixes (this pass's CP6 output)
P5 — Real Android release keystore
P6 — Privacy Policy / ToS / Legal Center / bank details / Data Safety
P7 — Minor remaining debt (Remote Config admin gate, proxipay_sessions constraint, triggers)
```

### The specific question this checkpoint asks: should P3 precede P4, given CP1/CP6?

**Checked directly, not assumed**: read all 14 undeployed feature migrations for any reference to
`bookings` or its indexes/triggers — the table CP6 identified as the real bottleneck
(`trg_increment_monthly_bookings`, a per-row, unbatched trigger) and CP1 identified as the highest
real-traffic table with open RLS-performance findings. Result: **3 of the 14 migrations reference
`bookings`** (`phase3_mv_revenue`, `phase3_backup`, `health_dashboard_views`), and all three only
**read** from `bookings` to build a materialized view or a reporting view — none of them add a
trigger, an index, or write load to `bookings` itself. **None of the 14 migrations touch
`trg_increment_monthly_bookings` or the RLS policies CP1 flagged.**

**Confirmed: the given order is fine as stated.** Deploying the 14 feature migrations (P3) does
not make CP6's bulk-write bottleneck or CP1's RLS-performance findings any worse — they're
orthogonal. `mv_daily_revenue`'s nightly refresh cost does scale with `bookings`' row count (CP1
measured 215ms at 10k rows; expect it to grow with real production volume), but that's a
once-nightly batch cost, not a user-facing latency path — worth monitoring once P3 ships, not a
reason to reorder it after P4.

## This pass's additions to the list

Inserted where they cause the least rework and the most reduction in real risk:

```
P1 — Approve 4 security migrations + 2 Edge Function deploys                [unchanged]
P1.5 — NEW: Fix the two concurrency bugs (OfflineSyncCoordinator concurrent-flush
        double-apply, run-scheduled-actions concurrent-invocation double-process) +
        the related schedule-reminders TOCTOU gap. Cheap, scoped, code-only fixes
        (add a claim step / an in-flight guard) — no reason to defer them behind
        anything schema/deploy-related. See OFFLINE_REPORT.md §3, BACKGROUND_JOBS_REPORT.md §3-4.
P2 — Recurring backup strategy                                              [unchanged]
P3 — Deploy the 14 feature migrations                                       [confirmed, see above]
P3.5 — NEW: Once P3 ships, wire a second real Edge Function's monitoring end-to-end
        (not just apply the migration) and confirm a row actually lands in
        edge_function_invocations from a real production call — CP8 found the
        one existing instrumented function (create-booking) has never fired
        end-to-end even where the table exists (dr-scratch). Migration alone
        won't close this gap; it needs a real call to prove it.
P4 — Scalability validation + bottleneck fixes (this pass's CP6 output)      [unchanged, confirmed
        to still belong after P3]
P5 — Real Android release keystore                                         [unchanged]
P6 — Privacy Policy / ToS / Legal Center / bank details / Data Safety       [unchanged]
P7 — Minor remaining debt (Remote Config admin gate, proxipay_sessions constraint,
        triggers) + NEW: RLS policy consolidation (multiple_permissive_policies /
        auth_rls_initplan, CP1), bound the 3 unbounded Realtime .stream() queries
        (CP1/CP6), add notification_logs to the supabase_realtime publication (CP4),
        add bucket-level file size/MIME limits + real WebP compression (CP2)
```

## Why P1.5 specifically, and why it's placed where it is

Both concurrency bugs are real, live-reproduced, and — per `PRODUCTION_READINESS_FINAL.md` §3 —
currently low-risk only because production traffic is near zero. They are also **cheap to fix**
(neither needs a schema migration; both need a code-level claim/lock step) and **independent of
every other pending decision** (they don't touch the drafted security migrations, don't need the
14 feature migrations, don't need the keystore or legal content). There's no reason to let them
wait behind decisions that are gated on Mylord's business/legal input — they can be scoped and
fixed as their own small, self-contained follow-up whenever engineering time is available, ideally
before real user growth makes them live risks rather than theoretical ones.

## Exit criteria for this campaign (self-check)

- [x] CP1-CP8 each produced either a real measured result or an explicit
  "not testable here, here's what's needed" — verified by re-reading all 8 reports' "what this
  checkpoint did not test" sections.
- [x] Zero invented numbers — every figure in every report traces to a real command run in this
  session (SQL query, live HTTP call, `flutter test` run, or direct file/schema inspection).
- [x] `flutter analyze` = 0 and full test suite green at the final gate (385 passing, 6 skipped —
  5 pre-existing OS-dependent goldens + 1 new, explicitly-documented regression test for the
  concurrency bug found this pass) — zero regressions introduced.
- [x] Given priority order confirmed against real evidence, not left unexamined (see above).
