# KYNZA — Feature Flags Registry

> Backed by the real `feature_flags` table (`supabase/migrations/20260630110000_phase4_feature_flags.sql`).
> Every flag below is cross-checked against actual code — flags for capabilities that don't exist
> in this repo are marked **NOT IMPLEMENTED**, not silently assumed to work.

## 1. Real schema (as deployed, not as originally assumed)

```
feature_flags          (id, key UNIQUE, name, description, is_enabled BOOLEAN,
                         rollout_percentage INT 0-100, created_at, updated_at)
salon_feature_overrides (id, salon_id, flag_key → feature_flags.key,
                         is_enabled, UNIQUE(salon_id, flag_key))
```

**Scope is only ever global or per-salon** — there is no per-user column anywhere in this schema.
Any flag documented below as "per-user" in spirit (e.g. a UI preference) is not actually
enforceable at the per-user level by this table; it would need its own mechanism.

**Evaluation**: RPC `evaluate_feature_flag(p_key)` — deterministic rollout bucketing via
`md5(salon_id || key)`, checking `salon_feature_overrides` first, falling back to the global
`feature_flags` row. Called from Flutter via `FeatureFlagRepositoryImpl.evaluateFlag(key)`
(`lib/features/evolution/feature_flags/data/repositories/feature_flag_repository_impl.dart`).

**Important finding**: `evaluateFlag()` is defined and functional, but a repo-wide search found
it is **called from nowhere except its own repository file** — no screen in the app actually
gates its UI or behavior on any flag's evaluated value today. `FeatureFlagScreen`
(`lib/features/evolution/feature_flags/presentation/screens/feature_flag_screen.dart`) is an
**owner-facing admin CRUD screen** that calls `getFlags()` to list/toggle flags — it does not
itself change what any other screen does. This mirrors the `PermissionGuard`-is-unwired finding
from Part 2 (`docs/WORKFLOWS.md` §2.5): the infrastructure is real, the wiring into actual
feature gates is not yet built anywhere. Every "Flutter read path" cell below reflects this
honestly.

## 2. Pre-existing seeded flags (5, already live)

| Key | Default | Rollout | Real Flutter read path |
|---|---|---|---|
| `advanced_analytics` | disabled | 100% | None — `evaluateFlag()` uncalled |
| `ai_scheduling` | disabled | 100% | None |
| `multi_location` | disabled | 0% | None |
| `client_app_v2` | disabled | 0% | None |
| `instant_booking` | enabled | 100% | None |

None of these 5 gate anything today either — confirmed by the same repo-wide search.

## 3. Registry — 27 flags from the brief

For every flag: name, description, default, scope, real Flutter read path, and fallback UX. A
draft migration adding the missing ones is at
`supabase/migrations/20260703140000_feature_flags_registry.sql` (**not applied** — see §8).

