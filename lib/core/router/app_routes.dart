import 'package:flutter/widgets.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// LNDRY Route Path Constants
/// Matches the canonical route inventory in spec Appendix B.
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

  // ── Dashboard Tabs ────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String profile = '/profile';

  // ── Discovery ─────────────────────────────────────────────────────────────
  static const String category = '/category/:categoryId';
  static const String vendorListing = '/vendors';
  static const String vendorDetails = '/vendor/:vendorId';

  // ── Checkout / Booking ────────────────────────────────────────────────────
  static const String checkout = '/checkout';
  static const String payment = '/checkout/payment';

  // ── Orders ────────────────────────────────────────────────────────────────
  /// Post-payment confirmation: /orders/:orderId/submitted
  static const String orderConfirmation = '/orders/:orderId/submitted';

  /// Order detail + tracking: registered as sub-route 'details/:orderId'
  /// under /orders, so full path = /orders/details/:orderId.
  static const String orderDetails = '/orders/details/:orderId';

  // ── Profile sub-routes ─────────────────────────────────────────────────────
  static const String editProfile = '/profile/edit';
  static const String address = '/profile/address';
  static const String notifications = '/profile/notifications';
  static const String myReviews = '/profile/reviews';
  static const String settings = '/profile/settings';
  static const String help = '/profile/help';
}

/// LNDRY Route Name Constants (for named navigation via context.goNamed).
abstract final class AppRouteNames {
  AppRouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String otp = 'otp';
  static const String profileSetup = 'profile-setup';
  static const String locationPermission = 'location-permission';
  static const String mapAddress = 'map-address';

  static const String home = 'home';
  static const String search = 'search';
  static const String cart = 'cart';
  static const String orders = 'orders';
  static const String profile = 'profile';

  static const String category = 'category';
  static const String vendorListing = 'vendor-listing';
  static const String vendorDetails = 'vendor-details';

  static const String checkout = 'checkout';
  static const String payment = 'payment';
  static const String orderConfirmation = 'order-confirmation';
  static const String orderDetails = 'order-details';

  static const String editProfile = 'edit-profile';
  static const String address = 'address';
  static const String notifications = 'notifications';
  static const String myReviews = 'my-reviews';
  static const String settings = 'settings';
  static const String help = 'help';
}
