import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/asset_constants.dart';
import '../../core/design/design_system.dart';
import '../../models/models.dart';

class BrandedServiceIcon extends StatelessWidget {
  const BrandedServiceIcon({
    super.key,
    this.iconKey,
    this.category,
    this.size,
    this.iconSize,
    this.backgroundColor,
  });

  final String? iconKey;
  final ServiceCategory? category;
  final double? size;
  final double? iconSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final asset = _assetFor(iconKey, category);
    final boxSize = size ?? 44.r;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
      ),
      child: Center(
        child: asset == null
            ? Icon(
                AppIcons.tag,
                size: iconSize ?? 22.r,
                color: AppColors.primary,
              )
            : SvgPicture.asset(
                asset,
                width: iconSize ?? 24.r,
                height: iconSize ?? 24.r,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  static String? _assetFor(String? iconKey, ServiceCategory? category) {
    final normalized = iconKey?.toLowerCase().replaceAll('_', '-').trim();
    return switch (normalized) {
      'washer' ||
      'wash' ||
      'wash-fold' ||
      'laundry' =>
        AssetConstants.serviceWashFold,
      'iron' || 'wash-iron' => AssetConstants.serviceWashIron,
      'dry' ||
      'dry-clean' ||
      'dry-cleaning' =>
        AssetConstants.serviceDryCleaning,
      'steam' || 'steam-press' => AssetConstants.serviceSteamPress,
      'shoe' || 'shoe-care' => AssetConstants.serviceShoeCare,
      'premium' ||
      'premium-care' ||
      'premium-garment-care' =>
        AssetConstants.servicePremiumGarmentCare,
      'bag' || 'bag-care' => AssetConstants.serviceBagCare,
      'tailoring' => AssetConstants.serviceTailoring,
      'curtain' || 'curtain-cleaning' => AssetConstants.serviceCurtainCleaning,
      'carpet' || 'carpet-cleaning' => AssetConstants.serviceCarpetCleaning,
      'blanket' || 'blanket-cleaning' => AssetConstants.serviceBlanketCleaning,
      _ => switch (category) {
          ServiceCategory.wash => AssetConstants.serviceWashFold,
          ServiceCategory.iron => AssetConstants.serviceWashIron,
          ServiceCategory.washAndIron => AssetConstants.serviceWashIron,
          ServiceCategory.dryClean => AssetConstants.serviceDryCleaning,
          ServiceCategory.fold => AssetConstants.serviceWashFold,
          ServiceCategory.premium => AssetConstants.servicePremiumGarmentCare,
          null => null,
        },
    };
  }
}
