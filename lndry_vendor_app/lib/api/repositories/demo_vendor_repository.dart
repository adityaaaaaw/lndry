
import 'dart:convert';
import '../../core/network/api_exception.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';
import '../../repositories/abstract/vendor_repository.dart';

class DemoVendorRepository implements VendorRepository {
  DemoVendorRepository({
    required StorageService storage,
  }) : _storage = storage {
    _initDefaultData();
    _loadPersistedData();
  }

  final StorageService _storage;

  // -- Stateful In-Memory Collections for Demonstration
  late VendorModel _profile;
  final List<ServiceModel> _services = [];
  final Map<String, List<Map<String, dynamic>>> _garmentRates = {};
  final List<OrderModel> _orders = [];
  final List<EmployeeModel> _employees = [];
  final List<PickupSlotModel> _slots = [];
  int _maxOrdersPerDay = 50;
  final Map<int, Map<String, dynamic>> _workingHours = {
    0: {'isOpen': true, 'openTime': '08:00', 'closeTime': '20:00'},
    1: {'isOpen': true, 'openTime': '08:00', 'closeTime': '20:00'},
    2: {'isOpen': true, 'openTime': '08:00', 'closeTime': '20:00'},
    3: {'isOpen': true, 'openTime': '08:00', 'closeTime': '20:00'},
    4: {'isOpen': true, 'openTime': '08:00', 'closeTime': '20:00'},
    5: {'isOpen': true, 'openTime': '08:00', 'closeTime': '20:00'},
    6: {'isOpen': true, 'openTime': '08:00', 'closeTime': '20:00'},
  };

