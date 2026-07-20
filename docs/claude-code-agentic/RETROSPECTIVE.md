# Retrospective

A running, dated log of what would make the skills / agents / workflow better — a misfired prompt, a
missing rule, a spawn that should've been inline, a convention that didn't fit. This is how the team
compounds (Gate 9 of `wse-orchestration`). Newest entries at the top.

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
