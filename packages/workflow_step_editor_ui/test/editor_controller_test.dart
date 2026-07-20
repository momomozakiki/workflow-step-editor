import 'package:flutter_test/flutter_test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';
import 'package:workflow_step_editor_ui/workflow_step_editor_ui.dart';

import 'support/recording_listener.dart';

void main() {
  group('EditorController', () {
    test('applyResult merges values and notifies listeners', () {
      final clock = FixedClock(DateTime(2026, 1, 1));
      final controller = EditorController(clock: clock.call);
      final listener = RecordingListener();
      controller.addListener(listener.call);

      controller.applyResult(const StepResult(values: {'a': '1'}));
      controller.applyResult(const StepResult(values: {'b': '2'}));

      expect(controller.values, {'a': '1', 'b': '2'});
      expect(controller.isPartial, isFalse);
      expect(listener.calls, 2);
      expect(controller.lastUpdated, DateTime(2026, 1, 1));
    });

    test('applyResult carries warnings + partial from a partial result', () {
      final controller = EditorController(clock: FixedClock(DateTime(2026)).call);
      controller.applyResult(
        const StepResult(
          values: {'a': '1'},
          warnings: [StepWarning('bad', key: 'a')],
          isPartial: true,
        ),
      );
      expect(controller.isPartial, isTrue);
      expect(controller.warnings.single.key, 'a');
    });

    test('a later result replaces the previous warning set', () {
      final controller = EditorController(clock: FixedClock(DateTime(2026)).call);
      controller.applyResult(
        const StepResult(values: {}, warnings: [StepWarning('first')], isPartial: true),
      );
      controller.applyResult(const StepResult(values: {'a': '1'}));
      expect(controller.warnings, isEmpty);
      expect(controller.isPartial, isFalse);
    });

    test('reset clears state and uses the injected clock', () {
      final clock = FixedClock(DateTime(2026, 1, 1));
      final controller = EditorController(clock: clock.call)
        ..applyResult(const StepResult(values: {'a': '1'}));
      clock.advance(const Duration(hours: 1));
      controller.reset();
      expect(controller.values, isEmpty);
      expect(controller.lastUpdated, DateTime(2026, 1, 1, 1));
    });

    test('exposed collections are unmodifiable', () {
      final controller = EditorController(clock: FixedClock(DateTime(2026)).call)
        ..applyResult(const StepResult(values: {'a': '1'}));
      expect(() => controller.values['x'] = 'y', throwsUnsupportedError);
      expect(() => controller.warnings.add(const StepWarning('n')),
          throwsUnsupportedError);
    });
  });
}
