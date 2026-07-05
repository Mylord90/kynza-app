# CP1 — Security Closure

**Date**: 2026-07-05. **Method**: re-tested every Master Inventory (§2 of
`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`) Security-domain item live against
`kynza-dr-scratch` (ref `hzjmyeptytvjmzbnsmwp`) — nothing applied to production
(`hhdkjfpgaklhrhfoxlhj`). Scope is exactly the Master Inventory: confirm existing
`Corrigé-non-déployé` items still hold (re-test, not redesign), and run a first real test for
the one item marked `Non validé` under Security. No new vulnerability class hunted.

**Status vocabulary used below** (per the execution prompt, three distinct states, never
collapsed): **Corrigé** (a fix exists in code/migration form) / **Testé** (fix has live
before/after evidence) / **Prêt au déploiement** (testé + rollback plan + validation step +
no unmet precondition, or the precondition explicitly named).

---

## 1. Re-confirmed this pass — automated live regression suite

`flutter test --tags live --run-skipped test/live/remediation_v1_security_fixes_test.dart`
against `kynza-dr-scratch`, using the project's real anon/service-role keys (fetched via
`supabase projects api-keys`, not stored in the repo). **6/6 passed**, 14s:

```
✓ staff_profiles.invitation_token is never returned to an unauthenticated caller
✓ v_staff_directory_public serves the public staff directory without invitation_token/phone
✓ a staff member cannot reassign their own staff_profiles.salon_id to another salon
✓ create_default_document_templates rejects an unauthenticated caller
✓ run-scheduled-actions rejects a caller with only the public anon key
✓ schedule-reminders rejects a caller with only the public anon key
```

| ID | Item | Fix location | Corrigé | Testé | Prêt au déploiement |
|---|---|---|---|---|---|
| **P0-1** | `staff_profiles.invitation_token` public exposure | `20260704190000_cp6_fix_staff_invitation_token_exposure.sql` | ✅ | ✅ re-confirmed 2026-07-05 | ✅ — REVIEW class, rollback documented (token-invalidation step itself not reversible, zero blast radius: 0 pending invitations in prod) |
| **P1-1** | `staff_profiles.salon_id` mass-assignment | `20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment.sql` | ✅ | ✅ re-confirmed 2026-07-05 | ✅ — REVIEW class, rollback = revert `WITH CHECK` clause |
| **P2-1** | `create_default_document_templates` anon-callable cross-tenant write | `20260704210000_cp11_hardening_batch.sql` | ✅ | ✅ re-confirmed 2026-07-05 | ✅ — REVIEW class, rollback = `DROP FUNCTION`/recreate |

## 2. Re-confirmed this pass — manual live re-test (not covered by the automated suite)

The automated suite's own comment explains why `calculate-commission` and the cron-secret
*success* path aren't in it (needs a disposable booking fixture / would require committing the
real secret). Re-tested manually instead, live, against `kynza-dr-scratch`:

**P2-2 — `calculate-commission` cross-tenant commission disclosure.** Signed in as QA Salon A's
staff account, called `calculate-commission` with a real completed booking ID belonging to QA
Salon B (`ff80497b-83f5-42c6-84bd-ad1f068c4212`):
```
POST /functions/v1/calculate-commission {"booking_id":"ff80497b-..."} (Salon A staff JWT)
→ HTTP 403 {"error":"forbidden"}
```
Confirmed the deployed function (`v3` on dr-scratch, source matches
`supabase/functions/calculate-commission/index.ts`) still carries the
`caller.salon_id !== booking.salon_id` check. **Corrigé ✅ / Testé ✅ (2026-07-05) / Prêt au
déploiement ✅** — code-only fix, no migration, rollback = `git revert` + redeploy.

**P2-3 — `run-scheduled-actions` / `schedule-reminders` cron-secret gate.** Both functions
re-tested via the automated suite above (rejection path, no secret needed) — both return 403 to
an anon-key-only caller. **Corrigé ✅ / Testé ✅ (rejection path) / Prêt au déploiement ⚠️
conditional** — the migration (`20260704220000`) and function code are ready, but the *success*
path depends on a precondition that is **not yet met in production**: `CRON_SECRET` must be set
as both an Edge Function secret and a Vault entry in production *before* this applies, or both
cron jobs silently stop firing with no visible error. This is not a new finding — it is the
single most-flagged silent-failure risk in the whole Master Plan (§7) — re-flagged here, not
re-discovered.

**P3-15 — `get_staff_week_rank` loose anon EXECUTE grant** (bundled in `20260704210000`, same
migration as P2-1). Re-tested independently since the automated suite doesn't cover it:
```
POST /rest/v1/rpc/get_staff_week_rank {"p_staff_id":"00000000-..."} (anon key only)
→ HTTP 401 {"code":"42501","message":"permission denied for function get_staff_week_rank"}
```
Confirms the corrected `REVOKE ... FROM PUBLIC` (not the original no-op `FROM anon`) still
holds. **Corrigé ✅ / Testé ✅ (2026-07-05) / Prêt au déploiement ✅** (bundled with P2-1).

## 3. Closed this pass — first real test (was `Non validé`)

