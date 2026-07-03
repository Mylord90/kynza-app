import 'package:flutter/widgets.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';

String legalDocumentTypeLabel(BuildContext context, LegalDocumentType type) =>
    switch (type) {
      LegalDocumentType.privacyPolicy => context.l10n.legalDocTypePrivacyPolicy,
      LegalDocumentType.termsOfService =>
        context.l10n.legalDocTypeTermsOfService,
      LegalDocumentType.cookiePolicy => context.l10n.legalDocTypeCookiePolicy,
      LegalDocumentType.acceptableUsePolicy =>
        context.l10n.legalDocTypeAcceptableUsePolicy,
      LegalDocumentType.refundPolicy => context.l10n.legalDocTypeRefundPolicy,
      LegalDocumentType.communityGuidelines =>
        context.l10n.legalDocTypeCommunityGuidelines,
      LegalDocumentType.dataDeletionPolicy =>
        context.l10n.legalDocTypeDataDeletionPolicy,
      LegalDocumentType.supportPolicy => context.l10n.legalDocTypeSupportPolicy,
      LegalDocumentType.legalNotices => context.l10n.legalDocTypeLegalNotices,
    };

String legalConsentTypeLabel(BuildContext context, LegalConsentType type) =>
    switch (type) {
      LegalConsentType.marketingEmails =>
        context.l10n.consentTypeMarketingEmailsLabel,
      LegalConsentType.analytics => context.l10n.consentTypeAnalyticsLabel,
      LegalConsentType.pushNotifications =>
        context.l10n.consentTypePushNotificationsLabel,
      LegalConsentType.dataProcessing =>
        context.l10n.consentTypeDataProcessingLabel,
    };

String legalConsentTypeSubtitle(BuildContext context, LegalConsentType type) =>
    switch (type) {
      LegalConsentType.marketingEmails =>
        context.l10n.consentTypeMarketingEmailsSubtitle,
      LegalConsentType.analytics => context.l10n.consentTypeAnalyticsSubtitle,
      LegalConsentType.pushNotifications =>
        context.l10n.consentTypePushNotificationsSubtitle,
      LegalConsentType.dataProcessing =>
        context.l10n.consentTypeDataProcessingSubtitle,
    };

String dataDeletionStatusLabel(
  BuildContext context,
  DataDeletionStatus status,
) => switch (status) {
  DataDeletionStatus.pending => context.l10n.dataRightsRequestStatusPending,
  DataDeletionStatus.inReview => context.l10n.dataRightsRequestStatusInReview,
  DataDeletionStatus.completed => context.l10n.dataRightsRequestStatusCompleted,
  DataDeletionStatus.rejected => context.l10n.dataRightsRequestStatusRejected,
};
