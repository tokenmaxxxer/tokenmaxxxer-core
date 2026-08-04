---
kind: build-proposal
subject: issue-132
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-132/reports/implementation/survey.md
    sha: same-commit
  - path: docs/issue-124/reports/execution-observation.md
    sha: 841a18c24ffe1c0b517b5aae1a4f8550b66786a5
  - path: docs/issue-124/reports/implementation.md
    sha: fdb620dd73af744d62d1c410d38bc9ae79bd4c05
  - path: docs/issue-124/proposals/2026-08-04-close-remaining-wrapper-parser-differential-habitats-r1-r2-r3.md
    sha: 7fcd4cdb7f3d90253960bf10d6521d749caadb6a
  - path: docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md
    sha: 85d4e29aae564ef06118d8c2abb2a0f22a26576f
---

files: `core/hooks/tests/run-board-gate-tests.sh`, `docs/issue-124/reports/implementation.md`, `docs/handbooks/board-gate-tests.md`, `docs/issue-132/reports/implementation/survey.md`, `docs/issue-132/proposals/2026-08-04-wrapper-class-closeout-r3-write-pin-record-fix-b1b2-note.md`

## Request

Issue #132 inherits three closeout items from `docs/issue-124/reports/
execution-observation.md`'s independent observation of PR #126 (issue-124):

1. **F1** — R3's four landed cases (`run-gate-lib-tests.sh:217-224`) are all
   `headof` read-shape assertions; no suite anywhere pins R3's
   write-direction (fail-closed) behavior. Add one deny case exercising a
   wrapper-own value-taking flag on a git *write* line (e.g.
   `timeout -s KILL 30 git rm …`) to `run-board-gate-tests.sh`, with
   red-green proof.
2. **F2** — `docs/issue-124/reports/implementation.md:321` states "the six
   new cases (2 per habitat)"; the actual diff adds 2 + 2 + 4 = 8 cases
   (the same document's own `## Verify` table, four lines above, already
   states this correctly). Correct the sentence to 8, and judge in this
   proposal whether that in-place edit is inside or outside the #100
   no-retroactive-fix precedent.
3. **B1/B2** — the flag tables' residual, uncovered shapes (git global
   flags beyond `-C`/`-c`; `TRANSPARENT` wrapper value flags beyond the
   four documented ones) are all fail-closed and were already named `## Out
   of scope` by the observed proposal. Record this residue in
   `docs/handbooks/board-gate-tests.md` as an accepted, fail-closed
   limitation, with an explicit expansion trigger, so a future reader does
   not mistake it for an unnoticed gap.

## Constraints

- `TRANSPARENT_FLAG_TAKES_ARG`/`GIT_GLOBAL_VALUE_FLAGS` themselves gain no
  new entries — no speculative table-tightening without a concrete
  over-blocking case (issue's own constraint; see Rationale for the
  grounding of this principle, and a note on the `#262` citation this
  survey could not independently corroborate).
- No change to any of PR #126's landed code
  (`core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`,
  `core/hooks/lib/gate-lib.py`) — this issue is pin, doc, and number only.
- #100's no-retroactive-fix precedent bears on requirement 2; this proposal
  states the judgment and reasoning below rather than assuming either
  direction.

## Rationale

