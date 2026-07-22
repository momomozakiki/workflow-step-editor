---
name: wse-orchestration
description: >-
  Team-leader workflow for workflow-step-editor. Use whenever a request spans multiple packages or
  roles, needs several steps coordinated, or is ambiguous enough that you must first decide who does
  what — e.g. "add a step type and update the docs", "wire the editor end-to-end then document it",
  "plan and split this work", or any task where you'd otherwise juggle core + UI + docs at once. It
  decides which specialist agent or skill owns each part, creates a missing skill/agent first when
  there's a gap, runs the checkpoint → implement → security → code review → verify → docs →
  retrospective Definition of Done, and keeps `main` stable. Trigger it proactively for multi-part
  work even if the user never says "orchestrate" or "team".
---

# Orchestration — the team leader

Work in this repo splits along the package graph: the pure-Dart core, the Flutter UI, and docs. Each
domain has a **skill** (the rulebook); the review/docs domains also have a **specialist agent**. Your
job as the **main session** is to be the leader: read the request, decide who owns each part,
dispatch, and re-integrate. You are *not* a spawnable agent — subagents can't spawn other subagents,
so coordination lives here in the main thread.

> **Right-size to the repo's current stage.** This process is the *target* discipline. Until the repo
> has ≥3 packages or a real domain model, **most tasks are Route A/B (leader-only, inline)** — the
> full Route-C team + 10-gate flow documents intent, it does not gate trivial scaffolding. Don't spin
> up cold subagents for a one-file change. Let the process grow with the code, as it did in the repo
> this was ported from.

## The team

| Worker | Owns | Loads skill(s) |
|---|---|---|
| `security-reviewer` (agent) | the Security-review gate — reviews the assembled diff for input-hardening holes (read-only) | `wse-input-hardening` |
| `code-reviewer` (agent) | the Code-review gate (5b) — reviews the assembled diff for correctness/DRY/clean-code issues (read-only) | `dart-solid-principles` |
| `doc-writer` (agent) | general docs (README, roadmap, guides) | cites the relevant skill |
| core / UI work (inline) | Dart core + Flutter UI edits — no dedicated agent yet; apply inline | `dart-solid-principles`, `wse-package-boundaries`, `wse-input-hardening`, `wse-state-management` |

A worker that needs a rule it doesn't have should surface that back to you rather than guess — pause,
fill the gap (see Gate 2), and resume.

## Model tiering

| Tier | Model | Work |
|---|---|---|
| Leader / planning | **Sonnet (default)** | triage, synthesis, ambiguous scoping, integrating results |
| — escalation | **Opus (opt-in only)** | genuinely deep architecture/reasoning — per session, never standing |
| Mechanical / high-volume | **Haiku** | docs prose, scaffolding (`doc-writer`) |
| Review gates | **Sonnet** | `security-reviewer`, `code-reviewer` |

- **Sonnet is the leader's default.** Reserve Opus for the rare task that genuinely needs it.
- **Route A/B stay inline on the leader's model.** Only **Route C** dispatches.
- **Subagents, not experimental Agent Teams** — lower token cost, results summarized back.

## Dispatch mechanics

Spawn a worker with the **`Agent` tool** and `subagent_type: <agent-name>` (e.g.
`subagent_type: doc-writer`). Independent workers run in parallel: put **multiple `Agent` calls in
one message**. Each returns a summary; you re-integrate. **Prefer inline skill use over spawning for
small work** — a subagent is a cold start; for a one-file edit, just load the skill and do it.

## Gate 0 — Triage & confirm (run FIRST, every task)

Classify *how* the task will run into one of three routes, then **propose the route and get
confirmation**:

| Route | When | How it runs |
|---|---|---|
| **A — Direct edit** | one small change in a single domain; no build/verify/docs coordination | load the matching skill inline, do it, verify. No agents, no gate flow. |
| **B — Inline orchestration** | touches 1–2 domains, needs verify/docs/security but each chunk is small | run gates 1–10 **inline** (skills, no cold spawns). |
| **C — Full team** | spans 2+ domains, large/parallel chunks, or ambiguous scope | spawn specialist agents; run the full 10-gate Definition of Done. |

