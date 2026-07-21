import 'package:flutter_test/flutter_test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';
import 'package:workflow_step_editor_ui/workflow_step_editor_ui.dart';

void main() {
  group('stepIconCatalog', () {
    test('keys are unique', () {
      final keys = stepIconCatalog.map((o) => o.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
    });

    test('iconFor resolves known keys and rejects empty/unknown', () {
      expect(iconFor('handshake'), isNotNull);
      expect(iconFor(''), isNull);
      expect(iconFor('definitely-not-an-icon'), isNull);
    });

    test('every default-template icon exists in the catalog', () {
      final doc = ProcedureDocument.defaultTemplate();
      for (final step in doc.steps) {
        expect(
          iconFor(step.icon),
          isNotNull,
          reason: 'template icon "${step.icon}" is missing from the catalog',
        );
      }
    });
  });
}
