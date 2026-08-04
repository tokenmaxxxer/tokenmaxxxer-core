---
kind: current-state-survey
subject: issue-132
produced_by: implementation
---

# Current-state survey — issue-132

## Scouting-skip record

Scouting-for-external-best-in-class does not apply here: this issue closes
three internal-record/test-suite gaps (a missing regression-guard test case,
a wrong count in this repo's own delivery record, and a handbook paragraph)
inside an existing, already-designed gate (`board-gate.sh`/`gate-lib.py`).
There is no external product surface, library choice, or UX decision to
benchmark against — the "best-in-class" reference here is this repo's own
established conventions (already read below), not an outside source. One-line
reason: internal test-suite/decision-precedent task, not a product-shaped
surface.

## F1 — `docs/issue-124/reports/execution-observation.md:356-381`

Verbatim finding: R3 (the `TRANSPARENT_FLAG_TAKES_ARG` wrapper-own-value-flag
fix in `gate-lib.py`) has no write-direction case anywhere in the landed
suites. Its four landed cases are all `headof` assertions in
`run-gate-lib-tests.sh:217-224` (read below), all read-shaped
(`… git log`). Root cause named explicitly: "R3's fix lives in a pure
resolver where the read/write distinction does not exist, so its
write-direction pin would have had to be placed one layer up, in
`run-board-gate-tests.sh`." Both the proposal (`docs/issue-124/proposals/…
-r1-r2-r3.md:156-171`) and the delivery followed the proposal's own R3
sub-bullet, which specifies only `headof` cases — so the gap traces to
proposal text, not to phase-2 deviation.

**Confirmed independently against the actual resolver
(`core/hooks/lib/gate-lib.py:194-251`) and the actual write-verdict path
(`core/hooks/board-gate.sh:181-253`):**

`gate_head_of`/`_resolve_transparent` only returns a **head string** (and
`gate_trailing_words`) — it has no concept of allow/deny. The allow/deny
verdict for a `git`-headed segment is computed in `board-gate.sh`'s
`_segment_is_failing` (`:225-253`): `if head == "git": return
_git_subcommand(stripped) not in GIT_READ_SUBCOMMANDS`. `GIT_READ_SUBCOMMANDS`
(`:181-184`) is a `board-gate.sh`-owned table; `run-gate-lib-tests.sh` never
imports or references it, so a resolver-level `headof` assertion is
structurally unable to express "and the write-shaped subcommand still
denies" — there is no verdict at that layer to assert. This mechanically
confirms F1's own root-cause claim: the write-direction pin can only be
expressed where the allow/deny verdict is actually computed, i.e.
`run-board-gate-tests.sh`.

**Traced the exact case F1's action item names
(`timeout -s KILL 30 git rm …`) through both the current (fixed) and a
hand-simulated pre-fix `_resolve_transparent`:**

- Post-fix (current `gate-lib.py:208-213,239-241`): words
  `["timeout","-s","KILL","30","git","rm",…]` → `"-s"` is in
  `TRANSPARENT_FLAG_TAKES_ARG["timeout"]` (`:211`), so `i` advances by 2
  past `-s KILL`, then `30` is consumed by `TRANSPARENT_TAKES_ARG`'s own
  `skip_extra`, landing head on `"git"`, trailing words `["rm","-r",…]`.
  `_git_subcommand` (`board-gate.sh:212-222`) reads `"rm"` — not in
  `GIT_READ_SUBCOMMANDS` — **deny**.
- Pre-fix (no `TRANSPARENT_FLAG_TAKES_ARG` branch): `"-s"` is treated as a
  bare flag (`i+=1`), `"KILL"` is consumed by `skip_extra` (mistaken for
  the wrapper's own bare arg), head lands on `"30"` — not `"git"`, not in
  `READ_ONLY_HEADS`/`READ_UNLESS_INPLACE` — `_segment_is_failing` still
  returns `True` (unresolved head, fail-closed) — **also deny**.

**Consequence for phase 2's "red-green 증명" requirement:** this exact case
is fail-closed both before and after the fix, at the whole-segment verdict
level — the same "deny, unchanged before and after" shape every other
write-direction sibling already in `run-board-gate-tests.sh` uses (e.g.
`bash-wrapper-timeout-git-rm-foreign-issue:253`,
`bash-git-c-flag-rm-foreign-issue:264`, both commented exactly that way).
It is **not** a case that flips allow→deny at the board-gate.sh layer; the
red→green flip for R3 already exists, and lives, correctly, at the resolver
level (`run-gate-lib-tests.sh`'s four `headof` cases, which do change return
value pre/post-fix). The new case's job is different: it is a
regression-guard "pin," not a bug-catching red→green — this is an open
design decision for the proposal's `## How you'll know it worked`,
resolved below.

One more check: the existing R2/R3-adjacent case at
`run-board-gate-tests.sh:253` (`timeout 30 git rm -r docs/issue-49/reports`,
`bash-wrapper-timeout-git-rm-foreign-issue`) does **not** exercise
`TRANSPARENT_FLAG_TAKES_ARG` at all — it carries no `-s`/value-taking flag,
so `_resolve_transparent` never reaches the `TRANSPARENT_FLAG_TAKES_ARG`
branch for it. A new case genuinely needs a wrapper-own value flag
(`-s KILL`, `-n 10`, `-u FOO`, or `-I …`) to exercise R3's actual code path;
the existing case alone does not cover it.

## F2 — the record's added-case count

`docs/issue-124/reports/implementation.md:321` (exact line, confirmed by
direct read): "Every pre-existing case in all three harnesses is unchanged
(`ok` in both the pre-edit baseline runs done for RED capture and the final
post-fix runs); **the six new cases (2 per habitat)** are the only
additions." This is the sentence issue #132 asks to correct.

The same document's own `## Verify` table, four lines above
(`implementation.md:304-308`), is internally accurate and gives the real
per-habitat breakdown:

| habitat | RED | GREEN |
|---|---|---|
| R1 | `43 passed, 1 failed` | `44 passed, 0 failed` |
| R2 | `90 passed, 1 failed` | `91 passed, 0 failed` |
| R3 | `53 passed, 5 failed` (4 new cases + 1 pre-existing) | `57 passed, 1 failed` |

R1: 44−43 = 1 new case (its deny sibling at `run-approval-gate-tests.sh:177`
is additional — the table's RED/GREEN count is the *read*-direction
regression, not a raw case count; the actual diff below settles this).
Reading the actual diff `fdb620d` cited by both `implementation.md:308` and
`execution-observation.md:389`: `run-approval-gate-tests.sh:174,177` = **2**
cases (R1); `run-board-gate-tests.sh:261,264` = **2** cases (R2);
`run-gate-lib-tests.sh:217-224` = **4** cases (R3). Total: **2+2+4 = 8**, not
6. This matches `execution-observation.md`'s Finding F2 exactly
(`:383-399`), which independently reconciled the same arithmetic and flagged
it as "the one number a later reader would use to reconcile the RED/GREEN
totals," root-caused to "the '2 per habitat' convention inherited from
#114's one-pair-per-habitat pattern was carried into the summary sentence
after R3's shape had already diverged to four `headof` cases."

**No other number in the document needs correction** — F2's own text states
this and I independently re-read the surrounding paragraph
(`implementation.md:301-345`): `43→44`, `90→91`, `53→57`, and the final
`44/0, 91/0, 57/1` all reconcile against the diff; only the prose
"six … (2 per habitat)" is wrong.

## `core/hooks/tests/run-board-gate-tests.sh` — structure and R3 gap, confirmed

Read the full file (398 lines). Confirms F1's premise precisely, with one
correction to this survey's own brief: the task brief described this file
as holding "the 4 landed read-form cases like `… git log`" for R3 — that is
not accurate. Those four cases are in `run-gate-lib-tests.sh:217-224` (see
above), not here. `run-board-gate-tests.sh` currently has **zero** R3-shaped
cases in **either** direction (read or write) — it exercises R1 (via
`run-approval-gate-tests.sh`, a different file) and R2 (`git -C`/`-c`,
`:261,264`) directly, and consumes R3 only *transitively* (any `timeout
…`-wrapped `git` case in this file passes through the fixed resolver, but no
case specifically targets a wrapper's own value-taking flag). This is
exactly the layer-and-gap F1 names: the write-direction pin belongs here,
and nothing here today exercises it at all, in either direction.

Harness conventions confirmed by reading the full file:
- `run <want> <name> <tool> <input-json-fragment>` — the general helper,
  used for most cases including all `Bash`-tool git/wrapper cases.
- Existing wrapper-git-write siblings this file already documents as
  "deny, unchanged before and after" (the same rhetorical shape a new R3
  case would use): `bash-wrapper-timeout-git-rm-foreign-issue` (`:253`),
  `bash-git-c-flag-rm-foreign-issue` (`:264`).
- Comment convention: every fix/gap gets a `# --- <topic> ---` or `#
  <issue-n>, <habitat>: <one-paragraph explanation>` block immediately
  before its case(s), citing the originating issue and (for negative-space
  siblings) explicitly noting "stays denied, both before and after."
- Naming convention: `bash-<wrapper>-<flag-shape>-<verb>-foreign-issue`
  (e.g. `bash-wrapper-timeout-git-rm-foreign-issue`,
  `bash-git-c-flag-rm-foreign-issue`) — a new case should follow this
  pattern, e.g. `bash-wrapper-timeout-s-git-rm-foreign-issue`.
- Report/count convention: `pass`/`fail` counters, final line
  `== N passed, M failed ==`, exit 1 iff `fail>0` — no per-group manifest
  in this file (unlike `run-gate-lib-tests.sh`'s `mark`/mandatory-groups
  convention).

## `core/hooks/lib/gate-lib.py` — resolver tables, read in full context

- `TRANSPARENT = (...)` (`:194-195`) — the eight wrapper heads.
- `TRANSPARENT_TAKES_ARG = ("timeout",)` (`:200`) — wrappers with a bare
  positional argument of their own (unrelated to R3/B2, pre-existing).
- `TRANSPARENT_FLAG_TAKES_ARG` (`:208-213`) — the R3 table, exactly four
  entries (`nice: -n/--adjustment`, `env: -u/--unset`,
  `timeout: -s/--signal`, `xargs: -I`), docstring at `:202-207` states these
  are "the subset of TRANSPARENT members with a documented own value-taking
  flag in common shell usage," citing `gate_wrapper_head_before`'s own
  docstring as source.
- `_resolve_transparent` (`:216-251`) — the resolver; consumes
  `TRANSPARENT_FLAG_TAKES_ARG` entries (`:239-241`) before the generic
  bare-flag/`skip_extra` walk gets a chance at the value token. This is a
  pure head/trailing-words resolver with **no allow/deny concept** — confirms
  why the write-direction pin cannot live here (see F1 above).
- `gate_head_of`/`gate_trailing_words` (`:254-273` approx.) — the two public
  accessors `board-gate.sh` consumes.

`core/hooks/board-gate.sh` (`:181-253`, read in full context): owns
`GIT_READ_SUBCOMMANDS` and `GIT_GLOBAL_VALUE_FLAGS` (both `board-gate.sh`-only
tables), `_git_subcommand`, and `_segment_is_failing` — the actual
allow/deny computation for a `git`-headed segment. Confirms: the R3 fix's
*mechanism* lives in `gate-lib.py`; the R3 fix's *consumer/verdict* lives in
`board-gate.sh`, exactly where the issue and F1 say the write-direction pin
belongs.

## `docs/handbooks/board-gate-tests.md` — read in full (271 lines)

Structure: one prose paragraph per landed fix, in landing order, each
citing its originating issue number, the exact code/table changed, and the
pinning test case name(s), in the same voice throughout ("Also covers …
(issue-N): …", ending in a sentence naming which case(s) pin the fix). The
file ends (`:229-271`) with the two issue-124 paragraphs already covering R2
(`:229-248`, the `git`-own global-value-flag paragraph) and R3
(`:250-271`, "as this gate's fail-closed consumer" paragraph) — the R3
paragraph's last sentence already states plainly: "`board-gate.sh` carries
no code change for R3 … but the R2 test cases above already exercise the
corrected resolver transitively; R3 itself is pinned directly by new
`headof` cases in `run-gate-lib-tests.sh`." This sentence will need one
clause added once phase 2 lands a direct `run-board-gate-tests.sh` pin too
(currently accurate, will become incomplete, not wrong, once F1 is closed).

No B1/B2 "accepted limitation" paragraph exists anywhere in this file today
— confirmed by reading the full file; the nearest related text is exactly
the sentence above (R3, and the R2 paragraph's own "`-C`/`-c` only" scoping
sentence at `:236-237`), neither of which states the residue is an accepted,
intentionally-bounded limit with an expansion trigger. This is the gap
requirement 3 closes.

## `docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md` and `docs/issue-100` (issue text via `gh issue view 100`) — read in full

issue #100 itself (closed) is about a **different**, but structurally
analogous, self-citation defect: `code_under_review`/`closed_checks[].code_sha`
citing a docs-only proposal commit instead of the code commit. Its decision
doc's Decision 1 (`:25-49`) replaced the sha with a file list (write-time
knowable); its own requirement 3 (issue body) explicitly *did* authorize
in-place correction of two other, already-merged issues'
own records — `docs/issue-90/reports/implementation.md` and
`docs/issue-94/reports/implementation.md` — with the constraint "**판정
내용은 무변경, 인용 형식만**" (verdict content unchanged, citation format
only). This is a real, on-point precedent for *bounded, judgment-preserving,
in-place correction of an already-merged record*, done by a dedicated
follow-up issue, grounded in an observation finding
(`docs/issue-90/reports/execution-observation.md` /
`docs/issue-94/reports/execution-observation.md`, both Finding 2).

Separately, the *general* "no-retroactive-edit" principle this repo invokes
elsewhere (`docs/issue-118/proposals/…:46-50`, `docs/issue-128/proposals/…
:37-39`) targets a **different** shape of edit: retroactively rewriting many
past, unrelated records to match a *newly invented* convention going
forward (e.g. not rewriting every past `execution-observation.md` to add a
new required question; not rewriting the 16+ issues still carrying an
unrelated placeholder). Issue #132 requirement 2 is neither of these
shapes — it is one document's own arithmetic self-contradiction (the
Verify table at `:308` already says "4 new cases" for R3; the prose at
`:321` sums to 6), grounded in a specific, already-published observation
Finding (F2) — closer in shape to #100's own carved-out exception than to
the general prohibition. This judgment, and its citation to the concrete
#100 decision text above, is carried into the proposal's `## Rationale`.

