# KYNZA — Global System Architecture

> Companion to the existing `docs/ARCHITECTURE.md` (compact overview). This document is the
> expanded, diagram-driven version: every diagram below was drawn against the actual code in
> `lib/`, `supabase/migrations/`, and `supabase/functions/` as of 2026-07-03 — not against the
> aspirational patterns described in `docs/ai/skills/*.md`, which are called out explicitly
> wherever they diverge from what's actually implemented.

## 1. Objectifs (business + technique)

Give a developer who has never touched KYNZA a single place to see how a tap in the Flutter app
becomes a row in PostgreSQL and back — across every layer, including the parts that are *not yet
built* (documented as gaps, not glossed over).

## 2. Architecture

### 2.1 Full stack

See [`docs/diagrams/architecture-layers.mermaid`](diagrams/architecture-layers.mermaid).

Key point not obvious from a generic Clean Architecture diagram: **there is no separate
datasource abstraction**. `data/repositories/*_repository_impl.dart` calls
`SupabaseService.client` directly — there's no local/remote datasource split beneath the
repository. Hive access (session flags, permission cache) also happens directly from services/
providers, not through the repository pattern at all — it's a parallel, simpler cache layer, not
part of the domain model.

### 2.2 Dependency graph

See [`docs/diagrams/dependency-diagram.mermaid`](diagrams/dependency-diagram.mermaid).

26 feature modules confirmed under `lib/features/`: `auth, automation, availability, billing,
booking, dashboard, data_platform, evolution, home_client, home_manager, home_owner, home_staff,
journey, loyalty, marketing, notifications, payment, permissions, proxipay, referral, reviews,
salon, search, services, settings, splash, staff, team`. No feature imports another feature
directly — cross-feature reads happen through Riverpod providers reading another feature's
repository interface (e.g. booking reads services), never through a direct Dart import chain
that would create a circular dependency.

**Update (Enterprise Final 100 CP1, 2026-07-05)**: this invariant was tool-verified, not just
asserted — an independent import/export reachability scanner found and fixed the 2 real
`core`↔`feature` cycles the Enterprise Certification v2 pass had identified but not fixed
(`core/providers/auth_providers.dart` and `core/providers/offline_sync_providers.dart` each split
into a core-only half and a feature/composition half — see
[`enterprise-final-100/CP1_ARCHITECTURE_BACKEND.md`](enterprise-final-100/CP1_ARCHITECTURE_BACKEND.md)
for the fix). The same scan also found `lib/shared/widgets/kynza_widgets.dart` is a genuine
barrel-export file — correcting `certification-v2/CP1_ARCHITECTURE_REVERIFY.md`'s prior claim
that no barrel files exist in this codebase.

### 2.3 Clean Architecture layering

See [`docs/diagrams/layer-diagram.mermaid`](diagrams/layer-diagram.mermaid).

Every feature follows: `presentation/ → application/ (providers) → domain/ (abstract repository)
← data/ (impl)`. **Divergences from textbook Clean Architecture** (deliberate, not accidental):

1. No datasource abstraction (§2.1).
2. Riverpod `AsyncNotifier`/providers act as both the "application" layer *and* the controller
   the screen watches directly — there's no separate use-case/interactor class per action. The
   notifier's method **is** the use case.
3. `domain/repositories` holds interfaces only; entities are the same Freezed models in
   `core/models` shared across all layers, not re-mapped per layer.

### 2.4 Representative request flow

See [`docs/diagrams/communication-diagram.mermaid`](diagrams/communication-diagram.mermaid) —
booking creation end-to-end including error paths (JWT invalid, quota exceeded, slot conflict).

### 2.5 Offline architecture — current state vs. target

See [`docs/diagrams/offline-diagram.mermaid`](diagrams/offline-diagram.mermaid).

**Important finding**: `docs/ai/skills/kynza-offline-realtime.md` (an AI-agent skill brief)
describes a full outbox-queue architecture (`HiveService`, `OutboxSyncService`,
`ConflictResolver`, encrypted `agenda_j7`/`clients_cache_readonly` boxes) — grepping the codebase
for `hive_service.dart`, `outbox_sync_service.dart`, `conflict_resolver.dart`, `realtime_service.dart`
returns **zero matches**. What's actually implemented in `lib/main.dart` today is two Hive boxes:
`kynza_prefs` (`SessionService` — session flag, role, language, confidential mode, pending
invitation/referral tokens, recent searches; **not encrypted**, no `HiveAesCipher` in use) and
`permission_cache` (`PermissionCache` — RBAC `check_permission()` results, 15-min TTL). ProxiPay
itself has **no Hive usage at all** — it is fully online, session-based via the
`proxipay_sessions` table. The full offline-first strategy for bookings/reviews/cash-payment
queues described in the skill file is a **target architecture**, not yet built. Part 11
(`docs/OFFLINE_STRATEGY.md`) treats this gap in depth.

