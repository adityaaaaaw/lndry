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

  String get id => switch (this) {
        ServiceCategory.wash => '11111111-1111-4444-a111-111111111111',
        ServiceCategory.iron => '439a1fe9-3531-4fe8-99ae-31eb2d3bb9a0',
        ServiceCategory.washAndIron => '129cacdf-b122-4968-bcb0-ac6e1f877126',
        ServiceCategory.dryClean => '4ce25f94-da85-4602-8561-afefb69c9d6f',
        ServiceCategory.fold => 'b590620e-cc79-4a58-bb90-9596519f372d',
        ServiceCategory.premium => '22222222-2222-4444-a222-222222222222',
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
    @JsonKey(name: 'category_id') String? categoryId,
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
