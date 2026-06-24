import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../enums/app_enums.dart';
import 'service_model.dart';
import 'staff_profile_model.dart';
import 'user_profile.dart';

part 'booking_model.freezed.dart';
part 'booking_model.g.dart';

class BookingStatusConverter extends JsonConverter<BookingStatus, String> {
  const BookingStatusConverter();

  static const _toDb = {
    BookingStatus.pendingPayment: 'pending_payment',
    BookingStatus.confirmed: 'confirmed',
    BookingStatus.inProgress: 'in_progress',
    BookingStatus.completed: 'completed',
    BookingStatus.cancelled: 'cancelled',
    BookingStatus.noShow: 'no_show',
  };

  @override
  BookingStatus fromJson(String json) => _toDb.entries
      .firstWhere((e) => e.value == json, orElse: () => _toDb.entries.first)
      .key;

  @override
  String toJson(BookingStatus object) => _toDb[object]!;
}

class PaymentStatusConverter extends JsonConverter<PaymentStatus, String> {
  const PaymentStatusConverter();

  @override
  PaymentStatus fromJson(String json) => PaymentStatus.values.firstWhere(
    (s) => s.name == json,
    orElse: () => PaymentStatus.pending,
  );

  @override
  String toJson(PaymentStatus object) => object.name;
}

@freezed
class BookingModel with _$BookingModel {
  const factory BookingModel({
    String? id,
    required String salonId,
    required String clientId,
    required String practitionerId,
    required String serviceId,
    @BookingStatusConverter()
    @Default(BookingStatus.pendingPayment)
    BookingStatus status,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime bufferEndTime,
    required int amountBif,
    @PaymentStatusConverter()
    @Default(PaymentStatus.pending)
    PaymentStatus paymentStatus,
    String? paymentMethod,
    String? idempotencyKey,
    @Default(false) bool depositRequired,
    @Default(0) int depositAmountBif,
    String? notes,
    String? cancellationReason,
    DateTime? cancelledAt,
    DateTime? completedAt,
    DateTime? noShowAt,
    ServiceModel? service,
    StaffProfileModel? practitioner,
    UserProfile? client,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _BookingModel;

  factory BookingModel.fromSupabase(Map<String, dynamic> json) =>
      BookingModel.fromJson(json);

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);
}

extension BookingModelX on BookingModel {
  bool get isPaid => paymentStatus == PaymentStatus.completed;
  bool get isActive =>
      status == BookingStatus.confirmed || status == BookingStatus.inProgress;
  bool get canCancel =>
      status == BookingStatus.pendingPayment ||
      status == BookingStatus.confirmed;

  String get statusLabel => switch (status) {
    BookingStatus.pendingPayment => 'Paiement en attente',
    BookingStatus.confirmed => 'Confirmé',
    BookingStatus.inProgress => 'En cours',
    BookingStatus.completed => 'Terminé',
    BookingStatus.cancelled => 'Annulé',
    BookingStatus.noShow => 'Absence',
  };

  Color get statusColor => switch (status) {
    BookingStatus.pendingPayment => AppColors.info,
    BookingStatus.confirmed => AppColors.primary,
    BookingStatus.inProgress => AppColors.warning,
    BookingStatus.completed => AppColors.success,
    BookingStatus.cancelled => AppColors.textMuted,
    BookingStatus.noShow => AppColors.error,
  };
}
