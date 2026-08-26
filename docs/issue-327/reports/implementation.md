---
issue: 327
role: implementation
author: implementation
loop_state: landed
upstream:
  - path: N/A — CORE_BUILD_NOW=1 build-now bypass (contract v3 s19a); no phase-1 proposal doc exists for this delivery
    sha: same-commit
code_under_review:
  - core/hooks/gh-guard.sh
  - core/hooks/approval-gate.sh
  - core/hooks/directive.sh
  - core/hooks/lib/role-directive.sh
  - core/hooks/pretooluse_dispatcher.py
  - core/hooks/tests/run-gh-guard-tests.sh
  - core/hooks/tests/run-approval-gate-tests.sh
  - core/hooks/tests/run-dispatcher-equivalence-tests.sh
type: refactor
breaking: none — every migrated presence test widens (OR) rather than narrows; no caller-visible behavior change for any existing scenario
verdict: pass
---

# issue-327 — implementation record

skill-verdict: work-in-english — not-applicable: this session's user-facing turns were in Korean per the spawning contract's own template, but the skill's own trigger is about doing repo-bound work (code, commits, PR text, docs) in English — all commit-adjacent artifacts in this delivery (code, comments, this record, test names) are already English; no Korean crept into any repo-bound output, so there was nothing to translate/redirect.
other mounted skills: not triggered

## What was done

Classified all 14 core hooks that read `CLAUDE_ROLE` (excluding shell/python
test harnesses under `core/hooks/tests/`) and migrated the presence-only
reads to also honor `TOKENMAXXXER_SPAWNED`, per issue #327 and the
on-the-record #2538 precedent it names.

derived: `grep -rl "CLAUDE_ROLE" core/hooks --include="*.sh" --include="*.py" | grep -v '/tests/' | grep -v 'test_board_gate.py' | sort`
```
approval-gate.sh
board-gate.sh
citation-gate.sh
directive.sh
facet-keyword-gate.sh
gh-guard.sh
handbook-trigger-gate.sh
lib/role-directive.sh
pretooluse_dispatcher.py
proposal-shape-gate.sh
record-fields-gate.sh
record-shape-gate.sh
survey-order-gate.sh
trailer-gate.sh
```
14 files, matching the issue's own count. 8 of these are the issue's named
non-goals (value-keyed, separate issues): `board-gate.sh`,
`record-fields-gate.sh`, `record-shape-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh`, `survey-order-gate.sh`, `citation-gate.sh`,
`facet-keyword-gate.sh` — left untouched, not re-classified here, per the
issue's own "Non-goals" section. The remaining 6 were read in full and
classified below; 5 of the 6 had at least one presence-only use and were
migrated, 1 (`proposal-shape-gate.sh`) turned out fully value-dependent on
inspection and was left alone (an "empty state" outcome per the issue's own
acceptance note, not a shortfall).

### Classification (every `CLAUDE_ROLE` use in each of the 6 non-excluded hooks)

**`core/hooks/gh-guard.sh`** — migrated
- `gh-guard.sh:32` (pre-migration line; now `gh-guard.sh:40` after the added
  comment block) — `[ -n "${CLAUDE_ROLE:-}" ] || { trap - EXIT; exit 0; }` —
  presence-only: the only question is "is this a role session", never the
  role's name.
- `gh-guard.sh:91` (`role = os.environ["CLAUDE_ROLE"].strip()`) —
  value-dependent: `role` is interpolated into the denial text
  (`gh-guard.sh` `_deny_for`, "refused for role session '%s'") — kept.

**`core/hooks/approval-gate.sh`** — migrated
- `approval-gate.sh:81` (pre-migration; now `approval-gate.sh:86`) —
  `[ -n "${CLAUDE_ROLE:-}" ] || { trap - EXIT; exit 0; }` — presence-only.
- `approval-gate.sh:143` (pre-migration `:138`,
  `role = os.environ["CLAUDE_ROLE"].strip()`) — value-dependent: `role` is
  used to select the phase-1/phase-2 boundary path
  (`reports/%s/` % role), to build the branch-name check
  (`issue-<n>/%s` % role), the APPROVE/REJECT/WITHDRAW/DEFER challenge
  strings, and multiple denial messages — kept.

