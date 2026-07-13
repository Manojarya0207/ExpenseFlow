import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';

/// Owns the single [Database] handle and creates the schema (PRD §8).
///
/// A tiny lazy singleton — the app opens exactly one connection and every
/// repository shares it.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final String dir = await getDatabasesPath();
    final String path = p.join(dir, DbConstants.databaseName);
    return openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.tableIncome} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colAmount} REAL NOT NULL,
        ${DbConstants.colCategory} TEXT NOT NULL,
        ${DbConstants.colNotes} TEXT,
        ${DbConstants.colDate} TEXT NOT NULL,
        ${DbConstants.colCreatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tableExpense} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colAmount} REAL NOT NULL,
        ${DbConstants.colCategory} TEXT NOT NULL,
        ${DbConstants.colPaymentMethod} TEXT NOT NULL,
        ${DbConstants.colNotes} TEXT,
        ${DbConstants.colDate} TEXT NOT NULL,
        ${DbConstants.colImage} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tableBudget} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colCategory} TEXT NOT NULL UNIQUE,
        ${DbConstants.colAmount} REAL NOT NULL
      )
    ''');

    // Helpful indexes for month-range and search queries.
    await db.execute(
      'CREATE INDEX idx_expense_date ON ${DbConstants.tableExpense}(${DbConstants.colDate})',
    );
    await db.execute(
      'CREATE INDEX idx_income_date ON ${DbConstants.tableIncome}(${DbConstants.colDate})',
    );
  }

  /// Test/utility hook to inject an in-memory database.
  // ignore: use_setters_to_change_properties
  void overrideForTesting(Database db) {
    _db = db;
  }
}
