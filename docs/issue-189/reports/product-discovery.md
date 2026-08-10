Subject: issue-189

# Phase-2 record — scope-gate `withdrawn` emergency fix

kind: hypothesis-registration
loop_state: measuring

## What was done

Shipped exactly the emergency-fix scope of the approved proposal
(`docs/issue-189/proposals/2026-08-10-scope-gate-withdrawn-emergency-fix-and-lifecycle-registration.md`),
nothing more:

- `warrant/hooks/scope-gate.sh`: `KNOWN_STATES` gained `"withdrawn"`
  (`("proposed", "approved", "landed")` -> `("proposed", "approved",
  "landed", "withdrawn")`). No other line changed — `withdrawn` flows
  through the same known/not-approved/not-enforced branch
  `proposed`/`landed` already take.
- `core/hooks/tests/run-scope-gate-tests.sh`: added a red/green pair
  (`run_status`/`withdrawn-proposal-stands-down`) constructing a
  workspace whose sole proposal carries `status: withdrawn`, asserting
  an ordinary `Write` call is allowed.
- Confirmed `core/hooks/tests/run-all.sh` already registers
  `run-scope-gate-tests.sh` (line 17) — no new registration needed, no
  drift.
- No `rejected` token, no board `loop_state` vocabulary, no issue
  close-reason use — those stay out of scope per the proposal, deferred
  to step 2.

## Why

A live incident in a consumer repo: `status: withdrawn` proposals were
misclassified by `scope-gate.sh` as malformed/unreadable, fail-closed
standing down two controller sessions. `withdrawn` is a legitimate,
already-observed non-warrant lifecycle state — the same bucket
`proposed`/`landed` already occupy — not a genuinely broken payload the
fail-closed posture should catch.

## Test evidence (red/green, run before writing this record)

Red (pre-fix, `warrant/hooks/scope-gate.sh` stashed back to
`KNOWN_STATES = ("proposed", "approved", "landed")`):

```
FAIL   withdrawn-proposal-stands-down     want=allow got=deny
```

Green (post-fix, working tree as committed):

```
ok     withdrawn-proposal-stands-down     allow
== 12 passed, 0 failed ==
```

Full suite (`core/hooks/tests/run-all.sh`): `ALL OK`, no regression on
existing `scope-gate.sh` cases (`approved`-enforcement, malformed
detection, hook-content-inspect carve-out) or any sibling-plugin suite.

## Upstream basis

06956dfca3ffc72c6c66ac867fb16b4b0006b60e (propose(product-discovery):
audit rejection/withdrawal gaps, scope emergency scope-gate fix,
issue-189) — the approved proposal this record delivers against, per
the issue's own step-1 emergency-fix directive.

## Pre-registered hypothesis (carried forward unchanged from the proposal)

Metric, threshold, and decision rule for whether the full lifecycle
work (steps 2-4: canonical rejection act, board `loop_state` refusal
states, issue close-reason use) is worth building are pre-registered
verbatim in the proposal's "Pre-registered hypothesis" section — primary
metric (false-positive brickings on legitimate rejection/withdrawal
states, 0/20 = go, 1-3/20 = pivot, 4+/20 = kill) and guardrail metric
(fail-closed regressions on genuinely malformed input, 0/20 threshold),
both measured over the first 20 fleet role sessions encountering a
rejection/withdrawal state after step 3 ships. No data has been
collected yet — this record's `loop_state: measuring` reflects that the
registration is live and the collection window has not started/closed,
not that a verdict has been reached. The verdict, when the window
closes, will be the mechanical application of this rule, not fresh
judgment.

## Guardrail status at this measurement point

Guardrail status: **not breached** at this delivery's own build-time
check — the full `core/hooks/tests/run-scope-gate-tests.sh` suite,
including every pre-existing malformed/unparseable-state case, is
green after the fix, so this delivery introduces no fail-closed
regression. This is distinct from the pre-registered guardrail's own
20-session measurement window (steps 2-4), which has not opened yet;
the guardrail there remains formally unmeasured until that window
runs, and this record does not claim otherwise.

## ITWWS (if this works we should ...)

Carried forward unchanged from the proposal, deferred (not actioned
here): if the pre-registered hypothesis validates (0/20), extend the
same gate-parseable-negative-outcome pattern to any future binary
lifecycle vocabulary this repo adds beyond
proposal/approval/loop_state/issue-closure. Deferred because it is a
future issue's scope, out of issue-189's scope, and because it is
conditioned on a measurement window (steps 2-4) that has not yet
started.

## Opportunity-solution tree disposition

Branch, in OST's four-layer vocabulary: outcome — role sessions in
consumer repos never brick on a legitimate lifecycle state;
opportunity — `scope-gate.sh` misreads `status: withdrawn` as
malformed and fail-closed stands sessions down; candidate solution —
add `withdrawn` to `KNOWN_STATES` as a non-warrant known state (this
delivery); discriminating assumption test — the pre-registered
hypothesis above (0/20 false-positive brickings = go).

This delivery **promotes** the candidate-solution branch (the
`KNOWN_STATES` addition) from proposed to **shipped/landed on this
branch** — it is not yet promoted to "validated" on the tree, since
that promotion is gated by the pre-registered hypothesis's own
measurement window (steps 2-4), not by this delivery alone. No branch
is pruned: `rejected` and the full lifecycle vocabulary remain live,
un-pruned candidate branches deferred to step 2, not killed.

## Open findings

None from this delivery. The scope-gate change is a single-line
`KNOWN_STATES` addition with a matching red/green test; the emergency
fix does not touch the `approved` enforcement path, malformed
detection for genuinely unparseable states, or any sibling gate.

## Next steps

- Steps 2-4 (canonical rejection act, board `loop_state` vocabulary,
  issue `state_reason` consumption) are architecture's call, aligned
  with on-the-record #573 — not started here.
- Begin the 20-session measurement window once step 3 ships a
  rejection/withdrawal-recognizing vocabulary for the primary/guardrail
  metrics above to count against.

## Resolution path

No open findings to resolve. The pre-registered hypothesis resolves at
step 4 (execution-observation ‖ conformance-review per the issue's
plan) by applying the fixed threshold to the 20-session count once
step 3 ships.
