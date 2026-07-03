import 'package:hive_flutter/hive_flutter.dart';

/// Minimal offline outbox for legal-document acceptance writes — the first
/// of its kind in this codebase (there is no established Hive
/// outbox/queue pattern to reuse yet; ProxiPay and every other mutating
/// flow are online-only today, see docs/OFFLINE_STRATEGY.md). Kept
/// deliberately small: store-if-offline, flush-on-reconnect, no retry-limit
/// or dead-letter-queue — Phase 6 of the Enterprise Hardening pass is where
/// that gets formalized and generalized to every mutating flow at once.
class LegalAcceptanceQueueService {
  static const boxName = 'kynza_legal_acceptance_queue';
  static const _itemsKey = 'pending';

  Box get _box => Hive.box(boxName);

  List<Map<String, dynamic>> _read() =>
      (_box.get(_itemsKey) as List?)
          ?.cast<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList() ??
      [];

  Future<void> enqueue({
    required String userId,
    required String documentVersionId,
    String? appVersion,
    String? platform,
  }) async {
    final items = _read()
      ..removeWhere(
        (i) =>
            i['userId'] == userId &&
            i['documentVersionId'] == documentVersionId,
      );
    items.add({
      'userId': userId,
      'documentVersionId': documentVersionId,
      'appVersion': appVersion,
      'platform': platform,
      'queuedAt': DateTime.now(),
    });
    await _box.put(_itemsKey, items);
  }

  List<Map<String, dynamic>> pending() => _read();

  Future<void> removeQueued(String userId, String documentVersionId) async {
    final items = _read()
      ..removeWhere(
        (i) =>
            i['userId'] == userId &&
            i['documentVersionId'] == documentVersionId,
      );
    await _box.put(_itemsKey, items);
  }

  Future<void> clear() => _box.delete(_itemsKey);
}
