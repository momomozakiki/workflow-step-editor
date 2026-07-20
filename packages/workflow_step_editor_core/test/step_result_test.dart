import 'package:test/test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

void main() {
  group('StepResult', () {
    test('happy path — carries values, not partial, no warnings', () {
      const result = StepResult(values: {'weight': '12.3'});
      expect(result.values, {'weight': '12.3'});
      expect(result.isPartial, isFalse);
      expect(result.warnings, isEmpty);
    });

    test('empty is a const zero-value result', () {
      expect(StepResult.empty.values, isEmpty);
      expect(StepResult.empty.warnings, isEmpty);
      expect(StepResult.empty.isPartial, isFalse);
    });

    test('copyWith replaces only the given fields', () {
      const base = StepResult(values: {'a': '1'});
      final next = base.copyWith(values: {'a': '2'});
      expect(next.values, {'a': '2'});
      expect(next.isPartial, isFalse);
    });

    test('withWarnings appends warnings and forces isPartial', () {
      const base = StepResult(values: {'a': '1'});
      final next = base.withWarnings(const [StepWarning('bad', key: 'a')]);
      expect(next.isPartial, isTrue);
      expect(next.warnings, hasLength(1));
      expect(next.warnings.single.key, 'a');
    });

    test('withWarnings on empty list is a no-op', () {
      const base = StepResult(values: {'a': '1'});
      expect(identical(base.withWarnings(const []), base), isTrue);
    });
  });

  group('StepWarning', () {
    test('value equality by message and key', () {
      expect(
        const StepWarning('x', key: 'k'),
        equals(const StepWarning('x', key: 'k')),
      );
      expect(
        const StepWarning('x', key: 'k'),
        isNot(const StepWarning('x', key: 'j')),
      );
    });
  });
}