**`core/hooks/directive.sh`** — migrated (mixed)
- `directive.sh:20-21` (pre-migration; now `directive.sh:21` after the
  header-comment edit, `role="${CLAUDE_ROLE:-}"` +
  `[ -n "$role" ] || { trap - EXIT; exit 0; }`) — presence-only for the
  guard itself: the sole question at that line is "does this session get
  the SessionStart directive at all".
- `directive.sh:94,96,97,99` (unchanged) — value-dependent: `${role}` is
  rendered into the printed INVARIANTS block ("role ${role}",
  "issue-<n>/${role}", "reports/${role}.md") — kept on `CLAUDE_ROLE`.
  This is exactly the trap the issue warned about ("a hook using the value
  50 lines later is value-dependent"): the issue's own candidate list
  named `directive.sh:20` as presence-only, and that line's guard *is*
  presence-only, but the same hook is NOT purely presence-only overall —
  it needs both, which the issue explicitly allows.

**`core/hooks/lib/role-directive.sh`** — migrated (mixed)
- `role-directive.sh:32-33` (pre-migration; now `:33`,
  `local role="${CLAUDE_ROLE:-}"` + `[ -n "$role" ] || return 0`) —
  presence-only for the guard.
- `role-directive.sh:36,42,49` (unchanged) — value-dependent: `role`
  builds the per-role kill-switch var name (`${role_upper}_CYCLE_OFF`)
  and is rendered into the printed directive (`[${role}] Role directive`,
  `reports/${role}.md`) — kept on `CLAUDE_ROLE`. Same shared boilerplate
  as `directive.sh` (43 rulebook copies per its own header comment), same
  mixed classification.

**`core/hooks/pretooluse_dispatcher.py`** — migrated (2 of 9 uses)
- `pretooluse_dispatcher.py:244` (pre-migration; `_setup_approval_gate`,
  `if not os.environ.get("CLAUDE_ROLE", ""): return "skip", None`) —
  presence-only, mirrors `approval-gate.sh`'s own guard (this is the LIVE
  PreToolUse code path — `hooks.json` registers only
  `pretooluse-dispatcher.sh`, which execs this file; `approval-gate.sh`
  and `gh-guard.sh` as standalone scripts are the source-of-truth bodies
  the dispatcher's `_gate_bodies()` extracts and re-runs, but their own
  bash-level presence guards are exercised only when the `.sh` is run
  directly, e.g. by the test suite — both copies needed migrating for the
  property to hold on the live path).
- `pretooluse_dispatcher.py:269` (pre-migration; `_setup_gh_guard`, same
  shape) — presence-only, mirrors `gh-guard.sh`'s own guard.
- `pretooluse_dispatcher.py:306` (pre-migration; `_setup_record_shape_gate`,
  `role = os.environ.get("CLAUDE_ROLE", "")`) — value-dependent: feeds
  `PG_ROLE`/`RS_ROLE` into `record-shape-gate.sh` (non-goal) — kept.
- `pretooluse_dispatcher.py:331` (`_setup_citation_gate`, `CIT_ROLE`) —
  value-dependent, feeds `citation-gate.sh` (non-goal) — kept.
- `pretooluse_dispatcher.py:344` (`_setup_facet_keyword_gate`, `FK_ROLE`) —
  value-dependent, feeds `facet-keyword-gate.sh` (non-goal) — kept.
- `pretooluse_dispatcher.py:359` (`_setup_handbook_trigger_gate`,
  `HT_ROLE`) — value-dependent, feeds `handbook-trigger-gate.sh`
  (non-goal) — kept.
- `pretooluse_dispatcher.py:381,383` (`_setup_record_fields_gate`,
  `role = os.environ.get("CLAUDE_ROLE", "")` then
  `if not role: return "deny", (...)`) — the guard itself denies on
  absence, but the SAME `role` value is passed onward as `RF_ROLE` into
  `record-fields-gate.sh` (non-goal), which uses it to resolve
  `docs/issue-<n>/reports/${role}.md` — value-dependent overall, same
  reasoning the issue itself applies to `record-fields-gate.sh:63,68` —
  kept.
- `pretooluse_dispatcher.py:414` (`_setup_survey_order_gate`, `PG_ROLE`) —
  value-dependent, feeds `survey-order-gate.sh` (non-goal) — kept.
- `pretooluse_dispatcher.py:426` (`_setup_trailer_gate`,
  `TRAILER_GATE_ROLE`) — value-dependent, feeds `trailer-gate.sh`
  (non-goal) — kept.

