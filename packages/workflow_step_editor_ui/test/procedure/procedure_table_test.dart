import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';
import 'package:workflow_step_editor_ui/workflow_step_editor_ui.dart';

void main() {
  Widget host(ProcedureEditorController controller) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProcedureTable(controller: controller),
          ),
        ),
      );

  testWidgets('renders a row per step with title and party', (tester) async {
    final controller = ProcedureEditorController(
      initial: const ProcedureDocument(
        title: 'T',
        subtitle: 'S',
        parties: [Party.buyer],
        notes: '',
        footer: '',
        steps: [
          ProcedureStep(
            title: 'ICPO',
            action: 'a',
            documents: 'd',
            party: Party.buyer,
          ),
        ],
      ),
    );

    await tester.pumpWidget(host(controller));

    expect(find.text('ICPO'), findsOneWidget);
    expect(find.text('BUYER'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
  });

  testWidgets('delete button removes the row', (tester) async {
    final controller = ProcedureEditorController();
    await tester.pumpWidget(host(controller));

    expect(controller.document.steps, hasLength(11));
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    expect(controller.document.steps, hasLength(10));
  });

  testWidgets('tapping the icon slot opens the picker and applies a choice',
      (tester) async {
    final controller = ProcedureEditorController(
      initial: const ProcedureDocument(
        title: 'T',
        subtitle: 'S',
        parties: [Party.buyer],
        notes: '',
        footer: '',
        steps: [
          ProcedureStep(title: 'ICPO', action: 'a', documents: 'd', party: Party.buyer),
        ],
      ),
    );
    await tester.pumpWidget(host(controller));

    // Empty icon → the "add icon" placeholder is shown.
    expect(controller.document.steps.first.icon, '');
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pumpAndSettle();

    // Pick the handshake tile (labelled "Agreement") in the dialog, then apply.
    await tester.tap(find.text('Agreement'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(controller.document.steps.first.icon, 'handshake');
  });

  testWidgets('typing a multi-character string keeps focus (no per-keystroke unfocus)',
      (tester) async {
    final controller = ProcedureEditorController(
      initial: const ProcedureDocument(
        title: 'T',
        subtitle: 'S',
        parties: [Party.buyer],
        notes: '',
        footer: '',
        steps: [
          ProcedureStep(title: '', action: 'a', documents: 'd', party: Party.buyer),
          ProcedureStep(title: 'other', action: 'a', documents: 'd', party: Party.buyer),
        ],
      ),
    );
    await tester.pumpWidget(host(controller));

    // The first TextField in the table is the first step's title cell (rows are
    // title/action/documents in order; the host pumps only the table). Index by
    // position so the finder stays valid as the field's text changes.
    final titleField = find.byType(TextField).first;
    await tester.tap(titleField);
    await tester.pump();

    const typed = 'Hello';
    for (final ch in typed.split('')) {
      final current = controller.document.steps.first.title;
      await tester.enterText(titleField, '$current$ch');
      await tester.pump();
      // The field backing the first step's title must remain the primary focus
      // after every keystroke; if the row remounts, focus is lost here.
      final editable = tester.state<EditableTextState>(
        find.descendant(
          of: find.byType(TextField).first,
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.widget.focusNode.hasPrimaryFocus, isTrue,
          reason: 'field lost focus after typing "$ch"');
    }

    expect(controller.document.steps.first.title, typed);
  });

  testWidgets('reorder moves rows with their content', (tester) async {
    final controller = ProcedureEditorController(
      initial: const ProcedureDocument(
        title: 'T',
        subtitle: 'S',
        parties: [Party.buyer],
        notes: '',
        footer: '',
        steps: [
          ProcedureStep(title: 'First', action: 'a', documents: 'd', party: Party.buyer),
          ProcedureStep(title: 'Second', action: 'a', documents: 'd', party: Party.buyer),
        ],
      ),
    );
    await tester.pumpWidget(host(controller));

    controller.moveStep(0, 1);
    await tester.pump();

    expect(controller.document.steps.map((s) => s.title).toList(),
        ['Second', 'First']);
    // Both titles still render after the reorder-driven rebuild.
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });
}
