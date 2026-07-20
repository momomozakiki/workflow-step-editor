import 'package:flutter/material.dart';

import 'editable_cell.dart';
import 'procedure_editor_controller.dart';

const Color _navy = Color(0xFF0A2F5E);

/// The document header: an editable title + subtitle on the left, and the
/// structural actions ("Add Row", "Reset") on the right. Export/import actions
/// live in the host app (they need file/platform access), not here.
class ProcedureHeader extends StatelessWidget {
  const ProcedureHeader({super.key, required this.controller});

  final ProcedureEditorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final doc = controller.document;
        return Container(
          padding: const EdgeInsets.only(bottom: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _navy, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditableCell(
                      value: doc.title,
                      bold: true,
                      hintText: 'Document title…',
                      onChanged: controller.setDocumentTitle,
                    ),
                    const SizedBox(height: 6),
                    EditableCell(
                      value: doc.subtitle,
                      hintText: 'Subtitle…',
                      onChanged: controller.setDocumentSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => controller.addStep(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Row'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmReset(context),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset document?'),
        content: const Text(
          'This replaces all rows with the default template. Unsaved edits '
          'will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok ?? false) controller.reset();
  }
}
