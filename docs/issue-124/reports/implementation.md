---
kind: coding-record
subject: issue-124
produced_by: implementation
code_under_review: `core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`, `core/hooks/lib/gate-lib.py`
loop_state: landed
upstream:
  - path: docs/issue-124/proposals/2026-08-04-close-remaining-wrapper-parser-differential-habitats-r1-r2-r3.md
    sha: 7fcd4cdb7f3d90253960bf10d6521d749caadb6a
---

# Implementation record — issue-124

## Why

Phase 2, approved via issue-level comment `APPROVE issue-124/implementation`
(exact string), posted 2026-08-04T06:20:10Z by `jjongkwann` — a
`docs/specs/approvers.md` account (`- jjongkwann`) who also authored PR
#126, so single-account mode applies per contract v3 s19. Independently
reconfirmed in this session (`gh issue view 124 --json state,comments`):
issue state `OPEN`, one comment, `author.login: "jjongkwann"`, `body:
"APPROVE issue-124/implementation"`, `createdAt: "2026-08-04T06:20:10Z"`,
`isMinimized: false`; `gh pr view 126 --json author,reviews,state`:
`author.login: "jjongkwann"`, `reviews: []`, `state: "OPEN"`.

Delivering the approved proposal's `## What will be done` items exactly as
written: the three frozen code edits (R1/R2/R3), one red→green regression
pair plus a same-shape write-direction sibling per habitat, and the two
handbook paragraphs the proposal specifies. No redesign of any landed
primitive; the proposal's own `## Constraints` and code blocks were
followed verbatim throughout.

## What was done

### R1 — `core/hooks/approval-gate.sh:122`

Replaced the raw-`split()` early-allow head check with the shared
resolver, exactly as specified:

```
- head = cmdline.strip().split()[0].rsplit("/", 1)[-1] if cmdline.strip() else ""
+ head = gate_lib.gate_head_of(cmdline)
```

Test cases added to `core/hooks/tests/run-approval-gate-tests.sh` (after
the existing `bash-cd-then-write-src` block, before the quoted-redirect
block):

```
run allow bash-wrapper-timeout-grep-read nopr x cmd='timeout 30 grep -rn foo src/app.py'
run deny  bash-wrapper-timeout-write     nopr x cmd='timeout 30 sh -c \"echo hi > src/app.py\"'
```

**RED (pre-fix)**, captured before touching `approval-gate.sh`:

```
FAIL   bash-wrapper-timeout-grep-read     want=allow got=deny
ok     bash-wrapper-timeout-write         deny
== 43 passed, 1 failed ==
```

Exactly as the proposal predicted: `bash-wrapper-timeout-grep-read` failed
`want=allow got=deny` (raw `split()[0]` resolved `head` to `"timeout"`, not
in `READ_ONLY_HEADS`, no PR to authorize the fall-through); the write
sibling `bash-wrapper-timeout-write` already passed pre-fix — confirmed
empirically as a regression pin, not a differential.

**GREEN (post-fix)**, after applying the edit above:

```
ok     bash-wrapper-timeout-grep-read     allow
ok     bash-wrapper-timeout-write         deny
== 44 passed, 0 failed ==
```

### R2 — `core/hooks/board-gate.sh`, `_git_subcommand`

