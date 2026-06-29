import 'flavors.dart';

/// LNDRY Environment Configuration
/// Resolves the correct API base URL and feature flags per flavor.
abstract final class Env {
  Env._();

  static final AppFlavor _flavor = AppFlavor.current;

  // ── API ───────────────────────────────────────────────────────────────────
  /// Base URL for the active flavor. Returns mock URL until backend exists.
  static String get baseUrl => switch (_flavor) {
        AppFlavor.development => 'https://api-dev.lndry.app/v1',
        AppFlavor.staging     => 'https://api-staging.lndry.app/v1',
        AppFlavor.production  => 'https://api.lndry.app/v1',
      };

  // ── Feature Flags ─────────────────────────────────────────────────────────

  /// When true, uses mock repositories instead of real API calls.
  /// Will be false once backend is available in staging/prod.
  static bool get useMocks => _flavor.isDev;

  /// Show debug overlay (FPS, layout borders, etc.)
  static bool get showDebugBanner => _flavor.isDev;

  /// Enable Crashlytics / error reporting
  static bool get enableCrashlytics => _flavor.isProduction;

  /// Enable Analytics
  static bool get enableAnalytics => !_flavor.isDev;

  // ── Keys (inject via --dart-define) ──────────────────────────────────────
  static const String googleMapsKey = String.fromEnvironment(
    'GOOGLE_MAPS_KEY',
    defaultValue: '',
  );

  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: '',
  );

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;

  // ── App Info ──────────────────────────────────────────────────────────────
  static AppFlavor get flavor => _flavor;
  static String get flavorLabel => _flavor.label;
}
