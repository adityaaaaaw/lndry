import '../../core/design/design_system.dart';

/// A reusable section header with optional "See All" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal divider with optional label
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.label, this.padding});

  final String? label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Divider(
        color: AppColors.outlineVariant,
        thickness: 1,
        height: 1,
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.outlineVariant)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              label!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.outlineVariant)),
        ],
      ),
    );
  }
}

/// Status badge chip (e.g., for order status).
/// Set [large] = true for full-width prominent status display.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.large = false,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: large
          ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h)
          : EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: large ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Text(
        label,
        style: (large ? AppTypography.labelLarge : AppTypography.badge)
            .copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// A rating row with star icon
class RatingRow extends StatelessWidget {
  const RatingRow({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize,
    this.style,
  });

  final double rating;
  final int? reviewCount;
  final double? starSize;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.tertiary, size: starSize ?? 16.r),
        SizedBox(width: 3.w),
        Text(
          rating.toStringAsFixed(1),
          style: style ?? AppTypography.labelMedium,
        ),
        if (reviewCount != null) ...[
          SizedBox(width: 3.w),
          Text(
            '($reviewCount)',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Price summary card showing subtotal, platform fee, GST and total.
/// Used on the cart, checkout, and order detail screens.
class PriceCard extends StatelessWidget {
  const PriceCard({
    super.key,
    required this.subtotal,
    required this.platformFee,
    required this.gstAmount,
    required this.total,
    this.padding,
  });

  final double subtotal;
  final double platformFee;
  final double gstAmount;
  final double total;
  final EdgeInsetsGeometry? padding;

  String _fmt(double v) => '₹${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Details', style: AppTypography.titleSmall),
          Gap(AppSpacing.sm.h),
          _PriceRow(label: 'Subtotal', value: _fmt(subtotal)),
          Gap(AppSpacing.xs.h),
          _PriceRow(label: 'Platform Fee', value: _fmt(platformFee)),
          Gap(AppSpacing.xs.h),
          _PriceRow(label: 'GST', value: _fmt(gstAmount)),
          Gap(AppSpacing.sm.h),
          Divider(color: AppColors.outlineVariant, thickness: 1, height: 1),
          Gap(AppSpacing.sm.h),
          _PriceRow(
            label: 'Total',
            value: _fmt(total),
            labelStyle: AppTypography.titleSmall,
            valueStyle: AppTypography.titleSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal helper row used by [PriceCard].
class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle ?? defaultStyle),
        Text(value, style: valueStyle ?? defaultStyle),
      ],
    );
  }
}
