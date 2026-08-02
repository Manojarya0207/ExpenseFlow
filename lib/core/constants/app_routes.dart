/// Route path + name constants for go_router.
class AppRoutes {
  const AppRoutes._();

  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String analytics = '/analytics';
  static const String investments = '/investments';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static const String addExpense = '/expense/add';
  static const String editExpense = '/expense/edit'; // + /:id
  static const String addIncome = '/income/add';
  static const String editIncome = '/income/edit'; // + /:id
  static const String addInvestment = '/investment/add';
  static const String editInvestment = '/investment/edit';
}
