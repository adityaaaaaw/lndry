import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/tokens/spacing.dart';
import '../theme/tokens/icons.dart';
import 'app_button.dart';

/// LNDRY Empty State Widget
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: AppIcons.ordersOutlined,
///   title: 'No Orders Yet',
///   subtitle: 'Place your first order and enjoy fresh laundry.',
///   actionLabel: 'Browse Services',
///   onAction: () => context.go(AppRoutes.home),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.padding,
  });

  final IconData? icon;

  /// Optional custom illustration widget (e.g. Lottie animation or Image).
  final Widget? illustration;

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: AppSpacing.xl.w,
            vertical: AppSpacing.xxl.h,
          ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Illustration ─────────────────────────────────────────────────
          if (illustration != null)
            illustration!
          else
            _IconIllustration(icon: icon ?? AppIcons.emptyBox),

          SizedBox(height: AppSpacing.lg.h),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            title,
            style: AppTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),

          // ── Subtitle ──────────────────────────────────────────────────────
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.sm.h),
            Text(
              subtitle!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // ── Actions ───────────────────────────────────────────────────────
          if (actionLabel != null) ...[
            SizedBox(height: AppSpacing.xl.h),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],

          if (secondaryActionLabel != null) ...[
            SizedBox(height: AppSpacing.cardGap.h),
            AppButton.outlined(
              label: secondaryActionLabel!,
              onPressed: onSecondaryAction,
            ),
          ],
        ],
      ),
    );
  }
}

class _IconIllustration extends StatelessWidget {
  const _IconIllustration({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120.r,
      height: 120.r,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryContainer,
      ),
      child: Icon(
        icon,
        size: 56.r,
        color: AppColors.primary,
      ),
    );
  }
}
