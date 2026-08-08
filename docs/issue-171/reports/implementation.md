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

## Resolution path (superseded — see session 2 below)

The prior open finding resolved: issue #173's fix (merged to `main`,
commit `edf25ed`, PR #174) landed a content-based `directive.sh` check
(`gate_is_role_directive_stub` in `core/hooks/lib/gate-lib.sh`). This
branch merged `main` in session 2 to pick it up.

## Session 2 — Batch 0 re-scan, Batch 1 attempt, new blocking finding

**Batch 0 re-scan (post-#173-merge):** cloned `content-design-rulebook`
fresh and ran `core/hooks/tests/fleet-silent-failure-scan.sh` against it
directly (not just `compliance-check.sh --canon-duplication` in
isolation, per the runbook's step 6). Result: `content-design-rulebook |
clean`. Confirms the #173 fix resolves the prior blocker for this repo.
No PR needed against `content-design-rulebook` — its `directive.sh` was
already the correct stub, as this record's session-1 pilot attempt had
predicted. Batch 0 is done.

**Batch 1 attempt (10 repos, count 1-2):** cloned all 10
(`market-analysis-rulebook`, `accessibility-rulebook`,
`requirements-engineering-rulebook`, `architecture-rulebook`,
`user-discovery-rulebook`, `pricing-rulebook`, `observability-rulebook`,
`localization-rulebook`, `legal-compliance-rulebook`,
`capacity-planning-rulebook`) and ran the fleet scan on each:

- Clean already, no action: `market-analysis-rulebook`,
  `requirements-engineering-rulebook`.
- Non-canon findings out of this rollout's scope (six-signal sweep hits,
  not canon-duplication — per the runbook's step 6, these are
  justification candidates, not something this rollout unit fixes):
  `user-discovery-rulebook` (fail-open-on-internal-error),
  `observability-rulebook` (fail-open-on-internal-error),
  `legal-compliance-rulebook` (mktemp-footgun).
- `pricing-rulebook`: flagged `canon-duplication` on
  `pricing/plugins/pricing-scope-gate/hooks/scope-gate.sh`. Attempted the
  runbook's step-1 mechanical delete, then inspected the file's content
  **before pushing** (this session's own added caution, not a runbook
  step) — it is not a vendored copy of any core canon file at all. It is
  `pricing-scope-gate`'s own PreToolUse gate (checks a `scope-gate
  result:` labeled line, sources `gate-lib.sh` by reference per the
  gate-house standard) that happens to share the filename `scope-gate.sh`
  with a core canon file of a completely different purpose
  (`core/hooks/tests/scope-gate.sh`). The deletion was reverted before
  any commit or push; branch discarded locally, nothing landed against
  `pricing-rulebook`.
- `architecture-rulebook`: flagged `canon-duplication` on `directive.sh`
  despite the file being a genuine `core_role_directive` stub (sources
  `role-directive.sh`, calls `core_role_directive` with four values).
  `gate_is_role_directive_stub` rejects it because it also sources
  `gate-lib.sh` and calls `gate_kill_switch_active` as an explicit early
  guard (a deliberate, commented design choice per issue-16) — a shape
  `core/hooks/tests/canon-forms.txt` does not register alongside
  `single-call`/`fragment-loop`.
- `accessibility-rulebook`, `localization-rulebook`,
  `capacity-planning-rulebook`: each has more than one `directive.sh`
  under different plugin subdirectories. In `accessibility-rulebook`,
  `accessibility/hooks/directive.sh` is a correct stub, but
  `wcag-em-directive/hooks/directive.sh` is a second, independent
  SessionStart hook (explicitly documented in its own header as
  layering additionally, not replacing or calling
  `core_role_directive`) — `gate_is_role_directive_stub` rejects it as
  "does not source role-directive.sh", which is correct-by-design for
  this file, not a defect in it. Same shape suspected (not fully
  confirmed per-file) for `localization-rulebook`'s and
  `capacity-planning-rulebook`'s extra `directive.sh` files.

No commit or push was made to any of the 43 sibling repos this session.

## What did not work (session 2)

- Ran the runbook's step-1 mechanical delete
  (`find <repo> -name <manifest-filename>` then delete every hit) against
  `pricing-rulebook`'s `canon-duplication` hit on `scope-gate.sh`,
  expecting a vendored core file per the runbook's own framing ("the
  authoritative list, not a hand-picked subset"). Reading the file's
  content before pushing showed it was an unrelated, legitimately-named
  gate specific to `pricing-scope-gate`, not a vendored copy of anything.
  The runbook's step 1 is unsafe as written for any manifest entry other
  than `directive.sh`: it deletes by filename match alone, with no
  content check, for the 12 other manifest filenames
  (`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`,
  `parse-check.sh`, `stub-check.sh`, `gate-lib.sh`, `gate-lib.py`,
  `compliance-check.sh`, `hunt-guard.sh`, `hunt-state.sh`,
  `scope-gate.sh`, `state.sh`, `warrant-hunter.md`) — exactly the same
  class of bug #173 fixed for `directive.sh`, still open for the rest of
  the manifest.

## Open findings (session 2)

- **Blocking for Batch 1 and the rest of the rollout:**
  `compliance-check.sh --canon-duplication` matches every manifest
  filename except `directive.sh` by name only, with no content check —
  confirmed to misclassify at least one real per-repo file
  (`pricing-rulebook`'s `pricing-scope-gate/hooks/scope-gate.sh`) as a
  canon duplicate. Any rollout step that deletes on this signal alone,
  for any of the other 12 manifest filenames, risks destroying
  legitimate role-specific files fleet-wide. Fix needs the same
  structural/content classification `gate_is_role_directive_stub` added
  for `directive.sh`, generalized (or file-specific) for the rest of the
  manifest — lives in `core/hooks/tests/compliance-check.sh` /
  `core/hooks/lib/gate-lib.sh`, outside this PR's frozen write set.
- **Blocking for `architecture-rulebook`, and any repo whose stub
  legitimately composes `gate-lib.sh` guards alongside
  `role-directive.sh`:** `core/hooks/tests/canon-forms.txt`'s registered
  shape set (`single-call`, `fragment-loop`) does not cover this pattern,
  so `gate_is_role_directive_stub` false-positives a correct stub. Fix is
  a new registered form in `canon-forms.txt` (or a broader "additional
  guard lines are fine if they only call `gate_lib_*` functions" rule) —
  outside this PR's frozen write set.
- **Blocking for any repo with more than one `directive.sh` (confirmed:
  `accessibility-rulebook`; suspected, unconfirmed:
  `localization-rulebook`, `capacity-planning-rulebook`):**
  `gate_is_role_directive_stub` (and by extension
  `--canon-duplication`) has no notion of "this repo has one canonical
  role stub plus N legitimately-independent layered directive files" —
  it flags every hit against the single-stub shape. Needs either a
  per-repo allowlist mechanism or a documented registration convention
  for layered directives (`docs/issue-7/proposals/methodology-
  enforcement.md` section 1 already names "composes alongside via
  hooks.json ordering" as sanctioned — the check just doesn't know
  about it) — outside this PR's frozen write set.

## Next steps

- Open a follow-up proposal (new issue, same pattern as #173) to
  generalize `compliance-check.sh --canon-duplication`'s content check
  beyond `directive.sh` to the rest of `canon-manifest.txt`, and to
  extend `canon-forms.txt` / add a layered-directive allowlist mechanism
  for the two `gate_is_role_directive_stub` gaps found this session.
- Until that lands, this rollout may only act on scan results with
  **manual content verification of every hit**, never a blind
  filename-match delete — this record's own "What did not work" entry
  is the reason. Batch 0 is closed (genuinely clean, zero manifest hits
  to verify). Batch 1's two clean repos
  (`market-analysis-rulebook`, `requirements-engineering-rulebook`) need
  no action. `pricing-rulebook` needs no action (its flagged file is not
  a duplicate). The remaining Batch 1 repos' canon-duplication findings
  (`accessibility-rulebook`, `architecture-rulebook`,
  `localization-rulebook`, `capacity-planning-rulebook`) stay open,
  blocked on the follow-up fix — per the runbook's own rule, a
  canon-duplication finding is never a justification candidate, so
  Batch 1 cannot close and Batch 2 does not open until then.
- Regenerate the Batch 1-4 roster programmatically from issue-171's
  embedded finding-count table (still outstanding from session 1).

## Resolution path (superseded — see session 3 below)

The open findings resolve when a follow-up proposal + PR generalizes
`compliance-check.sh --canon-duplication`'s content-based check to the
full manifest and closes the two `gate_is_role_directive_stub` gaps
(missing `canon-forms.txt` shape; no layered-directive allowlist), and a
re-run of the fleet scan against the four blocked Batch 1 repos shows
clean. Batch 1 does not close, and Batch 2 does not open, until then.

## Session 3 — post-#175 re-scan of the four blocked Batch 1 repos

Issue #175 (content-hash canon-duplication for the full manifest + new
`canon-forms.txt` stub shapes — `unregistered-stub`, `layered-directive`)
merged to `main` (PR #176, commit `e0e172a`). This branch merged `main`
to pick it up, then re-cloned and re-ran
`core/hooks/tests/fleet-silent-failure-scan.sh` against all four repos
that were blocking Batch 1 at the end of session 2.

Result: all four still report a `canon-duplication` finding on their
`directive.sh`. Reading each file's actual content shows why #175 did
not close them:

- `architecture-rulebook/architecture/hooks/directive.sh`: sources
  `gate-lib.sh`, calls `gate_kill_switch_active`, then sources
  `role-directive.sh` and calls `core_role_directive` — three non-blank/
  non-comment lines beyond the call itself. #175's `unregistered-stub`
  shape (`canon-forms.txt`) expects a single line matching
  `^[A-Za-z_]+_directive_extra$`, built from a *stated assumption* about
  this repo's shape (#175's own record says so — no access to the real
  bytes at the time). The assumption does not match the real file, so
  the false positive persists unchanged.
- `accessibility-rulebook/wcag-em-directive/hooks/directive.sh`: same
  pattern — #175's `layered-directive` shape (a `.` line matching
  `*layered-directive.sh`) was also a constructed guess, not read from
  this file, and does not match its actual source line.
- `localization-rulebook`, `capacity-planning-rulebook`: same
  `canon-duplication` class persists (unconfirmed per-file, consistent
  with session 2); each also still carries its own `mktemp-footgun`
  finding, unrelated to canon and out of this rollout's scope per the
  runbook.

No commit or push was made to any of the four sibling repos this
session. `docs/issue-171/reports/implementation/rollout-runbook.md`'s
re-scan log was updated with this round's results (Batch 0 confirmed
clean; Batch 1's two already-clean repos and `pricing-rulebook`
confirmed no-action; the four blocked repos' specific mismatch reasons
recorded) — the frozen write set for this PR.

## What did not work (session 3)

- Expected #175's merge to close the two `gate_is_role_directive_stub`
  gaps this record's session 2 flagged as blocking, and re-ran the fleet
  scan against the same four repos expecting `clean`. All four still
  fail: #175's new `canon-forms.txt` shapes were built from stated
  assumptions about each repo's real content (documented as such in
  #175's own record) rather than the real bytes, and the assumed
  patterns do not match what these repos actually contain.

## Open findings (session 3)

- **Still blocking Batch 1, unchanged in kind, now confirmed against
  real repo bytes:** `canon-forms.txt`'s `unregistered-stub` and
  `layered-directive` patterns do not match `architecture-rulebook`'s
  or `accessibility-rulebook`'s actual `directive.sh` content. A correct
  fix needs the real file content transcribed into the pattern (or a
  broader rule — e.g. "any additional lines that only source
  `gate-lib.sh`/call its exported functions, or source a sibling
  `*-directive.sh` file, are fine") rather than another guessed literal
  pattern. Lives in `core/hooks/tests/canon-forms.txt` /
  `core/hooks/lib/gate-lib.sh`, outside this PR's frozen write set.
- `localization-rulebook` and `capacity-planning-rulebook`'s
  canon-duplication hits remain unconfirmed per-file (same open item as
  session 2) and their `mktemp-footgun` findings remain out of this
  rollout's canon scope.

## Next steps

- Open a new follow-up proposal/issue (same pattern as #173, #175) that
  fixes `canon-forms.txt`'s `unregistered-stub` and `layered-directive`
  patterns against `architecture-rulebook`'s and `accessibility-rulebook`'s
  actual `directive.sh` bytes (read directly from the real repos, not
  reconstructed from the issue description) — and confirm
  `localization-rulebook`/`capacity-planning-rulebook`'s per-file shape
  while at it.
- Re-run the fleet scan against all four once that lands; only then can
  Batch 1 close and Batch 2 open.
- Regenerate the Batch 1-4 roster programmatically from issue-171's
  embedded finding-count table (still outstanding since session 1).

## Resolution path

The open findings resolve when a follow-up proposal + PR corrects
`canon-forms.txt`'s two new shapes against the real `directive.sh` bytes
of `architecture-rulebook` and `accessibility-rulebook`, and a re-run of
the fleet scan against all four blocked Batch 1 repos shows clean. Batch
1 does not close, and Batch 2 does not open, until then.
