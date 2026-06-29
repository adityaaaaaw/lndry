import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';
import '../../../cart/presentation/providers/cart_providers.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isProcessing = false;
  String _selectedMethod = 'upi'; // upi, card, netbanking, wallet

  void _processMockPayment(CartState cart) async {
    setState(() => _isProcessing = true);

    final session = GoRouterState.of(context).extra as CheckoutSession?;

    if (cart.cart.isEmpty) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppSnackBar.showError(context, 'Your cart is empty.');
        context.go(AppRoutes.vendorListing);
      }
      return;
    }
    
    // Simulate Razorpay transaction delay
    await Future.delayed(const Duration(milliseconds: 1800));

    try {
      final repo = ref.read(customerRepositoryProvider);
      final addressId = session?.deliveryAddressId ?? 'addr_1';

      // Place order mock in repository
      final placedOrder = await repo.placeOrder(
        PlaceOrderRequest(
          vendorId: cart.services.isNotEmpty ? cart.services.first.vendorId : 'vndr_demo',
          items: cart.cart.items
              .map((i) => OrderItemRequest(serviceId: i.serviceId, quantity: i.quantity))
              .toList(),
          deliveryAddressId: addressId,
          pickupAddressId: session?.pickupAddressId ?? addressId,
          paymentMethod: _resolvePaymentMethod(_selectedMethod),
        ),
      );

      // Clear the local cart
      ref.read(cartStateProvider.notifier).clear();

      if (mounted) {
        setState(() => _isProcessing = false);
        AppSnackBar.showSuccess(context, 'Payment Successful!');
        context.go('/checkout/confirmation/${placedOrder.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppSnackBar.showError(context, 'Transaction failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  PaymentMethod _resolvePaymentMethod(String method) => switch (method) {
        'upi' => PaymentMethod.upi,
        'card' => PaymentMethod.card,
        'wallet' => PaymentMethod.wallet,
        'netbanking' => PaymentMethod.card,
        _ => PaymentMethod.cash,
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(cartStateProvider);
    final session = GoRouterState.of(context).extra as CheckoutSession?;
    final amountDue = session?.finalPrice ?? cartState.total;

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
              style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isProcessing
            ? const AppLoadingPage(message: 'Securing transaction with Razorpay...')
            : cartState.cart.isEmpty
                ? AppEmptyState(
                    icon: AppIcons.cartOutlined,
                    title: 'Nothing to pay for',
                    subtitle: 'Your cart is empty. Add services before completing payment.',
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
                      backgroundColor: isDark ? AppColors.darkSurfaceContainer : AppColors.surface,
                      child: Column(
                        children: [
                          Text('AMOUNT TO PAY', style: AppTypography.caption),
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

                    Text('Select Payment Option', style: AppTypography.titleMedium),
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
                      label: 'Net Banking',
                      icon: AppIcons.document,
                      isSelected: _selectedMethod == 'netbanking',
                      onTap: () => setState(() => _selectedMethod = 'netbanking'),
                    ),
                    const Gap(12),
                    _PaymentMethodTile(
                      label: 'Wallet Pay',
                      icon: AppIcons.walletOutlined,
                      isSelected: _selectedMethod == 'wallet',
                      onTap: () => setState(() => _selectedMethod = 'wallet'),
                    ),

                    const Spacer(),

                    // Secure payment note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.lock, size: 14.r, color: AppColors.onSurfaceVariant),
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
                      label: 'Pay ${amountDue.toCurrencyDecimal}',
                      onPressed: () => _processMockPayment(cartState),
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
      backgroundColor: isSelected ? AppColors.primaryContainer.withOpacity(0.1) : AppColors.transparent,
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