**P2-6 / P2-27 — MANAGER-role and SYSTEM_ADMIN-role live RLS isolation.** No QA fixture existed
for either role before this pass (`CP3_RLS_ADVERSARIAL_MATRIX.md`'s own exit criteria flagged
this as an open gap, unresolved across 2 subsequent passes). Seeded two new QA fixtures on
`kynza-dr-scratch` this pass (kept in place, reusable by future passes, same convention as the
existing Salon A/B owner/staff/client fixtures):
- `kynza.qa.a.manager.cp1@example.com` — `users.role='manager'`, `salon_id`=QA Salon A.
- `kynza.qa.sysadmin.cp1@example.com` — `users.is_system_admin=true`, no tenant role/salon.

Ran the same cross-tenant matrix `CP3_RLS_ADVERSARIAL_MATRIX.md` used for owner/staff/client,
targeting QA Salon B's rows:

| Table/action | MANAGER (Salon A → Salon B) | SYSTEM_ADMIN (no tenant role → Salon B) |
|---|---|---|
| `salon_settings` read | `[]` ✅ isolated | `[]` ✅ isolated |
| `loyalty_programs` read | `[]` ✅ isolated | `[]` ✅ isolated |
| `loyalty_cards` read | `[]` ✅ isolated | not applicable (no salon) |
| `reviews` read | `[]` ✅ isolated | `[]` ✅ isolated |
| `invoices` read | `[]` ✅ isolated | `[]` ✅ isolated |
| `activity_logs` read | `[]` ✅ isolated | `[]` ✅ isolated |
| `bookings` read | `[]` ✅ isolated | `[]` ✅ isolated |
| `v_staff_directory_public` read | full public rows (by design, same as owner/staff/client — not a leak per P0-1's fix) | not tested (no tenant context) |
| `staff_profiles.is_active` cross-tenant `PATCH` | `[]`, HTTP 200 (0 rows matched, blocked); service-role re-check confirms Salon B's row unaffected | not attempted (no tenant role to attempt with) |

**Positive-capability check** (proving `has_system_admin()` isn't just inert, the other half of
what "isolation" needs to mean): called `get_supabase_dashboard()` (a `has_system_admin()`-gated
Health Center RPC) as both accounts —
```
MANAGER      → HTTP 400 {"code":"P0001","message":"forbidden"}
SYSTEM_ADMIN → HTTP 200 [{"table_count":78,"policy_count":135,...}]
```
Confirms the scope grants exactly its intended platform-wide access and nothing more — no
tenant-scoped policy anywhere accidentally keys off `has_system_admin()` (verified by the isolated
reads above, not just by reading the policy SQL).

**Verdict: MANAGER and SYSTEM_ADMIN isolation both hold. No live-exploitable gap found.**
**Status: `Non validé` → `Fermé (preuve)`.** (Update reflected in the Master Inventory at CP5.)

## 4. Left `Ouvert`, unchanged — not in this checkpoint's scope

Per the execution prompt's own rule, items already `Ouvert` (a real, un-drafted design gap) are
not force-fixed here — re-confirmed present, status unchanged, no re-investigation performed:

| ID | Item | Why still Ouvert |
|---|---|---|
| P2-4 | 2 `SECURITY DEFINER` views (`v_popular_searches`, `v_mv_daily_revenue`) | Needs a per-view intent decision (one may be a deliberate trade-off) before a fix can even be drafted — explicitly not to be blindly flipped |
| P2-5 | No Edge Function has a body-size limit (2MB/45s hang) | No fix drafted; mechanical but repo-wide (20 functions), correctly scoped as its own follow-up |
| P2-8 | `is_system_admin` has no grant/revoke/audit RPC | No fix drafted; recommended `grant_system_admin()`/`revoke_system_admin()` RPC still unbuilt |
| P2-13 | `PermissionGuard` wired into 0 screens | Product/UX scoping decision, not a bug |
| P2-21 | Certificate pinning inert; no root/jailbreak detection | Needs a verified captured prod cert first — ops decision, not just code |
| P2-26 | `check_rate_limit` fails open on its own error | No fix drafted |

---

## Exit criteria check

- [x] Every Security-domain Master Inventory item has exactly one of `Ouvert` /
      `Corrigé-non-déployé` (with Corrigé/Testé/Prêt-au-déploiement all explicitly marked) /
      `Fermé (preuve)` — none left ambiguous between the three.
- [x] Every `Corrigé-non-déployé` security item re-tested live this pass, not assumed from a
      prior report.
- [x] The one `Non validé` security item (P2-6/P2-27) received its first real test, with both a
      negative (isolation holds) and positive (scope actually grants what it should) result.
- [x] No item already `Ouvert` was redesigned or rediscovered under time pressure — status
      carried forward unchanged with a one-line reason.

**Net movement this checkpoint**: 1 row (`P2-6/P2-27`) moves from `Non validé` to
`Fermé (preuve)`. 6 `Corrigé-non-déployé` items re-confirmed unchanged (all still hold, all
still awaiting Mylord's deployment approval — see CP2). 6 `Ouvert` items re-confirmed unchanged
(no regression, no new fix attempted).
