import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_ltv_model.freezed.dart';
part 'client_ltv_model.g.dart';

/// One row of `public.v_client_ltv` — lifetime visit/spend aggregate for
/// a client at a salon. Reused for both the CLV top-5 list and the
/// top-clients query (ordered by totalSpentBif).
@freezed
class ClientLtvModel with _$ClientLtvModel {
  const factory ClientLtvModel({
    required String salonId,
    required String clientId,
    required String clientName,
    @Default(0) int visitCount,
    @Default(0) int totalSpentBif,
    DateTime? firstVisitAt,
    DateTime? lastVisitAt,
  }) = _ClientLtvModel;

  factory ClientLtvModel.fromSupabase(Map<String, dynamic> json) =>
      ClientLtvModel.fromJson(json);

  factory ClientLtvModel.fromJson(Map<String, dynamic> json) =>
      _$ClientLtvModelFromJson(json);
}
