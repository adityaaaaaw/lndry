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

/// Status badge chip (e.g., for order status)
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(color: color),
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
