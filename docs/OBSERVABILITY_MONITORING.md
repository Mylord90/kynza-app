# KYNZA — Observability & Monitoring

> Phase 4 of the Enterprise Hardening & Production Readiness pass. Makes failures visible
> before users report them: Crashlytics on every catch block that used to swallow errors
> silently, Firebase Performance traces on the 4 flows the phase brief named, a formal
> dead-letter queue for the offline outbox, and a Health Dashboard spec. Companion document:
> `docs/DISASTER_RECOVERY_RUNBOOK.md`.

## 1. Crashlytics — closing the silent-catch gap

The phase brief referenced a previously-documented "~40-notifier error-swallowing pattern."
Direct verification (not trusting that figure) found the real count is smaller and more
specific: **174 catch blocks exist across `lib/features/**/data/repositories/*.dart` and
`lib/features/**/application/providers/*.dart`, but 166 of them already convert the error into
an `AppException` and rethrow, or set `AsyncError` state and rethrow** — neither pattern is
silent. The actual gap was **27 truly silent catches**:

- **8** in repositories/providers — all "best-effort" fire-and-forget side effects explicitly
  commented as "must never block the primary flow": loyalty stamp award, commission
  calculation, journey-step push notification, loyalty-reward push notification, search
  logging, popular-searches fallback, an FTS-RPC-to-ILIKE fallback, and `forgotPassword`
  (deliberately silent **to the caller**, for anti-enumeration — logging to Crashlytics, a
  private ops-only sink, doesn't violate that).
- **19** `.catchError((_) {})` in the presentation layer, wrapping fire-and-forget UI mutations
  (mark no-show, remove a service, delete a notification, etc.).

**Fix applied to all 27**: added `CrashReportingService.recordError(e, st)` (or
`.catchError(CrashReportingService.recordError)` for the `.catchError` call sites) — logging
only, zero behavior change, per the phase's own constraint. `CrashReportingService` already
existed and required no new plumbing (`lib/core/services/crash_reporting_service.dart`,
wired into `main.dart`'s `runZonedGuarded` and `FlutterError.onError` since before this pass).

Full file list: `booking_providers.dart` (×2), `journey_repository_impl.dart`,
`loyalty_repository_impl.dart`, `search_repository_impl.dart` (×3), `auth_notifier.dart`,
`kynza_offline_banner.dart`, `commission_screen.dart`, `home_staff_screen.dart`,
`booking_detail_sheet.dart`, `staff_list_screen.dart` (×2), `staff_form_screen.dart` (×2),
`staff_detail_screen.dart` (×2), `notifications_screen.dart` (×3), `invite_clients_screen.dart`,
`service_form_screen.dart`, `services_list_screen.dart` (×2), `salon_creation_wizard_screen.dart`
(×2).

## 2. Firebase Performance

`firebase_performance: ^0.10.0` added to `pubspec.yaml` (was not previously a dependency — a
clean slate, no home-grown timing code existed to reconcile). Verified with an actual
`flutter build apk --release --split-per-abi` (not just `flutter analyze`/`flutter test`) —
build succeeded, and a fresh `aapt dump permissions` confirmed the release manifest gained
**zero** new permissions from the SDK (identical permission set to Phase 1's fixed baseline).

`lib/core/services/performance_monitoring_service.dart` — thin wrapper, same static/no-DI shape
as `CrashReportingService`:
- `startColdStartTrace()` / `stopColdStartTrace()` — a `cold_start` trace started as early as
  possible in `main()` (right after `Firebase.initializeApp()`) and stopped in `AuthBootGate`
  the first time the initial auth check resolves (loading → data/error) — the point the app is
  actually usable, not just rendered. This is in addition to, not instead of, the Performance
  SDK's own automatic app-start trace.
- `traceAsync<String, T>(name, action)` — wraps an action in a named trace, started before and
  stopped in a `finally` so a failed action still reports its timing (a slow failure is as worth
  measuring as a slow success).

Instrumented, per the phase brief's 4 named flows:
- **Cold start** — `main.dart` / `auth_boot_gate.dart` (above).
- **Booking creation** — `booking_repository_impl.dart`'s `createBooking`, trace name
  `booking_creation`.
- **ProxiPay payment confirmation** — `proxipay_repository_impl.dart`'s `confirmSession`, trace
  name `proxipay_payment_confirmation`.
- **Search** — `search_repository_impl.dart`'s `search`, trace name `search`.

## 3. Health Dashboard spec

Per the brief, documented as a spec with 2 new draft SQL views (not applied — Rule 8), not
necessarily a built admin screen yet:

| Metric | Source | Status |
|---|---|---|
| API latency | Firebase Performance's automatic network monitoring | Already covered — a server-side SQL view can't see client-observed latency at all, so no view was designed for this. |
| Sync queue depth | Client-local Hive storage (`LegalAcceptanceQueueService`) | **Not a SQL-view metric** — there's nothing in Postgres to query. Observed instead via Crashlytics non-fatal logs already added in §1 (every failed flush attempt is now logged) — an ops person watching Crashlytics volume for `flushQueue` failures gets an implicit queue-health signal today. A proper depth gauge would need a small client-side telemetry ping, out of scope for this phase. |
| Notification delivery rate | **New**: `public.v_notification_delivery_rate` (`supabase/migrations/20260703160000_health_dashboard_views.sql`) | Drafted, not applied. |
| Payment success rate | **New**: `public.v_payment_success_rate` (same migration) | Drafted, not applied. |
| Audit log volume | **Already exists**: `mv_audit_stats` (`20260629110000_audit_enterprise.sql`), refreshed hourly via pg_cron | No new work needed — flagged here so it isn't accidentally duplicated later. |

Both new views use `WITH (security_invoker = true)`, matching the existing
`v_salon_kpis`/`v_top_services` convention (`20260624070000_analytics_views.sql`) — they run
with the querying role's own privileges, so `transactions`' owner-only RLS and
`notification_logs`' owner/manager-salon-wide RLS still apply underneath. No privilege
escalation, no new policy needed.

Building an actual admin-facing dashboard screen on top of these views is intentionally
deferred — the brief asked for the metric definitions and their storage, not necessarily the UI.

## 4. Structured logging convention

- **Levels**: `CrashReportingService.log(message)` for breadcrumbs (non-error context leading up
  to a later crash/error), `CrashReportingService.recordError(error, stack)` for actual
  non-fatal errors (§1), and the existing `FlutterError.onError`/`PlatformDispatcher.onError`
  wiring in `CrashReportingService.init()` for fatal errors — 3 tiers, matching Crashlytics'
  own model, no new levels invented.
- **User/session context**: `CrashReportingService.setUser(userId, role)` already existed and is
  called on login — every non-fatal log in §1 is automatically attributed to the acting
  user/role in the Crashlytics console, no extra plumbing needed per call site.
- **Correlation IDs**: not implemented in this phase. Every mutating Edge Function already
  generates its own request-scoped identifiers implicitly via Postgres (e.g.
  `bookings.idempotency_key`, `transactions.idempotency_key`) — these already serve as the
  correlation key between a client-side error log and the corresponding server-side row, for
  the two flows that have them. A generic cross-cutting correlation-ID header is not currently
  threaded through Edge Functions and is out of scope here — flagged as a future improvement,
  not silently assumed to exist.

## 5. Dead-letter queue (Sync Queue / Outbox formalization)

Formalizes `LegalAcceptanceQueueService` (the only outbox in the codebase — see
`docs/LEGAL_CENTER_ARCHITECTURE.md` §1/§4 for why no other pattern existed to extend) with a
real dead-letter queue, per this phase's explicit acceptance criterion.

- `maxAttempts = 3` — an item's retry counter increments on each failed `flushQueue()` attempt
  (`LegalAcceptanceQueueService.recordFailedAttempt`); at 3 failed attempts it moves to a
  separate Hive box (`kynza_sync_dead_letter`, opened in `main.dart`) via `moveToDeadLetter` —
  removed from the pending queue (doesn't retry forever) but never deleted (doesn't vanish),
  visible via `deadLetterItems()`.
- No admin/support UI was built to browse the DLQ box in this phase (out of scope — the brief
  asked for the pattern to be "visible to support/admin," and `deadLetterItems()` is the
  documented, ready-to-wrap API for that; a screen can be added later without changing this
  service).
- **Proven, not asserted**: `test/unit/legal_acceptance_service_test.dart` — "an item that fails
  every flush attempt is moved to the DLQ after maxAttempts, removed from pending, and never
  simply vanishes" (asserts all three: not in `pending()`, present in `deadLetterItems()`, and a
  subsequent flush is a no-op — proving it doesn't loop forever). A second test proves an item
  that succeeds before `maxAttempts` never reaches the DLQ at all.

## 6. Alerting (documented thresholds, not live infra)

No live alerting infrastructure is provisioned in this phase (would require confirming a paid
Firebase/monitoring tier — out of scope without explicit sign-off, per Rule 9). Documented
thresholds for whoever wires real alerting later:

| Signal | Threshold | Where it'd hook in |
|---|---|---|
| Sync queue depth (proxy: Crashlytics non-fatal volume for `flushQueue` failures) | > 10 non-fatal logs/hour for the same error signature | Crashlytics' own alert rules (Firebase console → Crashlytics → Alerts) |
| Payment failure rate | `v_payment_success_rate.success_rate_pct` < 90% over a rolling day | A scheduled Edge Function checking the view + `send-notification` to an ops channel |
| Notification delivery rate | `v_notification_delivery_rate.delivery_rate_pct` < 80% over a rolling day | Same mechanism as above |
| Cold start p95 | > 3s | Firebase Performance's own console alerting (built into the SDK once enabled) |
| DLQ non-empty | Any item present in `kynza_sync_dead_letter` | No push-alert mechanism today (client-local Hive box, not server-visible) — flagged as a real gap; closing it needs either a periodic client→server sync of DLQ contents or moving the DLQ concept server-side in a future phase, neither of which this phase built |

## 7. Regression check

`flutter analyze` = 0 issues throughout. `flutter test`: 275/275 passing (273 baseline + 2 new
DLQ tests). A real `flutter build apk --release --split-per-abi` was run after adding
`firebase_performance` and confirmed to succeed with zero new Android permissions (§2).
