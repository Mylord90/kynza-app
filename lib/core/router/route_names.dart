abstract class RouteNames {
  static const splash = '/';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const verifyEmail = '/auth/verify-email';
  static const callback = '/auth/callback';
  static const completeProfile = '/auth/complete-profile';
  static const acceptInvitation = '/accept-invitation';
  static const homeOwner = '/owner/dashboard';
  static const homeManager = '/manager/dashboard';
  static const homeStaff = '/staff/today';
  static const homeClient = '/client/home';

  // Phase 2 — Subphase A
  static const ownerSalonCreate = '/owner/salon/create';

  // Phase 2 — Subphase B
  static const ownerServices = '/owner/services';

  // Phase 2 — Subphase C
  static const ownerStaff = '/owner/staff';

  // Phase 2 — Subphase D
  static const ownerAvailability = '/owner/availability';

  // Phase 2.2 — Module 1: Notifications
  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';

  // Phase 2.2 — Module 3: Advanced availability
  static const ownerAvailabilitySalon = '/owner/availability/salon';
  static const ownerAvailabilityStaff = '/owner/availability/staff/:staffId';
  static const ownerAvailabilityBreaks = '/owner/availability/breaks';
  static const ownerAvailabilityExceptions = '/owner/availability/exceptions';
  static const staffAvailability = '/staff/availability';

  static String ownerAvailabilityStaffPath(String staffId) =>
      '/owner/availability/staff/$staffId';

  // Phase 2 — Subphase F/G
  static const clientDiscover = '/client/discover';
  static const clientSalonDetail = '/client/salon/:id';
  static const clientBooking = '/client/booking';
  static const clientPayment = '/client/payment/:id';
  static const clientBookingConfirm = '/client/booking/confirm';

  static String clientSalonDetailPath(String id) => '/client/salon/$id';

  // Phase 3A — Loyalty + Reviews + Owner Journey + Marketing
  static const ownerMarketing = '/owner/marketing';
  static const ownerMarketingClients = '/owner/marketing/clients';
  static const ownerMarketingPromotions = '/owner/marketing/promotions';
  static const ownerMarketingLoyalty = '/owner/marketing/loyalty';
  static const ownerShare = '/owner/share';
  static const ownerReviews = '/owner/reviews';
  static const clientLoyalty = '/client/loyalty';
  static const clientBookings = '/client/bookings';
  static const clientProfile = '/client/profile';
  static const clientReview = '/client/review/:bookingId';

  static String clientReviewPath(String bookingId) =>
      '/client/review/$bookingId';

  static String clientPaymentPath(String id) => '/client/payment/$id';

  // Phase 3B — Deep linking + Loyalty QR + Notifications
  static const acceptReferral = '/accept-referral';
  static const clientLoyaltyQr = '/client/loyalty/qr/:cardId';
  static const ownerLoyaltyScan = '/owner/loyalty/scan';

  static String clientLoyaltyQrPath(String cardId) =>
      '/client/loyalty/qr/$cardId';

  // Phase 4 — Owner Dashboard Enterprise
  static const ownerAnalytics = '/owner/analytics';
  static const ownerAnalyticsClients = '/owner/analytics/clients';
  static const ownerAnalyticsTeam = '/owner/analytics/team';
  static const ownerAnalyticsForecast = '/owner/analytics/forecast';
  static const ownerAuditLogs = '/owner/audit-logs';

  // Phase 5 — Team Management + Commissions
  static const ownerTeam = '/owner/team';
  static const ownerTeamDetail = '/owner/team/:staffId';
  static const ownerTeamCommissions = '/owner/team/commissions';
  static const staffPerformance = '/staff/performance';

  static String ownerTeamDetailPath(String staffId) => '/owner/team/$staffId';

  // Phase 6 — Subscriptions + Billing
  static const ownerSubscription = '/owner/subscription';
  static const ownerBilling = '/owner/billing';
  static const ownerBillingInvoices = '/owner/billing/invoices';
  static const ownerBillingSuccess = '/owner/billing/success';

  // Advanced — Search
  static const search = '/search';

  // Enterprise Foundation V2 — Phase 1.1: RBAC
  static const ownerPermissionGroups = '/owner/permissions';
  static const ownerPermissionGroupDetail = '/owner/permissions/:groupId';

  static String ownerPermissionGroupDetailPath(String groupId) =>
      '/owner/permissions/$groupId';

  // Enterprise Foundation V2 — Phase 1.4: Centre de Configuration
  static const ownerSettings = '/owner/settings';

  // Enterprise Foundation V2 — Phase 2: Automation Platform
  static const ownerAutomation = '/owner/automation';

  // Enterprise Foundation V2 — Phase 3: Data Platform
  static const ownerBackup = '/owner/backup';
  static const ownerTemplates = '/owner/templates';

  // Enterprise Foundation V2 — Phase 4: Evolution Platform
  static const ownerFeatureFlags = '/owner/feature-flags';
  static const maintenance = '/maintenance';
  static const forceUpdate = '/force-update';

  // Backend Enterprise Completion — Phase 4: Remote Configuration
  static const ownerRemoteConfig = '/owner/remote-config';

  // Backend Enterprise Completion — Phase 2/5: Observability + Health Center
  static const ownerHealthCenter = '/owner/health-center';

  // Backend Enterprise Completion — Phase 9: CMS Enterprise
  static const ownerCmsAdmin = '/owner/cms-admin';
  static const helpCenter = '/help-center';

  // ProxiPay V1 — QR-based in-person payment
  static const ownerProxiPay = '/owner/proxipay/:bookingId';
  static const clientProxiPayScan = '/client/proxipay/scan';

  static String ownerProxiPayPath(String bookingId) =>
      '/owner/proxipay/$bookingId';

  // Branding — À propos
  static const ownerAbout = '/owner/about';

  // i18n — Language settings
  static const ownerLanguage = '/owner/language';

  // Enterprise Hardening Phase 3 — Legal Center Infrastructure
  static const legalCenter = '/legal';
  static const legalDocument = '/legal/:slug';
  static const legalDocumentHistory = '/legal/:slug/history';
  static const legalAcceptanceHistory = '/legal/my-acceptances';
  static const legalSupportContact = '/legal/support-contact';
  static const settingsConsent = '/settings/consent';
  static const settingsDataRights = '/settings/data-rights';

  static String legalDocumentPath(String slug) => '/legal/$slug';
  static String legalDocumentHistoryPath(String slug) =>
      '/legal/$slug/history';
}
