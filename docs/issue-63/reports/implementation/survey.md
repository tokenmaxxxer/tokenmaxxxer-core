---
subject: issue-63
role: implementation
---

# Current-state survey — warrant-hunt canon status

## Where warrant actually lives

`warrant` is a standalone plugin (`~/.claude/plugins/cache/tokenmaxxxer/warrant/{0.4.0,0.4.1}`),
not part of this repo. This repo (`tokenmaxxxer-core`) bundles only
`core`, `terse`, `freelunch`, `scout` (`.claude-plugin/marketplace.json`).
Each of the 43 downstream rulebooks (`.../runs/rulebooks/tokenmaxxxer-<x>/<x>/agents/warrant-hunter.md`)
vendors its own physical copy of `warrant`'s `agents/warrant-hunter.md`
rather than referencing the `warrant` plugin. Diffing the canonical
0.4.1 copy against the vendored `coding` rulebook copy shows byte-identical
content today, but `md5sum` across all vendored copies in
`runs/rulebooks/` returns **35 distinct hashes for ~43 files** — i.e.
rulebooks are pinned to whatever `warrant` version was current when each
was last regenerated, so the fleet is already drifting version-by-version
with no single point that re-syncs them. This is the literal problem the
issue names: "43 rulebooks, no single original."

`warrant`'s hunt cadence today (`hooks/directive.sh`, `hooks/hunt-guard.sh`,
`hooks/hunt-state.sh`, `agents/warrant-hunter.md`, ~480 lines total):
- Two dispatch points per work unit: right after the proposal is written,
  right before the work lands ("after-proposal" / "before-landing").
- Each dispatch is unconditional — always both, always full-diff — with no
  scaling by diff size, file count, or code-vs-docs kind.
- `WARRANT_HUNT_MAX` (default 3) caps *dispatch count per session*, not
  time; `hunt-guard.sh` enforces single-flight + the cap mechanically.
- No adaptive rule exists: N misses in a row does not lower cadence or
  scope. Every dispatch runs the full protocol regardless of prior yield.
- The agent type omits `Agent`/`Task`/`Workflow` (no nesting) and it never
  reads `docs/decisions/`, `docs/specs/`, `docs/handbooks/` (anti-anchoring).

## Contrast with scout (the issue's cited model)

Scout *is* core canon in this repo: `scout/hooks/directive.sh` +
`scout/README.md`, single source, referenced (not vendored) by every role
via the marketplace. Its cadence is a hard, self-measured budget:
sweep + deepening capped at **5 stages total** and **3 min wall-clock**,
with a mandatory skip record when skipped, a mandatory scout-brief.md
when run, and a saturation stop rule ("would another round change a
build decision?"). Warrant's hunt has none of these: no stage cap, no
wall-clock cap, no skip record, no saturation/adaptive-yield rule, and —
critically — it is not in this repo at all, so it cannot be edited,
gated, or synced the way scout can.

## Measured hunt cost (what evidence exists in this checkout)

No session-log corpus with per-phase timing/token breakdown is present
in this repo or reachable from it — `bench/run.py` and `ledger/collect.py`
in the marketplace root exist but are aggregate benchmark/ledger tooling,
not a hunt-cadence time series, and neither was run against warrant's
hunt specifically. `.warrant-hunt.count` (marketplace root) is a live
session counter, not a history. **This means step 2 of the issue
("측정 먼저") cannot be satisfied by desk research alone in this
session** — there is no artifact recording hunt-phase duration or token
share broken out by delivery size. The proposal below treats this as an
open data-collection requirement, not a filled-in number, and proposes
the minimal instrumentation (hunt records already carry a timestamp-free
verdict; adding start/end wall-clock to `hunt-state.sh`'s lock file,
already present as `start time`, into the persisted hunt record) needed
to make a future measurement possible.

## What hunt has actually caught (defect classes, from real records)

Two real, merged hunt records exist in this repo's history
(`docs/reports/2026-07-30-hunt-issue-comment-approval-scope.md`,
`docs/reports/2026-07-30-hunt-strip-wake-vocabulary.md`), giving three
concrete confirmed-finding instances:

1. **design-error** — proposal prose promised a guarantee ("closing the
   issue ends authorization unconditionally") that the mechanism it
   specified in the same document could not produce (the `gh issue view`
   call never requested issue state). Caught at *after-proposal*, before
   any code existed — a stance that reads proposal text against itself.
2. **silent-failure (edge-case field)** — `approval-gate.sh` reads only
   `author`+`body` off issue comments and ignores GitHub's `isMinimized`
   field, so a hidden/retracted approval comment still authorizes writes.
   Caught at *before-landing*, against real code, with a live `gh` call
   confirming the field exists.
3. **silent-failure (repo-wide residue)** — a vocabulary-strip edit to
   `role-handoff-contract.md` left the identical stale term ("wakes") in
   `README.md`, a file the diff didn't touch. Caught by the hunter's grep
   reach *following the diff's pattern across the repository*, not by
   reading the diff alone.

These three map directly onto the issue's own list ("directive 잔재,
README 잔재, watch 오탐 근본원인") for the first two categories; no
record of a "watch 오탐 근본원인" catch exists in this repo's
`docs/reports/` or `docs/issue-60/`, `docs/issue-20/` trees — the owner's
phrasing may reference a session not persisted here, or hunt did not
catch it and the fix in issue-20/issue-60 (endpoint+verb matching,
git-subcommand-aware classification) was found some other way. This
survey cannot confirm that fourth class from repo evidence and flags it
as unconfirmed rather than asserting it.

## Unknowns / gaps for the proposal to address

- No time-series data to size "efficiency" gains against — any proposed
  budget (stage cap, wall-clock cap, size-proportional depth) is a
  structural transplant from scout's numbers, not a measured optimum.
- No confirmed instance of hunt catching a "watch false-positive root
  cause" class in-repo — side-effect analysis below treats this class as
  unconfirmed and asks the user to point at the session if it exists.
- Canon promotion requires a target location: this repo has no `warrant/`
  directory today. Two structural options exist (own top-level plugin
  dir mirroring `scout/`, vs. folding hunt cadence into `core/`) — see
  proposal.
