import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

              // Success Checkmark Illustration
              Center(
                child: Container(
                  width: 140.r,
                  height: 140.r,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.success,
                    size: 80.r,
                    color: AppColors.success,
                  ),
                ),
              ),
              const Gap(32),

              // Headers
              Text(
                'Order Confirmed!',
                style: AppTypography.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const Gap(12),
              Text(
                'Your laundry pickup has been scheduled successfully. Our delivery partner will contact you shortly.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(40),

              // Order details summary box
              AppCard.outlined(
                backgroundColor: isDark ? AppColors.darkSurfaceContainer : AppColors.surface,
                padding: EdgeInsets.all(AppSpacing.md.r),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Order ID',
                      value: '#${orderId.substring(orderId.length - 8).toUpperCase()}',
                    ),
                    const Gap(10),
                    const _DetailRow(
                      label: 'Estimated Delivery',
                      value: '24 - 48 Hours',
                    ),
                    const Gap(10),
                    const _DetailRow(
                      label: 'Status',
                      value: 'Pending Pickup',
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action buttons
              AppButton(
                label: 'Track Order',
                onPressed: () => context.go('/orders/details/$orderId'),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: valueColor ?? context.theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
