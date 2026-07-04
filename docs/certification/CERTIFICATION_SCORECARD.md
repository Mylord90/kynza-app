# KYNZA — Enterprise Final Certification Scorecard

> Produced at CP10 (Phase 11) of the KYNZA Enterprise Final Certification Pass, 2026-07-04. Every
> score below is backed by a cited command, test, file, or prior checkpoint report — no score is
> rounded up "to look clean." Full narrative and remaining risks: `PHASE_11_FINAL_CERTIFICATION.md`.

| Domaine | Score /100 | Preuve principale | Écart restant (chiffré) |
|---|---|---|---|
| Architecture | **82** | CP1: feature-first layering (30 dirs), Riverpod graph (0 circular imports), GoRouter (0 orphan screens), Freezed/JSON coverage all ✅ | 14 files bypass the repository layer + only 1/24 features has a real datasource split (CP1, re-confirmed unchanged CP8) — **−18** |
| Infrastructure | **68** | Real production (`hhdkjfpgaklhrhfoxlhj`) + staging (`kynza-dr-scratch`) Supabase projects, 20 Edge Functions deployed and documented (CP3) | CI/CD pipeline has **never once actually executed** (re-confirmed CP1, unchanged since the prior 2 passes); no Android/iOS device or emulator exists in any environment this or the prior 3 passes have run in — **−32** |
| Backend | **85** | 381/381 tests passing, 0 `flutter analyze` issues (every checkpoint), Edge Function certification across 11 dimensions for all 20 functions (CP3), Remote Config's full lifecycle live-proven (CP3) | Timeout (0/20), tracing (0/20), and metrics (1/20) are near-universal gaps across Edge Functions (CP3) — **−15** |
| Sécurité | **52** | 12 of 13 live offensive vectors blocked (RBAC, JWT forgery ×2, SQL-injection-shaped input, feature-flag tampering, rate-limit enforcement exact-match, replay) — CP6; RLS 55/55 tables (CP1) | **1 CONFIRMED CRITICAL P0, live in production right now, unpatched**: `staff_profiles_public_select` leaks `invitation_token` to unauthenticated requests — a real account-takeover vector (CP6). Plus 2 `SECURITY DEFINER` views (CP2), an unbounded-payload DoS-shaped finding (CP6), no root/jailbreak detection, cert pinning wired but inert — **−48** |
| Performance | **42** | Real Edge Function latency now measured for the first time in any KYNZA pass: 1.4–2.1s cold / 0.6–0.7s warm (CP4) | 9 of 10 named targets in `PERFORMANCE_TARGETS.md` remain **"not measured"** — cold/hot start, FPS, memory, CPU/GPU, offline load time all require a real device/emulator that doesn't exist in this environment — **−58** |
| Observabilité | **58** | 13 Track A dashboards certified against real data sources (CP4); 1 live end-to-end pipeline proof executed (insert → RLS-deny → grant → RLS-allow, CP4) | **Zero alerting/threshold code exists anywhere** (2 greps, 0 hits, CP4); Crash Dashboard has no queryable data source at all (Crashlytics client-only); Performance Dashboard honestly renders "unavailable" — **−42** |
| Scalabilité | **58** | First real executed load test in any KYNZA pass: 1,000 salons / 10,000 bookings generated and query-planned live on `kynza-dr-scratch` (CP5) | Only 1 of the 5 required scale points (100/500/**1,000**/5,000/10,000) was actually tested; zero real production traffic exists yet to validate against — **−42** |
| Monitoring | **38** | 13 dashboards exist as real, queryable data sources (CP4) | **Zero alert thresholds configured anywhere** — no crash-free-user threshold, no Firebase Performance Monitoring package, nothing pages anyone today (CP4, re-confirming `PRODUCTION_CHECKLIST.md`) — **−62** |
| Automation | **74** | `execute-workflow`/`run-scheduled-actions` real and functional with shared retry/backoff (2/4/8min, max 3) — CP3 | No rate limiting on 4 functions (by design — server-to-server/cron-only trust, not a real gap) but no metrics/tracing either (universal gap) — **−26** |
| Remote Config | **80** | **Best-verified subsystem this pass**: full lifecycle live-tested on `kynza-dr-scratch` — 3 distinct malformed-value rejections, 1 valid update, 1 exact rollback (DB-verified), 1 unauthenticated rejection (CP3) | Still gated on `role === 'owner'`, not `has_system_admin()` (known, logged since the Backend Completion pass); engine schema still in an unapplied draft migration — **−20** |
| Feature Flags | **62** | Real engine: category grouping, per-role/user override schema exists (draft), Realtime propagation code real | `evaluateFlag()` is called from nowhere except its own repository (Backend Completion Phase 1 finding, unchanged) — the engine has no live consumer screen yet; draft migrations unapplied — **−38** |
| CMS | **65** | Real engine, admin-write RLS gated by `has_system_admin()` (live-proven CP4); 2 of 4 named client screens built | `OnboardingContentScreen`/`BeautyTipsScreen` not built (known, disclosed, "mechanical follow-up") — **−35** |
| Offline | **48** | Outbox covers 3 entities with real, passing tests (`offline_airplane_mode_test.dart`, `offline_sync_coordinator_test.dart`, cited CP7) | Both Hive boxes unencrypted (known); bookings exclusion documented, notifications exclusion is not (Backend Completion Phase 1 finding, unchanged); no live device test of any offline path in this or any prior pass — **−52** |
| Synchronisation | **55** | Realtime cache-fallback tests real and passing (`feature_flag_realtime_test.dart`, `remote_config_realtime_test.dart`, cited CP7) | Reconnection behavior is entirely the Supabase SDK's own default backoff — no KYNZA-authored tuning exists to verify; Network Dashboard is per-device only, not fleet-wide (Supabase platform limitation, CP4) — **−45** |
| Documentation | **92** | 4 major passes' worth of real, cross-referenced documentation (`ARCHITECTURE.md`, `DATABASE_ARCHITECTURE.md`, `SECURITY.md`, this entire `docs/certification/` tree, real Mermaid diagrams) | `DOCUMENTATION_INDEX.md` needed one more section for this pass itself (added this checkpoint) — **−8** |
| Qualité de code | **76** | `flutter analyze`: 0 issues at every one of 9 checkpoints; 2 real async-gap bugs found and fixed (CP8); 5 confirmed-dead files removed, 191 lines (CP8) | 14-file repository-layer-bypass debt and datasource-pattern inconsistency both re-confirmed still real, deliberately not touched (too large/risky for a cleanup checkpoint) — **−24** |
| Tests | **54** | 381/381 passing, zero regressions across all 9 checkpoints; 2 previously-0%-covered critical files brought to 100%/89.5% (CP9) | Line coverage **23.29%** overall; **zero repository-layer test files exist at all** — every repository wrapping the real Supabase client has 0% coverage, no mocking seam exists yet (CP9) — **−46** |
| Production Readiness | **33** | Real backup export mechanism (`create-backup`), real maintenance-mode gate, real versioning scheme — all previously verified and re-confirmed unchanged | **Privacy Policy/Terms: MISSING** (hard Play/App Store blocker, unchanged since 2026-07-03); Play Store listing not started; bank transfer details still `[À CONFIGURER]`; CI/CD never executed even once; no real device APK launch ever verified; **and the CP6 P0 security vulnerability is unpatched in production today** — **−67** |

## Unweighted average across 18 domains: **62.3/100**

Not a formal composite metric (domains aren't equally weighted in real launch risk — Sécurité and
Production Readiness matter far more than, say, Automation) — included only as a single honest
summary number, not a passing/failing threshold.

## The one number that matters most

**Sécurité cannot be certified above 52/100 while a confirmed, live, unauthenticated
account-takeover vulnerability remains unpatched in production.** Every other domain's score is
secondary to closing that one item. See `PHASE_6_SECURITY_OFFENSIVE.md` and
`PHASE_11_FINAL_CERTIFICATION.md` §P0 for the exact remediation already drafted and its one
remaining precondition.
