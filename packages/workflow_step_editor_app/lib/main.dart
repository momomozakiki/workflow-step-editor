import 'package:flutter/material.dart';

import 'src/editor_screen.dart';

void main() => runApp(const ProcedureEditorApp());

/// Desktop host app for the workflow procedure editor.
class ProcedureEditorApp extends StatelessWidget {
  const ProcedureEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Procedure Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0A2F5E),
      ),
      home: const EditorScreen(),
    );
  }
}
