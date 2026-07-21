import 'package:flutter/material.dart';

import 'editable_cell.dart';
import 'party_badge.dart';
import 'procedure_editor_controller.dart';
import 'step_icon_catalog.dart';
import 'step_icon_picker.dart';

const Color _navy = Color(0xFF0A2F5E);

/// The procedure table: a header row plus a drag-to-reorder list of step rows,
/// all driven by [controller]. Rebuilds itself on any controller change.
class ProcedureTable extends StatelessWidget {
  const ProcedureTable({super.key, required this.controller});

  final ProcedureEditorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final steps = controller.document.steps;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _HeaderRow(),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: steps.length,
              onReorderItem: controller.moveStep,
              itemBuilder: (context, i) => _StepRow(
                key: ValueKey('step-$i-${identityHashCode(steps[i])}'),
                controller: controller,
                index: i,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.5,
    );
    return Container(
      color: _navy,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: const Row(
        children: [
          SizedBox(width: 44, child: Text('#', style: style)),
          Expanded(flex: 2, child: Text('PROCEDURE', style: style)),
          Expanded(flex: 3, child: Text('KEY ACTION & DETAILS', style: style)),
          Expanded(flex: 2, child: Text('KEY DOCUMENTS', style: style)),
          SizedBox(width: 150, child: Text('PARTY', style: style)),
          SizedBox(width: 84, child: Text('', style: style)),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.controller,
    required this.index,
  });

  final ProcedureEditorController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final step = controller.document.steps[index];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE6ECF5))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 44, child: _StepNumber(index + 1)),
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepIconButton(controller: controller, index: index),
                const SizedBox(width: 6),
                Expanded(
                  child: EditableCell(
                    value: step.title,
                    bold: true,
                    hintText: 'Procedure name…',
                    maxLines: null,
                    onChanged: (v) => controller.updateTitle(index, v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: EditableCell(
              value: step.action,
              hintText: 'Key action…',
              maxLines: null,
              onChanged: (v) => controller.updateAction(index, v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: EditableCell(
              value: step.documents,
              hintText: 'Documents list…',
              maxLines: null,
              onChanged: (v) => controller.updateDocuments(index, v),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: Align(
              alignment: Alignment.centerLeft,
              child: PartyBadge(controller: controller, index: index),
            ),
          ),
          SizedBox(
            width: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.drag_indicator, color: Color(0xFF6A8BB0)),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete row',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFA94442)),
                  onPressed: () => controller.removeStep(index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The tappable step-icon slot shown to the left of the title cell. Shows the
/// chosen glyph, or a muted "add icon" placeholder when none is set. Tapping
/// opens [showStepIconPicker] and writes the result back through [controller].
class _StepIconButton extends StatelessWidget {
  const _StepIconButton({required this.controller, required this.index});

  final ProcedureEditorController controller;
  final int index;

  Future<void> _pick(BuildContext context) async {
    final current = controller.document.steps[index].icon;
    final result = await showStepIconPicker(context, initial: current);
    if (result == null) return; // cancelled
    controller.updateIcon(index, result);
  }

  @override
  Widget build(BuildContext context) {
    final key = controller.document.steps[index].icon;
    final px = iconSizePx(controller.document.iconSize);
    final glyph = stepIcon(key, size: px);
    final hasIcon = glyph != null;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _pick(context),
        child: Tooltip(
          message: hasIcon ? 'Change icon' : 'Add icon',
          child: Container(
            width: px + 10,
            height: px + 10,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasIcon ? const Color(0xFFEEF3FA) : null,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasIcon
                    ? const Color(0x14000000)
                    : const Color(0x33000000),
              ),
            ),
            child: glyph ??
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: px * 0.6,
                  color: const Color(0xFF9BB0CC),
                ),
          ),
        ),
      ),
    );
  }
}

class _StepNumber extends StatelessWidget {
  const _StepNumber(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: _navy, shape: BoxShape.circle),
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
