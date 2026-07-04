import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/extensions/extensions.dart';
import '../../models/models.dart';
import 'service_icon.dart';
import 'shared_widgets.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CATEGORY CARD
// ═════════════════════════════════════════════════════════════════════════════

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.isSelected = false,
  });

  final CategoryModel category;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // Map custom ETAs for mock display matching Image 1
    final String eta = switch (category.id) {
      'cat_wash' || 'wash_fold' || 'cat_001' => '24–36 hrs',
      'cat_iron' || 'wash_iron' || 'cat_002' => '24 hrs',
      'cat_wash_iron' => '24 hrs',
      'cat_dry_clean' || 'dry_cleaning' || 'cat_003' => '24–48 hrs',
      'cat_shoe' || 'shoe_care' || 'cat_004' => '48 hrs',
      'cat_premium' || 'premium_care' || 'cat_005' => '48–72 hrs',
      _ => '24 hrs',
    };

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 90.w,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.compactCard.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outline.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? AppElevation.low : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon in circle background
                BrandedServiceIcon(
                  iconKey: category.icon,
                  size: 44.r,
                  iconSize: 24.r,
                  backgroundColor: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.background,
                ),
                const Gap(8),
                Text(
                  category.name,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textBlack,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  eta,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: -6.h,
              right: -6.w,
              child: Container(
                padding: EdgeInsets.all(2.r),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.done,
                  color: AppColors.white,
                  size: 10.r,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VENDOR CARD
// ═════════════════════════════════════════════════════════════════════════════

class VendorCard extends StatelessWidget {
  const VendorCard({
    super.key,
    required this.vendor,
    required this.onTap,
  });

  final VendorModel vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Verification Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card.r),
                ),
                child: Container(
                  height: 140.h,
                  width: double.infinity,
                  color: AppColors.shimmerBase,
                  child: Hero(
                    tag: 'vendor-cover-${vendor.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: vendor.coverImageUrl.isNotNullOrBlank
                          ? CachedNetworkImage(
                              imageUrl: vendor.coverImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (_, __, ___) =>
                                  _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),
                ),
              ),
              if (vendor.isVerified)
                Positioned(
                  top: AppSpacing.sm.h,
                  right: AppSpacing.sm.w,
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.xs.r * 1.5),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.done,
                      color: AppColors.white,
                      size: 14.r,
                    ),
                  ),
                ),
              if (!vendor.isOpen)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card.r),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md.w,
                          vertical: AppSpacing.xs.h * 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppRadius.tag.r),
                        ),
                        child: Text(
                          'CLOSED',
                          style: AppTypography.badge,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Content Details
          Padding(
            padding: EdgeInsets.all(AppSpacing.md.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        vendor.name,
                        style: AppTypography.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vendor.averageRating != null) ...[
                      const Gap(4),
                      RatingRow(
                        rating: vendor.averageRating!,
                        reviewCount: vendor.reviewCount,
                      ),
                    ],
                  ],
                ),
                const Gap(4),
                Text(
                  vendor.description,
                  style: AppTypography.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(12),
                const AppDivider(),
                const Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IconText(
                      icon: AppIcons.clock,
                      label: '${vendor.estimatedTurnaroundHours} hrs delivery',
                    ),
                    _IconText(
                      icon: AppIcons.location,
                      label:
                          '${vendor.deliveryRadiusKm.toStringAsFixed(0)} km delivery radius',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.primaryContainer.withOpacity(0.5),
      child: Center(
        child: Icon(
          AppIcons.store,
          size: 48.r,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14.r, color: AppColors.onSurfaceVariant),
        const Gap(4),
        Text(
          label,
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SERVICE CARD
// ═════════════════════════════════════════════════════════════════════════════

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    this.quantity = 0,
    this.onAdd,
    this.onRemove,
  });

  final ServiceModel service;
  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    // Map exact pricing labels from screenshot
    final String priceLabel = switch (service.id) {
      'wash_fold' || 'svc_001' => '₹99/kg',
      'wash_iron' || 'svc_002' => '₹129/kg',
      'dry_cleaning' || 'svc_003' => 'From ₹79/item',
      'steam_press' || 'svc_004' => '₹25/item',
      'shoe_care' || 'svc_005' => 'From ₹299/pair',
      'premium_care' || 'svc_006' => 'From ₹199/item',
      _ => service.pricePerKg != null
          ? '${service.pricePerKg!.toCurrency}/kg'
          : '${(service.pricePerPiece ?? 0).toCurrency}/item',
    };

    // Map exact sub-details from screenshot
    final String subDetails = switch (service.id) {
      'wash_fold' || 'svc_001' => '48-hour delivery  •  Min. 3 kg',
      'wash_iron' || 'svc_002' => '48-hour delivery',
      'dry_cleaning' || 'svc_003' => '48-hour delivery  •  Min. 3 kg',
      'steam_press' || 'svc_004' => '48-hour delivery',
      'shoe_care' || 'svc_005' => '48-hour delivery',
      'premium_care' || 'svc_006' => '48-hour delivery',
      _ => '48-hour delivery',
    };

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.compactCard.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.04),
            blurRadius: 16.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service icon indicator (light violet circular/rounded background)
          BrandedServiceIcon(
            category: service.category,
            iconKey: service.tags.isNotEmpty ? service.tags.first : null,
            size: 48.r,
            iconSize: 26.r,
            backgroundColor: AppColors.primaryContainer.withOpacity(0.4),
          ),
          const Gap(12),

          // Details content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  service.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                // Clock-icon subtext row
                Row(
                  children: [
                    Icon(
                      AppIcons.clock,
                      size: 10.r,
                      color: AppColors.onSurfaceVariant.withOpacity(0.7),
                    ),
                    const Gap(4),
                    Expanded(
                      child: Text(
                        subDetails,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(8),

          // Pricing & Stepper column on the right
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(12),
              if (service.isAvailable) ...[
                if (quantity > 0) ...[
                  // Dynamic quantity layout matching UI Kit
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StepButton(
                        icon: AppIcons.remove,
                        onPressed: onRemove,
                      ),
                      const Gap(8),
                      Text(
                        '$quantity${service.pricePerKg != null ? ' kg' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const Gap(8),
                      _StepButton(
                        icon: AppIcons.add,
                        onPressed: onAdd,
                      ),
                    ],
                  ),
                ] else ...[
                  // Outline action buttons matching UI Kit
                  OutlinedButton(
                    onPressed: onAdd,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tag.r),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      minimumSize: Size(72.w, 28.h),
                    ),
                    child: Text(
                      service.id == 'dry_cleaning' || service.id == 'svc_003'
                          ? 'Choose garments'
                          : 'Add',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ] else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.tag.r),
                  ),
                  child: Text(
                    'UNAVAILABLE',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.sm.r),
      child: Container(
        width: 28.r,
        height: 28.r,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm.r),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 14.r,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRICE BREAKDOWN CARD
// ═════════════════════════════════════════════════════════════════════════════

class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({
    super.key,
    required this.subtotal,
    required this.platformFee,
    required this.gstAmount,
    required this.total,
    this.discountAmount,
    this.promoCode,
  });

  final double subtotal;
  final double platformFee;
  final double gstAmount;
  final double total;
  final double? discountAmount;
  final String? promoCode;

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      backgroundColor: context.theme.colorScheme.surfaceContainerLow,
      padding: EdgeInsets.all(AppSpacing.md.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Summary',
            style: AppTypography.titleSmall,
          ),
          const Gap(12),
          _PriceRow(
            label: 'Item Subtotal',
            value: subtotal.toCurrencyDecimal,
          ),
          if (discountAmount != null && discountAmount! > 0) ...[
            const Gap(8),
            _PriceRow(
              label: 'Discount ${promoCode != null ? "($promoCode)" : ""}',
              value: '-${discountAmount!.toCurrencyDecimal}',
              valueColor: AppColors.success,
            ),
          ],
          const Gap(8),
          _PriceRow(
            label: 'Platform Handling Fee',
            value: platformFee.toCurrencyDecimal,
          ),
          const Gap(8),
          _PriceRow(
            label: 'GST & Taxes',
            value: gstAmount.toCurrencyDecimal,
          ),
          const Gap(12),
          const AppDivider(),
          const Gap(12),
          _PriceRow(
            label: 'Grand Total',
            value: total.toCurrencyDecimal,
            isBold: true,
            style: AppTypography.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
    this.style,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? AppTypography.bodyMedium;
    final finalStyle =
        isBold ? baseStyle.copyWith(fontWeight: FontWeight.w700) : baseStyle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: finalStyle.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Text(
          value,
          style: finalStyle.copyWith(
            color: valueColor ?? context.theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