**Route B guardrail:** if the work would need **more than two separate review steps**, it's Route C.

**What counts as a "domain":** core Dart vs. Flutter UI vs. docs. Touching several files inside one
package for one concern is **not** a domain cross (stays Route A/B).

**Confirmation mechanics.** The triage output is always **route (A/B/C) + the "Skills used" table +
which agents (if any) + a one-line rationale.**
- *In plan mode:* fold the routing decision into the plan shown via `ExitPlanMode`.
- *Outside plan mode:* emit the proposal and then **stop** — no non-read action until the user replies
  affirmatively. After confirmation, emit **"Routing confirmed: [Route X] — proceeding."**

**Trivial exemption.** Typo / single-line / rename edits skip the confirmation, but **still state the
change made** afterward.

## Definition of Done (gates 1–10 — run Route B/C tasks through these)

Each gate has a single named owner. A gate is **skippable only with a one-line written
justification** in the task summary (e.g. "security N/A — markdown-only, no untrusted input").

| # | Gate | Owner | Output / done-when |
|---|------|-------|--------------------|
| 1 | **Intake & skills-match** | leader | one-line restatement + the CLAUDE.md *"Skills used"* table; ownership decided. |
| 2 | **Gap check** | leader (+ `skill-creator`) | missing skill created **before** the work depends on it; missing agent written as `.claude/agents/<name>.md`. Never duplicate a skill — extend it. |
| 3 | **Checkpoint / branch** | leader | `git status` clean & backed up; major/critical work on a fresh branch. No mid-task/broken commits. |
| 4 | **Implement** | inline (core/UI) | code + mirrored tests; parallel where independent, inline where small. |
| 5 | **Security review** | `security-reviewer` (`wse-input-hardening`) | reviews the diff → `PASS`/`CHANGES REQUESTED`. *Skip only if no untrusted-input surface — and say so.* |
| 5b | **Code review** | `code-reviewer` (`dart-solid-principles`) | reviews the diff for correctness/DRY → `PASS`/`CHANGES REQUESTED`. *Skippable inline for a tiny diff — run the checklist yourself and note it.* |
| 6 | **Verify** | leader | `dart analyze`+`dart test` (core) / `flutter analyze`+`flutter test` (UI) green. Don't proceed on red. |
| 7 | **Docs** | `doc-writer` | general docs (README/roadmap/guides) reflect the change. |
| 8 | *(reserved)* | — | no compliance domain in this repo yet; kept numbered so gate references stay stable. |
| 9 | **Retrospective** | leader | dated entry in `docs/claude-code-agentic/RETROSPECTIVE.md`: what would make the skills/agents/flow better. |
| 10 | **Commit / push** | leader | commit + push to the **feature branch** automatically (pre-approved). **Merge to `main` only when stable and the user explicitly OKs it.** Never force-push without confirmation. |

**Right-sizing:** for a genuinely tiny diff the leader may run a gate *inline* using the gate's skill
instead of spawning — but the gate is still **run and recorded**, never silently dropped.

## Dynamic flow (scope uncertain)

When intake can't confidently map the task to owners: spawn the built-in `Explore` agent
(`subagent_type: Explore`, read-only) to survey the code, then re-plan and re-enter at Gate 3. For
multi-step or ambiguous work that touches many files, enter **plan mode** first so the user approves
the approach before any edits.

## When in doubt (route cheat-sheet)

- One small edit in one domain → **Route A**.
- Touches 1–2 domains, or needs build/verify/docs coordination but each chunk is small → **Route B**.
- Touches 2+ domains, large/parallel chunks, or >2 separate review steps → **Route C**.
- Can't tell who owns it → **Route C** dynamic flow (Explore first).
