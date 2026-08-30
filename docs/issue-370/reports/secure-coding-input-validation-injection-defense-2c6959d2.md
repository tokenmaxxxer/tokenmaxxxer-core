---
issue: 370
role: secure-coding-input-validation-injection-defense-2c6959d2
author: secure-coding-input-validation-injection-defense-2c6959d2
skills: secure-coding-input-validation-injection-defense (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: done
code_under_review: core/hooks/board-gate.sh, warrant/hooks/lib/scope-gate.py, core/hooks/lib/gate-lib.py, core/hooks/tests/run-scope-gate-tests.sh
type: fix
breaking: false
verdict: delivered
upstream:
  - path: PR #391 (tokenmaxxxer/tokenmaxxxer-core, branch issue-370/secure-coding-input-validation-injection-defense-ed7ce13a)
    sha: 8bdc277a8b81c99f0a7e6b3e63220e8d02f9ac3a
  - path: docs/issue-370/reports/secure-coding-input-validation-injection-defense-ed7ce13a.md
    sha: same-commit
---

# issue-370 — secure-coding-input-validation-injection-defense-2c6959d2 record

## What was done

skill-verdict: secure-coding-input-validation-injection-defense — applied: invoked; rule 9 ("two validation layers doing the same allowlist check on the same field... REMOVE the duplicate... the looser one becomes the actual enforced policy") named the exact defect below and shaped the fix — derive the var-indirected check from the same single source the direct-form check already uses, instead of maintaining a second, independently drifting name list.

Round 2 on PR #391, after independent verification #395 returned BLOCKING. PR #391's own 11 commits (rounds 1-3 salvage + the var-indirected integration fix + its record) carried cleanly onto this branch — checked: `git cherry-pick 8c7cc8d..origin/issue-370/secure-coding-input-validation-injection-defense-ed7ce13a` — result: 11/11 applied with zero conflicts (`git log --oneline origin/main..HEAD | wc -l` — result: `11` immediately after the cherry-pick, before this round's own commits). PR #391's own record (`secure-coding-input-validation-injection-defense-ed7ce13a.md`, carried in unchanged) already covers the salvage's own claims; this record covers only round 2's delta.

**The blocking finding, reproduced live before any fix (checked: `bash /tmp/probe_gates.sh <repo>` run against the code as cherry-picked, before this round's edits, via `git stash`):**

```
== board-gate ==
P=perl; $P -c 'open(1)' -> 0
== scope-gate ==
P=perl; $P -c some/script.pl -> 0
```

Both gates ALLOW (`0`) the var-indirected perl `-c` form while the direct form `perl -c ...` correctly DENIES — checked live in the same run: `perl -c some/script.pl` (direct) — result: `2` (deny), confirming the deferral was narrower than the direct-form check it stood in for.

**Root cause:** both `VAR_INTERP_RE` (`core/hooks/board-gate.sh`) and its inline twin inside `UNANALYZABLE_WRITE_SHAPE` (`warrant/hooks/lib/scope-gate.py`) spelled their own hand-written, independent name lists for "which interpreters treat `-c` as inline-code" / "which treat `-e` as inline-code" — a second copy of the same per-interpreter flag knowledge the direct-form checks (`INLINE_FLAG_HEADS` in board-gate.sh; the direct-form alternatives in scope-gate.py) already hold as the authoritative source. perl is the one interpreter (round 6) with BOTH flags dangerous; the hand-written `-c` name list in both gates' var-indirected checks never named it, so it drifted looser than the direct-form policy for exactly this one interpreter. Per the skill's rule 9, the fix is to remove the second copy, not patch a perl-only entry into it.

**Fix, in both gates, applied identically in shape:**
- `core/hooks/board-gate.sh`: `VAR_INTERP_RE`'s two name groups are now built from `INLINE_FLAG_HEADS` itself (`_VAR_INTERP_C_NAMES`/`_VAR_INTERP_E_NAMES`, derived by filtering `INLINE_FLAG_HEADS` for `"-c"`/`"-e"` membership) instead of a hand-written enumeration — a name's var-indirected flags are now always exactly its direct-form flags, by construction.
- `warrant/hooks/lib/scope-gate.py`: introduced `_C_FLAG_INTERP_NAMES`/`_E_FLAG_INTERP_NAMES` module-level constants (this gate has no per-interpreter dict, only regex alternatives) and used them in BOTH the direct-form alternatives (collapsing the separate perl-only `-c` alternative into the shared group) and the var-indirected alternatives, removing the second copy the same way.
- Neither change adds a perl-specific branch anywhere — perl's double-flag membership is expressed once, as data (present in both flag groups), and consumed identically to every other interpreter.

**Live after-fix reproduction (checked: `bash /tmp/probe_gates.sh <repo>`, same script, run again with the fix applied):**

```
== board-gate ==
P=perl; $P -c 'open(1)' -> 2
P=bash; $P -e some/script.sh (must ALLOW) -> 0
ordinary: python3 script.py --input "$(pwd)/data.csv" (must ALLOW) -> 0
== scope-gate ==
P=perl; $P -c some/script.pl -> 2
P=bash; $P -e some/script.sh (must ALLOW) -> 0
ordinary: python3 script.py --input "$(pwd)/data.csv" (must ALLOW) -> 0
```

The perl bypass now denies (`2`) at both gates; round 6's own disclosed, in-scope residual (`P=bash; $P -e ...`, bash has no `-e` inline-code meaning) still allows; the ordinary computed-argument command still allows — the three variants verification #395 asked to be checked (non-literal assignment, non-visible assignment, reassignment) were not re-probed here because they were reported as already correctly DENYing and untouched by this fix (the fix only widens which name groups a *literal, visible* assignment is checked against; it does not touch the gating condition that requires that assignment to be literal and visible in the first place).

Second, non-blocking fix: reworded the one retired-role-noun comment the task named, in `core/hooks/lib/gate-lib.py` (part of the salvaged `32176ef` commit) — `` a `qa`-role call denied nothing while writing outside `qa`'s own write-set `` → `` a role session's call denied nothing while writing outside that role's own write-set ``, matching the "role session" phrasing already used elsewhere in this file's own comments (e.g. `core/hooks/board-gate.sh` R4/R2, `core/hooks/gh-guard.sh`).

## Why

Rule 9 of the mounted `secure-coding-input-validation-injection-defense` skill: two independently-maintained copies of the same allowlist rule diverge, and the looser one becomes the actually-enforced policy. That is exactly what verification #395 caught — the var-indirected deferral (a second, hand-written copy of "which interpreter needs which flag denied") had drifted looser than the direct-form check (the authoritative copy) for perl specifically, because perl is the one interpreter where the two copies' shapes (each interpreter has exactly one dangerous flag) stopped holding. The task explicitly asked not to bolt on a perl special case beside the others, since that repeats the same mistake with one more hardcoded name; deriving both var-indirected name groups from the same source the direct-form check already uses removes the second copy entirely, so the deferral cannot be narrower than the direct-form denial for any interpreter — not just perl — without anyone having to remember to keep two lists in sync.

`warrant/hooks/lib/scope-gate.py` had no equivalent to `INLINE_FLAG_HEADS` (its direct-form check is pure regex alternation, not a dict), so introducing two shared name-set constants (flag-keyed, not interpreter-keyed — `_C_FLAG_INTERP_NAMES`/`_E_FLAG_INTERP_NAMES`) and using them in both the direct-form and var-indirected alternatives was the smallest structural change that removes the duplication without inventing a new per-interpreter table (which the task explicitly said not to do). This also incidentally collapsed the direct-form check's separate perl-only `-c` alternative (which existed purely because the original `-c` group didn't include perl) into the shared group — a simplification, not a behavior change (perl already denied `-c` directly before this round; it is denied via the merged group now).

## What did not work

None.

## Upstream basis

- PR #391 (`issue-370/secure-coding-input-validation-injection-defense-ed7ce13a`), all 11 commits, cherry-picked onto this branch unchanged (`git cherry-pick 8c7cc8d..origin/issue-370/secure-coding-input-validation-injection-defense-ed7ce13a` — result: 11/11 applied, zero conflicts). PR #391's own record, `docs/issue-370/reports/secure-coding-input-validation-injection-defense-ed7ce13a.md`, sha: same-commit (carried in unmodified as part of the cherry-pick range), covers the salvage's own claims (the `d434daa` exclusion, the four bypass classes, the over-refusal probe) — not re-derived in this record; independent verification #395 reported those as clean and this round did not touch that code.
- Independent verification #395 (not a file in this repo; referenced by the round-2 task text that spawned this session) — the blocking finding it reported is reproduced live above, before any fix.

## Open findings

None open. The blocking finding from #395 is closed (see live before/after above). The non-blocking retired-role-noun finding is fixed (see above).

## Next steps

loop_state: done. Acceptance checks below satisfy the issue's three stated criteria plus the round-2 task's four standing invariants:

- checked: `git diff origin/main..HEAD -- core/hooks/board-gate.sh warrant/hooks/lib/scope-gate.py | grep -n "^+INLINE_FLAG_HEADS\|^+INTERPRETER_HEADS"` — result: empty (no new key added to either flag/head table by this round; `d434daa`'s hunks remain absent, unchanged from PR #391's own derivation)
- checked: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh` — result: `190 passed, 2 failed` (`feasibility-spikes`, `ops-postmortems`) — derived: `bash core/hooks/tests/run-board-gate-tests.sh` against `origin/main` in a scratch worktree — result: `159 passed, 2 failed`, same two names — identical failing-name set
- checked: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-scope-gate-tests.sh` — result: `92 passed, 0 failed` (was `91 passed, 1 failed` immediately after cherry-pick, before this round's fix — the one new failure was the pre-existing test asserting the now-closed gap, updated in this round's commit) vs `origin/main`'s `62 passed, 0 failed`
- checked: `env -u CLAUDE_PLUGIN_ROOT_CORE python3 -m pytest -q` — result: `3 failed, 79 passed` — derived: same command against `origin/main` in a scratch worktree — result: `3 failed, 79 passed`, same three names (`test_proposal_shape_gate_refuses_missing_sections`, `test_survey_order_gate_refuses_proposal_without_survey_or_skip`, `test_A5_trailer_gate_quote_split_commit_is_detected`) — identical failing-name set
- checked: `bash core/hooks/tests/run-fleet-scan-tests.sh` — result: `pass=26 fail=1` — derived: same command against `origin/main` in a scratch worktree — result: `pass=26 fail=1`, same case count, not quieter
- checked: 20-call interleaved timing of `board-gate.sh` against a `P=perl; $P -c ...` payload (the path this round's regex-derivation change actually touches) — after-fix: `real 0m1.025s` (~51.3ms/call) vs before-fix (`git stash`, same payload, same loop): `real 0m1.040s` (~52.0ms/call) — no overhead increase
- checked: `git diff origin/main -- . | grep -niE '\bqa\b'` restricted to added lines outside pre-existing salvaged test-fixture paths (`reports/qa/pwn.md`, present unchanged in PR #391's own cherry-picked test additions) — the one prose hit (`gate-lib.py`'s comment) is the fix described above; no new occurrence of the retired role axis as a code identifier
- checked: `python3 -c "import ast; ast.parse(open('warrant/hooks/lib/scope-gate.py').read())"` and the equivalent extraction+parse of `core/hooks/board-gate.sh`'s embedded python heredoc — both: no output (syntax OK)
