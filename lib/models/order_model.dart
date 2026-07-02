import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

// ── Canonical Order Status ────────────────────────────────────────────────────
/// 21-state canonical LNDRY order lifecycle per spec §6.
/// Internal status → customer label mapping is in [OrderStatusX.customerLabel].
enum OrderStatus {
  @JsonValue('PAYMENT_PENDING')
  paymentPending,

  @JsonValue('PAYMENT_FAILED')
  paymentFailed,

  @JsonValue('WAITING_FOR_VENDOR_CONFIRMATION')
  waitingForVendorConfirmation,

  @JsonValue('VENDOR_ACCEPTED')
  vendorAccepted,

  @JsonValue('PICKUP_ASSIGNED')
  pickupAssigned,

  @JsonValue('GOING_FOR_PICKUP')
  goingForPickup,

  @JsonValue('PICKUP_OTP_VERIFIED')
  pickupOtpVerified,

  @JsonValue('PICKED_UP')
  pickedUp,

  @JsonValue('RECEIVED_AT_VENDOR')
  receivedAtVendor,

  @JsonValue('PROCESSING')
  processing,

  @JsonValue('PACKED')
  packed,

  @JsonValue('DELIVERY_ASSIGNED')
  deliveryAssigned,

  @JsonValue('OUT_FOR_DELIVERY')
  outForDelivery,

  @JsonValue('DELIVERY_OTP_VERIFIED')
  deliveryOtpVerified,

  @JsonValue('DELIVERED')
  delivered,

  @JsonValue('VENDOR_REJECTED')
  vendorRejected,

  @JsonValue('AUTO_REJECTED')
  autoRejected,

  @JsonValue('CUSTOMER_CANCELLED')
  customerCancelled,

  @JsonValue('ADMIN_CANCELLED')
  adminCancelled,

  @JsonValue('REFUND_PENDING')
  refundPending,

  @JsonValue('REFUNDED')
  refunded,
}

extension OrderStatusX on OrderStatus {
  /// Customer-facing label per spec §6 canonical mapping table.
  String get label => switch (this) {
        OrderStatus.paymentPending => 'Payment Pending',
        OrderStatus.paymentFailed => 'Payment Failed',
        OrderStatus.waitingForVendorConfirmation => 'Waiting for Vendor Confirmation',
        OrderStatus.vendorAccepted => 'Scheduled',
        OrderStatus.pickupAssigned => 'Scheduled',
        OrderStatus.goingForPickup => 'Pickup Partner Coming',
        OrderStatus.pickupOtpVerified => 'Picked Up',
        OrderStatus.pickedUp => 'Picked Up',
        OrderStatus.receivedAtVendor => 'At Partner',
        OrderStatus.processing => 'Processing',
        OrderStatus.packed => 'Packed',
        OrderStatus.deliveryAssigned => 'Out for Delivery',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.deliveryOtpVerified => 'Delivered',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.vendorRejected => 'Rejected by Vendor',
        OrderStatus.autoRejected => 'Auto-Rejected',
        OrderStatus.customerCancelled => 'Cancelled',
        OrderStatus.adminCancelled => 'Cancelled',
        OrderStatus.refundPending => 'Refund Pending',
        OrderStatus.refunded => 'Refunded',
      };

  /// Whether this order is still in progress (not a terminal state).
  bool get isActive => switch (this) {
        OrderStatus.delivered ||
        OrderStatus.deliveryOtpVerified ||
        OrderStatus.vendorRejected ||
        OrderStatus.autoRejected ||
        OrderStatus.customerCancelled ||
        OrderStatus.adminCancelled ||
        OrderStatus.refunded =>
          false,
        _ => true,
      };

  /// Whether the customer can cancel at this stage.
  bool get isCancellable => switch (this) {
        OrderStatus.waitingForVendorConfirmation ||
        OrderStatus.vendorAccepted ||
        OrderStatus.pickupAssigned =>
          true,
        _ => false,
      };

  /// Whether the order ended in a rejection that allows selecting another vendor.
  bool get isRejected =>
      this == OrderStatus.vendorRejected || this == OrderStatus.autoRejected;

  /// Whether this is a terminal failure/completion state.
  bool get isTerminal => !isActive;

  /// Whether a refund is applicable or pending.
  bool get hasRefundState =>
      this == OrderStatus.refundPending || this == OrderStatus.refunded;

  /// Pickup OTP should be visible at these statuses (backend visibility=true
  /// is the authoritative source; this is a client-side hint only).
  bool get showPickupOtpHint =>
      this == OrderStatus.goingForPickup || this == OrderStatus.pickupAssigned;

  /// Delivery OTP should be visible at these statuses.
  bool get showDeliveryOtpHint =>
      this == OrderStatus.outForDelivery || this == OrderStatus.deliveryAssigned;
}

// ── Payment Method ─────────────────────────────────────────────────────────────
/// Approved Razorpay-supported payment methods per spec §12/§16.
/// Cash and platform-wallet have been removed per spec §16.
enum PaymentMethod {
  @JsonValue('upi')
  upi,

  @JsonValue('card')
  card,

  @JsonValue('wallet')
  wallet, // Razorpay-supported wallet only; not LNDRY stored-value wallet
}

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.upi => 'UPI',
        PaymentMethod.card => 'Card',
        PaymentMethod.wallet => 'Wallet',
      };
}

// ── Order Item ─────────────────────────────────────────────────────────────────
/// A single service/garment line in an order.
/// NOTE: unitPrice and totalPrice are stored in PAISE (integer) per spec §6.
/// When backend is integrated these will be MoneyPaise = int.
/// For mock phase they remain double to avoid breaking existing mock JSON.
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String serviceId,
    required String serviceName,
    required int quantity,
    @Default(0.0) double unitPrice,
    @Default(0.0) double totalPrice,
    String? notes,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

// ── Order Model ────────────────────────────────────────────────────────────────
/// Core customer order entity.
/// Money fields are double in mock phase; will become integer paise when
/// ApiCustomerRepository is wired (see spec §6 Money rule).
@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    required String id,
    required String customerId,
    required String vendorId,
    String? deliveryPartnerId,
    required List<OrderItem> items,
    required OrderStatus status,
    @Default(0.0) double subtotal,
    @Default(0.0) double platformFee,
    @Default(0.0) double gstAmount,
    @Default(0.0) double total,
    @Default(PaymentMethod.upi) PaymentMethod paymentMethod,
    @Default(false) bool isPaid,
    @Default('') String pickupAddressId,
    @Default('') String deliveryAddressId,
    DateTime? scheduledPickupAt,
    DateTime? estimatedDeliveryAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? cancellationReason,
    String? vendorRejectionReason,
    String? customerNotes,
    double? customerRating,
    String? customerReview,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}
