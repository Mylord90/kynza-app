# Phase 6 — Business Observability (Track B — schema/pipeline only)

> Checkpoint CP5 (part 1 of 2). Dashboards intentionally deferred to post-launch — this phase
> makes sure the data model exists so building them later is a UI task, not a data-modeling task.

## 1. Objectifs

SQL views/pipelines covering revenue, salons, staff, clients, subscriptions, commissions,
bookings, cancellations, payments, loyalty engagement, referrals, growth, conversion, activation,
retention, cohorts, LTV, ARPU, MRR, ARR, churn, and revenue-forecast inputs — **no dashboard
screens in this phase.**

## 2. Architecture

13 views over existing tables only (`bookings`, `transactions`, `salons`, `subscription_plans`,
`invoices`, `staff_commissions`, `referrals`, `loyalty_cards`, `owner_journey_progress`) — no new
raw data collection, per the brief's own instruction. Each is exposed through a `SECURITY DEFINER`
`get_bi_*()` RPC gated by `has_system_admin()`, identical enforcement shape to Phase 2's
dashboards (no view granted directly to `authenticated`/`anon`). A minimal Flutter Repository/
Provider layer (`business_observability_providers.dart`) wraps each RPC — **no screen watches any
of them in this pass**, consistent with Track B.

## 3. The ~21 named metrics → 13 views (consolidated, not dropped)

| Brief's named metric(s) | View | Real today? |
|---|---|---|
| Revenue, ARPU, revenue forecast inputs | `v_bi_revenue` | Yes — `transactions` where `status='completed'`, monthly. |
| Salons (active/churned), growth | `v_bi_salons` | Yes — `salons.plan_status`/`created_at`. Churn here is a **point-in-time proxy** (current `expired` count), not a true cohort churn rate — no historical `plan_status` snapshot table exists to compute that properly; documented, not conflated. |
| Staff | `v_bi_staff` | Yes — `staff_profiles`. |
| Clients, retention | `v_bi_clients` | Yes — repeat-booking rate within a 90-day window, from `bookings`. |
| Subscriptions, MRR, ARR, churn | `v_bi_subscriptions` | Yes — `subscription_plans` × `salons`. Same churn caveat as salons above. |
| Commissions | `v_bi_commissions` | Yes — `staff_commissions`, monthly by status. |
| Bookings, cancellations | `v_bi_bookings` | Yes — `bookings`, monthly by status + cancellation rate. |
| Payments | `v_bi_payments` | Yes — `transactions`, monthly by status/method. |
| Loyalty engagement | `v_bi_loyalty` | Yes — `loyalty_cards` averages. |
| Referrals | `v_bi_referrals` | Yes — `referrals` funnel by status. |
| Activation | `v_bi_activation` | Yes — `owner_journey_progress.step_first_booking_done`, already tracked. |
| Cohorts, LTV | `v_bi_ltv` | Yes for LTV (per-client lifetime `transactions` sum). **Cohorts** (retention curve by signup month) would need this joined against `v_bi_salons.signup_month` — not built as a 14th view in this pass; the join is straightforward once real data exists to make it worth doing (near-empty today either way). |
| Conversion | `v_bi_conversion` | **No.** No visit/funnel-event tracking table exists anywhere in this codebase, and this phase's own constraint ("no new raw data collection... since KYNZA doesn't yet generate the volume that would justify a new event-tracking pipeline") means this view structurally returns zero rows always (`WHERE false`) rather than fabricating a metric. Building this for real requires a client-side event pipeline — explicitly out of this phase. |

## 4. Fichiers livrés

- `supabase/migrations/20260704150000_business_observability_schema.sql` (draft, unapplied)
- `lib/features/evolution/business_observability/domain/repositories/business_observability_repository.dart`
- `lib/features/evolution/business_observability/data/repositories/business_observability_repository_impl.dart`
- `lib/features/evolution/business_observability/application/providers/business_observability_providers.dart`

## 5. Conventions & Structure

Same Repository/Provider shape as `HealthCenterRepository` (Phase 2/5) — raw `Map<String,
dynamic>` rows, not typed Freezed models, since these are internal/reporting-only and each view
has a distinct shape.

## 6. Migrations SQL / nouvelles tables

`20260704150000_business_observability_schema.sql` — draft, **not applied to any Supabase
project**. 13 views, 13 gated RPCs. No new tables.

## 7. Nouvelles Edge Functions

None.

## 8. Tests

None dedicated — Track B, no UI to test, and the RPC-wrapping repository pattern is already
covered by Phase 2's `health_center_dashboards_test.dart` precedent (same shape, not re-proven
here).

## 9. Documentation associée

- `docs/backend-completion/PHASE_2_OBSERVABILITY.md` (the `has_system_admin()` gating pattern
  reused here)

## 10. Critères de validation

- `flutter analyze`: 0 issues.
- `flutter test`: 350/350 passing (shared count with Phase 7, same checkpoint).
- No live/remote migration applied.

## 11. Checklist de sortie (Exit Criteria)

- [x] Every metric listed has a corresponding view/query that runs without error against current
      (even near-empty) data — confirmed per §3 (12 real views + 1 structurally-empty-by-design
      `v_bi_conversion`, which itself runs without error, just always returns zero rows).
- [x] Document explicitly states the activation trigger for building the dashboard UI later —
      **once KYNZA has its first ~10 live salons with 30+ days of booking history**, these 13
      views become worth building screens on top of; before that, every number would be near-zero
      or a single data point, which is why Track B defers the UI, not the data model.
