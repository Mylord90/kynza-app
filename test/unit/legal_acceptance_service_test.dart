import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/legal/legal_consent_setting_model.dart';
import 'package:kynza/core/models/legal/legal_document_model.dart';
import 'package:kynza/core/models/legal/legal_document_version_model.dart';
import 'package:kynza/core/models/legal/user_legal_acceptance_model.dart';
import 'package:kynza/core/services/legal_acceptance_queue_service.dart';
import 'package:kynza/features/legal/application/services/legal_acceptance_service.dart';
import 'package:kynza/features/legal/domain/repositories/legal_document_repository.dart';
import 'package:kynza/features/legal/domain/repositories/user_consent_repository.dart';

/// Stubs every method that isn't exercised by a given test — an
/// unexpected call throws instead of silently returning a default,
/// matching this codebase's existing fake-repository convention (see
/// test/unit/booking_flow_notifier_test.dart).
class _FakeLegalDocumentRepository implements LegalDocumentRepository {
  _FakeLegalDocumentRepository({this.currentVersion});

  LegalDocumentVersionModel? currentVersion;

  @override
  Future<List<LegalDocumentModel>> getActiveDocuments() =>
      throw UnimplementedError();

  @override
  Future<LegalDocumentModel?> getDocumentBySlug(String slug) =>
      throw UnimplementedError();

  @override
  Future<LegalDocumentModel?> getDocumentById(String id) =>
      throw UnimplementedError();

  @override
  Future<LegalDocumentVersionModel?> getVersionById(String id) =>
      throw UnimplementedError();

  @override
  Future<LegalDocumentVersionModel?> getCurrentVersion(
    String documentId, {
    String locale = 'fr',
  }) async => currentVersion;

  @override
  Future<List<LegalDocumentVersionModel>> getVersionHistory(
    String documentId, {
    String locale = 'fr',
  }) => throw UnimplementedError();
}

class _FakeUserConsentRepository implements UserConsentRepository {
  _FakeUserConsentRepository({List<UserLegalAcceptanceModel> existingAcceptances = const []})
    : acceptedCalls = [...existingAcceptances];

  /// Doubles as both "the calls made" and "what getUserAcceptances would
  /// now return" — a real (if tiny) stateful fake, so a test can call
  /// acceptDocumentVersion and then observe getUserAcceptances reflect it,
  /// exactly like the real table would.
  final List<UserLegalAcceptanceModel> acceptedCalls;

  @override
  Future<List<UserLegalAcceptanceModel>> getUserAcceptances(String userId) async =>
      acceptedCalls;

  @override
  Future<UserLegalAcceptanceModel> acceptDocumentVersion({
    required String userId,
    required String documentVersionId,
    String? appVersion,
    String? platform,
  }) async {
    final acceptance = UserLegalAcceptanceModel(
      userId: userId,
      documentVersionId: documentVersionId,
    );
    acceptedCalls.add(acceptance);
    return acceptance;
  }

  @override
  Future<List<LegalConsentSettingModel>> getUserConsents(String userId) =>
      throw UnimplementedError();

  @override
  Future<LegalConsentSettingModel> setConsent({
    required String userId,
    required LegalConsentType consentType,
    required bool granted,
  }) => throw UnimplementedError();
}

