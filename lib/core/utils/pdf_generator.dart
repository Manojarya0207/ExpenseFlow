import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/summary_models.dart';
import '../../data/models/transaction_item.dart';
import 'formatters.dart';

/// Builds the monthly PDF report: financial summary (with carry-forward),
/// expenses grouped category-wise with per-category totals, and income
/// grouped by source.
class PdfGenerator {
  static const PdfColor _blue = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor _blueLight = PdfColor.fromInt(0xFFE3F0FB);

  static const pw.TableBorder _tableBorder = pw.TableBorder(
    horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
  );

  static pw.Widget _sectionTitle(String text) => pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: _blue,
        ),
      );

  /// Header band above a category/source group: name left, total + share right.
  static pw.Widget _groupHeader(String name, String total, String share) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: _blueLight,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            name,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _blue),
          ),
          pw.Text(
            '$total  ($share)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _blue),
          ),
        ],
      ),
    );
  }

  static pw.Widget _rowsTable(
      List<String> headers, List<List<String>> data) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: _tableBorder,
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  static Future<void> exportMonthlyReport({
    required MonthlySummary summary,
    required List<TransactionItem> transactions,
    required String currencySymbol,
  }) async {
    final pw.Document pdf = pw.Document();

    // Income grouped by source, largest first.
    final Map<String, List<TransactionItem>> incomeBySource =
        <String, List<TransactionItem>>{};
    for (final TransactionItem t in transactions.where(
        (TransactionItem t) => t.isIncome)) {
      incomeBySource.putIfAbsent(t.category, () => <TransactionItem>[]).add(t);
    }
    final List<MapEntry<String, List<TransactionItem>>> incomeGroups =
        incomeBySource.entries.toList()
          ..sort((MapEntry<String, List<TransactionItem>> a,
                  MapEntry<String, List<TransactionItem>> b) =>
              _sum(b.value).compareTo(_sum(a.value)));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Text('ExpenseFlow Report',
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: _blue)),
                  pw.Text(Formatters.monthYear(summary.month),
                      style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Totals Section
            _sectionTitle('Financial Summary'),
            pw.SizedBox(height: 10),
            _rowsTable(
              <String>['Metric', 'Amount'],
              <List<String>>[
                <String>['Total Income', Formatters.money(summary.totalIncome, currencySymbol)],
                <String>['Total Expense', Formatters.money(summary.totalExpense, currencySymbol)],
                <String>['Savings (This Month)', Formatters.money(summary.savings, currencySymbol)],
                <String>['Carried Forward', Formatters.money(summary.carryForward, currencySymbol)],
                <String>['Total Balance', Formatters.money(summary.remainingBalance, currencySymbol)],
              ],
            ),
            pw.SizedBox(height: 24),

            // Category-wise expense breakdown: header + transactions per category.
            if (summary.categoryTotals.isNotEmpty) ...<pw.Widget>[
              _sectionTitle('Expenses by Category'),
              for (final CategoryTotal cat in summary.categoryTotals) ...<pw.Widget>[
                _groupHeader(
                  cat.category,
                  Formatters.money(cat.amount, currencySymbol),
                  '${(summary.totalExpense > 0 ? cat.amount / summary.totalExpense * 100 : 0).toStringAsFixed(1)}%',
                ),
                pw.SizedBox(height: 4),
                _rowsTable(
                  <String>['Date', 'Payment', 'Notes', 'Amount'],
                  transactions
                      .where((TransactionItem t) =>
                          t.isExpense && t.category == cat.category)
                      .map((TransactionItem t) => <String>[
                            Formatters.fullDate(t.date),
                            t.paymentMethod ?? '',
                            t.notes?.trim() ?? '',
                            Formatters.money(t.amount, currencySymbol),
                          ])
                      .toList(),
                ),
              ],
              pw.SizedBox(height: 24),
            ],

            // Income grouped by source.
            if (incomeGroups.isNotEmpty) ...<pw.Widget>[
              _sectionTitle('Income by Source'),
              for (final MapEntry<String, List<TransactionItem>> group
                  in incomeGroups) ...<pw.Widget>[
                _groupHeader(
                  group.key,
                  Formatters.money(_sum(group.value), currencySymbol),
                  '${(summary.totalIncome > 0 ? _sum(group.value) / summary.totalIncome * 100 : 0).toStringAsFixed(1)}%',
                ),
                pw.SizedBox(height: 4),
                _rowsTable(
                  <String>['Date', 'Notes', 'Amount'],
                  group.value
                      .map((TransactionItem t) => <String>[
                            Formatters.fullDate(t.date),
                            t.notes?.trim() ?? '',
                            Formatters.money(t.amount, currencySymbol),
                          ])
                      .toList(),
                ),
              ],
            ],
          ];
        },
      ),
    );

    final String docName = 'ExpenseFlow_${Formatters.monthYear(summary.month).replaceAll(' ', '_')}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: docName,
    );
  }

  static double _sum(List<TransactionItem> items) =>
      items.fold(0, (double s, TransactionItem t) => s + t.amount);
}
