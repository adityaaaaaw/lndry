/// LNDRY Route Path Constants
abstract final class AppRoutes {
  AppRoutes._();

  // ── Auth & Onboarding ─────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String locationPermission = '/location-permission';
  static const String mapAddress = '/map-address';

  // ── Main Dashboard Tabs ───────────────────────────────────────────────────
  static const String home = '/home';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String profile = '/profile';

  // ── Sub-routes / Detail pages ─────────────────────────────────────────────
  static const String category = '/category/:categoryId';
  static const String vendorListing = '/vendors';
  static const String vendorDetails = '/vendor/:vendorId';
  static const String checkout = '/checkout';
  static const String payment = '/checkout/payment';
  static const String orderConfirmation = '/checkout/confirmation/:orderId';
  static const String orderDetails = '/orders/details/:orderId';
  static const String address = '/profile/address';
  static const String notifications = '/profile/notifications';
  static const String editProfile = '/profile/edit';
  static const String settings = '/profile/settings';
  static const String help = '/profile/help';
}

/// LNDRY Route Name Constants (for named navigation)
abstract final class AppRouteNames {
  AppRouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String otp = 'otp';
  static const String profileSetup = 'profile-setup';
  static const String locationPermission = 'location-permission';
  static const String mapAddress = 'map-address';

  // Tabs
  static const String home = 'home';
  static const String search = 'search';
  static const String cart = 'cart';
  static const String orders = 'orders';
  static const String profile = 'profile';

  // Sub-routes / Detail pages
  static const String category = 'category';
  static const String vendorListing = 'vendor-listing';
  static const String vendorDetails = 'vendor-details';
  static const String checkout = 'checkout';
  static const String payment = 'payment';
  static const String orderConfirmation = 'order-confirmation';
  static const String orderDetails = 'order-details';
  static const String address = 'address';
  static const String notifications = 'notifications';
  static const String editProfile = 'edit-profile';
  static const String settings = 'settings';
  static const String help = 'help';
}
