import '../../core/constants/db_constants.dart';

/// A single income record. Maps 1:1 to the `income` table (PRD §8).
///
/// The PRD labels the income category column `category`; in the UI it is
/// surfaced as "Income Source".
class IncomeModel {
  const IncomeModel({
    this.id,
    required this.amount,
    required this.category,
    this.notes,
    required this.date,
    required this.createdAt,
  });

  final int? id;
  final double amount;
  final String category;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;

  IncomeModel copyWith({
    int? id,
    double? amount,
    String? category,
    String? notes,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      DbConstants.colId: id,
      DbConstants.colAmount: amount,
      DbConstants.colCategory: category,
      DbConstants.colNotes: notes,
      DbConstants.colDate: date.toIso8601String(),
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory IncomeModel.fromMap(Map<String, Object?> map) {
    return IncomeModel(
      id: map[DbConstants.colId] as int?,
      amount: (map[DbConstants.colAmount] as num).toDouble(),
      category: map[DbConstants.colCategory] as String,
      notes: map[DbConstants.colNotes] as String?,
      date: DateTime.parse(map[DbConstants.colDate] as String),
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
    );
  }
}
