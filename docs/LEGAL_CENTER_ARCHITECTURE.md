# KYNZA — Legal Center Architecture

> Phase 3 of the Enterprise Hardening & Production Readiness pass. Closes two previously-flagged
> release-blockers — no privacy policy/ToS anywhere in the repo, and camera/photo permissions
> unaudited — for the first (legal docs); infrastructure only, zero final legal copy. Every
> seeded document body is explicitly placeholder text pending real legal review.

## 1. Scope decisions made during this phase (read before extending)

Two things in the original spec turned out not to match the codebase's actual state, discovered
through direct verification (Rule 2 — never assume) rather than by reading docs at face value:

1. **No offline outbox pattern exists to reuse.** The spec asked for legal acceptance to "queue
   like the existing ProxiPay outbox pattern" — but ProxiPay has no such pattern; it's fully
   online (confirmed by reading `lib/features/proxipay/` end to end, and independently by
   `docs/ARCHITECTURE.md` §9 and the `feature_offline`/`feature_sync` flag descriptions in
   `supabase/migrations/20260703140000_feature_flags_registry.sql`, both stating no outbox is
   implemented anywhere). Per Mylord's decision, this phase builds the **first** minimal outbox
   in the codebase (`LegalAcceptanceQueueService`, §4) — small on purpose. Phase 6 (Offline-First
   Enterprise Upgrade) is where this gets formalized with a DLQ and generalized to every other
   mutating flow; this one should be treated as the reference precedent then, not re-invented.
2. **Riverpod providers in this codebase are 100% hand-written**, despite `riverpod_generator`
   being a dependency — confirmed via `docs/ARCHITECTURE.md`: *"No `@riverpod` codegen — all
   providers are hand-written for predictability."* Every legal provider follows suit.

## 2. Data layer (migration: `supabase/migrations/20260703150000_legal_center.sql`, DRAFT)

**Not applied to the remote project** — per Rule 8, this sits as a reviewable diff pending
Mylord's explicit per-file approval, same as the 3 pre-existing drafts from the prior
documentation pass.

| Table | Soft-delete? | Notes |
|---|---|---|
| `legal_documents` | Yes | One row per document *type* (9 types: privacy_policy, terms_of_service, cookie_policy, acceptable_use_policy, refund_policy, community_guidelines, data_deletion_policy, support_policy, legal_notices). `current_version_id` FK is added via `ALTER TABLE` after `legal_document_versions` exists, resolving the circular reference. |
| `legal_document_versions` | Yes | Full history, retained forever — `is_current` flips on publish, old rows never overwritten. `UNIQUE(document_id, version_number, locale)` — a version can have an fr + en row sharing the same `version_number`. |
| `user_legal_acceptances` | **No, deliberately** | Immutable audit ledger — matches `activity_logs`/`entity_versions`/`loyalty_stamp_logs` precedent (docs/DATABASE_ARCHITECTURE.md §4: legitimate append-only tables correctly have no `deleted_at`). No UPDATE/DELETE policy exists for any role but service_role. |
| `legal_consent_settings` | Yes | Added `deleted_at` even though the original brief's column list omitted it — Rule 4 requires soft-delete on every new table, and that list also omits `created_at`/`updated_at` for every table, so it's clearly non-exhaustive shorthand, not a literal exclusion. |
| `data_deletion_requests` | Yes | User can INSERT/SELECT their own rows only — **no UPDATE policy for `authenticated`**, so a user can never self-approve their own deletion; only service_role processes status transitions. |

Seeded: all 9 document types, each with one fr + one en version (`version_number = 1`,
`is_current = true`), body explicitly marked `⚠️ PLACEHOLDER — legal review required`.

### Design note: `current_version_id` and multi-locale versions

