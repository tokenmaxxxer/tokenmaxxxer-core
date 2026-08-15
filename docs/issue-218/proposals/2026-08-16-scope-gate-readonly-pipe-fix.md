---
status: approved
files:
  - warrant/hooks/scope-gate.sh
  - core/hooks/tests/run-scope-gate-tests.sh
---

## Request

Fix `readonly_allowed()` in warrant's scope-gate.sh: (1) allow single-pipe
read-only pipelines (`grep ... | head`) instead of blanket-rejecting any
`|`; (2) reject shell-chaining/redirection/newline-smuggling
(`;`, `&`, backtick, `$(`, `||`, `>`, `<`, embedded newline); (3) drop
`<`/`>` from `SAFE_ARG`'s argument char class; (4) never vouch `find`
invocations carrying exec-capable flags (`-exec`, `-execdir`, `-ok`,
`-okdir`, `-delete`, `-fprint`, `-fprintf`, `-fls`).

## Constraints

- Pure bugfix: scout skipped (see survey.md).
- `docs/reports/consult-log.md` cited by the issue does not exist in this
  repo; the issue's own fix direction and acceptance list are treated as
  authoritative.
- Must not weaken the existing `WITHHELD` redirection-refusal path or
  other gate behavior — only `readonly_allowed()` and its supporting
  regexes change.

## Rationale

Considered a full shell-grammar parser (`shlex`/AST) instead of extending
the regex-allowlist approach. Rejected: `readonly_allowed` already commits
to the regex-allowlist strategy for its whole design (A6's decision); a
parser rewrite is a much larger, differently-scoped change than this
defect calls for, and the issue's stated fix direction is itself
regex-shaped (reject specific chars, split on `|`, per-segment match).

## What will be done

- Change `SHELL_CHAIN` to reject `;`, `&`, backtick, `$(`, `||`, `>`, `<`,
  and `\n` — but no longer treat a single `|` as disqualifying on its own.
- In `readonly_allowed`, split `command` on `|`, and return True only when
  every non-empty segment (stripped) independently matches
  `READONLY_ALLOW` (rejecting first via the narrowed `SHELL_CHAIN`, which
  now applies to the whole command including `||`/newlines before
  splitting).
- Narrow `SAFE_ARG`'s char class to exclude `<` and `>` in addition to the
  existing excluded chars.
- Add a `find`-specific guard: when a segment's command is `find`, refuse
  the vouch if any of its arguments is one of the exec-capable flags
  (`-exec`, `-execdir`, `-ok`, `-okdir`, `-delete`, `-fprint`, `-fprintf`,
  `-fls`) — as a substring/word check on the segment.
- Add regression cases to `run-scope-gate-tests.sh`'s malformed-frontmatter
  and approved-unit branches per the issue's Acceptance: `grep -rn x
  tests/ | head` => allow, `grep x | sh` => deny, `cat a > b` => deny,
  `git log | tail -5` => allow, newline-smuggled command => deny,
  `find . -exec rm {} \;`-shaped command => deny, and an approved-unit
  piped-all-read-only case => allow.

## Out of scope

- Rewriting `readonly_allowed` as a real shell parser.
- Changes to `WITHHELD`, the write-set matching, or any other gate logic.
- The missing `docs/reports/consult-log.md` file itself.

## How you'll know it worked

`bash core/hooks/tests/run-scope-gate-tests.sh` and
`bash core/hooks/tests/run-all.sh` (if present) both pass, including the
new cases enumerated above.
