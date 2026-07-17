import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// Nom de l'application — ne jamais traduire
  ///
  /// In fr, this message translates to:
  /// **'KYNZA'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @commonShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get commonShare;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get commonSeeAll;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get commonLoading;

  /// No description provided for @commonContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// No description provided for @commonNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get commonNext;

  /// No description provided for @commonPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get commonPrevious;

  /// No description provided for @commonDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get commonDone;

  /// No description provided for @commonSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get commonSearch;

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get commonAdd;

  /// No description provided for @commonCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get commonCreate;

  /// No description provided for @commonSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get commonSend;

  /// No description provided for @commonYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get commonToday;

  /// No description provided for @commonError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get commonError;

  /// No description provided for @commonSelect.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get commonSelect;

  /// No description provided for @commonEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get commonEnable;

  /// No description provided for @commonDisable.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get commonDisable;

  /// No description provided for @commonReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get commonReset;

  /// No description provided for @commonExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get commonExport;

  /// No description provided for @commonCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In fr, this message translates to:
  /// **'Copié !'**
  String get commonCopied;

  /// No description provided for @commonLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Charger plus'**
  String get commonLoadMore;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue.'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes hors ligne.'**
  String get errorOffline;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion internet.'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée, veuillez vous reconnecter.'**
  String get errorUnauthorized;

  /// No description provided for @errorLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données.'**
  String get errorLoadFailed;

  /// No description provided for @emptyStateDefaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien à afficher'**
  String get emptyStateDefaultTitle;

  /// No description provided for @offlineBannerMessage.
  ///
  /// In fr, this message translates to:
  /// **'📴 Hors connexion • Données en cache'**
  String get offlineBannerMessage;

  /// No description provided for @offlineBannerSynced.
  ///
  /// In fr, this message translates to:
  /// **'✓ Synchronisé'**
  String get offlineBannerSynced;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get navCalendar;

  /// No description provided for @navDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navClients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get navClients;

  /// No description provided for @navMarketing.
  ///
  /// In fr, this message translates to:
  /// **'Marketing'**
  String get navMarketing;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @navNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get navSettings;

  /// No description provided for @navExplorer.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get navExplorer;

  /// No description provided for @navMyBookings.
  ///
  /// In fr, this message translates to:
  /// **'Mes RDV'**
  String get navMyBookings;

  /// No description provided for @navLoyalty.
  ///
  /// In fr, this message translates to:
  /// **'Fidélité'**
  String get navLoyalty;

  /// No description provided for @navToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get navToday;

  /// No description provided for @navPerformance.
  ///
  /// In fr, this message translates to:
  /// **'Performances'**
  String get navPerformance;

  /// No description provided for @navTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get navTeam;

  /// No description provided for @onboardingHeadlinePart1.
  ///
  /// In fr, this message translates to:
  /// **'Toute la beauté et le bien-être, réunis dans '**
  String get onboardingHeadlinePart1;

  /// No description provided for @onboardingHeadlineAccent.
  ///
  /// In fr, this message translates to:
  /// **'une seule application'**
  String get onboardingHeadlineAccent;

  /// No description provided for @onboardingHeadlinePart2.
  ///
  /// In fr, this message translates to:
  /// **'.'**
  String get onboardingHeadlinePart2;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservez facilement vos rendez-vous auprès des meilleurs salons, barbiers, spas, nail artists, maquilleurs et experts skincare.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingProgressStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String onboardingProgressStep(int current, int total);

  /// No description provided for @onboardingScreen2HeadlineLine1.
  ///
  /// In fr, this message translates to:
  /// **'Toute la beauté.'**
  String get onboardingScreen2HeadlineLine1;

  /// No description provided for @onboardingScreen2HeadlineLine2.
  ///
  /// In fr, this message translates to:
  /// **'Une seule app.'**
  String get onboardingScreen2HeadlineLine2;

  /// No description provided for @onboardingScreen2Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez des professionnels de confiance, réservez en un instant, et vivez une expérience premium — tout au même endroit.'**
  String get onboardingScreen2Subtitle;

  /// No description provided for @onboardingScreen3Headline.
  ///
  /// In fr, this message translates to:
  /// **'Votre prochaine expérience beauté commence ici.'**
  String get onboardingScreen3Headline;

  /// No description provided for @onboardingScreen3Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservez facilement vos soins, découvrez les meilleurs professionnels et profitez d\'une expérience beauté pensée pour vous.'**
  String get onboardingScreen3Subtitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingAlreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un compte ?'**
  String get onboardingAlreadyHaveAccount;

  /// No description provided for @onboardingSignInLinkHint.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre l\'écran de connexion'**
  String get onboardingSignInLinkHint;

  /// No description provided for @authLogin.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authLogin;

  /// No description provided for @authLogout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get authLogout;

  /// No description provided for @authRegister.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authRegister;

  /// No description provided for @authForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authForgotPassword;

  /// No description provided for @authLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour continuer'**
  String get authLoginSubtitle;

  /// No description provided for @authLoginEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authLoginEmailLabel;

  /// No description provided for @authLoginPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authLoginPasswordLabel;

  /// No description provided for @authLoginSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter →'**
  String get authLoginSubmitButton;

  /// No description provided for @authLoginForgotPasswordLink.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authLoginForgotPasswordLink;

  /// No description provided for @authLoginNoAccountLink.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? S\'inscrire'**
  String get authLoginNoAccountLink;

  /// No description provided for @authRegisterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez KYNZA en quelques secondes'**
  String get authRegisterSubtitle;

  /// No description provided for @authRegisterFullNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get authRegisterFullNameLabel;

  /// No description provided for @authRegisterEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authRegisterEmailLabel;

  /// No description provided for @authRegisterConfirmPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authRegisterConfirmPasswordLabel;

  /// No description provided for @authRegisterSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte →'**
  String get authRegisterSubmitButton;

  /// No description provided for @authRegisterAlreadyHaveAccountLink.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Se connecter'**
  String get authRegisterAlreadyHaveAccountLink;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevez un lien de réinitialisation par email'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authForgotPasswordEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authForgotPasswordEmailLabel;

  /// No description provided for @authForgotPasswordSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien →'**
  String get authForgotPasswordSubmitButton;

  /// No description provided for @authForgotPasswordBackLink.
  ///
  /// In fr, this message translates to:
  /// **'← Retour à la connexion'**
  String get authForgotPasswordBackLink;

  /// No description provided for @authForgotPasswordSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Email envoyé !'**
  String get authForgotPasswordSuccessTitle;

  /// No description provided for @authForgotPasswordSuccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Si un compte existe pour {email}, vous recevrez un lien de réinitialisation dans quelques instants.'**
  String authForgotPasswordSuccessSubtitle(String email);

  /// No description provided for @authForgotPasswordCheckSpam.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez vos spams.'**
  String get authForgotPasswordCheckSpam;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre email'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un lien de confirmation a été envoyé à {email}'**
  String authVerifyEmailSubtitle(String email);

  /// No description provided for @authVerifyEmailCheckSpam.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez vos spams.'**
  String get authVerifyEmailCheckSpam;

  /// No description provided for @authVerifyEmailResendButton.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email'**
  String get authVerifyEmailResendButton;

  /// No description provided for @authVerifyEmailResendCooldown.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email (00:{seconds})'**
  String authVerifyEmailResendCooldown(String seconds);

  /// No description provided for @authVerifyEmailChangeAddress.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser une autre adresse'**
  String get authVerifyEmailChangeAddress;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordNewLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get authResetPasswordNewLabel;

  /// No description provided for @authResetPasswordConfirmLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authResetPasswordConfirmLabel;

  /// No description provided for @authResetPasswordSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser →'**
  String get authResetPasswordSubmitButton;

  /// No description provided for @authResetPasswordSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe réinitialisé.'**
  String get authResetPasswordSuccess;

  /// No description provided for @authResetPasswordInvalidLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien invalide ou expiré.'**
  String get authResetPasswordInvalidLink;

  /// No description provided for @authCompleteProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Finalisez votre profil'**
  String get authCompleteProfileTitle;

  /// No description provided for @authCompleteProfileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques informations pour démarrer'**
  String get authCompleteProfileSubtitle;

  /// No description provided for @authCompleteProfileFullNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get authCompleteProfileFullNameLabel;

  /// No description provided for @authCompleteProfileSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Commencer →'**
  String get authCompleteProfileSubmitButton;

  /// No description provided for @authCompleteProfileRoleClientLabel.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get authCompleteProfileRoleClientLabel;

  /// No description provided for @authCompleteProfileRoleClientSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservez des soins'**
  String get authCompleteProfileRoleClientSubtitle;

  /// No description provided for @authCompleteProfileRoleStaffLabel.
  ///
  /// In fr, this message translates to:
  /// **'Staff'**
  String get authCompleteProfileRoleStaffLabel;

  /// No description provided for @authCompleteProfileRoleStaffSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Praticien dans un salon'**
  String get authCompleteProfileRoleStaffSubtitle;

  /// No description provided for @authCompleteProfileRoleOwnerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get authCompleteProfileRoleOwnerLabel;

  /// No description provided for @authCompleteProfileRoleOwnerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre salon'**
  String get authCompleteProfileRoleOwnerSubtitle;

  /// No description provided for @authOauthComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Disponible bientôt'**
  String get authOauthComingSoon;

  /// No description provided for @authOauthGoogleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authOauthGoogleLabel;

  /// No description provided for @authOauthFacebookLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Facebook'**
  String get authOauthFacebookLabel;

  /// No description provided for @authOauthAppleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get authOauthAppleLabel;

  /// No description provided for @authDividerLabel.
  ///
  /// In fr, this message translates to:
  /// **'ou continuer avec'**
  String get authDividerLabel;

  /// No description provided for @validatorEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Email requis.'**
  String get validatorEmailRequired;

  /// No description provided for @validatorEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide.'**
  String get validatorEmailInvalid;

  /// No description provided for @validatorPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis.'**
  String get validatorPasswordRequired;

  /// No description provided for @validatorPasswordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum.'**
  String get validatorPasswordMinLength;

  /// No description provided for @validatorPasswordNeedUppercase.
  ///
  /// In fr, this message translates to:
  /// **'1 majuscule minimum.'**
  String get validatorPasswordNeedUppercase;

  /// No description provided for @validatorPasswordNeedDigit.
  ///
  /// In fr, this message translates to:
  /// **'1 chiffre minimum.'**
  String get validatorPasswordNeedDigit;

  /// No description provided for @validatorPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Numéro requis.'**
  String get validatorPhoneRequired;

  /// No description provided for @validatorPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide (8 chiffres).'**
  String get validatorPhoneInvalid;

  /// No description provided for @validatorFieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'{field} requis.'**
  String validatorFieldRequired(String field);

  /// No description provided for @validatorConfirmPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation requise.'**
  String get validatorConfirmPasswordRequired;

  /// No description provided for @validatorPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get validatorPasswordMismatch;

  /// No description provided for @fieldPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get fieldPhoneLabel;

  /// No description provided for @fieldPhoneHelper.
  ///
  /// In fr, this message translates to:
  /// **'Pour les notifications WhatsApp uniquement.'**
  String get fieldPhoneHelper;

  /// No description provided for @fieldPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get fieldPasswordLabel;

  /// No description provided for @homeOwnerDashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard KYNZA'**
  String get homeOwnerDashboardTitle;

  /// No description provided for @homeOwnerScanLoyaltyTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Scanner fidélité'**
  String get homeOwnerScanLoyaltyTooltip;

  /// No description provided for @homeOwnerConfidentialModeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Masquer/afficher les montants'**
  String get homeOwnerConfidentialModeTooltip;

  /// No description provided for @homeOwnerShareTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Partager mon salon'**
  String get homeOwnerShareTooltip;

  /// No description provided for @homeOwnerNoSalonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre salon'**
  String get homeOwnerNoSalonTitle;

  /// No description provided for @homeOwnerNoSalonSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Configurez votre salon pour commencer à recevoir des réservations.'**
  String get homeOwnerNoSalonSubtitle;

  /// No description provided for @homeOwnerNoSalonCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon salon →'**
  String get homeOwnerNoSalonCta;

  /// No description provided for @homeOwnerCalendarError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le planning.'**
  String get homeOwnerCalendarError;

  /// No description provided for @homeOwnerCalendarEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun RDV ce jour'**
  String get homeOwnerCalendarEmptyTitle;

  /// No description provided for @homeOwnerCalendarEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre planning est libre.'**
  String get homeOwnerCalendarEmptySubtitle;

  /// No description provided for @homeOwnerCalendarEmptyCta.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get homeOwnerCalendarEmptyCta;

  /// No description provided for @homeOwnerClientsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos clients.'**
  String get homeOwnerClientsError;

  /// No description provided for @homeOwnerClientsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client encore'**
  String get homeOwnerClientsEmptyTitle;

  /// No description provided for @homeOwnerClientsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos clients apparaîtront ici après leur première réservation.'**
  String get homeOwnerClientsEmptySubtitle;

  /// No description provided for @homeOwnerClientFallbackName.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get homeOwnerClientFallbackName;

  /// No description provided for @homeOwnerClientRdvCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun RDV} =1{1 RDV} other{{count} RDV}}'**
  String homeOwnerClientRdvCount(int count);

  /// No description provided for @homeOwnerProfileMyReviews.
  ///
  /// In fr, this message translates to:
  /// **'Mes Avis'**
  String get homeOwnerProfileMyReviews;

  /// No description provided for @homeOwnerProfileActivityLog.
  ///
  /// In fr, this message translates to:
  /// **'Journal d\'activité'**
  String get homeOwnerProfileActivityLog;

  /// No description provided for @homeOwnerProfileSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get homeOwnerProfileSettings;

  /// No description provided for @homeOwnerProfileSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement & Facturation'**
  String get homeOwnerProfileSubscription;

  /// No description provided for @homeOwnerProfileLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get homeOwnerProfileLanguage;

  /// No description provided for @homeOwnerBookingCancelConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce RDV ?'**
  String get homeOwnerBookingCancelConfirmTitle;

  /// No description provided for @homeOwnerBookingCancelConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le client sera notifié et remboursé si applicable.'**
  String get homeOwnerBookingCancelConfirmMessage;

  /// No description provided for @homeOwnerBookingCancelConfirmButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get homeOwnerBookingCancelConfirmButton;

  /// No description provided for @homeManagerDashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard Manager'**
  String get homeManagerDashboardTitle;

  /// No description provided for @homeStaffScanLoyaltyTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Scanner fidélité'**
  String get homeStaffScanLoyaltyTooltip;

  /// No description provided for @homeStaffAvailabilityTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Mes disponibilités'**
  String get homeStaffAvailabilityTooltip;

  /// No description provided for @homeStaffAccountTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get homeStaffAccountTooltip;

  /// No description provided for @homeStaffConfirmArrivalButton.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer arrivée'**
  String get homeStaffConfirmArrivalButton;

  /// No description provided for @homeClientGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {firstName} 👋'**
  String homeClientGreeting(String firstName);

  /// No description provided for @homeClientNavExplorer.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get homeClientNavExplorer;

  /// No description provided for @homeClientNavMyBookings.
  ///
  /// In fr, this message translates to:
  /// **'Mes RDV'**
  String get homeClientNavMyBookings;

  /// No description provided for @homeClientNavMyLoyalties.
  ///
  /// In fr, this message translates to:
  /// **'Mes Fidélités'**
  String get homeClientNavMyLoyalties;

  /// No description provided for @homeClientProfileSeeAllBookings.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous mes RDV →'**
  String get homeClientProfileSeeAllBookings;

  /// No description provided for @homeClientProfileSeeAllPrograms.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes programmes →'**
  String get homeClientProfileSeeAllPrograms;

  /// No description provided for @homeClientProfileSeeAllReviews.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes avis →'**
  String get homeClientProfileSeeAllReviews;

  /// No description provided for @homeClientProfilePhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get homeClientProfilePhoneLabel;

  /// No description provided for @homeClientProfileInviteFriend.
  ///
  /// In fr, this message translates to:
  /// **'Invitez un ami'**
  String get homeClientProfileInviteFriend;

  /// No description provided for @homeClientProfileLogoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get homeClientProfileLogoutTitle;

  /// No description provided for @homeClientProfileLogoutMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr ?'**
  String get homeClientProfileLogoutMessage;

  /// No description provided for @homeClientProfileLogoutButton.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get homeClientProfileLogoutButton;

  /// No description provided for @homeClientProfileUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour votre profil.'**
  String get homeClientProfileUpdateError;

  /// No description provided for @homeClientProfileAvatarUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi de la photo.'**
  String get homeClientProfileAvatarUploadError;

  /// No description provided for @homeClientProfileInfoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes informations'**
  String get homeClientProfileInfoTitle;

  /// No description provided for @homeClientProfileNoPhone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun numéro'**
  String get homeClientProfileNoPhone;

  /// No description provided for @homeClientProfileNoEmail.
  ///
  /// In fr, this message translates to:
  /// **'Aucun email'**
  String get homeClientProfileNoEmail;

  /// No description provided for @homeClientProfileRecentBookingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes RDV récents'**
  String get homeClientProfileRecentBookingsTitle;

  /// No description provided for @homeClientProfileNoBookings.
  ///
  /// In fr, this message translates to:
  /// **'Aucun RDV pour le moment.'**
  String get homeClientProfileNoBookings;

  /// No description provided for @homeClientProfileLoyaltiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes fidélités'**
  String get homeClientProfileLoyaltiesTitle;

  /// No description provided for @homeClientProfileNoLoyalty.
  ///
  /// In fr, this message translates to:
  /// **'Réservez un RDV pour démarrer une carte de fidélité.'**
  String get homeClientProfileNoLoyalty;

  /// No description provided for @homeClientProfileReviewsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes avis'**
  String get homeClientProfileReviewsTitle;

  /// No description provided for @homeClientProfileReviewCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun avis} =1{J\'ai laissé 1 avis.} other{J\'ai laissé {count} avis.}}'**
  String homeClientProfileReviewCount(int count);

  /// No description provided for @homeClientProfileReviewsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos avis.'**
  String get homeClientProfileReviewsLoadError;

  /// No description provided for @homeClientProfileNoReviews.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas encore laissé d\'avis.'**
  String get homeClientProfileNoReviews;

  /// No description provided for @homeClientProfileEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mes informations'**
  String get homeClientProfileEditTitle;

  /// No description provided for @bookingSelectServiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un service'**
  String get bookingSelectServiceTitle;

  /// No description provided for @bookingSelectServiceEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service disponible'**
  String get bookingSelectServiceEmptyTitle;

  /// No description provided for @bookingSelectServiceEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce salon n\'a pas encore publié de service.'**
  String get bookingSelectServiceEmptySubtitle;

  /// No description provided for @bookingNoSalonSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun salon sélectionné.'**
  String get bookingNoSalonSelected;

  /// No description provided for @bookingSelectPractitionerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un praticien'**
  String get bookingSelectPractitionerTitle;

  /// No description provided for @bookingPractitionerLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'équipe.'**
  String get bookingPractitionerLoadError;

  /// No description provided for @bookingSelectDateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get bookingSelectDateTitle;

  /// No description provided for @bookingSelectTimeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un horaire'**
  String get bookingSelectTimeTitle;

  /// No description provided for @bookingTimeLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les créneaux.'**
  String get bookingTimeLoadError;

  /// No description provided for @bookingSelectTimeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun créneau disponible'**
  String get bookingSelectTimeEmptyTitle;

  /// No description provided for @bookingSelectTimeEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Essayez une autre date.'**
  String get bookingSelectTimeEmptySubtitle;

  /// No description provided for @bookingSelectTimeEmptyCtaLabel.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une autre date'**
  String get bookingSelectTimeEmptyCtaLabel;

  /// No description provided for @bookingSummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get bookingSummaryTitle;

  /// No description provided for @bookingSummaryNotesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note pour le salon (optionnel)'**
  String get bookingSummaryNotesLabel;

  /// No description provided for @bookingSummaryPaymentLockWarning.
  ///
  /// In fr, this message translates to:
  /// **'Votre créneau est verrouillé 5 minutes pendant le paiement. Aucun montant ne sera prélevé avant la validation finale.'**
  String get bookingSummaryPaymentLockWarning;

  /// No description provided for @bookingSummarySubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et payer →'**
  String get bookingSummarySubmitButton;

  /// No description provided for @bookingConfirmationTitle.
  ///
  /// In fr, this message translates to:
  /// **'✅ Payé ! Votre place est réservée.'**
  String get bookingConfirmationTitle;

  /// No description provided for @bookingAddToCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au calendrier'**
  String get bookingAddToCalendar;

  /// No description provided for @bookingReturnHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get bookingReturnHome;

  /// No description provided for @bookingStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get bookingStatusPending;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get bookingStatusInProgress;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Absent'**
  String get bookingStatusNoShow;

  /// No description provided for @bookingWalkInTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau RDV'**
  String get bookingWalkInTitle;

  /// No description provided for @bookingWalkInClientNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prénom du client *'**
  String get bookingWalkInClientNameLabel;

  /// No description provided for @bookingWalkInServiceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Service *'**
  String get bookingWalkInServiceLabel;

  /// No description provided for @bookingWalkInPractitionerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Praticien *'**
  String get bookingWalkInPractitionerLabel;

  /// No description provided for @bookingWalkInServicesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les services.'**
  String get bookingWalkInServicesLoadError;

  /// No description provided for @bookingWalkInStaffLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'équipe.'**
  String get bookingWalkInStaffLoadError;

  /// No description provided for @bookingWalkInTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get bookingWalkInTimeLabel;

  /// No description provided for @bookingWalkInMissingFields.
  ///
  /// In fr, this message translates to:
  /// **'Service et praticien requis.'**
  String get bookingWalkInMissingFields;

  /// No description provided for @bookingWalkInSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer le RDV'**
  String get bookingWalkInSubmitButton;

  /// No description provided for @bookingConfirmationRef.
  ///
  /// In fr, this message translates to:
  /// **'Réf.'**
  String get bookingConfirmationRef;

  /// No description provided for @bookingSalonDetailReserveButton.
  ///
  /// In fr, this message translates to:
  /// **'Réserver →'**
  String get bookingSalonDetailReserveButton;

  /// No description provided for @bookingDiscoveryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get bookingDiscoveryTitle;

  /// No description provided for @bookingDiscoverySearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un salon…'**
  String get bookingDiscoverySearchHint;

  /// No description provided for @bookingDiscoveryAdvancedSearchTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Recherche avancée'**
  String get bookingDiscoveryAdvancedSearchTooltip;

  /// No description provided for @bookingDiscoveryAllCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get bookingDiscoveryAllCategories;

  /// No description provided for @bookingDiscoveryLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les salons.'**
  String get bookingDiscoveryLoadError;

  /// No description provided for @bookingDiscoveryEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun salon trouvé'**
  String get bookingDiscoveryEmptyTitle;

  /// No description provided for @bookingDiscoveryEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Essayez une autre recherche ou catégorie.'**
  String get bookingDiscoveryEmptySubtitle;

  /// No description provided for @bookingDiscoveryResetButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get bookingDiscoveryResetButton;

  /// No description provided for @bookingCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun rendez-vous} =1{1 rendez-vous} other{{count} rendez-vous}}'**
  String bookingCount(int count);

  /// No description provided for @bookingUpcomingTab.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get bookingUpcomingTab;

  /// No description provided for @bookingPastTab.
  ///
  /// In fr, this message translates to:
  /// **'Passés'**
  String get bookingPastTab;

  /// No description provided for @bookingRebookButton.
  ///
  /// In fr, this message translates to:
  /// **'Réserver à nouveau'**
  String get bookingRebookButton;

  /// No description provided for @bookingViewReceiptButton.
  ///
  /// In fr, this message translates to:
  /// **'Voir le reçu'**
  String get bookingViewReceiptButton;

  /// No description provided for @bookingPaymentMethodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Méthode'**
  String get bookingPaymentMethodLabel;

  /// No description provided for @bookingShareReceiptButton.
  ///
  /// In fr, this message translates to:
  /// **'Partager le reçu'**
  String get bookingShareReceiptButton;

  /// No description provided for @bookingSalonDetailLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce salon.'**
  String get bookingSalonDetailLoadError;

  /// No description provided for @bookingSalonNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Salon introuvable.'**
  String get bookingSalonNotFound;

  /// No description provided for @bookingSalonDetailServicesTab.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get bookingSalonDetailServicesTab;

  /// No description provided for @bookingSalonDetailInfoTab.
  ///
  /// In fr, this message translates to:
  /// **'Info'**
  String get bookingSalonDetailInfoTab;

  /// No description provided for @bookingSalonDetailReviewsTab.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get bookingSalonDetailReviewsTab;

  /// No description provided for @bookingSalonDetailServicesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les services.'**
  String get bookingSalonDetailServicesLoadError;

  /// No description provided for @bookingSalonDetailServicesEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Revenez plus tard.'**
  String get bookingSalonDetailServicesEmptySubtitle;

  /// No description provided for @paymentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get paymentTitle;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In fr, this message translates to:
  /// **'Méthode de paiement'**
  String get paymentMethodTitle;

  /// No description provided for @paymentMethodLumicash.
  ///
  /// In fr, this message translates to:
  /// **'Lumicash'**
  String get paymentMethodLumicash;

  /// No description provided for @paymentMethodEcocash.
  ///
  /// In fr, this message translates to:
  /// **'EcoCash'**
  String get paymentMethodEcocash;

  /// No description provided for @paymentUssdInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Vous allez recevoir une demande USSD sur votre téléphone. Entrez votre code PIN pour confirmer.'**
  String get paymentUssdInstruction;

  /// No description provided for @paymentSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Payer →'**
  String get paymentSubmitButton;

  /// No description provided for @paymentFailedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce paiement n\'a pas abouti. Aucun argent débité.'**
  String get paymentFailedMessage;

  /// No description provided for @paymentRetryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get paymentRetryButton;

  /// No description provided for @paymentInvalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide.'**
  String get paymentInvalidPhone;

  /// No description provided for @proxipayQrTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser'**
  String get proxipayQrTitle;

  /// No description provided for @proxipayCreateSessionError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le QR de paiement.'**
  String get proxipayCreateSessionError;

  /// No description provided for @proxipayQrShowToClient.
  ///
  /// In fr, this message translates to:
  /// **'Faites scanner ce code par le client.'**
  String get proxipayQrShowToClient;

  /// No description provided for @proxipayQrExpiresIn.
  ///
  /// In fr, this message translates to:
  /// **'Expire dans {minutes}:{seconds}'**
  String proxipayQrExpiresIn(String minutes, String seconds);

  /// No description provided for @proxipayQrExpired.
  ///
  /// In fr, this message translates to:
  /// **'Le code a expiré. Générez-en un nouveau.'**
  String get proxipayQrExpired;

  /// No description provided for @proxipayAwaitingSettlementMessage.
  ///
  /// In fr, this message translates to:
  /// **'En attente de confirmation du paiement...'**
  String get proxipayAwaitingSettlementMessage;

  /// No description provided for @proxipaySuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Paiement reçu ✓'**
  String get proxipaySuccessMessage;

  /// No description provided for @proxipayFailedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce paiement n\'a pas abouti. Aucun argent débité.'**
  String get proxipayFailedMessage;

  /// No description provided for @proxipayRetryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get proxipayRetryButton;

  /// No description provided for @proxipayDoneButton.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get proxipayDoneButton;

  /// No description provided for @proxipayScanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Payer sur place'**
  String get proxipayScanTitle;

  /// No description provided for @proxipayScanInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Scannez le code affiché par le salon.'**
  String get proxipayScanInstruction;

  /// No description provided for @proxipayScanInvalidError.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide ou expiré.'**
  String get proxipayScanInvalidError;

  /// No description provided for @proxipayScanConnectionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion. Réessayez.'**
  String get proxipayScanConnectionError;

  /// No description provided for @proxipayConfirmPayButton.
  ///
  /// In fr, this message translates to:
  /// **'Payer →'**
  String get proxipayConfirmPayButton;

  /// No description provided for @proxipayConfirmErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de confirmer le paiement.'**
  String get proxipayConfirmErrorGeneric;

  /// No description provided for @proxipayConfirmSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Paiement envoyé ✓'**
  String get proxipayConfirmSuccessMessage;

  /// No description provided for @notificationsListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsListTitle;

  /// No description provided for @notificationsDeleteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Notification supprimée.'**
  String get notificationsDeleteSuccess;

  /// No description provided for @notificationsLoadMoreButton.
  ///
  /// In fr, this message translates to:
  /// **'Charger plus'**
  String get notificationsLoadMoreButton;

  /// No description provided for @notificationsSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préférences de notifications'**
  String get notificationsSettingsTitle;

  /// No description provided for @notificationsChannelsHeading.
  ///
  /// In fr, this message translates to:
  /// **'Canaux'**
  String get notificationsChannelsHeading;

  /// No description provided for @notificationsPushTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get notificationsPushTitle;

  /// No description provided for @notificationsWhatsappTitle.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get notificationsWhatsappTitle;

  /// No description provided for @notificationsWhatsappLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp'**
  String get notificationsWhatsappLabel;

  /// No description provided for @notificationsWhatsappHint.
  ///
  /// In fr, this message translates to:
  /// **'+257 ...'**
  String get notificationsWhatsappHint;

  /// No description provided for @notificationsAlertTypesHeading.
  ///
  /// In fr, this message translates to:
  /// **'Types d\'alertes'**
  String get notificationsAlertTypesHeading;

  /// No description provided for @notificationsBookingCreatedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservation créée'**
  String get notificationsBookingCreatedTitle;

  /// No description provided for @notificationsBookingCreatedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation immédiate de votre demande'**
  String get notificationsBookingCreatedSubtitle;

  /// No description provided for @notificationsBookingConfirmedTitle.
  ///
  /// In fr, this message translates to:
  /// **'RDV confirmé'**
  String get notificationsBookingConfirmedTitle;

  /// No description provided for @notificationsBookingCancelledTitle.
  ///
  /// In fr, this message translates to:
  /// **'RDV annulé'**
  String get notificationsBookingCancelledTitle;

  /// No description provided for @notificationsRemindersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappels RDV'**
  String get notificationsRemindersTitle;

  /// No description provided for @notificationsRemindersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappel 24h et 2h avant le rendez-vous'**
  String get notificationsRemindersSubtitle;

  /// No description provided for @notificationsTeamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get notificationsTeamTitle;

  /// No description provided for @notificationsTeamSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitations et arrivées de collaborateurs'**
  String get notificationsTeamSubtitle;

  /// No description provided for @notificationsMarketingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Marketing'**
  String get notificationsMarketingTitle;

  /// No description provided for @notificationsMarketingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Promotions et nouveautés du salon'**
  String get notificationsMarketingSubtitle;

  /// No description provided for @notificationsSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get notificationsSaveButton;

  /// No description provided for @notificationsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos préférences.'**
  String get notificationsLoadError;

  /// No description provided for @notificationsSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Préférences enregistrées.'**
  String get notificationsSaveSuccess;

  /// No description provided for @notificationsSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'enregistrement.'**
  String get notificationsSaveError;

  /// No description provided for @staffListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon Équipe'**
  String get staffListTitle;

  /// No description provided for @staffListSoloLink.
  ///
  /// In fr, this message translates to:
  /// **'Je travaille seul →'**
  String get staffListSoloLink;

  /// No description provided for @staffListCommissionsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Commissions'**
  String get staffListCommissionsTooltip;

  /// No description provided for @staffFilterActive.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get staffFilterActive;

  /// No description provided for @staffFilterPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get staffFilterPending;

  /// No description provided for @staffFilterDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivés'**
  String get staffFilterDisabled;

  /// No description provided for @staffListLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'équipe.'**
  String get staffListLoadError;

  /// No description provided for @staffInviteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un membre'**
  String get staffInviteTitle;

  /// No description provided for @staffInviteNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom *'**
  String get staffInviteNameLabel;

  /// No description provided for @staffInviteRoleStaff.
  ///
  /// In fr, this message translates to:
  /// **'Staff'**
  String get staffInviteRoleStaff;

  /// No description provided for @staffInviteRoleManager.
  ///
  /// In fr, this message translates to:
  /// **'Manager'**
  String get staffInviteRoleManager;

  /// No description provided for @staffInviteSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l\'invitation'**
  String get staffInviteSubmitButton;

  /// No description provided for @staffInviteError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'invitation.'**
  String get staffInviteError;

  /// No description provided for @staffFormTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le membre'**
  String get staffFormTitle;

  /// No description provided for @staffFormRemoveConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce membre ?'**
  String get staffFormRemoveConfirmTitle;

  /// No description provided for @staffFormRemoveConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne pourra plus accéder à ce salon.'**
  String staffFormRemoveConfirmMessage(String name);

  /// No description provided for @staffFormServicesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les services.'**
  String get staffFormServicesLoadError;

  /// No description provided for @staffAcceptInvitationVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de l\'invitation...'**
  String get staffAcceptInvitationVerifying;

  /// No description provided for @staffCommissionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commissions'**
  String get staffCommissionsTitle;

  /// No description provided for @availabilityManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilités'**
  String get availabilityManagementTitle;

  /// No description provided for @availabilityExceptionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jours exceptionnels & jours fériés'**
  String get availabilityExceptionsLabel;

  /// No description provided for @availabilityBlockedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jours bloqués (ponctuel)'**
  String get availabilityBlockedLabel;

  /// No description provided for @availabilityLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les disponibilités.'**
  String get availabilityLoadError;

  /// No description provided for @availabilitySalonHoursTitle.
  ///
  /// In fr, this message translates to:
  /// **'Horaires du salon'**
  String get availabilitySalonHoursTitle;

  /// No description provided for @availabilitySalonHoursSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Horaires enregistrés.'**
  String get availabilitySalonHoursSaveSuccess;

  /// No description provided for @availabilityStaffHoursUseSalonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser les horaires du salon'**
  String get availabilityStaffHoursUseSalonTitle;

  /// No description provided for @availabilityStaffHoursSaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Horaires enregistrés.'**
  String get availabilityStaffHoursSaveSuccess;

  /// No description provided for @availabilityBlockedSlotsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jours bloqués'**
  String get availabilityBlockedSlotsTitle;

  /// No description provided for @availabilityBlockedSlotsConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer ce jour ?'**
  String get availabilityBlockedSlotsConfirmTitle;

  /// No description provided for @availabilityBlockedSlotsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les jours bloqués.'**
  String get availabilityBlockedSlotsLoadError;

  /// No description provided for @availabilityExceptionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jours exceptionnels'**
  String get availabilityExceptionsTitle;

  /// No description provided for @availabilityBreaksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pauses de {name}'**
  String availabilityBreaksTitle(String name);

  /// No description provided for @availabilityDayOverrideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert ce jour-là'**
  String get availabilityDayOverrideTitle;

  /// No description provided for @availabilityDayOverrideReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Raison (optionnel)'**
  String get availabilityDayOverrideReasonLabel;

  /// No description provided for @availabilityDayOverrideHint.
  ///
  /// In fr, this message translates to:
  /// **'Congé, jour férié, formation…'**
  String get availabilityDayOverrideHint;

  /// No description provided for @availabilityBreakDayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get availabilityBreakDayLabel;

  /// No description provided for @availabilityBreakLabelField.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get availabilityBreakLabelField;

  /// No description provided for @availabilityBreakStartTime.
  ///
  /// In fr, this message translates to:
  /// **'Début {time}'**
  String availabilityBreakStartTime(String time);

  /// No description provided for @availabilityBreakEndTime.
  ///
  /// In fr, this message translates to:
  /// **'Fin {time}'**
  String availabilityBreakEndTime(String time);

  /// No description provided for @availabilityExceptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jour exceptionnel'**
  String get availabilityExceptionTitle;

  /// No description provided for @availabilityExceptionTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get availabilityExceptionTypeLabel;

  /// No description provided for @availabilityExceptionTypeVacation.
  ///
  /// In fr, this message translates to:
  /// **'Vacances'**
  String get availabilityExceptionTypeVacation;

  /// No description provided for @availabilityExceptionTypeClosure.
  ///
  /// In fr, this message translates to:
  /// **'Fermeture spéciale'**
  String get availabilityExceptionTypeClosure;

  /// No description provided for @availabilityExceptionTypeOpening.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture spéciale'**
  String get availabilityExceptionTypeOpening;

  /// No description provided for @availabilityExceptionChooseDates.
  ///
  /// In fr, this message translates to:
  /// **'Choisir les dates'**
  String get availabilityExceptionChooseDates;

  /// No description provided for @availabilityExceptionOpenTime.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre {time}'**
  String availabilityExceptionOpenTime(String time);

  /// No description provided for @availabilityExceptionCloseTime.
  ///
  /// In fr, this message translates to:
  /// **'Ferme {time}'**
  String availabilityExceptionCloseTime(String time);

  /// No description provided for @availabilityExceptionLabelField.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get availabilityExceptionLabelField;

  /// No description provided for @availabilityExceptionLabelHint.
  ///
  /// In fr, this message translates to:
  /// **'Congé annuel, formation…'**
  String get availabilityExceptionLabelHint;

  /// No description provided for @availabilityWeekdayPreset.
  ///
  /// In fr, this message translates to:
  /// **'Jours de semaine 8h–18h'**
  String get availabilityWeekdayPreset;

  /// No description provided for @availabilityAllDayPreset.
  ///
  /// In fr, this message translates to:
  /// **'Tous les jours 8h–20h'**
  String get availabilityAllDayPreset;

  /// No description provided for @availabilityHubStaffHoursLabel.
  ///
  /// In fr, this message translates to:
  /// **'Horaires par staff'**
  String get availabilityHubStaffHoursLabel;

  /// No description provided for @availabilityHubBreaksLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pauses & absences'**
  String get availabilityHubBreaksLabel;

  /// No description provided for @availabilityHubTouchHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un jour pour le fermer ou le rouvrir exceptionnellement.'**
  String get availabilityHubTouchHint;

  /// No description provided for @availabilitySaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'enregistrement.'**
  String get availabilitySaveFailed;

  /// No description provided for @availabilityDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la suppression.'**
  String get availabilityDeleteFailed;

  /// No description provided for @availabilityUnblockFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec du déblocage.'**
  String get availabilityUnblockFailed;

  /// No description provided for @availabilityNoBlockedDaysTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun jour bloqué'**
  String get availabilityNoBlockedDaysTitle;

  /// No description provided for @availabilityNoBlockedDaysSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos jours d\'ouverture habituels sont actifs.'**
  String get availabilityNoBlockedDaysSubtitle;

  /// No description provided for @availabilityUnblockMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce jour redeviendra ouvert selon vos horaires habituels.'**
  String get availabilityUnblockMessage;

  /// No description provided for @availabilityNoBreaksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pause'**
  String get availabilityNoBreaksTitle;

  /// No description provided for @availabilityNoBreaksSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez les pauses récurrentes de {name}.'**
  String availabilityNoBreaksSubtitle(String name);

  /// No description provided for @availabilityAddBreakCta.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une pause'**
  String get availabilityAddBreakCta;

  /// No description provided for @availabilityNewBreakTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle pause'**
  String get availabilityNewBreakTitle;

  /// No description provided for @availabilityBreakDefaultLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pause déjeuner'**
  String get availabilityBreakDefaultLabel;

  /// No description provided for @availabilityBreakFallbackLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get availabilityBreakFallbackLabel;

  /// No description provided for @availabilityNoExceptionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun jour exceptionnel'**
  String get availabilityNoExceptionsTitle;

  /// No description provided for @availabilityNoExceptionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos vacances ou fermetures spéciales.'**
  String get availabilityNoExceptionsSubtitle;

  /// No description provided for @availabilityPublicHolidaysHeading.
  ///
  /// In fr, this message translates to:
  /// **'Jours fériés'**
  String get availabilityPublicHolidaysHeading;

  /// No description provided for @availabilityNoPublicHolidays.
  ///
  /// In fr, this message translates to:
  /// **'Aucun jour férié configuré.'**
  String get availabilityNoPublicHolidays;

  /// No description provided for @availabilityStaffHoursScreenHint.
  ///
  /// In fr, this message translates to:
  /// **'Ces horaires remplacent les horaires du salon pour ce praticien.'**
  String get availabilityStaffHoursScreenHint;

  /// No description provided for @availabilityStaffHoursOf.
  ///
  /// In fr, this message translates to:
  /// **'Horaires de {name}'**
  String availabilityStaffHoursOf(String name);

  /// No description provided for @availabilityMyAvailability.
  ///
  /// In fr, this message translates to:
  /// **'Mes disponibilités'**
  String get availabilityMyAvailability;

  /// No description provided for @availabilityStaffHoursLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ces horaires.'**
  String get availabilityStaffHoursLoadError;

  /// No description provided for @availabilityNoStaffTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun staff'**
  String get availabilityNoStaffTitle;

  /// No description provided for @availabilityNoStaffSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitez votre équipe pour configurer leurs horaires.'**
  String get availabilityNoStaffSubtitle;

  /// No description provided for @availabilityStaffLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'équipe.'**
  String get availabilityStaffLoadError;

  /// No description provided for @availabilityClosedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get availabilityClosedLabel;

  /// No description provided for @availabilityBreaksLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les pauses.'**
  String get availabilityBreaksLoadError;

  /// No description provided for @availabilitySalonHoursLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les horaires.'**
  String get availabilitySalonHoursLoadError;

  /// No description provided for @availabilityExceptionsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les jours exceptionnels.'**
  String get availabilityExceptionsLoadError;

  /// No description provided for @weekdayMonday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get weekdaySunday;

  /// No description provided for @weekdayMondayShort.
  ///
  /// In fr, this message translates to:
  /// **'Lun'**
  String get weekdayMondayShort;

  /// No description provided for @weekdayTuesdayShort.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get weekdayTuesdayShort;

  /// No description provided for @weekdayWednesdayShort.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get weekdayWednesdayShort;

  /// No description provided for @weekdayThursdayShort.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get weekdayThursdayShort;

  /// No description provided for @weekdayFridayShort.
  ///
  /// In fr, this message translates to:
  /// **'Ven'**
  String get weekdayFridayShort;

  /// No description provided for @weekdaySaturdayShort.
  ///
  /// In fr, this message translates to:
  /// **'Sam'**
  String get weekdaySaturdayShort;

  /// No description provided for @weekdaySundayShort.
  ///
  /// In fr, this message translates to:
  /// **'Dim'**
  String get weekdaySundayShort;

  /// No description provided for @servicesListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get servicesListTitle;

  /// No description provided for @servicesDeleteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'{name} supprimé.'**
  String servicesDeleteSuccess(String name);

  /// No description provided for @servicesDeleteSnack.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » supprimé.'**
  String servicesDeleteSnack(String name);

  /// No description provided for @servicesNoServiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service'**
  String get servicesNoServiceTitle;

  /// No description provided for @servicesNoServiceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos prestations pour commencer à recevoir des RDV.'**
  String get servicesNoServiceSubtitle;

  /// No description provided for @servicesNoServiceCta.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un service'**
  String get servicesNoServiceCta;

  /// No description provided for @servicesFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get servicesFilterAll;

  /// No description provided for @servicesFormEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le service'**
  String get servicesFormEditTitle;

  /// No description provided for @servicesFormNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau service'**
  String get servicesFormNewTitle;

  /// No description provided for @servicesFormNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du service *'**
  String get servicesFormNameLabel;

  /// No description provided for @servicesFormCategoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie *'**
  String get servicesFormCategoryLabel;

  /// No description provided for @servicesFormDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get servicesFormDescriptionLabel;

  /// No description provided for @servicesFormDurationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Durée (minutes) *'**
  String get servicesFormDurationLabel;

  /// No description provided for @servicesFormDurationError.
  ///
  /// In fr, this message translates to:
  /// **'Durée invalide.'**
  String get servicesFormDurationError;

  /// No description provided for @servicesFormBufferLabel.
  ///
  /// In fr, this message translates to:
  /// **'Temps de préparation (minutes)'**
  String get servicesFormBufferLabel;

  /// No description provided for @servicesFormPriceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix (FBu) *'**
  String get servicesFormPriceLabel;

  /// No description provided for @servicesFormPriceError.
  ///
  /// In fr, this message translates to:
  /// **'Prix invalide.'**
  String get servicesFormPriceError;

  /// No description provided for @reviewsOwnerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Avis'**
  String get reviewsOwnerTitle;

  /// No description provided for @reviewsSortRecent.
  ///
  /// In fr, this message translates to:
  /// **'Récents'**
  String get reviewsSortRecent;

  /// No description provided for @reviewsSortLowest.
  ///
  /// In fr, this message translates to:
  /// **'Note basse'**
  String get reviewsSortLowest;

  /// No description provided for @reviewsSortUnanswered.
  ///
  /// In fr, this message translates to:
  /// **'Sans réponse'**
  String get reviewsSortUnanswered;

  /// No description provided for @reviewsReplyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Répondre à cet avis'**
  String get reviewsReplyTitle;

  /// No description provided for @reviewsReplyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse'**
  String get reviewsReplyLabel;

  /// No description provided for @reviewsReplySubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Publier la réponse'**
  String get reviewsReplySubmitButton;

  /// No description provided for @reviewsFlagConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler cet avis ?'**
  String get reviewsFlagConfirmTitle;

  /// No description provided for @reviewsFlagConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Il sera masqué en attendant une revue par notre équipe.'**
  String get reviewsFlagConfirmMessage;

  /// No description provided for @reviewsFlagConfirmButton.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get reviewsFlagConfirmButton;

  /// No description provided for @reviewsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis encore'**
  String get reviewsEmptyTitle;

  /// No description provided for @reviewsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos avis clients apparaîtront ici.'**
  String get reviewsEmptySubtitle;

  /// No description provided for @reviewsEmptyCta.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get reviewsEmptyCta;

  /// No description provided for @reviewsReplyError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi.'**
  String get reviewsReplyError;

  /// No description provided for @reviewsFlagError.
  ///
  /// In fr, this message translates to:
  /// **'Échec du signalement.'**
  String get reviewsFlagError;

  /// No description provided for @reviewsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos avis.'**
  String get reviewsLoadError;

  /// No description provided for @reviewsSalonLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les avis.'**
  String get reviewsSalonLoadError;

  /// No description provided for @reviewsLeaveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Laisser un avis'**
  String get reviewsLeaveTitle;

  /// No description provided for @reviewsLeaveBookingError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier votre réservation.'**
  String get reviewsLeaveBookingError;

  /// No description provided for @reviewsLeaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Avis publié ! Merci 💛'**
  String get reviewsLeaveSuccess;

  /// No description provided for @reviewsLeaveQueuedOffline.
  ///
  /// In fr, this message translates to:
  /// **'Avis enregistré hors ligne — sera publié dès la reconnexion.'**
  String get reviewsLeaveQueuedOffline;

  /// No description provided for @reviewsLeaveSkipButton.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get reviewsLeaveSkipButton;

  /// No description provided for @reviewsLeaveRatingRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une note avant de publier.'**
  String get reviewsLeaveRatingRequired;

  /// No description provided for @reviewsLeaveCommentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre expérience (optionnel)'**
  String get reviewsLeaveCommentLabel;

  /// No description provided for @reviewsLeaveAnonymousLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rester anonyme'**
  String get reviewsLeaveAnonymousLabel;

  /// No description provided for @reviewsLeavePublishButton.
  ///
  /// In fr, this message translates to:
  /// **'Publier mon avis'**
  String get reviewsLeavePublishButton;

  /// No description provided for @reviewsLeaveUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avis indisponible'**
  String get reviewsLeaveUnavailableTitle;

  /// No description provided for @reviewsLeaveUnavailableSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette réservation a déjà reçu un avis ou ne peut pas encore être notée.'**
  String get reviewsLeaveUnavailableSubtitle;

  /// No description provided for @reviewsLeaveBackButton.
  ///
  /// In fr, this message translates to:
  /// **'Retour à mes RDV'**
  String get reviewsLeaveBackButton;

  /// No description provided for @reviewsLeaveServiceFallback.
  ///
  /// In fr, this message translates to:
  /// **'Votre prestation'**
  String get reviewsLeaveServiceFallback;

  /// No description provided for @reviewsAnonymousName.
  ///
  /// In fr, this message translates to:
  /// **'Anonyme'**
  String get reviewsAnonymousName;

  /// No description provided for @reviewsClientFallbackName.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get reviewsClientFallbackName;

  /// No description provided for @reviewsSalonReplyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du salon'**
  String get reviewsSalonReplyLabel;

  /// No description provided for @reviewsFirstTitle.
  ///
  /// In fr, this message translates to:
  /// **'Soyez le premier à laisser un avis !'**
  String get reviewsFirstTitle;

  /// No description provided for @reviewsFirstSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservez puis partagez votre expérience.'**
  String get reviewsFirstSubtitle;

  /// No description provided for @reviewsVerifiedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} avis vérifiés'**
  String reviewsVerifiedCount(int count);

  /// No description provided for @marketingDashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Marketing'**
  String get marketingDashboardTitle;

  /// No description provided for @marketingBookingsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get marketingBookingsLabel;

  /// No description provided for @marketingRecurringLabel.
  ///
  /// In fr, this message translates to:
  /// **'Récurrents'**
  String get marketingRecurringLabel;

  /// No description provided for @marketingSeeAllContactsButton.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous mes contacts →'**
  String get marketingSeeAllContactsButton;

  /// No description provided for @marketingTeamPerformanceError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la performance équipe.'**
  String get marketingTeamPerformanceError;

  /// No description provided for @marketingForecastsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de calculer les prévisions.'**
  String get marketingForecastsError;

  /// No description provided for @marketingSendError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi.'**
  String get marketingSendError;

  /// No description provided for @marketingPromotionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Promotions'**
  String get marketingPromotionsTitle;

  /// No description provided for @marketingPromotionsActiveFilter.
  ///
  /// In fr, this message translates to:
  /// **'Actives'**
  String get marketingPromotionsActiveFilter;

  /// No description provided for @marketingPromotionsExpiredFilter.
  ///
  /// In fr, this message translates to:
  /// **'Expirées'**
  String get marketingPromotionsExpiredFilter;

  /// No description provided for @marketingPromotionsEmptyActive.
  ///
  /// In fr, this message translates to:
  /// **'Aucune promotion active'**
  String get marketingPromotionsEmptyActive;

  /// No description provided for @marketingPromotionsEmptyActiveHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre première offre pour attirer vos clients.'**
  String get marketingPromotionsEmptyActiveHint;

  /// No description provided for @marketingPromotionsEmptyExpired.
  ///
  /// In fr, this message translates to:
  /// **'Aucune promotion expirée'**
  String get marketingPromotionsEmptyExpired;

  /// No description provided for @marketingPromotionsCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer ma première promotion'**
  String get marketingPromotionsCreateButton;

  /// No description provided for @marketingPromotionsDeactivateConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver cette promotion ?'**
  String get marketingPromotionsDeactivateConfirmTitle;

  /// No description provided for @marketingPromotionsDeactivateConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne sera plus visible des clients.'**
  String marketingPromotionsDeactivateConfirmMessage(String name);

  /// No description provided for @marketingPromotionsDeactivateButton.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get marketingPromotionsDeactivateButton;

  /// No description provided for @marketingPromotionsDeactivateError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la désactivation.'**
  String get marketingPromotionsDeactivateError;

  /// No description provided for @marketingPromotionsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos promotions.'**
  String get marketingPromotionsLoadError;

  /// No description provided for @marketingPromotionTypePercentage.
  ///
  /// In fr, this message translates to:
  /// **'Pourcentage %'**
  String get marketingPromotionTypePercentage;

  /// No description provided for @marketingPromotionTypeFixed.
  ///
  /// In fr, this message translates to:
  /// **'Montant fixe FBu'**
  String get marketingPromotionTypeFixed;

  /// No description provided for @marketingPromotionGenerateCodeButton.
  ///
  /// In fr, this message translates to:
  /// **'Générer un code'**
  String get marketingPromotionGenerateCodeButton;

  /// No description provided for @marketingPromotionDateError.
  ///
  /// In fr, this message translates to:
  /// **'La date de fin doit être après la date de début.'**
  String get marketingPromotionDateError;

  /// No description provided for @marketingClientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Clients'**
  String get marketingClientsTitle;

  /// No description provided for @marketingClientsContactsTab.
  ///
  /// In fr, this message translates to:
  /// **'Contacts'**
  String get marketingClientsContactsTab;

  /// No description provided for @marketingClientsInvitationsTab.
  ///
  /// In fr, this message translates to:
  /// **'Invitations'**
  String get marketingClientsInvitationsTab;

  /// No description provided for @marketingClientsDeleteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'{name} supprimé.'**
  String marketingClientsDeleteSuccess(String name);

  /// No description provided for @marketingClientsOnKynzaBadge.
  ///
  /// In fr, this message translates to:
  /// **'Sur KYNZA ✓'**
  String get marketingClientsOnKynzaBadge;

  /// No description provided for @marketingClientsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos clients.'**
  String get marketingClientsLoadError;

  /// No description provided for @marketingLoyaltyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Programme Fidélité'**
  String get marketingLoyaltyTitle;

  /// No description provided for @marketingLoyaltyRewardMissingWarning.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez la récompense offerte.'**
  String get marketingLoyaltyRewardMissingWarning;

  /// No description provided for @marketingLoyaltySaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Programme enregistré !'**
  String get marketingLoyaltySaveSuccess;

  /// No description provided for @marketingLoyaltyRewardValidatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Récompense validée pour {name} !'**
  String marketingLoyaltyRewardValidatedSuccess(String name);

  /// No description provided for @marketingLoyaltyRewardValidateConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Valider la récompense ?'**
  String get marketingLoyaltyRewardValidateConfirmTitle;

  /// No description provided for @marketingLoyaltyRewardDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description de la récompense *'**
  String get marketingLoyaltyRewardDescriptionLabel;

  /// No description provided for @marketingLoyaltyStampsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tampons donnés'**
  String get marketingLoyaltyStampsLabel;

  /// No description provided for @marketingLoyaltyRewardsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Récompenses'**
  String get marketingLoyaltyRewardsLabel;

  /// No description provided for @marketingShareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager mon salon'**
  String get marketingShareTitle;

  /// No description provided for @marketingShareCopySuccess.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié !'**
  String get marketingShareCopySuccess;

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard KYNZA'**
  String get dashboardTitle;

  /// No description provided for @dashboardTeamPerformanceError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la performance équipe.'**
  String get dashboardTeamPerformanceError;

  /// No description provided for @dashboardForecastsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de calculer les prévisions.'**
  String get dashboardForecastsError;

  /// No description provided for @dashboardAuditLogLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le journal d\'activité.'**
  String get dashboardAuditLogLoadError;

  /// No description provided for @dashboardAuditLogExportTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Exporter (CSV)'**
  String get dashboardAuditLogExportTooltip;

  /// No description provided for @dashboardAuditLogLoadMoreButton.
  ///
  /// In fr, this message translates to:
  /// **'Charger plus'**
  String get dashboardAuditLogLoadMoreButton;

  /// No description provided for @dashboardLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le dashboard.'**
  String get dashboardLoadError;

  /// No description provided for @dashboardOverviewTab.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble'**
  String get dashboardOverviewTab;

  /// No description provided for @dashboardClientsTab.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get dashboardClientsTab;

  /// No description provided for @dashboardTeamTab.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get dashboardTeamTab;

  /// No description provided for @dashboardForecastTab.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions'**
  String get dashboardForecastTab;

  /// No description provided for @dashboardExportPdfButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter PDF'**
  String get dashboardExportPdfButton;

  /// No description provided for @dashboardKpiRevenu.
  ///
  /// In fr, this message translates to:
  /// **'Revenu'**
  String get dashboardKpiRevenu;

  /// No description provided for @dashboardKpiReservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get dashboardKpiReservations;

  /// No description provided for @dashboardKpiOccupancyRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux remplissage'**
  String get dashboardKpiOccupancyRate;

  /// No description provided for @dashboardKpiNoShowRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux no-show'**
  String get dashboardKpiNoShowRate;

  /// No description provided for @dashboardRevenueChartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Évolution du CA'**
  String get dashboardRevenueChartTitle;

  /// No description provided for @dashboardNoServiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service'**
  String get dashboardNoServiceTitle;

  /// No description provided for @dashboardNoServiceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos prestations pour suivre leur succès.'**
  String get dashboardNoServiceSubtitle;

  /// No description provided for @dashboardAddServiceCta.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un service'**
  String get dashboardAddServiceCta;

  /// No description provided for @dashboardNoStaffTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun staff'**
  String get dashboardNoStaffTitle;

  /// No description provided for @dashboardNoStaffSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitez votre équipe pour suivre leurs performances.'**
  String get dashboardNoStaffSubtitle;

  /// No description provided for @dashboardInviteTeamCta.
  ///
  /// In fr, this message translates to:
  /// **'Inviter votre équipe'**
  String get dashboardInviteTeamCta;

  /// No description provided for @dashboardQuickActionServices.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get dashboardQuickActionServices;

  /// No description provided for @dashboardQuickActionAddService.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter service'**
  String get dashboardQuickActionAddService;

  /// No description provided for @dashboardQuickActionTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get dashboardQuickActionTeam;

  /// No description provided for @dashboardQuickActionInviteStaff.
  ///
  /// In fr, this message translates to:
  /// **'Inviter staff'**
  String get dashboardQuickActionInviteStaff;

  /// No description provided for @dashboardClientExportCsvButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter clients (CSV)'**
  String get dashboardClientExportCsvButton;

  /// No description provided for @dashboardNewVsReturning.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux vs Récurrents'**
  String get dashboardNewVsReturning;

  /// No description provided for @dashboardNewClients.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux'**
  String get dashboardNewClients;

  /// No description provided for @dashboardReturningClients.
  ///
  /// In fr, this message translates to:
  /// **'Récurrents'**
  String get dashboardReturningClients;

  /// No description provided for @dashboardChurnRiskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Clients à risque'**
  String get dashboardChurnRiskTitle;

  /// No description provided for @dashboardNoChurnRisk.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client à risque pour le moment.'**
  String get dashboardNoChurnRisk;

  /// No description provided for @dashboardTopClientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Meilleurs clients'**
  String get dashboardTopClientsTitle;

  /// No description provided for @dashboardNoTopClients.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de clients.'**
  String get dashboardNoTopClients;

  /// No description provided for @dashboardClientVisitCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} visites'**
  String dashboardClientVisitCount(int count);

  /// No description provided for @dashboardCohortTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rétention par cohorte'**
  String get dashboardCohortTitle;

  /// No description provided for @dashboardChurnRiskHigh.
  ///
  /// In fr, this message translates to:
  /// **'Risque élevé'**
  String get dashboardChurnRiskHigh;

  /// No description provided for @dashboardChurnRiskMedium.
  ///
  /// In fr, this message translates to:
  /// **'Risque moyen'**
  String get dashboardChurnRiskMedium;

  /// No description provided for @dashboardChurnRiskLow.
  ///
  /// In fr, this message translates to:
  /// **'Risque faible'**
  String get dashboardChurnRiskLow;

  /// No description provided for @dashboardChurnAbsentDays.
  ///
  /// In fr, this message translates to:
  /// **'Absent depuis {days} jours'**
  String dashboardChurnAbsentDays(int days);

  /// No description provided for @dashboardChurnMoreHidden.
  ///
  /// In fr, this message translates to:
  /// **'+ {count} autres'**
  String dashboardChurnMoreHidden(int count);

  /// No description provided for @dashboardOwnerOnlyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservé au propriétaire'**
  String get dashboardOwnerOnlyTitle;

  /// No description provided for @dashboardOwnerOnlySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les performances de l\'équipe ne sont visibles que par le propriétaire.'**
  String get dashboardOwnerOnlySubtitle;

  /// No description provided for @dashboardTeamRevenueChartTitle.
  ///
  /// In fr, this message translates to:
  /// **'CA par staff'**
  String get dashboardTeamRevenueChartTitle;

  /// No description provided for @dashboardNoTeamDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée équipe'**
  String get dashboardNoTeamDataTitle;

  /// No description provided for @dashboardNoTeamDataSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les performances apparaîtront après les premiers RDV.'**
  String get dashboardNoTeamDataSubtitle;

  /// No description provided for @dashboardExportReportPdfButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter rapport (PDF)'**
  String get dashboardExportReportPdfButton;

  /// No description provided for @dashboardExportCsvButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter CSV'**
  String get dashboardExportCsvButton;

  /// No description provided for @dashboardForecastTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prévision sur 12 semaines'**
  String get dashboardForecastTitle;

  /// No description provided for @dashboardForecastNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore assez d\'historique pour une prévision.'**
  String get dashboardForecastNoHistory;

  /// No description provided for @dashboardExportForecastCsvButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter (CSV)'**
  String get dashboardExportForecastCsvButton;

  /// No description provided for @dashboardOccupancyTip.
  ///
  /// In fr, this message translates to:
  /// **'Occupation à {rate}% — pensez à relancer vos clients pour remplir votre planning.'**
  String dashboardOccupancyTip(int rate);

  /// No description provided for @dashboardTopServicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Top services'**
  String get dashboardTopServicesTitle;

  /// No description provided for @dashboardServiceSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get dashboardServiceSeeAll;

  /// No description provided for @dashboardServiceRdvCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} RDV'**
  String dashboardServiceRdvCount(int count);

  /// No description provided for @dashboardTopStaffTitle.
  ///
  /// In fr, this message translates to:
  /// **'Top équipe'**
  String get dashboardTopStaffTitle;

  /// No description provided for @dashboardStaffRdvCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} RDV'**
  String dashboardStaffRdvCount(int count);

  /// No description provided for @dashboardCohortHeader.
  ///
  /// In fr, this message translates to:
  /// **'Cohorte'**
  String get dashboardCohortHeader;

  /// No description provided for @dashboardNoCohortData.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de données de cohortes.'**
  String get dashboardNoCohortData;

  /// No description provided for @auditLogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Journal d\'activité'**
  String get auditLogTitle;

  /// No description provided for @auditLogFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get auditLogFilterAll;

  /// No description provided for @auditLogFilterBooking.
  ///
  /// In fr, this message translates to:
  /// **'RDV'**
  String get auditLogFilterBooking;

  /// No description provided for @auditLogFilterPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get auditLogFilterPayment;

  /// No description provided for @auditLogFilterStaff.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get auditLogFilterStaff;

  /// No description provided for @auditLogFilterSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get auditLogFilterSettings;

  /// No description provided for @auditLogNoActivityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité'**
  String get auditLogNoActivityTitle;

  /// No description provided for @auditLogNoActivitySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le journal se remplira au fil de vos actions.'**
  String get auditLogNoActivitySubtitle;

  /// No description provided for @dataTemplatesListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modèles de documents'**
  String get dataTemplatesListTitle;

  /// No description provided for @dataTemplatesDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le modèle'**
  String get dataTemplatesDeleteConfirmTitle;

  /// No description provided for @dataTemplatesDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ?'**
  String dataTemplatesDeleteConfirmMessage(String name);

  /// No description provided for @dataTemplatesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les modèles.'**
  String get dataTemplatesLoadError;

  /// No description provided for @dataTemplatesDeleteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Modèle supprimé.'**
  String get dataTemplatesDeleteSuccess;

  /// No description provided for @dataTemplatesDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer ce modèle.'**
  String get dataTemplatesDeleteError;

  /// No description provided for @dataTemplatesDefaultBadge.
  ///
  /// In fr, this message translates to:
  /// **'DÉFAUT'**
  String get dataTemplatesDefaultBadge;

  /// No description provided for @dataTemplateEditorNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du modèle'**
  String get dataTemplateEditorNameLabel;

  /// No description provided for @dataTemplateEditorContentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Contenu du modèle'**
  String get dataTemplateEditorContentLabel;

  /// No description provided for @dataTemplateEditorContentHint.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez [variable] pour insérer des données dynamiques.'**
  String get dataTemplateEditorContentHint;

  /// No description provided for @dataBackupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardes de données'**
  String get dataBackupTitle;

  /// No description provided for @dataBackupCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer une sauvegarde'**
  String get dataBackupCreateButton;

  /// No description provided for @dataBackupCreateCancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get dataBackupCreateCancelButton;

  /// No description provided for @dataBackupCreateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde créée avec succès.'**
  String get dataBackupCreateSuccess;

  /// No description provided for @billingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facturation'**
  String get billingTitle;

  /// No description provided for @billingSubscriptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement KYNZA'**
  String get billingSubscriptionTitle;

  /// No description provided for @billingSubscriptionRecommendedBadge.
  ///
  /// In fr, this message translates to:
  /// **'RECOMMANDÉ'**
  String get billingSubscriptionRecommendedBadge;

  /// No description provided for @billingSubscriptionDowngradeConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rétrograder vers {plan} ?'**
  String billingSubscriptionDowngradeConfirmTitle(String plan);

  /// No description provided for @billingSubscriptionDowngradeConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre salon passera immédiatement au plan {plan}.'**
  String billingSubscriptionDowngradeConfirmMessage(String plan);

  /// No description provided for @billingSubscriptionUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Plan mis à jour.'**
  String get billingSubscriptionUpdateSuccess;

  /// No description provided for @billingSubscriptionMarkPaidButton.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme payé'**
  String get billingSubscriptionMarkPaidButton;

  /// No description provided for @billingSubscriptionCopyReferenceButton.
  ///
  /// In fr, this message translates to:
  /// **'Copier la référence'**
  String get billingSubscriptionCopyReferenceButton;

  /// No description provided for @billingSubscriptionCopyReferenceSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Référence copiée !'**
  String get billingSubscriptionCopyReferenceSuccess;

  /// No description provided for @billingInvoicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique des factures'**
  String get billingInvoicesTitle;

  /// No description provided for @permissionsGroupsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Groupes de permissions'**
  String get permissionsGroupsTitle;

  /// No description provided for @permissionsGroupNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. Réceptionniste Senior'**
  String get permissionsGroupNameHint;

  /// No description provided for @permissionsGroupCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer ce groupe.'**
  String get permissionsGroupCreateError;

  /// No description provided for @permissionsGroupDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce groupe ?'**
  String get permissionsGroupDeleteConfirmTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsPermissionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Permissions & Équipe'**
  String get settingsPermissionsLabel;

  /// No description provided for @settingsAutomationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Automatisations'**
  String get settingsAutomationLabel;

  /// No description provided for @settingsBookingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get settingsBookingLabel;

  /// No description provided for @settingsNotificationsSalonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Notifications du salon'**
  String get settingsNotificationsSalonLabel;

  /// No description provided for @settingsMarketingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Marketing'**
  String get settingsMarketingLabel;

  /// No description provided for @settingsTeamLabel.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get settingsTeamLabel;

  /// No description provided for @settingsLoyaltyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fidélité'**
  String get settingsLoyaltyLabel;

  /// No description provided for @settingsReviewsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get settingsReviewsLabel;

  /// No description provided for @settingsPaymentsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get settingsPaymentsLabel;

  /// No description provided for @settingsAdvancedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get settingsAdvancedLabel;

  /// No description provided for @settingsDocumentTemplatesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modèles de documents'**
  String get settingsDocumentTemplatesLabel;

  /// No description provided for @settingsDataBackupLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardes de données'**
  String get settingsDataBackupLabel;

  /// No description provided for @settingsFeatureFlagsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Drapeaux de fonctionnalités'**
  String get settingsFeatureFlagsLabel;

  /// No description provided for @settingsRemoteConfigLabel.
  ///
  /// In fr, this message translates to:
  /// **'Configuration à distance'**
  String get settingsRemoteConfigLabel;

  /// No description provided for @settingsHealthCenterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Centre de supervision'**
  String get settingsHealthCenterLabel;

  /// No description provided for @settingsCmsAdminLabel.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de contenu'**
  String get settingsCmsAdminLabel;

  /// No description provided for @settingsHelpCenterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get settingsHelpCenterLabel;

  /// No description provided for @settingsAboutLabel.
  ///
  /// In fr, this message translates to:
  /// **'À propos de KYNZA'**
  String get settingsAboutLabel;

  /// No description provided for @settingsCategoryLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les paramètres.'**
  String get settingsCategoryLoadError;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSectionApp.
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get settingsAboutSectionApp;

  /// No description provided for @settingsAboutSectionLegal.
  ///
  /// In fr, this message translates to:
  /// **'Légal'**
  String get settingsAboutSectionLegal;

  /// No description provided for @settingsAboutVersionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get settingsAboutVersionLabel;

  /// No description provided for @settingsAboutBuildLabel.
  ///
  /// In fr, this message translates to:
  /// **'Build'**
  String get settingsAboutBuildLabel;

  /// No description provided for @settingsAboutPlatformLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plateforme'**
  String get settingsAboutPlatformLabel;

  /// No description provided for @settingsAboutPublisherLabel.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur'**
  String get settingsAboutPublisherLabel;

  /// No description provided for @settingsAboutCountryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get settingsAboutCountryLabel;

  /// No description provided for @settingsAboutCurrencyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get settingsAboutCurrencyLabel;

  /// No description provided for @settingsAboutCopyright.
  ///
  /// In fr, this message translates to:
  /// **'© {year} KYNZA. Tous droits réservés.'**
  String settingsAboutCopyright(String year);

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la langue de l\'application'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageSystemDetected.
  ///
  /// In fr, this message translates to:
  /// **'Détecté automatiquement'**
  String get settingsLanguageSystemDetected;

  /// No description provided for @languageSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageSectionTitle;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get languageEnglish;

  /// No description provided for @evolutionFeatureFlagsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Drapeaux de fonctionnalités'**
  String get evolutionFeatureFlagsTitle;

  /// No description provided for @evolutionFeatureFlagsDisabledBadge.
  ///
  /// In fr, this message translates to:
  /// **'GLOBAL: DÉSACTIVÉ'**
  String get evolutionFeatureFlagsDisabledBadge;

  /// No description provided for @evolutionFeatureFlagsEnabledBadge.
  ///
  /// In fr, this message translates to:
  /// **'GLOBAL: ACTIVÉ'**
  String get evolutionFeatureFlagsEnabledBadge;

  /// No description provided for @evolutionFeatureFlagsResetTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser (suivre global)'**
  String get evolutionFeatureFlagsResetTooltip;

  /// No description provided for @evolutionFeatureFlagsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun drapeau configuré'**
  String get evolutionFeatureFlagsEmptyTitle;

  /// No description provided for @evolutionFeatureFlagsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les drapeaux de fonctionnalités apparaîtront ici.'**
  String get evolutionFeatureFlagsEmptySubtitle;

  /// No description provided for @evolutionFeatureFlagsOverrideBadge.
  ///
  /// In fr, this message translates to:
  /// **'OVERRIDE'**
  String get evolutionFeatureFlagsOverrideBadge;

  /// No description provided for @evolutionFeatureFlagsRollout.
  ///
  /// In fr, this message translates to:
  /// **'GLOBAL: {percentage}%'**
  String evolutionFeatureFlagsRollout(int percentage);

  /// No description provided for @evolutionFeatureFlagsInfoText.
  ///
  /// In fr, this message translates to:
  /// **'Activez ou désactivez des fonctionnalités pour ce salon. Les overrides locaux priment sur les paramètres globaux.'**
  String get evolutionFeatureFlagsInfoText;

  /// No description provided for @evolutionFeatureFlagsScopeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Gérer la portée (rôle / utilisateur)'**
  String get evolutionFeatureFlagsScopeTooltip;

  /// No description provided for @evolutionFeatureFlagsRoleOverridesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Substitutions par rôle'**
  String get evolutionFeatureFlagsRoleOverridesTitle;

  /// No description provided for @evolutionFeatureFlagsUserOverridesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Substitutions par utilisateur'**
  String get evolutionFeatureFlagsUserOverridesTitle;

  /// No description provided for @evolutionFeatureFlagsUserIdHint.
  ///
  /// In fr, this message translates to:
  /// **'ID utilisateur'**
  String get evolutionFeatureFlagsUserIdHint;

  /// No description provided for @evolutionFeatureFlagsUserIdEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Entrez d\'abord un ID utilisateur'**
  String get evolutionFeatureFlagsUserIdEmpty;

  /// No description provided for @evolutionFeatureFlagsAuditTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'historique'**
  String get evolutionFeatureFlagsAuditTooltip;

  /// No description provided for @evolutionFeatureFlagsAuditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique des modifications'**
  String get evolutionFeatureFlagsAuditTitle;

  /// No description provided for @evolutionFeatureFlagsAuditEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune modification'**
  String get evolutionFeatureFlagsAuditEmptyTitle;

  /// No description provided for @evolutionFeatureFlagsAuditEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Chaque changement de substitution apparaîtra ici.'**
  String get evolutionFeatureFlagsAuditEmptySubtitle;

  /// No description provided for @evolutionRemoteConfigTitle.
  ///
  /// In fr, this message translates to:
  /// **'Configuration à distance'**
  String get evolutionRemoteConfigTitle;

  /// No description provided for @evolutionRemoteConfigEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée de configuration'**
  String get evolutionRemoteConfigEmptyTitle;

  /// No description provided for @evolutionRemoteConfigEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les entrées de configuration à distance apparaîtront ici.'**
  String get evolutionRemoteConfigEmptySubtitle;

  /// No description provided for @evolutionRemoteConfigEditTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la valeur'**
  String get evolutionRemoteConfigEditTooltip;

  /// No description provided for @evolutionRemoteConfigHistoryTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'historique des versions'**
  String get evolutionRemoteConfigHistoryTooltip;

  /// No description provided for @evolutionRemoteConfigNewValueHint.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle valeur'**
  String get evolutionRemoteConfigNewValueHint;

  /// No description provided for @evolutionRemoteConfigChangeReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Raison du changement (optionnel)'**
  String get evolutionRemoteConfigChangeReasonHint;

  /// No description provided for @evolutionRemoteConfigUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Configuration mise à jour.'**
  String get evolutionRemoteConfigUpdateSuccess;

  /// No description provided for @evolutionRemoteConfigHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique des versions'**
  String get evolutionRemoteConfigHistoryTitle;

  /// No description provided for @evolutionRemoteConfigRollbackButton.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer cette version'**
  String get evolutionRemoteConfigRollbackButton;

  /// No description provided for @evolutionRemoteConfigRollbackSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Version restaurée.'**
  String get evolutionRemoteConfigRollbackSuccess;

  /// No description provided for @evolutionHealthCenterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre de supervision'**
  String get evolutionHealthCenterTitle;

  /// No description provided for @evolutionHealthCenterEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée pour le moment'**
  String get evolutionHealthCenterEmptyTitle;

  /// No description provided for @evolutionHealthCenterEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette métrique n\'a pas encore de données à afficher.'**
  String get evolutionHealthCenterEmptySubtitle;

  /// No description provided for @evolutionHealthCenterRealtimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'EN DIRECT'**
  String get evolutionHealthCenterRealtimeLabel;

  /// No description provided for @evolutionHealthCenterPolledLabel.
  ///
  /// In fr, this message translates to:
  /// **'PÉRIODIQUE'**
  String get evolutionHealthCenterPolledLabel;

  /// No description provided for @evolutionHealthCenterClientOnlyLabel.
  ///
  /// In fr, this message translates to:
  /// **'CET APPAREIL UNIQUEMENT'**
  String get evolutionHealthCenterClientOnlyLabel;

  /// No description provided for @evolutionHealthCenterUnavailableLabel.
  ///
  /// In fr, this message translates to:
  /// **'AUCUNE API DE LECTURE'**
  String get evolutionHealthCenterUnavailableLabel;

  /// No description provided for @evolutionHealthCenterForbiddenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès administrateur système requis'**
  String get evolutionHealthCenterForbiddenTitle;

  /// No description provided for @evolutionHealthCenterForbiddenSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette surface est réservée aux administrateurs système de KYNZA.'**
  String get evolutionHealthCenterForbiddenSubtitle;

  /// No description provided for @evolutionCmsAdminTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de contenu'**
  String get evolutionCmsAdminTitle;

  /// No description provided for @evolutionCmsAdminEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu'**
  String get evolutionCmsAdminEmptyTitle;

  /// No description provided for @evolutionCmsAdminEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez ici du contenu d\'aide, FAQ ou annonces.'**
  String get evolutionCmsAdminEmptySubtitle;

  /// No description provided for @evolutionCmsCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau contenu'**
  String get evolutionCmsCreateButton;

  /// No description provided for @evolutionCmsTypeHint.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get evolutionCmsTypeHint;

  /// No description provided for @evolutionCmsSlugHint.
  ///
  /// In fr, this message translates to:
  /// **'Slug'**
  String get evolutionCmsSlugHint;

  /// No description provided for @evolutionCmsLocaleHint.
  ///
  /// In fr, this message translates to:
  /// **'Langue (fr/en)'**
  String get evolutionCmsLocaleHint;

  /// No description provided for @evolutionCmsTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get evolutionCmsTitleHint;

  /// No description provided for @evolutionCmsBodyHint.
  ///
  /// In fr, this message translates to:
  /// **'Contenu (Markdown)'**
  String get evolutionCmsBodyHint;

  /// No description provided for @evolutionCmsPublishButton.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get evolutionCmsPublishButton;

  /// No description provided for @evolutionCmsUnpublishButton.
  ///
  /// In fr, this message translates to:
  /// **'Dépublier'**
  String get evolutionCmsUnpublishButton;

  /// No description provided for @helpCenterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article d\'aide'**
  String get helpCenterEmptyTitle;

  /// No description provided for @helpCenterEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les articles d\'aide apparaîtront ici une fois publiés.'**
  String get helpCenterEmptySubtitle;

  /// No description provided for @evolutionAuditCenterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'audit'**
  String get evolutionAuditCenterTitle;

  /// No description provided for @evolutionAuditCenterHealthCenterNote.
  ///
  /// In fr, this message translates to:
  /// **'Les audits erreurs, performance et synchronisation réutilisent les pipelines du Centre de supervision (tableaux Crash/Edge Function/File/Sync) plutôt que d\'être dupliqués ici.'**
  String get evolutionAuditCenterHealthCenterNote;

  /// No description provided for @settingsAuditCenterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'audit'**
  String get settingsAuditCenterLabel;

  /// No description provided for @settingsMaintenanceAdminLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fenêtres de maintenance'**
  String get settingsMaintenanceAdminLabel;

  /// No description provided for @evolutionMaintenanceDefaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance en cours'**
  String get evolutionMaintenanceDefaultTitle;

  /// No description provided for @evolutionMaintenanceDefaultMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'application est temporairement indisponible. Nous reviendrons très bientôt.'**
  String get evolutionMaintenanceDefaultMessage;

  /// No description provided for @evolutionMaintenanceEndsAt.
  ///
  /// In fr, this message translates to:
  /// **'Fin prévue vers {time}'**
  String evolutionMaintenanceEndsAt(String time);

  /// No description provided for @evolutionForceUpdateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour requise'**
  String get evolutionForceUpdateTitle;

  /// No description provided for @evolutionForceUpdateDefaultMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette version de l\'application n\'est plus supportée. Veuillez mettre à jour pour continuer.'**
  String get evolutionForceUpdateDefaultMessage;

  /// No description provided for @evolutionForceUpdateVersionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version disponible : {version}'**
  String evolutionForceUpdateVersionLabel(String version);

  /// No description provided for @evolutionForceUpdateCheckButton.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier à nouveau'**
  String get evolutionForceUpdateCheckButton;

  /// No description provided for @evolutionForceUpdateButton.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get evolutionForceUpdateButton;

  /// No description provided for @evolutionMaintenanceCheckButton.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier à nouveau'**
  String get evolutionMaintenanceCheckButton;

  /// No description provided for @automationListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Automatisations'**
  String get automationListTitle;

  /// No description provided for @automationListHistoryTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Historique d\'exécution'**
  String get automationListHistoryTooltip;

  /// No description provided for @automationListEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune automatisation'**
  String get automationListEmptyTitle;

  /// No description provided for @automationListEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez un workflow pour automatiser une action quand un événement se produit.'**
  String get automationListEmptySubtitle;

  /// No description provided for @automationWorkflowTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau workflow'**
  String get automationWorkflowTitle;

  /// No description provided for @automationWorkflowNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get automationWorkflowNameLabel;

  /// No description provided for @automationWorkflowDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get automationWorkflowDescriptionLabel;

  /// No description provided for @automationWorkflowConditionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions'**
  String get automationWorkflowConditionsTitle;

  /// No description provided for @automationWorkflowNoConditions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune condition — le workflow s\'exécutera à chaque déclenchement.'**
  String get automationWorkflowNoConditions;

  /// No description provided for @automationWorkflowActionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get automationWorkflowActionsTitle;

  /// No description provided for @automationWorkflowNoActions.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins une action à exécuter.'**
  String get automationWorkflowNoActions;

  /// No description provided for @automationWorkflowFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Champ (ex. amount)'**
  String get automationWorkflowFieldLabel;

  /// No description provided for @automationWorkflowValueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Valeur'**
  String get automationWorkflowValueLabel;

  /// No description provided for @automationWorkflowDelayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Délai (secondes) :'**
  String get automationWorkflowDelayLabel;

  /// No description provided for @automationWorkflowTargetLabel.
  ///
  /// In fr, this message translates to:
  /// **'Destinataire'**
  String get automationWorkflowTargetLabel;

  /// No description provided for @automationWorkflowEventHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. booking_confirmed'**
  String get automationWorkflowEventHint;

  /// No description provided for @automationWorkflowStampsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tampons bonus'**
  String get automationWorkflowStampsLabel;

  /// No description provided for @automationWorkflowReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Raison (optionnel)'**
  String get automationWorkflowReasonLabel;

  /// No description provided for @automationWorkflowActionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get automationWorkflowActionLabel;

  /// No description provided for @automationWorkflowNotWired.
  ///
  /// In fr, this message translates to:
  /// **'(pas encore câblé)'**
  String get automationWorkflowNotWired;

  /// No description provided for @automationWorkflowComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'(bientôt)'**
  String get automationWorkflowComingSoon;

  /// No description provided for @automationWorkflowNotImplemented.
  ///
  /// In fr, this message translates to:
  /// **'Cette action n\'est pas encore disponible.'**
  String get automationWorkflowNotImplemented;

  /// No description provided for @automationWorkflowExecutionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 exécution} =1{1 exécution} other{{count} exécutions}}'**
  String automationWorkflowExecutionCount(int count);

  /// No description provided for @automationWorkflowTriggersLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les déclencheurs.'**
  String get automationWorkflowTriggersLoadError;

  /// No description provided for @automationWorkflowValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Le nom et le déclencheur sont requis.'**
  String get automationWorkflowValidationError;

  /// No description provided for @automationWorkflowCreateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer ce workflow.'**
  String get automationWorkflowCreateError;

  /// No description provided for @automationWorkflowTriggerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Déclencheur'**
  String get automationWorkflowTriggerLabel;

  /// No description provided for @automationWorkflowCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer le workflow'**
  String get automationWorkflowCreateButton;

  /// No description provided for @automationWorkflowLogicOperatorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Opérateur logique'**
  String get automationWorkflowLogicOperatorLabel;

  /// No description provided for @automationWorkflowOperatorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Opérateur'**
  String get automationWorkflowOperatorLabel;

  /// No description provided for @automationWorkflowEventLabel.
  ///
  /// In fr, this message translates to:
  /// **'Événement (event_type)'**
  String get automationWorkflowEventLabel;

  /// No description provided for @automationWorkflowSeverityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sévérité'**
  String get automationWorkflowSeverityLabel;

  /// No description provided for @searchAdvancedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get searchAdvancedTitle;

  /// No description provided for @searchAdvancedHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher salons, services…'**
  String get searchAdvancedHint;

  /// No description provided for @searchAdvancedClearButton.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get searchAdvancedClearButton;

  /// No description provided for @searchFiltersResetButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get searchFiltersResetButton;

  /// No description provided for @salonCreationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer votre salon'**
  String get salonCreationTitle;

  /// No description provided for @salonLocationHint.
  ///
  /// In fr, this message translates to:
  /// **'Rue, numéro, quartier'**
  String get salonLocationHint;

  /// No description provided for @salonCreationNextButton.
  ///
  /// In fr, this message translates to:
  /// **'Suivant →'**
  String get salonCreationNextButton;

  /// No description provided for @salonCreationSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon salon →'**
  String get salonCreationSubmitButton;

  /// No description provided for @salonCreationErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le salon. Réessayez.'**
  String get salonCreationErrorGeneric;

  /// No description provided for @salonInfoStepNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du salon *'**
  String get salonInfoStepNameLabel;

  /// No description provided for @salonInfoStepSloganLabel.
  ///
  /// In fr, this message translates to:
  /// **'Slogan'**
  String get salonInfoStepSloganLabel;

  /// No description provided for @salonInfoStepDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get salonInfoStepDescriptionLabel;

  /// No description provided for @salonInfoStepSocialTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réseaux sociaux'**
  String get salonInfoStepSocialTitle;

  /// No description provided for @salonLocationStepAddressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get salonLocationStepAddressLabel;

  /// No description provided for @salonMediaStepLogoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Logo'**
  String get salonMediaStepLogoLabel;

  /// No description provided for @salonMediaStepCoverLabel.
  ///
  /// In fr, this message translates to:
  /// **'Photo de couverture'**
  String get salonMediaStepCoverLabel;

  /// No description provided for @salonMediaStepAddCoverLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une couverture'**
  String get salonMediaStepAddCoverLabel;

  /// No description provided for @salonMediaStepGalleryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Galerie ({count}/{max})'**
  String salonMediaStepGalleryLabel(int count, int max);

  /// No description provided for @salonCreationSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre salon est créé ! 🎉'**
  String get salonCreationSuccessTitle;

  /// No description provided for @salonCreationSuccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez maintenant vos services'**
  String get salonCreationSuccessSubtitle;

  /// No description provided for @salonCreationSuccessCtaLabel.
  ///
  /// In fr, this message translates to:
  /// **'Configurer mes services →'**
  String get salonCreationSuccessCtaLabel;

  /// No description provided for @provinceSelectorProvinceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Province'**
  String get provinceSelectorProvinceLabel;

  /// No description provided for @provinceSelectorProvinceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Province requise.'**
  String get provinceSelectorProvinceRequired;

  /// No description provided for @provinceSelectorCommuneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Commune'**
  String get provinceSelectorCommuneLabel;

  /// No description provided for @provinceSelectorCommuneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Commune requise.'**
  String get provinceSelectorCommuneRequired;

  /// No description provided for @workingHoursClosed.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get workingHoursClosed;

  /// No description provided for @loyaltyCardsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos cartes de fidélité.'**
  String get loyaltyCardsLoadError;

  /// No description provided for @loyaltyCardsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte de fidélité'**
  String get loyaltyCardsEmptyTitle;

  /// No description provided for @loyaltyCardsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservez votre premier RDV pour commencer à collecter des tampons ! 💛'**
  String get loyaltyCardsEmptySubtitle;

  /// No description provided for @loyaltyCardsEmptyCtaLabel.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir les salons'**
  String get loyaltyCardsEmptyCtaLabel;

  /// No description provided for @loyaltyQrCardNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Carte de fidélité introuvable.'**
  String get loyaltyQrCardNotFound;

  /// No description provided for @loyaltyQrGenerateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le QR code.'**
  String get loyaltyQrGenerateError;

  /// No description provided for @loyaltyQrShowToStaff.
  ///
  /// In fr, this message translates to:
  /// **'Montrez ce code au personnel du salon'**
  String get loyaltyQrShowToStaff;

  /// No description provided for @loyaltyQrExpiresIn.
  ///
  /// In fr, this message translates to:
  /// **'Expire dans {minutes}:{seconds}'**
  String loyaltyQrExpiresIn(String minutes, String seconds);

  /// No description provided for @loyaltyScanQrInvalidError.
  ///
  /// In fr, this message translates to:
  /// **'QR invalide ou expiré.'**
  String get loyaltyScanQrInvalidError;

  /// No description provided for @loyaltyScanConnectionError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Réessayez.'**
  String get loyaltyScanConnectionError;

  /// No description provided for @loyaltyStampsRequired.
  ///
  /// In fr, this message translates to:
  /// **'{required} tampons requis'**
  String loyaltyStampsRequired(int required);

  /// No description provided for @loyaltyStampsProgress.
  ///
  /// In fr, this message translates to:
  /// **'{count} / {total} tampons'**
  String loyaltyStampsProgress(int count, int total);

  /// No description provided for @loyaltyRewardAvailable.
  ///
  /// In fr, this message translates to:
  /// **'🎉 Récompense disponible ! Montrez ce code au salon.'**
  String get loyaltyRewardAvailable;

  /// No description provided for @loyaltyStampLogsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique de vos tampons'**
  String get loyaltyStampLogsTitle;

  /// No description provided for @loyaltyStampLogsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'historique.'**
  String get loyaltyStampLogsLoadError;

  /// No description provided for @loyaltyStampLogsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tampon pour le moment.'**
  String get loyaltyStampLogsEmpty;

  /// No description provided for @loyaltyStampAdded.
  ///
  /// In fr, this message translates to:
  /// **'Tampon ajouté'**
  String get loyaltyStampAdded;

  /// No description provided for @loyaltyStampRewardValidated.
  ///
  /// In fr, this message translates to:
  /// **'Récompense validée'**
  String get loyaltyStampRewardValidated;

  /// No description provided for @loyaltyShowQrButton.
  ///
  /// In fr, this message translates to:
  /// **'Afficher mon QR'**
  String get loyaltyShowQrButton;

  /// No description provided for @journeyLaunchTitle.
  ///
  /// In fr, this message translates to:
  /// **'🚀 Lancez votre salon'**
  String get journeyLaunchTitle;

  /// No description provided for @journeySalonReady.
  ///
  /// In fr, this message translates to:
  /// **'🎉 Votre salon est prêt !'**
  String get journeySalonReady;

  /// No description provided for @permissionsGroupsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les groupes de permissions.'**
  String get permissionsGroupsLoadError;

  /// No description provided for @permissionsGroupEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe de permissions'**
  String get permissionsGroupEmptyTitle;

  /// No description provided for @permissionsGroupEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez un groupe pour donner à un membre de votre équipe des droits précis, au-delà de son rôle de base.'**
  String get permissionsGroupEmptySubtitle;

  /// No description provided for @permissionsGroupEmptyCtaLabel.
  ///
  /// In fr, this message translates to:
  /// **'Créer un groupe'**
  String get permissionsGroupEmptyCtaLabel;

  /// No description provided for @permissionsGroupDetailLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce groupe.'**
  String get permissionsGroupDetailLoadError;

  /// No description provided for @permissionsGroupNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Groupe introuvable'**
  String get permissionsGroupNotFound;

  /// No description provided for @permissionsGroupNotFoundSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce groupe a peut-être été supprimé.'**
  String get permissionsGroupNotFoundSubtitle;

  /// No description provided for @permissionsGroupDefaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Groupe de permissions'**
  String get permissionsGroupDefaultTitle;

  /// No description provided for @permissionsGroupDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les membres de \"{name}\" perdront les permissions accordées par ce groupe.'**
  String permissionsGroupDeleteConfirmMessage(String name);

  /// No description provided for @permissionsPermissionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Permissions'**
  String get permissionsPermissionsTitle;

  /// No description provided for @permissionsPermissionsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les permissions.'**
  String get permissionsPermissionsLoadError;

  /// No description provided for @permissionsMembersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get permissionsMembersTitle;

  /// No description provided for @permissionsMembersEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre dans ce groupe pour le moment.'**
  String get permissionsMembersEmpty;

  /// No description provided for @permissionsAddMemberTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un membre'**
  String get permissionsAddMemberTitle;

  /// No description provided for @permissionsAddMemberAllInGroup.
  ///
  /// In fr, this message translates to:
  /// **'Toute l\'équipe fait déjà partie de ce groupe.'**
  String get permissionsAddMemberAllInGroup;

  /// No description provided for @permissionsMemberFallback.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get permissionsMemberFallback;

  /// No description provided for @permissionsGroupFormTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau groupe de permissions'**
  String get permissionsGroupFormTitle;

  /// No description provided for @permissionsGroupFormNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get permissionsGroupFormNameLabel;

  /// No description provided for @permissionsGroupFormDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get permissionsGroupFormDescriptionLabel;

  /// No description provided for @permissionsGroupFormBaseRoleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rôle de base'**
  String get permissionsGroupFormBaseRoleLabel;

  /// No description provided for @permissionsGroupFormNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom requis'**
  String get permissionsGroupFormNameRequired;

  /// No description provided for @permissionsGroupFormCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe'**
  String get permissionsGroupFormCreateButton;

  /// No description provided for @loyaltyScanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner fidélité'**
  String get loyaltyScanTitle;

  /// No description provided for @loyaltyQrTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon QR fidélité'**
  String get loyaltyQrTitle;

  /// No description provided for @journeyProgressCloseButton.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get journeyProgressCloseButton;

  /// No description provided for @journeyProgressContinueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer la configuration →'**
  String get journeyProgressContinueButton;

  /// No description provided for @referralClaimVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de l\'invitation...'**
  String get referralClaimVerifying;

  /// No description provided for @teamCommissionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commissions'**
  String get teamCommissionsTitle;

  /// No description provided for @notificationsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get notificationsFilterAll;

  /// No description provided for @notificationsFilterBooking.
  ///
  /// In fr, this message translates to:
  /// **'RDV'**
  String get notificationsFilterBooking;

  /// No description provided for @notificationsFilterLoyalty.
  ///
  /// In fr, this message translates to:
  /// **'Fidélité'**
  String get notificationsFilterLoyalty;

  /// No description provided for @notificationsFilterMarketing.
  ///
  /// In fr, this message translates to:
  /// **'Marketing'**
  String get notificationsFilterMarketing;

  /// No description provided for @notificationsFilterSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get notificationsFilterSystem;

  /// No description provided for @notificationsSectionToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get notificationsSectionToday;

  /// No description provided for @notificationsSectionThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get notificationsSectionThisWeek;

  /// No description provided for @notificationsSectionOlder.
  ///
  /// In fr, this message translates to:
  /// **'Plus ancien'**
  String get notificationsSectionOlder;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer lu'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Revenez bientôt — vos alertes apparaîtront ici.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsLoadErrorFeed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos notifications.'**
  String get notificationsLoadErrorFeed;

  /// No description provided for @notificationsDeletedSnack.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » supprimée.'**
  String notificationsDeletedSnack(String title);

  /// No description provided for @staffListEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitez votre équipe pour commencer à organiser le planning, ou travaillez seul pour commencer.'**
  String get staffListEmptySubtitle;

  /// No description provided for @staffCountActive.
  ///
  /// In fr, this message translates to:
  /// **'actifs'**
  String get staffCountActive;

  /// No description provided for @staffCountPending.
  ///
  /// In fr, this message translates to:
  /// **'en attente'**
  String get staffCountPending;

  /// No description provided for @staffCountDisabled.
  ///
  /// In fr, this message translates to:
  /// **'désactivés'**
  String get staffCountDisabled;

  /// No description provided for @staffNoMembersInCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre dans cette catégorie.'**
  String get staffNoMembersInCategory;

  /// No description provided for @staffDetailPerformanceMonth.
  ///
  /// In fr, this message translates to:
  /// **'Performance ce mois'**
  String get staffDetailPerformanceMonth;

  /// No description provided for @staffDetailCommissionsMonth.
  ///
  /// In fr, this message translates to:
  /// **'Commissions ce mois'**
  String get staffDetailCommissionsMonth;

  /// No description provided for @staffDetailServicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Services proposés'**
  String get staffDetailServicesTitle;

  /// No description provided for @staffDetailLastBookings.
  ///
  /// In fr, this message translates to:
  /// **'Derniers RDV'**
  String get staffDetailLastBookings;

  /// No description provided for @staffDetailNoSpecialty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune spécialité.'**
  String get staffDetailNoSpecialty;

  /// No description provided for @staffDetailNoBookings.
  ///
  /// In fr, this message translates to:
  /// **'Aucun RDV pour le moment.'**
  String get staffDetailNoBookings;

  /// No description provided for @staffDetailScheduleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Horaires'**
  String get staffDetailScheduleLabel;

  /// No description provided for @staffDetailDeactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get staffDetailDeactivate;

  /// No description provided for @staffDetailReactivate.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver'**
  String get staffDetailReactivate;

  /// No description provided for @staffDetailDemote.
  ///
  /// In fr, this message translates to:
  /// **'Rétrograder en staff'**
  String get staffDetailDemote;

  /// No description provided for @staffDetailPromote.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir manager'**
  String get staffDetailPromote;

  /// No description provided for @staffDetailRemoveButton.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du salon'**
  String get staffDetailRemoveButton;

  /// No description provided for @staffDetailRemoveConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce membre ?'**
  String get staffDetailRemoveConfirmTitle;

  /// No description provided for @staffDetailRemoveConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne pourra plus accéder à ce salon.'**
  String staffDetailRemoveConfirmMessage(String name);

  /// No description provided for @staffDetailCommissionsEarned.
  ///
  /// In fr, this message translates to:
  /// **'Gagné'**
  String get staffDetailCommissionsEarned;

  /// No description provided for @staffDetailCommissionsPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get staffDetailCommissionsPaid;

  /// No description provided for @staffDetailCommissionsPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get staffDetailCommissionsPending;

  /// No description provided for @staffFormDisplayNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom affiché'**
  String get staffFormDisplayNameLabel;

  /// No description provided for @staffFormPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get staffFormPhoneLabel;

  /// No description provided for @staffFormBioLabel.
  ///
  /// In fr, this message translates to:
  /// **'Bio'**
  String get staffFormBioLabel;

  /// No description provided for @staffFormCommissionSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commission'**
  String get staffFormCommissionSectionTitle;

  /// No description provided for @staffFormCommissionTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get staffFormCommissionTypeLabel;

  /// No description provided for @staffFormCommissionTypePercent.
  ///
  /// In fr, this message translates to:
  /// **'% du RDV'**
  String get staffFormCommissionTypePercent;

  /// No description provided for @staffFormCommissionTypeFixed.
  ///
  /// In fr, this message translates to:
  /// **'FBu fixe'**
  String get staffFormCommissionTypeFixed;

  /// No description provided for @staffFormCommissionRatePercent.
  ///
  /// In fr, this message translates to:
  /// **'Taux (%)'**
  String get staffFormCommissionRatePercent;

  /// No description provided for @staffFormCommissionRateFixed.
  ///
  /// In fr, this message translates to:
  /// **'Montant (FBu)'**
  String get staffFormCommissionRateFixed;

  /// No description provided for @staffFormSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get staffFormSaveButton;

  /// No description provided for @staffFormRemoveButton.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce membre'**
  String get staffFormRemoveButton;

  /// No description provided for @acceptInvitationWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans l\'équipe !'**
  String get acceptInvitationWelcome;

  /// No description provided for @acceptInvitationError.
  ///
  /// In fr, this message translates to:
  /// **'Invitation invalide ou expirée. Contactez votre salon pour en recevoir une nouvelle.'**
  String get acceptInvitationError;

  /// No description provided for @myPerfMyBookings.
  ///
  /// In fr, this message translates to:
  /// **'Mes RDV'**
  String get myPerfMyBookings;

  /// No description provided for @myPerfMyRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Mon CA'**
  String get myPerfMyRevenue;

  /// No description provided for @myPerfRankText.
  ///
  /// In fr, this message translates to:
  /// **'{rank}{suffix} sur {teamSize} cette semaine'**
  String myPerfRankText(int rank, String suffix, int teamSize);

  /// No description provided for @myPerfMonthTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes RDV ce mois'**
  String get myPerfMonthTitle;

  /// No description provided for @myPerfReviewsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes avis récents'**
  String get myPerfReviewsTitle;

  /// No description provided for @myPerfNoBookings.
  ///
  /// In fr, this message translates to:
  /// **'Aucun RDV terminé ce mois.'**
  String get myPerfNoBookings;

  /// No description provided for @myPerfNoReviews.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis pour le moment.'**
  String get myPerfNoReviews;

  /// No description provided for @myPerfCommissionsMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mes commissions ce mois'**
  String get myPerfCommissionsMonth;

  /// No description provided for @myPerfCommissionsPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get myPerfCommissionsPaid;

  /// No description provided for @myPerfCommissionsPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get myPerfCommissionsPending;

  /// No description provided for @marketingFillMyDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Remplir ma journée'**
  String get marketingFillMyDayTitle;

  /// No description provided for @marketingFillMyDaySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Des créneaux libres aujourd\'hui ou demain ? Partagez une promotion à vos contacts personnels (max 2 par semaine).'**
  String get marketingFillMyDaySubtitle;

  /// No description provided for @marketingFillMyDayButton.
  ///
  /// In fr, this message translates to:
  /// **'Partager une promo →'**
  String get marketingFillMyDayButton;

  /// No description provided for @marketingFillMyDayLimitReached.
  ///
  /// In fr, this message translates to:
  /// **'Limite de 2 promotions par semaine atteinte.'**
  String get marketingFillMyDayLimitReached;

  /// No description provided for @marketingRecentContactsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contacts récents'**
  String get marketingRecentContactsTitle;

  /// No description provided for @marketingNoContactsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contact pour le moment.'**
  String get marketingNoContactsYet;

  /// No description provided for @marketingManageButton.
  ///
  /// In fr, this message translates to:
  /// **'Gérer →'**
  String get marketingManageButton;

  /// No description provided for @marketingNewBadge.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get marketingNewBadge;

  /// No description provided for @marketingFreeBadge.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get marketingFreeBadge;

  /// No description provided for @marketingActiveBadge.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get marketingActiveBadge;

  /// No description provided for @marketingToConfigureBadge.
  ///
  /// In fr, this message translates to:
  /// **'À configurer'**
  String get marketingToConfigureBadge;

  /// No description provided for @marketingExpiringSoonBadge.
  ///
  /// In fr, this message translates to:
  /// **'Expire bientôt'**
  String get marketingExpiringSoonBadge;

  /// No description provided for @marketingShareServicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager mes services'**
  String get marketingShareServicesTitle;

  /// No description provided for @marketingNoServicesToShare.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service à partager pour le moment.'**
  String get marketingNoServicesToShare;

  /// No description provided for @marketingSharePromotionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager une promotion'**
  String get marketingSharePromotionTitle;

  /// No description provided for @marketingInviteLinkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lien d\'invitation personnalisé'**
  String get marketingInviteLinkTitle;

  /// No description provided for @marketingInviteLinkSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Partagez ce lien. Vos clients téléchargent KYNZA et vous retrouvent directement.'**
  String get marketingInviteLinkSubtitle;

  /// No description provided for @marketingInviteLinkGenError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le lien pour l\'instant.'**
  String get marketingInviteLinkGenError;

  /// No description provided for @marketingCopyLinkButton.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get marketingCopyLinkButton;

  /// No description provided for @marketingShareArrowButton.
  ///
  /// In fr, this message translates to:
  /// **'Partager →'**
  String get marketingShareArrowButton;

  /// No description provided for @marketingLinkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié !'**
  String get marketingLinkCopied;

  /// No description provided for @marketingLoadSalonError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre salon.'**
  String get marketingLoadSalonError;

  /// No description provided for @marketingImportFromBookingsButton.
  ///
  /// In fr, this message translates to:
  /// **'Importer depuis les RDV'**
  String get marketingImportFromBookingsButton;

  /// No description provided for @marketingSearchContactHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un contact'**
  String get marketingSearchContactHint;

  /// No description provided for @marketingNoContactsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contact encore'**
  String get marketingNoContactsTitle;

  /// No description provided for @marketingNoContactsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos premiers clients.'**
  String get marketingNoContactsSubtitle;

  /// No description provided for @marketingAddContactButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un contact'**
  String get marketingAddContactButton;

  /// No description provided for @marketingImportNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun nouveau client à importer.'**
  String get marketingImportNone;

  /// No description provided for @marketingImportCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 client importé.} other{{count} clients importés.}}'**
  String marketingImportCount(int count);

  /// No description provided for @marketingNoInvitationsSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune invitation envoyée'**
  String get marketingNoInvitationsSentTitle;

  /// No description provided for @marketingNoInvitationsSentSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Partagez un lien de parrainage depuis vos contacts.'**
  String get marketingNoInvitationsSentSubtitle;

  /// No description provided for @marketingInviteSentOnDate.
  ///
  /// In fr, this message translates to:
  /// **'Envoyée le {date}'**
  String marketingInviteSentOnDate(String date);

  /// No description provided for @marketingInviteAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Acceptée'**
  String get marketingInviteAccepted;

  /// No description provided for @marketingInviteSent.
  ///
  /// In fr, this message translates to:
  /// **'Envoyée'**
  String get marketingInviteSent;

  /// No description provided for @marketingAddContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un contact'**
  String get marketingAddContactTitle;

  /// No description provided for @marketingFullNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet *'**
  String get marketingFullNameLabel;

  /// No description provided for @marketingLoyaltyLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le programme.'**
  String get marketingLoyaltyLoadError;

  /// No description provided for @marketingLoyaltyEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fidélisez vos clients'**
  String get marketingLoyaltyEmptyTitle;

  /// No description provided for @marketingLoyaltyEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Offrez des tampons à chaque visite. À la X ème visite, offrez une récompense.'**
  String get marketingLoyaltyEmptySubtitle;

  /// No description provided for @marketingLoyaltySetupCta.
  ///
  /// In fr, this message translates to:
  /// **'Configurer mon programme'**
  String get marketingLoyaltySetupCta;

  /// No description provided for @marketingLoyaltyStampsRequiredLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tampons requis'**
  String get marketingLoyaltyStampsRequiredLabel;

  /// No description provided for @marketingLoyaltyStampsRequiredHint.
  ///
  /// In fr, this message translates to:
  /// **'Après {count} visites, votre client reçoit une récompense.'**
  String marketingLoyaltyStampsRequiredHint(int count);

  /// No description provided for @marketingLoyaltyRewardDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: 1 coupe offerte'**
  String get marketingLoyaltyRewardDescriptionHint;

  /// No description provided for @marketingLoyaltyRewardValueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Valeur en FBu (optionnel)'**
  String get marketingLoyaltyRewardValueLabel;

  /// No description provided for @marketingLoyaltyProgramActiveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Programme actif'**
  String get marketingLoyaltyProgramActiveLabel;

  /// No description provided for @marketingLoyaltyCardPreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu carte client'**
  String get marketingLoyaltyCardPreviewTitle;

  /// No description provided for @marketingLoyaltyStatsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get marketingLoyaltyStatsTitle;

  /// No description provided for @marketingLoyaltyTopClientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Clients les plus fidèles'**
  String get marketingLoyaltyTopClientsTitle;

  /// No description provided for @marketingLoyaltyStatCardsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Cartes'**
  String get marketingLoyaltyStatCardsLabel;

  /// No description provided for @marketingLoyaltyStampsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} tampons'**
  String marketingLoyaltyStampsCount(int count);

  /// No description provided for @marketingLoyaltyValidateButton.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get marketingLoyaltyValidateButton;

  /// No description provided for @marketingLoyaltyValidateError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la validation.'**
  String get marketingLoyaltyValidateError;

  /// No description provided for @marketingLoyaltySaveError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'enregistrement.'**
  String get marketingLoyaltySaveError;

  /// No description provided for @marketingLoyaltyCardStampsRequired.
  ///
  /// In fr, this message translates to:
  /// **'{count} tampons requis'**
  String marketingLoyaltyCardStampsRequired(int count);

  /// No description provided for @marketingLoyaltyVisitsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Plus que {count} visites pour la récompense !'**
  String marketingLoyaltyVisitsRemaining(int count);

  /// No description provided for @marketingLoyaltyRewardValidateConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'{name} a atteint {count} tampons. Ses tampons seront remis à zéro.'**
  String marketingLoyaltyRewardValidateConfirmMessage(String name, int count);

  /// No description provided for @promotionFormCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une promotion'**
  String get promotionFormCreateTitle;

  /// No description provided for @promotionFormEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la promotion'**
  String get promotionFormEditTitle;

  /// No description provided for @promotionFormTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre *'**
  String get promotionFormTitleLabel;

  /// No description provided for @promotionFormDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get promotionFormDescriptionLabel;

  /// No description provided for @promotionFormValuePercentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Valeur (%) *'**
  String get promotionFormValuePercentLabel;

  /// No description provided for @promotionFormValueBifLabel.
  ///
  /// In fr, this message translates to:
  /// **'Valeur (FBu) *'**
  String get promotionFormValueBifLabel;

  /// No description provided for @promotionFormTargetServiceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Service ciblé (optionnel)'**
  String get promotionFormTargetServiceLabel;

  /// No description provided for @promotionFormAllServices.
  ///
  /// In fr, this message translates to:
  /// **'Tous les services'**
  String get promotionFormAllServices;

  /// No description provided for @promotionFormStartDate.
  ///
  /// In fr, this message translates to:
  /// **'Début : {date}'**
  String promotionFormStartDate(String date);

  /// No description provided for @promotionFormEndDate.
  ///
  /// In fr, this message translates to:
  /// **'Fin : {date}'**
  String promotionFormEndDate(String date);

  /// No description provided for @promotionFormMaxUsesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'utilisations max (optionnel)'**
  String get promotionFormMaxUsesLabel;

  /// No description provided for @promotionFormNoCode.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code promo'**
  String get promotionFormNoCode;

  /// No description provided for @promotionFormGenerateCodeButton.
  ///
  /// In fr, this message translates to:
  /// **'Générer un code'**
  String get promotionFormGenerateCodeButton;

  /// No description provided for @promotionFormCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer la promotion'**
  String get promotionFormCreateButton;

  /// No description provided for @promotionFormSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'enregistrement.'**
  String get promotionFormSaveError;

  /// No description provided for @promotionFormTitlePlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la promotion'**
  String get promotionFormTitlePlaceholder;

  /// No description provided for @promotionCardServiceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Service : {name}'**
  String promotionCardServiceLabel(String name);

  /// No description provided for @promotionCardShareButton.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get promotionCardShareButton;

  /// No description provided for @promotionCardEditButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get promotionCardEditButton;

  /// No description provided for @promotionCardDeactivateButton.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get promotionCardDeactivateButton;

  /// No description provided for @promotionDeactivateError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la désactivation.'**
  String get promotionDeactivateError;

  /// No description provided for @searchResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get searchResultsTitle;

  /// No description provided for @searchSalonsSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Salons'**
  String get searchSalonsSectionLabel;

  /// No description provided for @searchServicesSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get searchServicesSectionLabel;

  /// No description provided for @searchRecentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Recherches récentes'**
  String get searchRecentLabel;

  /// No description provided for @searchClearButton.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get searchClearButton;

  /// No description provided for @searchPopularLabel.
  ///
  /// In fr, this message translates to:
  /// **'Recherches populaires'**
  String get searchPopularLabel;

  /// No description provided for @searchNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get searchNoResults;

  /// No description provided for @searchNoResultsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Essayez une autre recherche ou filtre.'**
  String get searchNoResultsSubtitle;

  /// No description provided for @searchLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer la recherche.'**
  String get searchLoadError;

  /// No description provided for @searchFiltersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get searchFiltersTitle;

  /// No description provided for @searchFiltersPriceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix (FBu) — {min} à {max}'**
  String searchFiltersPriceLabel(String min, String max);

  /// No description provided for @searchFiltersMinRatingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note minimum'**
  String get searchFiltersMinRatingLabel;

  /// No description provided for @searchFiltersCategoriesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get searchFiltersCategoriesLabel;

  /// No description provided for @searchFiltersProvinceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Province'**
  String get searchFiltersProvinceLabel;

  /// No description provided for @searchFiltersAllProvinces.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les provinces'**
  String get searchFiltersAllProvinces;

  /// No description provided for @searchFiltersSortByLabel.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get searchFiltersSortByLabel;

  /// No description provided for @searchFiltersApplyButton.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get searchFiltersApplyButton;

  /// No description provided for @searchSortRelevance.
  ///
  /// In fr, this message translates to:
  /// **'Pertinence'**
  String get searchSortRelevance;

  /// No description provided for @searchSortPriceAsc.
  ///
  /// In fr, this message translates to:
  /// **'Prix ↑'**
  String get searchSortPriceAsc;

  /// No description provided for @searchSortPriceDesc.
  ///
  /// In fr, this message translates to:
  /// **'Prix ↓'**
  String get searchSortPriceDesc;

  /// No description provided for @searchSortRating.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get searchSortRating;

  /// No description provided for @billingCurrentPlanLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plan actuel'**
  String get billingCurrentPlanLabel;

  /// No description provided for @billingCurrentPeriodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Période en cours'**
  String get billingCurrentPeriodLabel;

  /// No description provided for @billingPaymentMethodManual.
  ///
  /// In fr, this message translates to:
  /// **'Méthode de paiement : Manuelle (virement bancaire)'**
  String get billingPaymentMethodManual;

  /// No description provided for @billingNextBillingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine facturation : {date}'**
  String billingNextBillingLabel(String date);

  /// No description provided for @billingManageSubscriptionButton.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mon abonnement'**
  String get billingManageSubscriptionButton;

  /// No description provided for @billingInvoiceHistoryButton.
  ///
  /// In fr, this message translates to:
  /// **'Historique des factures'**
  String get billingInvoiceHistoryButton;

  /// No description provided for @billingCurrentMonthUsage.
  ///
  /// In fr, this message translates to:
  /// **'{used} / {max} RDV ce mois'**
  String billingCurrentMonthUsage(int used, int max);

  /// No description provided for @billingCurrentPlanBadgeFree.
  ///
  /// In fr, this message translates to:
  /// **'PLAN GRATUIT'**
  String get billingCurrentPlanBadgeFree;

  /// No description provided for @billingCurrentPlanBadge.
  ///
  /// In fr, this message translates to:
  /// **'PLAN {plan}'**
  String billingCurrentPlanBadge(String plan);

  /// No description provided for @billingPlanCurrentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plan actuel'**
  String get billingPlanCurrentLabel;

  /// No description provided for @billingPlanUpgradeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Passer à {name} →'**
  String billingPlanUpgradeLabel(String name);

  /// No description provided for @billingPlanDowngradeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rétrograder'**
  String get billingPlanDowngradeLabel;

  /// No description provided for @billingUpgradeRequestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous demandez une mise à niveau vers {name}.'**
  String billingUpgradeRequestTitle(String name);

  /// No description provided for @billingUpgradeRequestSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe vous contactera pour le paiement.'**
  String get billingUpgradeRequestSubtitle;

  /// No description provided for @billingUpgradeConfirmButton.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la demande'**
  String get billingUpgradeConfirmButton;

  /// No description provided for @billingUpgradeSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée ! 🎉'**
  String get billingUpgradeSentTitle;

  /// No description provided for @billingUpgradeReferenceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence à inclure : {ref}'**
  String billingUpgradeReferenceLabel(String ref);

  /// No description provided for @billingUpgradeShareButton.
  ///
  /// In fr, this message translates to:
  /// **'Partager les instructions'**
  String get billingUpgradeShareButton;

  /// No description provided for @billingUpgradeDoneButton.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get billingUpgradeDoneButton;

  /// No description provided for @billingUpgradeReferenceCopied.
  ///
  /// In fr, this message translates to:
  /// **'Référence copiée !'**
  String get billingUpgradeReferenceCopied;

  /// No description provided for @billingInvoicesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les factures.'**
  String get billingInvoicesLoadError;

  /// No description provided for @billingInvoicesEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture'**
  String get billingInvoicesEmptyTitle;

  /// No description provided for @billingInvoicesEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos factures apparaîtront ici après une demande de mise à niveau.'**
  String get billingInvoicesEmptySubtitle;

  /// No description provided for @billingInvoiceStatusPaid.
  ///
  /// In fr, this message translates to:
  /// **'PAYÉE'**
  String get billingInvoiceStatusPaid;

  /// No description provided for @billingInvoiceStatusOverdue.
  ///
  /// In fr, this message translates to:
  /// **'EN RETARD'**
  String get billingInvoiceStatusOverdue;

  /// No description provided for @billingInvoiceStatusVoid.
  ///
  /// In fr, this message translates to:
  /// **'ANNULÉE'**
  String get billingInvoiceStatusVoid;

  /// No description provided for @billingInvoiceStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE'**
  String get billingInvoiceStatusPending;

  /// No description provided for @billingInvoicePaymentInstructionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Instructions de paiement'**
  String get billingInvoicePaymentInstructionsTitle;

  /// No description provided for @billingInvoiceExportPdfButton.
  ///
  /// In fr, this message translates to:
  /// **'Exporter facture PDF'**
  String get billingInvoiceExportPdfButton;

  /// No description provided for @billingInvoiceShareButton.
  ///
  /// In fr, this message translates to:
  /// **'Partager la facture'**
  String get billingInvoiceShareButton;

  /// No description provided for @billingInvoiceMarkPaidButton.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme payé'**
  String get billingInvoiceMarkPaidButton;

  /// No description provided for @upgradeSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée ! 🎉'**
  String get upgradeSuccessTitle;

  /// No description provided for @upgradeSuccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe va vous contacter sous 24h pour finaliser votre mise à niveau.'**
  String get upgradeSuccessSubtitle;

  /// No description provided for @upgradeSuccessNote.
  ///
  /// In fr, this message translates to:
  /// **'En attendant, vous pouvez continuer à utiliser KYNZA.'**
  String get upgradeSuccessNote;

  /// No description provided for @upgradeSuccessBackButton.
  ///
  /// In fr, this message translates to:
  /// **'Retour au dashboard'**
  String get upgradeSuccessBackButton;

  /// No description provided for @salonMediaDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce média ?'**
  String get salonMediaDeleteTitle;

  /// No description provided for @salonMediaDeleteMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action retire le média de votre galerie.'**
  String get salonMediaDeleteMessage;

  /// No description provided for @dashboardTrendStable.
  ///
  /// In fr, this message translates to:
  /// **'→ Stable'**
  String get dashboardTrendStable;

  /// No description provided for @dashboardTrendGrowing.
  ///
  /// In fr, this message translates to:
  /// **'↑ En croissance'**
  String get dashboardTrendGrowing;

  /// No description provided for @dashboardTrendDecreasing.
  ///
  /// In fr, this message translates to:
  /// **'↓ En baisse'**
  String get dashboardTrendDecreasing;

  /// No description provided for @dashboardBestWeekdayNone.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur jour : —'**
  String get dashboardBestWeekdayNone;

  /// No description provided for @dashboardBestWeekday.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur jour : {day}'**
  String dashboardBestWeekday(String day);

  /// No description provided for @dashboardPeakHourNone.
  ///
  /// In fr, this message translates to:
  /// **'Heure de pointe : —'**
  String get dashboardPeakHourNone;

  /// No description provided for @dashboardPeakHour.
  ///
  /// In fr, this message translates to:
  /// **'Heure de pointe : {hour}h'**
  String dashboardPeakHour(int hour);

  /// No description provided for @auditEventUserLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get auditEventUserLogin;

  /// No description provided for @auditEventUserLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get auditEventUserLogout;

  /// No description provided for @auditEventProfileUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour'**
  String get auditEventProfileUpdated;

  /// No description provided for @auditEventRoleChanged.
  ///
  /// In fr, this message translates to:
  /// **'Rôle modifié'**
  String get auditEventRoleChanged;

  /// No description provided for @auditEventSalonUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Salon mis à jour'**
  String get auditEventSalonUpdated;

  /// No description provided for @auditEventSalonStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'Statut du salon modifié'**
  String get auditEventSalonStatusChanged;

  /// No description provided for @auditEventStaffInvited.
  ///
  /// In fr, this message translates to:
  /// **'Invitation envoyée'**
  String get auditEventStaffInvited;

  /// No description provided for @auditEventStaffInvitationAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Invitation acceptée'**
  String get auditEventStaffInvitationAccepted;

  /// No description provided for @auditEventStaffRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Membre retiré'**
  String get auditEventStaffRemoved;

  /// No description provided for @auditEventStaffJoined.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau membre dans l\'équipe'**
  String get auditEventStaffJoined;

  /// No description provided for @auditEventBookingCreated.
  ///
  /// In fr, this message translates to:
  /// **'Réservation créée'**
  String get auditEventBookingCreated;

  /// No description provided for @auditEventBookingConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Réservation confirmée'**
  String get auditEventBookingConfirmed;

  /// No description provided for @auditEventBookingCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Réservation annulée'**
  String get auditEventBookingCancelled;

  /// No description provided for @auditEventBookingCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Réservation terminée'**
  String get auditEventBookingCompleted;

  /// No description provided for @auditEventBookingNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Client absent (no-show)'**
  String get auditEventBookingNoShow;

  /// No description provided for @auditEventPaymentCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Paiement réussi'**
  String get auditEventPaymentCompleted;

  /// No description provided for @auditEventPaymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement échoué'**
  String get auditEventPaymentFailed;

  /// No description provided for @auditEventRefundInitiated.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement initié'**
  String get auditEventRefundInitiated;

  /// No description provided for @auditEventDiscountApplied.
  ///
  /// In fr, this message translates to:
  /// **'Réduction appliquée'**
  String get auditEventDiscountApplied;

  /// No description provided for @auditEventLoyaltyStampAdded.
  ///
  /// In fr, this message translates to:
  /// **'Tampon fidélité ajouté'**
  String get auditEventLoyaltyStampAdded;

  /// No description provided for @auditEventLoyaltyRewardRedeemed.
  ///
  /// In fr, this message translates to:
  /// **'Récompense fidélité validée'**
  String get auditEventLoyaltyRewardRedeemed;

  /// No description provided for @auditEventReferralClaimed.
  ///
  /// In fr, this message translates to:
  /// **'Parrainage utilisé'**
  String get auditEventReferralClaimed;

  /// No description provided for @auditEventPermissionGroupCreated.
  ///
  /// In fr, this message translates to:
  /// **'Groupe de permissions créé'**
  String get auditEventPermissionGroupCreated;

  /// No description provided for @auditEventPermissionGroupDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Groupe de permissions supprimé'**
  String get auditEventPermissionGroupDeleted;

  /// No description provided for @auditEventPermissionGroupPermissionChanged.
  ///
  /// In fr, this message translates to:
  /// **'Permission modifiée'**
  String get auditEventPermissionGroupPermissionChanged;

  /// No description provided for @auditEventPermissionGroupMemberAdded.
  ///
  /// In fr, this message translates to:
  /// **'Membre ajouté à un groupe'**
  String get auditEventPermissionGroupMemberAdded;

  /// No description provided for @auditEventPermissionGroupMemberRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Membre retiré d\'un groupe'**
  String get auditEventPermissionGroupMemberRemoved;

  /// No description provided for @promotionCardUsagesLabel.
  ///
  /// In fr, this message translates to:
  /// **'{uses} utilisation(s)'**
  String promotionCardUsagesLabel(int uses);

  /// No description provided for @promotionCardUsagesMaxLabel.
  ///
  /// In fr, this message translates to:
  /// **'{uses} / {max} utilisation(s)'**
  String promotionCardUsagesMaxLabel(int uses, int max);

  /// No description provided for @promotionCardUntilDate.
  ///
  /// In fr, this message translates to:
  /// **'· jusqu\'au {date}'**
  String promotionCardUntilDate(String date);

  /// No description provided for @contactSourceBooking.
  ///
  /// In fr, this message translates to:
  /// **'RDV'**
  String get contactSourceBooking;

  /// No description provided for @contactSourceReferral.
  ///
  /// In fr, this message translates to:
  /// **'Parrainage'**
  String get contactSourceReferral;

  /// No description provided for @contactSourceManual.
  ///
  /// In fr, this message translates to:
  /// **'Manuel'**
  String get contactSourceManual;

  /// No description provided for @billingPlanNameFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get billingPlanNameFree;

  /// No description provided for @billingPlanNamePro.
  ///
  /// In fr, this message translates to:
  /// **'Pro'**
  String get billingPlanNamePro;

  /// No description provided for @billingPlanNamePremium.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get billingPlanNamePremium;

  /// No description provided for @marketingClientsImportError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'import.'**
  String get marketingClientsImportError;

  /// No description provided for @marketingContactAddError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'ajout.'**
  String get marketingContactAddError;

  /// No description provided for @commissionLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les commissions.'**
  String get commissionLoadError;

  /// No description provided for @commissionEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commission ce mois'**
  String get commissionEmptyTitle;

  /// No description provided for @commissionEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les commissions apparaîtront après les RDV terminés.'**
  String get commissionEmptySubtitle;

  /// No description provided for @commissionMarkAllPaid.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer payé'**
  String get commissionMarkAllPaid;

  /// No description provided for @commissionStaffFallback.
  ///
  /// In fr, this message translates to:
  /// **'Staff'**
  String get commissionStaffFallback;

  /// No description provided for @commissionBadgePaid.
  ///
  /// In fr, this message translates to:
  /// **'PAYÉ'**
  String get commissionBadgePaid;

  /// No description provided for @commissionBadgePending.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE'**
  String get commissionBadgePending;

  /// No description provided for @referralWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur KYNZA ! 🎉'**
  String get referralWelcomeTitle;

  /// No description provided for @referralStampGranted.
  ///
  /// In fr, this message translates to:
  /// **'Un tampon de fidélité vous a été offert !'**
  String get referralStampGranted;

  /// No description provided for @referralStampGrantedWithSalon.
  ///
  /// In fr, this message translates to:
  /// **'Un tampon de fidélité chez {salon} vous a été offert !'**
  String referralStampGrantedWithSalon(String salon);

  /// No description provided for @referralInvalidLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien d\'invitation invalide ou déjà utilisé.'**
  String get referralInvalidLink;

  /// No description provided for @automationLogEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune exécution'**
  String get automationLogEmptyTitle;

  /// No description provided for @automationLogEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les exécutions de workflow apparaîtront ici dès qu\'un déclencheur se produira.'**
  String get automationLogEmptySubtitle;

  /// No description provided for @automationLogLoadDetailError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le détail.'**
  String get automationLogLoadDetailError;

  /// No description provided for @automationLogLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'historique.'**
  String get automationLogLoadError;

  /// No description provided for @automationLogHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique d\'exécution'**
  String get automationLogHistoryTitle;

  /// No description provided for @dataPlatformDocumentTemplatesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modèles de documents'**
  String get dataPlatformDocumentTemplatesTitle;

  /// No description provided for @dataPlatformTemplateTypeInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Facture'**
  String get dataPlatformTemplateTypeInvoice;

  /// No description provided for @dataPlatformTemplateTypeReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get dataPlatformTemplateTypeReceipt;

  /// No description provided for @dataPlatformTemplateTypeMonthlyReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport mensuel'**
  String get dataPlatformTemplateTypeMonthlyReport;

  /// No description provided for @dataPlatformTemplateLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les modèles.'**
  String get dataPlatformTemplateLoadError;

  /// No description provided for @dataPlatformTemplateEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle'**
  String get dataPlatformTemplateEmptyTitle;

  /// No description provided for @dataPlatformTemplateEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez des modèles personnalisés pour vos factures, reçus et rapports.'**
  String get dataPlatformTemplateEmptySubtitle;

  /// No description provided for @dataPlatformTemplateCreateCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer un modèle'**
  String get dataPlatformTemplateCreateCta;

  /// No description provided for @dataPlatformTemplateDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le modèle'**
  String get dataPlatformTemplateDeleteTitle;

  /// No description provided for @dataPlatformTemplateDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ?'**
  String dataPlatformTemplateDeleteConfirm(String name);

  /// No description provided for @dataPlatformTemplateDeleteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Modèle supprimé.'**
  String get dataPlatformTemplateDeleteSuccess;

  /// No description provided for @dataPlatformTemplateDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer ce modèle.'**
  String get dataPlatformTemplateDeleteError;

  /// No description provided for @dataPlatformTemplateBadgeDefault.
  ///
  /// In fr, this message translates to:
  /// **'DÉFAUT'**
  String get dataPlatformTemplateBadgeDefault;

  /// No description provided for @dataPlatformTemplateValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Le nom et le contenu sont requis.'**
  String get dataPlatformTemplateValidationError;

  /// No description provided for @dataPlatformTemplateEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le modèle'**
  String get dataPlatformTemplateEditTitle;

  /// No description provided for @dataPlatformTemplateNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau modèle'**
  String get dataPlatformTemplateNewTitle;

  /// No description provided for @dataPlatformTemplateNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du modèle'**
  String get dataPlatformTemplateNameLabel;

  /// No description provided for @dataPlatformTemplateTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get dataPlatformTemplateTypeLabel;

  /// No description provided for @dataPlatformTemplateVariablesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Variables disponibles'**
  String get dataPlatformTemplateVariablesTitle;

  /// No description provided for @dataPlatformTemplateBodyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Contenu du modèle'**
  String get dataPlatformTemplateBodyLabel;

  /// No description provided for @dataPlatformTemplateBodyHint.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez le format variable pour insérer des données dynamiques.'**
  String get dataPlatformTemplateBodyHint;

  /// No description provided for @dataPlatformTemplateIsDefaultLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle par défaut'**
  String get dataPlatformTemplateIsDefaultLabel;

  /// No description provided for @dataPlatformTemplateSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get dataPlatformTemplateSaveButton;

  /// No description provided for @dataPlatformTemplateCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer le modèle'**
  String get dataPlatformTemplateCreateButton;

  /// No description provided for @dataPlatformBackupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardes de données'**
  String get dataPlatformBackupTitle;

  /// No description provided for @dataPlatformBackupLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les sauvegardes.'**
  String get dataPlatformBackupLoadError;

  /// No description provided for @dataPlatformBackupEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde'**
  String get dataPlatformBackupEmptyTitle;

  /// No description provided for @dataPlatformBackupEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre première sauvegarde pour archiver vos données.'**
  String get dataPlatformBackupEmptySubtitle;

  /// No description provided for @dataPlatformBackupCreateCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer une sauvegarde'**
  String get dataPlatformBackupCreateCta;

  /// No description provided for @dataPlatformBackupDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une sauvegarde'**
  String get dataPlatformBackupDialogTitle;

  /// No description provided for @dataPlatformBackupDialogContent.
  ///
  /// In fr, this message translates to:
  /// **'Les données des 90 derniers jours (réservations, clients, prestations, personnel, avis, factures) seront exportées et stockées de manière sécurisée.'**
  String get dataPlatformBackupDialogContent;

  /// No description provided for @dataPlatformBackupCreateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde créée avec succès.'**
  String get dataPlatformBackupCreateSuccess;

  /// No description provided for @dataPlatformBackupSecureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde sécurisée'**
  String get dataPlatformBackupSecureTitle;

  /// No description provided for @dataPlatformBackupSecureSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Exportez vos données dans un fichier JSON chiffré stocké sur nos serveurs. Une sauvegarde maximum toutes les 6 heures.'**
  String get dataPlatformBackupSecureSubtitle;

  /// No description provided for @dataPlatformBackupCreateButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer une sauvegarde'**
  String get dataPlatformBackupCreateButton;

  /// No description provided for @settingFieldBookingAdvanceDays.
  ///
  /// In fr, this message translates to:
  /// **'Délai de réservation max (jours)'**
  String get settingFieldBookingAdvanceDays;

  /// No description provided for @settingFieldBookingSlotDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée des créneaux (minutes)'**
  String get settingFieldBookingSlotDuration;

  /// No description provided for @settingFieldBookingCancellationHours.
  ///
  /// In fr, this message translates to:
  /// **'Délai d\'annulation (heures)'**
  String get settingFieldBookingCancellationHours;

  /// No description provided for @settingFieldBookingRequiresConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation requise'**
  String get settingFieldBookingRequiresConfirmation;

  /// No description provided for @settingFieldBookingAllowWalkin.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les walk-ins'**
  String get settingFieldBookingAllowWalkin;

  /// No description provided for @settingFieldBookingMaxPerClientPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Max RDV par client / jour'**
  String get settingFieldBookingMaxPerClientPerDay;

  /// No description provided for @settingFieldNotifSmsEnabled.
  ///
  /// In fr, this message translates to:
  /// **'SMS activés'**
  String get settingFieldNotifSmsEnabled;

  /// No description provided for @settingFieldNotifWhatsappEnabled.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp activé'**
  String get settingFieldNotifWhatsappEnabled;

  /// No description provided for @settingFieldNotifPushEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push activées'**
  String get settingFieldNotifPushEnabled;

  /// No description provided for @settingFieldNotifReminderHoursBefore.
  ///
  /// In fr, this message translates to:
  /// **'Premier rappel avant RDV (heures)'**
  String get settingFieldNotifReminderHoursBefore;

  /// No description provided for @settingFieldNotifReminderHoursBefore2.
  ///
  /// In fr, this message translates to:
  /// **'Second rappel avant RDV (heures)'**
  String get settingFieldNotifReminderHoursBefore2;

  /// No description provided for @settingFieldMarketingAutoReviewRequest.
  ///
  /// In fr, this message translates to:
  /// **'Demande d\'avis automatique'**
  String get settingFieldMarketingAutoReviewRequest;

  /// No description provided for @settingFieldMarketingReviewRequestHoursAfter.
  ///
  /// In fr, this message translates to:
  /// **'Demande d\'avis après le RDV (heures)'**
  String get settingFieldMarketingReviewRequestHoursAfter;

  /// No description provided for @settingFieldMarketingLoyaltyAutoStamp.
  ///
  /// In fr, this message translates to:
  /// **'Tampon fidélité automatique'**
  String get settingFieldMarketingLoyaltyAutoStamp;

  /// No description provided for @settingFieldMarketingReferralBonusBif.
  ///
  /// In fr, this message translates to:
  /// **'Bonus de parrainage (FBu)'**
  String get settingFieldMarketingReferralBonusBif;

  /// No description provided for @settingFieldStaffShowEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les revenus au staff'**
  String get settingFieldStaffShowEarnings;

  /// No description provided for @settingFieldStaffCommissionAutoCalculate.
  ///
  /// In fr, this message translates to:
  /// **'Calcul automatique des commissions'**
  String get settingFieldStaffCommissionAutoCalculate;

  /// No description provided for @settingFieldStaffRequireCheckin.
  ///
  /// In fr, this message translates to:
  /// **'Check-in requis'**
  String get settingFieldStaffRequireCheckin;

  /// No description provided for @settingFieldLoyaltyStampsPerCard.
  ///
  /// In fr, this message translates to:
  /// **'Tampons par carte'**
  String get settingFieldLoyaltyStampsPerCard;

  /// No description provided for @settingFieldLoyaltyRewardDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description de la récompense'**
  String get settingFieldLoyaltyRewardDescription;

  /// No description provided for @settingFieldLoyaltyExpiryDays.
  ///
  /// In fr, this message translates to:
  /// **'Expiration (jours)'**
  String get settingFieldLoyaltyExpiryDays;

  /// No description provided for @settingFieldReviewsAutoPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publication automatique'**
  String get settingFieldReviewsAutoPublish;

  /// No description provided for @settingFieldReviewsModerationEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Modération activée'**
  String get settingFieldReviewsModerationEnabled;

  /// No description provided for @settingFieldReviewsMinRatingAlert.
  ///
  /// In fr, this message translates to:
  /// **'Alerte si note ≤'**
  String get settingFieldReviewsMinRatingAlert;

  /// No description provided for @settingFieldPaymentGracePeriodMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Délai de grâce (minutes)'**
  String get settingFieldPaymentGracePeriodMinutes;

  /// No description provided for @settingFieldPaymentAutoInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Facturation automatique'**
  String get settingFieldPaymentAutoInvoice;

  /// No description provided for @settingFieldTimezone.
  ///
  /// In fr, this message translates to:
  /// **'Fuseau horaire'**
  String get settingFieldTimezone;

  /// No description provided for @settingFieldAdvancedDoubleBooking.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser le double-booking'**
  String get settingFieldAdvancedDoubleBooking;

  /// No description provided for @settingFieldAdvancedOverbookingLimit.
  ///
  /// In fr, this message translates to:
  /// **'Limite de surbooking'**
  String get settingFieldAdvancedOverbookingLimit;

  /// No description provided for @staffRoleManager.
  ///
  /// In fr, this message translates to:
  /// **'Manager'**
  String get staffRoleManager;

  /// No description provided for @staffRoleStaff.
  ///
  /// In fr, this message translates to:
  /// **'Staff'**
  String get staffRoleStaff;

  /// No description provided for @commonRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get commonRefresh;

  /// No description provided for @commonMonthJanuary.
  ///
  /// In fr, this message translates to:
  /// **'Janvier'**
  String get commonMonthJanuary;

  /// No description provided for @commonMonthFebruary.
  ///
  /// In fr, this message translates to:
  /// **'Février'**
  String get commonMonthFebruary;

  /// No description provided for @commonMonthMarch.
  ///
  /// In fr, this message translates to:
  /// **'Mars'**
  String get commonMonthMarch;

  /// No description provided for @commonMonthApril.
  ///
  /// In fr, this message translates to:
  /// **'Avril'**
  String get commonMonthApril;

  /// No description provided for @commonMonthMay.
  ///
  /// In fr, this message translates to:
  /// **'Mai'**
  String get commonMonthMay;

  /// No description provided for @commonMonthJune.
  ///
  /// In fr, this message translates to:
  /// **'Juin'**
  String get commonMonthJune;

  /// No description provided for @commonMonthJuly.
  ///
  /// In fr, this message translates to:
  /// **'Juillet'**
  String get commonMonthJuly;

  /// No description provided for @commonMonthAugust.
  ///
  /// In fr, this message translates to:
  /// **'Août'**
  String get commonMonthAugust;

  /// No description provided for @commonMonthSeptember.
  ///
  /// In fr, this message translates to:
  /// **'Septembre'**
  String get commonMonthSeptember;

  /// No description provided for @commonMonthOctober.
  ///
  /// In fr, this message translates to:
  /// **'Octobre'**
  String get commonMonthOctober;

  /// No description provided for @commonMonthNovember.
  ///
  /// In fr, this message translates to:
  /// **'Novembre'**
  String get commonMonthNovember;

  /// No description provided for @commonMonthDecember.
  ///
  /// In fr, this message translates to:
  /// **'Décembre'**
  String get commonMonthDecember;

  /// No description provided for @homeClientCannotLoadSalons.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les salons.'**
  String get homeClientCannotLoadSalons;

  /// No description provided for @homeClientDiscoverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez les salons'**
  String get homeClientDiscoverTitle;

  /// No description provided for @homeClientNoSalonsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun salon disponible pour le moment.'**
  String get homeClientNoSalonsSubtitle;

  /// No description provided for @homeClientSalonsNearYou.
  ///
  /// In fr, this message translates to:
  /// **'Salons près de vous'**
  String get homeClientSalonsNearYou;

  /// No description provided for @homeClientBookNextBeautyAppt.
  ///
  /// In fr, this message translates to:
  /// **'Réservez votre prochain rendez-vous beauté.'**
  String get homeClientBookNextBeautyAppt;

  /// No description provided for @homeStaffProfileNotLinked.
  ///
  /// In fr, this message translates to:
  /// **'Profil non lié'**
  String get homeStaffProfileNotLinked;

  /// No description provided for @homeStaffProfileNotLinkedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte n\'est pas encore associé à une équipe. Demandez une invitation à votre Owner.'**
  String get homeStaffProfileNotLinkedSubtitle;

  /// No description provided for @homeStaffNoApptTodayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun RDV aujourd\'hui'**
  String get homeStaffNoApptTodayTitle;

  /// No description provided for @homeStaffFreeDay.
  ///
  /// In fr, this message translates to:
  /// **'Profitez de votre journée libre !'**
  String get homeStaffFreeDay;

  /// No description provided for @homeStaffLaterToday.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard aujourd\'hui'**
  String get homeStaffLaterToday;

  /// No description provided for @homeStaffNothingScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu pour cette date.'**
  String get homeStaffNothingScheduled;

  /// No description provided for @homeStaffNextAppointment.
  ///
  /// In fr, this message translates to:
  /// **'Prochain rendez-vous'**
  String get homeStaffNextAppointment;

  /// No description provided for @homeManagerDashboardBody.
  ///
  /// In fr, this message translates to:
  /// **'Phase 2 — Booking Engine arrive ici'**
  String get homeManagerDashboardBody;

  /// No description provided for @homeManagerDashboardCta.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu des fonctionnalités →'**
  String get homeManagerDashboardCta;

  /// No description provided for @bookingLeaveReview.
  ///
  /// In fr, this message translates to:
  /// **'Laisser un avis'**
  String get bookingLeaveReview;

  /// No description provided for @bookingReceiptTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get bookingReceiptTitle;

  /// No description provided for @bookingReceiptSalon.
  ///
  /// In fr, this message translates to:
  /// **'Salon'**
  String get bookingReceiptSalon;

  /// No description provided for @bookingReceiptService.
  ///
  /// In fr, this message translates to:
  /// **'Service'**
  String get bookingReceiptService;

  /// No description provided for @bookingReceiptDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get bookingReceiptDate;

  /// No description provided for @bookingReceiptTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get bookingReceiptTime;

  /// No description provided for @bookingLastSlot.
  ///
  /// In fr, this message translates to:
  /// **'Dernière place !'**
  String get bookingLastSlot;

  /// No description provided for @bookingTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get bookingTotal;

  /// No description provided for @bookingDetailCompleteAndCollect.
  ///
  /// In fr, this message translates to:
  /// **'Terminer + encaisser'**
  String get bookingDetailCompleteAndCollect;

  /// No description provided for @bookingDetailMarkAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Marquer absent'**
  String get bookingDetailMarkAbsent;

  /// No description provided for @bookingDetailMarkAbsentGrace.
  ///
  /// In fr, this message translates to:
  /// **'Marquer absent (dès +15 min)'**
  String get bookingDetailMarkAbsentGrace;

  /// No description provided for @bookingDetailCancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce RDV'**
  String get bookingDetailCancelButton;

  /// No description provided for @dataPlatformBackupRecordsExported.
  ///
  /// In fr, this message translates to:
  /// **'{count} enregistrements'**
  String dataPlatformBackupRecordsExported(int count);

  /// No description provided for @commonOrdinalSuffixFirst.
  ///
  /// In fr, this message translates to:
  /// **'er'**
  String get commonOrdinalSuffixFirst;

  /// No description provided for @commonOrdinalSuffixOther.
  ///
  /// In fr, this message translates to:
  /// **'ème'**
  String get commonOrdinalSuffixOther;

  /// No description provided for @paymentRadarWaitMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande est envoyée. Attendez le message sur votre téléphone.'**
  String get paymentRadarWaitMessage;

  /// No description provided for @legalCenterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre légal'**
  String get legalCenterTitle;

  /// No description provided for @legalCenterLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les documents légaux.'**
  String get legalCenterLoadError;

  /// No description provided for @legalCenterEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document disponible'**
  String get legalCenterEmptyTitle;

  /// No description provided for @legalCenterEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Revenez plus tard, nos documents légaux sont en cours de publication.'**
  String get legalCenterEmptySubtitle;

  /// No description provided for @legalDocTypePrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get legalDocTypePrivacyPolicy;

  /// No description provided for @legalDocTypeTermsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get legalDocTypeTermsOfService;

  /// No description provided for @legalDocTypeCookiePolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de cookies'**
  String get legalDocTypeCookiePolicy;

  /// No description provided for @legalDocTypeAcceptableUsePolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique d\'utilisation acceptable'**
  String get legalDocTypeAcceptableUsePolicy;

  /// No description provided for @legalDocTypeRefundPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de remboursement'**
  String get legalDocTypeRefundPolicy;

  /// No description provided for @legalDocTypeCommunityGuidelines.
  ///
  /// In fr, this message translates to:
  /// **'Règles de la communauté'**
  String get legalDocTypeCommunityGuidelines;

  /// No description provided for @legalDocTypeDataDeletionPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de suppression des données'**
  String get legalDocTypeDataDeletionPolicy;

  /// No description provided for @legalDocTypeSupportPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique d\'assistance'**
  String get legalDocTypeSupportPolicy;

  /// No description provided for @legalDocTypeLegalNotices.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales'**
  String get legalDocTypeLegalNotices;

  /// No description provided for @policyViewerLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce document.'**
  String get policyViewerLoadError;

  /// No description provided for @policyViewerHistoryLink.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'historique des versions'**
  String get policyViewerHistoryLink;

  /// No description provided for @policyViewerAcceptButton.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte'**
  String get policyViewerAcceptButton;

  /// No description provided for @policyViewerAcceptedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Déjà accepté'**
  String get policyViewerAcceptedLabel;

  /// No description provided for @policyViewerAcceptedOfflineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Acceptation enregistrée hors ligne — sera synchronisée'**
  String get policyViewerAcceptedOfflineLabel;

  /// No description provided for @policyVersionHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique des versions'**
  String get policyVersionHistoryTitle;

  /// No description provided for @policyVersionHistoryLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'historique.'**
  String get policyVersionHistoryLoadError;

  /// No description provided for @policyVersionHistoryEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune version publiée'**
  String get policyVersionHistoryEmptyTitle;

  /// No description provided for @policyVersionHistoryEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce document n\'a pas encore de version publiée.'**
  String get policyVersionHistoryEmptySubtitle;

  /// No description provided for @policyVersionHistoryCurrentBadge.
  ///
  /// In fr, this message translates to:
  /// **'Version actuelle'**
  String get policyVersionHistoryCurrentBadge;

  /// No description provided for @acceptanceHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes acceptations'**
  String get acceptanceHistoryTitle;

  /// No description provided for @acceptanceHistoryLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre historique d\'acceptation.'**
  String get acceptanceHistoryLoadError;

  /// No description provided for @acceptanceHistoryEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune acceptation enregistrée'**
  String get acceptanceHistoryEmptyTitle;

  /// No description provided for @acceptanceHistoryEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les documents que vous acceptez apparaîtront ici.'**
  String get acceptanceHistoryEmptySubtitle;

  /// No description provided for @consentManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion du consentement'**
  String get consentManagementTitle;

  /// No description provided for @consentManagementLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos préférences de consentement.'**
  String get consentManagementLoadError;

  /// No description provided for @consentTypeMarketingEmailsLabel.
  ///
  /// In fr, this message translates to:
  /// **'E-mails marketing'**
  String get consentTypeMarketingEmailsLabel;

  /// No description provided for @consentTypeMarketingEmailsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevez nos offres et actualités par e-mail.'**
  String get consentTypeMarketingEmailsSubtitle;

  /// No description provided for @consentTypeAnalyticsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Analyse d\'utilisation'**
  String get consentTypeAnalyticsLabel;

  /// No description provided for @consentTypeAnalyticsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Nous aider à améliorer KYNZA en partageant des données d\'usage anonymisées.'**
  String get consentTypeAnalyticsSubtitle;

  /// No description provided for @consentTypePushNotificationsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get consentTypePushNotificationsLabel;

  /// No description provided for @consentTypePushNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevez des rappels et alertes sur votre appareil.'**
  String get consentTypePushNotificationsSubtitle;

  /// No description provided for @consentTypeDataProcessingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Traitement des données personnelles'**
  String get consentTypeDataProcessingLabel;

  /// No description provided for @consentTypeDataProcessingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser le traitement de vos données pour le fonctionnement du service.'**
  String get consentTypeDataProcessingSubtitle;

  /// No description provided for @dataRightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes données'**
  String get dataRightsTitle;

  /// No description provided for @dataRightsExportSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes données'**
  String get dataRightsExportSectionTitle;

  /// No description provided for @dataRightsExportDescription.
  ///
  /// In fr, this message translates to:
  /// **'Recevez une copie de vos données personnelles KYNZA.'**
  String get dataRightsExportDescription;

  /// No description provided for @dataRightsExportButton.
  ///
  /// In fr, this message translates to:
  /// **'Demander un export'**
  String get dataRightsExportButton;

  /// No description provided for @dataRightsDeletionSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get dataRightsDeletionSectionTitle;

  /// No description provided for @dataRightsDeletionDescription.
  ///
  /// In fr, this message translates to:
  /// **'Demandez la suppression définitive de votre compte et de vos données.'**
  String get dataRightsDeletionDescription;

  /// No description provided for @dataRightsDeletionButton.
  ///
  /// In fr, this message translates to:
  /// **'Demander la suppression'**
  String get dataRightsDeletionButton;

  /// No description provided for @dataRightsDeletionConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la demande'**
  String get dataRightsDeletionConfirmTitle;

  /// No description provided for @dataRightsDeletionConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action déclenche une demande de suppression de votre compte, traitée par notre équipe. Voulez-vous continuer ?'**
  String get dataRightsDeletionConfirmMessage;

  /// No description provided for @dataRightsRequestSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande a été envoyée.'**
  String get dataRightsRequestSubmitted;

  /// No description provided for @dataRightsRequestsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos demandes.'**
  String get dataRightsRequestsLoadError;

  /// No description provided for @dataRightsRequestsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en cours'**
  String get dataRightsRequestsEmptyTitle;

  /// No description provided for @dataRightsRequestsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos demandes de suppression de données apparaîtront ici.'**
  String get dataRightsRequestsEmptySubtitle;

  /// No description provided for @dataRightsRequestStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get dataRightsRequestStatusPending;

  /// No description provided for @dataRightsRequestStatusInReview.
  ///
  /// In fr, this message translates to:
  /// **'En cours d\'examen'**
  String get dataRightsRequestStatusInReview;

  /// No description provided for @dataRightsRequestStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get dataRightsRequestStatusCompleted;

  /// No description provided for @dataRightsRequestStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get dataRightsRequestStatusRejected;

  /// No description provided for @supportContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get supportContactTitle;

  /// No description provided for @supportContactDescription.
  ///
  /// In fr, this message translates to:
  /// **'Une question ou un problème ? Notre équipe vous répond.'**
  String get supportContactDescription;

  /// No description provided for @supportContactEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get supportContactEmailLabel;

  /// No description provided for @supportContactPolicyLink.
  ///
  /// In fr, this message translates to:
  /// **'Consulter la politique d\'assistance'**
  String get supportContactPolicyLink;

  /// No description provided for @policyUpdateBannerMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un document légal a été mis à jour. Veuillez le consulter.'**
  String get policyUpdateBannerMessage;

  /// No description provided for @policyUpdateBannerCta.
  ///
  /// In fr, this message translates to:
  /// **'Consulter'**
  String get policyUpdateBannerCta;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
