import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/database/app_database.dart';
import '../../features/settings/settings_provider.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../data/models/investment_model.dart';
import '../../data/models/summary_models.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repository/investment_repository.dart';
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

/// Investment holdings repository.
final Provider<InvestmentRepository> investmentRepositoryProvider =
    Provider<InvestmentRepository>(
  (Ref ref) => InvestmentRepository(ref.watch(appDatabaseProvider)),
);

/// All investment holdings, newest first.
final FutureProvider<List<InvestmentModel>> investmentsProvider =
    FutureProvider<List<InvestmentModel>>((Ref ref) async {
  ref.watch(dataRefreshProvider);
  return ref.watch(investmentRepositoryProvider).getInvestments();
});

/// Portfolio totals for the Investments summary cards.
final FutureProvider<PortfolioSummary> portfolioSummaryProvider =
    FutureProvider<PortfolioSummary>((Ref ref) async {
  ref.watch(dataRefreshProvider);
  return ref.watch(investmentRepositoryProvider).portfolioSummary();
});

/// Write-side controller for investments. Each purchase also creates a linked
/// expense (category 'Investment') so monthly balances reflect the money that
/// left the pocket; the linked row is kept in sync on edit and delete so
/// totals never drift.
class InvestmentController {
  InvestmentController(this._ref);

  final Ref _ref;

  InvestmentRepository get _repo => _ref.read(investmentRepositoryProvider);

  TransactionRepository get _txRepo =>
      _ref.read(transactionRepositoryProvider);

  void _invalidate() {
    _ref.read(dataRefreshProvider.notifier).state++;
  }

  ExpenseModel _linkedExpense(InvestmentModel investment, {int? id}) {
    return ExpenseModel(
      id: id,
      amount: investment.investedValue,
      category: 'Investment',
      paymentMethod: 'Net Banking',
      notes: '${investment.type.label}: ${investment.name}',
      date: investment.date,
      createdAt: investment.createdAt,
    );
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    final int expenseId = await _txRepo.addExpense(_linkedExpense(investment));
    await _repo.addInvestment(
      investment.copyWith(linkedExpenseId: expenseId),
    );
    _invalidate();
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    await _repo.updateInvestment(investment);
    final int? expenseId = investment.linkedExpenseId;
    if (expenseId != null) {
      await _txRepo.updateExpense(
        _linkedExpense(investment, id: expenseId),
      );
    }
    _invalidate();
  }

  /// Update just the manually-tracked market price (stocks). The invested
  /// amount is unchanged, so the linked expense is left alone.
  Future<void> updateCurrentPrice(
      InvestmentModel investment, double price) async {
    await _repo.updateInvestment(investment.copyWith(currentPrice: price));
    _invalidate();
  }

  Future<void> deleteInvestment(InvestmentModel investment) async {
    if (investment.id != null) {
      await _repo.deleteInvestment(investment.id!);
    }
    if (investment.linkedExpenseId != null) {
      await _txRepo.deleteExpense(investment.linkedExpenseId!);
    }
    _invalidate();
  }
}

final Provider<InvestmentController> investmentControllerProvider =
    Provider<InvestmentController>((Ref ref) => InvestmentController(ref));
