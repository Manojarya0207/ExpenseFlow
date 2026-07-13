import 'package:flutter/material.dart';

import '../core/constants/app_categories.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../data/models/transaction_item.dart';

/// A single row in any transaction list: leading category icon, category +
/// meta, and a signed amount colored by type (§5.1, §5.4).
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    required this.currencySymbol,
    this.onTap,
    this.showTime = true,
  });

  final TransactionItem item;
  final String currencySymbol;
  final VoidCallback? onTap;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final Color color = item.isIncome ? AppColors.income : AppColors.expense;
    final IconData icon = item.isIncome
        ? AppCategories.incomeIcon(item.category)
        : AppCategories.expenseIcon(item.category);

    final List<String> metaParts = <String>[
      if (showTime) Formatters.time(item.date),
      if (item.paymentMethod != null) item.paymentMethod!,
      if ((item.notes ?? '').trim().isNotEmpty) item.notes!.trim(),
    ];

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        foregroundColor: color,
        child: Icon(icon, size: 20),
      ),
      title: Text(
        item.category,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: metaParts.isEmpty
          ? null
          : Text(
              metaParts.join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Text(
        Formatters.signedMoney(item.signedAmount, currencySymbol),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 15,
        ),
      ),
    );
  }
}
