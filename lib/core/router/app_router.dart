import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/providers/auth_notifier_provider.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/home_client/presentation/screens/home_client_screen.dart';
import '../../features/home_manager/presentation/screens/home_manager_screen.dart';
import '../../features/home_owner/presentation/screens/home_owner_screen.dart';
import '../../features/home_staff/presentation/screens/home_staff_screen.dart';
import '../../features/availability/presentation/screens/availability_management_screen.dart';
import '../../features/availability/presentation/screens/breaks_management_screen.dart';
import '../../features/availability/presentation/screens/exceptions_calendar_screen.dart';
import '../../features/availability/presentation/screens/salon_hours_screen.dart';
import '../../features/availability/presentation/screens/staff_hours_screen.dart';
import '../../features/availability/presentation/screens/staff_picker_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/marketing/presentation/screens/invite_clients_screen.dart';
import '../../features/marketing/presentation/screens/loyalty_setup_screen.dart';
import '../../features/marketing/presentation/screens/marketing_dashboard_screen.dart';
import '../../features/marketing/presentation/screens/promotion_center_screen.dart';
import '../../features/marketing/presentation/screens/social_share_center_screen.dart';
import '../../features/home_client/presentation/screens/client_bookings_screen.dart';
import '../../features/home_client/presentation/screens/client_profile_screen.dart';
import '../../features/dashboard/presentation/screens/advanced_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/audit_log_screen.dart';
import '../../features/permissions/presentation/screens/permission_group_detail_screen.dart';
import '../../features/permissions/presentation/screens/permission_groups_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/language_settings_screen.dart';
import '../../features/settings/presentation/screens/settings_home_screen.dart';
import '../../features/legal/presentation/screens/acceptance_history_screen.dart';
import '../../features/legal/presentation/screens/consent_management_screen.dart';
import '../../features/legal/presentation/screens/data_rights_screen.dart';
import '../../features/legal/presentation/screens/legal_center_screen.dart';
import '../../features/legal/presentation/screens/policy_version_history_screen.dart';
import '../../features/legal/presentation/screens/policy_viewer_screen.dart';
import '../../features/legal/presentation/screens/support_contact_screen.dart';
import '../../features/automation/presentation/screens/automation_list_screen.dart';
import '../../features/data_platform/backup/presentation/screens/backup_screen.dart';
import '../../features/data_platform/templates/presentation/screens/template_list_screen.dart';
import '../../core/models/app_version_check_model.dart';
import '../../core/models/maintenance_window_model.dart';
import '../../features/evolution/audit_business/presentation/screens/audit_center_screen.dart';
import '../../features/evolution/cms/presentation/screens/cms_admin_screen.dart';
import '../../features/evolution/cms/presentation/screens/help_center_screen.dart';
import '../../features/evolution/feature_flags/presentation/screens/feature_flag_screen.dart';
import '../../features/evolution/health_center/presentation/screens/health_center_screen.dart';
import '../../features/evolution/remote_config/presentation/screens/remote_config_screen.dart';
import '../localization/extensions/build_context_l10n_extension.dart';
import '../../features/evolution/maintenance/application/providers/maintenance_providers.dart';
import '../../features/evolution/maintenance/presentation/screens/maintenance_admin_screen.dart';
import '../../features/evolution/maintenance/presentation/screens/maintenance_screen.dart';
import '../../features/evolution/version_manager/application/providers/version_providers.dart';
import '../../features/evolution/version_manager/presentation/screens/force_update_screen.dart';
import '../../features/loyalty/presentation/screens/client_loyalty_screen.dart';
import '../../features/loyalty/presentation/screens/loyalty_qr_screen.dart';
import '../../features/loyalty/presentation/screens/loyalty_scan_screen.dart';
import '../../features/referral/presentation/screens/referral_claim_screen.dart';
import '../../features/reviews/presentation/screens/leave_review_screen.dart';
import '../../features/reviews/presentation/screens/owner_reviews_screen.dart';
import '../../features/staff/application/providers/staff_providers.dart';
import '../../features/booking/application/providers/booking_flow_provider.dart';
import '../../features/booking/application/providers/booking_providers.dart';
import '../../features/booking/presentation/screens/salon_detail_screen.dart';
import '../../features/booking/presentation/screens/salon_discovery_screen.dart';
import '../../features/booking/presentation/screens/service_selection_screen.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/proxipay/presentation/screens/proxipay_qr_screen.dart';
import '../../features/proxipay/presentation/screens/proxipay_scan_screen.dart';
import '../../features/salon/application/providers/salon_providers.dart';
import '../../shared/widgets/kynza_widgets.dart';
import '../../features/salon/presentation/screens/salon_creation_wizard_screen.dart';
import '../../features/services/presentation/screens/services_list_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen_1.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen_2.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen_3.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/billing/presentation/screens/billing_screen.dart';
import '../../features/billing/presentation/screens/invoice_history_screen.dart';
import '../../features/billing/presentation/screens/subscription_plans_screen.dart';
import '../../features/billing/presentation/screens/upgrade_success_screen.dart';
import '../../features/search/presentation/screens/advanced_search_screen.dart';
import '../../features/staff/presentation/screens/accept_invitation_screen.dart';
import '../../features/staff/presentation/screens/my_performance_screen.dart';
import '../../features/staff/presentation/screens/staff_detail_screen.dart';
import '../../features/staff/presentation/screens/staff_list_screen.dart';
import '../../features/team/presentation/screens/commission_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_curves.dart';
import '../constants/app_durations.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../enums/user_role.dart';
import '../providers/app_providers.dart';
import '../utils/auth_redirect.dart';
import '../widgets/kynza_full_page_lock.dart';
import 'auth_callback_screen.dart';
import 'deep_link_handler.dart';
import 'route_names.dart';

