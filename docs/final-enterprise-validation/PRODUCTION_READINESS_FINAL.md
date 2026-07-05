# Production Readiness — Final Honest State

> Builds directly on Remediation v1's `docs/remediation/FINAL_REMEDIATION_REPORT.md` (still the
> authoritative source for what's applied/drafted/open as of that pass) and adds this campaign's
> 8 checkpoints of real testing on top. Nothing below re-litigates what that report already
> answered — only what changed or was newly discovered.

## 1. Still true, unchanged since Remediation v1

- Zero migrations applied to production, zero Edge Functions deployed, by this campaign's own
  Rule 8 — everything below is drafted/tested-on-dr-scratch/reported, nothing is live.
- The 5 P0/P1/P2 security fixes: still drafted, awaiting approval, **re-confirmed still effective
  against a fresh live exploit attempt** this pass (`SECURITY_REPORT.md` §1) — not just
  re-asserted.
- The 14 backend feature migrations (CMS, remote config, feature flags, legal center, catalog,
  A/B testing, business observability, audit business, Health Center, perf indexes): still
  undeployed. This pass adds one concrete consequence of that: the Health Center's own monitoring
  table doesn't exist in production, which is the direct cause of CP8's "not observable" verdict.
- Android upload keystore, Privacy Policy/Terms content, bank transfer details, iOS scope: all
  still open, still explicitly Mylord's decisions, unchanged by this pass.

## 2. New since Remediation v1 — found by this campaign

- **Two real concurrency bugs**, one in the offline mutation outbox (`OfflineSyncCoordinator`,
  `OFFLINE_REPORT.md` §3) and one in the automation action runner (`run-scheduled-actions`,
  `BACKGROUND_JOBS_REPORT.md` §3), both live-reproduced with real before/after evidence. A third,
  related finding (`schedule-reminders`, same TOCTOU shape, no DB backstop) was confirmed by code
  and schema inspection. None of these three were known before this pass.
- **Production has near-zero real data** (`SQL_PERFORMANCE_REPORT.md` §1) — every table tops out
  in single/double digits, confirming and quantifying what Remediation v1's backup finding (156
  rows / 55 tables) already implied.
- **Storage is functionally unused in production** (`STORAGE_REPORT.md` §4) — 0 objects in the
  public media bucket — and the AGENT.md-mandated server-side WebP compression doesn't exist in
  code (`StorageService.uploadBinary` stores whatever bytes the client sends).
- **`notification_logs` isn't in the Realtime publication** (`REALTIME_REPORT.md` §0) — the
  notifications screen's live-update code path can never actually receive a live update in
  production, on top of the already-known CMS/remote-config gaps.
- **A real, measured scale ceiling**: `trg_increment_monthly_bookings` (a per-row, unbatched
  trigger) caps single-statement bulk writes around 150k rows before hitting the environment's
  ~2-minute statement timeout (`SCALABILITY_REPORT.md` §1) — irrelevant to normal one-booking
  traffic, real for any future bulk-import or migration tooling.
- **Production is not observable**, directly confirmed (`OBSERVABILITY_REPORT.md` §5) — no
  monitoring table in production, one function's monitoring silently writing to nowhere, two
  unconsumed health views, zero alerting of any kind.

## 3. What this means for "is it safe to ship"

Nothing found this pass is a blocking emergency for the current, near-zero-real-traffic state of
production — every real bug found requires either genuine concurrent load (which doesn't exist yet
per §2's data-volume finding) or a bulk-write scenario (which also doesn't happen in normal
traffic). **The risk profile changes the moment either changes**: real user growth makes the
concurrency bugs live risks, not theoretical ones, and real user growth is also exactly what would
make the lack of observability (§2) costly — the two gaps compound each other. This is why
`FINAL_ROADMAP.md` treats fixing the concurrency bugs and closing the observability gap as
higher-urgency than their scorecard-domain scores alone might suggest.

## 4. Confirms Remediation v1's own priority list, with one addition

Remediation v1's "what Mylord needs to decide" list (§4 of `FINAL_REMEDIATION_REPORT.md`) still
stands as the right order for the items it covered. This pass's findings don't reorder it — they
add two new, scoped decisions to it (fix the two concurrency bugs; decide when to actually deploy
`20260704120000_observability_system_admin.sql` and wire a second Edge Function's monitoring as a
real end-to-end proof, not just a migration). See `FINAL_ROADMAP.md` for where these land relative
to the existing P1-P7 order.
