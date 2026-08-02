/// App-wide database constants: table + column names, kept in one place so
/// the database schema and mapping code never drift apart.
class DbConstants {
  const DbConstants._();

  static const String databaseName = 'expenseflow.db';
  static const int databaseVersion = 2;

  static const String tableExpense = 'expense';
  static const String tableIncome = 'income';
  static const String tableBudget = 'budget';
  static const String tableInvestment = 'investment';

  // Shared columns.
  static const String colId = 'id';
  static const String colAmount = 'amount';
  static const String colCategory = 'category';
  static const String colNotes = 'notes';
  static const String colDate = 'date';
  static const String colCreatedAt = 'createdAt';

  // Expense-only columns.
  static const String colPaymentMethod = 'paymentMethod';
  static const String colImage = 'image';

  // Investment-only columns.
  static const String colType = 'type';
  static const String colName = 'name';
  static const String colQuantity = 'quantity';
  static const String colBuyPrice = 'buyPrice';
  static const String colCurrentPrice = 'currentPrice';
  static const String colLinkedExpenseId = 'linkedExpenseId';
}
