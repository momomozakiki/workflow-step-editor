# workflow-step-editor

A Dart/Flutter project for editing workflow steps, built on a pure-Dart core + a Flutter UI.

> **Status:** foundation only. The core ships domain-free infrastructure (`StepResult`, `StepError`,
> `Registry<T>`); the real step model and editor UI are the next tasks — see
> [`docs/plan/ROADMAP.md`](docs/plan/ROADMAP.md).

## Layout

```
packages/
  workflow_step_editor_core/   # pure Dart — zero runtime deps, fully testable without Flutter
  workflow_step_editor_ui/     # Flutter widget library — imports only the core
```

No monorepo manager: each package is resolved independently. See
[`docs/FOUNDATIONS.md`](docs/FOUNDATIONS.md).

## Develop

Work **inside a package directory**:

```sh
# Core (pure Dart)
cd packages/workflow_step_editor_core
dart pub get && dart analyze && dart test

# UI (Flutter)
cd packages/workflow_step_editor_ui
flutter pub get && flutter analyze && flutter test
```

There is no CI server — the quality gate is local `analyze` + `test`.

## Documentation

- [`docs/FOUNDATIONS.md`](docs/FOUNDATIONS.md) — architecture, conventions, workflow, tooling.
- [`docs/plan/ROADMAP.md`](docs/plan/ROADMAP.md) — what's next.
- [`CLAUDE.md`](CLAUDE.md) — guidance for Claude Code, incl. the skills-first workflow.
