import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workflow_step_editor_app/main.dart';

void main() {
  testWidgets('app boots and shows the default template + toolbar', (tester) async {
    await tester.pumpWidget(const ProcedureEditorApp());

    // Toolbar actions are present.
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('JSON'), findsOneWidget);

    // The default template's first step title renders.
    expect(find.text('ICPO & DOCUMENTS'), findsOneWidget);

    // "Add Row" grows the table.
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(11));
    await tester.tap(find.text('Add Row'));
    await tester.pump();
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(12));
  });
}
