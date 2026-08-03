---
kind: build-proposal
subject: issue-99
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-99/reports/implementation/survey.md
    sha: <set at commit>
  - path: docs/issue-99/reports/implementation/scout-brief.md
    sha: <set at commit>
---

files: `core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`, `docs/handbooks/board-gate-tests.md`

## Request

board-gate.sh's `Bash` candidate builder (`board-gate.sh:256-274`) has a
fallback, `candidates.append(DOCS)` (`:272`), annotated "mentioned but
unextractable: adjudicate" that structurally can never adjudicate:
`posixpath.normpath("docs/")` is `"docs"`, whose `.find("docs/")` is
`-1`, so the fallback candidate never survives hit-extraction and the
branch always reaches `allow()` instead (confirmed live, survey section
1; already root-caused independently by
`docs/issue-90/reports/execution-observation.md` Finding 1). A command
whose write target is expressed relative to a `cd`-ed foreign issue
directory — `cd docs/issue-49 && date > x.md` — now allows where the
pre-issue-90 code denied via R4. The same gap catches non-redirect write
verbs too (`cp`, `mv`), confirmed live (survey section 2), since their
targets carry no `docs/` token any more than the redirect case's does.
Two negative-space shapes must not regress: issue-90's own preserved
false-positive fix (survey section 3, case 1) and a role's legitimate
`cd`-then-write into its own issue tree (survey section 3, case 2).

## Constraints

- board-gate's protection purpose is not weakened for any of R1-R5; this
  file's own "over-blocking is the safe direction" stance
  (`board-gate.sh:267`) holds.
- Every existing case in `core/hooks/tests/run-board-gate-tests.sh` keeps
  its current verdict (71 passed, 0 failed today — survey baseline).
- The fix distinguishes the two "empty candidates" cases (survey section
  4): a `docs/` mention sitting in an already-read-only segment (safe,
  must keep allowing) vs. one established by a preceding `cd` into
  `docs/` that a later write-classified segment inherits (unsafe, must
  now deny). A blanket "fail closed whenever candidates end up empty"
  is explicitly rejected — it would reopen issue-90's own preserved case.
- No new dependency, no rewrite of `_split_segments`/`SEGMENT`/the
  per-segment classification issue-90 already built and 71 cases
  verify — the fix extends that model, per this issue's own suggested
  discriminator ("앞선 읽기 전용 세그먼트가 docs/ 경로로 cd 했는가").
- Every new branch this fix adds must be empirically shown reachable and
  correctly discriminating before being proposed (issue's own stated
  pitfall) — done in a disposable, uncommitted scratch prototype this
  session (survey section 6): 71/71 existing cases held, all listed new
  cases produced the intended verdict, including the exact R4 deny
  reason the issue's own local experiment reports.

## Rationale

**Chosen shape: a sticky, existential `cd`-into-`docs/` tracker over the
existing per-segment model, reconstructing only the `cd` target
directory as the candidate.** Walk `_split_segments`' output in order;
track the most recent `docs/`-mentioning `cd` target as `cd_tail`
(never cleared by a later non-`docs/` `cd`); for any later
write-classified segment with no `docs/` token of its own, add
`DOCS + cd_tail` as a candidate instead of the dead `DOCS` literal. This
needs no per-command argument table (the same candidate — the directory
— covers a redirect, `cp`, `mv`, or any future write verb identically),
reuses `_write_candidate_segments`' existing per-segment classification
unchanged, and adds exactly one new piece of state (the tracked tail).

Three alternatives were considered and rejected:

- **Rescan the whole `cmdline` (not just failing segments) for `docs/`
  tokens, and deny only if that still finds nothing.** This is the
  issue's own cited pitfall shape (local C1-F1): the outer guard
  `if DOCS in cmdline` already guarantees the literal `docs/` is present
  somewhere on the line, so a whole-line rescan for that same literal
  can never come back empty — the "still nothing → deny" branch would be
  structurally unreachable, exactly like the dead fallback this issue
  reports, just moved one level up. Rejected on that basis alone, not
  reached for testing.
- **Full relative-path resolution** (track the exact effective cwd
  through arbitrary `cd .`/`cd ..`/multi-hop chains, un-set on leaving
  `docs/`). Scouted (angle 1): command-specific path extractors exist in
  more elaborate security gates, but building one here is a materially
  larger surface (needs `..`-aware joining, symlink-blind-but-consistent
  resolution, and a "left docs/" clear condition) with edge cases this
  session cannot empirically exhaust within this issue's scope. Rejected
  in favor of the simpler sticky/existential tracker the issue itself
  suggests, which is what was actually prototyped and measured. The
  accepted cost is one over-blocking case (`cd docs/issue-49 && cd /tmp
  && date > y.md` now denies even though the final write target is
  `/tmp`, not `docs/`) — measured, and consistent with this file's
  existing over-blocking-is-safe posture (`FILE_REDIR`/`SUBSHELL`
  already accept the converse trade-off, per the comment at
  `board-gate.sh:133-135`).
- **Replace the regex/segment model with a real shell parser** (bashlex
  / tree-sitter-bash). Scouted (angle 2): more accurate on quoting/
  nesting in general, but a new dependency this repo's convention
  avoids, disproportionate to two narrowly-reproducible defects, and
  would discard an architecture 71 existing cases across three prior
  issues (88, 90, 94) already verify. Rejected.

