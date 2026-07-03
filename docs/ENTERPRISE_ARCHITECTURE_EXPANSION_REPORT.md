# KYNZA — Enterprise Architecture & Documentation Expansion: Final Report

> Completed 2026-07-03, across 6 phases (A–F), each checked in with the user before continuing.
> Zero changes to existing business logic, screens, or passing tests — `flutter analyze` stayed
> at 0 issues and `flutter test` stayed at 244/244 passing throughout every phase.

## 1. What was created

**23 new documents** (14 primary Part deliverables + 2 wrap-up docs + `docs/security/` as a new
subfolder), **15 Mermaid diagrams** (all independently syntax-validated with `mmdc`, including 3
real syntax errors found and fixed during validation — see §4), **3 draft SQL migrations + 1 draft
seed script** (none applied to the remote project), **13 new empty asset folders**, and
**2 pre-existing documents extended in place** (`SECURITY.md`, `PRODUCTION_CHECKLIST.md`) via
appended, dated sections rather than rewrites. Full file-by-file list:
[`DOCUMENTATION_INDEX.md`](DOCUMENTATION_INDEX.md).

## 2. What was flagged as tech debt

Every gap below is tracked in `PRODUCTION_CHECKLIST.md`'s dated "Update" sections. The highest-
priority ones, in rough order of real-world impact:

1. **🔴 Candidate release-blocker**: the release `AndroidManifest.xml` declares zero
   `<uses-permission>` entries, including `INTERNET` — only present in debug/profile manifests.
   Not confirmed against an actual built/merged manifest in this pass; recommend testing before
   the next Play Store submission.
2. **No privacy policy or terms of service exists anywhere in the repo** — a hard requirement for
   both Play Store and App Store submission.
3. **Camera/photo-library permissions missing on both platforms** despite `image_picker`/
   `mobile_scanner` being live, in-use dependencies (ProxiPay scan, loyalty scan, photo upload) —
   iOS will hard-crash on first access without the `Info.plist` keys.
4. **No offline outbox/local-cache system exists** — only two unencrypted Hive boxes. Every
   mutating flow requires network; a cold offline start renders nothing for most screens.
5. **`PermissionGuard` and `evaluate_feature_flag()` are both fully built but wired into zero
   screens** — all real access control today is coarse role-level (`_RoleGuard`) plus RLS.
6. **The Manager home shell is a verified UI stub** — same 5-tab nav as Owner, every tab renders
   the same static empty state.
7. **CLIENT_SUPPORT doesn't exist as a role at any layer** — enum, router guard, or DB constraint.
8. **No CI/CD pipeline exists at all** — blocks automated testing, dependency scanning, and any
   future performance regression gate.
9. **No certificate pinning, Hive encryption, biometric auth, or root/jailbreak detection** —
   all confirmed absent, none partially started.
10. **`check-subscription` doesn't exist** — a paid plan that lapses is never auto-reverted to
    free.
11. Several smaller, table-level gaps from the Part 3 database audit (missing `deleted_at` on 3
    tables, missing `updated_at` triggers on 3 tables, missing FK indexes on 5 tables) — all with
    a drafted, unapplied fix migration.

## 3. What was intentionally left out of scope — with justification

- **No live production-database read was performed** (Part 5 pricing/category grounding, Part 3
  schema audit) — reading real customer/salon financial or personal data for a documentation task
  was judged out of scope without explicit sign-off. All schema facts came from migration files
  (100% reliable, since they define the schema); pricing/category seed content is extrapolated
  from one verified test fixture, explicitly flagged as needing owner review before trusting it.
- **No new Flutter screens were built** — Part 5's "Add service from template" picker, Part 6's
  feature-flag-gated UI, and Part 2's fine-grained permission-gated UI are all *designed* (data
  model + intended flow documented) but not implemented, since this pass's mandate was
  documentation and additive schema/data, not new application code.
