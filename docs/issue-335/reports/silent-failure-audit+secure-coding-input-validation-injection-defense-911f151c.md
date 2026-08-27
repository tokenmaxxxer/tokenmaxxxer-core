---
issue: 335
role: silent-failure-audit+secure-coding-input-validation-injection-defense-911f151c
author: silent-failure-audit+secure-coding-input-validation-injection-defense-911f151c
skills: silent-failure-audit (skill-repository(297e350)), secure-coding-input-validation-injection-defense (skill-repository(297e350))
loop_state: landed
upstream:
  - path: N/A — CORE_BUILD_NOW=1 build-now bypass (contract v3 s19a); no phase-1 proposal doc exists for this delivery
    sha: same-commit
code_under_review:
  - core/hooks/board-gate.sh
  - core/hooks/test_board_gate.py
type: bugfix
breaking: "no caller-visible behavior change for any legitimate write. The only segments that newly classify as read-only are ones whose resolved head is exactly `for`, `select`, or `case` AND that carry no subshell/redirect of their own (checked, unchanged, before this new check runs) — a shape that could previously only ever be denied by accident (a docs/-shaped literal sitting in a word list it never writes to), never as a correct positive. Every segment that was previously and correctly denied (a real `>`/subshell, or a write-capable head) is denied identically — verified live below, and by the full pre-existing test_board_gate.py/run-board-gate-tests.sh suites passing unchanged."
verdict: "pass — issue-335's three acceptance checks verified live below against the real recovered repro from the issue's correcting comment (not the issue body's own paraphrase, which the comment states could not reproduce the defect): a read-only for-loop over a word list naming a foreign docs/issue-100/ path now passes; a genuine write to that same directory is still refused with byte-identical message text before and after this change; and the disposition (which command heads are treated as non-executing list syntax, and why) is stated below, applied to a `case` shape not named in the issue's own repro."
---

# issue-335 — silent-failure-audit+secure-coding-input-validation-injection-defense-911f151c record

## What was done

Read `gh issue view 335` and its comment 0 first, per the spawn instruction — the comment corrects the issue body's own repro (`ls docs/issue-100/reports/`; `git log --oneline -1 -- docs/issue-100/reports/coding.md`), stating that pair was the reporter's paraphrase from memory and that PR #337's session correctly found it passes on current HEAD. The comment supplies the real command, recovered verbatim from the killed session's log, and its exact refusal text.

Traced `core/hooks/board-gate.sh`'s Python judge (the inline `CORE_BOARD_GATE` heredoc) by hand against that real command, then confirmed the trace live. The command's fourth line is a multi-line `for` loop:

```bash
for f in gates/spawn_on_pr.py gates/merge_gate.py gates/skip_eligibility.py board.py skills.py docs/specs/record-kind-vocabulary.md docs/issue-100/reports/coding.md docs/decisions/2026-08-25-retire-role-axis-staging.md docs/decisions/2026-08-21-single-skill-axis.md on-the-record/directive/spawn-and-board.md; do
  n=$(git log --oneline -- "$f" | wc -l)
  echo "$f : $n commits"
done
```

`_split_segments` cuts this on the `;` before `do`, so the for-header (`for f in gates/... on-the-record/directive/spawn-and-board.md`) is its own segment, separate from the loop body. `_segment_is_failing` (board-gate.sh, pre-fix) resolves that segment's head to `"for"` via `gate_lib.gate_head_of` — not `"git"`, not in `READ_ONLY_HEADS`, not in `READ_UNLESS_INPLACE` — so it fell through to the function's own catch-all `return True`, i.e. "unproven, treat as a write candidate." Because the segment was marked failing, the code a few lines below scans its raw text for `docs/`-shaped substrings (`own_hits`) and adds every one it finds as a write-target candidate — including `docs/issue-100/reports/coding.md`, which appears only as one item in the word list, never as an argument to anything that runs. That candidate then reaches R4 (branch check) and is denied with the exact message shape the issue reports: "requires branch issue-100/... (current: issue-2593/...)". The loop body's own two statements (`n=$(git log --oneline -- "$f" | wc -l)`, `echo "$f : $n commits"`) are separately classified on their own segments and are correctly read-only regardless of this bug — the false positive is entirely in the for-header segment, not the body.

Fixed by adding a `NONEXECUTING_LIST_HEADS` set and one check in `_segment_is_failing` (`core/hooks/board-gate.sh:349-351`):

```python
    head = gate_lib.gate_head_of(stripped)
    if head in NONEXECUTING_LIST_HEADS:
        return False
    if head == "git":
```

`NONEXECUTING_LIST_HEADS = ("for", "select", "case")` (`core/hooks/board-gate.sh:241`). This check runs only after the existing `SUBSHELL.search(seg) or gate_lib.gate_outside_quotes(seg, FILE_REDIR.pattern)` check earlier in the same function, which is unchanged and still runs first and unconditionally — a `for`/`select`/`case` header embedding a `$(...)` or an outside-quotes `>` still fails exactly as before.

