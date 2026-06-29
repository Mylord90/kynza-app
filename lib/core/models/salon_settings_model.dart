import 'package:freezed_annotation/freezed_annotation.dart';

part 'salon_settings_model.freezed.dart';
part 'salon_settings_model.g.dart';

@freezed
class SalonSettingsModel with _$SalonSettingsModel {
  const factory SalonSettingsModel({
    required String id,
    required String salonId,
    @Default(30) int bookingAdvanceDays,
    @Default(30) int bookingSlotDurationMinutes,
    @Default(24) int bookingCancellationHours,
    @Default(true) bool bookingRequiresConfirmation,
    @Default(true) bool bookingAllowWalkin,
    @Default(3) int bookingMaxPerClientPerDay,
    @Default(false) bool notifSmsEnabled,
    @Default(false) bool notifWhatsappEnabled,
    @Default(true) bool notifPushEnabled,
    @Default(24) int notifReminderHoursBefore,
    // json_serializable's snake_case codegen drops the underscore before
    // a trailing digit ('...before2', not '...before_2') — force the
    // name to match the actual DB column. invalid_annotation_target is a
    // known Freezed false-positive for @JsonKey on constructor params.
    // ignore: invalid_annotation_target
    @JsonKey(name: 'notif_reminder_hours_before_2')
    @Default(1)
    int notifReminderHoursBefore2,
    @Default(true) bool marketingAutoReviewRequest,
    @Default(2) int marketingReviewRequestHoursAfter,
    @Default(true) bool marketingLoyaltyAutoStamp,
    @Default(2000) int marketingReferralBonusBif,
    @Default(false) bool staffShowEarnings,
    @Default(true) bool staffCommissionAutoCalculate,
    @Default(false) bool staffRequireCheckin,
    @Default(10) int loyaltyStampsPerCard,
    @Default('Service gratuit') String loyaltyRewardDescription,
    @Default(365) int loyaltyExpiryDays,
    @Default(true) bool reviewsAutoPublish,
    @Default(false) bool reviewsModerationEnabled,
    @Default(2) int reviewsMinRatingAlert,
    @Default(30) int paymentGracePeriodMinutes,
    @Default(true) bool paymentAutoInvoice,
    @Default('Africa/Bujumbura') String timezone,
    @Default(false) bool advancedDoubleBooking,
    @Default(0) int advancedOverbookingLimit,
  }) = _SalonSettingsModel;

  factory SalonSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SalonSettingsModelFromJson(json);
}
