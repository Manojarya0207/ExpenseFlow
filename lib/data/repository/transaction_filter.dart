import '../models/transaction_item.dart';

/// Which transaction types to include in the Transactions list (§5.4).
enum TypeFilter { all, income, expense }

/// How the merged transaction list is ordered.
enum TransactionSort {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
}

/// A composable filter/sort/search spec applied client-side over the merged
/// transaction stream. Kept immutable so it can back a Riverpod state object.
class TransactionFilter {
  const TransactionFilter({
    this.type = TypeFilter.all,
    this.category,
    this.paymentMethod,
    this.query = '',
    this.sort = TransactionSort.dateDesc,
  });

  final TypeFilter type;
  final String? category;
  final String? paymentMethod;
  final String query;
  final TransactionSort sort;

  bool get isActive =>
      type != TypeFilter.all ||
      category != null ||
      paymentMethod != null ||
      query.trim().isNotEmpty;

  TransactionFilter copyWith({
    TypeFilter? type,
    String? category,
    bool clearCategory = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
    String? query,
    TransactionSort? sort,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      category: clearCategory ? null : (category ?? this.category),
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }

  /// Apply this filter (and sort) to [items].
  List<TransactionItem> apply(List<TransactionItem> items) {
    final String q = query.trim().toLowerCase();
    final List<TransactionItem> result = items.where((TransactionItem t) {
      switch (type) {
        case TypeFilter.income:
          if (!t.isIncome) return false;
          break;
        case TypeFilter.expense:
          if (!t.isExpense) return false;
          break;
        case TypeFilter.all:
          break;
      }
      if (category != null && t.category != category) return false;
      if (paymentMethod != null && t.paymentMethod != paymentMethod) {
        return false;
      }
      if (q.isNotEmpty) {
        final String haystack =
            '${t.category} ${t.notes ?? ''} ${t.paymentMethod ?? ''}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    result.sort((TransactionItem a, TransactionItem b) {
      switch (sort) {
        case TransactionSort.dateDesc:
          return b.date.compareTo(a.date);
        case TransactionSort.dateAsc:
          return a.date.compareTo(b.date);
        case TransactionSort.amountDesc:
          return b.amount.compareTo(a.amount);
        case TransactionSort.amountAsc:
          return a.amount.compareTo(b.amount);
      }
    });
    return result;
  }
}
