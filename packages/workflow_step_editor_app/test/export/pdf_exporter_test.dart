import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:workflow_step_editor_app/src/export/pdf_exporter.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

void main() {
  testWidgets('bundled Twemoji icon loads as PNG bytes for the PDF',
      (tester) async {
    // Proves the exporter's happy path: the UI package's icon asset is on the
    // bundle, so icons are actually embedded, not silently skipped by
    // _iconImages' error-tolerant fallback.
    final data = await rootBundle.load(
      'packages/workflow_step_editor_ui/assets/icons/twemoji/handshake.png',
    );
    final png = data.buffer.asUint8List();
    expect(png, isNotEmpty);
    // PNG signature: 0x89 'P' 'N' 'G'.
    expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  group('PdfExporter.build', () {
    const exporter = PdfExporter();

    // These use testWidgets because build() rasterizes SVG icons via the engine
    // (offscreen toImage), which only completes under a widgets binding.
    testWidgets('produces a non-empty PDF in portrait', (tester) async {
      final bytes = await exporter.build(
        ProcedureDocument.defaultTemplate(),
        orientation: PdfOrientation.portrait,
      );
      expect(bytes, isNotEmpty);
      // PDF files start with the "%PDF" magic bytes.
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    testWidgets('produces a non-empty PDF in landscape', (tester) async {
      final bytes = await exporter.build(
        ProcedureDocument.defaultTemplate(),
        orientation: PdfOrientation.landscape,
      );
      expect(bytes, isNotEmpty);
    });

    testWidgets('handles an empty document without throwing', (tester) async {
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
