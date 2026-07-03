import '../../../../core/services/legal_acceptance_queue_service.dart';
import '../../domain/repositories/legal_document_repository.dart';
import '../../domain/repositories/user_consent_repository.dart';

/// Orchestrates accepting a legal document version, offline-first: writes
/// go straight to Supabase when online, or into [LegalAcceptanceQueueService]
/// when offline, to be replayed by [flushQueue] on reconnect. Also answers
/// the soft-gate question every screen needs: "does this user still need to
/// accept a newer version of this document?"
class LegalAcceptanceService {
  LegalAcceptanceService({
    required this.documentRepository,
    required this.consentRepository,
    required this.queue,
  });

  final LegalDocumentRepository documentRepository;
  final UserConsentRepository consentRepository;
  final LegalAcceptanceQueueService queue;

  Future<void> acceptVersion({
    required String userId,
    required String documentVersionId,
    required bool isOnline,
    String? appVersion,
    String? platform,
  }) async {
    if (!isOnline) {
      await queue.enqueue(
        userId: userId,
        documentVersionId: documentVersionId,
        appVersion: appVersion,
        platform: platform,
      );
      return;
    }
    await consentRepository.acceptDocumentVersion(
      userId: userId,
      documentVersionId: documentVersionId,
      appVersion: appVersion,
      platform: platform,
    );
  }

  /// Replays every queued offline acceptance. An item is only removed after
  /// its write succeeds, so a mid-flush failure (connectivity drops again)
  /// leaves the rest queued for the next flush instead of losing them.
  Future<void> flushQueue() async {
    for (final item in queue.pending()) {
      await consentRepository.acceptDocumentVersion(
        userId: item['userId'] as String,
        documentVersionId: item['documentVersionId'] as String,
        appVersion: item['appVersion'] as String?,
        platform: item['platform'] as String?,
      );
      await queue.removeQueued(
        item['userId'] as String,
        item['documentVersionId'] as String,
      );
    }
  }

  /// Whether [userId] has accepted the current version of [documentId] in
  /// [locale]. Compares the specific current-version row id directly — if
  /// the user's active app locale changes between accepting and this check,
  /// they may be asked to accept the other locale's version row too; a
  /// deliberate V1 simplification (see the migration file's header note for
  /// the version_number-based cross-locale design this could grow into).
  Future<bool> isUpToDate({
    required String userId,
    required String documentId,
    String locale = 'fr',
  }) async {
    final current = await documentRepository.getCurrentVersion(
      documentId,
      locale: locale,
    );
    if (current?.id == null) return true; // nothing published yet to gate on
    final acceptances = await consentRepository.getUserAcceptances(userId);
    return acceptances.any((a) => a.documentVersionId == current!.id);
  }
}
