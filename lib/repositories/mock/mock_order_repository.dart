import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../abstract/vendor_repository.dart';

/// Mock implementation of [OrderRepository] for shared/cross-role order operations.
class MockOrderRepository implements OrderRepository {
  MockOrderRepository();

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
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus status) async {
    await _delay();
    final order = await getOrderById(orderId);
    return order.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status) async {
    await _delay();
    final data = await _loadJson('orders');
    return (data as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .where((o) => o.status == status)
        .toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<dynamic> _loadJson(String name) async {
    final raw = await rootBundle.loadString('assets/mock/$name.json');
    return json.decode(raw);
  }

  Future<void> _delay() =>
      Future.delayed(const Duration(milliseconds: 600));
}
