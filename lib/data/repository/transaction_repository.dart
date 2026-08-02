import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../../core/utils/date_utils.dart';
import '../database/app_database.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/summary_models.dart';
import '../models/transaction_item.dart';

/// All persistence + aggregation logic for transactions and budgets.
///
/// The app is fully offline (SQLite) so aggregation is done in Dart over the
/// month's rows — the data volume for a personal tracker is small and this
/// keeps the query surface simple and testable.
class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<int> addExpense(ExpenseModel expense) async {
    final Database db = await _database;
    return db.insert(DbConstants.tableExpense, expense.toMap());
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    final Database db = await _database;
    return db.update(
      DbConstants.tableExpense,
      expense.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: <Object?>[expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final Database db = await _database;
    return db.delete(
      DbConstants.tableExpense,
      where: '${DbConstants.colId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> addIncome(IncomeModel income) async {
    final Database db = await _database;
    return db.insert(DbConstants.tableIncome, income.toMap());
  }

  Future<int> updateIncome(IncomeModel income) async {
    final Database db = await _database;
    return db.update(
      DbConstants.tableIncome,
      income.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: <Object?>[income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final Database db = await _database;
    return db.delete(
      DbConstants.tableIncome,
      where: '${DbConstants.colId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<List<ExpenseModel>> _expensesInRange(DateTime start, DateTime end) async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      DbConstants.tableExpense,
      where: '${DbConstants.colDate} >= ? AND ${DbConstants.colDate} < ?',
      whereArgs: <Object?>[start.toIso8601String(), end.toIso8601String()],
      orderBy: '${DbConstants.colDate} DESC',
    );
    return rows.map(ExpenseModel.fromMap).toList();
  }

  Future<List<IncomeModel>> _incomesInRange(DateTime start, DateTime end) async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      DbConstants.tableIncome,
      where: '${DbConstants.colDate} >= ? AND ${DbConstants.colDate} < ?',
      whereArgs: <Object?>[start.toIso8601String(), end.toIso8601String()],
      orderBy: '${DbConstants.colDate} DESC',
    );
    return rows.map(IncomeModel.fromMap).toList();
  }

  Future<ExpenseModel?> getExpense(int id) async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      DbConstants.tableExpense,
      where: '${DbConstants.colId} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : ExpenseModel.fromMap(rows.first);
  }

  Future<IncomeModel?> getIncome(int id) async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      DbConstants.tableIncome,
      where: '${DbConstants.colId} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : IncomeModel.fromMap(rows.first);
  }

  /// Merged, date-descending transaction list for the month containing [month].
  Future<List<TransactionItem>> transactionsForMonth(DateTime month) async {
    final DateTime start = DateUtilsX.monthStart(month);
    final DateTime end = DateUtilsX.nextMonthStart(month);
    final List<ExpenseModel> expenses = await _expensesInRange(start, end);
    final List<IncomeModel> incomes = await _incomesInRange(start, end);

    final List<TransactionItem> items = <TransactionItem>[
      ...expenses.map(TransactionItem.fromExpense),
      ...incomes.map(TransactionItem.fromIncome),
    ]..sort((TransactionItem a, TransactionItem b) => b.date.compareTo(a.date));
    return items;
  }

  /// The [limit] most recent transactions overall (for the dashboard).
  Future<List<TransactionItem>> recentTransactions({int limit = 10}) async {
    final Database db = await _database;
    final List<Map<String, Object?>> exp = await db.query(
      DbConstants.tableExpense,
      orderBy: '${DbConstants.colDate} DESC',
      limit: limit,
    );
    final List<Map<String, Object?>> inc = await db.query(
      DbConstants.tableIncome,
      orderBy: '${DbConstants.colDate} DESC',
      limit: limit,
    );
    final List<TransactionItem> items = <TransactionItem>[
      ...exp.map(ExpenseModel.fromMap).map(TransactionItem.fromExpense),
      ...inc.map(IncomeModel.fromMap).map(TransactionItem.fromIncome),
    ]..sort((TransactionItem a, TransactionItem b) => b.date.compareTo(a.date));
    return items.take(limit).toList();
  }

  // ---------------------------------------------------------------------------
  // Aggregation
  // ---------------------------------------------------------------------------

  /// Net balance (all income - all expense) recorded strictly before [monthStart].
  ///
  /// This is the amount automatically carried forward into the month; the date
  /// indexes keep the two SUM range scans cheap.
  Future<double> balanceBefore(DateTime monthStart) async {
    final Database db = await _database;
    final String cutoff = monthStart.toIso8601String();
    Future<double> sumBefore(String table) async {
      final List<Map<String, Object?>> rows = await db.rawQuery(
        'SELECT COALESCE(SUM(${DbConstants.colAmount}), 0) AS total '
        'FROM $table WHERE ${DbConstants.colDate} < ?',
        <Object?>[cutoff],
      );
      return (rows.first['total'] as num).toDouble();
    }

    final double income = await sumBefore(DbConstants.tableIncome);
    final double expense = await sumBefore(DbConstants.tableExpense);
    return income - expense;
  }

