---
issue: 370
role: merge-gates-eb4aeb17
author: merge-gates-eb4aeb17
skills: merge-gates (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: dce87e8d1297f6c8a0655ab77cb74d12e5458650
  - path: core/hooks/lib/gate-lib.py
    sha: dce87e8d1297f6c8a0655ab77cb74d12e5458650
  - path: warrant/hooks/lib/scope-gate.py
    sha: dce87e8d1297f6c8a0655ab77cb74d12e5458650
  - path: core/hooks/tests/run-board-gate-tests.sh
    sha: dce87e8d1297f6c8a0655ab77cb74d12e5458650
  - path: core/hooks/tests/run-scope-gate-tests.sh
    sha: dce87e8d1297f6c8a0655ab77cb74d12e5458650
  - path: docs/handbooks/board-gate-tests.md
    sha: dce87e8d1297f6c8a0655ab77cb74d12e5458650
---

# issue-370 — merge-gates-eb4aeb17 record

## What was done

Rebased PR #398's branch (`issue-370/secure-coding-input-validation-injection-defense-2c6959d2`,
head `14ae52a`) onto current `origin/main` (`dafd1ca`), landing it here on
`issue-370/merge-gates-eb4aeb17`, and folded in two non-blocking findings
from PR #401's independent verification. The security-fix logic itself
(rounds 1-3 salvage plus round 2's var-indirected drift fix) is unchanged
from what #401 already verified.

- `derived: git rebase origin/main` (starting from a branch checked out at
  PR #398's head) completed with **zero manual conflict resolution** —
  `git rebase` auto-merged both branches' non-overlapping hunks in
  `core/hooks/board-gate.sh`, `core/hooks/lib/gate-lib.py`, and
  `core/hooks/tests/run-board-gate-tests.sh` cleanly.
- Confirmed the three role→skill denial-message strings issue-366 (`#389`,
  commit `237c8b9`, on `origin/main`) rewrote are intact post-rebase, not
  reverted and not double-applied:
  ```
  $ grep -n 'deny("cannot resolve the current git branch\|deny("sidecar skill/issue\|deny("docs/%s/reports/%s belongs to another skill' core/hooks/board-gate.sh
  1180:    deny("cannot resolve the current git branch for a board write; a skill "
  1215:            deny("sidecar skill/issue (issue-%d/%s) disagrees with the "
  1399:    deny("docs/%s/reports/%s belongs to another skill. %s writes only "
  ```
- **Finding 1 (PR #401, comment overclaim) — fixed.** `7ec6094`'s
  `_bare_var_has_literal_interp_assignment` preamble comment in
  `core/hooks/board-gate.sh` claimed "the existing conservative blanket
  check is unchanged -- that residual is the genuine
  interpreter-head-via-expansion class this salvage exists to keep
  closed." #401 showed that for the true env-only-`$P` case (no literal
  interpreter name anywhere in the payload text), the shell-level
  `UNANALYZABLE_HEAD_RE` fast path can exit before the Python judge (the
  "blanket check") ever runs, so the check does not close that sub-case.
  Reworded the comment (commit `dce87e8`) to say what actually runs, with
  no logic change — `derived: git show dce87e8 -- core/hooks/board-gate.sh`
  is a comment-only diff, verified below (invariant 4).
- **Finding 2 (PR #401, quoted-path-with-spaces class) — surfaced, not
  fixed, per explicit instruction not to change what the round-1-3/round-2
  fix does.** Live-verified below (acceptance check 2) rather than
  patched: `board-gate.sh`'s own tokenizer denies the backslash-escaped
  form (`escaped-space-interpreter-path`) but still allows the
  double-quoted form (`quoted-path-with-spaces`) and the ANSI-C-quoted
  flag form (`ansi-c-quoted-flag-word`) — a pre-existing gap dating to
  `2fb9038` (an issue-233 commit already on this branch before this
  session started), reproduced identically before and after the rebase.
  `warrant/hooks/lib/scope-gate.py` does **not** share this gap (denies
  all three live below) — the residual is board-gate.sh-specific.

## Why

The task was explicitly scoped as a rebase-and-land of an already-verified
fix (#401 confirmed the structural claim under exhaustive testing), not a
re-design: "It is verified and ready otherwise — do not change what the fix
does." The two #401 findings folded in here were both explicitly marked
non-blocking and low-risk to touch (a comment reword with no logic change,
and documentation/verification of an already-pre-existing, already-tested
gap) — the other three #401 findings (branch staleness, now resolved by
this rebase; test-coverage asymmetry for the round-2 perl fix; and the
residual un-derived third name enumeration) were explicitly out of scope
and left untouched.

## What did not work

None.

## Acceptance check 1 — `d434daa`'s hunks absent from the diff that lands

```
$ git log --oneline origin/main..HEAD | grep d434daa            # exit 1, no match
$ git merge-base --is-ancestor d434daa HEAD; echo $?              # 1, not an ancestor
$ git show d434daa | git patch-id | awk '{print $1}'
c97ae0f8446017b9944f32d6732922bd94378078
$ git log origin/main..HEAD --oneline | while read sha rest; do
    pid=$(git show "$sha" | git patch-id | awk '{print $1}')
    [ "$pid" = "c97ae0f8446017b9944f32d6732922bd94378078" ] && echo "MATCH: $sha"
  done                                                             # no output, no match
$ grep -n UNRESOLVED_SUBSTITUTION_WORD_RE core/hooks/board-gate.sh core/hooks/tests/run-board-gate-tests.sh
                                                                    # exit 1, absent
```

The diff that lands against `origin/main` (`derived: git diff --stat
origin/main..HEAD`):
```
 core/hooks/board-gate.sh                           | 226 +++++++++-
 core/hooks/lib/gate-lib.py                         | 106 ++++-
 core/hooks/tests/run-board-gate-tests.sh           | 164 ++++++++
 core/hooks/tests/run-scope-gate-tests.sh           | 176 +++++++-
 docs/handbooks/board-gate-tests.md                 | 139 ++++++-
 (7 new docs/issue-370 and docs/issue-233 report files)
 warrant/hooks/lib/scope-gate.py                    | 251 ++++++++++-
 13 files changed, 2671 insertions(+), 24 deletions(-)
```

## Acceptance check 2 — live before/after for the four bypass classes

Real subprocess invocations of `core/hooks/board-gate.sh`, comparing
`origin/main`'s copy of the script ("before") against this branch's HEAD
copy ("after"), each run inside a fresh throwaway git repo with a
`docs/issue-3/reports/qa` board, `CLAUDE_SKILL=qa`, on branch `issue-3/qa`:

| class | command | before | after |
|---|---|---|---|
| interpreter-head-via-expansion | `"$SHELL" -c open("reports/qa/pwn.md","w").write("1")` | allow | **deny** |
| backslash-escape word formation | `p\y\t\h\o\n3 -c open(...)` | allow | **deny** |
| backslash-newline splicing | `pyth\<newline>on3 -c open(...)` | allow | **deny** |
| escaped-space interpreter path | `/opt/My\ Python/python3 -c open(...)` | allow | **deny** |
| quoted-path-with-spaces | `"/opt/My Python/python3" -c open(...)` | allow | allow (pre-existing gap, see Finding 2 above) |

Same five payloads against `warrant/hooks/lib/scope-gate.py` (via
`warrant/hooks/scope-gate.sh`), `origin/main`'s copy vs. this branch's:

| class | before | after |
|---|---|---|
| interpreter-head-via-expansion | deny | deny |
| backslash-escape word formation | deny | deny |
| backslash-newline splicing | deny | deny |
| escaped-space interpreter path | deny | deny |
| quoted-path-with-spaces | deny | deny |

(`origin/main`'s scope-gate.py denies all five by its pre-existing
default-deny-unless-provably-safe posture, since it has none of this
issue's per-interpreter allowlist logic yet; the meaningful contrast for
scope-gate.py is acceptance check 3 below — ordinary safe commands that
must stay allowed, not these malicious ones.)

Reproduction (Python, real subprocesses, throwaway git repos and
worktrees, `origin/main` checked out via `git worktree add --detach
/tmp/main-worktree origin/main`):
```python
payload = json.dumps({"tool_name": "Bash",
                       "tool_input": {"command": command_text}, "cwd": td})
env = {**os.environ, "CLAUDE_PROJECT_DIR": td, "CLAUDE_PLUGIN_ROOT": core_root,
       "CLAUDE_SKILL": "qa"}
p = subprocess.run(["/bin/bash", gate], input=payload.encode(), env=env, ...)
# rc 0 => allow, rc 2 => deny
```
Full command texts and results (board-gate.sh):
```
interpreter-head-via-expansion         before=allow    after=deny      command='cd docs/issue-3 && "$SHELL" -c open("reports/qa/pwn.md", "w").write("1")'
backslash-escape-word-formation        before=allow    after=deny      command='cd docs/issue-3 && p\\y\\t\\h\\o\\n3 -c open("reports/qa/pwn.md", "w").write("1")'
backslash-newline-splice               before=allow    after=deny      command='cd docs/issue-3 && pyth\\<newline>on3 -c open("reports/qa/pwn.md", "w").write("1")'
escaped-space-interpreter-path         before=allow    after=deny      command='cd docs/issue-3 && /opt/My\\ Python/python3 -c open("reports/qa/pwn.md", "w").write("1")'
quoted-path-with-spaces                before=allow    after=allow     command='cd docs/issue-3 && "/opt/My Python/python3" -c open("reports/qa/pwn.md", "w").write("1")'
```
Cross-checked against the committed test suite (same repo, real
subprocess, `bash core/hooks/tests/run-board-gate-tests.sh`): identical
verdicts for the equivalent named tests
(`quoted-expansion-head-double`/`backslash-escape-spelling`/`backslash-newline-splice`/`escaped-space-interpreter-path-c-flag`
deny; `quoted-path-with-spaces-c-flag` allow, i.e. `FAIL want=deny
got=allow` — a known, disclosed pre-existing gap, not new).

## Acceptance check 3 — ordinary commands PR #363's branch denied, now allowed

Same live-subprocess method, `refs/pull/363/head` (`de44c51`, PR #363's
original, pre-salvage branch — still present on the remote) vs. this
branch's HEAD, against `core/hooks/board-gate.sh`:
```
pytest-computed-arg       PR#363=deny     HEAD=allow     command='python3 -m pytest -k "$(echo foo)"'
script-computed-input     PR#363=deny     HEAD=allow     command='python3 script.py --input "$(pwd)/data.csv"'
```
Both are also covered live in the committed suite as
`round5-pytest-computed-arg` and `round5-script-computed-input`, both
`ok ... allow` on this branch's HEAD.

## Standing invariants (all four checked live)

1. **No retired role-axis leak, pattern catches the plural too**
   (`\brole\b`, word-boundary): `derived: git diff origin/main..HEAD --
   core/hooks/board-gate.sh core/hooks/lib/gate-lib.py
   warrant/hooks/lib/scope-gate.py warrant/hooks/scope-gate.sh | grep -E
   '^\+' | grep -E '\brole\b'` → exactly 2 new lines, both from a source
   comment in `gate-lib.py` ("a role session's call ... role's own
   write-set") — the generic "a session that holds a role" concept, not a
   retired user-facing denial-message noun. The three denial-message
   strings issue-366 renamed (`board-gate.sh:1180,1215,1399`, quoted
   above) all read "skill", confirming the rename survived the rebase
   without being reverted or double-applied.
2. **No new bug, failing-test set vs `origin/main` as SETS OF NAMES,
   collection scope stated.** Collection scope:
   `core/hooks/tests/run-board-gate-tests.sh`,
   `core/hooks/tests/run-scope-gate-tests.sh`,
   `core/hooks/tests/run-role-gates-tests.sh` (the three suites covering
   the code this rebase touches), each run as a real subprocess:
   ```
   origin/main (dafd1ca):  board-gate 159 passed, 2 failed: {feasibility-spikes, ops-postmortems}
                            scope-gate 62 passed, 0 failed
                            role-gates 83 passed, 0 failed
   HEAD (dce87e8):          board-gate 188 passed, 4 failed: {feasibility-spikes, ops-postmortems,
                                        quoted-path-with-spaces-c-flag, ansi-c-quoted-flag-word}
                            scope-gate 92 passed, 0 failed
                            role-gates 83 passed, 0 failed
   ```
   Set difference vs. `origin/main`: `{quoted-path-with-spaces-c-flag,
   ansi-c-quoted-flag-word}`. Both test *names* do not exist at all on
   `origin/main` (added by `2fb9038`, an issue-233 commit already on this
   branch before this session began) and both already failed at the
   commit that introduced them — reproduced identically before this
   session's own rebase and comment-reword commit, and after. Zero new
   test failures introduced by this session's own two actions (the
   rebase and the comment reword).
3. **No overhead increase.** This session's only content change is
   `dce87e8`, and `derived: git show dce87e8 -- core/hooks/board-gate.sh
   | grep -E '^[+-][^+-]'` shows every changed line begins with `#` —
   comment-only, zero runtime cost. The rebase itself replayed PR #398's
   commits unmodified (already covered by PR #401's own invariant-4
   check on that diff).
4. **Monitor/watch machinery unbroken and not quieter.** `derived: git
   ls-files | grep -iE 'monitor|watch'` → no output. No such machinery
   exists in this repo; invariant vacuously satisfied (matches #401's
   own finding).

## Upstream basis

`tokenmaxxxer/tokenmaxxxer-core#398`, branch head `14ae52a`
(`14ae52af1146e2b171bfbd48b9bce984aa6b4e41`), rebased onto `origin/main`
at `dafd1ca` (current tip at rebase time, which includes issue-366's
role→skill rename `237c8b9` and PR #401's independent-verification record
`dafd1ca`). Context only (not restated): `docs/issue-370/reports/adversarial-review-b4a7cf19.md`
(PR #401's independent verification, source of both findings folded in
here).

## Open findings

1. **Pre-existing "quoted-path-with-spaces"/"ansi-c-quoted-flag-word" gap
   in `board-gate.sh`'s own tokenizer** — dates to `2fb9038` (issue-233),
   predates this session, out of scope to fix here per explicit
   instruction not to change what the fix does. `warrant/hooks/lib/scope-gate.py`
   does not share this gap. Resolution path: a follow-up round (issue-233
   or a new issue) giving `board-gate.sh`'s tokenizer the same
   quoted/ANSI-C-quote awareness it already has for backslash-escaped
   whitespace.
2. Findings 3 (branch staleness), 4 (test coverage asymmetry for the
   round-2 perl `-c` fix), and 5 (residual un-derived third name
   enumeration) from PR #401 need no action here per explicit task scope
   — 3 is resolved by this rebase itself; 4 and 5 are pre-existing,
   non-blocking, and out of this session's scope.

## Next steps

None — PR opened from this branch; landing decision is the reviewer's.

## Skill verdicts

- skill-verdict: merge-gates — not-applicable: this task is resolving a rebase conflict and landing an already-verified fix, which the skill's own scope explicitly excludes ("Do NOT use to resolve a conflict that has already happened (that is a code task)").
- skill-verdict: work-in-english — applied: invoked; followed for all commit messages, code comments, and this record (English), reserving Korean for the final user-facing chat summary only.
- other mounted skills (growth-analytics-metric-selection, test-depth-audit, conformance-review-finding-record, parallel-decomposition, accessibility-aria-and-contrast-rules): not triggered — none of their trigger conditions (metric selection, test-suite depth audit, conformance-review verdict recording, multi-agent build fan-out, ARIA/contrast decisions) apply to a single-session rebase-and-land task.
