import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';
import '../abstract/customer_repository.dart';

/// Mock implementation of [CustomerRepository].
/// Reads data from assets/mock/*.json files.
/// Replace this with [ApiCustomerRepository] when backend is available —
/// the UI layer never needs to change because it only depends on the abstract interface.
class MockCustomerRepository implements CustomerRepository {
  MockCustomerRepository();

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
      vendors = vendors
          .where((v) => v.categoryIds.contains(categoryId))
          .toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      vendors = vendors
          .where((v) =>
              v.name.toLowerCase().contains(q) ||
              v.description.toLowerCase().contains(q))
          .toList();
    }

    final total  = vendors.length;
    final offset = (params.page - 1) * params.pageSize;
    final items  = vendors.skip(offset).take(params.pageSize).toList();

    return PaginatedResponse(
      items: items,
      meta: PaginationMeta(
        currentPage:  params.page,
        totalPages:   (total / params.pageSize).ceil().clamp(1, 9999),
        totalItems:   total,
        pageSize:     params.pageSize,
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
        id:        'ci_${DateTime.now().millisecondsSinceEpoch}',
        serviceId: serviceId,
        quantity:  quantity,
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
    final total  = orders.length;
    final offset = (params.page - 1) * params.pageSize;
    final items  = orders.skip(offset).take(params.pageSize).toList();
    return PaginatedResponse(
      items: items,
      meta: PaginationMeta(
        currentPage: params.page,
        totalPages:  (total / params.pageSize).ceil().clamp(1, 9999),
        totalItems:  total,
        pageSize:    params.pageSize,
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
    return OrderModel(
      id:              'ord_${DateTime.now().millisecondsSinceEpoch}',
      customerId:      'usr_demo',
      vendorId:        request.vendorId,
      items:           request.items
          .map((i) => OrderItem(
                serviceId:   i.serviceId,
                serviceName: 'Service',
                quantity:    i.quantity,
                unitPrice:   199,
                totalPrice:  i.quantity * 199,
              ))
          .toList(),
      status:              OrderStatus.pending,
      subtotal:            request.items.fold(0, (s, i) => s + i.quantity * 199),
      platformFee:         request.items.fold(0.0, (s, i) => s + i.quantity * 199) * 0.05,
      gstAmount:           request.items.fold(0.0, (s, i) => s + i.quantity * 199) * 0.18,
      total:               request.items.fold(0.0, (s, i) => s + i.quantity * 199) * 1.23,
      paymentMethod:       request.paymentMethod,
      pickupAddressId:     request.pickupAddressId,
      deliveryAddressId:   request.deliveryAddressId,
      scheduledPickupAt:   request.scheduledPickupAt,
      customerNotes:       request.notes,
      createdAt:           DateTime.now(),
    );
  }

  @override
  Future<OrderModel> cancelOrder(String orderId, {String? reason}) async {
    await _delay();
    final order = await getOrderById(orderId);
    return order.copyWith(
      status:             OrderStatus.cancelled,
      cancellationReason: reason,
      updatedAt:          DateTime.now(),
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  UserModel _mockUser = const UserModel(
    id:         'usr_demo',
    name:       'Aditya Kumar',
    phone:      '9876543210',
    email:      'aditya@example.com',
    role:       UserRole.customer,
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
      name:      request.name      ?? _mockUser.name,
      email:     request.email     ?? _mockUser.email,
      avatarUrl: request.avatarUrl ?? _mockUser.avatarUrl,
      updatedAt: DateTime.now(),
    );
    return _mockUser;
  }

  // ── Addresses ─────────────────────────────────────────────────────────────

  final List<AddressModel> _addresses = [
    const AddressModel(
      id:        'addr_1',
      userId:    'usr_demo',
      line1:     '42, MG Road',
      city:      'Bengaluru',
      state:     'Karnataka',
      pincode:   '560001',
      type:      AddressType.home,
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
      id:        'addr_${DateTime.now().millisecondsSinceEpoch}',
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<dynamic> _loadJson(String name) async {
    final raw = await rootBundle.loadString('assets/mock/$name.json');
    return json.decode(raw);
  }

  Future<void> _delay({bool fast = false}) =>
      Future.delayed(Duration(milliseconds: fast ? 200 : 600));
}

// ── Riverpod Provider ─────────────────────────────────────────────────────────

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return MockCustomerRepository();
  // Later: return ApiCustomerRepository(dio: ref.watch(dioProvider));
});
