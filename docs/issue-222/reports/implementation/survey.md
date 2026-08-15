# Survey: board-gate R4 maintenance-targets exception (issue-222)

## Write set surveyed
- `core/hooks/board-gate.sh` — R4 block, `core/hooks/board-gate.sh:594-616`.
  `issue_hits` loop denies unless `branch == "<issue_dir>/<role>"`. No
  concept of a second, declared-target branch exists today.
- `core/hooks/tests/run-board-gate-tests.sh` — subprocess-driven gate
  tests (`run`/`runb` helpers), R1-R5 already covered; no `CORE_GH` seam
  wired here yet (unlike `run-approval-gate-tests.sh`).
- `docs/handbooks/board-gate-tests.md` — companion handbook documenting
  R1-R5's test matrix; needs an R4-exception subsection.

## Prior art in this repo for the same shape of problem
`core/hooks/approval-gate.sh:233-262` already reads a live GitHub fact
(issue state) via `gh issue view <n> --json ...`, with:
- `CORE_GH` env override as the test seam (`core/hooks/tests/run-approval-gate-tests.sh:31-63`
  stubs a `gh` script keyed by mode).
- fail-closed on `OSError`/non-zero `returncode`/unparseable JSON — never
  silently allow when GitHub is unreachable.
- `gh` called with `cwd=root`, not the tool's own cwd.

This is the exact pattern issue-222 needs for `maintenance-targets:`: a
live `gh issue view <n> --json body` read, not a local file, so the
value cannot be forged by writing something into the repo tree.

## The trust argument, already enforced elsewhere
`core/hooks/gh-guard.sh:66-70` already denies `gh issue edit` (and
`create/close/reopen/transfer/delete`) unconditionally for any session
carrying `CLAUDE_ROLE` — "issues are the user's requirement backlog,
user-authored only (contract v3 s9) — no role touches them." A role
session therefore has no tool-level path to mutate an issue body it did
not author. Reading that body live via `gh issue view` (never a locally
cached/committed copy) inherits this guarantee directly: whatever
`maintenance-targets:` a role's own issue N carries was written by the
user/orchestrator, and gh-guard.sh's existing rule is what keeps a role
session from later editing it to add trees mid-session. No new
enforcement code is needed for this half of the acceptance criterion —
it composes with an existing gate.

## Format precedent
No existing "declaration block in an issue body" parser exists in this
repo. The closest precedent is the `APPROVE issue-<n>/<role>` exact-string
match in `approval-gate.sh:277-295` — chosen there specifically to avoid
prose-interpretation ambiguity. The issue body itself (#222) uses the
literal line shape:
```
maintenance-targets: docs/issue-711/, docs/issue-476/, docs/issue-1461/
```
i.e. a single `key: comma-separated-list` line, matching
`docs/issue-<n>/` tokens (trailing slash optional, `docs/` prefix
optional per the issue's own alternate phrasing
`maintenance-targets: docs/issue-Y/`).

## Skip condition assessed
Not a pure bugfix (new gate behavior) and the format of the declaration
line is a real design choice — scouting/skip-record does not apply here;
the design decision (line format, `gh` reuse) is stated in the proposal's
Rationale instead.

## Unknowns the proposal must resolve
1. Exact regex/parse shape for the `maintenance-targets:` line (comma vs
   whitespace separated, `docs/` prefix optional or required, trailing
   slash optional).
2. Where the `gh issue view` call sits relative to the existing R4 loop
   (lazy, only invoked when a mismatch is first hit, to avoid a network
   call on every ordinary same-issue write).
3. Test coverage shape: reuse `runb`'s branch/role matrix vs. a new
   `CORE_GH`-stubbed helper mirroring `run-approval-gate-tests.sh`'s
   `stub_gh`.