/// Exposed so non-widget code (e.g. FCM foreground/tap handlers) can reach
/// the current [BuildContext] without threading it through every callback.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The router's whole redirect decision — same 3-branch/7-state logic as
/// always, only extracted out of `appRouterProvider`'s `GoRouter(redirect:
/// ...)` closure so it's directly testable: a `ProviderContainer` with
/// overridden providers plus a throwaway `GoRouter` (for [router]'s
/// `.configuration`) exercises this exact function, with no widget pumped
/// and no real Hive/Supabase I/O — `redirect` callbacks normally require a
/// `BuildContext` sourced from a mounted `Router` widget (go_router's
/// `parseRouteInformationWithDependencies` needs one), which is why this
/// wasn't testable in isolation before; nothing here still needs one.
String? computeAppRedirect({
  required Ref ref,
  required GoRouterState state,
  required GoRouter router,
}) {
  // Incoming com.kynza.app:// deep links always carry a URI host
  // (in-app context.go/push navigation never does) — rewrite them to
  // the real route before any path-based matching below.
  if (state.uri.host.isNotEmpty) {
    final rewritten = DeepLinkHandler.parseRoute(state.uri);
    if (rewritten != null) return rewritten;
  }

  final path = state.matchedLocation;
  final isAuthRoute = path.startsWith('/auth');
  final isSplash = path == RouteNames.splash;
  final isOnboarding = path.startsWith('/onboarding');
  final isAcceptInvitation =
      path == RouteNames.acceptInvitation ||
      path == RouteNames.acceptReferral;
  final isGuestRoute =
      path == RouteNames.login ||
      path == RouteNames.register ||
      path == RouteNames.forgotPassword;

  final authValue = ref.read(authNotifierProvider);
  if (authValue.isLoading) return null;

  final authState = authValue.valueOrNull;
  if (authState == null) return null;

  return authState.when(
    initial: () => null,
    loading: () => null,
    error: (_) => null,
    // The splash screen owns its own minimum-display-time transition
    // (see SplashScreen) — the generic guard never touches '/'.
    unauthenticated: () {
      if (isAuthRoute || isSplash || isOnboarding || isAcceptInvitation) {
        return null;
      }
      return RouteNames.login;
    },
    authenticated: (user) {
      if (isGuestRoute) return redirectAfterAuth(user);

      // Force-update gate — blocks all navigation when the installed
      // version is below the minimum required (checked once on login,
      // re-checked when the user taps "Vérifier à nouveau").
      if (path != RouteNames.forceUpdate) {
        final versionAsync = ref.read(appVersionCheckProvider);
        if (versionAsync is AsyncData<AppVersionCheckModel?> &&
            versionAsync.value?.updateRequired == true) {
          return RouteNames.forceUpdate;
        }
      }

      // Maintenance gate — blocks all navigation during an active window.
      // MaintenanceScreen polls every 30 s and invalidates the provider
      // when maintenance ends, which triggers a fresh redirect evaluation.
      if (path != RouteNames.maintenance) {
        final maintenanceAsync = ref.read(maintenanceStatusProvider);
        if (maintenanceAsync is AsyncData<MaintenanceWindowModel?> &&
            maintenanceAsync.value?.isActive == true) {
          return RouteNames.maintenance;
        }
      }

      // Cold-start FCM deep link replay (D3). A pending invitation/
      // referral token (SessionService — see resolvePostAuthRoute) is a
      // deliberate action and always wins: the push intent is left armed
      // for the next redirect() evaluation instead of being consumed and
      // discarded here, so it isn't silently lost to a race with
      // whichever navigation call happens to reach this branch first.
      final sessionService = ref.read(sessionServiceProvider);
      final hasPendingDeliberateIntent =
          sessionService.getPendingInvitationToken() != null ||
          sessionService.getPendingReferralToken() != null;
      if (!hasPendingDeliberateIntent) {
        final pendingDeepLink = DeepLinkHandler.consumePendingIntent(
          router.configuration,
        );
        if (pendingDeepLink != null) return pendingDeepLink;
      }

      return null;
    },
    emailNotVerified: (email, userId) {
      if (path == RouteNames.verifyEmail || path == RouteNames.callback) {
        return null;
      }
      return RouteNames.verifyEmail;
    },
    profileIncomplete: (userId) {
      if (path == RouteNames.completeProfile || path == RouteNames.callback) {
        return null;
      }
      return RouteNames.completeProfile;
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  // Forward reference: computeAppRedirect needs the router's own
  // RouteConfiguration but is itself passed into GoRouter's constructor —
  // assigned below, read only once redirect is actually invoked, always
  // after construction completes.
  late final GoRouter router;

  router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) =>
        computeAppRedirect(ref: ref, state: state, router: router),
    routes: [
      _fadeRoute(RouteNames.splash, (context, state) => const SplashScreen()),
      _fadeRoute(
        RouteNames.onboarding,
        (context, state) => OnboardingScreen1(
          onNext: () => context.go(RouteNames.onboardingStep2),
        ),
      ),
      _fadeRoute(
        RouteNames.onboardingStep2,
        (context, state) => OnboardingScreen2(
          onNext: () => context.go(RouteNames.onboardingStep3),
        ),
      ),
      _fadeRoute(
        RouteNames.onboardingStep3,
        (context, state) => OnboardingScreen3(
          onNext: () {
            ref.read(sessionServiceProvider).markOnboardingDone();
            context.go(RouteNames.login);
          },
          // Pushed (not go()) so the back button/gesture from Login returns
          // here rather than unwinding the whole onboarding stack. Marks
          // onboarding done up front too — otherwise a user who signs in
          // via this shortcut and later signs out would see the onboarding
          // carousel again next launch, despite already knowing the app.
          onSignIn: () {
            ref.read(sessionServiceProvider).markOnboardingDone();
            context.push(RouteNames.login);
          },
        ),
      ),
      _fadeRoute(RouteNames.login, (context, state) => const LoginScreen()),
      _fadeRoute(
        RouteNames.register,
        (context, state) => const RegisterScreen(),
      ),
      _fadeRoute(
        RouteNames.forgotPassword,
        (context, state) => const ForgotPasswordScreen(),
      ),
      _fadeRoute(
        RouteNames.resetPassword,
        (context, state) => const ResetPasswordScreen(),
      ),
      _fadeRoute(
        RouteNames.verifyEmail,
        (context, state) => const VerifyEmailScreen(),
      ),
      _fadeRoute(
        RouteNames.callback,
        (context, state) => const AuthCallbackScreen(),
      ),
      _fadeRoute(
        RouteNames.acceptInvitation,
        (context, state) =>
            AcceptInvitationScreen(token: state.uri.queryParameters['token']),
      ),
      _fadeRoute(
        RouteNames.completeProfile,
        (context, state) => const CompleteProfileScreen(),
      ),
      _fadeRoute(
        RouteNames.homeOwner,
        (context, state) =>
            const _RoleGuard(role: UserRole.owner, child: HomeOwnerScreen()),
      ),
      _fadeRoute(
        RouteNames.homeManager,
        (context, state) => const _RoleGuard(
          role: UserRole.manager,
          child: HomeManagerScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.homeStaff,
        (context, state) =>
            const _RoleGuard(role: UserRole.staff, child: HomeStaffScreen()),
      ),
      _fadeRoute(
        RouteNames.homeClient,
        (context, state) =>
            const _RoleGuard(role: UserRole.client, child: HomeClientScreen()),
      ),
      _fadeRoute(
        RouteNames.ownerSalonCreate,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerOnboardingGuard(child: SalonCreationWizardScreen()),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerServices,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: ServicesListScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerStaff,
        (context, state) =>
            const _RoleGuard(role: UserRole.owner, child: StaffListScreen()),
      ),
      _fadeRoute(
        RouteNames.ownerAvailability,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: AvailabilityManagementScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.clientDiscover,
        (context, state) => const _RoleGuard(
          role: UserRole.client,
          child: SalonDiscoveryScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.clientSalonDetail,
        (context, state) => _RoleGuard(
          role: UserRole.client,
          child: SalonDetailScreen(salonId: state.pathParameters['id']!),
        ),
      ),
      _fadeRoute(
        RouteNames.clientBooking,
        (context, state) => const _RoleGuard(
          role: UserRole.client,
          child: _BookingEntryGuard(),
        ),
      ),
      _fadeRoute(
        RouteNames.clientPayment,
        (context, state) => _RoleGuard(
          role: UserRole.client,
          child: _PaymentDeepLinkLoader(bookingId: state.pathParameters['id']!),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerProxiPay,
        (context, state) => _RoleGuard.anyOf(
          roles: const {UserRole.owner, UserRole.manager, UserRole.staff},
          child: _ProxiPayLoader(bookingId: state.pathParameters['bookingId']!),
        ),
      ),
      _fadeRoute(
        RouteNames.clientProxiPayScan,
        (context, state) => const _RoleGuard(
          role: UserRole.client,
          child: ProxiPayScanScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.notifications,
        (context, state) => const NotificationsScreen(),
      ),
      _fadeRoute(
        RouteNames.notificationSettings,
        (context, state) => const NotificationSettingsScreen(),
      ),
      _fadeRoute(
        RouteNames.ownerAvailabilitySalon,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: SalonHoursScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerAvailabilityStaff,
        (context, state) => _RoleGuard.anyOf(
          roles: const {UserRole.owner, UserRole.manager},
          child: _OwnerStaffHoursLoader(
            staffId: state.pathParameters['staffId']!,
          ),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerAvailabilityBreaks,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: _OwnerBreaksPickerLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerAvailabilityExceptions,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: _OwnerExceptionsLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.staffAvailability,
        (context, state) => const _RoleGuard(
          role: UserRole.staff,
          child: _StaffOwnHoursLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerMarketing,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: _OwnerMarketingLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerMarketingClients,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: _OwnerInviteClientsLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerMarketingPromotions,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: _OwnerPromotionsLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerMarketingLoyalty,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: _OwnerLoyaltySetupLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerShare,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: _OwnerShareLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.clientLoyalty,
        (context, state) => _RoleGuard(
          role: UserRole.client,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Mes Fidélités')),
            body: const ClientLoyaltyScreen(),
          ),
        ),
      ),
      _fadeRoute(
        RouteNames.clientBookings,
        (context, state) => _RoleGuard(
          role: UserRole.client,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Mes RDV')),
            body: const ClientBookingsScreen(),
          ),
        ),
      ),
      _fadeRoute(
        RouteNames.clientProfile,
        (context, state) => _RoleGuard(
          role: UserRole.client,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Mon Profil')),
            body: const ClientProfileScreen(),
          ),
        ),
      ),
      _fadeRoute(
        RouteNames.clientReview,
        (context, state) => _RoleGuard(
          role: UserRole.client,
          child: LeaveReviewScreen(
            bookingId: state.pathParameters['bookingId']!,
          ),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerReviews,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: _OwnerReviewsLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.acceptReferral,
        (context, state) =>
            ReferralClaimScreen(token: state.uri.queryParameters['token']),
      ),
      _fadeRoute(
        RouteNames.clientLoyaltyQr,
        (context, state) => _RoleGuard(
          role: UserRole.client,
          child: LoyaltyQrScreen(cardId: state.pathParameters['cardId']!),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerLoyaltyScan,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager, UserRole.staff},
          child: LoyaltyScanScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerAnalytics,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerAnalyticsLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerAnalyticsClients,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerAnalyticsLoader(initialIndex: 1),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerAnalyticsTeam,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerAnalyticsLoader(initialIndex: 2),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerAnalyticsForecast,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerAnalyticsLoader(initialIndex: 3),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerAuditLogs,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerAuditLogLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerPermissionGroups,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerPermissionGroupsLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerPermissionGroupDetail,
        (context, state) => _RoleGuard(
          role: UserRole.owner,
          child: _OwnerPermissionGroupDetailLoader(
            groupId: state.pathParameters['groupId']!,
          ),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerSettings,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerSettingsLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerAutomation,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerAutomationLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerBackup,
        (context, state) =>
            const _RoleGuard(role: UserRole.owner, child: _OwnerBackupLoader()),
      ),
      _fadeRoute(
        RouteNames.ownerTemplates,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerTemplatesLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerFeatureFlags,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerFeatureFlagsLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerRemoteConfig,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: RemoteConfigScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerHealthCenter,
        (context, state) => const _SystemAdminGuard(child: HealthCenterScreen()),
      ),
      _fadeRoute(
        RouteNames.ownerCmsAdmin,
        (context, state) => const _SystemAdminGuard(child: CmsAdminScreen()),
      ),
      _fadeRoute(
        RouteNames.helpCenter,
        (context, state) => const HelpCenterScreen(),
      ),
      _fadeRoute(
        RouteNames.ownerAuditCenter,
        (context, state) => const _SystemAdminGuard(child: AuditCenterScreen()),
      ),
      _fadeRoute(
        RouteNames.ownerMaintenanceAdmin,
        (context, state) =>
            const _SystemAdminGuard(child: MaintenanceAdminScreen()),
      ),
      _fadeRoute(
        RouteNames.maintenance,
        (context, state) => const MaintenanceScreen(),
      ),
      _fadeRoute(
        RouteNames.forceUpdate,
        (context, state) => const ForceUpdateScreen(),
      ),
      _fadeRoute(
        RouteNames.ownerAbout,
        (context, state) =>
            const _RoleGuard(role: UserRole.owner, child: AboutScreen()),
      ),
      _fadeRoute(
        RouteNames.ownerLanguage,
        (context, state) => const LanguageSettingsScreen(),
      ),
      _fadeRoute(
        RouteNames.legalCenter,
        (context, state) => const LegalCenterScreen(),
      ),
      _fadeRoute(
        RouteNames.legalDocument,
        (context, state) =>
            PolicyViewerScreen(slug: state.pathParameters['slug']!),
      ),
      _fadeRoute(
        RouteNames.legalDocumentHistory,
        (context, state) =>
            PolicyVersionHistoryScreen(slug: state.pathParameters['slug']!),
      ),
      _fadeRoute(
        RouteNames.legalAcceptanceHistory,
        (context, state) => const AcceptanceHistoryScreen(),
      ),
      _fadeRoute(
        RouteNames.legalSupportContact,
        (context, state) => const SupportContactScreen(),
      ),
      _fadeRoute(
        RouteNames.settingsConsent,
        (context, state) => const ConsentManagementScreen(),
      ),
      _fadeRoute(
        RouteNames.settingsDataRights,
        (context, state) => const DataRightsScreen(),
      ),
      _fadeRoute(
        RouteNames.ownerTeam,
        (context, state) =>
            const _RoleGuard(role: UserRole.owner, child: StaffListScreen()),
      ),
      _fadeRoute(
        RouteNames.ownerTeamDetail,
        (context, state) => _RoleGuard(
          role: UserRole.owner,
          child: _OwnerTeamDetailLoader(
            staffId: state.pathParameters['staffId']!,
          ),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerTeamCommissions,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerTeamCommissionsLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.staffPerformance,
        (context, state) => const _RoleGuard(
          role: UserRole.staff,
          child: _StaffPerformanceLoader(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerSubscription,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: SubscriptionPlansScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerBilling,
        (context, state) =>
            const _RoleGuard(role: UserRole.owner, child: BillingScreen()),
      ),
      _fadeRoute(
        RouteNames.ownerBillingInvoices,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: InvoiceHistoryScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerBillingSuccess,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: UpgradeSuccessScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.search,
        (context, state) => const _RoleGuard(
          role: UserRole.client,
          child: AdvancedSearchScreen(),
        ),
      ),
    ],
  );
  return router;
});

/// Premium push transition — fade + a short rightward settle, decelerating
/// into place. Every route uses this same builder so the whole app feels
/// consistent; per-route variants (modal/dialog-style) can be added later
/// without touching call sites since they all funnel through here.
GoRoute _fadeRoute(
  String path,
  Widget Function(BuildContext, GoRouterState) builder,
) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: builder(context, state),
      transitionDuration: AppDurations.pageTransition,
      reverseTransitionDuration: AppDurations.standard,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.decelerate,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Bridges Riverpod providers to GoRouter's refreshListenable so navigation
/// re-evaluates whenever auth state, maintenance status, or version check changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    _authSub = ref.listen(authNotifierProvider, (_, __) => notifyListeners());
    _maintenanceSub = ref.listen(
      maintenanceStatusProvider,
      (_, __) => notifyListeners(),
    );
    _versionSub = ref.listen(
      appVersionCheckProvider,
      (_, __) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<Object?>> _authSub;
  late final ProviderSubscription<AsyncValue<MaintenanceWindowModel?>>
  _maintenanceSub;
  late final ProviderSubscription<AsyncValue<AppVersionCheckModel?>>
  _versionSub;

  @override
  void dispose() {
    _authSub.close();
    _maintenanceSub.close();
    _versionSub.close();
    super.dispose();
  }
}

class _RoleGuard extends ConsumerWidget {
  const _RoleGuard({required UserRole role, required this.child})
    : roles = const {},
      _singleRole = role;

  const _RoleGuard.anyOf({required this.roles, required this.child})
    : _singleRole = null;

  final UserRole? _singleRole;
  final Set<UserRole> roles;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = _singleRole != null ? {_singleRole} : roles;
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final currentRole = authState?.whenOrNull(
      authenticated: (user) => user.role,
    );
    if (currentRole != null && !allowed.contains(currentRole)) {
      return KynzaFullPageLock(requiredRole: allowed.first);
    }
    return child;
  }
}

/// Entry point for `/client/booking` deep links — resumes the in-progress
/// tunnel if a salon was already selected (e.g. Fast-Pass), otherwise
/// sends the client back to discovery rather than a dead end (R04).
class _BookingEntryGuard extends ConsumerWidget {
  const _BookingEntryGuard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(bookingFlowProvider);
    return flowState.selectedSalon == null
        ? const SalonDiscoveryScreen()
        : const ServiceSelectionScreen();
  }
}

/// `/client/payment/:id` deep link — fetches the booking by id before
/// handing off to [PaymentScreen], which needs the full model, not just
/// the id (e.g. resuming a payment from a push notification).
class _PaymentDeepLinkLoader extends ConsumerWidget {
  const _PaymentDeepLinkLoader({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));
    return bookingAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: TextButton(
            onPressed: () => context.go(RouteNames.homeClient),
            child: const Text('Réservation introuvable — retour à l\'accueil'),
          ),
        ),
      ),
      data: (booking) => booking == null
          ? Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: TextButton(
                  onPressed: () => context.go(RouteNames.homeClient),
                  child: const Text(
                    'Réservation introuvable — retour à l\'accueil',
                  ),
                ),
              ),
            )
          : PaymentScreen(booking: booking),
    );
  }
}

