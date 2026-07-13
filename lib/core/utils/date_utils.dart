/// Small date helpers for month-range math. All ranges are computed on the
/// local timezone since transactions are user-entered wall-clock dates.
class DateUtilsX {
  const DateUtilsX._();

  /// First instant of the month containing [d].
  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

  /// First instant of the month *after* the one containing [d]
  /// (exclusive upper bound for range queries).
  static DateTime nextMonthStart(DateTime d) => DateTime(d.year, d.month + 1);

  /// Number of days in the month containing [d].
  static int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

  /// True if [a] and [b] fall in the same calendar month.
  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// True if [a] and [b] fall on the same calendar day.
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Date-only (midnight) version of [d].
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
