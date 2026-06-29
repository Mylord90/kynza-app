enum SettingFieldType { boolean, integer, text }

/// One row in a [SettingsCategoryScreen] — `key` matches a `salon_settings`
/// column exactly (the table uses `field_rename: snake` JSON codegen, so
/// `SalonSettingsModel.toJson()[key]` looks it up directly with no
/// per-field mapping needed).
class SettingField {
  const SettingField({
    required this.key,
    required this.label,
    required this.type,
  });

  final String key;
  final String label;
  final SettingFieldType type;
}

const bookingSettingFields = [
  SettingField(
    key: 'booking_advance_days',
    label: 'Délai de réservation max (jours)',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'booking_slot_duration_minutes',
    label: 'Durée des créneaux (minutes)',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'booking_cancellation_hours',
    label: "Délai d'annulation (heures)",
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'booking_requires_confirmation',
    label: 'Confirmation requise',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'booking_allow_walkin',
    label: 'Autoriser les walk-ins',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'booking_max_per_client_per_day',
    label: 'Max RDV par client / jour',
    type: SettingFieldType.integer,
  ),
];

const notificationSalonSettingFields = [
  SettingField(
    key: 'notif_sms_enabled',
    label: 'SMS activés',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'notif_whatsapp_enabled',
    label: 'WhatsApp activé',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'notif_push_enabled',
    label: 'Notifications push activées',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'notif_reminder_hours_before',
    label: 'Premier rappel avant RDV (heures)',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'notif_reminder_hours_before2',
    label: 'Second rappel avant RDV (heures)',
    type: SettingFieldType.integer,
  ),
];

const marketingSettingFields = [
  SettingField(
    key: 'marketing_auto_review_request',
    label: "Demande d'avis automatique",
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'marketing_review_request_hours_after',
    label: "Demande d'avis après le RDV (heures)",
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'marketing_loyalty_auto_stamp',
    label: 'Tampon fidélité automatique',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'marketing_referral_bonus_bif',
    label: 'Bonus de parrainage (FBu)',
    type: SettingFieldType.integer,
  ),
];

const staffSettingFields = [
  SettingField(
    key: 'staff_show_earnings',
    label: 'Afficher les revenus au staff',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'staff_commission_auto_calculate',
    label: 'Calcul automatique des commissions',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'staff_require_checkin',
    label: 'Check-in requis',
    type: SettingFieldType.boolean,
  ),
];

const loyaltySettingFields = [
  SettingField(
    key: 'loyalty_stamps_per_card',
    label: 'Tampons par carte',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'loyalty_reward_description',
    label: 'Description de la récompense',
    type: SettingFieldType.text,
  ),
  SettingField(
    key: 'loyalty_expiry_days',
    label: 'Expiration (jours)',
    type: SettingFieldType.integer,
  ),
];

const reviewsSettingFields = [
  SettingField(
    key: 'reviews_auto_publish',
    label: 'Publication automatique',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'reviews_moderation_enabled',
    label: 'Modération activée',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'reviews_min_rating_alert',
    label: 'Alerte si note ≤',
    type: SettingFieldType.integer,
  ),
];

const paymentSettingFields = [
  SettingField(
    key: 'payment_grace_period_minutes',
    label: 'Délai de grâce (minutes)',
    type: SettingFieldType.integer,
  ),
  SettingField(
    key: 'payment_auto_invoice',
    label: 'Facturation automatique',
    type: SettingFieldType.boolean,
  ),
];

const advancedSettingFields = [
  SettingField(
    key: 'timezone',
    label: 'Fuseau horaire',
    type: SettingFieldType.text,
  ),
  SettingField(
    key: 'advanced_double_booking',
    label: 'Autoriser le double-booking',
    type: SettingFieldType.boolean,
  ),
  SettingField(
    key: 'advanced_overbooking_limit',
    label: 'Limite de surbooking',
    type: SettingFieldType.integer,
  ),
];
