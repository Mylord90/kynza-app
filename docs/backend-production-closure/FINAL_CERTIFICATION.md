# KYNZA — Backend Production Closure: Final Certification

**Date**: 2026-07-06. **Scope**: the closing verdict for the KYNZA — Backend Production Closure
prompt, answered strictly from Checkpoints 1-5's own evidence — no new testing performed to reach
these answers beyond one final round of light, safe spot-checks (small requests only; P2-5 was
not re-hammered with large payloads again, since CP3/CP4 already gathered 27 real data points and
repeating that risks compounding whatever produces its intermittent failure). Every answer is
**OUI** or **NON**.

**Final spot-check, this session**: linked to production; `supabase migration list --linked` →
0 unapplied (87/87, unchanged); `staff_profiles_public_select` still absent (P0-1 holds);
`calculate-commission` and `update-remote-config` both respond `401 unauthenticated` to a small
request in under 2 seconds (both healthy, both still carrying their fixes). `flutter analyze`:
0 issues throughout every checkpoint.

---

## 1. Existe-t-il encore une différence connue entre le backend certifié et le backend en production ?

## **OUI.**

For P2-2 and P2-9: **no** — production is byte-hash-identical (P2-2) or logic-verified-identical
(P2-9) to the certified `kynza-dr-scratch` version, and both fixes' real behavior was reproduced
live in production itself (CP3). But for **P2-5**: yes, a difference remains — not between
production's *code* and the certified code (identical everywhere, confirmed in CP4), but between
production's *actual behavior* and what was certified. Prior reports certified "200KB body → 413,
reliably." Production delivers that in only 3 of 27 real attempts. That gap is real and open.

---

## 2. Existe-t-il encore une vulnérabilité connue non corrigée ?

## **OUI.**

P2-5 (the body-size DoS) is live, real, and intermittently exploitable in production today — the
guard exists and sometimes fires, but a request with the same shape that got rejected a moment ago
can still hang for the platform's execution-time limit on the next attempt. This is a genuine,
uncorrected vulnerability, not a closed one with residual paperwork. P2-2 and P2-9 are the two
vulnerabilities this checkpoint set out to close, and both are — no other known, uncorrected
vulnerability exists within this prompt's scope.

---

## 3. Existe-t-il encore un correctif validé mais non déployé ?

## **NON.**

This is a narrower, different question than #1 and #2, and the answer is genuinely different:
every fix that was validated (dr-scratch-tested, reviewed, committed) as of the start of this
closure **is now deployed** — all 16 functions touched by P2-5, plus P2-2's and P2-9's functions,
show fresh 2026-07-06 deploy timestamps (CP2). What remains open (P2-5) is not a validated fix
sitting undeployed — it is a deployed fix whose real-world reliability doesn't match what was
validated. That is a different, and arguably harder, problem than a pending deploy, and this
document does not conflate the two.

---

## 4. Existe-t-il encore une différence entre dr-scratch et Production ?

## **NON.**

