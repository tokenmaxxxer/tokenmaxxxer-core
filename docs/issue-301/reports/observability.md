---
issue: 301
role: observability
loop_state: delivered
upstream:
  - path: core/hooks/, warrant/hooks/, freelunch/hooks/, scout/hooks/, terse/hooks/ (repo root, as of this commit)
    sha: 3ae409b42a73d68cc2fd6615f64a640feb01d688
signal_type: n/a
attribute_name: n/a
attribute_type: n/a
verdict: pass
---

# issue-301 — observability record

## What was done

Silent-failure sweep of tokenmaxxxer-core (program: on-the-record#2295), per
the audit lens: for every mechanism, *when this fails, what does it say,
where, and to whom — and can that be swallowed?*

**Scope**: every executable hook/gate/directive script in this repo — 31
files across `core/hooks/` (21 files: 7 top-level gates + 14
dispatcher/proposal/record/survey/trailer/lib files), `warrant/hooks/` (6),
`freelunch/hooks/` (2), `scout/hooks/` (1), `terse/hooks/` (1). Test-suite
files (`*/hooks/tests/**`) were read for calling convention but not audited
as mechanisms themselves — they are not consumer-facing.

**Method**: 3 independent audit passes (dispatched as background workers,
one per file group), each required to actually invoke every candidate
failure point with degenerate/malformed/missing input and paste real
stdout/stderr/exit-code — grep-level suspicion alone was rejected as a
finding basis, per the issue's acceptance criterion. Already-fixed landed
exemplars named in the issue (#2293, #2229, #2240, #2291, #2262, #2231,
#2217, #2216, #2219, #2268) were excluded from re-audit.

**Result: 23 confirmed findings, 31/31 files swept (0 unaudited), 8 files
entirely clean.**

By failure class:

| class | count |
|---|---|
| silent-acceptance | 11 |
| wrong-signal | 4 |
| silent-loss | 3 |
| rejection-without-passing-shape | 3 |
| caller-dependent-visibility | 2 |

By severity:

| severity | count |
|---|---|
| misleads-human | 13 |
| strands-work | 6 |
| burns-tokens | 4 |

Two cross-cutting patterns emerged across independently-audited files (noted
here so a batched fix can address the pattern once rather than file-by-file):

- **Kill-switch fail-open-on-typo** (F19, F20 — 4 files): `gate-lib.sh`'s
  `gate_kill_switch_active` was already fixed to treat only an exact
  `1/true/yes/on` as "disable, everything else active" — but
  `role-directive.sh` and three sibling `*-directive.sh` UserPromptSubmit
  hooks still use an inline case statement with the old bug (any
  unrecognized value disables), including in files whose own header comment
  describes the bug being avoided. The fix already exists in the codebase;
  it just wasn't propagated.
- **Bash-level substring fast-path defeated by JSON `\uXXXX` escaping**
  (F15, F17 — 2 of 7 gates with a fast path): `gh-guard.sh` and
  `approval-gate.sh` both gate on a raw-text `case "$payload" in *gh*|...)`
  before parsing JSON; escaping one character of the matched substring
  (`gh` for `gh`, `/` for `/`) produces byte-identical parsed
  JSON but silently skips the entire gate. `board-gate.sh` and
  `ordering-gate.sh` were checked and are not vulnerable (no fast-path, or a
  match substring with no escapable characters).
- **Missing `python3` on PATH is handled inconsistently**: `citation-gate.sh`,
  `handbook-trigger-gate.sh`, `facet-keyword-gate.sh` (bash-level check) all
  print a specific "python3 not found" message before failing closed;
  `gh-guard.sh`, `approval-gate.sh`, `board-gate.sh`,
  `pretooluse-dispatcher.sh` fail closed with a bare exit code and zero
  bytes on either stream (F16, F18, F22).

### Findings

#### F1 — wrong-signal / misleads-human — `warrant/hooks/hunt-tier.sh:38`
`git diff --numstat "$base" "$head" -- 2>/dev/null` swallows a real git
failure (bad/typo'd ref, exit 128) and reports `reason=empty-diff`,
byte-identical to a genuinely empty diff.
```
$ bash warrant/hooks/hunt-tier.sh totally-bogus-ref-xyz HEAD
tier=none cap_seconds=0 max_stances=0 reason=empty-diff
exit=0
# the swallowed git error, captured separately:
fatal: 애매한 인자 'totally-bogus-ref-xyz': 알 수 없는 리비전 또는 작업 폴더에 없는 경로.
git own exit=128
```
A broken base ref silently cancels the before/after-landing hunter dispatch
instead of surfacing as a problem.

#### F2 — silent-acceptance / burns-tokens — `warrant/hooks/hunt-guard.sh:99-102`
With the session hunter cap already reached (3/3), a well-formed dispatch is
correctly refused (exit 2). The identical dispatch with truncated/malformed
JSON is silently allowed (exit 0, zero output, count file untouched).
```
$ echo "3" > .git/warrant/.warrant-hunt.count
$ echo '{"tool_name":"Agent","tool_input":{"subagent_type":"warrant:warrant-hunter","prompt":"probe"}}' | bash warrant/hooks/hunt-guard.sh
warrant: 3 hunters already dispatched in this repository (cap 3). No more until the count file is cleared: rm .../.git/warrant/.warrant-hunt.count
exit=2
$ printf '{"tool_name":"Agent","tool_input":{"subagent_type":"warrant:warrant-hunter","prompt":"probe"' | bash warrant/hooks/hunt-guard.sh
exit=0
```
The session-cap guard is bypassed by any harness hiccup that garbles the
hook payload.

#### F3 — silent-acceptance / burns-tokens — `warrant/hooks/hunt-guard.sh:170-174`
A corrupted `.warrant-hunt.count` (non-integer content) is silently read as
`used=0` and overwritten, resetting the session cap to full budget with no
warning — in direct contrast to the lock-file corruption path a few lines
above (`hunt-guard.sh:66-70`), which loudly refuses on the identical kind of
corruption.
```
$ echo "garbage-not-a-number" > .git/warrant/.warrant-hunt.count
$ echo '{"tool_name":"Agent","tool_input":{"subagent_type":"warrant:warrant-hunter","prompt":"probe"}}' | bash warrant/hooks/hunt-guard.sh
exit=0
$ cat .git/warrant/.warrant-hunt.count
1
```

#### F4 — silent-acceptance / misleads-human — `warrant/hooks/scope-gate.sh:25`
With an approved proposal freezing the write set, a Write to a file outside
it is correctly refused when `python3` is on PATH, and silently allowed
(exit 0, zero output on either stream) when `python3` is merely missing.
```
# python3 present:
warrant: refused — `src/evil_out_of_scope.py` is outside the write set frozen by docs/proposals/2026-08-25-test.md.
Approved paths: src/allowed.py
exit=2
# python3 absent from PATH, identical payload:
exit=0  (nothing printed)
```
The entire scope-enforcement mechanism goes dark with no signal.

#### F5 — silent-loss / misleads-human — `warrant/hooks/state.sh:63-65`
A proposal with broken frontmatter (missing closing `---` fence) is silently
skipped by the SessionStart report loop — never listed open, closed, or
flagged malformed.
```
$ bash warrant/hooks/state.sh
warrant: open work units in this repository —
  APPROVED, in progress: docs/proposals/2026-08-25-test.md — 0 commit(s) so far, branch master. ...
exit=0
```
(`docs/proposals/2026-08-25-broken.md` never appears anywhere in the
output.) This file's own stated purpose — "pick up an interrupted unit
without being told" — fails silently for exactly the proposal a human is
most likely to need surfaced (mid-edit, broken frontmatter);
`scope-gate.sh` reading the identical file reports it loudly by contrast.

#### F6 — silent-acceptance / burns-tokens — `freelunch/hooks/observe.sh:43-46`
With `FREELUNCH_ENFORCE=1`, a well-formed synchronous-dispatch violation is
correctly denied; the identical violation with truncated JSON produces
neither a deny decision nor a log line.
```
# well-formed:
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "freelunch: synchronous Agent dispatch (run_in_background: false) is blocked ..."}}
exit=0
# malformed:
exit=0   (no deny JSON, log file empty/missing)
```
The audit-trail JSONL — whose own comment warns "an empty observation log
otherwise reads as 'no dispatches happened'" — gains no row either; the
bypass leaves no trace at all.

#### F7 — wrong-signal / misleads-human — `terse/hooks/terse.sh:22-26,33-34`
An unrecognized *value* in `terse.level` gets an explicit
`NOTE: ... tell the user` appended to the emitted directive text; an
outright I/O failure reading the same file (permission denied) produces
only a bare shell error on stderr, outside the directive text, and the
directive itself is indistinguishable from a successfully-read "full"
setting.
```
$ chmod 000 .../terse.level; bash terse/hooks/terse.sh
terse/hooks/terse.sh: 줄 25: .../terse.level: 허가 거부
[terse-directive] ... LEVEL full: ... Read .../terse-style.md for the full rules.
exit=0
```

#### F8 — silent-loss / misleads-human — `core/hooks/facet-keyword-gate.sh:74-79`
A malformed or missing `FACET_KEYWORD_CONFIG` produces zero diagnostic on
either stream and disables the gate entirely, even for a payload that would
otherwise deny.
```
$ FACET_KEYWORD_CONFIG=/tmp/bad-config.json CLAUDE_ROLE=sales bash core/hooks/facet-keyword-gate.sh <<< '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/reports/sales.md","content":"# playbook\nsome text"}}'
exit:0   (0 bytes stdout, 0 bytes stderr)
```
`except (OSError, ValueError): sys.exit(0)` at line 78-79 gives no trace —
a config file broken by a bad merge/edit silently disables the gate for
every role.

#### F9 — wrong-signal / strands-work — `core/hooks/facet-keyword-gate.sh:26`
Missing `python3` hard-blocks (`gate_deny`, real exit 2, no
`hookSpecificOutput`) despite this gate's demoted/advisory design elsewhere
in the same file.
```
$ PATH=/tmp/nopython/bin CLAUDE_ROLE=sales bash core/hooks/facet-keyword-gate.sh <<< '...'
exit:2
STDERR: facet-keyword-gate: refused — python3 not found; cannot evaluate gate
```
A side-by-side run of `handbook-trigger-gate.sh` under the identical
missing-python3 condition confirms its sibling *did* get its bash-level
deny demoted (exit 0) — this file's environment-failure path was missed by
the issue-282 demotion pass.

#### F10 — silent-acceptance / strands-work — `core/hooks/handbook-trigger-gate.sh:139-149`
`git add -A`/`--all`/`-u` are dropped unconditionally from the projected
staged-set (the pathspec loop skips every bare `-`-prefixed token), so the
whole `git add` segment contributes nothing to the projection.
```
$ echo '{"tool_name":"Bash","tool_input":{"command":"git add -A && git commit -m \"add package.json\""}}' | CLAUDE_ROLE=implementation bash core/hooks/handbook-trigger-gate.sh
exit:0   (0 bytes stdout, 0 bytes stderr)
```
Confirmed via a follow-up `git add -A; git diff --cached --name-only` that
the real command would have staged an operational-surface file
(`package.json`). No "cannot resolve statically" deny fires even though the
code's own comment (lines 108-109) promises one for exactly this case —
`git add -A && git commit ...` is a complete, silent bypass of the §21
handbook-trigger obligation.

#### F11 — silent-acceptance / strands-work — `core/hooks/ordering-gate.sh:70-97`
A non-dict `tool_input` or non-string `file_path` (e.g. `file_path: 301` or
`tool_input` as a JSON array) makes every mechanism return `None`, falling
through to unconditional `sys.exit(0)` — a completely silent allow with no
trace the gate ever saw the call.
```
$ printf '{"tool_name":"Write","tool_input":{"file_path":301,"content":"x"}}' | ordering-gate.sh
exit:0   (0 bytes stdout, 0 bytes stderr)
```
The same target path with a well-typed string `file_path` correctly denies
(exit 2) in the identical fixture — a malformed-type payload defeats the
gate's own documented fail-closed posture for malformed input.

#### F12 — silent-loss / misleads-human — `core/hooks/ordering-gate.sh:298-305`
`update_status`'s `try/except Exception: data = {}` resets the *entire*
`.status.json` document to empty on any read/parse failure, silently
erasing every other tracked issue's stage history.
```
# seeded .status.json tracking issue-777 (done) and issue-301 (pending), then corrupted it
$ ordering-gate.sh   # fresh interaction-design write for issue-301
exit:0
# .status.json after: {"issue-301": {...}} — issue-777's entry is gone entirely
```

#### F13 — caller-dependent-visibility / misleads-human — `core/hooks/ordering-gate.sh:334-337`
The status-file write-back permission-error warning only fires on the
invisible allow path (`sys.exit(0)`); per this hook's own documented
contract, stderr on an allow is not surfaced to the model/human the way a
deny (exit 2) is.
```
$ chmod 444 .status.json && ordering-gate.sh   # fresh write that should update status
exit:0
STDERR: id-stage-order: warning: could not update status file: PermissionError(13, 'Permission denied')
```
Correct diagnostic text, wrong channel for how this hook is actually
consumed — write-once-read-never in normal operation.

#### F14 — silent-acceptance / strands-work — `core/hooks/citation-gate.sh:674-677`
`gate_trap_fail_closed` exists to remap any non-0/2 exit to 2, but this
file's own tail (`trap - EXIT; exit "$PY_EXIT"`) disarms that trap *before*
re-exiting with the raw Python exit code.
```
$ CITATION_CONFIG=/tmp/cit_config_badregex.json CLAUDE_ROLE=architecture bash core/hooks/citation-gate.sh < payload.json
exit:1
STDERR: ...re.error: unterminated character set at position 30 (raw traceback)
```
A config-authoring bug (bad regex in `citation-config.json`) surfaces as
exit 1, which Claude Code treats as non-blocking per `gate-lib.sh`'s own
doc comment — the entire citation gate silently disables for that row, only
a buried stderr traceback and no `hookSpecificOutput` on stdout.
`gh-guard.sh` does the equivalent rc-check manually and is not affected.

#### F15 — silent-acceptance / strands-work — `core/hooks/gh-guard.sh:42-45`
The bash-level fast path matches the *raw, unparsed* JSON text; escaping one
letter of `gh` as `gh` parses to the byte-identical command string but
defeats the substring match entirely.
```
# baseline, literal "gh":
exit:2 — gh-guard: refused for role session 'implementation': merging or closing a PR is the human's acceptance/refusal...
# {"tool_name": "Bash", "tool_input": {"command": "gh pr merge 42 --squash"}}
exit:0   (0 bytes stdout, 0 bytes stderr)
```
A role session can merge/close a PR, post a forged APPROVE comment, or push
to main — all otherwise human-only acts — completely undetected and
unlogged, by re-encoding one character of its own command string.

#### F16 — caller-dependent-visibility / misleads-human — `core/hooks/gh-guard.sh:47`
Missing `python3` blocks every tool call with zero explanation on either
stream.
```
$ PATH=/tmp/no-python-path CLAUDE_ROLE=implementation bash core/hooks/gh-guard.sh < payload.json
exit:2   (0 bytes stdout, 0 bytes stderr)
```
`citation-gate.sh`'s equivalent check is correctly informative by contrast
(same PATH-starvation test: exit 2, "citation-gate: refused — python3 not
found; cannot evaluate gate"). The calling model cannot distinguish "a real
policy violation" from "this environment is missing python3" and will
plausibly retry or abandon a legitimate command chasing the wrong cause.

#### F17 — silent-acceptance / misleads-human — `core/hooks/approval-gate.sh:87-92`
Same bug family as F15: the bash fast path
(`case "$payload" in *src/*|*test/*|*issue-*) ;; *) exit 0 ;; esac`) matches
raw JSON text; a `file_path` JSON-escaped as `src/bad_file.py` decodes
to an ordinary `src/...` path but never contains the literal substring
`src/`.
```
# literal "src/bad_file.py":
exit:2 — approval-gate: execution-surface writes happen only on this role's own issue branch...
# {"tool_name": "Write", "tool_input": {"file_path": "src/bad_file.py", ...}}
exit:0   (0 bytes stdout, 0 bytes stderr)
```
Reproduced a second way via the Bash `tool_input.command` path with the
same result. The entire two-phase-approval/branch/approver check is
skipped; an execution-surface write from the wrong branch with zero
approval is silently allowed. `board-gate.sh` was checked against the same
attack (its fast path keys on the literal substring `docs`, which contains
no escapable `/`) and confirmed **not** vulnerable.

#### F18 — rejection-without-passing-shape / burns-tokens — `core/hooks/approval-gate.sh:92`, `core/hooks/board-gate.sh:62`
Missing `python3` bypasses every other diagnostic path in both files —
including each file's own `fail-closed: internal error (gate judge exited
$rc)` message for every *other* failure mode.
```
$ PATH=/tmp/nopy3bin CLAUDE_ROLE=implementation bash core/hooks/approval-gate.sh <<< '{"tool_name":"Write","tool_input":{"file_path":"src/bad_file.py","content":"x"}}'
exit:2   (0 bytes stderr)
$ PATH=/tmp/nopy3bin CLAUDE_ROLE=observability bash core/hooks/board-gate.sh < payload.json
exit:2   (0 bytes stderr)
```
A human or role session sees only a bare exit code 2, no clue python3 is
the missing dependency — blind retries instead of a fixable message.

#### F19 — silent-acceptance / misleads-human — `core/hooks/lib/role-directive.sh:36`
The kill-switch case statement treats any unrecognized value as "disable",
not only the documented `1/true/yes/no/off/""` set.
```
$ CLAUDE_ROLE=test TEST_CYCLE_OFF=asdf bash -c ". core/hooks/lib/role-directive.sh; core_role_directive A B C D"
(no output at all)
rc=0
```
(Contrast: unset `TEST_CYCLE_OFF` prints the full `[test] Role directive...`
block.) A mistyped env var silently deletes the entire per-role behavioral
directive for the session — the exact fail-open kill-switch bug
`gate-lib.sh`'s own `gate_kill_switch_active` (lines 48-73) documents
having already fixed elsewhere ("a stray typo in an env var silently
disabled the gate... every other value stays active") — but
`role-directive.sh` was never migrated to use it.

#### F20 — silent-acceptance / misleads-human — `core/hooks/proposal-shape-directive.sh:16-19`, `core/hooks/record-shape-directive.sh:19-22`, `core/hooks/survey-order-directive.sh:16-19`
Same bug as F19, independently reimplemented in three more
UserPromptSubmit hooks.
```
$ PROPOSAL_SHAPE_OFF=typo-garbage bash core/hooks/proposal-shape-directive.sh   # rc=0, no output
$ RECORD_SHAPE_OFF=typo-garbage  bash core/hooks/record-shape-directive.sh      # rc=0, no output
$ SURVEY_ORDER_OFF=typo-garbage  bash core/hooks/survey-order-directive.sh      # rc=0, no output
# contrast, no OFF var set:
[proposal-shape-directive] phase-1 proposals carry files:, Request, Constraints, Rationale... rc=0
```
Each file's own header comment describes the bug being avoided ("the kill
switch silently killed it on exactly the spelling meant to keep it alive")
— the code below the comment still has it. A single typo'd
`PROPOSAL_SHAPE_OFF`/`RECORD_SHAPE_OFF`/`SURVEY_ORDER_OFF` value silently
removes phase-1/phase-2 shape steering from every prompt with no error
anywhere.

#### F21 — rejection-without-passing-shape / misleads-human — `core/hooks/pretooluse_dispatcher.py:521-528`
When two DEMOTE gates both deny the same tool call, only the first gate's
structured `hookSpecificOutput` reaches stdout — the channel the code's own
comment says the platform actually consumes.
```
# a write missing both required proposal shape AND its survey file:
STDOUT: {"hookSpecificOutput": {... "additionalContext": "proposal-shape: ... missing or misshapen required element(s): files: (missing); ## Request (missing); ..."}}
STDERR: proposal-shape: ...
        survey-order: docs/issue-999/proposals/test.md is a phase-1 proposal write for issue-999, but its survey file .../survey.md does not exist on disk, ...
        {"hookSpecificOutput": {... "additionalContext": "survey-order: ..."}}
exit=0
```
The second gate's entire finding, including its raw JSON blob, is shoved
into stderr — a consumer reading only the documented stdout channel sees
just the proposal-shape problem, fixes it, and only then discovers the
survey-order problem on the next turn.

#### F22 — rejection-without-passing-shape / strands-work — `core/hooks/pretooluse-dispatcher.sh:13`
Missing `python3` denies with a bare exit code and zero bytes on either
stream, unlike every one of the 14 owned gate scripts dispatched through
it, each of which prints a specific "requires python3" message.
```
$ env -i PATH=/nonexistent bash core/hooks/pretooluse-dispatcher.sh < payload.json
exit=2   (no stdout, no stderr)
```
The dispatcher is registered under the union `.*` matcher — in an
environment missing python3 this shim silently blocks *every* tool call in
the session with no diagnostic, forcing guess-and-retry to discover the
cause.

#### F23 — wrong-signal / misleads-human — `core/hooks/pretooluse_dispatcher.py:496-505`
`OTR_DISPATCH_ONLY`, the exact-match single-gate test harness used by
`core/hooks/tests/run-dispatcher-equivalence-tests.sh`, falls through to a
bare `return 0` when the requested gate name doesn't match any entry —
"gate not found" and "gate ran and found nothing wrong" are byte-identical.
```
$ OTR_DISPATCH_ONLY="record-fields-gate.sh" python3 core/hooks/pretooluse_dispatcher.py < payload2.json   # correct name, real defect in payload
implementation: sha: HEAD is not `same-commit` or a 40-character hex commit sha (issue-128/133)...
exit=0
$ OTR_DISPATCH_ONLY="record-felds-gate.sh" python3 core/hooks/pretooluse_dispatcher.py < payload2.json   # typo'd name (missing "i")
exit=0   (no output at all)
```
A typo in a test's `OTR_DISPATCH_ONLY` value silently turns that test
vacuous instead of failing loudly.

### Clean / swept

Confirmed by execution, not by inspection alone — one representative
command per file, contrasted against a passing baseline where relevant:

- **`board-gate.sh`** — `/`-escaped-slash attack replayed against it
  (same class as F17): correctly denied (fast path keys on literal `docs`,
  no `/` involved, not vulnerable). Empty stdin: denies with a message.
- **`ordering-gate.sh`** (remaining paths) — no bash-level substring fast
  path exists at all (confirmed by reading the full preamble); JSON
  `\/`-escaping is a non-issue since path matching operates on
  already-`json.loads`'d strings; empty/malformed/non-object stdin all
  fail-closed with a clear stderr reason (exit 2); kill-switch matches
  `gate-lib.sh`'s fixed narrow-disable convention exactly; top-level
  `except Exception` genuinely fail-closes stray internal errors; bash
  exit-code laundering + `gate_trap_fail_closed` EXIT trap correctly remap
  non-0/2 exits to 2.
- **`citation-gate.sh`** (remaining paths) — real advisory-trigger payload
  against the real config: `deny()` correctly demoted (exit 0, message on
  both stdout `hookSpecificOutput` and stderr). Empty/malformed stdin:
  correctly denies with an accurate message. Nonexistent `CITATION_CONFIG`:
  silent exit 0 — but this is explicitly documented as intentional
  empty-state behavior in the file's own header comment, not a new defect.
- **`gh-guard.sh`** (remaining paths) — truncated/invalid JSON that passes
  the fast path: denies with "unreadable PreToolUse payload; refusing
  rather than guessing". `CLAUDE_ROLE` unset: passes through untouched, as
  documented. Empty stdin with `CLAUDE_ROLE` set: denies with an explicit
  message.
- **`approval-gate.sh`** (remaining paths) — empty stdin: denies with a
  message. Malformed JSON that still matches the fast path: denies with
  "unreadable PreToolUse payload; refusing rather than guessing". `gh`
  binary unreachable: the branch-mismatch deny fires first with its normal
  message (the surrounding `deny()` machinery is intact).
- **`facet-keyword-gate.sh`** (remaining paths) — malformed JSON under a
  role with a config row: `deny()` emits well-formed JSON on stdout,
  mirrors it on stderr, exit 0. A real facet-governed Bash write: the
  reconstruction-failure deny fires correctly.
- **`handbook-trigger-gate.sh`** (remaining paths) — a genuine violation
  (staged `Dockerfile`, no `docs/handbooks/` touch): `deny()` fires
  correctly (well-formed stdout+stderr, exit 0). The internal-error
  fail-closed wrapper (`except Exception`, real exit 2) is a deliberate,
  distinct design from the advisory `deny()`; every ordinary error input
  tested (non-JSON payload, non-dict `tool_input`, non-string `command`,
  unresolvable `git add $(...)`, unparsable `git add` args) routes through
  the demoted `deny()`, not the internal-error path.
- **`warrant/hooks/directive.sh`** — `WARRANT_OFF=1`: correct silent exit 0
  (documented kill-switch). `CLAUDE_PLUGIN_ROOT_CORE` pointed at a
  nonexistent core: prints `cannot source gate-lib.sh`, exits 2
  (fail-closed).
- **`warrant/hooks/hunt-state.sh`** — `release`/`reset` with no
  `.git/warrant` statedir: benign no-op, exit 0. Unrecognized subcommand:
  falls through, exit 0 — but this script is only ever invoked by
  `hooks.json` with the literal fixed args `release`/`reset`, so the
  unknown-subcommand path is unreachable by any real caller.
- **`scout/hooks/directive.sh`** — same gate-lib-unreachable test as
  `warrant/hooks/directive.sh`: correctly prints the error and exits 2.
- **`freelunch/hooks/freelunch.sh`** — `FREELUNCH_OFF=maybe`: correctly
  warns on stderr ("treating as not-off, directive will print") and still
  emits the directive — fail-open to the directive, not to silence,
  exactly as its own comment claims.
- **`core/hooks/directive.sh`** — no-remote repo: prints the full
  `PRECONDITIONS NOT MET` block. Remote+auth present but
  `session-protocol.md` missing: prints an explicit fallback message. Both
  loud and actionable.
- **`core/hooks/pretooluse-dispatcher.sh`** (remaining path) — python3
  present: forwards stdin correctly (verified end-to-end).
- **`core/hooks/pretooluse_dispatcher.py`** (remaining paths) — per-gate
  setup `try/except`, KEEP-vs-DEMOTE exit-code mapping for the documented
  `deny`-verdict path, JSON-parse fallback to `{}` all matched their own
  documentation under live test payloads.
- **`core/hooks/proposal-shape-directive.sh`, `record-shape-directive.sh`,
  `survey-order-directive.sh`** (remaining path) — informational body with
  no OFF var set: prints correctly.
- **`core/hooks/proposal-shape-gate.sh`** — malformed JSON on stdin: denies
  with a clear stderr message and matching stdout `hookSpecificOutput`
  (advisory demote, exit 0). Missing-shape case also exercised end-to-end
  via the dispatcher (F21).
- **`core/hooks/record-fields-gate.sh`** — `CLAUDE_ROLE` unset: denies with
  "no CLAUDE_ROLE in the environment", exit 0, no silent pass.
- **`core/hooks/record-shape-gate.sh`** — an `implementation.md` write with
  zero frontmatter and no scout-skip text: correctly denies (exit 2)
  listing every missing field.
- **`core/hooks/survey-order-gate.sh`** — empty stdin: denies cleanly
  ("empty tool-use payload on stdin"), exit 0. Also exercised via the
  dispatcher multi-gate test (F21).
- **`core/hooks/trailer-gate.sh`** — a real staged commit via
  `git commit -F <file>` (message-via-file, unverifiable trailer): denies
  correctly with a specific message naming the issue and required
  `Subject:` trailer, exit 0 (advisory demote as documented).
- **`core/hooks/lib/gate-lib.py`** — `gate_reconstruct_write`,
  `_apply_replace`, `gate_normalize_path` all traced through every caller
  observed in this audit; an unreconstructable write always resolves to
  `ok=False`, and every caller denies rather than treating that as a no-op.
- **`core/hooks/lib/gate-lib.sh`** — `gate_kill_switch_active` run directly
  with a garbage value: correctly stays ACTIVE. This is the fixed
  reference implementation the four files in F19/F20 should be using but
  aren't — not itself a defect.

## Why

Operator directive (2026-08-25, program on-the-record#2295): sweep every
hook/gate/directive point in this repo for failures that don't properly
communicate what's wrong, against the five-class lens validated by this
drive's ~20 landed defects. This session covers only tokenmaxxxer-core, as
scoped by the issue's "one audit session for this repo" instruction; the
other two repos in the program are separate sessions. `CORE_BUILD_NOW=1`
was set by the spawner, authorizing direct delivery without a phase-1
proposal round (contract v3 s19a) — the issue's acceptance gate is this
record itself (an inventory, not a code fix), so there is no separate
code-write surface requiring the warrant proposal gate beyond this docs
tree.

## Upstream basis

- Issue #301 (this repo), program on-the-record#2295.
- Repo state audited: commit `3ae409b42a73d68cc2fd6615f64a640feb01d688`
  (HEAD of `issue-301/observability` at audit time).
- Pattern book (excluded from re-audit, per issue's Non-goals): #2293,
  #2229, #2240, #2291, #2262, #2231, #2217, #2216, #2219, #2268.

## Open findings

All 23 findings above are open — this issue's scope is the inventory only
("The inventory then becomes fix issues, batched by mechanism"), not the
fix. Resolution path: batch into fix issues by mechanism family, per the
issue's own Scope & method section:
1. Kill-switch fail-open-on-typo (F19, F20) — one fix, migrate all four
   files to `gate-lib.sh`'s `gate_kill_switch_active`.
2. JSON `\uXXXX`-escape defeats bash fast-path (F15, F17) — one fix pattern
   (parse JSON before the substring check, or drop the fast path), applied
   to `gh-guard.sh` and `approval-gate.sh`.
3. Missing-python3 silent/inconsistent failure (F9, F16, F18, F22) — one
   shared `gate-lib.sh` helper for the "python3 missing" deny message,
   applied to the four inconsistent call sites.
4. The remaining 14 findings (F1-F8, F10-F14, F21, F23) are each
   single-mechanism and independent; no further batching implied.

One scope note, not a finding: F17/F18's `approval-gate.sh`/`board-gate.sh`
are the two files this audit was asked to cover and are documented in-repo
as "the source of truth"; `pretooluse_dispatcher.py`'s Python
reimplementation of the same two gates' contracts (registered as the actual
production `PreToolUse` hook per `hooks.json`) was out of scope for this
pass and was not independently checked for the same two defect classes.

## What did not work

- The first `approval-gate.sh`/`board-gate.sh` audit worker completed its
  own direct testing (2 findings) but deferred final write-up to itself
  after its own further-delegated sub-agents finished, then exited without
  ever producing that write-up — its two findings were lost until a second,
  narrower worker re-ran the same two files from scratch (folded into F17,
  F18 above; no separate file was left unaudited).
- `citation-gate.sh` with a nonexistent `CITATION_CONFIG` was initially
  flagged as a candidate silent-failure by the auditing worker, then ruled
  out on closer reading: the file's own header comment documents this as
  intentional empty-state behavior, not a defect. Recorded above under
  Clean / swept rather than as a finding.

## Next steps

None for this record (loop_state: delivered — the inventory is the
deliverable). Follow-up fix issues, batched per the Open findings section
above, are for the operator/a future session to file; this session does
not file issues per the role-handoff contract.

## Skill verdicts

skill-verdict: silent-failure-audit — applied: invoked; loaded via Skill
tool after the audit's execution phase (should have been loaded before —
noted as a process gap, not repeated). Its trace-forward method (catch
site → return value → caller behavior → downstream consequence) and
evidence bar (file:line pair, forward trace ending at a stated
consequence) match what this record already does per finding; its H/S/U
classification was not substituted for the issue's own five-class lens
(silent-acceptance/silent-loss/wrong-signal/rejection-without-passing-shape/caller-dependent-visibility),
since the issue's lens is the one "validated against this drive's ~20
landed defects" and is the more specific instrument for this task. No
finding in this record changed as a result of loading the skill.
skill-verdict: observability-cardinality-budget — not-applicable: no
metric label/tag/attribute cardinality decision in this task (an
infrastructure silent-failure sweep, not metric instrumentation)
skill-verdict: observability-explorability — not-applicable: no dashboard
or incident-investigation design in this task
skill-verdict: observability-methodology-selection — not-applicable: no
RED/USE/Golden methodology choice for a touched surface in this task
skill-verdict: observability-phase-trace — not-applicable: this record is
an audit inventory, not a phase-2 signal-placement record to check against
a phase-1 methodology
skill-verdict: observability-signal-golden — not-applicable: no
service-rollup signal placement in this task
skill-verdict: observability-signal-red — not-applicable: no
single request-driven-surface signal placement in this task
skill-verdict: observability-signal-use — not-applicable: no
resource-bound-surface signal placement in this task