  void _initDefaultData() {
    // 1. Profile Initialisation
    _profile = const VendorModel(
      id: 'demo_vendor_id',
      name: 'LNDRY Demo Store',
      phone: '9876543210',
      email: 'demo@lndry.app',
      isVerified: true,
      ownerName: 'Demo Vendor',
      description: 'Premium laundry & dry cleaning service in Hyderabad.',
      address: AddressModel(
        id: 'addr_1',
        userId: 'demo_vendor_id',
        line1: 'Gachibowli',
        city: 'Hyderabad',
        state: 'Telangana',
        pincode: '500032',
        type: AddressType.work,
      ),
    );

    // 2. Services Initialisation
    _services.addAll([
      const ServiceModel(
        id: 'wash_1',
        vendorId: 'demo_vendor_id',
        name: 'Premium Wash',
        description: 'Quality laundry wash with premium detergents.',
        category: ServiceCategory.wash,
        minWeightKg: 1.0,
        pricePerPiece: 5.0,
        isAvailable: true,
      ),
      const ServiceModel(
        id: 'iron_1',
        vendorId: 'demo_vendor_id',
        name: 'Steam Press',
        description: 'Professional steam ironing for a crisp look.',
        category: ServiceCategory.iron,
        minWeightKg: 1.0,
        pricePerPiece: 2.0,
        isAvailable: true,
      ),
      const ServiceModel(
        id: 'wash_iron_1',
        vendorId: 'demo_vendor_id',
        name: 'Wash & Steam Iron',
        description: 'Complete package: wash, dry, and steam press.',
        category: ServiceCategory.washAndIron,
        minWeightKg: 2.0,
        pricePerPiece: 8.0,
        isAvailable: true,
      ),
      const ServiceModel(
        id: 'dry_clean_1',
        vendorId: 'demo_vendor_id',
        name: 'Premium Dry Cleaning',
        description: 'Gentle dry cleaning for premium and delicate wear.',
        category: ServiceCategory.dryClean,
        minWeightKg: 1.0,
        pricePerPiece: 15.0,
        isAvailable: true,
      ),
    ]);

    // 3. Garment Rates Initialisation
    _garmentRates['wash_1'] = [
      {'garment_rate_id': 'gr_w_1', 'garment_name': 'Shirt', 'rate_paise': 500, 'unit': 'piece'},
      {'garment_rate_id': 'gr_w_2', 'garment_name': 'T-Shirt', 'rate_paise': 400, 'unit': 'piece'},
      {'garment_rate_id': 'gr_w_3', 'garment_name': 'Jeans', 'rate_paise': 800, 'unit': 'piece'},
      {'garment_rate_id': 'gr_w_4', 'garment_name': 'Kurta', 'rate_paise': 700, 'unit': 'piece'},
    ];
    _garmentRates['iron_1'] = [
      {'garment_rate_id': 'gr_i_1', 'garment_name': 'Shirt', 'rate_paise': 200, 'unit': 'piece'},
      {'garment_rate_id': 'gr_i_2', 'garment_name': 'Trousers', 'rate_paise': 200, 'unit': 'piece'},
      {'garment_rate_id': 'gr_i_3', 'garment_name': 'Suit (2pc)', 'rate_paise': 1000, 'unit': 'piece'},
    ];
    _garmentRates['wash_iron_1'] = [
      {'garment_rate_id': 'gr_wi_1', 'garment_name': 'Shirt', 'rate_paise': 800, 'unit': 'piece'},
      {'garment_rate_id': 'gr_wi_2', 'garment_name': 'Jeans', 'rate_paise': 1200, 'unit': 'piece'},
      {'garment_rate_id': 'gr_wi_3', 'garment_name': 'Saree', 'rate_paise': 1500, 'unit': 'piece'},
    ];
    _garmentRates['dry_clean_1'] = [
      {'garment_rate_id': 'gr_dc_1', 'garment_name': 'Suit (2pc)', 'rate_paise': 3500, 'unit': 'piece'},
      {'garment_rate_id': 'gr_dc_2', 'garment_name': 'Sherwani', 'rate_paise': 5000, 'unit': 'piece'},
      {'garment_rate_id': 'gr_dc_3', 'garment_name': 'Silk Saree', 'rate_paise': 2500, 'unit': 'piece'},
    ];

    // 4. Orders Initialisation
    final now = DateTime.now();
    _orders.addAll([
      OrderModel(
        id: 'ord_pending_01',
        customerId: 'cust_1',
        vendorId: 'demo_vendor_id',
        status: OrderStatus.waitingForVendorConfirmation,
        subtotal: 250.0,
        platformFee: 15.0,
        gstAmount: 45.0,
        total: 310.0,
        paymentMethod: PaymentMethod.upi,
        isPaid: true,
        pickupAddressId: 'addr_c1',
        deliveryAddressId: 'addr_c1',
        scheduledPickupAt: now.add(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(minutes: 15)),
        items: const [
          OrderItem(serviceId: 'wash_1', serviceName: 'Premium Wash', quantity: 3, unitPrice: 50.0, totalPrice: 150.0),
          OrderItem(serviceId: 'iron_1', serviceName: 'Steam Press', quantity: 5, unitPrice: 20.0, totalPrice: 100.0),
        ],
      ),
      OrderModel(
        id: 'ord_received_02',
        customerId: 'cust_2',
        vendorId: 'demo_vendor_id',
        status: OrderStatus.receivedAtVendor,
        subtotal: 180.0,
        platformFee: 15.0,
        gstAmount: 32.4,
        total: 227.4,
        paymentMethod: PaymentMethod.card,
        isPaid: true,
        pickupAddressId: 'addr_c2',
        deliveryAddressId: 'addr_c2',
        scheduledPickupAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(hours: 2)),
        items: const [
          OrderItem(serviceId: 'wash_1', serviceName: 'Premium Wash', quantity: 4, unitPrice: 45.0, totalPrice: 180.0),
        ],
      ),
      OrderModel(
        id: 'ord_active_03',
        customerId: 'cust_3',
        vendorId: 'demo_vendor_id',
        status: OrderStatus.processing,
        subtotal: 350.0,
        platformFee: 15.0,
        gstAmount: 63.0,
        total: 428.0,
        paymentMethod: PaymentMethod.upi,
        isPaid: true,
        pickupAddressId: 'addr_c3',
        deliveryAddressId: 'addr_c3',
        scheduledPickupAt: now.subtract(const Duration(hours: 4)),
        createdAt: now.subtract(const Duration(hours: 5)),
        items: const [
          OrderItem(serviceId: 'dry_clean_1', serviceName: 'Premium Dry Cleaning', quantity: 2, unitPrice: 100.0, totalPrice: 200.0),
          OrderItem(serviceId: 'wash_iron_1', serviceName: 'Wash & Steam Iron', quantity: 3, unitPrice: 50.0, totalPrice: 150.0),
        ],
      ),
      OrderModel(
        id: 'ord_packed_04',
        customerId: 'cust_4',
        vendorId: 'demo_vendor_id',
        status: OrderStatus.packed,
        subtotal: 120.0,
        platformFee: 15.0,
        gstAmount: 21.6,
        total: 156.6,
        paymentMethod: PaymentMethod.wallet,
        isPaid: true,
        pickupAddressId: 'addr_c4',
        deliveryAddressId: 'addr_c4',
        scheduledPickupAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        items: const [
          OrderItem(serviceId: 'wash_1', serviceName: 'Premium Wash', quantity: 3, unitPrice: 40.0, totalPrice: 120.0),
        ],
      ),
      OrderModel(
        id: 'ord_delivered_05',
        customerId: 'cust_5',
        vendorId: 'demo_vendor_id',
        status: OrderStatus.delivered,
        subtotal: 450.0,
        platformFee: 15.0,
        gstAmount: 81.0,
        total: 546.0,
        paymentMethod: PaymentMethod.upi,
        isPaid: true,
        pickupAddressId: 'addr_c5',
        deliveryAddressId: 'addr_c5',
        scheduledPickupAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
        items: const [
          OrderItem(serviceId: 'dry_clean_1', serviceName: 'Premium Dry Cleaning', quantity: 3, unitPrice: 150.0, totalPrice: 450.0),
        ],
      ),
    ]);

