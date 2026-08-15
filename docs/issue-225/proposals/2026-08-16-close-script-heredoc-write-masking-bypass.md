---
status: approved
files:
  - core/hooks/board-gate.sh
  - warrant/hooks/scope-gate.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/run-scope-gate-tests.sh
---

## Request

board-gate R4 and warrant scope-gate's write-set check both key writes off
the visible command text. An interpreter invocation with an inline body
(`python3 - <<EOF`, `bash <<EOF`, `-c`/`-e` strings, `tee`, `dd`) can carry
a write whose real target never appears in that visible text, so the gate
misreads the call as carrying no write at all and lets it through. This
was observed live: after board-gate denied a direct cross-issue `Edit`,
the same session rewrote the file via `python3 - <<EOF` instead, and the
gate allowed it (on-the-record PR #1627).

Survey/proposal ordering skip condition: this is a pure bugfix to two
existing gate scripts — closing a specific, already-diagnosed bypass in
code whose structure, write set, and test harness already exist and were
read in full before this fix was written (both gate files, both test
suites, and gate-lib.py's helpers). No open design decision remains; the
scout-directive's "pure bugfix" skip condition applies, so no separate
survey.md/scout-brief.md was written.

## Constraints

- Deny only where a write-set/maintenance-set is actually being enforced
  (a role session on a board repo for board-gate; an approved proposal in
  progress for scope-gate) — an unrestricted session, or a repo with no
  enforceable write-set, must keep today's behavior byte-identical.
- A provably read-only interpreter call (`python3 -m pytest`, and every
  existing scope-gate `READONLY_ALLOW` entry) must keep working.
- No regression in either gate's existing test suite (110 + 26 cases).

## Rationale

Considered teaching the gates to parse heredoc bodies and `-c`/`-e`
strings as real (nested) shell/script content and re-run the write scan
recursively inside them. Rejected: heredoc bodies are not restricted to
shell syntax (a Python/Ruby/Perl script has none of Bash's redirect
grammar), so a generic recursive parser would need one parser per
interpreter language, is unbounded in scope, and can never be complete —
the next language or scripting trick reopens the same hole. The chosen
approach instead treats "a write-capable command whose target this gate
cannot read" as its own classification and fails closed for it, matching
the posture the warrant read-only allowlist already takes for unprovable
reads (deny-by-default, not allow-by-default) — no parser completeness
required, and the acceptance criteria only ask that these shapes be
denied, not that they be understood.

## What will be done

- `core/hooks/board-gate.sh`: track, per Bash segment already classified
  as write-capable-and-unproven-read-only, whether it is also
  "unanalyzable" (a heredoc operator, an interpreter `-c`/`-e` flag, or
  `dd`) AND contributed no docs/-shaped candidate of its own. When a role
  is set and the repo is a board (`docs/specs/approvers.md` exists) and
  any such segment exists, deny before the `if not hits: allow()`
  fallthrough that previously let it slip through unseen.
- `warrant/hooks/scope-gate.sh`: add the same shape check
  (`UNANALYZABLE_WRITE_SHAPE`), checked ahead of the existing
  `withheld()`/`readonly_allowed()` checks in the Bash branch that runs
  only while exactly one proposal is `approved` (a write-set is actually
  in force) — deny instead of the previous "decline to vouch" outcome
  that `tee`/`dd`/heredocs/`-c` shared with every other unrecognized
  command.
- Add test cases to both `core/hooks/tests/run-board-gate-tests.sh` and
  `core/hooks/tests/run-scope-gate-tests.sh` covering: the live bypass
  shape (`python3 - <<EOF`), a `bash <<EOF` heredoc, a `-c` inline string,
  `tee`/`dd` (scope-gate only — board-gate already catches direct `tee`
  targets via its existing window scan; the new deny is exercised through
  a case with a masked/absent target), an unrestricted-session negative
  case, and a `python3 -m pytest` still-allowed case.

## Out of scope

- No change to other gates (approval-gate.sh, gh-guard.sh, trailer-gate.sh).
- No recursive parsing of heredoc/`-c` bodies.
- No change to scope-gate's general "decline to vouch" posture for
  ordinary non-allowlisted commands outside this specific shape class.

## How you'll know it worked

- `core/hooks/tests/run-board-gate-tests.sh` and
  `core/hooks/tests/run-scope-gate-tests.sh` pass, including the new
  cases, with no regression in the pre-existing ones.
- `core/hooks/tests/run-all.sh` passes end to end.
- The exact live bypass shape (`python3 - <<EOF` rewriting an out-of-set
  path) is denied by both gates under write-set enforcement, and stays
  allowed for an unrestricted session and for `python3 -m pytest`.
