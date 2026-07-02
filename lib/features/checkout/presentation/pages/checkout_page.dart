import 'dart:async';

import '../../../../config/env.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/widgets/shared_widgets.dart';
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
                  const Gap(12),
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
  /// In mock mode, uses 'quote_mock' placeholder (acceptable).
  /// In API mode, skips because no real quoteId is available.
  Future<void> _loadBackendPrices() async {
    if (_isApiMode) {
      // No quote endpoint exists yet — can't call prepareOrder in API mode.
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

    // Use backend-computed prices if available (mock mode), else local fallback.
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
          title: Text('Checkout',
              style: AppTypography.titleLarge
                  .copyWith(fontWeight: FontWeight.bold)),
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
                    Text('Delivery Address',
                        style: AppTypography.titleLarge
                            .copyWith(fontWeight: FontWeight.bold)),
                    const Gap(12),
                    AppCard.outlined(
                      onTap: _showAddressModal,
                      padding: EdgeInsets.all(AppSpacing.md.r),
                      child: Row(
                        children: [
                          Icon(AppIcons.location,
                              color: AppColors.primary, size: 24.r),
                          const Gap(12),
                          Expanded(
                            child: _selectedAddress != null &&
                                    _selectedAddress!.id.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedAddress!.type.label,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${_selectedAddress!.line1}, ${_selectedAddress!.city}',
                                        style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary),
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
                          const Gap(16),
                          Text(
                            'Change',
                            style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),

                    // ── 2. 60-Minute Express Pickup Option ────────────────────
                    Text('Pickup Mode',
                        style: AppTypography.titleLarge
                            .copyWith(fontWeight: FontWeight.bold)),
                    const Gap(12),
                    AppCard.outlined(
                      borderColor: _isExpressPickup
                          ? AppColors.secondary
                          : AppColors.outline,
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
                          Icon(Icons.flash_on_rounded,
                              color: AppColors.secondary, size: 28.r),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '60-Min Express Pickup',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textBlack),
                                ),
                                Text(
                                  _isApiMode
                                      ? 'Available when backend express slots are returned'
                                      : 'Delivery agent arrives within 1 hour',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.textSecondary),
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
                    const Gap(24),

                    // ── 3. Standard Pickup Date & Time Picker ─────────────────
                    if (!_isExpressPickup) ...[
                      Text('Select Pickup Date & Time',
                          style: AppTypography.titleLarge
                              .copyWith(fontWeight: FontWeight.bold)),
                      const Gap(12),
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
                          const Gap(12),
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
                      const Gap(16),
                      Text(
                          _isApiMode
                              ? 'Backend Slots Available'
                              : '60-Minute Slots Available',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.textSecondary)),
                      const Gap(12),
                      if (_isApiMode && _isLoadingSlots)
                        const AppLoadingPage(
                            message: 'Checking pickup slots...')
                      else if (_isApiMode && _pickupSlots.isEmpty)
                        AppEmptyState(
                          icon: AppIcons.clock,
                          title: 'No slots available',
                          subtitle:
                              'Please try another date or vendor before checkout.',
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isChosen
                                      ? AppColors.primaryContainer
                                      : AppColors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.input.r),
                                  border: Border.all(
                                    color: isChosen
                                        ? AppColors.primary
                                        : AppColors.outline
                                            .withValues(alpha: 0.5),
                                    width: isChosen ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    slotLabel,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isChosen
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      fontWeight: isChosen
                                          ? FontWeight.bold
                                          : FontWeight.normal,
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
                    Text('Order Items Summary',
                        style: AppTypography.titleLarge
                            .copyWith(fontWeight: FontWeight.bold)),
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
                                orElse: () => const ServiceModel(
                                    id: '',
                                    vendorId: '',
                                    name: 'Service',
                                    description: '',
                                    category: ServiceCategory.wash,
                                    minWeightKg: 0),
                              );

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity} × ${svc.name}',
                                      style: AppTypography.bodyMedium
                                          .copyWith(color: AppColors.textBlack),
                                    ),
                                  ),
                                  Text(
                                    _isApiMode
                                        ? 'Backend priced'
                                        : ((svc.pricePerKg ??
                                                    svc.pricePerPiece ??
                                                    0.0) *
                                                item.quantity)
                                            .toCurrencyDecimal,
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _isApiMode
                                          ? AppColors.textMuted
                                          : null,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (_isExpressPickup && !_isApiMode) ...[
                            const Gap(10),
                            const AppDivider(),
                            const Gap(10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Express Delivery Agent Surcharge',
                                    style: AppTypography.bodyMedium
                                        .copyWith(color: AppColors.textBlack),
                                  ),
                                ),
                                Text(
                                  (99.0).toCurrencyDecimal,
                                  style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary),
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
                  // ── Backend-computed price breakdown (mock mode) ────────────
                  if (_backendPricesLoaded) ...[
                    _PriceRow(label: 'Subtotal', amount: _backendSubtotal),
                    _PriceRow(
                        label: 'Delivery Fee', amount: _backendDeliveryFee),
                    _PriceRow(label: 'Taxes & Charges', amount: _backendTaxes),
                    if (_backendDiscount > 0)
                      _PriceRow(
                        label: 'Discount',
                        amount: -_backendDiscount,
                        isPrimary: true,
                      ),
                    const AppDivider(),
                    const Gap(6),
                    _PriceRow(
                      label: 'Total Payable',
                      amount: _backendTotal,
                      bold: true,
                      isPrimary: true,
                    ),
                  ] else if (_isApiMode)
                    Text(
                      'Live payable amount will be calculated by the backend before payment.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    // ── Fallback local calculation ────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Estimated Price',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              finalPrice.toCurrencyDecimal,
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const Gap(16),
                  AppButton(
                    label: _isPreparingCheckout
                        ? 'Preparing Checkout...'
                        : 'Proceed to Payment',
                    onPressed: _isPreparingCheckout
                        ? null
                        : () => _onProceedToPayment(cartState),
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

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.bold = false,
    this.isPrimary = false,
  });

  final String label;
  final double amount;
  final bool bold;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: isPrimary ? AppColors.primary : AppColors.textBlack,
            ),
          ),
          Text(
            amount.toCurrencyDecimal,
            style: (bold ? AppTypography.titleMedium : AppTypography.bodyMedium)
                .copyWith(
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppColors.primary : AppColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }
}

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

class _CheckoutAmounts {
  const _CheckoutAmounts({
    required this.subtotal,
    required this.deliveryFee,
    required this.taxes,
    required this.discount,
    required this.total,
  });

  final double subtotal;
  final double deliveryFee;
  final double taxes;
  final double discount;
  final double total;

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
            color:
                isSelected ? AppColors.primaryContainer : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.input.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.outline.withValues(alpha: 0.5),
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
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