    // Generate 35 additional realistic orders dynamically
    final servicesList = [
      {'id': 'wash_1', 'name': 'Premium Wash', 'price': 50.0},
      {'id': 'iron_1', 'name': 'Steam Press', 'price': 20.0},
      {'id': 'wash_iron_1', 'name': 'Wash & Steam Iron', 'price': 60.0},
      {'id': 'dry_clean_1', 'name': 'Premium Dry Cleaning', 'price': 150.0},
    ];

    final statuses = [
      OrderStatus.waitingForVendorConfirmation,
      OrderStatus.vendorAccepted,
      OrderStatus.receivedAtVendor,
      OrderStatus.processing,
      OrderStatus.packed,
      OrderStatus.delivered,
      OrderStatus.vendorRejected,
      OrderStatus.customerCancelled,
    ];

    for (int i = 6; i <= 40; i++) {
      final orderStatus = statuses[i % statuses.length];
      final orderDate = now.subtract(Duration(days: i % 15, hours: i % 24, minutes: (i * 7) % 60));
      
      final item1 = servicesList[i % servicesList.length];
      final item2 = servicesList[(i + 1) % servicesList.length];
      
      final qty1 = (i % 4) + 1;
      final qty2 = (i % 3) + 1;
      
      final price1 = item1['price'] as double;
      final price2 = item2['price'] as double;
      
      final subtotal = (price1 * qty1) + (price2 * qty2);
      final platformFee = 15.0;
      final gstAmount = (subtotal * 0.18);
      final total = subtotal + platformFee + gstAmount;

      _orders.add(
        OrderModel(
          id: 'ord_mock_${100 + i}',
          customerId: 'cust_${100 + i}',
          vendorId: 'demo_vendor_id',
          status: orderStatus,
          subtotal: double.parse(subtotal.toStringAsFixed(2)),
          platformFee: platformFee,
          gstAmount: double.parse(gstAmount.toStringAsFixed(2)),
          total: double.parse(total.toStringAsFixed(2)),
          paymentMethod: i % 3 == 0 ? PaymentMethod.card : (i % 3 == 1 ? PaymentMethod.upi : PaymentMethod.wallet),
          isPaid: orderStatus == OrderStatus.delivered || i % 2 == 0,
          pickupAddressId: 'addr_${100 + i}',
          deliveryAddressId: 'addr_${100 + i}',
          scheduledPickupAt: orderDate.add(const Duration(hours: 3)),
          createdAt: orderDate,
          customerNotes: i % 5 == 0 ? 'Handle with care, delicate fabric.' : null,
          customerRating: orderStatus == OrderStatus.delivered ? (4.0 + (i % 2) * 0.5 + (i % 3) * 0.1) : null,
          customerReview: orderStatus == OrderStatus.delivered && i % 4 == 0 ? 'Excellent laundry service, prompt delivery!' : null,
          items: [
            OrderItem(
              serviceId: item1['id'] as String,
              serviceName: item1['name'] as String,
              quantity: qty1,
              unitPrice: price1,
              totalPrice: price1 * qty1,
            ),
            OrderItem(
              serviceId: item2['id'] as String,
              serviceName: item2['name'] as String,
              quantity: qty2,
              unitPrice: price2,
              totalPrice: price2 * qty2,
            ),
          ],
        ),
      );
    }

