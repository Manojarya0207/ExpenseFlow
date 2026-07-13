import '../../core/constants/db_constants.dart';

/// A per-category spending budget. Maps to the `budget` table (PRD §8).
///
/// Budget *enforcement* (warnings/notifications) is deferred to a later pass,
/// but the model and table exist now so the schema is stable.
class BudgetModel {
  const BudgetModel({
    this.id,
    required this.category,
    required this.amount,
  });

  final int? id;
  final String category;
  final double amount;

  BudgetModel copyWith({int? id, String? category, double? amount}) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      DbConstants.colId: id,
      DbConstants.colCategory: category,
      DbConstants.colAmount: amount,
    };
  }

  factory BudgetModel.fromMap(Map<String, Object?> map) {
    return BudgetModel(
      id: map[DbConstants.colId] as int?,
      category: map[DbConstants.colCategory] as String,
      amount: (map[DbConstants.colAmount] as num).toDouble(),
    );
  }
}
