import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/l10n/app_localizations.dart';
import 'package:kynza/l10n/app_localizations_en.dart';
import 'package:kynza/l10n/app_localizations_fr.dart';

void main() {
  group('l10n coverage', () {
    late AppLocalizations fr;
    late AppLocalizations en;

    setUpAll(() {
      fr = AppLocalizationsFr();
      en = AppLocalizationsEn();
    });

    test('French and English share the same locale codes', () {
      expect(fr.localeName, 'fr');
      expect(en.localeName, 'en');
    });

    test('common keys are non-empty in both locales', () {
      for (final l10n in [fr, en]) {
        expect(l10n.commonCancel, isNotEmpty);
        expect(l10n.commonConfirm, isNotEmpty);
        expect(l10n.commonSave, isNotEmpty);
        expect(l10n.commonRetry, isNotEmpty);
      }
    });

    test('auth keys are non-empty in both locales', () {
      for (final l10n in [fr, en]) {
        expect(l10n.authLoginTitle, isNotEmpty);
        expect(l10n.authRegisterTitle, isNotEmpty);
        expect(l10n.authForgotPasswordTitle, isNotEmpty);
        expect(l10n.authVerifyEmailTitle, isNotEmpty);
        expect(l10n.authResetPasswordTitle, isNotEmpty);
        expect(l10n.authCompleteProfileTitle, isNotEmpty);
        expect(l10n.authDividerLabel, isNotEmpty);
        expect(l10n.authOauthComingSoon, isNotEmpty);
      }
    });

    test('offline banner keys are non-empty in both locales', () {
      for (final l10n in [fr, en]) {
        expect(l10n.offlineBannerMessage, isNotEmpty);
        expect(l10n.offlineBannerSynced, isNotEmpty);
      }
    });

    test('settings keys are non-empty in both locales', () {
      for (final l10n in [fr, en]) {
        expect(l10n.settingsTitle, isNotEmpty);
        expect(l10n.settingsLanguageTitle, isNotEmpty);
        expect(l10n.settingsAboutTitle, isNotEmpty);
      }
    });

    test('BIF format key is not translated (currency is locale-invariant)', () {
      // The BIF format "45 000 FBu" is handled by CurrencyFormatter — not ARB.
      // Verify the appName key is never empty (smoke test for ARB loading).
      expect(fr.appName, 'KYNZA');
      expect(en.appName, 'KYNZA');
    });

    test('parameterized auth keys interpolate correctly in French', () {
      const email = 'test@example.com';
      expect(fr.authForgotPasswordSuccessSubtitle(email), contains(email));
      expect(fr.authVerifyEmailSubtitle(email), contains(email));
    });

    test('parameterized auth keys interpolate correctly in English', () {
      const email = 'test@example.com';
      expect(en.authForgotPasswordSuccessSubtitle(email), contains(email));
      expect(en.authVerifyEmailSubtitle(email), contains(email));
    });

    test('resend cooldown key interpolates seconds in both locales', () {
      for (final l10n in [fr, en]) {
        expect(l10n.authVerifyEmailResendCooldown('42'), contains('42'));
      }
    });

    test('about copyright key interpolates year in both locales', () {
      for (final l10n in [fr, en]) {
        expect(l10n.settingsAboutCopyright('2026'), contains('2026'));
        expect(l10n.settingsAboutCopyright('2026'), contains('KYNZA'));
      }
    });

    test('staff filter keys non-empty in both locales', () {
      for (final l10n in [fr, en]) {
        expect(l10n.staffFilterActive, isNotEmpty);
        expect(l10n.staffFilterPending, isNotEmpty);
        expect(l10n.staffFilterDisabled, isNotEmpty);
      }
    });

    test(
      'French strings are distinct from English strings for key samples',
      () {
        expect(fr.authLoginTitle, isNot(equals(en.authLoginTitle)));
        expect(fr.commonCancel, isNot(equals(en.commonCancel)));
        expect(fr.offlineBannerMessage, isNot(equals(en.offlineBannerMessage)));
      },
    );

    test('AppLocalizations.supportedLocales includes fr and en', () {
      final codes = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toList();
      expect(codes, containsAll(['fr', 'en']));
    });
  });
}
