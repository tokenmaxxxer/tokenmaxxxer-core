---
issue: 341
role: architecture-interface-contract-shape+silent-failure-audit-e0c3b8a8
author: architecture-interface-contract-shape+silent-failure-audit-e0c3b8a8
skills: architecture-interface-contract-shape (skill-repository(297e350)), silent-failure-audit (skill-repository(297e350))
loop_state: landed
type: fix
verdict: pass
breaking: true
code_under_review:
  - core/hooks/record-fields-gate.sh
  - core/hooks/record-shape-gate.sh
  - core/hooks/record-shape-config.json
  - core/hooks/pretooluse_dispatcher.py
  - core/hooks/tests/run-record-shape-gate-tests.sh
  - core/hooks/tests/run-role-gates-tests.sh
  - core/hooks/tests/run-issue-280-tests.sh
  - docs/handbooks/core.md
upstream:
  - path: docs/issue-331/reports/implementation.md
    sha: same-commit
---

# issue-341 — architecture-interface-contract-shape+silent-failure-audit-e0c3b8a8 record

## What was done

Removed both closed-set validations named in the issue, per the operator
ruling ("if a gate's decision genuinely cannot be made without enumerating
identities, remove that gate's capability").

**1. `core/hooks/record-fields-gate.sh` — `ROLE_TO_KIND` dict + role-in-tuple
check removed.** The 10-entry `ROLE_TO_KIND` dict (former :168-179) and the
`if role in ("coding", "implementation"):` check (former :346) are gone.
`kind` — used both to pick a record's per-kind terminal-`loop_state` set and
to decide whether the `code_under_review:` file-list requirement applies —
is now resolved *solely* from the record's own self-declared `kind:`
frontmatter field (an unrecognized or absent `kind:` falls back to the
legacy flat terminal-state set, unchanged). **Capability dropped:** nothing
now stops a record from self-declaring a kind more lenient than its actual
content — the exact anti-gaming behavior issue-147 C2's "before-landing
hunt" added (a role contract §2 names had its role-derived kind treated as
authoritative over a self-declared `kind:`, specifically to stop this).
That distinction no longer exists because there is no closed set of role
names left to check membership in. Demonstrated live: a `role=qa` record
self-declaring `kind: coding-record` with `loop_state: landed` used to be
refused (advisory) for missing `next-steps`/`resolution-path`, because role
`qa` mapped to `qa-record` regardless of the self-declared kind; it is now
accepted cleanly, since `coding-record`'s only terminal state is `landed`.
Pinned as `core/hooks/tests/run-role-gates-tests.sh`'s
"issue-341: qa record CAN now borrow coding-record's terminal state..." case.

**2. `core/hooks/record-shape-gate.sh` — config-driven CHECKERS dispatch
removed.** The issue-263 fold that looked up `config.get(CLAUDE_ROLE)`
against `record-shape-config.json` (145 rows across 43 role keys) is
deleted in full: the second python heredoc, its `PG_ROLE`/`PG_CONFIG`
plumbing (bash-level `RS_CONFIG`/`RS_ROLE` exports too), and
`record-shape-config.json` itself (`git rm`). **Capability dropped:** none
of the 145 folded per-rulebook record-shape checks (methodology
checklists, section-marker requirements, literal-token co-occurrence
checks — see `docs/issue-263/reports/implementation/survey.md` for the
per-hook list) run through this gate any more. Concretely: `accessibility`'s
folded WCAG-EM check no longer requires a `fail` key in
`docs/issue-10/proposals/gate-remediation.md`, and likewise for the other
144 rows/roles. The hardcoded `implementation`-role phase-2 record check
(issue-52, matches the single fixed path
`docs/issue-<n>/reports/implementation.md`, never a role-keyed dict) is
untouched and still runs unconditionally — it was never the violation.

`core/hooks/pretooluse_dispatcher.py`'s `_setup_record_shape_gate` (the
in-process mirror of `record-shape-gate.sh`'s bash preamble) had its now-dead
`PG_CONFIG`/`PG_ROLE`/`RS_CONFIG`/`RS_ROLE` env-var injection removed to
match; its heredoc-body extractor is generic over however many python
bodies a gate script contains, so it needed no other change and now
correctly runs only the one remaining body. `docs/handbooks/core.md`'s two
affected sections were rewritten to describe current (post-removal) state
plus what was dropped, rather than describing dead code as live.

