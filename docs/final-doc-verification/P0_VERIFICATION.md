# P0 Verification

**Date**: 2026-07-07. **Method**: direct, live, read-only verification against production
(`hhdkjfpgaklhrhfoxlhj`) — not inferred from any report's summary — cross-referenced against every
document that claims a P0 status, in chronological order.

---

## Identity

There is exactly **one** P0 item across every source document read for this verification:
**P0-1 — `staff_profiles_public_select` RLS policy exposes `invitation_token`/`phone` to any
unauthenticated request** (the sole credential `accept-invitation` uses to bind a caller's account
to a staff role + `salon_id` — an account-takeover vector).

It carries the same ID (`P0-1`) in both tracking documents that number it:
`docs/remediation/MASTER_ISSUES_MATRIX.md:41` and
`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:46`. No duplicate, no second P0 item, in any
document read.

## What each document claims, in chronological order

| Document | Commit / date | Claim |
|---|---|---|
| `docs/remediation/MASTER_ISSUES_MATRIX.md:96-102` | `a48d7cb`/`ed13955`, 2026-07-04 | "fix drafted + live-tested this pass, awaiting Mylord's explicit approval... **Not applied anywhere in production.**" |
| `docs/KYNZA_FINAL_ENGINEERING_CERTIFICATION.md:179-182` | `afba1be`, 2026-07-06 07:09 | "**P0-1 is still live and unpatched in production, today.** Re-verified this session via a read-only query against production... the `staff_profiles_public_select` RLS policy still exists, `roles = {public}`... no column restriction." |
| `docs/go-live/PHASE_1_SECURITY_GOLIVE_REPORT.md:1-144` | `cf1160d`, 2026-07-06 07:30 | Deploys the fix to production (20 minutes after the Engineering Certification above). Re-verifies before deploying: `pg_policies` confirms the policy "still present... the vulnerability was still live at the moment this phase began, not already fixed by an earlier pass." Post-deploy: policy dropped, `v_staff_directory_public` view live, real unauthenticated exploit attempt returns `[]`. |
| `docs/go-live/FINAL_PRODUCTION_CERTIFICATION.md:16,49` | `7e4c43c`, 2026-07-06 09:00 | "`pg_policies` re-checked directly: `staff_profiles_public_select` confirmed absent." "Every P0/P1 database-level fix is now closed in production (Phase 1: P0-1...)." |
| `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:46` | `8926e1d` (row last touched), 2026-07-06 13:45 | `Statut`: **Fermé (preuve)**. Cites both the dr-scratch live-test and the production go-live re-verification. |

**No contradiction exists between these five documents when read in chronological order.** Each is
correct as of the moment it was written: the Engineering Certification (07:09) correctly found the
vulnerability still live; Go-Live Phase 1 (07:30, 21 minutes later) correctly found it still live
immediately before deploying, then closed it; every document after 07:30 correctly reports it
closed. This is sequential supersession, not an unresolved contradiction — and
`go-live/FINAL_PRODUCTION_CERTIFICATION.md:176-177` says so explicitly in its own text ("This flips
from the prior Final Engineering Certification's **NON**... At that time, P0-1 was still live in
production. **P0-1 is now closed**").

## The actual contradiction: `MASTER_ISSUES_MATRIX.md` was never updated

The one document that is **factually wrong today**, not merely superseded-and-explained, is
`docs/remediation/MASTER_ISSUES_MATRIX.md`. Its P0-1 row (lines 96-102) still reads "Not applied
anywhere in production" as of this writing. Its last two touches were `a48d7cb` and `ed13955`, both
2026-07-04 — **it has never been edited since**, including through the 2026-07-06 go-live
deployment that closed this exact item, and including through this program's own P2-5 ECR
(2026-07-07), which edited this same file's P2-5 row and added a new P2-22 row without checking
or correcting the stale P0-1/P1-* rows already present in it. `git log --follow -- docs/remediation/MASTER_ISSUES_MATRIX.md`
confirms exactly three commits touch this file: `a48d7cb`, `ed13955` (both 2026-07-04), and
`44ce828` (2026-07-07, the P2-5 ECR's own CP6 commit) — none in between, none touching the P0-1/P1
rows.

## Direct, live re-verification performed this session (not trusting any report)

```
$ supabase db query --linked "SELECT policyname, cmd, roles, qual FROM pg_policies WHERE tablename = 'staff_profiles';"
```
Result, production, `hhdkjfpgaklhrhfoxlhj`, queried 2026-07-07: `manager_view_staff`,
`owner_manage_staff`, `staff_own_profile_select`, `staff_own_profile_update` — **`staff_profiles_public_select`
is absent.**

```
$ curl "https://hhdkjfpgaklhrhfoxlhj.supabase.co/rest/v1/staff_profiles?select=id,display_name,invitation_token,phone&limit=3" -H "apikey: <anon>"
→ HTTP 200, body: []
```
The exact repro from `MASTER_ISSUES_MATRIX.md:69-73` — re-run today, live, unauthenticated — now
returns zero rows to `anon`, not the vulnerable full-row dump the matrix still documents.

```
$ curl "https://hhdkjfpgaklhrhfoxlhj.supabase.co/rest/v1/v_staff_directory_public?select=*&limit=3" -H "apikey: <anon>"
→ HTTP 200, 2 real rows, no invitation_token/phone/invited_by field present
```
The legitimate replacement path still serves real data with the sensitive columns absent — the
fix did not break the practitioner-selection screen's data path.

## Conclusion

**P0-1 — genuinely closed, with live production evidence re-verified independently today, 2026-07-07,
not merely cited from a report.** Its status in `docs/remediation/MASTER_ISSUES_MATRIX.md` is
**closed but forgotten in the Master Inventory update** — that specific document was never touched
after the fix deployed. Its status in `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` (the
actively-maintained "Master Inventory" per `docs/KYNZA_FINAL_ENGINEERING_CERTIFICATION.md:8-11`) is
already correct (`Fermé (preuve)`).

**Proposed correction (not applied)**: update `docs/remediation/MASTER_ISSUES_MATRIX.md`'s P0-1
`Status` line (currently ending "...Not applied anywhere in production.") to state it was deployed
to production 2026-07-06 (`docs/go-live/PHASE_1_SECURITY_GOLIVE_REPORT.md`) and re-verified live
2026-07-07 (this document), citing both. Same correction needed for the executive summary counts
table at the top of that file (currently "P0 | 1 | 0" — should read "P0 | 1 | 1").
