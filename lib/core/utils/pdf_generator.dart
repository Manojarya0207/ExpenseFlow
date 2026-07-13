import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/summary_models.dart';
import '../../data/models/transaction_item.dart';
import 'formatters.dart';

class PdfGenerator {
  static Future<void> exportMonthlyReport({
    required MonthlySummary summary,
    required List<TransactionItem> transactions,
    required String currencySymbol,
  }) async {
    final pw.Document pdf = pw.Document();

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
                  pw.Text('ExpenseFlow Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(Formatters.monthYear(summary.month), style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Totals Section
            pw.Text('Financial Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: <String>['Metric', 'Amount'],
              data: <List<String>>[
                <String>['Total Income', Formatters.money(summary.totalIncome, currencySymbol)],
                <String>['Total Expense', Formatters.money(summary.totalExpense, currencySymbol)],
                <String>['Net Savings', Formatters.money(summary.savings, currencySymbol)],
              ],
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 24),

            // Categories Section
            if (summary.categoryTotals.isNotEmpty) ...<pw.Widget>[
              pw.Text('Top Category Expenses', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: <String>['Category', 'Amount', 'Percentage'],
                data: summary.categoryTotals.map((CategoryTotal cat) {
                  final double pct = summary.totalExpense > 0 ? (cat.amount / summary.totalExpense * 100) : 0.0;
                  return <String>[
                    cat.category,
                    Formatters.money(cat.amount, currencySymbol),
                    '${pct.toStringAsFixed(1)}%',
                  ];
                }).toList(),
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 24),
            ],

            // Transactions Section
            if (transactions.isNotEmpty) ...<pw.Widget>[
              pw.Text('All Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: <String>['Date', 'Category', 'Type', 'Amount', 'Details'],
                data: transactions.map((TransactionItem t) {
                  final String type = t.isIncome ? 'Income' : 'Expense';
                  final String amt = Formatters.signedMoney(t.signedAmount, currencySymbol);
                  final String dateStr = Formatters.fullDate(t.date);
                  final String details = <String>[
                    if (t.paymentMethod != null) t.paymentMethod!,
                    if (t.notes != null && t.notes!.trim().isNotEmpty) t.notes!.trim(),
                  ].join(' - ');
                  return <String>[
                    dateStr,
                    t.category,
                    type,
                    amt,
                    details,
                  ];
                }).toList(),
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
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
}
