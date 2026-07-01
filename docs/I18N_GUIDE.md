# KYNZA — Internationalisation Guide

Complete reference for the i18n system. All ~100 screens use `context.l10n.xxx`;
no hardcoded French strings remain in the codebase.

---

## 1. Architecture Overview

```
lib/
├── core/
│   └── localization/
│       ├── models/
│       │   └── language_enum.dart          # AppLanguage enum (supported languages)
│       ├── services/
│       │   ├── locale_detection_service.dart   # System locale → AppLanguage
│       │   ├── date_formatter_service.dart     # Locale-aware date formatting
│       │   └── currency_formatter_service.dart # BIF/FBu (immutable format)
│       ├── extensions/
│       │   └── build_context_l10n_extension.dart  # context.l10n shorthand
│       └── widgets/
│           └── language_selector_tile.dart    # Used by LanguageSettingsScreen
├── l10n/
│   ├── app_fr.arb    # French (primary, ~1 100 keys)
│   └── app_en.arb    # English (~1 100 keys)
└── features/
    └── settings/presentation/screens/
        └── language_settings_screen.dart   # Language picker UI
```

Generated (do not edit manually):

```
lib/
└── l10n/
    ├── app_localizations.dart
    ├── app_localizations_fr.dart
    └── app_localizations_en.dart
```

---

## 2. Supported Languages

| Code | Name | Status | RTL |
|------|------|--------|-----|
| `fr` | Français | Active (default) | No |
| `en` | English | Active | No |
| `rn` | Kirundi | Planned | No |
| `sw` | Swahili | Planned | No |

French is the absolute fallback. If the system locale matches no supported
language, French is always returned.

---

## 3. Auto-Detection Flow

```
App start
  │
  ├── LanguageNotifier.build()
  │     └── SessionService.getLanguage()  ← Hive (persisted preference)
  │           │
  │           ├── Found → use stored code
  │           └── Not found → LocaleDetectionService.detectSystemLanguage()
  │                           → PlatformDispatcher.instance.locales
  │                           → AppLanguage.fromCode(locale.languageCode)
  │                           → fallback: AppLanguage.french
  │
  └── currentLocaleProvider → Locale(languageCode)
        │
        └── MaterialApp.router(locale: locale, ...)
              └── Flutter rebuilds full widget tree with new locale
```

When the user picks a language in `LanguageSettingsScreen`:
1. `LanguageNotifier.setLanguage(code)` writes to Hive (local, instant).
2. Supabase `users.preferred_language` is updated asynchronously (sync failure is silent; local change always wins).
3. `currentLocaleProvider` emits the new `Locale`.
4. `MaterialApp` rebuilds. Language change is complete in < 100 ms.

---

## 4. Using Translations in a Widget

```dart
import 'package:kynza/core/localization/extensions/build_context_l10n_extension.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;   // AppLocalizations instance

    return Column(
      children: [
        Text(l10n.bookingConfirmButton),
        ElevatedButton(
          onPressed: () {},
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
```

`context.l10n` is defined by the `BuildContextL10n` extension:

