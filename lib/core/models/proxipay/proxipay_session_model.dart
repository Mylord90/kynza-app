import 'package:freezed_annotation/freezed_annotation.dart';

part 'proxipay_session_model.freezed.dart';
part 'proxipay_session_model.g.dart';

@freezed
class ProxiPaySessionModel with _$ProxiPaySessionModel {
  const factory ProxiPaySessionModel({
    required String id,
    required String bookingId,
    required String salonId,
    required String staffId,
    String? clientId,
    required int amountBif,
    @Default('pending') String status,
    required DateTime expiresAt,
    DateTime? confirmedAt,
    DateTime? createdAt,
  }) = _ProxiPaySessionModel;

  factory ProxiPaySessionModel.fromSupabase(Map<String, dynamic> json) =>
      ProxiPaySessionModel.fromJson(json);

  factory ProxiPaySessionModel.fromJson(Map<String, dynamic> json) =>
      _$ProxiPaySessionModelFromJson(json);
}

extension ProxiPaySessionModelX on ProxiPaySessionModel {
  bool get isPending =>
      status == 'pending' && expiresAt.isAfter(DateTime.now());
  bool get isConfirmed => status == 'confirmed';
  bool get isExpired =>
      status == 'expired' || (status == 'pending' && !isPending);
}
