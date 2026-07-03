import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/legal/data_deletion_request_model.dart';
import '../../../../core/models/legal/legal_consent_setting_model.dart';
import '../../../../core/models/legal/legal_document_model.dart';
import '../../../../core/models/legal/legal_document_version_model.dart';
import '../../../../core/models/legal/user_legal_acceptance_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/offline_sync_providers.dart';
import '../../../../core/services/legal_acceptance_queue_service.dart';
import '../../../../core/services/offline_sync_coordinator.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/data_deletion_repository_impl.dart';
import '../../data/repositories/legal_document_repository_impl.dart';
import '../../data/repositories/user_consent_repository_impl.dart';
import '../../domain/repositories/data_deletion_repository.dart';
import '../../domain/repositories/legal_document_repository.dart';
import '../../domain/repositories/user_consent_repository.dart';
import '../services/legal_acceptance_service.dart';

final legalDocumentRepositoryProvider = Provider<LegalDocumentRepository>(
  (ref) => LegalDocumentRepositoryImpl(),
);

final userConsentRepositoryProvider = Provider<UserConsentRepository>(
  (ref) => UserConsentRepositoryImpl(),
);

final dataDeletionRepositoryProvider = Provider<DataDeletionRepository>(
  (ref) => DataDeletionRepositoryImpl(),
);

final legalAcceptanceQueueServiceProvider = Provider<LegalAcceptanceQueueService>(
  (ref) => LegalAcceptanceQueueService(),
);

final legalAcceptanceServiceProvider = Provider<LegalAcceptanceService>(
  (ref) => LegalAcceptanceService(
    documentRepository: ref.watch(legalDocumentRepositoryProvider),
    consentRepository: ref.watch(userConsentRepositoryProvider),
    queue: ref.watch(legalAcceptanceQueueServiceProvider),
  ),
);

final activeLegalDocumentsProvider =
    FutureProvider.autoDispose<List<LegalDocumentModel>>(
      (ref) => ref.watch(legalDocumentRepositoryProvider).getActiveDocuments(),
    );

final legalDocumentBySlugProvider =
    FutureProvider.autoDispose.family<LegalDocumentModel?, String>(
      (ref, slug) =>
          ref.watch(legalDocumentRepositoryProvider).getDocumentBySlug(slug),
    );

/// Bundle used by PolicyViewerScreen: the document, its current version in
/// the active locale, and whether the current user has already accepted it.
class PolicyViewerData {
  const PolicyViewerData({
    required this.document,
    required this.version,
    required this.isAccepted,
  });

  final LegalDocumentModel document;
  final LegalDocumentVersionModel? version;
  final bool isAccepted;
}

final policyViewerDataProvider =
    FutureProvider.autoDispose.family<PolicyViewerData?, String>((
      ref,
      slug,
    ) async {
      final documentRepo = ref.watch(legalDocumentRepositoryProvider);
      final document = await documentRepo.getDocumentBySlug(slug);
      if (document?.id == null) return null;

      final locale = ref.watch(languageProvider);
      final version = await documentRepo.getCurrentVersion(
        document!.id!,
        locale: locale,
      );

      final userId = SupabaseService.auth.currentUser?.id;
      var isAccepted = false;
      if (userId != null && version?.id != null) {
        isAccepted = await ref
            .watch(legalAcceptanceServiceProvider)
            .isUpToDate(userId: userId, documentId: document.id!, locale: locale);
      }
      return PolicyViewerData(
        document: document,
        version: version,
        isAccepted: isAccepted,
      );
    });

final legalCurrentVersionProvider =
    FutureProvider.autoDispose.family<LegalDocumentVersionModel?, String>((
      ref,
      documentId,
    ) {
      final locale = ref.watch(languageProvider);
      return ref
          .watch(legalDocumentRepositoryProvider)
          .getCurrentVersion(documentId, locale: locale);
    });

final legalVersionHistoryProvider =
    FutureProvider.autoDispose.family<List<LegalDocumentVersionModel>, String>((
      ref,
      documentId,
    ) {
      final locale = ref.watch(languageProvider);
      return ref
          .watch(legalDocumentRepositoryProvider)
          .getVersionHistory(documentId, locale: locale);
    });

final userLegalAcceptancesProvider =
    FutureProvider.autoDispose<List<UserLegalAcceptanceModel>>((ref) async {
      final userId = SupabaseService.auth.currentUser?.id;
      if (userId == null) return [];
      return ref.watch(userConsentRepositoryProvider).getUserAcceptances(userId);
    });

/// View-model pairing each raw acceptance row with its document/version, for
/// AcceptanceHistoryScreen. Not a DB-mapped model — assembled here (not in
/// the widget) since acceptances only store a `documentVersionId` FK.
class AcceptanceHistoryEntry {
  const AcceptanceHistoryEntry({
    required this.acceptance,
    required this.document,
    required this.version,
  });

