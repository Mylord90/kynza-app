// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'KYNZA';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonShare => 'Partager';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonSeeAll => 'Voir tout';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonPrevious => 'Précédent';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonSearch => 'Rechercher';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonCreate => 'Créer';

  @override
  String get commonSend => 'Envoyer';

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get commonOk => 'OK';

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonError => 'Erreur';

  @override
  String get commonSelect => 'Sélectionner';

  @override
  String get commonEnable => 'Activer';

  @override
  String get commonDisable => 'Désactiver';

  @override
  String get commonReset => 'Réinitialiser';

  @override
  String get commonExport => 'Exporter';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonCopied => 'Copié !';

  @override
  String get commonLoadMore => 'Charger plus';

  @override
  String get errorGeneric => 'Une erreur est survenue.';

  @override
  String get errorOffline => 'Vous êtes hors ligne.';

  @override
  String get errorNetwork => 'Vérifiez votre connexion internet.';

  @override
  String get errorUnauthorized => 'Session expirée, veuillez vous reconnecter.';

  @override
  String get errorLoadFailed => 'Impossible de charger les données.';

  @override
  String get emptyStateDefaultTitle => 'Rien à afficher';

  @override
  String get offlineBannerMessage => '📴 Hors connexion • Données en cache';

  @override
  String get offlineBannerSynced => '✓ Synchronisé';

  @override
  String get navHome => 'Accueil';

  @override
  String get navCalendar => 'Calendrier';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navClients => 'Clients';

  @override
  String get navMarketing => 'Marketing';

  @override
  String get navProfile => 'Profil';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navExplorer => 'Explorer';

  @override
  String get navMyBookings => 'Mes RDV';

  @override
  String get navLoyalty => 'Fidélité';

  @override
  String get navToday => 'Aujourd\'hui';

  @override
  String get navPerformance => 'Performances';

  @override
  String get navTeam => 'Équipe';

  @override
  String get authLogin => 'Se connecter';

  @override
  String get authLogout => 'Se déconnecter';

  @override
  String get authRegister => 'Créer un compte';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authLoginTitle => 'Bon retour';

  @override
  String get authLoginSubtitle => 'Connectez-vous pour continuer';

  @override
  String get authLoginEmailLabel => 'Email';

  @override
  String get authLoginPasswordLabel => 'Mot de passe';

  @override
  String get authLoginSubmitButton => 'Se connecter →';

  @override
  String get authLoginForgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get authLoginNoAccountLink => 'Pas encore de compte ? S\'inscrire';

  @override
  String get authRegisterTitle => 'Créer un compte';

  @override
  String get authRegisterSubtitle => 'Rejoignez KYNZA en quelques secondes';

  @override
  String get authRegisterFullNameLabel => 'Nom complet';

  @override
  String get authRegisterEmailLabel => 'Email';

  @override
  String get authRegisterConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get authRegisterSubmitButton => 'Créer mon compte →';

  @override
  String get authRegisterAlreadyHaveAccountLink =>
      'Déjà un compte ? Se connecter';

  @override
  String get authForgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get authForgotPasswordSubtitle =>
      'Recevez un lien de réinitialisation par email';

  @override
  String get authForgotPasswordEmailLabel => 'Email';

  @override
  String get authForgotPasswordSubmitButton => 'Envoyer le lien →';

  @override
  String get authForgotPasswordBackLink => '← Retour à la connexion';

  @override
  String get authForgotPasswordSuccessTitle => 'Email envoyé !';

  @override
  String authForgotPasswordSuccessSubtitle(String email) {
    return 'Si un compte existe pour $email, vous recevrez un lien de réinitialisation dans quelques instants.';
  }

  @override
  String get authForgotPasswordCheckSpam => 'Vérifiez vos spams.';

  @override
  String get authVerifyEmailTitle => 'Vérifiez votre email';

  @override
  String authVerifyEmailSubtitle(String email) {
    return 'Un lien de confirmation a été envoyé à $email';
  }

  @override
  String get authVerifyEmailCheckSpam => 'Vérifiez vos spams.';

  @override
  String get authVerifyEmailResendButton => 'Renvoyer l\'email';

  @override
  String authVerifyEmailResendCooldown(String seconds) {
    return 'Renvoyer l\'email (00:$seconds)';
  }

  @override
  String get authVerifyEmailChangeAddress => 'Utiliser une autre adresse';

  @override
  String get authResetPasswordTitle => 'Réinitialiser';

  @override
  String get authResetPasswordNewLabel => 'Nouveau mot de passe';

  @override
  String get authResetPasswordConfirmLabel => 'Confirmer le mot de passe';

  @override
  String get authResetPasswordSubmitButton => 'Réinitialiser →';

  @override
  String get authResetPasswordSuccess => 'Mot de passe réinitialisé.';

  @override
  String get authResetPasswordInvalidLink => 'Lien invalide ou expiré.';

  @override
  String get authCompleteProfileTitle => 'Finalisez votre profil';

  @override
  String get authCompleteProfileSubtitle =>
      'Quelques informations pour démarrer';

  @override
  String get authCompleteProfileFullNameLabel => 'Nom complet';

  @override
  String get authCompleteProfileSubmitButton => 'Commencer →';

  @override
  String get authCompleteProfileRoleClientLabel => 'Client';

  @override
  String get authCompleteProfileRoleClientSubtitle => 'Réservez des soins';

  @override
  String get authCompleteProfileRoleStaffLabel => 'Staff';

  @override
  String get authCompleteProfileRoleStaffSubtitle => 'Praticien dans un salon';

  @override
  String get authCompleteProfileRoleOwnerLabel => 'Propriétaire';

  @override
  String get authCompleteProfileRoleOwnerSubtitle => 'Gérez votre salon';

  @override
  String get authOauthComingSoon => 'Disponible bientôt';

  @override
  String get authOauthGoogleLabel => 'Continuer avec Google';

  @override
  String get authOauthFacebookLabel => 'Continuer avec Facebook';

  @override
  String get authOauthAppleLabel => 'Continuer avec Apple';

  @override
  String get authDividerLabel => 'ou continuer avec';

  @override
  String get validatorEmailRequired => 'Email requis.';

  @override
  String get validatorEmailInvalid => 'Email invalide.';

  @override
  String get validatorPasswordRequired => 'Mot de passe requis.';

  @override
  String get validatorPasswordMinLength => '8 caractères minimum.';

  @override
  String get validatorPasswordNeedUppercase => '1 majuscule minimum.';

  @override
  String get validatorPasswordNeedDigit => '1 chiffre minimum.';

  @override
  String get validatorPhoneRequired => 'Numéro requis.';

  @override
  String get validatorPhoneInvalid => 'Numéro invalide (8 chiffres).';

  @override
  String validatorFieldRequired(String field) {
    return '$field requis.';
  }

  @override
  String get validatorConfirmPasswordRequired => 'Confirmation requise.';

  @override
  String get validatorPasswordMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get fieldPhoneLabel => 'Numéro de téléphone';

  @override
  String get fieldPhoneHelper => 'Pour les notifications WhatsApp uniquement.';

  @override
  String get fieldPasswordLabel => 'Mot de passe';

  @override
  String get homeOwnerDashboardTitle => 'Dashboard KYNZA';

  @override
  String get homeOwnerScanLoyaltyTooltip => 'Scanner fidélité';

  @override
  String get homeOwnerConfidentialModeTooltip =>
      'Masquer/afficher les montants';

  @override
  String get homeOwnerShareTooltip => 'Partager mon salon';

  @override
  String get homeOwnerNoSalonTitle => 'Créez votre salon';

  @override
  String get homeOwnerNoSalonSubtitle =>
      'Configurez votre salon pour commencer à recevoir des réservations.';

  @override
  String get homeOwnerNoSalonCta => 'Créer mon salon →';

  @override
  String get homeOwnerCalendarError => 'Impossible de charger le planning.';

  @override
  String get homeOwnerCalendarEmptyTitle => 'Aucun RDV ce jour';

  @override
  String get homeOwnerCalendarEmptySubtitle => 'Votre planning est libre.';

  @override
  String get homeOwnerCalendarEmptyCta => 'Aujourd\'hui';

  @override
  String get homeOwnerClientsError => 'Impossible de charger vos clients.';

  @override
  String get homeOwnerClientsEmptyTitle => 'Aucun client encore';

  @override
  String get homeOwnerClientsEmptySubtitle =>
      'Vos clients apparaîtront ici après leur première réservation.';

  @override
  String get homeOwnerClientFallbackName => 'Client';

  @override
  String homeOwnerClientRdvCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count RDV',
      one: '1 RDV',
      zero: 'Aucun RDV',
    );
    return '$_temp0';
  }

  @override
  String get homeOwnerProfileMyReviews => 'Mes Avis';

  @override
  String get homeOwnerProfileActivityLog => 'Journal d\'activité';

  @override
  String get homeOwnerProfileSettings => 'Paramètres';

  @override
  String get homeOwnerProfileSubscription => 'Abonnement & Facturation';

  @override
  String get homeOwnerProfileLanguage => 'Langue';

  @override
  String get homeOwnerBookingCancelConfirmTitle => 'Annuler ce RDV ?';

  @override
  String get homeOwnerBookingCancelConfirmMessage =>
      'Le client sera notifié et remboursé si applicable.';

  @override
  String get homeOwnerBookingCancelConfirmButton => 'Annuler';

  @override
  String get homeManagerDashboardTitle => 'Dashboard Manager';

  @override
  String get homeStaffScanLoyaltyTooltip => 'Scanner fidélité';

  @override
  String get homeStaffAvailabilityTooltip => 'Mes disponibilités';

  @override
  String get homeStaffConfirmArrivalButton => 'Confirmer arrivée';

  @override
  String homeClientGreeting(String firstName) {
    return 'Bonjour $firstName 👋';
  }

  @override
  String get homeClientNavExplorer => 'Explorer';

  @override
  String get homeClientNavMyBookings => 'Mes RDV';

  @override
  String get homeClientNavMyLoyalties => 'Mes Fidélités';

  @override
  String get homeClientProfileSeeAllBookings => 'Voir tous mes RDV →';

  @override
  String get homeClientProfileSeeAllPrograms => 'Voir mes programmes →';

  @override
  String get homeClientProfileSeeAllReviews => 'Voir mes avis →';

  @override
  String get homeClientProfilePhoneLabel => 'Téléphone';

  @override
  String get homeClientProfileInviteFriend => 'Invitez un ami';

  @override
  String get homeClientProfileLogoutTitle => 'Déconnexion';

  @override
  String get homeClientProfileLogoutMessage => 'Êtes-vous sûr ?';

  @override
  String get homeClientProfileLogoutButton => 'Se déconnecter';

  @override
  String get homeClientProfileUpdateError =>
      'Impossible de mettre à jour votre profil.';

  @override
  String get homeClientProfileAvatarUploadError =>
      'Échec de l\'envoi de la photo.';

  @override
  String get homeClientProfileInfoTitle => 'Mes informations';

  @override
  String get homeClientProfileNoPhone => 'Aucun numéro';

  @override
  String get homeClientProfileNoEmail => 'Aucun email';

  @override
  String get homeClientProfileRecentBookingsTitle => 'Mes RDV récents';

  @override
  String get homeClientProfileNoBookings => 'Aucun RDV pour le moment.';

  @override
  String get homeClientProfileLoyaltiesTitle => 'Mes fidélités';

  @override
  String get homeClientProfileNoLoyalty =>
      'Réservez un RDV pour démarrer une carte de fidélité.';

  @override
  String get homeClientProfileReviewsTitle => 'Mes avis';

  @override
  String homeClientProfileReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'J\'ai laissé $count avis.',
      one: 'J\'ai laissé 1 avis.',
      zero: 'Aucun avis',
    );
    return '$_temp0';
  }

  @override
  String get homeClientProfileReviewsLoadError =>
      'Impossible de charger vos avis.';

  @override
  String get homeClientProfileNoReviews =>
      'Vous n\'avez pas encore laissé d\'avis.';

  @override
  String get homeClientProfileEditTitle => 'Modifier mes informations';

  @override
  String get bookingSelectServiceTitle => 'Choisir un service';

  @override
  String get bookingSelectServiceEmptyTitle => 'Aucun service disponible';

  @override
  String get bookingSelectServiceEmptySubtitle =>
      'Ce salon n\'a pas encore publié de service.';

  @override
  String get bookingNoSalonSelected => 'Aucun salon sélectionné.';

  @override
  String get bookingSelectPractitionerTitle => 'Choisir un praticien';

  @override
  String get bookingPractitionerLoadError => 'Impossible de charger l\'équipe.';

  @override
  String get bookingSelectDateTitle => 'Choisir une date';

  @override
  String get bookingSelectTimeTitle => 'Choisir un horaire';

  @override
  String get bookingTimeLoadError => 'Impossible de charger les créneaux.';

  @override
  String get bookingSelectTimeEmptyTitle => 'Aucun créneau disponible';

  @override
  String get bookingSelectTimeEmptySubtitle => 'Essayez une autre date.';

  @override
  String get bookingSelectTimeEmptyCtaLabel => 'Choisir une autre date';

  @override
  String get bookingSummaryTitle => 'Récapitulatif';

  @override
  String get bookingSummaryNotesLabel => 'Note pour le salon (optionnel)';

  @override
  String get bookingSummaryPaymentLockWarning =>
      'Votre créneau est verrouillé 5 minutes pendant le paiement. Aucun montant ne sera prélevé avant la validation finale.';

  @override
  String get bookingSummarySubmitButton => 'Confirmer et payer →';

  @override
  String get bookingConfirmationTitle => '✅ Payé ! Votre place est réservée.';

  @override
  String get bookingAddToCalendar => 'Ajouter au calendrier';

  @override
  String get bookingReturnHome => 'Retour à l\'accueil';

  @override
  String get bookingStatusPending => 'En attente';

  @override
  String get bookingStatusConfirmed => 'Confirmé';

  @override
  String get bookingStatusInProgress => 'En cours';

  @override
  String get bookingStatusCompleted => 'Terminé';

  @override
  String get bookingStatusCancelled => 'Annulé';

  @override
  String get bookingStatusNoShow => 'Absent';

  @override
  String get bookingWalkInTitle => 'Nouveau RDV';

  @override
  String get bookingWalkInClientNameLabel => 'Prénom du client *';

  @override
  String get bookingWalkInServiceLabel => 'Service *';

  @override
  String get bookingWalkInPractitionerLabel => 'Praticien *';

  @override
  String get bookingWalkInServicesLoadError =>
      'Impossible de charger les services.';

  @override
  String get bookingWalkInStaffLoadError => 'Impossible de charger l\'équipe.';

  @override
  String get bookingWalkInTimeLabel => 'Heure';

  @override
  String get bookingWalkInMissingFields => 'Service et praticien requis.';

  @override
  String get bookingWalkInSubmitButton => 'Créer le RDV';

  @override
  String get bookingConfirmationRef => 'Réf.';

  @override
  String get bookingSalonDetailReserveButton => 'Réserver →';

  @override
  String get bookingDiscoveryTitle => 'Découvrir';

  @override
  String get bookingDiscoverySearchHint => 'Rechercher un salon…';

  @override
  String get bookingDiscoveryAdvancedSearchTooltip => 'Recherche avancée';

  @override
  String get bookingDiscoveryAllCategories => 'Toutes';

  @override
  String get bookingDiscoveryLoadError => 'Impossible de charger les salons.';

  @override
  String get bookingDiscoveryEmptyTitle => 'Aucun salon trouvé';

  @override
  String get bookingDiscoveryEmptySubtitle =>
      'Essayez une autre recherche ou catégorie.';

  @override
  String get bookingDiscoveryResetButton => 'Réinitialiser';

  @override
  String bookingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rendez-vous',
      one: '1 rendez-vous',
      zero: 'Aucun rendez-vous',
    );
    return '$_temp0';
  }

  @override
  String get bookingUpcomingTab => 'À venir';

  @override
  String get bookingPastTab => 'Passés';

  @override
  String get bookingRebookButton => 'Réserver à nouveau';

  @override
  String get bookingViewReceiptButton => 'Voir le reçu';

  @override
  String get bookingPaymentMethodLabel => 'Méthode';

  @override
  String get bookingShareReceiptButton => 'Partager le reçu';

  @override
  String get bookingSalonDetailLoadError => 'Impossible de charger ce salon.';

  @override
  String get bookingSalonNotFound => 'Salon introuvable.';

  @override
  String get bookingSalonDetailServicesTab => 'Services';

  @override
  String get bookingSalonDetailInfoTab => 'Info';

  @override
  String get bookingSalonDetailReviewsTab => 'Avis';

  @override
  String get bookingSalonDetailServicesLoadError =>
      'Impossible de charger les services.';

  @override
  String get bookingSalonDetailServicesEmptySubtitle => 'Revenez plus tard.';

  @override
  String get paymentTitle => 'Paiement';

  @override
  String get paymentMethodTitle => 'Méthode de paiement';

  @override
  String get paymentMethodLumicash => 'Lumicash';

  @override
  String get paymentMethodEcocash => 'EcoCash';

  @override
  String get paymentUssdInstruction =>
      'Vous allez recevoir une demande USSD sur votre téléphone. Entrez votre code PIN pour confirmer.';

  @override
  String get paymentSubmitButton => 'Payer →';

  @override
  String get paymentFailedMessage =>
      'Ce paiement n\'a pas abouti. Aucun argent débité.';

  @override
  String get paymentRetryButton => 'Réessayer';

  @override
  String get paymentInvalidPhone => 'Numéro invalide.';

  @override
  String get proxipayQrTitle => 'Encaisser';

  @override
  String get proxipayCreateSessionError =>
      'Impossible de générer le QR de paiement.';

  @override
  String get proxipayQrShowToClient => 'Faites scanner ce code par le client.';

  @override
  String proxipayQrExpiresIn(String minutes, String seconds) {
    return 'Expire dans $minutes:$seconds';
  }

  @override
  String get proxipayQrExpired => 'Le code a expiré. Générez-en un nouveau.';

  @override
  String get proxipayAwaitingSettlementMessage =>
      'En attente de confirmation du paiement...';

  @override
  String get proxipaySuccessMessage => 'Paiement reçu ✓';

  @override
  String get proxipayFailedMessage =>
      'Ce paiement n\'a pas abouti. Aucun argent débité.';

  @override
  String get proxipayRetryButton => 'Réessayer';

  @override
  String get proxipayDoneButton => 'Terminé';

  @override
  String get proxipayScanTitle => 'Payer sur place';

  @override
  String get proxipayScanInstruction => 'Scannez le code affiché par le salon.';

  @override
  String get proxipayScanInvalidError => 'Code invalide ou expiré.';

  @override
  String get proxipayScanConnectionError => 'Erreur de connexion. Réessayez.';

  @override
  String get proxipayConfirmPayButton => 'Payer →';

  @override
  String get proxipayConfirmErrorGeneric =>
      'Impossible de confirmer le paiement.';

  @override
  String get proxipayConfirmSuccessMessage => 'Paiement envoyé ✓';

  @override
  String get notificationsListTitle => 'Notifications';

  @override
  String get notificationsDeleteSuccess => 'Notification supprimée.';

  @override
  String get notificationsLoadMoreButton => 'Charger plus';

  @override
  String get notificationsSettingsTitle => 'Préférences de notifications';

  @override
  String get notificationsChannelsHeading => 'Canaux';

  @override
  String get notificationsPushTitle => 'Notifications push';

  @override
  String get notificationsWhatsappTitle => 'WhatsApp';

  @override
  String get notificationsWhatsappLabel => 'Numéro WhatsApp';

  @override
  String get notificationsWhatsappHint => '+257 ...';

  @override
  String get notificationsAlertTypesHeading => 'Types d\'alertes';

  @override
  String get notificationsBookingCreatedTitle => 'Réservation créée';

  @override
  String get notificationsBookingCreatedSubtitle =>
      'Confirmation immédiate de votre demande';

  @override
  String get notificationsBookingConfirmedTitle => 'RDV confirmé';

  @override
  String get notificationsBookingCancelledTitle => 'RDV annulé';

  @override
  String get notificationsRemindersTitle => 'Rappels RDV';

  @override
  String get notificationsRemindersSubtitle =>
      'Rappel 24h et 2h avant le rendez-vous';

  @override
  String get notificationsTeamTitle => 'Équipe';

  @override
  String get notificationsTeamSubtitle =>
      'Invitations et arrivées de collaborateurs';

  @override
  String get notificationsMarketingTitle => 'Marketing';

  @override
  String get notificationsMarketingSubtitle =>
      'Promotions et nouveautés du salon';

  @override
  String get notificationsSaveButton => 'Enregistrer';

  @override
  String get notificationsLoadError => 'Impossible de charger vos préférences.';

  @override
  String get notificationsSaveSuccess => 'Préférences enregistrées.';

  @override
  String get notificationsSaveError => 'Échec de l\'enregistrement.';

  @override
  String get staffListTitle => 'Mon Équipe';

  @override
  String get staffListSoloLink => 'Je travaille seul →';

  @override
  String get staffListCommissionsTooltip => 'Commissions';

  @override
  String get staffFilterActive => 'Actifs';

  @override
  String get staffFilterPending => 'En attente';

  @override
  String get staffFilterDisabled => 'Désactivés';

  @override
  String get staffListLoadError => 'Impossible de charger l\'équipe.';

  @override
  String get staffInviteTitle => 'Inviter un membre';

  @override
  String get staffInviteNameLabel => 'Nom *';

  @override
  String get staffInviteRoleStaff => 'Staff';

  @override
  String get staffInviteRoleManager => 'Manager';

  @override
  String get staffInviteSubmitButton => 'Envoyer l\'invitation';

  @override
  String get staffInviteError => 'Échec de l\'invitation.';

  @override
  String get staffFormTitle => 'Modifier le membre';

  @override
  String get staffFormRemoveConfirmTitle => 'Retirer ce membre ?';

  @override
  String staffFormRemoveConfirmMessage(String name) {
    return '$name ne pourra plus accéder à ce salon.';
  }

  @override
  String get staffFormServicesLoadError =>
      'Impossible de charger les services.';

  @override
  String get staffAcceptInvitationVerifying =>
      'Vérification de l\'invitation...';

  @override
  String get staffCommissionsTitle => 'Commissions';

  @override
  String get availabilityManagementTitle => 'Disponibilités';

  @override
  String get availabilityExceptionsLabel =>
      'Jours exceptionnels & jours fériés';

  @override
  String get availabilityBlockedLabel => 'Jours bloqués (ponctuel)';

  @override
  String get availabilityLoadError =>
      'Impossible de charger les disponibilités.';

  @override
  String get availabilitySalonHoursTitle => 'Horaires du salon';

  @override
  String get availabilitySalonHoursSaveSuccess => 'Horaires enregistrés.';

  @override
  String get availabilityStaffHoursUseSalonTitle =>
      'Utiliser les horaires du salon';

  @override
  String get availabilityStaffHoursSaveSuccess => 'Horaires enregistrés.';

  @override
  String get availabilityBlockedSlotsTitle => 'Jours bloqués';

  @override
  String get availabilityBlockedSlotsConfirmTitle => 'Débloquer ce jour ?';

  @override
  String get availabilityBlockedSlotsLoadError =>
      'Impossible de charger les jours bloqués.';

  @override
  String get availabilityExceptionsTitle => 'Jours exceptionnels';

  @override
  String availabilityBreaksTitle(String name) {
    return 'Pauses de $name';
  }

  @override
  String get availabilityDayOverrideTitle => 'Ouvert ce jour-là';

  @override
  String get availabilityDayOverrideReasonLabel => 'Raison (optionnel)';

  @override
  String get availabilityDayOverrideHint => 'Congé, jour férié, formation…';

  @override
  String get availabilityBreakDayLabel => 'Jour';

  @override
  String get availabilityBreakLabelField => 'Libellé';

  @override
  String availabilityBreakStartTime(String time) {
    return 'Début $time';
  }

  @override
  String availabilityBreakEndTime(String time) {
    return 'Fin $time';
  }

  @override
  String get availabilityExceptionTitle => 'Jour exceptionnel';

  @override
  String get availabilityExceptionTypeLabel => 'Type';

  @override
  String get availabilityExceptionTypeVacation => 'Vacances';

  @override
  String get availabilityExceptionTypeClosure => 'Fermeture spéciale';

  @override
  String get availabilityExceptionTypeOpening => 'Ouverture spéciale';

  @override
  String get availabilityExceptionChooseDates => 'Choisir les dates';

  @override
  String availabilityExceptionOpenTime(String time) {
    return 'Ouvre $time';
  }

  @override
  String availabilityExceptionCloseTime(String time) {
    return 'Ferme $time';
  }

  @override
  String get availabilityExceptionLabelField => 'Libellé';

  @override
  String get availabilityExceptionLabelHint => 'Congé annuel, formation…';

  @override
  String get availabilityWeekdayPreset => 'Jours de semaine 8h–18h';

  @override
  String get availabilityAllDayPreset => 'Tous les jours 8h–20h';

  @override
  String get availabilityHubStaffHoursLabel => 'Horaires par staff';

  @override
  String get availabilityHubBreaksLabel => 'Pauses & absences';

  @override
  String get availabilityHubTouchHint =>
      'Touchez un jour pour le fermer ou le rouvrir exceptionnellement.';

  @override
  String get availabilitySaveFailed => 'Échec de l\'enregistrement.';

  @override
  String get availabilityDeleteFailed => 'Échec de la suppression.';

  @override
  String get availabilityUnblockFailed => 'Échec du déblocage.';

  @override
  String get availabilityNoBlockedDaysTitle => 'Aucun jour bloqué';

  @override
  String get availabilityNoBlockedDaysSubtitle =>
      'Tous vos jours d\'ouverture habituels sont actifs.';

  @override
  String get availabilityUnblockMessage =>
      'Ce jour redeviendra ouvert selon vos horaires habituels.';

  @override
  String get availabilityNoBreaksTitle => 'Aucune pause';

  @override
  String availabilityNoBreaksSubtitle(String name) {
    return 'Ajoutez les pauses récurrentes de $name.';
  }

  @override
  String get availabilityAddBreakCta => 'Ajouter une pause';

  @override
  String get availabilityNewBreakTitle => 'Nouvelle pause';

  @override
  String get availabilityBreakDefaultLabel => 'Pause déjeuner';

  @override
  String get availabilityBreakFallbackLabel => 'Pause';

  @override
  String get availabilityNoExceptionsTitle => 'Aucun jour exceptionnel';

  @override
  String get availabilityNoExceptionsSubtitle =>
      'Ajoutez vos vacances ou fermetures spéciales.';

  @override
  String get availabilityPublicHolidaysHeading => 'Jours fériés';

  @override
  String get availabilityNoPublicHolidays => 'Aucun jour férié configuré.';

  @override
  String get availabilityStaffHoursScreenHint =>
      'Ces horaires remplacent les horaires du salon pour ce praticien.';

  @override
  String availabilityStaffHoursOf(String name) {
    return 'Horaires de $name';
  }

  @override
  String get availabilityMyAvailability => 'Mes disponibilités';

  @override
  String get availabilityStaffHoursLoadError =>
      'Impossible de charger ces horaires.';

  @override
  String get availabilityNoStaffTitle => 'Aucun staff';

  @override
  String get availabilityNoStaffSubtitle =>
      'Invitez votre équipe pour configurer leurs horaires.';

  @override
  String get availabilityStaffLoadError => 'Impossible de charger l\'équipe.';

  @override
  String get availabilityClosedLabel => 'Fermé';

  @override
  String get availabilityBreaksLoadError => 'Impossible de charger les pauses.';

  @override
  String get availabilitySalonHoursLoadError =>
      'Impossible de charger les horaires.';

  @override
  String get availabilityExceptionsLoadError =>
      'Impossible de charger les jours exceptionnels.';

  @override
  String get weekdayMonday => 'Lundi';

  @override
  String get weekdayTuesday => 'Mardi';

  @override
  String get weekdayWednesday => 'Mercredi';

  @override
  String get weekdayThursday => 'Jeudi';

  @override
  String get weekdayFriday => 'Vendredi';

  @override
  String get weekdaySaturday => 'Samedi';

  @override
  String get weekdaySunday => 'Dimanche';

  @override
  String get weekdayMondayShort => 'Lun';

  @override
  String get weekdayTuesdayShort => 'Mar';

  @override
  String get weekdayWednesdayShort => 'Mer';

  @override
  String get weekdayThursdayShort => 'Jeu';

  @override
  String get weekdayFridayShort => 'Ven';

  @override
  String get weekdaySaturdayShort => 'Sam';

  @override
  String get weekdaySundayShort => 'Dim';

  @override
  String get servicesListTitle => 'Services';

  @override
  String servicesDeleteSuccess(String name) {
    return '$name supprimé.';
  }

  @override
  String servicesDeleteSnack(String name) {
    return '« $name » supprimé.';
  }

  @override
  String get servicesNoServiceTitle => 'Aucun service';

  @override
  String get servicesNoServiceSubtitle =>
      'Ajoutez vos prestations pour commencer à recevoir des RDV.';

  @override
  String get servicesNoServiceCta => 'Ajouter un service';

  @override
  String get servicesFilterAll => 'Toutes';

  @override
  String get servicesFormEditTitle => 'Modifier le service';

  @override
  String get servicesFormNewTitle => 'Nouveau service';

  @override
  String get servicesFormNameLabel => 'Nom du service *';

  @override
  String get servicesFormCategoryLabel => 'Catégorie *';

  @override
  String get servicesFormDescriptionLabel => 'Description';

  @override
  String get servicesFormDurationLabel => 'Durée (minutes) *';

  @override
  String get servicesFormDurationError => 'Durée invalide.';

  @override
  String get servicesFormBufferLabel => 'Temps de préparation (minutes)';

  @override
  String get servicesFormPriceLabel => 'Prix (FBu) *';

  @override
  String get servicesFormPriceError => 'Prix invalide.';

  @override
  String get reviewsOwnerTitle => 'Mes Avis';

  @override
  String get reviewsSortRecent => 'Récents';

  @override
  String get reviewsSortLowest => 'Note basse';

  @override
  String get reviewsSortUnanswered => 'Sans réponse';

  @override
  String get reviewsReplyTitle => 'Répondre à cet avis';

  @override
  String get reviewsReplyLabel => 'Votre réponse';

  @override
  String get reviewsReplySubmitButton => 'Publier la réponse';

  @override
  String get reviewsFlagConfirmTitle => 'Signaler cet avis ?';

  @override
  String get reviewsFlagConfirmMessage =>
      'Il sera masqué en attendant une revue par notre équipe.';

  @override
  String get reviewsFlagConfirmButton => 'Signaler';

  @override
  String get reviewsEmptyTitle => 'Aucun avis encore';

  @override
  String get reviewsEmptySubtitle => 'Vos avis clients apparaîtront ici.';

  @override
  String get reviewsEmptyCta => 'Retour';

  @override
  String get reviewsReplyError => 'Échec de l\'envoi.';

  @override
  String get reviewsFlagError => 'Échec du signalement.';

  @override
  String get reviewsLoadError => 'Impossible de charger vos avis.';

  @override
  String get reviewsSalonLoadError => 'Impossible de charger les avis.';

  @override
  String get reviewsLeaveTitle => 'Laisser un avis';

  @override
  String get reviewsLeaveBookingError =>
      'Impossible de vérifier votre réservation.';

  @override
  String get reviewsLeaveSuccess => 'Avis publié ! Merci 💛';

  @override
  String get reviewsLeaveQueuedOffline =>
      'Avis enregistré hors ligne — sera publié dès la reconnexion.';

  @override
  String get reviewsLeaveSkipButton => 'Passer';

  @override
  String get reviewsLeaveRatingRequired =>
      'Choisissez une note avant de publier.';

  @override
  String get reviewsLeaveCommentLabel =>
      'Partagez votre expérience (optionnel)';

  @override
  String get reviewsLeaveAnonymousLabel => 'Rester anonyme';

  @override
  String get reviewsLeavePublishButton => 'Publier mon avis';

  @override
  String get reviewsLeaveUnavailableTitle => 'Avis indisponible';

  @override
  String get reviewsLeaveUnavailableSubtitle =>
      'Cette réservation a déjà reçu un avis ou ne peut pas encore être notée.';

  @override
  String get reviewsLeaveBackButton => 'Retour à mes RDV';

  @override
  String get reviewsLeaveServiceFallback => 'Votre prestation';

  @override
  String get reviewsAnonymousName => 'Anonyme';

  @override
  String get reviewsClientFallbackName => 'Client';

  @override
  String get reviewsSalonReplyLabel => 'Réponse du salon';

  @override
  String get reviewsFirstTitle => 'Soyez le premier à laisser un avis !';

  @override
  String get reviewsFirstSubtitle => 'Réservez puis partagez votre expérience.';

  @override
  String reviewsVerifiedCount(int count) {
    return '$count avis vérifiés';
  }

  @override
  String get marketingDashboardTitle => 'Marketing';

  @override
  String get marketingBookingsLabel => 'Réservations';

  @override
  String get marketingRecurringLabel => 'Récurrents';

  @override
  String get marketingSeeAllContactsButton => 'Voir tous mes contacts →';

  @override
  String get marketingTeamPerformanceError =>
      'Impossible de charger la performance équipe.';

  @override
  String get marketingForecastsError =>
      'Impossible de calculer les prévisions.';

  @override
  String get marketingSendError => 'Échec de l\'envoi.';

  @override
  String get marketingPromotionsTitle => 'Promotions';

  @override
  String get marketingPromotionsActiveFilter => 'Actives';

  @override
  String get marketingPromotionsExpiredFilter => 'Expirées';

  @override
  String get marketingPromotionsEmptyActive => 'Aucune promotion active';

  @override
  String get marketingPromotionsEmptyActiveHint =>
      'Créez votre première offre pour attirer vos clients.';

  @override
  String get marketingPromotionsEmptyExpired => 'Aucune promotion expirée';

  @override
  String get marketingPromotionsCreateButton => 'Créer ma première promotion';

  @override
  String get marketingPromotionsDeactivateConfirmTitle =>
      'Désactiver cette promotion ?';

  @override
  String marketingPromotionsDeactivateConfirmMessage(String name) {
    return '$name ne sera plus visible des clients.';
  }

  @override
  String get marketingPromotionsDeactivateButton => 'Désactiver';

  @override
  String get marketingPromotionsDeactivateError => 'Échec de la désactivation.';

  @override
  String get marketingPromotionsLoadError =>
      'Impossible de charger vos promotions.';

  @override
  String get marketingPromotionTypePercentage => 'Pourcentage %';

  @override
  String get marketingPromotionTypeFixed => 'Montant fixe FBu';

  @override
  String get marketingPromotionGenerateCodeButton => 'Générer un code';

  @override
  String get marketingPromotionDateError =>
      'La date de fin doit être après la date de début.';

  @override
  String get marketingClientsTitle => 'Mes Clients';

  @override
  String get marketingClientsContactsTab => 'Contacts';

  @override
  String get marketingClientsInvitationsTab => 'Invitations';

  @override
  String marketingClientsDeleteSuccess(String name) {
    return '$name supprimé.';
  }

  @override
  String get marketingClientsOnKynzaBadge => 'Sur KYNZA ✓';

  @override
  String get marketingClientsLoadError => 'Impossible de charger vos clients.';

  @override
  String get marketingLoyaltyTitle => 'Programme Fidélité';

  @override
  String get marketingLoyaltyRewardMissingWarning =>
      'Décrivez la récompense offerte.';

  @override
  String get marketingLoyaltySaveSuccess => 'Programme enregistré !';

  @override
  String marketingLoyaltyRewardValidatedSuccess(String name) {
    return 'Récompense validée pour $name !';
  }

  @override
  String get marketingLoyaltyRewardValidateConfirmTitle =>
      'Valider la récompense ?';

  @override
  String get marketingLoyaltyRewardDescriptionLabel =>
      'Description de la récompense *';

  @override
  String get marketingLoyaltyStampsLabel => 'Tampons donnés';

  @override
  String get marketingLoyaltyRewardsLabel => 'Récompenses';

  @override
  String get marketingShareTitle => 'Partager mon salon';

  @override
  String get marketingShareCopySuccess => 'Lien copié !';

  @override
  String get dashboardTitle => 'Dashboard KYNZA';

  @override
  String get dashboardTeamPerformanceError =>
      'Impossible de charger la performance équipe.';

  @override
  String get dashboardForecastsError =>
      'Impossible de calculer les prévisions.';

  @override
  String get dashboardAuditLogLoadError =>
      'Impossible de charger le journal d\'activité.';

  @override
  String get dashboardAuditLogExportTooltip => 'Exporter (CSV)';

  @override
  String get dashboardAuditLogLoadMoreButton => 'Charger plus';

  @override
  String get dashboardLoadError => 'Impossible de charger le dashboard.';

  @override
  String get dashboardOverviewTab => 'Vue d\'ensemble';

  @override
  String get dashboardClientsTab => 'Clients';

  @override
  String get dashboardTeamTab => 'Équipe';

  @override
  String get dashboardForecastTab => 'Prévisions';

  @override
  String get dashboardExportPdfButton => 'Exporter PDF';

  @override
  String get dashboardKpiRevenu => 'Revenu';

  @override
  String get dashboardKpiReservations => 'Réservations';

  @override
  String get dashboardKpiOccupancyRate => 'Taux remplissage';

  @override
  String get dashboardKpiNoShowRate => 'Taux no-show';

  @override
  String get dashboardRevenueChartTitle => 'Évolution du CA';

  @override
  String get dashboardNoServiceTitle => 'Aucun service';

  @override
  String get dashboardNoServiceSubtitle =>
      'Ajoutez vos prestations pour suivre leur succès.';

  @override
  String get dashboardAddServiceCta => 'Ajouter un service';

  @override
  String get dashboardNoStaffTitle => 'Aucun staff';

  @override
  String get dashboardNoStaffSubtitle =>
      'Invitez votre équipe pour suivre leurs performances.';

  @override
  String get dashboardInviteTeamCta => 'Inviter votre équipe';

  @override
  String get dashboardQuickActionServices => 'Services';

  @override
  String get dashboardQuickActionAddService => 'Ajouter service';

  @override
  String get dashboardQuickActionTeam => 'Équipe';

  @override
  String get dashboardQuickActionInviteStaff => 'Inviter staff';

  @override
  String get dashboardClientExportCsvButton => 'Exporter clients (CSV)';

  @override
  String get dashboardNewVsReturning => 'Nouveaux vs Récurrents';

  @override
  String get dashboardNewClients => 'Nouveaux';

  @override
  String get dashboardReturningClients => 'Récurrents';

  @override
  String get dashboardChurnRiskTitle => 'Clients à risque';

  @override
  String get dashboardNoChurnRisk => 'Aucun client à risque pour le moment.';

  @override
  String get dashboardTopClientsTitle => 'Meilleurs clients';

  @override
  String get dashboardNoTopClients => 'Pas encore de clients.';

  @override
  String dashboardClientVisitCount(int count) {
    return '$count visites';
  }

  @override
  String get dashboardCohortTitle => 'Rétention par cohorte';

  @override
  String get dashboardChurnRiskHigh => 'Risque élevé';

  @override
  String get dashboardChurnRiskMedium => 'Risque moyen';

  @override
  String get dashboardChurnRiskLow => 'Risque faible';

  @override
  String dashboardChurnAbsentDays(int days) {
    return 'Absent depuis $days jours';
  }

  @override
  String get dashboardOwnerOnlyTitle => 'Réservé au propriétaire';

  @override
  String get dashboardOwnerOnlySubtitle =>
      'Les performances de l\'équipe ne sont visibles que par le propriétaire.';

  @override
  String get dashboardTeamRevenueChartTitle => 'CA par staff';

  @override
  String get dashboardNoTeamDataTitle => 'Aucune donnée équipe';

  @override
  String get dashboardNoTeamDataSubtitle =>
      'Les performances apparaîtront après les premiers RDV.';

  @override
  String get dashboardExportReportPdfButton => 'Exporter rapport (PDF)';

  @override
  String get dashboardExportCsvButton => 'Exporter CSV';

  @override
  String get dashboardForecastTitle => 'Prévision sur 12 semaines';

  @override
  String get dashboardForecastNoHistory =>
      'Pas encore assez d\'historique pour une prévision.';

  @override
  String get dashboardExportForecastCsvButton => 'Exporter (CSV)';

  @override
  String dashboardOccupancyTip(int rate) {
    return 'Occupation à $rate% — pensez à relancer vos clients pour remplir votre planning.';
  }

  @override
  String get dashboardTopServicesTitle => 'Top services';

  @override
  String get dashboardServiceSeeAll => 'Voir tout';

  @override
  String dashboardServiceRdvCount(int count) {
    return '$count RDV';
  }

  @override
  String get dashboardTopStaffTitle => 'Top équipe';

  @override
  String dashboardStaffRdvCount(int count) {
    return '$count RDV';
  }

  @override
  String get dashboardCohortHeader => 'Cohorte';

  @override
  String get dashboardNoCohortData => 'Pas encore de données de cohortes.';

  @override
  String get auditLogTitle => 'Journal d\'activité';

  @override
  String get auditLogFilterAll => 'Tous';

  @override
  String get auditLogFilterBooking => 'RDV';

  @override
  String get auditLogFilterPayment => 'Paiement';

  @override
  String get auditLogFilterStaff => 'Équipe';

  @override
  String get auditLogFilterSettings => 'Paramètres';

  @override
  String get auditLogNoActivityTitle => 'Aucune activité';

  @override
  String get auditLogNoActivitySubtitle =>
      'Le journal se remplira au fil de vos actions.';

  @override
  String get dataTemplatesListTitle => 'Modèles de documents';

  @override
  String get dataTemplatesDeleteConfirmTitle => 'Supprimer le modèle';

  @override
  String dataTemplatesDeleteConfirmMessage(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get dataTemplatesLoadError => 'Impossible de charger les modèles.';

  @override
  String get dataTemplatesDeleteSuccess => 'Modèle supprimé.';

  @override
  String get dataTemplatesDeleteError => 'Impossible de supprimer ce modèle.';

  @override
  String get dataTemplatesDefaultBadge => 'DÉFAUT';

  @override
  String get dataTemplateEditorNameLabel => 'Nom du modèle';

  @override
  String get dataTemplateEditorContentLabel => 'Contenu du modèle';

  @override
  String get dataTemplateEditorContentHint =>
      'Utilisez [variable] pour insérer des données dynamiques.';

  @override
  String get dataBackupTitle => 'Sauvegardes de données';

  @override
  String get dataBackupCreateButton => 'Créer une sauvegarde';

  @override
  String get dataBackupCreateCancelButton => 'Annuler';

  @override
  String get dataBackupCreateSuccess => 'Sauvegarde créée avec succès.';

  @override
  String get billingTitle => 'Facturation';

  @override
  String get billingSubscriptionTitle => 'Abonnement KYNZA';

  @override
  String get billingSubscriptionRecommendedBadge => 'RECOMMANDÉ';

  @override
  String billingSubscriptionDowngradeConfirmTitle(String plan) {
    return 'Rétrograder vers $plan ?';
  }

  @override
  String billingSubscriptionDowngradeConfirmMessage(String plan) {
    return 'Votre salon passera immédiatement au plan $plan.';
  }

  @override
  String get billingSubscriptionUpdateSuccess => 'Plan mis à jour.';

  @override
  String get billingSubscriptionMarkPaidButton => 'Marquer comme payé';

  @override
  String get billingSubscriptionCopyReferenceButton => 'Copier la référence';

  @override
  String get billingSubscriptionCopyReferenceSuccess => 'Référence copiée !';

  @override
  String get billingInvoicesTitle => 'Historique des factures';

  @override
  String get permissionsGroupsTitle => 'Groupes de permissions';

  @override
  String get permissionsGroupNameHint => 'ex. Réceptionniste Senior';

  @override
  String get permissionsGroupCreateError => 'Impossible de créer ce groupe.';

  @override
  String get permissionsGroupDeleteConfirmTitle => 'Supprimer ce groupe ?';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsPermissionsLabel => 'Permissions & Équipe';

  @override
  String get settingsAutomationLabel => 'Automatisations';

  @override
  String get settingsBookingLabel => 'Réservations';

  @override
  String get settingsNotificationsSalonLabel => 'Notifications du salon';

  @override
  String get settingsMarketingLabel => 'Marketing';

  @override
  String get settingsTeamLabel => 'Équipe';

  @override
  String get settingsLoyaltyLabel => 'Fidélité';

  @override
  String get settingsReviewsLabel => 'Avis';

  @override
  String get settingsPaymentsLabel => 'Paiements';

  @override
  String get settingsAdvancedLabel => 'Avancé';

  @override
  String get settingsDocumentTemplatesLabel => 'Modèles de documents';

  @override
  String get settingsDataBackupLabel => 'Sauvegardes de données';

  @override
  String get settingsFeatureFlagsLabel => 'Drapeaux de fonctionnalités';

  @override
  String get settingsAboutLabel => 'À propos de KYNZA';

  @override
  String get settingsCategoryLoadError =>
      'Impossible de charger les paramètres.';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsAboutSectionApp => 'Application';

  @override
  String get settingsAboutSectionLegal => 'Légal';

  @override
  String get settingsAboutVersionLabel => 'Version';

  @override
  String get settingsAboutBuildLabel => 'Build';

  @override
  String get settingsAboutPlatformLabel => 'Plateforme';

  @override
  String get settingsAboutPublisherLabel => 'Éditeur';

  @override
  String get settingsAboutCountryLabel => 'Pays';

  @override
  String get settingsAboutCurrencyLabel => 'Devise';

  @override
  String settingsAboutCopyright(String year) {
    return '© $year KYNZA. Tous droits réservés.';
  }

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle =>
      'Choisissez la langue de l\'application';

  @override
  String get settingsLanguageSystemDetected => 'Détecté automatiquement';

  @override
  String get languageSectionTitle => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get evolutionFeatureFlagsTitle => 'Drapeaux de fonctionnalités';

  @override
  String get evolutionFeatureFlagsDisabledBadge => 'GLOBAL: DÉSACTIVÉ';

  @override
  String get evolutionFeatureFlagsEnabledBadge => 'GLOBAL: ACTIVÉ';

  @override
  String get evolutionFeatureFlagsResetTooltip =>
      'Réinitialiser (suivre global)';

  @override
  String get evolutionFeatureFlagsEmptyTitle => 'Aucun drapeau configuré';

  @override
  String get evolutionFeatureFlagsEmptySubtitle =>
      'Les drapeaux de fonctionnalités apparaîtront ici.';

  @override
  String get evolutionFeatureFlagsOverrideBadge => 'OVERRIDE';

  @override
  String evolutionFeatureFlagsRollout(int percentage) {
    return 'GLOBAL: $percentage%';
  }

  @override
  String get evolutionFeatureFlagsInfoText =>
      'Activez ou désactivez des fonctionnalités pour ce salon. Les overrides locaux priment sur les paramètres globaux.';

  @override
  String get evolutionMaintenanceDefaultTitle => 'Maintenance en cours';

  @override
  String get evolutionMaintenanceDefaultMessage =>
      'L\'application est temporairement indisponible. Nous reviendrons très bientôt.';

  @override
  String evolutionMaintenanceEndsAt(String time) {
    return 'Fin prévue vers $time';
  }

  @override
  String get evolutionForceUpdateTitle => 'Mise à jour requise';

  @override
  String get evolutionForceUpdateDefaultMessage =>
      'Cette version de l\'application n\'est plus supportée. Veuillez mettre à jour pour continuer.';

  @override
  String evolutionForceUpdateVersionLabel(String version) {
    return 'Version disponible : $version';
  }

  @override
  String get evolutionForceUpdateCheckButton => 'Vérifier à nouveau';

  @override
  String get evolutionForceUpdateButton => 'Mettre à jour';

  @override
  String get evolutionMaintenanceCheckButton => 'Vérifier à nouveau';

  @override
  String get automationListTitle => 'Automatisations';

  @override
  String get automationListHistoryTooltip => 'Historique d\'exécution';

  @override
  String get automationListEmptyTitle => 'Aucune automatisation';

  @override
  String get automationListEmptySubtitle =>
      'Créez un workflow pour automatiser une action quand un événement se produit.';

  @override
  String get automationWorkflowTitle => 'Nouveau workflow';

  @override
  String get automationWorkflowNameLabel => 'Nom';

  @override
  String get automationWorkflowDescriptionLabel => 'Description (optionnel)';

  @override
  String get automationWorkflowConditionsTitle => 'Conditions';

  @override
  String get automationWorkflowNoConditions =>
      'Aucune condition — le workflow s\'exécutera à chaque déclenchement.';

  @override
  String get automationWorkflowActionsTitle => 'Actions';

  @override
  String get automationWorkflowNoActions =>
      'Ajoutez au moins une action à exécuter.';

  @override
  String get automationWorkflowFieldLabel => 'Champ (ex. amount)';

  @override
  String get automationWorkflowValueLabel => 'Valeur';

  @override
  String get automationWorkflowDelayLabel => 'Délai (secondes) :';

  @override
  String get automationWorkflowTargetLabel => 'Destinataire';

  @override
  String get automationWorkflowEventHint => 'ex. booking_confirmed';

  @override
  String get automationWorkflowStampsLabel => 'Tampons bonus';

  @override
  String get automationWorkflowReasonLabel => 'Raison (optionnel)';

  @override
  String get automationWorkflowActionLabel => 'Action';

  @override
  String get automationWorkflowNotWired => '(pas encore câblé)';

  @override
  String get automationWorkflowComingSoon => '(bientôt)';

  @override
  String get automationWorkflowNotImplemented =>
      'Cette action n\'est pas encore disponible.';

  @override
  String automationWorkflowExecutionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exécutions',
      one: '1 exécution',
      zero: '0 exécution',
    );
    return '$_temp0';
  }

  @override
  String get automationWorkflowTriggersLoadError =>
      'Impossible de charger les déclencheurs.';

  @override
  String get automationWorkflowValidationError =>
      'Le nom et le déclencheur sont requis.';

  @override
  String get automationWorkflowCreateError =>
      'Impossible de créer ce workflow.';

  @override
  String get automationWorkflowTriggerLabel => 'Déclencheur';

  @override
  String get automationWorkflowCreateButton => 'Créer le workflow';

  @override
  String get automationWorkflowLogicOperatorLabel => 'Opérateur logique';

  @override
  String get automationWorkflowOperatorLabel => 'Opérateur';

  @override
  String get automationWorkflowEventLabel => 'Événement (event_type)';

  @override
  String get automationWorkflowSeverityLabel => 'Sévérité';

  @override
  String get searchAdvancedTitle => 'Recherche';

  @override
  String get searchAdvancedHint => 'Rechercher salons, services…';

  @override
  String get searchAdvancedClearButton => 'Effacer';

  @override
  String get searchFiltersResetButton => 'Réinitialiser';

  @override
  String get salonCreationTitle => 'Créer votre salon';

  @override
  String get salonLocationHint => 'Rue, numéro, quartier';

  @override
  String get salonCreationNextButton => 'Suivant →';

  @override
  String get salonCreationSubmitButton => 'Créer mon salon →';

  @override
  String get salonCreationErrorGeneric =>
      'Impossible de créer le salon. Réessayez.';

  @override
  String get salonInfoStepNameLabel => 'Nom du salon *';

  @override
  String get salonInfoStepSloganLabel => 'Slogan';

  @override
  String get salonInfoStepDescriptionLabel => 'Description';

  @override
  String get salonInfoStepSocialTitle => 'Réseaux sociaux';

  @override
  String get salonLocationStepAddressLabel => 'Adresse';

  @override
  String get salonMediaStepLogoLabel => 'Logo';

  @override
  String get salonMediaStepCoverLabel => 'Photo de couverture';

  @override
  String get salonMediaStepAddCoverLabel => 'Ajouter une couverture';

  @override
  String salonMediaStepGalleryLabel(int count, int max) {
    return 'Galerie ($count/$max)';
  }

  @override
  String get salonCreationSuccessTitle => 'Votre salon est créé ! 🎉';

  @override
  String get salonCreationSuccessSubtitle => 'Ajoutez maintenant vos services';

  @override
  String get salonCreationSuccessCtaLabel => 'Configurer mes services →';

  @override
  String get provinceSelectorProvinceLabel => 'Province';

  @override
  String get provinceSelectorProvinceRequired => 'Province requise.';

  @override
  String get provinceSelectorCommuneLabel => 'Commune';

  @override
  String get provinceSelectorCommuneRequired => 'Commune requise.';

  @override
  String get workingHoursClosed => 'Fermé';

  @override
  String get loyaltyCardsLoadError =>
      'Impossible de charger vos cartes de fidélité.';

  @override
  String get loyaltyCardsEmptyTitle => 'Aucune carte de fidélité';

  @override
  String get loyaltyCardsEmptySubtitle =>
      'Réservez votre premier RDV pour commencer à collecter des tampons ! 💛';

  @override
  String get loyaltyCardsEmptyCtaLabel => 'Découvrir les salons';

  @override
  String get loyaltyQrCardNotFound => 'Carte de fidélité introuvable.';

  @override
  String get loyaltyQrGenerateError => 'Impossible de générer le QR code.';

  @override
  String get loyaltyQrShowToStaff => 'Montrez ce code au personnel du salon';

  @override
  String loyaltyQrExpiresIn(String minutes, String seconds) {
    return 'Expire dans $minutes:$seconds';
  }

  @override
  String get loyaltyScanQrInvalidError => 'QR invalide ou expiré.';

  @override
  String get loyaltyScanConnectionError => 'Connexion impossible. Réessayez.';

  @override
  String loyaltyStampsRequired(int required) {
    return '$required tampons requis';
  }

  @override
  String loyaltyStampsProgress(int count, int total) {
    return '$count / $total tampons';
  }

  @override
  String get loyaltyRewardAvailable =>
      '🎉 Récompense disponible ! Montrez ce code au salon.';

  @override
  String get loyaltyStampLogsTitle => 'Historique de vos tampons';

  @override
  String get loyaltyStampLogsLoadError =>
      'Impossible de charger l\'historique.';

  @override
  String get loyaltyStampLogsEmpty => 'Aucun tampon pour le moment.';

  @override
  String get loyaltyStampAdded => 'Tampon ajouté';

  @override
  String get loyaltyStampRewardValidated => 'Récompense validée';

  @override
  String get loyaltyShowQrButton => 'Afficher mon QR';

  @override
  String get journeyLaunchTitle => '🚀 Lancez votre salon';

  @override
  String get journeySalonReady => '🎉 Votre salon est prêt !';

  @override
  String get permissionsGroupsLoadError =>
      'Impossible de charger les groupes de permissions.';

  @override
  String get permissionsGroupEmptyTitle => 'Aucun groupe de permissions';

  @override
  String get permissionsGroupEmptySubtitle =>
      'Créez un groupe pour donner à un membre de votre équipe des droits précis, au-delà de son rôle de base.';

  @override
  String get permissionsGroupEmptyCtaLabel => 'Créer un groupe';

  @override
  String get permissionsGroupDetailLoadError =>
      'Impossible de charger ce groupe.';

  @override
  String get permissionsGroupNotFound => 'Groupe introuvable';

  @override
  String get permissionsGroupNotFoundSubtitle =>
      'Ce groupe a peut-être été supprimé.';

  @override
  String get permissionsGroupDefaultTitle => 'Groupe de permissions';

  @override
  String permissionsGroupDeleteConfirmMessage(String name) {
    return 'Les membres de \"$name\" perdront les permissions accordées par ce groupe.';
  }

  @override
  String get permissionsPermissionsTitle => 'Permissions';

  @override
  String get permissionsPermissionsLoadError =>
      'Impossible de charger les permissions.';

  @override
  String get permissionsMembersTitle => 'Membres';

  @override
  String get permissionsMembersEmpty =>
      'Aucun membre dans ce groupe pour le moment.';

  @override
  String get permissionsAddMemberTitle => 'Ajouter un membre';

  @override
  String get permissionsAddMemberAllInGroup =>
      'Toute l\'équipe fait déjà partie de ce groupe.';

  @override
  String get permissionsMemberFallback => 'Membre';

  @override
  String get permissionsGroupFormTitle => 'Nouveau groupe de permissions';

  @override
  String get permissionsGroupFormNameLabel => 'Nom du groupe';

  @override
  String get permissionsGroupFormDescriptionLabel => 'Description (optionnel)';

  @override
  String get permissionsGroupFormBaseRoleLabel => 'Rôle de base';

  @override
  String get permissionsGroupFormNameRequired => 'Nom requis';

  @override
  String get permissionsGroupFormCreateButton => 'Créer le groupe';

  @override
  String get loyaltyScanTitle => 'Scanner fidélité';

  @override
  String get loyaltyQrTitle => 'Mon QR fidélité';

  @override
  String get journeyProgressCloseButton => 'Fermer';

  @override
  String get journeyProgressContinueButton => 'Continuer la configuration →';

  @override
  String get referralClaimVerifying => 'Vérification de l\'invitation...';

  @override
  String get teamCommissionsTitle => 'Commissions';

  @override
  String get notificationsFilterAll => 'Tous';

  @override
  String get notificationsFilterBooking => 'RDV';

  @override
  String get notificationsFilterLoyalty => 'Fidélité';

  @override
  String get notificationsFilterMarketing => 'Marketing';

  @override
  String get notificationsFilterSystem => 'Système';

  @override
  String get notificationsSectionToday => 'Aujourd\'hui';

  @override
  String get notificationsSectionThisWeek => 'Cette semaine';

  @override
  String get notificationsSectionOlder => 'Plus ancien';

  @override
  String get notificationsMarkAllRead => 'Tout marquer lu';

  @override
  String get notificationsEmptyTitle => 'Aucune notification';

  @override
  String get notificationsEmptySubtitle =>
      'Revenez bientôt — vos alertes apparaîtront ici.';

  @override
  String get notificationsLoadErrorFeed =>
      'Impossible de charger vos notifications.';

  @override
  String notificationsDeletedSnack(String title) {
    return '« $title » supprimée.';
  }

  @override
  String get staffListEmptySubtitle =>
      'Invitez votre équipe pour commencer à organiser le planning, ou travaillez seul pour commencer.';

  @override
  String get staffCountActive => 'actifs';

  @override
  String get staffCountPending => 'en attente';

  @override
  String get staffCountDisabled => 'désactivés';

  @override
  String get staffNoMembersInCategory => 'Aucun membre dans cette catégorie.';

  @override
  String get staffDetailPerformanceMonth => 'Performance ce mois';

  @override
  String get staffDetailCommissionsMonth => 'Commissions ce mois';

  @override
  String get staffDetailServicesTitle => 'Services proposés';

  @override
  String get staffDetailLastBookings => 'Derniers RDV';

  @override
  String get staffDetailNoSpecialty => 'Aucune spécialité.';

  @override
  String get staffDetailNoBookings => 'Aucun RDV pour le moment.';

  @override
  String get staffDetailScheduleLabel => 'Horaires';

  @override
  String get staffDetailDeactivate => 'Désactiver';

  @override
  String get staffDetailReactivate => 'Réactiver';

  @override
  String get staffDetailDemote => 'Rétrograder en staff';

  @override
  String get staffDetailPromote => 'Promouvoir manager';

  @override
  String get staffDetailRemoveButton => 'Retirer du salon';

  @override
  String get staffDetailRemoveConfirmTitle => 'Retirer ce membre ?';

  @override
  String staffDetailRemoveConfirmMessage(String name) {
    return '$name ne pourra plus accéder à ce salon.';
  }

  @override
  String get staffDetailCommissionsEarned => 'Gagné';

  @override
  String get staffDetailCommissionsPaid => 'Payé';

  @override
  String get staffDetailCommissionsPending => 'En attente';

  @override
  String get staffFormDisplayNameLabel => 'Nom affiché';

  @override
  String get staffFormPhoneLabel => 'Téléphone';

  @override
  String get staffFormBioLabel => 'Bio';

  @override
  String get staffFormCommissionSectionTitle => 'Commission';

  @override
  String get staffFormCommissionTypeLabel => 'Type';

  @override
  String get staffFormCommissionTypePercent => '% du RDV';

  @override
  String get staffFormCommissionTypeFixed => 'FBu fixe';

  @override
  String get staffFormCommissionRatePercent => 'Taux (%)';

  @override
  String get staffFormCommissionRateFixed => 'Montant (FBu)';

  @override
  String get staffFormSaveButton => 'Enregistrer';

  @override
  String get staffFormRemoveButton => 'Retirer ce membre';

  @override
  String get acceptInvitationWelcome => 'Bienvenue dans l\'équipe !';

  @override
  String get acceptInvitationError =>
      'Invitation invalide ou expirée. Contactez votre salon pour en recevoir une nouvelle.';

  @override
  String get myPerfMyBookings => 'Mes RDV';

  @override
  String get myPerfMyRevenue => 'Mon CA';

  @override
  String myPerfRankText(int rank, String suffix, int teamSize) {
    return '$rank$suffix sur $teamSize cette semaine';
  }

  @override
  String get myPerfMonthTitle => 'Mes RDV ce mois';

  @override
  String get myPerfReviewsTitle => 'Mes avis récents';

  @override
  String get myPerfNoBookings => 'Aucun RDV terminé ce mois.';

  @override
  String get myPerfNoReviews => 'Aucun avis pour le moment.';

  @override
  String get myPerfCommissionsMonth => 'Mes commissions ce mois';

  @override
  String get myPerfCommissionsPaid => 'Payé';

  @override
  String get myPerfCommissionsPending => 'En attente';

  @override
  String get marketingFillMyDayTitle => 'Remplir ma journée';

  @override
  String get marketingFillMyDaySubtitle =>
      'Des créneaux libres aujourd\'hui ou demain ? Partagez une promotion à vos contacts personnels (max 2 par semaine).';

  @override
  String get marketingFillMyDayButton => 'Partager une promo →';

  @override
  String get marketingFillMyDayLimitReached =>
      'Limite de 2 promotions par semaine atteinte.';

  @override
  String get marketingRecentContactsTitle => 'Contacts récents';

  @override
  String get marketingNoContactsYet => 'Aucun contact pour le moment.';

  @override
  String get marketingManageButton => 'Gérer →';

  @override
  String get marketingNewBadge => 'Nouveau';

  @override
  String get marketingFreeBadge => 'Gratuit';

  @override
  String get marketingActiveBadge => 'Actif';

  @override
  String get marketingToConfigureBadge => 'À configurer';

  @override
  String get marketingExpiringSoonBadge => 'Expire bientôt';

  @override
  String get marketingShareServicesTitle => 'Partager mes services';

  @override
  String get marketingNoServicesToShare =>
      'Aucun service à partager pour le moment.';

  @override
  String get marketingSharePromotionTitle => 'Partager une promotion';

  @override
  String get marketingInviteLinkTitle => 'Lien d\'invitation personnalisé';

  @override
  String get marketingInviteLinkSubtitle =>
      'Partagez ce lien. Vos clients téléchargent KYNZA et vous retrouvent directement.';

  @override
  String get marketingInviteLinkGenError =>
      'Impossible de générer le lien pour l\'instant.';

  @override
  String get marketingCopyLinkButton => 'Copier le lien';

  @override
  String get marketingShareArrowButton => 'Partager →';

  @override
  String get marketingLinkCopied => 'Lien copié !';

  @override
  String get marketingLoadSalonError => 'Impossible de charger votre salon.';

  @override
  String get marketingImportFromBookingsButton => 'Importer depuis les RDV';

  @override
  String get marketingSearchContactHint => 'Rechercher un contact';

  @override
  String get marketingNoContactsTitle => 'Aucun contact encore';

  @override
  String get marketingNoContactsSubtitle => 'Ajoutez vos premiers clients.';

  @override
  String get marketingAddContactButton => 'Ajouter un contact';

  @override
  String get marketingImportNone => 'Aucun nouveau client à importer.';

  @override
  String marketingImportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients importés.',
      one: '1 client importé.',
    );
    return '$_temp0';
  }

  @override
  String get marketingNoInvitationsSentTitle => 'Aucune invitation envoyée';

  @override
  String get marketingNoInvitationsSentSubtitle =>
      'Partagez un lien de parrainage depuis vos contacts.';

  @override
  String marketingInviteSentOnDate(String date) {
    return 'Envoyée le $date';
  }

  @override
  String get marketingInviteAccepted => 'Acceptée';

  @override
  String get marketingInviteSent => 'Envoyée';

  @override
  String get marketingAddContactTitle => 'Ajouter un contact';

  @override
  String get marketingFullNameLabel => 'Nom complet *';

  @override
  String get marketingLoyaltyLoadError => 'Impossible de charger le programme.';

  @override
  String get marketingLoyaltyEmptyTitle => 'Fidélisez vos clients';

  @override
  String get marketingLoyaltyEmptySubtitle =>
      'Offrez des tampons à chaque visite. À la X ème visite, offrez une récompense.';

  @override
  String get marketingLoyaltySetupCta => 'Configurer mon programme';

  @override
  String get marketingLoyaltyStampsRequiredLabel => 'Tampons requis';

  @override
  String marketingLoyaltyStampsRequiredHint(int count) {
    return 'Après $count visites, votre client reçoit une récompense.';
  }

  @override
  String get marketingLoyaltyRewardDescriptionHint => 'ex: 1 coupe offerte';

  @override
  String get marketingLoyaltyRewardValueLabel => 'Valeur en FBu (optionnel)';

  @override
  String get marketingLoyaltyProgramActiveLabel => 'Programme actif';

  @override
  String get marketingLoyaltyCardPreviewTitle => 'Aperçu carte client';

  @override
  String get marketingLoyaltyStatsTitle => 'Statistiques';

  @override
  String get marketingLoyaltyTopClientsTitle => 'Clients les plus fidèles';

  @override
  String get marketingLoyaltyStatCardsLabel => 'Cartes';

  @override
  String marketingLoyaltyStampsCount(int count) {
    return '$count tampons';
  }

  @override
  String get marketingLoyaltyValidateButton => 'Valider';

  @override
  String get marketingLoyaltyValidateError => 'Échec de la validation.';

  @override
  String get marketingLoyaltySaveError => 'Échec de l\'enregistrement.';

  @override
  String marketingLoyaltyCardStampsRequired(int count) {
    return '$count tampons requis';
  }

  @override
  String marketingLoyaltyVisitsRemaining(int count) {
    return 'Plus que $count visites pour la récompense !';
  }

  @override
  String marketingLoyaltyRewardValidateConfirmMessage(String name, int count) {
    return '$name a atteint $count tampons. Ses tampons seront remis à zéro.';
  }

  @override
  String get promotionFormCreateTitle => 'Créer une promotion';

  @override
  String get promotionFormEditTitle => 'Modifier la promotion';

  @override
  String get promotionFormTitleLabel => 'Titre *';

  @override
  String get promotionFormDescriptionLabel => 'Description';

  @override
  String get promotionFormValuePercentLabel => 'Valeur (%) *';

  @override
  String get promotionFormValueBifLabel => 'Valeur (FBu) *';

  @override
  String get promotionFormTargetServiceLabel => 'Service ciblé (optionnel)';

  @override
  String get promotionFormAllServices => 'Tous les services';

  @override
  String promotionFormStartDate(String date) {
    return 'Début : $date';
  }

  @override
  String promotionFormEndDate(String date) {
    return 'Fin : $date';
  }

  @override
  String get promotionFormMaxUsesLabel =>
      'Nombre d\'utilisations max (optionnel)';

  @override
  String get promotionFormNoCode => 'Aucun code promo';

  @override
  String get promotionFormGenerateCodeButton => 'Générer un code';

  @override
  String get promotionFormCreateButton => 'Créer la promotion';

  @override
  String get promotionFormSaveError => 'Échec de l\'enregistrement.';

  @override
  String get promotionFormTitlePlaceholder => 'Titre de la promotion';

  @override
  String promotionCardServiceLabel(String name) {
    return 'Service : $name';
  }

  @override
  String get promotionCardShareButton => 'Partager';

  @override
  String get promotionCardEditButton => 'Modifier';

  @override
  String get promotionCardDeactivateButton => 'Désactiver';

  @override
  String get promotionDeactivateError => 'Échec de la désactivation.';

  @override
  String get searchResultsTitle => 'Recherche';

  @override
  String get searchSalonsSectionLabel => 'Salons';

  @override
  String get searchServicesSectionLabel => 'Services';

  @override
  String get searchRecentLabel => 'Recherches récentes';

  @override
  String get searchClearButton => 'Effacer';

  @override
  String get searchPopularLabel => 'Recherches populaires';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String get searchNoResultsSubtitle =>
      'Essayez une autre recherche ou filtre.';

  @override
  String get searchLoadError => 'Impossible de lancer la recherche.';

  @override
  String get searchFiltersTitle => 'Filtres';

  @override
  String searchFiltersPriceLabel(String min, String max) {
    return 'Prix (FBu) — $min à $max';
  }

  @override
  String get searchFiltersMinRatingLabel => 'Note minimum';

  @override
  String get searchFiltersCategoriesLabel => 'Catégories';

  @override
  String get searchFiltersProvinceLabel => 'Province';

  @override
  String get searchFiltersAllProvinces => 'Toutes les provinces';

  @override
  String get searchFiltersSortByLabel => 'Trier par';

  @override
  String get searchFiltersApplyButton => 'Appliquer';

  @override
  String get searchSortRelevance => 'Pertinence';

  @override
  String get searchSortPriceAsc => 'Prix ↑';

  @override
  String get searchSortPriceDesc => 'Prix ↓';

  @override
  String get searchSortRating => 'Note';

  @override
  String get billingCurrentPlanLabel => 'Plan actuel';

  @override
  String get billingCurrentPeriodLabel => 'Période en cours';

  @override
  String get billingPaymentMethodManual =>
      'Méthode de paiement : Manuelle (virement bancaire)';

  @override
  String billingNextBillingLabel(String date) {
    return 'Prochaine facturation : $date';
  }

  @override
  String get billingManageSubscriptionButton => 'Gérer mon abonnement';

  @override
  String get billingInvoiceHistoryButton => 'Historique des factures';

  @override
  String billingCurrentMonthUsage(int used, int max) {
    return '$used / $max RDV ce mois';
  }

  @override
  String get billingCurrentPlanBadgeFree => 'PLAN GRATUIT';

  @override
  String billingCurrentPlanBadge(String plan) {
    return 'PLAN $plan';
  }

  @override
  String get billingPlanCurrentLabel => 'Plan actuel';

  @override
  String billingPlanUpgradeLabel(String name) {
    return 'Passer à $name →';
  }

  @override
  String get billingPlanDowngradeLabel => 'Rétrograder';

  @override
  String billingUpgradeRequestTitle(String name) {
    return 'Vous demandez une mise à niveau vers $name.';
  }

  @override
  String get billingUpgradeRequestSubtitle =>
      'Notre équipe vous contactera pour le paiement.';

  @override
  String get billingUpgradeConfirmButton => 'Confirmer la demande';

  @override
  String get billingUpgradeSentTitle => 'Demande envoyée ! 🎉';

  @override
  String billingUpgradeReferenceLabel(String ref) {
    return 'Référence à inclure : $ref';
  }

  @override
  String get billingUpgradeShareButton => 'Partager les instructions';

  @override
  String get billingUpgradeDoneButton => 'Terminer';

  @override
  String get billingUpgradeReferenceCopied => 'Référence copiée !';

  @override
  String get billingInvoicesLoadError => 'Impossible de charger les factures.';

  @override
  String get billingInvoicesEmptyTitle => 'Aucune facture';

  @override
  String get billingInvoicesEmptySubtitle =>
      'Vos factures apparaîtront ici après une demande de mise à niveau.';

  @override
  String get billingInvoiceStatusPaid => 'PAYÉE';

  @override
  String get billingInvoiceStatusOverdue => 'EN RETARD';

  @override
  String get billingInvoiceStatusVoid => 'ANNULÉE';

  @override
  String get billingInvoiceStatusPending => 'EN ATTENTE';

  @override
  String get billingInvoicePaymentInstructionsTitle =>
      'Instructions de paiement';

  @override
  String get billingInvoiceExportPdfButton => 'Exporter facture PDF';

  @override
  String get billingInvoiceShareButton => 'Partager la facture';

  @override
  String get billingInvoiceMarkPaidButton => 'Marquer comme payé';

  @override
  String get upgradeSuccessTitle => 'Demande envoyée ! 🎉';

  @override
  String get upgradeSuccessSubtitle =>
      'Notre équipe va vous contacter sous 24h pour finaliser votre mise à niveau.';

  @override
  String get upgradeSuccessNote =>
      'En attendant, vous pouvez continuer à utiliser KYNZA.';

  @override
  String get upgradeSuccessBackButton => 'Retour au dashboard';

  @override
  String get salonMediaDeleteTitle => 'Supprimer ce média ?';

  @override
  String get salonMediaDeleteMessage =>
      'Cette action retire le média de votre galerie.';

  @override
  String get dashboardTrendStable => '→ Stable';

  @override
  String get dashboardTrendGrowing => '↑ En croissance';

  @override
  String get dashboardTrendDecreasing => '↓ En baisse';

  @override
  String get dashboardBestWeekdayNone => 'Meilleur jour : —';

  @override
  String dashboardBestWeekday(String day) {
    return 'Meilleur jour : $day';
  }

  @override
  String get dashboardPeakHourNone => 'Heure de pointe : —';

  @override
  String dashboardPeakHour(int hour) {
    return 'Heure de pointe : ${hour}h';
  }

  @override
  String get auditEventUserLogin => 'Connexion';

  @override
  String get auditEventUserLogout => 'Déconnexion';

  @override
  String get auditEventProfileUpdated => 'Profil mis à jour';

  @override
  String get auditEventRoleChanged => 'Rôle modifié';

  @override
  String get auditEventSalonUpdated => 'Salon mis à jour';

  @override
  String get auditEventSalonStatusChanged => 'Statut du salon modifié';

  @override
  String get auditEventStaffInvited => 'Invitation envoyée';

  @override
  String get auditEventStaffInvitationAccepted => 'Invitation acceptée';

  @override
  String get auditEventStaffRemoved => 'Membre retiré';

  @override
  String get auditEventStaffJoined => 'Nouveau membre dans l\'équipe';

  @override
  String get auditEventBookingCreated => 'Réservation créée';

  @override
  String get auditEventBookingConfirmed => 'Réservation confirmée';

  @override
  String get auditEventBookingCancelled => 'Réservation annulée';

  @override
  String get auditEventBookingCompleted => 'Réservation terminée';

  @override
  String get auditEventBookingNoShow => 'Client absent (no-show)';

  @override
  String get auditEventPaymentCompleted => 'Paiement réussi';

  @override
  String get auditEventPaymentFailed => 'Paiement échoué';

  @override
  String get auditEventRefundInitiated => 'Remboursement initié';

  @override
  String get auditEventDiscountApplied => 'Réduction appliquée';

  @override
  String get auditEventLoyaltyStampAdded => 'Tampon fidélité ajouté';

  @override
  String get auditEventLoyaltyRewardRedeemed => 'Récompense fidélité validée';

  @override
  String get auditEventReferralClaimed => 'Parrainage utilisé';

  @override
  String get auditEventPermissionGroupCreated => 'Groupe de permissions créé';

  @override
  String get auditEventPermissionGroupDeleted =>
      'Groupe de permissions supprimé';

  @override
  String get auditEventPermissionGroupPermissionChanged =>
      'Permission modifiée';

  @override
  String get auditEventPermissionGroupMemberAdded =>
      'Membre ajouté à un groupe';

  @override
  String get auditEventPermissionGroupMemberRemoved =>
      'Membre retiré d\'un groupe';

  @override
  String promotionCardUsagesLabel(int uses) {
    return '$uses utilisation(s)';
  }

  @override
  String promotionCardUsagesMaxLabel(int uses, int max) {
    return '$uses / $max utilisation(s)';
  }

  @override
  String promotionCardUntilDate(String date) {
    return '· jusqu\'au $date';
  }

  @override
  String get contactSourceBooking => 'RDV';

  @override
  String get contactSourceReferral => 'Parrainage';

  @override
  String get contactSourceManual => 'Manuel';

  @override
  String get billingPlanNameFree => 'Gratuit';

  @override
  String get billingPlanNamePro => 'Pro';

  @override
  String get billingPlanNamePremium => 'Premium';

  @override
  String get marketingClientsImportError => 'Échec de l\'import.';

  @override
  String get marketingContactAddError => 'Échec de l\'ajout.';

  @override
  String get commissionLoadError => 'Impossible de charger les commissions.';

  @override
  String get commissionEmptyTitle => 'Aucune commission ce mois';

  @override
  String get commissionEmptySubtitle =>
      'Les commissions apparaîtront après les RDV terminés.';

  @override
  String get commissionMarkAllPaid => 'Tout marquer payé';

  @override
  String get commissionStaffFallback => 'Staff';

  @override
  String get commissionBadgePaid => 'PAYÉ';

  @override
  String get commissionBadgePending => 'EN ATTENTE';

  @override
  String get referralWelcomeTitle => 'Bienvenue sur KYNZA ! 🎉';

  @override
  String get referralStampGranted =>
      'Un tampon de fidélité vous a été offert !';

  @override
  String referralStampGrantedWithSalon(String salon) {
    return 'Un tampon de fidélité chez $salon vous a été offert !';
  }

  @override
  String get referralInvalidLink =>
      'Lien d\'invitation invalide ou déjà utilisé.';

  @override
  String get automationLogEmptyTitle => 'Aucune exécution';

  @override
  String get automationLogEmptySubtitle =>
      'Les exécutions de workflow apparaîtront ici dès qu\'un déclencheur se produira.';

  @override
  String get automationLogLoadDetailError => 'Impossible de charger le détail.';

  @override
  String get automationLogLoadError => 'Impossible de charger l\'historique.';

  @override
  String get automationLogHistoryTitle => 'Historique d\'exécution';

  @override
  String get dataPlatformDocumentTemplatesTitle => 'Modèles de documents';

  @override
  String get dataPlatformTemplateTypeInvoice => 'Facture';

  @override
  String get dataPlatformTemplateTypeReceipt => 'Reçu';

  @override
  String get dataPlatformTemplateTypeMonthlyReport => 'Rapport mensuel';

  @override
  String get dataPlatformTemplateLoadError =>
      'Impossible de charger les modèles.';

  @override
  String get dataPlatformTemplateEmptyTitle => 'Aucun modèle';

  @override
  String get dataPlatformTemplateEmptySubtitle =>
      'Créez des modèles personnalisés pour vos factures, reçus et rapports.';

  @override
  String get dataPlatformTemplateCreateCta => 'Créer un modèle';

  @override
  String get dataPlatformTemplateDeleteTitle => 'Supprimer le modèle';

  @override
  String dataPlatformTemplateDeleteConfirm(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get dataPlatformTemplateDeleteSuccess => 'Modèle supprimé.';

  @override
  String get dataPlatformTemplateDeleteError =>
      'Impossible de supprimer ce modèle.';

  @override
  String get dataPlatformTemplateBadgeDefault => 'DÉFAUT';

  @override
  String get dataPlatformTemplateValidationError =>
      'Le nom et le contenu sont requis.';

  @override
  String get dataPlatformTemplateEditTitle => 'Modifier le modèle';

  @override
  String get dataPlatformTemplateNewTitle => 'Nouveau modèle';

  @override
  String get dataPlatformTemplateNameLabel => 'Nom du modèle';

  @override
  String get dataPlatformTemplateTypeLabel => 'Type';

  @override
  String get dataPlatformTemplateVariablesTitle => 'Variables disponibles';

  @override
  String get dataPlatformTemplateBodyLabel => 'Contenu du modèle';

  @override
  String get dataPlatformTemplateBodyHint =>
      'Utilisez le format variable pour insérer des données dynamiques.';

  @override
  String get dataPlatformTemplateIsDefaultLabel => 'Modèle par défaut';

  @override
  String get dataPlatformTemplateSaveButton => 'Enregistrer';

  @override
  String get dataPlatformTemplateCreateButton => 'Créer le modèle';

  @override
  String get dataPlatformBackupTitle => 'Sauvegardes de données';

  @override
  String get dataPlatformBackupLoadError =>
      'Impossible de charger les sauvegardes.';

  @override
  String get dataPlatformBackupEmptyTitle => 'Aucune sauvegarde';

  @override
  String get dataPlatformBackupEmptySubtitle =>
      'Créez votre première sauvegarde pour archiver vos données.';

  @override
  String get dataPlatformBackupCreateCta => 'Créer une sauvegarde';

  @override
  String get dataPlatformBackupDialogTitle => 'Créer une sauvegarde';

  @override
  String get dataPlatformBackupDialogContent =>
      'Les données des 90 derniers jours (réservations, clients, prestations, personnel, avis, factures) seront exportées et stockées de manière sécurisée.';

  @override
  String get dataPlatformBackupCreateSuccess => 'Sauvegarde créée avec succès.';

  @override
  String get dataPlatformBackupSecureTitle => 'Sauvegarde sécurisée';

  @override
  String get dataPlatformBackupSecureSubtitle =>
      'Exportez vos données dans un fichier JSON chiffré stocké sur nos serveurs. Une sauvegarde maximum toutes les 6 heures.';

  @override
  String get dataPlatformBackupCreateButton => 'Créer une sauvegarde';

  @override
  String get settingFieldBookingAdvanceDays =>
      'Délai de réservation max (jours)';

  @override
  String get settingFieldBookingSlotDuration => 'Durée des créneaux (minutes)';

  @override
  String get settingFieldBookingCancellationHours =>
      'Délai d\'annulation (heures)';

  @override
  String get settingFieldBookingRequiresConfirmation => 'Confirmation requise';

  @override
  String get settingFieldBookingAllowWalkin => 'Autoriser les walk-ins';

  @override
  String get settingFieldBookingMaxPerClientPerDay =>
      'Max RDV par client / jour';

  @override
  String get settingFieldNotifSmsEnabled => 'SMS activés';

  @override
  String get settingFieldNotifWhatsappEnabled => 'WhatsApp activé';

  @override
  String get settingFieldNotifPushEnabled => 'Notifications push activées';

  @override
  String get settingFieldNotifReminderHoursBefore =>
      'Premier rappel avant RDV (heures)';

  @override
  String get settingFieldNotifReminderHoursBefore2 =>
      'Second rappel avant RDV (heures)';

  @override
  String get settingFieldMarketingAutoReviewRequest =>
      'Demande d\'avis automatique';

  @override
  String get settingFieldMarketingReviewRequestHoursAfter =>
      'Demande d\'avis après le RDV (heures)';

  @override
  String get settingFieldMarketingLoyaltyAutoStamp =>
      'Tampon fidélité automatique';

  @override
  String get settingFieldMarketingReferralBonusBif =>
      'Bonus de parrainage (FBu)';

  @override
  String get settingFieldStaffShowEarnings => 'Afficher les revenus au staff';

  @override
  String get settingFieldStaffCommissionAutoCalculate =>
      'Calcul automatique des commissions';

  @override
  String get settingFieldStaffRequireCheckin => 'Check-in requis';

  @override
  String get settingFieldLoyaltyStampsPerCard => 'Tampons par carte';

  @override
  String get settingFieldLoyaltyRewardDescription =>
      'Description de la récompense';

  @override
  String get settingFieldLoyaltyExpiryDays => 'Expiration (jours)';

  @override
  String get settingFieldReviewsAutoPublish => 'Publication automatique';

  @override
  String get settingFieldReviewsModerationEnabled => 'Modération activée';

  @override
  String get settingFieldReviewsMinRatingAlert => 'Alerte si note ≤';

  @override
  String get settingFieldPaymentGracePeriodMinutes =>
      'Délai de grâce (minutes)';

  @override
  String get settingFieldPaymentAutoInvoice => 'Facturation automatique';

  @override
  String get settingFieldTimezone => 'Fuseau horaire';

  @override
  String get settingFieldAdvancedDoubleBooking => 'Autoriser le double-booking';

  @override
  String get settingFieldAdvancedOverbookingLimit => 'Limite de surbooking';

  @override
  String get staffRoleManager => 'Manager';

  @override
  String get staffRoleStaff => 'Staff';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get commonMonthJanuary => 'Janvier';

  @override
  String get commonMonthFebruary => 'Février';

  @override
  String get commonMonthMarch => 'Mars';

  @override
  String get commonMonthApril => 'Avril';

  @override
  String get commonMonthMay => 'Mai';

  @override
  String get commonMonthJune => 'Juin';

  @override
  String get commonMonthJuly => 'Juillet';

  @override
  String get commonMonthAugust => 'Août';

  @override
  String get commonMonthSeptember => 'Septembre';

  @override
  String get commonMonthOctober => 'Octobre';

  @override
  String get commonMonthNovember => 'Novembre';

  @override
  String get commonMonthDecember => 'Décembre';

  @override
  String get homeClientCannotLoadSalons => 'Impossible de charger les salons.';

  @override
  String get homeClientDiscoverTitle => 'Découvrez les salons';

  @override
  String get homeClientNoSalonsSubtitle =>
      'Aucun salon disponible pour le moment.';

  @override
  String get homeClientSalonsNearYou => 'Salons près de vous';

  @override
  String get homeClientBookNextBeautyAppt =>
      'Réservez votre prochain rendez-vous beauté.';

  @override
  String get homeStaffProfileNotLinked => 'Profil non lié';

  @override
  String get homeStaffProfileNotLinkedSubtitle =>
      'Votre compte n\'est pas encore associé à une équipe. Demandez une invitation à votre Owner.';

  @override
  String get homeStaffNoApptTodayTitle => 'Aucun RDV aujourd\'hui';

  @override
  String get homeStaffFreeDay => 'Profitez de votre journée libre !';

  @override
  String get homeStaffLaterToday => 'Plus tard aujourd\'hui';

  @override
  String get homeStaffNothingScheduled => 'Rien de prévu pour cette date.';

  @override
  String get homeStaffNextAppointment => 'Prochain rendez-vous';

  @override
  String get homeManagerDashboardBody => 'Phase 2 — Booking Engine arrive ici';

  @override
  String get homeManagerDashboardCta => 'Aperçu des fonctionnalités →';

  @override
  String get bookingLeaveReview => 'Laisser un avis';

  @override
  String get bookingReceiptTitle => 'Reçu';

  @override
  String get bookingReceiptSalon => 'Salon';

  @override
  String get bookingReceiptService => 'Service';

  @override
  String get bookingReceiptDate => 'Date';

  @override
  String get bookingReceiptTime => 'Heure';

  @override
  String get bookingLastSlot => 'Dernière place !';

  @override
  String get bookingTotal => 'Total';

  @override
  String get bookingDetailCompleteAndCollect => 'Terminer + encaisser';

  @override
  String get bookingDetailMarkAbsent => 'Marquer absent';

  @override
  String get bookingDetailMarkAbsentGrace => 'Marquer absent (dès +15 min)';

  @override
  String get bookingDetailCancelButton => 'Annuler ce RDV';

  @override
  String dataPlatformBackupRecordsExported(int count) {
    return '$count enregistrements';
  }

  @override
  String get commonOrdinalSuffixFirst => 'er';

  @override
  String get commonOrdinalSuffixOther => 'ème';

  @override
  String get paymentRadarWaitMessage =>
      'Votre demande est envoyée. Attendez le message sur votre téléphone.';

  @override
  String get legalCenterTitle => 'Centre légal';

  @override
  String get legalCenterLoadError =>
      'Impossible de charger les documents légaux.';

  @override
  String get legalCenterEmptyTitle => 'Aucun document disponible';

  @override
  String get legalCenterEmptySubtitle =>
      'Revenez plus tard, nos documents légaux sont en cours de publication.';

  @override
  String get legalDocTypePrivacyPolicy => 'Politique de confidentialité';

  @override
  String get legalDocTypeTermsOfService => 'Conditions d\'utilisation';

  @override
  String get legalDocTypeCookiePolicy => 'Politique de cookies';

  @override
  String get legalDocTypeAcceptableUsePolicy =>
      'Politique d\'utilisation acceptable';

  @override
  String get legalDocTypeRefundPolicy => 'Politique de remboursement';

  @override
  String get legalDocTypeCommunityGuidelines => 'Règles de la communauté';

  @override
  String get legalDocTypeDataDeletionPolicy =>
      'Politique de suppression des données';

  @override
  String get legalDocTypeSupportPolicy => 'Politique d\'assistance';

  @override
  String get legalDocTypeLegalNotices => 'Mentions légales';

  @override
  String get policyViewerLoadError => 'Impossible de charger ce document.';

  @override
  String get policyViewerHistoryLink => 'Voir l\'historique des versions';

  @override
  String get policyViewerAcceptButton => 'J\'accepte';

  @override
  String get policyViewerAcceptedLabel => 'Déjà accepté';

  @override
  String get policyViewerAcceptedOfflineLabel =>
      'Acceptation enregistrée hors ligne — sera synchronisée';

  @override
  String get policyVersionHistoryTitle => 'Historique des versions';

  @override
  String get policyVersionHistoryLoadError =>
      'Impossible de charger l\'historique.';

  @override
  String get policyVersionHistoryEmptyTitle => 'Aucune version publiée';

  @override
  String get policyVersionHistoryEmptySubtitle =>
      'Ce document n\'a pas encore de version publiée.';

  @override
  String get policyVersionHistoryCurrentBadge => 'Version actuelle';

  @override
  String get acceptanceHistoryTitle => 'Mes acceptations';

  @override
  String get acceptanceHistoryLoadError =>
      'Impossible de charger votre historique d\'acceptation.';

  @override
  String get acceptanceHistoryEmptyTitle => 'Aucune acceptation enregistrée';

  @override
  String get acceptanceHistoryEmptySubtitle =>
      'Les documents que vous acceptez apparaîtront ici.';

  @override
  String get consentManagementTitle => 'Gestion du consentement';

  @override
  String get consentManagementLoadError =>
      'Impossible de charger vos préférences de consentement.';

  @override
  String get consentTypeMarketingEmailsLabel => 'E-mails marketing';

  @override
  String get consentTypeMarketingEmailsSubtitle =>
      'Recevez nos offres et actualités par e-mail.';

  @override
  String get consentTypeAnalyticsLabel => 'Analyse d\'utilisation';

  @override
  String get consentTypeAnalyticsSubtitle =>
      'Nous aider à améliorer KYNZA en partageant des données d\'usage anonymisées.';

  @override
  String get consentTypePushNotificationsLabel => 'Notifications push';

  @override
  String get consentTypePushNotificationsSubtitle =>
      'Recevez des rappels et alertes sur votre appareil.';

  @override
  String get consentTypeDataProcessingLabel =>
      'Traitement des données personnelles';

  @override
  String get consentTypeDataProcessingSubtitle =>
      'Autoriser le traitement de vos données pour le fonctionnement du service.';

  @override
  String get dataRightsTitle => 'Mes données';

  @override
  String get dataRightsExportSectionTitle => 'Exporter mes données';

  @override
  String get dataRightsExportDescription =>
      'Recevez une copie de vos données personnelles KYNZA.';

  @override
  String get dataRightsExportButton => 'Demander un export';

  @override
  String get dataRightsDeletionSectionTitle => 'Supprimer mon compte';

  @override
  String get dataRightsDeletionDescription =>
      'Demandez la suppression définitive de votre compte et de vos données.';

  @override
  String get dataRightsDeletionButton => 'Demander la suppression';

  @override
  String get dataRightsDeletionConfirmTitle => 'Confirmer la demande';

  @override
  String get dataRightsDeletionConfirmMessage =>
      'Cette action déclenche une demande de suppression de votre compte, traitée par notre équipe. Voulez-vous continuer ?';

  @override
  String get dataRightsRequestSubmitted => 'Votre demande a été envoyée.';

  @override
  String get dataRightsRequestsLoadError =>
      'Impossible de charger vos demandes.';

  @override
  String get dataRightsRequestsEmptyTitle => 'Aucune demande en cours';

  @override
  String get dataRightsRequestsEmptySubtitle =>
      'Vos demandes de suppression de données apparaîtront ici.';

  @override
  String get dataRightsRequestStatusPending => 'En attente';

  @override
  String get dataRightsRequestStatusInReview => 'En cours d\'examen';

  @override
  String get dataRightsRequestStatusCompleted => 'Terminée';

  @override
  String get dataRightsRequestStatusRejected => 'Refusée';

  @override
  String get supportContactTitle => 'Nous contacter';

  @override
  String get supportContactDescription =>
      'Une question ou un problème ? Notre équipe vous répond.';

  @override
  String get supportContactEmailLabel => 'E-mail';

  @override
  String get supportContactPolicyLink => 'Consulter la politique d\'assistance';

  @override
  String get policyUpdateBannerMessage =>
      'Un document légal a été mis à jour. Veuillez le consulter.';

  @override
  String get policyUpdateBannerCta => 'Consulter';
}
