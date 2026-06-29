import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';

/// Abstract contract for all customer-facing data operations.
/// Swap [MockCustomerRepository] → [ApiCustomerRepository] when backend is ready.
abstract interface class CustomerRepository {
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
  Future<CartModel> addToCart({required String serviceId, required int quantity});
  Future<CartModel> removeFromCart(String cartItemId);
  Future<CartModel> updateCartItem({required String cartItemId, required int quantity});
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

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<List<NotificationModel>> getNotifications({PaginationParams params});
  Future<void> markNotificationRead(String notificationId);
  Future<void> markAllNotificationsRead();
}

// ── Request DTOs (no freezed needed for simple request objects) ───────────────

class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.vendorId,
    required this.items,
    required this.deliveryAddressId,
    required this.pickupAddressId,
    required this.paymentMethod,
    this.scheduledPickupAt,
    this.notes,
  });

  final String vendorId;
  final List<OrderItemRequest> items;
  final String deliveryAddressId;
  final String pickupAddressId;
  final PaymentMethod paymentMethod;
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
