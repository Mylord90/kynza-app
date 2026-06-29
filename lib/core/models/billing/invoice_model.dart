import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_model.freezed.dart';
part 'invoice_model.g.dart';

@freezed
class InvoiceModel with _$InvoiceModel {
  const factory InvoiceModel({
    String? id,
    required String salonId,
    required String planKey,
    required int amountBif,
    required String reference,
    @Default('pending') String status,
    String? paymentInstructions,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? voidedAt,
  }) = _InvoiceModel;

  factory InvoiceModel.fromSupabase(Map<String, dynamic> json) =>
      InvoiceModel.fromJson(json);

  factory InvoiceModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceModelFromJson(json);
}

extension InvoiceModelX on InvoiceModel {
  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
}
