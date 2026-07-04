# CP11 — Auto-fix Safe Items, Draft the Rest

## What was auto-fixed directly this checkpoint

**Nothing new in CP11 itself.** On reflection, almost every finding in this pass touches either a
live database schema/policy (a migration, gated by Rule 8) or a deployed Edge Function (gated the
same way this pass has treated migrations throughout — a deploy is exactly as hard to reverse as a
migration once it reaches production). Gate 0 already established the one category that *is* safe
to fix directly in this pass: local, reversible, git-tracked Flutter source code that isn't
deployed by merely being edited (the `publicSalonStaffProvider` addition and
`practitioner_selection_screen.dart` repoint) — both were committed directly back in Gate 0, not
re-done here. No further "typo-level, non-schema, non-breaking" items were found this pass; `flutter
analyze` has been 0 issues at every checkpoint (CP7).

## Drafted this checkpoint: 2 migrations + 2 Edge Function code patches (none deployed/applied)

| Item | File(s) | What it does | Risk | Rollback |
|---|---|---|---|---|
| `create_default_document_templates` ownership check | `supabase/migrations/20260704210000_cp11_hardening_batch.sql` | Adds the same `has_role(owner/manager)` check already used correctly by `check_and_increment_promo_quota`; also revokes anon's dead-weight EXECUTE grant on `get_staff_week_rank` | Low — narrows an existing function's callers, doesn't change its return shape or any legitimate caller's behavior (owners/managers keep working exactly as before) | `DROP FUNCTION`/recreate without the check, or `git revert` + re-apply the old migration body |
| `calculate-commission` ownership check | `supabase/functions/calculate-commission/index.ts` | Rejects the call with `403 forbidden` unless `caller.salon_id === booking.salon_id` | Low — `BookingActionNotifier.markCompleted` (the only legitimate caller) always calls this for a booking at the caller's own salon, so no legitimate flow is affected | `git revert` this commit, redeploy |
| `run-scheduled-actions` / `schedule-reminders` shared-secret check | `supabase/functions/run-scheduled-actions/index.ts`, `supabase/functions/schedule-reminders/index.ts`, `supabase/migrations/20260704220000_cp11_cron_secret.sql` | Requires an `X-Cron-Secret` header matching a new `CRON_SECRET` Edge Function secret; updates both `pg_cron` job bodies to send it (sourced from Vault) | **Medium** — has 2 explicit preconditions documented in the migration file (set the `CRON_SECRET` function secret, store the same value in Vault) that must both be done *before* applying, or reminders/automation silently stop firing. Also flags that this draft *assumes* the production `pg_cron` jobnames based on schedule shape — never confirmed directly (CP6's query didn't select `jobname`) | `git revert` the function code; re-run `cron.schedule` with the old body to restore the un-gated version |

**None of these were deployed or applied.** The 2 Edge Function files are ordinary source changes
sitting in this repo's working tree — deploying them requires `supabase functions deploy`, which
this pass treats with the same caution as a migration `db push`, per the spirit of Rule 8 even
though the rule's letter only names migrations.

## Everything else from CP1-CP8 that still needs a decision from Mylord

Not re-drafted here since each already has its own concrete artifact:

- Gate 0's P0 fix and CP2's `staff_profiles.salon_id` fix — both migrations already drafted, see
  `MIGRATION_REVIEW.md` (CP10).
- The 14 pre-existing undeployed migrations — see `MIGRATION_REVIEW.md`'s recommended apply order.
- CI/CD activation, real release keystore, backup-schedule cron job, core↔feature architecture
  refactor, MANAGER/SYSTEM_ADMIN QA-fixture gap, `activity_logs` population consistency — all
  listed with effort estimates in `CP8_PRODUCTION_READINESS.md`, not duplicated here as they
  aren't code/schema patches this checkpoint could draft as a diff.

## Exit criteria

- [x] Every unambiguously-safe fix from this session (Gate 0's Flutter change) was already applied
      directly at the time it was found — not re-applied or re-described here.
- [x] Every remaining code/schema-level finding has a concrete patch file, a stated risk, and a
      rollback plan — not just a description.
- [x] Nothing was deployed or applied without Mylord's decision.