class _ProxiPayLoader extends ConsumerWidget {
  const _ProxiPayLoader({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));
    return bookingAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: TextButton(
            onPressed: () => context.go(RouteNames.homeOwner),
            child: const Text('Réservation introuvable — retour à l\'accueil'),
          ),
        ),
      ),
      data: (booking) => booking == null
          ? Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: TextButton(
                  onPressed: () => context.go(RouteNames.homeOwner),
                  child: const Text(
                    'Réservation introuvable — retour à l\'accueil',
                  ),
                ),
              ),
            )
          : ProxiPayQrScreen(booking: booking),
    );
  }
}

/// The salon creation wizard must never be re-enterable once a salon
/// already exists — checked here against the live `ownerSalonProvider`
/// (not the auth cache, which is not guaranteed to reflect a salon
/// created moments ago) so this never silently redirects mid-flow.
class _OwnerOnboardingGuard extends ConsumerWidget {
  const _OwnerOnboardingGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store, size: 64, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Vous avez déjà un salon',
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  salon.name,
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => context.go(RouteNames.homeOwner),
                  child: const Text('Aller au tableau de bord →'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return child;
  }
}

/// `/owner/availability/staff/:staffId` deep link — resolves the owner's
/// salon and the staff member's display name before handing off, since
/// [StaffHoursScreen] needs both, not just the path's staffId.
class _OwnerStaffHoursLoader extends ConsumerWidget {
  const _OwnerStaffHoursLoader({required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    final staff = ref.watch(salonStaffProvider(salon.id)).valueOrNull;
    final member = staff?.where((s) => s.id == staffId).firstOrNull;
    return StaffHoursScreen(
      staffId: staffId,
      salonId: salon.id,
      staffName: member?.displayName,
    );
  }
}

/// `/owner/availability/breaks` deep link — lands on the staff picker;
/// selecting one pushes [BreaksManagementScreen] via Navigator, same as
/// the in-app hub navigation (kynza-flutter-architecture.md — no
/// duplicated routing logic between deep links and in-app taps).
class _OwnerBreaksPickerLoader extends ConsumerWidget {
  const _OwnerBreaksPickerLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return StaffPickerScreen(
      salonId: salon.id,
      title: 'Pauses & absences',
      onSelect: (member) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BreaksManagementScreen(
            staffId: member.id!,
            salonId: salon.id,
            staffName: member.displayName,
          ),
        ),
      ),
    );
  }
}

