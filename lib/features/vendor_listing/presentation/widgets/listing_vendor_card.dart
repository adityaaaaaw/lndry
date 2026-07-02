import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../models/models.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class ListingVendorCard extends StatelessWidget {
  const ListingVendorCard({
    super.key,
    required this.vendor,
    required this.onTap,
  });

  final VendorModel vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = vendor.distanceKm == null
        ? 'Nearby'
        : '${vendor.distanceKm!.toStringAsFixed(1)} km';

    return AppCard.elevated(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Open/Closed Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card.r),
                ),
                child: Container(
                  height: 130.h,
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.tag.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.done, color: AppColors.white, size: 10.r),
                        const Gap(4),
                        Text('VERIFIED',
                            style: AppTypography.badge
                                .copyWith(color: AppColors.white)),
                      ],
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
                          'CLOSED NOW',
                          style: AppTypography.badge,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Content details
          Padding(
            padding: EdgeInsets.all(AppSpacing.md.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Rating
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
                const Gap(8),

                // Distance, Price & Turnaround Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoBadge(
                      icon: AppIcons.location,
                      label: distanceLabel,
                      tooltip: 'Distance',
                    ),
                    _InfoBadge(
                      icon: AppIcons.upi,
                      label: 'Starts ${vendor.minOrderAmount.toCurrency}',
                      tooltip: 'Starting Price',
                    ),
                    _InfoBadge(
                      icon: AppIcons.timer,
                      label: '${vendor.estimatedTurnaroundHours} hrs',
                      tooltip: 'Delivery Time',
                    ),
                  ],
                ),
                const Gap(12),
                const AppDivider(),
                const Gap(12),

                // Pickup & Delivery availability
                Row(
                  children: [
                    _AvailabilityChip(
                      label: 'Pickup',
                      isAvailable: vendor.isOpen,
                    ),
                    const Gap(8),
                    _AvailabilityChip(
                      label: 'Delivery',
                      isAvailable: vendor.isOpen,
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge(
      {required this.icon, required this.label, required this.tooltip});
  final IconData icon;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14.r, color: AppColors.onSurfaceVariant),
        const Gap(4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: context.theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.label, required this.isAvailable});
  final String label;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.chip.r),
        border: Border.all(
          color: isAvailable
              ? AppColors.success.withOpacity(0.3)
              : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? AppIcons.success : AppIcons.close,
            size: 12.r,
            color: isAvailable ? AppColors.success : AppColors.onSurfaceVariant,
          ),
          const Gap(4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color:
                  isAvailable ? AppColors.success : AppColors.onSurfaceVariant,
              fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
