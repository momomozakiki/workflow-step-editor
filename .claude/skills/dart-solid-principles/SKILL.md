---
name: dart-solid-principles
description: >-
  Use when writing or reviewing Dart classes, registries, interfaces, controllers, or services in
  this repository, especially when the request mentions SOLID, single responsibility, open/closed,
  Liskov substitution, interface segregation, dependency inversion, code structure, tight coupling,
  god classes, or where a feature should live. Also use for everyday Dart programming practices —
  DRY, code reuse vs duplication, modularity, file or class size, naming and visibility,
  immutability, copyWith, helper extraction, test structure/mirroring, "make this reusable", or
  "clean code". Scoped to Dart only.
---

# SOLID principles for Dart (workflow-step-editor)

Apply these when shaping Dart code in this repo — deciding where a class lives, what it depends on,
and how it extends. The point isn't dogma: SOLID is the *reason* this project's rules work (the core
stays **pure Dart, zero runtime deps, fully testable without Flutter**). The infrastructure in
`workflow_step_editor_core` already embodies all five principles; use the real code as the reference
model rather than inventing new abstractions.

> This skill is Dart-only. If a second language is ever added, create a sibling skill — don't stretch
> this one across languages.

## S — Single Responsibility

A class should have one reason to change. Keep each concern in its own file/type: a result value
(`StepResult`), an error taxonomy (`StepError`), an extension seam (`Registry<T>`), UI state
(`EditorController`). A change to one should not force edits to the others.

**Smell:** a class that both holds state *and* parses input *and* renders a widget. If you'd describe
a class with "and", it likely has two responsibilities — split it.

## O — Open/Closed

Open for extension, closed for modification. Add new behavior by writing a new implementer and
**registering a factory** — never by editing a central `switch`. `Registry<T>`
(`lib/registry/registry.dart`) maps a string `type` → a factory closure:

```dart
final registry = Registry<MyThing>()
  ..register('a', MyThingA.new); // tear-off factory
final thing = registry.create('a');       // fresh instance each call
```

**Smell:** a `switch (type)` over a hardcoded list in the core that grows every time a case is added.
That's modification, not extension.

## L — Liskov Substitution

Any subtype must be usable wherever the base type is expected — honoring the **contract
(postconditions)**, not just the signature. The project's contract: recoverable problems are surfaced
as `StepResult.warnings` + `isPartial = true`, **not** thrown. A subtype that threw for a merely
degraded input (instead of returning a partial result) would break every caller written against that
contract — even though it compiles. That's the LSP violation here.

**Smell:** a subclass that throws where its siblings return a partial result, or tightens
preconditions (rejects input the base type accepts).

> Reserve thrown errors (`StepError` variants) for genuinely fatal cases — see Error types below.

## I — Interface Segregation

No client should depend on methods it doesn't use. Prefer modelling closed input variants as a
**sealed type** and switching on only the variant(s) a given consumer supports, over a fat interface
that forces no-op implementations. An exhaustive `switch` over a sealed hierarchy (see `StepError`)
removes dead surface area.

**Smell:** a fat interface that makes implementers write `handleX() => throw Unimplemented` just to
satisfy the contract.

## D — Dependency Inversion

Depend on abstractions; inject concretions. **Registry-based injection + constructor injection are
how DIP is enforced here.** The core defines abstractions and **never imports a concrete
implementation**; the host/app injects factories at startup. UI controllers take their dependencies
via the constructor with default fallbacks:

```dart
EditorController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
```

The testable invariant: **the core never imports Flutter or a concrete I/O implementation**, and
time/IO-dependent code is injectable so it can be unit-tested deterministically.

**Smell:** `import 'package:flutter/...'` or a concrete I/O package inside `workflow_step_editor_core/lib/`.

## Error types

`StepError` (`lib/core/step_error.dart`) is a **sealed** exception hierarchy for *fatal* errors
(`ConfigError` with a `validationErrors` list, `ProcessError`, `NotFoundError`). Use it precisely so
LSP and ISP don't read as a contradiction:

- **Fatal:** throw a specific `StepError` variant for input/config the code genuinely can't handle.
- **Recoverable:** do **not** throw — surface as `StepResult.warnings` + `isPartial`.

## Applying this — PR litmus test

- ✅ Does this class have only one reason to change?
- ✅ Can I extend behavior by adding a class and registering it, without editing the core?
- ✅ Can I replace any implementation without breaking the caller (same `StepResult` contract)?
- ✅ Do clients depend only on the variants/methods they actually use?
- ✅ Does the core import only abstractions, never Flutter or concrete I/O?

## Practices — applying SOLID in everyday Dart

SOLID is the *why*; these are the daily habits that keep code modular, reusable, and DRY. They name
what the codebase already does, so new code matches it. (The lint set and file/test conventions in
`CLAUDE.md` → **Conventions** are assumed, not restated here.)

### DRY & reuse-before-build

Prefer reusing an existing primitive or seam over writing a new one; a near-duplicate is a smell.

- **Reuse the primitive.** `StepResult`, `StepError`, and `Registry<T>` are the building blocks;
  build on them rather than re-rolling a parallel result/error/registry type.
- **Extract a private helper** when logic is duplicated or a function grows past ~30 lines. Keep it
  private in the same file until a *second* file needs it — then promote it. Don't generalize on the
  first use.
- **One generic, never a second copy.** `Registry<T>` is the pattern — a second copy-pasted
  store/registry parameterizable by a type is a must-fix in review.
- **Lint parity.** Every package carries its own `analysis_options.yaml` with the repo baseline
  (recommended/flutter lints + `prefer_final_locals`, `prefer_const_constructors`, `avoid_print`).

### File & class size

Small, single-purpose files (aim ≤200 lines; ≤300 for a genuinely complex case). The "and" test for
class responsibilities is the concrete S smell.

### Immutability & `copyWith`

Model/result types take `const` constructors and stay immutable; thread state through a pipeline with
`copyWith` (e.g. `StepResult.copyWith`) rather than mutation. Immutability is what lets stages
compose without spooky action at a distance.

### Naming & visibility

Private helpers `_camelCase`; class constants `static const camelCase`; sealed-type variants as
`final class`. Names carry intent — a reader should not need the body to know what a helper does.

### Test-mirroring & determinism

One test file per source file, **mirroring its name**; cover happy + partial/warning + error paths.
Make logic testable without Flutter, a clock, or the filesystem by **injecting** those — e.g.
`EditorController` takes an injectable `clock`, so its logic is unit-tested deterministically. Use
hand-written fakes under `test/support/` — no mock libraries.

## References

- `packages/workflow_step_editor_core/lib/` — `StepResult`, `StepError`, `Registry<T>` (the worked
  examples of the five principles).
- `packages/workflow_step_editor_ui/lib/src/composite/editor_controller.dart` — injectable `clock`,
  `ChangeNotifier` state.
- `CLAUDE.md` → **Architecture** & **Conventions**.
- Related: [[wse-package-boundaries]] (DIP at the package level), [[wse-input-hardening]].

> References are intentionally concrete; if those paths move, update this skill.