### 2.6 Realtime architecture

See [`docs/diagrams/realtime-diagram.mermaid`](diagrams/realtime-diagram.mermaid).

Also diverges from the skill-file's hand-rolled `RealtimeService`/`.channel()` pattern: every
real consumer uses the `supabase_flutter` SDK's high-level query builder —
`SupabaseService.client.from(table).stream(primaryKey: ['id']).eq(column, value)`. Confirmed
consumers: bookings (by `client_id`, `salon_id`, `practitioner_id`), a single booking during
payment (`payment_screen.dart`), ProxiPay transactions + session (by `booking_id`/`id`), services
(by `salon_id`), staff profiles (by `salon_id`), loyalty cards (by `client_id`), marketing
contacts + promotions (by `salon_id`), notification logs (by `user_id`, ×2), owner journey (by
`salon_id`). Reconnection/backoff is entirely the SDK's default `RealtimeClient` behavior — no
app-authored reconnect/backoff code exists. Per-role scoping is achieved purely by the `.eq()`
filter value, not by a "channel per role" concept.

### 2.7 Security boundary

See [`docs/diagrams/security-diagram.mermaid`](diagrams/security-diagram.mermaid) — JWT issuance
→ RLS (`has_role()`, server-derived `salon_id`) → Edge Function service-role boundary → Vault
secrets. Full detail in `docs/SECURITY.md`; this diagram is the visual companion.

## 3. Workflow / Data Flow

Covered by §2.4 (representative flow) and Part 2 (`docs/WORKFLOWS.md`, per-role journeys — not
yet written as of this document; see Phase B).

## 4. Structure & Conventions

See `docs/ARCHITECTURE.md` §3 (directory layout, provider conventions, UI state machine) — not
duplicated here.

## 5. Contraintes & Edge Cases

- Every diagram in this document reflects **verified code paths only**. Where the codebase
  diverges from an aspirational skill-file spec (offline, realtime), the diagram shows the real
  state and calls out the target spec as a documented gap rather than silently "fixing" the
  diagram to match the aspiration.
- No diagram references a table, function, or service that doesn't exist in the current codebase.

## 6. Sécurité

See §2.7 and `docs/SECURITY.md`.

## 7. Performance

Realtime reconnection performance is entirely SDK-default (not independently tunable today) —
see Part 13 (`docs/PERFORMANCE_TARGETS.md`) for the target reconnection budget and what would
need to change to guarantee it.

## 8. Stratégie de tests

Architecture/diagram documents are not independently testable; correctness is enforced by
keeping every claim traceable to a cited file path (as done throughout this document) and by the
Global Validation Pass (Part 14) re-grepping for contradictions after all 14 parts are complete.

## 9. Documentation associée

- `docs/ARCHITECTURE.md` — compact overview (extended, not replaced, by this doc)
- `docs/SECURITY.md` — full RLS/JWT/secrets detail
- `docs/API_REFERENCE.md`, `docs/EDGE_FUNCTIONS_REFERENCE.md` — RPC/Edge Function detail
- `docs/DATABASE_ARCHITECTURE.md` — full 55-table reference (Phase A, in progress)
- `docs/OFFLINE_STRATEGY.md` — deep dive on the gap identified in §2.5 (Phase E)
- `docs/ai/skills/kynza-offline-realtime.md`, `docs/ai/skills/kynza-payments-leapa.md` — target/
  aspirational specs for AI agents; cross-referenced above with explicit gap notes, not treated
  as ground truth for "what exists today."

## 10. Critères d'acceptation

- [x] Every existing feature module (26) appears in `layer-diagram.mermaid` / `dependency-diagram.mermaid`.
- [x] Edge Functions referenced in `communication-diagram.mermaid` (create-booking, execute-workflow) and fully cataloged in Part 4.
- [x] No diagram references a table/service that doesn't exist in the codebase — cross-checked against `lib/` and `supabase/` directly, not against the skill-file specs.
- [x] Divergences from a "textbook" architecture explicitly called out (§2.3, §2.5, §2.6).

## 11. Livrables

- `docs/ARCHITECTURE_GLOBAL.md` (this file)
- `docs/diagrams/architecture-layers.mermaid`
- `docs/diagrams/dependency-diagram.mermaid`
- `docs/diagrams/layer-diagram.mermaid`
- `docs/diagrams/communication-diagram.mermaid`
- `docs/diagrams/offline-diagram.mermaid`
- `docs/diagrams/realtime-diagram.mermaid`
- `docs/diagrams/security-diagram.mermaid`
