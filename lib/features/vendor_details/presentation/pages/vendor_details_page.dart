import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../../../core/auth/auth_gate.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/widgets/service_icon.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../providers/vendor_details_providers.dart';

class VendorDetailsPage extends ConsumerStatefulWidget {
  const VendorDetailsPage({required this.vendorId, super.key});
  final String vendorId;

  @override
  ConsumerState<VendorDetailsPage> createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends ConsumerState<VendorDetailsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  VendorModel? _vendor;
  List<ReviewModel> _reviews = [];
  bool _reviewsLoading = false;
  late TabController _tabController;

  // Pickup slot state
  bool _slotsLoading = false;
  List<PickupSlot> _availableSlots = [];
  PickupSlot? _selectedSlot;
  String? _currentHoldId;
  String _selectedDate = '';

  // Service Type State
  bool _isExpressSelected = false;

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
        setState(() {
          _availableSlots = slots;
          if (_selectedSlot == null && slots.isNotEmpty) {
            _selectedSlot = slots.first;
          }
          _slotsLoading = false;
        });
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
      if (mounted) {
        AppSnackBar.showError(context,
            'This slot is no longer available. Please select another.');
      }
    }
  }

  void _showPickupSlotSheet() {
    AppBottomSheet.show<void>(
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
                      isSelected ? AppColors.primary : AppColors.outlineVariant,
                  backgroundColor: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.transparent,
                  onTap: () {
                    setState(() => _selectedSlot = slot);
                    Navigator.of(context).pop();
                    requireAuthenticated(
                      context: context,
                      ref: ref,
                      action: (_, __) => _holdSlot(slot),
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label, style: AppTypography.bodyMedium),
                      ),
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
      final reviewsFuture = repo.getVendorReviews(widget.vendorId);
      await ref.read(vendorCartProvider.notifier).init(
            widget.vendorId,
            includeCart: ref.read(authProvider) is AuthAuthenticated,
          );
      final reviews = await reviewsFuture;

      if (mounted) {
        setState(() {
          _vendor = v;
          _reviews = reviews.items;
          _isLoading = false;
        });
        _loadPickupSlots();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVendorReviews() async {
    setState(() => _reviewsLoading = true);
    try {
      final reviews = await ref
          .read(customerRepositoryProvider)
          .getVendorReviews(widget.vendorId);
      if (mounted) {
        setState(() {
          _reviews = reviews.items;
          _reviewsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _updateServiceQuantity(String serviceId, int delta) {
    return requireAuthenticated(
      context: context,
      ref: ref,
      action: (_, ref) => ref
          .read(vendorCartProvider.notifier)
          .updateQuantity(serviceId, delta),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.transparent, elevation: 0),
        body: const AppLoadingPage(message: 'Loading details...'),
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── 1. Sticky Transparent Header with Actions ──────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: AppColors.background,
                elevation: 0,
                leading: Center(
                  child: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: AppElevation.low,
                    ),
                    child: Center(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          AppIcons.back,
                          color: AppColors.textBlack,
                          size: 16.r,
                        ),
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
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: AppElevation.low,
                    ),
                    child: Center(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          AppIcons.share,
                          color: AppColors.textBlack,
                          size: 16.r,
                        ),
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
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: AppElevation.low,
                    ),
                    child: Center(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          AppIcons.favoriteOutlined,
                          color: AppColors.textBlack,
                          size: 16.r,
                        ),
                        onPressed: () => requireAuthenticated(
                          context: context,
                          ref: ref,
                          action: (context, _) {
                            AppSnackBar.showSuccess(
                                context, 'Added to your favorites!');
                          },
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                ],
              ),

              // ── 2. Unified Header Card Block ──────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.outlineVariant),
                    boxShadow: AppElevation.low,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryContainer.withValues(alpha: 0.1),
                            AppColors.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left details
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52.r,
                                    height: 52.r,
                                    decoration: BoxDecoration(
                                      color: AppColors.black,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: _vendor!.logoUrl.isNotNullOrBlank
                                          ? CachedNetworkImage(
                                              imageUrl: _vendor!.logoUrl!,
                                              fit: BoxFit.cover,
                                            )
                                          : Center(
                                              child: Icon(
                                                AppIcons.laundry,
                                                color: AppColors.rating,
                                                size: 26.r,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const Gap(12),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _vendor!.name,
                                          style: AppTypography.titleLarge
                                              .copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textBlack,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Gap(6),
                                      if (_vendor!.isVerified)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 6.w, vertical: 2.h),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryLight,
                                            borderRadius:
                                                BorderRadius.circular(4.r),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_rounded,
                                                  color: AppColors.secondary,
                                                  size: 10.r),
                                              const Gap(2),
                                              Text(
                                                'Verified',
                                                style: AppTypography.badge
                                                    .copyWith(
                                                  color: AppColors.secondary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 8.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Gap(6),
                                  Row(
                                    children: [
                                      Icon(AppIcons.star,
                                          color: AppColors.rating, size: 13.r),
                                      const Gap(3),
                                      Text(
                                        '${_vendor!.averageRating ?? 4.8}',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textBlack,
                                        ),
                                      ),
                                      const Gap(4),
                                      Text(
                                        '(${_vendor!.reviewCount} reviews)  •  ${_vendor!.distanceKm != null ? '${_vendor!.distanceKm!.toStringAsFixed(1)} km away' : 'Nearby'}',
                                        style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const Gap(10),
                                  Row(
                                    children: [
                                      Icon(AppIcons.delivery,
                                          color: AppColors.secondary,
                                          size: 14.r),
                                      const Gap(6),
                                      Expanded(
                                        child: Text(
                                          'Pickup available in 30 min',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Right cover photo
                          Container(
                            width: 130.w,
                            height: 180.h,
                            color: AppColors.shimmerBase,
                            child: CachedNetworkImage(
                              imageUrl: _vendor!.coverImageUrl.isNotNullOrBlank
                                  ? _vendor!.coverImageUrl!
                                  : 'https://images.unsplash.com/photo-1545180856-f6d2e61df3fa?fit=crop&w=400&q=80',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. Feature Badges Row ──────────────────────────────────────
              if (_tabController.index == 0 || _tabController.index == 2)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: _QualitiesRow(),
                  ),
                ),

              // ── 4. Tab selection bar ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(color: AppColors.primary, width: 3.h),
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

              // ── Services tab content ───────────────────────────────────────
              if (_tabController.index == 0) ...[
                // Standard vs Express Selector Toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ServiceTypeSelector(
                      isExpress: _isExpressSelected,
                      onChanged: (val) {
                        setState(() => _isExpressSelected = val);
                      },
                    ),
                  ),
                ),
                // Services List
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                        final svc = cartState.services[idx];
                        final item = cartState.items.firstWhere(
                          (CartItem i) => i.serviceId == svc.id,
                          orElse: () => const CartItem(
                              id: '', serviceId: '', quantity: 0),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VendorServiceCard(
                            service: svc,
                            quantity: item.quantity,
                            onAdd: () => _updateServiceQuantity(svc.id, 1),
                            onRemove: () => _updateServiceQuantity(svc.id, -1),
                          ),
                        );
                      },
                      childCount: cartState.services.length,
                    ),
                  ),
                ),
                // Popular Combo Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.r),
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        gradient: AppColors.offerGradient,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        boxShadow: AppElevation.low,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'POPULAR COMBO',
                                    style: AppTypography.badge.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8.sp,
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  'Weekly Essentials',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBlack,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  '5 kg Wash & Fold + 5 Steam Press items',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Gap(12),
                                Row(
                                  children: [
                                    Text(
                                      '₹649',
                                      style: AppTypography.titleLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textBlack,
                                      ),
                                    ),
                                    const Gap(8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryLight,
                                        borderRadius:
                                            BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        'Save ₹120',
                                        style: AppTypography.badge.copyWith(
                                          color: AppColors.secondary,
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
                                child: SizedBox(
                                  height: 28.h,
                                  width: 64.w,
                                  child: ElevatedButton(
                                    onPressed: () => requireAuthenticated(
                                      context: context,
                                      ref: ref,
                                      action: (context, ref) async {
                                        for (final svc in cartState.services.take(2)) {
                                          await ref
                                              .read(vendorCartProvider.notifier)
                                              .updateQuantity(svc.id, 1);
                                        }
                                        if (!context.mounted) return;
                                        AppSnackBar.showSuccess(context,
                                            'Weekly Essentials added to cart.');
                                      },
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      padding: EdgeInsets.zero,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                      ),
                                    ),
                                    child: Text(
                                      'Add',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.white,
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
                // Pickup Slot Estimate card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.outlineVariant),
                        boxShadow: AppElevation.low,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              AppIcons.calendar,
                              color: AppColors.primary,
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
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  _selectedSlot != null
                                      ? _slotLabel(_selectedSlot!)
                                      : 'Select a slot',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBlack,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  'Delivery estimate: ${_deliveryEstimate()}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          OutlinedButton(
                            onPressed: _showPickupSlotSheet,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 6.h),
                              minimumSize: Size(64.w, 32.h),
                            ),
                            child: Text(
                              'Change',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // ── Reviews tab content ────────────────────────────────────────
              if (_tabController.index == 1) ...[
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
                            color: AppColors.textBlack,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadVendorReviews,
                          child: Text(
                            'Refresh',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _reviewsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _reviews.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: const AppEmptyState(
                                icon: Icons.star_border_rounded,
                                title: 'No Reviews Yet',
                                subtitle: 'Customer reviews will appear here.',
                              ),
                            )
                          : SizedBox(
                              height: 120.h,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                itemCount: _reviews.length,
                                separatorBuilder: (_, __) => const Gap(12),
                                itemBuilder: (context, index) {
                                  final review = _reviews[index];
                                  return _ReviewCard(
                                    author: review.userName ?? 'Customer',
                                    rating: review.vendorRating.toDouble(),
                                    comment: review.comment ?? '',
                                    avatarUrl: review.userAvatarUrl ?? '',
                                  );
                                },
                              ),
                            ),
                ),
              ],

              const SliverToBoxAdapter(child: Gap(110)),
            ],
          ),

          // ── 10. Sticky Bottom Billing Cart ─────────────────────────────────
          if (cartState.totalQuantity > 0)
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 20.h,
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full.r),
                  border: Border.all(color: AppColors.outlineVariant),
                  boxShadow: AppElevation.high,
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.cartOutlined,
                            color: AppColors.primary,
                            size: 22.r,
                          ),
                        ),
                        Positioned(
                          top: -4.h,
                          right: -4.w,
                          child: Container(
                            padding: EdgeInsets.all(5.r),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cartState.totalQuantity}',
                              style: AppTypography.caption.copyWith(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
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
                            '${cartState.totalQuantity} services  ·  Estimated ${cartState.subtotal.toCurrency}',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                          Text(
                            'Final price after item verification',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => requireAuthenticated(
                        context: context,
                        ref: ref,
                        returnTo: currentRouteLocation(context),
                        action: (context, ref) async {
                          await ref.read(cartStateProvider.notifier).refresh();
                          if (!context.mounted) return;
                          context.push(AppRoutes.checkout);
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full.r),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 12.h),
                        minimumSize: Size(0, 44.h),
                      ),
                      child: Text(
                        'Continue',
                        style: AppTypography.buttonText.copyWith(
                          color: AppColors.white,
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

// ── Quality row helper ───────────────────────────────────────────────────────

class _QualitiesRow extends StatelessWidget {
  const _QualitiesRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            const Expanded(
              child: _QualityColumn(
                icon: Icons.verified_outlined,
                title: 'Verified partner',
              ),
            ),
            Container(width: 1, height: 32.h, color: AppColors.outlineVariant),
            const Expanded(
              child: _QualityColumn(
                icon: AppIcons.laundry,
                title: 'Separate wash',
              ),
            ),
            Container(width: 1, height: 32.h, color: AppColors.outlineVariant),
            const Expanded(
              child: _QualityColumn(
                icon: Icons.eco_outlined,
                title: 'Eco-friendly cleaning',
              ),
            ),
            Container(width: 1, height: 32.h, color: AppColors.outlineVariant),
            const Expanded(
              child: _QualityColumn(
                icon: Icons.shield_outlined,
                title: 'Damage protection',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityColumn extends StatelessWidget {
  const _QualityColumn({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20.r),
        const Gap(6),
        Text(
          title,
          style: AppTypography.caption.copyWith(
            color: AppColors.textBlack,
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Standard/Express toggle selector ──────────────────────────────────────────

class _ServiceTypeSelector extends StatelessWidget {
  const _ServiceTypeSelector({
    required this.isExpress,
    required this.onChanged,
  });

  final bool isExpress;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        height: 54.h,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(false),
                child: Container(
                  decoration: BoxDecoration(
                    color: !isExpress ? AppColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(16.r),
                    border: !isExpress
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3))
                        : null,
                    boxShadow: !isExpress ? AppElevation.low : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Standard',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: !isExpress
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '48-hour delivery',
                          style: AppTypography.caption.copyWith(
                            fontSize: 9.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(true),
                child: Container(
                  decoration: BoxDecoration(
                    color: isExpress ? AppColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(16.r),
                    border: isExpress
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3))
                        : null,
                    boxShadow: isExpress ? AppElevation.low : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Express',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isExpress
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '+₹49 surcharge',
                          style: AppTypography.caption.copyWith(
                            fontSize: 9.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
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

// ── Private Vendor Menu Service Card ─────────────────────────────────────────

class _VendorServiceCard extends StatelessWidget {
  const _VendorServiceCard({
    required this.service,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final ServiceModel service;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final String priceLabel = switch (service.id) {
      'wash_fold' || 'svc_001' => '₹99/kg',
      'wash_iron' || 'svc_002' => '₹129/kg',
      'dry_cleaning' || 'svc_003' => 'From ₹79/item',
      'steam_press' || 'svc_004' => '₹25/item',
      'shoe_care' || 'svc_005' => 'From ₹299/pair',
      'premium_care' || 'svc_006' => 'From ₹199/item',
      _ => service.pricePerKg != null
          ? '₹${service.pricePerKg!.toStringAsFixed(0)}/kg'
          : '₹${(service.pricePerPiece ?? 0).toStringAsFixed(0)}/item',
    };

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppElevation.low,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandedServiceIcon(
            category: service.category,
            iconKey: service.tags.isNotEmpty ? service.tags.first : null,
            size: 48.r,
            iconSize: 26.r,
            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.4),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  service.description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Row(
                  children: [
                    Icon(
                      AppIcons.clock,
                      size: 10.r,
                      color: AppColors.textMuted,
                    ),
                    const Gap(4),
                    Expanded(
                      child: Text(
                        subDetails,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceLabel,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const Gap(12),
              if (quantity > 0)
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
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const Gap(8),
                    _StepButton(
                      icon: AppIcons.add,
                      onPressed: onAdd,
                    ),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: onAdd,
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    minimumSize: Size(72.w, 28.h),
                  ),
                  child: Text(
                    service.id == 'dry_cleaning' || service.id == 'svc_003'
                        ? 'Choose garments'
                        : 'Add',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
  const _StepButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 12.r),
      ),
    );
  }
}

// ── Private Customer Review Card Widget ──────────────────────────────────────

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
        color: AppColors.surface,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Icon(AppIcons.profile, size: 14.r, color: AppColors.primary)
                    : null,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  author,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Icon(AppIcons.star, color: AppColors.rating, size: 12.r),
                  const Gap(2),
                  Text(
                    '$rating',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
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
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
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