    // 5. Employees Initialisation
    _employees.addAll([
      const EmployeeModel(
        id: 'emp_1',
        vendorId: 'demo_vendor_id',
        userId: 'usr_emp_1',
        name: 'Anil Kumar',
        email: 'anil@lndry.app',
        phone: '9876543210',
        role: 'manager',
        isActive: true,
      ),
      const EmployeeModel(
        id: 'emp_2',
        vendorId: 'demo_vendor_id',
        userId: 'usr_emp_2',
        name: 'Sunita Rao',
        email: 'sunita@lndry.app',
        phone: '9876543211',
        role: 'washer',
        isActive: true,
      ),
      const EmployeeModel(
        id: 'emp_3',
        vendorId: 'demo_vendor_id',
        userId: 'usr_emp_3',
        name: 'Ravi Teja',
        email: 'ravi@lndry.app',
        phone: '9876543212',
        role: 'ironer',
        isActive: true,
      ),
    ]);

    // 6. Slots Initialisation
    _slots.addAll([
      const PickupSlotModel(id: 'slot_1', vendorId: 'demo_vendor_id', dayOfWeek: 1, startTime: '09:00', endTime: '12:00', maxOrders: 10, isActive: true),
      const PickupSlotModel(id: 'slot_2', vendorId: 'demo_vendor_id', dayOfWeek: 1, startTime: '14:00', endTime: '17:00', maxOrders: 15, isActive: true),
      const PickupSlotModel(id: 'slot_3', vendorId: 'demo_vendor_id', dayOfWeek: 2, startTime: '09:00', endTime: '12:00', maxOrders: 10, isActive: true),
      const PickupSlotModel(id: 'slot_4', vendorId: 'demo_vendor_id', dayOfWeek: 3, startTime: '09:00', endTime: '12:00', maxOrders: 10, isActive: true),
      const PickupSlotModel(id: 'slot_5', vendorId: 'demo_vendor_id', dayOfWeek: 3, startTime: '14:00', endTime: '17:00', maxOrders: 15, isActive: true),
      const PickupSlotModel(id: 'slot_6', vendorId: 'demo_vendor_id', dayOfWeek: 4, startTime: '09:00', endTime: '12:00', maxOrders: 10, isActive: true),
      const PickupSlotModel(id: 'slot_7', vendorId: 'demo_vendor_id', dayOfWeek: 5, startTime: '09:00', endTime: '12:00', maxOrders: 10, isActive: true),
      const PickupSlotModel(id: 'slot_8', vendorId: 'demo_vendor_id', dayOfWeek: 5, startTime: '14:00', endTime: '17:00', maxOrders: 15, isActive: true),
      const PickupSlotModel(id: 'slot_9', vendorId: 'demo_vendor_id', dayOfWeek: 6, startTime: '10:00', endTime: '16:00', maxOrders: 20, isActive: true),
    ]);
  }

  // ── Auth implementation (Demo mode specific bypass) ────────────────────────
  @override
  Future<SendOtpResult> sendOtp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    var normalized = cleanPhone;
    if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
      normalized = cleanPhone.substring(2);
    }
    if (normalized.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(normalized)) {
      throw const ApiException(message: 'Please enter a valid Indian 10-digit mobile number.');
    }
    return const SendOtpResult(
      challengeId: 'demo_challenge_id',
      expiresIn: 300,
      devOtp: '123456',
    );
  }

  @override
  Future<VerifyOtpVendorResult> verifyOtp({
    required String phone,
    required String otp,
    String? challengeId,
    Map<String, dynamic>? device,
  }) async {
    if (otp != '123456') {
      throw const ApiException(message: 'Invalid OTP. For demo mode, enter: 123456');
    }

    // Persist entered phone number in the mock profile
    _profile = _profile.copyWith(phone: phone);

    // Save tokens securely to sustain reload session persistence
    await _storage.saveSecure(AppConstants.keyAccessToken, 'demo_access_token');
    await _storage.saveSecure(AppConstants.keyRefreshToken, 'demo_refresh_token');

    return VerifyOtpVendorResult(
      accessToken: 'demo_access_token',
      refreshToken: 'demo_refresh_token',
      vendor: _profile,
    );
  }

  @override
  Future<TokenPair> refreshTokens() async {
    return const TokenPair(
      accessToken: 'demo_access_token',
      refreshToken: 'demo_refresh_token',
    );
  }

  @override
  Future<void> logout() async {
    // clear session values
    await _storage.clearSession();
  }

  // ── Profile Implementation ──────────────────────────────────────────────────
  @override
  Future<VendorModel> getProfile() async {
    return _profile;
  }

  @override
  Future<VendorModel> updateProfile({
    required String name,
    required String email,
  }) async {
    _profile = _profile.copyWith(
      name: name.isNotEmpty ? name : _profile.name,
      email: email.isNotEmpty ? email : _profile.email,
    );
    await _saveProfile();
    return _profile;
  }

  @override
  Future<VendorModel> toggleStoreOpen(bool isOpen) async {
    _profile = _profile.copyWith(isOpen: isOpen);
    await _saveProfile();
    return _profile;
  }

  // ── Services Catalogue Implementation ─────────────────────────────────────────
  @override
  Future<List<ServiceModel>> getMyServices() async {
    return _services;
  }

  @override
  Future<ServiceModel> addService(ServiceModel service) async {
    final newService = service.copyWith(
      id: 'srv_${DateTime.now().millisecondsSinceEpoch}',
      vendorId: 'demo_vendor_id',
    );
    _services.add(newService);
    return newService;
  }

  @override
  Future<ServiceModel> updateService(ServiceModel service) async {
    final idx = _services.indexWhere((s) => s.id == service.id);
    if (idx != -1) {
      _services[idx] = service;
      return service;
    }
    return service;
  }

  @override
  Future<void> toggleServiceAvailability(String serviceId, bool isAvailable) async {
    final idx = _services.indexWhere((s) => s.id == serviceId);
    if (idx != -1) {
      _services[idx] = _services[idx].copyWith(isAvailable: isAvailable);
    }
  }

  @override
  Future<void> deleteService(String serviceId) async {
    _services.removeWhere((s) => s.id == serviceId);
    _garmentRates.remove(serviceId);
  }

  @override
  Future<Map<String, dynamic>> getServiceDetails(String serviceId) async {
    final srv = _services.firstWhere((s) => s.id == serviceId, orElse: () => _services.first);
    final rates = _garmentRates[serviceId] ?? [];
    return {
      'id': srv.id,
      'name': srv.name,
      'description': srv.description,
      'category': srv.category.name,
      'garments': rates,
    };
  }

  @override
  Future<void> addGarmentRate(
    String serviceId, {
    String? garmentTypeId,
    String? garmentTypeName,
    required double rate,
    String? rateUnit,
  }) async {
    final rates = _garmentRates[serviceId] ?? [];
    final id = garmentTypeId ?? 'g_rate_${DateTime.now().millisecondsSinceEpoch}';
    final name = garmentTypeName ?? 'New Custom Garment';
    rates.add({
      'garment_rate_id': id,
      'garment_name': name,
      'rate_paise': (rate * 100).toInt(),
      'unit': rateUnit ?? 'piece',
    });
    _garmentRates[serviceId] = rates;
  }

  @override
  Future<void> deleteGarmentRate(String serviceId, String garmentTypeId) async {
    final rates = _garmentRates[serviceId] ?? [];
    rates.removeWhere((r) => r['garment_rate_id'] == garmentTypeId);
    _garmentRates[serviceId] = rates;
  }

  // ── Orders Operations Implementation ──────────────────────────────────────────
  @override
  Future<OrderModel> getOrder(String orderId) async {
    return _orders.firstWhere((o) => o.id == orderId, orElse: () => _orders.first);
  }

  @override
  Future<PaginatedResponse<OrderModel>> getIncomingOrders({
    PaginationParams params = const PaginationParams(),
    String? status,
  }) async {
    var filtered = _orders;
    if (status != null && status.isNotEmpty) {
      filtered = _orders.where((o) {
        final st = o.status.name.toLowerCase();
        final filterSt = status.toLowerCase();
        
        // Handle alias filtering: Active orders group
        if (filterSt == 'active') {
          return o.status == OrderStatus.vendorAccepted ||
              o.status == OrderStatus.receivedAtVendor ||
              o.status == OrderStatus.processing;
        }
        
        // Handle pending state
        if (filterSt == 'pending' || filterSt == 'waiting_for_vendor_confirmation') {
          return o.status == OrderStatus.waitingForVendorConfirmation;
        }

        // Handle ready state
        if (filterSt == 'ready' || filterSt == 'packed') {
          return o.status == OrderStatus.packed;
        }

        // Handle history state
        if (filterSt == 'history') {
          return o.status == OrderStatus.delivered ||
              o.status == OrderStatus.vendorRejected ||
              o.status == OrderStatus.autoRejected ||
              o.status == OrderStatus.customerCancelled;
        }

        return st == filterSt;
      }).toList();
    }

    return PaginatedResponse(
      items: filtered,
      meta: PaginationMeta(
        currentPage: params.page,
        totalPages: 1,
        totalItems: filtered.length,
        pageSize: params.pageSize,
      ),
    );
  }

  @override
  Future<OrderModel> acceptOrder(String orderId) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: OrderStatus.vendorAccepted);
      return _orders[idx];
    }
    throw const ApiException(message: 'Order not found');
  }

  @override
  Future<OrderModel> rejectOrder(String orderId, {String? reason}) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        status: OrderStatus.vendorRejected,
        vendorRejectionReason: reason ?? 'Demonstration reject',
      );
      return _orders[idx];
    }
    throw const ApiException(message: 'Order not found');
  }

  @override
  Future<OrderModel> markOrderReady(String orderId) async {
    return updateProcessingStage(orderId, 'PACKED');
  }

  @override
  Future<OrderModel> updateProcessingStage(String orderId, String stage) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final parsedStatus = switch (stage.toUpperCase()) {
        'WASHING' || 'DRYING' || 'IRONING' || 'PROCESSING' => OrderStatus.processing,
        'PACKED' => OrderStatus.packed,
        'DELIVERED' => OrderStatus.delivered,
        'RECEIVED_AT_VENDOR' => OrderStatus.receivedAtVendor,
        _ => OrderStatus.processing,
      };
      _orders[idx] = _orders[idx].copyWith(status: parsedStatus);
      return _orders[idx];
    }
    throw const ApiException(message: 'Order not found');
  }

  @override
  Future<OrderModel> reconcileOrder(
    String orderId, {
    List<Map<String, dynamic>>? confirmedLines,
    double? confirmedWeightKg,
    String? adjustmentReason,
  }) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final order = _orders[idx];
      var newItems = order.items;
      if (confirmedLines != null) {
        newItems = confirmedLines.map((line) {
          final srvId = line['serviceId'] as String? ?? '';
          final name = line['serviceName'] as String? ?? 'Service';
          final qty = (line['quantity'] as num?)?.toInt() ?? 0;
          final unitPrice = (line['unitPrice'] as num?)?.toDouble() ?? 0.0;
          return OrderItem(
            serviceId: srvId,
            serviceName: name,
            quantity: qty,
            unitPrice: unitPrice,
            totalPrice: qty * unitPrice,
          );
        }).toList();
      }

      double subtotal = 0.0;
      for (final it in newItems) {
        subtotal += it.totalPrice;
      }
      
      final gst = subtotal * 0.18;
      final total = subtotal + order.platformFee + gst;

      _orders[idx] = order.copyWith(
        items: newItems,
        subtotal: subtotal,
        gstAmount: gst,
        total: total,
        cancellationReason: adjustmentReason,
      );
      return _orders[idx];
    }
    throw const ApiException(message: 'Order not found');
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final pendingCount = _orders.where((o) => o.status == OrderStatus.waitingForVendorConfirmation).length;
    final activeCount = _orders.where((o) =>
      o.status == OrderStatus.vendorAccepted ||
      o.status == OrderStatus.receivedAtVendor ||
      o.status == OrderStatus.pickupAssigned ||
      o.status == OrderStatus.goingForPickup ||
      o.status == OrderStatus.pickupOtpVerified ||
      o.status == OrderStatus.pickedUp ||
      o.status == OrderStatus.processing).length;
    final readyCount = _orders.where((o) => o.status == OrderStatus.packed).length;

    // Revenue: only count delivered orders from TODAY
    double todayRevenue = 0.0;
    int todayDeliveredCount = 0;
    for (final o in _orders) {
      if (o.status == OrderStatus.delivered &&
          o.createdAt.isAfter(todayStart) &&
          o.createdAt.isBefore(todayEnd)) {
        todayRevenue += o.total;
        todayDeliveredCount++;
      }
    }

    return {
      'today_orders_count': _orders.where((o) =>
        o.createdAt.isAfter(todayStart) && o.createdAt.isBefore(todayEnd)).length,
      'pending_orders': pendingCount,
      'processing_orders': activeCount,
      'packed_orders': readyCount,
      'revenue_today_paise': (todayRevenue * 100).toInt(),
      'today_delivered_count': todayDeliveredCount,
    };
  }

  // ── Device Tokens Implementation ─────────────────────────────────────────────
  @override
  Future<void> registerDevice({
    required String deviceId,
    required String platform,
    required String fcmToken,
  }) async {}

  @override
  Future<void> unregisterDevice(String deviceId) async {}

  // ── Employee Management Implementation ────────────────────────────────────────
  @override
  Future<List<EmployeeModel>> getEmployees() async {
    return _employees;
  }

  @override
  Future<EmployeeModel> createEmployee({
    required String name,
    required String email,
    required String role,
    String? phone,
    List<String>? permissions,
  }) async {
    final emp = EmployeeModel(
      id: 'emp_${DateTime.now().millisecondsSinceEpoch}',
      vendorId: 'demo_vendor_id',
      userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      permissions: permissions ?? const [],
      isActive: true,
    );
    _employees.add(emp);
    return emp;
  }

  @override
  Future<EmployeeModel> updateEmployee(
    String id, {
    required String role,
    required List<String> permissions,
    required bool isActive,
  }) async {
    final idx = _employees.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final updated = _employees[idx].copyWith(
        role: role,
        permissions: permissions,
        isActive: isActive,
      );
      _employees[idx] = updated;
      return updated;
    }
    throw const ApiException(message: 'Employee not found');
  }

  @override
  Future<void> deleteEmployee(String id) async {
    _employees.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> resetEmployeePassword(String id, String newPassword) async {}

  // ── Slots Implementation ─────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getCapacity() async {
    return {'max_orders_per_day': _maxOrdersPerDay};
  }

  @override
  Future<void> updateCapacityDailyLimit(int maxOrdersPerDay) async {
    _maxOrdersPerDay = maxOrdersPerDay;
  }

  @override
  Future<List<PickupSlotModel>> getPickupSlots() async {
    return _slots;
  }

  @override
  Future<PickupSlotModel> createPickupSlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    int? maxOrders,
  }) async {
    final slot = PickupSlotModel(
      id: 'slot_${DateTime.now().millisecondsSinceEpoch}',
      vendorId: 'demo_vendor_id',
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      maxOrders: maxOrders ?? 5,
      isActive: true,
    );
    _slots.add(slot);
    await _saveSlots();
    return slot;
  }

  @override
  Future<PickupSlotModel> updatePickupSlot(
    String id, {
    int? maxOrders,
    bool? isActive,
  }) async {
    final idx = _slots.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final s = _slots[idx];
      final updated = PickupSlotModel(
        id: s.id,
        vendorId: s.vendorId,
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
        endTime: s.endTime,
        maxOrders: maxOrders ?? s.maxOrders,
        isActive: isActive ?? s.isActive,
      );
      _slots[idx] = updated;
      await _saveSlots();
      return updated;
    }
    throw const ApiException(message: 'Slot not found');
  }

  @override
  Future<void> deletePickupSlot(String id) async {
    _slots.removeWhere((s) => s.id == id);
    await _saveSlots();
  }

  // ── Analytics Implementation ─────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getAnalyticsSummary({String period = 'week'}) async {
    final now = DateTime.now();
    final cutoff = period == 'week'
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    final periodOrders = _orders.where((o) => o.createdAt.isAfter(cutoff)).toList();

    double totalRevenue = 0.0;
    int deliveredCount = 0;
    int cancelledCount = 0;
    int processingCount = 0;
    int pendingCount = 0;

    final Map<String, double> categoryRevenue = {};

    for (final o in periodOrders) {
      if (o.status == OrderStatus.delivered) {
        totalRevenue += o.total;
        deliveredCount++;
        // Accumulate per-category
        for (final item in o.items) {
          categoryRevenue.update(
            item.serviceName,
            (existing) => existing + item.totalPrice,
            ifAbsent: () => item.totalPrice,
          );
        }
      } else if ([
        OrderStatus.vendorRejected,
        OrderStatus.customerCancelled,
        OrderStatus.adminCancelled,
        OrderStatus.autoRejected,
      ].contains(o.status)) {
        cancelledCount++;
      } else if (o.status == OrderStatus.processing) {
        processingCount++;
      } else if (o.status == OrderStatus.waitingForVendorConfirmation) {
        pendingCount++;
      }
    }

    // Daily breakdown for chart (last 7 days always shown)
    final List<Map<String, dynamic>> dailyData = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayOrders = _orders.where((o) =>
        o.createdAt.isAfter(dayStart) && o.createdAt.isBefore(dayEnd) &&
        o.status == OrderStatus.delivered,
      );
      double dayRevenue = 0.0;
      int dayCount = 0;
      for (final o in dayOrders) {
        dayRevenue += o.total;
        dayCount++;
      }
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
      dailyData.add({
        'label': weekday,
        'revenue': dayRevenue,
        'orders': dayCount,
      });
    }

    // Normalise category revenue into percentage breakdown
    final List<Map<String, dynamic>> categoryBreakdown = [];
    if (totalRevenue > 0) {
      categoryRevenue.forEach((name, rev) {
        categoryBreakdown.add({
          'name': name,
          'revenue': rev,
          'percentage': (rev / totalRevenue * 100).roundToDouble(),
        });
      });
      categoryBreakdown.sort((a, b) =>
          (b['revenue'] as double).compareTo(a['revenue'] as double));
    }

    final totalOrders = periodOrders.length;
    final fulfillmentRate = totalOrders > 0
        ? (deliveredCount / totalOrders * 100).roundToDouble()
        : 0.0;
    final avgTicket = deliveredCount > 0 ? totalRevenue / deliveredCount : 0.0;

    return {
      'period': period,
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'delivered_orders': deliveredCount,
      'cancelled_orders': cancelledCount,
      'processing_orders': processingCount,
      'pending_orders': pendingCount,
      'fulfillment_rate': fulfillmentRate,
      'avg_ticket_size': avgTicket,
      'daily_data': dailyData,
      'category_breakdown': categoryBreakdown,
      'repeat_customer_rate': 82.0,
      'on_time_delivery_rate': 94.0,
    };
  }

  @override
  Future<Map<int, Map<String, dynamic>>> getWorkingHours() async {
    return _workingHours;
  }

  @override
  Future<void> updateWorkingHours(int dayOfWeek, {required bool isOpen, required String openTime, required String closeTime}) async {
    _workingHours[dayOfWeek] = {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
    await _saveWorkingHours();
  }

  void _loadPersistedData() {
    final profileJson = _storage.getString('demo_profile');
    if (profileJson != null) {
      try {
        _profile = VendorModel.fromJson(jsonDecode(profileJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    final workingHoursJson = _storage.getString('demo_working_hours');
    if (workingHoursJson != null) {
      try {
        final decoded = jsonDecode(workingHoursJson) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          final day = int.tryParse(key);
          if (day != null) {
            _workingHours[day] = val as Map<String, dynamic>;
          }
        });
      } catch (_) {}
    }

    final slotsJson = _storage.getString('demo_slots');
    if (slotsJson != null) {
      try {
        final decoded = jsonDecode(slotsJson) as List<dynamic>;
        _slots.clear();
        for (final item in decoded) {
          _slots.add(PickupSlotModel.fromJson(item as Map<String, dynamic>));
        }
      } catch (_) {}
    }
  }

  Future<void> _saveProfile() async {
    await _storage.saveString('demo_profile', jsonEncode(_profile.toJson()));
  }

  Future<void> _saveWorkingHours() async {
    final stringKeyed = <String, Map<String, dynamic>>{};
    _workingHours.forEach((k, v) {
      stringKeyed[k.toString()] = v;
    });
    await _storage.saveString('demo_working_hours', jsonEncode(stringKeyed));
  }

  Future<void> _saveSlots() async {
    final list = _slots.map((s) => s.toJson()).toList();
    await _storage.saveString('demo_slots', jsonEncode(list));
  }
}