Added 5 tests to `core/hooks/test_board_gate.py`: the real repro shape (`test_forloop_wordlist_over_foreign_paths_passes`), a regression guard that a literal write inside the loop BODY (not the for-header) is still denied (`test_forloop_body_literal_write_still_denied`), the same rule demonstrated on `case` — a head not in `READ_ONLY_HEADS` and not the shape the issue itself named (`test_case_dispatch_mentioning_foreign_issue_passes`) — and a matching regression guard for a write inside a `case` arm (`test_case_arm_literal_write_still_denied`).

## Why

**Why `for`/`select`/`case` and not a broader keyword set, and why this is not the "allow-list of command names" the issue's must-not forbids.** These three are shell reserved words whose own header/dispatch text cannot execute a program: `for VAR in <word-list>` and `select VAR in <word-list>` only ever enumerate words (unless one contains a `$(...)`, which the pre-existing SUBSHELL check still catches before this one runs), and `case WORD in` only names the value being switched on. None of the three is a command name a real write could impersonate — a session cannot substitute a program called `for` for the keyword `for`; secure-coding-input-validation-injection-defense rule 1/2 ("validate with an allowlist that defines exactly what IS authorized," "do not special-case the one input that broke") is satisfied here because this narrows to what is grammatically incapable of writing, not to a set of trusted verbs.

**Why `do`/`then`/`else`/`elif` are deliberately excluded.** Bash lets the actual command that runs follow one of these directly in the same segment, separated only by a space, not by `;`/`|`/`&&`/newline: `do rm -rf docs/x`, `then echo bad > docs/x`. `gate_head_of` resolves only the first word of a segment, so treating `do`/`then`/`else`/`elif` as always-safe would read the keyword and never see the real command sitting right after it in the same segment — a genuine bypass. `for`/`select`/`case` do not have this shape: nothing can follow "for VAR in" or "case WORD in" in the same segment except more word-list/switch-value text, because bash's own grammar requires a separator (`;`/newline/`do`) before the body begins, and that separator is exactly where `_split_segments` already cuts.

**Residual limitation, not introduced by this fix.** I checked whether this change opens a write-via-loop-variable hole, e.g. `for f in docs/issue-100/x; do rm -f "$f"; done`. It does not newly open one: the loop body segment `rm -f "$f"` carries no literal `docs/` substring of its own (only the variable `$f` does), so `own_hits` was already blind to it — this is true with or without the for-header fix, and true for a plain assignment too (`x=1; use "$x"` is equally invisible once the write target is a variable, not a literal path). The pre-fix behavior only "caught" this specific for-loop shape by accident, because the for-header segment happened to carry the literal path text and was mis-flagged as a write itself — not because the actual `rm` was analyzed. Recorded as an Open finding below rather than silently left, per the silent-failure-audit evidence bar (state what is and is not covered, rather than imply broader coverage than what was checked).

## Upstream basis