void main() {
  late Directory tempDir;
  late LegalAcceptanceQueueService queue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_legal_queue_test');
    Hive.init(tempDir.path);
    await Hive.openBox(LegalAcceptanceQueueService.boxName);
    queue = LegalAcceptanceQueueService();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(LegalAcceptanceQueueService.boxName);
    await tempDir.delete(recursive: true);
  });

  group('LegalAcceptanceService.acceptVersion — online vs offline', () {
    test('writes directly to the repository when online, queue stays empty', () async {
      final consentRepo = _FakeUserConsentRepository();
      final service = LegalAcceptanceService(
        documentRepository: _FakeLegalDocumentRepository(),
        consentRepository: consentRepo,
        queue: queue,
      );

      await service.acceptVersion(
        userId: 'u-1',
        documentVersionId: 'v-1',
        isOnline: true,
      );

      expect(consentRepo.acceptedCalls, hasLength(1));
      expect(queue.pending(), isEmpty);
    });

    test('queues in Hive instead of calling the repository when offline', () async {
      final consentRepo = _FakeUserConsentRepository();
      final service = LegalAcceptanceService(
        documentRepository: _FakeLegalDocumentRepository(),
        consentRepository: consentRepo,
        queue: queue,
      );

      await service.acceptVersion(
        userId: 'u-1',
        documentVersionId: 'v-1',
        isOnline: false,
      );

      expect(consentRepo.acceptedCalls, isEmpty);
      expect(queue.pending(), hasLength(1));
      expect(queue.pending().single['documentVersionId'], 'v-1');
    });
  });

  group('LegalAcceptanceService.flushQueue — offline-to-online sync proof', () {
    test(
      'a queued offline acceptance produces exactly one server-side write on reconnect',
      () async {
        final consentRepo = _FakeUserConsentRepository();
        final service = LegalAcceptanceService(
          documentRepository: _FakeLegalDocumentRepository(),
          consentRepository: consentRepo,
          queue: queue,
        );

        // Simulate: offline accept, then reconnect.
        await service.acceptVersion(
          userId: 'u-1',
          documentVersionId: 'v-1',
          isOnline: false,
        );
        expect(consentRepo.acceptedCalls, isEmpty);

        await service.flushQueue();

        // Exactly one server-side effect — not zero, not duplicated.
        expect(consentRepo.acceptedCalls, hasLength(1));
        expect(consentRepo.acceptedCalls.single.documentVersionId, 'v-1');
        expect(queue.pending(), isEmpty);
      },
    );

    test('flushing an empty queue is a no-op', () async {
      final consentRepo = _FakeUserConsentRepository();
      final service = LegalAcceptanceService(
        documentRepository: _FakeLegalDocumentRepository(),
        consentRepository: consentRepo,
        queue: queue,
      );

      await service.flushQueue();

      expect(consentRepo.acceptedCalls, isEmpty);
    });
  });

  group('LegalAcceptanceService.isUpToDate', () {
    test('returns true when nothing has been published yet', () async {
      final service = LegalAcceptanceService(
        documentRepository: _FakeLegalDocumentRepository(currentVersion: null),
        consentRepository: _FakeUserConsentRepository(),
        queue: queue,
      );

      final upToDate = await service.isUpToDate(
        userId: 'u-1',
        documentId: 'doc-1',
      );

      expect(upToDate, isTrue);
    });

    test('returns false when the user has no matching acceptance', () async {
      final service = LegalAcceptanceService(
        documentRepository: _FakeLegalDocumentRepository(
          currentVersion: const LegalDocumentVersionModel(
            id: 'v-current',
            documentId: 'doc-1',
            versionNumber: 2,
            contentMarkdown: 'v2 text',
          ),
        ),
        consentRepository: _FakeUserConsentRepository(existingAcceptances: [
          const UserLegalAcceptanceModel(
            userId: 'u-1',
            documentVersionId: 'v-old',
          ),
        ]),
        queue: queue,
      );

      final upToDate = await service.isUpToDate(
        userId: 'u-1',
        documentId: 'doc-1',
      );

      expect(upToDate, isFalse);
    });

    test('returns true when the user already accepted the current version row', () async {
      final service = LegalAcceptanceService(
        documentRepository: _FakeLegalDocumentRepository(
          currentVersion: const LegalDocumentVersionModel(
            id: 'v-current',
            documentId: 'doc-1',
            versionNumber: 2,
            contentMarkdown: 'v2 text',
          ),
        ),
        consentRepository: _FakeUserConsentRepository(existingAcceptances: [
          const UserLegalAcceptanceModel(
            userId: 'u-1',
            documentVersionId: 'v-current',
          ),
        ]),
        queue: queue,
      );

      final upToDate = await service.isUpToDate(
        userId: 'u-1',
        documentId: 'doc-1',
      );

      expect(upToDate, isTrue);
    });
  });

  group('Accept-new-version gate flow (integration across service + repos)', () {
    test(
      'a document starts gated, accepting the current version un-gates it, '
      'and an older accepted version does not un-gate a newer one',
      () async {
        const currentVersion = LegalDocumentVersionModel(
          id: 'v-2',
          documentId: 'doc-1',
          versionNumber: 2,
          contentMarkdown: 'v2 text',
        );
        final documentRepo = _FakeLegalDocumentRepository(
          currentVersion: currentVersion,
        );
        final consentRepo = _FakeUserConsentRepository(
          existingAcceptances: [
            const UserLegalAcceptanceModel(
              userId: 'u-1',
              documentVersionId: 'v-1', // the OLD version, already accepted
            ),
          ],
        );
        final service = LegalAcceptanceService(
          documentRepository: documentRepo,
          consentRepository: consentRepo,
          queue: queue,
        );

        // Gated: user only ever accepted v1, but v2 is now current.
        expect(
          await service.isUpToDate(userId: 'u-1', documentId: 'doc-1'),
          isFalse,
        );

        // User accepts the new version.
        await service.acceptVersion(
          userId: 'u-1',
          documentVersionId: currentVersion.id!,
          isOnline: true,
        );

        // Un-gated: the acceptance for v2 now exists.
        expect(
          await service.isUpToDate(userId: 'u-1', documentId: 'doc-1'),
          isTrue,
        );
      },
    );
  });
}