**cd-based discriminator: adopted**, per the issue's own framing of this
as the proposal's decision (issue #99 requirement 2). Reconstructing
only the `cd` target *directory*, not the exact write-target filename,
is a deliberate, named scope boundary: it is sufficient to re-run R1-R4
correctly (none of those need the filename) but not R5 (per-file
`reports/` ownership, which does). Survey section 5 confirms this R5 gap
is pre-existing on `main` today (`cd docs/issue-3/reports && cp /tmp/a
review.md`, a same-issue cross-role write, already allows with no fix at
all) and is not widened by this fix. Closing it needs per-command
destination-argument extraction (which argument is `cp`'s destination
vs. `mv`'s, vs. a redirect's target) — a materially larger, currently
unrequested surface — so it is named explicitly Out of scope rather than
silently left unmentioned.

## What will be done

- [ ] `core/hooks/board-gate.sh`: extract the per-segment read/fail test
  currently inlined in `_write_candidate_segments`'s loop
  (`:226-243`) into a `_segment_is_failing(seg, stripped)` helper
  returning the same bool, with `_write_candidate_segments` becoming a
  thin filter over it (no behavior change — same classification rules,
  same return value for the same input).
- [ ] `core/hooks/board-gate.sh`: add `_cd_target(stripped)` (the
  argument a `cd` segment would receive — first non-flag word after
  `cd`) and a small helper to compute a candidate token's `docs/`-
  relative tail (the same normalize-then-find `DOCS` logic the existing
  hit-extraction loop already performs, exposed early enough to reuse
  here).
- [ ] `core/hooks/board-gate.sh:256-274` (`Bash` candidate builder):
  replace the `failing_segments`/whole-block-rescan flow with an
  in-order walk of `_split_segments`' segments. Read-only segments whose
  head is `cd` update `cd_tail` (sticky; only updated when the `cd`
  target itself contains a `docs/` token — never cleared by an
  unrelated `cd`). Write-classified segments extract their own `docs/`
  tokens as today; if none are found and `cd_tail` is set, append
  `DOCS + cd_tail` as a candidate instead of the current dead
  `candidates.append(DOCS)`; if none are found and `cd_tail` is unset,
  contribute nothing (preserves the issue-90 negative space).
- [ ] `core/hooks/tests/run-board-gate-tests.sh`: add, after the
  issue-90 candidate-scoping section:
  - `run deny bash-cd-relative-redirect-foreign Bash '{"command":"cd docs/issue-49 && date > x.md"}'` — this issue's headline repro; want the exact R4 branch-mismatch reason.
  - `run deny bash-cd-relative-cp-foreign Bash '{"command":"cd docs/issue-49 && cp /tmp/a x.md"}'` — the non-redirect write-verb gap, `cp`.
  - `run deny bash-cd-relative-mv-foreign Bash '{"command":"cd docs/issue-49 && mv /tmp/a x.md"}'` — same gap, `mv`.
  - `run allow bash-cd-relative-write-own-issue Bash '{"command":"cd docs/issue-3/reports && date > qa.md"}'` (negative-space sibling) — a role's own legitimate `cd`-then-write into its own issue tree must still allow, now via genuine R1-R4 adjudication rather than the dead fallback's accidental allow.
  - `run allow bash-unresolved-head-then-read` stays exactly as issue-90 left it (no change) — the sibling proving negative space untouched.
  - `run deny bash-cd-out-then-write-elsewhere Bash '{"command":"cd docs/issue-49 && cd /tmp && date > y.md"}'` — pins the accepted over-blocking trade-off (Rationale) as a deliberate verdict, not an accident.
- [ ] `docs/handbooks/board-gate-tests.md`: one entry documenting the
  `cd`-tracking fix, its negative-space siblings, and the accepted
  over-blocking trade-off, same turn as the code change (issue's
  requirement 5).
- [ ] Verify: `bash core/hooks/tests/run-board-gate-tests.sh` reports `0
  failed`, run once after the change.

## Out of scope

- The same-issue, cross-role R5 gap named in survey section 5 (`cd
  docs/issue-3/reports && cp /tmp/a review.md` allowing when it should
  deny). Pre-existing on `main`, not widened by this fix, and would need
  per-command destination-argument extraction — a materially larger
  surface than this issue's two named defects. Left as a residual for
  the human to decide whether it warrants its own issue.
- Full relative-path resolution of arbitrary `cd`/`cd ..`/multi-hop
  chains, and un-tracking `cd_tail` on leaving `docs/` — deliberately not
  chosen (Rationale); the resulting over-blocking edge case is accepted
  and pinned by a regression test rather than silently produced.
- Replacing the regex/segment parsing model with a real shell parser
  (bashlex/tree-sitter-bash) — deliberately not chosen (Rationale).
- Any other board-gate.sh rule (R1-R5) beyond the two named defects.
- `approval-gate.sh` — issue-90 already ported the equivalent
  quote-awareness/`cd` fixes there; this issue names only board-gate.sh.

## How you'll know it worked

`bash core/hooks/tests/run-board-gate-tests.sh` reports `0 failed`,
including: the three new foreign-issue `cd`-relative deny cases (one
redirect, two non-redirect write verbs) with the exact R4 branch-mismatch
reason; the new own-issue `cd`-relative allow case; the pinned
over-blocking `cd`-out-then-write deny case; every pre-existing case
(including `bash-unresolved-head-then-read`, issue-90's negative space)
unchanged; and the full suite still at 71+6 passed with the same 0
failed it has today.
