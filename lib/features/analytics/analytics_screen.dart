import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/summary_models.dart';
import '../../widgets/section_header.dart';

/// Analytics tab: category pie chart + monthly-expense bar chart (§5.6).
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String symbol = ref.watch(currencySymbolProvider);
    final DateTime month = ref.watch(selectedMonthProvider);
    final AsyncValue<MonthlySummary> summaryAsync =
        ref.watch(monthlySummaryProvider);
    final AsyncValue<List<MonthlyExpensePoint>> trendAsync =
        ref.watch(monthlyTrendProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: <Widget>[
          Text(
            Formatters.monthYear(month),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Spending by Category'),
          summaryAsync.when(
            loading: () => const _ChartLoader(),
            error: (Object e, _) => Text('Error: $e'),
            data: (MonthlySummary s) => s.categoryTotals.isEmpty
                ? const _NoData(message: 'No expenses to chart this month.')
                : _CategoryPie(
                    totals: s.categoryTotals,
                    total: s.totalExpense,
                    symbol: symbol,
                  ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Monthly Expense Comparison'),
          trendAsync.when(
            loading: () => const _ChartLoader(),
            error: (Object e, _) => Text('Error: $e'),
            data: (List<MonthlyExpensePoint> points) {
              final bool allZero =
                  points.every((MonthlyExpensePoint p) => p.amount == 0);
              return allZero
                  ? const _NoData(message: 'No expense history yet.')
                  : _ExpenseBars(points: points, symbol: symbol);
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({
    required this.totals,
    required this.total,
    required this.symbol,
  });

  final List<CategoryTotal> totals;
  final double total;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  sections: <PieChartSectionData>[
                    for (int i = 0; i < totals.length; i++)
                      PieChartSectionData(
                        value: totals[i].amount,
                        color: AppColors.chartColor(i),
                        radius: 56,
                        title: total > 0
                            ? '${(totals[i].amount / total * 100).round()}%'
                            : '',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: <Widget>[
                for (int i = 0; i < totals.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.chartColor(i),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(totals[i].category)),
                        Text(
                          Formatters.money(totals[i].amount, symbol),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseBars extends StatelessWidget {
  const _ExpenseBars({required this.points, required this.symbol});

  final List<MonthlyExpensePoint> points;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final double maxY = points
        .map((MonthlyExpensePoint p) => p.amount)
        .fold<double>(0, (double m, double v) => v > m ? v : m);
    final double interval = maxY <= 0 ? 1 : maxY / 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY <= 0 ? 1 : maxY * 1.2,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: interval,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        _compact(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final int i = value.toInt();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          Formatters.monthShort(points[i].month),
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: <BarChartGroupData>[
                for (int i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: points[i].amount,
                        color: AppColors.primary,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _compact(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}

class _ChartLoader extends StatelessWidget {
  const _ChartLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
