/// Fatal error hierarchy for the pipeline.
///
/// [StepError] is a **sealed** class, so callers can `switch` over it
/// exhaustively. Throw one of its variants only for genuinely *fatal* problems
/// — input the stage cannot handle, or invalid configuration. Recoverable
/// problems are surfaced as [StepWarning]s on a [StepResult] instead (see the
/// LSP contract in the `dart-solid-principles` skill).
library;

/// Base sealed type for all fatal pipeline errors.
sealed class StepError implements Exception {
  const StepError(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Configuration is invalid. Carries the list of individual [validationErrors]
/// so a caller (or UI) can surface all of them at once, not just the first.
final class ConfigError extends StepError {
  const ConfigError(super.message, [this.validationErrors = const []]);

  final List<String> validationErrors;

  @override
  String toString() => validationErrors.isEmpty
      ? 'ConfigError: $message'
      : 'ConfigError: $message (${validationErrors.join('; ')})';
}

/// Input could not be processed (e.g. an unsupported variant or unparseable
/// data). Distinct from a recoverable, out-of-range value, which is a warning.
final class ProcessError extends StepError {
  const ProcessError(super.message);
}

/// A referenced key or type could not be found.
final class NotFoundError extends StepError {
  const NotFoundError(super.message);
}
