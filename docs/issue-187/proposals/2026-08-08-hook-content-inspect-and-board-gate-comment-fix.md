---
status: proposed
files:
  - warrant/hooks/scope-gate.sh
  - core/hooks/board-gate.sh
  - core/hooks/tests/run-scope-gate-tests.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/run-all.sh
  - docs/handbooks/board-gate-tests.md
---

## Request

Fix two frictions observed in 3 of 10 #171 rollout workers: (1) a local
`Edit`/`Write` write wall on `*/hooks/*.sh` paths that denies regardless
of content, forcing a scratchpad-write + `mv` workaround; (2) board-gate
false-positive-blocking a write whose only `docs/issue-N`-shaped text
lives inside comment/echoed content, not an actual write target.

## Constraints

- Fixes land in the two gate scripts already responsible for this
  behavior — no new gate, no new enforcement layer.
- `scope-gate.sh`'s existing design (content-blind, path-only) stays the
  default; the change is a narrow, explicit carve-out for hook-script
  paths, not a general content-inspection regime.
- `board-gate.sh`'s Bash candidate extraction narrows to the actual
  write-target token; it must not start missing real board writes it
  currently catches (no regression on existing `run-board-gate-tests.sh`
  cases).
- Both fixes need a runtime red-green test pair (contract acceptance).

## Rationale

**Alternative considered for (1): leave `scope-gate.sh`'s Bash exemption
as-is and instead widen the frozen write set to include hook paths by
convention.** Rejected — the friction isn't which paths are pre-approved,
it's that a legitimately-scoped hook edit still gets a hard path-only deny
with no way to prove its content is safe; widening the write set doesn't
fix that for the next repo/path nobody thought to pre-list, and it does
nothing about malicious content, which the issue explicitly still wants
blocked. A narrow content-check carve-out scoped to `hooks/*.sh` (the
class of file the friction was actually observed on) fixes the reported
case without turning every Write/Edit into a content scan.

**Alternative considered for (2): treat any Bash segment mentioning
`docs/issue-N` as a write candidate only when the segment's head is a
known write command (echo>/tee/cp/mv/…), dropping the regex scan
entirely.** Rejected — this repeats the same command-classification logic
`_segment_is_failing` already carries and risks diverging from it;
narrowing the *extraction window* (redirection target / trailing
destination argument) inside the existing failing-segment path is a
smaller, more surgical change that keeps all current write-detection
logic (redirection, `tee`, `cd` tracking) intact and only fixes what data
inside a segment counts as a candidate token.

## What will be done

1. `warrant/hooks/scope-gate.sh`: when a `Write`/`Edit`/`MultiEdit`
   targets a path outside the frozen write set AND the path matches
   `(^|/)hooks/[^/]+\.sh$`, do not unconditionally deny. Instead inspect
   the proposed content (`content` for Write, `new_string` for Edit, the
   `new_string` of each edit for MultiEdit) against a small denylist of
   unsafe patterns (piping into a shell, `curl|wget ... | sh`, `rm -rf`,
   `sudo`, unconditionally short-circuiting a gate's own kill-switch/fail-
   closed trap). No denylist hit → allow directly (no `mv` workaround
   needed). A hit → deny with the specific reason. Every other path keeps
   today's content-blind write-set behavior unchanged.
2. `core/hooks/board-gate.sh`: narrow `own_hits` extraction on a failing
   Bash segment so it only scans the write-target window of that segment
   — the text immediately following a `FILE_REDIR` match, or (for a `tee`
   head) its trailing non-flag argument — instead of the segment's full
   raw text. A `docs/issue-N`-shaped string elsewhere in the segment (a
   comment, an echoed message, a heredoc body that isn't itself the
   redirection target) no longer becomes a candidate.
3. Add `core/hooks/tests/run-scope-gate-tests.sh`: red (sanctioned
   hook-script content outside the write set today denies) → green (same
   content allows after the fix) pair, plus a case proving malicious
   content to the same path still denies.
4. Extend `core/hooks/tests/run-board-gate-tests.sh` with a red-green pair:
   a write to a non-docs file whose content/commit-message contains a
   `docs/issue-N`-shaped string is not treated as a board write; an actual
   write targeting `docs/issue-N/...` is still caught.
5. Register the new suite in `core/hooks/tests/run-all.sh`.
6. Note the new hook-content-inspect carve-out in
   `docs/handbooks/board-gate-tests.md` (or the nearest matching gate
   handbook) per the doctrine ladder for a changed gate behavior.

## Out of scope

- Any change to the Claude Code sandbox/harness itself (this repo's gates
  run as PreToolUse hooks after the sandbox already allowed the call;
  they cannot affect a harness-level deny that fires before a hook runs).
- General content-scanning for paths other than `hooks/*.sh`.
- Re-architecting `board-gate.sh`'s segment classifier
  (`_segment_is_failing`/`_write_candidate_segments`) beyond the
  extraction-window narrowing described above.

## How you'll know it worked

- `core/hooks/tests/run-scope-gate-tests.sh` passes: sanctioned hook-file
  content writes directly (no deny, no `mv` needed); malicious content to
  the same path still denies.
- `core/hooks/tests/run-board-gate-tests.sh` passes, including the new
  case: a `docs/issue-N`-shaped string inside comment/content is not a
  board write; a real `docs/issue-N/...` write target is still enforced.
- `core/hooks/tests/run-all.sh` runs both suites clean.
