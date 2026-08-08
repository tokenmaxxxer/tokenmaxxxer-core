---
kind: build-proposal
subject: issue-146
produced_by: architecture
loop_state: proposed
status: proposed
files:
  - core/hooks/tests/prose-gate-consistency-check.sh
  - core/hooks/tests/canon-manifest.txt
  - core/hooks/tests/run-prose-gate-consistency-check-tests.sh
  - core/hooks/record-fields-gate.sh
  - core/hooks/handbook-trigger-gate.sh
  - core/hooks/directive.sh
  - core/hooks/lib/role-directive.sh
  - docs/handbooks/prose-gate-consistency.md
upstream:
  - path: docs/issue-146/reports/architecture/survey.md
    sha: same-commit
  - path: docs/issue-146/reports/architecture/scout-brief.md
    sha: same-commit
---

# Mechanical tie between gate literals and prose — issue-146

## Request

108 confirmed mismatches (39/44 units) exist because nothing joins a
gate's denial literals to the prose a role session actually reads before
writing. Design the mechanical check the issue asks for: "extracts a
gate's literal needles and asserts each appears in at least one injected
prose surface for the same role." Also close core's own 3 mismatches
(#147 C1–C3), since the check must "pass for core with no exceptions
carved out" (issue-146 acceptance).

## Constraints

- Must be **mechanical** (string presence), not semantic — confirmed as
  the correct boundary by external scouting (doc-drift tools separate
  structural presence-checking from semantic-consistency checking, and
  only the former is deterministic enough for a fail-closed gate
  ecosystem).
- Must be **runnable per-repo**: the 43 rulebook repos are separate repos
  from core. Reuse the existing canon-script execution model
  (`stub-check.sh`, `compliance-check.sh`): referenced from core's
  install path, never vendored, invoked against the calling repo's own
  `hooks/` tree.
- Must scope "the gates" by **registration** (which scripts are wired into
  a `hooks.json` `PreToolUse` block), not by filename glob —
  `compliance-check.sh`'s already-proven fix for the
  `hunt-guard.sh`/`gh-guard.sh` naming-miss class of bug.
- Weakens no existing gate check.

## Rationale for the annotation approach

Two ways to extract "a gate's literal needles" from a shell/python gate
script:

1. **Generic static extraction** — regex out every quoted string literal
   in the gate and treat each as a needle to search for in prose.
   Rejected: gates contain many string literals that are not
   prose-facing needles (variable names, ANSI-adjacent labels, internal
   role-prefix strings, python dict keys, `argparse`-style flags). This
   would produce a flood of false failures with no way to distinguish a
   real undiscoverable-requirement literal from incidental string
   content — the opposite of the mechanical/deterministic property the
   gate-house already optimizes for (`gate-lib.sh`'s fail-closed, no
   guessing philosophy).
2. **Self-declared annotation** (chosen) — a gate author marks each
   denial-literal with an inline marker comment,
   `# PROSE-NEEDLE: <exact accepted string or space-separated alternate
   spellings>`, directly above the check that denies on it. The checker
   only ever looks at annotated needles. This puts the burden where the
   knowledge already lives (the gate author knows which strings are
   denial-conditions) and gives a **zero-false-positive** check: every
   flagged mismatch is a real "this literal has no prose home," never
   noise from an unrelated string. It also gives #147's fix a mechanical
   pin for free — once `record-fields-gate.sh` and
   `handbook-trigger-gate.sh` carry `PROSE-NEEDLE` markers, the same
   check both proves today's fix and prevents regression.

Considered requiring a separate machine-readable manifest (e.g. a
`needles.json` per gate) instead of inline comments. Rejected: splits the
needle from the code path that denies on it, which is exactly the
divergence-prone shape the audit's shape-2/shape-3 findings already show
(prose and gate drift apart when they live in different files updated at
different times). An inline comment sits next to the line it documents,
so a future edit to the check is visually adjacent to its own
declaration — same principle `gate-lib.sh`'s doc comments already use.

## What will be done

1. **`core/hooks/tests/prose-gate-consistency-check.sh`** (new canon
   script, same execution model as `stub-check.sh`/`compliance-check.sh`:
   referenced via `${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/prose-gate-consistency-check.sh <target-repo-dir>`, never vendored):
   - Reuse `compliance-check.sh`'s `hooks.json` `PreToolUse` scan to find
     every wired gate script in the target repo (core's own 4
     role-agnostic gates count for every repo; a repo's local gates are
     found the same way).
   - For each wired gate, grep `# PROSE-NEEDLE: ...` marker lines and
     collect the declared literal(s), normalizing `-`/`_`/case per the
     precedent `record-fields-gate.sh` already established for its own
     terminal-state matching.
   - Collect the target repo's **injected prose surface**: the rendered
     text of every `directive.sh` in `hooks/` (statically extract the
     `cat <<EOF ... EOF` heredoc body — no execution needed, so no
     `CLAUDE_ROLE`/environment simulation required) plus any file a
     `handbook-trigger-gate.sh`-class gate names as the doc it points a
     role at.
   - For each declared needle, assert it appears as a substring
     (normalized) somewhere in the collected prose. Missing → one
     aggregated failure line naming gate file:line and the literal (same
     "accumulate, don't stair-step" shape #140 established for
     `record-fields-gate.sh` itself — this checker must not repeat the
     mistake it exists to prevent).
   - Exit 0/clean report when every declared needle has a prose home;
     nonzero + full list otherwise.
2. **`core/hooks/tests/canon-manifest.txt`**: add the new script (and its
   test runner) so `stub-check.sh` itself catches a future vendored copy.
3. **`core/hooks/tests/run-prose-gate-consistency-check-tests.sh`**: unit
   tests — annotated needle present/absent, multi-gate aggregation,
   normalization, registration-scoping (unregistered gate ignored).
4. **Close #147 C1/C3 (core's own mismatches), pinned by the new check**:
   - `record-fields-gate.sh`: add `# PROSE-NEEDLE` markers above each of
     its literal checks (§20 field names, sha-placeholder forms,
     `next steps`/`resolution path`), then add the corresponding literals
     to `core/hooks/directive.sh`'s injected heredoc (or to
     `core/hooks/lib/role-directive.sh` if shared across all roles).
   - `handbook-trigger-gate.sh`: add `# PROSE-NEEDLE` markers for its
     trigger-file patterns (`package.json`, `pyproject.toml`, `Dockerfile`,
     `.env*`, `migrations/`, `.github/workflows/`, `(deploy|setup|run|install)*.sh`)
     and the `docs/handbooks/` requirement; add the same set to the
     injected directive text (§21 obligation currently unstated beyond
     the bucket name).
   - C2 (inert terminal-state override channel) is **not** a prose↔gate
     mismatch — it's a broken config-plumbing path with no prose
     counterpart to tie to. Out of scope for this check; flagged as a
     separate hand-off below.