**`core/hooks/proposal-shape-gate.sh`** — reviewed, left alone (fully
value-dependent, empty-state outcome)
- `proposal-shape-gate.sh:14` — `role="${CLAUDE_ROLE:-proposal-shape}"` —
  this is NOT a presence gate: the fallback default (`proposal-shape`)
  means the variable is always truthy, and the gate applies unconditionally
  to any `docs/issue-<n>/proposals/*.md` write regardless of whether
  `CLAUDE_ROLE` is set at all. `role` is used only as a label prefix in
  `deny()`'s message (`"${role}: refused — $1"`). No presence test exists
  in this file to migrate.

### Edits made

1. `core/hooks/gh-guard.sh` — presence guard now
   `[ -n "${TOKENMAXXXER_SPAWNED:-}${CLAUDE_ROLE:-}" ] || { trap - EXIT; exit 0; }`.
2. `core/hooks/approval-gate.sh` — same OR-shaped guard.
3. `core/hooks/directive.sh` — same OR-shaped guard (role NAME still from
   `CLAUDE_ROLE`).
4. `core/hooks/lib/role-directive.sh` — same OR-shaped guard.
5. `core/hooks/pretooluse_dispatcher.py` — `_setup_approval_gate` and
   `_setup_gh_guard` now skip only when BOTH
   `os.environ.get("TOKENMAXXXER_SPAWNED", "")` and
   `os.environ.get("CLAUDE_ROLE", "")` are falsy.
6. Test-harness updates so genuine "no role" fixtures unset BOTH vars
   (they previously unset only `CLAUDE_ROLE`, which is what surfaced the
   design point below): `core/hooks/tests/run-gh-guard-tests.sh`,
   `core/hooks/tests/run-approval-gate-tests.sh`,
   `core/hooks/tests/run-dispatcher-equivalence-tests.sh`.

## Why

**OR, not switch.** on-the-record's own #2538/#698 precedent
(`$ON_THE_RECORD/on-the-record/hooks/deliverable-guard.sh`) resolves
presence from a SessionStart-bound snapshot first and the live
`TOKENMAXXXER_SPAWNED` only as fallback — that is what makes checking
`TOKENMAXXXER_SPAWNED` alone safe there: the snapshot was taken before any
mid-session unset could happen. core has no equivalent snapshot mechanism
(`grep -rln "session-role-bind\|role-bind" core/` — no hits). Migrating
`gh-guard.sh`/`approval-gate.sh`/`directive.sh`/`role-directive.sh` to test
`TOKENMAXXXER_SPAWNED` ALONE would have been a straight downgrade of the
security property the issue itself states as non-negotiable: since the
spawner sets both vars together, a session that unset only
`TOKENMAXXXER_SPAWNED` (leaving `CLAUDE_ROLE` intact) would flip a
switch-shaped guard from deny to allow — a new escape this issue did not
have before the migration. The OR form
(`[ -n "${TOKENMAXXXER_SPAWNED:-}${CLAUDE_ROLE:-}" ]`) closes that: either
var alone still trips the guard, so an attacker has to clear both (no
easier than the pre-migration one-var attack) while the hook is now also
correctly keyed off `TOKENMAXXXER_SPAWNED` going forward. This was verified
live, not argued from code — see Acceptance evidence below.

**Why these 5 files and not more.** The issue's own non-goals list (8
files) and its instruction to "verify each before touching it" were both
taken literally: every one of the 6 non-excluded candidates was read in
full, not grepped at the guard line alone. `directive.sh` and
`role-directive.sh` are the concrete case the issue predicted
("a hook using the value 50 lines later is value-dependent") — both are
migrated only at their presence guard while keeping `CLAUDE_ROLE` for the
role-NAME text they render afterward, exactly the "a hook can legitimately
need both" shape the issue calls out for `gh-guard.sh`/`approval-gate.sh`.
`proposal-shape-gate.sh` turned out to have no presence gate to migrate at
all (its `CLAUDE_ROLE` read is a label default, not a guard) — reported
as-is rather than force-fit into either bucket.