Distinct from #1 deliberately: #1 asks whether production matches what was *certified*; this asks
whether production matches `kynza-dr-scratch` *as it actually behaves today*. For P2-2 and P2-9,
both: content-identical or logic-verified-identical, confirmed in CP3/CP4. For P2-5: CP3 found
`kynza-dr-scratch`'s own first live-payload test this session **also** failed (the exact same
symptom as production), and CP4 concluded explicitly that "production = dr-scratch" for this fix —
both environments are equally, consistently unreliable. There is no *divergence* between the two
environments to close; the divergence is between both of them and the original certification claim
(answered in #1), not between each other.

---

## 5. Existe-t-il encore une dette d'ingénierie backend ?

## **OUI.**

Within this prompt's own three-item scope: **P2-5's root-cause investigation is now genuine
Category A engineering debt**, not a pending Ops action — CP3/CP4 reclassified it precisely because
a redeploy did not close it and diagnosing *why* (candidates: multi-instance edge deployment with
inconsistent `Content-Length` propagation, an upstream proxy/CDN layer, a runtime race) requires
real investigation this closure prompt was not scoped to perform ("no new feature, no architecture
change... never fix it here"). Beyond this prompt's scope, the program's pre-existing Category A
backlog (19/24 untested repositories, RLS-performance review, architecture debt, etc.) is
unchanged — real, but explicitly out of bounds for this session, per its own absolute rules.

---

## 6. Existe-t-il encore une dette de sécurité backend ?

## **OUI.**

P2-5 is, specifically, security debt — a DoS finding that remains live and intermittently
exploitable. P2-2 and P2-9 are fully closed and are not part of this debt anymore. No P0 or P1
security debt exists anywhere in this program's history as of this document (re-confirmed:
P0-1 and P1-1 both hold in production, spot-checked again this session). The remaining security
debt is exactly one item, P2 severity, precisely scoped and evidenced.

---

## 7. Le backend est-il désormais totalement synchronisé avec la production ?

## **NON.**

"Totalement" is the operative word this answer turns on. Two of the three fixes this prompt exists
to close are fully synchronized — code, config, and live behavior all match, with production
evidence (CP1-CP4). The third (P2-5) is deployed and code-synchronized but not *behaviorally*
synchronized with what was certified — a request that should reliably fail sometimes succeeds
instead (in the attacker's favor). Calling this "totally synchronized" would overstate what CP3's
27 real trials actually showed.

---

## 8. Le backend entre-t-il officiellement en phase de maintenance ?

## **NON — not yet, and this document does not round up to get there.**

Two of three fixes closing cleanly, zero P0/P1 debt anywhere, and a stable, well-evidenced backend
across four separate certification passes (Master Plan Execution, Enterprise Final 100, the Go-Live
phases, and now this closure) is real, substantial progress toward a maintenance posture. But
declaring "maintenance phase" implies the known-issues list is essentially clear or reduced to
low-priority upkeep — and a live, real, currently-exploitable DoS finding with an **undiagnosed
root cause** doesn't fit that description honestly. This is a judgment call stated plainly: the
backend is closer to maintenance than at any point in this program's history, but one specific,
open, security-relevant investigation (P2-5) keeps this answer NON rather than OUI.

---

## 9. Le développement UI/UX Premium peut-il désormais devenir la priorité principale du projet ?

## **OUI.**

This uses the same rule this whole program has applied consistently: **only a P0 or P1 gate blocks
this answer.** Zero P0 or P1 items remain open anywhere — P0-1, P1-1 closed in Go-Live Phase 1/2;
P2-2 and P2-9 (both P2) closed in this closure's CP1-CP4. P2-5 remains open but has never been more
than P2 severity, and this program's own established resolution rule (Final Production
Certification Q9, and the Final Engineering Certification before it) has never let P2/P3 debt gate
this specific question — only P0/P1 does. **Recommendation, not a requirement**: resource P2-5's
investigation in parallel with UI/UX Premium work, since it is a real, live security finding, even
though it does not block this answer.

---

## Summary table

| # | Question | Réponse |
|---|---|---|
| 1 | Différence backend certifié vs production ? | **OUI** (P2-5 only) |
| 2 | Vulnérabilité connue non corrigée ? | **OUI** (P2-5 only) |
| 3 | Correctif validé mais non déployé ? | **NON** |
| 4 | Différence dr-scratch vs Production ? | **NON** |
| 5 | Dette d'ingénierie backend ? | **OUI** (P2-5's investigation, P2 severity) |
| 6 | Dette de sécurité backend ? | **OUI** (P2-5 only, P2 severity) |
| 7 | Backend totalement synchronisé avec production ? | **NON** |
| 8 | Backend en phase de maintenance officielle ? | **NON** |
| 9 | UI/UX Premium priorité principale possible ? | **OUI** |

## What this closure pass actually accomplished

- **P2-2** (`calculate-commission` cross-tenant commission leak): closed, production-evidenced.
- **P2-9** (`update-remote-config`/`rollback-remote-config` wrong role gate): closed,
  production-evidenced, including a genuine first-time deploy (both functions were `404` before
  this pass).
- **P2-5** (body-size DoS guard): redeployed to all 16 functions, code-parity confirmed — but
  found, through real testing rather than assumption, to be unreliable in production. Not closed.
  Reclassified from an Ops item to a genuine engineering investigation. This is the single
  substantive finding of this entire closure pass, and the reason two of these nine answers are
  NON where the original prompt's own framing anticipated a clean sweep.

## What a future, explicitly-scoped session would need to close P2-5

1. Reproduce the intermittent failure with server-side visibility (Supabase project logs/traces
   for a `checkBodySize`-guarded function, not just client-side timing) to see whether the
   `Content-Length` header is actually reaching the Deno isolate on the failing attempts.
2. Test whether the failure correlates with which edge region/instance serves the request (if
   Supabase exposes that), since CP3's evidence (works occasionally, no clear pattern tied to
   cold-start or client) is most consistent with a multi-instance propagation issue.
3. Consider a defense-in-depth backstop that doesn't depend on `Content-Length` at all — e.g., a
   streaming read with an early abort past a byte threshold — as a candidate fix once the root
   cause is confirmed, not before (this closure's own rule against inventing fixes without
   evidence applies equally to any follow-up).

## Evidentiary trail

`docs/backend-production-closure/CP1_PRE_DEPLOYMENT.md`, `CP2_SAFE_REDEPLOYMENT.md`,
`CP3_LIVE_VALIDATION.md`, `CP4_PRODUCTION_PARITY.md`, `CP5_FINAL_REPORT_UPDATE.md` — this document
is the sixth and final piece, not a replacement for any of them.

This is the end of the KYNZA — Backend Production Closure prompt. No further stop required.
