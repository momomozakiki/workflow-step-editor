---
name: wse-input-hardening
description: >-
  Use as the security lens whenever code touches data that came from outside the process — step
  config maps, raw bytes/text from a file, serialized workflow documents, or anything a user typed.
  Trigger whenever a request mentions untrusted or external input, hardening, sanitizing, input
  validation, injection, ReDoS / catastrophic-backtracking regex, secrets/tokens/credentials in
  code, DoS or resource exhaustion, buffer/size limits, "is this input safe to parse", or reviewing
  the attack surface of a parser — even if the word "security" never appears. Defer the class/design
  contract to dart-solid-principles; this skill is about not trusting what comes in. Use it before
  adding a cast, a regex, a new inbound field, or a file/network read.
---

# Input hardening — trust nothing that came from outside

The editor loads and edits data that originates outside the process: config a user typed, serialized
workflow documents, files opened from disk. The core has **zero runtime dependencies** and must
parse hostile input without crashing, hanging, or leaking. That safety isn't automatic — it's a set
of habits this skill names so they don't erode one cast or one regex at a time.

The boundary is simple: **the moment a value crosses into the process from a file, a config map, or a
socket, it is untrusted** until validated. `dart-solid-principles` owns *how* a class is shaped; this
skill owns the orthogonal question — *did we assume this input was well-formed when we had no right
to?*

## Rule 1 — Validate before you parse; never bare-cast config

Untrusted config is a `Map<String, dynamic>`. Every field is a landmine: missing, wrong type, out of
range. The contract: a `validateConfig(config) → List<String>` (empty = valid) called *before* any
parsing, which throws `ConfigError(message, errors)` when non-empty — so a bad document fails loudly
with *all* its problems listed, instead of a `TypeError` deep in a loop.

Check types with `is!` and only then read the value — never `config['x'] as String` on a raw map,
because a bare cast turns attacker-controlled config into an uncaught runtime exception:

```dart
if (config['label'] != null && config['label'] is! String) {
  errors.add('label must be a String');
}
```

**Smell:** a bare `as` on a value pulled straight from a config/JSON map; parsing that begins before
validation has run; a validate step that *throws* instead of returning the list.

## Rule 2 — Every regex over external input gets a length cap and a time budget

A regex applied to attacker-controlled text is a ReDoS waiting to happen: a crafted input makes a
pattern backtrack for seconds and pins the isolate. Defend in two layers whenever you run a regex
over user text or a user-supplied pattern:

1. **Pre-flight length cap** — reject patterns/inputs longer than a `regexMaxLength` before compiling.
2. **Runtime time budget** — wrap the match in a `Stopwatch` against a `regexTimeoutMs`; if it blows
   the budget, **fall back safely** (e.g. treat the input as one token) and record a `StepWarning`.

**Smell:** `RegExp(userPattern)` or `pattern.allMatches(userText)` with no length guard and no
timeout — a single malicious line can hang the parser.

## Rule 3 — Recoverable input problems are warnings, not crashes

Degraded/hostile input — a short/truncated document, an out-of-range index, a reference to a missing
key — is **expected**, not a programming error. Surface it as a `StepWarning` and set `isPartial =
true` on the `StepResult`; return what you safely parsed. Reserve thrown `StepError`s for genuinely
fatal conditions (bad config, unusable input). This keeps a malformed file from taking down the
editor, and keeps the failure *observable* instead of swallowed.

**Smell:** an out-of-bounds list access that can throw `RangeError`; a `catch` that swallows a
malformed-input case and returns empty with no warning.

## Rule 4 — Any I/O boundary is minimal and bounded

The widest attack surface is anything that reads from disk or the network. Whenever such a boundary
is added:

1. **Bound the size** — cap how much is read before decoding, so a giant payload can't exhaust memory.
2. **Fail closed** — on a malformed/oversized input, reject and surface an error status; never act on
   half-parsed data.
3. **If a socket is ever added** — bind `127.0.0.1`/`loopbackIPv4` only (never `0.0.0.0`), put it
   behind a mandatory auth token compared **constant-time**, and cap inbound frame size *before*
   decoding.

**Smell:** reading an unbounded file/frame into memory; a future `HttpServer.bind('0.0.0.0', …)`; a
`==` token compare.

## Rule 5 — No secrets in code; keep them out of diagnostics too

Tokens, credentials, and secrets come from **runtime config**, never hard-coded literals in the repo
(they leak through git history forever). And when something is logged or surfaced as a warning,
**redact secrets and PII** — a diagnostic that echoes the token or raw payload just moves the leak.

**Smell:** a string literal that looks like a key/token/password in `lib/`; a warning that
interpolates the full raw payload or a secret.

## PR litmus test

- ✅ Did validation run (returning a list, throwing `ConfigError` only after) before any parse, with
  `is!` checks instead of bare `as` on untrusted config?
- ✅ Does every regex over external input have both a length cap **and** a timeout with a safe
  fallback + warning?
- ✅ Do degraded/hostile inputs become `StepWarning` + `isPartial`, never an unhandled throw or a
  silent empty result?
- ✅ Is any new file/socket read size-bounded and fail-closed (sockets loopback + token + constant-time
  compare)?
- ✅ Are there no secret literals in source, and do warnings/logs redact secrets and PII?

## References

- `packages/workflow_step_editor_core/lib/core/step_error.dart` / `core/step_result.dart` — fatal
  `StepError` vs recoverable `StepWarning` + `isPartial`.
- Related skills: [[dart-solid-principles]] (class contract), [[wse-package-boundaries]] (keep
  `dart:io` out of the core).

> Paths are intentionally concrete; if they move, update this skill.