Tests: `core/hooks/tests/run-record-shape-gate-tests.sh` was rewritten —
the 48 cases covering the removed config dispatch (empty-state,
no-config-file, per-check_type allow/refuse, the 43-role coverage sweep)
are gone; the still-relevant hardcoded-check cases (issue-285/297
trivial-diff exemption) are kept, plus one new regression pinning that a
formerly-configured role/path (`accessibility` /
`docs/issue-10/proposals/gate-remediation.md`) no longer gets refused.
`core/hooks/tests/run-role-gates-tests.sh`'s stale "hunt fix" test (which
asserted the now-removed anti-gaming behavior) was rewritten into a
regression pinning the new, weaker behavior. `core/hooks/tests/
run-issue-280-tests.sh`'s `RECORD_OK_FIELDS` fixture gained an explicit
`kind: coding-record` line, since the `code_under_review:` requirement it
exercises is no longer implied by `role=coding` alone.

## Why

The issue's acceptance criteria and the operator ruling are explicit:
enumerating identities to make a gate's decision is the defect, and the
fix is to drop the capability that required the enumeration, not to
re-express the same lookup under a different name (dict rename, file move,
per-entry sharding, JSON re-encoding — the three prior failure shapes
named in the issue). Both violations were structurally identical
("`<role-named env var>` indexes a fixed dict") even though one was a
literal role->kind map and the other a role->config-rows map, so both are
fixed the same way: the role-keyed lookup is deleted, and what it used to
decide is now decided from data present in the write itself (a
self-declared `kind:` field) or not decided at all (the folded per-rulebook
checks, which had no non-identity-keyed way to decide "which role's rows
apply").

## What did not work

None.

## Upstream basis

- Issue #341 body (verbatim acceptance criteria and operator ruling quote).
- `docs/issue-331/reports/implementation.md:471,494` — the deliberate-deferral
  note for `record-shape-gate.sh`'s config dispatch this issue now retires.
- Core commit `71234db` (`docs/issue-331/reports/implementation.md`'s own
  commit) — self-admission that `record-fields-gate.sh`'s `ROLE_TO_KIND`
  was a genuine closed-set validation, reported but not fixed at the time.

## Open findings

None. `core/hooks/survey-order-gate.sh`'s `PG_ROLE` (builds
`docs/issue-<n>/reports/<role>/survey.md` from the acting role) and
`core/hooks/board-gate.sh:735`'s `CLAUDE_ROLE` (same own-path-construction
pattern) were checked against the same test the issue applies to
`ROLE_TO_KIND`/`PG_ROLE`-against-`record-shape-config.json`: neither
indexes a fixed dict by role — both build one path string from the role
value already trusted for R3's board-write-scoping — so neither is the
closed-set pattern this issue targets, and both are left alone per the
issue's own "what did hold" list.

## Acceptance checks (executed live)

**Check 1 — `grep -rnE 'ROLE_TO_KIND|PG_ROLE|CLAUDE_ROLE|RF_ROLE' core/hooks/`,
scoped to the two named files, before and after:**

Before (original tree, `git stash`):
```
core/hooks/record-fields-gate.sh:7:# docs/issue-<n>/reports/${CLAUDE_ROLE}.md, parse the PROPOSED content and
core/hooks/record-fields-gate.sh:33:# CLAUDE_ROLE unconditionally. ...
core/hooks/record-fields-gate.sh:63:role="${CLAUDE_ROLE:-}"
core/hooks/record-fields-gate.sh:68:[ -n "$role" ] || deny "record-fields-gate: no CLAUDE_ROLE ..."
core/hooks/record-fields-gate.sh:111:RF_PAYLOAD="$payload" RF_ROOT="$root" RF_ROLE="$role" \
core/hooks/record-fields-gate.sh:118:    role = os.environ["RF_ROLE"]
core/hooks/record-fields-gate.sh:168:    ROLE_TO_KIND = {
core/hooks/record-fields-gate.sh:413:    kind = ROLE_TO_KIND.get(role)
core/hooks/record-shape-gate.sh:17:# acting CLAUDE_ROLE are checked; an unmatched role or an absent/
core/hooks/record-shape-gate.sh:56:role="${CLAUDE_ROLE:-record-shape}"
core/hooks/record-shape-gate.sh:65:export RS_ROLE="${CLAUDE_ROLE:-}"
core/hooks/record-shape-gate.sh:325:PG_PAYLOAD="$payload" PG_ROOT="$root" PG_CONFIG="$RS_CONFIG" PG_ROLE="$RS_ROLE" \
core/hooks/record-shape-gate.sh:347:    role = os.environ.get("PG_ROLE", "")
```

