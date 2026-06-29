import 'package:freezed_annotation/freezed_annotation.dart';
import 'address_model.dart';

part 'vendor_model.freezed.dart';
part 'vendor_model.g.dart';

/// A vendor profile in the LNDRY marketplace
@freezed
class VendorModel with _$VendorModel {
  const factory VendorModel({
    required String id,
    required String name,
    required String description,
    required String ownerName,
    required String phone,
    String? email,
    required AddressModel address,
    @Default([]) List<String> categoryIds,
    String? coverImageUrl,
    String? logoUrl,
    double? averageRating,
    @Default(0) int reviewCount,
    @Default(true) bool isOpen,
    @Default(false) bool isVerified,
    @Default(99.0) double minOrderAmount,
    @Default(10.0) double deliveryRadiusKm,
    @Default(24) int estimatedTurnaroundHours,
    @Default([]) List<String> tags,
    DateTime? createdAt,
  }) = _VendorModel;

  factory VendorModel.fromJson(Map<String, dynamic> json) =>
      _$VendorModelFromJson(json);
}

/// Category model for laundry service categories
@freezed
class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String id,
    required String name,
    required String description,
    required String icon,
    @Default('#4F6AF5') String color,
    String? imageUrl,
    @Default(true) bool isActive,
    @Default(0) int sortOrder,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);
}

/// Cart item
@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required String id,
    required String serviceId,
    required int quantity,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}

/// Cart aggregate
@freezed
class CartModel with _$CartModel {
  const factory CartModel({
    @Default([]) List<CartItem> items,
  }) = _CartModel;

  const CartModel._();

  bool get isEmpty  => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int  get itemCount => items.fold(0, (s, i) => s + i.quantity);
}

/// Notification model
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String userId,
    required String title,
    required String body,
    String? imageUrl,
    String? deepLink,
    @Default(false) bool isRead,
    required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
