---
subject: issue-75
role: implementation
code_under_review: core/hooks/lib/gate-lib.sh, core/hooks/lib/gate-lib.py, core/hooks/directive.sh, core/hooks/gh-guard.sh, core/hooks/trailer-gate.sh, core/hooks/handbook-trigger-gate.sh, core/hooks/approval-gate.sh, core/hooks/board-gate.sh, core/hooks/record-fields-gate.sh, core/hooks/tests/compliance-check.sh, core/hooks/tests/run-gate-lib-tests.sh, docs/handbooks/gate-house-standard.md
loop_state: landed
---

# Record — gate-lib source guard + gate_bash_write_targets py parity (phase 2)

## What was done

Built the two fixes the approved proposal
(`docs/issue-75/proposals/2026-08-01-gate-lib-source-guard-py-parity.md`)
specified:

- `core/hooks/lib/gate-lib.sh` — top-of-file usage comment now documents
  the guarded source form
  (`. "$path" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`)
  as the only sanctioned usage, replacing the bare `. "$path"` example
  that was the fail-open trap.
- All 7 `core/hooks/*.sh` gates (`directive.sh`, `gh-guard.sh`,
  `trailer-gate.sh`, `handbook-trigger-gate.sh`, `approval-gate.sh`,
  `board-gate.sh`, `record-fields-gate.sh`) now source `gate-lib.sh` with
  the `||` guard, each stderr message naming its own gate.
- `core/hooks/tests/compliance-check.sh` — added a third structural
  check: a gate file containing a `gate-lib.sh` source line with no `||`
  fallback on the same statement now fails compliance, same
  reasons-array/FAIL/ok report shape as the two existing checks.
- `core/hooks/tests/run-gate-lib-tests.sh` — added the mandatory
  `missing-core` group (7th): `record-fields-gate.sh` run with
  `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path asserts deny
  (exit 2), not the pre-fix silent-allow. Also extended the existing
  `bash-write-coverage` group with an sh/py `gate_bash_write_targets`
  parity assertion (same token set for the same command string). Bumped
  the six-groups-mandatory language and the trailing mandatory-group
  check to seven.
- `core/hooks/lib/gate-lib.py` — added `gate_bash_write_targets(command)`:
  `re.findall` against the same `[A-Za-z0-9_./~$-]+` character class the
  sh version's `grep -oE` uses, stdlib-only (`re`, already alongside
  `json`/`os`/`posixpath`), returning a list of tokens (the sh version
  prints one per line to stdout — documented in the docstring as the
  natural per-language equivalent of the same data).
- `docs/handbooks/gate-house-standard.md` — documented the guard as
  mandatory in the "provides" section, added `gate_bash_write_targets`
  to the Python-side function list, bumped the test-harness section from
  six to seven groups, updated the compliance-detector description and
  migration-checklist step 2 to mention the guard, and added a
  "Transition note (issue-75, for the final 43-rulebook remediation
  batch)" section recording both fixes for the 43 per-repo remediation
  issues to cite.

## Why

The 2026-08-01 43-rulebook A+ re-audit found both defects live in
core's own already-migrated canon (issue-72's deliverable), not just a
hypothetical for the 43 downstream repos: an unguarded `gate-lib.sh`
source silently disables every gate using it when core is unreachable
(a `source` failure defines no `gate_*` function, so the subsequent
`gate_kill_switch_active ... || { exit 0; }` reads "command not found"
(127) as the kill switch being off), and `gate_lib.gate_bash_write_targets`
being sh-only breaks any Python-payload gate calling it (confirmed
`AttributeError` on every `Bash` call in the pr-communications repo).
Both are fixed at the source of truth this standard exists to be, so the
43 rulebooks' remediation issues inherit the correct shape instead of
re-deriving the same bug. Full rationale, including the two rejected
alternatives (a gate-lib.sh self-check function instead of a call-site
guard; `shlex`-based tokenization instead of a direct regex mirror), is
in the phase-1 proposal.

## Upstream basis

`docs/issue-75/proposals/2026-08-01-gate-lib-source-guard-py-parity.md`
(approved via issue-level comment `APPROVE issue-75/implementation` from
`JiwonJung94`, a `docs/specs/approvers.md`-listed account — single-account
path). Scouting was skipped per the pure-bugfix condition, recorded in
the proposal's own "Scout skip record" section — no separate survey file
was required by that skip.

## Doc-placement ladder

- [x] `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py` — edited
  in place, src-equivalent canon code under `core/hooks/lib/`.
- [x] `core/hooks/directive.sh`, `core/hooks/gh-guard.sh`,
  `core/hooks/trailer-gate.sh`, `core/hooks/handbook-trigger-gate.sh`,
  `core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`,
  `core/hooks/record-fields-gate.sh` — edited in place, existing gate
  files under `core/hooks/`.
- [x] `core/hooks/tests/compliance-check.sh`,
  `core/hooks/tests/run-gate-lib-tests.sh` — edited in place, existing
  test harness files under `core/hooks/tests/`.
- [x] `docs/handbooks/gate-house-standard.md` — standing handbook
  bucket, edited in place (component-operational documentation that
  outlives this issue, same placement basis as issue-72's original
  authoring of the file).
- [x] `docs/issue-75/reports/implementation.md` — this record, the
  role's own phase-2 deliverable home.

## What did not work

None. Both fixes landed as specified in the proposal on the first pass;
the full `run-gate-lib-tests.sh` harness (30/30, all 7 mandatory groups)
and `compliance-check.sh` against core's own 5 `*-gate.sh` files passed
clean without needing a corrective iteration.

## Next steps

None — this record is terminal (`loop_state: landed`). Downstream: the
43 per-repo A+ remediation issues cite the "Transition note" section of
`docs/handbooks/gate-house-standard.md` to re-pull the guarded source
line and the py parity fix; no further work in this repo is required for
issue #75 itself.

## Open findings

None outstanding.
