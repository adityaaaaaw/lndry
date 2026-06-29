import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User roles in the LNDRY platform
enum UserRole {
  @JsonValue('customer')
  customer,

  @JsonValue('vendor')
  vendor,

  @JsonValue('delivery')
  delivery,

  @JsonValue('admin')
  admin,
}

extension UserRoleX on UserRole {
  String get displayName => switch (this) {
        UserRole.customer => 'Customer',
        UserRole.vendor => 'Vendor',
        UserRole.delivery => 'Delivery Partner',
        UserRole.admin => 'Admin',
      };

  bool get isCustomer => this == UserRole.customer;
  bool get isVendor => this == UserRole.vendor;
  bool get isDelivery => this == UserRole.delivery;
  bool get isAdmin => this == UserRole.admin;
}

/// Core User model shared across all modules
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String phone,
    String? email,
    String? avatarUrl,
    required UserRole role,
    @Default(false) bool isVerified,
    @Default(true) bool isActive,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
