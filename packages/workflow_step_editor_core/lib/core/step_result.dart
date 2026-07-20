/// The result of running a pipeline stage over some input.
///
/// Immutable value type. Recoverable problems are surfaced as [warnings] with
/// [isPartial] set to `true` — they are **not** thrown. Only genuinely fatal
/// problems throw a [StepError] (see `step_error.dart`). Thread state through a
/// pipeline with [copyWith] rather than mutation.
///
/// This is domain-free infrastructure: [values] is a flat, atomic
/// `Map<String, String>`. The concrete step model that produces these values is
/// defined later, against this type.
library;

/// A non-fatal problem encountered while producing a [StepResult].
///
/// Carries a human-readable [message] and, optionally, the [key] it relates to.
final class StepWarning {
  const StepWarning(this.message, {this.key});

  final String message;
  final String? key;

  @override
  bool operator ==(Object other) =>
      other is StepWarning && other.message == message && other.key == key;

  @override
  int get hashCode => Object.hash(message, key);

  @override
  String toString() =>
      key == null ? 'StepWarning($message)' : 'StepWarning($key: $message)';
}

/// Immutable output of a pipeline stage: atomic [values] plus any non-fatal
/// [warnings]. [isPartial] is `true` when the values are incomplete because a
/// recoverable problem was encountered.
final class StepResult {
  const StepResult({
    required this.values,
    this.warnings = const [],
    this.isPartial = false,
  });

  /// A result with no values and no warnings.
  static const StepResult empty = StepResult(values: {});

  final Map<String, String> values;
  final List<StepWarning> warnings;
  final bool isPartial;

  /// Return a copy with the given fields replaced. Use this to thread warnings
  /// through successive pipeline stages without mutating an earlier result.
  StepResult copyWith({
    Map<String, String>? values,
    List<StepWarning>? warnings,
    bool? isPartial,
  }) {
    return StepResult(
      values: values ?? this.values,
      warnings: warnings ?? this.warnings,
      isPartial: isPartial ?? this.isPartial,
    );
  }

  /// Return a copy with [extra] warnings appended and [isPartial] forced `true`.
  StepResult withWarnings(List<StepWarning> extra) {
    if (extra.isEmpty) return this;
    return copyWith(warnings: [...warnings, ...extra], isPartial: true);
  }

  @override
  String toString() =>
      'StepResult(values: $values, warnings: $warnings, isPartial: $isPartial)';
}
