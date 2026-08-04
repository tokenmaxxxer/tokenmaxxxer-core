---
kind: current-state-survey
subject: issue-122
produced_by: implementation
---

# Current-state survey — issue-122

## Write set (projected)

- `core/hooks/directive.sh` — two additions to the same file:
  1. One new bullet in the printed `[core] Interaction protocol` heredoc
     mirroring contract §13's commit-trailer requirement (`git commit -m`
     + `Subject: issue-<n>` trailer, one commit per subject).
  2. One line added to the file's own header comment (lines 1-8)
     recording the "mirror only what the gate repeatedly catches"
     anti-bloat principle, so future additions to this same heredoc are
     judged against a stated criterion instead of accumulating ad hoc.
- `docs/issue-122/reports/implementation.md` — phase-2 record only (not
  written this phase).

No other file needs to move. Requirement 3 (observe whether trailer-gate
friction actually drops after landing) is an execution-observation
concern, not this write set — matches how issue-106's own step 2 was
split out.

## The friction this issue describes, and where the rule currently lives

Issue #122's body (`gh issue view 122`) describes two days of role
sessions hitting `trailer-gate.sh` denials at commit time and re-committing,
because the trailer requirement is stated in only one place a session
reads late, if at all:

- `core/contract/role-handoff-contract.md:493-504` (`## 13. Commit
  trailer requirement`, confirmed by reading the section): every commit
  landing a record or a build must carry the trailer its own rulebook's
  hook enforces; where the trailer names the subject, its value is the
  issue-keyed form (`Subject: issue-<n>`, per section 9). This is
  authoritative but sits mid-document (500+ lines total, §13 of 22
  sections) — not something a session re-reads at commit time, tens of
  minutes after `SessionStart`.
- `core/hooks/directive.sh` — the `SessionStart` hook every role session
  actually reads (confirmed: this very session's own system reminders
  quote its printed text verbatim). `grep -c "[Tt]railer\|Subject:"
  core/hooks/directive.sh` → 0. The printed protocol covers issue-as-
  subject, branch/PR flow, the two-phase gate, output layout, the
  headless-delegation carve-out (§22), and board semantics — but never
  mentions the trailer format a commit must carry, even though the same
  bullets already discuss committing research/proposals/records.
- `core/hooks/trailer-gate.sh` (`PreToolUse`, matches `git commit`,
  read in full) is the enforcing half: it denies a commit that stages
  `docs/issue-<n>/**` work without an inline `-m` message carrying
  `^Subject: issue-<n>$`, or that stages more than one issue's tree in
  one commit. Its own header comment (`:4-14`) already states it
  implements contract §13 — the gate text is correct and unconditional;
  the issue's own constraint (below) is that this gate itself does not
  change.

This is the same informing/enforcing split issue-106 already
established the fix pattern for (see "Internal precedent" below):
`directive.sh` is the informing half, the matching `*-gate.sh` is the
enforcing half, and the file's own header comment already states an
obligation for the pair to "describe the same rules" (`core/hooks/directive.sh:2-4`,
citing contract v3 s10) — but that obligation is currently kept for
`board-gate.sh` only; `trailer-gate.sh` has no equivalent mirror despite
enforcing a rule (§13) that is just as mandatory.

## Internal precedent: the exact same mirror shape, already landed once

`core/hooks/directive.sh` was edited once before for precisely this
reason. Commit `ce4e81c` (issue-106, `git show ce4e81c -- core/hooks/directive.sh`)
added one bullet mirroring the then-new contract §22 (headless-delegation
carve-out) into this same heredoc, with the commit message stating the
rationale: "directive.sh's printed protocol text and adds a subordination
pointer inside freelunch/hooks/freelunch.sh's own directive text, so a
session reading either sees the carve-out in place." That bullet
(`core/hooks/directive.sh:111-118`) was inserted as a new list item
between the existing "Output layout, enforced" bullet and the trailing
"The board is what is MERGED to main" bullet — the file's established
convention is: one short paragraph per rule, dash-prefixed, in the same
heredoc, no sub-headers, no separate file.

