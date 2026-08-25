---
issue: 320
role: execution-observation
author: execution-observation
loop_state: landed
upstream:
  - path: fix/issue-2286-board-gate-r5-author-identity-v2 (PR #319)
    sha: 500fbce11d3b53dcec9c45e69b46e7d50eecb6df
subject: PR #319 — board-gate.sh R5 keys foreign-record ownership off a record's own `author:` frontmatter field instead of the filename/role match
test: core/hooks/test_board_gate.py (issue's named check); cross-checked with a standalone probe harness that invokes board-gate.sh directly, independent of the PR's own pasted output
result: passed
assertedBy: execution-observation (independent re-execution against PR #319's head commit 500fbce, plus hand-built live probes for all four R5 behaviors and a real pre-`author:` legacy record from this repo's own history)
---

# issue-320 — execution-observation record

## What was done

Independently verified PR #319 (`fix/issue-2286-board-gate-r5-author-identity-v2`,
head `500fbce11d3b53dcec9c45e69b46e7d50eecb6df`) against this repo, per issue
#320's four Acceptance checks. Nothing below is inferred from the diff or
taken on the PR's own word — each item was executed live in this repo
against PR #319's actual head commit.

**1. Named test suite, executed against PR #319's head.**

```
$ git fetch origin pull/319/head:pr-319-head
$ git checkout pr-319-head
$ python3 -m pytest core/hooks/test_board_gate.py -q
/home/jwjung/.local/lib/python3.10/site-packages/pytest_asyncio/plugin.py:208: PytestDeprecationWarning: The configuration option "asyncio_default_fixture_loop_scope" is unset.
The event loop scope for asynchronous fixtures will default to the fixture caching scope. Future versions of pytest-asyncio will default the loop scope for asynchronous fixtures to function scope. Set the default fixture loop scope explicitly in order to avoid unexpected behavior in the future. Valid fixture loop scopes are: "function", "class", "module", "package", "session"

  warnings.warn(PytestDeprecationWarning(_DEFAULT_FIXTURE_LOOP_SCOPE_UNSET))
.............                                                            [100%]
13 passed in 0.96s
```

13 passed — matches the issue's expected "13 passed: 8 pre-existing + 5
new" and PR #319's own claim. (The `main` branch, pre-PR, has no
`author:`-keyed R5 logic and no `EXTRA_SUBTREE` fix at all — confirmed by
reading `git diff main pr-319-head -- core/hooks/board-gate.sh`, 114
insertions.)

**2. All four R5 behaviors, demonstrated live, not inferred from the diff.**

Built a standalone probe (`/tmp/board_gate_r5_probe.py`, kept out of this
repo's `docs/` tree so it does not itself trip R1) that invokes
`core/hooks/board-gate.sh` exactly the way Claude Code's PreToolUse hook
does — a JSON payload on stdin, `CLAUDE_ROLE`/`CLAUDE_PLUGIN_ROOT`/
`CLAUDE_PROJECT_DIR` in the environment — against four fresh git-repo
fixtures (own `board-gate.sh`'s subprocess invocation contract, read from
`core/hooks/test_board_gate.py`'s `run_gate` helper, but a fresh harness
and fresh fixtures — not a re-run of the PR's own test file). Run inside
this repo, checked out at PR #319's head (`pr-319-head`):

```
$ python3 /tmp/board_gate_r5_probe.py

========================================================================
A) own-author write allowed (role=implementation writes a record it authored, under a filename that is NOT its own <role>.md)
========================================================================
fixture: /tmp/tmpp49hkw9_/docs/issue-198/reports/verify.md
---
author: implementation
---
body

command: echo overwritten > docs/issue-198/reports/verify.md
returncode: 0
stderr:
RESULT: ALLOWED as expected

========================================================================
B) foreign-author TRUNCATING write denied (role=implementation, record author=architecture, plain > redirect)
========================================================================
fixture: /tmp/tmppn_xrzzl/docs/issue-198/reports/verify.md
---
author: architecture
---
body

command: echo hi > docs/issue-198/reports/verify.md
returncode: 2
stderr: board-gate: docs/issue-198/reports/verify.md is authored by 'architecture', not 'implementation'. A session may append new content to a foreign-authored record but never alter another author's existing lines. (contract v3 s11, issue-2241 stage 3)

RESULT: DENIED as expected

========================================================================
C) foreign-author APPEND allowed (role=implementation, record author=architecture, provable >> append via heredoc)
========================================================================
fixture: /tmp/tmp8u5jph83/docs/issue-198/reports/verify.md
---
author: architecture
---
body

command: cat <<'EOF' >> docs/issue-198/reports/verify.md
more
EOF
returncode: 0
stderr:
RESULT: ALLOWED as expected

========================================================================
D) author:-less legacy record falls back to the original role-filename rule (role=implementation, no author: field, filename belongs to a different role)
========================================================================
fixture: /tmp/tmpy63726k7/docs/issue-198/reports/verify.md
no frontmatter here

command: echo hi >> docs/issue-198/reports/verify.md
returncode: 2
stderr: board-gate: docs/issue-198/reports/verify.md belongs to another role. implementation writes only implementation.md, implementation/** — never a foreign record. (contract v3 s11)

RESULT: DENIED as expected (legacy record still governed by filename rule, not suddenly unwritable in a new way -- it was already denied under the pre-existing rule)

========================================================================
ALL FOUR R5 BEHAVIORS CONFIRMED LIVE
========================================================================
```

All four assertions (`rc==0`/`rc==2` plus the exact denial-message
substrings) are asserted inside the probe script itself — the script
raises `AssertionError` on any mismatch, so a clean run is a positive
confirmation, not just an absence of a crash.

**3. `EXTRA_SUBTREE`'s corrected keys, verified against `board.py`'s
equivalent check, cited by file:line.**

`tokenmaxxxer-core` has no `board.py` of its own — read both sides across
repos, as the issue's Acceptance requires ("verified by reading both").

- `core/hooks/board-gate.sh:93` (PR #319 head):
  `EXTRA_SUBTREE = {"technical-feasibility": "spikes", "release-engineering": "postmortems"}`
- `on-the-record`'s `board.py` (checked out locally at
  `/home/jwjung/.tokenmaxxxer/work/on-the-record-issue-2333-execution-observation/board.py`,
  a sibling role session's working tree for the `on-the-record` repo —
  read-only, not modified), `board.py:768-770`:

  ```python
  768:        if role == "technical-feasibility" and rest.startswith("spikes/"):
  769:            continue
  770:        if role == "release-engineering" and rest.startswith("postmortems/"):
  ```

Same two role-name strings (`technical-feasibility` → `spikes`,
`release-engineering` → `postmortems`), same mapping direction. Confirmed
match, not inferred.

**4. No legacy record becomes unwritable — demonstrated with a real
pre-`author:` record from this repo's history.**

Every one of this repo's 289 existing `docs/issue-*/reports/*.md` files
predates the `author:` frontmatter field (checked by scanning all of them
for an `author:` line in their frontmatter block — zero matches). Used a
real one, `docs/issue-100/reports/implementation.md` (frontmatter uses
`produced_by:`, not `author:` — genuinely pre-dates issue-2241 stage 1),
and compared `board-gate.sh`'s verdict on the *same* write attempt against
that *same* real file's content, before and after PR #319:

```
$ python3 /tmp/board_gate_r5_legacy_probe.py
Real legacy record used: docs/issue-100/reports/implementation.md
--- first 4 lines ---
---
kind: coding-record
subject: issue-100
produced_by: implementation
has 'author:' field: False

command (role=implementation, own real record, append): echo more >> docs/issue-100/reports/implementation.md

[main / pre-#319 board-gate.sh]  rc=0  stderr=''
[pr-319-head board-gate.sh]      rc=0  stderr=''

RESULT: identical outcome before and after PR #319 for this real pre-author: legacy record -- the change adds no new restriction to it.
```

The probe ran `core/hooks/board-gate.sh` as checked out at `main` and, in
a second fixture, as checked out at PR #319's head, against a fixture
carrying this real file's exact bytes — same command, same result (`rc=0`,
empty stderr) both times. This matches the code path directly: PR #319's
new logic only activates `if author is not None:`; `_record_author`
returns `None` whenever no `author:` line is found in the frontmatter, so
every one of this repo's 289 pre-existing records falls straight through,
unchanged, to the original role-filename rule below it.

## Why

The issue requires evidence executed live in this repo against PR #319's
actual head, not evidence inferred from the diff or copied from the PR's
own pasted output or from the corroborating (but non-substituting)
`on-the-record` records cited in the issue body. Each of the four
Acceptance checks names a distinct kind of evidence (a test run, four
live behavior transcripts, a cross-repo file:line citation, a real legacy
record), so this record produces all four independently rather than
summarizing PR #319's description of them. The probe scripts were built
fresh from reading `board-gate.sh`'s own invocation contract (JSON
payload, `CLAUDE_ROLE`/`CLAUDE_PLUGIN_ROOT`/`CLAUDE_PROJECT_DIR`) rather
than copy-run from `test_board_gate.py`, so a defect that happened to be
masked by that file's own fixtures would not automatically survive here
too.

## Upstream basis

- `fix/issue-2286-board-gate-r5-author-identity-v2` (PR #319), commit
  `500fbce11d3b53dcec9c45e69b46e7d50eecb6df` — fetched locally as
  `pr-319-head` via `git fetch origin pull/319/head:pr-319-head`.
- `core/hooks/board-gate.sh` and `core/hooks/test_board_gate.py` at that
  commit (the two files PR #319 touches).
- `docs/issue-100/reports/implementation.md` at this repo's current
  `main` (unmodified by PR #319; used read-only as a real legacy-record
  fixture).
- `on-the-record`'s `board.py`, read read-only from a sibling role
  session's already-checked-out working tree at
  `/home/jwjung/.tokenmaxxxer/work/on-the-record-issue-2333-execution-observation`
  (not modified; cited by file:line only).

## Open findings

None. All four Acceptance checks confirmed; PR #319 correctly delivers
issue-2241 stage 3's core half.

## Next steps

None — loop_state: landed.