Confirmed the current text by `grep -n "GIT_READ_SUBCOMMANDS\|_git_subcommand"`
before editing (matched the proposal's approximate line numbers, 181-207).
Added `GIT_GLOBAL_VALUE_FLAGS = ("-C", "-c")` and rewrote the function's
loop to walk `gate_lib.gate_trailing_words(segment)` by index, skipping one
extra word whenever the current word is in `GIT_GLOBAL_VALUE_FLAGS` —
exactly the text given in the proposal, including the updated docstring.

Test cases added to `core/hooks/tests/run-board-gate-tests.sh` (after
`bash-wrapper-timeout-git-rm-foreign-issue`):

```
run allow bash-git-c-flag-log-foreign-issue Bash '{"command":"git -C /tmp log --oneline -- docs/issue-49"}'
run deny  bash-git-c-flag-rm-foreign-issue  Bash '{"command":"git -C /tmp rm -r docs/issue-49/reports"}'
```

**RED (pre-fix)**:

```
FAIL   bash-git-c-flag-log-foreign-issue  want=allow got=deny
ok     bash-git-c-flag-rm-foreign-issue   deny
== 90 passed, 1 failed ==
```

As predicted: `_git_subcommand`'s first-non-flag-word loop read `-C`'s
value `/tmp` as the subcommand, not in `GIT_READ_SUBCOMMANDS`, write
candidate, foreign-issue deny. The write sibling already denied pre-fix.

**GREEN (post-fix)**:

```
== 91 passed, 0 failed ==
```
(both `bash-git-c-flag-log-foreign-issue` and `bash-git-c-flag-rm-foreign-issue`
now `ok`, subcommand correctly read as `log`/`rm`.)

### R3 — `core/hooks/lib/gate-lib.py`, `_resolve_transparent`

Confirmed current text by `grep -n "TRANSPARENT_TAKES_ARG\|def _resolve_transparent"`
(matched lines 200/203). Added the `TRANSPARENT_FLAG_TAKES_ARG` table
after `TRANSPARENT_TAKES_ARG`, and inserted the one new branch (checking
`tok in TRANSPARENT_FLAG_TAKES_ARG.get(w, ())`, advancing `i` by 2) before
the existing bare-flag/`skip_extra` branches in the inner loop — exactly
the text given in the proposal.

Test cases added to `core/hooks/tests/run-gate-lib-tests.sh`'s existing
`headof` group, right after `headof bash 'nohup bash -c x' ...`:

```
headof git 'timeout -s KILL 30 git log' \
  "gate_head_of: timeout's own -s value-taking flag no longer swallows the bare DURATION slot"
headof git 'nice -n 10 git log' \
  "gate_head_of: nice's own -n value-taking flag resolves through to git"
headof git 'env -u FOO git log' \
  "gate_head_of: env's own -u value-taking flag resolves through to git"
headof git 'xargs -I fmt git log' \
  "gate_head_of: xargs's own -I value-taking flag (space-separated) resolves through to git"
```

**RED (pre-fix)**:

```
FAIL   gate_head_of: timeout's own -s value-taking flag no longer swallows the bare DURATION slot want=git got=30
FAIL   gate_head_of: nice's own -n value-taking flag resolves through to git want=git got=10
FAIL   gate_head_of: env's own -u value-taking flag resolves through to git want=git got=FOO
FAIL   gate_head_of: xargs's own -I value-taking flag (space-separated) resolves through to git want=git got=fmt
FAIL   compliance-check.sh: flags a hand-rolled kill-switch + replace shape want=deny got=allow
gate-lib: 53 passed, 5 failed
```

All four new cases failed exactly as traced (`timeout -s KILL 30 git log`
→ head resolved to `"30"`, `nice -n 10 git log` → `"10"`, `env -u FOO git
log` → `"FOO"`, `xargs -I fmt git log` → `"fmt"`). The fifth failure
(`compliance-check.sh`) is a pre-existing sandbox artifact — see `## Verify`.

**GREEN (post-fix)**:

```
ok     gate_head_of: timeout's own -s value-taking flag no longer swallows the bare DURATION slot git
ok     gate_head_of: nice's own -n value-taking flag resolves through to git git
ok     gate_head_of: env's own -u value-taking flag resolves through to git git
ok     gate_head_of: xargs's own -I value-taking flag (space-separated) resolves through to git git
gate-lib: 57 passed, 1 failed
```
(the one remaining failure is the same pre-existing `compliance-check.sh`
sandbox artifact, unrelated to any of the three source edits.)

### Handbook updates

- `docs/handbooks/approval-gate-tests.md`: appended one paragraph
  documenting R1 (cites the `split()[0]` → `gate_lib.gate_head_of(cmdline)`
  switch, issue-124, and names `bash-wrapper-timeout-grep-read` /
  `bash-wrapper-timeout-write`), in the file's existing citation voice,
  placed immediately before the existing "Test-authoring note" paragraph.
- `docs/handbooks/board-gate-tests.md`: appended two paragraphs (R2, R3)
  after the existing wrapper-prefixed-`git`-subcommand paragraph. R2 names
  the new `GIT_GLOBAL_VALUE_FLAGS` skip table and the two new test cases.
  R3 names the new `TRANSPARENT_FLAG_TAKES_ARG` table in `gate-lib.py` and
  points at the R3 `headof` cases in `run-gate-lib-tests.sh` (this file
  carries no code change of its own for R3 — the fix lives entirely in
  `gate-lib.py` — but is the fail-closed consumer, matching how this file
  already documents `gate-lib.py`-side changes, e.g. issue-94's
  `gate_outside_quotes` paragraph).
  - **Stale-sentence correction (required by the task):** the file's
    existing tail previously read (verbatim): "The pre-existing
    `git -C <dir> <subcommand>` global-flag misread (`git -C /tmp log`
    still reads `/tmp` as the subcommand) is untouched — `-C` is a
    `git`-own flag, not a `TRANSPARENT`-wrapper prefix, out of issue-114's
    scope." This became false once R2 landed. Corrected in place to say
    the gap was left open by issue-114 on purpose but "is no longer an
    open gap: it is closed by issue-124/R2, below" — not left silently as
    a stale, contradicted claim.

## What did not work

None. Every prediction in the frozen proposal's contract matched the
empirical trace exactly on the first attempt: all three RED runs failed
in precisely the shape and count the proposal/task described (R1: 1 new
failure, `want=allow got=deny`; R2: 1 new failure, same shape; R3: 4 new
failures, resolving to the misread token each time), and all three GREEN
runs passed with no unexpected side effects. No test-case shape needed
adjustment from what was specified.

## Doc-placement ladder

- [x] Handbooks touched — yes, both files:
  `docs/handbooks/approval-gate-tests.md` (R1) and
  `docs/handbooks/board-gate-tests.md` (R2 and R3, plus the stale-sentence
  correction). This satisfies `handbook-trigger-gate.sh`'s same-commit
  handbook-touch requirement for the three touched `run-*-tests.sh` files.
- [x] No `docs/issue-124/decisions/` entry needed. The proposal's own
  `## Rationale` section already carries the full alternative-and-reason
  record for all three sites (a second local head-resolver for R1, a
  generalized `_resolve_transparent`/`gate_trailing_words` for R2, routing
  R3 through `gate_wrapper_head_before` instead of a new flag table — all
  considered and rejected there) — this delivery executes that
  already-decided design, no new decision to record.
- [x] `docs/issue-124/reports/implementation.md` (this file) — the phase-2
  record, per contract v3 §11/§19.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence issue-118's record and its own cited
precedents note). Adopted two stances directly by inspection in its place.

