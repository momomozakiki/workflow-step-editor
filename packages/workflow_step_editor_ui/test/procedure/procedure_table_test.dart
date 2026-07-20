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
}
