# KYNZA — Phase 3A Summary

Loyalty · Reviews · Owner Success Journey · Marketing Engine

## 1. Files created

### Database
- `supabase/migrations/20260624090000_phase3a_schema.sql` — `loyalty_programs`, `loyalty_cards`, `loyalty_stamp_logs`, `reviews`, `review_media`, `owner_journey_progress`, `client_contacts`, `promotions`, `referrals` + `v_salon_ratings` view + RLS on every table
- `supabase/migrations/20260624091000_loyalty_notification_template.sql` — `loyalty_reward_available` push template
- `supabase/migrations/20260624092000_loyalty_stamp_functions.sql` — `add_loyalty_stamp` / `redeem_loyalty_reward` atomic RPCs
- `supabase/migrations/20260624093000_phase3a_fixups.sql` — `referrals.referral_token` default + `journey_step_complete` push template
- `supabase/migrations/20260624094000_storage_self_avatar.sql` — lets any authenticated user write their own `user/{uid}/avatar/...` object in the existing `kynza-media` bucket

### Models (`lib/core/models/`)
- `loyalty/loyalty_program_model.dart`, `loyalty_card_model.dart`, `loyalty_stamp_log_model.dart`
- `review/review_model.dart`, `salon_rating_model.dart`
- `journey/owner_journey_model.dart` (+ `JourneyStep`, the 5-step static list)
- `marketing/client_contact_model.dart`, `promotion_model.dart`, `referral_model.dart`
- `app_enums.dart` (+): `LoyaltyAction`, `DiscountType`

### Repositories + providers
- `lib/features/loyalty/**` — domain/data/application (`LoyaltyRepository`, providers, `LoyaltyNotifier`)
- `lib/features/reviews/**` — same shape for reviews
- `lib/features/journey/**` — same shape for the owner journey, plus `journeyDismissedProvider` (Hive-persisted dismiss flag)
- `lib/features/marketing/**` — same shape for contacts/promotions/referral-token

### Screens & widgets
- Owner: `journey_progress_card.dart`, `marketing_dashboard_screen.dart` (+ `MarketingDashboardBody`), `invite_clients_screen.dart`, `social_share_center_screen.dart`, `promotion_center_screen.dart`, `loyalty_setup_screen.dart`, `owner_reviews_screen.dart`
- Client: `client_loyalty_screen.dart` + `loyalty_card_widget.dart`, `client_profile_screen.dart` (replaces the old inline `_ProfileTab`), `client_bookings_screen.dart` (replaces the old inline `_AppointmentsTab`), `leave_review_screen.dart`
- Shared review UI: `rating_summary_widget.dart`, `review_tile.dart`, `salon_reviews_tab.dart`
- `lib/features/home_client/application/providers/client_profile_providers.dart` — profile edit + avatar upload

### Tests
- `test/unit/loyalty_models_test.dart` (12), `review_models_test.dart` (8), `journey_models_test.dart` (6), `marketing_models_test.dart` (13) — **39 new tests**, all passing alongside the 70 pre-existing ones (**109 total**)

## 2. Files modified (additive, Phase 1/2/2.2 behavior preserved)

| File | Change |
|---|---|
| `lib/core/router/route_names.dart`, `app_router.dart` | +10 routes; +6 owner-side deep-link loader widgets (resolve `ownerSalonProvider` first) plus inline `Scaffold` wrappers for the 3 client tabs screens and a direct route for `LeaveReviewScreen` |
| `lib/features/home_owner/presentation/screens/home_owner_screen.dart` | Journey card inserted above the KPI grid; Marketing tab now renders `MarketingDashboardBody`; Profil tab links to `/owner/reviews`; share icon shown when the Marketing tab is active |
| `lib/features/home_client/presentation/screens/home_client_screen.dart` | New 5th "Fidélité" tab; RDV/Profil tabs now point at the new dedicated screens instead of inline widgets |
| `lib/features/home_owner/presentation/widgets/booking_detail_sheet.dart`, `booking/application/providers/booking_providers.dart` | `markCompleted` now takes the full `BookingModel` and best-effort awards a loyalty stamp on completion |
| `lib/features/booking/presentation/screens/salon_detail_screen.dart` | "Avis" tab now renders `SalonReviewsTab` instead of a static placeholder |
| `lib/features/salon/presentation/screens/salon_creation_wizard_screen.dart` | Marks the `salon_info` and `hours` journey steps on successful submit (the wizard collects both at once) |
| `lib/features/services/presentation/screens/service_form_screen.dart` | Marks `first_service` on first creation (not on edits) |
| `lib/features/staff/presentation/screens/staff_list_screen.dart` | Marks `team` once staff exist, or via a new "Je travaille seul →" button on the empty state |
| `supabase/functions/create-booking/index.ts` | Marks `first_booking` when a salon's booking count first reaches 1; deployed |
| `lib/core/services/share_service.dart` | +`shareService`, `sharePromotion`, `shareClientInvite`, `shareSalonProfile`, `shareGenericInvite` |
| `lib/core/services/storage_service.dart` | +`uploadUserAvatar` |
| `lib/core/services/session_service.dart` | +journey-card dismissal flag (Hive) |
| `lib/core/enums/app_enums.dart` | +`LoyaltyAction`, `DiscountType` |
| `test/unit/availability_service_test.dart`, `booking_flow_notifier_test.dart`, `currency_formatter_edge_cases_test.dart`, `lib/core/models/time_slot_model.dart`, `booking/presentation/screens/time_slot_screen.dart`, `booking/presentation/widgets/walkin_booking_sheet.dart` | Whitespace-only — surfaced by the mandatory final `dart format` pass; no behavior change (full test suite green before and after) |

