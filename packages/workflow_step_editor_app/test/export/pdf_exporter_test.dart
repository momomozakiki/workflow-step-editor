import 'package:flutter_test/flutter_test.dart';
import 'package:workflow_step_editor_app/src/export/pdf_exporter.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

void main() {
  group('PdfExporter.build', () {
    const exporter = PdfExporter();

    test('produces a non-empty PDF in portrait', () async {
      final bytes = await exporter.build(
        ProcedureDocument.defaultTemplate(),
        orientation: PdfOrientation.portrait,
      );
      expect(bytes, isNotEmpty);
      // PDF files start with the "%PDF" magic bytes.
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('produces a non-empty PDF in landscape', () async {
      final bytes = await exporter.build(
        ProcedureDocument.defaultTemplate(),
        orientation: PdfOrientation.landscape,
      );
      expect(bytes, isNotEmpty);
    });

    test('handles an empty document without throwing', () async {
      final bytes = await exporter.build(
        const ProcedureDocument(
          title: '',
          subtitle: '',
          steps: [],
          parties: [],
          notes: '',
          footer: '',
        ),
        orientation: PdfOrientation.portrait,
      );
      expect(bytes, isNotEmpty);
    });
  });
}
