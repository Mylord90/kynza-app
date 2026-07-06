# Checkpoint 4 — Production Parity

**Date**: 2026-07-06. **Scope**: real inspection, not assumption, across every dimension the
prompt names — Git code, applied migrations, deployed Edge Functions, RLS policies, roles,
triggers, cron jobs, backups, RPC functions, production configuration — **scoped strictly to what
the three fixes touch**, not a new global audit.

## The claim, stated precisely up front

**"Production = Certified Backend" holds for P2-2 and P2-9, without qualification.**
**It does NOT hold for P2-5, and this checkpoint will not claim otherwise.** CP3 found a real,
reproducible behavioral gap for P2-5 that inspecting code/config/migrations cannot paper over —
parity of *deployed artifact* is confirmed below, but parity of *certified protection* is not, and
this document says so plainly rather than letting a clean infrastructure checklist imply more than
CP3's evidence supports.

---

## Git code

- **P2-2**: production's `calculate-commission` bundle hash (`c48517d99...97271f`) is
  **byte-for-byte identical** to `kynza-dr-scratch`'s deployed bundle for the same function —
  a cryptographic match, confirmed in CP3.
- **P2-9**: `git status --short` was clean throughout every deploy in CP2 (re-confirmed at the
  start of this checkpoint) — production's deployed content is provably exactly this repository's
  current `HEAD` for `update-remote-config`/`rollback-remote-config`. Bundle hashes differ from
  `kynza-dr-scratch`'s own snapshot, explained in CP3: dr-scratch was deployed 2026-07-05 from a
  working-tree state that evidently predates commit `d9c7613` being formalized (a "test then
  commit" workflow) — a timing/metadata artifact, not a logic divergence; the actual `is_system_
  admin` gate was read in full in CP1 and independently proven live and correct (both directions)
  in CP3.
- **P2-5**: all 16 functions' source carries the identical `checkBodySize()` call (confirmed via
  `grep -l "checkBodySize"` returning exactly 16 files, unchanged since CP1), and every one shows a
  fresh deploy timestamp (CP2). Code-level parity with git `HEAD` is real. **Behavioral parity is
  not** — see CP3.

## Applied migrations

`supabase migration list --linked` re-confirmed at the start of this checkpoint: **87 local, 87
applied, 0 unapplied** — unchanged since Go-Live Phase 3. None of the three fixes needed a new
migration (P2-2/P2-5 are pure Edge Function code; P2-9's only DB dependency, `has_system_admin()`/
`users.is_system_admin` from migration `20260704120000`, was already applied in Go-Live Phase 2 and
re-confirmed present this checkpoint via `select proname from pg_proc where proname=
'has_system_admin'`).

## Deployed Edge Functions

All 16 functions touched by the three fixes show `status: ACTIVE` and a 2026-07-06 deploy
timestamp (full table in CP2). Re-confirmed this checkpoint via a fresh `supabase functions list`
that nothing has drifted since CP2/CP3 (no redeploys or removals happened in between).

## RLS policies

Checked directly (not assumed) on every table these three fixes read or write:
`bookings`, `staff_commissions`, `staff_profiles`, `users`, `remote_config_entries`,
`remote_config_versions`, `remote_config_audit` — **RLS enabled on all of them**. Worth stating
explicitly: none of the three fixes' *enforcement* actually runs through RLS — all three Edge
Functions use `createServiceRoleClient()` (which bypasses RLS by design) and enforce their checks
in application code instead (`caller.salon_id !== booking.salon_id`, `!caller.is_system_admin`,
`checkBodySize()`). RLS parity here confirms nothing regressed elsewhere, not that RLS is the
mechanism securing these three items.

`remote_config_entries`/`remote_config_versions`/`remote_config_audit` each carry exactly one
policy — `..._authenticated_select` (`SELECT` only, role `authenticated`) — matching the migration's
own documented design ("No table policy grants authenticated INSERT/UPDATE... every write goes
through this function's validation gate first"). Confirmed via direct `pg_policies` query, not
inferred from the migration file alone.

## Roles / triggers

- `users_protect_columns` trigger: present, `tgenabled='O'` (enabled). `protect_user_columns()`
  function confirmed present. Both directly relevant to P2-9's dependency chain
  (`grant_system_admin`/`revoke_system_admin`, Go-Live Phase 2) — unaffected by, and unaffecting,
  this session's work, confirmed unchanged.
- `has_system_admin()`: present, confirmed callable (exercised live, both directions, in CP3).

## Cron jobs

**Not applicable to this scope** — confirmed by direct inspection, not assumed: `select jobname,
command from cron.job where command like '%calculate-commission%' or ... '%update-remote-config%'
or ... '%rollback-remote-config%'` returns **zero rows**. None of the three fixes' functions are
cron-invoked; all 8 real production cron jobs (`kynza-booking-reminders`,
`kynza-run-scheduled-actions`, `kynza-platform-backup`, `kynza-check-system-alerts`, plus 4
pre-existing) are untouched by this checkpoint's scope.

## Backups

**Not applicable to this scope** — none of the three fixes touch backup mechanisms
(`create-platform-backup`, `platform_backup_jobs`) at all; those were Go-Live Phase 3's scope, not
this session's.

## RPC functions

`has_system_admin()` — the only custom RPC any of the three fixes depend on — confirmed present
and, per CP3, confirmed *correctly evaluated* live (a real system_admin passes, a real non-admin
owner is rejected, both proven with the same caller identity differing only in that one flag).

## Production configuration

`supabase secrets list --project-ref hhdkjfpgaklhrhfoxlhj` re-checked this checkpoint: the same 8
secrets as before this whole closure session (`CRON_SECRET` + 7 platform defaults) — **unchanged**.
None of the three fixes required a new secret or environment variable (confirmed in CP1); none was
added, and none of the existing ones was touched.

---

## The honest bottom line

| Dimension | P2-2 | P2-9 | P2-5 |
|---|---|---|---|
| Git code matches certified source | ✅ (hash-identical) | ✅ (clean `HEAD`, logic-verified) | ✅ (code identical, all 16) |
| Migrations | N/A — none needed | ✅ dependency applied | N/A — none needed |
| Edge Functions deployed | ✅ | ✅ (first deploy) | ✅ (all 16) |
| RLS / roles / triggers | ✅ unaffected, confirmed stable | ✅ unaffected, confirmed stable | N/A |
| Cron / backups | N/A | N/A | N/A |
| RPC functions | N/A | ✅ `has_system_admin()` live-correct | N/A |
| Production config | ✅ unchanged | ✅ unchanged | ✅ unchanged |
| **Certified protection actually reproduces live** | **✅ yes (CP3)** | **✅ yes (CP3)** | **❌ no — 3/27 real attempts (CP3)** |

**"Production = Certified Backend" is true for P2-2 and P2-9 — every dimension checked, no
remaining difference found, both fixes' actual protection independently reproduced live.**

**For P2-5, production = dr-scratch (both show the same intermittent failure — confirmed in CP3,
dr-scratch's own first hit this session also failed), but neither one currently reproduces what
prior reports certified ("200KB body → 413" as a reliable guarantee). This checkpoint will not
round that up to parity.** The artifact is deployed and identical everywhere it needs to be; the
*protection it was meant to provide* is not reliably present anywhere it was tested this session.

## Next

Per the governing prompt: **STOP here.** Checkpoint 5 (Final Report Update) requires Mylord's
explicit authorization before starting, and — given the finding above — should mark P2-2 and P2-9
"Closed with Production Evidence" while P2-5 is marked precisely for what it is: redeployed,
code-parity-confirmed, but **not yet reliably validated**, pending a dedicated follow-up
investigation into the intermittent failure CP3 documented.
