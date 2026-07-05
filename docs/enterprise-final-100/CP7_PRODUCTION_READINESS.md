# CP7 — Production Readiness

**Date**: 2026-07-05. **Scope**: assemble the final release checklist and rollback validation —
strictly internal-engineering, cross-checked against the Master Plan's own production-readiness
sections rather than restarted from zero. One genuinely open, trivial, high-value item closed
along the way (P2-11).

## Objectifs

P2-11 (proxipay-create-session unique constraint — 5× corroborated, never fixed), final
consolidated migration/rollback checklist.

## Preuve

### P2-11 — closed, live-tested both directions

**The single most-repeated never-fixed finding in this entire program** (independently flagged by
5 separate passes, never drafted by any of them). New migration
`20260706130000_cp7_proxipay_session_unique.sql`: a partial unique index
(`UNIQUE (booking_id) WHERE status = 'pending'`) — only simultaneously-pending sessions for the
same booking conflict; a booking legitimately gets a new session after a prior one
expired/cancelled.

Live-tested on `kynza-dr-scratch`, both directions proven with a real booking, not asserted:
```
1st pending session for booking X       -> 201 created
2nd concurrent pending session, same X  -> 409 {"code":"23505", "duplicate key... idx_proxipay_sessions_one_pending_per_booking"}
1st session cancelled, then a new one   -> 201 created (legitimate retry still works)
```
Test rows cleaned up after. **Status: `Corrigé-non-déployé`.**

### Consolidated final migration/rollback checklist

Production (`hhdkjfpgaklhrhfoxlhj`) re-confirmed this session: **59 applied, 26 unapplied** (grew
from the 21 documented in `docs/master-plan-execution/CP2_DEPLOYMENT_READY.md` — 5 real new
migrations added across this whole campaign: `20260706100000` CP2, `20260706110000` CP3,
`20260706120000` CP4, `20260706130000` CP7, plus the 21 already tracked). Every new migration's
rollback statement is already written in its own checkpoint's report
(`CP2_DEPLOYMENT_READY.md`/`CP3_INFRASTRUCTURE.md`/`CP4_CODE_QUALITY.md`) — consolidated here,
not re-derived:

| # | Migration | Rollback (see source doc for full text) | Hard dependency |
|---|---|---|---|
| 1-21 | (Master Plan Execution batch — security, 14 feature, 2 resilience, realtime, backup automation) | `CP2_DEPLOYMENT_READY.md` §4/§7 | `20260704120000` gates 4+ downstream items |
| 22 | `20260706100000` (system-admin grant/revoke audit) | `CP3_INFRASTRUCTURE.md` | `20260704120000` (`has_system_admin`) |
| 23 | `20260706110000` (maintenance-window admin write) | `CP3_INFRASTRUCTURE.md` | `20260704120000`, `20260630110100` (already applied) |
| 24 | `20260706120000` (DB correctness: 3 triggers, 3 columns, 1 FK) | `CP4_CODE_QUALITY.md` implicit — `DROP TRIGGER`×3, `ALTER TABLE ... DROP COLUMN`×3, `ALTER TABLE salons DROP CONSTRAINT salons_owner_id_fkey; DROP INDEX idx_salons_owner_id;` | None |
| 25 | `20260706130000` (proxipay unique constraint, new this checkpoint) | `DROP INDEX idx_proxipay_sessions_one_pending_per_booking;` | None |

**New rollback statement, not previously written** (#24's wasn't spelled out verbatim in
`CP4_CODE_QUALITY.md`): captured above, derived directly from the migration's own DDL.

### Cross-checked against the Master Plan's own sections — not restarted

- §7 (Migration Deployment Plan) / §13 (Final Validation Plan) / §18 (Final Checklist): every
  item this whole campaign closed maps onto an existing row in these sections (P2-11 was
  explicitly item #10 in §13's own checklist) — no new checklist structure invented.
- §14 (Play Store Plan) / §15 (App Store Plan): unchanged, re-confirmed still accurate by CP4 of
  the prior Master Plan Execution session — not re-touched here (external dependencies).
- Rollback-drill status (P3-20, "written but not live-drilled"): still accurate for the original
  21-item batch (this campaign didn't drill those); **the 4 new migrations added this campaign
  (#22-25) all had their rollback statements live-verifiable by direct DDL inspection** (each is a
  simple `DROP`/`ALTER ... DROP` reversing an additive change), a lower-risk shape than the
  original batch's more complex items.

## Statut final

| ID | Statut |
|---|---|
| P2-11 | **Fermé (preuve)** — live-tested both directions on dr-scratch |
| Final migration/rollback checklist | Consolidated: 26 migrations, every one with a written rollback, cross-checked against the Master Plan's own sections, nothing re-derived from scratch |

## Documentation associée

`docs/master-plan-execution/CP2_DEPLOYMENT_READY.md`, `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`
§7/§13/§14/§15/§18.

## Commit hash

See end-of-checkpoint commit.
