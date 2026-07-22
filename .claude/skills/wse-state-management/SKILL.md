---
name: wse-state-management
description: >-
  Use whenever adding or changing state on `EditorController` or `ProcedureEditorController` — a
  new field, a new setter, or anything a user would notice surviving (or not surviving) a widget
  rebuild. Trigger whenever a request mentions `ChangeNotifier`, `setState`, "remember", "persist",
  "restore on launch", "undo/redo", "state management", or "don't lose my edits" — even if none of
  those exact words appear, whenever a change touches
  `packages/workflow_step_editor_ui/lib/src/composite/editor_controller.dart` or
  `packages/workflow_step_editor_ui/lib/src/procedure/procedure_editor_controller.dart`. Defer
  "is this loaded value safe to trust" to [[wse-input-hardening]] — this skill owns what the state
  container *is* and what it *remembers*, not whether a loaded document is well-formed.
---

# State management — decide what the editor remembers, and don't duplicate the container

The UI's state today is deliberately simple: two `ChangeNotifier`s, no third-party state library, no
persistence beyond an explicit user-triggered JSON export/import. That simplicity is a decision, not
an accident — this skill exists so it stays a decision as more state gets added (undo/redo, richer
cells), rather than eroding one convenient shortcut at a time.

## Rule 1 — Decide ephemeral vs. persisted explicitly; don't default by omission

Purely transient UI state — a hover highlight, an in-progress drag, an open dropdown — can safely
live in a widget's local state and reset on rebuild; nobody expects otherwise. State the user would
call "my document" — step content, party assignments, notes/footer, icon choices — already lives in
`ProcedureDocument` via `ProcedureEditorController`, and today the only way it survives past the
running app is an explicit `JsonStore.save()`/`open()` the user triggers themselves. Any new field
needs the same explicit call made for it: does it live only in memory for this session, does it ride
along in `ProcedureDocument.toJson()`/`fromJson()` so it round-trips through explicit export/import,
or does it need something more (e.g. an autosave) — which does not exist yet and should not be
assumed. Silence defaults to "forgotten," which must be a conscious choice, not an oversight.

**Smell:** a new field added to `ProcedureDocument` or a controller with no note on whether it's
expected to survive an export/import round-trip.

## Rule 2 — One controller per editor domain, not a second competing one

`EditorController` and `ProcedureEditorController` are each the single source of truth for their
domain (generic step values; the procedure document). Extend the relevant one for new state rather
than introducing a second, parallel container (a new `ChangeNotifier`, a `StatefulWidget` holding a
value also readable from the controller) without a stated reason — two sources of truth for
overlapping state is how "which one is right" bugs start. This includes state added for roadmap
work like undo/redo: a history stack belongs alongside (or wrapping) the existing controller, not as
a separate parallel tracker that can drift out of sync with it.

**Smell:** a new `ChangeNotifier`/`StatefulWidget` holding a value that's also readable from
`EditorController` or `ProcedureEditorController`.

## Why the source-project rules on `SharedPreferences` and stale-reference revalidation aren't here

This skill is adapted from a sibling project's `state-management` skill, which also covers restart
persistence (`SharedPreferences` round-trip verification) and revalidating a restored reference
against live data (e.g. a device ID that may have gone offline). Neither applies yet: this project
has no restart-persisted state and no concept of a reference that can go stale behind the editor's
back. Add those rules here if/when this project grows real persistence beyond explicit JSON
export/import — don't invent SharedPreferences-shaped scaffolding pre-emptively.

## PR litmus test

- Is every new piece of controller/document state explicitly in-memory-only or part of
  `ProcedureDocument`'s JSON shape — never accidental?
- Does new state extend `EditorController` or `ProcedureEditorController` rather than spawning a
  second, competing container?
- Does the PR/commit note which state is ephemeral vs. persisted, and why?

## References

- `packages/workflow_step_editor_ui/lib/src/composite/editor_controller.dart` — the generic editor
  state container; extend this rather than duplicating it.
- `packages/workflow_step_editor_ui/lib/src/procedure/procedure_editor_controller.dart` — the
  procedure-document state container.
- `packages/workflow_step_editor_app/lib/src/export/json_store.dart` — the only persistence path
  today (explicit, user-triggered).
- Related skills: [[wse-input-hardening]] (a loaded JSON document is untrusted input — validate it
  there, not here), [[dart-solid-principles]] (controller class design/testability).

> Paths are intentionally concrete; if they move, update this skill.
