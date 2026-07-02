import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// LNDRY Currency & Number formatting utilities
abstract final class CurrencyUtils {
  CurrencyUtils._();

  static final _inrFormatter = NumberFormat.currency(
    locale: AppConstants.defaultLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static final _inrFormatterDecimal = NumberFormat.currency(
    locale: AppConstants.defaultLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  /// Formats [amount] as ₹1,200
  static String format(num amount) => _inrFormatter.format(amount);

  /// Formats [amount] as ₹1,200.50
  static String formatDecimal(num amount) =>
      _inrFormatterDecimal.format(amount);

  /// All money calculations are performed server-side per spec §6 / §11.
  /// The client only formats and displays server-provided amounts.
  /// GST and platform fee functions have been intentionally removed.

  /// Compact format: ₹1.2K, ₹3.4M
  static String compact(num amount) {
    if (amount >= 1000000) {
      return '${AppConstants.currencySymbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}
