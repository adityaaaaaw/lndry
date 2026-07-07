import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/tokens/breakpoints.dart';

/// BuildContext extensions for quick, readable access to
/// theme, media query, navigation, and snackbar helpers.
extension ContextExt on BuildContext {
  // ── Theme ──────────────────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Screen ────────────────────────────────────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get statusBarHeight => MediaQuery.paddingOf(this).top;
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  // ── Responsive ────────────────────────────────────────────────────────────
  bool get isMobile => screenWidth < AppBreakpoints.tablet;
  bool get isTablet =>
      screenWidth >= AppBreakpoints.tablet &&
      screenWidth < AppBreakpoints.desktop;
  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;

  /// Returns [mobile], [tablet], or [desktop] based on current width.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  // NOTE: pop()/canPop() intentionally NOT defined here.
  // GoRouterHelper (from go_router) defines context.pop() and context.canPop()
  // which are the canonical navigation methods for this app.
  // For non-GoRouter pop (dialogs/bottom sheets), use Navigator.of(context).pop()
  // explicitly.

  // ── Keyboard ──────────────────────────────────────────────────────────────
  void hideKeyboard() => FocusScope.of(this).unfocus();

  // ── Snackbar ──────────────────────────────────────────────────────────────
  void showSnackbar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: isError
            ? AppColors.error
            : isSuccess
                ? AppColors.success
                : null,
      ),
    );
  }

  void showError(String message) => showSnackbar(message, isError: true);
  void showSuccess(String message) => showSnackbar(message, isSuccess: true);

  // ── Confirm Dialog ────────────────────────────────────────────────────────
  Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Spacing shorthands ────────────────────────────────────────────────────
  SizedBox get gapXS => SizedBox(height: 4.h);
  SizedBox get gapSM => SizedBox(height: 8.h);
  SizedBox get gapMD => SizedBox(height: 16.h);
  SizedBox get gapLG => SizedBox(height: 24.h);
  SizedBox get gapXL => SizedBox(height: 32.h);
  SizedBox get gapXXL => SizedBox(height: 48.h);

  EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h);

  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: 20.w);
}
