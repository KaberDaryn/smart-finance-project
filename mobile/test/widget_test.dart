import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/main.dart';

void main() {
  test('Amounts use exact minor units', () {
    expect(parseAmount('1500.01'), 150001);
    expect(parseAmount('0.10'), 10);
    expect(parseAmount('5'), 500);
    expect(parseAmount('10000000000'), 1000000000000);
    expect(parseAmount('10000000000.01'), isNull);
    for (final value in ['0', '-1', '1.001', 'abc', '1e3']) {
      expect(parseAmount(value), isNull);
    }
  });
  test('Currency formatting preserves minor units', () {
    expect(money(-12301), '-123.01 KZT');
    expect(money(5), '0.05 KZT');
  });
}
