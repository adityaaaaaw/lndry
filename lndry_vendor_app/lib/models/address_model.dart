import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_model.freezed.dart';
part 'address_model.g.dart';

/// Address types
enum AddressType {
  @JsonValue('home')
  home,

  @JsonValue('work')
  work,

  @JsonValue('other')
  other,
}

extension AddressTypeX on AddressType {
  String get label => switch (this) {
        AddressType.home => 'Home',
        AddressType.work => 'Work',
        AddressType.other => 'Other',
      };
}

/// Geo-coordinate
@freezed
class LatLng with _$LatLng {
  const factory LatLng({
    required double latitude,
    required double longitude,
  }) = _LatLng;

  factory LatLng.fromJson(Map<String, dynamic> json) =>
      _$LatLngFromJson(json);
}

/// Customer delivery/pickup address
@freezed
class AddressModel with _$AddressModel {
  const factory AddressModel({
    required String id,
    required String userId,
    required String line1,
    String? line2,
    required String city,
    required String state,
    required String pincode,
    String? landmark,
    required AddressType type,
    @Default(false) bool isDefault,
    LatLng? coordinates,
    DateTime? createdAt,
  }) = _AddressModel;

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);
}
