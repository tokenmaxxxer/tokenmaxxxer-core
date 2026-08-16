---
kind: execution-observation
subject: issue-227
produced_by: execution-observation
phase: 2
loop_state: handed-off
observed_pr: 228
observed_role: implementation
observed_commits:
  - 1a2d393fdb3c4fd8ace77cf564026e09c5cead74
  - 44bbab5878349a671a80e808a2ed2ee4e970adcc
upstream:
  - path: docs/issue-227/reports/execution-observation/survey.md
    sha: same-commit
  - path: docs/issue-227/proposals/2026-08-16-observe-pr-228-issue-227-execution.md
    sha: same-commit
---

# Execution observation — issue-227, PR #228 (`implementation` role)

## Independence statement

This role did not author or edit the observed artifact this session. No
edit was made to `core/hooks/board-gate.sh`, `warrant/hooks/scope-gate.sh`,
either gate's test suite, `docs/handbooks/board-gate-tests.md`, or
`docs/issue-227/reports/implementation.md`. All evidence below was read,
not re-executed: `board-gate.sh`/`scope-gate.sh` were read as text; neither
gate script nor either test suite was run this session. This statement
precedes all verdict language in this document.

## What was done

Independently observed PR #228 (`fix(issue-227): deny ${IFS} token-fusion
and board-gate indirect-tee write-gate holes`, author `JiwonJung94`),
covering two commits, `1a2d393` and `44bbab5`, against issue #227's two
named residual write-gate holes. Read, this session: `gh pr view 228
--json state,mergedAt,commits,comments` (state `OPEN`, `mergedAt: null`,
three PR comments — an initial adversarial review, an "amended per
review" reply citing `44bbab5`, and a second adversarial re-review citing
three new findings against the amended head); `gh pr diff 228` in full;
`docs/issue-227/reports/implementation.md` as landed in `1a2d393` (read
via the diff). Traced, by hand against the landed pattern text (no gate
execution), the three findings the second re-review comment raises
against head `44bbab5` — B1 (brace-form variable indirection), B2 (board-
gate awk/gawk `system()` write misclassified read-only upstream of the
new `WRITE_UNSAFE_HEADS` check), and finding "d" (scope-gate's new
`awk`/`gawk`/`ed`/`ex` alternative is unconditional, over-blocking pure
reads) — and confirmed all three independently. Renders a three-level
verdict (outcome / trajectory / step) below, per the proposal's
allocation (`docs/issue-227/proposals/2026-08-16-observe-pr-228-issue-227-execution.md`).

## Why

Issue #227 asked the `implementation` role to close two residual write-
gate holes found in core#226's adversarial review of #225: `${IFS}`
token-fusion fail-open (both gates) and board-gate's indirect-`tee` miss.
This role's job, per its governing directive, is to independently judge
whether that phase-1→phase-2 execution was sound by reading the actual
produced artifacts — never by re-running the observed role's code.

## Upstream / basis

- `docs/issue-227/reports/execution-observation/survey.md` (same commit)
- `docs/issue-227/proposals/2026-08-16-observe-pr-228-issue-227-execution.md` (same commit)
- Human approval: issue #227 comment, exact string
  `APPROVE issue-227/execution-observation`, account `JiwonJung94`
  (`docs/specs/approvers.md` lists `JiwonJung94`, `jjongkwann`), read via
  `gh issue view 227 --json comments` this session — opens this role's
  phase 2.

## Level 1 — outcome

Per the spec's recomputation rule: worst case among the step-level
results this record cites (Level 3 below), not a standalone summary.

- **Requirement 1 (`${IFS}`/`$IFS` fail-open)** — partially fixed, then
  reopened by the amendment's own new gap. `1a2d393`'s un-anchored
  `\$\{?IFS\}?` (over-blocking `$IFSHOME`-style reads, per the first
  review comment) was fixed in `44bbab5`'s
  `IFS_TOKEN_RE = re.compile(r"\$IFS(?![A-Za-z0-9_])|\$\{IFS(?=[:}])")`
  (`gh pr diff 228`, board-gate.sh hunk, mode: read — traced the anchored
  pattern by hand against `$IFSHOME`/`${IFS_DIR}`: neither matches,
  confirming the fix). Requirement 1's own narrow scope (bare `$IFS`
  token) is met.
- **Requirement 2 (board-gate indirect-`tee`)** — met.
  `_is_unanalyzable_write_shape`'s new
  `if head == "tee" and not [w for w in gate_lib.gate_trailing_words(stripped) if not w.startswith("-")]`
  branch (`gh pr diff 228`, board-gate.sh hunk, mode: read) covers the
  issue's own repro
  (`echo docs/issue-3/reports/x.md | xargs tee`) and is unaffected by any
  of the three open findings below, which are all scoped to the
  fusion-class extension, not the `tee` fix.
- **Fusion-class extension (added by this PR beyond the issue's literal
  `$IFS` text, to close the same class of hole)** — **not met**. Three
  confirmed step-level deficiencies (Level 3, items 1–3) remain
  unaddressed as of the second re-review comment
  (<https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/228#issuecomment>,
  posted after `44bbab5`, no third commit since — `gh pr view 228 --json
  commits` lists exactly two commits, mode: command). Two are write-gate
  fail-opens (B1, B2); one is a new over-block regression (d).
- **PR merge state** — `OPEN`, `mergedAt: null` (`gh pr view 228 --json
  state,mergedAt`, mode: command, read this session). Not landed on
  `main`.
- **Record's own citations** (`119`/`35`/`ALL OK` in the first commit;
  `126`/`42` in the amendment's PR comment) — `mode: asserted`, per the
  observed role's own record and PR comment text; not independently run
  by this role (execution of the observed role's code is prohibited to
  this role).

**Outcome verdict: FAILED.** The issue's own two named requirements are
individually met, but the PR that is supposed to deliver "closed" (per
its second comment's own claim, "closed the surviving fusion spellings")
still carries three unaddressed, independently-confirmed defects in that
same extension (Level 3, items 1–3), and has not landed. Worst case
among cited step-level results governs: FAILED.

## Level 2 — trajectory (for the observed `implementation` role)

- **scouted-when-required: not applicable, because** the observed
  record's own "Upstream / basis" section (read via the `1a2d393` diff)
  cites `docs/issue-225/reports/implementation.md` and the #225 review
  context as its basis, and issue #227 is tagged
  `validity-consult-skip: trivial` with no separate phase-1 proposal
  artifact visible in the merged tree or the PR's file list (`gh pr diff
  228` file list, mode: read) — consistent with a build-now-shaped
  single-PR delivery rather than a skipped scouting step.
- **surveyed-before-proposing: not applicable, because** the same
  build-now shape applies — no distinct survey-then-proposal sequence is
  visible for this role's step; the PR's single commit carries both
  research-derived basis and delivered code together.
- **approved-by-human: PASS.** Issue #227 comment, exact string `APPROVE
  issue-227/implementation`, account `JiwonJung94`, timestamp
  `2026-08-15T23:30:02Z` (`gh issue view 227 --json comments`, mode:
  read), listed in `docs/specs/approvers.md` (mode: read). Single-account
  mode applies: PR #228's author is also `JiwonJung94` (`gh pr view 228
  --json author`, mode: command). Ordering: approval `23:30:02Z` precedes
  commit `1a2d393`'s author timestamp `23:37:01Z`, which precedes PR
  creation `23:37:13Z` (`gh pr view 228 --json commits,createdAt`, mode:
  command) — monotonic, consistent with contract v3 §19's single-account
  path. This check covers the *implementation* role's approval only, not
  this role's own (recorded separately under Upstream / basis above).

**Trajectory verdict:** two checks not applicable (build-now shape, no
separate phase-1 artifacts to score), one check PASS (human approval,
verified against `docs/specs/approvers.md` and timestamp ordering). No
trajectory defect found.

## Level 3 — step (deficient artifacts)

1. **`warrant/hooks/scope-gate.sh`'s `VAR_INTERP_RE`
   (`core/hooks/board-gate.sh` carries the identical pattern) — brace-form
   indirection bypass.**
   - subject: `VAR_INTERP_RE = re.compile(r"\b(\w+)=(?:python3?|bash|sh|zsh|perl|ruby|node|nodejs)\b[^\n]*\$\1\b[^\n]*-[ce]\b")`
     (`gh pr diff 228`, board-gate.sh hunk, mode: read).
   - test: traced by hand against `P=python3; ${P} -c '...'` — the
     pattern's `\$\1` requires a literal `$` immediately followed by the
     captured variable-name text; `${P}` inserts `{` between `$` and `P`,
     so the pattern does not match. Confirmed independently this session
     (mode: read, on the pattern text, not gate execution) — matches the
     second re-review comment's finding B1
     (<https://github.com/tokenmaxxxer/tokenmaxxxer-core/pull/228>,
     comment asserting the same gap, mode: asserted for the comment's own
     repro claim; mode: read for this role's independent pattern trace).
   - result: **failed**.
   - assertedBy: execution-observation (this role), citing itself, plus
     the observed PR's own unresolved re-review comment as a
     corroborating but independently-reproduced source.
   - Impact: a write-capable command using brace-form variable
     indirection for its interpreter head (`${P} -c '...'`, `${B} -c
     '...'`) still bypasses both gates' fail-closed posture inside a
     write-restricted session — the exact class issue #227 asked to
     close, in an unaddressed spelling.
   - Timeline: introduced in `44bbab5` (the amendment meant to close the
     fusion class); flagged in the PR's second re-review comment, posted
     after `44bbab5`; no follow-up commit since (`gh pr view 228 --json
     commits`, mode: command, 2 commits total as of this session).
   - Root cause: `VAR_INTERP_RE` was written to match only the bare-`$`
     spelling of variable expansion (`\$\1`), not POSIX's brace form
     (`${\1}`), during a fix pass whose own PR body claims the class is
     "closed."
   - Action item: broaden `VAR_INTERP_RE` to match both `\$\1\b` and
     `\$\{\1\}` (or a single `\$\{?\1\}?` alternation), in both
     `board-gate.sh` and `scope-gate.sh`, with a regression test for the
     brace form in both suites, before this PR's "closed" claim is
     accurate.

2. **`core/hooks/board-gate.sh`'s `_segment_is_failing` /
   `READ_UNLESS_INPLACE` — awk/gawk `system()` write bypasses the new
   `WRITE_UNSAFE_HEADS` check entirely.**
   - subject: `READ_UNLESS_INPLACE = ("sed", "awk", "gawk")` (line 109,
     read this session, mode: read) and `_segment_is_failing`'s branch for
     that tuple (lines 226–252, read this session, mode: read): for
     `head in ("awk", "gawk")`, `writes` is set only by `INPLACE.search`
     or `FILE_REDIR.search(stripped)` — both require a raw redirect/`-i`
     token in the command text.
   - test: traced by hand against `awk 'BEGIN{system("touch
     pwn.md")}'` — no `-i`, no raw `>` outside the quoted program
     argument, so `_segment_is_failing` returns `False` (segment
     classified read-only) and the segment never enters
     `_write_candidate_segments`'s `failing` list. `_is_unanalyzable_write_shape`
     — where `44bbab5`'s new `WRITE_UNSAFE_HEADS = ("dd", "awk", "gawk",
     "nawk", "mawk", "ed", "ex")` check lives — is only reached for
     segments already in that `failing` list (`if not own_hits: head =
     gate_lib.gate_head_of(stripped); if _is_unanalyzable_write_shape(...)`,
     itself gated on the segment having failed `_segment_is_failing`
     upstream). The new check is dead code for this exact shape.
     Confirmed independently this session (mode: read, tracing the two
     functions' control flow, not gate execution) — matches the second
     re-review comment's finding B2.
   - result: **failed**.
   - assertedBy: execution-observation (this role), citing itself.
   - Impact: `awk 'BEGIN{system("touch <path>")}'` (or any awk/gawk
     `system()` write) inside a write-restricted board-gate session is
     allowed, not denied — the same masked-write class issue #227 named,
     surviving in board-gate specifically (the PR's own test additions
     only cover the `> "pwn.md"` raw-redirect spelling, which
     `FILE_REDIR` already caught before this PR).
   - Timeline: `WRITE_UNSAFE_HEADS` added in `44bbab5`; the upstream
     misclassification in `_segment_is_failing` predates this PR entirely
     (unmodified by either commit — `gh pr diff 228` shows no hunk
     touching `_segment_is_failing` or `READ_UNLESS_INPLACE`, mode:
     read) and was not caught before merge because the new tests only
     exercise the raw-`>` spelling.
   - Root cause: the fusion-class fix was layered onto
     `_is_unanalyzable_write_shape` without checking that the
     candidate-selection stage upstream (`_segment_is_failing`) actually
     routes awk/gawk `system()`-write commands into that function at
     all — it does not, because `READ_UNLESS_INPLACE`'s awk/gawk branch
     only recognizes writes via a literal redirect/`-i`.
   - Action item: either add a `system(` / (nothing else visibly
     redirecting) detection to `_segment_is_failing`'s awk/gawk branch so
     these segments reach `_is_unanalyzable_write_shape`, or move
     awk/gawk out of `READ_UNLESS_INPLACE` into an always-failing set
     (mirroring `WRITE_UNSAFE_HEADS`'s intent) — with a regression test
     for the `system("touch ...")` repro, in board-gate specifically
     (scope-gate's blanket `\bawk\b` alternative already catches this
     shape, per the diff read in finding 3 below).

3. **`warrant/hooks/scope-gate.sh`'s new `UNANALYZABLE_WRITE_SHAPE`
   alternative — unconditional `awk`/`gawk`/`nawk`/`mawk`/`ed`/`ex`
   over-block.**
   - subject: `r"|(?:^|\s)(?:awk|gawk|nawk|mawk|ed|ex)\b"` (`gh pr diff
     228`, scope-gate.sh hunk, mode: read) — added as a bare alternation
     inside `UNANALYZABLE_WRITE_SHAPE` with no read/write distinction,
     unlike board-gate's `READ_UNLESS_INPLACE` gating.
   - test: traced by hand against `awk '{print $1}' file.txt` — the
     regex matches on the bare word `awk` alone (`(?:^|\s)awk\b`), so
     this pure-read invocation is classified as an unanalyzable
     write-capable shape and hard-denied under a scoped session,
     regardless of whether any write mechanism appears. Confirmed
     independently this session (mode: read, on the pattern against a
     representative read-only invocation) — matches the second
     re-review comment's finding "d" (a new over-block, not a fail-open).
   - result: **failed**.
   - assertedBy: execution-observation (this role), citing itself.
   - Impact: a legitimate read-only `awk`/`sed`-family invocation
     (`awk '{print $1}' file.txt`) is denied in any scope-gated session,
     directly contradicting the issue's own acceptance line ("legitimate
     ... still allow") and this PR's own claimed parity goal with
     board-gate, which does not have this over-block (board-gate's
     `READ_UNLESS_INPLACE` branch, item 2 above, still classifies plain
     awk reads as non-failing).
   - Timeline: introduced in `44bbab5`; flagged in the same second
     re-review comment as B1/B2; no follow-up commit since.
   - Root cause: scope-gate's fix mirrored board-gate's head-name list
     (`WRITE_UNSAFE_HEADS`) without also mirroring board-gate's
     read/write distinction for that same head list — board-gate gates
     awk/gawk on `READ_UNLESS_INPLACE` first; scope-gate's parallel
     addition has no equivalent gate.
   - Action item: scope the new alternative to a write signal (a raw
     redirect, `-i`, or `system(`/`w ` inside the program/script text),
     matching board-gate's own (still-incomplete, per item 2) read/write
     split, rather than a bare head-name match.

4. **`docs/issue-227/reports/implementation.md`'s test-evidence and
   scope claims.**
   - subject: the record's PR-comment amendment claiming "closed the
     surviving fusion spellings" (PR #228 comment, mode: asserted, per
     the observed role's own PR comment, not the record file itself,
     which predates the amendment).
   - test: cross-checked against Level 3 items 1–3 above, all
     independently confirmed open by this role.
   - result: **failed** (the "closed" claim, as stated in the PR
     comment amending the record's basis).
   - assertedBy: execution-observation (this role), citing itself.
   - Impact: a reader trusting the amendment's "closed the surviving
     fusion spellings" comment would believe issue #227's full class is
     resolved; it is not.
   - Timeline: the claim was made in the PR comment following `44bbab5`
     (`2026-08-15T23:52Z`-adjacent, same session as the commit per `gh pr
     view 228 --json comments`, mode: command); the second re-review
     comment (after this) already disputed the claim, and no correction
     followed.
   - Root cause: the amendment's own test suite verifies the specific
     repro commands from the first review round but does not include a
     brace-form-indirection test, a `system()`-write awk/gawk test in
     board-gate, or a plain-read awk/gawk test in scope-gate — so the
     green suite (`126`/`42` per the PR comment, mode: asserted) did not
     surface any of items 1–3.
   - Action item: the record (and the PR body) should state the fusion
     class as partially closed, not closed, pending items 1–3, or issue
     #227 should be explicitly scoped down to its literal `$IFS`
     spelling with the extension's remaining gaps tracked as a follow-up
     — a call for the human to make, not this role.

## Open findings

1. Level 3, item 1 — `VAR_INTERP_RE` brace-form bypass (board-gate and
   scope-gate). Resolution path: broaden the regex, add a brace-form
   regression test in both suites.
2. Level 3, item 2 — board-gate awk/gawk `system()` write bypasses
   `WRITE_UNSAFE_HEADS` via upstream `READ_UNLESS_INPLACE` misclassification.
   Resolution path: route awk/gawk `system()`-shaped segments into
   `_is_unanalyzable_write_shape`, or move them to an always-failing set;
   add a `system("touch ...")` regression test in board-gate.
3. Level 3, item 3 — scope-gate's new awk/gawk/nawk/mawk/ed/ex
   alternative over-blocks pure reads. Resolution path: scope the
   alternative to an actual write signal, matching board-gate's
   read/write split; add a plain-read regression test.
4. Level 3, item 4 — the PR's "closed the surviving fusion spellings"
   claim is inaccurate against items 1–3. Resolution path: human
   decision on whether to correct the claim, land a further amendment, or
   split the extension's remaining scope into a follow-up issue.

## Next steps

This record is complete; no further action by this role. The human
approver decides how to act on the four open findings — most directly,
whether to request a further amendment on PR #228 before merge, or split
the unresolved fusion-class spellings into a follow-up issue.
