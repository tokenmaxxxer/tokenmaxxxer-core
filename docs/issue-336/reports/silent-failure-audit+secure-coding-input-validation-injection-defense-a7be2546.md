---
issue: 336
role: silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546
author: silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546
skills: silent-failure-audit (skill-repository(297e350)), secure-coding-input-validation-injection-defense (skill-repository(297e350))
loop_state: landed
upstream:
  - path: N/A — CORE_BUILD_NOW=1 build-now bypass (contract v3 s19a); no phase-1 proposal doc exists for this delivery
    sha: same-commit
code_under_review:
  - core/hooks/board-gate.sh
  - core/hooks/test_board_gate.py
  - docs/handbooks/board-gate-tests.md
type: bugfix
breaking: "no caller-visible behavior change for any legitimate write. The own_hits character class only ever gained one character (`+`); every path tail it matched before this change still matches identically (superset widening, verified by the full pre-existing `run-board-gate-tests.sh` suite passing unchanged — 143/145, the 2 pre-existing failures reproduced identically before and after this diff, see Open findings). The only behavior change is that a `+`-bearing own-record write, previously denied, is now allowed — the intended fix, not a break. The R5 owner comparison (`tail[0] == role`) itself is untouched."
verdict: "pass — #336's three acceptance checks verified live below (own `+`-bearing record writable; foreign record still denied; accepted character set + its bound stated in this record and exercised against a path shape outside the fixture set). #335 investigated per the issue's explicit joint-root question: its exact reported repro (the two named commands) already passes on current HEAD with no code change — documented below with live verification, not asserted from the regex."
---

# issue-336 — silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546 record

## What was done

Read both tokenmaxxxer-core#336 and #335 first, per the assignment, to check for a shared root before writing any code.

**#336 (code fix).** `core/hooks/board-gate.sh:638`'s `own_hits` extraction regex had its trailing character class widened from `[\w./-]*` to `[\w.+/-]*` — a pure superset addition of the literal `+` character, nothing removed. Since #2572 made `--skills` the sole spawn form, every session's role/slug is composed by the on-the-record plugin's `skills.py::skill_branch_slug()`, which joins skill directory names with `+` (confirmed live: `grep -n "def skill_branch_slug" -A10 "$ON_THE_RECORD/skills.py"` shows `"+".join(...)`). The old trailing class stopped matching at the first `+`, so a docs/ path under a multi-skill session's own record subtree (`docs/issue-<n>/reports/<skill>+<skill>-<hex>/...`) was captured only up to that first `+`. R5's owner check at board-gate.sh:1013 (`tail[0] == role`), which is correct and untouched, then compared that truncated prefix against the session's full `CLAUDE_ROLE` string and denied — the session's own record, misread as belonging to a different (nonexistent) role.

**#335 (investigated, no code change).** Reproduced the issue's own exact two commands (`ls docs/issue-100/reports/` and `git log --oneline -1 -- docs/issue-100/reports/coding.md`, both individually and joined with `;` exactly as quoted in the issue body) against current HEAD's `board-gate.sh`, from a branch not named `issue-100/...`, with `CLAUDE_ROLE` set to a multi-skill (`+`-bearing) role matching the issue's own quoted role fragment. All variants returned rc=0 (allow) with no gate output — see "How you will know it worked" for the exact harness and output. `git log -- core/hooks/board-gate.sh --since=2026-08-20` shows no commit between the issue's "observed live 2026-08-27" timestamp and this HEAD that touches read/write classification, so this is not a same-day fix landing out from under the report; the classification of `ls`/`git log` as read-only heads (`READ_ONLY_HEADS`, `GIT_READ_SUBCOMMANDS`) already existed pre-issue. I could not reproduce the reported misclassification with the exact commands the issue names, so no code change was made for #335 — see "Why" for the disposition this leaves for the record's own acceptance bullet, and Open findings for what remains unresolved.

## Why

