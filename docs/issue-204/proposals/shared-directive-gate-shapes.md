---
status: proposed
files:
  - core/hooks/directive.sh
  - core/hooks/tests/run-directive-shape-tests.sh
---

## Request

The on-the-record cross-repo audit (#726) found three gate-enforced
shapes that every role currently learns only from a gate refusal,
because no role-independent directive text states them: (1) a session
touching `docs/specs/*` must regenerate `docs/specs/reconciled-index.md`
before commit; (2) the phase-1/phase-2 PR-trailer split
(`Closes/Fixes/Resolves #n` forbidden in phase-1, required in phase-2)
exists only in the `coding` rulebook's own directive, not shared; (3) a
clean-pass test claim must not omit pasted `SKIPPED` lines, and a
hand-typed pass count must match the pasted summary. Promote all three
into the shared role directive every session receives.

## Constraints

- Mirror exactly what each gate checks — no drifting second copy of the
  rule.
- Shared text lives in `core/hooks/directive.sh` (injected into every
  role session), not in a single rulebook's own `directive.sh`.
- New bullets follow the existing heredoc's bullet style and voice.
- No gate script changes — the referenced gates
  (`spec-index-preflight.sh`, `pr-preflight.sh`,
  `role-test-claim-guard.sh`) live in another repo (on-the-record) and
  are out of this repo's write set; this proposal only adds the missing
  proactive text.

## Rationale

Considered adding the three shapes to `core/hooks/lib/role-directive.sh`'s
`core_role_directive` function instead, since that is also "the shared
role directive" by the issue's own wording. Rejected: that function's
body renders only the boilerplate framing (preamble, kill-switch,
RECORD/RECORD FORMAT footer) around each rulebook's own four
role-specific paragraphs — it has no place for role-independent protocol
rules that aren't part of any rulebook's role identity. The three shapes
here (spec-index regen, PR trailer phasing, test-claim fidelity) apply
identically regardless of role, exactly like the branch-per-issue and
new-file-staging bullets already in `core/hooks/directive.sh`'s own
heredoc (added for issue-203) — that file, not the library helper, is
where core already puts this class of rule.

## What will be done

Append three bullets to the interaction-protocol heredoc in
`core/hooks/directive.sh`, after the existing operational-surface-file
bullet and before the heredoc's closing `EOF`:

1. **Spec-index regeneration**: a commit that stages a change to any
   `docs/specs/*` file must also regenerate and stage
   `docs/specs/reconciled-index.md` (`python3 gates/spec_index.py
   --update`) in the same commit — mirroring
   `spec-index-preflight.sh`'s refusal.
2. **PR trailer phase split**: phase-1 proposal PRs reference their
   issue as a plain `#<issue>` in the body; `Closes`/`Fixes`/`Resolves
   #<issue>` is forbidden until the phase-2 delivery PR, which must
   carry it — mirroring `pr-preflight.sh`'s `check_body`. (This
   restates, for every role, what the `implementation` role directive's
   own ISSUE REFERENCE paragraph — visible in this session's
   `[implementation]` SessionStart block — already states for one role;
   the shared bullet is the promoted, role-independent version.)
3. **Test-claim fidelity**: a reply claiming a clean pytest pass must
   not omit pasted `SKIPPED` lines without acknowledging them, and a
   hand-typed pass count must equal the pasted summary's count —
   mirroring `role-test-claim-guard.sh`'s #334/#435 checks.

Add `core/hooks/tests/run-directive-shape-tests.sh`, following
`run-role-directive-staging-tests.sh`'s precedent shape: render
`core/hooks/directive.sh` with `CLAUDE_ROLE=implementation`, assert each
of the three bullets' key phrases is present, and include one
empty-state fixture per bullet (a hand-built string lacking the phrase
must fail the check) so the test can't pass vacuously.

## Out of scope

- Editing any individual rulebook's own `directive.sh` (e.g. removing
  the now-duplicated ISSUE REFERENCE paragraph from `coding`'s
  directive) — that lives in a separate repo, outside this repo's write
  set.
- Rows 2, 19 (record-shape specifics) and row 25 (advisory) from the
  audit — lower priority per the issue, not touched here.
- Any gate-script change in on-the-record — those gates already enforce
  correctly; this proposal only adds the missing proactive text.
- Wiring the new test file into `core/hooks/tests/run-all.sh` —
  `run-role-directive-staging-tests.sh` (issue-203's precedent) was
  never wired in either; consistent, not an omission.

## How you'll know it worked

`bash core/hooks/tests/run-directive-shape-tests.sh` exits 0, with each
of the three shape assertions and their empty-state fixture assertions
reported `ok`, and fails (non-zero) if any of the three bullets is
missing or reworded away from what the gates check.
