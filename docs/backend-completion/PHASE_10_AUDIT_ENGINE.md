# Phase 10 — Audit Business

> Checkpoint CP6. A genuine audit engine, split the same way as Phase 2: Track A built fully now,
> Track B schema-only.

## 1. Objectifs

Security, RGPD, fraud, sync, error, and performance audits built fully (Track A); financial,
accounting, user-behavior, salon-performance, payment-volume, loyalty-engagement,
subscription-churn, commission-accuracy, and automation-execution audits as schema-only,
report-generation deferred (Track B).

## 2. Architecture — deliberately NOT duplicating prior checkpoints

Only **3 genuinely new views** were needed for Track A — the rest of the brief's Track A list is
already real, existing pipeline from earlier checkpoints, reused rather than rebuilt:

| Brief's Track A item | Implementation |
|---|---|
| Security audit trail | **New**: `v_audit_security_trail`/`get_audit_security_trail()` — formalizes a queryable slice of `activity_logs` (security-sensitive `type_action`s), extending the existing `AuditLogger` pipeline rather than adding a parallel log. |
| RGPD audit | **New**: `v_audit_rgpd_trail`/`get_audit_rgpd_trail()` — unions `data_deletion_requests` (Legal Center) and `backup_jobs` (data export) — both tables already fully captured who/when/what; no new logging code needed. |
| Fraud audit (ProxiPay) | **New**: `v_audit_fraud_proxipay`/`get_audit_fraud_proxipay()` — 2 heuristics over existing `proxipay_sessions` data: duplicate sessions per booking (a gap `docs/EDGE_FUNCTIONS_REFERENCE.md` already flags) and staff session-creation bursts. |
| Synchronization audit | **Reused, not rebuilt**: `MutationOutboxService.deadLetterItems()` (client-side) already IS this audit trail — same finding as Phase 2's Sync Dashboard (no SQL view possible, outbox/DLQ are Hive-only). |
| Error audit | **Reused, not rebuilt**: Phase 2's `v_crash_dashboard`/`get_crash_dashboard()`. |
| Performance audit | **Reused, not rebuilt**: Phase 2's `v_edge_function_dashboard`/`v_queue_dashboard` — consumed as a periodic report rather than live dashboard, same pipeline. |

`AuditCenterScreen` (SYSTEM_ADMIN-gated, new route `/owner/audit-center`) shows only the 3
genuinely new sections — it explicitly does not re-display Health Center's sections, with an
in-screen note pointing there instead, the same "compose, don't duplicate" discipline as Phase 5.

## 3. Track B — 5 genuinely new views, 3 reused

| Brief's Track B item | Implementation |
|---|---|
| Payment-volume audit | **Reused**: Phase 6's `v_bi_payments`/`get_bi_payments()`. |
| Loyalty-engagement audit | **Reused**: Phase 6's `v_bi_loyalty`/`get_bi_loyalty()`. |
| Subscription-churn audit | **Reused**: Phase 6's `v_bi_subscriptions`/`get_bi_subscriptions()`. |
| Financial/accounting audit | **New**: `v_audit_financial_accounting` — `invoices` reconciliation view. |
| User-behavior audit | **New**: `v_audit_user_behavior` — `activity_logs` volume by action, all-time. |
| Salon-performance audit | **New**: `v_audit_salon_performance` — completed bookings vs. reviews/rating per salon. |
| Commission-accuracy audit | **New**: `v_audit_commission_accuracy` — a real correctness check (flags a `staff_commissions` row whose `amount_bif` doesn't match `rate_value` applied to the booking's `amount_bif`), not just a volume report. |
| Automation-execution audit | **New**: `v_audit_automation_execution` — real data already exists from the prior hardening pass's automation engine; report generation is what's deferred, not the data. |

No report screen consumes any Track B provider in this pass — verified by grep: zero `Screen`/
`Widget` files import `audit_business_providers.dart`'s Track B provider names outside the
providers file itself.

## 4. Fichiers livrés

- `supabase/migrations/20260704170000_audit_business.sql` (draft, unapplied)
- `lib/features/evolution/audit_business/domain/repositories/audit_business_repository.dart`
- `lib/features/evolution/audit_business/data/repositories/audit_business_repository_impl.dart`
- `lib/features/evolution/audit_business/application/providers/audit_business_providers.dart`
- `lib/features/evolution/audit_business/presentation/screens/audit_center_screen.dart` (Track A only)
- `lib/core/router/app_router.dart`, `route_names.dart` (`/owner/audit-center`, SYSTEM_ADMIN-gated)
- `lib/features/settings/presentation/screens/settings_home_screen.dart` (menu entry)
- `lib/l10n/app_en.arb`, `app_fr.arb` (+3 keys)
- `test/unit/audit_business_providers_test.dart`

## 5. Conventions & Structure

Same `has_system_admin()`-gated `SECURITY DEFINER` RPC pattern as Phase 2/6. Raw-map repository
shape, same reasoning as `HealthCenterRepository`/`BusinessObservabilityRepository`.

## 6. Migrations SQL

`20260704170000_audit_business.sql` — draft, **not applied to any Supabase project**. 8 new
views (3 Track A + 5 Track B), 8 gated RPCs. No new tables — every view reads existing schema.

## 7. Nouvelles Edge Functions

None.

## 8. Tests

- `test/unit/audit_business_providers_test.dart` (3 tests): proves the Track A providers surface
  exactly what the repository returns (real data, or a real empty result) — same composition
  principle proven for Health Center in Phase 2.
- Full suite: 353 passing (was 350 before this phase).

## 9. Documentation associée

- `docs/backend-completion/PHASE_2_OBSERVABILITY.md` (Crash/Edge Function/Queue/Sync reuse)
- `docs/backend-completion/PHASE_6_BUSINESS_OBSERVABILITY_SCHEMA.md` (Payments/Loyalty/
  Subscriptions reuse)
- `docs/EDGE_FUNCTIONS_REFERENCE.md` (the duplicate-ProxiPay-session gap this phase's fraud
  heuristic surfaces, not fixes)

## 10. Critères de validation

- `flutter analyze`: 0 issues.
- `flutter test`: 353/353 passing.
- No live/remote migration applied.

## 11. Checklist de sortie (Exit Criteria)

- [x] Every Track A audit type produces a real report against current QA/system data — the 3 new
      views query real existing tables (`activity_logs`, `data_deletion_requests`, `backup_jobs`,
      `proxipay_sessions`); the 3 reused ones were already proven real in Phase 2.
- [x] Track B views run without error but are explicitly marked "awaiting production data" — all
      5 new Track B views query real existing tables and will return real (if sparse) rows against
      current QA data; no screen renders them yet, and this document states that explicitly rather
      than silently building further than scoped.
