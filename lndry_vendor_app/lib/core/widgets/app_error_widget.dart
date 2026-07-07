import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/tokens/spacing.dart';
import '../theme/tokens/icons.dart';
import '../theme/tokens/radius.dart';
import 'app_button.dart';

/// LNDRY Error Widget — inline and fullscreen variants.
///
/// Usage:
/// ```dart
/// // Inline
/// AppErrorWidget(message: 'Failed to load services.', onRetry: fetchServices)
///
/// // Fullscreen
/// AppErrorWidget.fullscreen(message: error.message, onRetry: retry)
/// ```
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.padding,
    bool isFullscreen = false,
  }) : _fullscreen = isFullscreen;

  const AppErrorWidget.fullscreen({
    Key? key,
    String? message,
    String? title,
    VoidCallback? onRetry,
    IconData? icon,
  }) : this(
          key: key,
          message: message,
          title: title,
          onRetry: onRetry,
          icon: icon,
          isFullscreen: true,
        );

  final String? message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final bool _fullscreen;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (_fullscreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Center(child: content)),
      );
    }

    return content;
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: AppSpacing.xl.w,
            vertical: AppSpacing.xl.h,
          ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Error Illustration ────────────────────────────────────────────
          Container(
            width: 100.r,
            height: 100.r,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.errorContainer,
            ),
            child: Icon(
              icon ?? AppIcons.noInternet,
              size: 48.r,
              color: AppColors.error,
            ),
          ),

          SizedBox(height: AppSpacing.lg.h),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            title ?? 'Something went wrong',
            style: AppTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),

          // ── Message ───────────────────────────────────────────────────────
          if (message != null) ...[
            SizedBox(height: AppSpacing.sm.h),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // ── Retry ─────────────────────────────────────────────────────────
          if (onRetry != null) ...[
            SizedBox(height: AppSpacing.xl.h),
            AppButton(
              label: 'Try Again',
              onPressed: onRetry,
              icon: const Icon(AppIcons.refresh, color: AppColors.onPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

/// A lightweight banner-style inline error (e.g., inside a form).
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w * 3.5, // ~14
        vertical: AppSpacing.sm.h * 1.25, // ~10
      ),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.input.r),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.error, color: AppColors.error, size: 18.r),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(AppIcons.close,
                  size: 16.r, color: AppColors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