### after-proposal (retroactive) — stance: assume the rule as drafted cannot hold — find the state nothing maintains

Verdict: NO FINDING
Seed: `docs/issue-124/proposals/2026-08-04-close-remaining-wrapper-parser-differential-habitats-r1-r2-r3.md`
`## What will be done` (the frozen code-edit text), commit `7fcd4cd`.
Started/ended: this session, immediately after applying each of the three
source edits.

Checked whether the shipped code differs from the proposal's own exact
frozen text for any of R1/R2/R3 — a byte-level comparison of the applied
`old_string`/`new_string` pairs against the proposal's `## What will be
done` prose and the task's own literal code blocks, not a paraphrase.
`core/hooks/approval-gate.sh:122`, `core/hooks/board-gate.sh:181-217`
(`GIT_READ_SUBCOMMANDS`, `GIT_GLOBAL_VALUE_FLAGS`, `_git_subcommand`), and
`core/hooks/lib/gate-lib.py:200-213,225-241`
(`TRANSPARENT_FLAG_TAKES_ARG`, the inner-loop branch) match the given text
exactly — confirmed by direct `Read`/`Edit` diffing during the session,
re-confirmed by the `grep -n` line-number checks run immediately before
each edit. Nothing in the landed code departs from the approved contract.

### before-landing — stance: assume this change and another rule cancel each other — find the pair

Verdict: NO FINDING
Seed: the post-fix `git grep` re-enumeration (`## Verify` below) against
`core/hooks/gh-guard.sh`'s deliberately-separate fail-open resolver path.
Started/ended: this session, after the Step 5 re-enumeration grep.

