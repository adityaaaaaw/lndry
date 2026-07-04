import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/auth_gate.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/widgets/service_icon.dart';
import '../providers/cart_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CART PAGE
// ═══════════════════════════════════════════════════════════════════════════

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _isLoading = true;
  final _couponController = TextEditingController();
  final _couponFocusNode = FocusNode();
  bool _couponApplied = false;
  bool _couponFocused = false;

  VendorModel? _vendor;
  bool _vendorLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _couponFocusNode.addListener(_onCouponFocusChange);
    _couponController.addListener(_onCouponTextChanged);
  }

  @override
  void dispose() {
    _couponFocusNode.removeListener(_onCouponFocusChange);
    _couponFocusNode.dispose();
    _couponController.removeListener(_onCouponTextChanged);
    _couponController.dispose();
    super.dispose();
  }

  void _onCouponTextChanged() {
    if (mounted) setState(() {});
  }

  void _onCouponFocusChange() {
    if (mounted) {
      setState(() => _couponFocused = _couponFocusNode.hasFocus);
    }
  }

  void _loadCart() async {
    setState(() => _isLoading = true);
    await ref.read(cartStateProvider.notifier).init();
    if (mounted) {
      setState(() => _isLoading = false);
      _loadVendor();
    }
  }

  void _loadVendor() async {
    final state = ref.read(cartStateProvider);
    if (state.cart.items.isNotEmpty && state.services.isNotEmpty) {
      final vendorId = state.services.first.vendorId;
      if (vendorId.isNotEmpty) {
        setState(() => _vendorLoading = true);
        try {
          final repo = ref.read(customerRepositoryProvider);
          final v = await repo.getVendorById(vendorId);
          if (mounted) {
            setState(() {
              _vendor = v;
              _vendorLoading = false;
            });
          }
        } catch (_) {
          if (mounted) setState(() => _vendorLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _vendor = null;
          _vendorLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final state = ref.watch(cartStateProvider);

    // Watch for cart updates to load vendor details
    ref.listen<CartState>(cartStateProvider, (previous, next) {
      if (next.cart.isEmpty) {
        if (_vendor != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _vendor = null);
          });
        }
      } else if (_vendor == null && next.services.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadVendor();
        });
      }
    });

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          systemOverlayStyle: isDark
              ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                )
              : const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                ),
        ),
        body: const AppLoadingPage(message: 'Loading cart...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isDark, state),
      body: state.cart.isEmpty
          ? _buildEmptyState()
          : _buildCartContent(isDark, state),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark, CartState state) {
    return AppBar(
      leading: Center(
        child: Container(
          width: 36.r,
          height: 36.r,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceContainer : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? AppColors.darkOutlineVariant
                  : AppColors.outlineVariant,
            ),
            boxShadow: AppElevation.low,
          ),
          child: Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                AppIcons.back,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                size: 16.r,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      title: Text(
        state.cart.isEmpty ? 'Cart' : 'Cart (${state.cart.itemCount})',
        style: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      centerTitle: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5.r,
      systemOverlayStyle: isDark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
      actions: [
        if (state.cart.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: TextButton(
              onPressed: () async {
                final confirm = await AppDialog.show(
                  context,
                  title: 'Clear Cart?',
                  message: 'Are you sure you want to remove all items?',
                  confirmLabel: 'Clear All',
                  isDestructive: true,
                );
                if (confirm == true) {
                  ref.read(cartStateProvider.notifier).clear();
                  setState(() => _vendor = null);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
              ),
              child: Text(
                'Clear',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isDark = context.isDark;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 32.w,
            vertical: 40.h,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Container(
                    width: 100.r,
                    height: 100.r,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                    ),
                    child: Center(
                      child: Icon(
                        AppIcons.cartOutlined,
                        size: 44.r,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(32),
              Text(
                'Your cart is empty',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(12),
              Text(
                'Browse laundry services and add items\nto get started on your order.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(32),
              SizedBox(
                width: 200.w,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    try {
                      final navShell = StatefulNavigationShell.of(context);
                      navShell.goBranch(1);
                    } catch (_) {
                      context.go(AppRoutes.home);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Browse Laundries',
                    style: AppTypography.buttonText.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cart Content ───────────────────────────────────────────────────────────

  Widget _buildCartContent(bool isDark, CartState state) {
    final discount = _couponApplied ? 50.0 : 0.0;
    final grandTotal = (state.total - discount).clamp(0.0, double.infinity);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await ref.read(cartStateProvider.notifier).init();
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20.w,
                16.h,
                20.w,
                24.h,
              ),
              children: [
                // 1. Vendor Card (reactive block)
                if (_vendorLoading)
                  Container(
                    height: 80.h,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  )
                else if (_vendor != null) ...[
                  _CartVendorCard(vendor: _vendor!),
                  const Gap(20),
                ],

                // 2. Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Services',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${state.cart.items.length} items',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Gap(12),

                // 3. Cart Items List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.cart.items.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, idx) {
                    final item = state.cart.items[idx];
                    final svc = state.services.firstWhere(
                      (s) => s.id == item.serviceId,
                      orElse: () => ServiceModel(
                        id: item.serviceId,
                        vendorId: '',
                        name: 'Service',
                        description: '',
                        category: ServiceCategory.wash,
                        minWeightKg: 0,
                      ),
                    );
                    return _CartItemCard(
                      service: svc,
                      quantity: item.quantity,
                      onAdd: () => ref
                          .read(cartStateProvider.notifier)
                          .updateQuantity(svc.id, item.quantity + 1),
                      onRemove: () => ref
                          .read(cartStateProvider.notifier)
                          .updateQuantity(svc.id, item.quantity - 1),
                      onRemoveItem: () async {
                        final confirm = await AppDialog.show(
                          context,
                          title: 'Remove Item?',
                          message: 'Remove "${svc.name}" from your cart?',
                          confirmLabel: 'Remove',
                          isDestructive: true,
                        );
                        if (confirm == true) {
                          ref
                              .read(cartStateProvider.notifier)
                              .updateQuantity(svc.id, 0);
                        }
                      },
                    );
                  },
                ),
                const Gap(24),

                // 4. Coupon Code Entry Section
                _CouponSection(
                  controller: _couponController,
                  focusNode: _couponFocusNode,
                  isApplied: _couponApplied,
                  isFocused: _couponFocused,
                  onApply: () {
                    if (_couponController.text.trim().isNotEmpty) {
                      setState(() => _couponApplied = true);
                      AppSnackBar.showSuccess(context, 'Coupon applied!');
                    }
                  },
                  onRemove: () {
                    setState(() {
                      _couponApplied = false;
                      _couponController.clear();
                    });
                  },
                ),
                const Gap(24),

                // 5. Price Breakdown Summary
                _PriceSummary(
                  state: state,
                  couponDiscount: discount,
                  grandTotal: grandTotal,
                ),
              ],
            ),
          ),
        ),

        // 6. Sticky Bottom Summary Bar
        _CartBottomCheckoutBar(
          grandTotal: grandTotal,
          onCheckout: () => requireAuthenticated(
            context: context,
            ref: ref,
            returnTo: AppRoutes.cart,
            action: (ctx, _) => ctx.push(AppRoutes.checkout),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CART VENDOR CARD
// ═══════════════════════════════════════════════════════════════════════════

class _CartVendorCard extends StatelessWidget {
  const _CartVendorCard({required this.vendor});
  final VendorModel vendor;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.outlineVariant,
        ),
        boxShadow: AppElevation.low,
      ),
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: vendor.logoUrl != null && vendor.logoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: vendor.logoUrl!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        AppIcons.laundry,
                        color: AppColors.primary,
                        size: 24.r,
                      ),
                    ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        vendor.name,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(6),
                    if (vendor.isVerified)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                color: AppColors.secondary, size: 8.r),
                            const Gap(2),
                            Text(
                              'Verified',
                              style: AppTypography.badge.copyWith(
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
                const Gap(4),
                Row(
                  children: [
                    Icon(AppIcons.star, color: AppColors.rating, size: 12.r),
                    const Gap(3),
                    Text(
                      '${vendor.averageRating ?? 4.8}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '(${vendor.reviewCount} reviews)  •  ${vendor.distanceKm != null ? '${vendor.distanceKm!.toStringAsFixed(1)} km' : 'Nearby'}',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Gap(6),
                Row(
                  children: [
                    Icon(AppIcons.delivery,
                        color: AppColors.secondary, size: 12.r),
                    const Gap(4),
                    Text(
                      'Next pickup: Today, 5:30 PM',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
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

// ═══════════════════════════════════════════════════════════════════════════
// CART ITEM CARD
// ═══════════════════════════════════════════════════════════════════════════

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.service,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onRemoveItem,
  });

  final ServiceModel service;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.outlineVariant,
          width: 1,
        ),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandedServiceIcon(
                category: service.category,
                iconKey: service.tags.isNotEmpty ? service.tags.first : null,
                size: 48.r,
                iconSize: 26.r,
                backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.4),
              ),
              Gap(AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(AppSpacing.xs.h),
                    Text(
                      service.description,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(AppSpacing.xs.h),
                    Text(
                      _priceLabel(service),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 36.r,
                height: 36.r,
                child: IconButton(
                  icon: Icon(
                    AppIcons.close,
                    size: 16.r,
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onRemoveItem,
                ),
              ),
            ],
          ),
          Gap(AppSpacing.md.h),
          Divider(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
            thickness: 1,
            height: 1,
          ),
          Gap(AppSpacing.md.h),
          Row(
            children: [
              _QuantityStepper(
                quantity: quantity,
                onAdd: onAdd,
                onRemove: onRemove,
              ),
              const Spacer(),
              Text(
                _itemTotal(service, quantity),
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _priceLabel(ServiceModel svc) {
    if (svc.pricePerKg != null && svc.pricePerKg! > 0) {
      return '${svc.pricePerKg!.toCurrency}/kg';
    }
    if (svc.pricePerPiece != null && svc.pricePerPiece! > 0) {
      return '${svc.pricePerPiece!.toCurrency}/item';
    }
    return '';
  }

  String _itemTotal(ServiceModel svc, int qty) {
    final unitPrice = svc.pricePerKg ?? svc.pricePerPiece ?? 0;
    final total = unitPrice * qty;
    return total.toCurrencyDecimal;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUANTITY STEPPER
// ═══════════════════════════════════════════════════════════════════════════

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.full.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: AppIcons.remove,
            onPressed: onRemove,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            child: Text(
              '$quantity',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: context.isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          _StepperButton(
            icon: AppIcons.add,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44.r,
      height: 44.r,
      child: Center(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.full.r),
          child: Container(
            width: 32.r,
            height: 32.r,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 16.r,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COUPON SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _CouponSection extends StatelessWidget {
  const _CouponSection({
    required this.controller,
    required this.focusNode,
    required this.isApplied,
    required this.isFocused,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isApplied;
  final bool isFocused;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (isApplied) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.successContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              AppIcons.coupon,
              size: 20.r,
              color: AppColors.success,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coupon Applied!',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Flat ₹50.00 discount applied',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                AppIcons.close,
                size: 16.r,
                color: AppColors.success,
              ),
              onPressed: onRemove,
            ),
          ],
        ),
      );
    }

    final isTextEmpty = controller.text.trim().isEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isFocused
              ? AppColors.primary
              : isDark
                  ? AppColors.darkOutlineVariant
                  : AppColors.outlineVariant,
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.coupon,
            size: 20.r,
            color: isFocused ? AppColors.primary : AppColors.textMuted,
          ),
          const Gap(12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Enter coupon code',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!isTextEmpty) onApply();
              },
            ),
          ),
          const Gap(8),
          SizedBox(
            height: 36.h,
            child: ElevatedButton(
              onPressed: isTextEmpty ? null : onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.outlineVariant,
                disabledForegroundColor: AppColors.textMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              child: Text(
                'Apply',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isTextEmpty
                      ? AppColors.textMuted
                      : AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRICE SUMMARY
// ═══════════════════════════════════════════════════════════════════════════

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.state,
    required this.couponDiscount,
    required this.grandTotal,
  });

  final CartState state;
  final double couponDiscount;
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final hasPrices = state.total > 0;

    if (!hasPrices) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.md.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18.r,
              color: AppColors.onSurfaceVariant,
            ),
            Gap(AppSpacing.sm.w),
            Expanded(
              child: Text(
                'Final price will be calculated securely during checkout.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Summary',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Gap(AppSpacing.md.h),
          _SummaryRow(
            label: 'Item Subtotal',
            value: state.subtotal.toCurrencyDecimal,
            isDark: isDark,
          ),
          Gap(AppSpacing.sm.h),
          _SummaryRow(
            label: 'Platform Handling Fee',
            value: state.platformFee.toCurrencyDecimal,
            isDark: isDark,
          ),
          Gap(AppSpacing.sm.h),
          _SummaryRow(
            label: 'Delivery Fee',
            value: 'FREE',
            isDark: isDark,
            valueColor: AppColors.success,
          ),
          Gap(AppSpacing.sm.h),
          _SummaryRow(
            label: 'GST & Taxes',
            value: state.gstAmount.toCurrencyDecimal,
            isDark: isDark,
          ),
          if (couponDiscount > 0) ...[
            Gap(AppSpacing.sm.h),
            _SummaryRow(
              label: 'Coupon Discount',
              value: '-${couponDiscount.toCurrencyDecimal}',
              isDark: isDark,
              valueColor: AppColors.success,
            ),
          ],
          Gap(AppSpacing.md.h),
          Divider(
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.outlineVariant,
            thickness: 1,
            height: 1,
          ),
          Gap(AppSpacing.md.h),
          _SummaryRow(
            label: 'Grand Total',
            value: grandTotal.toCurrencyDecimal,
            isDark: isDark,
            isBold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isDark;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          )
        : AppTypography.bodySmall;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextBody,
          ),
        ),
        Text(
          value,
          style: style.copyWith(
            color: valueColor ??
                (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STICKY BOTTOM CHECKOUT BAR
// ═══════════════════════════════════════════════════════════════════════════

class _CartBottomCheckoutBar extends StatelessWidget {
  const _CartBottomCheckoutBar({
    required this.grandTotal,
    required this.onCheckout,
  });

  final double grandTotal;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        16.h,
        20.w,
        MediaQuery.paddingOf(context).bottom + 16.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.r),
        ),
        boxShadow: AppElevation.high,
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full.r),
              ),
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              minimumSize: Size(double.infinity, 48.h),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),
                Text(
                  '•',
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
                const Gap(8),
                Text(
                  grandTotal.toCurrencyDecimal,
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
