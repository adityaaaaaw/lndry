import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../config/env.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/widgets.dart';
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
    this.orderDraftId,
    this.backendSubtotal,
    this.backendDeliveryFee,
    this.backendTaxes,
    this.backendDiscount,
    this.backendTotal,
  });

  final String deliveryAddressId;
  final String pickupAddressId;
  final double finalPrice;
  final String? selectedSlot;
  final bool isExpressPickup;
  final int pickupDateIdx;

  /// Order draft ID from POST /orders/prepare (API mode).
  final String? orderDraftId;

  /// Backend-computed price breakdown (only in API mode).
  final double? backendSubtotal;
  final double? backendDeliveryFee;
  final double? backendTaxes;
  final double? backendDiscount;
  final double? backendTotal;
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

  // ── Backend-computed prices (from POST /orders/prepare) ───────────────────
  bool _backendPricesLoaded = false;
  bool _isPreparingCheckout = false;
  double _backendSubtotal = 0;
  double _backendDeliveryFee = 0;
  double _backendTaxes = 0;
  double _backendDiscount = 0;
  double _backendTotal = 0;
  String? _orderDraftId;
  List<PickupSlot> _pickupSlots = const [];
  bool _isLoadingSlots = false;
  bool _isApiMode = false;

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
    _isApiMode = !Env.useMocksForVisualTestsOnly;
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
            orElse: () => list.isNotEmpty
                ? list.first
                : const AddressModel(
                    id: '',
                    userId: '',
                    line1: '',
                    city: '',
                    state: '',
                    pincode: '',
                    type: AddressType.home),
          );
          _selectedSlot = _isApiMode ? null : _slots.first;
          _isLoading = false;
        });
        if (_isApiMode) {
          unawaited(_loadPickupSlots());
        } else {
          unawaited(_loadBackendPrices());
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddressModal() {
    AppBottomSheet.show<void>(
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
              backgroundColor:
                  isChosen ? AppColors.primaryContainer : AppColors.transparent,
              onTap: () {
                setModalState(() => _selectedAddress = addr);
                setState(() => _selectedAddress = addr);
              },
              child: Row(
                children: [
                  Icon(
                    addr.type == AddressType.home
                        ? AppIcons.homeOutlined
                        : AppIcons.store,
                    color:
                        isChosen ? AppColors.primary : AppColors.textSecondary,
                  ),
                  Gap(AppSpacing.cardGap.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(addr.type.label,
                            style: AppTypography.labelLarge
                                .copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '${addr.line1}, ${addr.city}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isChosen)
                    Icon(AppIcons.success,
                        color: AppColors.primary, size: 18.r),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _checkoutDate() {
    final date = DateTime.now().add(Duration(days: _selectedDateIdx));
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _loadPickupSlots() async {
    if (!_isApiMode) return;

    final vendorId = _cartVendorId(ref.read(cartStateProvider));
    if (vendorId == null) {
      if (mounted) {
        setState(() {
          _pickupSlots = const [];
          _selectedSlot = null;
        });
      }
      return;
    }

    setState(() {
      _isLoadingSlots = true;
      _backendPricesLoaded = false;
      _orderDraftId = null;
    });

    try {
      final slots = await ref.read(customerRepositoryProvider).getPickupSlots(
            vendorId: vendorId,
            date: _checkoutDate(),
          );
      if (!mounted) return;
      final activeSlots = slots
          .where((slot) => slot.isActive && slot.remainingCapacity > 0)
          .toList();
      setState(() {
        _pickupSlots = activeSlots;
        if (activeSlots.isEmpty) {
          _selectedSlot = null;
        } else {
          final currentStillAvailable =
              activeSlots.any((slot) => slot.id == _selectedSlot);
          _selectedSlot =
              currentStillAvailable ? _selectedSlot : activeSlots.first.id;
        }
        _isLoadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pickupSlots = const [];
        _selectedSlot = null;
        _isLoadingSlots = false;
      });
    }
  }

  /// Fetch backend-computed prices from POST /orders/prepare.
  Future<void> _loadBackendPrices() async {
    if (_isApiMode) {
      setState(() => _backendPricesLoaded = false);
      return;
    }

    final repo = ref.read(customerRepositoryProvider);
    try {
      final draft = await repo.prepareOrder(
        quoteId: 'quote_mock',
        addressId: _selectedAddress?.id ?? 'addr_1',
        slotId: 'slot_mock',
      );
      if (mounted) {
        setState(() {
          if (draft.orderDraftId.isNotEmpty) {
            _orderDraftId = draft.orderDraftId;
            _backendTotal = draft.payableAmountPaise / 100.0;
            _backendSubtotal =
                ((draft.snapshot?['subtotal'] as num?)?.toDouble() ?? 0) /
                    100.0;
            _backendDeliveryFee =
                ((draft.snapshot?['delivery_fee'] as num?)?.toDouble() ?? 0) /
                    100.0;
            _backendTaxes =
                ((draft.snapshot?['tax'] as num?)?.toDouble() ?? 0) / 100.0;
            _backendPricesLoaded = true;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _backendPricesLoaded = false);
    }
  }

  Future<void> _prepareApiCheckout(CartState cart) async {
    if (_isPreparingCheckout) return;

    final address = _selectedAddress;
    final slotId = _selectedSlot;
    if (address == null || address.id.isEmpty) {
      AppSnackBar.showError(context, 'Please select a validated address.');
      return;
    }
    if (slotId == null || slotId.isEmpty) {
      AppSnackBar.showError(context, 'Please select an available pickup slot.');
      return;
    }

    final quoteInput = _buildQuoteInput(cart);
    if (quoteInput == null) {
      AppSnackBar.showError(
        context,
        'Live quote cannot be created for this cart. Please select one service category from one vendor.',
      );
      return;
    }

    setState(() => _isPreparingCheckout = true);

    try {
      final repo = ref.read(customerRepositoryProvider);
      final quote = await repo.createQuote(
        vendorId: quoteInput.vendorId,
        vendorServiceId: quoteInput.vendorServiceId,
        garmentLines: quoteInput.lines,
      );
      if (quote.quoteId.isEmpty) {
        throw const FormatException('Quote creation failed.');
      }

      final hold = await repo.holdSlot(
        vendorId: quoteInput.vendorId,
        slotId: slotId,
        date: _checkoutDate(),
        quoteId: quote.quoteId,
      );
      if (hold.holdId.isEmpty) {
        throw const FormatException('Pickup slot hold failed.');
      }

      final draft = await repo.prepareOrder(
        quoteId: quote.quoteId,
        addressId: address.id,
        slotId: slotId,
      );
      if (draft.orderDraftId.isEmpty || draft.payableAmountPaise <= 0) {
        throw const FormatException('Order draft is unavailable.');
      }

      final amounts = _CheckoutAmounts.fromDraft(draft);
      if (!mounted) return;
      setState(() {
        _orderDraftId = draft.orderDraftId;
        _backendSubtotal = amounts.subtotal;
        _backendDeliveryFee = amounts.deliveryFee;
        _backendTaxes = amounts.taxes;
        _backendDiscount = amounts.discount;
        _backendTotal = amounts.total;
        _backendPricesLoaded = true;
        _isPreparingCheckout = false;
      });

      _goToPayment(
        finalPrice: amounts.total,
        backendSubtotal: amounts.subtotal,
        backendDeliveryFee: amounts.deliveryFee,
        backendTaxes: amounts.taxes,
        backendDiscount: amounts.discount,
        backendTotal: amounts.total,
        orderDraftId: draft.orderDraftId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPreparingCheckout = false);
      AppSnackBar.showError(
        context,
        'Live checkout could not be prepared. Please retry.',
      );
    }
  }

  _QuoteInput? _buildQuoteInput(CartState cart) {
    if (cart.cart.items.isEmpty || cart.services.isEmpty) return null;

    String? vendorId;
    String? vendorServiceId;
    final lines = <QuoteGarmentLine>[];

    for (final item in cart.cart.items) {
      final service = cart.services.firstWhere(
        (svc) => svc.id == item.serviceId,
        orElse: () => const ServiceModel(
          id: '',
          vendorId: '',
          name: '',
          description: '',
          category: ServiceCategory.wash,
          minWeightKg: 0,
        ),
      );
      if (service.id.isEmpty || item.quantity <= 0) return null;

      final serviceVendorId = service.vendorId;
      final backendVendorServiceId =
          _tagValue(service.tags, 'vendor_service_id') ?? service.id;
      final garmentTypeId =
          _tagValue(service.tags, 'garment_type_id') ?? service.id;

      vendorId ??= serviceVendorId;
      vendorServiceId ??= backendVendorServiceId;
      if (vendorId != serviceVendorId ||
          vendorServiceId != backendVendorServiceId ||
          garmentTypeId.isEmpty) {
        return null;
      }

      lines.add(QuoteGarmentLine(
        garmentTypeId: garmentTypeId,
        quantity: item.quantity,
      ));
    }

    if (vendorId == null || vendorServiceId == null || lines.isEmpty) {
      return null;
    }
    return _QuoteInput(
      vendorId: vendorId,
      vendorServiceId: vendorServiceId,
      lines: lines,
    );
  }

  String? _cartVendorId(CartState cart) {
    final vendors = cart.services
        .where((svc) => cart.cart.items.any((item) => item.serviceId == svc.id))
        .map((svc) => svc.vendorId)
        .where((id) => id.isNotEmpty)
        .toSet();
    return vendors.length == 1 ? vendors.first : null;
  }

  String? _tagValue(List<String> tags, String key) {
    final prefix = '$key:';
    for (final tag in tags) {
      if (tag.startsWith(prefix)) return tag.substring(prefix.length);
    }
    return null;
  }

  Future<void> _onProceedToPayment(CartState cart) async {
    if (_selectedAddress == null || _selectedAddress!.id.isEmpty) {
      AppSnackBar.showError(context, 'Please select a delivery address.');
      return;
    }

    if (_selectedSlot == null && !_isExpressPickup) {
      AppSnackBar.showError(context, 'Please select a pickup time slot.');
      return;
    }

    if (_isApiMode) {
      await _prepareApiCheckout(cart);
      return;
    }

    final price = _backendPricesLoaded
        ? _backendTotal
        : cart.total + (_isExpressPickup ? 99.0 : 0.0);

    final String? orderDraftId = _backendPricesLoaded ? _orderDraftId : null;
    final double? backendSubtotal =
        _backendPricesLoaded ? _backendSubtotal : null;
    final double? backendDeliveryFee =
        _backendPricesLoaded ? _backendDeliveryFee : null;
    final double? backendTaxes = _backendPricesLoaded ? _backendTaxes : null;
    final double? backendTotal = _backendPricesLoaded ? _backendTotal : null;

    _goToPayment(
      finalPrice: price,
      backendSubtotal: backendSubtotal,
      backendDeliveryFee: backendDeliveryFee,
      backendTaxes: backendTaxes,
      backendDiscount: _backendPricesLoaded ? _backendDiscount : null,
      backendTotal: backendTotal,
      orderDraftId: orderDraftId,
    );
  }

  void _goToPayment({
    required double finalPrice,
    required double? backendSubtotal,
    required double? backendDeliveryFee,
    required double? backendTaxes,
    required double? backendDiscount,
    required double? backendTotal,
    required String? orderDraftId,
  }) {
    if (!context.mounted) return;
    context.push(
      AppRoutes.payment,
      extra: CheckoutSession(
        deliveryAddressId: _selectedAddress!.id,
        pickupAddressId: _selectedAddress!.id,
        finalPrice: finalPrice,
        selectedSlot: _selectedSlotLabel(),
        isExpressPickup: _isExpressPickup,
        pickupDateIdx: _selectedDateIdx,
        orderDraftId: orderDraftId,
        backendSubtotal: backendSubtotal,
        backendDeliveryFee: backendDeliveryFee,
        backendTaxes: backendTaxes,
        backendDiscount: backendDiscount,
        backendTotal: backendTotal,
      ),
    );
  }

  String? _selectedSlotLabel() {
    if (_isExpressPickup && !_isApiMode) return 'Express (within 60 min)';
    if (_isApiMode) {
      final slot = _pickupSlots.where((slot) => slot.id == _selectedSlot);
      if (slot.isEmpty) return null;
      final selected = slot.first;
      return selected.label ?? '${selected.startTime} - ${selected.endTime}';
    }
    return _selectedSlot;
  }

  // ── Coupon state ───────────────────────────────────────────────────────────

  final _couponController = TextEditingController();
  final _couponFocusNode = FocusNode();
  bool _couponApplied = false;
  bool _couponFocused = false;

  final _notesController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    _couponFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cartState = ref.watch(cartStateProvider);

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
        body: const AppLoadingPage(message: 'Preparing checkout summary...'),
      );
    }

    if (cartState.cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Checkout',
              style: AppTypography.titleLarge
                  .copyWith(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(AppIcons.back),
            onPressed: () => context.pop(),
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        body: AppEmptyState(
          icon: AppIcons.cartOutlined,
          title: 'Nothing to checkout',
          subtitle:
              'Add laundry services from a vendor before scheduling pickup.',
          actionLabel: 'Browse vendors',
          onAction: () => context.go(AppRoutes.vendorListing),
        ),
      );
    }

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final finalPrice = _isApiMode
        ? _backendTotal
        : cartState.total + (_isExpressPickup ? 99.0 : 0.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Checkout',
            style:
                AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePaddingH.w,
                  AppSpacing.sm.h,
                  AppSpacing.pagePaddingH.w,
                  AppSpacing.sm.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Address Picker Section ──────────────────────────────
                    _sectionHeader('Delivery Address'),
                    Gap(AppSpacing.cardGap.h),
                    AppCard.outlined(
                      onTap: _showAddressModal,
                      padding: EdgeInsets.all(AppSpacing.md.r),
                      child: Row(
                        children: [
                          Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md.r),
                            ),
                            child: Icon(AppIcons.location,
                                color: AppColors.primary, size: 20.r),
                          ),
                          Gap(AppSpacing.md.w),
                          Expanded(
                            child: _selectedAddress != null &&
                                    _selectedAddress!.id.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedAddress!.type.label,
                                        style: AppTypography.titleSmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Gap(AppSpacing.xs.h),
                                      Text(
                                        '${_selectedAddress!.line1}, ${_selectedAddress!.city}',
                                        style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  )
                                : Text(
                                    'No address selected',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: AppColors.textMuted),
                                  ),
                          ),
                          Gap(AppSpacing.sm.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm.w,
                              vertical: AppSpacing.xs.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.tag.r),
                            ),
                            child: Text(
                              'Change',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(AppSpacing.sectionGap.h),

                    // ── 2. 60-Minute Express Pickup Option ────────────────────
                    _sectionHeader('Pickup Mode'),
                    Gap(AppSpacing.cardGap.h),
                    AppCard.outlined(
                      borderColor: _isExpressPickup
                          ? AppColors.secondary
                          : AppColors.outlineVariant,
                      backgroundColor: _isExpressPickup
                          ? AppColors.secondaryLight.withValues(alpha: 0.3)
                          : AppColors.transparent,
                      onTap: () {
                        if (_isApiMode) {
                          AppSnackBar.showError(
                            context,
                            'Express pickup requires backend express slots and is unavailable for live checkout.',
                          );
                          return;
                        }
                        setState(() {
                          _isExpressPickup = !_isExpressPickup;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 44.r,
                            height: 44.r,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md.r),
                            ),
                            child: Icon(
                              Icons.flash_on_rounded,
                              color: AppColors.secondary,
                              size: 24.r,
                            ),
                          ),
                          Gap(AppSpacing.md.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '60-Min Express Pickup',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Gap(AppSpacing.xs.h),
                                Text(
                                  _isApiMode
                                      ? 'Available when backend express slots are returned'
                                      : 'Delivery agent arrives within 1 hour',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isExpressPickup,
                            activeThumbColor: AppColors.secondary,
                            onChanged: _isApiMode
                                ? null
                                : (val) {
                                    setState(() {
                                      _isExpressPickup = val;
                                    });
                                    unawaited(_loadBackendPrices());
                                  },
                          ),
                        ],
                      ),
                    ),
                    Gap(AppSpacing.sectionGap.h),

                    // ── 3. Standard Pickup Date & Time Picker ─────────────────
                    if (!_isExpressPickup) ...[
                      _sectionHeader('Select Pickup Date & Time'),
                      Gap(AppSpacing.cardGap.h),
                      Row(
                        children: [
                          _DateChip(
                            label: 'Today',
                            subtitle: today.toDayMonth,
                            isSelected: _selectedDateIdx == 0,
                            onTap: () {
                              setState(() => _selectedDateIdx = 0);
                              unawaited(_loadPickupSlots());
                            },
                          ),
                          Gap(AppSpacing.cardGap.w),
                          _DateChip(
                            label: 'Tomorrow',
                            subtitle: tomorrow.toDayMonth,
                            isSelected: _selectedDateIdx == 1,
                            onTap: () {
                              setState(() => _selectedDateIdx = 1);
                              unawaited(_loadPickupSlots());
                            },
                          ),
                        ],
                      ),
                      Gap(AppSpacing.md.h),
                      Text(
                          _isApiMode
                              ? 'Available Slots'
                              : 'Available Slots',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.onSurfaceVariant)),
                      Gap(AppSpacing.cardGap.h),
                      if (_isApiMode && _isLoadingSlots)
                        const AppLoadingPage(
                            message: 'Checking pickup slots...')
                      else if (_isApiMode && _pickupSlots.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl.h),
                          child: Center(
                            child: Text(
                              'No slots available for this date.\nPlease try another date.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.w,
                            mainAxisSpacing: 10.h,
                            childAspectRatio: 2.8,
                          ),
                          itemCount:
                              _isApiMode ? _pickupSlots.length : _slots.length,
                          itemBuilder: (context, idx) {
                            final slot =
                                _isApiMode ? _pickupSlots[idx].id : _slots[idx];
                            final slotLabel = _isApiMode
                                ? (_pickupSlots[idx].label ??
                                    '${_pickupSlots[idx].startTime} - ${_pickupSlots[idx].endTime}')
                                : slot;
                            final isChosen = _selectedSlot == slot;

                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedSlot = slot;
                                _backendPricesLoaded = false;
                                _orderDraftId = null;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isChosen
                                      ? AppColors.primaryContainer
                                      : isDark
                                          ? AppColors.darkSurfaceContainer
                                          : AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md.r),
                                  border: Border.all(
                                    color: isChosen
                                        ? AppColors.primary
                                        : isDark
                                            ? AppColors.darkOutlineVariant
                                            : AppColors.outlineVariant,
                                    width: isChosen ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    slotLabel,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: isChosen
                                          ? AppColors.primary
                                          : isDark
                                              ? AppColors.darkTextBody
                                              : AppColors.onSurfaceVariant,
                                      fontWeight: isChosen
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      Gap(AppSpacing.sectionGap.h),
                    ],

                    // ── 4. Order Items Summary ─────────────────────────────────
                    _sectionHeader('Order Items Summary'),
                    Gap(AppSpacing.cardGap.h),
                    AppCard.outlined(
                      padding: EdgeInsets.all(AppSpacing.md.r),
                      child: Column(
                        children: [
                          ...cartState.cart.items.map((item) {
                            final svc = cartState.services.firstWhere(
                              (s) => s.id == item.serviceId,
                              orElse: () => const ServiceModel(
                                id: '',
                                vendorId: '',
                                name: 'Service',
                                description: '',
                                category: ServiceCategory.wash,
                                minWeightKg: 0,
                              ),
                            );

                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity} × ${svc.name}',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextBody
                                            : AppColors.onSurface,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Gap(AppSpacing.md.w),
                                  Text(
                                    _isApiMode
                                        ? 'Backend priced'
                                        : ((svc.pricePerKg ??
                                                    svc.pricePerPiece ??
                                                    0.0) *
                                                item.quantity)
                                            .toCurrencyDecimal,
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _isApiMode
                                          ? AppColors.onSurfaceVariant
                                          : isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (_isExpressPickup && !_isApiMode) ...[
                            Divider(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : AppColors.outlineVariant,
                              thickness: 1,
                              height: 1,
                            ),
                            Gap(AppSpacing.sm.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Express Delivery Agent Surcharge',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextBody
                                          : AppColors.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Gap(AppSpacing.md.w),
                                Text(
                                  (99.0).toCurrencyDecimal,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Gap(AppSpacing.sectionGap.h),

                    // ── 5. Coupon Section ──────────────────────────────────────
                    _sectionHeader('Coupon Code'),
                    Gap(AppSpacing.cardGap.h),
                    _CouponSection(
                      controller: _couponController,
                      focusNode: _couponFocusNode,
                      isApplied: _couponApplied,
                      isFocused: _couponFocused,
                      onFocusChange: (v) =>
                          setState(() => _couponFocused = v),
                      onApply: () {
                        if (_couponController.text.trim().isNotEmpty) {
                          setState(() => _couponApplied = true);
                          context.showSuccess('Coupon applied!');
                        }
                      },
                      onRemove: () {
                        setState(() {
                          _couponApplied = false;
                          _couponController.clear();
                        });
                      },
                    ),
                    Gap(AppSpacing.sectionGap.h),

                    // ── 6. Notes / Instructions ────────────────────────────────
                    _sectionHeader('Notes & Instructions'),
                    Gap(AppSpacing.cardGap.h),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md.r),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.outlineVariant,
                        ),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add delivery instructions...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(AppSpacing.md.r),
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Gap(AppSpacing.sectionGap.h),
                  ],
                ),
              ),
            ),

            // ── Sticky Checkout Summary & Payment CTA ─────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePaddingH.w,
                AppSpacing.md.h,
                AppSpacing.pagePaddingH.w,
                MediaQuery.paddingOf(context).bottom + AppSpacing.md.h,
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
                  // ── Price breakdown ─────────────────────────────────────────
                  if (_backendPricesLoaded) ...[
                    _PriceRow(
                      label: 'Subtotal',
                      amount: _backendSubtotal,
                      isDark: isDark,
                    ),
                    _PriceRow(
                      label: 'Delivery Fee',
                      amount: _backendDeliveryFee,
                      isDark: isDark,
                    ),
                    _PriceRow(
                      label: 'Taxes & Charges',
                      amount: _backendTaxes,
                      isDark: isDark,
                    ),
                    if (_backendDiscount > 0)
                      _PriceRow(
                        label: 'Discount',
                        amount: -_backendDiscount,
                        isDark: isDark,
                      ),
                    Gap(AppSpacing.sm.h),
                    Divider(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.outlineVariant,
                      thickness: 1,
                      height: 1,
                    ),
                    Gap(AppSpacing.sm.h),
                    _PriceRow(
                      label: 'Total Payable',
                      amount: _backendTotal,
                      bold: true,
                      isDark: isDark,
                    ),
                  ] else if (_isApiMode)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                      child: Text(
                        'Live payable amount will be calculated by the backend before payment.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total Estimated Price',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Gap(AppSpacing.md.w),
                        Text(
                          finalPrice.toCurrencyDecimal,
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Gap(AppSpacing.md.h),
                  SizedBox(
                    height: 52.h,
                    child: AppButton(
                      label: _isPreparingCheckout
                          ? 'Preparing Checkout...'
                          : 'Proceed to Payment',
                      onPressed: _isPreparingCheckout
                          ? null
                          : () => _onProceedToPayment(cartState),
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

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.titleLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: context.isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COUPON SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _CouponSection extends StatefulWidget {
  const _CouponSection({
    required this.controller,
    required this.focusNode,
    required this.isApplied,
    required this.isFocused,
    required this.onFocusChange,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isApplied;
  final bool isFocused;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) widget.onFocusChange(widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (widget.isApplied) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.sm.h,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.successContainer,
          borderRadius: BorderRadius.circular(AppRadius.md.r),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(AppIcons.coupon, size: 18.r, color: AppColors.success),
            Gap(AppSpacing.sm.w),
            Expanded(
              child: Text(
                'Coupon "${widget.controller.text.trim().toUpperCase()}" applied!',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 40.r,
              height: 40.r,
              child: IconButton(
                icon: Icon(AppIcons.close, size: 16.r, color: AppColors.success),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: widget.onRemove,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.sm.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
        border: Border.all(
          color: widget.isFocused
              ? AppColors.primary
              : isDark
                  ? AppColors.darkOutlineVariant
                  : AppColors.outlineVariant,
          width: widget.isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm.w),
            child: Icon(
              AppIcons.coupon,
              size: 20.r,
              color: widget.isFocused
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
          ),
          Gap(AppSpacing.sm.w),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              decoration: InputDecoration(
                hintText: 'Enter coupon code',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (widget.controller.text.trim().isNotEmpty) {
                  widget.onApply();
                }
              },
            ),
          ),
          SizedBox(
            height: 44.h,
            child: AppButton(
              label: 'Apply',
              width: 72.w,
              height: 44.h,
              onPressed: widget.controller.text.trim().isNotEmpty
                  ? widget.onApply
                  : null,
              isDisabled: widget.controller.text.trim().isEmpty,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
              textStyle: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRICE ROW
// ═══════════════════════════════════════════════════════════════════════════

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    required this.isDark,
    this.bold = false,
  });

  final String label;
  final double amount;
  final bool bold;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (bold ? AppTypography.titleSmall : AppTypography.bodyMedium)
                  .copyWith(
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                color: bold
                    ? AppColors.primary
                    : isDark
                        ? AppColors.darkTextBody
                        : AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Gap(AppSpacing.md.w),
          Text(
            amount.toCurrencyDecimal,
            style: (bold
                    ? AppTypography.titleMedium
                    : AppTypography.bodyMedium)
                .copyWith(
              fontWeight: FontWeight.w600,
              color: bold
                  ? AppColors.primary
                  : isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUOTE INPUT
// ═══════════════════════════════════════════════════════════════════════════

class _QuoteInput {
  const _QuoteInput({
    required this.vendorId,
    required this.vendorServiceId,
    required this.lines,
  });

  final String vendorId;
  final String vendorServiceId;
  final List<QuoteGarmentLine> lines;
}

// ═══════════════════════════════════════════════════════════════════════════
// CHECKOUT AMOUNTS
// ═══════════════════════════════════════════════════════════════════════════

class _CheckoutAmounts {
  const _CheckoutAmounts({
    required this.subtotal,
    required this.deliveryFee,
    required this.taxes,
    required this.discount,
    required this.total,
  });

  factory _CheckoutAmounts.fromDraft(OrderDraftResult draft) {
    final snapshot = draft.snapshot ?? const <String, dynamic>{};
    final feeBreakdown =
        snapshot['fee_breakdown'] as Map<String, dynamic>? ?? const {};
    final quote = snapshot['quote'] as Map<String, dynamic>? ?? const {};

    final subtotalPaise = _readPaise(
      feeBreakdown,
      const ['subtotal_paise', 'subtotal'],
      fallback: _readPaise(quote, const ['estimate_paise']),
    );
    final deliveryPaise =
        _readPaise(feeBreakdown, const ['delivery_fee_paise', 'delivery_fee']);
    final taxPaise =
        _readPaise(feeBreakdown, const ['tax_paise', 'tax', 'tax_paise_total']);
    final discountPaise = _readPaise(
      feeBreakdown,
      const ['discount_paise', 'discount', 'discount_paise_total'],
    );
    final totalPaise = _readPaise(
      feeBreakdown,
      const ['total_payable_paise', 'payable_amount_paise', 'total'],
      fallback: draft.payableAmountPaise,
    );

    return _CheckoutAmounts(
      subtotal: subtotalPaise / 100.0,
      deliveryFee: deliveryPaise / 100.0,
      taxes: taxPaise / 100.0,
      discount: discountPaise / 100.0,
      total: totalPaise / 100.0,
    );
  }

  final double subtotal;
  final double deliveryFee;
  final double taxes;
  final double discount;
  final double total;

  static int _readPaise(
    Map<String, dynamic> json,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toInt();
    }
    return fallback;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATE CHIP
// ═══════════════════════════════════════════════════════════════════════════

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
    final isDark = context.isDark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainer
                : isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Gap(AppSpacing.xs.h),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
