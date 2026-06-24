import 'package:freezed_annotation/freezed_annotation.dart';

part 'availability_exception_model.freezed.dart';
part 'availability_exception_model.g.dart';

/// Multi-day closure/vacation/special-opening/public-holiday, salon-wide
/// ([staffId] null) or for a single staff member.
@freezed
class AvailabilityExceptionModel with _$AvailabilityExceptionModel {
  const factory AvailabilityExceptionModel({
    String? id,
    required String salonId,
    String? staffId,
    required String exceptionType,
    required DateTime startDate,
    required DateTime endDate,
    required String label,
    String? opensAt,
    String? closesAt,
    @Default(true) bool isClosed,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _AvailabilityExceptionModel;

  factory AvailabilityExceptionModel.fromSupabase(Map<String, dynamic> json) =>
      AvailabilityExceptionModel.fromJson(json);

  factory AvailabilityExceptionModel.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityExceptionModelFromJson(json);
}

extension AvailabilityExceptionModelX on AvailabilityExceptionModel {
  bool get isMultiDay =>
      startDate.year != endDate.year ||
      startDate.month != endDate.month ||
      startDate.day != endDate.day;

  bool get isPublicHoliday => exceptionType == 'public_holiday';

  String get typeLabel => switch (exceptionType) {
    'holiday' => 'Congé',
    'vacation' => 'Vacances',
    'special_closure' => 'Fermeture spéciale',
    'special_opening' => 'Ouverture spéciale',
    'public_holiday' => 'Jour férié',
    _ => exceptionType,
  };
}
