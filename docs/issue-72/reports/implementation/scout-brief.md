---
subject: issue-72
role: implementation
---

# Scout brief — shared gate library + compliance detector patterns

Mode: this environment gives this session no `WebSearch`/`WebFetch` tool, so
a real scout sweep against external sources (ESLint shareable configs,
pre-commit-hooks framework docs, OPA/Rego bundle docs, shellcheck plugin
ecosystem, etc.) cannot be run. **Web search unavailable in this
environment; scouting skipped per stated-assumptions fallback.** Everything
below is ASSUMPTION — sound engineering precedent this session already knows
from training, explicitly labeled as such, not a sourced finding from a
sweep that actually happened. No URL, version number, or specific claim
below should be treated as verified against a live source; treat it as
"what these systems are widely known to do," not as a citation.

## ASSUMPTION: the four systems named in the task, and the one convergent shape

- **ESLint shareable configs** (`eslint-config-*` packages): a rule
  implementation lives in exactly one published package; consumers
  `extends` it by name rather than copy-pasting rule source into their own
  repo. Enforcement of "don't hand-roll a rule the shared config already
  provides" is itself a lint rule in some setups, not just a convention.
- **pre-commit-hooks framework** (the multi-language git-hook manager): a
  `.pre-commit-config.yaml` in a consuming repo pins a hook repo + rev +
  hook id; the hook's actual script lives once, in the hook's own repo, and
  is fetched/cached, never vendored into the consumer.
- **OPA/Rego policy bundles**: policy logic is packaged as a bundle
  distributed to every enforcement point (each service's OPA sidecar);
  services query the bundle's decision API rather than re-implementing
  policy logic locally. A policy's own test suite (`opa test`) ships
  alongside the bundle and is mandatory for a bundle to be considered
  release-ready.
- **shellcheck-style mechanical linters**: a single static analyzer with a
  fixed rule catalog runs against every consumer's shell scripts; violations
  are enumerable rule IDs (SC2086, etc.), not free-text review comments —
  this is the closest existing shape to what issue #72 asks the compliance
  detector to be (`stub-check.sh`'s own drift-detector precedent in this
  repo is already this shape, just narrower in scope).

**Convergent shape across all four** (ASSUMPTION, not measured): (1) exactly
one canonical source per rule/policy/script, referenced by every consumer,
never forked; (2) the canonical source ships its own test suite, and that
suite is what "compliant" is measured against, not each consumer re-deriving
correctness; (3) a mechanical detector (linter run, bundle version pin,
hook-repo rev) tells a consumer whether it is up to date, rather than a
human periodically re-auditing by hand; (4) migration to a new version of the
shared rule/policy is a per-consumer, incremental rollout (bump a rev, bump a
version pin) — not a single atomic flag day across every consumer at once.

## Fit against this repo's own existing precedent

This repo already has an in-house instance of the same convergent shape,
independent of any external system: `core/hooks/lib/role-directive.sh` (a
sourced shared library, point 1) plus `core/hooks/tests/stub-check.sh` +
`canon-manifest.txt` (a mechanical detector, point 3) plus
`docs/handbooks/canon-scripts.md` (the "reference, never copy" convention,
point 1 stated as a rule rather than left implicit). The one piece this
repo's precedent does not yet have, that all four external systems
(ASSUMPTION) treat as load-bearing, is point 2: a canonical, versioned test
suite shipped alongside the shared source that a consumer's own compliance
run is checked against — `stub-check.sh` today checks *presence/structure*
of a reference, not *behavioral correctness* of what it's referencing. This
is exactly the gap issue #72's "표준 테스트 하네스" (standard test harness)
item targets, and the proposal below treats it as the one genuinely new
piece rather than reinventing what `role-directive.sh`/`stub-check.sh`
already established for the reference-library and drift-detector halves.

## What this brief does NOT claim

- No specific package name, version, or doc URL above should be treated as
  verified — this session did not fetch any of them.
- No adoption numbers, no "X% of teams use Y" claim, no named case study is
  offered — those would require real research this session could not run.
- If a future session has `WebSearch`/`WebFetch` available, this brief
  should be re-run for real before phase 2 finalizes `gate-lib.sh`'s public
  function surface, since a real sweep might reveal a naming or structuring
  convention worth matching that this ASSUMPTION-only pass could not check.
