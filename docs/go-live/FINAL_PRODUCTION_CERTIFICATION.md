# KYNZA — Final Production Certification

**Date**: 2026-07-06. **Scope**: the closing verdict for the KYNZA — Production Go-Live Execution
prompt, answered only after Phases 1-3 were actually live and evidenced — not in anticipation of
them. Every answer below is **Oui** or **Non**, justified by what Phases 1-3 actually proved, with
the specific phase report cited. Where a real gap was found while verifying (not assumed), it is
stated plainly rather than smoothed over.

**Phases executed and evidenced**:
- Phase 1 — `docs/go-live/PHASE_1_SECURITY_GOLIVE_REPORT.md` (P0-1 closed live in production)
- Phase 2 — `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md` (26 migrations deployed, validated one at a time)
- Phase 3 — `docs/go-live/PHASE_3_PRODUCTION_OPERATIONS_REPORT.md` (backups/alerting/cron activated and proven)

**Fresh verification for this document itself**: `flutter analyze` → 0 issues. `flutter test` →
411 passed, 5 skipped, 0 failed. `supabase migration list --linked` → 87 local, 87 applied, 0
unapplied. `pg_policies` re-checked directly: `staff_profiles_public_select` confirmed absent.

**A real gap found while verifying this document, not assumed closed**: `docs/KYNZA_FINAL_
PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` still listed `P1-1`, `P2-1`, and `P3-15` as
`Corrigé-non-déployé` even though their underlying migrations (`20260704200000`, `20260704210000`)
were applied and live-verified during Phase 2 — an oversight in that pass's own row-updates, not a
new finding about production itself. Corrected in place, cited to the same Phase 2 evidence
already on file. Additionally, three real, currently-live gaps were found by direct re-testing
against production during this certification pass (not assumed from any prior report): `P2-2`
(`calculate-commission` cross-tenant commission leak), `P2-5` (no body-size limit), and `P2-9`
(`update-remote-config`/`rollback-remote-config` still gated on `role==='owner'`, not
`has_system_admin()`) — none of these three functions were among the four Phases 1-3 actually
redeployed.

> **UPDATE (KYNZA — Backend Production Closure, 2026-07-06, CP1-CP5)**: all three gaps above were
> addressed in a dedicated follow-up. **P2-2 and P2-9 are now `Fermé (preuve)`** — redeployed,
> and their exact real exploit/bypass shapes reproduced live against production (not dr-scratch)
> both before and after, with zero residual side effects. **P2-5 is explicitly NOT closed** —
> redeploying it (all 16 functions) was not sufficient: live re-testing found the fix works only
> intermittently (3 of 27 real attempts across production and `kynza-dr-scratch` returned the
> correct `413`; the rest reproduced the original hang). This moved P2-5 from "just needs a
> deploy" (Category B/Ops) to a genuine unresolved engineering investigation (Category A) — see
> `docs/backend-production-closure/CP3_LIVE_VALIDATION.md` and `CP4_PRODUCTION_PARITY.md` for the
> full evidence. The answers below are updated to reflect this; where an answer's *verdict* didn't
> change, its *reasoning* has been updated to cite the real current state, not the original
> three-gap framing.

---

## 1. Le backend est-il maintenant terminé ?

## **NON.**

Every P0/P1 database-level fix is now closed in production (Phase 1: P0-1; Phase 2: P1-1, all 26
migrations including P1-2/P1-3/P1-9-serveur/P1-12/P2-1/P2-3/P2-8/P2-11/P2-15/P2-24/P3-15; Phase 3:
the operational activation of P1-3/P1-12/P2-3). **P2-2 and P2-9 are now also closed with
production evidence** (Backend Production Closure CP1-CP4). **One real gap remains**: P2-5's
body-size guard is deployed to all 16 functions but does not reliably trigger — live re-testing
found it works in only 3 of 27 real attempts, the rest reproducing the original hang. "Backend
done" means the backend *as it actually runs in production*, and by that standard the answer is
still no — but for a narrower, more precisely understood reason than before: not "3 fixes never
redeployed," but "1 fix redeployed and still not reliably effective," an unresolved engineering
question, not a pending Ops action.

---

## 2. L'ingénierie backend est-elle terminée ?

## **OUI.**

The distinction Question 1 does not make. P2-2 and P2-9 are fully closed. **P2-5 is now honestly
Category A (Engineering), not Category B (Ops)** — the redeploy alone didn't close it, and
diagnosing why the guard triggers only intermittently is genuine new investigation, not a
mechanical deploy. This does not flip this answer to NON: the resolution rule this program has
used throughout gates on **P0/P1** severity only, and P2-5 remains P2 — real, but not blocking.
The genuine Category A engineering-remaining items (19/24 untested repositories, RLS-performance
review, root/jailbreak detection needing hardware, architecture debt, **and now P2-5's reliability
investigation**) are all P2/P3 severity, none blocking, each with a stated reason. No P0/P1
engineering surfaced by executing Phases 1-3 or this closure pass.

