import 'package:test/test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

void main() {
  group('ProcedureStep', () {
    const step = ProcedureStep(
      title: 'ICPO',
      action: 'Buyer issues ICPO.',
      documents: 'ICPO',
      party: Party.buyer,
      icon: 'assignment',
    );

    test('copyWith replaces only the given field', () {
      final updated = step.copyWith(party: Party.seller);
      expect(updated.party, Party.seller);
      expect(updated.title, step.title);
      expect(updated.icon, step.icon);
    });

    test('copyWith updates the icon', () {
      expect(step.copyWith(icon: 'handshake').icon, 'handshake');
    });

    test('icon defaults to empty when omitted', () {
      const s = ProcedureStep(
        title: 't',
        action: 'a',
        documents: 'd',
        party: Party.buyer,
      );
      expect(s.icon, '');
    });

    test('value equality', () {
      expect(step, step.copyWith());
      expect(step == step.copyWith(title: 'OTHER'), isFalse);
      expect(step == step.copyWith(icon: 'science'), isFalse);
    });

    test('toJson / fromJson round-trip (incl. icon)', () {
      expect(step.toJson()['icon'], 'assignment');
      expect(ProcedureStep.fromJson(step.toJson()), step);
    });

    test('fromJson defaults missing fields and nested party', () {
      final s = ProcedureStep.fromJson(const <String, Object?>{});
      expect(s.title, '');
      expect(s.action, '');
      expect(s.documents, '');
      expect(s.icon, '');
      expect(s.party.name, 'PARTY');
    });

    test('fromJson defaults a malformed icon to empty', () {
      final s = ProcedureStep.fromJson(const {'icon': 42});
      expect(s.icon, '');
    });

    test('fromJson tolerates a non-map input', () {
      final s = ProcedureStep.fromJson(42);
      expect(s.title, '');
      expect(s.party.name, 'PARTY');
    });
  });
}
