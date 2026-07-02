import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/proxipay/proxipay_session_model.dart';
import '../../data/repositories/proxipay_repository_impl.dart';
import '../../domain/repositories/proxipay_repository.dart';

final proxipayRepositoryProvider = Provider<ProxiPayRepository>(
  (ref) => ProxiPayRepositoryImpl(),
);

final proxipaySessionStreamProvider = StreamProvider.autoDispose
    .family<ProxiPaySessionModel?, String>(
      (ref, sessionId) =>
          ref.watch(proxipayRepositoryProvider).watchSession(sessionId),
    );

final proxipayNotifierProvider =
    AsyncNotifierProvider.autoDispose<ProxiPayNotifier, void>(
      ProxiPayNotifier.new,
    );

class ProxiPayNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  void build() {}

  Future<ProxiPaySessionModel> createSession(String bookingId) {
    return ref.read(proxipayRepositoryProvider).createSession(bookingId);
  }

  Future<ProxiPaySessionModel?> getSession(String sessionId) {
    return ref.read(proxipayRepositoryProvider).getSession(sessionId);
  }

  Future<void> confirmSession({
    required String sessionId,
    required String method,
    required String phone,
  }) {
    return ref
        .read(proxipayRepositoryProvider)
        .confirmSession(sessionId: sessionId, method: method, phone: phone);
  }
}
