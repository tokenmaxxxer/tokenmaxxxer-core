---
issue: 336
role: conformance-review
author: conformance-review
loop_state: landed
upstream:
  - path: PR #337 (issue-336/silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546), commit fc850d6970af9ef8598d27cbe8d3388e678509c5
    sha: fc850d6970af9ef8598d27cbe8d3388e678509c5
subject: PR #337 (merged to main), commit fc850d6970af9ef8598d27cbe8d3388e678509c5
test: python3 -m pytest core/hooks/test_board_gate.py -q (issue #336's own named acceptance checks, reused) plus independent live board-gate.sh invocations against fresh fixtures
result: passed
assertedBy: issue-336/conformance-review
---

# issue-336 — conformance-review record

## What was done

Builder-blind conformance review of merged PR #337 (`core/hooks/board-gate.sh:638`'s `own_hits` extraction regex, widened from `[\w./-]*` to `[\w.+/-]*`). Reviewed against `main`'s HEAD (fc850d69, not the implementer's own claims): re-ran the named test file, then independently reproduced all three of #336's named acceptance commands from a fresh, disposable git fixture on a `+`-bearing branch (`issue-336/skillA+skillB-deadbeef01`), driving `board-gate.sh` directly with `CLAUDE_ROLE` set — not through `pytest`, mirroring `test_board_gate.py`'s own `board()`/`run_gate()` fixture shape. Also read `skills.py::skill_branch_slug()` in `$ON_THE_RECORD` to confirm the `+`-join premise, diffed the pre-fix and post-fix regex to confirm the R5 owner comparison (`tail[0] == role`) was untouched, and checked the pre-existing fixture set in `test_board_gate.py` to confirm the new "path shape not in fixture set" test is a genuinely new shape. 7 requirements extracted from the Acceptance section; all 7 Present. No Absent or Incorrect findings.

## Why

CORE_BUILD_NOW=1 was set by the spawning environment (build-now bypass, contract v3 s19a) — the proposal/survey/scout round is skipped by that bypass, not by this session's own choice; this record is delivered directly per the bypass instruction. Separately, the scout-directive's own mandatory skip condition also applies on its merits: issue #336's Acceptance section is four fixed, already-fully-specified checks against already-landed code (PR #337, already reviewed and merged) — there is no open design decision for a scout pass to steer, only verification of claims already made. Full enumeration (all 4 Acceptance bullets, split into 7 checkable requirements per rule 1) was used rather than a derived sample, because the population is 4 fixed bullets, not a corpus large enough to need sampling.

**R-1/R-2/R-3** (own `+`-bearing record writable): the issue's Ask section names three exact commands (`mkdir -p`, `git add <file>`, `git add <dir>/`) bundled under one Acceptance bullet ("can write, stage and commit its own record directory") — split per requirement-extraction rule 1 into one line item per command, since a bundled line would let a partial fix (e.g. `mkdir` fixed but `git add` still broken) score as one Present instead of surfacing the gap.

**R-6** is kept as its own line item (rule 5) rather than folded into R-5, because its applicability is explicitly conditional on R-5's own text ("applied to at least one path shape not in the fixture set" only makes sense once R-5's disposition exists to apply).

**R-7** (must-not) is extracted as its own scope-boundary requirement even though it has no dedicated "check:" bullet, because the issue's Acceptance section states it as a binding constraint on the same fix ("must not: do not widen... Do not relax... Do not special-case `+`") — dropping it would leave the review silent on the constraint the issue considered most likely to be violated by a careless fix.

`skill-verdict: conformance-review-requirement-extraction — applied: invoked; split the bundled "write, stage and commit" acceptance bullet into R-1/R-2/R-3 (rule 1), kept R-6 as its own item stating its dependency on R-5 (rule 5), extracted the "must not" paragraph as R-7 (a scope-boundary requirement, rule 6) rather than treating it as unactionable prose, and dimension-tagged all 7`
`skill-verdict: conformance-review-verification-method-selection — applied: invoked; Test (reuse of the 4 new `test_multiskill_*` cases in `core/hooks/test_board_gate.py`, rule 4) plus independent Demonstration (live `board-gate.sh` invocations against a fresh git fixture, rule 3) for R-1/R-2/R-3/R-4; Inspection (structural comparison of the stated character-set disposition against the actual regex at board-gate.sh:638, rule 1) for R-5; Test (the pre-existing new fixture-outside test, rule 4) for R-6; Analysis (diffing pre-fix vs. post-fix code to confirm the owner comparison and character-class monotonicity, rule 2 — this is not something a demonstration run can establish, since a smuggling attempt not thought of by either the fixer or the reviewer would not show up in any specific test run) for R-7`

## What did not work

None.

## Upstream basis

PR #337 (branch `issue-336/silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546`), commit `fc850d6970af9ef8598d27cbe8d3388e678509c5`, merged to `main`. Implementer's own record: `docs/issue-336/reports/silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546.md` (sha: same as above — landed in the same commit).

## Requirement verdicts

**R-1** (functional) — a `+`-bearing session can `mkdir -p` its own record directory without refusal.
- verdict: Present
- evidence: `test_multiskill_mkdir_own_record_dir_allowed` in `core/hooks/test_board_gate.py` (part of `python3 -m pytest core/hooks/test_board_gate.py -q` → `18 passed`, re-run live). Independently reproduced: `CLAUDE_ROLE="skillA+skillB-deadbeef01" bash core/hooks/board-gate.sh` fed `{"tool_name":"Bash","tool_input":{"command":"mkdir -p \"docs/issue-336/reports/skillA+skillB-deadbeef01\""}}` from a fresh git fixture on branch `issue-336/skillA+skillB-deadbeef01` → `rc=0`, no output.

