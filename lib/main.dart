import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: ExpenseFlowApp()));
}

class ExpenseFlowApp extends ConsumerWidget {
  const ExpenseFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(settingsProvider).themeMode;
    return MaterialApp.router(
      title: 'ExpenseFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