  /// Build the dashboard/report summary for the month containing [month].
  Future<MonthlySummary> monthlySummary(DateTime month) async {
    final DateTime start = DateUtilsX.monthStart(month);
    final DateTime end = DateUtilsX.nextMonthStart(month);
    final List<ExpenseModel> expenses = await _expensesInRange(start, end);
    final List<IncomeModel> incomes = await _incomesInRange(start, end);
    final double carryForward = await balanceBefore(start);

    if (expenses.isEmpty && incomes.isEmpty) {
      final MonthlySummary base = MonthlySummary.empty(start);
      final double? util = await _budgetUtilization(0);
      return MonthlySummary(
        month: base.month,
        totalIncome: 0,
        totalExpense: 0,
        transactionCount: 0,
        averageDailyExpense: 0,
        largestExpense: 0,
        topIncomeSource: '',
        categoryTotals: const <CategoryTotal>[],
        budgetUtilization: util,
        carryForward: carryForward,
      );
    }

    final double totalExpense =
        expenses.fold(0, (double s, ExpenseModel e) => s + e.amount);
    final double totalIncome =
        incomes.fold(0, (double s, IncomeModel i) => s + i.amount);

    // Category totals (expenses), descending.
    final Map<String, double> byCategory = <String, double>{};
    for (final ExpenseModel e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final List<CategoryTotal> categoryTotals = byCategory.entries
        .map((MapEntry<String, double> e) =>
            CategoryTotal(category: e.key, amount: e.value))
        .toList()
      ..sort((CategoryTotal a, CategoryTotal b) =>
          b.amount.compareTo(a.amount));

    // Largest single expense.
    final double largestExpense = expenses.fold<double>(
        0, (double m, ExpenseModel e) => e.amount > m ? e.amount : m);

    // Top income source.
    final Map<String, double> bySource = <String, double>{};
    for (final IncomeModel i in incomes) {
      bySource[i.category] = (bySource[i.category] ?? 0) + i.amount;
    }
    String topIncomeSource = '';
    double topIncomeAmount = -1;
    bySource.forEach((String k, double v) {
      if (v > topIncomeAmount) {
        topIncomeAmount = v;
        topIncomeSource = k;
      }
    });

    // Average daily expense over elapsed days (current month) or full month.
    final DateTime now = DateTime.now();
    final int divisor = DateUtilsX.sameMonth(now, start)
        ? now.day
        : DateUtilsX.daysInMonth(start);
    final double averageDailyExpense =
        divisor > 0 ? totalExpense / divisor : 0;

    return MonthlySummary(
      month: start,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactionCount: expenses.length + incomes.length,
      averageDailyExpense: averageDailyExpense,
      largestExpense: largestExpense,
      topIncomeSource: topIncomeSource,
      categoryTotals: categoryTotals,
      budgetUtilization: await _budgetUtilization(totalExpense),
      carryForward: carryForward,
    );
  }

  /// Expense totals per month for the last [months] months (for the bar chart).
  Future<List<MonthlyExpensePoint>> monthlyExpenseTrend({int months = 6}) async {
    final DateTime now = DateTime.now();
    final List<MonthlyExpensePoint> points = <MonthlyExpensePoint>[];
    for (int i = months - 1; i >= 0; i--) {
      final DateTime m = DateTime(now.year, now.month - i);
      final List<ExpenseModel> expenses = await _expensesInRange(
        DateUtilsX.monthStart(m),
        DateUtilsX.nextMonthStart(m),
      );
      final double total =
          expenses.fold(0, (double s, ExpenseModel e) => s + e.amount);
      points.add(MonthlyExpensePoint(month: m, amount: total));
    }
    return points;
  }

  Future<double?> _budgetUtilization(double totalExpense) async {
    final List<BudgetModel> budgets = await getBudgets();
    if (budgets.isEmpty) return null;
    final double totalBudget =
        budgets.fold(0, (double s, BudgetModel b) => s + b.amount);
    if (totalBudget <= 0) return null;
    return totalExpense / totalBudget;
  }

  // ---------------------------------------------------------------------------
  // Budgets
  // ---------------------------------------------------------------------------

  Future<List<BudgetModel>> getBudgets() async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows =
        await db.query(DbConstants.tableBudget);
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<void> upsertBudget(BudgetModel budget) async {
    final Database db = await _database;
    await db.insert(
      DbConstants.tableBudget,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
