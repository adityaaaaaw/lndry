import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';

/// Abstract contract for vendor-facing data operations.
/// Used by Vendor module (future). Defined now for type consistency.
abstract interface class VendorRepository {
  Future<VendorModel> getMyVendorProfile();
  Future<VendorModel> updateVendorProfile(VendorModel vendor);
  Future<List<ServiceModel>> getMyServices();
  Future<ServiceModel> addService(ServiceModel service);
  Future<ServiceModel> updateService(ServiceModel service);
  Future<void> toggleServiceAvailability(String serviceId, bool isAvailable);
  Future<PaginatedResponse<OrderModel>> getIncomingOrders({PaginationParams params});
  Future<OrderModel> acceptOrder(String orderId);
  Future<OrderModel> rejectOrder(String orderId, {String? reason});
  Future<OrderModel> markOrderReady(String orderId);
}

/// Abstract contract for order-specific operations shared across roles.
abstract interface class OrderRepository {
  Future<OrderModel> getOrderById(String orderId);
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus status);
  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status);
}