Checked whether R2's `GIT_GLOBAL_VALUE_FLAGS`/`_git_subcommand` change or
R3's `TRANSPARENT_FLAG_TAKES_ARG`/`_resolve_transparent` change reaches
`gh-guard.sh`'s `gate_wrapper_head_before` call — the one site the
proposal's own `## Constraints` names as explicitly staying unchanged,
because its fail-*open* direction means a resolver-walk misread there
would be a security regression, not an over-block. The re-enumeration grep
(`git grep -n "gate_head_of\|gate_trailing_words\|gate_wrapper_head_before" -- core warrant`)
shows `core/hooks/gh-guard.sh:147` still calling
`gate_lib.gate_wrapper_head_before` (unchanged), and
`gate_wrapper_head_before`'s own body (`core/hooks/lib/gate-lib.py:289-322`)
does not call `_resolve_transparent` at all — it scans `words` directly by
its own docstring's design ("deliberately not via `gate_head_of`'s
`TRANSPARENT` hop-by-hop walk"), so neither the R2 nor the R3 edit is
reachable from that call site. `run-gate-lib-tests.sh`'s existing 12
`wrapperhead` cases (unrelated to this delivery's four new `headof` cases)
all still pass unchanged in the full post-fix run, corroborating no
observable behavior change at that boundary. No finding.

### Closed checks (for verify)

closed_checks:
- name: the three source edits match the proposal's frozen text exactly, no drift
  ref: docs/issue-124/proposals/2026-08-04-close-remaining-wrapper-parser-differential-habitats-r1-r2-r3.md, core/hooks/approval-gate.sh:122, core/hooks/board-gate.sh:181-217, core/hooks/lib/gate-lib.py:200-213,225-241
- name: gh-guard.sh's fail-open gate_wrapper_head_before call site is unreachable by the R2/R3 edits
  ref: core/hooks/gh-guard.sh:147, core/hooks/lib/gate-lib.py:289-322

## Next steps

None required by this delivery's own scope. The re-enumeration (Step 5,
`## Verify`) turned up no new, unanticipated habitat — Requirement 3's
"zero remaining after these three" holds, so nothing beyond what the
proposal itself named is being folded into this delivery's write set. The
proposal's own `## Out of scope` items remain exactly as it named them and
are not re-opened here: any `TRANSPARENT` wrapper flag beyond the four
documented shapes (`nice -n`, `env -u`, `timeout -s`, `xargs -I`); any git
global flag beyond `-C`/`-c`; `gh-guard.sh`'s `gate_wrapper_head_before` and
its fail-open design; and `_cd_target`'s argument extraction (no R2-shaped
gap exists there, `cd` takes no value-consuming global flag analogous to
git's). Each stays an intentionally-scoped residual named by the proposal
itself, not a defect this record is flagging.

## Resolution path

No open finding is raised against any artifact from this delivery; both
Hunt stances above closed with no finding, and the Step 5 re-enumeration
confirms zero remaining habitats of this specific class. Nothing here
requires human action beyond the review the doc-placement ladder already
covers.

## Verify

**Per-habitat red→green** (full command output captured above in
`## What was done`; summarized):

| habitat | RED | GREEN |
|---|---|---|
| R1 | `43 passed, 1 failed` (new case `want=allow got=deny`) | `44 passed, 0 failed` |
| R2 | `90 passed, 1 failed` (new case `want=allow got=deny`) | `91 passed, 0 failed` |
| R3 | `53 passed, 5 failed` (4 new cases + 1 pre-existing) | `57 passed, 1 failed` (pre-existing only) |

**Full-suite zero-regression confirmation**, all three run after all three
fixes are applied:

```
bash core/hooks/tests/run-approval-gate-tests.sh   → 44 passed, 0 failed
bash core/hooks/tests/run-board-gate-tests.sh      → 91 passed, 0 failed
bash core/hooks/tests/run-gate-lib-tests.sh        → 57 passed, 1 failed
```

Every pre-existing case in all three harnesses is unchanged (`ok` in both
the pre-edit baseline runs done for RED capture and the final post-fix
runs); the six new cases (2 per habitat) are the only additions.

The one `run-gate-lib-tests.sh` failure —
`compliance-check.sh: flags a hand-rolled kill-switch + replace shape
want=deny got=allow` — is a pre-existing sandbox artifact, not caused by
this delivery. Confirmed two ways: (1) it is not among any of this
delivery's six new cases (all of which pass); (2) the failure is caused by
the sandbox denying `mktemp`/`mkdir` under `/`
(`mktemp: mkdtemp failed on /var/folders/…: Operation not permitted`
immediately precedes it in the output, and the test's own fixture-building
`mkdir -p "$td/..."`/file-write calls fail as a result), which
`docs/issue-118/reports/implementation.md`'s `## Verify` section already
documented as the identical pre-existing sandbox condition (`mktemp:
mkdtemp failed`, `mkdir: /docs: Operation not permitted`,
`mkdir: /hooks: Operation not permitted`) against unmodified `origin/main`,
independent of any change any coding delivery makes. None of this
delivery's three touched files (`approval-gate.sh`, `board-gate.sh`,
`gate-lib.py`) is read or exercised by `compliance-check.sh` itself, and
the mandatory-group check at the harness's own tail
(`mandatory groups exercised: kill-switch malformed-json absolute-path
replace_all-edit multiedit-replace_all bash-write-coverage dequote
wrapper-head record-fields-gate-e2e compliance-check stub-check-manifest
missing-core`) confirms no `MANDATORY GROUP MISSING` line — all seven
required groups are present.

