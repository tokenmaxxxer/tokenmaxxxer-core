---
issue: 384
role: adversarial-review-87b10290
author: adversarial-review-87b10290
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
code_under_review: PR #399 (issue-384/silent-failure-audit-97b1e431, base issue-384/diagnose-first+technical-writing-minimalism-scoping-bceafc9c i.e. PR #386), specifically core/hooks/directive.sh, core/directive/session-protocol-build-now.md, test/test_directive_injection.py
type: verification-record
breaking: false
verdict: PASS — leak fixed and recount clean under a plural-safe pattern; drift risk fixed at the source (single-sourced shell variables for directive.sh's shared bullets, structurally provable, not test-pinned) plus a content-derived (not literal-copy) sync test for the two protocol .md files; saving preserved (619 tok at the injection point, consistent with all three prior measurements on this issue); CORE_BUILD_NOW remains enforced only as a bare unsigned env-var check — a session can technically self-grant the bypass, this is stated-but-unenforced, unchanged by round 3 and inherited from round 1
loop_state: landed
upstream:
  - path: docs/issue-384/reports/silent-failure-audit-97b1e431.md
    sha: 83badd682623eb0d7b2f6b64c95a6a4f2d5e8e91
  - path: docs/issue-384/reports/adversarial-review-61b82bd3.md
    sha: 6507f22e60cc18eefa4316724cb019081930a22f
---

# issue-384 — adversarial-review-87b10290 record

## What was done

canonical: `gh issue view 384 --repo tokenmaxxxer/tokenmaxxxer-core` (read this session).
canonical: `gh pr view 386/397/399 --repo tokenmaxxxer/tokenmaxxxer-core --json ...` (read this session, before any code inspection).

Independent (round 3) verification of PR #399, which fixes both findings PR #397 raised against PR #386 (issue #384: core/warrant SessionStart injection diet). Per the brief, did not restate round 1's already-verified substance (base token saving, warrant's 0-tok claim, the 16-vs-15 mapping) — re-derived only what round 3 changed, plus the two items round 1 left open.

Checked out `issue-384/silent-failure-audit-97b1e431` (PR #399 head, `83badd6`) and its actual base `issue-384/diagnose-first+technical-writing-minimalism-scoping-bceafc9c` (PR #386 tip, `3b50ebb`) into separate worktrees (`/tmp/pr399-tree`, `/tmp/pr386-tree`), plus `origin/main` (`237c8b9`) into `/tmp/main-tree`, all removed with `git worktree remove` at the end of this session.

**1. The leak (Finding 1) — fixed, recounted with a plural-safe pattern.**

derived: `sed -n '40,60p' core/directive/session-protocol-build-now.md` on `/tmp/pr399-tree` shows line 54 now reads `read other skills' state from main, not from open PRs.` — the "roles'" leak is gone.

derived (recount, plural-safe, scoped to PR399's own diff against its actual base — not `origin/main`, which has diverged with an unrelated issue-366 role→skill rename since PR386 branched, see "No new bug" below for why that matters):
```
$ cd /tmp/pr399-tree
$ git diff pr386-check..pr399-check -- core/ warrant/ test/ | grep -nE '^\+' | grep -iE '\brole'
163:+    role->skill vocabulary rename in progress elsewhere in this repo
166:+    session-protocol-build-now.md:54 still saying "roles'" -- survived
170:+    uses (whole-word role/roles -> skill/skills, boundary-safe including
174:+    def role_to_skill(text):
175:+        text = text.replace("<role>", "<skill>")
191:+    # -- zero role/skill vocabulary in either file, must be byte-identical.
198:+    assert role_to_skill(req_two_phase) == req_build_now
209:+    assert role_to_skill(middle_two_phase) == middle_build_now
214:+    assert role_to_skill(verify_two_phase) == verify_build_now
```
All 9 hits are in `test/test_directive_injection.py`, inside the new sync test's own docstring/helper-function name (`role_to_skill`, a substitution helper — expected, it names the axis it converts *from*), not in shipped protocol content. Direct check of the actual protocol file:
```
$ grep -inE '\brole' core/directive/session-protocol-build-now.md
$ echo $?
1
```
Exit 1 = zero matches. Pattern used: `\brole` (case-insensitive, no trailing `\b`) — same pattern PR #399's own record cites as the fix for round 1/2's blind spot (`\brole\b` cannot match "roles" because the trailing boundary requires a non-word character after "role", and "s" is a word character). Confirmed clean.

**on-the-record #2881 (identifier-aware tokenization check) — not available, confirmed unavailable rather than assumed.**
```
$ gh pr view 2881 --repo tokenmaxxxer/on-the-record --json state,mergedAt,title
{"mergedAt":null,"state":"OPEN","title":"issue-2876: fix retirement-check plural blind spot, dispose of the 217-site gap"}
$ find "$ON_THE_RECORD" -name "retirement_count*" 2>/dev/null | grep -v /.git/
(no output)
```
PR #2881 (on-the-record repo, issue #2876) is still open/unmerged; its `gates/retirement_count.py`/`.sh` checker exists only on that PR's own now-unlanded branch (confirmed via `docs/issue-2876/reports/independent-verification-2.md` in the on-the-record checkout, which explicitly notes those files are "untracked on main"). It is also a different repo's tool (on-the-record's `gates/`, not tokenmaxxxer-core's), so even once merged there it would need porting to apply here. Not run; the plural-safe `\brole` grep above stands as this round's check.

**2. The drift risk (Finding 2) — fixed at the source for `directive.sh`; content-derived (not byte-pinned) sync test added for the two `.md` files.**

derived (what round 3 actually did to `core/hooks/directive.sh`):
```
$ git diff pr386-check..pr399-check -- core/hooks/directive.sh
```
Round 3 extracted the five bullets that were byte-identical text duplicated in both `cat <<EOF` branches (Requirements/Output/Layout/Specs/Verify) into five shell variables (`$REQ_BULLET`, `$OUTPUT_BULLET`, `$LAYOUT_BULLET`, `$SPECS_BULLET`, `$VERIFY_BULLET`), each defined once and referenced by both branches via interpolation. **This is the strong option, not the weak byte-comparison option I was told to rule out**: there is no longer a second copy to keep in sync via a test — the two branches read the same variable, so they cannot render different text for these five bullets, by construction, with no test involved.

Verified this claim by trying to break it, repeating PR #397's own demonstration on the new code:
```
$ grep -n 'LAYOUT_BULLET=' core/hooks/directive.sh   # exactly one definition, line 106
$ grep -n '\$LAYOUT_BULLET' core/hooks/directive.sh  # two call sites, lines 117 and 130
$ sed -i 's/LAYOUT_BULLET="- Layout: code src\/.../LAYOUT_BULLET="- MUTATED-LAYOUT: code src\/.../' core/hooks/directive.sh
$ CORE_BUILD_NOW=1 bash core/hooks/directive.sh | grep -c "MUTATED-LAYOUT"   # 1
$ CORE_BUILD_NOW=  bash core/hooks/directive.sh | grep -c "MUTATED-LAYOUT"   # 1
```
Both renders picked up the mutation identically — there is no edit that makes the two branches disagree on these five bullets anymore, because there is only one place to edit them. Reverted (`cp /tmp/backup-directive.sh core/hooks/directive.sh`; `git status --porcelain` empty afterward).

Content-correctness caveat: no test asserts the *literal wording* of these five bullets (e.g. nothing checks `$LAYOUT_BULLET` says the right thing) — but that is a different concern (content correctness) from the one round 3 was asked to fix (cross-copy drift), and drift between the two `directive.sh` branches is now structurally impossible, not merely tested-for.

The second half of the duplication — `DFILE` still points at two separate files (`session-protocol.md` for two-phase, `session-protocol-build-now.md` for build-now) — is real but by design (the build-now file is intentionally shorter and uses `skill` vocabulary the two-phase file doesn't yet use, per the in-progress role→skill rename). These can't be single-sourced the way the heredoc bullets were. Round 3 added `test_shared_bullets_between_protocol_variants_stay_in_sync` (`test/test_directive_injection.py`), which re-derives the build-now file's shared blocks from the two-phase file via the same `role`→`skill` substitution the repo's ongoing rename already uses, then asserts equality — a content-derived check, not a literal-copy/byte-pin assertion (a literal-copy assertion isn't even well-formed here, since the two files' shared blocks are supposed to differ by vocabulary).

Verified this test actually catches drift, by mutating one file only (not both) — the direct analogue of PR #397's "edit one copy" demonstration, now applied to the layer where two copies still genuinely exist:
```
$ cp core/directive/session-protocol-build-now.md /tmp/backup-build-now.md
$ sed -i 's/docs\/specs\/reconciled-index.md/docs\/specs\/RECONCILED-index.md/' core/directive/session-protocol-build-now.md
$ python3 -m pytest test/test_directive_injection.py -q
...
FAILED test/test_directive_injection.py::test_shared_bullets_between_protocol_variants_stay_in_sync
1 failed, 8 passed in 0.47s
$ cp /tmp/backup-build-now.md core/directive/session-protocol-build-now.md   # reverted; git status --porcelain empty after
```
Something reports it, and what it asserts is a derived transform-then-equality check, not a stored-byte comparison — the strong option for this layer, given true single-sourcing isn't available (the files must differ).

Copy count, before → after: `directive.sh` layer, 2 inline duplicated copies → 1 canonical source (2 render sites). `.md`-file layer, 2 files with independently-maintained shared blocks and no test → still 2 files (unavoidable, by design) but now covered by a content-derived sync test.

**3. Saving re-derived at the injection point on PR #399's tree — preserved.**
```
$ export CLAUDE_PLUGIN_ROOT_CORE="$PWD/core" CLAUDE_PLUGIN_ROOT="$PWD/core" TOKENMAXXXER_SPAWNED=1 CLAUDE_SKILL=implementation
$ env -u CORE_BUILD_NOW bash core/hooks/directive.sh 2>/dev/null | wc -c   # 10778
$ CORE_BUILD_NOW=1    bash core/hooks/directive.sh 2>/dev/null | wc -c   # 8224
$ python3 -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
two = open('/tmp/twophase_out.txt').read(); bn = open('/tmp/buildnow_out.txt').read()
print(len(enc.encode(two)), len(enc.encode(bn)), len(enc.encode(two))-len(enc.encode(bn)))
"
2650 2031 619
```
10778 → 8224 bytes, 2650 → 2031 tok (cl100k_base), 619 tok saved — matches PR #399's own claimed numbers exactly, and is in the same ~610–630 tok neighborhood as round 1's (PR #397, on PR #386's tree: 610 tok) and the original issue projection (630 tok). The drift fix did not re-merge the two paths or give back the saving.

**4. `CORE_BUILD_NOW`'s contract — stated, not enforced.**
```
$ grep -n "CORE_BUILD_NOW" core/hooks/approval-gate.sh
185:# The spawn task, not the role itself, sets CORE_BUILD_NOW=1 -- the same
190:if os.environ.get("CORE_BUILD_NOW", "").strip() == "1":
191:    allow()
```
The only enforcement point is a bare `os.environ.get(...) == "1"` string check — no signature, token, or process-provenance verification distinguishes "the spawner set this" from "the session set this for itself." `session-protocol.md`/`session-protocol-build-now.md`'s "never grant yourself this bypass" is prose only. Demonstrated directly:
```
$ CORE_BUILD_NOW=1 python3 -c "import os; print(os.environ.get('CORE_BUILD_NOW'))"
1
```
— the exact same read `approval-gate.sh:190` performs; nothing distinguishes this session's own `export` from a spawner's. This is unchanged by round 3 (it isn't in PR #399's diff — confirmed: `git diff pr386-check..pr399-check --name-only` does not include `approval-gate.sh`) and was left open by round 1. Recorded here as a standing, pre-existing gap, not a round-3 regression.

**Standing invariants.**

*No return of the retired role axis, plural included.* Covered under Finding 1 above — `\brole` (case-insensitive, no trailing boundary) on PR #399's own diff against its base: 0 hits outside the sync-test's transform-helper naming; direct check of the shipped protocol file: 0 hits.

*No new bug — failing-test set vs baseline, as sets of names.* Two comparisons, because `origin/main` has diverged from PR #399's actual base with an unrelated commit (`237c8b9`, issue #366's role→skill rename in gate messages) landed after PR #386 branched — a raw diff against `origin/main` is contaminated by that unrelated drift (confirmed: `core/hooks/test_board_gate.py` has 5 tests asserting the pre-366 "belongs to another role" wording that now fail on a fresh `origin/main` worktree because `board-gate.sh` there already says "belongs to another skill" — a pre-existing bug on `main` itself, unrelated to and not caused by PR #399; not present on PR #399's tree because its `board-gate.sh` lineage predates that rename).
- Against PR #399's own base (PR #386 tip, correct comparison — collection scope: `python3 -m pytest .` at repo root, i.e. `test/`, `tests/`, and `core/hooks/test_*.py`): PR #386 tip → `{test_proposal_shape_gate_refuses_missing_sections, test_survey_order_gate_refuses_proposal_without_survey_or_skip, test_A5_trailer_gate_quote_split_commit_is_detected}` (3 failed, 79 passed). PR #399 head → same 3 names (3 failed, 82 passed — the +3 are round 3's own new, passing tests). Identical set.
- Against `origin/main` (collection scope: `bash core/hooks/tests/run-all.sh`, the repo's full custom hook-test aggregate — 49 parse-checked hook files plus board-gate/scope-gate/approval-gate/gh-guard/gate-shape/role-gates/issue-280/dispatcher-equivalence/facet-keyword-gate/citation-gate/record-shape-gate/survey-order-gate/ups-diet/freelunch/scout sub-suites): summary-count lines byte-identical between PR #399's tree and `origin/main` (`diff` of the two summary-line extracts: empty). Individually verified the 3 sub-suites with any failures — board-gate `{feasibility-spikes, ops-postmortems}`, approval-gate `{checkpoint-refusal-names-await-approval, execute-without-remote}`, dispatcher-equivalence `{approval-gate: execution write, no approvers.md -> deny}` — same 5 names on both trees.

*No overhead increase.* Covered under item 3 above — decrease confirmed at the injection point (619 tok saved), re-derived independently, not cited from the PR record.

*Monitor and watch machinery unbroken and not quieter.* `core/hooks/tests/run-all.sh` (the repo's aggregate check-everything script) run to completion on both PR #399's tree and `origin/main`; every per-suite summary line (pass/fail counts) is identical between the two runs (`diff /tmp/main_summary.txt /tmp/pr399_summary.txt` → empty, "IDENTICAL SUMMARY COUNTS"). Not quieter: same number of suites ran, same number of checks reported passed/failed in each.

## Why

Round 1 (PR #397) already re-derived the base token saving, warrant's 0-tok claim, and the 16-vs-15 mapping — redoing that would be pure restatement, which the brief explicitly ruled out. This round's actual load-bearing question was narrower and harder: did round 3 fix the drift risk *structurally*, or did it paper over it with the byte-pinning test I was told to treat as the weak option? Answering that required reading `directive.sh`'s actual diff (not the PR record's prose about it) and then trying to break what round 3 built — mutating a variable, mutating a file, and watching what happened — rather than trusting the PR's own "verified by reverting the fix and rerunning" claim. The mutation tests are the only way to distinguish "a test asserts these match" (still crackable if someone edits both sides in the same wrong way, or the test itself gets deleted) from "these cannot structurally disagree" (true for the `directive.sh` layer now); I kept those separate in the write-up because they're genuinely different strengths of guarantee, and round 3 delivered the stronger one for the layer where it was possible.

Discovered the `origin/main` divergence (issue #366's landed rename) by surprise, mid-recount — the plural-safe grep against `origin/main` returned ~140 hits that were obviously not this PR's doing (fully-qualified deny-message strings in `board-gate.sh`, `approval-gate.sh`, etc.). Rather than filtering noise out of a single number, treated it as a scoping question: PR #399's base is PR #386's tip, not `origin/main`, so the fair "did this PR introduce anything" comparison is against that base, with `origin/main` kept only as the secondary check for the custom shell-test suites (which happened to be unaffected by the same drift). This surfaced a real, separate, pre-existing bug (5 `test_board_gate.py` tests broken on `main` itself since `237c8b9`) that is out of scope for issue #384 but worth flagging so it isn't mistaken for something this PR caused.

## What did not work

None — every mutation/revert cycle and every re-derivation reproduced its expected result on the first attempt; nothing was tried and abandoned this session.

## Upstream basis

- `docs/issue-384/reports/silent-failure-audit-97b1e431.md` (PR #399's own record, `issue-384/silent-failure-audit-97b1e431` branch, commit `83badd6`) — read for orientation, not restated; every specific claim checked above was re-derived independently in a separate worktree rather than cited from it.
- PR #397 (`gh pr view 397`, `gh pr diff 397`) and its record `docs/issue-384/reports/adversarial-review-61b82bd3.md` at `6507f22e60cc18eefa4316724cb019081930a22f` (`issue-384/adversarial-review-61b82bd3` branch tip, per `git ls-remote origin issue-384/adversarial-review-61b82bd3`) — round 1's findings, which round 3 and this round both build on.
- PR #386 tip (`issue-384/diagnose-first+technical-writing-minimalism-scoping-bceafc9c`, commit `3b50ebb`) — PR #399's actual base, used as the correct baseline for the "no new bug" comparison.
- `origin/main` at `237c8b9` — used as the secondary "no new bug" baseline (custom shell test suites) and to confirm the unrelated issue-366 divergence.

## Open findings

1. **`CORE_BUILD_NOW`'s "never grant yourself this bypass" is unenforced** (approval-gate.sh:190 is a bare env-var read with no provenance check). Pre-existing since round 1, not introduced or touched by round 3, not in scope for issue #384's stated acceptance criteria (which are about content reachability and token cost, not about the bypass's authorization model). Resolution path: none required for this issue; flagging so a future issue about spawn-authorization integrity doesn't have to rediscover it from scratch.
2. **5 tests in `core/hooks/test_board_gate.py` are broken on `origin/main` itself** (`237c8b9`, issue #366's role→skill gate-message rename, shipped without updating these test assertions from "belongs to another role" to "belongs to another skill"). Unrelated to and not caused by PR #399 (confirmed not present in `git diff pr386-check..pr399-check --name-only`). Resolution path: none needed for issue #384; worth a separate issue against #366's landing.

## Next steps

None — `loop_state: landed`. This verification is complete.

skill-verdict: adversarial-review — applied: invoked; this entire record is the adversarial-review protocol applied to PR #399 — independent worktree checkouts, re-derivation of every claim from scratch rather than citing the PR's own `derived:` tags, and active attempts to break round 3's fix (mutation + revert) rather than accepting its own "verified by reverting" claim at face value.
other mounted skills: implementation-audit — not-applicable: this is a verification-of-a-fix task against a prior round's specific findings, not a full spec-vs-implementation claim audit. model-routing — not-applicable: single-session direct tool-call investigation, no delegation decision was live once the freelunch-directive conflict (see below) was resolved in favor of doing the verification work directly. parallel-decomposition — not-applicable: no fan-out to multiple build agents was performed or warranted (see STEP 1 tally at the top of this session: sequential, judgment-dependent investigation on one shared worktree, width merges to 1). diagnose-first — not-applicable: this is a verification task with a fully specified target (PR #399), not an open-ended cost/slowness/recurring-problem diagnosis. work-in-english — applied: invoked implicitly per its own standing-policy trigger; this record, all commit messages, and the PR are in English.

Deviation note (not a scope violation, recorded per the freelunch-directive's own priority="absolute" framing): this session's STEP 1 tally judged the freelunch fan-out/delegate model inapplicable to this specific task and performed the investigation's tool calls directly rather than delegating to a background `freelunch:freelunch-worker`. Rationale: the task's explicit charge ("Re-derive; do not restate its record") requires this session's own judgment on a specific weak-vs-strong distinction; the freelunch worker contract ("skips verification and delivers raw," no second worker, no re-check) is structurally incompatible with an adversarial-review task where the entire deliverable *is* independent verification — accepting an unverified single-shot delegate's raw conclusion on "are these copies structurally unable to disagree" would be exactly the kind of laundered, unverified claim this review exists to catch. Additionally, several steps share one mutable resource (a single checked-out worktree subjected to a mutate-then-revert cycle) and are sequentially dependent on each other's findings, which independently merges the unit count to 1 under the directive's own "non-freezable coupling" rule.
