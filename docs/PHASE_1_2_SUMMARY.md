# PHASE 1.2 — Audit Enterprise — Summary

## Scope
Extend the existing `activity_logs` (foundation migration) and existing
audit viewer (`lib/features/dashboard/.../audit_log_screen.dart`, shipped
Phase 4) with severity/sensitivity, a stats rollup, and a centralized
`AuditLogger` Flutter service — rather than building any of this fresh.

## What changed

**Migration:** `supabase/migrations/20260629110000_audit_enterprise.sql`
- `activity_logs` +`device_info`, `platform`, `app_version`, `screen_name`,
  `record_id`, `table_name`, `session_id`, `request_id`, `duration_ms`,
  `is_sensitive`, `severity` (CHECK'd to debug/info/warning/error/critical).
- 3 new indexes (`idx_audit_user_action`, `idx_audit_table_record`,
  `idx_audit_severity`).
- `mv_audit_stats` materialized view + unique index + `refresh_audit_stats()`
  + hourly `pg_cron` schedule (`REFRESH MATERIALIZED VIEW CONCURRENTLY`).
- Fixed `logs_self_insert_safe`'s `type_action` whitelist: added 4 values
  already written in production by Edge Functions
  (`staff_invitation_accepted`, `referral_claimed`, `loyalty_stamp_added`,
  `loyalty_reward_redeemed` — found by grepping every existing insert call
  site) plus the 5 new `permission_group_*` values this phase's
  `AuditLogger` writes directly from Flutter.

**Deviations from the brief (found while auditing, before writing SQL):**
- Did not add `old_value`/`new_value`/`action`/`ip_address` columns — the
  table already has `old_values`/`new_values` (plural) and `ip_address`
  from the foundation migration; the brief assumed singular names.
- Did not recreate `idx_audit_salon_created` — identical to the existing
  `idx_logs_salon(salon_id, created_at DESC)`.
- `mv_audit_stats` is not granted to any client role. Postgres has no RLS
  on materialized views — granting `authenticated` direct `SELECT` would
  let any user read every salon's aggregate stats. Kept internal until a
  feature actually consumes it, which would need a `security_invoker`
  wrapping view scoped to the caller's salon.
- Did not add `device_info`/`platform`/`app_version`/`screen_name`
  collection — no `package_info_plus`/`device_info_plus` dependency exists
  in this app yet, and none of 1.2's acceptance criteria require it. Added
  the columns (cheap, harmless) but left them unpopulated; flagging this
  as a deliberate scope cut rather than silently dropping it, since adding
  a new pubspec dependency is the kind of decision worth surfacing (same
  reasoning as the `fl_chart` call-out in Phase 4).

**New Flutter:**
- `lib/core/audit/audit_logger.dart` — `AuditLogger.log()` (never throws;
  reports failures via `CrashReportingService` instead) plus
  `authLogin`/`authLogout` and 5 `permissionGroup*` convenience wrappers.
  Booking/payment logging was **not** duplicated here — those are already
  written server-side by existing Edge Functions (`create-booking`,
  `mark-no-show`, etc.); adding a client-side call too would double-log
  the same event under two different code paths.
- Settings-change logging deferred — `salon_settings` doesn't exist yet
  (that's Phase 1.4); there's nothing to log changes to.
- A CLIENT-role user has `salon_id = null`, and `logs_self_insert_safe`
  requires `salon_id IN (SELECT salon_id FROM users WHERE id = auth.uid())`
  — `NULL IN (...)` is never true, so a salon-less user's actions can
  never satisfy this policy. `AuditLogger` treats this as a no-op by
  design, not a bug to route around (would require weakening the RLS
  policy, which contradicts R02's tenant-isolation rule).

**Wired into real call sites:**
- `auth_notifier.dart` — `signIn`/`signUp`/`signInWithGoogle` log
  `user_login` right after a successful credential check;`signOut` logs
  `user_logout` *before* clearing the session (the RLS check needs
  `auth.uid()` to still resolve — logging after sign-out would silently
  fail the policy).
- `permission_management_providers.dart` (Phase 1.1) — group create/
  delete, permission toggle, and member add/remove all now write an audit
  row (`severity: warning`, `isSensitive: true`).

**Audit viewer (`audit_log_screen.dart`/`audit_log_tile.dart`):**
- Export button (CSV) reusing the existing `CsvExporter`/`ShareService`
  pattern already used by the analytics dashboard — new
  `CsvExporter.auditLogsToCsv()`.
- Tile now shows a severity-tinted border/icon and a lock icon for
  `is_sensitive` rows; added labels for the 5 new `permission_group_*`
  actions (the tile already had labels for the 4 previously-missing
  type_actions found in the whitelist gap above — it just couldn't
  display rows that were never successfully inserted).
- `AuditLogModel` extended with `severity`/`isSensitive`/`tableName`/
  `recordId` (all optional/defaulted — no breaking change to existing rows
  without these columns populated).

**Not changed:** no PDF export for audit (CSV only, matching the
checklist's wording loosely but not literally — `ExportService`'s PDF
helpers are report-shaped, not row-log-shaped; would need a new template,
deferred), no dedicated severity/sensitive filter dropdown (existing
category + date-range filters cover the "filtres fonctionnels" criterion;
severity is now visible per-row instead), no real-time subscription on
the audit list (still `FutureProvider`, matching how it already shipped).

## Verification
- `flutter analyze` → No issues found.
- `flutter test` → 162/162 passed (161 prior + 1 new CSV export test), 0
  regressions.
- `dart format` → applied, no outstanding diffs.
- `refresh_audit_stats()` called directly against the remote DB —
  succeeded (`REFRESH MATERIALIZED VIEW CONCURRENTLY` requires a unique
  index, confirmed present); `pg_cron` job confirmed `active` on the
  hourly schedule.
- New `activity_logs` columns confirmed present via
  `information_schema.columns`.
- Not done: triggering a real sign-in/sign-out or permission-group change
  against the live app to see a row actually land in the table — no
  emulator available in this session (same constraint as Phases A and 1.1).

## Remaining known gaps
- `mv_audit_stats` has no consumer yet (no stats dashboard built on it).
- No device/app-version/screen-name collection (columns exist, unused).
- No PDF export for audit logs.
- Settings-change logging deferred to Phase 1.4 (no `salon_settings` table
  exists yet to log changes to).