class _OwnerExceptionsLoader extends ConsumerWidget {
  const _OwnerExceptionsLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return ExceptionsCalendarScreen(salonId: salon.id);
  }
}

/// `/staff/availability` — a staff member's own self-service hours
/// screen, resolved from their own staff_profiles row (never a path
/// param — a staff session must only ever reach their own staffId).
class _StaffOwnHoursLoader extends ConsumerWidget {
  const _StaffOwnHoursLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(myStaffProfileProvider);
    return staffAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: TextButton(
            onPressed: () => context.go(RouteNames.homeStaff),
            child: const Text('Profil introuvable — retour à l\'accueil'),
          ),
        ),
      ),
      data: (staff) => staff == null
          ? Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: TextButton(
                  onPressed: () => context.go(RouteNames.homeStaff),
                  child: const Text('Profil introuvable — retour à l\'accueil'),
                ),
              ),
            )
          : StaffHoursScreen(staffId: staff.id!, salonId: staff.salonId),
    );
  }
}

/// Phase 3A owner/manager deep links all share the same "resolve the
/// owner's salon first" shape as the availability loaders above.
class _OwnerMarketingLoader extends ConsumerWidget {
  const _OwnerMarketingLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return MarketingDashboardScreen(salonId: salon.id);
  }
}

class _OwnerInviteClientsLoader extends ConsumerWidget {
  const _OwnerInviteClientsLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return InviteClientsScreen(salonId: salon.id);
  }
}

