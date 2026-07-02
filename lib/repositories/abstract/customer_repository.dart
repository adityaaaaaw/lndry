import 'dart:typed_data';

import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';

/// Abstract contract for all customer-facing data operations.
/// Swap [MockCustomerRepository] → [ApiCustomerRepository] when backend is ready.
abstract interface class CustomerRepository {
  // ── Auth ────────────────────────────────────────────────────────────────────
  /// Request an OTP for [phone]. Returns challenge metadata.
  /// In dev mode [devOtp] may contain the OTP for quick testing.
  Future<SendOtpResult> sendOtp(String phone);

  /// Verify [otp] received for [phone] against the optional [challengeId].
  /// On success returns tokens and user profile.
  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String otp,
    String? challengeId,
    Map<String, dynamic>? device,
  });

  /// Refresh the access + refresh token pair.
  Future<TokenPair> refreshTokens();

  /// Invalidate the current refresh token on the server and clear local state.
  Future<void> logout();

  // ── Services / Categories ─────────────────────────────────────────────────
  Future<List<CategoryModel>> getCategories();

  Future<PaginatedResponse<VendorModel>> getVendors({
    String? categoryId,
    String? search,
    PaginationParams params,
  });

  Future<VendorModel> getVendorById(String vendorId);

  Future<List<ServiceModel>> getServicesByVendor(String vendorId);

  // ── Cart ──────────────────────────────────────────────────────────────────
  Future<CartModel> getCart();
  Future<CartModel> addToCart(
      {required String serviceId, required int quantity});
  Future<CartModel> removeFromCart(String cartItemId);
  Future<CartModel> updateCartItem(
      {required String cartItemId, required int quantity});
  Future<void> clearCart();

  // ── Orders ────────────────────────────────────────────────────────────────
  Future<PaginatedResponse<OrderModel>> getMyOrders({PaginationParams params});
  Future<OrderModel> getOrderById(String orderId);
  Future<OrderModel> placeOrder(PlaceOrderRequest request);
  Future<OrderModel> cancelOrder(String orderId, {String? reason});

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile(UpdateProfileRequest request);

  // ── Addresses ─────────────────────────────────────────────────────────────
  Future<List<AddressModel>> getAddresses();
  Future<AddressModel> addAddress(AddressModel address);
  Future<AddressModel> updateAddress(AddressModel address);
  Future<void> deleteAddress(String addressId);
  Future<void> setDefaultAddress(String addressId);

  // ── Search / Discovery ──────────────────────────────────────────────────
  /// Unified search across categories, garment types, and vendors.
  Future<SearchResults> search({
    required String query,
    double? lat,
    double? lng,
  });

  /// Autocomplete suggestions for the search bar.
  Future<List<SearchSuggestion>> getSearchSuggestions(String query);

  /// Get available filter options (sort options, garment types).
  Future<FilterOptions> getFilterOptions();

  // ── Pickup Slots ──────────────────────────────────────────────────────────
  /// Get available pickup slots for a vendor on a given date.
  /// Returns only slots with remaining capacity > 0.
  Future<List<PickupSlot>> getPickupSlots({
    required String vendorId,
    required String date,
  });

  /// Hold a pickup slot for 10 minutes.
  Future<SlotHoldResult> holdSlot({
    required String vendorId,
    required String slotId,
    required String date,
    String? quoteId,
  });

  /// Release a previously held slot.
  Future<void> releaseSlotHold(String holdId);

  // ── Order Draft / Quote ─────────────────────────────────────────────────----
  /// Create a backend quotation before holding a slot and preparing checkout.
  Future<QuoteResult> createQuote({
    required String vendorId,
    required String vendorServiceId,
    required List<QuoteGarmentLine> garmentLines,
    double? estimatedWeightKg,
  });

  /// Prepare an order draft before payment. Returns the draft ID and payable amount.
  Future<OrderDraftResult> prepareOrder({
    required String quoteId,
    required String addressId,
    required String slotId,
  });

  // ── Payments ──────────────────────────────────────────────────────────────
  /// Create a Razorpay payment order for an existing order or order draft.
  Future<PaymentOrderResult> createPaymentOrder({
    String? orderId,
    String? orderDraftId,
  });

  /// Verify a Razorpay payment signature.
  Future<PaymentVerificationResult> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? orderDraftId,
  });

  // ── Order Actions ─────────────────────────────────────────────────────────
  /// Reorder a previous order.
  Future<ReorderResult> reorder(String orderId);

  /// Get invoice for an order.
  Future<InvoiceResult> getOrderInvoice(String orderId);

  /// Get pickup or delivery OTP for an order.
  Future<OtpResult> getOrderOtp(String orderId, {required String purpose});

  // ── User Stats ──────────────────────────────────────────────────────────────
  /// Get user statistics (total orders, total spent, loyalty points).
  Future<UserStats> getUserStats();

  // ── Reviews ─────────────────────────────────────────────────────────────────
  /// Get reviews for a vendor.
  Future<PaginatedResponse<ReviewModel>> getVendorReviews(String vendorId,
      {PaginationParams params});

  /// Get the current user's own reviews.
  Future<PaginatedResponse<ReviewModel>> getMyReviews(
      {PaginationParams params});

  /// Create a review for an order (vendor rating).
  Future<ReviewModel> createReview({
    required String orderId,
    required int vendorRating,
    int? riderRating,
    String? comment,
  });

  /// Update an existing review.
  Future<ReviewModel> updateReview(
    String reviewId, {
    int? vendorRating,
    int? riderRating,
    String? comment,
  });

  /// Delete a review.
  Future<void> deleteReview(String reviewId);

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<List<NotificationModel>> getNotifications({PaginationParams params});
  Future<void> markNotificationRead(String notificationId);
  Future<void> markAllNotificationsRead();
  Future<void> deleteNotification(String notificationId);

  // ── Device Registration ───────────────────────────────────────────────
  Future<void> registerDevice({
    required String deviceId,
    required String platform,
    required String fcmToken,
    String? appVersion,
  });

  Future<void> unregisterDevice(String deviceId);

  // ── Notification Preferences ────────────────────────────────────────────────
  Future<NotificationPreferences> getNotificationPreferences();
  Future<NotificationPreferences> updateNotificationPreferences({
    bool? orderUpdates,
    bool? promotions,
    bool? newProducts,
    bool? deliveryUpdates,
    bool? priceDrops,
  });

  // ── Avatar ──────────────────────────────────────────────────────────────────
  /// Upload a profile avatar image. Returns the URL of the uploaded image.
  Future<String> uploadAvatar(String filePath);
}

