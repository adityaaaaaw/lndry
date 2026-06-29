import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';

/// LNDRY Reusable SnackBar Helper class
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.success,
      color: AppColors.success,
      action: action,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.error,
      color: AppColors.error,
      action: action,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.info,
      color: AppColors.primary,
      action: action,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.warning,
      color: AppColors.warning,
      action: action,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surface,
        margin: EdgeInsets.all(AppSpacing.md.r),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.sm.h * 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input.r),
          side: BorderSide(
            color: color.withOpacity(0.4),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24.r,
            ),
            const Gap(12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        action: action,
      ),
    );
  }
}
