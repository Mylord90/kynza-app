# Phase 7 — A/B Testing Engine (Track B — engine ready, first experiment TBD post-launch)

> Checkpoint CP5 (part 2 of 2). The experiment infrastructure, inert until launch.

## 1. Objectifs

`experiments`/`experiment_assignments`/`experiment_events` exactly as specified, a deterministic
offline-capable assignment engine, integration with the existing Feature Flags engine (Phase 3)
rather than duplicating gating logic — and **zero live experiments** at the end of this phase.

## 2. Architecture

```
experiments             (id, key, name, hypothesis, status, variant_config_json, started_at, ended_at, deleted_at)
experiment_assignments  (id, experiment_id, user_id, variant, assigned_at)
experiment_events       (id, experiment_id, user_id, event_key, occurred_at)
```

Assignment: `ExperimentAssignmentService.assign(userId, experimentKey, variantWeights)` — a pure,
synchronous Dart function using an FNV-1a 32-bit hash of `'$userId:$experimentKey'`, bucketed
proportionally across the supplied variant weights. No `crypto` package dependency added — FNV-1a
needs no cryptographic strength, only stable, deterministic bucketing, and this codebase avoids
adding a dependency where a small, self-contained implementation suffices (same discipline as not
adding `google_maps_flutter`/`firebase_app_check` before they're actually needed).

`experiment_assignments` exists so a computed assignment can be **recorded** for later
server-side reporting — the assignment itself never requires a network round trip to determine,
satisfying "works offline" literally, not just "degrades gracefully offline."

Integration point with Phase 3 (not built as a concrete gate in this pass, since no experiment is
live): `experimentVariantProvider(experiment)` returns the deterministic variant; a future,
actually-running experiment would have its 'treatment' variant flip an existing
`role_feature_overrides`/`salon_feature_overrides`-style toggle rather than this engine
reinventing its own gating mechanism.

## 3. Workflow / Data Flow

1. `experimentsProvider` reads all experiments (authenticated read, `SYSTEM_ADMIN` write only —
   platform-wide experiment definitions, not a salon-tenant concern).
2. For any experiment, `experimentVariantProvider` computes the current user's variant
   synchronously, no network call.
3. `AbTestingNotifier.recordAssignment()`/`.recordEvent()` persist the assignment/events for
   later analysis — write-only from the client's perspective (`experiment_assignments`/
   `experiment_events` RLS: a user may only insert/read their own rows).

## 4. Fichiers livrés

- `supabase/migrations/20260704160000_ab_testing_engine.sql` (draft, unapplied)
- `lib/core/models/experiment_model.dart`
- `lib/features/evolution/ab_testing/domain/experiment_assignment_service.dart`
- `lib/features/evolution/ab_testing/domain/repositories/ab_testing_repository.dart`
- `lib/features/evolution/ab_testing/data/repositories/ab_testing_repository_impl.dart`
- `lib/features/evolution/ab_testing/application/providers/ab_testing_providers.dart`
- `test/unit/experiment_assignment_service_test.dart`

## 5. Conventions & Structure

Repository/Provider shape mirrors every other engine built in this pass. No admin UI — Track B
engine-only, explicitly no live-experiment dashboard, per the brief.

## 6. Migrations SQL / nouvelles tables

`20260704160000_ab_testing_engine.sql` — draft, **not applied to any Supabase project**. 3 new
tables exactly as specified. Seeds exactly **one** experiment, `onboarding_cta_copy`, with
`status = 'draft'` — never `'running'`, satisfying the exit criterion by construction, not by
after-the-fact discipline.

## 7. Nouvelles Edge Functions

None — assignment is computed client-side by design (no round trip needed); recording an
assignment/event is a plain RLS-gated table write, no validation complex enough to warrant an
Edge Function (unlike Remote Config's per-key JSON schema needs).

## 8. Tests

- `test/unit/experiment_assignment_service_test.dart` (6 tests): determinism across repeated
  calls, real bucketing across distinct users (not a hardcoded constant), independence across
  different experiment keys for the same user, graceful `null` on an empty variant map, a 0-weight
  variant is genuinely never assigned across 30 samples, and the function is synchronous (proving
  no network round trip is even possible, not just unused).
- Full suite: 350 passing (was 344 before Phase 6/7 combined; +6 from this phase, +0 dedicated
  from Phase 6).

## 9. Documentation associée

- `docs/backend-completion/PHASE_3_FEATURE_FLAGS_ENGINE.md` (the gating mechanism a future live
  experiment would integrate with, rather than duplicate)

## 10. Critères de validation

- `flutter analyze`: 0 issues.
- `flutter test`: 350/350 passing.
- No live/remote migration applied.

## 11. Checklist de sortie (Exit Criteria)

- [x] Assignment is deterministic and offline-capable — proven by
      `test/unit/experiment_assignment_service_test.dart` (repeated-call determinism test +
      synchronous-function test, the latter proving no network round trip is even structurally
      possible).
- [x] Zero experiments are actually running at the end of this phase (by design) — confirmed:
      the migration's only seeded row has `status = 'draft'`; no code path in this pass sets any
      experiment to `'running'`.
