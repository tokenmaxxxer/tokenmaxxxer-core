# Survey — issue-167

Scope: fix 3 confirmed defects from #163. Spec (issue body) already names the
exact file/line and required behavior for each; this is corrective work with
no open product-shape decision — SKIP CONDITION: pure bugfix (scout-directive
skip condition 1) — no scout sweep run.

## A4 (Critical) — warrant/hooks/scope-gate.sh:207-239
Bash branch: computes `withheld(command)` against a fixed regex list
(`rm -rf`, `sudo`, redirection, etc.) and, if nothing matches, prints
`permissionDecision: allow` unconditionally — including for a Bash command
that never referenced the frozen `files:` write set at all. Two independent
holes: (1) the withhold regexes only see literal substrings, so
`F=-rf; rm $F` never matches `rm\s+-[a-z]*[rR]`; (2) even a command that
matches nothing in the withhold list (e.g. `curl ... -o /tmp/leak.txt`) gets
auto-approved — Bash is never checked against the write set, unlike
Write/Edit/NotebookEdit below it in the same file.
Repro: `tests/test_silent_failure_repros.py::test_A4_...` (lines 110-142).

## A2 (High) — warrant/hooks/hunt-guard.sh:87
`if agent_type != "warrant-hunter": allow()` — compares the unqualified
name. This session's actual agent registry (confirmed in this session's own
system reminder) dispatches the hunter as `warrant:warrant-hunter`
(plugin-namespaced). That qualified string never equals `"warrant-hunter"`,
so the single-flight lock and `WARRANT_HUNT_MAX` cap silently never engage
for a real dispatch.
Repro: `tests/test_silent_failure_repros.py::test_A2_...` (lines 84-107).

## A5 (High) — core/hooks/trailer-gate.sh:86
`commit_m = re.search(r'\bgit\b[^\n;&|]*\bcommit\b(?!-)', command)` matches
against the raw command *source text*. `git commi""t -m x` is, to the shell,
identical to `git commit -m x` (adjacent quoted empty strings concatenate),
but the raw source text has no contiguous `commit` substring, so the regex
misses it and the gate calls `allow()` — skipping the §13 trailer check
entirely for a commit that stages `docs/issue-<n>/**` work.
Repro: `tests/test_silent_failure_repros.py::test_A5_...` (lines 145-170).
Note: trailer-gate.sh already has a precedent for resolving shell constructs
by effect rather than raw text — see the `-m`/`--message` resolver
(`_extract_resolvable_expr`, added for issue-141) a few lines below the
match site. The fix for A5 follows the same resolve-before-match discipline
already established in this file, applied to the git verb itself instead of
just the message payload.

## Write set (confirmed against repro tests + gate suites)
- `warrant/hooks/scope-gate.sh` — Bash branch fix
- `warrant/hooks/hunt-guard.sh` — qualified-name match fix
- `core/hooks/trailer-gate.sh` — quote-normalize before verb match
- `tests/test_silent_failure_repros.py` — flip A2/A4/A5 assertions to
  fixed-behavior
- No new dependency, no new env var, no schema/migration change.

## Regression surfaces
- `core/hooks/tests/run-gate-lib-tests.sh`
- `core/hooks/tests/run-role-gates-tests.sh`
- `warrant/hooks/tests/*` if present (checked at build time)