**F1 — the write-direction pin belongs in `run-board-gate-tests.sh`, not
`run-gate-lib-tests.sh`. Rejected alternative: add a fifth, write-shaped
case alongside the existing four `headof` cases in `run-gate-lib-tests.sh`.**
Rejected because it cannot express the thing being pinned:
`gate_head_of`/`_resolve_transparent` (`core/hooks/lib/gate-lib.py:216-262`)
is a pure resolver — it returns a head string and trailing words, with no
allow/deny concept at all. The allow/deny verdict for a `git`-headed
segment is computed one layer up, in `board-gate.sh`'s `_segment_is_failing`
(`:225-253`): `if head == "git": return _git_subcommand(stripped) not in
GIT_READ_SUBCOMMANDS` — and `GIT_READ_SUBCOMMANDS` is a `board-gate.sh`-own
table `run-gate-lib-tests.sh` never references. A "write case" added to
`run-gate-lib-tests.sh` could only assert what head/subcommand the resolver
returns (which the four existing cases about `git log` already establish
the pattern for) — it structurally cannot assert "and this denies," because
denial is not a resolver-level fact. This is exactly execution-observation's
own root-cause finding ("R3's fix lives in a pure resolver where the
read/write distinction does not exist"), independently re-derived here by
tracing the actual call path rather than restated from the finding alone.

**F1 — case genuinely exercises the fix, not merely re-testing an existing
sibling.** The existing `run-board-gate-tests.sh:253` case
(`timeout 30 git rm -r docs/issue-49/reports`) carries no value-taking
flag, so `_resolve_transparent` never reaches the `TRANSPARENT_FLAG_TAKES_ARG`
branch for it — it exercises `TRANSPARENT_TAKES_ARG`'s pre-existing
bare-duration skip (issue-114 vintage), not R3. The proposed case adds
`-s KILL` specifically to force the R3 branch (`gate-lib.py:239-241`) to
consume the flag+value pair before the generic walk would otherwise
misread `KILL` as the wrapper's bare positional and `30` as the head.

**Rejected alternative: verdict-flip red-green proof.** The issue's
"red-green 증명" was read, in the survey, as possibly requiring the new
case to fail before the fix and pass after (a verdict flip) — this is
rejected as the framing for this specific case, because it is not
achievable: hand-tracing `_resolve_transparent` with the
`TRANSPARENT_FLAG_TAKES_ARG` branch removed shows the segment resolves to
head `"30"` instead of `"git"`, which is *also* not in
`READ_ONLY_HEADS`/`READ_UNLESS_INPLACE`, so `_segment_is_failing` still
returns `True` (fail-closed by default) — deny, unchanged, exactly the
"deny, unchanged before and after" shape this file's own existing
write-direction siblings (`:253`, `:264`) are already commented with. A
verdict-flip framing would either be false (claiming a flip that doesn't
happen) or would require deliberately weakening `_segment_is_failing`'s
default-deny fallback to manufacture a flip, which would be testing a
different (and worse) bug than R3's. The red-green proof instead composes
two already-true facts: (a) the resolver-level red→green for this exact
flag shape already exists and is genuine (`run-gate-lib-tests.sh:217`,
`headof git 'timeout -s KILL 30 git log' …`, which does return the wrong
head pre-fix and the right one post-fix), and (b) the new board-gate.sh
case demonstrates that verdict now composes correctly end-to-end and stays
fail-closed if the R3 branch is ever removed — verified locally (not
committed) by temporarily neutralizing the `TRANSPARENT_FLAG_TAKES_ARG`
branch and confirming the new case's `deny` outcome is unchanged, the same
verification shape `:253`/`:264` already rest on.

**F2 — judged inside the #100 precedent's carved-out exception, not the
general no-retroactive-edit prohibition, and not an unresolved exception
to it either.** Two things this repo already does under the name
"no-retroactive-edit" are different in shape from this correction:
`docs/issue-118/proposals/…:46-50` and `docs/issue-128/proposals/…:37-39`
both invoke it against *rewriting many past, unrelated records to match a
newly invented convention going forward* (a new required question on every
past `execution-observation.md`; a new citation format on 16+ unrelated
issues' placeholders). Requirement 2 here is neither: it is one document
correcting its own internal arithmetic contradiction — the `## Verify`
table at `implementation.md:308` already, correctly, says "4 new cases" for
R3; the prose four lines below at `:321` sums the same three numbers to 6.
Issue #100's own decision (`docs/issue-100/decisions/…:25-49`, requirement
3 of issue #100's body) already established a directly on-point precedent
for exactly this shape: a dedicated follow-up issue authorizing an in-place
correction of two other, already-merged records
(`docs/issue-90/reports/implementation.md`,
`docs/issue-94/reports/implementation.md`), grounded in a published
observation Finding, under the explicit constraint "판정 내용은 무변경,
인용 형식만" (verdict content unchanged, citation format only). This
delivery's correction matches every element of that precedent: a dedicated
follow-up issue (#132), grounded in a published observation Finding (F2),
changing only a count in a summary sentence, not any verdict, hunt
conclusion, or `closed_checks` result. Judgment: **this correction is
inside the shape #100 already legitimized, not an exception requiring new
justification, and not covered by the general prohibition at all** (the
general prohibition's target — convention-drift retrofits across many
unrelated records — does not describe a single document's own arithmetic
self-contradiction).

**Rejected alternative: leave the wrong number, or add a separate erratum
note instead of editing in place.** Rejected on two grounds. First,
practical: F2's own stated impact is that this is "the one number a later
reader would use to reconcile the RED/GREEN totals" — the record already
contradicts itself internally (`:308` vs `:321`), so leaving it wrong, or
parking the correction in a document a reader would have no reason to
cross-reference, defeats the purpose of a record a later role is expected
to read standalone. Second, precedent-consistency: #100's own
`code_under_review` fix was applied *in place* to issue-90 and issue-94's
records, not via a separate erratum — an erratum-elsewhere approach here
would be a *stricter* rule than #100 itself already applied to a
structurally identical problem, with no stated reason for the asymmetry.

**B1/B2 — a handbook paragraph over expanding the tables.** The observed
proposal itself already made this call for these exact residues: "adding
speculative table entries for hypothetical future flags nobody has hit
would be scope creep in the direction issue #124 is trying to close, not
open" (`docs/issue-124/proposals/…-r1-r2-r3.md:104-117`), and
`execution-observation.md:334-339` independently confirms both B1 and B2
"fall inside the observed proposal's declared `## Out of scope`" and are
"class-status facts about the codebase, not charged against PR #126 as a
scope violation." Issue #132's own body cites `#262`'s decision document
for the same principle; this survey searched this repo and the one other
repo (`tokenmaxxxer/on-the-record`) this codebase's own cross-references
point at for a nearby issue cluster, and found `#262` there to be an
unrelated topic (a CI-gate proposal-file-pattern mismatch), not a
speculative-tightening decision. That citation is not used here as
grounding; the principle is instead cited directly from its real, primary
source above, which is sufficient and already on point. **Rejected
alternative: expand the tables now, using B1/B2 as the concrete cases.**
Rejected because B1/B2 are enumerated from reading `git`/`xargs`/`env`/
`timeout` synopses, not from an observed over-block in an actual command
line any role or user has run — exactly the "no concrete case" condition
the issue's own constraint and the cited proposal text both name as the
line not to cross. A handbook paragraph documents the residue as an
accepted limitation without writing untested, speculative code.

## What will be done

1. **`core/hooks/tests/run-board-gate-tests.sh`** — add one new case,
   placed immediately after the existing R2 negative-space sibling at
   `:264` (`bash-git-c-flag-rm-foreign-issue`), preceded by a comment block
   in this file's established voice naming issue-124/R3, issue-132/F1, the
   root cause (resolver has no read/write concept, pin belongs here), and
   explicitly noting the case denies unchanged before/after (fail-closed
   only):

   ```
   run deny  bash-wrapper-timeout-s-git-rm-foreign-issue Bash '{"command":"timeout -s KILL 30 git rm -r docs/issue-49/reports"}'
   ```

   Verification for the record: run the full suite before this addition
   (baseline pass count), add the case, re-run (pass count +1, 0 failed);
   separately and locally (not committed), neutralize the
   `TRANSPARENT_FLAG_TAKES_ARG["timeout"]` entry in `gate-lib.py`, confirm
   the new case still reports `deny` (fail-closed, no verdict regression
   possible even if R3's fix were removed), then restore the file and
   confirm no diff remains against the landed tree.

2. **`docs/issue-124/reports/implementation.md:321`** — change "the six new
   cases (2 per habitat) are the only additions" to "the eight new cases (2
   + 2 + 4, one read/write pair per R1 and R2 plus R3's four `headof`
   cases) are the only additions" (exact wording may tighten slightly at
   delivery time, but the corrected count — 8 — and the 2+2+4 breakdown are
   fixed by this proposal). No other sentence, field, or verdict in this
   file changes. The edit is a single-line, in-place correction under the
   #100-precedent judgment above — no separate erratum file, no rewrite of
   `code_under_review`, `## Verify`'s table, or any `## Verdict`/`## Hunt`
   content.

3. **`docs/handbooks/board-gate-tests.md`** — append one new paragraph
   after the existing R3 paragraph (currently the file's last content,
   ending `:271`), in the file's established "Also covers … (issue-N): …"
   voice, stating: (a) `GIT_GLOBAL_VALUE_FLAGS` covers `-C`/`-c` only; git
   also accepts its long global flags in a space-joined form the table does
   not recognize (B1); (b) `TRANSPARENT_FLAG_TAKES_ARG` covers one
   value-taking flag per wrapper; `env`, `timeout`, and `xargs` each
   document further value-taking flags the table does not cover (B2); (c)
   both are **accepted, intentionally-bounded, fail-closed limitations**,
   not unnoticed gaps — over-block only, never a hole, per
   `execution-observation.md`'s Axis B; (d) the **expansion trigger**: a
   concrete command line hitting one of these uncovered shapes and being
   over-blocked in real use, mirroring this same handbook's own
   already-established convention for `gap-awk-comparison-over-block`
   (`:116-121`, "kept visible … rather than silently accepted"). A short
   clause may also be added to the existing R3 paragraph's closing sentence
   (`:268-271`) once item 1 lands, since that sentence currently states R3
   is pinned only by `run-gate-lib-tests.sh`'s `headof` cases, which will
   then be one pin short of complete.

## Out of scope

- Any expansion of `TRANSPARENT_FLAG_TAKES_ARG` or `GIT_GLOBAL_VALUE_FLAGS`
  themselves — no new table entries, per the issue's explicit constraint
  and the Rationale above.
- Any other B1/B2-adjacent case (e.g. a specific new `git` long-flag test,
  a specific new `xargs`/`env`/`timeout` flag test) without a concrete
  over-blocking case in hand — the handbook paragraph names the trigger; it
  does not pre-emptively write the cases the trigger would eventually ask
  for.
- Any change to PR #126's landed code
  (`core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`,
  `core/hooks/lib/gate-lib.py`) beyond the one new test case in item 1,
  which touches only the test harness, not the gate scripts.
- Any correction to `implementation.md` beyond the single `:321` sentence —
  `code_under_review`, `## Verdict`/`## Hunt` content, `## Verify`'s table,
  and every other line are left exactly as landed.
- `gh-guard.sh`'s fail-open design and `_cd_target`'s argument extraction —
  both already out of scope for issue-124 and untouched by this issue.
- A standing `docs/decisions/` entry for the F2 judgment above — this
  repo's own precedent (`docs/issue-106`, `docs/issue-118`, `docs/issue-128`)
  carries a record-norm judgment in the phase-1 proposal's own `##
  Rationale` rather than a separate decision document when only one
  delivery consumes it; this proposal follows that shape.

## How you'll know it worked

- `bash core/hooks/tests/run-board-gate-tests.sh` passes in full, with the
  new `bash-wrapper-timeout-s-git-rm-foreign-issue` case included in the
  pass count and 0 failures — this is the case's steady-state proof
  (`deny`, matching every other write-direction sibling in this file).
- Fail-closed proof (the "red-green" the issue asks for, applied correctly
  to a case that cannot flip verdict): with
  `TRANSPARENT_FLAG_TAKES_ARG["timeout"]`'s `-s`/`--signal` entry locally
  neutralized (not committed), the new case still reports `deny` — proving
  the write direction was already, and remains, fail-closed, which is the
  property being pinned; and the *already-existing* resolver-level case
  `run-gate-lib-tests.sh:217` (`headof git 'timeout -s KILL 30 git log'`)
  is re-confirmed to flip from a wrong head to `git` across that same
  neutralize/restore — the genuine red→green this delivery's write pin
  rides on.
- `docs/issue-124/reports/implementation.md:321` reads a count of 8
  matching `2 (run-approval-gate-tests.sh:174,177) + 2
  (run-board-gate-tests.sh:261,264) + 4 (run-gate-lib-tests.sh:217-224)`,
  and the `## Verify` table at `:304-308` and the corrected sentence no
  longer contradict each other.
- `docs/handbooks/board-gate-tests.md` carries a new paragraph naming B1 and
  B2 as accepted fail-closed limitations and stating the expansion trigger
  (a concrete over-blocking case) in the same voice as this file's other
  paragraphs — checkable by a plain read of the file's tail.
