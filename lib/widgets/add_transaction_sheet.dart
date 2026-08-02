import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_colors.dart';

/// Bottom sheet shown by the FAB to choose between adding an expense or income
/// (§6 floating button → Add Transaction).
Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.expense.withValues(alpha: 0.14),
                foregroundColor: AppColors.expense,
                child: const Icon(Icons.arrow_upward),
              ),
              title: const Text('Add Expense'),
              subtitle: const Text('Record money you spent'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.addExpense);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.income.withValues(alpha: 0.14),
                foregroundColor: AppColors.income,
                child: const Icon(Icons.arrow_downward),
              ),
              title: const Text('Add Income'),
              subtitle: const Text('Record money you received'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.addIncome);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.trending_up),
              ),
              title: const Text('Add Investment'),
              subtitle: const Text('Record a SIP or stock purchase'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.addInvestment);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
