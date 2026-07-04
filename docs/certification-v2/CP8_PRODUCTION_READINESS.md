# CP8 — Enterprise Readiness & Production Readiness `[CLOSE THE GAP]`

Scored 33/100 previously — the lowest domain in the prior scorecard. This is the single most
important document of this pass for Mylord's decision-making: a plain list of what specifically
keeps Production Readiness below 100 today, synthesized from Gate 0 and CP1-CP7's real findings
(not re-derived — every item below links back to where it was actually found and proven).

## What's keeping Production Readiness below 100, ranked by severity

| # | Item | Found in | Effort estimate | Blocking? |
|---|---|---|---|---|
| 1 | Gate 0 P0: `staff_profiles.invitation_token` publicly readable, live in production | Gate 0 | Trivial — migration fully drafted and Flutter-side precondition resolved; needs only Mylord's review + apply to dr-scratch then prod | 🔴 **Yes — hard blocker on any "production-ready" claim** |
| 2 | `staff_profiles.salon_id` mass-assignment (cross-tenant self-reassignment) | CP2 | Trivial — 1-line WITH CHECK fix drafted, unapplied | 🟠 High priority, not a hard blocker (no confidentiality impact) |
| 3 | 14 backend feature migrations never deployed to production (CMS, remote config, feature flags enterprise, legal center, catalog, A/B testing, business observability, audit business, health dashboards, 2 rounds of perf indexes) | CP5 | **Medium-large** — each needs the line-by-line SAFE/REVIEW/BLOCKER pass (CP10) plus a real post-deploy smoke test per feature, in dependency order | 🔴 **Yes for any claim that these features are "enterprise-certified"** — they are certified against dr-scratch/local only |
| 4 | `calculate-commission` cross-tenant financial-data disclosure | CP4 | Small — one ownership check, same pattern as 2 other functions that already do it correctly | 🟠 High priority |
| 5 | `run-scheduled-actions`/`schedule-reminders` rely on `verify_jwt` alone (satisfied by the public anon key) for a "cron-only" trust boundary | CP4 | Small — add a real shared-secret header check | 🟡 Medium priority (dampened by existing idempotency guards) |
| 6 | No CI/CD has ever executed (0 GitHub Actions runs, confirmed via the real API) | CP6 | Small — pipeline file already exists and needs no secrets for analyze/test/build stages; just needs a push that triggers it | 🟡 Not a security blocker, but "production-ready" without any CI execution history is a real gap |
| 7 | Zero backups have ever protected production; no `pg_cron` schedule calls `create-backup` | CP6 | Small — add a scheduled cron call, or formalize a manual SOP if that's the deliberate choice | 🔴 **Yes for any DR/production-readiness claim** — this is not "untested," it's "never done" |
| 8 | No real Android release keystore provisioned (release build falls back to debug signing) | CP6 | Medium — generate + securely store a real upload keystore, follow the existing documented procedure | 🔴 Yes, for Play Store specifically (see CP9) |
| 9 | `core`↔`feature` circular provider dependencies (`auth_providers.dart`, `offline_sync_providers.dart`) | CP1 | Medium (refactor, no functional bug) | 🟢 Low priority — maintainability debt, not a readiness blocker |
| 10 | MANAGER/SYSTEM_ADMIN role isolation never independently live-tested (no QA fixture exists for either) | CP3 | Small — seed 2 more QA accounts, extend the live RLS test suite | 🟡 Coverage gap, not a known failure |
| 11 | `activity_logs.ip_address`/`device_info` not populated by several Edge Functions despite the schema supporting it | CP1/CP5 | Small-medium — systemic, needs a pass across all 20 functions | 🟡 Audit-quality gap, not a security hole |
| 12 | iOS: default Flutter scaffold only — no Apple Developer team configured, no Firebase (`GoogleService-Info.plist` absent), no App Store Connect record | CP9 (below) | Large — this is a full second-platform launch effort, not a fix | 🔴 Full App Store No-Go (see CP9) |

## What's genuinely solid (re-confirmed this pass, not just re-asserted)

- RLS isolation holds for every table checked except the 2 known `staff_profiles` gaps (CP3) —
  services/salons "leaks" are confirmed by-design, not bugs.
- 21 of 23 SECURITY DEFINER functions correctly validate caller identity/role (CP2); the 2 gaps are
  narrow and now documented.
- R8/obfuscation is correctly configured (CP6).
- Git history has never leaked a secret (CP6).
- `flutter analyze`/`flutter test` are clean, zero regressions from this pass's own changes (CP7).
- The refresh-token rotation/reuse model is correctly implemented by Supabase Auth (CP2).

## Honest scoring direction

This pass found the prior 33/100 was, if anything, **generous** — item #3 (14 undeployed
migrations) is a category of gap the prior pass's own report never surfaced, because its
certification testing ran against `kynza-dr-scratch`/local without checking production deployment
state. CP12's scorecard must reflect this: Production Readiness cannot score meaningfully higher
than 33 until at minimum items #1, #3, #7, and #8 are resolved — these are the true hard blockers,
not stylistic concerns.

## Exit criteria

- [x] A plain, ranked list with effort estimates — not vague statements.
- [x] Every item traceable to where it was actually found (no new claims invented in this
      checkpoint that weren't already evidenced earlier in this pass).
- [x] Explicit honest scoring guidance for CP12 rather than leaving the number to be re-asserted
      without justification.
