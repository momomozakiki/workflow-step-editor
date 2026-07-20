# Roadmap

The canonical "where are we" tracker. The `**Next action:**` line below is auto-surfaced into context
at the start of every session by `.claude/hooks/workflow_hook.py`. Keep it current — update the
status boxes and the Next action line as each item is verified and committed.

**Next action:** Define the real `WorkflowStep` domain model (sealed taxonomy + a `StepRegistry`) in
`workflow_step_editor_core`, replacing the test-only `FakeStep` used to prove the registry pattern.

## Status

### Foundation (in progress)
- [x] Project scaffolded from `odb_library` practices — two packages, governance, docs.
- [x] Core infrastructure: `StepResult`, `StepError` (sealed), `Registry<T>` — domain-free.
- [x] UI: `EditorController` (`ChangeNotifier`, injectable clock), imports only the core.
- [x] `.claude` governance ported: hook, settings, 3 agents, 4 skills.
- [ ] Merge `feat/project-foundation` to `main` once confirmed stable.

### Next
- [ ] **Domain model** — define the real `WorkflowStep` sealed taxonomy and its `StepRegistry` in the
  core. Delete the test-only `test/support/fake_step.dart` stand-in once real variants exist. This is
  the first feature task; the infra it builds on is already proven.
- [ ] **Editor UI** — build the actual step-editing widgets on top of `EditorController`.
- [ ] **Example / host app** — a Flutter package that *runs* the UI. `workflow_step_editor_ui` is a
  library with **no `flutter run` target of its own**; running it requires an example or host app.
  When one is added, adopt a versioned + checksummed packaging script (the `odb_library`
  `scripts/package-installers.ps1` template) and stage artifacts only in `dist/`.
