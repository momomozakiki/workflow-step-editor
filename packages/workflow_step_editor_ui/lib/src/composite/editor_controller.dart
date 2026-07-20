import 'package:flutter/foundation.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

/// Editor state, exposed as a [ChangeNotifier] (the project's only state
/// mechanism — no third-party state library).
///
/// Dependencies are **constructor-injected with default fallbacks** so tests can
/// pass fakes/deterministic clocks; production callers pass nothing. This class
/// imports **only** the pure-Dart core — never a concrete implementation — so it
/// builds on every platform.
class EditorController extends ChangeNotifier {
  EditorController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  final Map<String, String> _values = {};
  final List<StepWarning> _warnings = [];
  DateTime? _lastUpdated;
  bool _isPartial = false;

  /// Accumulated atomic values from applied results.
  Map<String, String> get values => Map.unmodifiable(_values);

  /// Warnings gathered from the most recent [applyResult].
  List<StepWarning> get warnings => List.unmodifiable(_warnings);

  /// Whether the last applied result was partial.
  bool get isPartial => _isPartial;

  /// When the state last changed, per the injected clock.
  DateTime? get lastUpdated => _lastUpdated;

  /// Merge [result]'s values into the editor state, replacing the warning set
  /// with this result's warnings, and notify listeners.
  void applyResult(StepResult result) {
    _values.addAll(result.values);
    _warnings
      ..clear()
      ..addAll(result.warnings);
    _isPartial = result.isPartial;
    _lastUpdated = _clock();
    notifyListeners();
  }

  /// Clear all accumulated state and notify listeners.
  void reset() {
    _values.clear();
    _warnings.clear();
    _isPartial = false;
    _lastUpdated = _clock();
    notifyListeners();
  }
}
