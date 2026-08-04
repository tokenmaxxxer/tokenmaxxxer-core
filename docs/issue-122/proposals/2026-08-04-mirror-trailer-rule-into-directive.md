files: core/hooks/directive.sh

## Request

Issue #122 asks this repo to reduce a two-day-observed pattern (nearly
every role session hitting `trailer-gate.sh`'s commit-trailer denial at
least once and re-committing) by mirroring contract §13's commit-trailer
requirement (`git commit -m` + a `Subject: issue-<n>` trailer, one commit
per subject) into `core/hooks/directive.sh`'s printed `SessionStart`
protocol — the document every session actually reads early, unlike the
500-line contract's §13 (line 493 of 22 sections). It also asks a second,
standing thing to be recorded alongside the mirror itself: a directive-
bloat-prevention principle stating that only rules a gate has been
observed to *repeatedly* catch earn a mirror into `directive.sh`, so this
fix does not become precedent for unbounded future accumulation.
`trailer-gate.sh` itself does not change — the issue is explicit that the
gate already denies correctly; the goal is a session not hitting it in
the first place. Automatic trailer attachment (a gate or hook writing the
trailer for the session) is explicitly rejected by the issue itself, on
two stated grounds: it would race with the gate's own static check at
commit time, and it would defeat the trailer's actual purpose — a session
demonstrating it knows its own subject.

## Constraints

- `core/hooks/trailer-gate.sh` is not modified — it already enforces
  contract §13 correctly (confirmed by reading it in full this session);
  this issue is about a session never reaching the denial, not about
  changing what the denial does.
- No auto-attach mechanism (gate- or hook-written trailer) — ruled out by
  the issue itself for the two reasons above.
- The mirror must land somewhere every session actually reads before its
  first commit — mid-contract text at line 493 does not satisfy this,
  which is the entire premise of the issue.
- The anti-bloat principle must be recorded as a stated, findable
  criterion, not left implicit in this proposal's own reasoning — it has
  to survive past this one issue and be citable by a future session
  proposing bullet N+2.

## Rationale

