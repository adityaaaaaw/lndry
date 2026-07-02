import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key, required this.orderId});
  final String orderId;

  /// Safe short ID — last 8 chars if available, otherwise full id.
  String get _shortId {
    if (orderId.isEmpty) return 'NEW';
    return orderId.length > 8
        ? orderId.substring(orderId.length - 8).toUpperCase()
        : orderId.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingH.w,
            vertical: AppSpacing.pagePaddingV.h * 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Success icon
              Center(
                child: Container(
                  width: 140.r,
                  height: 140.r,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(AppIcons.success, size: 80.r, color: AppColors.success),
                ),
              ),
              const Gap(32),

              Text(
                'Payment Successful!',
                style: AppTypography.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const Gap(16),

              // Spec §12 exact confirmation copy
              Text(
                'Your payment has been verified and the order has been sent to '
                'the selected laundry partner.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(24),

              // Status card
              AppCard.outlined(
                backgroundColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.primaryContainer.withOpacity(0.4),
                borderColor: AppColors.primary.withOpacity(0.3),
                padding: EdgeInsets.all(AppSpacing.md.r),
                child: Column(
                  children: [
                    // Canonical status label per spec §12
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full.r),
                        ),
                        child: Text(
                          'Waiting for Vendor Confirmation',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Gap(16),
                    _Row(label: 'Order ID', value: '#$_shortId'),
                    const Gap(8),
                    _Row(
                      label: 'Next step',
                      value:
                          'You will be notified when the vendor accepts or rejects.',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              AppButton(
                label: 'Track Order',
                onPressed: () {
                  if (orderId.isNotEmpty) {
                    context.go('/orders/details/$orderId');
                  } else {
                    context.go(AppRoutes.orders);
                  }
                },
              ),
              const Gap(16),
              AppButton.text(
                label: 'Back to Home',
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor ?? AppColors.textBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
