/// Flutter widget library for the workflow step editor.
///
/// Imports only the pure-Dart core; host apps inject concretions. This is the
/// single public export barrel — implementation lives under `lib/src/`.
library;

export 'src/composite/editor_controller.dart';

// Procedure editor: controller + widgets.
export 'src/procedure/procedure_editor_controller.dart';
export 'src/procedure/procedure_header.dart';
export 'src/procedure/procedure_table.dart';
export 'src/procedure/party_badge.dart';
export 'src/procedure/party_editor.dart';
export 'src/procedure/document_notes.dart';
export 'src/procedure/step_icon_catalog.dart';
export 'src/procedure/step_icon_picker.dart';
