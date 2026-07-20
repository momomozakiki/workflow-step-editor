import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

/// Page orientation for [PdfExporter]; chosen by the user before export.
enum PdfOrientation { portrait, landscape }

const PdfColor _navy = PdfColor.fromInt(0xFF0A2F5E);

/// Renders a [ProcedureDocument] to a print-ready A4 PDF (mirroring the on-screen
/// table) and opens the system print / save-as-PDF dialog via `printing`. A
/// platform concretion — kept in the host app.
class PdfExporter {
  const PdfExporter();

  /// Build the PDF and hand it to the print/save dialog.
  Future<void> export(
    ProcedureDocument doc, {
    required PdfOrientation orientation,
  }) async {
    final bytes = await build(doc, orientation: orientation);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: _fileName(doc));
  }

  /// Build the PDF bytes (separated from [export] so it is unit-testable).
  Future<Uint8List> build(
    ProcedureDocument doc, {
    required PdfOrientation orientation,
  }) async {
    final format = orientation == PdfOrientation.landscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format.copyWith(
          marginLeft: 24,
          marginRight: 24,
          marginTop: 24,
          marginBottom: 24,
        ),
        build: (context) => [
          _headerBlock(doc),
          pw.SizedBox(height: 14),
          _table(doc),
          if (doc.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _notesBlock(doc),
          ],
          if (doc.footer.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _footerBlock(doc),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  String _fileName(ProcedureDocument doc) {
    final base = doc.title.trim().isEmpty ? 'procedure' : doc.title.trim();
    return base.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').replaceAll(' ', '_');
  }

  pw.Widget _headerBlock(ProcedureDocument doc) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          doc.title,
          style: const pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _navy,
          ),
        ),
        if (doc.subtitle.trim().isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            doc.subtitle,
            style: const pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF2C5A8C)),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(color: _navy, thickness: 2),
      ],
    );
  }

  pw.Widget _table(ProcedureDocument doc) {
    return pw.Table(
      border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFDDE4ED)),
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(3),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(1.4),
      },
      children: [
        _headerRow(),
        for (var i = 0; i < doc.steps.length; i++) _dataRow(i + 1, doc.steps[i]),
      ],
    );
  }

  pw.TableRow _headerRow() {
    pw.Widget cell(String text) => pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            text,
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
          ),
        );
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _navy),
      children: [
        cell('#'),
        cell('PROCEDURE'),
        cell('KEY ACTION & DETAILS'),
        cell('KEY DOCUMENTS'),
        cell('PARTY'),
      ],
    );
  }

  pw.TableRow _dataRow(int number, ProcedureStep step) {
    pw.Widget text(String value, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('$number',
              style:
                  const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        text(step.title, bold: true),
        text(step.action),
        text(step.documents),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: _partyBadge(step.party),
        ),
      ],
    );
  }

  pw.Widget _partyBadge(Party party) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(party.backgroundArgb),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(
        party.name,
        style: pw.TextStyle(
          color: PdfColor.fromInt(party.textArgb),
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _notesBlock(ProcedureDocument doc) {
    final lines = doc.notes
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF2F6FD)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('KEY NOTES',
              style: const pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 4),
          for (final line in lines)
            pw.Bullet(text: line, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _footerBlock(ProcedureDocument doc) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF0F5FE),
        border: pw.Border(left: pw.BorderSide(color: _navy, width: 3)),
      ),
      child: pw.Text(
        doc.footer,
        style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }
}
