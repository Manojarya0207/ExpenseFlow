import '../../core/constants/db_constants.dart';

/// A single expense record. Maps 1:1 to the `expense` table (PRD §8).
class ExpenseModel {
  const ExpenseModel({
    this.id,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    this.notes,
    required this.date,
    this.image,
    required this.createdAt,
  });

  final int? id;
  final double amount;
  final String category;
  final String paymentMethod;
  final String? notes;
  final DateTime date;
  final String? image;
  final DateTime createdAt;

  ExpenseModel copyWith({
    int? id,
    double? amount,
    String? category,
    String? paymentMethod,
    String? notes,
    DateTime? date,
    String? image,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      DbConstants.colId: id,
      DbConstants.colAmount: amount,
      DbConstants.colCategory: category,
      DbConstants.colPaymentMethod: paymentMethod,
      DbConstants.colNotes: notes,
      DbConstants.colDate: date.toIso8601String(),
      DbConstants.colImage: image,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, Object?> map) {
    return ExpenseModel(
      id: map[DbConstants.colId] as int?,
      amount: (map[DbConstants.colAmount] as num).toDouble(),
      category: map[DbConstants.colCategory] as String,
      paymentMethod: (map[DbConstants.colPaymentMethod] as String?) ?? 'Cash',
      notes: map[DbConstants.colNotes] as String?,
      date: DateTime.parse(map[DbConstants.colDate] as String),
      image: map[DbConstants.colImage] as String?,
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
    );
  }
}
