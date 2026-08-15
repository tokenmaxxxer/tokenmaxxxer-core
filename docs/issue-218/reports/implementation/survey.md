# Survey: issue-218 scope-gate read-only vouch fix

Scout skip: pure bugfix (scout-directive skip condition 1). The defect and
fix direction are fully specified by the issue (regex/logic corrections to
an existing function); no product-facing or design decision is open.

## Write set

- `warrant/hooks/scope-gate.sh` — `readonly_allowed()`, `SHELL_CHAIN`,
  `SAFE_ARG`, `READONLY_ALLOW` in the embedded Python heredoc.
- `core/hooks/tests/run-scope-gate-tests.sh` — regression cases.

## Current state

`readonly_allowed(command)` (scope-gate.sh):
- `SHELL_CHAIN = re.compile(r"[;&|`]|\$\(")` — rejects on any `|`, `;`,
  `&`, backtick, or `$(`. This blanket-rejects single-pipe read-only
  pipelines like `grep -rn x tests/ | head`.
- `SAFE_ARG = r"(?:\s+[^\s;&|`$]+)*"` — the char class excludes
  whitespace, `;`, `&`, `|`, backtick, `$`, but NOT `>` or `<`, so
  `cat a > b` matches `READONLY_ALLOW`'s `cat` pattern. `\s` also matches
  `\n`, so a newline-embedded second command can ride inside one "safe
  arg" span.
- `READONLY_ALLOW` is a list of 4 compiled regexes matched via
  `pattern.match(stripped)` against the whole command string (no
  segment-splitting).
- `find` is in the plain-command allowlist
  (`^(ls|cat|pwd|echo|which|head|tail|wc|find|grep|file)...`) with no
  exclusion for `find`'s exec-capable flags (`-exec`, `-execdir`, `-ok`,
  `-okdir`, `-delete`, `-fprint`, `-fprintf`, `-fls`).

`readonly_allowed` is called from two sites: the malformed-frontmatter
branch (`call_is_readonly()`) and the approved-unit branch's Bash handler
(`if not readonly_allowed(command): allow()` — i.e., only a readonly
match gets a printed `permissionDecision: allow`).

## Consult trace

Issue references `docs/reports/consult-log.md` 2026-08-16 secure-coding
for the find-exec point; no such file exists in this repo (checked
project-wide). Treating the issue's own acceptance criteria and fix
direction as authoritative in its absence — the four fix bullets and
acceptance list are fully mechanical and require no further judgment
call.

## Alternative considered

Full shell tokenization/AST parsing (e.g. via `shlex` + a real grammar)
instead of pipe-splitting regexes. Rejected: `readonly_allowed` already
commits to a regex-allowlist strategy (not a parser) for A6; introducing
a parser here would be a much larger, differently-scoped rewrite than
this bug warrants, and the issue's fix direction is explicitly regex-shaped
(reject on literal chars, split on `|`).
