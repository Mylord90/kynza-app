import '../../../../core/services/atomic_claim_service.dart';
import '../../../../core/services/crash_reporting_service.dart';
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
  /// leaves it queued for the next flush instead of losing it — up to
  /// [LegalAcceptanceQueueService.maxAttempts] times, after which it moves
  /// to the dead-letter queue instead of retrying forever.
  /// Claim key shared across every [LegalAcceptanceService] instance
  /// (deliberately a fixed string, not per-instance) — same reasoning as
  /// `OfflineSyncCoordinator._claimKey`: `KynzaOfflineBanner` is mounted
  /// independently across ~40 screens, each building its own service, so
  /// only an instance-independent claim key actually serializes them.
  static const _claimKey = 'legal_acceptance_service.flushQueue';

  Future<void> flushQueue() {
    return AtomicClaimService.instance.runExclusive(_claimKey, () async {
      for (final item in queue.pending()) {
        final userId = item['userId'] as String;
        final documentVersionId = item['documentVersionId'] as String;
        try {
          await consentRepository.acceptDocumentVersion(
            userId: userId,
            documentVersionId: documentVersionId,
            appVersion: item['appVersion'] as String?,
            platform: item['platform'] as String?,
          );
          await queue.removeQueued(userId, documentVersionId);
        } catch (e, st) {
          try {
            CrashReportingService.recordError(e, st);
          } catch (_) {
            // Never let a Crashlytics failure (e.g. Firebase uninitialized —
            // this path also runs in tests with no Firebase app) block the
            // retry/DLQ bookkeeping below.
          }
          final attempts = await queue.recordFailedAttempt(
            userId,
            documentVersionId,
          );
          if (attempts >= LegalAcceptanceQueueService.maxAttempts) {
            await queue.moveToDeadLetter(userId, documentVersionId);
          }
        }
      }
    });
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
