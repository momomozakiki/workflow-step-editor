# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`workflow-step-editor` is a Dart/Flutter project for editing workflow steps. It is scaffolded on the
proven practices of the sibling repo `odb_library`; the full rationale is in
[`docs/FOUNDATIONS.md`](docs/FOUNDATIONS.md). The domain model (the real `WorkflowStep` taxonomy) is
**not yet defined** — the core currently ships only domain-free infrastructure. See
[`docs/plan/ROADMAP.md`](docs/plan/ROADMAP.md).

**Core stays pure Dart with zero runtime dependencies** so it remains fully testable without Flutter;
do not add Flutter/platform/UI deps to it.

## Skills-first workflow (do this BEFORE any plan or change)

Before starting **any** task, decide which skill(s) apply and load them — then follow them. Common
mappings:

- Dart class/interface design, DRY, clean code → [`dart-solid-principles`](.claude/skills/dart-solid-principles/SKILL.md)
- Package layering & pubspec deps → [`wse-package-boundaries`](.claude/skills/wse-package-boundaries/SKILL.md)
- Any external/untrusted input (config, files, documents) → [`wse-input-hardening`](.claude/skills/wse-input-hardening/SKILL.md)
- Multi-part / cross-domain / ambiguous work → [`wse-orchestration`](.claude/skills/wse-orchestration/SKILL.md) (the team-leader workflow)

No suitable skill? If the capability is reusable, create it first with `skill-creator`; if it's
genuinely one-off, proceed and note why. Never duplicate a skill — extend it.

**Every plan starts with a "Skills used" table** documenting which rules the work rests on.

## Orchestration & the Definition of Done

Multi-part work runs through [`wse-orchestration`](.claude/skills/wse-orchestration/SKILL.md): a
3-route triage (A direct / B inline / C full team) and a 10-gate Definition of Done (checkpoint →
implement → security review → code review → verify → docs → retrospective → commit). Specialist
agents: `code-reviewer`, `security-reviewer`, `doc-writer`. **Right-size to the repo's stage** — until
there are ≥3 packages or a real domain, most tasks stay Route A/B (leader-only, inline); don't spin up
cold subagents for a one-file change.

## Commands

All work happens **inside a package directory**, not the repo root. The Dart/Flutter SDK is on PATH
(managed by puro); the workflow hook resolves it via PATH.

Core (`workflow_step_editor_core`, pure Dart):

```sh
cd packages/workflow_step_editor_core
dart pub get
dart analyze          # lint
dart test             # all tests
dart test test/registry_test.dart          # single file
dart test --name "unknown type"            # single test by name substring
```

UI (`workflow_step_editor_ui`, Flutter):

```sh
cd packages/workflow_step_editor_ui
flutter pub get
flutter analyze
flutter test
```

`workflow_step_editor_ui` is a **library with no `flutter run` target of its own**; running the UI
requires the host app below.

App (`workflow_step_editor_app`, Flutter desktop — the runnable host):

```sh
cd packages/workflow_step_editor_app
flutter pub get
flutter analyze
flutter test
flutter run -d windows   # hot reload for fast development
```

## Git Workflow

- **Default branch:** `main` (stable-only).
- **Checkpoint first:** commit/push the current working state before starting new work.
- **Branch for major/critical work:** `feat/<name>` / `fix/<name>` before touching code.
- **Commit & push feature branches automatically** once verification passes (`analyze` clean + tests
  green) — `git add`/`commit`/`push` are pre-approved in `.claude/settings.json`. **Exceptions that
  still require explicit confirmation:** pushing/merging to `main`, any force-push, or committing
  mid-task / with failing tests.
- Conventional Commits with a scope (`feat(core): …`, `fix(ui): …`).

The SessionStart/Stop hooks surface branch status and prompt for commits at the right moments.

## Architecture

Three packages under `packages/` (no monorepo manager — see FOUNDATIONS):

- **`workflow_step_editor_core`** — pure-Dart infrastructure + domain model. Public surface via the
  barrel `lib/workflow_step_editor_core.dart`; code in stage/feature folders directly under `lib/`
  (`core/`, `registry/`, `procedure/`) — **not** `lib/src/`.
  - `StepResult` — immutable `values` + `warnings` + `isPartial`; recoverable problems are warnings,
    not exceptions; thread state with `copyWith`.
  - `StepError` — **sealed** fatal-error hierarchy (`ConfigError`, `ProcessError`, `NotFoundError`).
  - `Registry<T>` — instance-based `type → factory` seam (Open/Closed + Dependency Inversion).
  - `procedure/` — the procedure-editor domain: `Party`, `ProcedureStep`, `ProcedureDocument`
    (immutable, `copyWith`, `toJson`/hardened `fromJson`). **Colors are `int` ARGB, not Flutter
    `Color`**, so the core stays Flutter-free.
- **`workflow_step_editor_ui`** — Flutter widget library; imports **only** the core; hides impl under
  `lib/src/`. State via `ChangeNotifier` (`EditorController`, `ProcedureEditorController`);
  dependencies constructor-injected with default fallbacks (injectable `clock` for deterministic
  tests). `lib/src/procedure/` holds the editor widgets (table with drag reorder, editable cells,
  party badge + color picker, notes/footer).
- **`workflow_step_editor_app`** — the runnable Flutter **desktop host** (Windows). Injects the
  platform concretions the libraries omit: `lib/src/export/` (`JsonStore`, `PdfExporter`,
  `ImageExporter`) is the only place `dart:io`, `pdf`, `printing`, and `file_selector` are used.

## Conventions

- **Lints:** recommended/flutter lints + `prefer_final_locals`, `prefer_const_constructors`,
  `avoid_print` (no `print` — use `StepWarning` or a thrown `StepError`). One `analysis_options.yaml`
  per package.
- **Dart 3.2+; sealed types hand-written** (no freezed/json_serializable/build_runner).
- **Tests:** one test file per source file, mirroring its name; happy + partial/warning + error paths;
  **hand-written fakes under `test/support/`** (no mock libraries); inject clock/IO for determinism.
- **SDK invariant:** core floor (`>=3.2.0`) ≤ UI floor (`^3.12.0`), same major ceiling.

See [`docs/FOUNDATIONS.md`](docs/FOUNDATIONS.md) for the full rationale.
