# Retrospective

A running, dated log of what would make the skills / agents / workflow better — a misfired prompt, a
missing rule, a spawn that should've been inline, a convention that didn't fit. This is how the team
compounds (Gate 9 of `wse-orchestration`). Newest entries at the top.

---

## 2026-07-20 — Procedure editor v1 (first runnable desktop app)

- **What was done:** Recreated the `Interactive Procedure` HTML tool as a Flutter app across all three
  layers: domain model in the core (`Party`/`ProcedureStep`/`ProcedureDocument`, hardened `fromJson`),
  editor widgets in the UI (`ProcedureEditorController` + drag-reorder table, in-house color picker,
  editable notes/footer), and a new **`workflow_step_editor_app`** Windows host with JSON/PDF/PNG
  export. First `flutter run` target in the repo.
- **What worked:** `wse-package-boundaries` made the dependency placement unambiguous — storing colors
  as `int` ARGB kept the core Flutter-free, and confining `pdf`/`printing`/`file_selector`/`dart:io`
  to `app/lib/src/export/` kept the UI library dependency-light. The layered split meant the domain +
  controller were fully unit-tested (60 tests) before any GUI existed.
- **Adaptations to note:** (1) Flutter 3.44 deprecated `ReorderableListView.onReorder` in favor of
  `onReorderItem` (newIndex pre-adjusted for the removed item) — the controller's `moveStep` follows
  the new semantics. (2) The `pdf` package's built-in Helvetica has no Unicode glyphs, so the default
  template was switched to ASCII (curly quotes/middle-dot → straight); a bundled Unicode font is a
  tracked follow-up for arbitrary typed text.
- **Right-sizing:** three packages now exist (the `wse-orchestration` threshold for the full team),
  but per the harness guidance no cold review subagents were spawned unprompted — the security/DRY
  review was done inline (hardened `fromJson`, `FormatException` caught on import, no raw casts).

---

## 2026-07-20 — Project foundation scaffolded from odb_library

- **What was done:** Ported the reusable Dart/Flutter practices, workflow, and Claude Code governance
  from the sibling `odb_library` repo into this greenfield project: two-package layout (pure-Dart
  core + Flutter UI), lint baseline, LF normalization, the fail-soft `workflow_hook.py`, permissions
  allowlist, three domain-neutral agents (`code-reviewer`, `security-reviewer`, `doc-writer`), and
  four skills (`dart-solid-principles`, `wse-orchestration`, `wse-package-boundaries`,
  `wse-input-hardening`).
- **What worked:** Two review agents (a Claude Code doc-verifier + an architecture reviewer) caught
  concrete issues before implementation — lockfile un-ignore lines that don't apply to a library-only
  repo, a machine-specific `flutter_bin_dir` that would have leaked a path, and a placeholder domain
  type that would have pre-molded the real model. All were fixed in the plan.
- **Adaptation to note:** the ported hook now resolves the Dart/Flutter SDK via PATH (with an optional
  `WSE_DART_FLUTTER_BIN` / config override) instead of a hardcoded puro path, so it stays portable.
- **Open follow-up:** the full 10-gate/Route-C team is deliberately oversized for a 2-package repo;
  `wse-orchestration` documents this and says most tasks stay Route A/B until the repo grows.
