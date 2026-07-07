# Checkpoint 6 — Documentation & Closure

**Date**: 2026-07-07. **Scope**: cross-reference (not rewrite) the P2-5 RCA, update the engineering
backlog / Master Issues Matrix, add the ADR this decision warrants, and state — with justification
rooted in Checkpoints 1-5's actual evidence, not assumed — whether P2-5 may be marked "Closed with
Engineering Evidence."

---

## What was updated, and why each one

### 1. `docs/p2-5-rca/FINAL_RCA_REPORT.md` — resolution note appended, nothing rewritten

Added a dated "Resolution note" section after the RCA's existing "Explicit final classification."
The RCA's own findings, evidence, and conclusions above the note are untouched — the note states
what was fixed, cites the exact Checkpoint 3/5 evidence for the closure claim, and is explicit that
the newly-discovered platform ceiling (P2-22) is an *addition* to this RCA's picture (and may be
the fuller explanation for its own "~4%, not 0%" observation), not a correction of anything the RCA
got wrong.

### 2. `docs/remediation/MASTER_ISSUES_MATRIX.md` — the Master Inventory

- **P2-5's entry**: `Status` changed from `open, tracked, no fix drafted this pass` to **`Closed
  with Engineering Evidence (2026-07-07)`**, with a summary of the fix, the shared utility it
  lives in, and the exact evidence (CP3 Section H's 100%-vs-0-20% controlled comparison, CP5's
  live production validation) — plus an explicit note that closure is scoped to the
  `Content-Length`-reliability mechanism, cross-referencing P2-22 for what remains open.
- **New entry, P2-22** added immediately after P2-21 (the next unused ID in the matrix):
  "Request bodies ≳210KB have a substantial-to-near-total chance of never reaching the Edge
  Function isolate at all, identically on any code version" — `Status: open, newly discovered, not
  fixed`. Written to the same standard as every other entry in this matrix (corroboration, impact,
  evidence, proposed-fix status), not a shorthand note.
- **Executive summary counts** updated: P2 count 21→22, closed count 0→1 (with a footnote
  explaining the 1 closure and the same-session new item so the numbers don't read as
  contradictory), total distinct issues 49→50, total closed 6→7.
- **Cross-reference section** (source document → matrix ID) given a new dated entry for
  `docs/p2-5-rca/` and `docs/p2-5-ecr/`, since both post-date the 5 passes this matrix originally
  synthesized and would otherwise be invisible to that section's own stated completeness goal.

### 3. `docs/adr/0005-streaming-body-size-guard-over-content-length.md` — new ADR

This is exactly the kind of decision the ADR directory's own README says warrants a record: a
shared utility replacing a header-trust pattern, where the "why" (an RCA's worth of evidence that
the header is unreliable, plus live testing that ruled out keeping even a partial header
dependency as an optimization) is not derivable from reading the code alone. Documents the decision,
explicitly the *rejected* alternative (keeping a `Content-Length` fast-path, which the RCA's own
text had suggested was fine to keep) and why testing overturned that, and the consequences
including the disclosed performance cost and the newly-discovered, separately-tracked P2-22.

---

## Was Checkpoint 5's evidence sufficient to close P2-5?

**Yes, for the mechanism this ECR was scoped to fix — stated with the same scoping discipline
Checkpoint 5 itself used, not a broader claim:**

- The RCA's root cause (`Content-Length` unreliable across the gateway→isolate hop, causing the old
  guard's own designed fallback to admit an unbounded body) is directly, repeatedly, and
  decisively disproven as still-present in the new code: Checkpoint 3's controlled, same-session,
  side-by-side comparison (Section H) showed the exact scenario the RCA describes — absent
  `Content-Length`, 150KB body — resolving correctly **100% of the time** (10/10, then 5/5) with
  the new guard, against **0/10 and 1/5** for the unmodified old code tested in the same window.
- Checkpoint 5 confirmed this holds on **production** itself, using the **official, unmodified**
  reproduction script and only its own pre-existing `payloadSize` parameter: **30/30 (100%)**
  correct at a size below the platform ceiling.
- The literal default-size run of the official script (2.5% combined success) does **not**, taken
  alone, meet "zero intermittent failures" — but Checkpoint 3 and Checkpoint 5 both independently
  proved, with the *unmodified pre-ECR* code as a control, that this specific shortfall is caused
  by a different, separate mechanism this ECR was never scoped to touch (`ABSOLUTE RULES`: "P2-5
  only... no modification outside the body-size guard mechanism").

Closing P2-5 without opening P2-22 would misrepresent the matrix's own accuracy standard (folding
a proven-separate mechanism into a closed item, or worse, leaving a real, newly-discovered DoS-shaped
finding untracked). Both were done together in this checkpoint, which is why they're presented as
one closure action, not two.

## Next

`FINAL_CERTIFICATION.md` — the six required OUI/NON questions, answered against everything
established in Checkpoints 1-6.
