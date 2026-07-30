---
subject: issue-53
role: coding
loop_state: scope-proposed
---

# Current-state survey — issue #53

## The three-way disagreement, located exactly

1. **Contract text says PR, never issue.**
   - `core/contract/role-handoff-contract.md:329-331` (section 10, "The
     interaction channels"): "Approval, acceptance, and refusal comments
     are always attached to the PR under review, never the issue; an
     issue comment is never approval provenance."
   - `core/contract/role-handoff-contract.md:683-685` (section 19,
     single-account mode): "A role recording provenance for this signal
     must cite the PR comment (its URL or PR-comment id), never the
     issue — an issue comment is never approval provenance."
   - The issue text cites the first as "s8:330"; read against the file as
     it exists on this branch today, line 330 falls inside **section
     10** ("Where records live"), not section 8 ("The human's seat") —
     section 8 (lines 238-260) contains no "never the issue" text at all.
     This is a citation discrepancy worth recording plainly (survey rigor
     floor), not silently corrected: the substance (the clause to remove)
     is unambiguous and located at 329-331 regardless of which section
     number the issue meant.
2. **The gate reads the PR only.** `core/hooks/approval-gate.sh:202-214`:
   the only GitHub lookup is `gh pr view <branch> --json reviews,comments`
   (lines 203-206); there is no `gh issue view` call anywhere in the
   file. Confirmed by reading the full 262-line file.
3. **Practice already treats the issue comment as canonical, ahead of
   both the gate and (in one spot) the contract text.** `git show -s
   0800649` (issue-46, PR #47, on this branch's history) carries in its
   commit body: "Approved via issue-level comment APPROVE
   issue-46/coding (single-account mode, PR #47 author and approver same
   account)." That PR's phase 2 proceeded on an issue-comment approval
   the gate as read today (point 2) cannot check — direct, in-repo
   evidence that the gate is not actually the thing that authorized that
   session's phase-2 writes, matching the issue's own claim ("It has not
   been denying, which means the gate is not actually loaded in the
   sessions doing this work").

The fourth location the issue names — `on-the-record/commands/run.md`,
`README.md:293`, `protocol.md` declaring the issue canonical — is **not
in this repository**. `find on-the-record` and a repo-wide search for
those filenames from this checkout return nothing; `on-the-record` is a
separate repo this coding role has no branch, no write access, and no
issue open in. Recorded as an **unknown/out-of-scope boundary**, not
silently dropped: whatever `on-the-record` itself must change to stay
aligned is that repo's own issue, not this one's write set.

## Practice evidence: the two-PR pattern

The issue's own body cites five issue→two-PR pairs (issue-126→#127/#128,
issue-129→#130/#131, issue-132→#133/#134, issue-135→#137/#138,
issue-115→#117/#118, issue-73→#77/#136). This survey did not re-derive
that list (no `gh pr list --state all` scan of historical PR pairs was
run — recorded as an unknown rather than re-verified, since the issue's
own citation is specific enough to act on and re-scanning would not
change the decision below). Locally confirmed instead: `gh pr list
--state open` returns `[]` repo-wide at survey time — no PR is currently
open on any branch, so this change lands with zero in-flight approvals
of any kind to migrate or break.

## Write-set surfaces, current state

- **`core/contract/role-handoff-contract.md`** — 838 lines, `status:
  final`, 21 numbered sections. The two clauses above are the only
  "never the issue" occurrences (`rg -n "never the issue"
  core/contract/` → exactly these two lines). Section 19's single-account
  paragraph (lines 670-688) is otherwise unrelated to this issue's scope
  except for the clause being replaced.
- **`core/hooks/approval-gate.sh`** — 262 lines. Structure: bash
  preamble (kill switch, role check, fast-path), a `python3` heredoc
  doing the actual adjudication. The single `gh pr view` call (lines
  203-214) feeds both the two-account review check (lines 225-235) and
  the single-account PR-comment check (lines 237-246). No issue-number
  extraction exists yet, though the branch-role regex (`m = re.match(
  r"^issue-[0-9]+/(.+)$", branch)`, line 168) already isolates the digits
  needed — it currently discards them (`m.group(1)` in the branch-name
  match is `.+` for the role tail, not the issue number; the number is
  only present in the branch string itself).
- **`core/hooks/tests/run-approval-gate-tests.sh`** — 167 lines. The
  `stub_gh` helper (lines 27-42) writes ONE static stub script that
  answers `gh pr view ... --json reviews,comments` with a fixed JSON
  blob per named mode (`human`, `comment-challenge`, `bot`, `agent`,
  `revoked`, `nopr`, etc.), regardless of the arguments it is actually
  invoked with. It does not currently need to distinguish `pr view` from
  `issue view` calls because only one gh call exists today. This is the
  one file in the write set whose current shape most directly constrains
  phase 2: the stub must become argument-aware to serve two independent
  gh call sites with independently controllable outcomes.

## Alignment check: core #36 and #38

Both fetched via `gh issue view` at survey time: **#36** ("strip wake
routing (s3 table, s15 re-verify edge)") and **#38** ("sweep residual
wake-routing prose") are both `state: OPEN` with **no PR open** for
either (`gh pr list --state open` → `[]`, matching the practice-evidence
check above). Their target text is section 3's routing-judgment prose
and section 15's finding-re-verify edge, plus a residual-prose sweep
across other sections — none of which overlaps the lines this issue
touches (section 10's interaction-channels bullet, section 19's
single-account paragraph). Confirmed by reading both full sections in
the current file: section 3 (lines 80-107) already reads "no routing
table, no host-doc pointer" — a stance #36 wants to reverse (defer
routing to on-the-record's `wake-routing.md`) but that has evidently not
landed yet, consistent with #36 showing no PR. Low line-level collision
risk; both issues are recorded here as a coordination note per the
issue's own request, since a human could still open a PR for either
before this one lands and the merge order isn't this survey's to decide.

## Unknowns, stated plainly

- Whether `on-the-record`'s `run.md`/`README.md`/`protocol.md` will be
  updated in the same round, and by whom — outside this repo, not
  observable from here.
- The exact historical two-PR pairs the issue cites were not
  independently re-verified against `gh pr list --state all` (see
  "Practice evidence" above) — taken as given from the issue body.
- Whether `docs/decisions/` (repo-standing bucket per contract section
  21's literal text) or `docs/issue-53/decisions/` (per this session's
  own role-directive wording) is the intended path for the scope-model
  decision record — both are valid buckets under board-gate's layout
  rule; which one phase 2 uses is left as a phase-2 write-time judgment,
  not a phase-1 blocker.
