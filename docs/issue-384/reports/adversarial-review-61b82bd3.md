---
issue: 384
role: adversarial-review-61b82bd3
author: adversarial-review-61b82bd3
skills: adversarial-review (skill-repository(c05de12))
verifies_subject: true
loop_state: reported
upstream:
  - path: tokenmaxxxer/tokenmaxxxer-core#386 (branch issue-384/diagnose-first+technical-writing-minimalism-scoping-bceafc9c)
    sha: 3b50ebbba5c25c69c437b6b1b59d4577c406dcb0
---

# issue-384 — adversarial-review-61b82bd3 record

skill-verdict: adversarial-review — applied: invoked; used as the operating stance for this whole record — every number and claim in PR #386 was re-derived from a clone of the branch rather than re-stated from the builder's own report or record files, per the skill's "session separation" mechanism
skill-verdict: work-in-english — applied: invoked; record, commit, and PR all written in English, Korean reserved for the final chat summary
other mounted skills: not triggered (implementation-audit — this task is a direct adversarial re-derivation of a PR's own numeric/correctness claims, not a claims-extraction-then-classify audit against a spec)

## What was done

Independently re-derived PR #386 (tokenmaxxxer-core#386, issue #384) end to end, in an isolated clone (`/tmp/pr386test`, cloned from this session's own checkout, with a `real-main` ref fetched directly from `origin/refs/remotes/origin/main` to sidestep this checkout's stale local `main` branch — the local `main` is 450b758, "14 ahead / 36 behind" `origin/main`; every "before" measurement below uses `real-main` = `origin/main` = 7040a3a, not local `main`). Four areas were checked, each re-run rather than read from the builder's own record:

**1. Token-saving claim.** Ran `core/hooks/directive.sh` for real (not estimated) with `CLAUDE_SKILL=adversarial-review-61b82bd3 TOKENMAXXXER_SPAWNED=1`, capturing actual injected stdout bytes:
```
$ env -u CORE_BUILD_NOW CLAUDE_SKILL=adversarial-review-61b82bd3 TOKENMAXXXER_SPAWNED=1 bash core/hooks/directive.sh | wc -c   # real-main, default (only mode pre-PR)
10817
$ CORE_BUILD_NOW=1 CLAUDE_SKILL=adversarial-review-61b82bd3 TOKENMAXXXER_SPAWNED=1 bash core/hooks/directive.sh | wc -c        # pr-386, build-now
8275
```
Injected-bytes saving: 10817 → 8275 = **2542 bytes**. Tokenized both captured outputs with `tiktoken` (`cl100k_base`, a proxy since no Claude tokenizer is available offline): 2675 → 2065 tok = **610 tok**, in the same neighborhood as the PR's claimed 630 (methodology matches — measured at the actual injection point on a real spawn, not estimated).

Also computed the file-size-only version of the same comparison, since the PR body's own issue text (#384) originally quoted file sizes (`session-protocol.md` 8,729 B) rather than injected bytes:
```
$ wc -c core/directive/session-protocol.md core/directive/session-protocol-build-now.md   # pr-386
8729  core/directive/session-protocol.md
6526  core/directive/session-protocol-build-now.md
```
File-size-only diff: 8729 → 6526 = 2203 bytes = 540 tok (cl100k_base) — **a different, smaller number than the injected-bytes measurement** (610 tok), because the short INVARIANTS heredoc in `directive.sh` (which also changes length between the two modes) is not part of either file. The PR's own methodology (capturing the hook's actual stdout) is the correct one; the file-size number understates the real per-spawn saving by ~70 tok. Both are reported here since they differ, per instruction.

Warrant side: confirmed live that `docs/proposals` (top-level) has never existed in this repo's git history —
```
$ git log --all --oneline -- docs/proposals | wc -l
0
```
— so the claimed "0 tok saved (warrant)" is correct in this repo; the real value of the warrant change is the correctness fix, not a token saving. Reproduced the before/after report live on a `issue-200/implementation`-named branch merged with `pr-386` (real proposal file: `docs/issue-200/proposals/conflict-free-system-writes.md`, `status: proposed`):
```
before (real-main state.sh): <no output>            — silent, 0 bytes
after  (pr-386 state.sh):     "warrant: open work units in this repository —
  AWAITING APPROVAL: docs/issue-200/proposals/conflict-free-system-writes.md — do not start this work until the user approves it. — deferred (auto, stale since 2026-08-10T23:46:41Z)"
```
Matches the PR's claim exactly, reproduced independently rather than trusted.

