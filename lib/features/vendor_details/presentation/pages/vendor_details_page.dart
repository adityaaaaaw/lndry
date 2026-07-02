import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/domain_cards.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../core/router/app_routes.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../providers/vendor_details_providers.dart';

class VendorDetailsPage extends ConsumerStatefulWidget {
  const VendorDetailsPage({super.key, required this.vendorId});
  final String vendorId;

  @override
  ConsumerState<VendorDetailsPage> createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends ConsumerState<VendorDetailsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  VendorModel? _vendor;
  late TabController _tabController;

  // Pickup slot state
  bool _slotsLoading = false;
  List<PickupSlot> _availableSlots = [];
  PickupSlot? _selectedSlot;
  String? _currentHoldId;
  String _selectedDate = '';

  Future<void> _loadPickupSlots() async {
    final repo = ref.read(customerRepositoryProvider);
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    setState(() {
      _slotsLoading = true;
      _selectedDate = dateStr;
    });

    try {
      final slots = await repo.getPickupSlots(
        vendorId: widget.vendorId,
        date: dateStr,
      );
      if (mounted) {
        PickupSlot? firstSlot;
        setState(() {
          _availableSlots = slots;
          if (_selectedSlot == null && slots.isNotEmpty) {
            _selectedSlot = slots.first;
            firstSlot = slots.first;
          }
          _slotsLoading = false;
        });
        // Hold outside setState to properly handle async
        if (firstSlot != null) {
          _holdSlot(firstSlot!);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _slotsLoading = false);
    }
  }

  Future<void> _holdSlot(PickupSlot slot) async {
    // Release previous hold if any
    if (_currentHoldId != null) {
      try {
        await ref
            .read(customerRepositoryProvider)
            .releaseSlotHold(_currentHoldId!);
      } catch (_) {}
    }

    try {
      final result = await ref.read(customerRepositoryProvider).holdSlot(
            vendorId: widget.vendorId,
            slotId: slot.id,
            date: _selectedDate,
          );
      if (mounted) {
        setState(() {
          _currentHoldId = result.holdId;
        });
      }
    } catch (_) {
      // Hold failed — slot may no longer be available
      if (mounted) {
        AppSnackBar.showError(context,
            'This slot is no longer available. Please select another.');
      }
    }
  }

  void _showPickupSlotSheet() {
    AppBottomSheet.show(
      context: context,
      title: 'Select pickup slot',
      child: _slotsLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: _availableSlots.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (context, idx) {
                final slot = _availableSlots[idx];
                final isSelected = _selectedSlot?.id == slot.id;
                final label = _slotLabel(slot);

                return AppCard.outlined(
                  borderColor:
                      isSelected ? AppColors.primary : AppColors.outline,
                  backgroundColor: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.transparent,
                  onTap: () {
                    setState(() => _selectedSlot = slot);
                    _holdSlot(slot);
                    Navigator.of(context).pop();
                  },
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(label, style: AppTypography.bodyMedium)),
                      if (isSelected)
                        Icon(AppIcons.success,
                            color: AppColors.primary, size: 18.r),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _slotLabel(PickupSlot slot) {
    final part = slot.label != null ? '${slot.label} • ' : '';
    return '$part${slot.startTime}–${slot.endTime}';
  }

  String _deliveryEstimate() {
    // Rough estimate: if slot starts before 12 PM, delivery next day evening;
    // otherwise day after.
    if (_selectedSlot == null) return 'Tomorrow, 7:00 PM';
    final startHour =
        int.tryParse((_selectedSlot!.startTime.split(':').first)) ?? 9;
    return startHour < 12 ? 'Tomorrow, 7:00 PM' : 'Day after, 7:00 PM';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadVendorData();
  }

  @override
  void dispose() {
    // Release any held slot
    if (_currentHoldId != null) {
      ref.read(customerRepositoryProvider).releaseSlotHold(_currentHoldId!);
    }
    _tabController.dispose();
    super.dispose();
  }

  void _loadVendorData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);
    try {
      final v = await repo.getVendorById(widget.vendorId);
      await ref.read(vendorCartProvider.notifier).init(widget.vendorId);

      if (mounted) {
        setState(() {
          _vendor = v;
          _isLoading = false;
        });
        // Load pickup slots in background
        _loadPickupSlots();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const AppLoadingPage(message: 'Loading Luxe details...'),
      );
    }

    if (_vendor == null) {
      return Scaffold(
        body: AppErrorWidget.fullscreen(
          title: 'Store unavailable',
          message: 'Unable to fetch the selected vendor details.',
          onRetry: _loadVendorData,
        ),
      );
    }

    final cartState = ref.watch(vendorCartProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── 1. Banner Image AppBar with overlay back/share/heart ─────
              SliverAppBar(
                expandedHeight: 220.h,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                leading: Center(
                  child: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppElevation.low,
                    ),
                    child: Center(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(AppIcons.back,
                            color: const Color(0xFF090F14), size: 16.r),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                actions: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppElevation.low,
                    ),
                    child: Center(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(AppIcons.share,
                            color: const Color(0xFF090F14), size: 16.r),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(
                            text:
                                'Check out ${_vendor!.name} on LNDRY! lndry.app/vendor/${_vendor!.id}',
                          ));
                          if (!context.mounted) return;
                          AppSnackBar.showSuccess(
                              context, 'Vendor link copied to clipboard!');
                        },
                      ),
                    ),
                  ),
                  const Gap(8),
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppElevation.low,
                    ),
                    child: Center(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(AppIcons.favoriteOutlined,
                            color: const Color(0xFF090F14), size: 16.r),
                        onPressed: () {
                          AppSnackBar.showSuccess(
                              context, 'Added to your favorites!');
                        },
                      ),
                    ),
                  ),
                  const Gap(16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'vendor-cover-${_vendor!.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: CachedNetworkImage(
                            imageUrl: _vendor!.coverImageUrl.isNotNullOrBlank
                                ? _vendor!.coverImageUrl!
                                : 'https://images.unsplash.com/photo-1545180856-f6d2e61df3fa?fit=crop&w=400&q=80',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        color: AppColors.black.withOpacity(0.15),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Profile Details Overlap Card ────────────────────────────
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, -24.h),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Card container
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowColor.withOpacity(0.08),
                              blurRadius: 16.r,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 16.w, right: 16.w, top: 48.h, bottom: 16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _vendor!.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontSize: 18.sp,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Gap(8),
                                  if (_vendor!.isVerified)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.successContainer
                                            .withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(AppIcons.done,
                                              color: AppColors.success,
                                              size: 10.r),
                                          const Gap(4),
                                          Text(
                                            'Verified',
                                            style: TextStyle(
                                              color: AppColors.success,
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const Gap(8),
                              Row(
                                children: [
                                  Icon(AppIcons.star,
                                      color: Colors.amber, size: 14.r),
                                  const Gap(4),
                                  Text(
                                    '${_vendor!.averageRating ?? 4.8}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    '(${_vendor!.reviewCount} reviews)  •  ${_vendor!.distanceKm != null ? '${_vendor!.distanceKm!.toStringAsFixed(1)} km away' : 'Nearby'}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              Row(
                                children: [
                                  Icon(AppIcons.delivery,
                                      color: AppColors.success, size: 16.r),
                                  const Gap(6),
                                  Text(
                                    'Pickup available in 30 min',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Floating logo container
                      Positioned(
                        top: -30.h,
                        left: 36.w,
                        child: Container(
                          width: 60.r,
                          height: 60.r,
                          decoration: BoxDecoration(
                            color: const Color(0xFF090F14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 3.r,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor.withOpacity(0.15),
                                blurRadius: 8.r,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30.r),
                            child: _vendor!.logoUrl.isNotNullOrBlank
                                ? CachedNetworkImage(
                                    imageUrl: _vendor!.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        Center(
                                      child: Icon(
                                        AppIcons.laundry,
                                        color: const Color(0xFFFBD38D), // gold
                                        size: 26.r,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      AppIcons.laundry,
                                      color: const Color(0xFFFBD38D), // gold
                                      size: 26.r,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 4. Tabs Bar ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3.h),
                      insets: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    labelStyle: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                    unselectedLabelStyle: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 13.sp,
                    ),
                    tabs: const [
                      Tab(text: 'Services'),
                      Tab(text: 'Reviews'),
                      Tab(text: 'About'),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Gap(16)),

              // ── 3. Vendor Qualities Row ────────────────────────────────────
              if (_tabController.index == 0 || _tabController.index == 2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _QualityItem(
                            icon: Icons.verified_outlined,
                            line1: 'Verified',
                            line2: 'partner',
                          ),
                          const Gap(16),
                          _QualityItem(
                            icon: AppIcons.laundry,
                            line1: 'Separate',
                            line2: 'wash',
                          ),
                          const Gap(16),
                          _QualityItem(
                            icon: Icons.eco_outlined,
                            line1: 'Eco-friendly',
                            line2: 'cleaning',
                          ),
                          const Gap(16),
                          _QualityItem(
                            icon: Icons.shield_outlined,
                            line1: 'Damage',
                            line2: 'protection',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_tabController.index == 0 || _tabController.index == 2)
                const SliverToBoxAdapter(child: Gap(20)),

              // ── About tab content ──────────────────────────────────────────
              if (_tabController.index == 2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: AppCard.outlined(
                      padding: EdgeInsets.all(16.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About ${_vendor!.name}',
                            style: AppTypography.titleMedium
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Gap(8),
                          Text(
                            _vendor!.description,
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_tabController.index == 2)
                const SliverToBoxAdapter(child: Gap(16)),

              // ── 6. Service menu items list ─────────────────────────────────
              if (_tabController.index == 0)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                        final svc = cartState.services[idx];
                        final item = cartState.items.firstWhere(
                          (i) => i.serviceId == svc.id,
                          orElse: () => const CartItem(
                              id: '', serviceId: '', quantity: 0),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ServiceCard(
                            service: svc,
                            quantity: item.quantity,
                            onAdd: () => ref
                                .read(vendorCartProvider.notifier)
                                .updateQuantity(svc.id, 1),
                            onRemove: () => ref
                                .read(vendorCartProvider.notifier)
                                .updateQuantity(svc.id, -1),
                          ),
                        );
                      },
                      childCount: cartState.services.length,
                    ),
                  ),
                ),

              // ── 7. Weekly Essentials popular combo banner ─────────────────
              if (_tabController.index == 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.r),
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E1B4B),
                                  const Color(0xFF311042)
                                ]
                              : [
                                  const Color(0xFFF0EDFF),
                                  const Color(0xFFF9EBFF)
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left details column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'POPULAR COMBO',
                                    style: AppTypography.badge.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  'Weekly Essentials',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  '5 kg Wash & Fold + 5 Steam Press items',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 11.sp,
                                  ),
                                ),
                                const Gap(12),
                                Row(
                                  children: [
                                    Text(
                                      '₹649',
                                      style: AppTypography.titleLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const Gap(8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        'Save ₹120',
                                        style: AppTypography.badge.copyWith(
                                          color: AppColors.secondaryDark,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Gap(16),
                          // Right column with product image and overlapping Add button
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: 80.w,
                                height: 80.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  image: const DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      'https://images.unsplash.com/photo-1545180856-f6d2e61df3fa?fit=crop&w=120&q=80',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -12.h,
                                child: Container(
                                  height: 28.h,
                                  width: 64.w,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      for (final svc
                                          in cartState.services.take(2)) {
                                        ref
                                            .read(vendorCartProvider.notifier)
                                            .updateQuantity(svc.id, 1);
                                      }
                                      AppSnackBar.showSuccess(context,
                                          'Weekly Essentials added to cart.');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── 8. Pickup Slot Estimate summary card ───────────────────────
              if (_tabController.index == 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowColor.withOpacity(0.04),
                            blurRadius: 6.r,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              AppIcons.calendar,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20.r,
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next pickup slot',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  _selectedSlot != null
                                      ? _slotLabel(_selectedSlot!)
                                      : 'Select a slot',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  'Delivery estimate: ${_deliveryEstimate()}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          OutlinedButton(
                            onPressed: _showPickupSlotSheet,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 6.h),
                              minimumSize: Size(64.w, 32.h),
                            ),
                            child: Text(
                              'Change',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: Gap(24)),

              // ── 9. "What customers say" Section ────────────────────────────
              if (_tabController.index == 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'What customers say',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _tabController.animateTo(1),
                          child: Text(
                            'View all',
                            style: AppTypography.labelMedium.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_tabController.index == 1)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      children: [
                        _ReviewCard(
                          author: 'Aarav S.',
                          rating: 5.0,
                          comment:
                              'Excellent service! Clothes came back spotless and crisp.',
                          avatarUrl:
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=50&q=80',
                        ),
                        const Gap(12),
                        _ReviewCard(
                          author: 'Neha R.',
                          rating: 4.7,
                          comment:
                              'Very happy with the quality and on-time pickup.',
                          avatarUrl:
                              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?fit=crop&w=50&q=80',
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom padding spacing
              const SliverToBoxAdapter(child: Gap(110)),
            ],
          ),

          // ── 10. Sticky Bottom Billing Bar (Image 2 layout) ─────────────────
          if (cartState.totalQuantity > 0)
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 20.h,
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor.withOpacity(0.1),
                      blurRadius: 16.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cart quantity badge circle
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.cartOutlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22.r,
                          ),
                        ),
                        Positioned(
                          top: -4.h,
                          right: -4.w,
                          child: Container(
                            padding: EdgeInsets.all(5.r),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cartState.totalQuantity}',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cartState.subtotal > 0
                                ? '${cartState.totalQuantity} items  •  ${cartState.subtotal.toCurrency}'
                                : '${cartState.totalQuantity} items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Final price after item verification',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(cartStateProvider.notifier).refresh();
                        if (!context.mounted) return;
                        context.push(AppRoutes.checkout);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 12.h),
                        minimumSize: Size(0, 40.h),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

// ── Quality detail row helper ────────────────────────────────────────────────

class _QualityItem extends StatelessWidget {
  const _QualityItem({
    required this.icon,
    required this.line1,
    required this.line2,
  });

  final IconData icon;
  final String line1;
  final String line2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20.r,
              ),
            ),
          ),
          const Gap(8),
          Text(
            line1,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            line2,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Customer reviews card helper ─────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.author,
    required this.rating,
    required this.comment,
    required this.avatarUrl,
  });

  final String author;
  final double rating;
  final String comment;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260.w,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.03),
            blurRadius: 4.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundImage: CachedNetworkImageProvider(avatarUrl),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  author,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(AppIcons.star, color: Colors.amber, size: 12.r),
                  const Gap(2),
                  Text(
                    '$rating',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(8),
          Expanded(
            child: Text(
              comment,
              style: TextStyle(
                fontSize: 11.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