A document version has a `locale`, but `legal_documents.current_version_id` can only point to
one row. Rather than forcing a single physical FK to represent two concurrent "current" rows (fr
+ en), `current_version_id` points at the canonical (fr) row for display/admin convenience, and
the actual freshness gate (`LegalAcceptanceService.isUpToDate`, §5) compares the specific
current-version **row id** for the user's active locale, not `version_number`. This is a
deliberate V1 simplification: if a user's app locale changes between accepting a document and the
next gate check, they may be asked to accept the other locale's version row too. A
`version_number`-based cross-locale comparison would avoid that, and is documented as the
natural next step if it's ever needed — not built now because nothing in this phase's scope
requires it yet (don't design for a hypothetical).

## 3. Domain/data layer (Dart)

- Models: `lib/core/models/legal/{legal_document,legal_document_version,user_legal_acceptance,legal_consent_setting,data_deletion_request}_model.dart` — plain Freezed models, one per table, following the existing `JsonConverter`-per-enum pattern (see `BookingStatusConverter` in `booking_model.dart` for precedent).
- Repositories: `lib/features/legal/domain/repositories/` (interfaces) + `lib/features/legal/data/repositories/` (Supabase impls) — `LegalDocumentRepository`, `UserConsentRepository` (covers both acceptances and consent toggles — the brief names only 3 repository providers total, so acceptances and consent settings share one), `DataDeletionRepository`.
- Providers: `lib/features/legal/application/providers/legal_providers.dart` — `legalDocumentRepositoryProvider`, `userConsentRepositoryProvider`, `dataDeletionRepositoryProvider`, plus read providers (`activeLegalDocumentsProvider`, `legalCurrentVersionProvider`, `legalVersionHistoryProvider`, `userLegalAcceptancesProvider`, `userLegalConsentsProvider`, `dataDeletionRequestsProvider`, `pendingPolicyUpdatesProvider`) and write notifiers (`LegalAcceptanceNotifier`, `LegalConsentNotifier`, `DataDeletionNotifier`).

## 4. Offline outbox: `LegalAcceptanceQueueService`

`lib/core/services/legal_acceptance_queue_service.dart` — a single Hive box
(`kynza_legal_acceptance_queue`), opened in `main.dart` alongside the two existing boxes. Stores
pending acceptances as a plain `List<Map<String, dynamic>>` (no `@HiveType` adapter — matches
this codebase's existing convention of storing primitives/maps directly, confirmed zero
`@HiveType` classes exist anywhere in `lib/`).

- **Store-if-offline, flush-on-reconnect, no retry limit, no dead-letter queue.** Intentionally
  minimal — Phase 6 formalizes the DLQ pattern for every flow at once, this one included.
- The flush trigger is `KynzaOfflineBanner`'s existing offline→online transition detector
  (`_handleConnectivity`) — the one place in the app that already observes this transition. One
  line added there (`ref.read(legalAcceptanceNotifierProvider.notifier).flushOfflineQueue()`), no
  new global listener introduced.
- **Proven, not asserted**: `test/unit/legal_acceptance_service_test.dart` — "a queued offline
  acceptance produces exactly one server-side write on reconnect" — using a real temp-directory
  Hive box (`Hive.init(tempDir)`), not a mock.

## 5. `LegalAcceptanceService` — the soft-gate

`lib/features/legal/application/services/legal_acceptance_service.dart`. Three responsibilities:

- `acceptVersion(...)` — writes directly to Supabase when online, or enqueues via
  `LegalAcceptanceQueueService` when offline.
- `flushQueue()` — replays every queued item; each is removed from the queue only after its
  write succeeds, so a mid-flush failure leaves the rest queued for the next flush rather than
  losing them.
- `isUpToDate(...)` — the gate check itself (see §2's design note on the row-id comparison).

`pendingPolicyUpdatesProvider` calls `isUpToDate` for every active document and returns the ones
the user hasn't accepted — this drives `PolicyUpdateNotificationBanner`.

**Soft-gate, not hard-crash**: the banner is a dismissible, non-blocking overlay (mounted once in
`AuthBootGate`, §7), never a modal that locks the user out of the app.

## 6. Screens

All under `lib/features/legal/presentation/screens/`, using the existing UI-state convention
(`AsyncValue.when(loading/error/data)` with `KynzaSkeleton`/`KynzaErrorState`/`KynzaEmptyState` —
there's no dedicated "offline" state; that's the global banner, orthogonal to screen state):

- `LegalCenterScreen` — index of all 9 active documents + links to acceptance history and support contact.
- `PolicyViewerScreen` — renders `content_markdown` as `SelectableText` for the active locale (no `flutter_markdown`/similar dependency added — the seeded placeholder content has no real markdown syntax to render, and adding a new pub dependency wasn't necessary for this phase; swapping in real rendering later is a presentation-only change, no schema impact). Shows the accept button or an "already accepted" badge depending on `isUpToDate`.
- `PolicyVersionHistoryScreen` — full version list for a document (not narrowed to `is_current` — the RLS policy intentionally allows reading any non-deleted version of an active document, since published legal text has no confidentiality concern and the screen needs history to show).
- `AcceptanceHistoryScreen` — the user's own acceptance ledger, joined client-side with document/version info via `acceptanceHistoryEntriesProvider` (an N+1 lookup, acceptable at the expected scale of ≤9 documents per user).
- `ConsentManagementScreen` — 4 fixed `SwitchListTile`s (one per `LegalConsentType`), always rendered regardless of whether a consent row exists yet (defaults to `granted: false`).
- `DataRightsScreen` — data-deletion request flow is fully wired (writes to `data_deletion_requests`, confirmation dialog, status list). **Data export has no dedicated backend in this migration** (only `data_deletion_requests` was in scope) — the export button opens `SupportContactScreen` rather than fabricating a fake success state; a real export pipeline is future work, not silently implied here.
- `SupportContactScreen` — static contact info + link to the `support-policy` document.
- `PolicyUpdateNotificationBanner` — mounted once, app-wide, in `AuthBootGate` as a `Stack` overlay shown only when authenticated (§7) — not copy-pasted into every home screen.

## 7. Routing

`RouteNames`: `legalCenter` (`/legal`), `legalDocument` (`/legal/:slug`),
`legalDocumentHistory` (`/legal/:slug/history`), `legalAcceptanceHistory`
(`/legal/my-acceptances`), `legalSupportContact` (`/legal/support-contact`),
`settingsConsent` (`/settings/consent`), `settingsDataRights` (`/settings/data-rights`) — all
unguarded (no `_RoleGuard`), reachable by every role.

Nav entry points added to the two screens that already have a real settings/account surface:
`SettingsHomeScreen` (owner) and `ClientProfileScreen` (client). **Staff and Manager home
screens have no equivalent settings/account surface to extend** — this is pre-existing tech debt
(the Manager home shell is a documented UI stub, see `project_shellroute_refactor_backlog`
memory), not a gap newly introduced here. The routes are still reachable by staff/manager via
direct navigation once such a surface exists.

`PolicyUpdateNotificationBanner` is mounted in `AuthBootGate` (`lib/core/widgets/auth_boot_gate.dart`)
as a `Stack` overlay shown only when `authNotifierProvider` resolves to `AuthAuthenticated` —
chosen because that file already handles one other global overlay concern (the FCM foreground
notification banner), so it's a consistent, single-touch integration point rather than a change
duplicated across every home/tab screen.

## 8. Tests

- `test/unit/legal_models_test.dart` — `fromSupabase` parsing + every `JsonConverter` round-trip.
- `test/unit/legal_acceptance_service_test.dart` — online/offline branching, queue flush (proven
  with a real temp Hive box, not mocked), `isUpToDate` gate logic, and an explicit
  accept-new-version integration test: *"a document starts gated, accepting the current version
  un-gates it, and an older accepted version does not un-gate a newer one."*
- `test/unit/legal_center_rls_policy_test.dart` — **a static text check of the migration SQL,
  not a live database test.** The migration isn't applied to the remote (Rule 8), and this
  environment has no local Postgres/Docker (Phase 0 §7), so a real "user A cannot read user B's
  acceptance row" proof isn't possible without applying the migration first. This test guards
  against a future edit accidentally weakening the `user_id = auth.uid()` predicate — it's a
  regression guard, not proof of runtime enforcement. **A live RLS proof is a follow-up action
  once Mylord approves applying this migration**, tracked here rather than silently assumed done.
- `test/features/legal/policy_viewer_screen_test.dart` — 5 render states: loading, load error,
  null document/version (treated as another error path), not-yet-accepted (accept button),
  already-accepted (badge).
- `test/features/legal/consent_management_screen_test.dart` — loading, error, and content
  states. **No distinct empty/content-size-split states** — this screen always renders exactly 4
  fixed toggles regardless of data length, so that part of the "5 states" convention (designed
  for data-driven lists) doesn't apply here; documented in the test file rather than forced.

**Known gap, not attempted**: a `LegalConsentNotifier`/`DataDeletionNotifier` unit test that
exercises the notifier directly throws `AssertionError: You must initialize the supabase instance`
— every `AsyncNotifier` in this codebase that reads `SupabaseService.auth.currentUser` directly
(an established, pre-existing pattern, e.g. `ClientProfileNotifier`) is untestable without a real
Supabase test-bootstrap, which doesn't exist anywhere in this test suite today. This is a
pre-existing gap this phase exposed, not introduced — worth a line item in Phase 9 (Testing
Enterprise Expansion), tracked in `docs/PRODUCTION_CHECKLIST.md`.

Total: 244 baseline + 29 new = **273 tests, all passing**. `flutter analyze` stayed at 0 issues
throughout.

## 9. Acceptance criteria check (from the phase brief)

- [x] Zero legal copy is asserted as final — every seeded document body is explicitly marked
      `⚠️ PLACEHOLDER — legal review required`.
- [x] A user can accept a doc offline and it syncs on reconnect — proven by test
      (`legal_acceptance_service_test.dart`), not assertion.
- [ ] ~~RLS proven: a user cannot read another user's `user_legal_acceptances` row (test it)~~ —
      **only a static SQL-text guard exists, not a live proof** (§8). Flagged explicitly rather
      than checked off dishonestly; closing this requires applying the migration first, which is
      Mylord's call per Rule 8, not this phase's to make unilaterally.
