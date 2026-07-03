import 'package:hive_flutter/hive_flutter.dart';

/// Offline outbox for legal-document acceptance writes — the first of its
/// kind in this codebase (there was no established Hive outbox/queue
/// pattern to reuse when this was built; ProxiPay and every other mutating
/// flow are online-only, see docs/OFFLINE_STRATEGY.md). Store-if-offline,
/// flush-on-reconnect, with a formal dead-letter queue (Phase 4 of the
/// Enterprise Hardening pass): an item that fails [maxAttempts] flush
/// attempts moves to [deadLetterBoxName] instead of retrying forever or
/// being silently dropped — visible to support/admin via [deadLetterItems].
class LegalAcceptanceQueueService {
  static const boxName = 'kynza_legal_acceptance_queue';
  static const deadLetterBoxName = 'kynza_sync_dead_letter';
  static const _itemsKey = 'pending';
  static const _deadLetterKey = 'items';

  /// After this many failed flush attempts, an item is moved to the DLQ
  /// rather than retried again — chosen to match this pass's own acceptance
  /// criterion ("an item that fails 3x lands in the DLQ").
  static const maxAttempts = 3;

  Box get _box => Hive.box(boxName);
  Box get _deadLetterBox => Hive.box(deadLetterBoxName);

  List<Map<String, dynamic>> _readBox(Box box, String key) =>
      (box.get(key) as List?)
          ?.cast<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList() ??
      [];

  List<Map<String, dynamic>> _read() => _readBox(_box, _itemsKey);

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
      'attempts': 0,
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

  /// Increments the retry counter for a queued item and returns the new
  /// count — call this when a flush attempt fails. Does nothing (returns 0)
  /// if the item isn't found, which can't normally happen but is handled
  /// defensively rather than throwing.
  Future<int> recordFailedAttempt(
    String userId,
    String documentVersionId,
  ) async {
    final items = _read();
    final index = items.indexWhere(
      (i) =>
          i['userId'] == userId && i['documentVersionId'] == documentVersionId,
    );
    if (index == -1) return 0;
    final attempts = (items[index]['attempts'] as int? ?? 0) + 1;
    items[index] = {...items[index], 'attempts': attempts};
    await _box.put(_itemsKey, items);
    return attempts;
  }

  /// Moves a queued item from the pending list to the dead-letter box —
  /// removed from [pending] but never deleted outright, so support/admin
  /// can still see and act on it via [deadLetterItems].
  Future<void> moveToDeadLetter(String userId, String documentVersionId) async {
    final items = _read();
    final index = items.indexWhere(
      (i) =>
          i['userId'] == userId && i['documentVersionId'] == documentVersionId,
    );
    if (index == -1) return;
    final item = items.removeAt(index);
    await _box.put(_itemsKey, items);

    final deadLetterItems = _readBox(_deadLetterBox, _deadLetterKey)
      ..add({...item, 'movedToDeadLetterAt': DateTime.now()});
    await _deadLetterBox.put(_deadLetterKey, deadLetterItems);
  }

  List<Map<String, dynamic>> deadLetterItems() =>
      _readBox(_deadLetterBox, _deadLetterKey);

  /// Support/admin action once a dead-lettered item has been manually
  /// resolved (e.g. investigated and confirmed safe to discard).
  Future<void> clearDeadLetter() => _deadLetterBox.delete(_deadLetterKey);

  Future<void> clear() => _box.delete(_itemsKey);
}