class _OwnerPromotionsLoader extends ConsumerWidget {
  const _OwnerPromotionsLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return PromotionCenterScreen(salonId: salon.id);
  }
}

class _OwnerLoyaltySetupLoader extends ConsumerWidget {
  const _OwnerLoyaltySetupLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return LoyaltySetupScreen(salonId: salon.id);
  }
}

class _OwnerShareLoader extends ConsumerWidget {
  const _OwnerShareLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return SocialShareCenterScreen(salonId: salon.id);
  }
}

class _OwnerReviewsLoader extends ConsumerWidget {
  const _OwnerReviewsLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return OwnerReviewsScreen(salonId: salon.id);
  }
}

class _OwnerAnalyticsLoader extends ConsumerWidget {
  const _OwnerAnalyticsLoader({this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return AdvancedDashboardScreen(
      salonId: salon.id,
      initialIndex: initialIndex,
    );
  }
}

class _OwnerAuditLogLoader extends ConsumerWidget {
  const _OwnerAuditLogLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return AuditLogScreen(salonId: salon.id);
  }
}

class _OwnerPermissionGroupsLoader extends ConsumerWidget {
  const _OwnerPermissionGroupsLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return PermissionGroupsScreen(salonId: salon.id);
  }
}

class _OwnerPermissionGroupDetailLoader extends ConsumerWidget {
  const _OwnerPermissionGroupDetailLoader({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return PermissionGroupDetailScreen(salonId: salon.id, groupId: groupId);
  }
}

class _OwnerSettingsLoader extends ConsumerWidget {
  const _OwnerSettingsLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return SettingsHomeScreen(salonId: salon.id);
  }
}

