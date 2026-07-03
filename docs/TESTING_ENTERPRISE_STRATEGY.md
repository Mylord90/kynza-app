# Testing Enterprise Strategy

> Phase 9 of the Enterprise Hardening pass — "extend coverage into categories not yet
> exercised, without destabilizing the existing 295+ baseline." Delivered in 2 stages: Batch A
> (5 sub-batches, offline, no live network, always part of the standard `flutter test` run) and
> Batch B (4 tests against a real, non-production Supabase project, tagged `live` and
> skip-by-default so they never destabilize the standard baseline).

## 1. Test count before/after (the acceptance criterion's literal ask)

| | Count |
|---|---|
| Before this phase (Phase 8 checkpoint) | 295 passing |
| After Batch A (golden + integration + fuzz + accessibility + offline) | 323 passing |
| After Batch B (live suites added, tagged `live`, skipped by default) | **323 passing + 4 live suites skipped** by the standard `flutter test` invocation |
| When Batch B is run explicitly (`flutter test --tags live --run-skipped test/live/`) | 7 additional assertions across 4 files, all verified passing against the real kynza-dr-scratch project |

Pass rate never decreased at any checkpoint — every batch in this phase was individually
verified with `flutter analyze` (0 issues) and `flutter test` (previous count + N) before being
committed, per this phase's own rule ("`flutter test` green after every single batch commit, not
just the final one").

## 2. One test per required category (none skipped silently)

| # | Category (from the phase brief) | Delivered as | Status |
|---|---|---|---|
| 1 | Golden tests | `test/golden/kynza_button_golden_test.dart`, `kynza_empty_state_golden_test.dart` | Done |
| 2 | Integration tests: booking flow | `test/integration/booking_flow_integration_test.dart` | Done |
| 2 | Integration tests: ProxiPay flow | `test/integration/proxipay_flow_integration_test.dart` | Done |
| 2 | Integration tests: legal acceptance gate | Already covered pre-Phase-9 — see §3 | Done (pre-existing) |
| 2 | Integration tests: offline sync | `test/integration/offline_airplane_mode_test.dart` (also satisfies #7) | Done |
| 3 | E2E: signup → book → pay | `test/live/e2e_signup_book_pay_test.dart` | Done |
| 4 | Stress/performance: concurrent booking | `test/live/booking_concurrency_stress_test.dart` | Done |
| 5 | Monkey/fuzz: 3 most complex forms | `test/fuzz/form_fuzz_test.dart` | Done |
| 6 | Accessibility: automated semantic-tree assertions | `test/accessibility/guideline_test.dart` | Done |
| 7 | Offline: airplane-mode simulation | `test/integration/offline_airplane_mode_test.dart` | Done |
| 8 | Security: replay-attack | `test/live/proxipay_replay_attack_test.dart` | Done |
| 8 | Security: RLS cross-tenant | `test/live/rls_cross_tenant_test.dart` | Done |

## 3. Deliberate deviations from the brief's literal wording, and why

**No `integration_test/` package.** The brief's deliverable line names
`test/golden/`, `integration_test/`. This repo has no `integration_test` package dependency, and
adding it would only pay off with a connected device/emulator to run `flutter drive`/`flutter
test integration_test/` against — this environment has neither (confirmed in Phase 8: no
Android/iOS device or emulator, no `windows/`/`macos`/`linux` platform folder configured, only
Windows desktop + Chrome/Edge web targets). A widget-level "integration" test using this repo's
own established convention (`ProviderScope` overrides + fake repositories — see
`test/features/legal/consent_management_screen_test.dart`, pre-existing) proves the same
collaborating-units-working-together property the brief is really asking for (booking flow's
notifier + repository + auth; ProxiPay's notifier + repository; offline flows' notifier +
connectivity + outbox) without needing a device this environment doesn't have. `test/integration/`
was used as the folder name instead — same intent, honest about the mechanism.

**Legal acceptance gate — not re-tested, cross-referenced instead.** Research before writing any
code found `test/unit/legal_acceptance_service_test.dart` already has a group named literally
"Accept-new-version gate flow (integration across service + repos)" — end-to-end coverage of
exactly this flow, built in Phase 3/6. Writing a second, near-identical test would pad the count
without adding real coverage; this phase's job was to close *actual* gaps, and the real gap in
this space was ProxiPay (zero coverage beyond a model test before this phase), not the legal
gate.

**E2E "signup" step uses the Admin API, not the public signup endpoint.** Documented in full
inside `test/live/e2e_signup_book_pay_test.dart`'s doc comment: the real public
`/auth/v1/signup` endpoint rejects IANA-reserved throwaway domains outright, and once a real
domain was used instead, Supabase's built-in (no custom SMTP configured) email service hit its
send-rate limit on the very next attempt. Configuring custom SMTP to work around this would be
activating new infrastructure without the explicit per-service approval this hardening pass's
Absolute Rules require (Rule 9) — so the test creates its "brand-new user" via the same Admin API
path `scripts/qa/seed_qa_accounts.mjs` already uses. Still a genuinely fresh, never-before-seen
user exercising the full book→pay path; just not through the public HTTP signup endpoint
specifically.

**E2E "pay" step stops at payment *initiation*, not settlement.** `create-payment` (the
client-initiated online flow a freshly-signed-up user actually hits) calls
`initiateLeapaPayment`, which — confirmed by reading `supabase/functions/_shared/leapa.ts` before
writing this test — falls back to a local `{status: "processing", sandbox: true}` stub whenever
`LEAPA_API_KEY` isn't configured (true on every project here; Leapa's account is still pending
approval). The booking's final flip to `confirmed` is driven by `leapa-webhook`, a callback from
Leapa's real servers — this test has no way to trigger that without a real Leapa sandbox
integration, and fabricating a synthetic webhook call would prove nothing about the real
integration. Asserted honestly as "payment initiated, sandbox mode."

