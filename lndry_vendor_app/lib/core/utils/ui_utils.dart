import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// LNDRY UI Utilities — spacing, sizing, snackbar, dialogs
abstract final class UIUtils {
  UIUtils._();

  // ── Snackbar ──────────────────────────────────────────────────────────────

  static void showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: isError
            ? Colors.red.shade700
            : isSuccess
                ? Colors.green.shade700
                : null,
      ),
    );
  }

  static void showError(BuildContext context, String message) =>
      showSnackbar(context, message, isError: true);

  static void showSuccess(BuildContext context, String message) =>
      showSnackbar(context, message, isSuccess: true);

  // ── Dialogs ───────────────────────────────────────────────────────────────

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
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
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // ── Keyboard ──────────────────────────────────────────────────────────────

  static void dismissKeyboard(BuildContext context) =>
      FocusScope.of(context).unfocus();

  // ── Screen sizing helpers ─────────────────────────────────────────────────

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static double statusBarHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  static double bottomPadding(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  // ── Common spacing constants (for inline use without ScreenUtil) ──────────
  static SizedBox get verticalXS => SizedBox(height: 4.h);
  static SizedBox get verticalSM => SizedBox(height: 8.h);
  static SizedBox get verticalMD => SizedBox(height: 16.h);
  static SizedBox get verticalLG => SizedBox(height: 24.h);
  static SizedBox get verticalXL => SizedBox(height: 32.h);
  static SizedBox get verticalXXL => SizedBox(height: 48.h);

  static SizedBox get horizontalXS => SizedBox(width: 4.w);
  static SizedBox get horizontalSM => SizedBox(width: 8.w);
  static SizedBox get horizontalMD => SizedBox(width: 16.w);
  static SizedBox get horizontalLG => SizedBox(width: 24.w);
  static SizedBox get horizontalXL => SizedBox(width: 32.w);

  // ── Padding shortcuts ─────────────────────────────────────────────────────
  static EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h);

  static EdgeInsets get horizontalPadding =>
      EdgeInsets.symmetric(horizontal: 20.w);

  static EdgeInsets cardPadding([double p = 16]) =>
      EdgeInsets.all(p.r);
}

/// Extension on num to quickly get Gap SizedBox widgets.
extension GapExt on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble().h);
  SizedBox get horizontalSpace => SizedBox(width: toDouble().w);
}

/// Extension on BuildContext for quick media queries.
extension ContextExt on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get statusBarHeight => MediaQuery.paddingOf(this).top;
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
  bool get isTablet => MediaQuery.sizeOf(this).shortestSide >= 600;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
