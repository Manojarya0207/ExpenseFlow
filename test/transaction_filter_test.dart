import 'package:expenseflow/data/models/transaction_item.dart';
import 'package:expenseflow/data/repository/transaction_filter.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionItem _tx({
  required int id,
  required TransactionType type,
  required double amount,
  required String category,
  String? paymentMethod,
  String? notes,
  required DateTime date,
}) {
  return TransactionItem(
    id: id,
    type: type,
    amount: amount,
    category: category,
    paymentMethod: paymentMethod,
    notes: notes,
    date: date,
    createdAt: date,
  );
}

void main() {
  final List<TransactionItem> sample = <TransactionItem>[
    _tx(
      id: 1,
      type: TransactionType.expense,
      amount: 200,
      category: 'Food',
      paymentMethod: 'Cash',
      date: DateTime(2026, 7, 12, 9),
    ),
    _tx(
      id: 2,
      type: TransactionType.expense,
      amount: 500,
      category: 'Fuel',
      paymentMethod: 'UPI',
      date: DateTime(2026, 7, 12, 18),
    ),
    _tx(
      id: 3,
      type: TransactionType.income,
      amount: 20000,
      category: 'Salary',
      notes: 'July pay',
      date: DateTime(2026, 7, 1, 10),
    ),
  ];

  test('type filter keeps only expenses', () {
    const TransactionFilter filter =
        TransactionFilter(type: TypeFilter.expense);
    final List<TransactionItem> result = filter.apply(sample);
    expect(result.length, 2);
    expect(result.every((TransactionItem t) => t.isExpense), isTrue);
  });

  test('search matches category and notes case-insensitively', () {
    expect(
      const TransactionFilter(query: 'food').apply(sample).single.id,
      1,
    );
    expect(
      const TransactionFilter(query: 'JULY').apply(sample).single.id,
      3,
    );
  });

  test('category filter narrows to a single category', () {
    final List<TransactionItem> result =
        const TransactionFilter(category: 'Fuel').apply(sample);
    expect(result.single.category, 'Fuel');
  });

  test('payment-method filter works', () {
    final List<TransactionItem> result =
        const TransactionFilter(paymentMethod: 'UPI').apply(sample);
    expect(result.single.id, 2);
  });

  test('sort by amount descending', () {
    final List<TransactionItem> result =
        const TransactionFilter(sort: TransactionSort.amountDesc)
            .apply(sample);
    expect(result.map((TransactionItem t) => t.amount).toList(),
        <double>[20000, 500, 200]);
  });

  test('default sort is newest first', () {
    final List<TransactionItem> result =
        const TransactionFilter().apply(sample);
    expect(result.first.id, 2); // 12 Jul 18:00 is the latest
  });

  test('isActive reflects any active constraint', () {
    expect(const TransactionFilter().isActive, isFalse);
    expect(const TransactionFilter(query: 'x').isActive, isTrue);
    expect(const TransactionFilter(type: TypeFilter.income).isActive, isTrue);
  });
}