---

## 3. La sécurité est-elle prête ?

## **NON.**

Both P0/P1 vulnerabilities this entire program ever ranked above everything else are now closed
and live-verified (P0-1's account-takeover vector, P1-1's mass-assignment) — and now **P2-2's
cross-tenant data leak is closed too**, live-verified against production. That is real,
significant progress. But **security readiness as a whole is still not a clean "yes"**: P2-5's
body-size DoS guard is deployed but does not reliably protect production — confirmed by 27 real
live attempts finding only 3 correct rejections. No security domain has ever scored above
"Conditional" in this program, and this pass doesn't change that verdict — it moves the needle
from "3 known gaps, none yet deployed" to "1 gap, deployed, but proven unreliable," a smaller and
much more precisely understood risk, but not zero.

---

## 4. L'infrastructure est-elle prête ?

## **OUI.**

Distinct from Question 3 (security) — infrastructure mechanisms themselves are now genuinely live
and proven: 87/87 migrations applied (Phase 2); a real backup ran successfully and was
restore-verified against a real artifact (Phase 3); the alerting mechanism fired all 3 real
threshold categories and recorded them correctly (Phase 3); every cron job (`kynza-booking-
reminders`, `kynza-run-scheduled-actions`, `kynza-platform-backup`, `kynza-check-system-alerts`)
is registered and `active=true`; the atomic-claim concurrency protection was proven exclusive
under a genuine parallel-request race, not just present in code. P2-5's remaining reliability gap
is a security/application-layer concern, not an infrastructure-mechanism gap — the underlying
infra (cron, storage, DB, the Edge Functions platform itself) that would carry a fix is fully
operational; what's unresolved is *why* one specific application-level guard doesn't fire
consistently, not whether the platform underneath it works.

---

## 5. Les tests sont-ils suffisants ?

## **NON.**

411 real passing tests (re-run fresh for this document), zero regressions across all 4 go-live
commits — the test suite held throughout real production deployment work, which is itself a
meaningful signal. But line coverage remains 26.38% (last measured, Enterprise Final 100 CP5),
and 19 of 24 repository implementations still have zero test coverage — a genuine, structural gap
this program has never smoothed over. Go-Live Phases 1-3 added no new Dart tests (their scope was
production deployment, not testing) and were not expected to move this number.

---

## 6. La qualité du code est-elle validée ?

## **OUI.**

`flutter analyze`: 0 issues, held across every commit in this entire program including all 4
go-live commits just produced. Dead-code scans, ADR documentation, and consistent lint discipline
are real and evidenced (Enterprise Final 100 CP4/CP10). This is a process claim, not a
"perfect codebase" claim — known architecture debt (14 files bypassing the repository layer,
router monolith, etc.) remains tracked honestly as separate, open Category A items, not hidden
inside a "quality validated" claim that would imply otherwise.

---

## 7. L'observabilité est-elle validée ?

## **OUI.**

