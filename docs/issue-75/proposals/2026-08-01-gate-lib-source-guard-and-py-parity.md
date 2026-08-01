files:
- core/hooks/lib/gate-lib.sh
- core/hooks/lib/gate-lib.py
- core/hooks/directive.sh
- core/hooks/gh-guard.sh
- core/hooks/trailer-gate.sh
- core/hooks/handbook-trigger-gate.sh
- core/hooks/approval-gate.sh
- core/hooks/board-gate.sh
- core/hooks/record-fields-gate.sh
- core/hooks/tests/compliance-check.sh
- core/hooks/tests/run-gate-lib-tests.sh
- docs/handbooks/gate-house-standard.md

## Scout skip record

Scouting (per the scout-directive) is skipped under the pure-bugfix condition: both defects are
confirmed, reproducible bugs (fail-open on missing core; `AttributeError` on every Bash call) in
existing canon, and the issue text already supplies the verified fix shapes to apply — the
source-guard form used and confirmed by two downstream rulebooks (interaction-design,
technical-feasibility), and py/sh semantic parity as gate-lib's own stated premise
(gate-house-standard.md's opening line: gate-lib exists so rulebooks stop re-deriving their own
version of each shape — sh and py are supposed to already agree). No external product/design
space to survey; this is closing a gap against this repo's own already-chosen standard.

## Request

