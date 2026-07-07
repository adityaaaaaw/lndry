import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_model.freezed.dart';
part 'service_model.g.dart';

/// Laundry service categories
enum ServiceCategory {
  @JsonValue('wash')
  wash,

  @JsonValue('iron')
  iron,

  @JsonValue('wash_iron')
  washAndIron,

  @JsonValue('dry_clean')
  dryClean,

  @JsonValue('fold')
  fold,

  @JsonValue('premium')
  premium,
}

extension ServiceCategoryX on ServiceCategory {
  String get label => switch (this) {
        ServiceCategory.wash => 'Wash',
        ServiceCategory.iron => 'Iron',
        ServiceCategory.washAndIron => 'Wash & Iron',
        ServiceCategory.dryClean => 'Dry Clean',
        ServiceCategory.fold => 'Fold',
        ServiceCategory.premium => 'Premium',
      };
}

/// A vendor's laundry service offering
@freezed
class ServiceModel with _$ServiceModel {
  const factory ServiceModel({
    required String id,
    required String vendorId,
    required String name,
    required String description,
    required ServiceCategory category,
    double? pricePerKg,
    double? pricePerPiece,
    required double minWeightKg,
    @Default(true) bool isAvailable,
    String? imageUrl,
    @Default([]) List<String> tags,
    double? averageRating,
    @Default(0) int reviewCount,
    Duration? estimatedDuration,
    DateTime? createdAt,
  }) = _ServiceModel;

  factory ServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceModelFromJson(json);
}
