import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/repositories/api_customer_repository.dart';
import '../../config/env.dart';
import '../../core/network/network.dart';
import '../../core/services/storage_service.dart';
import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';
import '../abstract/customer_repository.dart';

/// Mock implementation of [CustomerRepository].
/// Reads data from assets/mock/*.json files.
/// Replace this with [ApiCustomerRepository] when backend is available —
/// the UI layer never needs to change because it only depends on the abstract interface.
class MockCustomerRepository implements CustomerRepository {
  MockCustomerRepository();

  // ── Auth (mock implementation for offline dev) ─────────────────────────────

  @override
  Future<SendOtpResult> sendOtp(String phone) async {
    await _delay();
    return SendOtpResult(
      challengeId: 'mock_challenge_${DateTime.now().millisecondsSinceEpoch}',
      expiresIn: 300,
      devOtp: '1234',
    );
  }

  @override
  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String otp,
    String? challengeId,
    Map<String, dynamic>? device,
  }) async {
    await _delay();
    if (otp == '1234') {
      return VerifyOtpResult(
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
        user: UserModel(
          id: 'usr_${phone.hashCode.abs()}',
          name: 'Test User',
          phone: phone,
          email: 'test@example.com',
          role: UserRole.customer,
          isVerified: true,
        ),
        isNewUser: false,
      );
    }
    throw const ApiException(
      message: 'Invalid OTP. Please try again.',
      code: 'INVALID_OTP',
    );
  }

  @override
  Future<TokenPair> refreshTokens() async {
    return const TokenPair(
      accessToken: 'mock_access_token_refreshed',
      refreshToken: 'mock_refresh_token_refreshed',
    );
  }

  @override
  Future<void> logout() async {
    // No-op in mock mode
  }

  // ── Categories ────────────────────────────────────────────────────────────

  @override
  Future<List<CategoryModel>> getCategories() async {
    await _delay();
    final data = await _loadJson('categories');
    return (data as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Vendors ───────────────────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<VendorModel>> getVendors({
    String? categoryId,
    String? search,
    PaginationParams params = const PaginationParams(),
  }) async {
    await _delay();
    final data = await _loadJson('vendors');
    var vendors = (data as List)
        .map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (categoryId != null) {
      vendors =
          vendors.where((v) => v.categoryIds.contains(categoryId)).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      vendors = vendors
          .where((v) =>
              v.name.toLowerCase().contains(q) ||
              v.description.toLowerCase().contains(q))
          .toList();
    }

    final total = vendors.length;
    final offset = (params.page - 1) * params.pageSize;
    final items = vendors.skip(offset).take(params.pageSize).toList();

    return PaginatedResponse(
      items: items,
      meta: PaginationMeta(
        currentPage: params.page,
        totalPages: (total / params.pageSize).ceil().clamp(1, 9999),
        totalItems: total,
        pageSize: params.pageSize,
      ),
    );
  }

  @override
  Future<VendorModel> getVendorById(String vendorId) async {
    await _delay();
    final data = await _loadJson('vendors');
    final json = (data as List).firstWhere(
      (e) => (e as Map<String, dynamic>)['id'] == vendorId,
      orElse: () => throw Exception('Vendor $vendorId not found'),
    );
    return VendorModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<ServiceModel>> getServicesByVendor(String vendorId) async {
    await _delay();
    final data = await _loadJson('services');
    return (data as List)
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .where((s) => s.vendorId == vendorId)
        .toList();
  }

  // ── Cart ──────────────────────────────────────────────────────────────────

  final List<CartItem> _cartItems = [];

  @override
  Future<CartModel> getCart() async {
    await _delay(fast: true);
    return _buildCart();
  }

  @override
  Future<CartModel> addToCart({
    required String serviceId,
    required int quantity,
  }) async {
    await _delay(fast: true);
    final existing = _cartItems.indexWhere((i) => i.serviceId == serviceId);
    if (existing >= 0) {
      _cartItems[existing] = _cartItems[existing].copyWith(
        quantity: _cartItems[existing].quantity + quantity,
      );
    } else {
      _cartItems.add(CartItem(
        id: 'ci_${DateTime.now().millisecondsSinceEpoch}',
        serviceId: serviceId,
        quantity: quantity,
      ));
    }
    return _buildCart();
  }

  @override
  Future<CartModel> removeFromCart(String cartItemId) async {
    await _delay(fast: true);
    _cartItems.removeWhere((i) => i.id == cartItemId);
    return _buildCart();
  }

  @override
  Future<CartModel> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async {
    await _delay(fast: true);
    if (quantity <= 0) return removeFromCart(cartItemId);
    final idx = _cartItems.indexWhere((i) => i.id == cartItemId);
    if (idx >= 0) {
      _cartItems[idx] = _cartItems[idx].copyWith(quantity: quantity);
    }
    return _buildCart();
  }

  @override
  Future<void> clearCart() async {
    _cartItems.clear();
  }

  CartModel _buildCart() => CartModel(items: List.unmodifiable(_cartItems));

  // ── Orders ────────────────────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<OrderModel>> getMyOrders({
    PaginationParams params = const PaginationParams(),
  }) async {
    await _delay();
    final data = await _loadJson('orders');
    final orders = (data as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = orders.length;
    final offset = (params.page - 1) * params.pageSize;
    final items = orders.skip(offset).take(params.pageSize).toList();
    return PaginatedResponse(
      items: items,
      meta: PaginationMeta(
        currentPage: params.page,
        totalPages: (total / params.pageSize).ceil().clamp(1, 9999),
        totalItems: total,
        pageSize: params.pageSize,
      ),
    );
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    await _delay();
    final data = await _loadJson('orders');
    final json = (data as List).firstWhere(
      (e) => (e as Map<String, dynamic>)['id'] == orderId,
      orElse: () => throw Exception('Order $orderId not found'),
    );
    return OrderModel.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<OrderModel> placeOrder(PlaceOrderRequest request) async {
    await _delay();
    // Draft-based placement: return a sensible mock order
    if (request.orderDraftId != null && request.orderDraftId!.isNotEmpty) {
      return OrderModel(
        id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
        customerId: 'usr_demo',
        vendorId: 'vndr_demo',
        items: [
          OrderItem(
              serviceId: 'svc_mock_1',
              serviceName: 'Wash & Fold',
              quantity: 3,
              unitPrice: 199,
              totalPrice: 597),
          OrderItem(
              serviceId: 'svc_mock_2',
              serviceName: 'Steam Iron',
              quantity: 5,
              unitPrice: 99,
              totalPrice: 495),
        ],
        status: OrderStatus.waitingForVendorConfirmation,
        subtotal: 1092.0,
        platformFee: 54.60,
        gstAmount: 196.56,
        total: 1343.16,
        paymentMethod: PaymentMethod.upi,
        pickupAddressId: 'addr_1',
        deliveryAddressId: 'addr_1',
        scheduledPickupAt: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
      );
    }

    // Legacy direct placement
    return OrderModel(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      customerId: 'usr_demo',
      vendorId: request.vendorId ?? 'vndr_demo',
      items: request.items
          .map((i) => OrderItem(
                serviceId: i.serviceId,
                serviceName: 'Service',
                quantity: i.quantity,
                unitPrice: 199,
                totalPrice: i.quantity * 199,
              ))
          .toList(),
      status: OrderStatus.waitingForVendorConfirmation,
      subtotal: request.items.fold(0.0, (s, i) => s + i.quantity * 199),
      platformFee:
          request.items.fold(0.0, (s, i) => s + i.quantity * 199) * 0.05,
      gstAmount: request.items.fold(0.0, (s, i) => s + i.quantity * 199) * 0.18,
      total: request.items.fold(0.0, (s, i) => s + i.quantity * 199) * 1.23,
      paymentMethod: request.paymentMethod ?? PaymentMethod.upi,
      pickupAddressId: request.pickupAddressId ?? 'addr_1',
      deliveryAddressId: request.deliveryAddressId ?? 'addr_1',
      scheduledPickupAt: request.scheduledPickupAt ??
          DateTime.now().add(const Duration(hours: 2)),
      customerNotes: request.notes,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<OrderModel> cancelOrder(String orderId, {String? reason}) async {
    await _delay();
    final order = await getOrderById(orderId);
    return order.copyWith(
      status: OrderStatus.customerCancelled,
      cancellationReason: reason,
      updatedAt: DateTime.now(),
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  UserModel _mockUser = const UserModel(
    id: 'usr_demo',
    name: 'Aditya Kumar',
    phone: '9876543210',
    email: 'aditya@example.com',
    role: UserRole.customer,
    isVerified: true,
  );

  @override
  Future<UserModel> getProfile() async {
    await _delay(fast: true);
    return _mockUser;
  }

  @override
  Future<UserModel> updateProfile(UpdateProfileRequest request) async {
    await _delay();
    _mockUser = _mockUser.copyWith(
      name: request.name ?? _mockUser.name,
      email: request.email ?? _mockUser.email,
      avatarUrl: request.avatarUrl ?? _mockUser.avatarUrl,
      updatedAt: DateTime.now(),
    );
    return _mockUser;
  }

  // ── Addresses ─────────────────────────────────────────────────────────────

  final List<AddressModel> _addresses = [
    const AddressModel(
      id: 'addr_1',
      userId: 'usr_demo',
      line1: '42, MG Road',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
      type: AddressType.home,
      isDefault: true,
    ),
  ];

  @override
  Future<List<AddressModel>> getAddresses() async {
    await _delay(fast: true);
    return List.unmodifiable(_addresses);
  }

  @override
  Future<AddressModel> addAddress(AddressModel address) async {
    await _delay();
    final a = address.copyWith(
      id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _addresses.add(a);
    return a;
  }

  @override
  Future<AddressModel> updateAddress(AddressModel address) async {
    await _delay();
    final idx = _addresses.indexWhere((a) => a.id == address.id);
    if (idx >= 0) _addresses[idx] = address;
    return address;
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    await _delay(fast: true);
    _addresses.removeWhere((a) => a.id == addressId);
  }

  @override
  Future<void> setDefaultAddress(String addressId) async {
    await _delay(fast: true);
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(
        isDefault: _addresses[i].id == addressId,
      );
    }
  }

  // ── Search / Discovery ──────────────────────────────────────────────────

  @override
  Future<SearchResults> search({
    required String query,
    double? lat,
    double? lng,
  }) async {
    await _delay();
    // Return empty results in mock mode; search is a backend feature.
    return const SearchResults(
      categories: [],
      garmentTypes: [],
      vendors: [],
    );
  }

  @override
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    await _delay(fast: true);
    return [];
  }

  @override
  Future<FilterOptions> getFilterOptions() async {
    await _delay(fast: true);
    return const FilterOptions(
      sortOptions: [
        SortOption(label: 'Nearest', value: 'nearest'),
        SortOption(label: 'Best Rating', value: 'best_rating'),
        SortOption(label: 'Price: Low to High', value: 'price_asc'),
        SortOption(label: 'Price: High to Low', value: 'price_desc'),
        SortOption(label: 'Value for Money', value: 'value_for_money'),
      ],
      garmentTypes: [],
    );
  }

  // ── Payments (mock) ───────────────────────────────────────────────────────

  @override
  Future<PaymentOrderResult> createPaymentOrder({
    String? orderId,
    String? orderDraftId,
  }) async {
    await _delay();
    return PaymentOrderResult(
      paymentId: 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
      razorpayOrderId:
          'rzp_mock_order_${DateTime.now().millisecondsSinceEpoch}',
      amount: 79900,
      currency: 'INR',
      keyId: 'rzp_mock_key',
    );
  }

  @override
  Future<PaymentVerificationResult> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? orderDraftId,
  }) async {
    await _delay(fast: true);
    return const PaymentVerificationResult(
      success: true,
      paymentId: 'pay_mock_verified',
      razorpayPaymentId: 'rzp_pay_mock',
      orderId: 'ord_mock',
      status: 'VERIFIED',
    );
  }

  // ── Pickup Slots (mock) ───────────────────────────────────────────────────

  @override
  Future<List<PickupSlot>> getPickupSlots({
    required String vendorId,
    required String date,
  }) async {
    await _delay();
    return [
      PickupSlot(
        id: 'slot_morning_1',
        vendorId: vendorId,
        date: date,
        startTime: '09:00',
        endTime: '10:00',
        label: 'Morning',
        remainingCapacity: 5,
        isActive: true,
      ),
      PickupSlot(
        id: 'slot_morning_2',
        vendorId: vendorId,
        date: date,
        startTime: '10:00',
        endTime: '11:00',
        label: 'Morning',
        remainingCapacity: 3,
        isActive: true,
      ),
      PickupSlot(
        id: 'slot_afternoon_1',
        vendorId: vendorId,
        date: date,
        startTime: '14:00',
        endTime: '15:00',
        label: 'Afternoon',
        remainingCapacity: 7,
        isActive: true,
      ),
      PickupSlot(
        id: 'slot_afternoon_2',
        vendorId: vendorId,
        date: date,
        startTime: '15:00',
        endTime: '16:00',
        label: 'Afternoon',
        remainingCapacity: 4,
        isActive: true,
      ),
      PickupSlot(
        id: 'slot_evening_1',
        vendorId: vendorId,
        date: date,
        startTime: '17:00',
        endTime: '18:00',
        label: 'Evening',
        remainingCapacity: 6,
        isActive: true,
      ),
    ];
  }

  @override
  Future<SlotHoldResult> holdSlot({
    required String vendorId,
    required String slotId,
    required String date,
    String? quoteId,
  }) async {
    await _delay(fast: true);
    return SlotHoldResult(
      holdId: 'hold_${DateTime.now().millisecondsSinceEpoch}',
      slotId: slotId,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<void> releaseSlotHold(String holdId) async {
    await _delay(fast: true);
    // No-op in mock mode
  }

  // ── Order Draft (mock) ─────────────────────────────────────────────────────

  @override
  Future<QuoteResult> createQuote({
    required String vendorId,
    required String vendorServiceId,
    required List<QuoteGarmentLine> garmentLines,
    double? estimatedWeightKg,
  }) async {
    await _delay(fast: true);
    final estimatedPaise = garmentLines.fold<int>(
      0,
      (sum, line) => sum + (line.quantity * 19900),
    );
    return QuoteResult(
      quoteId: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      estimatePaise: estimatedPaise == 0 ? 59900 : estimatedPaise,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<OrderDraftResult> prepareOrder({
    required String quoteId,
    required String addressId,
    required String slotId,
  }) async {
    await _delay();
    return OrderDraftResult(
      orderDraftId: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      payableAmountPaise: 79900, // ₹799.00
      snapshot: {
        'subtotal': 59900,
        'delivery_fee': 5000,
        'tax': 10000,
        'total': 79900,
        'items': [
          {
            'name': 'Wash & Fold',
            'quantity': 3,
            'unit_price': 9900,
            'total': 29700
          },
          {
            'name': 'Steam Iron',
            'quantity': 5,
            'unit_price': 4900,
            'total': 24500
          },
        ],
      },
    );
  }

  // ── User Stats (mock) ───────────────────────────────────────────────────

  @override
  Future<UserStats> getUserStats() async {
    await _delay();
    return const UserStats(
      totalOrders: 12,
      totalSpent: 7590.50,
      loyaltyPoints: 240,
    );
  }

  // ── Reviews (mock) ────────────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<ReviewModel>> getVendorReviews(
    String vendorId, {
    PaginationParams params = const PaginationParams(),
  }) async {
    await _delay();
    return PaginatedResponse(
      items: [
        ReviewModel(
          id: 'rev_1',
          userId: 'usr_demo',
          orderId: 'ord_1',
          vendorId: vendorId,
          vendorRating: 5,
          comment: 'Excellent service! Clothes came back spotless and crisp.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          userName: 'Aarav S.',
        ),
        ReviewModel(
          id: 'rev_2',
          userId: 'usr_demo2',
          orderId: 'ord_2',
          vendorId: vendorId,
          vendorRating: 4,
          comment: 'Very happy with the quality and on-time pickup.',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          userName: 'Neha R.',
        ),
      ],
      meta: const PaginationMeta(
        currentPage: 1,
        totalPages: 1,
        totalItems: 2,
        pageSize: 20,
      ),
    );
  }

  @override
  Future<PaginatedResponse<ReviewModel>> getMyReviews({
    PaginationParams params = const PaginationParams(),
  }) async {
    await _delay();
    return PaginatedResponse(
      items: const [],
      meta: PaginationMeta(
        currentPage: 1,
        totalPages: 1,
        totalItems: 0,
        pageSize: params.pageSize,
      ),
    );
  }

  @override
  Future<ReviewModel> createReview({
    required String orderId,
    required int vendorRating,
    int? riderRating,
    String? comment,
  }) async {
    await _delay();
    return ReviewModel(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr_demo',
      orderId: orderId,
      vendorId: 'vndr_demo',
      vendorRating: vendorRating,
      riderRating: riderRating,
      comment: comment,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<ReviewModel> updateReview(
    String reviewId, {
    int? vendorRating,
    int? riderRating,
    String? comment,
  }) async {
    await _delay();
    return ReviewModel(
      id: reviewId,
      userId: 'usr_demo',
      orderId: 'ord_1',
      vendorId: 'vndr_demo',
      vendorRating: vendorRating ?? 5,
      riderRating: riderRating,
      comment: comment,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _delay(fast: true);
  }

  // ── Order Actions (mock) ─────────────────────────────────────────────────

  @override
  Future<ReorderResult> reorder(String orderId) async {
    await _delay();
    final original = await getOrderById(orderId);
    return ReorderResult(
      success: true,
      message: 'Items added for reorder.',
      itemCount: original.items.length,
    );
  }

  @override
  Future<InvoiceResult> getOrderInvoice(String orderId) async {
    await _delay();
    return InvoiceResult(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      invoiceUrl: 'https://lndry.app/invoices/mock_$orderId',
      amount: 599.00,
      gst: 107.82,
      platformFee: 29.95,
      total: 736.77,
      generatedAt: DateTime.now(),
      pdfUrl: 'https://lndry.app/invoices/mock_$orderId.pdf',
    );
  }

  @override
  Future<OtpResult> getOrderOtp(
    String orderId, {
    required String purpose,
  }) async {
    await _delay();
    return OtpResult(
      otp: '123456',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      type: purpose.toLowerCase(),
      isVerified: false,
    );
  }

  // ── Notification Preferences (mock) ───────────────────────────────────────

  NotificationPreferences _notificationPrefs = const NotificationPreferences();

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    await _delay(fast: true);
    return _notificationPrefs;
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences({
    bool? orderUpdates,
    bool? promotions,
    bool? newProducts,
    bool? deliveryUpdates,
    bool? priceDrops,
  }) async {
    await _delay();
    _notificationPrefs = NotificationPreferences(
      orderUpdates: orderUpdates ?? _notificationPrefs.orderUpdates,
      promotions: promotions ?? _notificationPrefs.promotions,
      newProducts: newProducts ?? _notificationPrefs.newProducts,
      deliveryUpdates: deliveryUpdates ?? _notificationPrefs.deliveryUpdates,
      priceDrops: priceDrops ?? _notificationPrefs.priceDrops,
    );
    return _notificationPrefs;
  }

  // ── Avatar (mock) ─────────────────────────────────────────────────────────

  @override
  Future<String> uploadAvatar(String filePath) async {
    await _delay();
    return 'https://via.placeholder.com/150?text=Avatar';
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  @override
  Future<List<NotificationModel>> getNotifications({
    PaginationParams params = const PaginationParams(),
  }) async {
    await _delay(fast: true);
    return [];
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {}

  @override
  Future<void> markAllNotificationsRead() async {}

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _delay(fast: true);
  }

  @override
  Future<void> registerDevice({
    required String deviceId,
    required String platform,
    required String fcmToken,
    String? appVersion,
  }) async {
    await _delay(fast: true);
  }

  @override
  Future<void> unregisterDevice(String deviceId) async {
    await _delay(fast: true);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<dynamic> _loadJson(String name) async {
    final raw = await rootBundle.loadString('assets/mock/$name.json');
    return json.decode(raw);
  }

  Future<void> _delay({bool fast = false}) =>
      Future.delayed(Duration(milliseconds: fast ? 200 : 600));
}

// ── Riverpod Provider ─────────────────────────────────────────────────────────

/// Resolves the active [CustomerRepository] based on the environment.
///
/// - When `Env.useMocksForVisualTestsOnly` is `true`, returns
///   [MockCustomerRepository] for explicit development UI review/golden tests.
/// - When `false`, returns [ApiCustomerRepository] wired to the live backend.
///
/// Switching is safe at any point — every page depends on the abstract
/// [CustomerRepository] interface, not on any concrete implementation.
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  if (Env.useMocksForVisualTestsOnly) {
    return MockCustomerRepository();
  }
  final dio = ref.watch(dioClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return ApiCustomerRepository(dio: dio, storage: storage);
});
