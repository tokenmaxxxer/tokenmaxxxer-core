---
issue: 366
role: adversarial-review-d3da02be
author: adversarial-review-d3da02be
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: false  # original build work under CORE_BUILD_NOW=1 bypass, not an independent verification of another subject's deliverable
loop_state: landed
upstream:
  - path: core/hooks/approval-gate.sh
    sha: same-commit
  - path: core/hooks/board-gate.sh
    sha: same-commit
  - path: core/hooks/directive.sh
    sha: same-commit
  - path: core/hooks/gh-guard.sh
    sha: same-commit
  - path: core/hooks/ordering-gate.sh
    sha: same-commit
  - path: core/hooks/pretooluse_dispatcher.py
    sha: same-commit
  - path: core/hooks/record-fields-gate.sh
    sha: same-commit
  - path: core/hooks/test_board_gate.py
    sha: same-commit
---

# issue-366 — adversarial-review-d3da02be record

skill-verdict: work-in-english — applied: invoked; code/comments/commits/this record written in English, Korean reserved for the final user-facing summary
skill-verdict: model-routing — applied: invoked; confirmed the STEP 1 solo decision (single coherent vocabulary-consistency edit, not independently parallelizable) matched the skill's "when NOT to delegate" guidance before doing the edits inline
other mounted skills: not triggered (verify-finding-record, parallel-decomposition, adversarial-review, product-discovery-opportunity-solution-tree — none apply: this is original build work under the CORE_BUILD_NOW=1 bypass, not a defect-verification record, not a multi-agent fan-out, not a review of another session's artifact, not opportunity/outcome framing)

## What was done

The role assignment for this issue is `adversarial-review-d3da02be`, but
issue #366 itself is a direct build/bugfix ask, delivered under the
CORE_BUILD_NOW=1 bypass (build-now, no proposal round).

Renamed the retired noun "role" to "skill" in every **gate-message**
string across `core/hooks` — the strings a live session actually reads
when a hook denies a call or a SessionStart hook informs it, as opposed
to comments, code identifiers, or filenames (all out of scope: #2600's
own already-landed slices, or a much larger rename this issue does not
ask for). `warrant/hooks` had zero such strings (see population search
below) — no changes were needed there.

Files touched, one `deny()`/heredoc-message fix count in parentheses:
`core/hooks/board-gate.sh` (6), `core/hooks/approval-gate.sh` (4),
`core/hooks/gh-guard.sh` (6), `core/hooks/directive.sh` (3),
`core/hooks/record-fields-gate.sh` (2), `core/hooks/ordering-gate.sh` (1),
`core/hooks/pretooluse_dispatcher.py` (1) — 23 distinct message-string
edits, landing as 34 changed lines (`git diff --stat` below; several
messages wrap the interpolated word across a line break, so one edit can
touch two adjacent lines). `core/hooks/test_board_gate.py` (5 assertions)
was updated in the same commit to match the new message text — a pure
test-content sync, not a new or renamed test.

canonical: `git diff --stat -- core/hooks warrant/hooks` (executed) —
```
 core/hooks/approval-gate.sh         | 12 ++++++------
 core/hooks/board-gate.sh            | 16 ++++++++--------
 core/hooks/directive.sh             |  8 ++++----
 core/hooks/gh-guard.sh              | 14 +++++++-------
 core/hooks/ordering-gate.sh         |  2 +-
 core/hooks/pretooluse_dispatcher.py |  2 +-
 core/hooks/record-fields-gate.sh    |  4 ++--
 core/hooks/test_board_gate.py       | 10 +++++-----
 8 files changed, 34 insertions(+), 34 deletions(-)
```

### Acceptance check 1 — live before/after denial at board-gate.sh's
unanalyzable-write-shape rule (the exact rule the issue quoted, now at
line 846 in the current file — line numbers had drifted since the issue
was filed against an older revision)

derived: reproduced live via a standalone board-gate.sh subprocess
invocation (temp git repo, CLAUDE_SKILL set to the exact skill name from
the issue's own reproduction, a Bash `cat > "$FILE" <<'EOF'` payload
matching the issue verbatim) — driver script at `/tmp/repro_366.sh`,
run as `bash /tmp/repro_366.sh "$(pwd)/core/hooks/board-gate.sh" "$(pwd)"`.

Before (captured before any edit landed in this session, same driver,
same payload):
```
board-gate: a Bash call carries an un-analyzable write-capable shape (cat > "/tmp/.../docs/issue-366/reports/adversarial-review-d3da02be.md" <<'EOF') while this
gate enforces role 'technical-writing-style-guide-compliance-632a1d33''s write-set. A heredoc body, ...
```

After (this commit's tree):
```
board-gate: a Bash call carries an un-analyzable write-capable shape (cat > "/tmp/tmp.b389puAIdO/docs/issue-366/reports/adversarial-review-d3da02be.md" <<'EOF') while this gate enforces skill 'technical-writing-style-guide-compliance-632a1d33''s write-set. A heredoc body, an interpreter -c/-e inline script, or a dd invocation does not show its real write target in the command text, so this refuses rather than risk a masked out-of-set write (issue-225 — the on-the-record PR #1627 bypass). Use a provably read-only invocation (e.g. python3 -m pytest), or write through Write/Edit or a plain redirect this gate can read the target of. This is a write-set discipline check, not a security boundary (issue-233 round 5): it denies only shapes it cannot read the write target of, and does not claim to catch a shape deliberately built to hide that target from this text-level read.
RC=2
```

The slot now names what it actually holds: a skill name, labelled
"skill", not "role" — matching the issue's exact reproduction case.

A second live sample, `directive.sh`'s SessionStart message (the exact
message this very session received at spawn — visible verbatim at the
top of this session's own transcript, quoting the pre-fix text) —

derived: `env TOKENMAXXXER_SPAWNED=1 CLAUDE_SKILL=technical-writing-style-guide-compliance-632a1d33 CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$(pwd)" /bin/bash core/hooks/directive.sh` (executed, temp repo with a git remote so the precondition probe passes to the INVARIANTS block)

After:
```
[core] Interaction protocol for skill technical-writing-style-guide-compliance-632a1d33 (role-handoff contract v3). INVARIANTS:
...
- Two phases (s19): ... or an issue comment whose entire body is exactly APPROVE issue-<n>/<skill>. String equality only; ...
```
("role-handoff contract v3" is the proper name of an actual spec file,
`docs/specs/role-handoff-contract.md` — left unchanged; renaming a spec's
own name is a separate, much larger identifier-rename this issue does not
ask for and `docs/` may not be touched.)

### Acceptance check 2 — population: the search that defines "a string a
session can see", and its count

derived: "a string a session can see" = a string literal passed to a
gate's `deny()`/`sys.stderr.write()`/`print(..., file=sys.stderr)` call,
or emitted via `echo`/`cat <<EOF` from a SessionStart hook's stdout —
i.e. message-emitting code, excluding comments, code identifiers,
filenames, and `*/tests/*` or `test_*.py` files (dev-only harnesses,
never delivered to a live coding session).

Step 1 (candidate population, excludes dev-only test harnesses):
```
grep -rn "role" core/hooks warrant/hooks --include="*.sh" --include="*.py" | grep -v "/tests/"
```
→ 212 lines in `core/hooks`, 2 lines in `warrant/hooks` (214 total,
`wc -l` on the grep output, executed).

Step 2: every one of those 214 candidate lines was read in its full
call-site context (not grepped in isolation, since gate messages are
multi-line concatenated Python string literals a single-line regex
cannot safely classify) and classified message vs. non-message. Result:
- `core/hooks`: 23 distinct message-string sites containing "role"
  (listed under "What was done" above) — all fixed. The remaining ~189
  candidate lines are comments, the historical rename-explanation message
  at `board-gate.sh:974-977` (deliberately describes the past `role ->
  skill` rename as history, not live vocabulary — left unchanged),
  filename references (`.on-the-record/role.json`,
  `docs/specs/role-handoff-contract.md`), and code identifiers
  (`gate_is_role_directive_stub`, `core_role_directive`,
  `role_directive_hits`) — the identifier/filename slice #2600 already
  claims, not this issue's population.
- `warrant/hooks`: 0 message-string sites. Both candidate lines are a
  comment (`state.sh:42`) and a safe-command filename regex
  (`scope-gate.py:122`, matching the literal test-runner filename
  `run-role-gates-tests.sh`) — reported zero explicitly, this directory
  needed no change.

Step 3 (post-edit verification, same search re-run against the fixed
tree, re-classified the same way):
```
grep -rn "role" core/hooks warrant/hooks --include="*.sh" --include="*.py" | grep -v "/tests/"
```
→ 0 remaining message-emitting occurrences of "role" (only the same
deliberately-kept non-message hits: comments, the historical-rename
message, filenames, identifiers, and the "role-handoff contract v3"
proper noun).

`core/directive/session-protocol.md` — a file `directive.sh` `cat`s
verbatim into a live session's SessionStart output, and does contain
"role" 11 times — was deliberately **not** touched: it sits outside the
issue's declared population (`core/hooks` and `warrant/hooks`), and its
content is authored directive/prompt text for a model, which is exactly
#2600's "prompt text" slice (already landed, explicitly a non-goal here
per the issue body: "#2600's five slices, all landed"). Flagging this as
a known gap for a follow-up issue, not fixing it here — expanding the
declared population was not asked for.

### Acceptance check 3 — gate test suites before/after, as sets of test
names

derived: ran the touched suites before any edit landed in this session,
and again after, saved full output, and diffed both the plain name sets and the
`{status, name}` pairs (so a name reappearing with a different pass/fail
status would show up, not just a name being added/removed).

```
cd core/hooks/tests
bash run-board-gate-tests.sh        # 159 passed, 2 failed (unrelated, pre-existing — see below)
bash run-approval-gate-tests.sh     # 65 passed, 2 failed (unrelated, pre-existing)
bash run-gh-guard-tests.sh          # 54 passed, 0 failed
bash run-role-gates-tests.sh        # 83 passed, 0 failed
bash run-scope-gate-tests.sh        # 62 passed, 0 failed
bash run-dispatcher-equivalence-tests.sh   # 24 passed, 1 failed (unrelated, pre-existing)
python3 -m pytest core/hooks/test_board_gate.py -q    # 22 passed
```

`diff <(sort before_names) <(sort after_names)` — empty (identical sets)
for every suite above except `run-dispatcher-equivalence-tests.sh`, whose
one non-identical line is the "dispatcher end-to-end latency < 100ms
(avg NNms)" test's own embedded timing number (a runtime metric baked
into that one test's name, not a test being added/removed/renamed);
`diff` on the `{status, name}` pairs (pass/fail attached) was also empty
for `run-board-gate-tests.sh` and `run-approval-gate-tests.sh` — the same
2+2 tests fail before and after, for the same reasons.
`python3 -m pytest core/hooks/test_board_gate.py --collect-only -q`
before/after: identical 22-name list, `diff` empty.

Acceptance requirement met — checked: `diff before_board_status.txt
after_board_status.txt && diff before_approval_status.txt
after_approval_status.txt` — result: both empty (no diff output),
confirming "no gate changes what it allows or denies" for every test
name in both suites, pass or fail.

Pre-existing failures (unrelated to this change — logic/behavior bugs,
not message text; present before any edit in this session, left
untouched per "No gate changes what it allows or denies"):
`feasibility-spikes`, `ops-postmortems` (board-gate, want=allow got=deny),
`checkpoint-refusal-names-await-approval`, `execute-without-remote`
(approval-gate), `approval-gate: execution write, no approvers.md ->
deny` (dispatcher-equivalence). None of these assert on "role"/"skill"
message text; their failure mode is unrelated to this issue.

## Why

The issue's own framing is the rationale: #2600 sliced the "role" →
"skill" vocabulary retirement by occurrence kind (env vars / comments &
docstrings / prompt text / identifiers / persisted keys), and gate
messages — strings composed by gate logic and interpolated with a live
value (a skill name), then written to stderr or SessionStart stdout —
fit none of those kinds cleanly. They are code, but they are also the
exact sentence a session reads at the moment it is blocked. Fixing the
vocabulary here, and nowhere else the diff shows, keeps the change
scoped to "what a session reads", the population the issue actually
names, rather than re-litigating #2600's already-landed slices or
reaching into `docs/` (forbidden) or a spec's own filename (a
much bigger, unrequested rename).

