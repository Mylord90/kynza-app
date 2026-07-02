import '../../../../core/models/proxipay/proxipay_session_model.dart';

abstract class ProxiPayRepository {
  /// Staff-initiated — creates a short-lived session for [bookingId]. Amount
  /// is derived server-side from the booking, never sent from the client.
  Future<ProxiPaySessionModel> createSession(String bookingId);

  /// One-shot read used by the client's scan screen to resolve a scanned
  /// session id into displayable amount/status before confirming.
  Future<ProxiPaySessionModel?> getSession(String sessionId);

  /// Client-initiated — confirms the session and triggers the Mobile Money
  /// charge. The phone number is never persisted on the session row.
  Future<void> confirmSession({
    required String sessionId,
    required String method,
    required String phone,
  });

  /// Realtime stream watched by the staff screen while the QR is displayed.
  Stream<ProxiPaySessionModel?> watchSession(String sessionId);
}
