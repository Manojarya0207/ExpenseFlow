import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_generator.dart';
import '../../data/models/summary_models.dart';
import '../../data/models/transaction_item.dart';
import '../../widgets/section_header.dart';

/// Reports tab: monthly income/expense/savings breakdown with progress bars
/// (§5.5). PDF/Excel/CSV export is deferred to a later pass.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String symbol = ref.watch(currencySymbolProvider);
    final DateTime month = ref.watch(selectedMonthProvider);
    final AsyncValue<MonthlySummary> summaryAsync =
        ref.watch(monthlySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              final MonthlySummary? summary = summaryAsync.value;
              if (summary == null) return;
              
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating PDF Report...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                final List<TransactionItem> transactions =
                    await ref.read(monthTransactionsProvider.future);
                
                await PdfGenerator.exportMonthlyReport(
                  summary: summary,
                  transactions: transactions,
                  currencySymbol: symbol,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error generating PDF: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Error: $e')),
        data: (MonthlySummary s) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: <Widget>[
            Text(
              Formatters.monthYear(month),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _TotalsCard(summary: s, symbol: symbol),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Monthly Progress'),
            _ProgressCard(summary: s, symbol: symbol),
            const SizedBox(height: 16),
            if (s.categoryTotals.isNotEmpty) ...<Widget>[
              const SectionHeader(title: 'Top Categories'),
              _CategoryBreakdown(summary: s, symbol: symbol),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.summary, required this.symbol});

  final MonthlySummary summary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _row(context, 'Income',
                Formatters.money(summary.totalIncome, symbol), AppColors.income),
            const Divider(height: 20),
            _row(context, 'Expense',
                Formatters.money(summary.totalExpense, symbol),
                AppColors.expense),
            const Divider(height: 20),
            _row(context, 'Savings',
                Formatters.money(summary.savings, symbol), AppColors.savings),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.summary, required this.symbol});

  final MonthlySummary summary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    // Normalise bars against income (or expense if income is zero) so the
    // relative sizes are meaningful.
    final double base = summary.totalIncome > 0
        ? summary.totalIncome
        : (summary.totalExpense > 0 ? summary.totalExpense : 1);
    final double savings = summary.savings.clamp(0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _bar(context, 'Income', summary.totalIncome / base,
                AppColors.income),
            const SizedBox(height: 16),
            _bar(context, 'Expense', summary.totalExpense / base,
                AppColors.expense),
            const SizedBox(height: 16),
            _bar(context, 'Savings', savings / base, AppColors.savings),
          ],
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, String label, double fraction,
      Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.summary, required this.symbol});

  final MonthlySummary summary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final List<CategoryTotal> top = summary.categoryTotals.take(5).toList();
    final double total = summary.totalExpense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < top.length; i++) ...<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(top[i].category),
                  Text(
                    '${Formatters.money(top[i].amount, symbol)}'
                    '${total > 0 ? '  (${(top[i].amount / total * 100).round()}%)' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (i != top.length - 1) const Divider(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
