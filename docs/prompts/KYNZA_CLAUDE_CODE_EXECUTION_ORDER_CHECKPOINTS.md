# KYNZA â Backend Enterprise Completion: Autonomous Execution Order
### Prepend/attach this to `KYNZA_CLAUDE_CODE_PROMPT_BACKEND_ENTERPRISE_COMPLETION.md` â one continuous Claude Code run

---

## INSTRUCTION TO CLAUDE CODE

Execute the full Backend Enterprise Completion prompt (Phases 1-11) **autonomously, end to end,
in a single continuous session**, grouped into the 7 checkpoints below. Do not stop to ask
Mylord between checkpoints. Move from one checkpoint straight into the next **as soon as, and
only if,** the current checkpoint's gate passes. If a gate fails, stop immediately, do not
proceed to the next checkpoint, and report the failure with full diagnostic output.

This is the same phase content already specified in the main prompt â this document only defines
**grouping, gating, and continuation behavior**. Do not skip, reorder, or merge checkpoints
beyond what's specified here.

---

## CHECKPOINT MAP

```
CP1 â Phase 1                    (Backend Enterprise Final Audit)
CP2 â Phase 3 + Phase 4          (Feature Flags Engine + Remote Config Engine)
CP3 â Phase 2 + Phase 5          (Observability Track A + Health Center)
CP4 â Phase 8 + Phase 9          (Configuration Engine coverage + CMS Enterprise)
CP5 â Phase 6 + Phase 7          (Business Observability schema + A/B Testing engine â Track B, schema/engine only, no UI/live experiments)
CP6 â Phase 10                   (Audit Business â Track A live, Track B schema-only)
CP7 â Phase 11                   (Backend Completion Checklist â final gate)
```

---

## MANDATORY LOOP â REPEAT FOR EACH CHECKPOINT (CP1 â CP7, IN ORDER)

**1. Execute** the checkpoint's phase(s) exactly per their spec in the main prompt (objectives,
architecture, files, migrations, Edge Functions, tests, documentation â all of it, not a subset).

**2. Self-gate before committing.** Run and paste real output for every one of these, no
exceptions:
- `flutter analyze` â must be 0 issues.
- `flutter test` â must be 100% green, report the new total test count.
- Confirm every Exit Criteria checkbox listed for this checkpoint's phase(s) in the main prompt
  â mark each â only with evidence (a command output, a test name, a file path), never by
  assertion.
- Confirm no live/remote Supabase migration was applied without explicit prior approval (draft
  files only, per Rule 8 of the main prompt).
- Confirm Track B items in this checkpoint (if any) are schema/engine-only with no dashboard/
  live-experiment UI accidentally built beyond scope.

**3. If the gate fails:** stop. Do not commit. Do not proceed to the next checkpoint. Write a
failure report (`docs/backend-completion/CHECKPOINT_<N>_FAILURE.md`) with the exact command
output that failed, revert any partial change that broke the gate, and end the session there for
Mylord to review.

**4. If the gate passes:** commit with this exact message format:

```
feat(backend-completion): CP<N> â <short summary of phase(s)>

Phases: <Phase X[, Phase Y]>
flutter analyze: 0 issues
flutter test: <total> passing (was <previous total>)
Exit criteria: all confirmed with evidence â see docs/backend-completion/PHASE_<N>_*.md
```

**5. Write the checkpoint report** at `docs/backend-completion/CHECKPOINT_<N>_REPORT.md`
summarizing what was built, the gate evidence, and the commit hash.

**6. Immediately continue to the next checkpoint** in the same session â no pause, no request
for confirmation, unless CP7 has just completed (see below) or a gate has failed (see step 3).

---

## AFTER CP7 (FINAL CHECKPOINT)

- Tag the final commit: `git tag backend-complete-v1`.
- Produce `docs/backend-completion/BACKEND_COMPLETION_FINAL_SUMMARY.md`: one table listing
  CP1-CP7, their commit hashes, test counts at each step (proving the count only ever grew or
  held steady, never dropped), and a final honest statement of what remains outside this prompt's
  scope (UI Premium, final legal content, marketing assets, Leapa go-live, Google Maps go-live,
  Play Store / App Store submission â plus every Track B item explicitly still queued for
  post-launch).
- Update `docs/DOCUMENTATION_INDEX.md` and `docs/PRODUCTION_CHECKLIST.md` to reference every new
  document from this run.
- Stop. Do not start any Track B UI/dashboard/experiment work beyond what was explicitly scoped
  as schema/engine-only, even if it looks like a natural continuation â that decision belongs to
  Mylord post-launch, not to this run.

---

## HARD RULES FOR THIS AUTONOMOUS RUN

- Never merge two checkpoints into one commit, even if both gates would pass â the commit
  history must show 7 distinct, individually revertible checkpoints.
- Never silently skip a failed test to keep momentum â a red test always stops the run at that
  checkpoint.
- Never expand Track B scope during CP5 or CP6 "since it's already in context" â schema/engine
  only means schema/engine only, checked explicitly at each of those two checkpoints' gates.
- If at any point a phase's spec in the main prompt is ambiguous enough to block execution
  (not just a minor judgment call), stop and report rather than guessing â this is the one
  exception to "never pause between checkpoints."