After (this commit):
```
core/hooks/record-shape-gate.sh:12:# `record-shape-config.json` lookup keyed by CLAUDE_ROLE -- `config.get(role)`
core/hooks/record-shape-gate.sh:63:role="${CLAUDE_ROLE:-record-shape}"
core/hooks/record-fields-gate.sh:7:# docs/issue-<n>/reports/${CLAUDE_ROLE}.md, parse the PROPOSED content and
core/hooks/record-fields-gate.sh:33:# CLAUDE_ROLE unconditionally. ...
core/hooks/record-fields-gate.sh:51:# role-axis removal (issue-331) left live by accident; see the removal note
core/hooks/record-fields-gate.sh:66:role="${CLAUDE_ROLE:-}"
core/hooks/record-fields-gate.sh:71:[ -n "$role" ] || deny "record-fields-gate: no CLAUDE_ROLE ..."
core/hooks/record-fields-gate.sh:114:RF_PAYLOAD="$payload" RF_ROOT="$root" RF_ROLE="$role" \
core/hooks/record-fields-gate.sh:121:    role = os.environ["RF_ROLE"]
```
Empty state met: `ROLE_TO_KIND` is gone entirely (no hits, live or
comment). `PG_ROLE` is gone from `record-shape-gate.sh` entirely. The
remaining `CLAUDE_ROLE`/`RF_ROLE` hits are: (a) one comment referencing
the removed pattern by prose description, not the literal `PG_ROLE` token
(line 12); (b) `CLAUDE_ROLE` used only for the deny-message role-label
prefix (`role="${CLAUDE_ROLE:-record-shape}"`, `role="${CLAUDE_ROLE:-}"`);
(c) `RF_ROLE`/`CLAUDE_ROLE` used only to build this role's *own* record
path (`docs/issue-<n>/reports/${CLAUDE_ROLE}.md`) or presence-gate before
resolving it — the exact "own record path construction" pattern the issue
names as fine (`RECORDS_RE` match), not a closed-set membership test.

**Check 2 — both gates, before and after, one accept case and one refuse
case each, on a real record-write PreToolUse payload (full commands and
raw output in this repo's session transcript; reproduced verbatim below,
`diff`-identical before/after in every case):**

`record-fields-gate.sh`, self-declared `kind: coding-record`,
`code_under_review:` present as a valid file list (PASS case) —
before and after: `rc=0`, empty output (clean accept, no advisory).

`record-fields-gate.sh`, same `kind: coding-record`, `code_under_review:`
a bare sha with no file list (REFUSE case) — before and after: `rc=0`
(gate is advisory/DEMOTED per issue-282), identical advisory text both
times:
```
coding: record has 1 unmet requirement(s): code_under_review: `0123456789abcdef0123456789abcdef01234567` is a bare commit sha with no file list. Expected shape: `code_under_review: <file> <file> ...` ...
```

`record-shape-gate.sh`, `docs/issue-1/reports/implementation.md` with all
required frontmatter + `## What did not work` (PASS case) — before and
after: `rc=0`, empty output.

