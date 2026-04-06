import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/admin_reports_model.dart';

class AdminReportsPdf {
  static Future<pw.Document> build({
    required AdminReportsSummary data,
    required DateTime from,
    required DateTime to,
  }) async {
    final df = DateFormat('yyyy-MM-dd');
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Admin Reports',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Date Range: ${df.format(from)} → ${df.format(to)}'),
          pw.SizedBox(height: 14),

          pw.Text('KPIs',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Bullet(text: 'Active Auctions: ${data.activeAuctions}'),
          pw.Bullet(text: 'Bids Count: ${data.bidsCount}'),
          pw.Bullet(
            text: 'Payments Total: ${data.paymentsTotal.toStringAsFixed(0)} EGP',
          ),

          pw.SizedBox(height: 16),
          pw.Text('Bids By Day',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: const ['Date', 'Count'],
            data: data.bidsByDay
                .map((e) => [df.format(e.date), e.count.toString()])
                .toList(),
          ),

          pw.SizedBox(height: 16),
          pw.Text('Revenue By Category',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: const ['Category', 'Amount'],
            data: data.revenueByCategory
                .map((e) => [e.category, e.amount.toStringAsFixed(0)])
                .toList(),
          ),
        ],
      ),
    );

    return doc;
  }
}