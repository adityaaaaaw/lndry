import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

// ═════════════════════════════════════════════════════════════════════════════
// LOADING WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

/// Fullscreen loading overlay.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    this.message,
    this.color,
  });

  final String? message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: AppCard(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLoadingIndicator(color: color),
              if (message != null) ...[
                SizedBox(height: 16.h),
                Text(
                  message!,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline circular loading indicator.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size,
    this.strokeWidth,
    this.color,
  });

  final double? size;
  final double? strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 36.r,
      height: size ?? 36.r,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// Fullscreen loading page (e.g. while router is initializing).
class AppLoadingPage extends StatelessWidget {
  const AppLoadingPage({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLoadingIndicator(size: 48.r),
            if (message != null) ...[
              SizedBox(height: 20.h),
              Text(message!, style: AppTypography.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
