import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

/// A **test-only** type used to exercise [Registry] without committing a real
/// domain model to `lib/`. It stands in for whatever the eventual `WorkflowStep`
/// taxonomy will be; keeping it here (never in `lib/`) avoids pre-molding the
/// domain. See `docs/plan/ROADMAP.md`.
class FakeStep {
  FakeStep(this.label);

  final String label;

  /// A trivial stand-in for a step's produce-output behavior.
  StepResult run(String input) {
    if (input.isEmpty) {
      return const StepResult(
        values: {},
        warnings: [StepWarning('empty input', key: 'input')],
        isPartial: true,
      );
    }
    return StepResult(values: {label: input});
  }
}
