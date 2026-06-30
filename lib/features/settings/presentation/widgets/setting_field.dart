import '../../../../l10n/app_localizations.dart';

enum SettingFieldType { boolean, integer, text }

/// One row in a [SettingsCategoryScreen] — `key` matches a `salon_settings`
/// column exactly (the table uses `field_rename: snake` JSON codegen, so
/// `SalonSettingsModel.toJson()[key]` looks it up directly with no
/// per-field mapping needed).
///
/// [labelKey] is an l10n key resolved at render time via [resolveLabel].
class SettingField {
  const SettingField({
    required this.key,
    required this.labelKey,
    required this.type,
  });

  final String key;
  final String labelKey;
  final SettingFieldType type;

  String resolveLabel(AppLocalizations l10n) =>
      _settingFieldLabels(l10n)[labelKey] ?? labelKey;
}

Map<String, String> _settingFieldLabels(AppLocalizations l10n) => {
  'settingFieldBookingAdvanceDays': l10n.settingFieldBookingAdvanceDays,
  'settingFieldBookingSlotDuration': l10n.settingFieldBookingSlotDuration,
  'settingFieldBookingCancellationHours':
      l10n.settingFieldBookingCancellationHours,
  'settingFieldBookingRequiresConfirmation':
      l10n.settingFieldBookingRequiresConfirmation,
  'settingFieldBookingAllowWalkin': l10n.settingFieldBookingAllowWalkin,
  'settingFieldBookingMaxPerClientPerDay':
      l10n.settingFieldBookingMaxPerClientPerDay,
  'settingFieldNotifSmsEnabled': l10n.settingFieldNotifSmsEnabled,
  'settingFieldNotifWhatsappEnabled': l10n.settingFieldNotifWhatsappEnabled,
  'settingFieldNotifPushEnabled': l10n.settingFieldNotifPushEnabled,
  'settingFieldNotifReminderHoursBefore':
      l10n.settingFieldNotifReminderHoursBefore,
  'settingFieldNotifReminderHoursBefore2':
      l10n.settingFieldNotifReminderHoursBefore2,
  'settingFieldMarketingAutoReviewRequest':
      l10n.settingFieldMarketingAutoReviewRequest,
  'settingFieldMarketingReviewRequestHoursAfter':
      l10n.settingFieldMarketingReviewRequestHoursAfter,
  'settingFieldMarketingLoyaltyAutoStamp':
      l10n.settingFieldMarketingLoyaltyAutoStamp,
  'settingFieldMarketingReferralBonusBif':
      l10n.settingFieldMarketingReferralBonusBif,
  'settingFieldStaffShowEarnings': l10n.settingFieldStaffShowEarnings,
  'settingFieldStaffCommissionAutoCalculate':
      l10n.settingFieldStaffCommissionAutoCalculate,
  'settingFieldStaffRequireCheckin': l10n.settingFieldStaffRequireCheckin,
  'settingFieldLoyaltyStampsPerCard': l10n.settingFieldLoyaltyStampsPerCard,
  'settingFieldLoyaltyRewardDescription':
      l10n.settingFieldLoyaltyRewardDescription,
  'settingFieldLoyaltyExpiryDays': l10n.settingFieldLoyaltyExpiryDays,
  'settingFieldReviewsAutoPublish': l10n.settingFieldReviewsAutoPublish,
  'settingFieldReviewsModerationEnabled':
      l10n.settingFieldReviewsModerationEnabled,
  'settingFieldReviewsMinRatingAlert': l10n.settingFieldReviewsMinRatingAlert,
  'settingFieldPaymentGracePeriodMinutes':
      l10n.settingFieldPaymentGracePeriodMinutes,
  'settingFieldPaymentAutoInvoice': l10n.settingFieldPaymentAutoInvoice,
  'settingFieldTimezone': l10n.settingFieldTimezone,
  'settingFieldAdvancedDoubleBooking': l10n.settingFieldAdvancedDoubleBooking,
  'settingFieldAdvancedOverbookingLimit':
      l10n.settingFieldAdvancedOverbookingLimit,
};

