import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/domain_cards.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../providers/home_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../providers/providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedCategoryIdx = 0;
  int _carouselIdx = 0;

  int _activeOrderStep(OrderStatus status) {
    // Map canonical statuses to 4-step visual tracker index.
    return switch (status) {
      OrderStatus.waitingForVendorConfirmation ||
      OrderStatus.vendorAccepted ||
      OrderStatus.pickupAssigned ||
      OrderStatus.goingForPickup =>
        0,
      OrderStatus.pickupOtpVerified ||
      OrderStatus.pickedUp ||
      OrderStatus.receivedAtVendor ||
      OrderStatus.processing =>
        1,
      OrderStatus.packed => 2,
      OrderStatus.deliveryAssigned ||
      OrderStatus.outForDelivery ||
      OrderStatus.deliveryOtpVerified ||
      OrderStatus.delivered =>
        3,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final addressAsync = ref.watch(currentAddressProvider);
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final vendorsAsync = ref.watch(homeVendorsProvider);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(currentAddressProvider);
            ref.invalidate(homeCategoriesProvider);
            ref.invalidate(homeVendorsProvider);
            ref.invalidate(activeOrdersProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Bar: Title & Address Selector (Pixel Perfect) ─────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lndry',
                              style: AppTypography.displayMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(4),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.mapAddress),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppIcons.location,
                                    color: AppColors.primary,
                                    size: 16.r,
                                  ),
                                  const Gap(4),
                                  addressAsync.when(
                                    data: (addr) => Flexible(
                                      child: Text(
                                        addr != null
                                            ? '${addr.type.label}  •  ${addr.city}'
                                            : 'Select address',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    loading: () => Container(
                                      width: 120.w,
                                      height: 12.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.shimmerBase,
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                    ),
                                    error: (_, __) => Text(
                                      'Select address',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Gap(2),
                                  Icon(
                                    AppIcons.chevronDown,
                                    color: AppColors.textSecondary,
                                    size: 16.r,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification badge click
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              AppIcons.notificationsOutlined,
                              color: AppColors.textBlack,
                              size: 26.r,
                            ),
                            onPressed: () => context.push(AppRoutes.notifications),
                          ),
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: Container(
                              width: 8.r,
                              height: 8.r,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      // Avatar: initials or user photo
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.profile),
                        child: Builder(builder: (context) {
                          final user = ref.watch(currentUserProvider);
                          final avatarUrl = user?.avatarUrl;
                          final initials = (user?.name ?? '')
                              .trim()
                              .split(' ')
                              .where((p) => p.isNotEmpty)
                              .take(2)
                              .map((p) => p[0].toUpperCase())
                              .join();
                          return CircleAvatar(
                            radius: 20.r,
                            backgroundColor: AppColors.primaryContainer,
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(
                                    initials.isNotEmpty ? initials : '?',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                // ── 2. Greeting Header ────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Builder(builder: (context) {
                    final user = ref.watch(currentUserProvider);
                    final firstName = (user?.name ?? '').trim().split(' ').first;
                    final displayName = firstName.isNotEmpty ? firstName : 'there';
                    final hour = DateTime.now().hour;
                    final greeting = hour < 12
                        ? 'Good morning'
                        : hour < 17
                            ? 'Good afternoon'
                            : 'Good evening';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $displayName',
                          style: AppTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'What would you like us to care for today?',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const Gap(20),

                // ── 3. Search Bar with Filter Icon ───────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final navShell = StatefulNavigationShell.of(context);
                            navShell.goBranch(1);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.full.r),
                              border: Border.all(color: AppColors.outline.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(AppIcons.search, color: AppColors.textSecondary, size: 20.r),
                                const Gap(10),
                                Expanded(
                                  child: Text(
                                    'Search services or nearby laundries',
                                    style: AppTypography.inputHint.copyWith(fontSize: 14.sp),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Gap(12),
                      GestureDetector(
                        onTap: () {
                          // Switch to Search tab branch
                          final navShell = StatefulNavigationShell.of(context);
                          navShell.goBranch(1);
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.filter,
                            color: AppColors.primary,
                            size: 22.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // ── 5. Category Scroll Row ("What do you need?") ──────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'What do you need?',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go(AppRoutes.search);
                        },
                        child: Text(
                          'View all',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                SizedBox(
                  height: 124.h,
                  child: categoriesAsync.when(
                    data: (cats) => ListView.separated(
                      padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 10.h, bottom: 4.h),
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (context, idx) {
                        final cat = cats[idx];
                        final isSelected = _selectedCategoryIdx == idx;
                        return CategoryCard(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedCategoryIdx = idx);
                            context.go('/category/${cat.id}');
                          },
                        );
                      },
                    ),
                    loading: () => ListView.separated(
                      padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 10.h, bottom: 4.h),
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (_, __) => const AppSkeletonCard(width: 90, height: 100),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const Gap(24),

                // ── 7. Active Order Status Tracker (Image 1 checklist steps) ──
                activeOrdersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) return const SizedBox.shrink();
                    final order = orders.first;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Active order',
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBlack,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/orders/details/${order.id}'),
                                child: Text(
                                  'Track',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),
                          _ActiveOrderTrackerCard(
                            order: order,
                            currentStep: _activeOrderStep(order.status),
                          ),
                          const Gap(24),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // ── 8. "Recommended near you" Section ──────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recommended near you',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                SizedBox(
                  height: 270.h,
                  child: vendorsAsync.when(
                    data: (vendors) => ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: vendors.length,
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (context, idx) {
                        final vendor = vendors[idx];
                        return SizedBox(
                          width: 300.w,
                          child: _HorizontalVendorCard(
                            vendor: vendor,
                            onTap: () => context.push('/vendor/${vendor.id}'),
                          ),
                        );
                      },
                    ),
                    loading: () => ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: 2,
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (_, __) => const AppSkeletonCard(width: 300, height: 260),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const Gap(32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Active Order checklist status tracker card ───────────────────────────────

class _ActiveOrderTrackerCard extends StatelessWidget {
  const _ActiveOrderTrackerCard({required this.order, required this.currentStep});
  final OrderModel order;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        boxShadow: AppElevation.low,
      ),
      child: Stack(
        children: [
          // Left accent bar (teal)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5.w,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card.r),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #LN${(order.id.length >= 4 ? order.id.substring(order.id.length - 4) : order.id).toUpperCase()}',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/orders/details/${order.id}'),
                      child: Text(
                        'Track',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.laundry,
                        color: AppColors.secondary,
                        size: 20.r,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your clothes are being cleaned',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                          Text(
                            '${order.items.length} items  •  ${order.items.isNotEmpty ? order.items.first.serviceName : 'Laundry'}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            order.estimatedDeliveryAt?.toDayDate ?? 'Delivery estimate pending',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                const AppDivider(),
                const Gap(16),

                // Timeline tracker row (Picked up -> Cleaning -> Quality check -> Out for delivery)
                _ActiveOrderTimelineRow(currentStep: currentStep),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderTimelineRow extends StatelessWidget {
  const _ActiveOrderTimelineRow({required this.currentStep});
  final int currentStep; // 0: Picked up, 1: Cleaning, 2: Quality check, 3: Out for delivery

  @override
  Widget build(BuildContext context) {
    final List<String> steps = const [
      'Picked up',
      'Cleaning',
      'Quality check',
      'Out for delivery',
    ];

    return Row(
      children: List.generate(
        steps.length,
        (index) {
          final isCompleted = index <= currentStep;
          final isCurrent = index == currentStep;
          final showLine = index < steps.length - 1;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // Dot
                    Container(
                      width: 14.r,
                      height: 14.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? AppColors.secondary : AppColors.outline.withOpacity(0.6),
                      ),
                      child: isCompleted && index == 0
                          ? Center(
                              child: Icon(
                                AppIcons.done,
                                color: AppColors.white,
                                size: 8.r,
                              ),
                            )
                          : null,
                    ),
                    if (showLine)
                      Expanded(
                        child: Container(
                          height: 2.h,
                          color: isCompleted ? AppColors.secondary : AppColors.outline.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
                const Gap(6),
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Text(
                    steps[index],
                    style: AppTypography.caption.copyWith(
                      fontSize: 8.sp,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? AppColors.secondary : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Horizontal vendor card Recommended (Matches Luxe Fabric storefront style) ─

class _HorizontalVendorCard extends StatelessWidget {
  const _HorizontalVendorCard({required this.vendor, required this.onTap});
  final VendorModel vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Use distance from backend, or fallback for mock mode
    final double displayDistance = vendor.distanceKm ?? ((vendor.id.hashCode.abs() % 20) + 5) / 10;

    return AppCard.outlined(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store front cover
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.card.r),
            ),
            child: Container(
              height: 110.h,
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
                        )
                      : Container(
                          color: AppColors.primaryContainer,
                          child: Icon(AppIcons.store, size: 36.r, color: AppColors.primary),
                        ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor Name
                Text(
                  vendor.name,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                // Rating & Distance Row
                Row(
                  children: [
                    Icon(AppIcons.star, color: Colors.amber, size: 12.r),
                    const Gap(2),
                    Text(
                      '${vendor.averageRating ?? 4.5}  •  ${displayDistance.toStringAsFixed(1)} km',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                // Price & Pickup
                Row(
                  children: [
                    Text(
                      'From ${vendor.minOrderAmount.toCurrency}/kg',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.sp,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      '•',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 8.sp),
                    ),
                    const Gap(6),
                    Text(
                      'Pickup in 30 min',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                const Gap(10),
                // Divider
                Container(height: 1.h, color: AppColors.outline.withOpacity(0.5)),
                const Gap(8),
                // Bottom row: Verified badge & Action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (vendor.isVerified)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.success,
                            color: AppColors.secondary,
                            size: 14.r,
                          ),
                          const Gap(4),
                          Text(
                            'Verified',
                            style: AppTypography.badge.copyWith(
                              color: AppColors.secondary,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.forward,
                        color: AppColors.white,
                        size: 10.r,
                      ),
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

}

