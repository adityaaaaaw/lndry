// ignore_for_file: inference_failure_on_function_invocation

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';
import '../../repositories/abstract/customer_repository.dart';

/// Production implementation of [CustomerRepository].
/// Calls the LNDRY backend API via Dio.
///
/// Maps between backend snake_case JSON responses and the camelCase domain
/// models. The backend envelope is `{ success, message, data, pagination? }`.
class ApiCustomerRepository implements CustomerRepository {
  ApiCustomerRepository({
    required Dio dio,
    required StorageService storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final StorageService _storage;
  final List<CartItem> _localCartItems = <CartItem>[];

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Extract `data` from the API envelope.
  Map<String, dynamic> _extractData(Map<String, dynamic> body) =>
      body['data'] as Map<String, dynamic>? ?? {};

  /// Extract `data` as a list from the API envelope.
  List<dynamic> _extractList(Map<String, dynamic> body) =>
      body['data'] as List<dynamic>? ?? [];

  List<dynamic> _extractNestedList(
    Map<String, dynamic> body,
    String key,
  ) {
    final data = body['data'];
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      return data[key] as List<dynamic>? ?? [];
    }
    return [];
  }

  Map<String, dynamic>? _extractNestedMap(
    Map<String, dynamic> body,
    String key,
  ) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data[key] as Map<String, dynamic>?;
    }
    return null;
  }

  double? _paiseToRupees(dynamic value) {
    final amount = value as num?;
    return amount == null ? null : amount.toDouble() / 100.0;
  }

  // ── Auth (CustomerRepository interface) ─────────────────────────────────────

  @override
  Future<SendOtpResult> sendOtp(String phone) async {
    final resp = await _dio.post(
      ApiEndpoints.sendOtp,
      data: {'phone': phone},
    );
    final data = _extractData(resp.data as Map<String, dynamic>);
    return SendOtpResult(
      challengeId: data['challenge_id'] as String? ??
          data['challengeId'] as String? ??
          '',
      expiresIn: (data['expires_in'] as num?)?.toInt() ??
          (data['expiresIn'] as num?)?.toInt() ??
          300,
      devOtp: data['otp'] as String?,
    );
  }

  @override
  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String otp,
    String? challengeId,
    Map<String, dynamic>? device,
  }) async {
    final body = <String, dynamic>{
      'phone': phone,
      'otp': otp,
      if (challengeId != null) 'challenge_id': challengeId,
      if (device != null) 'device': device,
    };
    final resp = await _dio.post(ApiEndpoints.verifyOtp, data: body);
    final data = _extractData(resp.data as Map<String, dynamic>);

    final accessToken = data['accessToken'] as String? ?? '';
    final refreshToken = data['refreshToken'] as String? ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    final user = _parseUser(userJson);

    // Persist tokens securely
    if (accessToken.isNotEmpty) {
      await _storage.saveSecure(AppConstants.keyAccessToken, accessToken);
    }
    if (refreshToken.isNotEmpty) {
      await _storage.saveSecure(AppConstants.keyRefreshToken, refreshToken);
    }

    return VerifyOtpResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      isNewUser:
          data['isNewUser'] as bool? ?? data['is_new_user'] as bool? ?? false,
    );
  }

  @override
  Future<TokenPair> refreshTokens() async {
    final currentRefresh =
        await _storage.getSecure(AppConstants.keyRefreshToken);
    if (currentRefresh == null || currentRefresh.isEmpty) {
      throw ApiException(
        message: 'No refresh token available',
        code: 'NO_REFRESH_TOKEN',
      );
    }

    final resp = await _dio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': currentRefresh},
    );
    final data = _extractData(resp.data as Map<String, dynamic>);

    final newAccess = data['accessToken'] as String? ?? '';
    final newRefresh = data['refreshToken'] as String? ?? '';

    if (newAccess.isNotEmpty) {
      await _storage.saveSecure(AppConstants.keyAccessToken, newAccess);
    }
    if (newRefresh.isNotEmpty) {
      await _storage.saveSecure(AppConstants.keyRefreshToken, newRefresh);
    }

    return TokenPair(accessToken: newAccess, refreshToken: newRefresh);
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort; always clear local session
    }
    await _storage.clearSession();
  }

  // ── Categories / Discovery ───────────────────────────────────────────────────

  @override
  Future<List<CategoryModel>> getCategories() async {
    final resp = await _dio.get(ApiEndpoints.categories);
    final list = _extractList(resp.data as Map<String, dynamic>);

    return list.map((e) => _parseCategory(e as Map<String, dynamic>)).toList();
  }

  // ── Vendors ──────────────────────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<VendorModel>> getVendors({
    String? categoryId,
    String? search,
    PaginationParams params = const PaginationParams(),
  }) async {
    final queryParams = <String, dynamic>{
      'page': params.page,
      'limit': params.pageSize,
      if (categoryId != null) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'q': search,
    };

    final resp = await _dio.get(
      ApiEndpoints.vendors,
      queryParameters: queryParams,
    );
    final body = resp.data as Map<String, dynamic>;
    final list = _extractList(body);
    final pagination = ApiPagination.fromJson(
      (body['pagination'] as Map<String, dynamic>?) ?? {},
    );

    final vendors =
        list.map((e) => _parseVendor(e as Map<String, dynamic>)).toList();
    return PaginatedResponse(
      items: vendors,
      meta: PaginationMeta(
        currentPage: pagination.currentPage,
        totalPages: pagination.totalPages,
        totalItems: pagination.total,
        pageSize: pagination.pageSize,
      ),
    );
  }

  @override
  Future<VendorModel> getVendorById(String vendorId) async {
    final resp = await _dio.get('${ApiEndpoints.vendorById}/$vendorId');
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseVendor(json);
  }

  @override
  Future<List<ServiceModel>> getServicesByVendor(String vendorId) async {
    final resp = await _dio.get(
      '${ApiEndpoints.vendorServices}/$vendorId/services',
    );
    final list = _extractList(resp.data as Map<String, dynamic>);

    return list.map((e) {
      final json = e as Map<String, dynamic>;
      final vendorServiceId = json['service_id'] as String? ?? '';
      final garmentTypeId = json['garment_type_id'] as String? ?? '';
      return ServiceModel(
        id: garmentTypeId.isNotEmpty ? garmentTypeId : vendorServiceId,
        vendorId: vendorId,
        name: json['garment_name'] as String? ?? '',
        description: json['category_name'] as String? ?? '',
        category: _parseServiceCategory(json['category_name'] as String?),
        minWeightKg: 1.0,
        isAvailable: true,
        pricePerPiece:
            ((json['rate_paise'] as num?)?.toDouble() ?? 0.0) / 100.0,
        tags: [
          if (vendorServiceId.isNotEmpty) 'vendor_service_id:$vendorServiceId',
          if (garmentTypeId.isNotEmpty) 'garment_type_id:$garmentTypeId',
        ],
      );
    }).toList();
  }

  // ── Cart (server-side cart is commented out in backend; use local cart) ─────
  // The backend cart module is commented out (`// await app.register(import(...cart))`)
  // so we keep the existing mock/local cart for now.

  @override
  Future<CartModel> getCart() async => CartModel(
        items: List<CartItem>.unmodifiable(_localCartItems),
      );

  @override
  Future<CartModel> addToCart({
    required String serviceId,
    required int quantity,
  }) async {
    final idx =
        _localCartItems.indexWhere((item) => item.serviceId == serviceId);
    if (idx >= 0) {
      final current = _localCartItems[idx];
      _localCartItems[idx] =
          current.copyWith(quantity: current.quantity + quantity);
    } else {
      _localCartItems.add(CartItem(
        id: 'local_$serviceId',
        serviceId: serviceId,
        quantity: quantity,
      ));
    }
    return getCart();
  }

  @override
  Future<CartModel> removeFromCart(String cartItemId) async {
    _localCartItems.removeWhere((item) => item.id == cartItemId);
    return getCart();
  }

  @override
  Future<CartModel> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async {
    if (quantity <= 0) return removeFromCart(cartItemId);
    final idx = _localCartItems.indexWhere((item) => item.id == cartItemId);
    if (idx >= 0) {
      _localCartItems[idx] = _localCartItems[idx].copyWith(quantity: quantity);
    }
    return getCart();
  }

  @override
  Future<void> clearCart() async {
    _localCartItems.clear();
  }

  // ── Orders ───────────────────────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<OrderModel>> getMyOrders({
    PaginationParams params = const PaginationParams(),
  }) async {
    final resp = await _dio.get(
      ApiEndpoints.orders,
      queryParameters: {
        'page': params.page,
        'limit': params.pageSize,
      },
    );
    final body = resp.data as Map<String, dynamic>;
    final list = _extractList(body);
    final pagination = body['pagination'] as Map<String, dynamic>?;

    final orders =
        list.map((e) => _parseOrder(e as Map<String, dynamic>)).toList();
    return PaginatedResponse(
      items: orders,
      meta: PaginationMeta(
        currentPage: (pagination?['page'] as int?) ?? 1,
        totalPages: (pagination?['totalPages'] as int?) ?? 1,
        totalItems: (pagination?['total'] as int?) ?? 0,
        pageSize:
            (pagination?['limit'] as int?) ?? AppConstants.defaultPageSize,
      ),
    );
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    final resp = await _dio.get(ApiEndpoints.orderById(orderId));
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  @override
  Future<OrderModel> placeOrder(PlaceOrderRequest request) async {
    // Draft-based placement (new flow)
    if (request.orderDraftId != null && request.orderDraftId!.isNotEmpty) {
      final data = <String, dynamic>{
        'order_draft_id': request.orderDraftId,
      };
      final resp = await _dio.post(ApiEndpoints.orders, data: data);
      final body = resp.data as Map<String, dynamic>;
      final responseData = body['data'] as Map<String, dynamic>?;
      final ordersList = (responseData?['orders'] as List<dynamic>?) ?? [];
      if (ordersList.isNotEmpty) {
        return _parseOrder(ordersList.first as Map<String, dynamic>);
      }
      final orderData =
          (responseData?['order'] ?? responseData) as Map<String, dynamic>;
      return _parseOrder(orderData);
    }

    throw ApiException(
      message: 'Order draft is required before placing an API-mode order.',
      code: 'ORDER_DRAFT_REQUIRED',
    );
  }

  @override
  Future<OrderModel> cancelOrder(String orderId, {String? reason}) async {
    final resp = await _dio.post(
      ApiEndpoints.cancelOrder(orderId),
      data: {'reason': reason},
    );
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  // ── Profile ──────────────────────────────────────────────────────────────────

  @override
  Future<UserModel> getProfile() async {
    final resp = await _dio.get(ApiEndpoints.userProfile);
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseUser(json);
  }

  @override
  Future<UserModel> updateProfile(UpdateProfileRequest request) async {
    final data = <String, dynamic>{};
    if (request.name != null) data['name'] = request.name;
    if (request.email != null) data['email'] = request.email;
    if (request.avatarUrl != null) data['avatar_url'] = request.avatarUrl;

    final resp = await _dio.put(ApiEndpoints.userProfile, data: data);
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseUser(json);
  }

  // ── Addresses ────────────────────────────────────────────────────────────────

  @override
  Future<List<AddressModel>> getAddresses() async {
    final resp = await _dio.get(ApiEndpoints.addresses);
    final list = _extractList(resp.data as Map<String, dynamic>);
    return list.map((e) => _parseAddress(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AddressModel> addAddress(AddressModel address) async {
    final resp = await _dio.post(
      ApiEndpoints.addresses,
      data: {
        'addressLine1': address.line1,
        'addressLine2': address.line2,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
        'lat': address.coordinates?.latitude,
        'lng': address.coordinates?.longitude,
        'label': address.type.label,
        'isDefault': address.isDefault,
      },
    );
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseAddress(json);
  }

  @override
  Future<AddressModel> updateAddress(AddressModel address) async {
    final resp = await _dio.put(
      ApiEndpoints.addressById(address.id),
      data: {
        'addressLine1': address.line1,
        if (address.line2 != null) 'addressLine2': address.line2,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
        'lat': address.coordinates?.latitude,
        'lng': address.coordinates?.longitude,
        'label': address.type.label,
      },
    );
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseAddress(json);
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    await _dio.delete(ApiEndpoints.addressById(addressId));
  }

  @override
  Future<void> setDefaultAddress(String addressId) async {
    await _dio.put(ApiEndpoints.defaultAddress(addressId));
  }

  // ── Search / Discovery ───────────────────────────────────────────────────────

  @override
  Future<SearchResults> search({
    required String query,
    double? lat,
    double? lng,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    final resp = await _dio.get(
      ApiEndpoints.search,
      queryParameters: queryParams,
    );
    final data = _extractData(resp.data as Map<String, dynamic>);

    final categories = (data['categories'] as List<dynamic>?)
            ?.map((e) => _parseCategory(e as Map<String, dynamic>))
            .toList() ??
        [];

    final garmentTypes = (data['garment_types'] as List<dynamic>?)
            ?.map((e) => SearchGarmentType(
                  id: e['id'] as String? ?? '',
                  name: e['name'] as String? ?? '',
                  slug: e['slug'] as String?,
                  unit: e['unit'] as String?,
                ))
            .toList() ??
        [];

    final vendors = (data['vendors'] as List<dynamic>?)
            ?.map((e) => _parseVendor(e as Map<String, dynamic>))
            .toList() ??
        [];

    return SearchResults(
      categories: categories,
      garmentTypes: garmentTypes,
      vendors: vendors,
    );
  }

  @override
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    final resp = await _dio.get(
      ApiEndpoints.searchSuggestions,
      queryParameters: {'q': query},
    );
    final list = _extractList(resp.data as Map<String, dynamic>);
    return list.map((e) {
      final json = e as Map<String, dynamic>;
      return SearchSuggestion(
        type: json['type'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<FilterOptions> getFilterOptions() async {
    final resp = await _dio.get(ApiEndpoints.filterOptions);
    final data = _extractData(resp.data as Map<String, dynamic>);

    final sortOptions = (data['sort_options'] as List<dynamic>?)
            ?.map((e) => SortOption(
                  label: e['label'] as String? ?? '',
                  value: e['value'] as String? ?? '',
                ))
            .toList() ??
        [
          const SortOption(label: 'Nearest', value: 'nearest'),
          const SortOption(label: 'Best Rating', value: 'best_rating'),
          const SortOption(label: 'Price: Low to High', value: 'price_asc'),
          const SortOption(label: 'Price: High to Low', value: 'price_desc'),
          const SortOption(label: 'Value for Money', value: 'value_for_money'),
        ];

    final garmentTypes = (data['garment_types'] as List<dynamic>?)
            ?.map((e) => SearchGarmentType(
                  id: e['id'] as String? ?? '',
                  name: e['name'] as String? ?? '',
                ))
            .toList() ??
        [];

    return FilterOptions(
      sortOptions: sortOptions,
      garmentTypes: garmentTypes,
    );
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  @override
  Future<PaymentOrderResult> createPaymentOrder({
    String? orderId,
    String? orderDraftId,
  }) async {
    final body = <String, dynamic>{
      if (orderId != null) 'orderId': orderId,
      if (orderDraftId != null) 'order_draft_id': orderDraftId,
    };
    final resp = await _dio.post(ApiEndpoints.createPaymentOrder, data: body);
    final data = _extractData(resp.data as Map<String, dynamic>);
    return PaymentOrderResult(
      paymentId: data['paymentId'] as String? ?? '',
      razorpayOrderId: data['razorpayOrderId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'INR',
      keyId: data['keyId'] as String?,
    );
  }

  @override
  Future<PaymentVerificationResult> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? orderDraftId,
  }) async {
    final body = <String, dynamic>{
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
      if (orderDraftId != null) 'order_draft_id': orderDraftId,
    };
    try {
      final resp = await _dio.post(ApiEndpoints.verifyPayment, data: body);
      final data = _extractData(resp.data as Map<String, dynamic>);
      return PaymentVerificationResult(
        success: true,
        paymentId: data['id'] as String?,
        razorpayPaymentId: data['razorpayPaymentId'] as String?,
        orderId: data['orderId'] as String?,
        status: data['status'] as String?,
      );
    } on ApiException catch (e) {
      return PaymentVerificationResult(
        success: false,
        status: e.code,
      );
    }
  }

  // ── Pickup Slots ──────────────────────────────────────────────────────────

  @override
  Future<List<PickupSlot>> getPickupSlots({
    required String vendorId,
    required String date,
  }) async {
    final resp = await _dio.get(
      ApiEndpoints.pickupSlots(vendorId),
      queryParameters: {'date': date},
    );
    final list = _extractList(resp.data as Map<String, dynamic>);
    return list.map((e) {
      final json = e as Map<String, dynamic>;
      return PickupSlot(
        id: json['id'] as String? ?? '',
        vendorId: vendorId,
        date: date,
        startTime:
            json['start_time'] as String? ?? json['startTime'] as String? ?? '',
        endTime:
            json['end_time'] as String? ?? json['endTime'] as String? ?? '',
        label: json['label'] as String?,
        remainingCapacity: (json['remaining_capacity'] as num?)?.toInt() ??
            (json['remainingCapacity'] as num?)?.toInt() ??
            0,
        isActive:
            json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      );
    }).toList();
  }

  @override
  Future<SlotHoldResult> holdSlot({
    required String vendorId,
    required String slotId,
    required String date,
    String? quoteId,
  }) async {
    final body = <String, dynamic>{
      'vendor_id': vendorId,
      'slot_id': slotId,
      'date': date,
      if (quoteId != null) 'quote_id': quoteId,
    };
    final resp = await _dio.post(ApiEndpoints.slotHolds, data: body);
    final data = _extractData(resp.data as Map<String, dynamic>);
    return SlotHoldResult(
      holdId: data['id'] as String? ?? '',
      slotId: slotId,
      expiresAt: DateTime.tryParse(
          data['expires_at'] as String? ?? data['expiresAt'] as String? ?? ''),
    );
  }

  @override
  Future<void> releaseSlotHold(String holdId) async {
    await _dio.delete('${ApiEndpoints.slotHolds}/$holdId');
  }

  // ── Order Draft / Quote ───────────────────────────────────────────────────

  @override
  Future<QuoteResult> createQuote({
    required String vendorId,
    required String vendorServiceId,
    required List<QuoteGarmentLine> garmentLines,
    double? estimatedWeightKg,
  }) async {
    final body = <String, dynamic>{
      'vendor_id': vendorId,
      'service_id': vendorServiceId,
      if (garmentLines.isNotEmpty)
        'garment_lines': garmentLines
            .map((line) => {
                  'garment_type_id': line.garmentTypeId,
                  'quantity': line.quantity,
                })
            .toList(),
      if (estimatedWeightKg != null) 'estimated_weight_kg': estimatedWeightKg,
    };

    final resp = await _dio.post(ApiEndpoints.quotes, data: body);
    final data = _extractData(resp.data as Map<String, dynamic>);
    return QuoteResult(
      quoteId: data['quote_id'] as String? ?? data['quoteId'] as String? ?? '',
      estimatePaise: (data['estimate_paise'] as num?)?.toInt() ??
          (data['estimatePaise'] as num?)?.toInt() ??
          0,
      expiresAt: DateTime.tryParse(
        data['expiry'] as String? ?? data['expiresAt'] as String? ?? '',
      ),
    );
  }

  @override
  Future<OrderDraftResult> prepareOrder({
    required String quoteId,
    required String addressId,
    required String slotId,
  }) async {
    final body = <String, dynamic>{
      'quote_id': quoteId,
      'address_id': addressId,
      'slot_id': slotId,
    };
    final resp = await _dio.post(ApiEndpoints.orderPrepare, data: body);
    final data = _extractData(resp.data as Map<String, dynamic>);
    return OrderDraftResult(
      orderDraftId: data['order_draft_id'] as String? ??
          data['orderDraftId'] as String? ??
          '',
      payableAmountPaise: (data['payable_amount_paise'] as num?)?.toInt() ??
          (data['payableAmountPaise'] as num?)?.toInt() ??
          0,
      snapshot: data['snapshot'] as Map<String, dynamic>?,
    );
  }

  // ── User Stats ─────────────────────────────────────────────────────────────

  @override
  Future<UserStats> getUserStats() async {
    final resp = await _dio.get(ApiEndpoints.userStats);
    final data = _extractData(resp.data as Map<String, dynamic>);
    return UserStats(
      totalOrders: (data['total_orders'] as num?)?.toInt() ??
          (data['totalOrders'] as num?)?.toInt() ??
          0,
      totalSpent: (data['total_spent'] as num?)?.toDouble() ??
          (data['totalSpent'] as num?)?.toDouble() ??
          0.0,
      loyaltyPoints: (data['loyalty_points'] as num?)?.toInt() ??
          (data['loyaltyPoints'] as num?)?.toInt() ??
          0,
    );
  }

  // ── Reviews ─────────────────────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<ReviewModel>> getVendorReviews(
    String vendorId, {
    PaginationParams params = const PaginationParams(),
  }) async {
    final resp = await _dio.get(
      ApiEndpoints.vendorReviews(vendorId),
      queryParameters: {'page': params.page, 'limit': params.pageSize},
    );
    final body = resp.data as Map<String, dynamic>;
    final list = _extractNestedList(body, 'reviews');
    final reviews =
        list.map((e) => _parseReview(e as Map<String, dynamic>)).toList();
    final pagination = _extractNestedMap(body, 'pagination') ??
        body['pagination'] as Map<String, dynamic>?;
    return PaginatedResponse(
      items: reviews,
      meta: PaginationMeta(
        currentPage: (pagination?['page'] as int?) ?? 1,
        totalPages: (pagination?['totalPages'] as int?) ?? 1,
        totalItems: (pagination?['total'] as int?) ?? 0,
        pageSize:
            (pagination?['limit'] as int?) ?? AppConstants.defaultPageSize,
      ),
    );
  }

  @override
  Future<PaginatedResponse<ReviewModel>> getMyReviews({
    PaginationParams params = const PaginationParams(),
  }) async {
    final resp = await _dio.get(
      ApiEndpoints.myReviews,
      queryParameters: {'page': params.page, 'limit': params.pageSize},
    );
    final body = resp.data as Map<String, dynamic>;
    final list = _extractNestedList(body, 'reviews');
    final reviews =
        list.map((e) => _parseReview(e as Map<String, dynamic>)).toList();
    final pagination = _extractNestedMap(body, 'pagination') ??
        body['pagination'] as Map<String, dynamic>?;
    return PaginatedResponse(
      items: reviews,
      meta: PaginationMeta(
        currentPage: (pagination?['page'] as int?) ?? 1,
        totalPages: (pagination?['totalPages'] as int?) ?? 1,
        totalItems: (pagination?['total'] as int?) ?? 0,
        pageSize:
            (pagination?['limit'] as int?) ?? AppConstants.defaultPageSize,
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
    final body = <String, dynamic>{
      'order_id': orderId,
      'vendor_rating': vendorRating,
      if (riderRating != null) 'rider_rating': riderRating,
      if (comment != null) 'comment': comment,
    };
    final resp = await _dio.post(ApiEndpoints.reviews, data: body);
    final data = _extractData(resp.data as Map<String, dynamic>);
    return _parseReview(data);
  }

  @override
  Future<ReviewModel> updateReview(
    String reviewId, {
    int? vendorRating,
    int? riderRating,
    String? comment,
  }) async {
    final body = <String, dynamic>{};
    if (vendorRating != null) body['vendor_rating'] = vendorRating;
    if (riderRating != null) body['rider_rating'] = riderRating;
    if (comment != null) body['comment'] = comment;
    final resp =
        await _dio.patch('${ApiEndpoints.reviews}/$reviewId', data: body);
    final data = _extractData(resp.data as Map<String, dynamic>);
    return _parseReview(data);
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _dio.delete('${ApiEndpoints.reviews}/$reviewId');
  }

  // ── Order Actions (reorder / invoice / OTP) ────────────────────────────────

  @override
  Future<ReorderResult> reorder(String orderId) async {
    final resp = await _dio.post(ApiEndpoints.reorder(orderId));
    final body = resp.data as Map<String, dynamic>;
    final data = _extractData(body);
    final warnings = (body['warnings'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final items = data['items'] as List<dynamic>? ?? [];
    return ReorderResult(
      success: body['success'] as bool? ?? true,
      message: body['message'] as String? ?? 'Items added for reorder.',
      itemCount: (data['itemCount'] as num?)?.toInt() ??
          (data['item_count'] as num?)?.toInt() ??
          items.length,
      warnings: warnings,
    );
  }

  @override
  Future<InvoiceResult> getOrderInvoice(String orderId) async {
    final resp = await _dio.get<List<int>>(
      ApiEndpoints.orderInvoice(orderId),
      options: Options(responseType: ResponseType.bytes),
    );
    final disposition = resp.headers.value('content-disposition') ?? '';
    final filenameMatch =
        RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    final fileName = filenameMatch?.group(1) ?? 'invoice-$orderId.pdf';
    final bytes = Uint8List.fromList(resp.data ?? const <int>[]);
    return InvoiceResult(
      id: orderId,
      orderId: orderId,
      invoiceUrl: '',
      amount: 0.0,
      gst: 0.0,
      platformFee: 0.0,
      total: 0.0,
      generatedAt: DateTime.now(),
      pdfBytes: bytes,
      fileName: fileName,
    );
  }

  @override
  Future<OtpResult> getOrderOtp(
    String orderId, {
    required String purpose,
  }) async {
    final normalizedPurpose = purpose.toUpperCase();
    final resp = await _dio.get(
      ApiEndpoints.orderOtp(orderId),
      queryParameters: {'purpose': normalizedPurpose},
    );
    final data = _extractData(resp.data as Map<String, dynamic>);
    return OtpResult(
      otp: data['otp'] as String? ?? '',
      expiresAt: DateTime.tryParse(data['expires_at'] as String? ??
              data['expiresAt'] as String? ??
              '') ??
          DateTime.now().add(const Duration(minutes: 10)),
      type: (data['purpose'] as String? ?? data['type'] as String? ?? purpose)
          .toLowerCase(),
      isVerified:
          data['is_verified'] as bool? ?? data['isVerified'] as bool? ?? false,
    );
  }

  // ── Notification Preferences ────────────────────────────────────────────────

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    final resp = await _dio.get(ApiEndpoints.notificationPreferences);
    final data = _extractData(resp.data as Map<String, dynamic>);
    return NotificationPreferences(
      orderUpdates: data['orderUpdates'] as bool? ??
          data['order_updates'] as bool? ??
          true,
      promotions: data['promotions'] as bool? ?? false,
      newProducts: data['newProducts'] as bool? ??
          data['new_products'] as bool? ??
          false,
      deliveryUpdates: data['deliveryUpdates'] as bool? ??
          data['delivery_updates'] as bool? ??
          true,
      priceDrops:
          data['priceDrops'] as bool? ?? data['price_drops'] as bool? ?? false,
    );
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences({
    bool? orderUpdates,
    bool? promotions,
    bool? newProducts,
    bool? deliveryUpdates,
    bool? priceDrops,
  }) async {
    final body = <String, dynamic>{};
    if (orderUpdates != null) body['orderUpdates'] = orderUpdates;
    if (promotions != null) body['promotions'] = promotions;
    if (newProducts != null) body['newProducts'] = newProducts;
    if (deliveryUpdates != null) body['deliveryUpdates'] = deliveryUpdates;
    if (priceDrops != null) body['priceDrops'] = priceDrops;
    final resp =
        await _dio.put(ApiEndpoints.notificationPreferences, data: body);
    final data = _extractData(resp.data as Map<String, dynamic>);
    return NotificationPreferences(
      orderUpdates: data['orderUpdates'] as bool? ??
          data['order_updates'] as bool? ??
          true,
      promotions: data['promotions'] as bool? ?? false,
      newProducts: data['newProducts'] as bool? ??
          data['new_products'] as bool? ??
          false,
      deliveryUpdates: data['deliveryUpdates'] as bool? ??
          data['delivery_updates'] as bool? ??
          true,
      priceDrops:
          data['priceDrops'] as bool? ?? data['price_drops'] as bool? ?? false,
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────────

  @override
  Future<String> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final resp = await _dio.put(
      '${ApiEndpoints.userProfile}/avatar',
      data: formData,
    );
    final data = _extractData(resp.data as Map<String, dynamic>);
    return data['url'] as String? ??
        data['avatar_url'] as String? ??
        data['avatarUrl'] as String? ??
        '';
  }

  // ── Notifications ────────────────────────────────────────────────────────────

  @override
  Future<List<NotificationModel>> getNotifications({
    PaginationParams params = const PaginationParams(),
  }) async {
    final resp = await _dio.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'page': params.page,
        'limit': params.pageSize,
      },
    );
    final list =
        _extractNestedList(resp.data as Map<String, dynamic>, 'notifications');
    return list.map((e) {
      final json = e as Map<String, dynamic>;
      return NotificationModel(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
        deepLink: json['deep_link'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    await _dio.patch(ApiEndpoints.markNotificationRead(notificationId));
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _dio.patch(ApiEndpoints.markAllRead);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _dio.delete('${ApiEndpoints.notifications}/$notificationId');
  }

  @override
  Future<void> registerDevice({
    required String deviceId,
    required String platform,
    required String fcmToken,
    String? appVersion,
  }) async {
    await _dio.post(
      ApiEndpoints.devices,
      data: {
        'device_id': deviceId,
        'platform': platform,
        'fcm_token': fcmToken,
        if (appVersion != null) 'app_version': appVersion,
      },
    );
  }

  @override
  Future<void> unregisterDevice(String deviceId) async {
    await _dio.delete(ApiEndpoints.deviceById(deviceId));
  }

  // ── JSON Mappers ─────────────────────────────────────────────────────────────

  ReviewModel _parseReview(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      orderId: json['order_id'] as String? ?? json['orderId'] as String? ?? '',
      vendorId:
          json['vendor_id'] as String? ?? json['vendorId'] as String? ?? '',
      vendorRating: (json['vendor_rating'] as num?)?.toInt() ??
          (json['vendorRating'] as num?)?.toInt() ??
          5,
      riderRating: (json['rider_rating'] as num?)?.toInt() ??
          (json['riderRating'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ??
              json['createdAt'] as String? ??
              '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
          json['updated_at'] as String? ?? json['updatedAt'] as String? ?? ''),
      userName: json['user_name'] as String? ?? json['userName'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String? ??
          json['userAvatarUrl'] as String?,
    );
  }

  VendorModel _parseVendor(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      address: AddressModel(
        id: json['address_id'] as String? ?? '',
        userId: '',
        line1: json['address_line1'] as String? ?? '',
        line2: json['address_line2'] as String?,
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        pincode: json['pincode'] as String? ?? '',
        type: AddressType.other,
        isDefault: false,
        coordinates: (json['lat'] != null && json['lng'] != null)
            ? LatLng(
                latitude: (json['lat'] as num).toDouble(),
                longitude: (json['lng'] as num).toDouble(),
              )
            : null,
      ),
      coverImageUrl: json['banner_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      averageRating: (json['rating'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isOpen: true,
      isVerified: true,
      deliveryRadiusKm:
          (json['approved_service_radius_km'] as num?)?.toDouble() ?? 0.0,
      estimatedTurnaroundHours: 24,
    );
  }

  CategoryModel _parseCategory(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['image_url'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  OrderModel _parseOrder(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => _parseOrderItem(e as Map<String, dynamic>))
            .toList() ??
        [];

    return OrderModel(
      id: json['id'] as String? ?? '',
      customerId:
          json['user_id'] as String? ?? json['customer_id'] as String? ?? '',
      vendorId:
          json['shop_id'] as String? ?? json['vendor_id'] as String? ?? '',
      items: itemsList,
      status: _parseOrderStatus(json['status'] as String?),
      subtotal: (json['subtotal'] as num?)?.toDouble() ??
          _paiseToRupees(json['subtotal_paise']) ??
          0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ??
          (json['platform_fee'] as num?)?.toDouble() ??
          _paiseToRupees(json['platform_fee_paise']) ??
          0.0,
      gstAmount: (json['taxAmount'] as num?)?.toDouble() ??
          (json['tax_amount'] as num?)?.toDouble() ??
          _paiseToRupees(json['tax_paise']) ??
          0.0,
      total: (json['totalAmount'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          _paiseToRupees(json['total_payable_paise']) ??
          0.0,
      paymentMethod: _parsePaymentMethod(json['paymentMethod'] as String? ??
          json['payment_method'] as String?),
      isPaid: (json['paymentStatus'] as String?) == 'PAID' ||
          (json['payment_status'] as String?) == 'PAID' ||
          json['is_paid'] == true,
      pickupAddressId: '',
      deliveryAddressId: '',
      scheduledPickupAt: DateTime.tryParse(
          json['scheduledPickupAt'] as String? ??
              json['pickup_date'] as String? ??
              ''),
      estimatedDeliveryAt: DateTime.tryParse(
          json['estimatedDelivery'] as String? ??
              json['estimated_delivery_at'] as String? ??
              ''),
      deliveredAt: DateTime.tryParse(json['deliveredAt'] as String? ??
          json['delivered_at'] as String? ??
          ''),
      cancellationReason: json['cancellationReason'] as String? ??
          json['cancelled_reason'] as String?,
      customerNotes: json['deliveryNotes'] as String? ??
          json['customerNotes'] as String? ??
          json['customer_notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ??
              json['created_at'] as String? ??
              '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
          json['updatedAt'] as String? ?? json['updated_at'] as String? ?? ''),
    );
  }

  OrderItem _parseOrderItem(Map<String, dynamic> json) {
    return OrderItem(
      serviceId: json['productId'] as String? ??
          json['product_id'] as String? ??
          json['garment_type_id'] as String? ??
          json['garment_rate_id'] as String? ??
          '',
      serviceName: json['name'] as String? ??
          json['garment_name'] as String? ??
          json['garment_type_name'] as String? ??
          '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['price'] as num?)?.toDouble() ??
          (json['unit_price'] as num?)?.toDouble() ??
          _paiseToRupees(json['rate_paise']) ??
          0.0,
      totalPrice: (json['total'] as num?)?.toDouble() ??
          (json['total_price'] as num?)?.toDouble() ??
          _paiseToRupees(json['total_paise']) ??
          0.0,
      notes: json['notes'] as String?,
    );
  }

  AddressModel _parseAddress(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      line1: json['addressLine1'] as String? ??
          json['address_line1'] as String? ??
          '',
      line2:
          json['addressLine2'] as String? ?? json['address_line2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      landmark: json['landmark'] as String?,
      type: _parseAddressType(json['label'] as String?),
      isDefault:
          json['isDefault'] as bool? ?? json['is_default'] as bool? ?? false,
      coordinates: (json['lat'] != null && json['lng'] != null)
          ? LatLng(
              latitude: (json['lat'] as num).toDouble(),
              longitude: (json['lng'] as num).toDouble(),
            )
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  UserModel _parseUser(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: _parseUserRole(json['role'] as String?),
      isVerified: true,
      isActive: json['deleted_at'] == null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  // ── Enum Mappers ─────────────────────────────────────────────────────────────

  OrderStatus _parseOrderStatus(String? status) {
    if (status == null) return OrderStatus.paymentPending;
    switch (status.toUpperCase()) {
      case 'PAYMENT_CONFIRMED':
      case 'WAITING_VENDOR_CONFIRMATION':
      case 'WAITING_FOR_VENDOR_CONFIRMATION':
        return OrderStatus.waitingForVendorConfirmation;
      case 'WASHING':
      case 'DRYING':
      case 'IRONING':
      case 'PREPARING':
        return OrderStatus.processing;
      case 'PENDING':
        return OrderStatus.paymentPending;
      case 'CONFIRMED':
        return OrderStatus.vendorAccepted;
      case 'CANCELLED':
        return OrderStatus.customerCancelled;
    }
    return OrderStatus.values.firstWhere(
      (s) => s.name == _toCamelCase(status),
      orElse: () => OrderStatus.paymentPending,
    );
  }

  PaymentMethod _parsePaymentMethod(String? method) {
    switch (method?.toUpperCase()) {
      case 'UPI':
      case 'ONLINE':
        return PaymentMethod.upi;
      case 'CARD':
        return PaymentMethod.card;
      case 'WALLET':
        return PaymentMethod.wallet;
      default:
        return PaymentMethod.upi;
    }
  }

  UserRole _parseUserRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'CUSTOMER':
        return UserRole.customer;
      case 'VENDOR':
        return UserRole.vendor;
      case 'DELIVERY':
      case 'RIDER':
        return UserRole.delivery;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }

  AddressType _parseAddressType(String? label) {
    switch (label?.toLowerCase()) {
      case 'home':
        return AddressType.home;
      case 'work':
        return AddressType.work;
      default:
        return AddressType.other;
    }
  }

  ServiceCategory _parseServiceCategory(String? name) {
    switch (name?.toLowerCase()) {
      case 'wash':
        return ServiceCategory.wash;
      case 'iron':
        return ServiceCategory.iron;
      case 'wash & iron':
      case 'wash_and_iron':
        return ServiceCategory.washAndIron;
      case 'dry clean':
      case 'dry_clean':
        return ServiceCategory.dryClean;
      case 'fold':
        return ServiceCategory.fold;
      default:
        return ServiceCategory.wash;
    }
  }

  /// Convert SNAKE_CASE or SCREAMING_SNAKE_CASE to camelCase.
  String _toCamelCase(String input) {
    final parts = input.toLowerCase().split('_');
    if (parts.isEmpty) return input;
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join('');
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

final apiCustomerRepositoryProvider = Provider<ApiCustomerRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return ApiCustomerRepository(dio: dio, storage: storage);
});