const bookingSettingFields = [
  SettingField(
    key: 'booking_advance_days',
    labelKey: 'settingFieldBookingAdvanceDays',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'booking_slot_duration_minutes',
    labelKey: 'settingFieldBookingSlotDuration',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'booking_cancellation_hours',
    labelKey: 'settingFieldBookingCancellationHours',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'booking_requires_confirmation',
    labelKey: 'settingFieldBookingRequiresConfirmation',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'booking_allow_walkin',
    labelKey: 'settingFieldBookingAllowWalkin',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'booking_max_per_client_per_day',
    labelKey: 'settingFieldBookingMaxPerClientPerDay',
    type: SettingFieldType.integer,
  ),
];

const notificationSalonSettingFields = [
  SettingField(
    key: 'notif_sms_enabled',
    labelKey: 'settingFieldNotifSmsEnabled',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'notif_whatsapp_enabled',
    labelKey: 'settingFieldNotifWhatsappEnabled',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'notif_push_enabled',
    labelKey: 'settingFieldNotifPushEnabled',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'notif_reminder_hours_before',
    labelKey: 'settingFieldNotifReminderHoursBefore',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'notif_reminder_hours_before2',
    labelKey: 'settingFieldNotifReminderHoursBefore2',
    type: SettingFieldType.integer,
  ),
];

const marketingSettingFields = [
  SettingField(
    key: 'marketing_auto_review_request',
    labelKey: 'settingFieldMarketingAutoReviewRequest',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'marketing_review_request_hours_after',
    labelKey: 'settingFieldMarketingReviewRequestHoursAfter',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'marketing_loyalty_auto_stamp',
    labelKey: 'settingFieldMarketingLoyaltyAutoStamp',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'marketing_referral_bonus_bif',
    labelKey: 'settingFieldMarketingReferralBonusBif',
    type: SettingFieldType.integer,
  ),
];

const staffSettingFields = [
  SettingField(
    key: 'staff_show_earnings',
    labelKey: 'settingFieldStaffShowEarnings',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'staff_commission_auto_calculate',
    labelKey: 'settingFieldStaffCommissionAutoCalculate',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'staff_require_checkin',
    labelKey: 'settingFieldStaffRequireCheckin',
    type: SettingFieldType.boolean,
  ),
];

const loyaltySettingFields = [
  SettingField(
    key: 'loyalty_stamps_per_card',
    labelKey: 'settingFieldLoyaltyStampsPerCard',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'loyalty_reward_description',
    labelKey: 'settingFieldLoyaltyRewardDescription',
    type: SettingFieldType.text,
  ),
  SettingField(
    key: 'loyalty_expiry_days',
    labelKey: 'settingFieldLoyaltyExpiryDays',
    type: SettingFieldType.integer,
  ),
];

const reviewsSettingFields = [
  SettingField(
    key: 'reviews_auto_publish',
    labelKey: 'settingFieldReviewsAutoPublish',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'reviews_moderation_enabled',
    labelKey: 'settingFieldReviewsModerationEnabled',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'reviews_min_rating_alert',
    labelKey: 'settingFieldReviewsMinRatingAlert',
    type: SettingFieldType.integer,
  ),
];

const paymentSettingFields = [
  SettingField(
    key: 'payment_grace_period_minutes',
    labelKey: 'settingFieldPaymentGracePeriodMinutes',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'payment_auto_invoice',
    labelKey: 'settingFieldPaymentAutoInvoice',
    type: SettingFieldType.boolean,
  ),
];

const advancedSettingFields = [
  SettingField(
    key: 'timezone',
    labelKey: 'settingFieldTimezone',
    type: SettingFieldType.text,
  ),
  SettingField(
    key: 'advanced_double_booking',
    labelKey: 'settingFieldAdvancedDoubleBooking',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'advanced_overbooking_limit',
    labelKey: 'settingFieldAdvancedOverbookingLimit',
    type: SettingFieldType.integer,
  ),
];
