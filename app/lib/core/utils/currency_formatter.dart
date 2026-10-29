import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inCompactFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static String format(num? value) {
    if (value == null) return '₹0.00';
    return _inFormat.format(value);
  }

  static String formatCompact(num? value) {
    if (value == null) return '₹0';
    return _inCompactFormat.format(value);
  }

  static String formatInteger(int? value) {
    if (value == null) return '0';
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return formatter.format(value);
  }
}

