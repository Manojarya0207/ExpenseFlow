// Basic smoke test: the app boots and renders the dashboard shell.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expenseflow/main.dart';

void main() {
  testWidgets('App boots and shows the ExpenseFlow home tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ExpenseFlowApp()));
    await tester.pump();

    // App bar title on the dashboard.
    expect(find.text('ExpenseFlow'), findsWidgets);
    // The center FAB used to add a transaction.
    expect(find.byIcon(Icons.add), findsWidgets);
  });
}