## `#262` — could not locate a matching decision document

Issue #132's body cites "#262 결정 문서의 같은 원칙" (the same principle as
#262's decision document) for the B1/B2 "no speculative table-tightening
without concrete over-blocking cases" stance. Searched:

- This repo (`tokenmaxxxer-core`): no `docs/issue-262/` tree exists;
  `gh issue view 262` returns "Could not resolve to an issue or pull
  request with the number of 262" in this repo.
- `tokenmaxxxer/on-the-record` (the only other repo this codebase's own
  cross-references point at for a nearby "#245/#262/#266" cluster, per
  `docs/issue-118/proposals/…:16-18`, "otr #245/#262/#266"): issue #262
  there exists but is a **different, unrelated topic** — `gates.py`'s
  `_always_writable()` proposal-file-pattern mismatch blocking a CI-gate
  bundle (confirmed via `gh issue view 262 --repo tokenmaxxxer/on-the-record`,
  full body read). It says nothing about speculative table-tightening.
- No other repo in `gh repo list tokenmaxxxer` (searched by name for
  "table"/"speculative"/"투기") surfaced a plausible match.

**Conclusion for the proposal:** the `#262` citation in issue #132's body
cannot be independently verified against a real, on-point decision document
in this or the one other repo this codebase cross-references. The
underlying principle itself, however, *is* independently and directly
grounded in this same delivery's own primary source: `docs/issue-124/
proposals/2026-08-04-close-remaining-…-r1-r2-r3.md:104-117` ("Scoping the
flag tables minimally, not exhaustively" — "adding speculative table
entries for hypothetical future flags nobody has hit would be scope creep
in the direction issue #124 is trying to close, not open"), which is the
text `execution-observation.md:334-339` already cites as the reason B1/B2
are "class-status facts … not charged against PR #126 as a scope
violation." The proposal's Rationale will cite this primary source directly
and note the `#262` reference could not be independently corroborated,
rather than asserting a cross-repo citation this survey could not confirm.