`record-shape-gate.sh`, same path missing `loop_state:`/`type:`/the
`## What did not work` heading (REFUSE case) — before and after: `rc=2`,
identical refusal text both times:
```
record-shape: refused — phase-2 record write to docs/issue-1/reports/implementation.md is missing required element(s): frontmatter key `loop_state:`; frontmatter key `type:`; `## What did not work` heading, or (trivial-diff exemption, issue-285) some statement that there was nothing to report. ...
```

Full test suites: `core/hooks/tests/run-all.sh` before vs. after —
identical pass/fail counts in every suite except `record-shape-gate`
(57 passed -> 5 passed, the intended reduction from removing the 48 cases
that covered the now-deleted config dispatch); the two pre-existing
failures elsewhere (`dispatcher-equivalence`'s approval-gate case,
`ups-diet`'s 1 case) are present identically before and after —
unrelated to this change. `python3 -m pytest tests/test_promoted_hooks.py
core/hooks/test_board_gate.py` — same 2 pre-existing failures
(`test_proposal_shape_gate_refuses_missing_sections`,
`test_survey_order_gate_refuses_proposal_without_survey_or_skip`) before
and after, `test_board_gate.py` 22/22 clean both times.

**Check 3 — `scripts/audit_removal_claim.py` (on-the-record PR #2627)
against two claims, one per gate, `removed_names` = the actual identifiers
deleted, `member_samples` = the closed set's actual members:**

```json
[
  {"name": "record-fields-gate.sh ROLE_TO_KIND role->kind closed-set map",
   "removed_names": ["ROLE_TO_KIND"],
   "member_samples": ["product","coding","implementation","qa","feasibility","ux-design","review","verify","ops","reflect"],
   "min_coloc": 5},
  {"name": "record-shape-gate.sh PG_ROLE-keyed record-shape-config.json dispatch",
   "removed_names": ["PG_ROLE","PG_CONFIG","RS_CONFIG","RS_ROLE","record-shape-config.json"],
   "member_samples": ["accessibility","api-design","architecture","brand-design","capacity-planning","conformance-review","content-design","customer-support","data-engineering","data-modeling"],
   "min_coloc": 3}
]
```

Tool verdict for both claims: **RESHAPE_DETECTED** (raw tool output in
`/tmp/audit_removal_claim_final.log` this session; not reproduced in full
here for length, but every hit is enumerated and accounted for below —
none is waved off by category, each is named).

Q1 (name gone) — claim 1: `gone: true`, zero live hits (the earlier run
before this session's comment cleanup showed 1 hit, itself just a comment
in `record-fields-gate.sh`; rephrased to describe the removed dict without
spelling its old identifier, now zero). Claim 2: `gone: false`, 3 residual
hits: `PG_ROLE` in `core/hooks/survey-order-gate.sh` and
`core/hooks/pretooluse_dispatcher.py`'s `_setup_survey_order_gate` — both
are the untouched, unrelated, own-path-construction usage this issue's
"what did hold" list excludes (same file/function on the pre-removal
control run, unaffected by this change); and `record-shape-config.json` in
`.git/index` — a binary git staging artifact from `git rm`, not live code
(will clear on commit).

Q2 (reshaped) is `true` for both claims, but this is a demonstrated
false-positive of the tool's plain-substring co-location check, not
evidence of reconstruction: run against the **pre-removal** tree with the
identical claims file, Q2 already reported `reshaped: true` with the exact
same colocated-file set for claim 1 (`core/hooks/record-fields-gate.sh`
included, 9/10 samples) — because `KIND_TERMINAL_DEFAULTS` (contract §2's
own record-kind vocabulary, e.g. `"coding-record"`, `"qa-record"` —
explicitly *retained*, never part of this issue's scope) contains each
role-name sample as a literal substring of its kind name
(`"coding"` ⊂ `"coding-record"`, `"qa"` ⊂ `"qa-record"`, etc.) by
naming convention alone. Claim 2's Q2 hits are `core/hooks/
citation-config.json`/`citation-gate.sh` — both named in the issue's own
"what did hold" list as already-clean, unrelated to this removal, and
pre-existing on the control tree too. Neither Q2 hit set changed shape
between before and after; both are artifacts of the naive substring
matcher hitting a pre-existing, in-scope-excluded, retained structure —
not something this change introduced or could have avoided while keeping
`KIND_TERMINAL_DEFAULTS` (which the issue does not ask to remove: it is
contract §2's own record-kind vocabulary, not an identity closed set).

Q3 (still branches on closed-set membership) is `false` for both claims —
this is the check that would catch a rename/reshape that still gates
behavior on identity, and it found nothing.

**Bottom line:** the tool's raw verdict is RESHAPE_DETECTED for both
claims per its fixed three-outcome enum, and that is reported honestly
above rather than only citing the clean sub-checks. Read against what each
sub-check actually measures: Q1 dropped from 1/12 genuine hits (original
tree) to 0/3 residual hits, all 3 residual hits independently confirmed to
be a different, untouched, in-scope-excluded code path; Q2's positive
signal is proven identical on the pre-removal control tree, i.e.
independent of this change, and traced to a specific retained structure
the issue does not target; Q3 (the check that directly answers "does
anything still branch on the closed set") is negative for both. Both
demonstrated capability-loss regression tests (`run-role-gates-tests.sh`'s
qa/coding-record test, `run-record-shape-gate-tests.sh`'s accessibility
test) additionally confirm by direct execution that neither closed set is
consulted for its former decision any more.

## Next steps

None — `loop_state: landed`, this record is terminal.

other mounted skills: architecture-interface-contract-shape,
silent-failure-audit, work-in-english — not triggered (none were invoked
via the Skill tool this session: the task is a code-level closed-set
removal inside existing hook scripts, not a boundary-contract-shape choice
or new error-handling path to audit; per invoke-before-apply, a
not-applicable judgment does not require invoking the skill first).
