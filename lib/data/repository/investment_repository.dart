import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../database/app_database.dart';
import '../models/investment_model.dart';

/// Persistence + aggregation for investment holdings (SIPs and stocks).
///
/// Kept separate from [TransactionRepository]: investments are a distinct
/// domain with their own screen, and the linked-expense bookkeeping lives in
/// the controller layer, not here.
class InvestmentRepository {
  InvestmentRepository(this._db);

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  Future<int> addInvestment(InvestmentModel investment) async {
    final Database db = await _database;
    return db.insert(DbConstants.tableInvestment, investment.toMap());
  }

  Future<int> updateInvestment(InvestmentModel investment) async {
    final Database db = await _database;
    return db.update(
      DbConstants.tableInvestment,
      investment.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: <Object?>[investment.id],
    );
  }

  Future<int> deleteInvestment(int id) async {
    final Database db = await _database;
    return db.delete(
      DbConstants.tableInvestment,
      where: '${DbConstants.colId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// All holdings, newest first.
  Future<List<InvestmentModel>> getInvestments() async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      DbConstants.tableInvestment,
      orderBy: '${DbConstants.colDate} DESC',
    );
    return rows.map(InvestmentModel.fromMap).toList();
  }

  /// Totals across all holdings for the summary cards.
  Future<PortfolioSummary> portfolioSummary() async {
    final List<InvestmentModel> items = await getInvestments();
    double invested = 0;
    double current = 0;
    for (final InvestmentModel i in items) {
      invested += i.investedValue;
      current += i.currentValue;
    }
    return PortfolioSummary(totalInvested: invested, currentValue: current);
  }
}
