# Roadmap

The canonical "where are we" tracker. The `**Next action:**` line below is auto-surfaced into context
at the start of every session by `.claude/hooks/workflow_hook.py`. Keep it current — update the
status boxes and the Next action line as each item is verified and committed.

**Next action:** Grow the procedure editor from its first runnable cut — candidate follow-ups:
inline icon/image cells *inside* the rich text (per-step icons already landed), a bundled Unicode PDF
font so arbitrary typed characters export cleanly, undo/redo, and enabling additional platforms
(`flutter create --platforms=…`).

## Status

### Foundation
- [x] Project scaffolded from `odb_library` practices — two packages, governance, docs.
- [x] Core infrastructure: `StepResult`, `StepError` (sealed), `Registry<T>` — domain-free.
- [x] UI: `EditorController` (`ChangeNotifier`, injectable clock), imports only the core.
- [x] `.claude` governance ported: hook, settings, 3 agents, 4 skills.
- [x] Merge to `main` (2026-07-22) — `main` created from the `feat/procedure-editor` tip (linear
  history containing the foundation + procedure editor v1), verified green across all three packages,
  and set as the GitHub default branch.

### Procedure editor (v1 — first runnable app)
The concrete domain landed as a **procedure table** editor (ported from the `Interactive Procedure`
HTML tool), not the abstract sealed `WorkflowStep` taxonomy originally sketched — the taxonomy remains
available in the core infra (`StepResult`/`StepError`/`Registry`) if a future feature needs it.
- [x] **Domain model** (core `lib/procedure/`) — `Party`, `ProcedureStep`, `ProcedureDocument` with
  `copyWith`, `toJson`, and hardened `fromJson`.
- [x] **Editor UI** (ui `lib/src/procedure/`) — `ProcedureEditorController` + widgets: table with
  drag-and-drop reorder, editable cells, party badge + in-house color picker/palette, editable
  notes/footer.
- [x] **Host app** — `workflow_step_editor_app` (Windows desktop), the first `flutter run` target.
  Import/export JSON, export PDF (portrait/landscape), export PNG.
- [x] **Per-step icons** — each `ProcedureStep` carries an `icon` key (curated Material-icon
  catalog in ui `step_icon_catalog.dart`, tap-to-pick via `showStepIconPicker`). Renders in the
  editor + PNG; PDF embeds each glyph as a rasterized PNG (`icon_raster.dart`) since Flutter's
  offline icon font is CFF, which the `pdf` package can't parse. Round-trips through JSON.

### Next
- [ ] Rich-text cells (icons/images *inline within* a cell's text), bundled Unicode PDF font,
  undo/redo, more platforms.
- [ ] When packaging a release, adopt a versioned + checksummed script (the `odb_library`
  `scripts/package-installers.ps1` template) and stage artifacts only in `dist/`.
