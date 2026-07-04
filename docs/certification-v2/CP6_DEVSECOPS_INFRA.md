# CP6 — DevSecOps & Infrastructure `[NEW DEPTH]`

## Git history secrets scan (real, full history — not just current files)

Ran real pattern scans over `git log --all -p` (85 commits, all branches/refs):
`service_role`/`sb_secret_`/`SUPABASE_SERVICE_ROLE`/PEM private-key headers/AWS key shape,
literal JWT-shaped strings (`eyJ...\....\....`), and `password`/`secret`/`api_key` literal
assignments (excluding obvious placeholders). **Result: clean.** Every `service_role` match is the
word used in a comment/doc discussing the *role concept*, never an actual key value. No JWT-shaped
token, no password, no API key literal was ever committed, at any point in history — confirmed
`.env` was never added to the repo (`git log --all --diff-filter=A -- .env` returns nothing) and
is correctly gitignored (`.gitignore:49`). The specific `kynza-dr-scratch` DB password recorded in
this pass's own memory was also checked — never appears in any commit. Nothing to rotate.

## CI/CD — real execution status, checked via the actual GitHub API, not re-cited

`.github/workflows/ci.yml` exists and is well-formed, but its own header comment already admits
"no CI service is actually provisioned for this repo today." Verified this is still true, for
real: the repo **is** public and pushed to GitHub (`Mylord90/kynza-app`, confirmed via
`git ls-remote origin` returning a real ref, and a plain unauthenticated
`GET api.github.com/repos/Mylord90/kynza-app` confirming `private: false`) — so Actions *could*
run — but `GET .../actions/runs` returns `"total_count": 0`. **Zero workflow runs have ever
executed**, confirmed today via the real API, not assumed from the file's own comment. Unchanged
from the prior pass.

## Release: R8/obfuscation/signing, re-confirmed

- `android/app/build.gradle.kts`: `isMinifyEnabled = true`, `isShrinkResources = true`,
  `proguardFiles(...)` — R8/obfuscation is correctly wired for the `release` build type. ✅ Intact.
- **Signing**: `android/key.properties` (the real upload-keystore credentials file) does not exist
  in this checkout. The build correctly falls back to the debug signing config when absent (by
  design, documented in the file's own comment + `docs/android/RELEASE_SIGNING_PROCEDURE.md`) —
  but this means **a release build produced today would be debug-signed**, not Play-Store-
  submittable. Not a regression — this has never been provisioned — but a concrete, current
  blocker, cross-referenced into CP9's Play Store go/no-go rather than re-described there.
- **App Check / Play Integrity**: `lib/core/security/app_check_service.dart`,
  `app_check_feature_gate.dart`, and `supabase/functions/_shared/app_check.ts` all exist and are
  wired into `create-booking`/`proxipay-confirm` per the prior cert table (`🟡 [app_check] only` —
  i.e. present but not on every function). Not re-tested end-to-end this checkpoint (requires a
  real device/Play Integrity token, same device-dependency limitation as CP5's performance/offline
  gaps) — re-confirmed present in code, not re-confirmed working live.

## Infrastructure

- **Storage buckets**: `kynza-media` is `public=true` (intentional — salon photos/avatars, same
  public-by-design reasoning as `services`/`salons` in CP3), `kynza-backups` is `public=false` ✅
  correctly private.
- **Extensions**: `pg_cron`, `pg_net`, `pg_stat_statements`, `pg_trgm`, `pgcrypto`,
  `supabase_vault`, `uuid-ossp` — a minimal, purposeful set, nothing unnecessary or risky installed.
- **Vault-based secret usage in cron jobs**: the 2 `pg_cron` jobs that call Edge Functions
  (`schedule-reminders` hourly, `run-scheduled-actions` every 5 min) build their `Authorization`
  header via a *subquery* against `vault.decrypted_secrets`, not a literal embedded key. Checked
  who can read `cron.job` (where that subquery text lives): only `postgres` has `SELECT` —
  `anon`/`authenticated`/`service_role` are not granted access. This is a correctly-architected
  pattern, confirmed by checking actual grants, not assumed safe. ✅

## 🔴 Backup/restore — the DR mechanism has never actually run against production

- The Phase 4/7 DR rehearsal proved `create-backup`/restore *works*, against `kynza-dr-scratch`.
  This checkpoint checked whether it has ever actually protected **production**:
  `SELECT count(*) FROM storage.objects WHERE bucket_id='kynza-backups'` on
  `hhdkjfpgaklhrhfoxlhj` → **0**. No backup object has ever been created for the real database.
- Checked `cron.job` for a scheduled trigger: **none of the 6 active `pg_cron` jobs call
  `create-backup`** — payment-timeout cleanup, monthly counter reset, hourly reminders, hourly
  audit-stats refresh, the 5-minute scheduled-actions runner, and a daily materialized-view
  refresh are the only 6, confirmed by direct query.
- **Real implication**: the backup feature is owner/manager-triggerable on demand
  (per the Edge Function cert table) but nothing calls it automatically, and no one ever has —
  if production's database were lost or corrupted today, there is no KYNZA-application-level
  backup to restore from. (Supabase's own platform-level backups/PITR, if the project's plan tier
  includes them, are a separate safety net this checkpoint did not check — that's a billing/plan
  question, not a KYNZA-code question, and shouldn't be assumed present.)
- **Recommendation, queued for CP11**: either add a `pg_cron` schedule calling `create-backup` on
  a real cadence (e.g. daily), or if the intent was always fully-manual, this needs an actual
  standard operating procedure and calendar reminder for Mylord — right now it's neither automated
  nor demonstrably done manually.

## Exit criteria

- [x] Git history secrets scan actually run (not just current-file scan) — clean, evidenced.
- [x] CI/CD execution checked via the real GitHub API, not re-cited from the file's own comment.
- [x] Release signing/obfuscation re-confirmed with the actual build config, not assumed intact.
- [x] Infrastructure (buckets/extensions/cron secret-handling) checked with real grant/config
      queries.
- [x] Backup/restore re-tested a "second execution" as instructed — and the honest result is
      worse than "still fine": found it has *never* protected production, not just "not re-tested
      since Phase 7."
