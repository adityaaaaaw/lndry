import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';
import '../abstract/vendor_repository.dart';

/// Mock implementation of [VendorRepository] for future vendor module needs.
class MockVendorRepository implements VendorRepository {
  MockVendorRepository();

  @override
  Future<VendorModel> getMyVendorProfile() async {
    await _delay();
    final data = await _loadJson('vendors');
    final json = (data as List).first as Map<String, dynamic>;
    return VendorModel.fromJson(json);
  }

  @override
  Future<VendorModel> updateVendorProfile(VendorModel vendor) async {
    await _delay();
    return vendor;
  }

  @override
  Future<List<ServiceModel>> getMyServices() async {
    await _delay();
    final data = await _loadJson('services');
    return (data as List)
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .where((s) => s.vendorId == 'vndr_001')
        .toList();
  }

  @override
  Future<ServiceModel> addService(ServiceModel service) async {
    await _delay();
    return service;
  }

  @override
  Future<ServiceModel> updateService(ServiceModel service) async {
    await _delay();
    return service;
  }

  @override
  Future<void> toggleServiceAvailability(String serviceId, bool isAvailable) async {
    await _delay(fast: true);
  }

  @override
  Future<PaginatedResponse<OrderModel>> getIncomingOrders({
    PaginationParams params = const PaginationParams(),
  }) async {
    await _delay();
    final data = await _loadJson('orders');
    final orders = (data as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .where((o) => o.vendorId == 'vndr_001')
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
  Future<OrderModel> acceptOrder(String orderId) async {
    await _delay();
    final order = await _getOrder(orderId);
    return order.copyWith(status: OrderStatus.confirmed);
  }

  @override
  Future<OrderModel> rejectOrder(String orderId, {String? reason}) async {
    await _delay();
    final order = await _getOrder(orderId);
    return order.copyWith(status: OrderStatus.cancelled, cancellationReason: reason);
  }

  @override
  Future<OrderModel> markOrderReady(String orderId) async {
    await _delay();
    final order = await _getOrder(orderId);
    return order.copyWith(status: OrderStatus.ready);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<OrderModel> _getOrder(String orderId) async {
    final data = await _loadJson('orders');
    final json = (data as List).firstWhere(
      (e) => (e as Map<String, dynamic>)['id'] == orderId,
      orElse: () => throw Exception('Order $orderId not found'),
    );
    return OrderModel.fromJson(json as Map<String, dynamic>);
  }

  Future<dynamic> _loadJson(String name) async {
    final raw = await rootBundle.loadString('assets/mock/$name.json');
    return json.decode(raw);
  }

  Future<void> _delay({bool fast = false}) =>
      Future.delayed(Duration(milliseconds: fast ? 200 : 600));
}
