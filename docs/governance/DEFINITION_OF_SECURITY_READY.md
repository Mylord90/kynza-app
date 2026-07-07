# KYNZA — Definition of Security Ready

**Date**: 2026-07-07 (Backend Governance Phase 3). **Scope**: when a specific security finding —
or the backend as a whole — may be called security-ready. Narrower than
`DEFINITION_OF_PRODUCTION_READY.md` (which covers non-security readiness too).

---

## Per-finding security-ready bar

A specific vulnerability/finding is security-ready (closeable) only when, per
`BACKEND_GOVERNANCE_GUIDE.md` §5.3:
1. A real, direct exploit attempt against the finding was performed **before** the fix, confirming
   it's genuinely exploitable (not assumed from reading the policy/code).
2. The fix is deployed to the environment that matters (production, if the finding has production
   impact).
3. The **exact same exploit attempt** is re-run **after** the fix, against that same environment,
   and fails as expected.
4. A legitimate, adjacent code path is also re-checked to confirm the fix didn't silently break
   real functionality (the concrete precedent: P0-1's fix was re-verified not just to block the
   exploit but to confirm `v_staff_directory_public` still serves the practitioner-selection
   screen's real data).

A finding closed on code review alone, a passing unit test alone, or "the logic looks correct" is
**not** security-ready by this definition — every real security closure in this project's history
(P0-1, P1-1, P2-1, P2-2, P2-3, P2-9, P2-5) met the full four-point bar above, not a subset.

## Backend-wide security-ready bar

The backend as a whole is security-ready only when:
1. Zero P0-severity findings are open (per `BACKEND_GOVERNANCE_GUIDE.md` §5.2's criteria) —
   **currently true**, verified live 2026-07-07 (`docs/final-doc-verification/P0_VERIFICATION.md`).
2. Zero P1-severity findings are open in Categories A/B (Engineering/Operations) — External
   Dependencies (Category C) do not block this status, since they are not engineering gaps.
   **Currently true** — the only 4 open P1s are all External Dependencies
   (`docs/final-doc-verification/P1_VERIFICATION.md`).
3. Every open P2/P3 security-relevant finding is explicitly tracked with a stated reason it isn't
   blocking (per the existing Master Inventory convention) — not silently ignored.

**This project's own history has never called security "unconditionally ready"** — every
certification pass that scored security capped it at "Conditional" even when every P0/P1 was
closed, because the four criteria above describe *known* findings being closed, not a guarantee no
*unknown* finding exists. This definition preserves that honesty: "security ready" here means
"every known finding meeting the bar above is closed," not "provably secure."

## Current status (evidence-cited, re-verifiable)

Per the two criteria above: **backend-wide security-ready, as narrowly defined here, is currently
met** — 0 P0 open, 0 P1 open in Category A/B, re-verified live 2026-07-07. This does not mean "no
future finding will ever surface" — it means every finding this project's history has actually
discovered and confirmed is closed to the evidence standard above.
