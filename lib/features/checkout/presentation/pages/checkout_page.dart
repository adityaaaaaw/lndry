import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/domain_cards.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../cart/presentation/providers/cart_providers.dart';

/// Checkout selections passed to the payment screen via GoRouter extra.
class CheckoutSession {
  const CheckoutSession({
    required this.deliveryAddressId,
    required this.pickupAddressId,
    required this.finalPrice,
    this.selectedSlot,
    this.isExpressPickup = false,
    this.pickupDateIdx = 0,
  });

  final String deliveryAddressId;
  final String pickupAddressId;
  final double finalPrice;
  final String? selectedSlot;
  final bool isExpressPickup;
  final int pickupDateIdx;
}

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  bool _isLoading = true;
  AddressModel? _selectedAddress;
  List<AddressModel> _addresses = [];
  
  // Date select state: 0 = Today, 1 = Tomorrow
  int _selectedDateIdx = 0;
  
  // 60-minute pickup slot string
  String? _selectedSlot;
  bool _isExpressPickup = false;

  final List<String> _slots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
    '04:00 PM - 05:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  void _loadCheckoutData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);
    try {
      final list = await repo.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = list;
          _selectedAddress = list.firstWhere(
            (a) => a.isDefault,
            orElse: () => list.isNotEmpty ? list.first : const AddressModel(id: '', userId: '', line1: '', city: '', state: '', pincode: '', type: AddressType.home),
          );
          _selectedSlot = _slots.first;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddressModal() {
    AppBottomSheet.show(
      context: context,
      title: 'Select Delivery Address',
      primaryActionLabel: 'Confirm Address',
      child: StatefulBuilder(
        builder: (context, setModalState) => ListView.separated(
          shrinkWrap: true,
          itemCount: _addresses.length,
          separatorBuilder: (_, __) => const Gap(8),
          itemBuilder: (context, idx) {
            final addr = _addresses[idx];
            final isChosen = _selectedAddress?.id == addr.id;

            return AppCard.outlined(
              borderColor: isChosen ? AppColors.primary : AppColors.outline,
              backgroundColor: isChosen ? AppColors.primaryContainer : AppColors.transparent,
              onTap: () {
                setModalState(() => _selectedAddress = addr);
                setState(() => _selectedAddress = addr);
              },
              child: Row(
                children: [
                  Icon(
                    addr.type == AddressType.home ? AppIcons.homeOutlined : AppIcons.store,
                    color: isChosen ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(addr.type.label, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '${addr.line1}, ${addr.city}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isChosen)
                    Icon(AppIcons.success, color: AppColors.primary, size: 18.r),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _onProceedToPayment(CartState cart) {
    if (_selectedAddress == null || _selectedAddress!.id.isEmpty) {
      AppSnackBar.showError(context, 'Please select a delivery address.');
      return;
    }

    if (_selectedSlot == null && !_isExpressPickup) {
      AppSnackBar.showError(context, 'Please select a pickup time slot.');
      return;
    }

    // Save final checkout total details to payment via route extra
    context.push(
      AppRoutes.payment,
      extra: CheckoutSession(
        deliveryAddressId: _selectedAddress!.id,
        pickupAddressId: _selectedAddress!.id,
        finalPrice: cart.total + (_isExpressPickup ? 99.0 : 0.0),
        selectedSlot: _isExpressPickup ? 'Express (within 60 min)' : _selectedSlot,
        isExpressPickup: _isExpressPickup,
        pickupDateIdx: _selectedDateIdx,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(cartStateProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.transparent, elevation: 0),
        body: const AppLoadingPage(message: 'Preparing checkout summary...'),
      );
    }

    if (cartState.cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Checkout', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(AppIcons.back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        body: AppEmptyState(
          icon: AppIcons.cartOutlined,
          title: 'Nothing to checkout',
          subtitle: 'Add laundry services from a vendor before scheduling pickup.',
          actionLabel: 'Browse vendors',
          onAction: () => context.go(AppRoutes.vendorListing),
        ),
      );
    }

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final finalPrice = cartState.total + (_isExpressPickup ? 99.0 : 0.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Checkout', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Address Picker Section ──────────────────────────────
                    Text('Delivery Address', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    const Gap(12),
                    AppCard.outlined(
                      onTap: _showAddressModal,
                      padding: EdgeInsets.all(AppSpacing.md.r),
                      child: Row(
                        children: [
                          Icon(AppIcons.location, color: AppColors.primary, size: 24.r),
                          const Gap(12),
                          Expanded(
                            child: _selectedAddress != null && _selectedAddress!.id.isNotEmpty
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedAddress!.type.label,
                                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${_selectedAddress!.line1}, ${_selectedAddress!.city}',
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  )
                                : Text(
                                    'No address selected',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                  ),
                          ),
                          const Gap(16),
                          Text(
                            'Change',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),

                    // ── 2. 60-Minute Express Pickup Option ────────────────────
                    Text('Pickup Mode', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    const Gap(12),
                    AppCard.outlined(
                      borderColor: _isExpressPickup ? AppColors.secondary : AppColors.outline,
                      backgroundColor: _isExpressPickup ? AppColors.secondaryLight.withOpacity(0.3) : AppColors.transparent,
                      onTap: () {
                        setState(() {
                          _isExpressPickup = !_isExpressPickup;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 28.r),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '60-Min Express Pickup',
                                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textBlack),
                                ),
                                Text(
                                  'Delivery agent arrives within 1 hour • Add ₹99',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isExpressPickup,
                            activeColor: AppColors.secondary,
                            onChanged: (val) {
                              setState(() {
                                _isExpressPickup = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),

                    // ── 3. Standard Pickup Date & Time Picker ─────────────────
                    if (!_isExpressPickup) ...[
                      Text('Select Pickup Date & Time', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      const Gap(12),
                      Row(
                        children: [
                          _DateChip(
                            label: 'Today',
                            subtitle: today.toDayMonth,
                            isSelected: _selectedDateIdx == 0,
                            onTap: () => setState(() => _selectedDateIdx = 0),
                          ),
                          const Gap(12),
                          _DateChip(
                            label: 'Tomorrow',
                            subtitle: tomorrow.toDayMonth,
                            isSelected: _selectedDateIdx == 1,
                            onTap: () => setState(() => _selectedDateIdx = 1),
                          ),
                        ],
                      ),
                      const Gap(16),

                      Text('60-Minute Slots Available', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
                      const Gap(12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.h,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: _slots.length,
                        itemBuilder: (context, idx) {
                          final slot = _slots[idx];
                          final isChosen = _selectedSlot == slot;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedSlot = slot),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isChosen ? AppColors.primaryContainer : AppColors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.input.r),
                                border: Border.all(
                                  color: isChosen ? AppColors.primary : AppColors.outline.withOpacity(0.5),
                                  width: isChosen ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  slot,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isChosen ? AppColors.primary : AppColors.textSecondary,
                                    fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const Gap(24),
                    ],

                    // ── 4. Checkout Order Items Summary list ──────────────────
                    Text('Order Items Summary', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    const Gap(12),
                    AppCard.outlined(
                      padding: EdgeInsets.all(AppSpacing.md.r),
                      child: Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cartState.cart.items.length,
                            separatorBuilder: (_, __) => const Gap(10),
                            itemBuilder: (context, idx) {
                              final item = cartState.cart.items[idx];
                              final svc = cartState.services.firstWhere(
                                (s) => s.id == item.serviceId,
                                orElse: () => const ServiceModel(id: '', vendorId: '', name: 'Service', description: '', category: ServiceCategory.wash, minWeightKg: 0),
                              );

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity} × ${svc.name}',
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textBlack),
                                    ),
                                  ),
                                  Text(
                                    ((svc.pricePerKg ?? svc.pricePerPiece ?? 0.0) * item.quantity).toCurrencyDecimal,
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (_isExpressPickup) ...[
                            const Gap(10),
                            const AppDivider(),
                            const Gap(10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Express Delivery Agent Surcharge',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textBlack),
                                  ),
                                ),
                                Text(
                                  (99.0).toCurrencyDecimal,
                                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sticky Checkout Summary & Payment Proceed Button ─────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePaddingH.w,
                vertical: AppSpacing.pagePaddingV.h,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.dialog.r),
                ),
                boxShadow: AppElevation.high,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Estimated Price',
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        finalPrice.toCurrencyDecimal,
                        style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Gap(16),
                  AppButton(
                    label: 'Proceed to Payment',
                    onPressed: () => _onProceedToPayment(cartState),
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

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.input.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outline.withOpacity(0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textBlack,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
