import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

/// Order lifecycle status
enum OrderStatus {
  @JsonValue('pending')
  pending,

  @JsonValue('confirmed')
  confirmed,

  @JsonValue('picked_up')
  pickedUp,

  @JsonValue('processing')
  processing,

  @JsonValue('ready')
  ready,

  @JsonValue('out_for_delivery')
  outForDelivery,

  @JsonValue('delivered')
  delivered,

  @JsonValue('cancelled')
  cancelled,

  @JsonValue('refunded')
  refunded,
}

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.pickedUp => 'Picked Up',
        OrderStatus.processing => 'Processing',
        OrderStatus.ready => 'Ready',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        OrderStatus.refunded => 'Refunded',
      };

  bool get isActive =>
      this != OrderStatus.delivered &&
      this != OrderStatus.cancelled &&
      this != OrderStatus.refunded;

  bool get isCancellable =>
      this == OrderStatus.pending || this == OrderStatus.confirmed;
}

/// Payment methods supported
enum PaymentMethod {
  @JsonValue('cash')
  cash,

  @JsonValue('upi')
  upi,

  @JsonValue('card')
  card,

  @JsonValue('wallet')
  wallet,
}

/// A single laundry item in an order
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String serviceId,
    required String serviceName,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
    String? notes,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

/// Core Order model
@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    required String id,
    required String customerId,
    required String vendorId,
    String? deliveryPartnerId,
    required List<OrderItem> items,
    required OrderStatus status,
    required double subtotal,
    required double platformFee,
    required double gstAmount,
    required double total,
    required PaymentMethod paymentMethod,
    @Default(false) bool isPaid,
    required String pickupAddressId,
    required String deliveryAddressId,
    DateTime? scheduledPickupAt,
    DateTime? estimatedDeliveryAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? cancellationReason,
    String? customerNotes,
    double? customerRating,
    String? customerReview,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}
