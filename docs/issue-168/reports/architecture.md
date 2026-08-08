# architecture — issue-168, phase 2

Proposal: docs/issue-168/proposals/2026-08-08-fleet-scan-driver.md

## Context

Issue-163's A8 recorded all 43 rulebook repos as `blocked: needs-repro-
access`, treating the fleet as unreachable. Phase 1's survey
(`docs/issue-168/reports/architecture/survey.md`) showed that premise
false: all 43 `*-rulebook` repos under the `tokenmaxxxer` org are
public and clonable via plain HTTPS `git clone`, no auth, nothing
`gh-guard.sh` intercepts. `core/hooks/tests/compliance-check.sh` is
already path-parameterized (`--canon-duplication <path>`). The missing
piece was purely a driver to enumerate, clone, scan, and aggregate.

## Decision

Build an **orchestrator clone-and-run** driver (not a scheduled sweep):
`run-fleet-scan.sh` enumerates the fleet via `gh repo list`, shallow-
clones each repo to a temp dir, and calls a new per-repo scanner,
`fleet-silent-failure-scan.sh`, which reuses `compliance-check.sh`
unmodified for canon-duplication and adds a grep-based sweep for the
six silent-failure signal categories from issue-142/163. Output is one
row per repo (`clean` or `FINDING: ...`); a clone failure is its own
`CLONE-FAILED` row. `blocked` is never emitted for a repo that was
actually reached.

## Consequences

- The fleet-scan half of issue-163/#168 is now runnable synchronously
  from any session with `gh`/network access — no scheduled-job
  infrastructure was added, so there's nothing new to operate or
  monitor for failure.
- `run-fleet-scan.sh` is sweep-callable as-is if drift-over-time
  monitoring is wanted later (a cheap follow-up, not built now).
- The six-category sweep is heuristic (grep-based), not the deeper
  Explore-agent read pass issue-163 used on this checkout's own scope;
  it will produce candidate hits requiring human/role triage, same as
  #163's A1-A7 findings did. This run already surfaced 36 `mktemp-
  footgun` + 1 `canon-duplication` candidates (see below) that route to
  a follow-up issue, not fixed in this one.
- Every fleet run performs 43 network clones; wall-clock and GitHub
  rate-limit exposure scale with fleet size — acceptable at 43 repos,
  worth revisiting if the fleet grows an order of magnitude.

## Alternatives considered

- **Scheduled sweep (issue's option B)** — rejected: the fleet is
  synchronously reachable with a bare `git clone`, so a recurring job
  buys no reachability the synchronous driver lacks, only adds
  operational surface (a cron/CI job, its own failure alerting).
- **New detector logic per repo** — rejected: issue-168 is a driver/
  access problem, not a new-detector problem (out of scope, matches
  #142/#146/#163 detector ownership); the driver reuses
  `compliance-check.sh` and the existing six signal categories as-is.
- **Deep Explore-agent read pass per repo (like #163's own-checkout
  scan)** — rejected for the fleet driver itself: 43x the agent-dispatch
  cost for a phase-2 build turn that must finish inline in one session;
  the grep-based sweep is the cheap, repeatable, driver-side substitute,
  with deeper triage left to whatever role picks up the findings.

## C4 container diagram

```
+---------------------------+      git clone (HTTPS, no auth)     +----------------------------+
|  run-fleet-scan.sh         | -------------------------------->  |  43x *-rulebook repos       |
|  (orchestrator driver)     |                                     |  (tokenmaxxxer org, public) |
|  - gh repo list             |                                     +----------------------------+
|  - mktd temp workspace      |
|  - trap cleanup             |
+--------------+---------------+
               | invokes, per clone
               v
+---------------------------+      invokes unmodified              +----------------------------+
|  fleet-silent-failure-      | ------------------------------->    |  compliance-check.sh        |
|  scan.sh (per-repo driver)  |    --canon-duplication <path>       |  (existing canon-dup scan)  |
|  - 6-category grep sweep    |                                     +----------------------------+
+--------------+---------------+
               | one result row per repo
               v