class _OwnerAutomationLoader extends ConsumerWidget {
  const _OwnerAutomationLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return AutomationListScreen(salonId: salon.id);
  }
}

class _OwnerBackupLoader extends ConsumerWidget {
  const _OwnerBackupLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return BackupScreen(salonId: salon.id);
  }
}

/// Gates `/owner/health-center` — SYSTEM_ADMIN scope (Phase 1 audit finding,
/// docs/backend-completion/PHASE_1_FINAL_AUDIT.md §3 item 9), stricter than
/// the plain owner `_RoleGuard`: an owner who is not also flagged
/// `is_system_admin` in `public.users` still sees the lock screen.
class _SystemAdminGuard extends ConsumerWidget {
  const _SystemAdminGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final isSystemAdmin = authState?.whenOrNull(
      authenticated: (user) => user.role == UserRole.owner && user.isSystemAdmin,
    );
    if (isSystemAdmin != true) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: AppColors.textMuted),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.evolutionHealthCenterForbiddenTitle,
                  style: AppTypography.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.evolutionHealthCenterForbiddenSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return child;
  }
}

class _OwnerFeatureFlagsLoader extends ConsumerWidget {
  const _OwnerFeatureFlagsLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return FeatureFlagScreen(salonId: salon.id);
  }
}

