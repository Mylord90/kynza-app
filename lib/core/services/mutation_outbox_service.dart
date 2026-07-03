import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Generic offline outbox for mutating writes that don't yet have their
/// own dedicated queue (contrast with `LegalAcceptanceQueueService`, which
/// stays a separate, entity-specific box). Same shape as that service —
/// store-if-offline, flush-on-reconnect, dead-letter queue after
/// [maxAttempts] failed attempts — generalized over an arbitrary [type]
/// string + payload map so one Hive box can back multiple mutation kinds
/// (review creation, profile edits, data-deletion requests) instead of
/// duplicating the same box/DLQ plumbing three more times.
class MutationOutboxService {
  static const boxName = 'kynza_mutation_outbox';
  static const deadLetterBoxName = 'kynza_mutation_dead_letter';
  static const _itemsKey = 'pending';
  static const _deadLetterKey = 'items';

  /// After this many failed flush attempts, an item moves to the DLQ
  /// instead of retrying forever — same threshold as
  /// LegalAcceptanceQueueService, for one consistent house rule.
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

  /// [dedupeKey], when provided, makes this a "last write wins" queue for
  /// that key: any existing queued item of the same [type] with the same
  /// [dedupeKey] is replaced rather than appended (e.g. profile edits —
  /// only the most recent edit while offline needs to survive to sync).
  /// Leave it null for mutations where every queued item is independent
  /// (e.g. a review, keyed by its own booking, never collides with another).
  Future<String> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    String? dedupeKey,
  }) async {
    final items = _read();
    if (dedupeKey != null) {
      items.removeWhere(
        (i) => i['type'] == type && i['dedupeKey'] == dedupeKey,
      );
    }
    final id = const Uuid().v4();
    items.add({
      'id': id,
      'type': type,
      'payload': payload,
      'dedupeKey': dedupeKey,
      'queuedAt': DateTime.now(),
      'attempts': 0,
    });
    await _box.put(_itemsKey, items);
    return id;
  }

  List<Map<String, dynamic>> pending({String? type}) {
    final items = _read();
    return type == null ? items : items.where((i) => i['type'] == type).toList();
  }

  Future<void> remove(String id) async {
    final items = _read()..removeWhere((i) => i['id'] == id);
    await _box.put(_itemsKey, items);
  }

  Future<int> recordFailedAttempt(String id) async {
    final items = _read();
    final index = items.indexWhere((i) => i['id'] == id);
    if (index == -1) return 0;
    final attempts = (items[index]['attempts'] as int? ?? 0) + 1;
    items[index] = {...items[index], 'attempts': attempts};
    await _box.put(_itemsKey, items);
    return attempts;
  }

  Future<void> moveToDeadLetter(String id) async {
    final items = _read();
    final index = items.indexWhere((i) => i['id'] == id);
    if (index == -1) return;
    final item = items.removeAt(index);
    await _box.put(_itemsKey, items);

    final deadLetterItems = _readBox(_deadLetterBox, _deadLetterKey)
      ..add({...item, 'movedToDeadLetterAt': DateTime.now()});
    await _deadLetterBox.put(_deadLetterKey, deadLetterItems);
  }

  List<Map<String, dynamic>> deadLetterItems({String? type}) {
    final items = _readBox(_deadLetterBox, _deadLetterKey);
    return type == null ? items : items.where((i) => i['type'] == type).toList();
  }

  Future<void> clearDeadLetter() => _deadLetterBox.delete(_deadLetterKey);

  Future<void> clear() => _box.delete(_itemsKey);
}