| Key | Default | Status | Fallback UX if disabled |
|---|---|---|---|
| `feature_google_maps` | off, 0% | **Scaffolded, inert (Phase 7 of the Enterprise Hardening pass)** — repository interfaces + gated impls exist (`lib/features/maps/`), but no `google_maps_flutter`/`geolocator`/`geocoding` package is installed and no API key is configured; every method either returns null/empty (gate off) or throws `UnimplementedError` (gate on, but still no SDK) — see `docs/GOOGLE_MAPS_ARCHITECTURE.md` | Already satisfied today, not new work: `AdvancedSearchScreen` is purely list-based and `SalonLocationStep` is purely manual entry — there is no map/autocomplete UI to fall back *from* yet |
| `feature_proxipay` | on, 100% | Live (`proxipay_sessions`, `proxipay-create-session`, `proxipay-confirm`) | If disabled: hide the "Payer sur place" entry point, fall back to Mobile Money only — never show a broken QR screen |
| `feature_ble` | off, 0% | **NOT IMPLEMENTED** — no Bluetooth package anywhere, no `TransportDetector` class (confirmed absent in Part 1 grounding) | n/a — QR is currently the only ProxiPay transport, so this flag has no observable effect either way |
| `feature_nfc` | off, 0% | **NOT IMPLEMENTED** — same as BLE | n/a, same as above |
| `feature_qr` | on, 100% | Live (`mobile_scanner` + `qr_flutter`, used by ProxiPay and loyalty) | If disabled: both ProxiPay and loyalty-stamp scanning would need a fallback — none exists today, so this flag should not actually be turned off in practice until one is built |
| `feature_notifications` | on, 100% | Live | Disabled → `NotificationsScreen` shows `KynzaEmptyState`, not a crash; push/WhatsApp sends would need a server-side gate too (not currently wired to this flag) |
| `feature_reviews` | on, 100% | Live | Hide "Laisser un avis" CTA on completed bookings; existing reviews stay visible (read path unaffected) |
| `feature_marketing` | on, 100% | Live | Hide `MarketingDashboardBody`/owner marketing tab entries |
| `feature_referrals` | on, 100% | Live | Hide referral share CTA; `accept-referral` deep link should still resolve gracefully, not 404 |
| `feature_loyalty` | on, 100% | Live | Hide loyalty tab/QR entry points |
| `feature_commissions` | on, 100% | Live | Hide `CommissionScreen`; staff performance screen degrades to booking counts only |
| `feature_dashboard` | on, 100% | Live (owner-only) | Fall back to the basic 5-tab home without the analytics tab |
| `feature_pdf` | on, 100% | Live (`pdf`/`printing` packages, `ExportService`) | Hide PDF export buttons, keep CSV if `feature_csv` is separately on |
| `feature_csv` | on, 100% | Live (`CsvExporter`) | Hide CSV export buttons |
| `feature_export` | on, 100% | Live (`create-backup`, cooldown 1/6h) | Hide `BackupScreen`'s trigger button |
| `feature_crashlytics` | on, 100% | Live, but this is a technical/ops flag, not a user-facing one — `CrashReportingService.init()` runs unconditionally in `main()` today, not gated by this flag | n/a — documented for completeness of the registry, not a real toggle point yet |
| `feature_i18n` | on, 100% | Partially live — pipeline (ARB files, `flutter_localizations`, language toggle) works, but ~100+ existing screens still hardcode French (known tech debt, `docs/PRODUCTION_CHECKLIST.md`) | n/a — disabling wouldn't un-hardcode anything; this flag doesn't currently control retrofit completeness |
| `feature_chat` | off, 0% | **NOT IMPLEMENTED** — no chat/messaging feature folder anywhere in `lib/features/` | n/a |
| `feature_ai` | off, 0% | **NOT IMPLEMENTED** — distinct from the pre-existing `ai_scheduling` flag, which is also uncalled by any code | n/a |
| `feature_offline` | on, 100% | **Partial** — only `kynza_prefs` (session) and `permission_cache` Hive boxes exist; no outbox queue, no encrypted local cache, no offline booking/review/cash queue (`docs/OFFLINE_STRATEGY.md`, Phase E) | Already the de facto behavior — the app degrades gracefully for read-cached screens and blocks mutating actions with a "requires network" toast, per `docs/ai/skills/kynza-offline-realtime.md` §7's toast convention |
| `feature_sync` | off, 0% | **NOT IMPLEMENTED** as a dedicated mechanism — no `OutboxSyncService` in `lib/` | n/a |
| `feature_subscriptions` | on, 100% | Live (Phase 6 billing) — but `check-subscription`/plan-expiry auto-check is unwired (`docs/EDGE_FUNCTIONS_REFERENCE.md` §4) | Hide `SubscriptionPlansScreen`/`BillingScreen` entry points |
| `feature_staff` | on, 100% | Live (real role) | n/a — this is a role-existence flag, not a screen-level gate; disabling would need to be enforced at `_RoleGuard` level, not built today |
| `feature_owner` | on, 100% | Live | Same caveat as `feature_staff` |
| `feature_manager` | on, 100% | Live route access, **but** the Manager home shell is a verified UI stub — all 5 tabs render the same static `KynzaEmptyState` regardless of selection (`docs/WORKFLOWS.md` §3.3) | Already effectively "disabled" from a UX standpoint for the home shell; shared routes (services, availability, marketing, reviews) work normally |
| `feature_support` | off, 0% | **NOT IMPLEMENTED** — no CLIENT_SUPPORT role anywhere (`docs/WORKFLOWS.md` §3.5) | n/a |
| `leapa_enabled` | on, 100% | **No flag by this name exists in code today** — Leapa/Mobile Money is unconditionally live via Vault secret presence (`LEAPA_API_KEY` etc.), not gated by any flag. Added to the registry as a **forward-looking kill switch**, not a description of current behavior | If a future `leapa_enabled=false` is wired in: fall back to "Payer sur place" (ProxiPay) only, hide the Mobile Money payment option — mirrors the existing `TransportDetector`-less fallback already used for BLE/NFC → QR |

