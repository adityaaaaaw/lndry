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

  /// Returns amount with GST applied.
  static double addGst(double amount) =>
      amount + (amount * AppConstants.gstPercent);

  /// Returns platform fee amount.
  static double platformFee(double amount) =>
      amount * AppConstants.platformFeePercent;

  /// Returns grand total including platform fee and GST.
  static double grandTotal(double subtotal) {
    final fee = platformFee(subtotal);
    return addGst(subtotal + fee);
  }

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