**One fix does not cover both — they are not the same defect**, confirming the issue's own framing: #336 is about what the `own_hits` extractor *captures* (a character-class gap that truncates a legitimate path), #335 is about how an already-fully-captured, already-correctly-parsed command is *classified* (read vs. write). The #336 fix touches only the trailing character class in the extraction regex; it does not touch `_segment_is_failing`, `READ_ONLY_HEADS`, or `GIT_READ_SUBCOMMANDS` — the classification machinery #335 is about. Conversely, nothing in the classification path needed a `+`-related change: `_git_subcommand`/`gate_head_of` resolve on whitespace-split words, not path-shaped substrings, so the character-class gap never touched classification.

**#336: allowlist widening, not a `+` special case (secure-coding-input-validation-injection-defense rule 1/2).** The fix does not add a rule like `if char == '+': allow` (a denylist-style patch around the one character that broke). It widens the *allowlist* character class to the union of what a `--skills`-composed slug can legitimately contain: lowercase skill-directory names, digits, hyphens (already accepted via `\w` and `-`), and the `+` join character `skill_branch_slug()` inserts between them. This is rule 1 applied directly ("validate with an allowlist regex that defines exactly what IS authorized") and rule 2 ("do not special-case the one input that broke — bound the class by what the field can legitimately contain"). The R5 owner comparison (`tail[0] == role`, an exact string `==`) is untouched, per the issue's explicit "must not" — only its input (the extracted tail) was wrong, and only that input is fixed.

**Widening direction verified monotonic.** `[\w.+/-]*` is `[\w./-]*` plus one additional literal (`+`) in the same character class — every string the old class matched, the new class still matches identically; the only change is that a `+`-bearing tail is no longer cut short. This was verified, not just asserted: the full pre-existing `run-board-gate-tests.sh` (145 cases) and `test_board_gate.py` (12 pre-existing cases) suites pass identically before and after the diff (see How you will know it worked).

**#335: reported "before" state not reproducible against current HEAD.** silent-failure-audit's own procedure (see skill-verdict below) requires a finding to cite a concrete file:line pair showing an error caught and not acted upon — the analogous bar here is a concrete, runnable repro showing the misclassification. I traced `_segment_is_failing` by hand for both exact commands (both resolve to a recognized read-only head — `ls` is in `READ_ONLY_HEADS`; `git log` resolves via `_git_subcommand` to `"log"`, which is in `GIT_READ_SUBCOMMANDS` — neither segment is flagged failing, so `if not any(failing...): allow()` fires before any branch/role check runs) and then verified the trace live through both `board-gate.sh` directly and the real `pretooluse-dispatcher.sh` entry point the issue names. Both return rc=0. Declaring #335 "fixed" would be an unverified claim the skill's own evidence bar rejects; declaring it "not investigated" would be inaccurate given the live repro. The accurate disposition is: not reproducible against current HEAD, no code change made, and the acceptance checks that only require *behavior* (not a diff) already pass live.

## What did not work

None — the repro-first approach (write a runnable pytest reproduction of both issues' exact named commands before writing any fix) surfaced #335's non-reproduction early, before any speculative code change was attempted against it.

## Upstream basis

N/A — CORE_BUILD_NOW=1 build-now bypass (contract v3 s19a): the spawning prompt authorized delivery-only, so this record is the only upstream basis; no phase-1 proposal document exists for this issue.

## Open findings

1. **`board-gate.sh:830`'s `_cross_bm` regex has the same character-class gap, but does not misfire — it silently no-ops instead.** `_cross_bm = re.match(r"^issue-([0-9]+)/([\w-]+)$", branch)` (the sidecar-vs-branch disagreement cross-check, R4) also excludes `+` from its role-group class. Traced live: for a `+`-bearing branch, `[\w-]+$` cannot consume the full remainder before the anchored `$`, so `re.match` returns `None` rather than a truncated match — the `if _cross_bm:` block is skipped entirely, not misfired. This means the sidecar/branch disagreement check silently does not run for any multi-skill (100% of current) session; a hand-edited `.on-the-record/role.json` that disagreed with the branch would not be caught by this specific cross-check (R4's separate sidecar-issue/role loop at line ~878 still independently enforces ownership correctly, unaffected by this gap). Left unfixed this round: it is a distinct code path from the `own_hits` extractor #336 named, does not reproduce the reported symptom (an own-record denial), and fixing character-class gaps not named by either issue's acceptance criteria risks the exact scope-blur the assignment explicitly warned against. Flagged here rather than silently left for the next session to rediscover.
2. **#335's actual live trigger, if any, remains unidentified.** The issue's report is specific (exact commands, exact error text, dollar cost, session outcome) and I do not have grounds to say the report is mistaken — only that its exact named repro does not reproduce against current HEAD. Two hypotheses, neither confirmed: (a) an intervening fix already closed this gap silently as a side effect of unrelated work between the observation and this HEAD (no direct evidence found: no board-gate.sh commit in that window per `git log --since`), or (b) the real trigger involved additional command shapes or session state not captured by the issue's minimal repro. Left open rather than guessed at.

