import 'package:test/test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

void main() {
  group('ProcedureDocument', () {
    test('defaultTemplate holds the 11 sample steps and 4 parties', () {
      final doc = ProcedureDocument.defaultTemplate();
      expect(doc.steps, hasLength(11));
      expect(doc.parties, hasLength(4));
      expect(doc.steps.first.title, 'ICPO & DOCUMENTS');
      expect(doc.steps.last.party, Party.both);
      expect(doc.footer, contains('SPA'));
      expect(doc.notes, contains('MT799 RWA'));
    });

    test('copyWith replaces only the given field', () {
      final doc = ProcedureDocument.defaultTemplate();
      final updated = doc.copyWith(title: 'NEW');
      expect(updated.title, 'NEW');
      expect(updated.steps, doc.steps);
    });

    test('toJson / fromJson round-trips the template', () {
      final doc = ProcedureDocument.defaultTemplate();
      final restored = ProcedureDocument.fromJson(doc.toJson());
      expect(restored.title, doc.title);
      expect(restored.subtitle, doc.subtitle);
      expect(restored.steps, doc.steps);
      expect(restored.parties, doc.parties);
      expect(restored.notes, doc.notes);
      expect(restored.footer, doc.footer);
    });

    test('fromJson tolerates a non-map input (no throw)', () {
      final doc = ProcedureDocument.fromJson('garbage');
      expect(doc.title, '');
      expect(doc.steps, isEmpty);
      expect(doc.parties, Party.presets); // empty palette falls back to presets
    });

    test('fromJson skips malformed step entries gracefully', () {
      final doc = ProcedureDocument.fromJson({
        'title': 'T',
        'steps': [
          {'title': 'A', 'party': 'not-a-map'},
          'garbage',
        ],
      });
      expect(doc.title, 'T');
      expect(doc.steps, hasLength(2));
      expect(doc.steps.first.title, 'A');
      expect(doc.steps.first.party.name, 'PARTY');
      expect(doc.steps[1].title, '');
    });
  });
}