**2. Duplication / silent-drift.** Read `core/hooks/directive.sh`'s full injection path (not just the diff hunk): after the new `if/else`, the script unconditionally falls through to `if [ -r "$DFILE" ]; then ... cat "$DFILE"`, and `DFILE` is set inside each branch. So a build-now spawn injects **two** copies back to back: the short build-now heredoc (7 bullets, embedded directly in `directive.sh`) *and* the full `core/directive/session-protocol-build-now.md` (15 bullets) via `cat`. Confirmed by running the hook and reading the captured output — the heredoc's "INVARIANTS" block appears first, then the literal string `[core] Full protocol (session-protocol.md), delivered inline, no Read needed:`, then the entire build-now `.md` file. This mirrors the pre-existing default-path pattern (short heredoc + full `session-protocol.md`, same double-injection, already present on `main`) — the PR does not invent double-injection, but it does add a **second flavor** of it, several of whose bullets restate the same rule in near-identical wording as the short heredoc sitting a few lines above it in the same file (e.g. the docs/specs-regen bullet and the verify-at-landing bullet appear, close to verbatim, in both the heredoc and the `.md` file it's followed by). Net count of overlapping-content copies in the repo after this PR: **4** (build-now heredoc, build-now `.md`, default heredoc, default `.md`, two of each pair injected together per mode) versus 2 before.

Checked whether anything would catch one copy drifting from its sibling: edited only the build-now heredoc's docs/specs bullet in `core/hooks/directive.sh` (leaving `session-protocol-build-now.md`'s matching bullet untouched), then ran the full suite:
```
$ sed -i 's/A session that stages a change to any docs\/specs\/\* file also regenerates .../A session that touches docs\/specs\/* MUST regen the index or the commit is invalid./' core/hooks/directive.sh   # build-now heredoc copy only
$ bash core/hooks/tests/run-all.sh > /tmp/runall_drifted.txt 2>&1
$ git checkout core/hooks/directive.sh   # revert
$ bash core/hooks/tests/run-all.sh > /tmp/runall_clean.txt 2>&1
$ diff /tmp/runall_clean.txt /tmp/runall_drifted.txt
(no output — byte-identical)
```
Confirmed: no test in the suite ever invokes `directive.sh` with `CORE_BUILD_NOW=1` to check the build-now injected *text content*. `core/hooks/tests/run-directive-shape-tests.sh` only exercises the default (`CLAUDE_SKILL=implementation bash directive.sh`, no `CORE_BUILD_NOW`) path against `session-protocol.md`; the only existing `CORE_BUILD_NOW` test coverage (`run-approval-gate-tests.sh`) exercises the *enforcing* gate's allow/deny behavior, not the *informing* text's content. `core/hooks/tests/run-canon-duplication-content-tests.sh` is a different mechanism entirely (detects vendored copies of whole hook *files* across plugin directories, not intra-file text duplication). **Nothing catches a drift between the two build-now copies, or between the build-now and default flavors, of the same rule. This is the finding requested: silent-drift is real, and confirmed to be silent by direct repro, not by absence-of-evidence.**

Also noticed, while tracing the injection path: the hardcoded line `core/hooks/directive.sh:141` (`echo "[core] Full protocol (session-protocol.md), delivered inline, no Read needed:"`) runs unconditionally regardless of which branch was taken — for a build-now spawn it mislabels the file that actually follows (`session-protocol-build-now.md`, not `session-protocol.md`). Minor, but it is new incorrect text a build-now session will see every spawn.

**3. Dropped-content review (unreachable-only check).** Built the full bullet-level mapping by parsing both files' `- ` blocks (16 in `session-protocol.md`, 15 in `session-protocol-build-now.md`) and diffing pairwise. Table:

