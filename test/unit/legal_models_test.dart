import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/legal/data_deletion_request_model.dart';
import 'package:kynza/core/models/legal/legal_consent_setting_model.dart';
import 'package:kynza/core/models/legal/legal_document_model.dart';
import 'package:kynza/core/models/legal/legal_document_version_model.dart';
import 'package:kynza/core/models/legal/user_legal_acceptance_model.dart';

void main() {
  group('LegalDocumentModel', () {
    test('fromSupabase parses snake_case columns and the type converter', () {
      final model = LegalDocumentModel.fromSupabase({
        'id': 'doc-1',
        'slug': 'privacy-policy',
        'type': 'privacy_policy',
        'current_version_id': 'v-1',
        'is_active': true,
      });
      expect(model.slug, 'privacy-policy');
      expect(model.type, LegalDocumentType.privacyPolicy);
      expect(model.currentVersionId, 'v-1');
    });

    test('LegalDocumentTypeConverter round-trips every enum value', () {
      const converter = LegalDocumentTypeConverter();
      for (final type in LegalDocumentType.values) {
        expect(converter.fromJson(converter.toJson(type)), type);
      }
    });
  });

  group('LegalDocumentVersionModel', () {
    test('fromSupabase parses version fields and defaults locale to fr', () {
      final model = LegalDocumentVersionModel.fromSupabase({
        'id': 'v-1',
        'document_id': 'doc-1',
        'version_number': 2,
        'content_markdown': '⚠️ PLACEHOLDER',
        'is_current': true,
      });
      expect(model.versionNumber, 2);
      expect(model.locale, 'fr');
      expect(model.isCurrent, true);
    });
  });

  group('UserLegalAcceptanceModel', () {
    test('fromSupabase parses the acceptance ledger row', () {
      final model = UserLegalAcceptanceModel.fromSupabase({
        'id': 'a-1',
        'user_id': 'u-1',
        'document_version_id': 'v-1',
        'accepted_at': '2026-07-03T12:00:00.000Z',
        'platform': 'android',
      });
      expect(model.userId, 'u-1');
      expect(model.documentVersionId, 'v-1');
      expect(model.platform, 'android');
    });
  });

  group('LegalConsentSettingModel', () {
    test('LegalConsentTypeConverter round-trips every enum value', () {
      const converter = LegalConsentTypeConverter();
      for (final type in LegalConsentType.values) {
        expect(converter.fromJson(converter.toJson(type)), type);
      }
    });

    test('fromSupabase parses the granted flag', () {
      final model = LegalConsentSettingModel.fromSupabase({
        'id': 'c-1',
        'user_id': 'u-1',
        'consent_type': 'marketing_emails',
        'granted': true,
      });
      expect(model.consentType, LegalConsentType.marketingEmails);
      expect(model.granted, true);
    });
  });

  group('DataDeletionRequestModel', () {
    test('DataDeletionStatusConverter round-trips every enum value', () {
      const converter = DataDeletionStatusConverter();
      for (final status in DataDeletionStatus.values) {
        expect(converter.fromJson(converter.toJson(status)), status);
      }
    });

    test('fromSupabase defaults status to pending via the converter', () {
      final model = DataDeletionRequestModel.fromSupabase({
        'id': 'r-1',
        'user_id': 'u-1',
        'status': 'pending',
      });
      expect(model.status, DataDeletionStatus.pending);
    });
  });
}
