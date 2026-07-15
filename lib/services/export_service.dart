import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:spelling_bee/models/result.dart';

// Conditional imports for platform-specific download
import 'export_stub.dart'
    if (dart.library.html) 'export_web.dart'
    if (dart.library.io) 'export_native.dart';

/// Service for generating and downloading Excel and PDF exports of the leaderboard.
class ExportService {
  /// Generate an Excel workbook from results and trigger download.
  Future<void> exportToExcel(List<Result> results) async {
    final excel = Excel.createExcel();
    final sheet = excel['Leaderboard'];

    // Header row
    sheet.appendRow([
      TextCellValue('Rank'),
      TextCellValue('Student Name'),
      TextCellValue('Grade'),
      TextCellValue('Score'),
      TextCellValue('Correct'),
      TextCellValue('Wrong'),
      TextCellValue('Passes Used'),
      TextCellValue('Time Remaining (s)'),
      TextCellValue('Accuracy (%)'),
    ]);

    // Data rows
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(r.studentName),
        TextCellValue(r.grade),
        IntCellValue(r.finalScore),
        IntCellValue(r.correctAnswers),
        IntCellValue(r.wrongAnswers),
        IntCellValue(r.passesUsed),
        IntCellValue(r.timeRemainingSeconds),
        DoubleCellValue(double.parse(r.accuracy.toStringAsFixed(2))),
      ]);
    }

    // Remove default sheet if it exists
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    await downloadFile(
      Uint8List.fromList(bytes),
      'spelling_bee_leaderboard.xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  /// Generate a PDF document from results and trigger download.
  Future<void> exportToPdf(List<Result> results) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Everest Spelling Bee – Open Championship',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Leaderboard Results',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headers: [
              '#',
              'Name',
              'Grade',
              'Score',
              'Correct',
              'Wrong',
              'Passes',
              'Time(s)',
              'Accuracy%'
            ],
            data: List.generate(results.length, (i) {
              final r = results[i];
              return [
                '${i + 1}',
                r.studentName,
                r.grade,
                '${r.finalScore}',
                '${r.correctAnswers}',
                '${r.wrongAnswers}',
                '${r.passesUsed}',
                '${r.timeRemainingSeconds}',
                r.accuracy.toStringAsFixed(1),
              ];
            }),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    await downloadFile(
      bytes,
      'spelling_bee_leaderboard.pdf',
      'application/pdf',
    );
  }
}