## Next steps

None — `loop_state: landed`. If #335's underlying trigger resurfaces, the next session should ask the reporting session for the FULL command history (every Bash call, not just the two shown) rather than re-deriving from the minimal repro, since that repro is now confirmed insufficient to reproduce the report.

## Disposition: accepted character set (issue-336 acceptance bullet 3)

`own_hits`'s trailing class, after this fix, is `[\w.+/-]` — word characters (`[A-Za-z0-9_]`), `.`, `+`, `/`, `-`. Bound: this is exactly the union of what a `docs/issue-<n>/reports/<tail>` path component can legitimately contain today —
- `\w` and `-`: path/file-name characters already in use before this fix (issue numbers, bucket names, kebab-case skill-directory names, the 8-hex-char lease disambiguator `roster.new_lease_disambiguator()` mints).
- `.`: file extensions (`.md`) and the current-directory token.
- `/`: path separators between issue/bucket/role segments.
- `+`: the multi-skill join character `skills.py::skill_branch_slug()` inserts between skill names — the one character this fix adds.

Applied to a path shape not in the pre-existing fixture set (both `run-board-gate-tests.sh` and `test_board_gate.py`'s tests predating this change): a plain redirect (not a directory member, not `mkdir`/`git add`) writing a `+`-bearing slug's own record `.md` FILE directly — `echo 'loop_state: landed' > docs/issue-336/reports/<multiskill-role>.md` — pinned live as `test_multiskill_path_shape_not_in_fixture_set` in `core/hooks/test_board_gate.py`, rc=0.

No character outside this set is accepted, by design: an attempt to smuggle a foreign write past R5 by embedding e.g. a `;`/`|`/backtick inside a path-shaped token would need that character IN the matched tail for the smuggled segment to resolve to the attacker's target, and none of those separator/subshell characters are in the class — so the class stays exactly as tight as it was for every character except the one it was verifiably missing.

## Disposition: read-vs-write classification (issue-335 acceptance bullet 3, non-goal unless shared root — documented per the issue's own request)

Per #335's ask ("say whether one fix covers both... state the disposition list even if not fixed"): board-gate.sh classifies a Bash segment as a **read** (not a write candidate) when its resolved head is in `READ_ONLY_HEADS` (`ls, cat, head, tail, grep, rg, find, wc, diff, stat, file, sort, uniq, cut, tr, echo, printf, basename, dirname, realpath, column, nl, comm, jq, true, test, [, cd`), or when its head is `git` and the resolved subcommand is in `GIT_READ_SUBCOMMANDS` (`log, show, diff, status, blame, ls-files, ls-tree, ls-remote, cat-file, rev-parse, symbolic-ref, describe, shortlog, reflog`), or when its head is in `READ_UNLESS_INPLACE` (`sed, awk, gawk`) AND none of that head's own write mechanisms fire (`-i`/`--in-place`, awk's `system(...)`, sed's `w`/`W` command). Every other head is unproven and treated as a write candidate (fail-closed) — this is a closed allowlist of command EFFECTS, not command NAMES: `git`'s write subcommands (`rm`, `checkout --`, `restore`, `clean`, `apply`, `mv`, `stash`, ...) fall through the same `git` head to the write-candidate path because the subcommand, not the word `git`, decides. Rule applied to a command shape not in either explicit list (per acceptance bullet 3's "at least one command not in the list"): `git stash` (a genuine write subcommand) resolves via `_git_subcommand()` to `"stash"`, which is absent from `GIT_READ_SUBCOMMANDS`, so it is correctly treated as a write candidate under this same effect-based rule — consistent with the issue's own "must not" (`git log -- x; rm -rf x` stays refused — verified live as `test_issue335_must_not_smuggled_write`, rc=2).

## How you will know it worked

**#336 acceptance bullet 1** (own `+`-bearing record writable) — the issue's exact three commands, reproduced live against both `board-gate.sh` directly and `pretooluse-dispatcher.sh` (the real hook entry point), from a workspace on branch `issue-336/<multiskill-role>`:
```
$ python3 -m pytest core/hooks/test_board_gate.py -q -k multiskill
....                                                                    [100%]
4 passed
```
(`test_multiskill_mkdir_own_record_dir_allowed`, `test_multiskill_git_add_own_record_file_allowed`, `test_multiskill_git_add_own_record_dir_allowed`, plus the disposition-bullet-3 test above; all rc=0.) Confirmed the same fix through the real dispatcher path too (not just the standalone script), and confirmed each of these commands is denied on unpatched HEAD with the exact reported message shape (`docs/issue-336/reports/silent-failure-audit belongs to another role` — the slug truncated at the first `+`, quoting the full slug twice, matching the issue's own quote of the live incident) via `git stash -- core/hooks/board-gate.sh` and rerunning.

**#336 acceptance bullet 2** (foreign record still refused) — `test_multiskill_foreign_record_still_denied`: a `git add` of a directory under a *different* `+`-bearing role's record subtree, from the same multi-skill workspace, still denies with `belongs to another role` — rc=2.

**#336 acceptance bullet 3** (accepted character set stated, applied outside the fixture set) — see the Disposition section above and `test_multiskill_path_shape_not_in_fixture_set`.

**Regression check** — `run-board-gate-tests.sh` (145 cases, 143 pass / 2 pre-existing unrelated failures — `feasibility-spikes`/`ops-postmortems`, reproduced identically via `git stash` on unpatched HEAD, unrelated to this change), `test_board_gate.py` (18 cases including the 6 new ones above, all pass), `run-dispatcher-equivalence-tests.sh` (24/25 pass, the 1 pre-existing failure is `approval-gate`, unrelated, reproduced identically on unpatched HEAD), `run-gate-shape-tests.sh` (18/18), `run-role-gates-tests.sh` (83/83), `run-gate-prose-coverage-tests.sh` (4/4) — all run live via `bash core/hooks/tests/run-*.sh` and `python3 -m pytest core/hooks/`.

**#335 acceptance bullet 1** (read-only commands not refused) — `test_issue335_ls_alone`, `test_issue335_gitlog_alone`, `test_issue335_compound`, `test_issue335_ls_stderr_alone` (a throwaway pytest harness at `/tmp/test_repro335.py`, not committed — reproduces the issue's exact two commands, individually and joined with `;` exactly as quoted): all rc=0 against current HEAD, from branch `issue-2593/<the issue's own quoted role fragment>`.

**#335 acceptance bullet 2** (genuine foreign write still refused) — `test_issue335_genuine_write_still_refused`: rc=2, same message shape as today.

**#335 must-not** (`git log -- x; rm -rf x` stays refused) — `test_issue335_must_not_smuggled_write`: rc=2.

skill-verdict: secure-coding-input-validation-injection-defense — applied: invoked; rules 1 and 2 directly shaped the #336 fix (widen the own_hits allowlist to the legitimate slug charset rather than denylisting/special-casing the `+` character that broke) — see Why.
skill-verdict: silent-failure-audit — not-applicable: this change widens one regex literal in an existing gate; it introduces no new catch block, error-handling path, or fallible operation for the audit's Handled/Silently-Absorbed/Unreachable classification to apply to. The skill's own evidence bar (a concrete file:line trace from error origin to effect) was still applied by analogy to the #335 investigation itself (see Why) to avoid an unverified "fixed" claim.
