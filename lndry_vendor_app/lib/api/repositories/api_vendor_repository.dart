import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/config.dart';
import '../../core/network/network.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';
import '../../repositories/abstract/vendor_repository.dart';
import 'demo_vendor_repository.dart';

class ApiVendorRepository implements VendorRepository {
  ApiVendorRepository({
    required Dio dio,
    required StorageService storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final StorageService _storage;

  // -- Helpers
  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    if (response['success'] == true) {
      return (response['data'] as Map<String, dynamic>?) ?? response;
    }
    return response;
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    if (response['success'] == true) {
      return (response['data'] as List<dynamic>?) ?? [];
    }
    if (response['data'] is List) {
      return response['data'] as List<dynamic>;
    }
    return [];
  }

  // -- Auth
  @override
  Future<SendOtpResult> sendOtp(String phone) async {
    final apiPhone = phone.startsWith('+') ? phone : '+91$phone';
    final resp = await _dio.post(
      ApiEndpoints.sendOtp,
      data: {'phone': apiPhone, 'role': 'vendor'},
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
  Future<VerifyOtpVendorResult> verifyOtp({
    required String phone,
    required String otp,
    String? challengeId,
    Map<String, dynamic>? device,
  }) async {
    final apiPhone = phone.startsWith('+') ? phone : '+91$phone';
    final body = <String, dynamic>{
      'phone': apiPhone,
      'otp': otp,
      if (challengeId != null) 'challenge_id': challengeId,
      if (device != null) 'device': device,
      'role': 'vendor',
    };
    final resp = await _dio.post(ApiEndpoints.verifyOtp, data: body);
    final data = _extractData(resp.data as Map<String, dynamic>);

    final accessToken = data['accessToken'] as String? ?? '';
    final refreshToken = data['refreshToken'] as String? ?? '';
    final vendorJson = data['vendor'] as Map<String, dynamic>? ?? {};
    final vendor = _parseVendor(vendorJson);

    // Persist tokens securely
    if (accessToken.isNotEmpty) {
      await _storage.saveSecure(AppConstants.keyAccessToken, accessToken);
    }
    if (refreshToken.isNotEmpty) {
      await _storage.saveSecure(AppConstants.keyRefreshToken, refreshToken);
    }

    return VerifyOtpVendorResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      vendor: vendor,
    );
  }

  @override
  Future<TokenPair> refreshTokens() async {
    final currentRefresh = await _storage.getSecure(AppConstants.keyRefreshToken);
    if (currentRefresh == null || currentRefresh.isEmpty) {
      throw const ApiException(message: 'No refresh token available');
    }
    final resp = await _dio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': currentRefresh},
    );
    final data = _extractData(resp.data as Map<String, dynamic>);
    final accessToken = data['accessToken'] as String? ?? '';
    final refreshToken = data['refreshToken'] as String? ?? '';

    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> logout() async {
    try {
      final currentRefresh = await _storage.getSecure(AppConstants.keyRefreshToken);
      if (currentRefresh != null && currentRefresh.isNotEmpty) {
        await _dio.post(
          ApiEndpoints.logout,
          data: {'refreshToken': currentRefresh},
        );
      }
    } finally {
      await _storage.clearSession();
    }
  }

  // -- Profile
  @override
  Future<VendorModel> getProfile() async {
    final resp = await _dio.get('/api/v1/vendor/profile');
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseVendor(json);
  }

  @override
  Future<VendorModel> updateProfile({
    required String name,
    required String email,
  }) async {
    final data = <String, dynamic>{};
    if (name.isNotEmpty) data['name'] = name;
    if (email.isNotEmpty) data['email'] = email;

    final resp = await _dio.patch('/api/v1/vendor/profile', data: data);
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseVendor(json);
  }

  @override
  Future<VendorModel> toggleStoreOpen(bool isOpen) async {
    final resp = await _dio.patch('/api/v1/vendor/profile', data: {'is_open': isOpen});
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseVendor(json);
  }

  // -- Services
  @override
  Future<List<ServiceModel>> getMyServices() async {
    final resp = await _dio.get('/api/v1/vendor/services');
    final list = _extractList(resp.data as Map<String, dynamic>);
    return list.map((e) => _parseService(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ServiceModel> addService(ServiceModel service) async {
    final resp = await _dio.post('/api/v1/vendor/services', data: {
      'name': service.name,
      'description': service.description,
      'category': service.category.name,
      'price_per_piece': ((service.pricePerPiece ?? 0.0) * 100).toInt(),
      'min_weight_kg': service.minWeightKg,
    });
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseService(json);
  }

  @override
  Future<ServiceModel> updateService(ServiceModel service) async {
    final resp = await _dio.patch('/api/v1/vendor/services/${service.id}', data: {
      'name': service.name,
      'description': service.description,
      'category': service.category.name,
      'price_per_piece': ((service.pricePerPiece ?? 0.0) * 100).toInt(),
      'min_weight_kg': service.minWeightKg,
      'is_available': service.isAvailable,
    });
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseService(json);
  }

  @override
  Future<void> toggleServiceAvailability(String serviceId, bool isAvailable) async {
    await _dio.patch('/api/v1/vendor/services/$serviceId', data: {
      'is_available': isAvailable,
    });
  }

  @override
  Future<void> deleteService(String serviceId) async {
    await _dio.delete('/api/v1/vendor/services/$serviceId');
  }

  @override
  Future<Map<String, dynamic>> getServiceDetails(String serviceId) async {
    final resp = await _dio.get('/api/v1/vendor/services/$serviceId');
    return _extractData(resp.data as Map<String, dynamic>);
  }

  @override
  Future<void> addGarmentRate(
    String serviceId, {
    String? garmentTypeId,
    String? garmentTypeName,
    required double rate,
    String? rateUnit,
  }) async {
    final data = <String, dynamic>{
      'rate_paise': (rate * 100).toInt(),
      if (garmentTypeId != null) 'garment_type_id': garmentTypeId,
      if (garmentTypeName != null) 'garment_type_name': garmentTypeName,
      if (rateUnit != null) 'rate_unit': rateUnit,
    };
    await _dio.post('/api/v1/vendor/services/$serviceId/garment-rates', data: data);
  }

  @override
  Future<void> deleteGarmentRate(String serviceId, String garmentTypeId) async {
    await _dio.delete('/api/v1/vendor/services/$serviceId/garment-rates/$garmentTypeId');
  }

  // -- Orders
  @override
  Future<OrderModel> getOrder(String orderId) async {
    final resp = await _dio.get('/api/v1/vendor-orders/$orderId');
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  @override
  Future<PaginatedResponse<OrderModel>> getIncomingOrders({
    PaginationParams params = const PaginationParams(),
    String? status,
  }) async {
    final resp = await _dio.get(
      '/api/v1/vendor-orders',
      queryParameters: {
        'page': params.page,
        'limit': params.pageSize,
        if (status != null) 'status': status,
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
        currentPage: (pagination?['page'] as int?) ?? params.page,
        totalPages: (pagination?['totalPages'] as int?) ?? 1,
        totalItems: (pagination?['total'] as int?) ?? list.length,
        pageSize: (pagination?['limit'] as int?) ?? params.pageSize,
      ),
    );
  }

  @override
  Future<OrderModel> acceptOrder(String orderId) async {
    final resp = await _dio.post('/api/v1/vendor-orders/$orderId/accept');
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  @override
  Future<OrderModel> rejectOrder(String orderId, {String? reason}) async {
    final resp = await _dio.post(
      '/api/v1/vendor-orders/$orderId/reject',
      data: reason != null ? {'reason': reason} : null,
    );
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  @override
  Future<OrderModel> markOrderReady(String orderId) async {
    return updateProcessingStage(orderId, 'PACKED');
  }

  @override
  Future<OrderModel> updateProcessingStage(String orderId, String stage) async {
    final resp = await _dio.post(
      '/api/v1/vendor-orders/$orderId/processing-stage',
      data: {'status': stage},
    );
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  @override
  Future<OrderModel> reconcileOrder(
    String orderId, {
    List<Map<String, dynamic>>? confirmedLines,
    double? confirmedWeightKg,
    String? adjustmentReason,
  }) async {
    final body = <String, dynamic>{};
    if (confirmedLines != null) body['confirmed_lines'] = confirmedLines;
    if (confirmedWeightKg != null) body['confirmed_weight_kg'] = confirmedWeightKg;
    if (adjustmentReason != null) body['adjustment_reason'] = adjustmentReason;

    final resp = await _dio.post(
      '/api/v1/vendor-orders/$orderId/reconcile',
      data: body,
    );
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final resp = await _dio.get('/api/v1/vendor-orders/stats');
    return _extractData(resp.data as Map<String, dynamic>);
  }

  // -- Device Tokens
  @override
  Future<void> registerDevice({
    required String deviceId,
    required String platform,
    required String fcmToken,
  }) async {
    await _dio.post(ApiEndpoints.registerDeviceToken, data: {
      'device_id': deviceId,
      'platform': platform,
      'fcm_token': fcmToken,
    });
  }

  @override
  Future<void> unregisterDevice(String deviceId) async {
    await _dio.delete('${ApiEndpoints.devices}/$deviceId');
  }

  // -- Employees
  @override
  Future<List<EmployeeModel>> getEmployees() async {
    final resp = await _dio.get('/api/v1/vendor/employees');
    final list = _extractList(resp.data as Map<String, dynamic>);
    return list.map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<EmployeeModel> createEmployee({
    required String name,
    required String email,
    required String role,
    String? phone,
    List<String>? permissions,
  }) async {
    final resp = await _dio.post('/api/v1/vendor/employees', data: {
      'name': name,
      'email': email,
      'role': role,
      if (phone != null) 'phone': phone,
      if (permissions != null) 'permissions': permissions,
    });
    final json = _extractData(resp.data as Map<String, dynamic>);
    return EmployeeModel.fromJson(json);
  }

  @override
  Future<EmployeeModel> updateEmployee(
    String id, {
    required String role,
    required List<String> permissions,
    required bool isActive,
  }) async {
    final resp = await _dio.patch('/api/v1/vendor/employees/$id', data: {
      'role': role,
      'permissions': permissions,
      'is_active': isActive,
    });
    final json = _extractData(resp.data as Map<String, dynamic>);
    return EmployeeModel.fromJson(json);
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _dio.delete('/api/v1/vendor/employees/$id');
  }

  @override
  Future<void> resetEmployeePassword(String id, String newPassword) async {
    await _dio.post('/api/v1/vendor/employees/$id/reset-password', data: {
      'password': newPassword,
    });
  }

  // -- Capacity & Slots
  @override
  Future<Map<String, dynamic>> getCapacity() async {
    final resp = await _dio.get('/api/v1/vendor/capacity');
    return _extractData(resp.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateCapacityDailyLimit(int maxOrdersPerDay) async {
    await _dio.put('/api/v1/vendor/capacity/daily-limit', data: {
      'max_orders_per_day': maxOrdersPerDay,
    });
  }

  @override
  Future<List<PickupSlotModel>> getPickupSlots() async {
    final resp = await _dio.get('/api/v1/vendor/pickup-slots');
    final list = _extractList(resp.data as Map<String, dynamic>);
    return list.map((e) => PickupSlotModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<PickupSlotModel> createPickupSlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    int? maxOrders,
  }) async {
    final resp = await _dio.post('/api/v1/vendor/pickup-slots', data: {
      'day_of_week': dayOfWeek,
      'start': startTime,
      'end': endTime,
      if (maxOrders != null) 'max_orders': maxOrders,
    });
    final json = _extractData(resp.data as Map<String, dynamic>);
    return PickupSlotModel.fromJson(json);
  }

  @override
  Future<PickupSlotModel> updatePickupSlot(
    String id, {
    int? maxOrders,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (maxOrders != null) data['max_orders'] = maxOrders;
    if (isActive != null) data['is_active'] = isActive;

    final resp = await _dio.patch('/api/v1/vendor/pickup-slots/$id', data: data);
    final json = _extractData(resp.data as Map<String, dynamic>);
    return PickupSlotModel.fromJson(json);
  }

  @override
  Future<void> deletePickupSlot(String id) async {
    await _dio.delete('/api/v1/vendor/pickup-slots/$id');
  }

  // -- Parsers
  VendorModel _parseVendor(Map<String, dynamic> json) => VendorModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
        description: json['description'] as String? ?? '',
        ownerName: json['owner_name'] as String? ?? json['ownerName'] as String? ?? '',
        address: json['address'] != null
            ? AddressModel.fromJson(json['address'] as Map<String, dynamic>)
            : const AddressModel(
                id: '',
                userId: '',
                line1: '',
                city: '',
                state: '',
                pincode: '',
                type: AddressType.other,
              ),
      );

  ServiceModel _parseService(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String? ?? '',
        vendorId: json['vendor_id'] as String? ?? json['vendorId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: _parseServiceCategory(json['category'] as String?),
        minWeightKg: (json['min_weight_kg'] as num?)?.toDouble() ??
            (json['minWeightKg'] as num?)?.toDouble() ??
            1.0,
        isAvailable: json['is_available'] as bool? ??
            json['isAvailable'] as bool? ??
            true,
        pricePerPiece: ((json['price_per_piece'] as num?)?.toDouble() ??
                (json['pricePerPiece'] as num?)?.toDouble() ??
                0.0) /
            100.0,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  OrderModel _parseOrder(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String? ?? '',
        customerId: json['customer_id'] as String? ?? json['customerId'] as String? ?? '',
        vendorId: json['vendor_id'] as String? ?? json['vendorId'] as String? ?? '',
        status: _parseOrderStatus(json['status'] as String?),
        total: ((json['total_amount_paise'] as num?)?.toDouble() ??
                (json['totalAmountPaise'] as num?)?.toDouble() ??
                0.0) /
            100.0,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(
                json['created_at'] as String? ?? json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  ServiceCategory _parseServiceCategory(String? category) {
    if (category == null) return ServiceCategory.wash;
    final lower = category.toLowerCase();
    return switch (lower) {
      'wash' => ServiceCategory.wash,
      'iron' => ServiceCategory.iron,
      'wash_iron' || 'wash & iron' => ServiceCategory.washAndIron,
      'dry_clean' || 'dry_cleaning' => ServiceCategory.dryClean,
      'fold' || 'wash_fold' || 'wash & fold' => ServiceCategory.fold,
      'premium' || 'premium_garment_care' => ServiceCategory.premium,
      _ => ServiceCategory.wash,
    };
  }

  OrderStatus _parseOrderStatus(String? status) {
    if (status == null) return OrderStatus.waitingForVendorConfirmation;
    final lower = status.toLowerCase();
    return switch (lower) {
      'payment_pending' => OrderStatus.paymentPending,
      'payment_failed' => OrderStatus.paymentFailed,
      'waiting_for_vendor_confirmation' || 'waiting_vendor_confirmation' => OrderStatus.waitingForVendorConfirmation,
      'vendor_accepted' => OrderStatus.vendorAccepted,
      'pickup_assigned' => OrderStatus.pickupAssigned,
      'going_for_pickup' => OrderStatus.goingForPickup,
      'pickup_otp_verified' => OrderStatus.pickupOtpVerified,
      'picked_up' => OrderStatus.pickedUp,
      'received_at_vendor' => OrderStatus.receivedAtVendor,
      'processing' || 'washing' || 'drying' || 'ironing' => OrderStatus.processing,
      'packed' => OrderStatus.packed,
      'delivery_assigned' => OrderStatus.deliveryAssigned,
      'out_for_delivery' => OrderStatus.outForDelivery,
      'delivery_otp_verified' => OrderStatus.deliveryOtpVerified,
      'delivered' => OrderStatus.delivered,
      'vendor_rejected' => OrderStatus.vendorRejected,
      'auto_rejected' => OrderStatus.autoRejected,
      'customer_cancelled' => OrderStatus.customerCancelled,
      'admin_cancelled' => OrderStatus.adminCancelled,
      'refund_pending' => OrderStatus.refundPending,
      'refunded' => OrderStatus.refunded,
      _ => OrderStatus.waitingForVendorConfirmation,
    };
  }
}

// ── Provider ────────────────────────────────────────────────────────────────────

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  if (Env.demoMode) {
    return DemoVendorRepository(storage: storage);
  }
  final dio = ref.watch(dioClientProvider);
  return ApiVendorRepository(dio: dio, storage: storage);
});