**Re-enumeration (Step 5, issue-114's exact method), post-fix tree:**

```
$ git grep -n "gate_head_of\|gate_trailing_words\|gate_wrapper_head_before" -- core warrant
core/hooks/approval-gate.sh:122:    head = gate_lib.gate_head_of(cmdline)
core/hooks/board-gate.sh:212:    words = gate_lib.gate_trailing_words(segment)
core/hooks/board-gate.sh:237:    head = gate_lib.gate_head_of(stripped)
core/hooks/board-gate.sh:293:    for w in gate_lib.gate_trailing_words(stripped):
core/hooks/board-gate.sh:356:                if gate_lib.gate_head_of(stripped) == "cd":
core/hooks/gh-guard.sh:147:               gate_lib.gate_wrapper_head_before(cmd, span.start()):
core/hooks/lib/gate-lib.py:254:def gate_head_of(segment):
core/hooks/lib/gate-lib.py:264:def gate_trailing_words(segment):
core/hooks/lib/gate-lib.py:289:def gate_wrapper_head_before(cmdline, span_start):
(plus doc-comment / test-harness string hits, unchanged in kind from issue-114's own table)

$ git grep -n "split()" -- core/hooks warrant/hooks
core/hooks/board-gate.sh:147:    from real separators; a plain .split() would still cut at those spans.  [doc comment, not code]
core/hooks/lib/gate-lib.py:230:    words = segment.split()   [_resolve_transparent's own base split — the canonical model itself]
core/hooks/lib/gate-lib.py:324:    words = cmdline[sep_end:span_start].split()   [gate_wrapper_head_before's own non-resolver scan]
core/hooks/record-fields-gate.sh:110:    TERMINAL = set(os.environ["RF_TERMINAL"].split())   [env-var parsing, out of class]
warrant/hooks/hunt-guard.sh:98:            started = int((handle.read().split()[0] or "0"))   [file-content parsing, out of class]
(plus doc-comment hits in run-approval-gate-tests.sh:171 and run-board-gate-tests.sh:324, not code)
```

Compared against `docs/issue-114/reports/execution-observation.md`'s
`## Verdict 4` table and R1/R2/R3 prose (lines 232-304):

- **`approval-gate.sh:122`** — was `raw cmdline.strip().split()[0]`
  (issue-114's own table row, "R1, fail-closed (over-block)"). Now reads
  `gate_lib.gate_head_of(cmdline)` — resolver model, canonical. **No
  longer a raw-`split()` differential.**
- **`board-gate.sh`'s `_git_subcommand`** — issue-114's table already
  marked its *iteration source* "closed by #114" (`gate_trailing_words`),
  but the function's own value-flag blindness (R2, named in issue-114's
  own R2 prose, "the pre-existing `git -C <dir> <subcommand>` global-flag
  misread") is now also closed: `_git_subcommand` recognizes git's own
  `-C`/`-c` value-taking global flags via `GIT_GLOBAL_VALUE_FLAGS`. **No
  longer a differential.**
- **`gate-lib.py`'s `_resolve_transparent`** (the canonical model itself,
  issue-114's R3) — no longer misreads a `TRANSPARENT` wrapper's own
  value-taking flag; `TRANSPARENT_FLAG_TAKES_ARG` consumes the flag's
  value token before the generic bare-flag/`skip_extra` walk can misread
  it, for all four documented shapes (`nice -n`, `env -u`, `timeout -s`,
  `xargs -I`).
- **`gh-guard.sh:147`'s `gate_wrapper_head_before` call** — unchanged, as
  the proposal's `## Constraints` required; still the documented
  fail-open design (`gate-lib.py:281-322`), not touched by any of
  R1/R2/R3.
- **Every other production site** (`board-gate.sh:237,293,356`, the
  `gate-lib.py` resolver definitions themselves) is unchanged from
  issue-114's table and remains canonical or fail-open-by-design, not a
  differential.
- **Every `split()` production hit** is either the canonical resolver's
  own base tokenization (`gate-lib.py:230`), the separate non-resolver
  scan (`gate-lib.py:324`), or out-of-class (env-var/file parsing,
  `record-fields-gate.sh:110`, `hunt-guard.sh:98`) — the same three
  categories issue-114's own table already used, no new site.

**Zero remaining habitats of this class.** R1, R2, and R3 are all closed;
the mechanical re-run turned up nothing new or unanticipated — the
proposal's own out-of-scope handling for an unanticipated re-enumeration
result was not needed here, since nothing unanticipated turned up (see
`## Next steps`).
