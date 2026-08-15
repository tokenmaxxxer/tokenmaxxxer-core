---
status: proposed
files:
  - core/hooks/board-gate.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - docs/handbooks/board-gate-tests.md
---

## Request
board-gate.sh's R4 refuses any `docs/issue-Y/` write unless the current
branch is exactly `issue-Y/<role>`, so a record-maintenance issue (its
own branch `issue-X/<role>`) can never fix a defect that lives in some
other, already-closed issue's tree. Add a narrow, operator-controlled
exception: when issue X's own body carries a literal
`maintenance-targets: <tree list>` line, its branch may also write
exactly those listed `docs/issue-<n>/` trees. No declaration => today's
behavior, byte-identical.

## Constraints
- The declaration must be read live from GitHub (`gh issue view`), never
  from a locally writable file — a role session must not be able to
  self-expand its own write set by writing something into the repo tree.
- Reuse the `gh`-call shape `approval-gate.sh` already uses (`CORE_GH`
  test seam, fail-closed on any `gh` failure) rather than inventing a
  second convention.
- Only the R4 block changes; R1/R2/R3/R5 in `board-gate.sh` are
  untouched.
- No network call on the common path: an ordinary same-issue write must
  not trigger a `gh` call at all — only a cross-issue write does.

## Rationale
Considered caching the resolved issue body's `maintenance-targets:` list
in a repo file (e.g. `docs/issue-X/.maintenance-targets`) written once at
session start, then read locally by the gate on every call — this would
avoid a `gh` round-trip on every cross-issue write. Rejected: a file
under `docs/` is exactly the surface a role session's own tools (Write/
Edit) can touch, so caching the declaration there reintroduces the
self-expansion hole the issue explicitly calls out ("role sessions must
not be able to self-expand the set") — the whole point of reading it via
`gh issue view` is that `gh-guard.sh` already denies role sessions
`gh issue edit`, so the live value is provably outside the role's own
write reach. A local cache breaks that guarantee for a one-time
network-call saving, so it stays a live `gh` read, mirroring
`approval-gate.sh`'s existing issue-state check.

## What will be done
In `core/hooks/board-gate.sh`'s R4 block (`board-gate.sh:594-616`):
- Parse the current branch as `issue-<n>/<role>` once (already computed
  as `branch`); call this the "own issue number" only when the trailing
  role segment matches `CLAUDE_ROLE`.
- Keep the existing per-`issue_hits` loop's same-issue check
  (`branch == "<issue_dir>/<role>"`) as the first, free check — unchanged
  for the common case.
- On a mismatch only, lazily fetch and cache (per gate invocation, not
  across invocations) `gh issue view <own-issue-num> --json body` (via
  the `CORE_GH` env override, same as `approval-gate.sh`), and search the
  body with `re.search(r"^maintenance-targets:\s*(.+)$", body, re.MULTILINE)`.
  Split the captured list on `,`/whitespace, strip each token, and accept
  a token matching `^(?:docs/)?(issue-[0-9]+)/?$` (both
  `docs/issue-711/` and `issue-711` spellings, matching the issue body's
  own two phrasings). Build a set of `issue-<n>` strings.
- A mismatched `issue_dir` is allowed only when it is in that set; deny
  with a message naming both the branch mismatch and the (absent or
  non-matching) declaration otherwise.
- `gh` unreachable, non-zero exit, or unparseable JSON on that lazy
  fetch: treat the declaration set as empty (fail closed — the mismatch
  still denies, same as no declaration existed) rather than raising past
  the trap.
- Add a `docs/handbooks/board-gate-tests.md` subsection documenting the
  R4 exception's shape and its no-declaration-byte-identical guarantee.

## Out of scope
- `gh-guard.sh` (already denies `gh issue edit` for role sessions; no
  change needed — cited as the trust argument, not touched).
- `approval-gate.sh` and R1/R2/R3/R5 of `board-gate.sh`.
- Actually landing on-the-record#1624's citation fixes (a different
  repo/session; this issue is the gate mechanism only).
- Any UI/tooling for authoring the `maintenance-targets:` line itself —
  it is plain issue-body text the user/orchestrator writes by hand.

## How you'll know it worked
- `core/hooks/tests/run-board-gate-tests.sh` (extended with a
  `CORE_GH`-stubbed case group, mirroring `run-approval-gate-tests.sh`'s
  `stub_gh`) asserts:
  - branch `issue-X/<role>` writing `docs/issue-Y/...` denies with no
    declaration (today's behavior, unchanged).
  - the same write allows when issue X's stubbed body carries
    `maintenance-targets: docs/issue-Y/`.
  - a `docs/issue-Z/...` write (Z not listed) still denies under the
    same declaration.
  - own-issue writes (`docs/issue-X/...`) never invoke the stub `gh` at
    all (own-issue path stays free of the network call).
- `bash core/hooks/tests/run-board-gate-tests.sh` and
  `bash core/hooks/tests/run-all.sh` run green.
