import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/investment_model.dart';
import '../../widgets/section_header.dart';
import '../../widgets/summary_card.dart';

/// Investments tab: portfolio totals + SIP and stock holdings with manual
/// price updates for profit/loss tracking.
class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String symbol = ref.watch(currencySymbolProvider);
    final AsyncValue<PortfolioSummary> summaryAsync =
        ref.watch(portfolioSummaryProvider);
    final AsyncValue<List<InvestmentModel>> investmentsAsync =
        ref.watch(investmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add Investment',
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.addInvestment),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(dataRefreshProvider.notifier).state++;
          await ref.read(investmentsProvider.future);
        },
        child: investmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, _) => Center(child: Text('Error: $e')),
          data: (List<InvestmentModel> items) {
            final List<InvestmentModel> sips =
                items.where((InvestmentModel i) => !i.isStock).toList();
            final List<InvestmentModel> stocks =
                items.where((InvestmentModel i) => i.isStock).toList();
            final PortfolioSummary summary =
                summaryAsync.value ?? PortfolioSummary.empty;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: <Widget>[
                _PortfolioCards(summary: summary, symbol: symbol),
                const SizedBox(height: 8),
                const SectionHeader(title: 'SIPs'),
                if (sips.isEmpty)
                  const _EmptySection(
                    icon: Icons.autorenew,
                    message: 'No SIPs yet. Tap + to add one.',
                  )
                else
                  ...sips.map((InvestmentModel i) =>
                      _SipTile(investment: i, symbol: symbol)),
                const SizedBox(height: 8),
                const SectionHeader(title: 'Stock Holdings'),
                if (stocks.isEmpty)
                  const _EmptySection(
                    icon: Icons.show_chart,
                    message: 'No stocks yet. Tap + to add a holding.',
                  )
                else
                  ...stocks.map((InvestmentModel i) =>
                      _StockTile(investment: i, symbol: symbol)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PortfolioCards extends StatelessWidget {
  const _PortfolioCards({required this.summary, required this.symbol});

  final PortfolioSummary summary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final bool gain = summary.profitLoss >= 0;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SummaryCard(
                label: 'Total Invested',
                value: Formatters.money(summary.totalInvested, symbol),
                icon: Icons.account_balance,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                label: 'Current Value',
                value: Formatters.money(summary.currentValue, symbol),
                icon: Icons.pie_chart,
                color: AppColors.savings,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SummaryCard(
          label: 'Profit / Loss',
          value: Formatters.signedMoney(summary.profitLoss, symbol),
          icon: gain ? Icons.trending_up : Icons.trending_down,
          color: gain ? AppColors.income : AppColors.expense,
        ),
      ],
    );
  }
}

class _SipTile extends ConsumerWidget {
  const _SipTile({required this.investment, required this.symbol});

  final InvestmentModel investment;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.14),
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.autorenew),
        ),
        title: Text(investment.name),
        subtitle: Text('Since ${Formatters.fullDate(investment.date)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${Formatters.money(investment.amount, symbol)}/mo',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            _InvestmentMenu(investment: investment, symbol: symbol),
          ],
        ),
        onTap: () =>
            context.push(AppRoutes.editInvestment, extra: investment),
      ),
    );
  }
}

class _StockTile extends ConsumerWidget {
  const _StockTile({required this.investment, required this.symbol});

  final InvestmentModel investment;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double pl = investment.profitLoss;
    final bool gain = pl >= 0;
    final double plPercent = investment.investedValue > 0
        ? pl / investment.investedValue * 100
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (gain ? AppColors.income : AppColors.expense).withValues(alpha: 0.14),
          foregroundColor: gain ? AppColors.income : AppColors.expense,
          child: const Icon(Icons.show_chart),
        ),
        title: Text(investment.name),
        subtitle: Text(
          '${_trim(investment.quantity ?? 0)} @ '
          '${Formatters.money(investment.buyPrice ?? 0, symbol)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  Formatters.money(investment.currentValue, symbol),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${gain ? '+' : ''}${plPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: gain ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            _InvestmentMenu(investment: investment, symbol: symbol),
          ],
        ),
        onTap: () =>
            context.push(AppRoutes.editInvestment, extra: investment),
      ),
    );
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
}

/// Shared overflow menu: Update Price (stocks), Edit, Delete.
class _InvestmentMenu extends ConsumerWidget {
  const _InvestmentMenu({required this.investment, required this.symbol});

  final InvestmentModel investment;
  final String symbol;

  Future<void> _updatePrice(BuildContext context, WidgetRef ref) async {
    final TextEditingController controller = TextEditingController(
      text: investment.currentPrice?.toString() ?? '',
    );
    final double? price = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Update ${investment.name} price'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Current price (per share)',
              prefixText: '$symbol ',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final double? v = double.tryParse(controller.text.trim());
                Navigator.of(dialogContext).pop(v);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    if (price != null && price > 0) {
      await ref
          .read(investmentControllerProvider)
          .updateCurrentPrice(investment, price);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete ${investment.name}?'),
          content: const Text(
            'The linked expense entry will also be removed from your records.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.expense,
                minimumSize: Size.zero,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed ?? false) {
      await ref.read(investmentControllerProvider).deleteInvestment(investment);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (String action) {
        switch (action) {
          case 'price':
            _updatePrice(context, ref);
          case 'edit':
            context.push(AppRoutes.editInvestment, extra: investment);
          case 'delete':
            _delete(context, ref);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (investment.isStock)
          const PopupMenuItem<String>(
            value: 'price',
            child: ListTile(
              leading: Icon(Icons.currency_rupee),
              title: Text('Update Price'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