```dart
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

Never call `AppLocalizations.of(context)` directly — use `context.l10n`.
Never hardcode French (or any language) strings in widget files.

---

## 5. Key Naming Convention

All ARB keys use camelCase with a feature prefix:

| Prefix | Scope |
|--------|-------|
| `common` | Shared across features (Cancel, Save, Retry…) |
| `auth` | Authentication screens |
| `booking` | Booking flow |
| `home` | Home screens (owner/staff/client) |
| `settings` | Settings screens |
| `staff` | Staff management |
| `team` | Team & commissions |
| `marketing` | Marketing & campaigns |
| `loyalty` | Loyalty cards |
| `dashboard` | Analytics dashboard |
| `automation` | Workflow builder |
| `subscription` | Plans & billing |
| `search` | Search screens |
| `notification` | Notification settings |
| `permissions` | RBAC permission groups |
| `journey` | Client journey |
| `referral` | Referral program |
| `data` | Data platform (backup, templates) |
| `evolution` | Feature flags, maintenance, version |
| `error` | Error states |
| `empty` | Empty states |
| `offline` | Offline banner |
| `nav` | Bottom navigation labels |
| `validator` | Form validation messages |

Examples:

```
authLoginTitle          → screen title on the login screen
authLoginSubmitButton   → primary CTA on login
bookingConfirmButton    → confirm button in booking flow
staffFilterActive       → "Active" tab label in staff list
homeOwnerClientRdvCount → pluralized RDV count on owner home
```

---

## 6. ARB File Structure

### Header

```json
{
  "@@locale": "fr",

  "appName": "KYNZA",
  "@appName": { "description": "Nom de l'application — ne jamais traduire" },
```

### Simple string

```json
  "commonCancel": "Annuler",
```

### String with placeholder

```json
  "authForgotPasswordSuccessSubtitle": "Si un compte existe pour {email}, vous recevrez un lien dans quelques instants.",
  "@authForgotPasswordSuccessSubtitle": {
    "placeholders": { "email": { "type": "String" } }
  },
```

### Plural string (ICU format)

```json
  "bookingCount": "{count, plural, =0{Aucun rendez-vous} =1{1 rendez-vous} other{{count} rendez-vous}}",
  "@bookingCount": {
    "placeholders": { "count": { "type": "int" } }
  },
```

### Adding a new key (step-by-step)

1. Add the key to `lib/l10n/app_fr.arb` with the French value and optional `@` metadata.
2. Add the same key to `lib/l10n/app_en.arb` with the English value.
3. Run `flutter gen-l10n` (regenerates `app_localizations_fr.dart` and `app_localizations_en.dart`).
4. Use `context.l10n.myNewKey` in the widget.

Both ARB files must contain every key; `flutter gen-l10n` fails if a key is
missing from any locale.

---

## 7. ICU Plural and Parameter Format

### Plural

```json
"homeOwnerClientRdvCount": "{count, plural, =0{Aucun RDV} =1{1 RDV} other{{count} RDV}}",
"@homeOwnerClientRdvCount": {
  "placeholders": { "count": { "type": "int" } }
},
```

In Dart:

```dart
l10n.homeOwnerClientRdvCount(booking.count)
```

### String parameter

```dart
l10n.authVerifyEmailSubtitle(user.email)
// → "Un lien de confirmation a été envoyé à user@example.com"
```

### Multiple parameters

```dart
l10n.settingsAboutCopyright('2026')
// → "© 2026 KYNZA. Tous droits réservés."
```

---

## 8. DateFormatterService

`DateFormatterService` is locale-aware and formats dates in the active language.

```dart
final formatter = DateFormatterService(ref.watch(languageProvider));
// or
final formatter = DateFormatterService.of(locale);

formatter.formatLong(date);             // "14 juin 2025" / "June 14, 2025"
formatter.formatShort(date);            // "14/06/2025" / "06/14/2025"
formatter.formatDayMonth(date);         // "14 juin" / "June 14"
formatter.formatWeekdayDayMonth(date);  // "lun. 14 juin" / "Mon, June 14"
formatter.formatTime(date);             // "09:30"  (locale-independent, 24 h)
formatter.formatTimeRange(start, end);  // "09:30 – 10:00"
formatter.formatAppointment(date);      // "lun. 14 juin · 09:30"
```

---

## 9. CurrencyFormatterService

The BIF/FBu format is **immutable** — it must never change regardless of locale.

```
"45 000 FBu"  ← the only accepted format (locale fr, space separator, FBu suffix)
```

```dart
final currency = CurrencyFormatterService.of(locale);

currency.formatBif(45000);   // "45 000 FBu"
currency.confidential();     // "••••• FBu"
currency.parseBif('45 000 FBu');  // 45000
```

`CurrencyFormatterService` delegates to `CurrencyFormatter`
(`lib/core/utils/currency_formatter.dart`). The locale field is reserved for
future multi-currency support; for BIF all locales produce the same output.

Do not add a new ARB key for BIF amounts. Use `CurrencyFormatter.formatBif()`
(or `context.l10n` wrappers that call it) everywhere.

---

## 10. RTL Preparation

The `isRtl` field on `AppLanguage` marks right-to-left languages. No RTL
language is active in V1; the field is pre-wired for Kirundi/Swahili (both LTR)
and future Arabic/Hebrew additions.

```dart
final lang = AppLanguage.fromCodeOrFallback(code);
if (lang.isRtl) { /* layout adjustments, if any */ }
```

Flutter's `MaterialApp` handles text direction automatically from the active
`Locale` when a RTL locale is set. No manual `Directionality` widget is needed
for standard layouts.

---

## 11. Running i18n Tests

```bash
# All localization unit tests (detection, provider, ARB coverage)
flutter test test/core/localization/

# ARB coverage specifically (verifies keys non-empty in both locales)
flutter test test/core/localization/l10n_coverage_test.dart

# Full suite (191 tests, includes 27 localization tests)
flutter test

# Regenerate after ARB changes
flutter gen-l10n

# Static analysis
flutter analyze
```