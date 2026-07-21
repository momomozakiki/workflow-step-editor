import 'package:flutter_test/flutter_test.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';
import 'package:workflow_step_editor_ui/workflow_step_editor_ui.dart';

import '../support/recording_listener.dart';

void main() {
  group('ProcedureEditorController', () {
    late ProcedureEditorController controller;
    late RecordingListener listener;

    setUp(() {
      controller = ProcedureEditorController();
      listener = RecordingListener();
      controller.addListener(listener.call);
    });

    test('defaults to the template document', () {
      expect(controller.document.steps, hasLength(11));
      expect(controller.parties, hasLength(4));
    });

    test('setIconSize updates the document icon size and notifies', () {
      expect(controller.document.iconSize, 'medium');
      controller.setIconSize('large');
      expect(controller.document.iconSize, 'large');
      expect(listener.calls, greaterThan(0));
    });

    test('accepts an injected initial document', () {
      final c = ProcedureEditorController(
        initial: const ProcedureDocument(
          title: 'T',
          subtitle: 'S',
          steps: [],
          parties: [Party.buyer],
          notes: '',
          footer: '',
        ),
      );
      expect(c.document.title, 'T');
      expect(c.document.steps, isEmpty);
    });

    test('addStep appends a blank step and notifies', () {
      controller.addStep();
      expect(controller.document.steps, hasLength(12));
      expect(controller.document.steps.last.title, isEmpty);
      expect(listener.calls, 1);
    });

    test('removeStep drops the row; out-of-range is a no-op', () {
      controller.removeStep(0);
      expect(controller.document.steps, hasLength(10));
      final before = listener.calls;
      controller.removeStep(99);
      expect(listener.calls, before); // no notify on no-op
    });

    test('updateTitle/action/documents edit the right row', () {
      controller.updateTitle(0, 'NEW TITLE');
      controller.updateAction(0, 'new action');
      controller.updateDocuments(0, 'new docs');
      final s = controller.document.steps.first;
      expect(s.title, 'NEW TITLE');
      expect(s.action, 'new action');
      expect(s.documents, 'new docs');
    });

    test('updateParty replaces the party for a row', () {
      controller.updateParty(0, Party.seller);
      expect(controller.document.steps.first.party, Party.seller);
    });

    test('updateIcon sets the icon for a row', () {
      controller.updateIcon(0, 'handshake');
      expect(controller.document.steps.first.icon, 'handshake');
      controller.updateIcon(0, ''); // clearing is allowed
      expect(controller.document.steps.first.icon, '');
    });

    test('moveStep reorders using onReorderItem (post-removal) semantics', () {
      final first = controller.document.steps[0].title;
      final second = controller.document.steps[1].title;
      // newIndex is the final index after removal, so 1 swaps rows 0 and 1.
      controller.moveStep(0, 1);
      expect(controller.document.steps[0].title, second);
      expect(controller.document.steps[1].title, first);
    });

    test('moveStep is a no-op for an out-of-range source', () {
      final before = listener.calls;
      controller.moveStep(99, 0);
      expect(listener.calls, before);
    });

    test('addPartyToPalette adds a new party but skips duplicates', () {
      const custom = Party(name: 'AGENT', backgroundArgb: 1, textArgb: 2);
      controller.addPartyToPalette(custom);
      expect(controller.parties, contains(custom));
      final count = controller.parties.length;
      controller.addPartyToPalette(custom);
      expect(controller.parties, hasLength(count));
    });

    test('setNotes / setFooter update the document', () {
      controller.setNotes('n');
      controller.setFooter('f');
      expect(controller.document.notes, 'n');
      expect(controller.document.footer, 'f');
    });

    test('load replaces the whole document', () {
      final doc = ProcedureDocument.fromJson({'title': 'LOADED', 'steps': []});
      controller.load(doc);
      expect(controller.document.title, 'LOADED');
      expect(controller.document.steps, isEmpty);
    });

    test('reset restores the template', () {
      controller.removeStep(0);
      controller.reset();
      expect(controller.document.steps, hasLength(11));
    });
  });
}
