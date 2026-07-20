/// Pure-Dart core for the workflow step editor.
///
/// Domain-free infrastructure only. The concrete step model (a sealed
/// `WorkflowStep` taxonomy and its `StepRegistry`) is defined later, against
/// these primitives — see `docs/plan/ROADMAP.md`.
///
/// This is the single public export barrel; everything a consumer needs is
/// re-exported here.
library;

export 'core/step_result.dart';
export 'core/step_error.dart';
export 'registry/registry.dart';

// Procedure-editor domain model.
export 'procedure/party.dart';
export 'procedure/procedure_step.dart';
export 'procedure/procedure_document.dart';