N/A — CORE_BUILD_NOW=1 build-now bypass (contract v3 s19a): the spawning prompt authorized delivery-only, so this record is the only upstream basis; no phase-1 proposal document exists for this issue. Builds on the prior investigation in `docs/issue-336/reports/silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546.md` (same repo, PR #337, merged), which investigated #335 against the issue body's own (since-corrected) repro and could not reproduce it — that record's own "Open findings" flagged the report as unresolved and asked for the full command history rather than the minimal repro; the issue's comment 0 supplied exactly that.

## Open findings

1. **Write-via-loop-variable remains undetected when the write's own segment carries no literal `docs/` text.** `for f in docs/issue-100/x; do rm -f "$f"; done` is allowed by this gate today, with or without this fix (see Why). This is a general, pre-existing limitation of this gate's design — a static text scanner that greps for literal `docs/`-shaped substrings, not a shell interpreter with variable tracking — not a regression this fix introduces. Not fixed this round: closing it in general would require tracking a shell variable's possible values across segments, a materially larger change than this issue's acceptance criteria ask for, and risks the same "if it cannot be classified safely, refuse it" must-not being violated by an incomplete heuristic. Flagged here rather than left for the next session to rediscover.

## Next steps

None — `loop_state: landed`.

## What did not work

None.

## Disposition: read-vs-write classification, `for`/`select`/`case` addendum (issue-335 acceptance bullet 3)

Per the acceptance bullet's requirement to state the disposition list with the rule applied to at least one command not in it: `core/hooks/board-gate.sh`'s `_segment_is_failing` now treats a segment as read-only (not a write candidate) when its resolved head is in `READ_ONLY_HEADS`, or `git` with a subcommand in `GIT_READ_SUBCOMMANDS`, or in `READ_UNLESS_INPLACE` with no in-place/write mechanism triggered, or — the addition here — exactly `for`, `select`, or `case` (`NONEXECUTING_LIST_HEADS`, `core/hooks/board-gate.sh:241`) with no subshell/redirect of its own. Applied to a command shape not named anywhere in the issue's own repro: `case docs/issue-651/reports/x.md in` (a `case` dispatch on a literal foreign path, not a `for` loop) is classified read-only by the same rule — pinned live as `test_case_dispatch_mentioning_foreign_issue_passes`. The `must not` still holds: `do`/`then`/`else`/`elif` are excluded from this set for the reason in Why, and a write embedded in a `for`/`case` header via `$(...)` or `>` is caught by the pre-existing, unmoved SUBSHELL/FILE_REDIR check that runs before this one.

## How you will know it worked

**Acceptance bullet 1** (a read-only command naming a `docs/issue-<n>/` path is not refused) — the real recovered repro from the issue's comment 0, run against this repo's own live `core/hooks/board-gate.sh` from this session's actual branch (`issue-335/silent-failure-audit+secure-coding-input-validation-injection-defense-911f151c`, not `issue-100/...`), with `CLAUDE_ROLE` set to this session's own role:
- checked: `git show HEAD:core/hooks/board-gate.sh` (pre-fix) fed the exact recovered command → `rc=2`, `board-gate: writing docs/issue-100/ requires branch issue-100/silent-failure-audit+secure-coding-input-validation-injection-defense-911f151c (current: issue-335/silent-failure-audit+secure-coding-input-validation-injection-defense-911f151c), and issue #335's body declares no matching \`maintenance-targets:\` entry for issue-100. ...` — result: reproduces the issue's exact refusal shape live, on this repo's own current HEAD, confirming the defect is real and not already fixed by #337.
- checked: the working-tree `core/hooks/board-gate.sh` (post-fix) fed the identical command and payload → `rc=0`, no output — result: passes.
- derived: `python3 -m pytest core/hooks/test_board_gate.py -q -k "forloop_wordlist_over_foreign_paths or case_dispatch_mentioning_foreign"` — result: 2 passed.

**Acceptance bullet 2** (a genuine write to another issue's record directory is still refused, with the same message it gives today) —
- checked: `echo overwritten > docs/issue-100/reports/coding.md`, fed to both the pre-fix (`git show HEAD:...`) and post-fix `board-gate.sh`, same branch/role as above — both return `rc=2` with byte-identical stderr: `board-gate: writing docs/issue-100/ requires branch issue-100/silent-failure-audit+secure-coding-input-validation-injection-defense-911f151c (current: issue-335/silent-failure-audit+secure-coding-input-validation-injection-defense-911f151c), and issue #335's body declares no matching \`maintenance-targets:\` entry for issue-100. Every role output reaches main only through a PR the human merges — never a direct write from another branch. (contract v3 s10)` — result: identical before and after.
- derived: `python3 -m pytest core/hooks/test_board_gate.py -q -k "forloop_body_literal_write_still_denied or case_arm_literal_write_still_denied"` — result: 2 passed.

**Acceptance bullet 3** (disposition list, applied to a command not in it) — see the Disposition section above.

**Regression check** —
- derived: `python3 -m pytest core/hooks/test_board_gate.py -q` — result: 22 passed (17 pre-existing + 5 new above).
- derived: `bash core/hooks/tests/run-board-gate-tests.sh` — result: 143 passed, 2 failed (`feasibility-spikes`, `ops-postmortems`); confirmed pre-existing and unrelated via `git stash` against unpatched HEAD — result: identical 143 passed, 2 failed, same two names.
- derived: `bash core/hooks/tests/run-gate-lib-tests.sh` — result: 64 passed, 2 failed (`record-fields-gate.sh` missing-fields / kill-switch cases, a different gate file this change does not touch); confirmed pre-existing via `git stash` against unpatched HEAD — result: identical 64 passed, 2 failed.

skill-verdict: silent-failure-audit — applied: invoked; used the skill's evidence bar (a concrete file:line trace from cause to effect, not an inference from the regex) to hand-trace `_segment_is_failing`'s catch-all `return True` as the actual silent-misclassification path before writing any fix, and to state explicitly, in Open findings, what the fix does and does not cover (write-via-loop-variable) rather than implying broader coverage.
skill-verdict: secure-coding-input-validation-injection-defense — applied: invoked; the fix widens `_segment_is_failing`'s read-only classification by a bounded allowlist of shell reserved words (rule 1) rather than by command name or a denylist patch for the one reported command (rule 2) — see Why for why `for`/`select`/`case` are safe as a class while `do`/`then`/`else`/`elif` are excluded from it.