## 3. SQL tables created (all RLS-enabled)

| Table | RLS summary |
|---|---|
| `loyalty_programs` | owner/manager manage; public reads active ones |
| `loyalty_cards` | client **read-only** on own card; owner/manager/staff manage (stamps are staff-administered, never client-self-served) |
| `loyalty_stamp_logs` | append-only via owner/manager/staff; client read-only own logs |
| `reviews` | client inserts only for their own completed booking; 30-day self-edit window; owner/manager reply; column-level write protection via `protect_review_columns` trigger (mirrors `protect_user_columns`) |
| `review_media` | scoped to the parent review's visibility/ownership (the literal spec enabled RLS here but defined zero policies — fixed, otherwise the table would have been completely inert) |
| `owner_journey_progress` | owner-only, auto-created via `on_salon_created` trigger |
| `client_contacts` | owner/manager of that salon only |
| `promotions` | owner/manager manage; public reads active+unexpired |
| `referrals` | visible to either party (schema-only this phase — see Known Gaps) |

## 4. Screens created (route → purpose)

- `/owner/marketing`, `/owner/marketing/clients`, `/owner/marketing/promotions`, `/owner/marketing/loyalty`, `/owner/share`, `/owner/reviews`
- `/client/loyalty`, `/client/bookings`, `/client/profile`, `/client/review/:bookingId`

## 5. Bugs found & fixed (relative to the literal spec)

1. RLS used `auth.jwt()->>'role'`/`'salon_id'` — this project already replaced that exact pattern with `public.has_role()` after real production bugs (see the `fix_access_token_hook_*` migrations); rewrote every new policy to match.
2. `client_own_card` was `FOR ALL`, letting a client write their own `stamps_count` directly — split into client-read-only + staff-managed-write.
3. `review_media` had RLS enabled with no policies — added client-owns / public-reads-if-visible.
4. Review `INSERT` didn't verify the booking actually belonged to the reviewer or was completed — added that check.
5. `owner_reply_review` allowed the owner to overwrite `rating`/`comment` — added `protect_review_columns` trigger so each side can only touch its own fields.
6. `referrals.referral_token` had no DB default — added one (fixup migration).

## 6. Build status

```
flutter analyze        → No issues found
flutter test           → 109/109 passing
dart format --set-exit-if-changed → applied (51 files, mostly Phase 3A; a handful of pre-existing files normalized too)
supabase migration list → local == remote, 0 pending
```

## 7. Known gaps (intentional scope cuts, not oversights)

- **Referral claim flow**: `referrals` table + RLS exist and `com.kynza.app://accept-referral?token=...` links are sent, but no screen handles that deep link yet — claiming a referral on signup is Phase 3B work.
- **Loyalty redemption QR code**: the client loyalty card shows the reward-available state but not a scannable code; redemption today is `redeemReward()` called by staff/owner (e.g. exposed in the Loyalty Setup screen's stats), not a client-facing QR flow.
- **"Mes avis" detail / receipt views** are bottom-sheets, not dedicated routed screens, since none were listed in the routing spec.
- **Pagination** on `getSalonReviews` is server-side (`page` param, 10/page) but the salon-detail Avis tab currently renders only the first page — a "load more" control is a small follow-up.

## 8. Phase 3B preparation

- Subscription billing Pro/Premium
- Manager dashboard (still placeholder)
- Analytics export PDF/CSV
- Search advanced with price/rating filters
- Multi-salon (Phase 4)
- Referral claim deep-link handler (see Known Gaps)