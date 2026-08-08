---
code_under_review:
  - docs/issue-171/reports/implementation/rollout-runbook.md
loop_state: open
---

# Fleet canon rollout — phase 2 execution (issue-171)

## What was done

Phase 1's approved runbook
(`docs/issue-171/reports/implementation/rollout-runbook.md`) defines a
5-batch rollout (pilot + 4 count-ascending waves) across 43 sibling
rulebook repos. This session confirmed `ADMIN` write access to the org's
rulebook repos (the phase-1 proposal's stated "no write access" was
written before that was checked — see `## Rationale for deviations`) and
attempted **Batch 0 (pilot)**: `content-design-rulebook`.

Pilot attempt:

1. Cloned `content-design-rulebook`. Its layout is six independent plugin
   subdirectories (`content-design/`, `content-design-ab-spec/`,
   `content-design-decision-rationale/`, `content-design-phase1-basis/`,
   `content-design-self-critique/`, `content-design-tone-axis/`), each
   with its own `hooks/hooks.json`. Checked every one against
   `core/hooks/tests/canon-manifest.txt`: none of the 13 vendored-gate
   filenames (`trailer-gate.sh`, `record-fields-gate.sh`, etc.) are
   present anywhere in the clone. Only `content-design/hooks/directive.sh`
   exists, and it is already the current-pattern thin stub — it sources
   `core`'s `hooks/lib/role-directive.sh` and calls `core_role_directive`
   with its four role-unique strings, not a vendored copy of shared
   logic.
2. Ran `core/hooks/tests/fleet-silent-failure-scan.sh` against the clone
   before touching anything (runbook step 5, done early since step 1's
   delete list came up empty). It still reported one finding:
   `canon-duplication: ... vendored copy of core canon file 'directive.sh'
   found under <path>`.
3. Traced the cause in `core/hooks/tests/compliance-check.sh`
   (`--canon-duplication` mode, lines ~35-49): it flags any file matching
   a manifest-listed **name**, `directive.sh` included, with no content
   check. `directive.sh` is on `canon-manifest.txt` alongside genuinely
   vendor-and-delete files, but its own intended pattern (documented in
   `core/hooks/lib/role-directive.sh`'s own header comment, and matching
   the runbook's step 2) is a small per-repo stub that is *kept*, not
   deleted — the stub itself is what every rulebook is supposed to have
   locally. `content-design-rulebook` already has exactly that stub, and
   the scan still fails it as a duplicate.

Stopped here: no commit was made to `content-design-rulebook`, no PR was
opened, and `docs/issue-171/reports/implementation/rollout-runbook.md`'s
re-scan log was left as `(none run yet)` rather than logged as pilot
`clean`, because the pilot did not actually reach clean and forcing an
edit to `content-design-rulebook` (or to `core/hooks/tests/
compliance-check.sh`, which is outside this proposal's frozen write set:
`docs/issue-171/reports/implementation/rollout-runbook.md`) to make it
appear clean would misrepresent what was verified.

## Why

Executed the phase-1 approved plan's pilot-first ordering (validate the
mechanical stub swap and the `${CLAUDE_PLUGIN_ROOT}` sibling-resolution
path against one real external repo before Batch 1 opens) exactly as
`docs/issue-171/reports/implementation/rollout-runbook.md` specifies.
The pilot surfaced that the runbook's own premise — "a remaining
canon-duplication finding always means step 1 was incomplete, never a
candidate for justification" — does not hold for `directive.sh`
specifically, because `compliance-check.sh --canon-duplication` cannot
distinguish a genuinely-vendored copy from the intended per-repo stub
that step 2 itself instructs keeping. This is exactly the class of
signal the pilot batch exists to catch before it propagates through 42
more repos (per the runbook's own rationale for per-batch re-scanning
rather than a single end-of-rollout scan).

## Upstream

Basis: `docs/issue-171/proposals/2026-08-08-fleet-canon-rollout-plan.md`
(approved) and `docs/issue-171/reports/implementation/rollout-runbook.md`.

## Rationale for deviations

Two deviations from `## What will be done`, both discovered mid-pilot:

1. **Access.** The phase-1 proposal's `## Constraints` stated this repo
   "has no write access to the 43 sibling rulebook repos" and framed
   phase-2 execution as "an orchestration dispatch against each rulebook
   repo, not a commit from this repo." This session verified actual
   access (`gh repo view tokenmaxxxer/content-design-rulebook --json
   viewerPermission`) and found `ADMIN`. Superseded by finding 2 below —
   this access was never used to write to the sibling repo.
2. **Scope-exceeded stop.** The pilot repo's `directive.sh` cannot be
   brought to a passing scan by the runbook's steps 1-6 alone: the false
   positive traces to `core/hooks/tests/compliance-check.sh`'s
   `--canon-duplication` mode, a file outside this PR's frozen write set
   (`docs/issue-171/reports/implementation/rollout-runbook.md`). Per the
   scope-exceeded rule, this session finished what the runbook's steps
   could reach (steps 1-3 confirmed as no-ops for this repo; step 5's
   scan run) and stopped rather than editing `compliance-check.sh`
   unreviewed, or pushing a PR to `content-design-rulebook` that the
   scan cannot actually confirm clean.

## What did not work

- Ran `core/hooks/tests/fleet-silent-failure-scan.sh` against the pilot
  clone expecting a single `canon-duplication` finding fixable by the
  runbook's step 2 (directive.sh stub swap). The clone's `directive.sh`
  was already the target-pattern stub, and the finding persisted anyway
  — `compliance-check.sh --canon-duplication` matches by filename only,
  so it cannot tell "vendored copy, needs replacing" apart from "correct
  stub, already in place." The runbook's assumption that "a remaining
  canon-duplication finding always means step 1 was incomplete" is false
  for `directive.sh`.

## Open findings

- **Blocking for Batch 0 completion:** `compliance-check.sh
  --canon-duplication` cannot distinguish a vendored copy of
  `directive.sh` from the intended per-repo stub, so it will report a
  false `canon-duplication` finding for every repo that already has (or
  correctly adopts) the stub pattern — not just `content-design-rulebook`.
  Fixing this requires either a content check (e.g. does the file source
  `role-directive.sh` and call `core_role_directive`) or removing
  `directive.sh` from `canon-manifest.txt`'s delete-list semantics and
  giving it a separate stub-shape check. That fix lives in
  `core/hooks/tests/compliance-check.sh`, outside this PR's frozen write
  set — it needs its own proposal.

## Next steps

- Open a proposal to fix `compliance-check.sh --canon-duplication`'s
  `directive.sh` handling (content-based check, not filename-only) before
  Batch 0 can close.
- Re-run the pilot against `content-design-rulebook` once that fix lands;
  only then log the re-scan result and open the pilot's own PR (which,
  per this repo's finding, may end up being a no-op for
  `content-design-rulebook` itself — its `directive.sh` was already
  correct).
- Regenerate the Batch 1-4 roster programmatically from issue-171's
  embedded finding-count table (the runbook flags the hand-copied roster
  as carrying transcription risk) before opening Batch 1's PRs.

## Resolution path

The open finding resolves when a follow-up proposal + PR fixes
`compliance-check.sh --canon-duplication`'s `directive.sh` detection and
a re-run of the pilot scan against `content-design-rulebook` shows clean
(or a justified, non-`directive.sh` finding). Batch 1 does not open until
then, per the runbook's own gate.
