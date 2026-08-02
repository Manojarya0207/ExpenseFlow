import '../../core/constants/db_constants.dart';

/// Kind of investment holding.
enum InvestmentType {
  sip('SIP'),
  stock('Stock');

  const InvestmentType(this.label);

  final String label;

  static InvestmentType fromLabel(String label) =>
      label == stock.label ? stock : sip;
}

/// A single investment holding (SIP or stock). Maps 1:1 to the `investment`
/// table (schema v2). Stock-only fields are null for SIPs.
class InvestmentModel {
  const InvestmentModel({
    this.id,
    required this.type,
    required this.name,
    required this.amount,
    this.quantity,
    this.buyPrice,
    this.currentPrice,
    required this.date,
    this.notes,
    this.linkedExpenseId,
    required this.createdAt,
  });

  final int? id;
  final InvestmentType type;

  /// Stock symbol / fund name.
  final String name;

  /// SIP: monthly amount. Stock: total invested (quantity x buy price).
  final double amount;

  /// Number of shares (stock only).
  final double? quantity;

  /// Purchase price per share (stock only).
  final double? buyPrice;

  /// Latest market price per share, updated manually (stock only).
  final double? currentPrice;

  /// Buy date (stock) or SIP start date.
  final DateTime date;
  final String? notes;

  /// Expense row created alongside so the purchase shows in monthly totals;
  /// deleted together with this holding.
  final int? linkedExpenseId;
  final DateTime createdAt;

  bool get isStock => type == InvestmentType.stock;

  /// Money put in: SIP monthly amount, or stock quantity x buy price.
  double get investedValue =>
      isStock ? (quantity ?? 0) * (buyPrice ?? 0) : amount;

  /// Market value now; falls back to buy price until a current price is set.
  double get currentValue => isStock
      ? (quantity ?? 0) * (currentPrice ?? buyPrice ?? 0)
      : amount;

  double get profitLoss => currentValue - investedValue;

  InvestmentModel copyWith({
    int? id,
    InvestmentType? type,
    String? name,
    double? amount,
    double? quantity,
    double? buyPrice,
    double? currentPrice,
    DateTime? date,
    String? notes,
    int? linkedExpenseId,
    DateTime? createdAt,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      linkedExpenseId: linkedExpenseId ?? this.linkedExpenseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      DbConstants.colId: id,
      DbConstants.colType: type.label,
      DbConstants.colName: name,
      DbConstants.colAmount: amount,
      DbConstants.colQuantity: quantity,
      DbConstants.colBuyPrice: buyPrice,
      DbConstants.colCurrentPrice: currentPrice,
      DbConstants.colDate: date.toIso8601String(),
      DbConstants.colNotes: notes,
      DbConstants.colLinkedExpenseId: linkedExpenseId,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory InvestmentModel.fromMap(Map<String, Object?> map) {
    return InvestmentModel(
      id: map[DbConstants.colId] as int?,
      type: InvestmentType.fromLabel(map[DbConstants.colType] as String),
      name: map[DbConstants.colName] as String,
      amount: (map[DbConstants.colAmount] as num).toDouble(),
      quantity: (map[DbConstants.colQuantity] as num?)?.toDouble(),
      buyPrice: (map[DbConstants.colBuyPrice] as num?)?.toDouble(),
      currentPrice: (map[DbConstants.colCurrentPrice] as num?)?.toDouble(),
      date: DateTime.parse(map[DbConstants.colDate] as String),
      notes: map[DbConstants.colNotes] as String?,
      linkedExpenseId: map[DbConstants.colLinkedExpenseId] as int?,
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
    );
  }
}

/// Portfolio-level totals shown on the Investments dashboard cards.
class PortfolioSummary {
  const PortfolioSummary({
    required this.totalInvested,
    required this.currentValue,
  });

  final double totalInvested;
  final double currentValue;

  double get profitLoss => currentValue - totalInvested;

  static const PortfolioSummary empty =
      PortfolioSummary(totalInvested: 0, currentValue: 0);
}
