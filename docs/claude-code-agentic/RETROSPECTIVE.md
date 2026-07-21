# Retrospective

A running, dated log of what would make the skills / agents / workflow better — a misfired prompt, a
missing rule, a spawn that should've been inline, a convention that didn't fit. This is how the team
compounds (Gate 9 of `wse-orchestration`). Newest entries at the top.

---

## 2026-07-21 — Fixed step-cell focus loss while typing (unstable row key)

- **What was done:** Editable step cells dropped focus after every character. Root cause was the
  `ReorderableListView` row key `ValueKey('step-$i-${identityHashCode(steps[i])}')`: `copyWith` mints
  a new `ProcedureStep` per keystroke → new identity hash → new key → row remount → the cell's
  `TextEditingController`/focus node disposed. Fixed by keying rows on **position** (`ValueKey('step-$i')`).
  Added widget tests for per-keystroke focus retention and reorder-content correctness.
- **What worked:** Red-then-green discipline paid off — writing the focus test first proved it failed
  against the old key before the one-line fix, so the test genuinely guards the regression rather than
  just documenting current behaviour.
- **Adaptation to note:** the `wse-orchestration` triage correctly stayed **Route A** (one-file UI fix);
  no cold subagents spawned. A user code-review pass pushed back on index keys breaking
  `ReorderableListView` drag — worth recording the counter-argument: the list doesn't rebuild its
  `itemBuilder` with reordered data *mid-drag* (the backing list mutates only at drop via `moveStep`),
  so index keys stay stable during a gesture; the usual index-key caveat ("state follows position") is
  moot because `EditableCell` re-derives its text from `value` in `didUpdateWidget`. A stable model `id`
  was rejected because `ProcedureStep` is a value-equality type whose identity is deliberately its
  position — an `id` would break `==` and leak a UI concern into the pure core.
- **Skill gap:** none new. A one-line note in `dart-solid-principles` (or a future Flutter-UI skill)
  that "list-item widget keys must be derived from stable per-item identity, never from a value that
  `copyWith` regenerates" would have surfaced this class of bug up front — candidate if it recurs.

---

## 2026-07-21 — Step icons switched to flat-colour Twemoji PNGs

- **What was done:** Replaced the monochrome Material step glyphs with flat multi-colour **Twemoji**
  icons (closer to the reference infographic). The catalog now maps the same stable `String` key to a
  bundled `assets/icons/twemoji/<key>.png`; a single `stepIcon()` seam renders `Image.asset` for both
  the table slot and the picker, and the PDF exporter embeds the same PNG via `rootBundle` →
  `pw.MemoryImage`. Core stayed untouched (the key is still an opaque string).
- **What worked:** the earlier design paid off — because the core already stored an opaque key and the
  UI owned a single catalog seam, the whole restyle was UI/app-only with **zero core changes**. Driving
  the icon-source decision with a **published comparison Artifact** (real icon files fetched live and
  inlined — Material/Lucide/Phosphor/Twemoji/OpenMoji/Fluent 3D) let the user pick from actual samples
  instead of prose.
- **Adaptation to note (worth a skill hint):** rendering SVG icons **in the PDF is a trap**. Two paths
  were tried and both hung export: the `pdf` package's own `pw.SvgImage` (very slow on multi-path
  colour glyphs) and `flutter_svg`'s `vg.loadPicture` + offscreen `Picture.toImage` (does not complete
  under the non-widget test binding). The fix was to **ship pre-rendered PNG assets** and load bytes —
  no runtime rasterization at all. A future "colour icons in PDF" task should bundle raster assets
  rather than rasterize SVG at export time.
- **Testing gotcha:** the `PdfExporter.build` tests were plain `test()` and only "passed" originally
  because `rootBundle` failed silently (icons skipped). Once real asset loading worked they had to
  become `testWidgets` (binding required); a dedicated happy-path test now asserts the icon PNG
  actually loads so a silent-skip regression can't hide again.
- **Licensing note:** picked Twemoji (MIT) over extracting icons from the user's raster infographic
  (low quality + almost certainly Flaticon-licensed art). Worth a reusable stance: never rip icons out
  of a supplied bitmap; match the style with a permissively-licensed set instead.
- **Right-sizing:** implemented inline across ui/app; verification was the existing analyze + test gate
  (core 44 / ui 24 / app 5, all green). A concurrent session had shipped the v1 icon feature under me
  mid-task — surfaced it and paused rather than fighting the working tree, which avoided a clobber.

---

## 2026-07-21 — Per-step icons (editor + PNG + PDF)

- **What was done:** Added a chosen icon per `ProcedureStep`, mirroring the reference infographic.
  Core stores an opaque `String icon` key (Flutter-free, same spirit as `Party`'s ARGB ints); the UI
  owns the single-source-of-truth catalog (`step_icon_catalog.dart`, ~27 `const Icons.*` entries) and
  a search-filtered `showStepIconPicker`; the row shows a tap-to-pick slot left of the title cell.
- **What worked:** Reusing the `Party`/`PartyBadge`/`showPartyEditor` pattern made placement obvious —
  a primitive-typed core field + a UI catalog + a picker dialog + a `controller.updateIcon`, no new
  architecture. `const` catalog entries sidestep Flutter's release icon-tree-shaker with no build flag.
- **Adaptation to note (worth a skill hint):** the plan said "bundle `MaterialIcons-Regular.ttf`" for
  the PDF, but the only Material-icons font Flutter ships offline is **CFF/`OTTO`**, which the `pdf`
  package's TrueType parser rejects. Pivoted to rasterizing each glyph to a PNG via Flutter's own
  renderer (`icon_raster.dart`) and embedding `pw.Image` — fully offline, full fidelity. A future
  "icons in PDF" task should reach for glyph-rasterization first rather than font embedding.
- **Small gotcha:** `IconData` is exported from `package:flutter/widgets.dart`, not `painting.dart`;
  the first `icon_raster.dart` cut used `painting.dart` and failed to compile (caught by app analyze).
- **Right-sizing:** implemented inline across core/ui/app (the plan-mode Explore+Plan agents were used
  for design only); no review subagents spawned unprompted — verification was the existing
  analyze + test gate (core 44 / ui 24 / app 4, all green).

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
