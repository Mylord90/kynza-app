// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'KYNZA';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonShare => 'Share';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonNext => 'Next';

  @override
  String get commonPrevious => 'Previous';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonSend => 'Send';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonToday => 'Today';

  @override
  String get commonError => 'Error';

  @override
  String get commonSelect => 'Select';

  @override
  String get commonEnable => 'Enable';

  @override
  String get commonDisable => 'Disable';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonExport => 'Export';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied!';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorOffline => 'You are offline.';

  @override
  String get errorNetwork => 'Check your internet connection.';

  @override
  String get errorUnauthorized => 'Session expired, please sign in again.';

  @override
  String get errorLoadFailed => 'Unable to load data.';

  @override
  String get emptyStateDefaultTitle => 'Nothing to show';

  @override
  String get offlineBannerMessage => '📴 Offline • Cached data';

  @override
  String get offlineBannerSynced => '✓ Synced';

  @override
  String get navHome => 'Home';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navClients => 'Clients';

  @override
  String get navMarketing => 'Marketing';

  @override
  String get navProfile => 'Profile';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navSettings => 'Settings';

  @override
  String get navExplorer => 'Explore';

  @override
  String get navMyBookings => 'My Bookings';

  @override
  String get navLoyalty => 'Loyalty';

  @override
  String get navToday => 'Today';

  @override
  String get navPerformance => 'Performance';

  @override
  String get navTeam => 'Team';

  @override
  String get authLogin => 'Sign in';

  @override
  String get authLogout => 'Sign out';

  @override
  String get authRegister => 'Create account';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authLoginTitle => 'Welcome back';

  @override
  String get authLoginSubtitle => 'Sign in to continue';

  @override
  String get authLoginEmailLabel => 'Email';

  @override
  String get authLoginPasswordLabel => 'Password';

  @override
  String get authLoginSubmitButton => 'Sign in →';

  @override
  String get authLoginForgotPasswordLink => 'Forgot password?';

  @override
  String get authLoginNoAccountLink => 'Don\'t have an account? Sign up';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubtitle => 'Join KYNZA in seconds';

  @override
  String get authRegisterFullNameLabel => 'Full name';

  @override
  String get authRegisterEmailLabel => 'Email';

  @override
  String get authRegisterConfirmPasswordLabel => 'Confirm password';

  @override
  String get authRegisterSubmitButton => 'Create my account →';

  @override
  String get authRegisterAlreadyHaveAccountLink =>
      'Already have an account? Sign in';

  @override
  String get authForgotPasswordTitle => 'Forgot password';

  @override
  String get authForgotPasswordSubtitle => 'Get a password reset link by email';

  @override
  String get authForgotPasswordEmailLabel => 'Email';

  @override
  String get authForgotPasswordSubmitButton => 'Send link →';

  @override
  String get authForgotPasswordBackLink => '← Back to sign in';

  @override
  String get authForgotPasswordSuccessTitle => 'Email sent!';

  @override
  String authForgotPasswordSuccessSubtitle(String email) {
    return 'If an account exists for $email, you\'ll receive a reset link shortly.';
  }

  @override
  String get authForgotPasswordCheckSpam => 'Check your spam folder.';

  @override
  String get authVerifyEmailTitle => 'Verify your email';

  @override
  String authVerifyEmailSubtitle(String email) {
    return 'A confirmation link was sent to $email';
  }

  @override
  String get authVerifyEmailCheckSpam => 'Check your spam folder.';

  @override
  String get authVerifyEmailResendButton => 'Resend email';

  @override
  String authVerifyEmailResendCooldown(String seconds) {
    return 'Resend email (00:$seconds)';
  }

  @override
  String get authVerifyEmailChangeAddress => 'Use a different address';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authResetPasswordNewLabel => 'New password';

  @override
  String get authResetPasswordConfirmLabel => 'Confirm password';

  @override
  String get authResetPasswordSubmitButton => 'Reset →';

  @override
  String get authResetPasswordSuccess => 'Password reset successfully.';

  @override
  String get authResetPasswordInvalidLink => 'Invalid or expired link.';

  @override
  String get authCompleteProfileTitle => 'Complete your profile';

  @override
  String get authCompleteProfileSubtitle => 'A few details to get started';

  @override
  String get authCompleteProfileFullNameLabel => 'Full name';

  @override
  String get authCompleteProfileSubmitButton => 'Get started →';

  @override
  String get authCompleteProfileRoleClientLabel => 'Client';

  @override
  String get authCompleteProfileRoleClientSubtitle => 'Book treatments';

  @override
  String get authCompleteProfileRoleStaffLabel => 'Staff';

  @override
  String get authCompleteProfileRoleStaffSubtitle => 'Practitioner in a salon';

  @override
  String get authCompleteProfileRoleOwnerLabel => 'Owner';

  @override
  String get authCompleteProfileRoleOwnerSubtitle => 'Manage your salon';

  @override
  String get authOauthComingSoon => 'Coming soon';

  @override
  String get authOauthGoogleLabel => 'Continue with Google';

  @override
  String get authOauthFacebookLabel => 'Continue with Facebook';

  @override
  String get authOauthAppleLabel => 'Continue with Apple';

  @override
  String get authDividerLabel => 'or continue with';

  @override
  String get validatorEmailRequired => 'Email required.';

  @override
  String get validatorEmailInvalid => 'Invalid email.';

  @override
  String get validatorPasswordRequired => 'Password required.';

  @override
  String get validatorPasswordMinLength => 'Minimum 8 characters.';

  @override
  String get validatorPasswordNeedUppercase => 'At least 1 uppercase letter.';

  @override
  String get validatorPasswordNeedDigit => 'At least 1 digit.';

  @override
  String get validatorPhoneRequired => 'Phone number required.';

  @override
  String get validatorPhoneInvalid => 'Invalid number (8 digits).';

  @override
  String validatorFieldRequired(String field) {
    return '$field required.';
  }

  @override
  String get validatorConfirmPasswordRequired => 'Confirmation required.';

  @override
  String get validatorPasswordMismatch => 'Passwords don\'t match.';

  @override
  String get fieldPhoneLabel => 'Phone number';

  @override
  String get fieldPhoneHelper => 'For WhatsApp notifications only.';

  @override
  String get fieldPasswordLabel => 'Password';

  @override
  String get homeOwnerDashboardTitle => 'KYNZA Dashboard';

  @override
  String get homeOwnerScanLoyaltyTooltip => 'Scan loyalty';

  @override
  String get homeOwnerConfidentialModeTooltip => 'Hide/show amounts';

  @override
  String get homeOwnerShareTooltip => 'Share my salon';

  @override
  String get homeOwnerNoSalonTitle => 'Create your salon';

  @override
  String get homeOwnerNoSalonSubtitle =>
      'Set up your salon to start receiving bookings.';

  @override
  String get homeOwnerNoSalonCta => 'Create my salon →';

  @override
  String get homeOwnerCalendarError => 'Unable to load schedule.';

  @override
  String get homeOwnerCalendarEmptyTitle => 'No appointments today';

  @override
  String get homeOwnerCalendarEmptySubtitle => 'Your schedule is free.';

  @override
  String get homeOwnerCalendarEmptyCta => 'Today';

  @override
  String get homeOwnerClientsError => 'Unable to load clients.';

  @override
  String get homeOwnerClientsEmptyTitle => 'No clients yet';

  @override
  String get homeOwnerClientsEmptySubtitle =>
      'Your clients will appear here after their first booking.';

  @override
  String get homeOwnerClientFallbackName => 'Client';

  @override
  String homeOwnerClientRdvCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appointments',
      one: '1 appointment',
      zero: 'No appointments',
    );
    return '$_temp0';
  }

  @override
  String get homeOwnerProfileMyReviews => 'My Reviews';

  @override
  String get homeOwnerProfileActivityLog => 'Activity log';

  @override
  String get homeOwnerProfileSettings => 'Settings';

  @override
  String get homeOwnerProfileSubscription => 'Subscription & Billing';

  @override
  String get homeOwnerProfileLanguage => 'Language';

  @override
  String get homeOwnerBookingCancelConfirmTitle => 'Cancel this appointment?';

  @override
  String get homeOwnerBookingCancelConfirmMessage =>
      'The client will be notified and refunded if applicable.';

  @override
  String get homeOwnerBookingCancelConfirmButton => 'Cancel';

  @override
  String get homeManagerDashboardTitle => 'Manager Dashboard';

  @override
  String get homeStaffScanLoyaltyTooltip => 'Scan loyalty';

  @override
  String get homeStaffAvailabilityTooltip => 'My availability';

  @override
  String get homeStaffConfirmArrivalButton => 'Confirm arrival';

  @override
  String homeClientGreeting(String firstName) {
    return 'Hello $firstName 👋';
  }

  @override
  String get homeClientNavExplorer => 'Explore';

  @override
  String get homeClientNavMyBookings => 'My Bookings';

  @override
  String get homeClientNavMyLoyalties => 'My Loyalty';

  @override
  String get homeClientProfileSeeAllBookings => 'See all my bookings →';

  @override
  String get homeClientProfileSeeAllPrograms => 'See my programs →';

  @override
  String get homeClientProfileSeeAllReviews => 'See my reviews →';

  @override
  String get homeClientProfilePhoneLabel => 'Phone';

  @override
  String get homeClientProfileInviteFriend => 'Invite a friend';

  @override
  String get homeClientProfileLogoutTitle => 'Sign out';

  @override
  String get homeClientProfileLogoutMessage => 'Are you sure?';

  @override
  String get homeClientProfileLogoutButton => 'Sign out';

  @override
  String get homeClientProfileUpdateError => 'Unable to update your profile.';

  @override
  String get homeClientProfileAvatarUploadError => 'Failed to upload photo.';

  @override
  String get homeClientProfileInfoTitle => 'My information';

  @override
  String get homeClientProfileNoPhone => 'No phone number';

  @override
  String get homeClientProfileNoEmail => 'No email';

  @override
  String get homeClientProfileRecentBookingsTitle => 'Recent appointments';

  @override
  String get homeClientProfileNoBookings => 'No appointments yet.';

  @override
  String get homeClientProfileLoyaltiesTitle => 'My loyalty';

  @override
  String get homeClientProfileNoLoyalty =>
      'Book an appointment to start a loyalty card.';

  @override
  String get homeClientProfileReviewsTitle => 'My reviews';

  @override
  String homeClientProfileReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I left $count reviews.',
      one: 'I left 1 review.',
      zero: 'No reviews',
    );
    return '$_temp0';
  }

  @override
  String get homeClientProfileReviewsLoadError =>
      'Unable to load your reviews.';

  @override
  String get homeClientProfileNoReviews => 'You haven\'t left any reviews yet.';

  @override
  String get homeClientProfileEditTitle => 'Edit my information';

  @override
  String get bookingSelectServiceTitle => 'Choose a service';

  @override
  String get bookingSelectServiceEmptyTitle => 'No services available';

  @override
  String get bookingSelectServiceEmptySubtitle =>
      'This salon has not published any services yet.';

  @override
  String get bookingNoSalonSelected => 'No salon selected.';

  @override
  String get bookingSelectPractitionerTitle => 'Choose a practitioner';

  @override
  String get bookingPractitionerLoadError => 'Unable to load team.';

  @override
  String get bookingSelectDateTitle => 'Choose a date';

  @override
  String get bookingSelectTimeTitle => 'Choose a time';

  @override
  String get bookingTimeLoadError => 'Unable to load time slots.';

  @override
  String get bookingSelectTimeEmptyTitle => 'No time slots available';

  @override
  String get bookingSelectTimeEmptySubtitle => 'Try another date.';

  @override
  String get bookingSelectTimeEmptyCtaLabel => 'Choose another date';

  @override
  String get bookingSummaryTitle => 'Summary';

  @override
  String get bookingSummaryNotesLabel => 'Note to the salon (optional)';

  @override
  String get bookingSummaryPaymentLockWarning =>
      'Your slot is locked for 5 minutes during payment. No charge until final confirmation.';

  @override
  String get bookingSummarySubmitButton => 'Confirm and pay →';

  @override
  String get bookingConfirmationTitle => '✅ Paid! Your spot is reserved.';

  @override
  String get bookingAddToCalendar => 'Add to calendar';

  @override
  String get bookingReturnHome => 'Back to home';

  @override
  String get bookingStatusPending => 'Pending';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusInProgress => 'In progress';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusNoShow => 'No-show';

  @override
  String get bookingWalkInTitle => 'New Appointment';

  @override
  String get bookingWalkInClientNameLabel => 'Client first name *';

  @override
  String get bookingWalkInServiceLabel => 'Service *';

  @override
  String get bookingWalkInPractitionerLabel => 'Practitioner *';

  @override
  String get bookingWalkInServicesLoadError => 'Unable to load services.';

  @override
  String get bookingWalkInStaffLoadError => 'Unable to load team.';

  @override
  String get bookingWalkInTimeLabel => 'Time';

  @override
  String get bookingWalkInMissingFields => 'Service and practitioner required.';

  @override
  String get bookingWalkInSubmitButton => 'Create appointment';

  @override
  String get bookingConfirmationRef => 'Ref.';

  @override
  String get bookingSalonDetailReserveButton => 'Book →';

  @override
  String get bookingDiscoveryTitle => 'Discover';

  @override
  String get bookingDiscoverySearchHint => 'Search a salon…';

  @override
  String get bookingDiscoveryAdvancedSearchTooltip => 'Advanced search';

  @override
  String get bookingDiscoveryAllCategories => 'All';

  @override
  String get bookingDiscoveryLoadError => 'Unable to load salons.';

  @override
  String get bookingDiscoveryEmptyTitle => 'No salon found';

  @override
  String get bookingDiscoveryEmptySubtitle =>
      'Try a different search or category.';

  @override
  String get bookingDiscoveryResetButton => 'Reset';

  @override
  String bookingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appointments',
      one: '1 appointment',
      zero: 'No appointments',
    );
    return '$_temp0';
  }

  @override
  String get bookingUpcomingTab => 'Upcoming';

  @override
  String get bookingPastTab => 'Past';

  @override
  String get bookingRebookButton => 'Book again';

  @override
  String get bookingViewReceiptButton => 'View receipt';

  @override
  String get bookingPaymentMethodLabel => 'Method';

  @override
  String get bookingShareReceiptButton => 'Share receipt';

  @override
  String get bookingSalonDetailLoadError => 'Unable to load this salon.';

  @override
  String get bookingSalonNotFound => 'Salon not found.';

  @override
  String get bookingSalonDetailServicesTab => 'Services';

  @override
  String get bookingSalonDetailInfoTab => 'Info';

  @override
  String get bookingSalonDetailReviewsTab => 'Reviews';

  @override
  String get bookingSalonDetailServicesLoadError => 'Unable to load services.';

  @override
  String get bookingSalonDetailServicesEmptySubtitle => 'Check back later.';

  @override
  String get paymentTitle => 'Payment';

  @override
  String get paymentMethodTitle => 'Payment method';

  @override
  String get paymentMethodLumicash => 'Lumicash';

  @override
  String get paymentMethodEcocash => 'EcoCash';

  @override
  String get paymentUssdInstruction =>
      'You will receive a USSD request on your phone. Enter your PIN to confirm.';

  @override
  String get paymentSubmitButton => 'Pay →';

  @override
  String get paymentFailedMessage =>
      'This payment failed. No money was charged.';

  @override
  String get paymentRetryButton => 'Retry';

  @override
  String get paymentInvalidPhone => 'Invalid number.';

  @override
  String get proxipayQrTitle => 'Collect payment';

  @override
  String get proxipayCreateSessionError =>
      'Couldn\'t generate the payment QR code.';

  @override
  String get proxipayQrShowToClient => 'Have the client scan this code.';

  @override
  String proxipayQrExpiresIn(String minutes, String seconds) {
    return 'Expires in $minutes:$seconds';
  }

  @override
  String get proxipayQrExpired => 'This code has expired. Generate a new one.';

  @override
  String get proxipayAwaitingSettlementMessage =>
      'Waiting for payment confirmation...';

  @override
  String get proxipaySuccessMessage => 'Payment received ✓';

  @override
  String get proxipayFailedMessage =>
      'This payment failed. No money was charged.';

  @override
  String get proxipayRetryButton => 'Retry';

  @override
  String get proxipayDoneButton => 'Done';

  @override
  String get proxipayScanTitle => 'Pay in person';

  @override
  String get proxipayScanInstruction => 'Scan the code shown by the salon.';

  @override
  String get proxipayScanInvalidError => 'Invalid or expired code.';

  @override
  String get proxipayScanConnectionError => 'Connection error. Please retry.';

  @override
  String get proxipayConfirmPayButton => 'Pay →';

  @override
  String get proxipayConfirmErrorGeneric => 'Couldn\'t confirm the payment.';

  @override
  String get proxipayConfirmSuccessMessage => 'Payment sent ✓';

  @override
  String get notificationsListTitle => 'Notifications';

  @override
  String get notificationsDeleteSuccess => 'Notification deleted.';

  @override
  String get notificationsLoadMoreButton => 'Load more';

  @override
  String get notificationsSettingsTitle => 'Notification preferences';

  @override
  String get notificationsChannelsHeading => 'Channels';

  @override
  String get notificationsPushTitle => 'Push notifications';

  @override
  String get notificationsWhatsappTitle => 'WhatsApp';

  @override
  String get notificationsWhatsappLabel => 'WhatsApp number';

  @override
  String get notificationsWhatsappHint => '+257 ...';

  @override
  String get notificationsAlertTypesHeading => 'Alert types';

  @override
  String get notificationsBookingCreatedTitle => 'Booking created';

  @override
  String get notificationsBookingCreatedSubtitle =>
      'Immediate confirmation of your request';

  @override
  String get notificationsBookingConfirmedTitle => 'Appointment confirmed';

  @override
  String get notificationsBookingCancelledTitle => 'Appointment cancelled';

  @override
  String get notificationsRemindersTitle => 'Appointment reminders';

  @override
  String get notificationsRemindersSubtitle =>
      'Reminder 24h and 2h before your appointment';

  @override
  String get notificationsTeamTitle => 'Team';

  @override
  String get notificationsTeamSubtitle => 'Invitations and colleague arrivals';

  @override
  String get notificationsMarketingTitle => 'Marketing';

  @override
  String get notificationsMarketingSubtitle => 'Promotions and salon updates';

  @override
  String get notificationsSaveButton => 'Save';

  @override
  String get notificationsLoadError => 'Unable to load your preferences.';

  @override
  String get notificationsSaveSuccess => 'Preferences saved.';

  @override
  String get notificationsSaveError => 'Failed to save.';

  @override
  String get staffListTitle => 'My Team';

  @override
  String get staffListSoloLink => 'I work alone →';

  @override
  String get staffListCommissionsTooltip => 'Commissions';

  @override
  String get staffFilterActive => 'Active';

  @override
  String get staffFilterPending => 'Pending';

  @override
  String get staffFilterDisabled => 'Disabled';

  @override
  String get staffListLoadError => 'Unable to load team.';

  @override
  String get staffInviteTitle => 'Invite a member';

  @override
  String get staffInviteNameLabel => 'Name *';

  @override
  String get staffInviteRoleStaff => 'Staff';

  @override
  String get staffInviteRoleManager => 'Manager';

  @override
  String get staffInviteSubmitButton => 'Send invitation';

  @override
  String get staffInviteError => 'Invitation failed.';

  @override
  String get staffFormTitle => 'Edit member';

  @override
  String get staffFormRemoveConfirmTitle => 'Remove this member?';

  @override
  String staffFormRemoveConfirmMessage(String name) {
    return '$name will no longer have access to this salon.';
  }

  @override
  String get staffFormServicesLoadError => 'Unable to load services.';

  @override
  String get staffAcceptInvitationVerifying => 'Verifying invitation...';

  @override
  String get staffCommissionsTitle => 'Commissions';

  @override
  String get availabilityManagementTitle => 'Availability';

  @override
  String get availabilityExceptionsLabel => 'Special days & public holidays';

  @override
  String get availabilityBlockedLabel => 'Blocked days (one-time)';

  @override
  String get availabilityLoadError => 'Unable to load availability.';

  @override
  String get availabilitySalonHoursTitle => 'Salon hours';

  @override
  String get availabilitySalonHoursSaveSuccess => 'Hours saved.';

  @override
  String get availabilityStaffHoursUseSalonTitle => 'Use salon hours';

  @override
  String get availabilityStaffHoursSaveSuccess => 'Hours saved.';

  @override
  String get availabilityBlockedSlotsTitle => 'Blocked days';

  @override
  String get availabilityBlockedSlotsConfirmTitle => 'Unblock this day?';

  @override
  String get availabilityBlockedSlotsLoadError =>
      'Unable to load blocked days.';

  @override
  String get availabilityExceptionsTitle => 'Special days';

  @override
  String availabilityBreaksTitle(String name) {
    return '$name\'s breaks';
  }

  @override
  String get availabilityDayOverrideTitle => 'Open this day';

  @override
  String get availabilityDayOverrideReasonLabel => 'Reason (optional)';

  @override
  String get availabilityDayOverrideHint => 'Leave, public holiday, training…';

  @override
  String get availabilityBreakDayLabel => 'Day';

  @override
  String get availabilityBreakLabelField => 'Label';

  @override
  String availabilityBreakStartTime(String time) {
    return 'Start $time';
  }

  @override
  String availabilityBreakEndTime(String time) {
    return 'End $time';
  }

  @override
  String get availabilityExceptionTitle => 'Special day';

  @override
  String get availabilityExceptionTypeLabel => 'Type';

  @override
  String get availabilityExceptionTypeVacation => 'Vacation';

  @override
  String get availabilityExceptionTypeClosure => 'Special closure';

  @override
  String get availabilityExceptionTypeOpening => 'Special opening';

  @override
  String get availabilityExceptionChooseDates => 'Choose dates';

  @override
  String availabilityExceptionOpenTime(String time) {
    return 'Opens $time';
  }

  @override
  String availabilityExceptionCloseTime(String time) {
    return 'Closes $time';
  }

  @override
  String get availabilityExceptionLabelField => 'Label';

  @override
  String get availabilityExceptionLabelHint => 'Annual leave, training…';

  @override
  String get availabilityWeekdayPreset => 'Weekdays 8am–6pm';

  @override
  String get availabilityAllDayPreset => 'Every day 8am–8pm';

  @override
  String get availabilityHubStaffHoursLabel => 'Staff hours';

  @override
  String get availabilityHubBreaksLabel => 'Breaks & absences';

  @override
  String get availabilityHubTouchHint =>
      'Tap a day to close or reopen it exceptionally.';

  @override
  String get availabilitySaveFailed => 'Failed to save.';

  @override
  String get availabilityDeleteFailed => 'Failed to delete.';

  @override
  String get availabilityUnblockFailed => 'Failed to unblock.';

  @override
  String get availabilityNoBlockedDaysTitle => 'No blocked days';

  @override
  String get availabilityNoBlockedDaysSubtitle =>
      'All your usual opening days are active.';

  @override
  String get availabilityUnblockMessage =>
      'This day will reopen according to your usual hours.';

  @override
  String get availabilityNoBreaksTitle => 'No breaks';

  @override
  String availabilityNoBreaksSubtitle(String name) {
    return 'Add $name\'s recurring breaks.';
  }

  @override
  String get availabilityAddBreakCta => 'Add a break';

  @override
  String get availabilityNewBreakTitle => 'New break';

  @override
  String get availabilityBreakDefaultLabel => 'Lunch break';

  @override
  String get availabilityBreakFallbackLabel => 'Break';

  @override
  String get availabilityNoExceptionsTitle => 'No special days';

  @override
  String get availabilityNoExceptionsSubtitle =>
      'Add your holidays or special closures.';

  @override
  String get availabilityPublicHolidaysHeading => 'Public holidays';

  @override
  String get availabilityNoPublicHolidays => 'No public holidays configured.';

  @override
  String get availabilityStaffHoursScreenHint =>
      'These hours override the salon hours for this practitioner.';

  @override
  String availabilityStaffHoursOf(String name) {
    return '$name\'s hours';
  }

  @override
  String get availabilityMyAvailability => 'My availability';

  @override
  String get availabilityStaffHoursLoadError => 'Unable to load these hours.';

  @override
  String get availabilityNoStaffTitle => 'No staff';

  @override
  String get availabilityNoStaffSubtitle =>
      'Invite your team to configure their hours.';

  @override
  String get availabilityStaffLoadError => 'Unable to load team.';

  @override
  String get availabilityClosedLabel => 'Closed';

  @override
  String get availabilityBreaksLoadError => 'Unable to load breaks.';

  @override
  String get availabilitySalonHoursLoadError => 'Unable to load hours.';

  @override
  String get availabilityExceptionsLoadError => 'Unable to load special days.';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get weekdayMondayShort => 'Mon';

  @override
  String get weekdayTuesdayShort => 'Tue';

  @override
  String get weekdayWednesdayShort => 'Wed';

  @override
  String get weekdayThursdayShort => 'Thu';

  @override
  String get weekdayFridayShort => 'Fri';

  @override
  String get weekdaySaturdayShort => 'Sat';

  @override
  String get weekdaySundayShort => 'Sun';

  @override
  String get servicesListTitle => 'Services';

  @override
  String servicesDeleteSuccess(String name) {
    return '$name deleted.';
  }

  @override
  String servicesDeleteSnack(String name) {
    return '« $name » deleted.';
  }

  @override
  String get servicesNoServiceTitle => 'No services';

  @override
  String get servicesNoServiceSubtitle =>
      'Add your services to start receiving appointments.';

  @override
  String get servicesNoServiceCta => 'Add a service';

  @override
  String get servicesFilterAll => 'All';

  @override
  String get servicesFormEditTitle => 'Edit service';

  @override
  String get servicesFormNewTitle => 'New service';

  @override
  String get servicesFormNameLabel => 'Service name *';

  @override
  String get servicesFormCategoryLabel => 'Category *';

  @override
  String get servicesFormDescriptionLabel => 'Description';

  @override
  String get servicesFormDurationLabel => 'Duration (minutes) *';

  @override
  String get servicesFormDurationError => 'Invalid duration.';

  @override
  String get servicesFormBufferLabel => 'Preparation time (minutes)';

  @override
  String get servicesFormPriceLabel => 'Price (FBu) *';

  @override
  String get servicesFormPriceError => 'Invalid price.';

  @override
  String get reviewsOwnerTitle => 'My Reviews';

  @override
  String get reviewsSortRecent => 'Recent';

  @override
  String get reviewsSortLowest => 'Lowest rating';

  @override
  String get reviewsSortUnanswered => 'Unanswered';

  @override
  String get reviewsReplyTitle => 'Reply to this review';

  @override
  String get reviewsReplyLabel => 'Your reply';

  @override
  String get reviewsReplySubmitButton => 'Post reply';

  @override
  String get reviewsFlagConfirmTitle => 'Report this review?';

  @override
  String get reviewsFlagConfirmMessage =>
      'It will be hidden pending review by our team.';

  @override
  String get reviewsFlagConfirmButton => 'Report';

  @override
  String get reviewsEmptyTitle => 'No reviews yet';

  @override
  String get reviewsEmptySubtitle => 'Client reviews will appear here.';

  @override
  String get reviewsEmptyCta => 'Back';

  @override
  String get reviewsReplyError => 'Failed to send.';

  @override
  String get reviewsFlagError => 'Failed to report.';

  @override
  String get reviewsLoadError => 'Unable to load your reviews.';

  @override
  String get reviewsSalonLoadError => 'Unable to load reviews.';

  @override
  String get reviewsLeaveTitle => 'Leave a review';

  @override
  String get reviewsLeaveBookingError => 'Unable to verify your booking.';

  @override
  String get reviewsLeaveSuccess => 'Review posted! Thank you 💛';

  @override
  String get reviewsLeaveQueuedOffline =>
      'Review saved offline — will be posted once reconnected.';

  @override
  String get reviewsLeaveSkipButton => 'Skip';

  @override
  String get reviewsLeaveRatingRequired =>
      'Please choose a rating before publishing.';

  @override
  String get reviewsLeaveCommentLabel => 'Share your experience (optional)';

  @override
  String get reviewsLeaveAnonymousLabel => 'Stay anonymous';

  @override
  String get reviewsLeavePublishButton => 'Publish my review';

  @override
  String get reviewsLeaveUnavailableTitle => 'Review unavailable';

  @override
  String get reviewsLeaveUnavailableSubtitle =>
      'This booking has already received a review or cannot be rated yet.';

  @override
  String get reviewsLeaveBackButton => 'Back to my bookings';

  @override
  String get reviewsLeaveServiceFallback => 'Your service';

  @override
  String get reviewsAnonymousName => 'Anonymous';

  @override
  String get reviewsClientFallbackName => 'Client';

  @override
  String get reviewsSalonReplyLabel => 'Salon reply';

  @override
  String get reviewsFirstTitle => 'Be the first to leave a review!';

  @override
  String get reviewsFirstSubtitle => 'Book then share your experience.';

  @override
  String reviewsVerifiedCount(int count) {
    return '$count verified reviews';
  }

  @override
  String get marketingDashboardTitle => 'Marketing';

  @override
  String get marketingBookingsLabel => 'Bookings';

  @override
  String get marketingRecurringLabel => 'Recurring';

  @override
  String get marketingSeeAllContactsButton => 'See all my contacts →';

  @override
  String get marketingTeamPerformanceError =>
      'Unable to load team performance.';

  @override
  String get marketingForecastsError => 'Unable to calculate forecasts.';

  @override
  String get marketingSendError => 'Failed to send.';

  @override
  String get marketingPromotionsTitle => 'Promotions';

  @override
  String get marketingPromotionsActiveFilter => 'Active';

  @override
  String get marketingPromotionsExpiredFilter => 'Expired';

  @override
  String get marketingPromotionsEmptyActive => 'No active promotions';

  @override
  String get marketingPromotionsEmptyActiveHint =>
      'Create your first offer to attract clients.';

  @override
  String get marketingPromotionsEmptyExpired => 'No expired promotions';

  @override
  String get marketingPromotionsCreateButton => 'Create my first promotion';

  @override
  String get marketingPromotionsDeactivateConfirmTitle =>
      'Deactivate this promotion?';

  @override
  String marketingPromotionsDeactivateConfirmMessage(String name) {
    return '$name will no longer be visible to clients.';
  }

  @override
  String get marketingPromotionsDeactivateButton => 'Deactivate';

  @override
  String get marketingPromotionsDeactivateError => 'Failed to deactivate.';

  @override
  String get marketingPromotionsLoadError => 'Unable to load promotions.';

  @override
  String get marketingPromotionTypePercentage => 'Percentage %';

  @override
  String get marketingPromotionTypeFixed => 'Fixed amount FBu';

  @override
  String get marketingPromotionGenerateCodeButton => 'Generate code';

  @override
  String get marketingPromotionDateError =>
      'End date must be after start date.';

  @override
  String get marketingClientsTitle => 'My Clients';

  @override
  String get marketingClientsContactsTab => 'Contacts';

  @override
  String get marketingClientsInvitationsTab => 'Invitations';

  @override
  String marketingClientsDeleteSuccess(String name) {
    return '$name deleted.';
  }

  @override
  String get marketingClientsOnKynzaBadge => 'On KYNZA ✓';

  @override
  String get marketingClientsLoadError => 'Unable to load clients.';

  @override
  String get marketingLoyaltyTitle => 'Loyalty Program';

  @override
  String get marketingLoyaltyRewardMissingWarning =>
      'Describe the reward offered.';

  @override
  String get marketingLoyaltySaveSuccess => 'Program saved!';

  @override
  String marketingLoyaltyRewardValidatedSuccess(String name) {
    return 'Reward validated for $name!';
  }

  @override
  String get marketingLoyaltyRewardValidateConfirmTitle => 'Validate reward?';

  @override
  String get marketingLoyaltyRewardDescriptionLabel => 'Reward description *';

  @override
  String get marketingLoyaltyStampsLabel => 'Stamps given';

  @override
  String get marketingLoyaltyRewardsLabel => 'Rewards';

  @override
  String get marketingShareTitle => 'Share my salon';

  @override
  String get marketingShareCopySuccess => 'Link copied!';

  @override
  String get dashboardTitle => 'KYNZA Dashboard';

  @override
  String get dashboardTeamPerformanceError =>
      'Unable to load team performance.';

  @override
  String get dashboardForecastsError => 'Unable to calculate forecasts.';

  @override
  String get dashboardAuditLogLoadError => 'Unable to load activity log.';

  @override
  String get dashboardAuditLogExportTooltip => 'Export (CSV)';

  @override
  String get dashboardAuditLogLoadMoreButton => 'Load more';

  @override
  String get dashboardLoadError => 'Unable to load the dashboard.';

  @override
  String get dashboardOverviewTab => 'Overview';

  @override
  String get dashboardClientsTab => 'Clients';

  @override
  String get dashboardTeamTab => 'Team';

  @override
  String get dashboardForecastTab => 'Forecasts';

  @override
  String get dashboardExportPdfButton => 'Export PDF';

  @override
  String get dashboardKpiRevenu => 'Revenue';

  @override
  String get dashboardKpiReservations => 'Bookings';

  @override
  String get dashboardKpiOccupancyRate => 'Fill rate';

  @override
  String get dashboardKpiNoShowRate => 'No-show rate';

  @override
  String get dashboardRevenueChartTitle => 'Revenue trend';

  @override
  String get dashboardNoServiceTitle => 'No services';

  @override
  String get dashboardNoServiceSubtitle =>
      'Add your services to track their performance.';

  @override
  String get dashboardAddServiceCta => 'Add a service';

  @override
  String get dashboardNoStaffTitle => 'No staff';

  @override
  String get dashboardNoStaffSubtitle =>
      'Invite your team to track their performance.';

  @override
  String get dashboardInviteTeamCta => 'Invite your team';

  @override
  String get dashboardQuickActionServices => 'Services';

  @override
  String get dashboardQuickActionAddService => 'Add service';

  @override
  String get dashboardQuickActionTeam => 'Team';

  @override
  String get dashboardQuickActionInviteStaff => 'Invite staff';

  @override
  String get dashboardClientExportCsvButton => 'Export clients (CSV)';

  @override
  String get dashboardNewVsReturning => 'New vs Returning';

  @override
  String get dashboardNewClients => 'New';

  @override
  String get dashboardReturningClients => 'Returning';

  @override
  String get dashboardChurnRiskTitle => 'At-risk clients';

  @override
  String get dashboardNoChurnRisk => 'No at-risk clients for now.';

  @override
  String get dashboardTopClientsTitle => 'Top clients';

  @override
  String get dashboardNoTopClients => 'No clients yet.';

  @override
  String dashboardClientVisitCount(int count) {
    return '$count visits';
  }

  @override
  String get dashboardCohortTitle => 'Cohort retention';

  @override
  String get dashboardChurnRiskHigh => 'High risk';

  @override
  String get dashboardChurnRiskMedium => 'Medium risk';

  @override
  String get dashboardChurnRiskLow => 'Low risk';

  @override
  String dashboardChurnAbsentDays(int days) {
    return 'Absent for $days days';
  }

  @override
  String get dashboardOwnerOnlyTitle => 'Owner only';

  @override
  String get dashboardOwnerOnlySubtitle =>
      'Team performance is only visible to the owner.';

  @override
  String get dashboardTeamRevenueChartTitle => 'Revenue by staff';

  @override
  String get dashboardNoTeamDataTitle => 'No team data';

  @override
  String get dashboardNoTeamDataSubtitle =>
      'Performance will appear after the first appointments.';

  @override
  String get dashboardExportReportPdfButton => 'Export report (PDF)';

  @override
  String get dashboardExportCsvButton => 'Export CSV';

  @override
  String get dashboardForecastTitle => '12-week forecast';

  @override
  String get dashboardForecastNoHistory =>
      'Not enough history for a forecast yet.';

  @override
  String get dashboardExportForecastCsvButton => 'Export (CSV)';

  @override
  String dashboardOccupancyTip(int rate) {
    return 'Occupancy at $rate% — consider re-engaging your clients to fill your schedule.';
  }

  @override
  String get dashboardTopServicesTitle => 'Top services';

  @override
  String get dashboardServiceSeeAll => 'See all';

  @override
  String dashboardServiceRdvCount(int count) {
    return '$count appts';
  }

  @override
  String get dashboardTopStaffTitle => 'Top team';

  @override
  String dashboardStaffRdvCount(int count) {
    return '$count appts';
  }

  @override
  String get dashboardCohortHeader => 'Cohort';

  @override
  String get dashboardNoCohortData => 'No cohort data yet.';

  @override
  String get auditLogTitle => 'Activity log';

  @override
  String get auditLogFilterAll => 'All';

  @override
  String get auditLogFilterBooking => 'Bookings';

  @override
  String get auditLogFilterPayment => 'Payment';

  @override
  String get auditLogFilterStaff => 'Team';

  @override
  String get auditLogFilterSettings => 'Settings';

  @override
  String get auditLogNoActivityTitle => 'No activity';

  @override
  String get auditLogNoActivitySubtitle =>
      'The log will fill up as you take actions.';

  @override
  String get dataTemplatesListTitle => 'Document templates';

  @override
  String get dataTemplatesDeleteConfirmTitle => 'Delete template';

  @override
  String dataTemplatesDeleteConfirmMessage(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get dataTemplatesLoadError => 'Unable to load templates.';

  @override
  String get dataTemplatesDeleteSuccess => 'Template deleted.';

  @override
  String get dataTemplatesDeleteError => 'Unable to delete this template.';

  @override
  String get dataTemplatesDefaultBadge => 'DEFAULT';

  @override
  String get dataTemplateEditorNameLabel => 'Template name';

  @override
  String get dataTemplateEditorContentLabel => 'Template content';

  @override
  String get dataTemplateEditorContentHint =>
      'Use [variable] to insert dynamic data.';

  @override
  String get dataBackupTitle => 'Data backups';

  @override
  String get dataBackupCreateButton => 'Create backup';

  @override
  String get dataBackupCreateCancelButton => 'Cancel';

  @override
  String get dataBackupCreateSuccess => 'Backup created successfully.';

  @override
  String get billingTitle => 'Billing';

  @override
  String get billingSubscriptionTitle => 'KYNZA Subscription';

  @override
  String get billingSubscriptionRecommendedBadge => 'RECOMMENDED';

  @override
  String billingSubscriptionDowngradeConfirmTitle(String plan) {
    return 'Downgrade to $plan?';
  }

  @override
  String billingSubscriptionDowngradeConfirmMessage(String plan) {
    return 'Your salon will immediately switch to the $plan plan.';
  }

  @override
  String get billingSubscriptionUpdateSuccess => 'Plan updated.';

  @override
  String get billingSubscriptionMarkPaidButton => 'Mark as paid';

  @override
  String get billingSubscriptionCopyReferenceButton => 'Copy reference';

  @override
  String get billingSubscriptionCopyReferenceSuccess => 'Reference copied!';

  @override
  String get billingInvoicesTitle => 'Invoice history';

  @override
  String get permissionsGroupsTitle => 'Permission groups';

  @override
  String get permissionsGroupNameHint => 'e.g. Senior Receptionist';

  @override
  String get permissionsGroupCreateError => 'Unable to create this group.';

  @override
  String get permissionsGroupDeleteConfirmTitle => 'Delete this group?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPermissionsLabel => 'Permissions & Team';

  @override
  String get settingsAutomationLabel => 'Automations';

  @override
  String get settingsBookingLabel => 'Bookings';

  @override
  String get settingsNotificationsSalonLabel => 'Salon notifications';

  @override
  String get settingsMarketingLabel => 'Marketing';

  @override
  String get settingsTeamLabel => 'Team';

  @override
  String get settingsLoyaltyLabel => 'Loyalty';

  @override
  String get settingsReviewsLabel => 'Reviews';

  @override
  String get settingsPaymentsLabel => 'Payments';

  @override
  String get settingsAdvancedLabel => 'Advanced';

  @override
  String get settingsDocumentTemplatesLabel => 'Document templates';

  @override
  String get settingsDataBackupLabel => 'Data backups';

  @override
  String get settingsFeatureFlagsLabel => 'Feature flags';

  @override
  String get settingsAboutLabel => 'About KYNZA';

  @override
  String get settingsCategoryLoadError => 'Unable to load settings.';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutSectionApp => 'Application';

  @override
  String get settingsAboutSectionLegal => 'Legal';

  @override
  String get settingsAboutVersionLabel => 'Version';

  @override
  String get settingsAboutBuildLabel => 'Build';

  @override
  String get settingsAboutPlatformLabel => 'Platform';

  @override
  String get settingsAboutPublisherLabel => 'Publisher';

  @override
  String get settingsAboutCountryLabel => 'Country';

  @override
  String get settingsAboutCurrencyLabel => 'Currency';

  @override
  String settingsAboutCopyright(String year) {
    return '© $year KYNZA. All rights reserved.';
  }

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose the app language';

  @override
  String get settingsLanguageSystemDetected => 'Auto-detected';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get evolutionFeatureFlagsTitle => 'Feature flags';

  @override
  String get evolutionFeatureFlagsDisabledBadge => 'GLOBAL: DISABLED';

  @override
  String get evolutionFeatureFlagsEnabledBadge => 'GLOBAL: ENABLED';

  @override
  String get evolutionFeatureFlagsResetTooltip => 'Reset (follow global)';

  @override
  String get evolutionFeatureFlagsEmptyTitle => 'No flags configured';

  @override
  String get evolutionFeatureFlagsEmptySubtitle =>
      'Feature flags will appear here.';

  @override
  String get evolutionFeatureFlagsOverrideBadge => 'OVERRIDE';

  @override
  String evolutionFeatureFlagsRollout(int percentage) {
    return 'GLOBAL: $percentage%';
  }

  @override
  String get evolutionFeatureFlagsInfoText =>
      'Enable or disable features for this salon. Local overrides take precedence over global settings.';

  @override
  String get evolutionMaintenanceDefaultTitle => 'Maintenance in progress';

  @override
  String get evolutionMaintenanceDefaultMessage =>
      'The app is temporarily unavailable. We\'ll be back very soon.';

  @override
  String evolutionMaintenanceEndsAt(String time) {
    return 'Expected to end around $time';
  }

  @override
  String get evolutionForceUpdateTitle => 'Update required';

  @override
  String get evolutionForceUpdateDefaultMessage =>
      'This version of the app is no longer supported. Please update to continue.';

  @override
  String evolutionForceUpdateVersionLabel(String version) {
    return 'Available version: $version';
  }

  @override
  String get evolutionForceUpdateCheckButton => 'Check again';

  @override
  String get evolutionForceUpdateButton => 'Update';

  @override
  String get evolutionMaintenanceCheckButton => 'Check again';

  @override
  String get automationListTitle => 'Automations';

  @override
  String get automationListHistoryTooltip => 'Execution history';

  @override
  String get automationListEmptyTitle => 'No automations yet';

  @override
  String get automationListEmptySubtitle =>
      'Create a workflow to automate an action when an event occurs.';

  @override
  String get automationWorkflowTitle => 'New workflow';

  @override
  String get automationWorkflowNameLabel => 'Name';

  @override
  String get automationWorkflowDescriptionLabel => 'Description (optional)';

  @override
  String get automationWorkflowConditionsTitle => 'Conditions';

  @override
  String get automationWorkflowNoConditions =>
      'No conditions — the workflow will run on every trigger.';

  @override
  String get automationWorkflowActionsTitle => 'Actions';

  @override
  String get automationWorkflowNoActions =>
      'Add at least one action to execute.';

  @override
  String get automationWorkflowFieldLabel => 'Field (e.g. amount)';

  @override
  String get automationWorkflowValueLabel => 'Value';

  @override
  String get automationWorkflowDelayLabel => 'Delay (seconds):';

  @override
  String get automationWorkflowTargetLabel => 'Recipient';

  @override
  String get automationWorkflowEventHint => 'e.g. booking_confirmed';

  @override
  String get automationWorkflowStampsLabel => 'Bonus stamps';

  @override
  String get automationWorkflowReasonLabel => 'Reason (optional)';

  @override
  String get automationWorkflowActionLabel => 'Action';

  @override
  String get automationWorkflowNotWired => '(not yet wired)';

  @override
  String get automationWorkflowComingSoon => '(coming soon)';

  @override
  String get automationWorkflowNotImplemented =>
      'This action is not yet available.';

  @override
  String automationWorkflowExecutionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count executions',
      one: '1 execution',
      zero: '0 executions',
    );
    return '$_temp0';
  }

  @override
  String get automationWorkflowTriggersLoadError => 'Unable to load triggers.';

  @override
  String get automationWorkflowValidationError =>
      'Name and trigger are required.';

  @override
  String get automationWorkflowCreateError => 'Unable to create this workflow.';

  @override
  String get automationWorkflowTriggerLabel => 'Trigger';

  @override
  String get automationWorkflowCreateButton => 'Create workflow';

  @override
  String get automationWorkflowLogicOperatorLabel => 'Logical operator';

  @override
  String get automationWorkflowOperatorLabel => 'Operator';

  @override
  String get automationWorkflowEventLabel => 'Event (event_type)';

  @override
  String get automationWorkflowSeverityLabel => 'Severity';

  @override
  String get searchAdvancedTitle => 'Search';

  @override
  String get searchAdvancedHint => 'Search salons, services…';

  @override
  String get searchAdvancedClearButton => 'Clear';

  @override
  String get searchFiltersResetButton => 'Reset';

  @override
  String get salonCreationTitle => 'Create your salon';

  @override
  String get salonLocationHint => 'Street, number, area';

  @override
  String get salonCreationNextButton => 'Next →';

  @override
  String get salonCreationSubmitButton => 'Create my salon →';

  @override
  String get salonCreationErrorGeneric =>
      'Unable to create salon. Please try again.';

  @override
  String get salonInfoStepNameLabel => 'Salon name *';

  @override
  String get salonInfoStepSloganLabel => 'Slogan';

  @override
  String get salonInfoStepDescriptionLabel => 'Description';

  @override
  String get salonInfoStepSocialTitle => 'Social media';

  @override
  String get salonLocationStepAddressLabel => 'Address';

  @override
  String get salonMediaStepLogoLabel => 'Logo';

  @override
  String get salonMediaStepCoverLabel => 'Cover photo';

  @override
  String get salonMediaStepAddCoverLabel => 'Add a cover';

  @override
  String salonMediaStepGalleryLabel(int count, int max) {
    return 'Gallery ($count/$max)';
  }

  @override
  String get salonCreationSuccessTitle => 'Your salon is created! 🎉';

  @override
  String get salonCreationSuccessSubtitle => 'Now add your services';

  @override
  String get salonCreationSuccessCtaLabel => 'Set up my services →';

  @override
  String get provinceSelectorProvinceLabel => 'Province';

  @override
  String get provinceSelectorProvinceRequired => 'Province required.';

  @override
  String get provinceSelectorCommuneLabel => 'Commune';

  @override
  String get provinceSelectorCommuneRequired => 'Commune required.';

  @override
  String get workingHoursClosed => 'Closed';

  @override
  String get loyaltyCardsLoadError => 'Unable to load your loyalty cards.';

  @override
  String get loyaltyCardsEmptyTitle => 'No loyalty cards';

  @override
  String get loyaltyCardsEmptySubtitle =>
      'Book your first appointment to start collecting stamps! 💛';

  @override
  String get loyaltyCardsEmptyCtaLabel => 'Discover salons';

  @override
  String get loyaltyQrCardNotFound => 'Loyalty card not found.';

  @override
  String get loyaltyQrGenerateError => 'Unable to generate QR code.';

  @override
  String get loyaltyQrShowToStaff => 'Show this code to salon staff';

  @override
  String loyaltyQrExpiresIn(String minutes, String seconds) {
    return 'Expires in $minutes:$seconds';
  }

  @override
  String get loyaltyScanQrInvalidError => 'Invalid or expired QR.';

  @override
  String get loyaltyScanConnectionError => 'Connection failed. Please retry.';

  @override
  String loyaltyStampsRequired(int required) {
    return '$required stamps required';
  }

  @override
  String loyaltyStampsProgress(int count, int total) {
    return '$count / $total stamps';
  }

  @override
  String get loyaltyRewardAvailable =>
      '🎉 Reward available! Show this code to the salon.';

  @override
  String get loyaltyStampLogsTitle => 'Your stamp history';

  @override
  String get loyaltyStampLogsLoadError => 'Unable to load history.';

  @override
  String get loyaltyStampLogsEmpty => 'No stamps yet.';

  @override
  String get loyaltyStampAdded => 'Stamp added';

  @override
  String get loyaltyStampRewardValidated => 'Reward validated';

  @override
  String get loyaltyShowQrButton => 'Show my QR';

  @override
  String get journeyLaunchTitle => '🚀 Launch your salon';

  @override
  String get journeySalonReady => '🎉 Your salon is ready!';

  @override
  String get permissionsGroupsLoadError => 'Unable to load permission groups.';

  @override
  String get permissionsGroupEmptyTitle => 'No permission groups';

  @override
  String get permissionsGroupEmptySubtitle =>
      'Create a group to give a team member precise rights beyond their base role.';

  @override
  String get permissionsGroupEmptyCtaLabel => 'Create a group';

  @override
  String get permissionsGroupDetailLoadError => 'Unable to load this group.';

  @override
  String get permissionsGroupNotFound => 'Group not found';

  @override
  String get permissionsGroupNotFoundSubtitle =>
      'This group may have been deleted.';

  @override
  String get permissionsGroupDefaultTitle => 'Permission group';

  @override
  String permissionsGroupDeleteConfirmMessage(String name) {
    return 'Members of \"$name\" will lose the permissions granted by this group.';
  }

  @override
  String get permissionsPermissionsTitle => 'Permissions';

  @override
  String get permissionsPermissionsLoadError => 'Unable to load permissions.';

  @override
  String get permissionsMembersTitle => 'Members';

  @override
  String get permissionsMembersEmpty => 'No members in this group yet.';

  @override
  String get permissionsAddMemberTitle => 'Add a member';

  @override
  String get permissionsAddMemberAllInGroup =>
      'The whole team is already in this group.';

  @override
  String get permissionsMemberFallback => 'Member';

  @override
  String get permissionsGroupFormTitle => 'New permission group';

  @override
  String get permissionsGroupFormNameLabel => 'Group name';

  @override
  String get permissionsGroupFormDescriptionLabel => 'Description (optional)';

  @override
  String get permissionsGroupFormBaseRoleLabel => 'Base role';

  @override
  String get permissionsGroupFormNameRequired => 'Name required';

  @override
  String get permissionsGroupFormCreateButton => 'Create group';

  @override
  String get loyaltyScanTitle => 'Scan loyalty';

  @override
  String get loyaltyQrTitle => 'My loyalty QR';

  @override
  String get journeyProgressCloseButton => 'Close';

  @override
  String get journeyProgressContinueButton => 'Continue setup →';

  @override
  String get referralClaimVerifying => 'Verifying invitation...';

  @override
  String get teamCommissionsTitle => 'Commissions';

  @override
  String get notificationsFilterAll => 'All';

  @override
  String get notificationsFilterBooking => 'Bookings';

  @override
  String get notificationsFilterLoyalty => 'Loyalty';

  @override
  String get notificationsFilterMarketing => 'Marketing';

  @override
  String get notificationsFilterSystem => 'System';

  @override
  String get notificationsSectionToday => 'Today';

  @override
  String get notificationsSectionThisWeek => 'This week';

  @override
  String get notificationsSectionOlder => 'Older';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptySubtitle =>
      'Come back soon — your alerts will appear here.';

  @override
  String get notificationsLoadErrorFeed => 'Unable to load your notifications.';

  @override
  String notificationsDeletedSnack(String title) {
    return '\'$title\' deleted.';
  }

  @override
  String get staffListEmptySubtitle =>
      'Invite your team to start organising the schedule, or work solo to get started.';

  @override
  String get staffCountActive => 'active';

  @override
  String get staffCountPending => 'pending';

  @override
  String get staffCountDisabled => 'disabled';

  @override
  String get staffNoMembersInCategory => 'No members in this category.';

  @override
  String get staffDetailPerformanceMonth => 'Performance this month';

  @override
  String get staffDetailCommissionsMonth => 'Commissions this month';

  @override
  String get staffDetailServicesTitle => 'Services offered';

  @override
  String get staffDetailLastBookings => 'Recent appointments';

  @override
  String get staffDetailNoSpecialty => 'No speciality.';

  @override
  String get staffDetailNoBookings => 'No appointments yet.';

  @override
  String get staffDetailScheduleLabel => 'Schedule';

  @override
  String get staffDetailDeactivate => 'Deactivate';

  @override
  String get staffDetailReactivate => 'Reactivate';

  @override
  String get staffDetailDemote => 'Demote to staff';

  @override
  String get staffDetailPromote => 'Promote to manager';

  @override
  String get staffDetailRemoveButton => 'Remove from salon';

  @override
  String get staffDetailRemoveConfirmTitle => 'Remove this member?';

  @override
  String staffDetailRemoveConfirmMessage(String name) {
    return '$name will no longer have access to this salon.';
  }

  @override
  String get staffDetailCommissionsEarned => 'Earned';

  @override
  String get staffDetailCommissionsPaid => 'Paid';

  @override
  String get staffDetailCommissionsPending => 'Pending';

  @override
  String get staffFormDisplayNameLabel => 'Display name';

  @override
  String get staffFormPhoneLabel => 'Phone';

  @override
  String get staffFormBioLabel => 'Bio';

  @override
  String get staffFormCommissionSectionTitle => 'Commission';

  @override
  String get staffFormCommissionTypeLabel => 'Type';

  @override
  String get staffFormCommissionTypePercent => '% of booking';

  @override
  String get staffFormCommissionTypeFixed => 'Fixed FBu';

  @override
  String get staffFormCommissionRatePercent => 'Rate (%)';

  @override
  String get staffFormCommissionRateFixed => 'Amount (FBu)';

  @override
  String get staffFormSaveButton => 'Save';

  @override
  String get staffFormRemoveButton => 'Remove member';

  @override
  String get acceptInvitationWelcome => 'Welcome to the team!';

  @override
  String get acceptInvitationError =>
      'Invalid or expired invitation. Contact your salon to get a new one.';

  @override
  String get myPerfMyBookings => 'My Bookings';

  @override
  String get myPerfMyRevenue => 'My Revenue';

  @override
  String myPerfRankText(int rank, String suffix, int teamSize) {
    return '$rank$suffix out of $teamSize this week';
  }

  @override
  String get myPerfMonthTitle => 'My appointments this month';

  @override
  String get myPerfReviewsTitle => 'My recent reviews';

  @override
  String get myPerfNoBookings => 'No completed appointments this month.';

  @override
  String get myPerfNoReviews => 'No reviews yet.';

  @override
  String get myPerfCommissionsMonth => 'My commissions this month';

  @override
  String get myPerfCommissionsPaid => 'Paid';

  @override
  String get myPerfCommissionsPending => 'Pending';

  @override
  String get marketingFillMyDayTitle => 'Fill my day';

  @override
  String get marketingFillMyDaySubtitle =>
      'Free slots today or tomorrow? Share a promotion with your personal contacts (max 2 per week).';

  @override
  String get marketingFillMyDayButton => 'Share a promo →';

  @override
  String get marketingFillMyDayLimitReached =>
      'Limit of 2 promotions per week reached.';

  @override
  String get marketingRecentContactsTitle => 'Recent contacts';

  @override
  String get marketingNoContactsYet => 'No contacts yet.';

  @override
  String get marketingManageButton => 'Manage →';

  @override
  String get marketingNewBadge => 'New';

  @override
  String get marketingFreeBadge => 'Free';

  @override
  String get marketingActiveBadge => 'Active';

  @override
  String get marketingToConfigureBadge => 'To configure';

  @override
  String get marketingExpiringSoonBadge => 'Expiring soon';

  @override
  String get marketingShareServicesTitle => 'Share my services';

  @override
  String get marketingNoServicesToShare => 'No services to share yet.';

  @override
  String get marketingSharePromotionTitle => 'Share a promotion';

  @override
  String get marketingInviteLinkTitle => 'Personalised invitation link';

  @override
  String get marketingInviteLinkSubtitle =>
      'Share this link. Your clients download KYNZA and find you directly.';

  @override
  String get marketingInviteLinkGenError =>
      'Unable to generate the link right now.';

  @override
  String get marketingCopyLinkButton => 'Copy link';

  @override
  String get marketingShareArrowButton => 'Share →';

  @override
  String get marketingLinkCopied => 'Link copied!';

  @override
  String get marketingLoadSalonError => 'Unable to load your salon.';

  @override
  String get marketingImportFromBookingsButton => 'Import from bookings';

  @override
  String get marketingSearchContactHint => 'Search a contact';

  @override
  String get marketingNoContactsTitle => 'No contacts yet';

  @override
  String get marketingNoContactsSubtitle => 'Add your first clients.';

  @override
  String get marketingAddContactButton => 'Add a contact';

  @override
  String get marketingImportNone => 'No new clients to import.';

  @override
  String marketingImportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients imported.',
      one: '1 client imported.',
    );
    return '$_temp0';
  }

  @override
  String get marketingNoInvitationsSentTitle => 'No invitations sent';

  @override
  String get marketingNoInvitationsSentSubtitle =>
      'Share a referral link from your contacts.';

  @override
  String marketingInviteSentOnDate(String date) {
    return 'Sent on $date';
  }

  @override
  String get marketingInviteAccepted => 'Accepted';

  @override
  String get marketingInviteSent => 'Sent';

  @override
  String get marketingAddContactTitle => 'Add a contact';

  @override
  String get marketingFullNameLabel => 'Full name *';

  @override
  String get marketingLoyaltyLoadError => 'Unable to load the program.';

  @override
  String get marketingLoyaltyEmptyTitle => 'Build client loyalty';

  @override
  String get marketingLoyaltyEmptySubtitle =>
      'Give stamps at each visit. At the Xth visit, offer a reward.';

  @override
  String get marketingLoyaltySetupCta => 'Set up my program';

  @override
  String get marketingLoyaltyStampsRequiredLabel => 'Stamps required';

  @override
  String marketingLoyaltyStampsRequiredHint(int count) {
    return 'After $count visits, your client receives a reward.';
  }

  @override
  String get marketingLoyaltyRewardDescriptionHint => 'e.g. 1 free haircut';

  @override
  String get marketingLoyaltyRewardValueLabel => 'Value in FBu (optional)';

  @override
  String get marketingLoyaltyProgramActiveLabel => 'Program active';

  @override
  String get marketingLoyaltyCardPreviewTitle => 'Client card preview';

  @override
  String get marketingLoyaltyStatsTitle => 'Statistics';

  @override
  String get marketingLoyaltyTopClientsTitle => 'Most loyal clients';

  @override
  String get marketingLoyaltyStatCardsLabel => 'Cards';

  @override
  String marketingLoyaltyStampsCount(int count) {
    return '$count stamps';
  }

  @override
  String get marketingLoyaltyValidateButton => 'Validate';

  @override
  String get marketingLoyaltyValidateError => 'Validation failed.';

  @override
  String get marketingLoyaltySaveError => 'Failed to save.';

  @override
  String marketingLoyaltyCardStampsRequired(int count) {
    return '$count stamps required';
  }

  @override
  String marketingLoyaltyVisitsRemaining(int count) {
    return 'Only $count more visits for the reward!';
  }

  @override
  String marketingLoyaltyRewardValidateConfirmMessage(String name, int count) {
    return '$name has reached $count stamps. Their stamps will be reset to zero.';
  }

  @override
  String get promotionFormCreateTitle => 'Create a promotion';

  @override
  String get promotionFormEditTitle => 'Edit promotion';

  @override
  String get promotionFormTitleLabel => 'Title *';

  @override
  String get promotionFormDescriptionLabel => 'Description';

  @override
  String get promotionFormValuePercentLabel => 'Value (%) *';

  @override
  String get promotionFormValueBifLabel => 'Value (FBu) *';

  @override
  String get promotionFormTargetServiceLabel => 'Target service (optional)';

  @override
  String get promotionFormAllServices => 'All services';

  @override
  String promotionFormStartDate(String date) {
    return 'Start: $date';
  }

  @override
  String promotionFormEndDate(String date) {
    return 'End: $date';
  }

  @override
  String get promotionFormMaxUsesLabel => 'Max number of uses (optional)';

  @override
  String get promotionFormNoCode => 'No promo code';

  @override
  String get promotionFormGenerateCodeButton => 'Generate code';

  @override
  String get promotionFormCreateButton => 'Create promotion';

  @override
  String get promotionFormSaveError => 'Failed to save.';

  @override
  String get promotionFormTitlePlaceholder => 'Promotion title';

  @override
  String promotionCardServiceLabel(String name) {
    return 'Service: $name';
  }

  @override
  String get promotionCardShareButton => 'Share';

  @override
  String get promotionCardEditButton => 'Edit';

  @override
  String get promotionCardDeactivateButton => 'Deactivate';

  @override
  String get promotionDeactivateError => 'Failed to deactivate.';

  @override
  String get searchResultsTitle => 'Search';

  @override
  String get searchSalonsSectionLabel => 'Salons';

  @override
  String get searchServicesSectionLabel => 'Services';

  @override
  String get searchRecentLabel => 'Recent searches';

  @override
  String get searchClearButton => 'Clear';

  @override
  String get searchPopularLabel => 'Popular searches';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchNoResultsSubtitle => 'Try a different search or filter.';

  @override
  String get searchLoadError => 'Unable to start search.';

  @override
  String get searchFiltersTitle => 'Filters';

  @override
  String searchFiltersPriceLabel(String min, String max) {
    return 'Price (FBu) — $min to $max';
  }

  @override
  String get searchFiltersMinRatingLabel => 'Minimum rating';

  @override
  String get searchFiltersCategoriesLabel => 'Categories';

  @override
  String get searchFiltersProvinceLabel => 'Province';

  @override
  String get searchFiltersAllProvinces => 'All provinces';

  @override
  String get searchFiltersSortByLabel => 'Sort by';

  @override
  String get searchFiltersApplyButton => 'Apply';

  @override
  String get searchSortRelevance => 'Relevance';

  @override
  String get searchSortPriceAsc => 'Price ↑';

  @override
  String get searchSortPriceDesc => 'Price ↓';

  @override
  String get searchSortRating => 'Rating';

  @override
  String get billingCurrentPlanLabel => 'Current plan';

  @override
  String get billingCurrentPeriodLabel => 'Current period';

  @override
  String get billingPaymentMethodManual =>
      'Payment method: Manual (bank transfer)';

  @override
  String billingNextBillingLabel(String date) {
    return 'Next billing: $date';
  }

  @override
  String get billingManageSubscriptionButton => 'Manage my subscription';

  @override
  String get billingInvoiceHistoryButton => 'Invoice history';

  @override
  String billingCurrentMonthUsage(int used, int max) {
    return '$used / $max appointments this month';
  }

  @override
  String get billingCurrentPlanBadgeFree => 'FREE PLAN';

  @override
  String billingCurrentPlanBadge(String plan) {
    return '$plan PLAN';
  }

  @override
  String get billingPlanCurrentLabel => 'Current plan';

  @override
  String billingPlanUpgradeLabel(String name) {
    return 'Switch to $name →';
  }

  @override
  String get billingPlanDowngradeLabel => 'Downgrade';

  @override
  String billingUpgradeRequestTitle(String name) {
    return 'You are requesting an upgrade to $name.';
  }

  @override
  String get billingUpgradeRequestSubtitle =>
      'Our team will contact you for payment.';

  @override
  String get billingUpgradeConfirmButton => 'Confirm request';

  @override
  String get billingUpgradeSentTitle => 'Request sent! 🎉';

  @override
  String billingUpgradeReferenceLabel(String ref) {
    return 'Reference to include: $ref';
  }

  @override
  String get billingUpgradeShareButton => 'Share instructions';

  @override
  String get billingUpgradeDoneButton => 'Done';

  @override
  String get billingUpgradeReferenceCopied => 'Reference copied!';

  @override
  String get billingInvoicesLoadError => 'Unable to load invoices.';

  @override
  String get billingInvoicesEmptyTitle => 'No invoices';

  @override
  String get billingInvoicesEmptySubtitle =>
      'Your invoices will appear here after an upgrade request.';

  @override
  String get billingInvoiceStatusPaid => 'PAID';

  @override
  String get billingInvoiceStatusOverdue => 'OVERDUE';

  @override
  String get billingInvoiceStatusVoid => 'VOID';

  @override
  String get billingInvoiceStatusPending => 'PENDING';

  @override
  String get billingInvoicePaymentInstructionsTitle => 'Payment instructions';

  @override
  String get billingInvoiceExportPdfButton => 'Export invoice PDF';

  @override
  String get billingInvoiceShareButton => 'Share invoice';

  @override
  String get billingInvoiceMarkPaidButton => 'Mark as paid';

  @override
  String get upgradeSuccessTitle => 'Request sent! 🎉';

  @override
  String get upgradeSuccessSubtitle =>
      'Our team will contact you within 24h to finalise your upgrade.';

  @override
  String get upgradeSuccessNote =>
      'In the meantime, you can continue using KYNZA.';

  @override
  String get upgradeSuccessBackButton => 'Back to dashboard';

  @override
  String get salonMediaDeleteTitle => 'Delete this media?';

  @override
  String get salonMediaDeleteMessage =>
      'This action removes the media from your gallery.';

  @override
  String get dashboardTrendStable => '→ Stable';

  @override
  String get dashboardTrendGrowing => '↑ Growing';

  @override
  String get dashboardTrendDecreasing => '↓ Declining';

  @override
  String get dashboardBestWeekdayNone => 'Best day: —';

  @override
  String dashboardBestWeekday(String day) {
    return 'Best day: $day';
  }

  @override
  String get dashboardPeakHourNone => 'Peak hour: —';

  @override
  String dashboardPeakHour(int hour) {
    return 'Peak hour: ${hour}h';
  }

  @override
  String get auditEventUserLogin => 'Login';

  @override
  String get auditEventUserLogout => 'Logout';

  @override
  String get auditEventProfileUpdated => 'Profile updated';

  @override
  String get auditEventRoleChanged => 'Role changed';

  @override
  String get auditEventSalonUpdated => 'Salon updated';

  @override
  String get auditEventSalonStatusChanged => 'Salon status changed';

  @override
  String get auditEventStaffInvited => 'Invitation sent';

  @override
  String get auditEventStaffInvitationAccepted => 'Invitation accepted';

  @override
  String get auditEventStaffRemoved => 'Member removed';

  @override
  String get auditEventStaffJoined => 'New team member';

  @override
  String get auditEventBookingCreated => 'Booking created';

  @override
  String get auditEventBookingConfirmed => 'Booking confirmed';

  @override
  String get auditEventBookingCancelled => 'Booking cancelled';

  @override
  String get auditEventBookingCompleted => 'Booking completed';

  @override
  String get auditEventBookingNoShow => 'Client absent (no-show)';

  @override
  String get auditEventPaymentCompleted => 'Payment successful';

  @override
  String get auditEventPaymentFailed => 'Payment failed';

  @override
  String get auditEventRefundInitiated => 'Refund initiated';

  @override
  String get auditEventDiscountApplied => 'Discount applied';

  @override
  String get auditEventLoyaltyStampAdded => 'Loyalty stamp added';

  @override
  String get auditEventLoyaltyRewardRedeemed => 'Loyalty reward redeemed';

  @override
  String get auditEventReferralClaimed => 'Referral used';

  @override
  String get auditEventPermissionGroupCreated => 'Permission group created';

  @override
  String get auditEventPermissionGroupDeleted => 'Permission group deleted';

  @override
  String get auditEventPermissionGroupPermissionChanged => 'Permission changed';

  @override
  String get auditEventPermissionGroupMemberAdded => 'Member added to group';

  @override
  String get auditEventPermissionGroupMemberRemoved =>
      'Member removed from group';

  @override
  String promotionCardUsagesLabel(int uses) {
    return '$uses use(s)';
  }

  @override
  String promotionCardUsagesMaxLabel(int uses, int max) {
    return '$uses / $max use(s)';
  }

  @override
  String promotionCardUntilDate(String date) {
    return '· until $date';
  }

  @override
  String get contactSourceBooking => 'Booking';

  @override
  String get contactSourceReferral => 'Referral';

  @override
  String get contactSourceManual => 'Manual';

  @override
  String get billingPlanNameFree => 'Free';

  @override
  String get billingPlanNamePro => 'Pro';

  @override
  String get billingPlanNamePremium => 'Premium';

  @override
  String get marketingClientsImportError => 'Import failed.';

  @override
  String get marketingContactAddError => 'Failed to add contact.';

  @override
  String get commissionLoadError => 'Unable to load commissions.';

  @override
  String get commissionEmptyTitle => 'No commissions this month';

  @override
  String get commissionEmptySubtitle =>
      'Commissions will appear after completed appointments.';

  @override
  String get commissionMarkAllPaid => 'Mark all as paid';

  @override
  String get commissionStaffFallback => 'Staff';

  @override
  String get commissionBadgePaid => 'PAID';

  @override
  String get commissionBadgePending => 'PENDING';

  @override
  String get referralWelcomeTitle => 'Welcome to KYNZA! 🎉';

  @override
  String get referralStampGranted => 'A loyalty stamp has been gifted to you!';

  @override
  String referralStampGrantedWithSalon(String salon) {
    return 'A loyalty stamp at $salon has been gifted to you!';
  }

  @override
  String get referralInvalidLink => 'Invalid or already used invitation link.';

  @override
  String get automationLogEmptyTitle => 'No executions';

  @override
  String get automationLogEmptySubtitle =>
      'Workflow executions will appear here once a trigger fires.';

  @override
  String get automationLogLoadDetailError => 'Unable to load details.';

  @override
  String get automationLogLoadError => 'Unable to load history.';

  @override
  String get automationLogHistoryTitle => 'Execution history';

  @override
  String get dataPlatformDocumentTemplatesTitle => 'Document templates';

  @override
  String get dataPlatformTemplateTypeInvoice => 'Invoice';

  @override
  String get dataPlatformTemplateTypeReceipt => 'Receipt';

  @override
  String get dataPlatformTemplateTypeMonthlyReport => 'Monthly report';

  @override
  String get dataPlatformTemplateLoadError => 'Unable to load templates.';

  @override
  String get dataPlatformTemplateEmptyTitle => 'No templates';

  @override
  String get dataPlatformTemplateEmptySubtitle =>
      'Create custom templates for your invoices, receipts and reports.';

  @override
  String get dataPlatformTemplateCreateCta => 'Create a template';

  @override
  String get dataPlatformTemplateDeleteTitle => 'Delete template';

  @override
  String dataPlatformTemplateDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get dataPlatformTemplateDeleteSuccess => 'Template deleted.';

  @override
  String get dataPlatformTemplateDeleteError =>
      'Unable to delete this template.';

  @override
  String get dataPlatformTemplateBadgeDefault => 'DEFAULT';

  @override
  String get dataPlatformTemplateValidationError =>
      'Name and content are required.';

  @override
  String get dataPlatformTemplateEditTitle => 'Edit template';

  @override
  String get dataPlatformTemplateNewTitle => 'New template';

  @override
  String get dataPlatformTemplateNameLabel => 'Template name';

  @override
  String get dataPlatformTemplateTypeLabel => 'Type';

  @override
  String get dataPlatformTemplateVariablesTitle => 'Available variables';

  @override
  String get dataPlatformTemplateBodyLabel => 'Template content';

  @override
  String get dataPlatformTemplateBodyHint =>
      'Use the variable format to insert dynamic data.';

  @override
  String get dataPlatformTemplateIsDefaultLabel => 'Default template';

  @override
  String get dataPlatformTemplateSaveButton => 'Save';

  @override
  String get dataPlatformTemplateCreateButton => 'Create template';

  @override
  String get dataPlatformBackupTitle => 'Data backups';

  @override
  String get dataPlatformBackupLoadError => 'Unable to load backups.';

  @override
  String get dataPlatformBackupEmptyTitle => 'No backups';

  @override
  String get dataPlatformBackupEmptySubtitle =>
      'Create your first backup to archive your data.';

  @override
  String get dataPlatformBackupCreateCta => 'Create a backup';

  @override
  String get dataPlatformBackupDialogTitle => 'Create a backup';

  @override
  String get dataPlatformBackupDialogContent =>
      'Data from the last 90 days (bookings, clients, services, staff, reviews, invoices) will be exported and stored securely.';

  @override
  String get dataPlatformBackupCreateSuccess => 'Backup created successfully.';

  @override
  String get dataPlatformBackupSecureTitle => 'Secure backup';

  @override
  String get dataPlatformBackupSecureSubtitle =>
      'Export your data as an encrypted JSON file stored on our servers. Maximum one backup every 6 hours.';

  @override
  String get dataPlatformBackupCreateButton => 'Create a backup';

  @override
  String get settingFieldBookingAdvanceDays => 'Max booking advance (days)';

  @override
  String get settingFieldBookingSlotDuration => 'Slot duration (minutes)';

  @override
  String get settingFieldBookingCancellationHours =>
      'Cancellation delay (hours)';

  @override
  String get settingFieldBookingRequiresConfirmation => 'Requires confirmation';

  @override
  String get settingFieldBookingAllowWalkin => 'Allow walk-ins';

  @override
  String get settingFieldBookingMaxPerClientPerDay =>
      'Max bookings per client / day';

  @override
  String get settingFieldNotifSmsEnabled => 'SMS enabled';

  @override
  String get settingFieldNotifWhatsappEnabled => 'WhatsApp enabled';

  @override
  String get settingFieldNotifPushEnabled => 'Push notifications enabled';

  @override
  String get settingFieldNotifReminderHoursBefore =>
      'First reminder before appointment (hours)';

  @override
  String get settingFieldNotifReminderHoursBefore2 =>
      'Second reminder before appointment (hours)';

  @override
  String get settingFieldMarketingAutoReviewRequest =>
      'Automatic review request';

  @override
  String get settingFieldMarketingReviewRequestHoursAfter =>
      'Review request after appointment (hours)';

  @override
  String get settingFieldMarketingLoyaltyAutoStamp => 'Automatic loyalty stamp';

  @override
  String get settingFieldMarketingReferralBonusBif => 'Referral bonus (FBu)';

  @override
  String get settingFieldStaffShowEarnings => 'Show earnings to staff';

  @override
  String get settingFieldStaffCommissionAutoCalculate =>
      'Auto-calculate commissions';

  @override
  String get settingFieldStaffRequireCheckin => 'Require check-in';

  @override
  String get settingFieldLoyaltyStampsPerCard => 'Stamps per card';

  @override
  String get settingFieldLoyaltyRewardDescription => 'Reward description';

  @override
  String get settingFieldLoyaltyExpiryDays => 'Expiry (days)';

  @override
  String get settingFieldReviewsAutoPublish => 'Auto-publish';

  @override
  String get settingFieldReviewsModerationEnabled => 'Moderation enabled';

  @override
  String get settingFieldReviewsMinRatingAlert => 'Alert if rating ≤';

  @override
  String get settingFieldPaymentGracePeriodMinutes => 'Grace period (minutes)';

  @override
  String get settingFieldPaymentAutoInvoice => 'Auto-invoice';

  @override
  String get settingFieldTimezone => 'Timezone';

  @override
  String get settingFieldAdvancedDoubleBooking => 'Allow double-booking';

  @override
  String get settingFieldAdvancedOverbookingLimit => 'Overbooking limit';

  @override
  String get staffRoleManager => 'Manager';

  @override
  String get staffRoleStaff => 'Staff';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonMonthJanuary => 'January';

  @override
  String get commonMonthFebruary => 'February';

  @override
  String get commonMonthMarch => 'March';

  @override
  String get commonMonthApril => 'April';

  @override
  String get commonMonthMay => 'May';

  @override
  String get commonMonthJune => 'June';

  @override
  String get commonMonthJuly => 'July';

  @override
  String get commonMonthAugust => 'August';

  @override
  String get commonMonthSeptember => 'September';

  @override
  String get commonMonthOctober => 'October';

  @override
  String get commonMonthNovember => 'November';

  @override
  String get commonMonthDecember => 'December';

  @override
  String get homeClientCannotLoadSalons => 'Unable to load salons.';

  @override
  String get homeClientDiscoverTitle => 'Discover salons';

  @override
  String get homeClientNoSalonsSubtitle => 'No salons available right now.';

  @override
  String get homeClientSalonsNearYou => 'Salons near you';

  @override
  String get homeClientBookNextBeautyAppt =>
      'Book your next beauty appointment.';

  @override
  String get homeStaffProfileNotLinked => 'Profile not linked';

  @override
  String get homeStaffProfileNotLinkedSubtitle =>
      'Your account is not yet linked to a team. Ask your Owner for an invitation.';

  @override
  String get homeStaffNoApptTodayTitle => 'No appointments today';

  @override
  String get homeStaffFreeDay => 'Enjoy your free day!';

  @override
  String get homeStaffLaterToday => 'Later today';

  @override
  String get homeStaffNothingScheduled => 'Nothing scheduled for this date.';

  @override
  String get homeStaffNextAppointment => 'Next appointment';

  @override
  String get homeManagerDashboardBody => 'Phase 2 — Booking Engine coming soon';

  @override
  String get homeManagerDashboardCta => 'Features overview →';

  @override
  String get bookingLeaveReview => 'Leave a review';

  @override
  String get bookingReceiptTitle => 'Receipt';

  @override
  String get bookingReceiptSalon => 'Salon';

  @override
  String get bookingReceiptService => 'Service';

  @override
  String get bookingReceiptDate => 'Date';

  @override
  String get bookingReceiptTime => 'Time';

  @override
  String get bookingLastSlot => 'Last spot!';

  @override
  String get bookingTotal => 'Total';

  @override
  String get bookingDetailCompleteAndCollect => 'Complete & collect';

  @override
  String get bookingDetailMarkAbsent => 'Mark absent';

  @override
  String get bookingDetailMarkAbsentGrace => 'Mark absent (after +15 min)';

  @override
  String get bookingDetailCancelButton => 'Cancel appointment';

  @override
  String dataPlatformBackupRecordsExported(int count) {
    return '$count records';
  }

  @override
  String get commonOrdinalSuffixFirst => 'st';

  @override
  String get commonOrdinalSuffixOther => 'th';

  @override
  String get paymentRadarWaitMessage =>
      'Your request has been sent. Wait for the message on your phone.';

  @override
  String get legalCenterTitle => 'Legal Center';

  @override
  String get legalCenterLoadError => 'Unable to load legal documents.';

  @override
  String get legalCenterEmptyTitle => 'No documents available';

  @override
  String get legalCenterEmptySubtitle =>
      'Check back later, our legal documents are being published.';

  @override
  String get legalDocTypePrivacyPolicy => 'Privacy Policy';

  @override
  String get legalDocTypeTermsOfService => 'Terms of Service';

  @override
  String get legalDocTypeCookiePolicy => 'Cookie Policy';

  @override
  String get legalDocTypeAcceptableUsePolicy => 'Acceptable Use Policy';

  @override
  String get legalDocTypeRefundPolicy => 'Refund Policy';

  @override
  String get legalDocTypeCommunityGuidelines => 'Community Guidelines';

  @override
  String get legalDocTypeDataDeletionPolicy => 'Data Deletion Policy';

  @override
  String get legalDocTypeSupportPolicy => 'Support Policy';

  @override
  String get legalDocTypeLegalNotices => 'Legal Notices';

  @override
  String get policyViewerLoadError => 'Unable to load this document.';

  @override
  String get policyViewerHistoryLink => 'View version history';

  @override
  String get policyViewerAcceptButton => 'I accept';

  @override
  String get policyViewerAcceptedLabel => 'Already accepted';

  @override
  String get policyViewerAcceptedOfflineLabel =>
      'Acceptance saved offline — will sync';

  @override
  String get policyVersionHistoryTitle => 'Version history';

  @override
  String get policyVersionHistoryLoadError => 'Unable to load version history.';

  @override
  String get policyVersionHistoryEmptyTitle => 'No published version';

  @override
  String get policyVersionHistoryEmptySubtitle =>
      'This document has no published version yet.';

  @override
  String get policyVersionHistoryCurrentBadge => 'Current version';

  @override
  String get acceptanceHistoryTitle => 'My acceptances';

  @override
  String get acceptanceHistoryLoadError =>
      'Unable to load your acceptance history.';

  @override
  String get acceptanceHistoryEmptyTitle => 'No acceptance recorded';

  @override
  String get acceptanceHistoryEmptySubtitle =>
      'Documents you accept will appear here.';

  @override
  String get consentManagementTitle => 'Consent management';

  @override
  String get consentManagementLoadError =>
      'Unable to load your consent preferences.';

  @override
  String get consentTypeMarketingEmailsLabel => 'Marketing emails';

  @override
  String get consentTypeMarketingEmailsSubtitle =>
      'Receive our offers and news by email.';

  @override
  String get consentTypeAnalyticsLabel => 'Usage analytics';

  @override
  String get consentTypeAnalyticsSubtitle =>
      'Help us improve KYNZA by sharing anonymized usage data.';

  @override
  String get consentTypePushNotificationsLabel => 'Push notifications';

  @override
  String get consentTypePushNotificationsSubtitle =>
      'Receive reminders and alerts on your device.';

  @override
  String get consentTypeDataProcessingLabel => 'Personal data processing';

  @override
  String get consentTypeDataProcessingSubtitle =>
      'Allow processing of your data for the service to function.';

  @override
  String get dataRightsTitle => 'My data';

  @override
  String get dataRightsExportSectionTitle => 'Export my data';

  @override
  String get dataRightsExportDescription =>
      'Receive a copy of your personal KYNZA data.';

  @override
  String get dataRightsExportButton => 'Request an export';

  @override
  String get dataRightsDeletionSectionTitle => 'Delete my account';

  @override
  String get dataRightsDeletionDescription =>
      'Request permanent deletion of your account and data.';

  @override
  String get dataRightsDeletionButton => 'Request deletion';

  @override
  String get dataRightsDeletionConfirmTitle => 'Confirm request';

  @override
  String get dataRightsDeletionConfirmMessage =>
      'This starts a request to delete your account, handled by our team. Do you want to continue?';

  @override
  String get dataRightsRequestSubmitted => 'Your request has been sent.';

  @override
  String get dataRightsRequestsLoadError => 'Unable to load your requests.';

  @override
  String get dataRightsRequestsEmptyTitle => 'No pending request';

  @override
  String get dataRightsRequestsEmptySubtitle =>
      'Your data deletion requests will appear here.';

  @override
  String get dataRightsRequestStatusPending => 'Pending';

  @override
  String get dataRightsRequestStatusInReview => 'Under review';

  @override
  String get dataRightsRequestStatusCompleted => 'Completed';

  @override
  String get dataRightsRequestStatusRejected => 'Rejected';

  @override
  String get supportContactTitle => 'Contact us';

  @override
  String get supportContactDescription =>
      'A question or an issue? Our team is here to help.';

  @override
  String get supportContactEmailLabel => 'Email';

  @override
  String get supportContactPolicyLink => 'View support policy';

  @override
  String get policyUpdateBannerMessage =>
      'A legal document has been updated. Please review it.';

  @override
  String get policyUpdateBannerCta => 'Review';
}
