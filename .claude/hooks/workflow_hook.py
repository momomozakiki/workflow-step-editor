#!/usr/bin/env python
"""workflow-step-editor workflow-nudge hook.

One dispatcher wired to three Claude Code hook events. Ported from odb_library's
hook and rebound to this repo's canonical files. Path constants are overridable
per-key via ``.claude/workflow_config.json``; a missing/malformed config or key
falls back to the in-code default, so the hook always fails soft. A
``plans/UNFINISHED.md`` breadcrumb is refreshed at Stop on a dirty tree.

- ``SessionStart`` (startup|resume) — injects git branch/dirty status, a
  dart/flutter version check, and the ``**Next action:**`` line out of
  ``docs/plan/ROADMAP.md``.
- ``PostToolUse`` (Edit|Write|MultiEdit) — advisory, fires once per session: if
  a package `lib/` file was touched and no ``docs/`` file has been
  touched yet this session, nudge toward CLAUDE.md's doc-update rule
  (docs/plan/ROADMAP.md + relevant guides).
- ``Stop`` — reminds (never hard-blocks past ``MAX_STOP_BLOCKS``) to commit a
  dirty non-main tree, and to add a dated entry to
  ``docs/claude-code-agentic/RETROSPECTIVE.md`` when source changed
  this session without one; also refreshes the ``plans/UNFINISHED.md``
  breadcrumb whenever the tree is dirty (any branch).

Every handler fails soft: any unexpected error exits 0, so a hook never breaks
a tool call or a turn. Output shapes are event-specific (validated against the
source implementation, not the outdated "decision: approve" spec examples):
SessionStart/PostToolUse use ``hookSpecificOutput.additionalContext``; Stop
uses a top-level ``decision``/``reason``.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

MAX_STOP_BLOCKS = 2
STATE_TTL_SECONDS = 24 * 3600
GIT_TIMEOUT = 10
ENV_TIMEOUT = 10

# In-code defaults. Each is overridable per-key via .claude/workflow_config.json
# (see _apply_config); a missing key, a missing/malformed config file, or a
# wrong-typed value falls back to the default here, so the hook always fails soft.
_DEFAULT_SOURCE_MARKER = "/lib/"  # any packages/*/lib/** file
_DEFAULT_DOCS_MARKER = "docs/"
_DEFAULT_RETROSPECTIVE_PATH = "docs/claude-code-agentic/RETROSPECTIVE.md"
_DEFAULT_ROADMAP_PATH = "docs/plan/ROADMAP.md"

SOURCE_MARKER = _DEFAULT_SOURCE_MARKER
DOCS_MARKER = _DEFAULT_DOCS_MARKER
RETROSPECTIVE_PATH = _DEFAULT_RETROSPECTIVE_PATH
ROADMAP_PATH = _DEFAULT_ROADMAP_PATH

CONFIG_PATH = ".claude/workflow_config.json"

# SDK bin dir. Resolution precedence (see _resolve_bin_dir): the WSE_DART_FLUTTER_BIN
# env var, then the config's "flutter_bin_dir" key, then None — in which case
# _env_status falls back to the dart/flutter on PATH. Nothing machine-specific is
# baked in, so the committed config stays portable across machines/CI.
_CONFIG_FLUTTER_BIN_DIR: str | None = None


def _load_config(project_dir: Path) -> dict:
    """Read .claude/workflow_config.json; return {} on any problem (fail-soft)."""
    try:
        raw = json.loads((project_dir / CONFIG_PATH).read_text(encoding="utf-8"))
        return raw if isinstance(raw, dict) else {}
    except (OSError, ValueError):
        return {}


def _apply_config(project_dir: Path) -> None:
    """Override the module-level path constants from config, per-key.

    Only a present, correctly-typed string replaces a default; anything else
    leaves that constant at its in-code default, so one bad/missing key never
    disturbs the others.
    """
    global SOURCE_MARKER, DOCS_MARKER, RETROSPECTIVE_PATH, ROADMAP_PATH
    global _CONFIG_FLUTTER_BIN_DIR
    cfg = _load_config(project_dir)

    def _str(key: str, default: str) -> str:
        val = cfg.get(key)
        return val if isinstance(val, str) and val else default

    SOURCE_MARKER = _str("source_marker", _DEFAULT_SOURCE_MARKER)
    DOCS_MARKER = _str("docs_marker", _DEFAULT_DOCS_MARKER)
    RETROSPECTIVE_PATH = _str("retrospective_file", _DEFAULT_RETROSPECTIVE_PATH)
    ROADMAP_PATH = _str("roadmap_file", _DEFAULT_ROADMAP_PATH)
    bin_dir = cfg.get("flutter_bin_dir")
    _CONFIG_FLUTTER_BIN_DIR = bin_dir if isinstance(bin_dir, str) and bin_dir else None


# --- state helpers ----------------------------------------------------------
def _state_path(session_id: str) -> Path:
    safe = re.sub(r"[^A-Za-z0-9_.-]", "_", session_id or "default")
    return Path(tempfile.gettempdir()) / f"workflow_hook_state_{safe}.json"


def _load_state(session_id: str) -> dict:
    try:
        return json.loads(_state_path(session_id).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def _save_state(session_id: str, state: dict) -> None:
    path = _state_path(session_id)
    try:
        fd, tmp_name = tempfile.mkstemp(
            dir=str(path.parent), prefix=path.name + ".", suffix=".tmp"
        )
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(state, f)
            os.replace(tmp_name, path)
        except OSError:
            try:
                os.unlink(tmp_name)
            except OSError:
                pass
    except OSError:
        pass


def _cleanup_stale_state() -> None:
    cutoff = time.time() - STATE_TTL_SECONDS
    try:
        for p in Path(tempfile.gettempdir()).glob("workflow_hook_state_*.json"):
            try:
                if p.stat().st_mtime < cutoff:
                    p.unlink()
            except OSError:
                pass
    except OSError:
        pass


def _project_dir(data: dict) -> Path:
    return Path(os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or ".")


def _tool_input(data: dict) -> dict:
    ti = data.get("tool_input")
    return ti if isinstance(ti, dict) else {}


# --- output helpers ----------------------------------------------------------
def _emit_context(event: str, message: str, session_title: str | None = None) -> int:
    payload: dict = {
        "hookSpecificOutput": {
            "hookEventName": event,
            "additionalContext": message,
        }
    }
    if session_title:
        payload["sessionTitle"] = session_title
    print(json.dumps(payload))
    return 0


def _emit_stop_block(reason: str) -> int:
    print(json.dumps({"decision": "block", "reason": reason}))
    return 0


# --- SessionStart pieces ------------------------------------------------------
def _git_status(project_dir: Path) -> str:
    try:
        branch = subprocess.run(
            ["git", "-C", str(project_dir), "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=GIT_TIMEOUT,
        ).stdout.strip() or "(unknown)"
        porcelain = subprocess.run(
            ["git", "-C", str(project_dir), "status", "--porcelain"],
            capture_output=True, text=True, timeout=GIT_TIMEOUT,
        ).stdout
        dirty = "dirty" if porcelain.strip() else "clean"
        ahead_behind = subprocess.run(
            ["git", "-C", str(project_dir), "rev-list", "--left-right", "--count",
             "@{u}...HEAD"],
            capture_output=True, text=True, timeout=GIT_TIMEOUT,
        )
        sync_note = ""
        if ahead_behind.returncode == 0 and ahead_behind.stdout.strip():
            behind, ahead = (ahead_behind.stdout.strip().split() + ["0", "0"])[:2]
            if behind != "0" or ahead != "0":
                sync_note = f", {ahead} ahead / {behind} behind origin"
        return f"Git: branch `{branch}`, {dirty}{sync_note}"
    except Exception:
        return "Git: (status unavailable)"


def _resolve_bin_dir() -> Path | None:
    # Precedence: env override > config flutter_bin_dir > None (fall back to PATH).
    override = os.environ.get("WSE_DART_FLUTTER_BIN")
    if override:
        return Path(override)
    if _CONFIG_FLUTTER_BIN_DIR:
        return Path(_CONFIG_FLUTTER_BIN_DIR)
    return None


def _resolve_exe(bin_dir: Path | None, name: str, exe: str) -> str | None:
    """Locate a tool: prefer the configured bin dir, else fall back to PATH.

    Returns an invokable path/name, or None if it can't be found either way.
    """
    if bin_dir is not None:
        path = bin_dir / exe
        return str(path) if path.exists() else None
    from shutil import which
    return which(name) or which(exe)


def _env_status() -> str:
    bin_dir = _resolve_bin_dir()
    parts = []
    for name, exe in (("dart", "dart.bat"), ("flutter", "flutter.bat")):
        resolved = _resolve_exe(bin_dir, name, exe)
        if not resolved:
            where = f" ({bin_dir})" if bin_dir else " (not on PATH)"
            parts.append(f"{name}: not found{where}")
            continue
        try:
            proc = subprocess.run(
                [resolved, "--version"], capture_output=True, text=True,
                timeout=ENV_TIMEOUT,
            )
            line = (proc.stdout or proc.stderr or "").strip().splitlines()
            parts.append(f"{name}: {line[0] if line else 'ok'}")
        except Exception:
            parts.append(f"{name}: (version check failed)")
    return "Env — " + "; ".join(parts)


def _next_roadmap_action(project_dir: Path) -> str | None:
    try:
        text = (project_dir / ROADMAP_PATH).read_text(encoding="utf-8")
    except OSError:
        return None
    m = re.search(r"\*\*Next action:\*\*\s*(.+)", text)
    return m.group(1).strip() if m else None


def handle_session_start(data: dict, session_id: str) -> int:
    _cleanup_stale_state()
    _save_state(session_id, {})  # fresh session: reset all per-session flags
    project_dir = _project_dir(data)

    parts = [f"[{_git_status(project_dir)}]", f"[{_env_status()}]"]

    next_action = _next_roadmap_action(project_dir)
    if next_action:
        parts.append(f"[ROADMAP next action] {next_action}")
    else:
        parts.append(f"[ROADMAP] (no '**Next action:**' line found in {ROADMAP_PATH})")

    return _emit_context(
        "SessionStart", "\n\n".join(parts),
        session_title="workflow-step-editor session",
    )


# --- PostToolUse --------------------------------------------------------------
def _modified_paths(tool: str, ti: dict) -> list[str]:
    paths: list[str] = []
    if tool in ("Edit", "Write", "NotebookEdit"):
        fp = ti.get("file_path")
        if fp:
            paths.append(str(fp))
    elif tool == "MultiEdit":
        fp = ti.get("file_path")
        if fp:
            paths.append(str(fp))
        for edit in ti.get("edits") or []:
            if isinstance(edit, dict):
                efp = edit.get("file_path")
                if efp:
                    paths.append(str(efp))
    return [p.replace("\\", "/") for p in paths]


def _touches_source(path: str) -> bool:
    return SOURCE_MARKER in f"/{path}"


def _touches_docs(path: str) -> bool:
    return DOCS_MARKER in path


def _touches_retrospective(path: str) -> bool:
    return path.endswith(RETROSPECTIVE_PATH) or RETROSPECTIVE_PATH in path


def handle_post_tool_use(data: dict, session_id: str) -> int:
    tool = (data.get("tool_name") or "").strip()
    if tool == "Bash":
        return 0  # can't reliably tell which files a Bash command touched

    paths = _modified_paths(tool, _tool_input(data))
    if not paths:
        return 0

    state = _load_state(session_id)
    dirty = False

    if any(_touches_retrospective(p) for p in paths) and not state.get("retrospective_touched"):
        state["retrospective_touched"] = True
        dirty = True
    if any(_touches_docs(p) for p in paths) and not state.get("docs_touched"):
        state["docs_touched"] = True
        dirty = True
    if any(_touches_source(p) for p in paths) and not state.get("source_changed"):
        state["source_changed"] = True
        dirty = True

    touched_docs_this_call = any(_touches_docs(p) for p in paths)
    touched_source_this_call = any(_touches_source(p) for p in paths)
    emit_nudge = (
        touched_source_this_call
        and not touched_docs_this_call
        and not state.get("docs_touched")
        and not state.get("doc_nudge_emitted")
    )
    if emit_nudge:
        state["doc_nudge_emitted"] = True
        dirty = True

    if dirty:
        _save_state(session_id, state)
    if emit_nudge:
        return _emit_context(
            "PostToolUse",
            "Source under packages/*/lib/ changed. Per CLAUDE.md, consider updating "
            "the relevant docs (docs/plan/ROADMAP.md status + any user-facing guide) "
            "to reflect the change. If nothing user-facing changed, do nothing. "
            "(This reminder fires once per session.)",
        )
    return 0


# --- Stop ----------------------------------------------------------------------
UNFINISHED_PATH = "plans/UNFINISHED.md"
BREADCRUMB_START = "<!-- workflow-hook: auto-breadcrumb -->"
BREADCRUMB_END = "<!-- /workflow-hook: auto-breadcrumb -->"


def _git_branch_and_porcelain(project_dir: Path) -> tuple[str, str]:
    try:
        branch = subprocess.run(
            ["git", "-C", str(project_dir), "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=GIT_TIMEOUT,
        ).stdout.strip()
        porcelain = subprocess.run(
            ["git", "-C", str(project_dir), "status", "--porcelain"],
            capture_output=True, text=True, timeout=GIT_TIMEOUT,
        ).stdout
        return branch, porcelain
    except Exception:
        return "", ""


def _write_unfinished_breadcrumb(
    project_dir: Path, branch: str, porcelain: str, pending: list[str]
) -> None:
    """Write/refresh the auto-breadcrumb section of plans/UNFINISHED.md.

    Only ever manages the region between BREADCRUMB_START/END; any human-authored
    content outside that region is preserved. Fail-soft: any error is swallowed.
    """
    try:
        files = "\n".join(f"- `{ln[3:]}`" for ln in porcelain.splitlines() if ln.strip())
        steps = "\n".join(f"- {p}" for p in pending) if pending else "- (none computed)"
        section = (
            f"{BREADCRUMB_START}\n"
            f"## Unfinished work (auto-written by workflow_hook)\n\n"
            f"_Last session ended with a dirty tree — resume here. This section is "
            f"machine-managed; edit outside the markers freely._\n\n"
            f"- **When:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n"
            f"- **Branch:** `{branch or '(unknown)'}`\n\n"
            f"**Changed files:**\n{files or '- (none)'}\n\n"
            f"**Pending closure steps:**\n{steps}\n"
            f"{BREADCRUMB_END}"
        )
        path = project_dir / UNFINISHED_PATH
        existing = ""
        try:
            existing = path.read_text(encoding="utf-8")
        except OSError:
            existing = ""
        if BREADCRUMB_START in existing and BREADCRUMB_END in existing:
            pre = existing.split(BREADCRUMB_START, 1)[0]
            post = existing.split(BREADCRUMB_END, 1)[1]
            new_text = pre + section + post
        elif existing.strip():
            new_text = existing.rstrip() + "\n\n" + section + "\n"
        else:
            new_text = section + "\n"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(new_text, encoding="utf-8")
    except Exception:
        pass


def handle_stop(data: dict, session_id: str) -> int:
    project_dir = _project_dir(data)
    state = _load_state(session_id)

    branch, porcelain = _git_branch_and_porcelain(project_dir)
    tree_dirty = bool(porcelain.strip())
    dirty_non_main = tree_dirty and branch not in ("main", "")
    retrospective_due = (
        state.get("source_changed")
        and not state.get("retrospective_touched")
        and not state.get("retrospective_reminder_emitted")
    )

    # Outstanding closure steps — computed independently of the block budget so
    # the breadcrumb always reflects what's still pending.
    reasons: list[str] = []
    if dirty_non_main:
        reasons.append(
            f"Working tree is dirty on non-main branch `{branch}`. Per CLAUDE.md's git "
            "workflow, commit and push to this feature branch once verification passes "
            "(this is pre-approved — no need to ask)."
        )
    if retrospective_due:
        reasons.append(
            "Source under packages/*/lib/ changed this session but no entry was added "
            "to docs/claude-code-agentic/RETROSPECTIVE.md. Per the "
            "wse-orchestration Gate 9, add a dated retrospective entry if there's "
            "anything worth recording, then stop. If there's nothing worth noting, you "
            "may stop without one."
        )

    # Durable breadcrumb whenever the tree is dirty — on ANY branch, so a session
    # that dies mid-closure leaves a "resume here" trace. Never blocks the turn.
    if tree_dirty:
        _write_unfinished_breadcrumb(project_dir, branch, porcelain, reasons)

    if not reasons:
        return 0  # nothing to remind about — let the turn end

    blocks = int(state.get("stop_blocks", 0))
    stop_hook_active = bool(data.get("stop_hook_active", False))
    if blocks >= MAX_STOP_BLOCKS or stop_hook_active:
        return 0  # budget exhausted — never trap the turn

    if retrospective_due:
        state["retrospective_reminder_emitted"] = True
    state["stop_blocks"] = blocks + 1
    _save_state(session_id, state)
    return _emit_stop_block("\n\n".join(reasons))


# --- misc ------------------------------------------------------------------
_HANDLERS = {
    "SessionStart": handle_session_start,
    "PostToolUse": handle_post_tool_use,
    "Stop": handle_stop,
}


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    if not isinstance(data, dict):
        return 0
    event = data.get("hook_event_name") or data.get("hookEventName") or ""
    session_id = str(data.get("session_id") or "default")
    handler = _HANDLERS.get(event)
    if handler is None:
        return 0
    try:
        _apply_config(_project_dir(data))  # override path constants, per-key, fail-soft
        return handler(data, session_id)
    except Exception:  # fail soft — a hook must never break a tool call/turn
        return 0


if __name__ == "__main__":
    sys.exit(main())
