---
name: wse-package-boundaries
description: >-
  Use for questions about this project's package graph — which package a new file/feature belongs in,
  whether a dependency may be added to a package's pubspec, creating a new package, or whether an
  import crosses a layer it shouldn't. Trigger whenever the request mentions pubspec dependencies,
  "where does this belong", adding a plugin/Flutter dep, package layering, keeping the core pure, or
  SDK constraint ranges across packages. This is the package-graph guard (which package may depend on
  what); for class-level design within a package use dart-solid-principles instead.
---

# Package boundaries (the dependency graph)

The project is deliberately split into two packages so the **core stays pure Dart with zero runtime
dependencies** (fully testable without Flutter) and the **UI imports only the core**. This skill is
about the **dependency graph between packages**: who may import whom. For how a *class* inside one
package should be shaped, use [[dart-solid-principles]] — that's the class-level guard; this is the
package-level one. They meet at Dependency Inversion: DIP says depend on abstractions, and the
boundary below is *where* that rule is physically enforced.

## The allowed dependency directions

| Package | May depend on | Must NOT depend on |
| --- | --- | --- |
| `workflow_step_editor_core` (**core**) | pure Dart only | Flutter SDK, any UI, `dart:io`, plugins — **zero runtime deps** |
| `workflow_step_editor_ui` (**UI**, `lib/src/**`) | the **core** + Flutter SDK | any concrete I/O implementation or platform plugin (inject it from a host instead) |
| a future host/app entrypoint (`lib/main.dart`) | everything — it **injects** concretions | — |

**The key inversion:** library code never imports a concrete implementation; a **host/app** registers
factories at startup (`registry.register('type', Impl.new)`) so the core and UI stay platform-neutral.

## SDK constraint invariant

The core uses `sdk: '>=3.2.0 <4.0.0'` (the `3.2.0` floor is the first SDK with `sealed`/`final
class`); the UI uses `sdk: ^3.12.0`. The rule to preserve when bumping either:

> **Core SDK floor ≤ UI SDK floor, same major ceiling.**

If the *core* ever raised its floor above the UI's (e.g. core `>=3.15.0` while UI stays `^3.12.0`),
the UI would fail to resolve on SDKs in the gap. Keep the core's floor the lower (or equal) of the two.

## No monorepo manager — on purpose

There is **no** melos, no root `pubspec.yaml` pub-workspace. Each package is resolved independently
(`pub get` per package). A pub workspace would pin the whole repo to one SDK floor, defeating the
core's lower `>=3.2.0` floor — do not add one. See `docs/FOUNDATIONS.md`.

## Smells (each is a boundary break)

- Any `import 'package:flutter/...'`, `dart:io`, or a concrete I/O / platform plugin **inside
  `workflow_step_editor_core/lib/`** — the core must stay pure.
- A concrete I/O implementation imported under `workflow_step_editor_ui/lib/src/**` instead of being
  injected from a host.
- Adding a Flutter dependency to the core's `pubspec.yaml`. If a feature seems to *need* one, it
  belongs in a different package — that's the signal, not a reason to relax the core.

## Reviewer self-checks (run by hand; not a CI test)

```sh
# Core must be Flutter/plugin/dart:io free:
grep -rE "package:flutter|dart:io" packages/workflow_step_editor_core/lib/ && echo "BOUNDARY BREAK" || echo "core clean"

# UI library must import only the core (never a concrete I/O impl it should inject):
grep -rn "dart:io" packages/workflow_step_editor_ui/lib/src/ && echo "CHECK: should this be injected?" || echo "src clean"
```

A non-empty match on the core check is the thing to fix (or consciously move the file to a host
entrypoint).

## Where does a new thing go?

- Needs only Dart + does modelling / validation / transforms → **core** (`workflow_step_editor_core`).
- A Flutter widget or controller that renders/edits domain state → `workflow_step_editor_ui/lib/src/`.
- `dart:io`, sockets, file pickers, platform channels → a **host/app** entrypoint (not yet created;
  see `docs/plan/ROADMAP.md`).

## References

- `CLAUDE.md` → **Architecture** — the package list and the decoupling rule.
- `docs/FOUNDATIONS.md` — the no-monorepo-manager decision and SDK-tier rationale.
- [[dart-solid-principles]] (DIP, class-level) — the principle this boundary physically enforces.

> Paths are intentionally concrete; if they move, update this skill.
