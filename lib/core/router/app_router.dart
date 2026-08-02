import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../../data/models/investment_model.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/expense/expense_form_screen.dart';
import '../../features/income/income_form_screen.dart';
import '../../features/investment/investment_form_screen.dart';
import '../../features/investment/investments_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/transaction/transactions_screen.dart';
import '../../widgets/app_scaffold.dart';

/// Top-level go_router with a persistent bottom-nav shell (§6) and
/// full-screen add/edit routes pushed on top.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
          StatefulNavigationShell shell) {
        return AppScaffold(shell: shell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (_, _) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.transactions,
              builder: (_, _) => const TransactionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.analytics,
              builder: (_, _) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.investments,
              builder: (_, _) => const InvestmentsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.reports,
              builder: (_, _) => const ReportsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.settings,
              builder: (_, _) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.addExpense,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const ExpenseFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.addIncome,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const IncomeFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.addInvestment,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const InvestmentFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.editInvestment,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, GoRouterState state) => InvestmentFormScreen(
        existing: state.extra as InvestmentModel?,
      ),
    ),
  ],
  navigatorKey: _rootNavigatorKey,
);

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();