Fix two confirmed core-canon defects in the gate-house standard (issue-72's deliverable),
found in the 2026-08-01 43-rulebook A+ re-audit (issue #75):

1. Sourcing `gate-lib.sh` with no guard silently disables every gate that uses it when core is
   unreachable (fail-open), because the undefined `gate_*` functions afterward return 127, which
   every documented `gate_kill_switch_active ... || { exit 0; }` call site reads as "kill switch
   says disable."
2. `gate_bash_write_targets` exists only in `gate-lib.sh`, not `gate-lib.py`, breaking any
   Python-payload gate that calls it (confirmed in the pr-communications repo: `AttributeError`
   on every Bash tool call).

Required: mandate the guard in the gate-house-standard usage contract, add a compliance-check.sh
detection rule for an unguarded source, add a missing-core mandatory test case (asserting deny),
port `gate_bash_write_targets` to `gate-lib.py` with matching semantics and tests, and update the
transition note the final 43-rulebook remediation batch will reference.

## Constraints

- `gate-lib.sh` cannot guard its own loading — a failed `source`/`.` never executes any code
  inside the sourced file, so the guard must live at every call site, not inside the library.
- The fix must not change gate-lib.sh's/gate-lib.py's public function behavior for the already-
  passing six-group test harness (`run-gate-lib-tests.sh`) — this is an additive defect fix, not
  a rewrite.
- `gate-lib.py`'s `gate_bash_write_targets` must be usable by a caller with no compiled regex
  dependency beyond stdlib `re` (matches gate-lib.py's existing stdlib-only posture: only
  `json`, `os`, `posixpath` imported today).
- Per role-handoff contract v3 s19, this is phase 1 only: proposal + survey, no code changes, no
  self-approval.

## Rationale

**Guard placement — call-site guard (adopted) vs. a gate-lib.sh self-check function (rejected).**
A self-check function inside gate-lib.sh (e.g. requiring gates to call `gate_lib_loaded_ok`
after sourcing) was considered because it would centralize the check in one place instead of
duplicating a guard clause across 7+ call sites. Rejected: if the source itself fails, no
function gate-lib.sh defines — including a self-check — is ever callable, so this design cannot
detect the exact failure mode it exists to catch. The interaction-design/technical-feasibility
precedent already resolved this correctly with a call-site guard
(`. "$path" || { echo ... >&2; exit 2; }`); adopted as-is rather than re-deriving a new shape.

**Guard exit behavior — fail closed (exit 2) vs. fail open (exit 0) on guard trip (adopted:
fail closed).** A guard that falls back to `exit 0` on missing core was considered (treats
"core unreachable" like "kill switch off") and rejected: that reproduces defect 1's exact
fail-open outcome under a different trigger, and contradicts `gate_trap_fail_closed`'s own
documented posture (any non-0/non-2 exit gets remapped to 2) — a missing core is an
infrastructure failure, not a deliberate kill-switch signal, and the standard's fail-closed
default should hold. Exit 2 plus a stderr line naming the missing path is adopted, matching the
verified precedent.

**Python port strategy — direct `re.findall` mirror of the sh `grep -oE` pattern (adopted) vs.
`shlex`-based tokenization (rejected).** `shlex.split` was considered because it's the more
"correct" way to tokenize a shell command in Python. Rejected: the sh implementation is
deliberately a permissive regex token-scan (`grep -oE '[[:alnum:]_./~$-]+'`), not real shell
parsing — approval-gate.sh/board-gate.sh's technique per gate-lib.sh's own doc comment. A
`shlex`-based py port would tokenize differently on quoting, pipes, and `$()` substitution than
the sh version does, breaking sh/py parity for the same input — exactly the defect class this
whole standard exists to close. The regex mirror keeps output identical between the two
languages for the same command string, which is the compliance bar (gate-house-standard.md:
"same semantics").

## What will be done

1. **gate-lib.sh usage contract**: update the top-of-file usage comment (lines 11-13) to show
   the guarded source form (`. "$path" || { echo "gate-lib.sh: cannot source ... " >&2; exit 2; }`)
   as the only documented usage, replacing the current bare `. "$path"` example.
2. **7 core gates**: apply the guarded source line to `directive.sh`, `gh-guard.sh`,
   `trailer-gate.sh`, `handbook-trigger-gate.sh`, `approval-gate.sh`, `board-gate.sh`,
   `record-fields-gate.sh` — same guard clause, gate name in the stderr message per site.
3. **compliance-check.sh**: add a third structural check — a gate file containing a
   `gate-lib.sh` source line with no `||` fallback on the same statement fails compliance, same
   report shape as the existing two checks (reasons array, FAIL/ok output).
4. **run-gate-lib-tests.sh**: add a seventh mandatory group, `missing-core`, exercising a gate
   (or a minimal harness sourcing gate-lib.sh) with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a
   nonexistent path and no valid relative fallback, asserting deny (exit 2) — not the current
   silent-allow bug. Update the six-groups-mandatory language and count everywhere it's stated
   (script header comment, `groups_seen` accounting) to seven.
5. **gate-lib.py**: add `gate_bash_write_targets(command)` using `re.findall` against the same
   character class as the sh version (`[A-Za-z0-9_./~$-]+`), returning a list of tokens (sh
   version prints one per line to stdout; py version returns a list — the natural per-language
   equivalent of the same data, documented as such in the docstring).
6. **gate-lib.py tests**: extend `run-gate-lib-tests.sh` (or add a py-side test invocation
   alongside it, matching however group 6's existing Bash-write-target case is currently
   exercised) to assert the py port returns the same token set as the sh version for the same
   fixture command string.
7. **docs/handbooks/gate-house-standard.md**: document the guard as mandatory (add to the
   "What `gate-lib.sh`/`gate-lib.py` provide" usage description and the per-repo migration
   checklist step 2), add `gate_bash_write_targets` to the Python-side function list, bump the
   "Standard test harness" section from six to seven mandatory groups, and add a "transition
   note" subsection recording this fix for the final 43-rulebook remediation batch to cite (per
   issue-75 requirement 3) — what changed, why every already-migrated rulebook needs to re-pull
   the guarded usage line and the py parity fix.

## Out of scope

- No retroactive fix to any of the 43 downstream rulebook repos' gates — per
  gate-house-standard.md's own closing line, that is each rulebook's own A+ remediation issue,
  not this repo's job.
- No new gate-lib.sh/py functions beyond `gate_bash_write_targets` parity — no scope creep into
  other potential sh/py drift not raised by issue-75.
- No change to `gate_kill_switch_active`'s on/off-spelling semantics (issue-72's already-fixed
  defect) — issue-75 is a distinct pair of defects, not a re-litigation of issue-72.
- Phase-2 code changes themselves are out of scope for this document — this proposal covers
  design only; implementation happens after human Approve per contract v3 s19.

## How you'll know it worked

- `compliance-check.sh` run against `core/hooks/` itself reports `ok` for all 7 gates with no
  unguarded-source violation, and flags a deliberately-reverted unguarded gate as FAIL (proves
  the new check actually fires, not just passes by construction).
- `run-gate-lib-tests.sh` reports seven `mark`ed groups all present, with the new `missing-core`
  case asserting exit 2 (not 0) when `CLAUDE_PLUGIN_ROOT_CORE` points nowhere.
- A Python payload gate calling `gate_lib.gate_bash_write_targets("cat docs/x.md")` returns the
  same token set `gate_bash_write_targets` in bash would print for the identical command string,
  verified by a test fixture comparing both outputs.
- `docs/handbooks/gate-house-standard.md` names the guard as mandatory and lists seven test
  groups; a transition note exists for the 43-rulebook remediation batch to cite.
