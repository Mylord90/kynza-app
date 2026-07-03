# Phase 0 — Baseline & Pre-Flight Audit

> Captured 2026-07-03, before any hardening work begins. This is the source-of-truth "before"
> state for every later phase in the Enterprise Hardening & Production Readiness pass. Every
> section below is a verbatim (or lightly trimmed, noted where trimmed) command output — no
> claim in this document is inferred.

## 0. Preliminary: pre-existing uncommitted work

Before this baseline was captured, the working tree had substantial uncommitted output from a
prior, separate "Enterprise Architecture & Documentation Expansion" pass (23 docs, 15 diagrams,
3 draft migrations, 1 seed script — see `docs/ENTERPRISE_ARCHITECTURE_EXPANSION_REPORT.md`).
Per user decision, this was committed as-is (commit `ff91e59`, "docs: Enterprise Architecture &
Documentation Expansion (Phases A-F)") before this baseline was tagged, so the baseline tag sits
on a clean tree and this pass starts from a known, committed state.

## 1. `flutter --version`

```
Flutter 3.44.2 • channel stable • https://github.com/flutter/flutter.git
Framework • revision c9a6c48423 (3 weeks ago) • 2026-06-10 15:52:41 -0700
Engine • hash 04efd7c093d4e9281d5526ebcad6ecc60ba8badf (revision 77e2e94772) (22 days ago) • 2026-06-10 19:59:06.000Z
Tools • Dart 3.12.2 • DevTools 2.57.0
```

## 2. `flutter analyze`

```
Analyzing KYNZA-PROJET...
No issues found! (ran in 33.7s)
```

**Result: 0 issues.** This is the floor every later phase must not regress below (Rule 1).

## 3. `flutter test`

Full suite run to completion. Final line:

```
00:31 +244: All tests passed!
```

**Result: 244/244 passing.** Matches the count from the prior session's work
(`ENTERPRISE_ARCHITECTURE_EXPANSION_REPORT.md` and memory both cite 244). This is the floor
every later phase must not regress below.

## 4. `flutter pub outdated`

Informational only — **no upgrades performed or planned in this pass** unless a specific phase
calls for one and it's flagged explicitly.

Key facts from the raw output:
- 19 direct dependencies have newer resolvable versions (majors), locked via `pubspec.yaml`
  constraints — e.g. `go_router` 14.8.1 → 17.3.0, `flutter_riverpod` 2.6.1 → 3.3.2,
  `firebase_core` 3.15.2 → 4.11.0, `supabase_flutter` 2.15.0 → 2.15.3 (patch-level, closest to
  safe).
- `phosphor_flutter` is pinned via a local vendor override at 2.1.0 (per the IconData-final SDK
  patch documented in commit `5971168` / `423e5c8` — memory: vendor patch note).
- 3 transitive packages are flagged discontinued upstream: `js`, `build_resolvers`,
  `build_runner_core`. None are direct dependencies; no action taken this pass.
- 13 upgradable dependencies are locked in `pubspec.lock` to older versions; 43 dependencies are
  constrained below their latest resolvable version in `pubspec.yaml`.

No dependency upgrades are in scope for this hardening pass unless a specific phase's acceptance
criteria requires one (none currently do). Full raw output available by re-running
`flutter pub outdated` — not pasted in full here to keep this document scannable.

## 5. Android manifests — as committed today (source, not merged)

### `android/app/src/main/AndroidManifest.xml` (release-relevant source manifest)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application ...>
        <activity .../>
        <meta-data android:name="com.google.firebase.messaging.default_notification_icon" .../>
        <meta-data android:name="com.google.firebase.messaging.default_notification_color" .../>
        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

**Confirmed: zero `<uses-permission>` elements in the main source manifest.** This is the same
finding flagged in the prior pass, now directly re-confirmed by reading the file in this
session — but note this is the **source** manifest, not a merged/release manifest. Phase 1's job
is to build the actual release AAB/APK and inspect the **merged** manifest via `aapt`, since
plugins can inject permissions during the Gradle manifest merge even when the source app manifest
declares none. This baseline only proves what the source file says today.

### `android/app/src/debug/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

### `android/app/src/profile/AndroidManifest.xml`

Identical to the debug variant — `INTERNET` only, with the same Flutter-tooling comment.

**Implication:** if the Gradle manifest merge does not pull `INTERNET` in from a plugin for the
release variant, and no release-flavor manifest snippet grants it, the release build could ship
without network access entirely. This must be verified against the actual merged manifest in
Phase 1, not assumed from this source-level read.

## 6. `android/app/build.gradle.kts`

Full file (47 lines) — key facts:
- `namespace` / `applicationId` = `com.kynza.app`.
- `compileSdk` / `minSdk` / `targetSdk` / `versionCode` / `versionName` all delegate to the
  Flutter tool's defaults (`flutter.compileSdkVersion` etc.) — no explicit override.
- Java/Kotlin target: 17.
- **Release build type signs with the `debug` signing config** (`signingConfig =
  signingConfigs.getByName("debug")`), with an explicit `// TODO: Add your own signing config
  for the release build.` comment. This is the previously-flagged debug-keystore blocker,
  reconfirmed here — carried forward to Phase 10 (Production Readiness), not fixed in this
  baseline phase.
- No `minifyEnabled` / `shrinkResources` / R8 config present at all — carried forward to
  Phase 10.

## 7. Supabase schema — live migration state

`supabase db dump` requires a local Docker daemon to run a version-matched `pg_dump` container;
this machine has no Docker Desktop installed (confirmed: `docker` calls fail with "the default
daemon configuration on Windows... elevated privileges... cannot find the file specified").
`psql` / `pg_dump` are also not installed locally. **A full raw schema dump is not possible in
this environment without provisioning Docker or a local Postgres client** — flagged here as a
tooling gap, not silently worked around.

Instead, the source of truth used (matching the prior pass's own methodology, since migration
files 100% define the schema) is `supabase migration list --linked`, which queries the remote
project's `supabase_migrations.schema_migrations` table directly (no Docker required) and
compares it against local files:

- **62 total local migration files** in `supabase/migrations/`.
- **59 are applied on the remote** (`hhdkjfpgaklhrhfoxlhj`), with matching local/remote
  timestamps.
- **3 are NOT applied to the remote** — confirmed empty in the "Remote" column:
  - `20260703120000_indexes_optimization.sql`
  - `20260703130000_catalog_schema.sql`
  - `20260703140000_feature_flags_registry.sql`

  These are exactly the 3 draft migrations from the prior documentation pass. **This confirms
  Rule 8 has been honored to date: no draft migration has touched the live remote project.**

Phase 2 (Schema Reconciliation Report) will parse every applied migration's `CREATE TABLE`
statements to build the authoritative live table list and resolve the 47-vs-55 count
discrepancy — that reconstruction happens there, not here; this section only establishes which
migrations are live today.

## 8. Git baseline tag

```
git tag pre-hardening-baseline
```

Applied to the commit that includes this document plus the prior pass's commit (`ff91e59`) as
its immediate parent. This tag is the universal rollback fallback for the entire hardening pass
(see the prompt's Global Rollback Plan).

## 9. Acceptance criteria check

- [x] `flutter analyze` = 0 issues, captured verbatim above.
- [x] `flutter test` = 244/244 passing, captured verbatim above.
- [x] Android manifest variants (main/debug/profile) and `build.gradle.kts` snapshotted from the
      actual files, not assumed.
- [x] Live Supabase migration state captured via `migration list --linked` (real remote query);
      full `pg_dump`-style dump explicitly flagged as blocked by missing Docker/psql, not
      silently skipped or faked.
- [x] Repo tagged `pre-hardening-baseline` for traceable rollback.

Every later phase's "before" state is traceable to this document, per Phase 0's acceptance
criterion.
