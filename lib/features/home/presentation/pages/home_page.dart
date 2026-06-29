import 'dart:async';
import 'package:flutter/services.dart';
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

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedCategoryIdx = 0;
  int _carouselIdx = 0;
  String _bookService = 'Wash & Fold';
  String _bookPickupSlot = 'Today, 6–8 PM';
  String _bookAddress = 'Koramangala, BLR';

  static const _bookServiceOptions = [
    'Wash & Fold',
    'Iron Only',
    'Wash & Iron',
    'Dry Clean',
  ];

  static const _bookPickupSlots = [
    'Today, 6–8 PM',
    'Today, 2–4 PM',
    'Tomorrow, 10–12 AM',
    'Tomorrow, 6–8 PM',
  ];

  void _showBookOptionSheet({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    AppBottomSheet.show(
      context: context,
      title: title,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: options.length,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (context, idx) {
          final option = options[idx];
          final isSelected = option == current;
          return AppCard.outlined(
            borderColor: isSelected ? AppColors.primary : AppColors.outline,
            backgroundColor: isSelected ? AppColors.primaryContainer : AppColors.transparent,
            onTap: () {
              onSelected(option);
              Navigator.of(context).pop();
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(AppIcons.success, color: AppColors.primary, size: 18.r),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _schedulePickup() async {
    final cartState = ref.read(cartStateProvider);
    if (cartState.cart.isEmpty) {
      await ref.read(customerRepositoryProvider).addToCart(
            serviceId: 'svc_001',
            quantity: 2,
          );
      await ref.read(cartStateProvider.notifier).init();
    }
    if (mounted) {
      context.push(AppRoutes.checkout);
    }
  }

  int _activeOrderStep(OrderStatus status) {
    if (status.index >= OrderStatus.outForDelivery.index) return 3;
    if (status.index >= OrderStatus.ready.index) return 2;
    if (status.index >= OrderStatus.processing.index) return 1;
    return 0;
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
                                  Text(
                                    'Home',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textBlack,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '  •  Koramangala, Bengaluru',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                            onPressed: () => context.go(AppRoutes.notifications),
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
                      // User profile photo avatar (aarav)
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.profile),
                        child: CircleAvatar(
                          radius: 20.r,
                          backgroundImage: const NetworkImage(
                            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=100&q=80',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 2. Greeting Header ────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, Aarav',
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
                  ),
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

                // ── 4. Hero Carousel Promo Card (Matches Image 1 layout) ──────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: const _PromotionalBanner(),
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
                          context.go(AppRoutes.vendorListing);
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

                // ── 6. "Book in under a minute" widget (Pixel Perfect layout) ──
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: AppCard.outlined(
                    padding: EdgeInsets.all(16.r),
                    borderRadius: AppRadius.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Book in under a minute',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const Gap(16),
                        Row(
                          children: [
                            // Column 1: Service
                            Expanded(
                              child: _BookDropdownField(
                                icon: AppIcons.laundry,
                                title: 'Service',
                                value: _bookService,
                                onTap: () => _showBookOptionSheet(
                                  title: 'Select service',
                                  options: _bookServiceOptions,
                                  current: _bookService,
                                  onSelected: (value) => setState(() => _bookService = value),
                                ),
                              ),
                            ),
                            Container(width: 1.w, height: 40.h, color: AppColors.outline.withOpacity(0.6)),
                            // Column 2: Pickup time
                            Expanded(
                              child: _BookDropdownField(
                                icon: AppIcons.clock,
                                title: 'Pickup time',
                                value: _bookPickupSlot,
                                onTap: () => _showBookOptionSheet(
                                  title: 'Select pickup time',
                                  options: _bookPickupSlots,
                                  current: _bookPickupSlot,
                                  onSelected: (value) => setState(() => _bookPickupSlot = value),
                                ),
                              ),
                            ),
                            Container(width: 1.w, height: 40.h, color: AppColors.outline.withOpacity(0.6)),
                            // Column 3: Address
                            Expanded(
                              child: _BookDropdownField(
                                icon: AppIcons.location,
                                title: 'Address',
                                value: _bookAddress,
                                onTap: () => context.push(AppRoutes.mapAddress),
                              ),
                            ),
                          ],
                        ),
                        const Gap(16),
                        AppButton(
                          label: 'Schedule pickup',
                          onPressed: _schedulePickup,
                        ),
                      ],
                    ),
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
                                onTap: () => context.go('/orders/details/${order.id}'),
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
                            onTap: () => context.go('/vendor/${vendor.id}'),
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
                const Gap(24),

                // ── 9. Special Offers Section ──────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    'Special offers',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                ),
                const Gap(12),
                SizedBox(
                  height: 90.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    children: [
                      _PromoCouponCard(
                        title: 'Free ironing',
                        subtitle: 'over ₹499',
                        code: 'IRONFREE',
                        icon: AppIcons.iron,
                        color: const Color(0xFFFDF8F0),
                        borderColor: const Color(0xFFFBD38D),
                        onTap: () {
                          Clipboard.setData(const ClipboardData(text: 'IRONFREE'));
                          AppSnackBar.showSuccess(context, 'Promo code IRONFREE copied!');
                        },
                      ),
                      const Gap(12),
                      _PromoCouponCard(
                        title: '20% off',
                        subtitle: 'your first dry clean',
                        code: 'DRYCLEAN20',
                        icon: AppIcons.dry,
                        color: const Color(0xFFEDF2F7),
                        borderColor: const Color(0xFFCBD5E0),
                        onTap: () {
                          Clipboard.setData(const ClipboardData(text: 'DRYCLEAN20'));
                          AppSnackBar.showSuccess(context, 'Promo code DRYCLEAN20 copied!');
                        },
                      ),
                    ],
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

// ── Dropdown Item layout widget for booking ──────────────────────────────────

class _BookDropdownField extends StatelessWidget {
  const _BookDropdownField({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.r, color: AppColors.primary),
              const Gap(4),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(AppIcons.chevronDown, size: 14.r, color: AppColors.textSecondary),
            ],
          ),
        ],
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
    // Mock values matching Luxe Fabric details
    final double mockDistance = ((vendor.id.hashCode.abs() % 20) + 5) / 10;

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
                      '${vendor.averageRating ?? 4.5}  •  ${mockDistance.toStringAsFixed(1)} km',
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
                // Service Tags Row
                Row(
                  children: [
                    _buildTagChip('Wash & Fold'),
                    const Gap(4),
                    _buildTagChip('Dry Clean'),
                    const Gap(4),
                    _buildTagChip('+3'),
                  ],
                ),
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

  Widget _buildTagChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColors.outline.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 8.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Promo coupon row ─────────────────────────────────────────────────────────

class _PromoCouponCard extends StatelessWidget {
  const _PromoCouponCard({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.icon,
    required this.color,
    required this.borderColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String code;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 210.w,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.card.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 30.r),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(fontSize: 10.sp, color: AppColors.textSecondary),
                ),
                const Gap(4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.outline, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Use code: $code',
                    style: AppTypography.caption.copyWith(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(AppIcons.forward, color: AppColors.textSecondary, size: 14.r),
        ],
      ),
    ),
    );
  }
}

// ── Reusable, Overflow-Free Promotional Banner Widget ────────────────────────

class _PromotionalBanner extends StatefulWidget {
  const _PromotionalBanner();

  @override
  State<_PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends State<_PromotionalBanner> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'First pickup is on us',
      'subtitle': 'Book your first order today',
      'button': 'Book now',
      'image': 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?fit=crop&w=200&q=80',
    },
    {
      'title': 'Flat 20% off on Luxe',
      'subtitle': 'Premium fabric care experience',
      'button': 'Claim offer',
      'image': 'https://images.unsplash.com/photo-1545180856-f6d2e61df3fa?fit=crop&w=200&q=80',
    },
    {
      'title': 'Get express delivery',
      'subtitle': 'Clean clothes in just 24 hours',
      'button': 'Explore',
      'image': 'https://images.unsplash.com/photo-1489274495757-95c7c837b101?fit=crop&w=200&q=80',
    },
  ];

  // Starting page in the middle of a large range for infinite loop
  late final int _initialPage;

  @override
  void initState() {
    super.initState();
    _initialPage = _slides.length * 100;
    _currentPage = _initialPage;
    _pageController = PageController(initialPage: _initialPage);

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
              _resetTimer();
            },
            itemBuilder: (context, index) {
              final slideIdx = index % _slides.length;
              final slide = _slides[slideIdx];

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEEECFF), Color(0xFFF5F3FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: AppElevation.low,
                      borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Text Contents
                        Expanded(
                          flex: 13,
                          child: Padding(
                            padding: EdgeInsets.all(16.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slide['title'] as String,
                                  style: AppTypography.titleLarge.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(4),
                                Text(
                                  slide['subtitle'] as String,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primaryDark.withOpacity(0.8),
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(12),
                                ElevatedButton(
                                  onPressed: () {
                                    final navShell = StatefulNavigationShell.of(context);
                                    navShell.goBranch(2); // Cart/Book
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.full.r),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    slide['button'] as String,
                                    style: AppTypography.buttonText.copyWith(fontSize: 12.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Right Illustration Image
                        Expanded(
                          flex: 9,
                          child: Padding(
                            padding: EdgeInsets.only(right: 16.w, top: 12.h, bottom: 12.h),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: 110.h,
                                  maxWidth: 120.w,
                                ),
                                child: Image.network(
                                  slide['image'] as String,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    AppIcons.laundry,
                                    size: 80.r,
                                    color: AppColors.primary.withOpacity(0.15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Gap(10),
        // Synchronized center indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (idx) {
            final activeIdx = _currentPage % _slides.length;
            final isActive = idx == activeIdx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: isActive ? 12.w : 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.outline.withOpacity(0.6),
                borderRadius: BorderRadius.circular(3.r),
              ),
            );
          }),
        ),
      ],
    );
  }
}