| `session-protocol.md` bullet | fate in build-now file | reachable under `CORE_BUILD_NOW=1`? |
|---|---|---|
| Requirements are GitHub ISSUES | kept verbatim | n/a (always reachable) |
| YOUR issue is assigned | kept verbatim | n/a |
| ALL output → PR, branch `issue-<n>/<role\|skill>` | kept, `<role>`→`<skill>` | n/a |
| Work in two phases (s19): phase-1/phase-2 boundary, default/checkpoint modes | **condensed** into "This session is running build-now…", with an explicit pointer back to `core/directive/session-protocol.md` for the case a scope-exceeded stop hands off to a follow-up two-phase unit | No — `core/hooks/approval-gate.sh:190` (`if os.environ.get("CORE_BUILD_NOW")... allow()`) short-circuits before the two-phase/Approve logic is ever reached in this run; the follow-up unit that might need it runs without `CORE_BUILD_NOW=1` and gets the full text anyway |
| Build-now bypass (s19a) description | merged into the same condensed bullet above | reachable, and kept |
| Human decisions / Approve mechanics (two-account, single-account, string-equality, near-match reporting duty) | **condensed** to "PR merge = acceptance…, never approve/merge/relay yourself"; Approve-signal mechanics dropped | No — same short-circuit; a build-now session never evaluates an Approve comment itself |
| Output layout | kept verbatim (role→skill) | n/a |
| docs/issue-<n>/** commit + `git add` | kept verbatim | n/a |
| Headless/single-shot delegation rule | kept verbatim | n/a |
| Board = MERGED to main | kept, **but see finding below — not fully renamed** | n/a |
| Record required fields | kept verbatim | n/a |
| Terminal loop_state per kind | kept verbatim | n/a |
| Operational-surface commit refusal | kept verbatim | n/a |
| docs/specs/* → regen reconciled-index | kept verbatim | n/a |
| PR trailer phase split (phase-1 plain `#<issue>`, phase-2 `Closes/Fixes`) | **replaced** with "this build-now PR is the delivery PR: Closes/Fixes/Resolves or Advances/Part of, never neither" | Correct adaptation — a build-now run never produces a phase-1-only PR, so the phase-split framing itself doesn't apply; the underlying trailer-choice rule survives, correctly reworded |
| Verify-at-landing | kept, condensed wording, same substance | n/a |

Every drop maps to a rule that `approval-gate.sh`'s own build-now short-circuit (line 190, pre-existing since issue-212, unchanged by this PR) makes structurally unreachable in a build-now run. No dropped content was found that a build-now session could still need.

**4. Retired role-axis check (the subject of round 1's rejection).** Round 1 rejected the file for introducing "for role ${skill}" 8 times. The round-2 fix (commit `3b50ebb`) renamed those 8 sites and re-ran its own check: `git diff ... | grep -icE '\bCLAUDE_ROLE\b'` → 0, and (per the sibling record `technical-writing-structure-comprehension-e0bd9d2c.md`) `grep -icE '\brole\b|역할'` → 0. Re-ran a plain (non-word-boundary) sweep instead of trusting the word-boundary form:
```
$ git diff real-main pr-386 -- core/directive/session-protocol-build-now.md core/hooks/directive.sh warrant/hooks/state.sh | grep -n "^+" | grep -i "role"
60:+  read other roles' state from main, not from open PRs.
```
**One occurrence survives**, at `core/directive/session-protocol-build-now.md:54` (`- The board is what is MERGED to main. An open PR is not yet on the board;\n  read other roles' state from main, not from open PRs.`), byte-identical to `session-protocol.md`'s own copy of the same bullet — i.e. copy-pasted, never renamed. Confirmed why both the round-1 grep and round-2's re-check missed it:
```
$ echo "read other roles' state from main" | grep -icE '\brole\b|역할'
0
$ echo "read other roles' state from main" | grep -icE 'role'
1
```
`\brole\b` cannot match inside "roles" — `s` is a word character, so there is no word boundary between `role` and `s`. Both review rounds' own verification command structurally excludes the plural form of the exact word they were checking for. **This is a confirmed, unambiguous, previously-undetected instance of the retired role axis, in the exact new file round 1 already flagged for the same defect class. It was removed from 8 sites and left in a 9th, not fully removed as claimed ("0 additions" does not hold — the true count is 1).**

**5. `CORE_BUILD_NOW` contract.** `core/hooks/approval-gate.sh:190` and `core/hooks/directive.sh:99` both key off a bare `os.environ.get("CORE_BUILD_NOW") == "1"` / `[ "${CORE_BUILD_NOW:-}" = "1" ]` check — pre-existing since issue-212, unchanged by PR #386. "Never grant yourself this bypass" is stated in the directive text and in code comments at `approval-gate.sh:46` and `:185` ("The spawn task, not the role itself, sets CORE_BUILD_NOW=1") but there is no technical check anywhere in `core/` or `warrant/` of *who* set the variable or through what channel — unlike the Approve-signal mechanism (string-equality, different-account-vs-comment check), there is no analogous verification for `CORE_BUILD_NOW`. This is an existing architectural trust boundary, not something PR #386 introduces or changes; noted here because the task asked for it to be confirmed, not because it is a new defect.

**6. Standing invariants.**
- No return of the retired role axis in any reshaped form: **fails** — see finding above (1 occurrence, `session-protocol-build-now.md:54`).
- No new bug — failing-test set vs `origin/main`(=`real-main`=7040a3a), compared as sets of names:
  ```
  $ bash core/hooks/tests/run-board-gate-tests.sh 2>&1 | grep -E '^FAIL'          # both branches
  FAIL   feasibility-spikes                 want=allow got=deny
  FAIL   ops-postmortems                    want=allow got=deny
  $ bash core/hooks/tests/run-approval-gate-tests.sh 2>&1 | grep -E '^FAIL'       # both branches
  FAIL   checkpoint-refusal-names-await-approval want=present got=absent
  FAIL   execute-without-remote             want=deny got=allow
  $ bash core/hooks/tests/run-dispatcher-equivalence-tests.sh 2>&1 | grep -E '^FAIL'  # both branches
  FAIL   approval-gate: execution write, no approvers.md -> deny  want_rc=2 standalone_rc=0 dispatcher_rc=0
  ```
  Identical 5-name set on both `real-main` and `pr-386`. (Minor: the PR body's own text claims "same 6 failing test names" — the actual reproducible, named set is 5, not 6. Doesn't affect the "no new bug" conclusion since the set is identical either way, but the PR description's count is off by one.) `python3 -m pytest test/test_directive_injection.py -q` — 6 passed on both branches.
- No overhead increase: **confirmed decrease** — 10817 → 8275 injected bytes for a build-now spawn (−2542 B, −23.5%), 2675 → 2065 tok (cl100k_base, −610 tok). The default (non-build-now) path is byte-identical on both branches (`env -u CORE_BUILD_NOW … directive.sh | wc -c` = 10817 on both `real-main` and `pr-386`) — no regression for non-build-now spawns.
- Monitor/watch machinery unbroken and not quieter:
  ```
  $ diff <(sed -E 's/[0-9]+ms/Xms/g' /tmp/full_main.txt) <(sed -E 's/[0-9]+ms/Xms/g' /tmp/full_pr.txt)
  (no output)
  ```
  `core/hooks/tests/run-all.sh`'s full output (every sub-suite, every pass/fail count) is byte-identical between `real-main` and `pr-386` after normalizing timing jitter — nothing newly silent, no suite count dropped.

## Why

Adversarial-review's core mechanism is session separation: the builder session already committed to its own numbers and its own "0 additions" claim in-context, so re-stating them from its record would just launder that commitment. Every number and claim above was re-run from a clone, independent of the builder's report — including re-deriving the failing-test set from the actual test runners rather than copying the builder's own copied set, and re-running the role-axis check with a *different* grep than either of the builder's two prior self-checks (a plain substring, not a word-boundary regex), specifically because both prior checks shared the same blind spot and a repeat of the same command would have re-confirmed the same miss.

## What did not work

None — every measurement and repro in this record executed as expected on the first attempt (isolated clone, `real-main` ref fetch to bypass the stale local `main`, drift-injection repro, live before/after demo).

## Upstream basis

- `tokenmaxxxer/tokenmaxxxer-core#386`, commit `3b50ebbba5c25c69c437b6b1b59d4577c406dcb0` (PR head at review time) — subject of this verification.
- `docs/issue-384/reports/technical-writing-structure-comprehension-e0bd9d2c.md` (same-commit on `pr-386`, not this record's own commit) — cross-checked, not trusted: its failing-test-set numbers matched my independent re-run; its role-axis re-check command was the one shown to have the blind spot this record's finding depends on.
- `core/directive/record-shape.md`, read for frontmatter shape; this record is a review-record (terminal `loop_state: reported`), not the `implementation.md` coding-record the directive's field list (`code_under_review:`, `type:`, `breaking:`) is written for — those fields are not carried here because they don't apply to this record kind; the skeleton's own frontmatter shape (`issue`, `role`, `author`, `skills`, `verifies_subject`, `loop_state`, `upstream`) was kept instead, per this session's spawn instruction to fill the skeleton rather than restructure it.

## Open findings

1. **Retired role axis survives once** — `core/directive/session-protocol-build-now.md:54`, "read other roles' state from main, not from open PRs." Resolution path: rename `roles'` → `skills'` in that bullet (mirroring the same rename already applied to every other instance in the file), and change the round's self-check grep from `\brole\b` to a plain `role` (or `\brole` without the trailing boundary) so the plural form can't hide again.
2. **Mislabeled protocol-file name in the injected header** — `core/hooks/directive.sh:141` always prints `session-protocol.md` regardless of which `$DFILE` was actually cat'd. Resolution path: make the string reference `$DFILE`'s basename, or branch the message text alongside the `if/else` above it.
3. **No test exercises build-now injected text content** — confirmed via live drift repro (see "What was done" §2); a future edit to either build-now copy (heredoc or `.md`) can silently diverge from its sibling with zero test signal. Resolution path: extend `run-directive-shape-tests.sh` (or a new sibling script) to also invoke `directive.sh` with `CORE_BUILD_NOW=1` and assert the same shape rows against the build-now output/file pair — out of this PR's stated scope, but the gap this PR's own design choice (a second full-text variant) creates.
4. **PR body's failing-test count (6) doesn't match the reproducible named set (5)** — cosmetic, doesn't affect the "no new bug" conclusion since the set is identical pre/post PR either way; no resolution needed beyond noting it here.

## Next steps

None — `loop_state: reported` is terminal for this record kind (review-record). Findings above are handed off via this PR's own review thread / a follow-up commit on `issue-384`'s branch, not further action within this session.
