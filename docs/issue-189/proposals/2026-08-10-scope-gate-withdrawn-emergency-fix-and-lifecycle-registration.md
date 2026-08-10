---
status: proposed
files:
  - warrant/hooks/scope-gate.sh
  - core/hooks/tests/run-scope-gate-tests.sh
  - core/hooks/tests/run-all.sh
  - docs/issue-189/reports/product-discovery.md
---

## Request

Two things, sequenced per the issue's own directive. (1) Ship the emergency
fix now: `warrant/hooks/scope-gate.sh` treats `status: withdrawn` as an
unreadable/malformed proposal and fail-closed stands the whole session
down — a live incident in a consumer repo (two dead controller sessions,
issues #272/#270 there). (2) Pre-register the hypothesis, metric,
threshold, and decision rule that will govern whether the full
lifecycle work (canonical rejection act, board `loop_state` refusal
states, issue close-reason use) is worth building past step 1, per this
role's registration discipline. No mechanism beyond the emergency fix is
designed in this PR — steps 2-4 of the issue's plan do that.

## Constraints

- The emergency fix touches only `scope-gate.sh`'s existing
  `KNOWN_STATES` tuple and its malformed-detection branch — no new gate,
  no change to the `approved` enforcement path, no vocabulary added
  beyond the one token the live incident needs.
- `withdrawn` is accepted as a *non-warrant* state: same treatment
  `scope-gate.sh` already gives `proposed`/`landed` (readable, known,
  not enforced against). It must NOT become eligible for the `approved`
  write-set/trailer enforcement branch — a withdrawn proposal is closed,
  not in flight.
- `rejected` is named in the issue as a future companion token but is
  **not** added by this fix — the survey (`docs/issue-189/reports/
  product-discovery/survey.md`) found no live incident forcing it now,
  and the full vocabulary (including `rejected`, board `loop_state`
  states, and the canonical rejection act) is architecture's job at step
  2, aligned with on-the-record #573's `verdict`/`finding` shapes — adding
  it piecemeal here would pre-empt that design.
- Every code change needs a runtime red-green test pair (contract
  acceptance criterion: "scope-gate regression test constructing a
  workspace with a withdrawn proposal and asserting Bash/Read/Edit
  pass").

## Rationale

**Alternative considered: treat any unrecognized status as silently
non-enforced (drop the malformed classification entirely).** Rejected —
that is the fail-closed posture the issue explicitly calls correct
("Fail-closed is the right posture; misclassifying a legitimate
lifecycle state as invalid is the defect"). The defect is narrower:
`withdrawn` specifically is a known, legitimate, already-observed state
that deserves a bucket, not a general amnesty for typos or genuinely
broken frontmatter.

**Alternative considered: add `rejected` alongside `withdrawn` in this
same PR, since the issue names both.** Rejected for this PR — the issue's
own sequencing directive scopes the emergency fix to unblocking the
*live* incident (`status: withdrawn` bricking a consumer repo today);
`rejected` has no equivalent live incident forcing an emergency path, and
folding it in now would mean designing (informally, under incident
pressure) a token that step 2's architecture work is supposed to define
deliberately, aligned with #573. Keeping this PR to exactly the tuple
addition the incident needs keeps the emergency fix small and reviewable
on its own merits.

## What will be done (emergency-fix scope)

1. `warrant/hooks/scope-gate.sh` line 39: change
   `KNOWN_STATES = ("proposed", "approved", "landed")` to
   `KNOWN_STATES = ("proposed", "approved", "landed", "withdrawn")`.
   No other line in the malformed-detection, `approved`-selection, or
   stand-down logic changes — `withdrawn` flows through exactly the same
   branch `proposed`/`landed` already take (known, not approved, not
   enforced).
2. `core/hooks/tests/run-scope-gate-tests.sh`: add a red/green pair —
   red: today, a `docs/proposals/*.md` with `status: withdrawn` frontmatter
   causes `scope-gate.sh` to refuse (`exit 1`) on a subsequent Bash/Write/
   Edit call, exactly the consumer-repo failure mode; green: after the
   fix, the same workspace allows ordinary Bash/Read/Edit calls normally
   (gate stands down, no enforcement, no refusal) — matching the issue's
   own acceptance check verbatim.
3. Confirm `run-scope-gate-tests.sh` is already registered in
   `core/hooks/tests/run-all.sh` (no new registration expected — the
   suite exists; only asserting no drift).
4. `docs/issue-189/reports/product-discovery.md`: this role's phase-2
   record (once phase-2 opens per contract v3 s19) — not written in this
   PR's phase-1 commit; listed here only because the frozen write set
   must name it in advance.

## Out of scope

- Adding `rejected` to `KNOWN_STATES` or anywhere else (architecture's
  call at step 2).
- A canonical rejection act/token (candidate 2), board `loop_state`
  refusal vocabulary (candidate 3), or issue `state_reason` consumption
  (candidate 4) — all deferred to steps 2-4 per the issue's plan.
- Any change to `state.sh`'s open-unit reporting (survey finding #5) or
  `approval-gate.sh`'s `CHANGES_REQUESTED`/`DISMISSED` handling (survey
  finding #7) — noted for step 2, not built here.

## How you'll know it worked

- `core/hooks/tests/run-scope-gate-tests.sh`'s new red/green pair passes:
  a workspace with a `status: withdrawn` proposal no longer refuses
  ordinary tool calls.
- `core/hooks/tests/run-all.sh` runs clean, no regression on existing
  `scope-gate.sh` cases (`approved`-enforcement, malformed-detection for
  genuinely unknown/unparseable states, hook-content-inspect carve-out).

## Pre-registered hypothesis — full lifecycle work (steps 2-4)

Per this role's hypothesis-testing/guardrail-metrics discipline, fixed
before any step-2+ data is collected:

- **Hypothesis**: giving rejection/withdrawal a first-class,
  gate-parseable substrate (canonical act, `loop_state` vocabulary,
  issue `state_reason` use) eliminates the class of failure the live
  incident exemplifies — a legitimate negative outcome misread as an
  unreadable/invalid state and bricking a session — without weakening the
  fail-closed posture on genuinely malformed input.
- **Primary metric**: count of sessions, across the fleet, that die or
  stand down (any gate `exit 1`/`exit 2` refusal, or a `malformed`
  classification) on a status/act/state value that the post-step-4
  vocabulary recognizes as a *legitimate* negative-outcome state (i.e.
  false-positive brickings on legitimate rejection/withdrawal states),
  measured over the first 20 role sessions that encounter a
  rejection/withdrawal state after step 3 ships.
- **Threshold / decision rule**: **go** (mechanism validated) if that
  count is **0 out of 20**; **pivot** (vocabulary/token shape needs
  revision, not abandonment) if **1-3 out of 20**, with the specific
  false-positive states feeding step 2's design as a correction; **kill**
  (the substrate itself needs re-architecture, not a patch) if **4+ out
  of 20** — a rate that high means the chosen vocabulary shape, not
  incidental coverage, is wrong.
- **Guardrail metric**: count of sessions, over the same 20-session
  window, where a *genuinely* malformed/unreadable proposal or act (not a
  legitimate negative-outcome state) is incorrectly let through
  (fail-closed regression). Threshold: **0 out of 20** — any breach here
  is a reduced-trust result regardless of the primary metric's outcome,
  because it means the fix traded a false-positive-brick problem for a
  false-negative-safety problem.
- **ITWWS (if this works we should ...)**: extend the same
  gate-parseable-negative-outcome pattern to any future binary lifecycle
  vocabulary this repo adds (the pattern generalizes beyond
  proposal/approval/loop_state/issue-closure) — deferred to a future
  issue, not actioned here, since it is out of this issue's scope.
- **Measurement point**: step 4 (execution-observation ‖ conformance-
  review) per the issue's plan; this registration is written now, at
  step 1, so the step-4 verdict is the mechanical application of this
  rule to the collected counts, not fresh judgment after the numbers are
  in.
