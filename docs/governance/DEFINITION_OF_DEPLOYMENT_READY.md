# KYNZA — Definition of Deployment Ready

**Date**: 2026-07-07 (Backend Governance Phase 3). **Scope**: the specific, narrow pre-deploy
checklist for a single migration or Edge Function change — the operational gate immediately
before `supabase db push`/`supabase functions deploy` against production. Narrower than
`DEFINITION_OF_PRODUCTION_READY.md` (system-wide) or `DEFINITION_OF_DONE.md` (generic).

---

A migration or Edge Function change is **Deployment Ready** only when every item below is true,
per `BACKEND_GOVERNANCE_GUIDE.md` §2/§4:

1. ☐ Applied cleanly to `kynza-dr-scratch` with zero errors.
2. ☐ A real before/after check on `kynza-dr-scratch` proves the change does what it claims (not
   just "it ran without error").
3. ☐ Rollback procedure is written down, in full, **before** requesting approval — not drafted
   after something breaks.
4. ☐ Hard-failure and silent-failure dependencies are identified explicitly (the real precedent:
   `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §7's own "Silent-failure risk" callout
   for `CRON_SECRET` — a misordered migration that fails silently is more dangerous than one that
   errors loudly, and must be called out by name, not left implicit).
5. ☐ Mylord's explicit, per-migration or per-batch approval is given — **before** the deploy
   command runs, never retroactively.
6. ☐ For an Edge Function change touching a shared utility (`_shared/*.ts`): every function that
   imports it is included in the same deploy batch, not just the function under active
   development (`BACKEND_GOVERNANCE_GUIDE.md` §4).
7. ☐ Post-deploy, the same before/after check from item 2 is re-run against production itself,
   immediately.

**Deployment Ready is a pre-condition for deployment, not a synonym for "deployed."** A change
that satisfies items 1-6 but hasn't yet had step 5's approval is deployment-ready and *awaiting*
deployment — a distinct, real state (`Corrigé-non-déployé` in this project's existing vocabulary),
not to be conflated with either "still being built" or "already live."
