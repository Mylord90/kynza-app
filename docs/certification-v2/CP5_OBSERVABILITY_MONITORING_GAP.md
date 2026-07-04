# CP5 — Observability, Monitoring, Performance, Offline `[CLOSE THE GAP]`

The prior scorecard put Monitoring at 38/100. This checkpoint found *why*, and it's a much bigger
finding than "some dashboards are incomplete."

## 🔴 The central finding of this checkpoint: 14 backend feature migrations were never deployed

While checking why `HealthCenterRepositoryImpl`'s 7 dashboard RPCs
(`get_supabase_dashboard`, `get_storage_dashboard`, `get_notification_dashboard`,
`get_queue_dashboard`, `get_edge_function_dashboard`, `get_crash_dashboard`,
`get_security_dashboard`) all failed a direct existence check against production
(`pg_proc`/`pg_namespace`, 0 rows for every one of the 7), traced it to the root cause:
**`supabase migration list --linked` shows 16 of the repo's 75 local migrations have never been
applied to production** (confirmed by both migration history *and* a direct
`information_schema.tables` check for `cms_content`, `experiments`, `categories`,
`legal_documents`, `remote_config_entries`, `service_templates` — **all absent**, not a
migration-history bookkeeping artifact).

Two of those 16 are this pass's own Gate 0/CP2 fixes (correctly unapplied, pending Mylord's
approval). The other **14** are pre-existing, dated 2026-07-03/07-04, and correspond almost
exactly to the entire "Backend Completion" checkpoint series from before this pass began
(`git log`: "CP2 — Feature Flags Engine + Remote Config Engine", "CP3 — Observability Track A +
Health Center", "CP4 — Configuration Engine coverage + CMS Enterprise", "CP5 — Business
Observability schema + A/B Testing engine", "CP6 — Audit Business"):

| Migration | What it built | Live in production? |
|---|---|---|
| `20260703120000_indexes_optimization.sql` | Performance indexes | ❌ No |
| `20260703130000_catalog_schema.sql` | Service catalog/templates/variants/tags/filters | ❌ No |
| `20260703140000_feature_flags_registry.sql` | Feature flags (base) | ❌ No |
| `20260703150000_legal_center.sql` | Legal documents/consent/data-deletion | ❌ No |
| `20260703160000_health_dashboard_views.sql` | Health dashboard views | ❌ No |
| `20260704100000_feature_flags_enterprise.sql` | Feature flags (enterprise layer) | ❌ No |
| `20260704110000_remote_config_engine.sql` | Remote config engine | ❌ No |
| `20260704120000_observability_system_admin.sql` | The 7 Health Center dashboards + `has_system_admin` | ❌ No |
| `20260704130000_configuration_engine_coverage.sql` | Configuration engine | ❌ No |
| `20260704140000_cms_enterprise.sql` | CMS content + versions | ❌ No |
| `20260704150000_business_observability_schema.sql` | Business observability schema | ❌ No |
| `20260704160000_ab_testing_engine.sql` | A/B testing engine | ❌ No |
| `20260704170000_audit_business.sql` | Audit business | ❌ No |
| `20260704180000_cp2_fk_indexes.sql` | FK indexes (this pass's own CP1 architecture work, pre-dating this pass — likely the *original* pass's own CP-numbered work, not this pass's CP2) | ❌ No |

**Real user-facing impact, checked, not assumed**: `health_center_screen.dart` does have
`AsyncError` handling (`KynzaErrorState` + retry), so a `system_admin` opening Health Center in
production today gets a graceful "load failed, retry" state, not a crash — but every one of its 7
dashboards is, in fact, completely non-functional in production right now. The same is true for
CMS, remote config, legal center, catalog/service-templates, A/B testing, feature flags
(enterprise layer), business observability, and audit business — an entire tier of "certified"
functionality exists only as SQL files in this repo, never reaching real users.

**Why this matters beyond CP5**: this is the actual explanation for the prior pass's own
Monitoring (38) and Production Readiness (33) scores — not incomplete implementation, but
undeployed implementation. It also means every prior certification claim about these 14 areas
needs re-reading as "built and tested against dr-scratch/local, not verified live in production" —
a distinction the prior pass's own reports did not draw explicitly. Full line-by-line
SAFE/REVIEW/BLOCKER classification of all 16 unapplied migrations (including whether they're safe
to apply now, in what order, and any interdependency) is CP10's job, not duplicated here — this
checkpoint establishes the fact and scope; CP10 does the deployment-readiness review.

## Alert-category firing (re-tested where possible)

Could not trigger a real end-to-end alert (no alerting *destination* — Slack/email/PagerDuty
webhook — is configured/discoverable in this environment; the dashboards that would compute
threshold breaches are themselves among the 14 undeployed migrations above, e.g.
`v_security_dashboard`'s rate-limit-pressure view). Nothing to fire in production today because
the underlying views don't exist there yet. Once CP10/Mylord approve deployment, this becomes
testable for real; until then, "does it fire" is moot because the computation layer isn't live.

## Log/metric/trace coverage gaps

Extends CP1's finding (`accept-invitation` doesn't populate `activity_logs.ip_address`/
`device_info` despite the columns existing) — spot-checked 2 more Edge Functions
(`calculate-commission`, `claim-referral`): same pattern, `activity_logs` inserts omit
`ip_address`/`device_info`/`session_id`/`request_id` in both. This looks systemic across Edge
Functions, not isolated to `accept-invitation` — worth a follow-up pass specifically on
`activity_logs` population consistency across all 20 Edge Functions (not completed here, time
budget went to the migration-gap finding above, which is the higher-value result).

## Performance re-measurement

⚪ **Not testable in this environment** — no running device/emulator/profiler available (same
limitation every prior phase in this codebase's history has honestly admitted). Cannot re-run the
heaviest-screen measurements or confirm no regression from CP8's 191-line dead-code removal without
one. Not substituted with a guess.

## Offline fault-injection re-run

⚪ **Not testable in this environment**, same reason — fault injection (killing network mid-sync)
requires a running device. `offline_sync_coordinator`'s unit tests (non-device, logic-only) were
not independently re-run this checkpoint given the time this checkpoint's real finding (the
migration gap) required — flagged as a small residual gap, not a claim of "still passing."

## Exit criteria

- [x] Real before/after, not a re-assertion of the old score: found the *actual* root cause behind
      the low Monitoring score (undeployed migrations), which the prior pass's own report never
      identified.
- [x] Honest about what remains untestable in this environment (performance, offline,
      alert-firing) rather than a fabricated pass.
- [ ] This checkpoint did **not** move Monitoring's score up — if anything it should move down
      once CP12 accounts for "the dashboards don't exist in production." That's the honest
      direction of travel this pass's own instructions require when a re-test reveals the prior
      number was too generous.