class _OwnerTemplatesLoader extends ConsumerWidget {
  const _OwnerTemplatesLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return TemplateListScreen(salonId: salon.id);
  }
}

class _OwnerTeamDetailLoader extends ConsumerWidget {
  const _OwnerTeamDetailLoader({required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    final staff = ref.watch(salonStaffProvider(salon.id)).valueOrNull;
    final member = staff?.where((s) => s.id == staffId).firstOrNull;
    if (member == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: TextButton(
            onPressed: () => context.go(RouteNames.ownerTeam),
            child: const Text('Membre introuvable — retour à l\'équipe'),
          ),
        ),
      );
    }
    return StaffDetailScreen(staff: member);
  }
}

class _OwnerTeamCommissionsLoader extends ConsumerWidget {
  const _OwnerTeamCommissionsLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      );
    }
    return CommissionScreen(salonId: salon.id);
  }
}

class _StaffPerformanceLoader extends ConsumerWidget {
  const _StaffPerformanceLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(myStaffProfileProvider);
    return staffAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoaderInline(size: KynzaLoaderSize.large),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: TextButton(
            onPressed: () => context.go(RouteNames.homeStaff),
            child: const Text('Profil introuvable — retour à l\'accueil'),
          ),
        ),
      ),
      data: (staff) => staff == null
          ? Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: TextButton(
                  onPressed: () => context.go(RouteNames.homeStaff),
                  child: const Text('Profil introuvable — retour à l\'accueil'),
                ),
              ),
            )
          : Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(title: const Text('Ma Performance')),
              body: Column(
                children: [
                  const KynzaOfflineBanner(),
                  Expanded(child: MyPerformanceScreen(staffId: staff.id!)),
                ],
              ),
            ),
    );
  }
}
