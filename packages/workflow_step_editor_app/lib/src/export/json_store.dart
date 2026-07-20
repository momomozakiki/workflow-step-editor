import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

/// Reads/writes a [ProcedureDocument] as a JSON file via native file dialogs.
///
/// This is a platform concretion (file I/O), so it lives in the host app — not
/// in the pure-Dart core or the UI library. Deserialization is delegated to the
/// core's hardened [ProcedureDocument.fromJson]; a syntactically invalid file
/// surfaces as a [FormatException] for the caller to report.
class JsonStore {
  const JsonStore();

  static const XTypeGroup _group = XTypeGroup(
    label: 'JSON',
    extensions: <String>['json'],
  );

  /// Prompt for a file and load it. Returns `null` if the user cancels.
  /// Throws [FormatException] if the file is not valid JSON.
  Future<ProcedureDocument?> open() async {
    final file = await openFile(acceptedTypeGroups: const [_group]);
    if (file == null) return null;
    final text = await file.readAsString();
    return ProcedureDocument.fromJson(jsonDecode(text));
  }

  /// Prompt for a destination and save [document]. Returns the written path, or
  /// `null` if the user cancels.
  Future<String?> save(ProcedureDocument document) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [_group],
      suggestedName: 'procedure.json',
    );
    if (location == null) return null;
    final json = const JsonEncoder.withIndent('  ').convert(document.toJson());
    await File(location.path).writeAsString(json);
    return location.path;
  }
}
