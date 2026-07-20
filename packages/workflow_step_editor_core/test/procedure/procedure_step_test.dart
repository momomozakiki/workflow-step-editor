import 'package:test/test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

void main() {
  group('ProcedureStep', () {
    const step = ProcedureStep(
      title: 'ICPO',
      action: 'Buyer issues ICPO.',
      documents: 'ICPO',
      party: Party.buyer,
    );

    test('copyWith replaces only the given field', () {
      final updated = step.copyWith(party: Party.seller);
      expect(updated.party, Party.seller);
      expect(updated.title, step.title);
    });

    test('value equality', () {
      expect(step, step.copyWith());
      expect(step == step.copyWith(title: 'OTHER'), isFalse);
    });

    test('toJson / fromJson round-trip', () {
      expect(ProcedureStep.fromJson(step.toJson()), step);
    });

    test('fromJson defaults missing fields and nested party', () {
      final s = ProcedureStep.fromJson(const <String, Object?>{});
      expect(s.title, '');
      expect(s.action, '');
      expect(s.documents, '');
      expect(s.party.name, 'PARTY');
    });

    test('fromJson tolerates a non-map input', () {
      final s = ProcedureStep.fromJson(42);
      expect(s.title, '');
      expect(s.party.name, 'PARTY');
    });
  });
}
