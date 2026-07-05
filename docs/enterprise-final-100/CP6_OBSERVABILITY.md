# CP6 — Observability

**Date**: 2026-07-05. **Scope**: confirm whether "not observable in production today" is still
true after the recent deployment-prep work, and close P2-7 (the one remaining Observability-domain
item with no fix attempted yet).

## Objectifs

P2-7 (`activity_logs.ip_address`/`device_info` not populated), production-observability status
re-confirmation.

## Preuve

### Re-confirmed: production is still not observable — exact, current reason why

`supabase migration list --linked` (production, `hhdkjfpgaklhrhfoxlhj`), re-run this session:
**84 local, 59 applied, 25 unapplied** (grew from 21 to 25 as CP2/CP3/CP4 each added one real
migration this session). The two migrations that actually matter for observability —
`20260704120000` (Health Center: 7 dashboard RPCs, `has_system_admin()`) and `20260705110000`
(payment-failure dashboard + `system_alerts` real alerting) — are both still in the unapplied set.
**Verdict unchanged, for the same reason as every prior pass**: the mechanism is built and proven
(twice, on dr-scratch, across this and the prior session), production simply doesn't have it yet,
pending Mylord's deployment approval. Nothing new needed here beyond this re-confirmation — the
work to close this gap is CP2's already-consolidated 25-migration deployment batch, not new
engineering.

### P2-7 — `activity_logs.ip_address`/`device_info`, fixed for real and live-tested

Confirmed via fresh `grep` this session: a shared `logActivity()` helper already existed
(`_shared/audit.ts`) but **was never actually called anywhere** — all 9 functions that write to
`activity_logs` (`accept-invitation`, `calculate-commission`, `claim-referral`, `create-booking`,
`create-manual-invoice`, `create-walkin-booking`, `leapa-webhook`, `mark-no-show`, `validate-qr`)
each had their own inline `.from("activity_logs").insert(...)`, none populating `ip_address`/
`device_info` despite both columns existing on the table. This is a second, related finding beyond
P2-7's own 3 named functions — the gap was systemic across all 9, not just the 3 spot-checked.

**Fixed**: `logActivity()` now takes the original `Request` and derives `ip_address` from
`x-forwarded-for` (the real client IP once behind Supabase's proxy) and `device_info` from
`user-agent`. All 9 call sites migrated to use the shared helper instead of their own inline
insert — closing the population gap and a real duplication (9 copies of the same insert shape)
in the same mechanical pass.

**Live-tested on `kynza-dr-scratch`**, not just deployed: redeployed `calculate-commission`,
invoked it for real (a genuine same-tenant completed booking, temporarily given a non-zero
commission rate, reverted after) with a distinguishable `User-Agent` header:
```
POST /functions/v1/calculate-commission (real staff JWT, User-Agent: KYNZA-CP6-live-test/1.0)
-> 200 {"success":true,"amountBif":2000}

activity_logs row: ip_address = "143.105.213.194" (real, from x-forwarded-for)
                    device_info = "KYNZA-CP6-live-test/1.0" (the exact header sent)
```
Both fields populated for the first time ever in this codebase's history — proven, not asserted.
Test mutations (`commission_rate`, the one `staff_commissions` row) reverted/removed after; the
resulting `activity_logs` row left in place as real audit history, consistent with audit logs
being append-only elsewhere in this program.

`leapa-webhook`'s call site carries a one-line note: `ip_address`/`device_info` there capture
Leapa's own webhook infrastructure, not the paying customer's device — the correct, only available
signal for a server-to-server callback, not a bug.

## Statut final

| ID | Statut |
|---|---|
| P2-7 | **Fermé (preuve)** — fixed in the shared helper, migrated all 9 call sites, live-tested end-to-end |
| Production observability | Unchanged verdict: not observable today, for the same already-known reason (2 migrations undeployed); no new gap found, nothing new required beyond the existing CP2 deployment batch |

## Documentation associée

`supabase/functions/_shared/audit.ts` (fixed + adopted), `docs/master-plan-execution/
CP2_DEPLOYMENT_READY.md` (the deployment batch that flips production observability once approved).

## Commit hash

See end-of-checkpoint commit.
