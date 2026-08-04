---
kind: coding-record
subject: issue-122
produced_by: implementation
code_under_review: `core/hooks/directive.sh`
loop_state: landed
upstream:
  - path: docs/issue-122/proposals/2026-08-04-mirror-trailer-rule-into-directive.md
    sha: 7fba271c4101f8be8699d7ca32c7b4a030353e3f
---

# Implementation record — issue-122

## Why

Phase 2, approved via issue-level comment `APPROVE issue-122/implementation`
(exact string, posted by an approvers.md account, jjongkwann, on issue #122;
author and approver are the same account, so this is single-account mode
per contract v3 s19). Delivering the approved proposal's two `## What will
be done` items: mirror contract §13's commit-trailer requirement into
`core/hooks/directive.sh`'s printed protocol, and record the anti-bloat
criterion governing this heredoc's own future growth — both reusing the
§22 mirror shape issue-106 already landed (commit `ce4e81c`).

## What was done

1. `core/hooks/directive.sh:9-12` — added one sentence to the file's own
   header comment (which already states the file's pairing obligation with
   `board-gate.sh`, lines 2-4) recording the anti-bloat criterion: this
   heredoc mirrors a contract rule only once a gate has been observed
   repeatedly catching a session on it — an anticipated-but-unobserved
   friction point is not, by itself, grounds for a new bullet.
2. `core/hooks/directive.sh:116-119` — inserted one new dash-prefixed
   bullet in the printed `[core] Interaction protocol` heredoc, immediately
   after the existing "Output layout, enforced" bullet and before the
   existing "Headless/single-shot" bullet (same adjacency the proposal's
   `## What will be done` item 1 specified). States: a commit that stages
   any `docs/issue-<n>/**` work must use `git commit -m` and carry a
   `Subject: issue-<n>` trailer naming that issue (contract v3 s13), one
   commit per subject — the same requirement `trailer-gate.sh` already
   enforces mechanically at commit time.
3. Ran `bash core/hooks/tests/run-all.sh` (below, `## Verify`) — full
   suite green, confirming the two comment/heredoc edits did not break
   shell syntax or any existing gate/canon-form test. No test in this repo
   asserts the heredoc's content (confirmed in the phase-1 survey), so no
   test file needed a change — this run confirms that expectation held.
4. This record.

## What did not work

None. Both write-set edits (header comment sentence, heredoc bullet)
landed as drafted on the first attempt; `run-all.sh` was green on the
first run with no fix-up needed.

## Doc-placement ladder

- [x] No `docs/decisions/` entry. The proposal document itself
  (`docs/issue-122/proposals/2026-08-04-mirror-trailer-rule-into-directive.md`,
  `## Rationale`) already carries the required alternative-and-reason
  record for the one choice this issue makes (mirror shape and header-
  comment placement vs. a new handbook file, vs. verbatim §13 text, vs.
  bullet position) — this delivery is that already-decided choice's
  execution, not a second, separate decision needing its own
  `docs/issue-122/decisions/` file.
- [x] No `docs/handbooks/<component>.md` entry. No environment variable,
  config key, dependency, migration, or run/setup/deploy step was
  introduced or changed — contract §21's handbook trigger does not fire.
- [x] `docs/issue-122/reports/implementation.md` (this file) — the
  phase-2 record, per contract §11/§19.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in issue-90/93/94/98/100/106's
records). In its place, adopted the stance directly by inspection,
following the same local precedent.

### before-landing — stance: assume this mirror and another plugin's directive text cancel each other or drift apart — find the pair

Verdict: NO FINDING (follow-up recorded, not a blocking pair)
Seed: `git diff` of `core/hooks/directive.sh` against sibling plugin
directives (`warrant/hooks/directive.sh`, `scout/hooks/directive.sh`).

#### Reproduce

```
grep -rn "Subject: issue\|trailer-gate\|commit -m" warrant/hooks/directive.sh scout/hooks/directive.sh
```
→ no output: zero occurrences in either sibling plugin's directive text.

#### Observed

Neither `warrant/hooks/directive.sh` nor `scout/hooks/directive.sh` mirrors
the commit-trailer requirement either — the same absence this issue's own
proposal `## Out of scope` already named and explicitly declined to fix
("issue #122's own text scopes the fix to `directive.sh` (singular, core's
printed protocol); extending the same mirror to the other two plugin
directives is a separate decision this proposal does not make for them").
This is a pre-existing, already-disclosed scope boundary, not a new
composition gap introduced by this delivery — no finding against this
change. Confirmed no drift between `core/hooks/directive.sh`'s new bullet
and `core/contract/role-handoff-contract.md` §13's text: both state the
same two facts (`git commit -m` required, `Subject: issue-<n>` trailer
required), the contract carrying the full-length version and this bullet
the short consequence-only mirror, matching the §22 precedent's own
division of detail.

## Next steps

- **`warrant/hooks/directive.sh` and `scout/hooks/directive.sh` §13
  mirror (this repo, in scope for a future proposal).** Per this issue's
  own `## Out of scope`, extending the commit-trailer mirror to the other
  two plugin directives was explicitly left undecided, not silently
  skipped. If those sessions show the same trailer-gate friction this
  issue was opened to fix, a follow-up issue can propose the same bullet
  for each.
- Requirement 3 (whether trailer-gate denial frequency actually drops in
  role sessions opened after this lands) is an execution-observation-role
  concern for a later step, per this issue's own proposal `## Out of
  scope` — not measured by this delivery.

## Open findings

None. No open finding is raised against another role's record from this
delivery. The `Hunt` result above is a confirmed-and-disclosed scope
boundary (the issue's own `## Out of scope`), carried forward only as a
`## Next steps` recommendation, not a blocking open finding.

## Verify

`bash core/hooks/tests/run-all.sh` → `ALL OK`: board gate 89/0, approval
gate 42/0, gh guard 52/0, role-agnostic gates (trailer/record-fields/
handbook-trigger) 19/0, stub-check canon forms 3/0, compliance-check
scan-scope 4/0; `terse`/`freelunch`/`scout` sibling-plugin parse-checks
(including the edited file, `core/hooks/directive.sh`) all `ok`; freelunch
observe.sh enforcement 9/0.

`grep -n "Subject: issue" core/hooks/directive.sh` → line 117, the new
bullet (was: no output, per the proposal's own "How you'll know it
worked" baseline).

`grep -n "mirror only\|repeatedly catching\|anticipated-but-unobserved"
core/hooks/directive.sh` → lines 11-12, the anti-bloat criterion sentence.
