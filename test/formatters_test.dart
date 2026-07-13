import 'package:expenseflow/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money drops trailing .00 and groups thousands', () {
    expect(Formatters.money(45000, '₹'), '₹45,000');
    expect(Formatters.money(1250.5, r'$'), r'$1,250.5');
    expect(Formatters.money(0, '€'), '€0');
  });

  test('money renders negative amounts with a leading sign', () {
    expect(Formatters.money(-500, '₹'), '-₹500');
  });

  test('signedMoney adds a + only for positive values', () {
    expect(Formatters.signedMoney(20000, '₹'), '+₹20,000');
    expect(Formatters.signedMoney(-200, '₹'), '-₹200');
    expect(Formatters.signedMoney(0, '₹'), '₹0');
  });
}
