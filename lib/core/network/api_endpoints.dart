/// LNDRY API endpoint path constants.
/// Paths are relative to [Env.baseUrl] (which already includes `/api/v1`).
abstract final class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String deleteAccount = '/auth/account';
  static const String session = '/auth/session';
  static const String myRoles = '/auth/my-roles';
  static const String selectRole = '/auth/select-role';

  // ── Users ───────────────────────────────────────────────────────────────────
  static const String userProfile = '/users/me';
  static const String userStats = '/users/me/stats';

  // ── Customer Profile ────────────────────────────────────────────────────────
  static const String customerProfile = '/customer/me';

  // ── Discovery ───────────────────────────────────────────────────────────────
  static const String home = '/discovery/home';
  static const String vendors = '/discovery/vendors';
  static const String vendorById = '/discovery/vendors'; // + /:vendorId
  static const String vendorServices = '/discovery/vendors'; // + /:vendorId/services
  static const String serviceDetails = '/discovery/services'; // + /:serviceId
  static const String search = '/discovery/search';
  static const String searchSuggestions = '/discovery/search/suggestions';
  static const String filterOptions = '/discovery/filters';

  // ── Service Categories ──────────────────────────────────────────────────────
  static const String categories = '/service-categories';

  // ── Pickup Slots ────────────────────────────────────────────────────────────
  static String pickupSlots(String vendorId) =>
      '/vendors/$vendorId/pickup-slots';
  static const String slotHolds = '/slot-holds'; // DELETE /slot-holds/:holdId

  // ── Orders ──────────────────────────────────────────────────────────────────
  static const String quotes = '/quotes';
  static const String orders = '/orders';
  static const String orderPrepare = '/orders/prepare';
  static const String orderActive = '/orders/active';
  static String orderById(String id) => '/orders/$id';
  static String cancelOrder(String id) => '/orders/$id/cancel';
  static String reorder(String id) => '/orders/$id/reorder';
  static String orderInvoice(String id) => '/orders/$id/invoice';
  static String orderOtp(String id) => '/orders/$id/otp';

  // ── Payments ────────────────────────────────────────────────────────────────
  static const String createPaymentOrder = '/payments/create-order';
  static const String verifyPayment = '/payments/verify';
  static const String paymentHistory = '/payments/history';

  // ── Addresses ───────────────────────────────────────────────────────────────
  static const String addresses = '/addresses';
  static String addressById(String id) => '/addresses/$id';
  static String defaultAddress(String id) => '/addresses/$id/default';
  static const String validateLocation = '/addresses/validate-location';
  static const String validatePincode = '/addresses/validate-pincode';

  // ── Notifications ───────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllRead = '/notifications/read-all';
  static const String notificationPreferences = '/notifications/preferences';
  static const String registerDeviceToken = '/notifications/tokens';

  // ── Reviews ─────────────────────────────────────────────────────────────────
  static String vendorReviews(String vendorId) => '/reviews/vendors/$vendorId';
  static String reviewEligibility(String id) => '/reviews/eligibility/$id';
  static const String myReviews = '/reviews/my-reviews';
  static const String reviews = '/reviews';

  // ── Misc Public ─────────────────────────────────────────────────────────────
  static const String banners = '/banners';
  static const String theme = '/theme';
  static const String tipPresets = '/tip-presets';
  static const String paymentOffers = '/payment-offers';
}
