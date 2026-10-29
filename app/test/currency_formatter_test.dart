import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_tracker/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats rupee amounts in Indian grouping correctly', () {
      expect(CurrencyFormatter.format(0), '₹0.00');
      expect(CurrencyFormatter.format(1000), '₹1,000.00');
      expect(CurrencyFormatter.format(123456), '₹1,23,456.00');
      expect(CurrencyFormatter.format(4200.5), '₹4,200.50');
      expect(CurrencyFormatter.format(4900), '₹4,900.00');
    });

    test('formats integer counts with Indian commas', () {
      expect(CurrencyFormatter.formatInteger(0), '0');
      expect(CurrencyFormatter.formatInteger(500), '500');
      expect(CurrencyFormatter.formatInteger(15000), '15,000');
      expect(CurrencyFormatter.formatInteger(100000), '1,00,000');
    });
  });
}