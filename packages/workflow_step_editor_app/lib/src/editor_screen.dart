import 'package:flutter/material.dart';
import 'package:workflow_step_editor_ui/workflow_step_editor_ui.dart';

import 'export/image_exporter.dart';
import 'export/json_store.dart';
import 'export/pdf_exporter.dart';

/// The single editor screen: a toolbar of import/export actions above the
/// procedure "card" (header + table + notes), which is wrapped in a
/// [RepaintBoundary] so it can be captured to PNG without the toolbar.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ProcedureEditorController _controller = ProcedureEditorController();
  final GlobalKey _cardKey = GlobalKey();
  final JsonStore _jsonStore = const JsonStore();
  final PdfExporter _pdfExporter = const PdfExporter();
  final ImageExporter _imageExporter = const ImageExporter();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _importJson() async {
    try {
      final doc = await _jsonStore.open();
      if (doc == null) return; // cancelled
      _controller.load(doc);
      _notify('Imported ${doc.steps.length} step(s).');
    } on FormatException {
      _notify('Import failed: the file is not valid JSON.');
    } catch (_) {
      _notify('Import failed: could not read the file.');
    }
  }

  Future<void> _exportJson() async {
    try {
      final path = await _jsonStore.save(_controller.document);
      if (path != null) _notify('Saved JSON to $path');
    } catch (_) {
      _notify('Export failed: could not write the file.');
    }
  }

  Future<void> _exportPdf() async {
    final orientation = await _chooseOrientation();
    if (orientation == null) return; // cancelled
    try {
      await _pdfExporter.export(_controller.document, orientation: orientation);
    } catch (_) {
      _notify('PDF export failed.');
    }
  }

  Future<void> _exportPng() async {
    try {
      final bytes = await _imageExporter.capture(_cardKey);
      if (bytes == null) {
        _notify('PNG export failed: nothing to capture.');
        return;
      }
      final path = await _imageExporter.savePng(bytes);
      if (path != null) _notify('Saved PNG to $path');
    } catch (_) {
      _notify('PNG export failed.');
    }
  }

  Future<PdfOrientation?> _chooseOrientation() {
    return showDialog<PdfOrientation>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export PDF'),
        content: const Text('Choose the page orientation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(PdfOrientation.portrait),
            child: const Text('Portrait'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(PdfOrientation.landscape),
            child: const Text('Landscape'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF4),
      appBar: AppBar(
        title: const Text('Procedure Editor'),
        actions: [
          TextButton.icon(
            onPressed: _importJson,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Import'),
          ),
          TextButton.icon(
            onPressed: _exportJson,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('JSON'),
          ),
          TextButton.icon(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF'),
          ),
          TextButton.icon(
            onPressed: _exportPng,
            icon: const Icon(Icons.image_outlined),
            label: const Text('PNG'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: RepaintBoundary(
              key: _cardKey,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProcedureHeader(controller: _controller),
                    const SizedBox(height: 16),
                    ProcedureTable(controller: _controller),
                    DocumentNotes(controller: _controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
