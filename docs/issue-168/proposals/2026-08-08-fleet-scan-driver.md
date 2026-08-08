---
status: proposed
files:
  - core/hooks/tests/fleet-silent-failure-scan.sh
  - core/hooks/tests/run-fleet-scan.sh
  - core/hooks/tests/run-fleet-scan-tests.sh
  - docs/issue-168/reports/architecture.md
---

## Intent

Issue-163's A8 recorded all 43 rulebook repos as `blocked:
needs-repro-access`. The survey (`docs/issue-168/reports/architecture/survey.md`)
shows that premise is false: the 43 repos are public and clonable with a
bare `git clone`, no auth. Issue-168 asks for a driver that actually runs
the silent-failure/divergence scan against real checkouts of all 43 and
emits a per-repo result — no blocked rows.

## Constraints

- Driver must be runnable from an ordinary session (orchestrator or
  scheduled), not require any credential beyond what already works
  (plain HTTPS clone).
- Reuses the existing path-parameterized scan surface
  (`core/hooks/tests/compliance-check.sh`'s documented invocation
  contract) rather than inventing new scan logic — issue-168 is a
  driver/access problem, not a new-detector problem.
- Per-repo output must be a real result row: finding(s) or an explicit
  clean row. Zero `blocked` rows is the acceptance bar.
- Must not write into any cloned rulebook repo (read-only clones,
  scratch/temp dir, discarded after the run).

## What will be built

1. **`core/hooks/tests/fleet-silent-failure-scan.sh <repo-path>`** — thin
   per-repo wrapper matching the issue's own named driver shape. Runs the
   existing scan surface(s) (`compliance-check.sh` plus the six
   silent-failure signal categories from issue-142/163's survey) against
   one already-checked-out rulebook path, and prints one structured
   result line per repo: `<repo> | clean` or `<repo> | FINDING: <text>`.
   Never prints `blocked` for a path that exists and was scanned.
2. **`core/hooks/tests/run-fleet-scan.sh`** — the orchestrator driver.
   Enumerates the 43 rulebook repos (`gh repo list tokenmaxxxer --json
   name -q '.[].name' | grep 'rulebook$'`), shallow-clones
   (`--depth 1`) each into a temp dir under `${TMPDIR:-/tmp}`,
   runs `fleet-silent-failure-scan.sh` against each clone, aggregates
   all 43 result rows into a report table, and removes the temp dir on
   exit (trap). Exits non-zero if any repo failed to clone or scan (that
   failure is itself a row, not a silent drop — "explicit clean row"
   applies to scan outcomes, a clone failure is reported as its own
   distinct outcome, never folded into "clean").
3. **`core/hooks/tests/run-fleet-scan-tests.sh`** — test asserting: (a)
   the driver produces exactly 43 rows for the current repo list, (b)
   zero rows are `blocked`, (c) a synthetic single-repo dry run (a local
   throwaway git repo standing in for one clone) round-trips through
   `fleet-silent-failure-scan.sh` to a `clean` or `FINDING` row.
4. **`docs/issue-168/reports/architecture.md`** — phase-2 record (written
   only after Approve, per contract v3 s19), documenting what the driver
   run actually found across the 43 repos.

Chosen mechanism: **orchestrator clone-and-run** (issue's option A), not
a scheduled sweep (option B) — the fleet is reachable synchronously with
plain `git clone`, so there is no access reason to defer to a cron/CI
sweep; a scheduled sweep would only add operational surface (a
recurring job, its own failure alerting) for no reachability gain the
synchronous driver doesn't already have. A scheduled sweep remains a
cheap follow-up (`run-fleet-scan.sh` is already sweep-callable as-is)
if drift-over-time monitoring is wanted later.

## Out of scope

- New silent-failure detector logic — the scan surface itself is
  issue-142/163/146 territory; this issue only makes it runnable at
  fleet scale.
- Fixing any finding the fleet scan surfaces — findings route to coding
  as their own follow-up issues, per the defect-verification role's own
  precedent on A1-A7.
- Any change to `gh-guard.sh` or auth — the reachability test in the
  survey confirms no guard change is needed for read-only clones.

## How you'll know it worked

- `run-fleet-scan.sh` executed once produces a report with exactly 43
  rows, each `clean` or carrying a finding, zero `blocked`.
- `run-fleet-scan-tests.sh` passes and is wired into whatever test
  runner convention `core/hooks/tests/` already uses.

## Scout-directive skip record

Scouting skipped (external exemplar research) — carried over from the
survey's own skip record (`docs/issue-168/reports/architecture/survey.md`):
the two live product decisions here (orchestrator-clone-and-run vs.
scheduled-sweep; which existing scan surface to parameterize) are
settled by in-repo precedent already confirmed in the survey
(`compliance-check.sh`'s documented invocation contract, the plain-
clone reachability test) — an internal tooling decision constrained
entirely by this repo's own auth boundaries and existing canon
scripts, not by benchmarking external CI fleet-scan tools.

## What did not work

- Fleet-wide six-category sweep as a deep per-file Explore-agent read
  (the approach #163 used on this checkout's own, much smaller scope)
  was considered and dropped for the driver itself: 43x the per-repo
  agent-dispatch cost doesn't fit a phase-2 build turn that must finish
  inline in one session. Replaced with a grep-based heuristic sweep for
  the same six categories — cheaper, repeatable, but produces
  candidates for follow-up triage rather than confirmed verdicts.
