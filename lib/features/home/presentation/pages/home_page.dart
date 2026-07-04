import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/auth/auth_gate.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';
import '../../../../providers/providers.dart';
import '../../../../shared/widgets/domain_cards.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../providers/home_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Issue 2: No category selected initially
  int _selectedCategoryIdx = -1;

  int _activeOrderStep(OrderStatus status) {
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
                // ── 1. Top Header: Logo, Location, Notification & Avatar ─────
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
                              onTap: () => requireAuthenticated(
                                context: context,
                                ref: ref,
                                returnTo: AppRoutes.mapAddress,
                                action: (context, _) =>
                                    context.push(AppRoutes.mapAddress),
                              ),
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
                                            ? '${addr.type.label} · ${addr.line2 != null && addr.line2!.isNotEmpty ? '${addr.line2}, ' : ''}${addr.city}'
                                            : 'Select address',
                                        style: AppTypography.labelMedium
                                            .copyWith(
                                          color: AppColors.textBlack,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    loading: () => Container(
                                      width: 120.w,
                                      height: 14.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.shimmerBase,
                                        borderRadius:
                                            BorderRadius.circular(4.r),
                                      ),
                                    ),
                                    error: (_, __) => Text(
                                      'Select address',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.textBlack,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Gap(4),
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
                      // Notification badge
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              AppIcons.notificationsOutlined,
                              color: AppColors.textBlack,
                              size: 26.r,
                            ),
                            onPressed: () => requireAuthenticated(
                              context: context,
                              ref: ref,
                              returnTo: AppRoutes.notifications,
                              action: (context, _) =>
                                  context.push(AppRoutes.notifications),
                            ),
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
                      // Avatar
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
                            backgroundImage:
                                (avatarUrl != null && avatarUrl.isNotEmpty)
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
                    final firstName =
                        (user?.name ?? '').trim().split(' ').first;
                    final displayName =
                        firstName.isNotEmpty ? firstName : 'there';
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
                            fontWeight: FontWeight.w700,
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
                  child: GestureDetector(
                    onTap: () {
                      final navShell = StatefulNavigationShell.of(context);
                      navShell.goBranch(1);
                    },
                    child: Container(
                      height: 52.h,
                      padding: EdgeInsets.only(left: 16.w, right: 8.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.full.r),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.search,
                            color: AppColors.textBlack,
                            size: 20.r,
                          ),
                          const Gap(12),
                          Expanded(
                            child: Text(
                              'Search services or nearby laundries',
                              style: AppTypography.inputHint.copyWith(
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Container(
                            width: 36.r,
                            height: 36.r,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                AppIcons.filter,
                                color: AppColors.primary,
                                size: 18.r,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(20),

                // ── 4. Offer Banner Carousel (Issue 1) ────────────────────────
                const _OfferBannerCarousel(),
                const Gap(24),

                // ── 5. Category Scroll Row (Issue 2) ──────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'What do you need?',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.search),
                        child: Text(
                          'View all',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                SizedBox(
                  height: math.max(
                    132.h,
                    MediaQuery.textScalerOf(context).scale(132.h),
                  ),
                  child: categoriesAsync.when(
                    data: (cats) => ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 8.h,
                      ),
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (context, idx) {
                        final cat = cats[idx];
                        final isSelected = _selectedCategoryIdx == idx;
                        return AnimatedScale(
                          scale: isSelected ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: CategoryCard(
                            category: cat,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                // Toggle off if same category tapped
                                if (_selectedCategoryIdx == idx) {
                                  _selectedCategoryIdx = -1;
                                } else {
                                  _selectedCategoryIdx = idx;
                                  context.go('/category/${cat.id}');
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                    loading: () => ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 8.h,
                      ),
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (_, __) =>
                          const AppSkeletonCard(width: 90, height: 110),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const Gap(24),

                // ── 6. Quick Schedule Card (Issue 5) ─────────────────────────
                const _QuickScheduleCard(),
                const Gap(24),

                // ── 7. Active Order Status Tracker ────────────────────────────
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
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textBlack,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    context.push('/orders/details/${order.id}'),
                                child: Text(
                                  'Track',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
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

                // ── 8. "Recommended near you" Section (Issue 3) ───────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    'Recommended near you',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBlack,
                    ),
                  ),
                ),
                const Gap(12),
                vendorsAsync.when(
                  data: (vendors) {
                    if (vendors.isEmpty) {
                      // Case B: Empty state (Issue 3)
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: _buildEmptyVendorState(),
                      );
                    }
                    // Case A: Vendors available
                    return SizedBox(
                      height: 180.h,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        scrollDirection: Axis.horizontal,
                        itemCount: vendors.length,
                        separatorBuilder: (_, __) => const Gap(16),
                        itemBuilder: (context, idx) {
                          final vendor = vendors[idx];
                          return SizedBox(
                            width: 315.w,
                            child: _HorizontalVendorCard(
                              vendor: vendor,
                              onTap: () =>
                                  context.push('/vendor/${vendor.id}'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => SizedBox(
                    height: 180.h,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: 2,
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (_, __) =>
                          const AppSkeletonCard(width: 315, height: 180),
                    ),
                  ),
                  error: (_, __) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: AppEmptyState(
                      icon: AppIcons.store,
                      title: 'Couldn\'t load nearby partners',
                      subtitle:
                          'Check your connection and try again.',
                      actionLabel: 'Retry',
                      onAction: () =>
                          ref.invalidate(homeVendorsProvider),
                    ),
                  ),
                ),
                const Gap(24),

                // ── 9. "Special offers" Section (Issue 4) ─────────────────────
                const _SpecialOffersSection(),
                const Gap(32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Issue 3: Empty vendor state with Enable Location / Refresh
  Widget _buildEmptyVendorState() {
    return AppEmptyState(
      icon: AppIcons.store,
      title: 'No laundry partners available nearby',
      subtitle: 'Enable location to discover nearby laundry partners.',
      actionLabel: 'Enable Location',
      onAction: () {
        ref.invalidate(homeVendorsProvider);
        requireAuthenticated(
          context: context,
          ref: ref,
          returnTo: AppRoutes.locationPermission,
          action: (context, _) =>
              context.push(AppRoutes.locationPermission),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ISSUE 1: Offer Banner Carousel
// ═════════════════════════════════════════════════════════════════════════════

class _OfferBannerCarousel extends StatefulWidget {
  const _OfferBannerCarousel();

  @override
  State<_OfferBannerCarousel> createState() => _OfferBannerCarouselState();
}

class _OfferBannerCarouselState extends State<_OfferBannerCarousel> {
  late PageController _pageController;
  late Timer _autoScrollTimer;
  int _currentPage = 0;

  /// Static banners — can be swapped with backend-driven list later.
  /// If only one banner, auto-scroll is silently disabled.
  static const int _bannerCount = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    // Issue 1: Only auto-scroll if more than one banner
    if (_bannerCount <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _bannerCount;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 140.h,
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: const [
                _BannerPage(
                  title: 'First pickup is on us',
                  subtitle: 'Book your first order today',
                  cta: 'Book now',
                  gradientStart: AppColors.offerLavender,
                  gradientEnd: Color(0xFFCFC8FF),
                  imageAsset: AssetConstants.firstPickupBanner,
                ),
                _BannerPage(
                  title: '20% off dry cleaning',
                  subtitle: 'Use code DRYCLEAN20',
                  cta: 'Claim now',
                  gradientStart: AppColors.secondaryLight,
                  gradientEnd: AppColors.secondary,
                  // No image — text-only promotional layout
                ),
                _BannerPage(
                  title: 'Free ironing',
                  subtitle: 'on orders over ₹499',
                  cta: 'Book now',
                  gradientStart: AppColors.offerLavender,
                  gradientEnd: AppColors.primaryContainer,
                  // No image — text-only promotional layout
                ),
              ],
            ),
          ),
          const Gap(10),
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: index == _currentPage ? 18.w : 6.r,
                height: 6.r,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.full.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerPage extends StatelessWidget {
  const _BannerPage({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradientStart,
    required this.gradientEnd,
    this.imageAsset,
  });

  final String title;
  final String subtitle;
  final String cta;
  final Color gradientStart;
  final Color gradientEnd;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.search),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          boxShadow: AppElevation.low,
        ),
        child: Stack(
          children: [
            if (imageAsset != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 170.w,
                child: Image.asset(
                  imageAsset!,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                top: 18.h,
                bottom: 18.h,
                right: imageAsset != null ? 150.w : 20.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.button.r),
                    ),
                    child: Text(
                      cta,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Quick Book Card ("Book in under a minute")
// ═════════════════════════════════════════════════════════════════════════════

class _QuickScheduleCard extends StatelessWidget {
  const _QuickScheduleCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: AppElevation.low,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book in under a minute',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textBlack,
              ),
            ),
            const Gap(14),
            Row(
              children: [
                Expanded(
                  child: _QuickScheduleItem(
                    icon: AppIcons.laundry,
                    label: 'Service',
                    value: 'Wash & Fold',
                    onTap: () => context.go(AppRoutes.search),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32.h,
                  color: AppColors.outlineVariant,
                ),
                Expanded(
                  child: _QuickScheduleItem(
                    icon: AppIcons.timer,
                    label: 'Pickup time',
                    value: 'Today, 6–8 PM',
                    onTap: () => context.go(AppRoutes.search),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32.h,
                  color: AppColors.outlineVariant,
                ),
                Expanded(
                  child: _QuickScheduleItem(
                    icon: AppIcons.location,
                    label: 'Address',
                    value: 'Koramangala, BLR',
                    onTap: () => context.push(AppRoutes.mapAddress),
                  ),
                ),
              ],
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.search),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r),
                  ),
                ),
                child: Text(
                  'Schedule pickup',
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickScheduleItem extends StatelessWidget {
  const _QuickScheduleItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 14.r),
            ),
            const Gap(6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(1),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        AppIcons.chevronDown,
                        size: 12.r,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Active Order Tracker Card
// ═════════════════════════════════════════════════════════════════════════════

class _ActiveOrderTrackerCard extends StatelessWidget {
  const _ActiveOrderTrackerCard(
      {required this.order, required this.currentStep});
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
                    Flexible(
                      child: Text(
                        'Order #LN${(order.id.length >= 4 ? order.id.substring(order.id.length - 4) : order.id).toUpperCase()}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                      decoration: const BoxDecoration(
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
                            '${order.items.length} items · ${order.items.isNotEmpty ? order.items.first.serviceName : 'Laundry'}',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            order.estimatedDeliveryAt?.toDayDate ??
                                'Delivery estimate pending',
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
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const List<String> steps = [
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isCurrent ? 16.r : 14.r,
                      height: isCurrent ? 16.r : 14.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.secondary
                            : AppColors.outlineVariant,
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
                          color: isCompleted
                              ? AppColors.secondary
                              : AppColors.outlineVariant,
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
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted
                          ? AppColors.secondary
                          : AppColors.textMuted,
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

// ═════════════════════════════════════════════════════════════════════════════
// Horizontal Vendor Card ("Recommended near you")
// ═════════════════════════════════════════════════════════════════════════════

class _HorizontalVendorCard extends StatelessWidget {
  const _HorizontalVendorCard({required this.vendor, required this.onTap});
  final VendorModel vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double displayDistance =
        vendor.distanceKm ?? ((vendor.id.hashCode.abs() % 20) + 5) / 10;

    return AppCard.outlined(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(AppRadius.card.r),
            ),
            child: Container(
              width: 115.w,
              height: double.infinity,
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
                          child: Icon(
                            AppIcons.store,
                            size: 32.r,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      Row(
                        children: [
                          Icon(
                            AppIcons.star,
                            color: AppColors.rating,
                            size: 13.r,
                          ),
                          const Gap(4),
                          Expanded(
                            child: Text(
                              '${vendor.averageRating ?? 4.8} · ${displayDistance.toStringAsFixed(1)} km',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'From ${vendor.minOrderAmount.toCurrency}/kg',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Pickup in 30 min',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ServicePill(label: 'Wash & Fold'),
                        Gap(4),
                        _ServicePill(label: 'Dry Clean'),
                        Gap(4),
                        _ServicePill(label: '+3'),
                      ],
                    ),
                  ),
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
                              size: 13.r,
                            ),
                            const Gap(4),
                            Text(
                              'Verified',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.forward,
                          color: AppColors.primary,
                          size: 12.r,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicePill extends StatelessWidget {
  const _ServicePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 9.sp,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ISSUE 4: Special Offers Section (now tappable)
// ═════════════════════════════════════════════════════════════════════════════

class _SpecialOffersSection extends StatelessWidget {
  const _SpecialOffersSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'Special offers',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textBlack,
            ),
          ),
        ),
        const Gap(12),
        SizedBox(
          height: 100.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            clipBehavior: Clip.none,
            children: [
              _SpecialOfferCard(
                title: 'Free ironing',
                subtitle: 'over ₹499',
                code: 'IRONFREE',
                backgroundColor: AppColors.offerLavender,
                iconColor: AppColors.primary,
                onTap: () => _showOfferDetailsSheet(
                  context,
                  title: 'Free Ironing',
                  description: 'Get free ironing on all orders above ₹499. No coupon needed — discount applied automatically at checkout.',
                  code: 'IRONFREE',
                ),
              ),
              const Gap(16),
              _SpecialOfferCard(
                title: '20% off',
                subtitle: 'your first dry clean',
                code: 'DRYCLEAN20',
                backgroundColor: AppColors.secondaryLight,
                iconColor: AppColors.secondaryDark,
                onTap: () => _showOfferDetailsSheet(
                  context,
                  title: '20% Off Dry Cleaning',
                  description: 'Enjoy 20% discount on your first dry cleaning order. Minimum order value ₹299.',
                  code: 'DRYCLEAN20',
                  terms: 'Valid once per customer. Cannot be clubbed with other offers. Valid for 30 days.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _showOfferDetailsSheet(
    BuildContext context, {
    required String title,
    required String description,
    required String code,
    String? terms,
  }) {
    AppBottomSheet.show<void>(
      context: context,
      title: 'Offer Details',
      primaryActionLabel: 'Copy Code',
      secondaryActionLabel: 'Close',
      onSecondaryAction: () => Navigator.of(context).pop(),
      onPrimaryAction: () {
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.laundry,
                    color: AppColors.primary,
                    size: 24.r,
                  ),
                ),
                Gap(AppSpacing.md.w),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Gap(AppSpacing.cardGap.h),
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            Gap(AppSpacing.md.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md.w,
                vertical: AppSpacing.sm.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.input.r),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.coupon, color: AppColors.primary, size: 18.r),
                  Gap(AppSpacing.sm.w),
                  Expanded(
                    child: Text(
                      code,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Icon(
                    AppIcons.copy,
                    color: AppColors.primary,
                    size: 18.r,
                  ),
                ],
              ),
            ),
            if (terms != null) ...[
              Gap(AppSpacing.md.h),
              Text(
                'Terms & Conditions',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap(AppSpacing.xs.h),
              Text(
                terms,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpecialOfferCard extends StatelessWidget {
  const _SpecialOfferCard({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String code;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250.w,
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
        ),
        child: Row(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.laundry, color: iconColor, size: 24.r),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBlack,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Use code: $code',
                      style: AppTypography.caption.copyWith(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.forward, color: iconColor, size: 12.r),
            ),
          ],
        ),
      ),
    );
  }
}
