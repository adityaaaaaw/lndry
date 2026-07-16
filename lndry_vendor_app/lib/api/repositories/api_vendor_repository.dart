import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    final userPhone = userJson['phone'] as String? ?? '';

    return VerifyOtpVendorResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      vendor: vendor,
      userPhone: userPhone.isNotEmpty ? userPhone : null,
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
    final resp = await _dio.get('/vendor/profile');
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseVendor(json);
  }

  @override
  Future<VendorModel> updateProfile({
    required String name,
    required String email,
    String? description,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
  }) async {
    final data = <String, dynamic>{};
    if (name.isNotEmpty) data['name'] = name;
    if (email.isNotEmpty) data['email'] = email;
    if (description != null) data['description'] = description;
    if (addressLine1 != null) data['address_line1'] = addressLine1;
    if (city != null) data['city'] = city;
    if (state != null) data['state'] = state;
    if (pincode != null) data['pincode'] = pincode;

    final resp = await _dio.patch('/vendor/profile', data: data);
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseVendor(json);
  }

  @override
  Future<VendorModel> toggleStoreOpen(bool isOpen) async {
    final resp = await _dio.patch('/vendor/profile', data: {'is_open': isOpen});
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseVendor(json);
  }

  // -- Services
  @override
  Future<List<ServiceModel>> getMyServices() async {
    final resp = await _dio.get('/vendor/services');
    final list = _extractList(resp.data as Map<String, dynamic>);
    return list.map((e) => _parseService(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ServiceModel> addService(ServiceModel service) async {
    final payload = <String, dynamic>{
      'category_id': service.categoryId ?? service.category.id,
      'category': service.category.name,
      'name': service.name,
      'description': service.description,
      'price_per_piece': ((service.pricePerPiece ?? 0.0) * 100).toInt(),
      'min_weight_kg': service.minWeightKg,
    };
    debugPrint('Outgoing POST /vendor/services request: $payload');
    final resp = await _dio.post('/vendor/services', data: payload);
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseService(json);
  }

  @override
  Future<ServiceModel> updateService(ServiceModel service) async {
    final payload = <String, dynamic>{
      'category_id': service.categoryId ?? service.category.id,
      'category': service.category.name,
      'name': service.name,
      'description': service.description,
      'price_per_piece': ((service.pricePerPiece ?? 0.0) * 100).toInt(),
      'min_weight_kg': service.minWeightKg,
      'is_available': service.isAvailable,
    };
    debugPrint('Outgoing PATCH /vendor/services/${service.id} request: $payload');
    final resp = await _dio.patch('/vendor/services/${service.id}', data: payload);
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseService(json);
  }

  @override
  Future<void> toggleServiceAvailability(String serviceId, bool isAvailable) async {
    await _dio.patch('/vendor/services/$serviceId', data: {
      'is_available': isAvailable,
    });
  }

  @override
  Future<void> deleteService(String serviceId) async {
    await _dio.delete('/vendor/services/$serviceId');
  }

  @override
  Future<Map<String, dynamic>> getServiceDetails(String serviceId) async {
    final resp = await _dio.get('/vendor/services/$serviceId');
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
    await _dio.post('/vendor/services/$serviceId/garment-rates', data: data);
  }

  @override
  Future<void> deleteGarmentRate(String serviceId, String garmentTypeId) async {
    await _dio.delete('/vendor/services/$serviceId/garment-rates/$garmentTypeId');
  }

  // -- Orders
  @override
  Future<OrderModel> getOrder(String orderId) async {
    final resp = await _dio.get('/vendor/orders/$orderId');
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  @override
  Future<PaginatedResponse<OrderModel>> getIncomingOrders({
    PaginationParams params = const PaginationParams(),
    String? status,
  }) async {
    final resp = await _dio.get(
      '/vendor/orders',
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
    final resp = await _dio.post('/vendor/orders/$orderId/accept');
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  @override
  Future<OrderModel> rejectOrder(String orderId, {String? reason}) async {
    final resp = await _dio.post(
      '/vendor/orders/$orderId/reject',
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
      '/vendor/orders/$orderId/processing-stage',
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
      '/vendor/orders/$orderId/reconcile',
      data: body,
    );
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseOrder(json);
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final resp = await _dio.get('/vendor/orders/stats');
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

  List<String> _mapUiPermissionsToBackend(List<String> uiPermissions) {
    final backend = <String>[];
    for (final p in uiPermissions) {
      switch (p) {
        case 'orders:read':
          backend.add('shop_orders.view');
          break;
        case 'orders:write':
          backend.addAll(['shop_orders.view', 'shop_orders.update_status', 'shop_orders.assign_rider', 'shop_orders.cancel']);
          break;
        case 'catalog:write':
          backend.addAll(['vendor_services.create', 'vendor_services.update', 'vendor_services.delete', 'vendor_services.view']);
          break;
        case 'staff:write':
          backend.addAll(['vendor_staff.create', 'vendor_staff.update', 'vendor_staff.delete', 'vendor_staff.view']);
          break;
        default:
          backend.add(p);
      }
    }
    return backend.toSet().toList();
  }

  List<String> _mapBackendPermissionsToUi(List<String> backendPermissions) {
    final ui = <String>[];
    final backendSet = backendPermissions.toSet();
    if (backendSet.contains('shop_orders.view')) {
      ui.add('orders:read');
    }
    if (backendSet.contains('shop_orders.update_status')) {
      ui.add('orders:write');
    }
    if (backendSet.contains('vendor_services.create') ||
        backendSet.contains('vendor_services.update')) {
      ui.add('catalog:write');
    }
    if (backendSet.contains('vendor_staff.create') ||
        backendSet.contains('vendor_staff.update')) {
      ui.add('staff:write');
    }
    return ui;
  }

  EmployeeModel _parseEmployee(Map<String, dynamic> json) {
    final mappedJson = Map<String, dynamic>.from(json);
    if (mappedJson['permissions'] != null) {
      mappedJson['permissions'] = _mapBackendPermissionsToUi(
        (mappedJson['permissions'] as List<dynamic>).map((e) => e.toString()).toList(),
      );
    }
    return EmployeeModel.fromJson(mappedJson);
  }

  // -- Employees
  @override
  Future<List<EmployeeModel>> getEmployees() async {
    final resp = await _dio.get('/vendor/employees');
    final data = _extractData(resp.data as Map<String, dynamic>);
    final list = data['staff'] as List<dynamic>? ?? [];
    return list.map((e) => _parseEmployee(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<EmployeeModel> createEmployee({
    required String name,
    required String email,
    required String role,
    String? phone,
    List<String>? permissions,
  }) async {
    final resp = await _dio.post('/vendor/employees', data: {
      'name': name,
      'email': email,
      'role': role,
      if (phone != null) 'phone': phone,
      if (permissions != null) 'permissions': _mapUiPermissionsToBackend(permissions),
    });
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseEmployee(json);
  }

  @override
  Future<EmployeeModel> updateEmployee(
    String id, {
    required String role,
    required List<String> permissions,
    required bool isActive,
  }) async {
    final resp = await _dio.patch('/vendor/employees/$id', data: {
      'role': role,
      'permissions': _mapUiPermissionsToBackend(permissions),
      'is_active': isActive,
    });
    final json = _extractData(resp.data as Map<String, dynamic>);
    return _parseEmployee(json);
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _dio.delete('/vendor/employees/$id');
  }

  @override
  Future<void> resetEmployeePassword(String id, String newPassword) async {
    await _dio.post('/vendor/employees/$id/reset-password', data: {
      'password': newPassword,
    });
  }

  // -- Capacity & Slots
  @override
  Future<Map<String, dynamic>> getCapacity() async {
    final resp = await _dio.get('/vendor/capacity');
    return _extractData(resp.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateCapacityDailyLimit(int maxOrdersPerDay) async {
    await _dio.put('/vendor/capacity/daily-limit', data: {
      'max_orders_per_day': maxOrdersPerDay,
    });
  }

  @override
  Future<List<PickupSlotModel>> getPickupSlots() async {
    final resp = await _dio.get('/vendor/pickup-slots');
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
    final resp = await _dio.post('/vendor/pickup-slots', data: {
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

    final resp = await _dio.patch('/vendor/pickup-slots/$id', data: data);
    final json = _extractData(resp.data as Map<String, dynamic>);
    return PickupSlotModel.fromJson(json);
  }

  @override
  Future<void> deletePickupSlot(String id) async {
    await _dio.delete('/vendor/pickup-slots/$id');
  }

  // -- Parsers
  double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  VendorModel _parseVendor(Map<String, dynamic> json) => VendorModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
        isOpen: json['is_open'] as bool? ?? json['isOpen'] as bool? ?? true,
        description: json['description'] as String? ?? '',
        ownerName: json['owner_name'] as String? ?? json['ownerName'] as String? ?? '',
        logoUrl: json['logo_url'] as String? ?? json['logoUrl'] as String?,
        coverImageUrl: json['banner_url'] as String? ?? json['bannerUrl'] as String? ?? json['coverImageUrl'] as String?,
        averageRating: _toDouble(json['rating']) ?? _toDouble(json['average_rating']) ?? _toDouble(json['averageRating']),
        reviewCount: _toInt(json['review_count']) ?? _toInt(json['reviewCount']) ?? 0,
        estimatedTurnaroundHours: _toInt(json['estimated_turnaround_hours']) ?? _toInt(json['estimatedTurnaroundHours']) ?? 24,
        address: json['address'] != null
            ? AddressModel.fromJson(json['address'] as Map<String, dynamic>)
            : AddressModel(
                id: json['id'] as String? ?? '',
                userId: '',
                line1: json['address_line1'] as String? ?? '',
                line2: json['address_line2'] as String?,
                city: json['city'] as String? ?? '',
                state: json['state'] as String? ?? '',
                pincode: json['pincode'] as String? ?? '',
                type: AddressType.other,
                coordinates: (json['lat'] != null && json['lng'] != null)
                    ? LatLng(
                        latitude: _toDouble(json['lat']) ?? 0.0,
                        longitude: _toDouble(json['lng']) ?? 0.0,
                      )
                    : null,
              ),
      );

  ServiceModel _parseService(Map<String, dynamic> json) {
    final catEnum = _parseServiceCategory(
        json['category_name'] as String? ?? json['category'] as String?);
    return ServiceModel(
      id: json['id'] as String? ?? '',
      vendorId:
          json['vendor_id'] as String? ?? json['vendorId'] as String? ?? '',
      name: json['name'] as String? ?? json['category_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: catEnum,
      categoryId: json['category_id'] as String? ??
          json['categoryId'] as String? ??
          catEnum.id,
      minWeightKg: _toDouble(json['min_weight_kg']) ??
          _toDouble(json['minWeightKg']) ??
          1.0,
      isAvailable: json['is_available'] as bool? ??
          json['isAvailable'] as bool? ??
          true,
      pricePerPiece: (_toDouble(json['price_per_piece']) ??
              _toDouble(json['pricePerPiece']) ??
              0.0) /
          100.0,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  OrderModel _parseOrder(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String? ?? '',
        customerId: json['customer_id'] as String? ?? json['customerId'] as String? ?? '',
        vendorId: json['vendor_id'] as String? ?? json['vendorId'] as String? ?? '',
        status: _parseOrderStatus(json['status'] as String?),
        total: (_toDouble(json['total_amount_paise']) ??
                _toDouble(json['totalAmountPaise']) ??
                0.0) /
            100.0,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) {
                  final m = e as Map<String, dynamic>;
                  return OrderItem(
                    serviceId: m['service_id'] as String? ?? m['serviceId'] as String? ?? '',
                    serviceName: m['service_name'] as String? ?? m['serviceName'] as String? ?? 'Item',
                    quantity: _toInt(m['quantity']) ?? 1,
                    unitPrice: _toDouble(m['unit_price']) ?? _toDouble(m['unitPrice']) ?? 0.0,
                    totalPrice: _toDouble(m['total_price']) ?? _toDouble(m['totalPrice']) ?? 0.0,
                    notes: m['notes'] as String?,
                  );
                })
                .toList() ??
            [],
        createdAt: DateTime.tryParse(
                json['created_at'] as String? ?? json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @visibleForTesting
  VendorModel parseVendorForTest(Map<String, dynamic> json) => _parseVendor(json);

  @visibleForTesting
  ServiceModel parseServiceForTest(Map<String, dynamic> json) => _parseService(json);

  @visibleForTesting
  OrderModel parseOrderForTest(Map<String, dynamic> json) => _parseOrder(json);

  ServiceCategory _parseServiceCategory(String? category) {
    if (category == null) return ServiceCategory.wash;
    final lower = category.toLowerCase().trim();
    return switch (lower) {
      // Canonical API values
      'wash' => ServiceCategory.wash,
      'iron' || 'ironing' => ServiceCategory.iron,
      'wash_iron' || 'wash & iron' || 'wash and iron' => ServiceCategory.washAndIron,
      'dry_clean' || 'dry_cleaning' || 'dry clean' => ServiceCategory.dryClean,
      'fold' || 'wash_fold' || 'wash & fold' || 'wash and fold' => ServiceCategory.fold,
      'premium' || 'premium_garment_care' || 'premium garment care' => ServiceCategory.premium,
      // Additional backend category names from service_categories table
      'blanket cleaning' || 'blanket_cleaning' || 'blanket' => ServiceCategory.premium,
      'carpet cleaning' || 'carpet_cleaning' || 'carpet' => ServiceCategory.premium,
      'curtain cleaning' || 'curtain_cleaning' || 'curtain' => ServiceCategory.premium,
      'shoe care' || 'shoe_care' || 'shoe carejjjjjj' => ServiceCategory.premium,
      // Unknown → default to wash
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

  @override
  Future<Map<String, dynamic>> getAnalyticsSummary({String period = 'week'}) async {
    final resp = await _dio.get(
      '/vendor/analytics/summary',
      queryParameters: {'period': period},
    );
    return _extractData(resp.data as Map<String, dynamic>);
  }

  @override
  Future<Map<int, Map<String, dynamic>>> getWorkingHours() async {
    final resp = await _dio.get('/vendor/profile');
    final json = _extractData(resp.data as Map<String, dynamic>);

    // operating_hours.schedule is stored as { "0": {...}, "1": {...}, ... }
    final rawHours = json['operating_hours'] as Map<String, dynamic>?;
    final schedule = rawHours?['schedule'] as Map<String, dynamic>? ?? {};

    final result = <int, Map<String, dynamic>>{};
    for (int day = 0; day < 7; day++) {
      final dayData = schedule[day.toString()] as Map<String, dynamic>?;
      result[day] = {
        'isOpen': dayData?['isOpen'] as bool? ?? true,
        'openTime': dayData?['openTime'] as String? ?? '08:00',
        'closeTime': dayData?['closeTime'] as String? ?? '20:00',
      };
    }
    return result;
  }

  @override
  Future<void> updateWorkingHours(
    int dayOfWeek, {
    required bool isOpen,
    required String openTime,
    required String closeTime,
  }) async {
    // Fetch current operating_hours so we can merge just the one day
    final profileResp = await _dio.get('/vendor/profile');
    final profileJson = _extractData(profileResp.data as Map<String, dynamic>);
    final rawHours = profileJson['operating_hours'] as Map<String, dynamic>? ?? {};
    final schedule =
        Map<String, dynamic>.from(rawHours['schedule'] as Map<String, dynamic>? ?? {});

    schedule[dayOfWeek.toString()] = {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };

    await _dio.patch('/vendor/profile', data: {
      'operating_hours': {
        ...rawHours,
        'schedule': schedule,
      },
    });
  }

  // -- Support Tickets
  @override
  Future<Map<String, dynamic>> createSupportTicket({
    required String title,
    required String description,
    required String category,
  }) async {
    final resp = await _dio.post('/vendor/support-tickets', data: {
      'title': title,
      'description': description,
      'category': category,
    });
    return _extractData(resp.data as Map<String, dynamic>);
  }

  @override
  Future<List<Map<String, dynamic>>> getSupportTickets() async {
    final resp = await _dio.get('/vendor/support-tickets');
    final list = _extractList(resp.data as Map<String, dynamic>);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
