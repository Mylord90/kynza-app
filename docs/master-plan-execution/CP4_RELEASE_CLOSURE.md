# CP4 — Android Release Closure

**Date**: 2026-07-05. **Scope**: confirm current state of each Master Plan §14/§10 item and close
any genuinely open gap; the keystore itself remains Mylord's one-way action per Rule 8 — this
checkpoint's job is to make that action zero-ambiguity, not to perform it.

---

## 1. Android keystore — procedure re-confirmed final, nothing generated

Re-verified this session: `android/key.properties` and `android/app/upload-keystore.jks` both
still absent (`ls` — no such file). `android/app/build.gradle.kts`'s conditional signing wiring
re-read and confirmed unchanged and correct (line 58-82: `hasReleaseKeystore` gate, `release`
falls back to `debug` signingConfig when absent, `isMinifyEnabled`/`isShrinkResources` both `true`
with `proguard-rules.pro` referenced — R8/shrinking status unchanged, re-certified).

`docs/android/RELEASE_SIGNING_PROCEDURE.md` re-read in full — it already is the exact,
copy-pasteable, zero-ambiguity procedure the Master Plan asks this checkpoint to produce:
`keytool` command, exact prompts to expect, where to move the file, the `key.properties` template
fields, the 2-independent-durable-locations backup requirement, and the CI-secrets note for
wiring real signing into the pipeline later. **No changes made** — re-verified accurate against
today's actual repo state (the template file `android/key.properties.template` still exists, the
gradle wiring still matches the doc's own description line-for-line). Nothing here needed
regenerating; the procedure was already final.

**Status**: `Ouvert` (P1-4), unchanged — this is correct and expected, not a gap this checkpoint
could or should close.

## 2. CI/CD — re-confirmed genuinely running, not just checked-in

Master Plan (`R-7`) states 5 real runs, most recent green. Re-checked live this session via the
public GitHub Actions API (read-only, no `gh` CLI available in this environment, used
`api.github.com/repos/Mylord90/kynza-app/actions/runs` directly instead):

```
total_count: 7   (was 5 as of the Remediation pass — 2 more runs have happened since)
28730760506  CI  completed  success   2026-07-05T05:30:53Z
28730634059  CI  completed  success   2026-07-05T05:24:52Z
28730270227  CI  completed  success   2026-07-05T05:07:22Z   (the "run 5" the Master Plan cites)
28729567620  CI  completed  failure   2026-07-05T04:32:56Z
28718728585  CI  completed  failure   2026-07-04T20:29:26Z
```

**Confirmed still accurate, now with more evidence**: 3 consecutive green runs, not just 1.
`.github/workflows/ci.yml` re-read: `analyze-and-test` → `build-release` (produces a real,
debug-signed `app-release.apk` artifact, uploaded, 14-day retention) → `approve-deploy` (a
`production` GitHub Environment gate — inert until that Environment is configured with required
reviewers, honestly documented as such in the workflow's own comment) → `deploy` (explicit stub,
never wired to a real Play Store service account, correctly out of scope of every pass so far).

**Status**: `Fermé (preuve)` (R-7), reconfirmed unchanged, evidence strengthened (7 runs vs. 5).

## 3. Play Integrity / App Check — confirmed correctly inert, no gap to close

Re-read `docs/security/APP_CHECK_ARCHITECTURE.md` and re-verified every file it names still
exists and matches: `lib/core/security/app_check_feature_gate.dart`,
`lib/core/security/app_check_service.dart` (still `return const {}` unconditionally, line 18),
`supabase/functions/_shared/app_check.ts`, `test/unit/app_check_feature_gate_test.dart`. This is
a **deliberately inert scaffold** — same "double-gate proven off by test, heavy SDK not added
until real Play Console/Firebase Console configuration exists" pattern as the Google Maps
scaffold. The Master Plan's own instruction was to "close any gap that's genuinely still
open" — there is none here; the documented 7-step future activation procedure (§3 of that doc)
remains the correct next action once Mylord does the external Play Console/Firebase Console setup
it depends on, which is not a repo-level task.

**Status**: not a Master Inventory row (a correctly-scoped, working-as-intended scaffold, not a
gap) — re-confirmed, not touched.

## 4. Play Store checklist — consolidated, final, ordered

Every item traced to `docs/PRODUCTION_CHECKLIST.md` Part 14 and Master Plan §14, re-verified
against the current repo state (not copied blind):

| # | Item | Status today | Owner | Blocking? |
|---|---|---|---|---|
| 1 | Real upload keystore generated + custody plan executed | Open — procedure final (§1 above), execution is Mylord's one-time action | Mylord | Hard blocker |
| 2 | `CRON_SECRET` set in production (precondition for CP2's migration #4) | Open — re-confirmed absent from production secrets this session (CP2) | Mylord/engineering | Blocks reminders' security fix, not Play Store itself |
| 3 | 21-migration deployment batch applied (CP2) | Ready, pending Mylord's sign-off | Mylord approval, engineering execution | Blocks every undeployed feature being "real" in production, not the Play Store submission mechanics themselves |
| 4 | Real Privacy Policy / Terms content, linked from the app | Open — Legal Center *mechanism* ready (part of the 14-migration batch), zero real legal copy exists anywhere (P1-6) | Business/legal | Hard blocker (Play Console requires a live URL) |
| 5 | Real bank transfer details (`[À CONFIGURER]` placeholder) | Open (P2-19) | Business | Blocks real invoicing, not submission itself |
| 6 | Data Safety Form | Open (P1-8) — real, verified data inventory already produced (`PRODUCTION_CHECKLIST.md` Part 14: personal info/photos/financial records/app activity collected, location not collected) | Mylord (Play Console UI) | Hard blocker |
| 7 | Store listing copy, screenshots, feature graphic | Open — never produced by any pass (design-asset task, correctly out of every engineering pass's scope) | Design/business | Hard blocker |
| 8 | Release notes template | Open — none exists; recommend a 2-line `FR:.../EN:...` format | Whoever cuts releases | Not blocking, just undecided |
| 9 | Versioning scheme | **Fermé (preuve)** — `1.0.0+1` in `pubspec.yaml` matches `app_version.dart`, `check_app_version()` RPC live | — | Done |
| 10 | R8/Proguard/shrinking | **Fermé (preuve)**, re-certified this session (§1 above) — `isMinifyEnabled`/`isShrinkResources` both `true`, unchanged | — | Done |
| 11 | CI/CD pipeline genuinely executing | **Fermé (preuve)**, re-confirmed this session (§2 above) | — | Done |
| 12 | Play Integrity / App Check | Not a blocker — deliberately inert by design (§3 above), same as Google Maps | — | N/A |

**Net for this checkpoint**: items 9-12 re-certified with fresh evidence (not blindly copied
forward); items 1, 4, 6, 7 remain the 4 genuine hard blockers, unchanged from every prior pass's
own finding — no new blocker discovered, none silently resolved either.

---

## Exit criteria check

- [x] Keystore procedure re-verified as final and zero-ambiguity — not regenerated, not
      autonomously created.
- [x] CI/CD state re-confirmed live (not assumed from the Master Plan's own prior snapshot) —
      found to have *more* evidence than claimed (7 runs, not 5).
- [x] Play Integrity/App Check gap-closure question answered directly: there is no gap, the
      scaffold is correctly inert by design.
- [x] Play Store checklist consolidated into one final, ordered, actionable list, distinguishing
      exactly which items are done vs. still genuinely open, and who owns each.
