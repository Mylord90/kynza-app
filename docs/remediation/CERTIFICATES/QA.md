# QA / Testing Certificate — Remediation v1

**Verdict: PARTIALLY UNCONDITIONAL.** Real, new, verifiable improvement to test enforcement and
targeted coverage — but the underlying coverage number itself remains low and largely unaddressed,
honestly.

## Certified unconditional

- **CI now enforces the test suite on every push, for the first time ever** —
  `flutter analyze`/`flutter test` are no longer just a manually-run claim repeated across 5 prior
  passes; they're a real, automated, currently-green gate (`PHASE_4_READINESS_CLOSURES.md`).
- **Targeted regression coverage added for every code path this pass's own security fixes touched**
  that could reasonably be tested without a disproportionate new-infrastructure investment: 6 new
  live tests (`test/live/remediation_v1_security_fixes_test.dart`), covering `invitation_token`
  exposure, `v_staff_directory_public`'s column safety, `salon_id` mass-assignment, the
  `create_default_document_templates` auth check, and both cron-secret rejection paths. All 13 live
  tests (7 pre-existing + 6 new) pass against `kynza-dr-scratch`; full suite 381/381 (+ these 6
  live-tagged, skipped by default locally).
- **A real regression caught and fixed mid-pass**: Phase 2's temporary password change to a QA
  fixture would have silently broken the pre-existing live suite's sign-in assumption; found and
  corrected before calling this phase complete (`PHASE_2_SECURITY_FIXES.md`).

## Still open, not addressed this pass

- **P2-10**: overall line coverage remains 23.29%, with zero repository-layer test files anywhere
  in the codebase — no dependency-injection seam or mock exists for `SupabaseService`, confirmed
  again this pass while writing `publicSalonStaffProvider`'s would-be unit test (had to use the
  live-test pattern instead, since no seam exists to mock it). Explicitly deferred, consistent with
  2 prior passes' judgment that this needs new mocking infrastructure, not a rushed retrofit.
- **P2-6**: MANAGER/SYSTEM_ADMIN role isolation still has no dedicated QA fixture or live test.

## Evidence

`PHASE_2_SECURITY_FIXES.md`, `PHASE_4_READINESS_CLOSURES.md`, `MASTER_ISSUES_MATRIX.md` (P2-6, P2-10).
