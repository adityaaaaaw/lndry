import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../config/env.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/repositories.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  late final Razorpay _razorpay;
  bool _isProcessing = false;
  bool _isVerifyingPayment = false;
  bool _paymentFinalized = false;
  bool _verificationRetryPending = false;
  String _selectedMethod = 'upi'; // upi, card, wallet
  PaymentOrderResult? _pendingPaymentOrder;
  CheckoutSession? _pendingSession;
  PaymentSuccessResponse? _pendingSuccessResponse;
  final Set<String> _handledGatewayEvents = <String>{};

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _processPayment(CartState cart) async {
    if (_isProcessing || _isVerifyingPayment || _paymentFinalized) return;

    if (_verificationRetryPending && _pendingSuccessResponse != null) {
      await _verifyAndPlaceOrder(_pendingSuccessResponse!);
      return;
    }

    final session = GoRouterState.of(context).extra as CheckoutSession?;

    if (cart.cart.isEmpty) {
      if (mounted) {
        AppSnackBar.showError(context, 'Your cart is empty.');
        context.go(AppRoutes.vendorListing);
      }
      return;
    }

    final repo = ref.read(customerRepositoryProvider);

    try {
      final isMockMode = Env.useMocksForVisualTestsOnly;

      setState(() => _isProcessing = true);

      if (!isMockMode) {
        if (session?.orderDraftId == null || session!.orderDraftId!.isEmpty) {
          if (mounted) {
            setState(() => _isProcessing = false);
            AppSnackBar.showError(
              context,
              'Checkout quote is unavailable. Please retry checkout.',
            );
          }
          return;
        }

        final paymentResult = await repo.createPaymentOrder(
          orderDraftId: session.orderDraftId,
        );
        final gatewayKey = _gatewayKey(paymentResult);

        if (gatewayKey.isEmpty) {
          if (mounted) {
            setState(() => _isProcessing = false);
            AppSnackBar.showError(
              context,
              'Payment gateway is not configured for this build.',
            );
          }
          return;
        }

        if (paymentResult.razorpayOrderId.isEmpty) {
          if (mounted) {
            setState(() => _isProcessing = false);
            AppSnackBar.showError(
              context,
              'Payment order is unavailable. Please retry checkout.',
            );
          }
          return;
        }

        _pendingPaymentOrder = paymentResult;
        _pendingSession = session;
        _pendingSuccessResponse = null;
        _verificationRetryPending = false;
        _handledGatewayEvents.clear();

        _razorpay.open(_buildCheckoutOptions(
          paymentResult: paymentResult,
          gatewayKey: gatewayKey,
          amountDue: session.finalPrice,
        ));
        return;
      }

      // Development mock mode only: simulate a Razorpay transaction.
      final paymentResult = await repo.createPaymentOrder(
        orderDraftId: session?.orderDraftId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 1800));

      // Development mock mode only: verify using mock repository semantics.
      final verifyResult = await repo.verifyPayment(
        razorpayOrderId: paymentResult.razorpayOrderId,
        razorpayPaymentId: 'rzp_pay_${DateTime.now().millisecondsSinceEpoch}',
        razorpaySignature: 'mock_signature',
        orderDraftId: session?.orderDraftId,
      );

      if (!verifyResult.success) {
        if (mounted) {
          setState(() => _isProcessing = false);
          AppSnackBar.showError(context, 'Payment verification failed.');
        }
        return;
      }

      await _placeOrderAfterVerifiedPayment(session: session, cart: cart);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppSnackBar.showError(context, 'Transaction failed: ${e.toString()}');
      }
    }
  }

  Map<String, dynamic> _buildCheckoutOptions({
    required PaymentOrderResult paymentResult,
    required String gatewayKey,
    required double amountDue,
  }) {
    final user = ref.read(currentUserProvider);
    final amountPaise =
        paymentResult.amount > 0 ? (paymentResult.amount * 100).round() : 0;

    return <String, dynamic>{
      'key': gatewayKey,
      'order_id': paymentResult.razorpayOrderId,
      if (amountPaise > 0) 'amount': amountPaise,
      'currency': paymentResult.currency,
      'name': 'LNDRY',
      'description': 'Laundry order payment',
      'timeout': 300,
      'prefill': <String, dynamic>{
        if (user?.name.isNotEmpty == true) 'name': user!.name,
        if (user?.phone.isNotEmpty == true) 'contact': user!.phone,
        if (user?.email?.isNotEmpty == true) 'email': user!.email,
      },
      'notes': <String, dynamic>{
        if (_pendingSession?.orderDraftId?.isNotEmpty == true)
          'orderDraftId': _pendingSession!.orderDraftId,
        'paymentId': paymentResult.paymentId,
        'amountDue': amountDue.toStringAsFixed(2),
      },
    };
  }

  String _gatewayKey(PaymentOrderResult result) {
    final backendKey = result.keyId;
    if (backendKey != null && backendKey.isNotEmpty) return backendKey;
    return Env.razorpayKey;
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId;
    final eventKey = paymentId ?? response.orderId ?? '';
    if (eventKey.isNotEmpty && !_handledGatewayEvents.add(eventKey)) return;

    _pendingSuccessResponse = response;
    await _verifyAndPlaceOrder(response);
  }

  Future<void> _verifyAndPlaceOrder(PaymentSuccessResponse response) async {
    if (_isVerifyingPayment || _paymentFinalized) return;

    final pendingOrder = _pendingPaymentOrder;
    final session = _pendingSession;
    final razorpayOrderId = response.orderId?.isNotEmpty == true
        ? response.orderId!
        : pendingOrder?.razorpayOrderId;
    final razorpayPaymentId = response.paymentId;
    final razorpaySignature = response.signature;

    if (pendingOrder == null ||
        session?.orderDraftId == null ||
        razorpayOrderId == null ||
        razorpayOrderId.isEmpty ||
        razorpayPaymentId == null ||
        razorpayPaymentId.isEmpty ||
        razorpaySignature == null ||
        razorpaySignature.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isVerifyingPayment = false;
      });
      AppSnackBar.showError(
        context,
        'Payment response was incomplete. Please contact support.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _isVerifyingPayment = true;
      _verificationRetryPending = false;
    });

    try {
      final verifyResult =
          await ref.read(customerRepositoryProvider).verifyPayment(
                razorpayOrderId: razorpayOrderId,
                razorpayPaymentId: razorpayPaymentId,
                razorpaySignature: razorpaySignature,
                orderDraftId: session!.orderDraftId,
              );

      if (!verifyResult.success) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _isVerifyingPayment = false;
        });
        AppSnackBar.showError(context, 'Payment verification failed.');
        return;
      }

      _paymentFinalized = true;
      await _placeOrderAfterVerifiedPayment(session: session, cart: null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isVerifyingPayment = false;
        _verificationRetryPending = true;
      });
      AppSnackBar.showError(
        context,
        'Payment captured, but verification could not be completed. Tap Verify Payment to retry.',
      );
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    if (_paymentFinalized) return;

    final isCancel = response.code == 2 ||
        (response.message ?? '').toLowerCase().contains('cancel');

    _pendingPaymentOrder = null;
    _pendingSession = null;
    _pendingSuccessResponse = null;
    _handledGatewayEvents.clear();

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isVerifyingPayment = false;
      _verificationRetryPending = false;
    });

    AppSnackBar.showError(
      context,
      isCancel
          ? 'Payment cancelled. You can retry safely.'
          : 'Payment failed. Please try another payment method.',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted || _paymentFinalized) return;
    AppSnackBar.showSuccess(
        context, 'Wallet selected. Complete payment to continue.');
  }

  Future<void> _placeOrderAfterVerifiedPayment({
    required CheckoutSession? session,
    required CartState? cart,
  }) async {
    final repo = ref.read(customerRepositoryProvider);

    final PlaceOrderRequest placeRequest;
    if (session?.orderDraftId != null) {
      placeRequest = PlaceOrderRequest(
        orderDraftId: session!.orderDraftId,
      );
    } else {
      final addressId = session?.deliveryAddressId;
      final currentCart = cart;
      final selectedSlot = session?.selectedSlot;
      if (!Env.useMocksForVisualTestsOnly ||
          addressId == null ||
          addressId.isEmpty ||
          selectedSlot == null ||
          selectedSlot.isEmpty ||
          currentCart == null ||
          currentCart.services.isEmpty) {
        if (mounted) {
          setState(() => _isProcessing = false);
          AppSnackBar.showError(
            context,
            'Checkout session is unavailable. Please retry checkout.',
          );
        }
        return;
      }
      placeRequest = PlaceOrderRequest(
        vendorId: currentCart.services.first.vendorId,
        vendorSlotId: selectedSlot,
        items: currentCart.cart.items
            .map((i) => OrderItemRequest(
                  serviceId: i.serviceId,
                  quantity: i.quantity,
                ))
            .toList(),
        deliveryAddressId: addressId,
        pickupAddressId: session?.pickupAddressId ?? addressId,
        paymentMethod: _resolvePaymentMethod(_selectedMethod),
      );
    }

    final placedOrder = await repo.placeOrder(placeRequest);
    ref.read(cartStateProvider.notifier).clear();

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isVerifyingPayment = false;
        _verificationRetryPending = false;
      });
      AppSnackBar.showSuccess(context, 'Payment Successful!');
      context.go('/orders/${placedOrder.id}/submitted');
    }
  }

  PaymentMethod _resolvePaymentMethod(String method) => switch (method) {
        'upi' => PaymentMethod.upi,
        'card' => PaymentMethod.card,
        'wallet' => PaymentMethod.wallet,
        _ => PaymentMethod.upi,
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(cartStateProvider);
    final session = GoRouterState.of(context).extra as CheckoutSession?;
    final amountDue = session?.finalPrice ?? cartState.total;
    final paymentCtaLabel = _verificationRetryPending
        ? 'Verify Payment'
        : 'Pay ${amountDue.toCurrencyDecimal}';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment_rounded, color: AppColors.primary, size: 24.r),
            const Gap(8),
            Text(
              'Razorpay Secures',
              style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isProcessing
            ? const AppLoadingPage(
                message: 'Securing transaction with Razorpay...')
            : cartState.cart.isEmpty
                ? AppEmptyState(
                    icon: AppIcons.cartOutlined,
                    title: 'Nothing to pay for',
                    subtitle:
                        'Your cart is empty. Add services before completing payment.',
                    actionLabel: 'Browse vendors',
                    onAction: () => context.go(AppRoutes.vendorListing),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePaddingH.w,
                      vertical: AppSpacing.pagePaddingV.h * 1.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Grand total summary
                        AppCard.outlined(
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceContainer
                              : AppColors.surface,
                          child: Column(
                            children: [
                              Text('AMOUNT TO PAY',
                                  style: AppTypography.caption),
                              const Gap(8),
                              Text(
                                amountDue.toCurrencyDecimal,
                                style: AppTypography.displaySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(32),

                        Text('Select Payment Option',
                            style: AppTypography.titleMedium),
                        const Gap(16),

                        // Payment options list
                        _PaymentMethodTile(
                          label: 'UPI (GPay / PhonePe / Paytm)',
                          icon: AppIcons.upi,
                          isSelected: _selectedMethod == 'upi',
                          onTap: () => setState(() => _selectedMethod = 'upi'),
                        ),
                        const Gap(12),
                        _PaymentMethodTile(
                          label: 'Credit / Debit Card',
                          icon: AppIcons.creditCard,
                          isSelected: _selectedMethod == 'card',
                          onTap: () => setState(() => _selectedMethod = 'card'),
                        ),
                        const Gap(12),
                        _PaymentMethodTile(
                          label: 'Wallet Pay',
                          icon: AppIcons.walletOutlined,
                          isSelected: _selectedMethod == 'wallet',
                          onTap: () =>
                              setState(() => _selectedMethod = 'wallet'),
                        ),

                        const Spacer(),

                        // Secure payment note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.lock,
                                size: 14.r, color: AppColors.onSurfaceVariant),
                            const Gap(6),
                            Text(
                              '100% Secure PCI-DSS compliant transactions',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                        const Gap(24),

                        // Trigger payment CTA
                        AppButton(
                          label: paymentCtaLabel,
                          onPressed: () => _processPayment(cartState),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      onTap: onTap,
      borderColor: isSelected ? AppColors.primary : AppColors.outline,
      backgroundColor: isSelected
          ? AppColors.primaryContainer.withValues(alpha: 0.1)
          : AppColors.transparent,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          const Gap(16),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Container(
            width: 20.r,
            height: 20.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.outline,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10.r,
                      height: 10.r,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