5. **`docs/handbooks/prose-gate-consistency.md`**: how to annotate a new
   gate, the invocation line for a rulebook's own CI, and the
   normalization rules, mirroring `docs/handbooks/canon-scripts.md`'s
   reference-not-vendor documentation shape.

## Out of scope

- **Fleet-wide annotation rollout** (annotating all ~40 other rulebooks'
  gates and fixing their ~105 remaining mismatches). This proposal builds
  and proves the check on core's own repo (issue-146 acceptance: "passes
  for core with no exceptions carved out"); rolling it out fleet-wide is
  per-repo coding-role work in each of those 43 repos, using this check
  as the verification tool. Flagged as follow-up, not built here.
- **#147 C2** (terminal-state override channel is silently inert) — a
  config-plumbing defect, not a prose↔gate literal mismatch; needs its
  own fix (make the override fail loudly or route through one documented
  channel), tracked by #147 directly, not by this check.
- **Wiring the check into actual CI** (`.github/workflows/`) — that's
  ops-role territory (on-the-record#290 tracks fleet CI). This proposal
  ships the script and its handbook; wiring it into a workflow file is a
  hand-off.
- Rewriting the `substring in text.lower()` idiom flagged as "generator 2"
  in issue-146 (anchored matching for semantic conditions like the RED-gate
  false-arm case). Orthogonal defect class — a gate matching too loosely,
  not a gate whose literal has no prose home — separate issue.

## How you'll know it worked

- `prose-gate-consistency-check.sh` run against core itself exits 0 after
  step 4's annotations land.
- Deleting a `PROSE-NEEDLE` marker or a directive literal it depends on
  (test fixture) makes the check fail, naming both the gate file:line and
  the missing literal.
- `stub-check.sh` flags a vendored copy of the new script if one appears
  outside core.
- Unit tests in `run-prose-gate-consistency-check-tests.sh` pass; wired
  into `core/hooks/tests/run-all.sh`.

## Hand-off

- **coding**: build the script/tests/annotations/directive edits listed
  above (this is architecture's phase-1 design; phase-2 build stays with
  architecture per contract, or may be handed to coding — orchestrator's
  call at Approve time).
- **ops**: wire the check into fleet CI (on-the-record#290) once proven
  on core.
- Per-repo rollout across the other 42 rulebooks (fixing their share of
  the 105 remaining mismatches): out of this issue's scope; #146's
  acceptance only requires the check to exist and core to pass it.
