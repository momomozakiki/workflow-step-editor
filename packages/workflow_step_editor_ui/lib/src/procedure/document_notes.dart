import 'package:flutter/material.dart';

import 'editable_cell.dart';
import 'procedure_editor_controller.dart';

/// The editable "Key Notes" block and footer disclaimer beneath the table.
class DocumentNotes extends StatelessWidget {
  const DocumentNotes({super.key, required this.controller});

  final ProcedureEditorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final doc = controller.document;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            const _SectionLabel('KEY NOTES (one per line)'),
            const SizedBox(height: 6),
            Container(
              color: const Color(0xFFF2F6FD),
              padding: const EdgeInsets.all(8),
              child: EditableCell(
                value: doc.notes,
                hintText: 'Add notes, one per line…',
                maxLines: null,
                onChanged: controller.setNotes,
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('FOOTER'),
            const SizedBox(height: 6),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F5FE),
                border: Border(
                  left: BorderSide(color: Color(0xFF0A2F5E), width: 4),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: EditableCell(
                value: doc.footer,
                hintText: 'Footer note…',
                maxLines: null,
                onChanged: controller.setFooter,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6A8BB0),
          letterSpacing: 0.5,
        ),
      );
}
