import 'package:intl/intl.dart';

/// Currency + date formatting helpers used by every screen.
///
/// The active currency symbol comes from Settings; number grouping uses the
/// Indian locale grouping by default (matches the PRD's ₹ examples) but works
/// for any symbol.
class Formatters {
  const Formatters._();

  static final NumberFormat _grouped = NumberFormat.decimalPattern('en_IN');

  /// e.g. `₹45,000` or `₹1,250.50` (drops trailing `.00`).
  static String money(double amount, String symbol) {
    final double abs = amount.abs();
    final String number = abs == abs.roundToDouble()
        ? _grouped.format(abs.round())
        : _grouped.format(abs);
    final String sign = amount < 0 ? '-' : '';
    return '$sign$symbol$number';
  }

  /// Signed money with an explicit leading `+` for positive values
  /// (used for income rows, e.g. `+₹20,000`).
  static String signedMoney(double amount, String symbol) {
    if (amount > 0) return '+${money(amount, symbol)}';
    return money(amount, symbol);
  }

  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);
  static String fullDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String monthShort(DateTime d) => DateFormat('MMM').format(d);
  static String time(DateTime d) => DateFormat('h:mm a').format(d);
  static String weekdayFull(DateTime d) => DateFormat('EEEE, d MMM').format(d);
}
