# Foundations — practices, workflow & tooling

This project's engineering foundation, distilled from the mature sibling repo
[`odb_library`](https://github.com/momomozakiki/odb_library) and adapted here. It records the *why*
behind the conventions so they don't erode. For the machine-readable rulebooks, see `.claude/skills/`.

## Architecture

- **Two packages, layered.** `workflow_step_editor_core` is **pure Dart, zero runtime dependencies,
  fully testable without Flutter**; `workflow_step_editor_ui` is a Flutter widget library that
  **imports only the core**. A future host/app entrypoint injects any concrete I/O. The physical
  package split is what makes "the core stays pure" enforceable rather than a convention a lint can't
  fully check. See [`wse-package-boundaries`](../.claude/skills/wse-package-boundaries/SKILL.md).
- **Zero code generation.** No `build_runner`, `freezed`, or `json_serializable`. Sealed types are
  hand-written (`sealed` / `final class`, Dart 3.2+).
- **Core primitives** (`workflow_step_editor_core`):
  - `StepResult` — immutable result carrying `values` + non-fatal `warnings` + `isPartial`.
    Recoverable problems are **warnings, not exceptions**; thread state with `copyWith`.
  - `StepError` — a **sealed** hierarchy for *fatal* errors (`ConfigError`, `ProcessError`,
    `NotFoundError`).
  - `Registry<T>` — instance-based (not a global singleton): string `type` → factory tear-off. This
    is the Open/Closed + Dependency-Inversion seam; the core never imports a concrete implementation.
- **State & DI (UI):** `ChangeNotifier`/`ValueNotifier` only — no `provider`/`riverpod`/`bloc`/
  `get_it`. Dependencies are **constructor-injected with default fallbacks** (`Ctrl({Dep? dep}) : dep
  = dep ?? Dep()`), which also makes time/IO injectable for deterministic tests.

## SDK constraints (two tiers)

- Core: `sdk: '>=3.2.0 <4.0.0'` — `3.2.0` is the first SDK with `sealed`/`final class`.
- UI: `sdk: ^3.12.0` (`flutter: '>=3.0.0'`).
- **Invariant:** core SDK floor ≤ UI SDK floor, same major ceiling. Verified toolchain: Dart 3.12.1 /
  Flutter 3.44.1.

## No monorepo manager — on purpose

There is **no** melos and **no** root pub-workspace. Each package is resolved independently
(`pub get` per package). A pub workspace would pin the whole repo to a single SDK floor, defeating the
core's lower `>=3.2.0` floor. Do not add one. The per-package `pub get` cost for two packages is
trivial.

## Conventions

- **Lints:** `package:lints/recommended` (core) / `package:flutter_lints` (UI), each **plus**
  `prefer_final_locals`, `prefer_const_constructors`, `avoid_print`. Every package carries its own
  `analysis_options.yaml` (lint parity, so a package stays self-contained if moved). `avoid_print` is
  load-bearing — surface problems via `StepWarning` or a thrown `StepError`, never `print`.
- **Layout:** one public **export barrel** per package (`lib/<name>.dart`). The **core** organizes
  code in stage/feature folders directly under `lib/` (`core/`, `registry/`); the **UI** hides
  implementation under `lib/src/`.
- **Naming:** files `snake_case.dart`; private helpers `_camelCase`; sealed variants `final class`;
  immutable value types with `const` constructors + `copyWith`.
- **File/class size:** aim ≤200 lines (≤300 for a genuinely complex case). The "and" test flags a
  class with two responsibilities.
- **Tests:** `package:test` (core) / `flutter_test` (UI). **One test file per source file, mirroring
  its name**; cover happy + partial/warning + error paths. **Hand-written fakes under `test/support/`
  — no `mockito`/`mocktail`.** Inject clock/IO for determinism.

## Workflow & tooling

- **No CI server.** Quality gate is local: `dart analyze` + `dart test` (core), `flutter analyze` +
  `flutter test` (UI) — run **inside each package directory**, never the repo root. Enforced by
  convention plus the Stop hook.
- **Git:** checkpoint-first (back up before new work), feature branches (`feat/…`/`fix/…`) for
  major/critical work, `main` is stable-only (never force-push or push to `main` without explicit
  confirmation). Conventional Commits with a scope (`feat(core): …`). LF line endings enforced via
  `.gitattributes`. Library lockfiles are gitignored (add a `!` exception only when a shipped app is
  introduced).
- **Claude Code governance** (`.claude/`):
  - `hooks/workflow_hook.py` — a fail-soft dispatcher on SessionStart / PostToolUse / Stop. Surfaces
    git + SDK status and the ROADMAP "Next action" at session start; nudges docs after a `lib/` edit;
    reminds to commit + add a retrospective entry at Stop; writes a `plans/UNFINISHED.md` breadcrumb
    on a dirty tree. Config-driven via `.claude/workflow_config.json`; resolves the SDK via PATH (or
    the `WSE_DART_FLUTTER_BIN` env / config override) — nothing machine-specific is committed.
  - `settings.json` — a pre-approved allowlist (git add/commit/push, dart/flutter analyze/test, gh pr
    read) so verified feature-branch work commits without prompting.
  - `agents/` — `code-reviewer`, `security-reviewer`, `doc-writer`.
  - `skills/` — `dart-solid-principles`, `wse-orchestration`, `wse-package-boundaries`,
    `wse-input-hardening`. **Load the matching skill before starting any task.**
  - `wse-orchestration` defines a 3-route triage + 10-gate Definition of Done. It is the *target*
    discipline; until the repo has ≥3 packages or a real domain, most tasks stay Route A/B
    (leader-only) — the ceremony documents intent, it does not gate trivial work.

## What was intentionally left behind from odb_library

ODB's domain-specific skills/agents (adapters, hub/IPC, camera, compliance/PDPA, release packaging)
and its `docs/spec`, `docs/hub`, `docs/compliance` trees — none apply here. The release packaging
script is deferred until there's a shippable app (see `docs/plan/ROADMAP.md`).
