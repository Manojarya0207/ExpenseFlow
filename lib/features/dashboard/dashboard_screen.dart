import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/summary_models.dart';
import '../../data/models/transaction_item.dart';
import '../../widgets/section_header.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_tile.dart';

/// Home tab: current-month financial summary + quick actions (§5.1, §11).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _changeMonth(WidgetRef ref, int delta) {
    final DateTime current = ref.read(selectedMonthProvider);
    ref.read(selectedMonthProvider.notifier).state =
        DateTime(current.year, current.month + delta);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String symbol = ref.watch(currencySymbolProvider);
    final DateTime month = ref.watch(selectedMonthProvider);
    final AsyncValue<MonthlySummary> summaryAsync =
        ref.watch(monthlySummaryProvider);
    final AsyncValue<List<TransactionItem>> recentAsync =
        ref.watch(recentTransactionsProvider);
    final bool isCurrentMonth =
        DateUtilsX.sameMonth(month, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpenseFlow'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(dataRefreshProvider.notifier).state++;
          await ref.read(monthlySummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: <Widget>[
            _MonthSelector(
              month: month,
              onPrev: () => _changeMonth(ref, -1),
              onNext: isCurrentMonth ? null : () => _changeMonth(ref, 1),
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => const _SummarySkeleton(),
              error: (Object e, _) => _ErrorBox(message: '$e'),
              data: (MonthlySummary s) => _SummarySection(
                summary: s,
                symbol: symbol,
              ),
            ),
            const SizedBox(height: 16),
            _QuickActions(),
            const SizedBox(height: 8),
            SectionHeader(
              title: 'Recent Transactions',
              action: TextButton(
                onPressed: () => context.go(AppRoutes.transactions),
                child: const Text('See all'),
              ),
            ),
            recentAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object e, _) => _ErrorBox(message: '$e'),
              data: (List<TransactionItem> items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      icon: Icons.receipt_long,
                      title: 'No transactions yet',
                      message: 'Tap + to add your first income or expense.',
                    ),
                  );
                }
                return Column(
                  children: items
                      .map((TransactionItem t) => TransactionTile(
                            item: t,
                            currencySymbol: symbol,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton.filledTonal(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          Formatters.monthYear(month),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton.filledTonal(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary, required this.symbol});

  final MonthlySummary summary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: <Widget>[
            SummaryCard(
              label: 'Monthly Income',
              value: Formatters.money(summary.totalIncome, symbol),
              icon: Icons.arrow_downward,
              color: AppColors.income,
            ),
            SummaryCard(
              label: 'Monthly Expense',
              value: Formatters.money(summary.totalExpense, symbol),
              icon: Icons.arrow_upward,
              color: AppColors.expense,
            ),
            SummaryCard(
              label: 'Savings (This Month)',
              value: Formatters.money(summary.savings, symbol),
              icon: Icons.savings,
              color: AppColors.savings,
            ),
            SummaryCard(
              label: 'Total Balance',
              value: Formatters.money(summary.remainingBalance, symbol),
              icon: Icons.account_balance_wallet,
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricsCard(summary: summary, symbol: symbol),
      ],
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.summary, required this.symbol});

  final MonthlySummary summary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      ('Carried Forward', Formatters.money(summary.carryForward, symbol)),
      ('Avg. Daily Expense', Formatters.money(summary.averageDailyExpense, symbol)),
      ('Largest Expense', Formatters.money(summary.largestExpense, symbol)),
      (
        'Top Income Source',
        summary.topIncomeSource.isEmpty ? '—' : summary.topIncomeSource
      ),
      ('Total Transactions', '${summary.transactionCount}'),
      (
        'Budget Utilization',
        summary.budgetUtilization == null
            ? 'No budget set'
            : '${(summary.budgetUtilization! * 100).toStringAsFixed(0)}%'
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      rows[i].$1,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      rows[i].$2,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (i != rows.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.addExpense),
            icon: const Icon(Icons.remove),
            label: const Text('Expense'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.addIncome),
            icon: const Icon(Icons.add),
            label: const Text('Income'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.reports),
            icon: const Icon(Icons.bar_chart),
            label: const Text('Report'),
          ),
        ),
      ],
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Something went wrong.\n$message',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
