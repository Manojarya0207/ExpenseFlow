import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/database/app_database.dart';
import '../../features/settings/settings_provider.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../data/models/summary_models.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repository/transaction_filter.dart';
import '../../data/repository/transaction_repository.dart';
import '../utils/date_utils.dart';

/// Single database handle.
final Provider<AppDatabase> appDatabaseProvider =
    Provider<AppDatabase>((Ref ref) => AppDatabase.instance);

/// Active currency symbol, re-exported here so feature screens only need the
/// core providers import. Backed by Settings.
final Provider<String> currencySymbolProvider = Provider<String>(
  (Ref ref) => ref.watch(settingsProvider).currencySymbol,
);

/// The repository all data flows through.
final Provider<TransactionRepository> transactionRepositoryProvider =
    Provider<TransactionRepository>(
  (Ref ref) => TransactionRepository(ref.watch(appDatabaseProvider)),
);

/// Currently-viewed month (normalised to the first of the month).
final StateProvider<DateTime> selectedMonthProvider =
    StateProvider<DateTime>((Ref ref) => DateUtilsX.monthStart(DateTime.now()));

/// Bumped after every write so dependent [FutureProvider]s re-run. This keeps
/// the data layer simple (no streams) while still giving instant UI refresh.
final StateProvider<int> dataRefreshProvider =
    StateProvider<int>((Ref ref) => 0);

/// Aggregated summary for the selected month (dashboard + report).
final FutureProvider<MonthlySummary> monthlySummaryProvider =
    FutureProvider<MonthlySummary>((Ref ref) async {
  ref.watch(dataRefreshProvider);
  final DateTime month = ref.watch(selectedMonthProvider);
  return ref.watch(transactionRepositoryProvider).monthlySummary(month);
});

/// All transactions for the selected month (unfiltered).
final FutureProvider<List<TransactionItem>> monthTransactionsProvider =
    FutureProvider<List<TransactionItem>>((Ref ref) async {
  ref.watch(dataRefreshProvider);
  final DateTime month = ref.watch(selectedMonthProvider);
  return ref.watch(transactionRepositoryProvider).transactionsForMonth(month);
});

/// Active filter/search/sort spec for the Transactions screen.
final StateProvider<TransactionFilter> transactionFilterProvider =
    StateProvider<TransactionFilter>((Ref ref) => const TransactionFilter());

/// Month transactions with the active filter + sort applied.
final Provider<AsyncValue<List<TransactionItem>>> filteredTransactionsProvider =
    Provider<AsyncValue<List<TransactionItem>>>((Ref ref) {
  final AsyncValue<List<TransactionItem>> all =
      ref.watch(monthTransactionsProvider);
  final TransactionFilter filter = ref.watch(transactionFilterProvider);
  return all.whenData(filter.apply);
});

/// Most recent transactions overall (dashboard "Recent Transactions").
final FutureProvider<List<TransactionItem>> recentTransactionsProvider =
    FutureProvider<List<TransactionItem>>((Ref ref) async {
  ref.watch(dataRefreshProvider);
  return ref.watch(transactionRepositoryProvider).recentTransactions(limit: 8);
});

/// Trailing months' expense totals for the analytics bar chart.
final FutureProvider<List<MonthlyExpensePoint>> monthlyTrendProvider =
    FutureProvider<List<MonthlyExpensePoint>>((Ref ref) async {
  ref.watch(dataRefreshProvider);
  return ref.watch(transactionRepositoryProvider).monthlyExpenseTrend(months: 6);
});

/// Write-side controller. All mutations go through here so the single
/// [dataRefreshProvider] bump lives in one place.
class TransactionController {
  TransactionController(this._ref);

  final Ref _ref;

  TransactionRepository get _repo =>
      _ref.read(transactionRepositoryProvider);

  void _invalidate() {
    _ref.read(dataRefreshProvider.notifier).state++;
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _repo.addExpense(expense);
    _invalidate();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _repo.updateExpense(expense);
    _invalidate();
  }

  Future<void> deleteExpense(int id) async {
    await _repo.deleteExpense(id);
    _invalidate();
  }

  Future<void> addIncome(IncomeModel income) async {
    await _repo.addIncome(income);
    _invalidate();
  }

  Future<void> updateIncome(IncomeModel income) async {
    await _repo.updateIncome(income);
    _invalidate();
  }

  Future<void> deleteIncome(int id) async {
    await _repo.deleteIncome(id);
    _invalidate();
  }
}

final Provider<TransactionController> transactionControllerProvider =
    Provider<TransactionController>((Ref ref) => TransactionController(ref));