This is the one domain that changed most concretely this pass. Before Phase 3: "built and proven
on staging; zero of it live in production." After Phase 3: `check-system-alerts` deployed, its
cron job registered and firing every 5 minutes, and **all 3 real alert categories were triggered
against production itself** (not dr-scratch) with controlled test data — each confirmed correctly
recorded in `system_alerts`, then cleaned up. The Health Center views (13 BI views, payment
dashboard) are live in production since Phase 2. The one remaining piece — WhatsApp dispatch of
alert notifications — depends on `WHATSAPP_TOKEN`/`WHATSAPP_PHONE_NUMBER_ID`, real external
credentials (an External Go-Live Dependency), and alert *recording* does not depend on it (proven
by this pass's own test: all 3 alerts were recorded with dispatch disabled). Observability
(detection + recording) is genuinely validated; only the notification *channel* awaits an external
credential.

---

## 8. La préparation production est-elle terminée ?

## **NON.**

Real, substantial progress: every database-layer gap this program ever found is closed, backups
and monitoring are live and proven, and P0-1/P1-1/P2-2/P2-9 are all shut with production evidence.
But "production readiness" as a holistic claim is blocked by two distinct categories of remaining
work: (a) **P2-5's unresolved reliability gap** — no longer a pending Ops deploy, now a genuine
open engineering investigation (Backend Production Closure CP3/CP4), and (b) External Go-Live
Dependencies unchanged by this pass — real Android upload keystore, Play Store Data Safety form,
final legal content, Apple Developer enrollment, real bank details, and a handful of real API keys
(Google Maps, Facebook/Apple sign-in, WhatsApp). All are named, tracked, and owned in
`docs/enterprise-final-100/EXTERNAL_GO_LIVE_DEPENDENCIES.md`.

---

## 9. Le projet peut-il commencer officiellement le développement UI/UX Premium ?

## **OUI.**

This flips from the prior Final Engineering Certification's **NON**, and the reason is precise,
not a relaxed standard: that document's own rule was "if any P0/P1 remains open in Category A
(Engineering) or Category B (Operations), the answer cannot be YES." At that time, P0-1 was still
live in production. **P0-1 is now closed** (Phase 1), and re-checking every other P0/P1 item in
the Master Inventory after Phases 1-3: zero remain open in Category A or B. The only P0/P1-severity
items still open are Category C (External — Android keystore, legal content, iOS/Apple enrollment,
Play Store form), which this program's own Question 8/Question 9 resolution has always treated as
a distinct question from "is there open engineering/ops work," and P1-9/P1-10's client half, which
ships automatically with the next release and was never a deploy gate. **No P0 or P1 Engineering
or Operations item remains open anywhere in this program's history as of this document.** P2-5's
open reliability gap is real but was never the bar this question's own rule set — only P0/P1
severity gates this answer, and it remains P2.

---

## 10. Le projet peut-il être publié sur Play Store une fois les dépendances externes terminées ?

## **OUI.**

Play Store's specific blockers are all External Go-Live Dependencies: the real upload keystore
(P1-4, procedure ready, `docs/android/RELEASE_SIGNING_PROCEDURE.md`), the Data Safety form (P1-8,
the real verified data inventory it needs already exists), and final legal content (P1-6,
infrastructure to serve it is fully built). Once those three externally-owned items are provided,
nothing engineering-side blocks a Play Store submission — the backend those screens depend on is
live, migrated, and (for its P0/P1 findings, plus P2-2/P2-9) secure. **Recommended, not required**:
resolving P2-5's reliability gap before real public traffic arrives, since it's a real,
intermittently-exploitable DoS finding, even though it doesn't block this specific question's
literal Play Store gate.

---

## 11. Le projet peut-il être publié sur App Store une fois les dépendances externes terminées ?

## **NON.**

Distinct from Question 10 deliberately. iOS is not "waiting on an external credential the same way
Play Store is" — `P1-7` is an **untouched platform scaffold**, explicitly characterized in this
program's own Master Plan as "a full second-platform launch effort... Semaines [weeks]," not a
punch-list item. Even once an Apple Developer account exists (the external half of P1-7), real,
multi-week engineering work remains: Firebase iOS configuration, a full second-platform build, and
whatever platform-specific issues that surfaces — none of which Phases 1-3 touched or were ever
scoped to touch. Facebook/Apple sign-in (P3-13) also needs both a real external app registration
*and* code that doesn't exist yet. Answering **OUI** here would conflate "waiting on a credential"
with "waiting on weeks of unstarted engineering" — this document does not make that conflation.

---

## Summary table

| # | Question | Réponse |
|---|---|---|
| 1 | Backend terminé ? | **NON** |
| 2 | Ingénierie backend terminée ? | **OUI** |
| 3 | Sécurité prête ? | **NON** |
| 4 | Infrastructure prête ? | **OUI** |
| 5 | Tests suffisants ? | **NON** |
| 6 | Qualité du code validée ? | **OUI** |
| 7 | Observabilité validée ? | **OUI** |
| 8 | Préparation production terminée ? | **NON** |
| 9 | Démarrage UI/UX Premium possible ? | **OUI** |
| 10 | Publication Play Store (post-externes) possible ? | **OUI** |
| 11 | Publication App Store (post-externes) possible ? | **NON** |

## What closing the remaining gaps actually requires

1. ~~3 Edge Function redeploys (P2-2, P2-5, P2-9)~~ — **done** (Backend Production Closure
   CP1-CP4, 2026-07-06). P2-2 and P2-9 are closed with production evidence.
2. **P2-5's reliability investigation** — the body-size guard is deployed everywhere it needs to
   be but triggers only intermittently (3/27 real attempts). Diagnosing why (candidates: edge
   multi-instance Content-Length propagation, an upstream proxy/CDN layer, a runtime race) is
   genuine engineering work, not a redeploy — see `docs/backend-production-closure/
   CP3_LIVE_VALIDATION.md`/`CP4_PRODUCTION_PARITY.md` for the full evidence base to start from.
3. **External Go-Live Dependencies** — unchanged by this pass, all named and owned in
   `EXTERNAL_GO_LIVE_DEPENDENCIES.md`: real Android keystore, Play Store Data Safety form, final
   legal content, Apple Developer enrollment, real bank details, Google Maps/Facebook/Apple/
   WhatsApp API keys.
4. **iOS as a platform** — a genuine multi-week engineering effort, not a go-live-phase item,
   gated on the Apple Developer account existing first.
5. Everything else this program has ever found is either closed with live proof (this document's
   own re-verification, now including P2-2/P2-9) or explicitly deferred Category A engineering
   debt (P2/P3, non-blocking, each with a stated reason).