Chose plain "skill" over any hedge/compatibility phrasing (e.g. no
"role/skill" dual-vocabulary) per the issue's explicit `must not`:
no compatibility alias, no dual-vocabulary period — precedent (#2572,
#2592) is a hard cutover naming the replacement outright. "skill" was
picked, not invented: it is the vocabulary the code's own variables
already use everywhere (`CLAUDE_SKILL`, `skill = os.environ.get(...)`,
`_sidecar_skill`) — the message text was the one place still lagging the
code that composes it.

## What did not work

None.

## Upstream basis

All eight `core/hooks/*` files listed in this record's frontmatter
`upstream:` land in this same commit (`sha: same-commit`). No other
record or commit was built upon.

## Open findings

`core/directive/session-protocol.md` still teaches "role" vocabulary to
every live session that receives the full protocol text (11 occurrences,
derived: `grep -c "role" core/directive/session-protocol.md`, executed) —
left open per the population-boundary reasoning under Acceptance check 2.
Whether this belongs to #2600's already-landed "prompt text" slice, or is
itself a second instance of the same finding this issue reports, is a
scoping question for a human or a follow-up issue, not resolved here.

## Next steps

loop_state: landed — none pending for this record. The
`core/directive/session-protocol.md` gap above is a candidate follow-up,
not a next step of this delivery.
