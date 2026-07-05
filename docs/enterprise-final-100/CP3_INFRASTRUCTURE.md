# CP3 — Infrastructure

**Date**: 2026-07-05. **Scope**: confirm production-deployment readiness of the cold-start cache
and recurring-backup mechanism built in the prior pass (not rebuild them); close remaining
health-check/cron/maintenance-mode items; document rollback for every migration this whole
campaign has added since the last deployment-plan snapshot.

## Objectifs

P3-11 (maintenance window admin UI), production-readiness confirmation for P1-13 (cold-start
cache) and P1-3 (backup automation), rollback-plan gap-fill for CP2/CP3's new migrations.

## Preuve

### P1-13 (cold-start cache) — re-confirmed production-ready, nothing pending

Pure Flutter client code (`BookingReadCache`/`SearchReadCache`/`ProfileReadCache`/
`NotificationReadCache` + the 4 provider wirings) — no migration, no Edge Function, no server
deploy gate. Ships automatically with the next app release, exactly like `P1-10`/`P1-11`. Nothing
new needed here; re-confirmed by re-reading `CP3_ENGINEERING_CLOSURE.md` against the current
codebase state — all 4 cache files and their wirings are unchanged since they were built and
tested.

### P1-3 (recurring backup) — rollback plan gap-filled

`20260705130000_cp3_platform_backup_automation.sql` had no documented rollback statement (a real
gap `CP2_DEPLOYMENT_READY.md` didn't cover — that document predates this migration's own creation
within the same prior session). Written now, derived directly from the migration's own DDL:
```sql
SELECT cron.unschedule('kynza-platform-backup')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'kynza-platform-backup');
DROP FUNCTION IF EXISTS public.get_all_public_tables();
DROP TABLE IF EXISTS public.platform_backup_jobs;
```
Validation step (unchanged from prior pass): re-run the 2 real automated backup runs' methodology
against production immediately after applying, confirm a `platform_backup_jobs` row completes.

### New migrations this session (CP2/CP3) — rollback plans written

**`20260706100000_cp2_system_admin_grant_audit.sql`**:
```sql
DROP FUNCTION IF EXISTS public.grant_system_admin(UUID, TEXT);
DROP FUNCTION IF EXISTS public.revoke_system_admin(UUID, TEXT);
DROP TABLE IF EXISTS public.system_admin_audit;
-- Restore protect_user_columns() to its pre-CP2 body (drop the
-- current_setting('app.system_admin_grant_rpc') exception, captured
-- verbatim in 20260704120000_observability_system_admin.sql).
```
Validation: re-run this session's live grant/revoke/audit-trail test against production.

**`20260706110000_cp3_maintenance_admin_write.sql`**:
```sql
DROP POLICY IF EXISTS "maintenance_windows_admin_write" ON public.maintenance_windows;
DROP POLICY IF EXISTS "maintenance_windows_admin_delete" ON public.maintenance_windows;
```
Validation: re-run this session's live non-admin-rejected/admin-succeeds test against production.

### P3-11 — maintenance window admin UI, built and live-tested end-to-end

Previously SQL-only (no authenticated write path existed at all). Built:
- Migration: 2 RLS policies (INSERT/DELETE, gated `has_system_admin`) — no UPDATE policy by
  design (a live window is edited via delete-and-recreate, avoiding partial-edit races).
- `MaintenanceRepository`: `createWindow`/`listUpcoming`/`deleteWindow` added to the existing
  interface (`checkMaintenance` untouched).
- New screen `MaintenanceAdminScreen`, routed at `/owner/maintenance-admin`, gated by the existing
  `_SystemAdminGuard` (same pattern as Health Center/CMS Admin/Audit Center), linked from Settings
  with a new l10n-backed label (`settingsMaintenanceAdminLabel`, both `en`/`fr` added,
  `flutter gen-l10n` re-run to regenerate the 3 generated l10n files).

Live-tested on `kynza-dr-scratch`, both directions of both policies:
```
Owner (not system_admin) INSERT -> 403 {"code":"42501", RLS violation}
System_admin INSERT             -> 201, row created
Owner DELETE                    -> 200, [] (0 rows affected — RLS-blocked)
System_admin DELETE             -> 200, row returned (deleted)
```
`flutter analyze`: 0 issues on the new/changed files.

### P3-21 — backup/restore capability, re-assessed against what now actually exists

The finding ("`create-backup` remains export-only, no restore-from-backup code path exists") was
true when written but **CP3's prior-session work already changed the shape of this**: a genuine
restore was performed twice (once in Phase 0's original pass, once in the prior `CP3_ENGINEERING_
CLOSURE.md` rehearsal) using a documented, repeatable manual procedure (download the backup's
per-table JSON, `CREATE TABLE ... LIKE ... INCLUDING ALL`, bulk REST insert, verify row counts).
**Not building a fully-automated one-click "restore" Edge Function this pass** — a genuine
automated restore needs to handle FK ordering, schema drift between backup-time and restore-time,
and partial-failure recovery, none of which can be responsibly rushed. This matches how most
production disaster-recovery playbooks actually work (a documented, human-supervised procedure,
not a single button) — re-classified from "no restore path exists" to "a real, twice-proven
manual restore playbook exists; full automation is a distinct, larger future item," not silently
left at its original wording.

## Statut final

| ID | Statut |
|---|---|
| P1-13 | Fermé (preuve) — re-confirmed, unchanged, production-ready (client-only, no deploy gate) |
| P1-3 | Corrigé-non-déployé — rollback plan gap closed |
| P3-11 | **Fermé (preuve)** — built, live-tested both RLS directions |
| P3-21 | Ouvert, re-scoped — manual restore playbook proven twice; full automation explicitly deferred as a distinct, larger item |

## Documentation associée

`docs/master-plan-execution/CP2_DEPLOYMENT_READY.md`, `docs/master-plan-execution/
CP3_ENGINEERING_CLOSURE.md` (prior session), this document (rollback gap-fill + P3-11 evidence).

## Commit hash

See end-of-checkpoint commit.
