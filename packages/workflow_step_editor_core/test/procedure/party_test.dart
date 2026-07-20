import 'package:test/test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

void main() {
  group('Party', () {
    test('copyWith replaces only the given field', () {
      final updated = Party.buyer.copyWith(name: 'IMPORTER');
      expect(updated.name, 'IMPORTER');
      expect(updated.backgroundArgb, Party.buyer.backgroundArgb);
      expect(updated.textArgb, Party.buyer.textArgb);
    });

    test('value equality', () {
      expect(
        const Party(name: 'X', backgroundArgb: 1, textArgb: 2),
        const Party(name: 'X', backgroundArgb: 1, textArgb: 2),
      );
      expect(Party.buyer == Party.seller, isFalse);
    });

    test('toJson / fromJson round-trip', () {
      final json = Party.terminalOperator.toJson();
      expect(Party.fromJson(json), Party.terminalOperator);
    });

    test('fromJson defaults every missing field (does not throw)', () {
      final p = Party.fromJson(const <String, Object?>{});
      expect(p.name, 'PARTY');
      expect(p.backgroundArgb, Party.defaultBackgroundArgb);
      expect(p.textArgb, Party.defaultTextArgb);
    });

    test('fromJson tolerates a non-map and malformed color', () {
      final p = Party.fromJson('garbage');
      expect(p.name, 'PARTY');
      final q = Party.fromJson({'name': 'A', 'backgroundArgb': 'not-a-color'});
      expect(q.name, 'A');
      expect(q.backgroundArgb, Party.defaultBackgroundArgb);
    });

    test('fromJson parses a hex-string color', () {
      final p = Party.fromJson({'name': 'A', 'backgroundArgb': '#D4E2FF'});
      expect(p.backgroundArgb, 0xD4E2FF);
    });

    test('presets contains the four defaults', () {
      expect(Party.presets, hasLength(4));
      expect(Party.presets, contains(Party.buyer));
    });
  });
}