## 4. Contraintes & Edge Cases

- Because `evaluateFlag()` is unwired everywhere, **toggling any flag in `FeatureFlagScreen`
  today has zero observable effect on the app** beyond the admin screen's own list refreshing.
  This is a real, verified gap — not a documentation oversight — and is appended to
  `docs/PRODUCTION_CHECKLIST.md` (Part 14).
- `salon_feature_overrides` has no `deleted_at` — removing an override is a real `DELETE` (see
  `removeOverride()` in `FeatureFlagRepositoryImpl`), which is an exception to this project's
  general no-hard-delete rule. This is acceptable because an override row carries no history
  value (it's a live toggle, not a business record) — flagged here so it isn't mistaken for a
  violation of R12 elsewhere.

## 5. Sécurité

`feature_flags`/`salon_feature_overrides` RLS: authenticated read-all on flags; owner full
manage + manager read-only on overrides (`docs/DATABASE_ARCHITECTURE.md` §3.10). No flag or
override is ever readable by an unauthenticated client.

## 6. Performance

288 rows max realistically (27 flags × salons) — trivial read cost, no caching strategy needed
beyond what `evaluate_feature_flag()`'s single RPC call already provides.

## 7. Stratégie de tests

Not covered by existing tests (no Dart code changed in this pass). Recommended: once any flag is
actually wired into a real gate, add a widget test asserting the fallback UX renders one of the 5
mandated states, never a blank/crashed screen.

## 8. Documentation associée

- `docs/DATABASE_ARCHITECTURE.md` §3.10 — real schema detail.
- `docs/WORKFLOWS.md` §2.5, §3.3, §3.5 — the Manager-stub and CLIENT_SUPPORT-absent findings
  cross-referenced above.
- `docs/EDGE_FUNCTIONS_REFERENCE.md` §4 — `check-subscription` gap, relevant to `feature_subscriptions`.
- `docs/PRODUCTION_CHECKLIST.md` — the "flags exist but gate nothing" gap tracked there (Part 14).

## 9. Critères d'acceptation

- [x] Every flag has a documented fallback UX — for the "NOT IMPLEMENTED" flags, explicitly
      marked `n/a` rather than inventing a fallback for a feature that doesn't exist, per the
      hard rule against fabricating behavior.
- [x] `leapa_enabled` documented honestly as **not currently a real switch** — Leapa is
      unconditionally live via Vault secrets — rather than repeating the brief's unverified claim
      that it's "the exact single-flag go-live switch."

## 10. Livrables

- `docs/FEATURE_FLAGS.md` (this file)
- `supabase/migrations/20260703140000_feature_flags_registry.sql` — **drafted, data-only
  (INSERT ... ON CONFLICT DO NOTHING), not applied**. Lower-risk than Part 5's schema migration
  since it touches no schema — flagging for your review on whether to apply this one now or hold
  it with the others.