**Chosen: add one bullet to `core/hooks/directive.sh`'s existing printed
heredoc mirroring §13's consequence, and add the anti-bloat criterion as
one added sentence in that same file's own header comment (lines 1-8) —
no new file.** This is the identical shape issue-106 already used for
contract §22 (commit `ce4e81c`): one dash-prefixed paragraph appended to
the heredoc, no sub-headers, no restructuring. Reusing a shape this
codebase has already run once, with an already-observed outcome
(execution-observation's PR #111 record confirmed the §22 bullet reaches
every role session unconditionally, `docs/issue-106/reports/execution-observation.md`
check point 4), is lower-risk than inventing a new mirror mechanism for
what is structurally the same problem. The anti-bloat sentence goes in
the file's own header comment because that comment already states the
one existing pairing obligation this file carries ("board-gate.sh is the
enforcing half; the two must describe the same rules", `core/hooks/directive.sh:2-4`)
— extending that same comment block keeps every editorial rule governing
this file's heredoc content in the one place someone editing the file
will actually look, rather than splitting related editorial guidance
across two files for one added sentence.

**Alternative considered and rejected: record the anti-bloat principle as
a new standing-clause handbook document under `docs/handbooks/`** (the
pattern `canon-scripts.md` and `gate-house-standard.md` already
establish for gate-*implementation* conventions). Rejected because that
pattern exists for conventions with enough surface area to need their
own reference document (gate-lib usage, canon-vs-copy enforcement, each
with a compliance checker and a migration checklist) — the anti-bloat
principle here is one sentence, no checklist, no enforcement mechanism of
its own, and creating a new handbook file for a single criterion is
disproportionate to what it states. It would also separate the principle
from the one file whose content it governs, requiring a future editor to
know a second document exists at all before finding the rule that bounds
what they are about to add.

**Alternative considered and rejected: mirror the full §13 text verbatim
(trailer key names, the "machine-checkable" framing, the cross-reference
to §9) instead of a short consequence-only bullet.** Rejected on the same
proportionality basis §22's own bullet already settled: every other
bullet in this heredoc restates its source contract section's
*consequence for the reading session* in one short paragraph, not the
section's full text — the contract stays the authoritative, fully-worded
version; `directive.sh` is deliberately the terse pointer. A verbatim
mirror would also make the two texts editable-independently-yet-
supposed-to-match in more places (more surface for exactly the drift the
scout brief's SSOT sources warn about), for no discoverability gain over
a short paragraph stating the same two facts (`git commit -m` required,
`Subject: issue-<n>` trailer required).

**Alternative considered and rejected: place the new bullet at the very
end of the heredoc (after the existing headless-delegation and board
bullets) rather than immediately after the "Output layout, enforced"
bullet.** Every other bullet already discussing where output/records/
commits go (two-phase-PR, output-layout) sits together earlier in the
heredoc; the trailer requirement is a property of the *same* act those
bullets describe (committing what was just written), so placing it
immediately adjacent keeps commit-related guidance contiguous instead of
separated from its nearest neighbors by two bullets on an unrelated
topic (headless execution, board semantics).

## What will be done

1. In `core/hooks/directive.sh`'s printed heredoc, insert one new
   dash-prefixed bullet immediately after the existing "Output layout,
   enforced: code under src/..." bullet and before the existing
   "Headless/single-shot..." bullet. The bullet states: a commit that
   stages any `docs/issue-<n>/**` work must use `git commit -m` and carry
   a `Subject: issue-<n>` trailer naming that issue (contract v3 s13),
   one commit per subject — the same requirement `trailer-gate.sh`
   already enforces mechanically at commit time.
2. In the same file's header comment (lines 1-8), add one sentence
   recording the anti-bloat principle: this heredoc mirrors a contract
   rule only once a gate has been observed repeatedly catching a
   session on it — an anticipated-but-unobserved friction point is not,
   by itself, grounds for a new bullet.
3. Phase-2 record (`docs/issue-122/reports/implementation.md`) will
   quote the exact diff and re-run `bash core/hooks/tests/run-all.sh` to
   confirm the addition does not regress the existing suite (this
   proposal's survey already establishes no test in this repo asserts
   the heredoc's content, so no test file is expected to need a change;
   phase 2 confirms that expectation holds against the actual diff
   rather than assuming it).

## Out of scope

- Any change to `core/hooks/trailer-gate.sh` — the issue's own first
  constraint.
- Any auto-attach/auto-write mechanism for the trailer — the issue's own
  second constraint.
- Requirement 3 (observing whether trailer-gate denial frequency actually
  drops after this lands) — an execution-observation-role concern for a
  later step, the same split issue-106 used between its implementation
  and execution-observation steps; this proposal does not claim to
  measure an outcome it has not yet produced.
- Editing `core/contract/role-handoff-contract.md` — §13 already states
  the rule correctly and completely; this issue is purely about a second,
  reader-facing surface for the same already-correct rule, not a change
  to the rule itself.
- Any `warrant/hooks/directive.sh` or `scout/hooks/directive.sh` mirror —
  neither file currently mirrors §13 either (confirmed absent by the
  same grep the survey ran), but issue #122's own text scopes the fix to
  `directive.sh` (singular, core's printed protocol); extending the same
  mirror to the other two plugin directives is a separate decision this
  proposal does not make for them.

## How you'll know it worked

- `core/hooks/directive.sh`'s printed heredoc contains a new bullet
  stating the `git commit -m` + `Subject: issue-<n>` requirement,
  findable by grep (`grep -n "Subject: issue" core/hooks/directive.sh`
  currently returns nothing; after the change it returns the new
  bullet).
- The same file's header comment states the "mirror only what a gate
  repeatedly catches" criterion, findable the same way.
- `bash core/hooks/tests/run-all.sh` still reports `ALL OK` after the
  change (baseline captured this session: `pass=4 fail=0` / `ALL OK`
  across all four plugins).
- Requirement 3's own measurement (trailer-gate denial frequency across
  role sessions opened after this lands) is left to a later
  execution-observation step, per the split this proposal's "Out of
  scope" section states — this proposal's own success is the mirror
  existing and being read, not yet the friction-reduction outcome.