// ── Search Result Types ───────────────────────────────────────────────────────-

class SearchResults {
  const SearchResults({
    required this.categories,
    required this.garmentTypes,
    required this.vendors,
  });

  final List<CategoryModel> categories;
  final List<SearchGarmentType> garmentTypes;
  final List<VendorModel> vendors;
}

class SearchGarmentType {
  const SearchGarmentType({
    required this.id,
    required this.name,
    this.slug,
    this.unit,
  });

  final String id;
  final String name;
  final String? slug;
  final String? unit;
}

class SearchSuggestion {
  const SearchSuggestion({
    required this.type,
    required this.text,
  });

  /// 'category', 'garment_type', or 'vendor'
  final String type;
  final String text;
}

class FilterOptions {
  const FilterOptions({
    required this.sortOptions,
    required this.garmentTypes,
  });

  final List<SortOption> sortOptions;
  final List<SearchGarmentType> garmentTypes;
}

class SortOption {
  const SortOption({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

// ── Quote Types ──────────────────────────────────────────────────────────────

class QuoteGarmentLine {
  const QuoteGarmentLine({
    required this.garmentTypeId,
    required this.quantity,
  });

  final String garmentTypeId;
  final int quantity;
}

class QuoteResult {
  const QuoteResult({
    required this.quoteId,
    required this.estimatePaise,
    this.expiresAt,
  });

  final String quoteId;
  final int estimatePaise;
  final DateTime? expiresAt;
}

// ── Auth Result Types ─────────────────────────────────────────────────────────

class SendOtpResult {
  const SendOtpResult({
    required this.challengeId,
    required this.expiresIn,
    this.devOtp,
  });

  /// Unique challenge identifier returned by the backend.
  final String challengeId;

  /// OTP expiry in seconds (typically 300).
  final int expiresIn;

  /// Only populated in development mode — the actual OTP value.
  /// Null in production/staging (OTP is sent via SMS).
  final String? devOtp;
}

class VerifyOtpResult {
  const VerifyOtpResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.isNewUser,
  });

  final String accessToken;
  final String refreshToken;
  final UserModel user;

  /// True when this is the user's first login and they need profile setup.
  final bool isNewUser;
}

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

// ── Payment Types ────────────────────────────────────────────────────────────

/// Result of creating a Razorpay payment order.
class PaymentOrderResult {
  const PaymentOrderResult({
    required this.paymentId,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    this.keyId,
  });

  final String paymentId;
  final String razorpayOrderId;
  final double amount;
  final String currency;
  final String? keyId;
}

/// Result of verifying a Razorpay payment.
class PaymentVerificationResult {
  const PaymentVerificationResult({
    required this.success,
    this.paymentId,
    this.razorpayPaymentId,
    this.orderId,
    this.status,
  });