  final UserLegalAcceptanceModel acceptance;
  final LegalDocumentModel? document;
  final LegalDocumentVersionModel? version;
}

final acceptanceHistoryEntriesProvider =
    FutureProvider.autoDispose<List<AcceptanceHistoryEntry>>((ref) async {
      final acceptances = await ref.watch(userLegalAcceptancesProvider.future);
      final repo = ref.watch(legalDocumentRepositoryProvider);
      final entries = <AcceptanceHistoryEntry>[];
      for (final acceptance in acceptances) {
        final version = await repo.getVersionById(acceptance.documentVersionId);
        final document = version == null
            ? null
            : await repo.getDocumentById(version.documentId);
        entries.add(
          AcceptanceHistoryEntry(
            acceptance: acceptance,
            document: document,
            version: version,
          ),
        );
      }
      return entries;
    });

final userLegalConsentsProvider =
    FutureProvider.autoDispose<List<LegalConsentSettingModel>>((ref) async {
      final userId = SupabaseService.auth.currentUser?.id;
      if (userId == null) return [];
      return ref.watch(userConsentRepositoryProvider).getUserConsents(userId);
    });

final dataDeletionRequestsProvider =
    FutureProvider.autoDispose<List<DataDeletionRequestModel>>((ref) async {
      final userId = SupabaseService.auth.currentUser?.id;
      if (userId == null) return [];
      return ref.watch(dataDeletionRepositoryProvider).getUserRequests(userId);
    });

/// Every active document the current user hasn't accepted the current
/// version of yet — drives PolicyUpdateNotificationBanner.
final pendingPolicyUpdatesProvider =
    FutureProvider.autoDispose<List<LegalDocumentModel>>((ref) async {
      final userId = SupabaseService.auth.currentUser?.id;
      if (userId == null) return [];
      final documents = await ref.watch(activeLegalDocumentsProvider.future);
      final service = ref.watch(legalAcceptanceServiceProvider);
      final locale = ref.watch(languageProvider);
      final pending = <LegalDocumentModel>[];
      for (final doc in documents) {
        if (doc.id == null) continue;
        final upToDate = await service.isUpToDate(
          userId: userId,
          documentId: doc.id!,
          locale: locale,
        );
        if (!upToDate) pending.add(doc);
      }
      return pending;
    });

final legalAcceptanceNotifierProvider =
    AsyncNotifierProvider<LegalAcceptanceNotifier, void>(
      LegalAcceptanceNotifier.new,
    );

class LegalAcceptanceNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> acceptCurrentVersion(String documentVersionId) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? false;
      await ref
          .read(legalAcceptanceServiceProvider)
          .acceptVersion(
            userId: userId,
            documentVersionId: documentVersionId,
            isOnline: isOnline,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(userLegalAcceptancesProvider);
      ref.invalidate(pendingPolicyUpdatesProvider);
    }
  }

  /// Replays any acceptance queued while offline — call this when
  /// [connectivityProvider] flips back to true (e.g. from the app shell).
  Future<void> flushOfflineQueue() async {
    try {
      await ref.read(legalAcceptanceServiceProvider).flushQueue();
    } finally {
      ref.invalidate(userLegalAcceptancesProvider);
      ref.invalidate(pendingPolicyUpdatesProvider);
    }
  }
}

final legalConsentNotifierProvider =
    AsyncNotifierProvider<LegalConsentNotifier, void>(
      LegalConsentNotifier.new,
    );

class LegalConsentNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> setConsent(LegalConsentType type, bool granted) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      await ref
          .read(userConsentRepositoryProvider)
          .setConsent(userId: userId, consentType: type, granted: granted);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(userLegalConsentsProvider);
    }
  }
}

final dataDeletionNotifierProvider =
    AsyncNotifierProvider<DataDeletionNotifier, void>(
      DataDeletionNotifier.new,
    );

class DataDeletionNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  /// Offline-first: writes directly when online; when offline, queues via
  /// the generic mutation outbox. Safe to replay on reconnect —
  /// `OfflineSyncCoordinator` checks for an already-pending request for
  /// this user before replaying, so a flaky-connection retry never
  /// creates two rows for the same request.
  Future<void> requestDeletion({String? notes}) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? false;
      if (!isOnline) {
        await ref.read(mutationOutboxServiceProvider).enqueue(
          type: OutboxMutationType.dataDeletionRequest,
          payload: {'userId': userId, 'notes': notes},
        );
      } else {
        await ref
            .read(dataDeletionRepositoryProvider)
            .createRequest(userId: userId, notes: notes);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(dataDeletionRequestsProvider);
    }
  }
}
