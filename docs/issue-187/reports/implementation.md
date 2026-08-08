---
code_under_review: warrant/hooks/scope-gate.sh, core/hooks/board-gate.sh, core/hooks/tests/run-scope-gate-tests.sh, core/hooks/tests/run-board-gate-tests.sh, core/hooks/tests/run-all.sh, docs/handbooks/board-gate-tests.md
loop_state: delivered
---

# Implementation record: issue-187

Subject: issue-187. Upstream: approved phase-1 proposal
`docs/issue-187/proposals/2026-08-08-hook-content-inspect-and-board-gate-comment-fix.md`,
approved via issue-level `APPROVE issue-187/implementation` comment
(2026-08-08T13:05:26Z, `JiwonJung94`, single-account mode — PR #188's
author and the approver are the same account).

## What was done

1. `warrant/hooks/scope-gate.sh`: added a content-inspect carve-out for
   `Write`/`Edit`/`MultiEdit` targeting a path outside the frozen write
   set that matches `(^|/)hooks/[^/]+\.sh$`. Instead of the unconditional
   path-only deny, the proposed content (`content` for Write, `new_string`
   for Edit, every edit's `new_string` for MultiEdit) is checked against a
   small denylist — piping into a shell, `curl`/`wget` piped into a shell,
   `rm -rf`, `sudo`, disabling a gate's own fail-closed trap
   (`trap - EXIT`), short-circuiting a `gate_kill_switch_active` check. No
   hit -> allow directly (no scratchpad + `mv` workaround needed). A hit
   -> deny with the matched reason. Every other path is unaffected.
2. `core/hooks/board-gate.sh`: added `_write_target_windows(seg, stripped)`
   and rewired the `own_hits` extraction in the `Bash` candidate-builder
   loop to use it. For a failing segment whose failure reason is a real
   (outside-quotes) `FILE_REDIR` match or a `tee` head, `own_hits` now
   scans only the write-target window (the text after the redirect
   operator, or `tee`'s trailing non-flag arguments) instead of the whole
   segment — so a `docs/issue-N`-shaped string sitting only in an echoed
   comment (`echo "see docs/issue-3/x.md" > /tmp/notes.txt`) no longer
   becomes a false-positive write candidate. Every other failing reason
   (git write subcommands, subshells, in-place edits, and
   `READ_UNLESS_INPLACE`'s own raw redirect scan for awk/sed, where the
   established `gap-awk-comparison-over-block` residual depends on the
   full-segment scan) keeps the prior full-segment scan, unchanged.
   `gate_lib.gate_dequote` collapses quoted spans to a single space
   (not length-preserving), so the window is sliced from the dequoted
   text, not the original segment, to keep match offsets aligned — caught
   by a first failing run of the new test (`## What did not work`).
3. `core/hooks/tests/run-scope-gate-tests.sh` (new): red-green pair —
   sanctioned hook-script content outside the write set now allows
   directly (`hook-write-sanctioned-content`, `hook-edit-sanctioned-content`,
   `hook-multiedit-sanctioned`); malicious content to the same path still
   denies (`hook-write-piped-shell`, `hook-write-rm-rf`, `hook-write-sudo`,
   `hook-write-disables-trap`, `hook-edit-piped-shell`); negative-space
   siblings pin a non-hook path outside the write set still denies
   content-blind (`nonhook-outside-writeset`) and a hook path already
   inside the write set is unaffected (`hook-inside-writeset`).
4. `core/hooks/tests/run-board-gate-tests.sh`: added the red-green pair —
   `bash-echo-comment-not-target`/`bash-tee-comment-not-target` (allow: a
   foreign-record mention inside an echoed comment no longer denies a
   write elsewhere) and their negative-space siblings
   `bash-echo-comment-real-target`/`bash-tee-comment-real-target` (deny: a
   real write into a foreign record through the same echo/redirect or
   echo/tee shape still denies).
5. `core/hooks/tests/run-all.sh`: registered the new
   `run-scope-gate-tests.sh` suite (`=== scope gate (warrant) ===`
   section, alongside `=== board gate ===`).
6. `docs/handbooks/board-gate-tests.md`: documented both fixes —
   the board-gate false-positive fix and the scope-gate content-inspect
   carve-out, per the doctrine ladder for changed gate behavior.

## Doc-placement ladder — completed items

- [x] Changed gate behavior documented in
  `docs/handbooks/board-gate-tests.md`: the `own_hits` extraction-window
  narrowing in `board-gate.sh`, and the new `hooks/*.sh` content-inspect
  carve-out in `scope-gate.sh`.
- No new env var, dependency, or migration was introduced — no
  `.env.example` or manifest change needed.
- No library-or-format choice over a named alternative was made beyond
  what the approved proposal's own `## Rationale` already recorded (no
  new `docs/decisions/` entry needed).

## What did not work

- First implementation of `_write_target_windows` sliced the write-target
  tail from the ORIGINAL segment text at the match offset found in the
  `gate_lib.gate_dequote`-processed text. Expected: offsets in the
  dequoted text line up with the original segment (both same length).
  Actual: `gate_dequote` collapses each quoted span to a single space
  (`GATE_QUOTE_SPAN.sub(" ", text)`), not a same-length blank run, so any
  redirect appearing after a quoted span in the same segment had its
  target token sliced from the wrong offset — the new
  `bash-echo-comment-real-target` case (`echo "..." > docs/issue-3/reports/review.md`)
  came back `allow` instead of the expected `deny` on first run. Fixed
  by slicing the tail from the dequoted text itself (which the match
  offsets DO correctly index into), not the original segment.
- The first draft of the new `bash-echo-comment-real-target`/
  `bash-tee-comment-real-target` test cases pointed the real write target
  at `$BOARD/proposals/x.md` (a path the test's own role/branch fixture is
  actually entitled to write). That is a legitimate own-bucket write, not
  a foreign-record write, so it correctly allowed — the test's own
  expectation was wrong, not the gate. Retargeted both cases to
  `$BOARD/reports/review.md`, matching this file's existing
  foreign-record-deny convention (`bash-redirect-foreign` et al.).

## Why

Fixes the two frictions issue #187 reports from 3 of 10 #171 rollout
workers: a hook-script edit outside the frozen write set denying
regardless of content (forcing a scratchpad + `mv` workaround, the exact
lesson #476 already established — blanket-deny only rewards evasion), and
`board-gate.sh` false-positive-denying a write whose only
`docs/issue-N`-shaped text lived inside comment/echoed content rather
than the actual write target.

## Upstream

`docs/issue-187/proposals/2026-08-08-hook-content-inspect-and-board-gate-comment-fix.md`

## Hunt cadence

After-proposal hunt (phase 1): NO FINDING — see
`docs/reports/2026-08-08-hunt-hook-content-inspect-and-board-gate-comment-fix.md`,
`## after-proposal` section.

Before-landing hunt (this session, stance 1 — "assume this change and
another plugin's rule cancel each other"): FINDING, resolved before this
record's commit. `warrant/hooks/scope-gate.sh`'s first `UNSAFE_HOOK_CONTENT`
denylist flagged `trap - EXIT` ("disabling a gate's fail-closed trap"),
but `trap - EXIT` (restore-default) is the project-wide sanctioned
early-exit idiom every gate script's own kill-switch/success path uses
(`{ trap - EXIT; exit 0; }` — `gh-guard.sh`, `board-gate.sh`,
`scope-gate.sh` itself), so a hook edit whose content merely reproduces
another gate's own shipped source (repro used `core/hooks/gh-guard.sh`
verbatim) was wrongly denied — defeating the carve-out's own purpose of
allowing legitimate hook edits.

closed_checks:
  - check: warrant-hunt before-landing, stance 1 ("cancels another
    plugin's rule") — FINDING, then resolved
    ref: warrant/hooks/scope-gate.sh:327-331
    resolution: narrowed the denylist rule from `trap - EXIT` (matches
      the sanctioned restore-then-exit idiom) to `trap '' EXIT` / `trap
      -- '' EXIT` (ignore-the-signal, the actually dangerous
      never-restores shape). Re-ran the hunt's own repro
      (`core/hooks/gh-guard.sh`'s real content, Write to
      `some/hooks/gh-guard.sh`) — now `allow`. Added
      `hook-write-standard-early-exit` (negative-space sibling of
      `hook-write-disables-trap`) to
      `core/hooks/tests/run-scope-gate-tests.sh` pinning the fix.
      Documented in `docs/handbooks/board-gate-tests.md`.

## Open findings

None outstanding. The one finding this session produced (before-landing
hunt, stance 1, above) is resolved and pinned by a regression test; no
further hunt is owed for this transition.

## Next steps

None — `## What will be done` in the approved proposal is fully
delivered; `core/hooks/tests/run-all.sh` runs clean end to end
(`ALL OK`).

## Resolution path

Not applicable — no open findings.
