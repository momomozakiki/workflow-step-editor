import 'package:test/test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

import 'support/fake_step.dart';

void main() {
  group('Registry<T>', () {
    test('create yields a fresh instance each call (not a singleton)', () {
      final registry = Registry<FakeStep>()
        ..register('label', () => FakeStep('out'));
      final a = registry.create('label');
      final b = registry.create('label');
      expect(a, isNot(same(b)));
      expect(a.label, 'out');
    });

    test('tear-off factory works and registered behavior runs', () {
      final registry = Registry<FakeStep>()..register('x', () => FakeStep('x'));
      final step = registry.create('x');
      expect(step.run('hi').values, {'x': 'hi'});
      // recoverable problem → warning + isPartial, never thrown
      final partial = step.run('');
      expect(partial.isPartial, isTrue);
      expect(partial.warnings.single.key, 'input');
    });

    test('contains and types reflect registrations in order', () {
      final registry = Registry<FakeStep>()
        ..register('a', () => FakeStep('a'))
        ..register('b', () => FakeStep('b'));
      expect(registry.contains('a'), isTrue);
      expect(registry.contains('z'), isFalse);
      expect(registry.types, ['a', 'b']);
    });

    test('unknown type throws NotFoundError', () {
      final registry = Registry<FakeStep>();
      expect(() => registry.create('nope'), throwsA(isA<NotFoundError>()));
    });

    test('empty type throws ConfigError', () {
      final registry = Registry<FakeStep>();
      expect(
        () => registry.register('', () => FakeStep('x')),
        throwsA(isA<ConfigError>()),
      );
    });

    test('duplicate registration throws ConfigError', () {
      final registry = Registry<FakeStep>()..register('a', () => FakeStep('a'));
      expect(
        () => registry.register('a', () => FakeStep('a2')),
        throwsA(isA<ConfigError>()),
      );
    });
  });
}