## Exact write set expected for phase 2

- `core/hooks/tests/run-board-gate-tests.sh` — one new deny case, placed
  near the existing R2/wrapper-git block (`:249-264`), following the
  established naming/comment convention, e.g.
  `bash-wrapper-timeout-s-git-rm-foreign-issue` for
  `timeout -s KILL 30 git rm -r docs/issue-49/reports` (want `deny`).
- `docs/issue-124/reports/implementation.md:321` — the phrase "the six new
  cases (2 per habitat)" corrected to "the eight new cases (2 + 2 + 4, one
  per habitat pair plus R3's four)" or equivalent, matching the Verify
  table already on `:304-308`. No other line in this file changes.
- `docs/handbooks/board-gate-tests.md` — one new paragraph appended after
  the existing R3 paragraph (currently ending at `:271`), naming B1
  (`GIT_GLOBAL_VALUE_FLAGS` covers `-C`/`-c` only; git's long global flags
  also accept a space-joined form the table does not cover) and B2
  (`TRANSPARENT_FLAG_TAKES_ARG` covers one flag per wrapper; `env`/`timeout`/
  `xargs` document more) as an accepted, fail-closed, intentionally-bounded
  residue, plus the expansion trigger (a concrete over-blocking case, not
  speculative coverage). A small addendum clause to the existing R3
  paragraph's last sentence (`:268-271`) may also be needed once the new
  `run-board-gate-tests.sh` case exists, to keep that sentence accurate.

No other file is touched in phase 2. `run-board-gate-tests.sh`'s existing
content, `implementation.md`'s frontmatter/verdict/Verify-table content
other than the one phrase, and the handbook's existing paragraphs are all
left as-is.

## Open design decisions (for the proposal to resolve)

1. **Test-case exact form and name.** Resolved above by tracing the
   resolver: `timeout -s KILL 30 git rm -r docs/issue-49/reports` (the
   issue's own suggested form) genuinely exercises
   `TRANSPARENT_FLAG_TAKES_ARG["timeout"]`, unlike the existing
   `timeout 30 git rm …` sibling. Proposed name:
   `bash-wrapper-timeout-s-git-rm-foreign-issue`.
2. **What "red-green 증명" means for a case that denies both before and
   after the fix.** Resolved above: the code-level red→green already exists
   at the resolver layer (`run-gate-lib-tests.sh`'s four `headof` cases);
   the new `run-board-gate-tests.sh` case is a same-shape regression-guard
   sibling, matching this file's own established "deny, unchanged before
   and after" convention for write-direction siblings. The proposal's `##
   How you'll know it worked` will frame the proof this way rather than
   claiming a verdict-level flip that the resolver mechanics do not
   support.
3. **F2 exception judgment under #100.** Resolved above: correcting
   `implementation.md:321` is judged **inside** the shape #100's own
   decision already exercised (bounded, in-place, verdict-preserving,
   citation/count-only correction of one's own already-merged record,
   grounded in a published observation Finding) — not an invocation of, or
   exception to, the *general* no-retroactive-edit prohibition, which
   targets a materially different shape of edit (rewriting many unrelated
   past records to match a new convention). The rejected alternative
   (leave the sentence wrong, or add a separate erratum note elsewhere) is
   argued in the proposal's Rationale.
4. **B1/B2 paragraph wording and expansion trigger.** Both residues are
   fail-closed (over-block only, never a hole) per
   `execution-observation.md:289-333`, and both are already-named `##
   Out of scope` items in the observed proposal
   (`docs/issue-124/proposals/…-r1-r2-r3.md:191-209`), corroborated by
   `execution-observation.md:334-339`'s "class-status facts, not a scope
   violation" framing. The new paragraph states this status plus a
   concrete expansion trigger: a real command line hitting one of the
   uncovered shapes (git's space-joined long global flags; `env`/`timeout`/
   `xargs`'s other documented value-taking flags) and being over-blocked in
   practice — mirroring this file's own already-established
   "over-blocking is the safe direction, tightened only on concrete
   evidence" posture (seen verbatim for `gap-awk-comparison-over-block`,
   `:116-121` of the same handbook file).
