---
issue: 384
role: diagnose-first+technical-writing-minimalism-scoping-bceafc9c
author: diagnose-first+technical-writing-minimalism-scoping-bceafc9c
skills: diagnose-first (skill-repository(c05de12)), technical-writing-minimalism-scoping (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: docs/issue-2827/_assets/tokenmaxxxer-core-patch/ (tokenmaxxxer/on-the-record, branch issue-2827/diagnose-first+technical-writing-minimalism-scoping-9ef999ec)
    sha: 99b6461674d82adf4f531f1e97dd2e50c084cc60
---

# issue-384 — diagnose-first+technical-writing-minimalism-scoping-bceafc9c record

Build-now delivery (CORE_BUILD_NOW=1 in this session's own environment, set by the spawner). Proposal round skipped per contract v3 s19a.

skill-verdict: diagnose-first — applied: invoked; used to verify passage-by-passage (not in aggregate) which bullets of session-protocol.md are unreachable under CORE_BUILD_NOW=1, quantify each side's real byte/token share on a live measurement rather than the projected figure, and catch that (b)'s claimed 257-token saving does not actually exist in this repo (see Why, "the miss")
skill-verdict: technical-writing-minimalism-scoping — applied: invoked; used to build the mapping table below (rule 6: condense the unreachable two-phase/Approve-signal block since it has no remaining task/decision attached under build-now; reword rather than delete the phase-split PR-trailer rule since a delivery PR's trailer choice is still a live decision)

## What was done

Applied, then independently corrected, the prepared patch from on-the-record#2827 (`docs/issue-2827/_assets/tokenmaxxxer-core-patch/` on branch `issue-2827/diagnose-first+technical-writing-minimalism-scoping-9ef999ec`, fetched and read via `git -C /home/jwjung/tokenmaxxxer/on-the-record show FETCH_HEAD:<path>`), re-deriving both halves in this repo rather than trusting the cross-repo measurement:

**(a) `core/hooks/directive.sh`** — added a `CORE_BUILD_NOW=1` branch that renders a condensed INVARIANTS block and cats a new file, `core/directive/session-protocol-build-now.md`, instead of the full `core/directive/session-protocol.md`. The existing (`else`) non-build-now path is untouched — `diff core/hooks/directive.sh <patch>` shows only the `if/else` insertion, confirmed via:
```
$ diff core/hooks/directive.sh /tmp/issue384-patch/core-hooks-directive.sh
99,100c99,113
< DFILE=...directive/session-protocol.md
< cat <<EOF
---
> if [ "${CORE_BUILD_NOW:-}" = "1" ]; then
...
> fi
```
`core/directive/session-protocol.md` itself is **not modified** — the full two-phase/checkpoint/Approve mechanics stay fully intact and reachable for every non-build-now session, and for a build-now session that scope-exceeds into a follow-up two-phase unit (the build-now variant's own pointer sentence names this path back).

**(b) `warrant/hooks/state.sh`** — applied the patch's per-issue scoping, then found and fixed a real bug in it (see "Open findings"): the patch used a bash glob `issue-*/"${CLAUDE_SKILL}"` to detect an issue-scoped session, which — unlike board-gate.sh's own R4 pattern it claimed to mirror (`^issue-([0-9]+)/(.+)$`, board-gate.sh:1003) — accepts a non-numeric issue segment (e.g. branch `issue-40b/skill`) and then silently drops into the `[ -d ... ] || exit 0` guard with **no fallback to the top-level scan**, going quiet on a real open unit that a correctly-scoped session would have surfaced. Replaced the glob with a `[[ "$branch" =~ ^issue-([0-9]+)/(.+)$ ]] && [ "${BASH_REMATCH[2]}" = "${CLAUDE_SKILL}" ]` test that matches board-gate.sh's own numeric-issue, full-second-group-equality pattern exactly.

New file: `core/directive/session-protocol-build-now.md`.

## Why

**(a) verified passage-by-passage, not in aggregate** (diagnose-first: quantify the share of the whole each candidate cause/passage actually carries, don't act on an aggregate "~half" estimate). Walked all 16 bullets of `session-protocol.md` against `CORE_BUILD_NOW=1`:
- 12 of 16 bullets apply unconditionally regardless of build-now (issue-sourcing, branch/PR shape, layout, commit-trailer rule, headless-delegation rule, board-is-merged, record required fields, terminal loop_state table, operational-surface commit rule, specs-regen rule, verify-at-landing, and the first sentence of "human decisions are GitHub acts only") — kept verbatim.
- 1 bullet (the two-phase/checkpoint description, contract v3 s19) **cannot fire** while `CORE_BUILD_NOW=1` is set: build-now skips the proposal round and the phase-2-gated-by-Approve boundary entirely this run, so there is no default/checkpoint distinction left to describe. Condensed.
- 1 bullet (the "Phase 2 opens through exactly two paths" Approve-signal mechanics — two-account vs single-account mode, string-equality test, near-match reporting duty) is entirely about the same boundary build-now skips — **cannot fire**. Condensed to the one still-live fragment ("never approve, merge, or relay an approval yourself" — still true in general, not tied to the skipped boundary).
- 1 bullet (build-now bypass itself, s19a) describes the session's *actual current mode* under `CORE_BUILD_NOW=1` — not conditional, it always fires this run. Restated directly rather than as an "if" (a proposal-shape-directive-style distinction: an always-true statement about the running mode isn't a conditional rule).
- 1 bullet (PR-trailer phase split) has a case that cannot fire (the phase-1-proposal-PR half — build-now opens exactly one PR) and a case that stays live (the trailer choice on that one PR still matters — Closes/Fixes/Resolves vs Advances/Part of). **Reworded, not deleted**, per the issue's own "must not: do not delete a rule to hit the number."
This matches the on-the-record patch's own condensation choices; independent verification confirmed rather than found a defect in this half of the patch.

Per diagnose-first's Amdahl check — is any of this reachable if the default is overridden, and does it stay?: yes. `session-protocol.md` itself is never edited; the condensed content only ever substitutes in the build-now branch of `directive.sh`, so a session spawned without `CORE_BUILD_NOW=1` (or one where a build-now session hands off remaining work to a follow-up two-phase unit) reads the full, untouched file.

**(b) confirmed both directions on real repo state, not the on-the-record README's synthetic python-body-only test.** First measured this session's own real spawn:
```
$ ls docs/proposals/ 2>&1
ls: 'docs/proposals/'에 접근할 수 없음: 그런 파일이나 디렉터리가 없습니다
$ git log --oneline --all -- docs/proposals | wc -l
0
```
`docs/proposals/` (top level) has **never existed** in `tokenmaxxxer-core`'s history — confirmed via `git log --all`, not just the current tree. So in *this* repo, `warrant/hooks/state.sh`'s current top-level-only scan is not merely "vestigial," it is **permanently inert**: it returns 0 bytes for every session, on every branch, always — and, critically, this means a session scoped to an issue with a real open per-issue proposal is currently **blind** to it (not "spends 257 tokens telling you," but "tells you nothing at all"). Reproduced live with a real per-issue proposal already in this repo (`docs/issue-200/proposals/conflict-free-system-writes.md`, `status: proposed`), from a worktree checked out to `issue-200/probe-role`:
```
$ CLAUDE_PROJECT_DIR=$PWD CLAUDE_SKILL=probe-role bash warrant/hooks/state.sh   # BEFORE (unmodified)
[no output, exit 0]
$ CLAUDE_PROJECT_DIR=$PWD CLAUDE_SKILL=probe-role bash warrant/hooks/state.sh   # AFTER (patched)
warrant: open work units in this repository —
  AWAITING APPROVAL: docs/issue-200/proposals/conflict-free-system-writes.md — do not start this work until the user approves it. — deferred (auto, stale since 2026-08-10T23:46:41Z)
```
Non-issue-scoped fallback (`CLAUDE_SKILL` unset, same branch) confirmed unchanged: still scans top-level `docs/proposals` (still absent → 0 bytes, same as before the patch). Acceptance criterion "(b) still reports a real open unit when one exists — before and after" satisfied on real data, not a synthetic fixture.

**The 351-vs-1 counting evidence in the issue is about a different repository, not this one.** `git ls-tree -r --name-only origin/main` in `tokenmaxxxer/on-the-record` shows a real, populated top-level `docs/proposals/` (many files, several `status: landed`/historical, at least one still open) — that is where the "1 stale top-level" figure and the 257-token saving originate. In `tokenmaxxxer-core`, that directory has never existed, so **(b)'s token-diet component measures zero here** on any real spawn (see "the miss," below). (b)'s value in *this* repo is entirely the correctness fix (surfacing real per-issue open units it currently misses) plus the bug fix found by the warrant hunt below — not a token saving.

**The miss.** Measured on this session's own real spawn (`CLAUDE_SKILL=diagnose-first+technical-writing-minimalism-scoping-bceafc9c`, `CORE_BUILD_NOW=1`, real branch/repo state):
```
$ CLAUDE_PLUGIN_ROOT_CORE=$PWD/core CLAUDE_PLUGIN_ROOT=$PWD/core CLAUDE_PROJECT_DIR=$PWD \
  CLAUDE_SKILL=diagnose-first+technical-writing-minimalism-scoping-bceafc9c TOKENMAXXXER_SPAWNED=1 CORE_BUILD_NOW=1 \
  bash core/hooks/directive.sh | wc -c     # before: 10916, after: 8396
$ CLAUDE_PLUGIN_ROOT_CORE=$PWD/core CLAUDE_PLUGIN_ROOT=$PWD/warrant CLAUDE_PROJECT_DIR=$PWD \
  CLAUDE_SKILL=diagnose-first+technical-writing-minimalism-scoping-bceafc9c \
  bash warrant/hooks/state.sh | wc -c      # before: 0, after: 0 (docs/issue-384/proposals/ does not exist either)
```
derived: the two `wc -c` pipelines above, run against the real `directive.sh`/`state.sh` before and after the edits in this working tree.
- (a): 10916 B → 8396 B = 2520 B ≈ 630 tok saved. Matches the on-the-record projection exactly (this session's own role-name length happens to match the one the patch was measured on).
- (b): 0 B → 0 B = **0 tok saved**, on this real spawn — because there is nothing to remove here (see above). The correctness value is real (issue-200 demo) but does not show up as bytes saved on a spawn without its own open proposal, which is the common case.
- **Combined measured: 630 tok saved, not the projected 887.** Misses the projection by 257 tok, entirely attributable to (b)'s token-diet component not existing in this repo. Reporting this as the actual number per the issue's own instruction ("report what you actually get, including if it misses").

## Upstream basis

`docs/issue-2827/_assets/tokenmaxxxer-core-patch/{README.md,core-hooks-directive.sh,core-directive-session-protocol-build-now.md,warrant-hooks-state.sh}` in `tokenmaxxxer/on-the-record`, branch `issue-2827/diagnose-first+technical-writing-minimalism-scoping-9ef999ec` — read via `git -C /home/jwjung/tokenmaxxxer/on-the-record fetch origin <branch>` then `git show FETCH_HEAD:<path>`. Used as a starting draft only; re-derived and one defect found and fixed in this repo (see "Open findings").

## Mapping table

Every normative statement in `core/directive/session-protocol.md` (16 bullets) against where it lives after, same discipline as #2102/PR #2106. "Home" = the build-now variant unless noted; `session-protocol.md` itself is unedited and remains the home for the full mechanics on the non-build-now path.

| # | Statement (session-protocol.md) | Reachable under CORE_BUILD_NOW=1? | Home after |
|---|---|---|---|
| 1 | Requirements are user-authored GitHub issues; never file/pick one | yes | kept verbatim, build-now variant + INVARIANTS (both branches) |
| 2 | Your issue is assigned in the invocation prompt; ask+stop if none | yes | kept verbatim, build-now variant |
| 3 | All output returns as a PR from `issue-<n>/<role>`; never push main | yes | kept verbatim, build-now variant + INVARIANTS |
| 4 | Two phases (s19): phase-1 proposal PR, phase-2 gated on human Approve; default two-session vs checkpoint single-session | **no** — build-now skips the proposal round and the phase boundary entirely | condensed into one build-now-mode bullet, pointing back to `session-protocol.md` for the full mechanics if this session ever needs them (e.g. after a scope-exceeded handoff) |
| 5 | Build-now bypass (s19a): `CORE_BUILD_NOW=1` skips the proposal round | yes — this *is* the running mode | restated directly (not as a conditional) in the build-now variant + INVARIANTS |
| 6a | Human decisions are GitHub acts: PR merge = acceptance, closed unmerged = refusal | yes | kept verbatim |
| 6b | Phase 2 opens via exactly two Approve paths (two-account/single-account string-equality, near-match reporting duty) | **no** — no Approve-gated boundary exists this run | condensed to the one still-live fragment: never approve/merge/relay an approval yourself; full mechanics stay in `session-protocol.md` |
| 7 | Output layout: `src/`, `test/`, `docs/` six buckets; own record area only | yes | kept verbatim |
| 8 | Commit trailer (`Subject: issue-<n>`) + explicit `git add` for new files | yes | kept verbatim |
| 9 | Headless/single-shot: never end a turn with unconsumed delegated work | yes | kept verbatim |
| 10 | Board is what is MERGED to main, not open PRs | yes | kept verbatim |
| 11 | Record required fields (what/why/upstream/kind/loop_state/open findings/next steps) | yes | kept verbatim |
| 12 | Terminal `loop_state` per record kind | yes | kept verbatim |
| 13 | Operational-surface commit rule (needs a docs/handbooks touch) | yes | kept verbatim |
| 14 | `docs/specs/*` change requires `spec_index.py --update` in the same commit | yes | kept verbatim |
| 15 | PR trailer phase split: phase-1 PR plain `#<issue>`, Closes/Fixes/Resolves reserved for phase-2 delivery PR | **partially** — build-now opens exactly one PR, so the "phase-1 PR" half never fires, but the trailer-choice decision itself still matters | **reworded, not deleted**: "this build-now PR is the delivery PR — Closes/Fixes/Resolves when complete, Advances/Part of when intentionally partial, never neither" |
| 16 | Verify-at-landing: executed acceptance evidence in the record, no new persistent test files by default | yes | kept verbatim |

`warrant/hooks/state.sh`'s single normative behavior (scan proposals, report open/closed/malformed units) is unconditionally reachable both before and after; only its *scope* changes — top-level `docs/proposals/` unconditionally, before; `docs/issue-<n>/proposals/` when the session is issue/role-scoped by board-gate.sh's own numeric-issue pattern, else the unchanged top-level scan, after. Nothing in its normative behavior is lost — the top-level scan path still exists verbatim for every session that doesn't resolve to one issue's own tree.

## Open findings

1. **Found and fixed during this build**: the prepared patch's issue-scope detection in `warrant/hooks/state.sh` used a bash glob (`issue-*/"${CLAUDE_SKILL}"`) that, unlike the board-gate.sh R4 pattern its own comment claimed to mirror (`^issue-([0-9]+)/(.+)$`), accepted a non-numeric issue segment and then silently skipped the fallback-to-top-level scan, going quiet on a real open unit. Reproduced independently via a background `warrant-hunter` dispatch (stance 0, "assume the gate/informer just touched is bypassable") before landing, and confirmed by hand:
```
$ git checkout -q -b issue-40b/skill   # non-numeric issue segment
$ CLAUDE_SKILL=skill bash warrant/hooks/state.sh   # BEFORE the fix: no output at all, real open unit in docs/proposals/ missed
$ CLAUDE_SKILL=skill bash warrant/hooks/state.sh   # AFTER the fix: falls back correctly, reports the real open unit
warrant: open work units in this repository —
  AWAITING APPROVAL: docs/proposals/some-open-unit.md — do not start this work until the user approves it.
```
Resolution path: fixed in this same commit (`warrant/hooks/state.sh`'s scope test now uses `[[ "$branch" =~ ^issue-([0-9]+)/(.+)$ ]] && [ "${BASH_REMATCH[2]}" = "${CLAUDE_SKILL}" ]`, matching board-gate.sh:1003 exactly). Closed, not open.
2. **(b)'s projected token saving does not materialize in this repo** — see Why, "the miss." Not a defect to fix; a measurement finding to carry forward if a future issue re-derives the combined-savings figure across repos. No resolution path needed; stated as fact.

## Standing invariants, executed live

1. **No return of the retired role axis (`CLAUDE_ROLE` value-dependent read) in any reshaped form.**
```
$ git diff origin/main -- core/hooks/directive.sh warrant/hooks/state.sh core/directive/session-protocol-build-now.md | grep -E '^\+' | grep -iE '\bCLAUDE_ROLE\b'
[no output, exit 1]
```
2. **No new bug — failing-test set vs origin/main, as sets of names.** Full suite (`core/hooks/tests/run-all.sh`) run on this branch and, separately, on a fresh `git worktree add <tmp> origin/main`, in the same environment:
```
board gate:            FAIL feasibility-spikes, FAIL ops-postmortems           (159 passed, 2 failed) — identical on origin/main
approval gate:         FAIL checkpoint-refusal-names-await-approval,
                        FAIL execute-without-remote                            (65 passed, 2 failed)  — identical on origin/main
dispatcher-equivalence: FAIL approval-gate: execution write, no approvers.md -> deny (24 passed, 1 failed) — identical on origin/main
ups-diet:               FAIL combined UPS payload <= 3072 bytes                (35 passed, 1 failed)  — identical on origin/main
```
Same 6 failing test names on both trees (pre-existing, environment-order-dependent, unrelated to this diff — confirmed by re-running against a clean `origin/main` worktree in the same session). `test/test_directive_injection.py`: 6/6 passed (exercises the unmodified `else` branch). `core/hooks/tests/run-directive-shape-tests.sh`: 31/31 passed.
3. **No overhead increase.** (a): −630 tok on a build-now spawn, 0 change on a non-build-now spawn (the file it reads is unedited). (b): 0 byte change in the common case (no own open proposal — the guard exits before any extra work), one extra `[[ =~ ]]` regex test replacing the removed `case` glob in the scoped-session path. No spawn gets larger output or more work than before.
4. **Monitor/watch machinery unbroken and not quieter about anything real.** (a): the build-now variant still carries every field verify-at-landing and record-shape-gate.sh actually check (required record fields, terminal loop_state table, commit-trailer rule) — nothing a gate depends on was cut. (b): demonstrably *louder*, not quieter — it now reports a real open unit (`docs/issue-200/proposals/...`) that the unmodified script silently missed, and the hunt-found bug (non-numeric issue segment going silent with no fallback) is fixed rather than left as a new blind spot.

## Next steps

None — loop_state is terminal (landed). This build-now PR carries `Closes #384`.