**R-2** (functional) — a `+`-bearing session can `git add` a file inside its own record directory without refusal.
- verdict: Present
- evidence: `test_multiskill_git_add_own_record_file_allowed`. Independently reproduced: same fixture, `git add "docs/issue-336/reports/skillA+skillB-deadbeef01/x.md"` → `rc=0`.

**R-3** (functional) — a `+`-bearing session can `git add` its own record directory (trailing slash) without refusal.
- verdict: Present
- evidence: `test_multiskill_git_add_own_record_dir_allowed`. Independently reproduced: `git add docs/issue-336/reports/skillA+skillB-deadbeef01/` → `rc=0`.

**R-4** (error-handling / scope-boundary) — a genuinely foreign `+`-bearing record is still refused, with today's message.
- verdict: Present
- evidence: `test_multiskill_foreign_record_still_denied` asserts `rc == 2` and `"belongs to another role" in err`. Independently reproduced from the same `skillA+skillB-deadbeef01` fixture against a different role's directory (`otherSkillX+otherSkillY-cafebeef02`): `git add docs/issue-336/reports/otherSkillX+otherSkillY-cafebeef02/` → `rc=2`, message `board-gate: docs/issue-336/reports/otherSkillX+otherSkillY-cafebeef02 belongs to another role. skillA+skillB-deadbeef01 writes only skillA+skillB-deadbeef01.md, skillA+skillB-deadbeef01/** — never a foreign record. (contract v3 s11)` — same message shape as pre-fix.

**R-5** (scope-boundary / documentation) — the extractor's accepted character set is stated in the record, with reasoning for its bound.
- verdict: Present
- evidence: implementer's record, `## Disposition: accepted character set (issue-336 acceptance bullet 3)` — states the post-fix trailing class as `[\w.+/-]` and gives a per-character justification (`\w`/`-` = existing path/name chars, `.` = extensions, `/` = separators, `+` = the `skill_branch_slug()` join char). Cross-checked against `core/hooks/board-gate.sh:638` live: `re.findall(r"[\w./~$:-]*%s[\w.+/-]*" % re.escape(DOCS), target)` — the stated set matches the actual trailing class exactly, character for character.

**R-6** (edge-case, dependent on R-5) — the R-5 disposition is applied to at least one path shape not in the pre-existing fixture set.
- verdict: Present
- evidence: `test_multiskill_path_shape_not_in_fixture_set` — a plain redirect (`echo ... > docs/issue-336/reports/<multiskill-role>.md`, not `mkdir`/`git add`) writing a `+`-bearing slug's record `.md` file directly, `rc=0`. Checked this is genuinely a new shape, not a relabeled old one: the pre-existing fixture set (`git show 62c7005^:core/hooks/test_board_gate.py`) already had a plain-redirect-to-own-`.md` test (`test_plain_redirect_write_outside_write_set_still_denied` family, e.g. `echo hi > docs/issue-198/reports/verify.md`), but none of those pre-existing plain-redirect cases used a `+`-bearing role — the specific combination (plain redirect × `+`-bearing own slug) did not exist before this PR.

**R-7** (must-not / scope-boundary) — the extractor is not widened beyond capturing more of the path (no smuggling enabled), the `tail[0] == role` owner comparison is not relaxed, and `+` is not special-cased.
- verdict: Present
- evidence: `git diff 62c7005^ fc850d6 -- core/hooks/board-gate.sh` — the only functional change is the trailing character class gaining the single literal `+` (`[\w./-]*` → `[\w.+/-]*`); the `tail[0] == role` comparison line does not appear in the diff at all, i.e. is byte-for-byte unchanged. Not a special case: the change is a class-widening (one more character accepted anywhere the class already matched), not an `if char == '+'` branch — confirmed by reading the diff context, which shows no conditional logic added, only the character-class literal. Smuggling check: none of the shell metacharacters that could redirect a match to an attacker-controlled path (`;`, `|`, backtick, `$(`) are in the class before or after the change, so the widening cannot let a foreign write masquerade as an own-record write. `run-board-gate-tests.sh` (143/145, 2 pre-existing unrelated failures reproduced identically on unpatched HEAD) and `test_board_gate.py`'s 12 pre-existing cases passing unchanged corroborate that the widening is a pure superset for every previously-accepted shape.

## Open findings

None — all 7 extracted requirements verdicted Present; no Absent, Incorrect, Surface, or Unverifiable findings. (The implementer's own record separately flags an out-of-scope `_cross_bm` character-class gap at `board-gate.sh:846` and the unresolved #335 investigation as open items in *its* Open findings — both are outside this issue's Acceptance criteria and are not re-litigated here; spot-checked live that `_cross_bm = re.match(r"^issue-([0-9]+)/([\w-]+)$", branch)` at line 846 does still lack `+`, confirming the claim is accurate as stated, without treating it as an #336 defect since #336's Acceptance criteria do not name that code path.)

## Next steps

None — `loop_state: landed`.

skill-verdict: conformance-review-requirement-extraction — applied: invoked; see Why
skill-verdict: conformance-review-verification-method-selection — applied: invoked; see Why
skill-verdict: work-in-english — applied: invoked; all repository-bound content in this record (frontmatter, prose, commit message) written in English; this final chat response is in Korean per the user's own language
