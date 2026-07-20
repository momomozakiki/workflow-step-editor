# workflow_step_editor_app

The runnable **desktop host** for the workflow procedure editor. It wires the pure-Dart core
(`workflow_step_editor_core`) and the Flutter UI library (`workflow_step_editor_ui`) together and
supplies the platform concretions the libraries deliberately leave out — file dialogs, PDF/print, and
image capture.

## Run (with hot reload)

```sh
cd packages/workflow_step_editor_app
flutter pub get
flutter run -d windows      # edit a widget + save to hot-reload
```

Windows is the only scaffolded platform for now; add others with
`flutter create --platforms=macos,linux,web .` from this directory.

> Requires the Windows desktop toolchain (Visual Studio with the "Desktop development with C++"
> workload). Verify with `flutter doctor`.

## Verify

```sh
flutter analyze
flutter test
flutter build windows --debug   # confirm the native build
```

## What it does (v1)

- Editable procedure table — add / delete rows, **drag to reorder**, edit each cell's text and the
  procedure title.
- Party badge per row with an in-house color picker (preset swatches + hex) and a reusable palette
  ("add new party").
- Editable document title/subtitle, Key Notes, and footer.
- **Import / Export JSON** (`ProcedureDocument` round-trips; import is hardened against malformed
  files).
- **Export PDF** (A4, choose portrait or landscape) and **Export PNG** (captures the procedure card).

## Architecture

The export/IO services under `lib/src/export/` are the only place `dart:io`, `pdf`, `printing`, and
`file_selector` are used — keeping the core pure and the UI library dependency-light (see the
`wse-package-boundaries` skill). PDF text currently uses the built-in Helvetica font, which covers
ASCII; a bundled Unicode font is a tracked follow-up (see `docs/plan/ROADMAP.md`).
