import 'package:test/test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

void main() {
  group('StepError', () {
    test('variants are all StepError and Exception', () {
      const errors = <StepError>[
        ConfigError('bad'),
        ProcessError('nope'),
        NotFoundError('missing'),
      ];
      for (final e in errors) {
        expect(e, isA<StepError>());
        expect(e, isA<Exception>());
      }
    });

    test('exhaustive switch over the sealed hierarchy', () {
      String describe(StepError e) => switch (e) {
            ConfigError() => 'config',
            ProcessError() => 'process',
            NotFoundError() => 'not-found',
          };
      expect(describe(const ConfigError('x')), 'config');
      expect(describe(const ProcessError('x')), 'process');
      expect(describe(const NotFoundError('x')), 'not-found');
    });

    test('ConfigError surfaces all validation errors in toString', () {
      const e = ConfigError('invalid', ['a required', 'b out of range']);
      expect(e.validationErrors, hasLength(2));
      expect(e.toString(), contains('a required'));
      expect(e.toString(), contains('b out of range'));
    });
  });
}