This issue (#122) is the same move applied to contract §13 instead of
§22: a rule that already exists in the contract and is already
mechanically enforced by a gate, being additionally mirrored into the
one document every session actually reads at `SessionStart`.

## The anti-bloat requirement (issue's requirement 2) — what exists today

`grep -rn "bloat\|only mirror\|repeatedly catches" core/hooks/directive.sh
core/contract/role-handoff-contract.md docs/handbooks/*.md` → no hits.
No existing file states any criterion for when a rule earns a mirror
into `directive.sh` versus staying contract-only. The only two mirrors
that exist today (`board-gate.sh`'s pairing, stated in the file's own
header comment since before this issue, and §22's bullet from issue-106)
were each added ad hoc, on their own issue's say-so, with no standing
rule connecting them or bounding future additions. Issue #122
requirement 2 asks for exactly that missing bound: mirror only what a
gate has been observed to repeatedly catch, stated once, in
`directive.sh`'s own comment or an appropriate normative doc, so a
future session proposing bullet N+1 has a criterion to argue against
instead of "it seemed important."

`docs/handbooks/` (`canon-scripts.md`, `gate-house-standard.md`, three
`*-tests.md` files — all five read in full) are all standing-clause
documents for gate *implementation* conventions (kill-switch handling,
`gate-lib.sh` usage, canon-vs-copy). None of them address the separate
question of what earns a place in a role-facing *printed protocol*
message — this repo's editorial policy for `directive.sh`'s own content
has never been written down anywhere.

## What `directive.sh` looks like today (structure relevant to the edit)

`core/hooks/directive.sh` (125 lines, read in full) is a single
`SessionStart` hook, not a template sourcing role-specific fragments
(that mechanism, `core/hooks/lib/role-directive.sh`, is a separate file
other rulebooks' own `directive.sh` use — irrelevant here, confirmed by
reading its header). The relevant structure:

- Lines 1-8: shebang + header comment, including the informing/enforcing
  pairing statement this issue's requirement 2 would extend.
- Lines 9-56: fail-closed trap, kill switch, precondition probe (git
  repo / `gh` auth) — unrelated to this change, untouched.
- Lines 58-121: one `cat <<EOF ... EOF` heredoc, ten dash-prefixed
  bullets, printed verbatim as `[core] Interaction protocol for role
  '${role}'`. This is the only heredoc in the file; there is no
  per-bullet gating or conditional printing inside it (confirmed: no `if`
  between `cat <<EOF` and its closing `EOF`), so a new bullet added here
  reaches every role session unconditionally, the same fact issue-106's
  own execution-observation check point 4 already confirmed for the §22
  bullet.

## Test/tooling surface checked, found not coupled

- `core/hooks/tests/run-all.sh` (run this session, `bash
  core/hooks/tests/run-all.sh` → `pass=4 fail=0` / `ALL OK` across all
  four plugins) exercises `parse-check.sh` (`bash -n` syntax only),
  `compliance-check.sh` (scoped to `PreToolUse`-registered gates, not
  `SessionStart` hooks), `stub-check.sh` + `canon-forms.txt`
  (structural-shape checks for rulebooks that source
  `core/hooks/lib/role-directive.sh`'s `core_role_directive` helper —
  `core/hooks/directive.sh` itself does not call that helper, it prints
  its own literal heredoc, so this file is not a member of the set
  `stub-check.sh` classifies against `canon-forms.txt` in the first
  place, confirmed by reading `canon-forms.txt` and `stub-check.sh`'s own
  file-selection logic). No test in this repo asserts the heredoc's
  *content* (grep for `Interaction protocol` or `trailer` across
  `core/hooks/tests/` → no hits) — matches what issue-106's own
  execution-observation record already found true for the §22 bullet
  (`docs/issue-106/reports/execution-observation.md`, check point 4).
- `docs/decisions/` does not exist in this repo yet (`ls docs/decisions/`
  → no such directory). This change is a protocol-text mirror, not a
  library/format/schema choice under contract §21's placement ladder, so
  this survey does not project a write there.
- `docs/specs/approvers.md` — unchanged, no action needed.

## Unknowns

- Whether the anti-bloat criterion, once stated, will actually be
  consulted by a future session proposing bullet N+2 is not something
  this survey or this proposal can verify — it is a norm, not a gate;
  requirement 3's own observation step is the only mechanism that could
  eventually measure whether it holds.
- The exact wall-clock/session-count evidence behind the issue's "오늘
  하루 로그만으로 10회 이상" (10+ trailer-gate denials in one day) claim
  is not independently re-derived by this survey (no session-log access
  from this branch beyond what the issue body already states); the
  proposal treats it as the issue author's own observed background, not
  a figure this role re-verifies.