+---------------------------+
|  aggregated report table   |
|  (43 rows: clean/FINDING/  |
|   CLONE-FAILED; 0 blocked) |
+---------------------------+
```

## Why

Issue-163's A8 recorded all 43 rulebook repos as `blocked: needs-repro-
access`. Phase 1's survey established that premise was false — the
fleet is public and clonable with a bare `git clone`, no auth — so the
real gap was a missing driver, not a real access block. This phase
builds that driver so the fleet silent-failure scan actually runs.

## What was done

- `core/hooks/tests/fleet-silent-failure-scan.sh <repo-path>` — per-repo
  driver. Runs `compliance-check.sh --canon-duplication` unmodified,
  then a grep-based sweep for the six silent-failure signal categories
  from issue-142/163's survey (swallowed errors, fail-open-on-internal-
  error, absent-input-allows, string-judged commands, mktemp footguns,
  dead deny branches), scoped to every `.sh`/`.py` file under the repo.
  Emits exactly one row per repo: `<repo> | clean` or `<repo> |
  FINDING: <cat>: <path>[; <cat>: <path> ...]`. Never `blocked`.
- `core/hooks/tests/run-fleet-scan.sh` — orchestrator. Enumerates the
  fleet (`gh repo list tokenmaxxxer ... | grep 'rulebook$'`), shallow-
  clones each into a `mktd`-managed temp dir (removed on exit via
  `trap`), runs the per-repo driver against each clone, prints an
  aggregated table plus a summary line, and exits non-zero only on a
  clone failure (reported as its own `CLONE-FAILED` row, never folded
  into `clean`).
- `core/hooks/tests/run-fleet-scan-tests.sh` — synthetic clean/finding/
  nonexistent-path cases plus a live 43-repo run asserting exactly 43
  rows and zero `blocked` rows (network-gated with an explicit `SKIP`
  line, not a silent pass, if `gh`/network is unavailable).

Concrete upstream basis: docs/issue-168/reports/architecture/survey.md
(reachability fact) and docs/issue-168/proposals/2026-08-08-fleet-scan-
driver.md (approved design), both phase-1, both on this PR.

## Live run result (this session)

`run-fleet-scan.sh` executed once against the real fleet: **43 rows,
zero `blocked`, zero `CLONE-FAILED`** — 7 `clean`, 36 carrying at least
one `FINDING`. All 36 findings observed in this run are `mktemp-
footgun` (repo scripts calling `mktemp -d` without the `-p
"${TMPDIR:-/tmp}"` pattern this repo's own `_tmp.sh` header documents
as load-bearing, per issue #57) and one `canon-duplication` FAIL. Raw
findings are heuristic grep hits (candidates, not confirmed verdicts).

`run-fleet-scan-tests.sh`: 9/9 pass, including the live 43-row / 0-
blocked assertions.

## Acceptance check

- `run-fleet-scan.sh` produced 43 real per-repo results, 0 blocked. ✓
- `run-fleet-scan-tests.sh` asserts 0 `blocked` rows and passes. ✓

## Open findings

- 36 of 43 fleet repos carry a candidate `mktemp-footgun` hit and 1
  carries a candidate `canon-duplication` FAIL, surfaced by this run
  but not triaged or fixed here — out of scope per the proposal (new-
  detector and fix work are follow-up issues, matching #163's A1-A7
  precedent). Whoever opens the follow-up issue should start from this
  run's row output rather than re-scanning from zero.

## Hand-off

Findings triage (are the 36 `mktemp-footgun` / 1 `canon-duplication`
hits real, and do they need fixes) is out of this issue's scope per
the proposal — routes to whichever role/issue the operator opens next
for fleet-finding follow-up. This role's job (issue-168) was making
the scan runnable at fleet scale, not triaging what it found.

loop_state: done
