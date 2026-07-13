import 'expense_model.dart';
import 'income_model.dart';

enum TransactionType { income, expense }

/// A unified, read-only view over an expense or income row so the
/// Transactions list, search, calendar and recent-activity widgets can
/// render a single merged, sorted stream.
class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.paymentMethod,
    this.notes,
    required this.date,
    required this.createdAt,
  });

  final int id;
  final TransactionType type;
  final double amount;
  final String category;
  final String? paymentMethod;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  /// Signed amount: positive for income, negative for expense.
  double get signedAmount => isIncome ? amount : -amount;

  factory TransactionItem.fromExpense(ExpenseModel e) {
    return TransactionItem(
      id: e.id!,
      type: TransactionType.expense,
      amount: e.amount,
      category: e.category,
      paymentMethod: e.paymentMethod,
      notes: e.notes,
      date: e.date,
      createdAt: e.createdAt,
    );
  }

  factory TransactionItem.fromIncome(IncomeModel i) {
    return TransactionItem(
      id: i.id!,
      type: TransactionType.income,
      amount: i.amount,
      category: i.category,
      paymentMethod: null,
      notes: i.notes,
      date: i.date,
      createdAt: i.createdAt,
    );
  }
}