  final bool success;
  final String? paymentId;
  final String? razorpayPaymentId;
  final String? orderId;
  final String? status;
}

// ── Pickup Slot Types ────────────────────────────────────────────────────────

/// A pickup slot returned by the backend.
class PickupSlot {
  const PickupSlot({
    required this.id,
    required this.vendorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.label,
    required this.remainingCapacity,
    required this.isActive,
  });

  final String id;
  final String vendorId;
  final String date; // 'YYYY-MM-DD'
  final String startTime; // '09:00'
  final String endTime; // '10:00'
  final String? label; // e.g. 'Morning slot'
  final int remainingCapacity;
  final bool isActive;
}

/// Result of a successful slot hold.
class SlotHoldResult {
  const SlotHoldResult({
    required this.holdId,
    required this.slotId,
    this.expiresAt,
  });

  final String holdId;
  final String slotId;
  final DateTime? expiresAt;
}

/// Result of POST /orders/prepare.
class OrderDraftResult {
  const OrderDraftResult({
    required this.orderDraftId,
    required this.payableAmountPaise,
    this.snapshot,
  });

  final String orderDraftId;
  final int payableAmountPaise;
  final Map<String, dynamic>? snapshot;
}

// ── Request DTOs (no freezed needed for simple request objects) ───────────────

class PlaceOrderRequest {
  const PlaceOrderRequest({
    this.vendorId,
    this.vendorSlotId,
    this.items = const [],
    this.deliveryAddressId,
    this.pickupAddressId,
    this.paymentMethod,
    this.scheduledPickupAt,
    this.notes,
    this.orderDraftId,
  });

  /// For draft-based placement, provide [orderDraftId]; for legacy direct
  /// placement provide the fields below.
  final String? orderDraftId;

  /// Legacy direct placement fields.
  final String? vendorId;
  final String? vendorSlotId;
  final List<OrderItemRequest> items;
  final String? deliveryAddressId;
  final String? pickupAddressId;
  final PaymentMethod? paymentMethod;
  final DateTime? scheduledPickupAt;
  final String? notes;
}

class OrderItemRequest {
  const OrderItemRequest({
    required this.serviceId,
    required this.quantity,
  });
  final String serviceId;
  final int quantity;
}

// ── Invoice / OTP Types ──────────────────────────────────────────────────────

/// Invoice data returned by GET /orders/:id/invoice.
class InvoiceResult {
  const InvoiceResult({
    required this.id,
    required this.orderId,
    required this.invoiceUrl,
    required this.amount,
    required this.gst,
    required this.platformFee,
    required this.total,
    required this.generatedAt,
    this.pdfUrl,
    this.pdfBytes,
    this.fileName,
  });

  final String id;
  final String orderId;
  final String invoiceUrl;
  final double amount;
  final double gst;
  final double platformFee;
  final double total;
  final DateTime generatedAt;
  final String? pdfUrl;
  final Uint8List? pdfBytes;
  final String? fileName;
}

/// OTP data returned by GET /orders/:id/otp.
class OtpResult {
  const OtpResult({
    required this.otp,
    required this.expiresAt,
    required this.type,
    this.isVerified = false,
  });

  /// The 6-digit OTP string.
  final String otp;

  /// Expiry timestamp.
  final DateTime expiresAt;

  /// 'pickup' or 'delivery'.
  final String type;

  /// Whether this OTP has already been verified.
  final bool isVerified;
}

class ReorderResult {
  const ReorderResult({
    required this.success,
    required this.message,
    this.itemCount = 0,
    this.warnings = const [],
  });

  final bool success;
  final String message;
  final int itemCount;
  final List<String> warnings;
}

// ── User Stats Types ─────────────────────────────────────────────────────────

class UserStats {
  const UserStats({
    required this.totalOrders,
    required this.totalSpent,
    this.loyaltyPoints = 0,
  });

  final int totalOrders;
  final double totalSpent;
  final int loyaltyPoints;
}

// ── Review Model ───────────────────────────────────────────────────────────────

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.vendorId,
    required this.vendorRating,
    this.riderRating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userAvatarUrl,
  });

  final String id;
  final String userId;
  final String orderId;
  final String vendorId;
  final int vendorRating; // 1–5
  final int? riderRating; // 1–5 (optional)
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userName;
  final String? userAvatarUrl;
}

// ── Notification Preferences ───────────────────────────────────────────────────

class NotificationPreferences {
  const NotificationPreferences({
    this.orderUpdates = true,
    this.promotions = false,
    this.newProducts = false,
    this.deliveryUpdates = true,
    this.priceDrops = false,
  });

  final bool orderUpdates;
  final bool promotions;
  final bool newProducts;
  final bool deliveryUpdates;
  final bool priceDrops;
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.name,
    this.email,
    this.avatarUrl,
  });
  final String? name;
  final String? email;
  final String? avatarUrl;
}
