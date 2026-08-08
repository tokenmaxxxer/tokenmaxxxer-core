# survey — issue-168, phase 1

## Current state

- Issue-163's A8 recorded all 43 rulebook repos as `blocked:
  needs-repro-access`, on the stated ground that "no sibling rulebook
  checkout is reachable from this session (single public repo,
  tokenmaxxxer-core...)" (`docs/issue-163/reports/defect-verification/survey.md`).
- That ground does not hold under direct test from this checkout:
  - `gh repo list tokenmaxxxer --limit 100` lists 43 repos whose name
    ends in `rulebook`, all `public` visibility.
  - `git clone --depth 1 https://github.com/tokenmaxxxer/architecture-rulebook.git`
    succeeds with no authentication — plain HTTPS clone, no `gh` auth,
    no write access, nothing `gh-guard.sh` would intercept (`gh-guard.sh`
    only gates `gh`/API calls that touch review/merge endpoints, not
    `git clone` of a public repo).
  - Every cloned rulebook repo carries its own `hooks/` and `tests/`
    tree (confirmed on `architecture-rulebook`: `arch-*` plugin dirs,
    `architecture/`, `docs/`, `tests/`).
- `core/hooks/tests/compliance-check.sh` is explicitly documented (its
  own header) as core canon meant to be invoked *from within* a
  rulebook's own hooks dir, or via `--canon-duplication <rulebook-path>`
  against an arbitrary rulebook root — i.e. it is already
  path-parameterized, matching the issue's own description of the
  #66/#146 scans.
- No `fleet-silent-failure-scan.sh` or fleet-level orchestrator driver
  exists yet anywhere in the repo (`find` for `*fleet*scan*` /
  `fleet-silent-failure-scan*` returns nothing beyond the unrelated
  `run-compliance-scan-scope-tests.sh`).
- No scheduled-sweep mechanism (cron, CI workflow) exists in this repo
  that touches the rulebook fleet.

## What issue-168 actually needs

The blocker A8 named ("no checkout reachable") is a false premise, not
a real access gap — the fleet is public and clonable with a bare `git
clone`. The missing piece is purely a **driver**: something that (a)
enumerates the 43 rulebook repos, (b) clones each, (c) runs the
existing path-parameterized scan surface against each clone, (d) emits
one row per repo (finding or explicit clean), never `blocked`.

## Scout-directive skip record

Scouting (external exemplar research) skipped: the two live "product"
decisions here — orchestrator-clone-and-run vs. scheduled-sweep, and
which existing scan surface to parameterize — are answered by
in-repo precedent already confirmed above (`compliance-check.sh`'s own
documented invocation contract, and the plain-clone reachability test),
not by benchmarking external CI fleet-scan tools. This is an internal
tooling decision constrained entirely by this repo's own auth
boundaries and existing canon scripts; no external field survey would
change the choice. Falls under "spec leaves no design decision open"
once the reachability fact above is established.
