import 'package:flutter/foundation.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

/// Editor state for a [ProcedureDocument], exposed as a [ChangeNotifier] (the
/// project's only state mechanism — no third-party state library).
///
/// Every mutation rebuilds the immutable [document] via `copyWith` and notifies
/// listeners. The initial document is constructor-injected with a default
/// fallback so tests can supply a fixture; production callers pass nothing. This
/// class imports **only** the pure-Dart core.
class ProcedureEditorController extends ChangeNotifier {
  ProcedureEditorController({ProcedureDocument? initial})
      : _document = initial ?? ProcedureDocument.defaultTemplate();

  ProcedureDocument _document;

  /// The current, immutable document.
  ProcedureDocument get document => _document;

  /// The reusable party palette (the "add new party" list).
  List<Party> get parties => _document.parties;

  void _update(ProcedureDocument next) {
    _document = next;
    notifyListeners();
  }

  List<ProcedureStep> get _steps => _document.steps;

  // ── Document header ────────────────────────────────────────────────────
  void setDocumentTitle(String title) =>
      _update(_document.copyWith(title: title));

  void setDocumentSubtitle(String subtitle) =>
      _update(_document.copyWith(subtitle: subtitle));

  void setNotes(String notes) => _update(_document.copyWith(notes: notes));

  void setFooter(String footer) => _update(_document.copyWith(footer: footer));

  /// Set the document-wide step-icon size (one of `ProcedureDocument.iconSizes`).
  void setIconSize(String size) =>
      _update(_document.copyWith(iconSize: size));

  // ── Steps ──────────────────────────────────────────────────────────────
  /// Append a blank step assigned to [party] (defaults to the first palette
  /// entry, or [Party.buyer] if the palette is empty).
  void addStep({Party? party}) {
    final step = ProcedureStep(
      title: '',
      action: '',
      documents: '',
      party: party ?? (parties.isNotEmpty ? parties.first : Party.buyer),
    );
    _update(_document.copyWith(steps: [..._steps, step]));
  }

  void removeStep(int index) {
    if (index < 0 || index >= _steps.length) return;
    _update(_document.copyWith(steps: [..._steps]..removeAt(index)));
  }

  /// Move the step at [oldIndex] to [newIndex] (drag-and-drop reorder). Matches
  /// `ReorderableListView.onReorderItem` semantics: [newIndex] is the final
  /// insertion index **after** the item has been removed.
  void moveStep(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _steps.length) return;
    final next = [..._steps];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), moved);
    _update(_document.copyWith(steps: next));
  }

  void updateTitle(int index, String title) =>
      _replaceStep(index, (s) => s.copyWith(title: title));

  void updateAction(int index, String action) =>
      _replaceStep(index, (s) => s.copyWith(action: action));

  void updateDocuments(int index, String documents) =>
      _replaceStep(index, (s) => s.copyWith(documents: documents));

  void updateParty(int index, Party party) =>
      _replaceStep(index, (s) => s.copyWith(party: party));

  void updateIcon(int index, String icon) =>
      _replaceStep(index, (s) => s.copyWith(icon: icon));

  void _replaceStep(int index, ProcedureStep Function(ProcedureStep) change) {
    if (index < 0 || index >= _steps.length) return;
    final next = [..._steps];
    next[index] = change(next[index]);
    _update(_document.copyWith(steps: next));
  }

  // ── Palette ────────────────────────────────────────────────────────────
  /// Add [party] to the palette (skipping an exact duplicate).
  void addPartyToPalette(Party party) {
    if (parties.contains(party)) return;
    _update(_document.copyWith(parties: [...parties, party]));
  }

  // ── Whole-document ─────────────────────────────────────────────────────
  /// Replace the entire document (e.g. after importing a file).
  void load(ProcedureDocument document) => _update(document);

  /// Reset back to the default template.
  void reset() => _update(ProcedureDocument.defaultTemplate());
}
