/// LNDRY App-wide Constants
abstract final class AppConstants {
  AppConstants._();

  // ── Developer Preview Mode ────────────────────────────────────────────────
  static const bool kDeveloperPreview = true;

  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'LNDRY';
  static const String appTagline = 'Fresh clothes, delivered fast.';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String bundleId = 'com.lndry.app';
  static const String supportEmail = 'support@lndry.app';
  static const String privacyPolicyUrl = 'https://lndry.app/privacy';
  static const String termsOfServiceUrl = 'https://lndry.app/terms';

  // ── API ───────────────────────────────────────────────────────────────────
  static const String baseUrlDev = 'https://api-dev.lndry.app/v1';
  static const String baseUrlStaging = 'https://api-staging.lndry.app/v1';
  static const String baseUrlProd = 'https://api.lndry.app/v1';
  static const int connectTimeout = 30000; // ms
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

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

  // ── Hive Box Names ────────────────────────────────────────────────────────
  static const String hiveBoxUser = 'user_box';
  static const String hiveBoxOrders = 'orders_box';
  static const String hiveBoxCart = 'cart_box';
  static const String hiveBoxSettings = 'settings_box';

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // ── Order ─────────────────────────────────────────────────────────────────
  static const double minimumOrderAmount = 99.0;
  static const double platformFeePercent = 0.05; // 5%
  static const double gstPercent = 0.18;         // 18%

  // ── Map / Location ────────────────────────────────────────────────────────
  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946; // Bengaluru
  static const double deliveryRadiusKm = 10.0;

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationSlower = Duration(milliseconds: 600);
  static const Duration durationSplash = Duration(milliseconds: 2200);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const int otpLength = 4;
  static const int otpResendSeconds = 30;
  static const int sessionTimeoutMinutes = 30;
  static const int maxImageUploadMb = 5;
  static const int maxImagesPerOrder = 4;
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const String defaultLocale = 'en_IN';
}
