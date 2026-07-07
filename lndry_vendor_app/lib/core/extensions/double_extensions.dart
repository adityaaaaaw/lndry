import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_constants.dart';

/// double / num extensions for responsive sizing, currency, and UI helpers.
extension DoubleExt on double {
  // ── Responsive sizing (ScreenUtil) ────────────────────────────────────────

  /// Width-scaled value
  double get w => ScreenUtil().setWidth(this);

  /// Height-scaled value
  double get h => ScreenUtil().setHeight(this);

  /// Radius / symmetric size scaled
  double get r => ScreenUtil().radius(this);

  /// Font size scaled
  double get sp => ScreenUtil().setSp(this);

  // ── Currency ──────────────────────────────────────────────────────────────

  /// ₹1,200  (no decimal)
  String get toCurrency {
    if (this >= 1000) {
      return '${AppConstants.currencySymbol}${(this / 1000).toStringAsFixed(1)}K'
          .replaceAll('.0K', 'K');
    }
    return '${AppConstants.currencySymbol}${toStringAsFixed(0)}';
  }

  /// ₹1,200.50  (with decimal)
  String get toCurrencyDecimal =>
      '${AppConstants.currencySymbol}${toStringAsFixed(2)}';

  /// Compact: ₹1.2K, ₹3.4M
  String get toCompactCurrency {
    if (this >= 1000000) {
      return '${AppConstants.currencySymbol}${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${AppConstants.currencySymbol}${(this / 1000).toStringAsFixed(1)}K';
    }
    return '${AppConstants.currencySymbol}${toStringAsFixed(0)}';
  }

  // ── Percentage ────────────────────────────────────────────────────────────

  /// 0.185 → "18.5%"
  String get toPercent => '${(this * 100).toStringAsFixed(1)}%';

  /// 18.5 → "18.5%"
  String get percentString => '${toStringAsFixed(1)}%';

  // ── Rounding ──────────────────────────────────────────────────────────────
  double roundTo(int places) {
    final mod = _pow(10.0, places);
    return (this * mod).round() / mod;
  }

  // ── Widget helpers ────────────────────────────────────────────────────────
  SizedBox get verticalSpace   => SizedBox(height: h);
  SizedBox get horizontalSpace => SizedBox(width: w);

  EdgeInsets get allPadding        => EdgeInsets.all(r);
  EdgeInsets get horizontalPadding =>
      EdgeInsets.symmetric(horizontal: w);
  EdgeInsets get verticalPadding   =>
      EdgeInsets.symmetric(vertical: h);

  BorderRadius get circular        => BorderRadius.circular(r);

  // ── Clamp helpers ─────────────────────────────────────────────────────────
  double clampToPositive() => clamp(0.0, double.infinity).toDouble();
}

extension IntExt on int {
  double get w  => toDouble().w;
  double get h  => toDouble().h;
  double get r  => toDouble().r;
  double get sp => toDouble().sp;

  SizedBox get verticalSpace   => SizedBox(height: h);
  SizedBox get horizontalSpace => SizedBox(width: w);

  /// "1 item" / "5 items"
  String plural(String word) => this == 1 ? '1 $word' : '$this ${word}s';

  /// Converts seconds → "02:30"
  String get toMMSS {
    final m = (this ~/ 60).toString().padLeft(2, '0');
    final s = (this % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

double _pow(double x, int exp) {
  double result = 1.0;
  for (var i = 0; i < exp; i++) {
    result *= x;
  }
  return result;
}