## 4. Real findings surfaced while writing these tests (not assumed, not hidden)

- **`services` and `staff_profiles` are intentionally publicly readable** across tenants
  (`services_public_select` / `staff_profiles_public_select` policies) — the first draft of
  `rls_cross_tenant_test.dart` assumed otherwise and failed against the *real* project, which is
  exactly what a live test is for. Corrected the test, not the (correct, by-design) policy;
  landed the cross-tenant assertion against `transactions` instead, which has no such carve-out
  and is real, tenant-scoped financial data.
- **The DB-level `UNIQUE(practitioner_id, start_time)` constraint really is the race-condition
  guard** — 10 concurrent `create-booking` calls at the same slot produced exactly 1 success and
  9 real `409 slot_taken` responses from the live deployed function, not a client-side assumption.
- **ProxiPay's replay protection is real and already correct** (matching a Phase 5 finding that
  was previously verified only by reading the code, not by exercising it) — replaying the same
  `proxipay-confirm` call against the live project returns `alreadyConfirmed: true` and never
  creates a second `transactions` row.
- **Supabase's built-in email service has a real, low send-rate limit** with no custom SMTP
  configured (see §3) — worth remembering for any future phase that touches real signup flows in
  this environment.

## 5. Live-test infrastructure

- **Project**: `kynza-dr-scratch` (ref `hzjmyeptytvjmzbnsmwp`) — the same non-production scratch
  project provisioned in Phase 4 for the DR restore rehearsal, explicitly kept as a reusable
  staging target for exactly this purpose.
- **Edge functions deployed to it this phase**: `create-booking`, `proxipay-create-session`,
  `proxipay-confirm`, `create-payment` (previously only had `create-backup`, from Phase 4).
- **Seed data**: 2 independent tenants ("QA Salon A" / "QA Salon B"), each with an owner, a
  staff/practitioner, a client, and one bookable service — created by
  `scripts/qa/seed_qa_accounts.mjs` (idempotent; reads `KYNZA_SCRATCH_SERVICE_ROLE_KEY`/
  `KYNZA_SCRATCH_ANON_KEY`/`KYNZA_QA_PASSWORD` from env vars, no secrets committed).
- **Gating**: every file under `test/live/` is tagged `@Tags(['live'])`, and `dart_test.yaml`
  configures that tag with `skip: "<reason>"` — this means the tag is skipped **unconditionally**
  by default, including under a plain `--tags live` filter; the only way to actually execute them
  is `flutter test --tags live --run-skipped test/live/` with the required env vars set. This was
  verified directly (not assumed) — a probe test confirmed the exact skip/run-skipped behavior
  before any real test was written against it.

## 6. Explicitly out of scope for this phase

- **Full device-lab matrix testing** (real Android/iOS hardware across OS versions/screen sizes)
  — this environment has no device/emulator at all; out of scope for the same reason Phase 8's
  frame-timing and 200%-text-scale checks were.
- **CI wiring for the `live` tag** — these tests are documented as an on-demand, manually-invoked
  suite (matching this repo's existing pattern for the Leapa-sandbox/offline manual procedures);
  actually scheduling them in CI would need the scratch project's credentials provisioned as CI
  secrets, a decision for whoever owns CI/CD setup (Phase 10), not made unilaterally here.
- **Owner/manager/staff role E2E paths** — only the client-side signup→book→pay path was built;
  the equivalent for a staff member accepting an invitation, or an owner completing the salon
  onboarding wizard end-to-end, are real gaps a future pass could pick up using the same
  `test/live/` infrastructure (tenants, seed script, `LiveTestEnv` helper) already in place.
- **A dedicated fuzz-testing dependency** (e.g. property-based generators) — the fuzz suite uses a
  fixed, hand-picked corpus of 12 adversarial strings, not generative fuzzing. Sufficient to prove
  "garbage input never crashes the app," which was the actual property under test; a generative
  fuzzer would be a reasonable follow-up but is a bigger dependency/scope decision on its own.
- **Golden tests for full screens** — only shared widgets (`KynzaButton`, `KynzaEmptyState`) got
  new golden coverage, matching the existing convention (`KynzaLoader`, pre-existing) of testing
  small, render-stable components rather than whole screens, whose Riverpod/network-dependent
  content would make golden diffs noisy and unreliable.
