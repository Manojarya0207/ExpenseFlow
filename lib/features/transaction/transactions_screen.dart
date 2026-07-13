import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_categories.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repository/transaction_filter.dart';
import '../../data/repository/transaction_repository.dart';
import '../../widgets/section_header.dart';
import '../../widgets/transaction_tile.dart';
import '../expense/expense_form_screen.dart';
import '../income/income_form_screen.dart';

/// Transactions tab: searchable, filterable, sortable list for the selected
/// month with edit + delete (§5.4, §5.8).
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    ref.read(transactionFilterProvider.notifier).update(
          (TransactionFilter f) => f.copyWith(query: value),
        );
  }

  void _setType(TypeFilter type) {
    ref.read(transactionFilterProvider.notifier).update(
          (TransactionFilter f) => f.copyWith(type: type),
        );
  }

  Future<void> _openEdit(TransactionItem item) async {
    final TransactionRepository repo =
        ref.read(transactionRepositoryProvider);
    if (item.isExpense) {
      final ExpenseModel? model = await repo.getExpense(item.id);
      if (model == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExpenseFormScreen(existing: model),
        ),
      );
    } else {
      final IncomeModel? model = await repo.getIncome(item.id);
      if (model == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => IncomeFormScreen(existing: model),
        ),
      );
    }
  }

  Future<void> _confirmDelete(TransactionItem item) async {
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: Text(
              'This will permanently remove the ${item.category} '
              '${item.isIncome ? 'income' : 'expense'}.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    final TransactionController controller =
        ref.read(transactionControllerProvider);
    if (item.isExpense) {
      await controller.deleteExpense(item.id);
    } else {
      await controller.deleteIncome(item.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String symbol = ref.watch(currencySymbolProvider);
    final TransactionFilter filter = ref.watch(transactionFilterProvider);
    final AsyncValue<List<TransactionItem>> itemsAsync =
        ref.watch(filteredTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Filter & sort',
            icon: Badge(
              isLabelVisible: filter.category != null ||
                  filter.paymentMethod != null ||
                  filter.sort != TransactionSort.dateDesc,
              child: const Icon(Icons.tune),
            ),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _setQuery,
              decoration: InputDecoration(
                hintText: 'Search food, fuel, salary…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _setQuery('');
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                _typeChip('All', TypeFilter.all, filter.type),
                _typeChip('Income', TypeFilter.income, filter.type),
                _typeChip('Expense', TypeFilter.expense, filter.type),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: itemsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(child: Text('Error: $e')),
              data: (List<TransactionItem> items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: filter.isActive
                        ? Icons.search_off
                        : Icons.receipt_long,
                    title: filter.isActive
                        ? 'No matching transactions'
                        : 'No transactions this month',
                    message: filter.isActive
                        ? 'Try changing your search or filters.'
                        : 'Add income or expenses to see them here.',
                  );
                }
                return _GroupedList(
                  items: items,
                  symbol: symbol,
                  onTap: _openEdit,
                  onDelete: _confirmDelete,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, TypeFilter value, TypeFilter selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected == value,
        onSelected: (_) => _setType(value),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) => const _FilterSheet(),
    );
  }
}

/// A list grouped by day with sticky-style date headers.
class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.items,
    required this.symbol,
    required this.onTap,
    required this.onDelete,
  });

  final List<TransactionItem> items;
  final String symbol;
  final void Function(TransactionItem) onTap;
  final void Function(TransactionItem) onDelete;

  @override
  Widget build(BuildContext context) {
    // Build a flat list of headers + tiles preserving incoming order.
    final List<Object> rows = <Object>[];
    DateTime? lastDay;
    for (final TransactionItem item in items) {
      final DateTime day = DateUtilsX.dateOnly(item.date);
      if (lastDay == null || !DateUtilsX.sameDay(day, lastDay)) {
        rows.add(day);
        lastDay = day;
      }
      rows.add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int index) {
        final Object row = rows[index];
        if (row is DateTime) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 2),
            child: SectionHeader(title: Formatters.weekdayFull(row)),
          );
        }
        final TransactionItem item = row as TransactionItem;
        return Dismissible(
          key: ValueKey<String>('${item.type}-${item.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            onDelete(item);
            return false; // deletion handled via provider refresh
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          child: TransactionTile(
            item: item,
            currencySymbol: symbol,
            onTap: () => onTap(item),
          ),
        );
      },
    );
  }
}

/// Bottom sheet for category/payment/sort filtering (§5.4 filter options).
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionFilter filter = ref.watch(transactionFilterProvider);
    final StateController<TransactionFilter> notifier =
        ref.read(transactionFilterProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(title: 'Sort by'),
          Wrap(
            spacing: 8,
            children: <Widget>[
              _sortChip(notifier, filter, 'Newest', TransactionSort.dateDesc),
              _sortChip(notifier, filter, 'Oldest', TransactionSort.dateAsc),
              _sortChip(
                  notifier, filter, 'Amount ↑', TransactionSort.amountAsc),
              _sortChip(
                  notifier, filter, 'Amount ↓', TransactionSort.amountDesc),
            ],
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Category'),
          DropdownButtonFormField<String?>(
            initialValue: filter.category,
            isExpanded: true,
            decoration: const InputDecoration(hintText: 'Any category'),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                child: Text('Any category'),
              ),
              ...<String>{...AppCategories.expense, ...AppCategories.income}
                  .map((String c) =>
                      DropdownMenuItem<String?>(value: c, child: Text(c))),
            ],
            onChanged: (String? v) {
              notifier.state = v == null
                  ? filter.copyWith(clearCategory: true)
                  : filter.copyWith(category: v);
            },
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: 'Payment method'),
          DropdownButtonFormField<String?>(
            initialValue: filter.paymentMethod,
            isExpanded: true,
            decoration: const InputDecoration(hintText: 'Any method'),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                child: Text('Any method'),
              ),
              ...AppCategories.paymentMethods.map((String m) =>
                  DropdownMenuItem<String?>(value: m, child: Text(m))),
            ],
            onChanged: (String? v) {
              notifier.state = v == null
                  ? filter.copyWith(clearPaymentMethod: true)
                  : filter.copyWith(paymentMethod: v);
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    notifier.state = TransactionFilter(query: filter.query);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sortChip(
    StateController<TransactionFilter> notifier,
    TransactionFilter filter,
    String label,
    TransactionSort sort,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: filter.sort == sort,
      onSelected: (_) => notifier.state = filter.copyWith(sort: sort),
    );
  }
}
