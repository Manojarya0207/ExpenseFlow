/// Aggregated figures for a single month, used by the Dashboard (§5.1, §11)
/// and Monthly Report (§5.5).
class MonthlySummary {
  const MonthlySummary({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactionCount,
    required this.averageDailyExpense,
    required this.largestExpense,
    required this.topIncomeSource,
    required this.categoryTotals,
    required this.budgetUtilization,
  });

  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final int transactionCount;
  final double averageDailyExpense;

  /// Largest single expense this month (0 if none).
  final double largestExpense;

  /// Income source contributing the most this month ('' if none).
  final String topIncomeSource;

  /// Expense total per category, descending by amount.
  final List<CategoryTotal> categoryTotals;

  /// Fraction (0..1+) of total budget consumed by expenses; null if no budget.
  final double? budgetUtilization;

  double get savings => totalIncome - totalExpense;

  /// Remaining balance for the month (same basis as savings in an offline,
  /// single-month view).
  double get remainingBalance => savings;

  factory MonthlySummary.empty(DateTime month) {
    return MonthlySummary(
      month: month,
      totalIncome: 0,
      totalExpense: 0,
      transactionCount: 0,
      averageDailyExpense: 0,
      largestExpense: 0,
      topIncomeSource: '',
      categoryTotals: const <CategoryTotal>[],
      budgetUtilization: null,
    );
  }
}

/// A category paired with its summed amount (used by pie/bar charts).
class CategoryTotal {
  const CategoryTotal({required this.category, required this.amount});

  final String category;
  final double amount;
}

/// One month's expense total, used by the analytics bar chart (§5.6).
class MonthlyExpensePoint {
  const MonthlyExpensePoint({required this.month, required this.amount});

  final DateTime month;
  final double amount;
}