- **No actual `flutter build apk --release` was run** to confirm the AndroidManifest finding
  against a real merged manifest — flagged as a high-confidence but not 100%-certain finding,
  with the exact verification step named for you to run.
- **3 of 4 drafted SQL files were not applied to the remote**, per your explicit decision before
  this pass began (no local Supabase/Docker stack; `db push` always hits the live project). The
  4th (`20260703140000_feature_flags_registry.sql`, data-only) was flagged as lower-risk and left
  for your call rather than assumed safe to auto-apply.
- **`docs/ai/skills/*.md` files were read and cross-referenced but never edited** — they're
  outside this pass's file ownership (AI-agent-facing companion docs, not the enterprise
  documentation deliverables requested), even where their content was found to have drifted from
  real code (offline architecture, payments refund flow, design-system component variants,
  permission-resolution schema). Every drift found was noted in the relevant new document instead.

## 4. Process notes worth knowing

- **Three real Mermaid syntax errors were caught and fixed** during validation, not before: a
  stray semicolon inside sequence-diagram message text (twice, in `communication-diagram.mermaid`
  and `realtime-diagram.mermaid` — Mermaid's sequence-diagram grammar treats `;` as a statement
  separator inside message text) and an invalid pseudo-attribute row format in `erd.mermaid`'s
  entity blocks (a bare quoted string isn't a valid attribute `type`). All 15 diagrams now render
  cleanly via `mmdc`, independently re-verified at the end of this pass, not just at time of
  authoring.
- **One arithmetic error was caught and corrected before finalizing**: Part 10's hand-computed
  WCAG contrast ratios initially mis-stated one pair (`textSecondary` on `surface`) as passing
  AAA; a recheck found it's actually ~6.9:1, just under the 7:1 AAA threshold. Fixed, and the
  section now explicitly notes these are manual calculations, not tool-verified.
- **Several findings materially changed the shape of a deliverable from what the original brief
  assumed**, each documented at the point of divergence rather than silently reinterpreted:
  - Part 3: 55 real tables, not ~47.
  - Part 4: `check-subscription` doesn't exist; `run-scheduled-actions` does (unnamed in the
    brief).
  - Part 5: the brief's proposed `services` schema is the *existing* salon-scoped table — a new
    global `service_templates` catalog was introduced instead of seeding fake salon data.
  - Part 6: `leapa_enabled` doesn't exist — Leapa is unconditionally live via secrets, not a flag.
  - Part 7: several named APIs (Google Maps, Firebase Analytics, local notifications, BLE, NFC)
    have zero matching code.
  - Part 2: CLIENT_SUPPORT isn't implemented at all.

## 5. Verification performed

- `flutter analyze`: 0 issues, checked after every phase.
- `flutter test`: 244/244 passing, checked after every phase.
- Forbidden-string sweep (`€`, `$`, `SalonYawe`, `BackdropFilter`) across every new `.md`/`.sql`
  file: clean — only expected "documenting the never-use rule" mentions remain.
- All 15 Mermaid diagrams: independently re-validated with `mmdc` at the end of this pass.
- Heading hierarchy: all 14 primary new documents have exactly one H1.
- Cross-link check: every `docs/...` and `diagrams/...` path referenced across all new documents
  was checked to exist on disk — zero broken references found.

## 6. Suggested next steps (not part of this pass, offered for your prioritization)

1. Confirm/fix the `AndroidManifest.xml` permissions gap before any release build.
2. Draft a privacy policy and terms of service — required for both stores regardless of anything
   else in this report.
3. Review and decide whether to apply the 4 drafted SQL files (`DOCUMENTATION_INDEX.md` §"apply
   status").
4. Decide whether to invest in the offline outbox system (Part 11) or explicitly de-scope it from
   the product's stated offline-first goal.
5. Wire `PermissionGuard`/`evaluate_feature_flag()` into at least one real screen each, or
   consciously decide they're infrastructure-for-later and document that decision.