**Build-now bypass used.** The spawning environment carried
`CORE_BUILD_NOW=1` (spawner-set; confirmed via `printenv CORE_BUILD_NOW`
at session start, per contract v3 s19a). Per the top-level spawn
instructions this authorizes delivery-only: skip the proposal round, build
directly on `issue-327/implementation`, commit code and this record, open
one PR. No `docs/issue-327/proposals/` file exists for that reason; this
record's `upstream:` frontmatter states the bypass instead of a fabricated
path.

## What did not work

None.

## Upstream basis

CORE_BUILD_NOW=1 build-now bypass (contract v3 s19a): no phase-1
proposal/survey document exists for this delivery. The requirement is
`gh issue view 327` (quoted acceptance criteria above, read at session
start) plus the on-the-record #2538 precedent it names, read directly at
`$ON_THE_RECORD/on-the-record/hooks/deliverable-guard.sh` (the
snapshot-first pattern cited in the "Why" section) and
`$ON_THE_RECORD/pipeline.py:672-680` (confirms `TOKENMAXXXER_SPAWNED` is
set alongside `CLAUDE_ROLE` on every spawn, matching the issue's claim).

## Acceptance evidence

### 1. Classification with file:line citations

canonical: the "Classification" subsection above — every `CLAUDE_ROLE` use
in each of the 6 non-excluded candidate hooks is cited by file:line with a
one-line presence-only/value-dependent reason.

### 2. Each migrated gate still denies what it denied before (same payload, refusal text before vs. after)

`directive.sh` and `role-directive.sh` never deny (they are SessionStart
information hooks that either print or silently no-op, `exit 0` on every
path) — this check applies to the 2 hooks that DO deny:
`gh-guard.sh`/`approval-gate.sh`, plus their live dispatch path through
`pretooluse_dispatcher.py`.

derived: `git stash push -- core/hooks/*.{sh,py} core/hooks/tests/*.sh` (revert to
pre-migration), run the identical payload, `git stash pop` (restore), run
again — same shell session, same repo, only the working tree toggled.

BEFORE (pre-migration) `gh-guard.sh`, role session running `gh pr merge 5`:
```
gh-guard: refused for role session 'coding': merging or closing a PR is the human's acceptance/refusal — a role session only opens PRs and pushes to its own issue branch. (two-account model, contract v3 s8)
rc=2
```
AFTER (migrated) `gh-guard.sh`, identical payload and role:
```
gh-guard: refused for role session 'coding': merging or closing a PR is the human's acceptance/refusal — a role session only opens PRs and pushes to its own issue branch. (two-account model, contract v3 s8)
rc=2
```
Byte-identical. Same result through the live dispatch path
(`OTR_DISPATCH_ONLY=gh-guard.sh python3 pretooluse_dispatcher.py`), before
and after — same text, `rc=2`.

BEFORE (pre-migration) `approval-gate.sh`, role session writing
`src/foo.py` in a repo with no `docs/specs/approvers.md`:
```
approval-gate: this repository has no docs/specs/approvers.md, but the session carries CLAUDE_ROLE=coding. A role session works only on a board, and that file is both the board opt-in and the approver allowlist — ask the human to add it
rc=2
```
AFTER (migrated) `approval-gate.sh`, identical payload:
```
approval-gate: this repository has no docs/specs/approvers.md, but the session carries CLAUDE_ROLE=coding. A role session works only on a board, and that file is both the board opt-in and the approver allowlist — ask the human to add it
rc=2
```
Byte-identical. Same result through the live dispatch path
(`OTR_DISPATCH_ONLY=approval-gate.sh python3 pretooluse_dispatcher.py`),
before and after — same text, `rc=2`.

Full existing gate test suites also still pass at the same rate as on the
pre-migration tree (verified by `git stash`-ing my changes and re-running):
derived: `bash core/hooks/tests/run-gh-guard-tests.sh` — before and after
both `== 54 passed, 0 failed ==` (after the harness fix in "Edits made"
item 6; before that harness fix, the pre-existing-`CLAUDE_ROLE`-only
unset made 2 of these fail against the migrated code, in this sandbox,
because this very session's own shell carries `TOKENMAXXXER_SPAWNED=1` —
not a regression in the gate, a test-fixture gap the migration exposed and
item 6 closed).
derived: `bash core/hooks/tests/run-approval-gate-tests.sh` — `== 64 passed, 2 failed ==`
both before and after my changes (`git stash` comparison); the 2 failures
(`checkpoint-refusal-names-await-approval`, `execute-without-remote`) are
pre-existing and reproduce identically on the unmodified base tree, not
introduced by this migration.
derived: `bash core/hooks/tests/run-dispatcher-equivalence-tests.sh` —
`24 passed, 1 failed` both before and after; the 1 failure
(`approval-gate: execution write, no approvers.md -> deny`) is pre-existing
(reproduces on the unmodified base tree) — an environment artifact in this
sandbox (`gh`/network availability), not caused by this migration.
derived: `bash core/hooks/tests/run-directive-shape-tests.sh` — `31 passed, 0 failed` (unchanged).
derived: `bash core/hooks/tests/run-role-directive-staging-tests.sh` — `role-directive-staging: 4 passed, 0 failed` (unchanged).

### 3. A spawned session that unsets TOKENMAXXXER_SPAWNED does NOT escape any migrated gate

derived: `env -u TOKENMAXXXER_SPAWNED CLAUDE_ROLE=coding bash core/hooks/gh-guard.sh` with payload `{"tool_name":"Bash","tool_input":{"command":"gh pr merge 5"}}` on stdin:
```
gh-guard: refused for role session 'coding': merging or closing a PR is the human's acceptance/refusal — a role session only opens PRs and pushes to its own issue branch. (two-account model, contract v3 s8)
rc=2
```
derived: `env -u TOKENMAXXXER_SPAWNED CLAUDE_ROLE=coding CLAUDE_PROJECT_DIR=<fresh empty git repo> env -u CORE_BUILD_NOW bash core/hooks/approval-gate.sh` with payload `{"tool_name":"Write","tool_input":{"file_path":"src/foo.py","content":"x"}}` on stdin:
```
approval-gate: this repository has no docs/specs/approvers.md, but the session carries CLAUDE_ROLE=coding. A role session works only on a board, and that file is both the board opt-in and the approver allowlist — ask the human to add it
rc=2
```
derived: same payload as the first case, through the live dispatch path —
`env -u TOKENMAXXXER_SPAWNED CLAUDE_ROLE=coding OTR_DISPATCH_ONLY=gh-guard.sh python3 core/hooks/pretooluse_dispatcher.py`:
```
gh-guard: refused for role session 'coding': merging or closing a PR is the human's acceptance/refusal — a role session only opens PRs and pushes to its own issue branch. (two-account model, contract v3 s8)
rc=2
```
No escape in any of the 3 migrated live paths tested. Sanity check on the
other direction — unsetting BOTH vars (a genuine non-role session) still
allows, unchanged:
derived: `env -u TOKENMAXXXER_SPAWNED -u CLAUDE_ROLE bash core/hooks/gh-guard.sh` with the same `gh pr merge 5` payload → `rc=0` (no stderr output).

### 4. A real spawn runs end to end with core loaded

derived: from the repo root,
```
CLAUDE_ROLE=implementation TOKENMAXXXER_SPAWNED=1 CLAUDE_PROJECT_DIR="$(pwd)" \
claude -p "Reply with exactly the single word: SPAWN-OK" \
  --plugin-dir "$(pwd)/core" \
  --output-format stream-json --verbose --include-hook-events \
  --max-turns 3
```
`--plugin-dir "$(pwd)/core"` points at THIS working tree's edited core
(not the installed plugin copy at `$CLAUDE_PLUGIN_ROOT_CORE`), so the
migrated `directive.sh` is what actually ran. Model reply: `SPAWN-OK`.
Hook-event stream confirms the migrated `SessionStart:startup` hook
(`directive.sh`) fired for real and produced the live protocol text:
```
{"type": "system", "subtype": "hook_response", "hook_id": "c9dcde8e-7ded-46ce-a6aa-7b2e54301bc8", "hook_name": "SessionStart:startup", "hook_event": "SessionStart", "output": "[core] Interaction protocol for role implementation (role-handoff contract v3). INVARIANTS:\n- Requirements are user-authored GitHub ISSUES...
```
`exit_code: 0`, `outcome: success` on that hook response — the presence
guard at `directive.sh`'s new OR line let the session through exactly as
before (role name still rendered correctly from `CLAUDE_ROLE`), and the
session completed end to end (`SPAWN-OK`, `Error` absent, `max-turns 3`
sufficient).

## Open findings

None.

## Next steps

None — loop_state: landed.
