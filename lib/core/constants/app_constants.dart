/// LNDRY App-wide Constants
abstract final class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'LNDRY';
  static const String appTagline = 'Fresh clothes, delivered fast.';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String bundleId = 'com.lndry.app';
  static const String supportEmail = 'support@lndry.app';
  static const String privacyPolicyUrl = 'https://lndry.app/privacy';
  static const String termsOfServiceUrl = 'https://lndry.app/terms';
  static const String refundPolicyUrl = 'https://lndry.app/refunds';

  // ── Storage Keys ──────────────────────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyFcmToken = 'fcm_token';
  static const String keyDeviceId = 'device_id';

  // ── Notification Preference Keys ──────────────────────────────────────────
  static const String keyPushNotifications = 'pref_push_notifications';
  static const String keyWhatsappUpdates = 'pref_whatsapp_updates';

  // ── Hive Box Names ────────────────────────────────────────────────────────
  static const String hiveBoxUser = 'user_box';
  static const String hiveBoxOrders = 'orders_box';
  static const String hiveBoxSettings = 'settings_box';

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // ── NOTE: Platform fee and GST constants have been intentionally removed.
  // All money calculations are performed server-side and returned as integer
  // paise. Flutter only formats and displays server-provided amounts.
  // See spec §6 "Money rule" and §11 "Remove local commercial calculations".

  // ── Map / Location ────────────────────────────────────────────────────────
  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946; // Bengaluru fallback only
  static const double deliveryRadiusKm = 10.0;

  // ── OTP ───────────────────────────────────────────────────────────────────
  static const int otpLength = 6; // backend-configurable; UI uses this default
  static const int otpResendSeconds = 30;

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const int sessionTimeoutMinutes = 30;
  static const int maxImageUploadMb = 5;
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const String defaultLocale = 'en_IN';
}
