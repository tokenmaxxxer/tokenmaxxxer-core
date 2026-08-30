---
issue: 274
role: overengineering-audit-ad596781
author: overengineering-audit-ad596781
skills: overengineering-audit (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: complete
upstream: []
---

# issue-274 — overengineering-audit-ad596781 record

## What was done

Ran a relic sweep of the five `core` enforcement plugins (`core`, `terse`,
`freelunch`, `scout`, `warrant`) for state-machine-era / wake / role-era
retirement relics, per the issue's "kinds, not words" lens: tonight's prior
finding was that `#2600`'s five occurrence-kind slices (env vars / comments
and docstrings / prompt text / identifiers / persisted keys) missed whole
KINDS of surface -- gate denial messages (`#366`), test filenames, and a
production sidecar path -- because no slice claimed them.

Population searched: every hook (`.sh`/`.py`, excluding `/tests/`),
directive (`.md`), and contract (`.md`) file under `core/hooks`,
`core/directive`, `core/contract`, `terse/hooks`, `terse/directive`,
`freelunch/hooks`, `freelunch/directive`, `scout/hooks`, `scout/directive`,
`warrant/hooks`, `warrant/directive`, plus `scripts/` generator scripts that
feed gate config.
derived: `git ls-files core/hooks terse/hooks freelunch/hooks scout/hooks warrant/hooks core/directive terse/directive freelunch/directive scout/directive warrant/directive core/contract scripts | grep -vE '/tests/|\.json$' | wc -l` — result: 43

Beyond the content-vocabulary grep, four additional surface KINDS were
searched explicitly (the lens the issue asked for), because a word-grep
alone would have missed exactly the same class of thing `#366`'s message
strings and `#384`'s sidecar path did:

1. **File/directory names** (not content) across the same five plugins plus
   `test/`/`tests/`/`scripts/`.
   derived: `git ls-files core terse freelunch scout warrant test tests scripts | grep -niE 'wake|state|mint|role-era|rolegen|entities'` — result: 2 matches (`warrant/hooks/hunt-state.sh`, `warrant/hooks/state.sh`), both read and confirmed current-design (per-issue proposal/hunt-count tracking, not the retired state-machine) — see table row 39/43.
2. **Hardcoded sidecar paths** (state/lock/count/status files a hook reads
   or writes) across the same five plugins.
   derived: `git grep -noE '\.[A-Za-z][A-Za-z0-9_-]*\.(lock|count|level|log|cache|state|json)\b' -- core terse freelunch scout warrant` — result: 11 lines, all `.warrant-hunt.lock`/`.warrant-hunt.count` (current hunt-guard machinery), `.waiting-on.json` (current checkpoint-approval file), `.status.json` (current interaction-design ordering tracker), `.spec.json` (current record-shape schema pointer) — none reference a retired concept.
3. **Environment-variable names** across the same five plugins plus
   `test/`/`tests/`/`scripts/`, filtered for the retired vocabulary.
   derived: `git grep -ohE '\b[A-Z][A-Z0-9_]{2,}\b' -- core terse freelunch scout warrant test tests scripts | sort -u | grep -iE 'wake|mint|statemach'` — result: 0 matches.
4. **Test filenames** specifically (own subset of finding 1): none of the 91
   files under `test/`, `tests/`, and the various `hooks/tests/`
   directories match `wake|state|mint|role-era` in their name.
   derived: `git ls-files test tests core/hooks/tests terse/hooks/tests freelunch/hooks/tests scout/hooks/tests warrant/hooks/tests | grep -niE 'wake|state|mint|role-era'` — result: 0 matches.

Content-vocabulary grep (the retired-concept list from the issue: rulebook
states, roles-as-entities, wake, state files, test-default, plus mint and
pre-diet full-blob, each phrase-scoped so it does not collide with `#366`'s
separate bare-`role` sweep):
derived: `git grep -niE 'state-gate|state-file|state_file|state machine|statemachine|wake[_-]?system|\bwake\b|role-era|roles-as-entities|rulebook state|\bmint\b|full[- ]blob|test-default|test_default' -- core terse freelunch scout warrant test tests scripts README.md` — result: 9 lines, all in `core/contract/role-handoff-contract.md` (3), `core/hooks/approval-gate.sh` (1), `terse/hooks/terse.sh` (4), `warrant/hooks/tests/run-hunt-guard-tests.sh` (1) — each individually reviewed below and in the evidence table; none is a relic.

Full per-file evidence table (population, origin, fire evidence,
retired-concept refs, disposition) posted as an issue comment on `#274`
(the acceptance's required delivery form) and reproduced here:

| # | file | origin | fire evidence | retired-concept refs | disposition |
|---|---|---|---|---|---|
| 1 | `core/contract/role-handoff-contract.md` | n/a | referenced doc, not directly hook-fired | contains 'state machine'/'mint' as current-design vocabulary (loop_state authority, search-before-mint discipline for subject IDs) -- not the retired state-machine/mint systems, no relic | KEEP -- no retired-concept reference found |
| 2 | `core/directive/proposal-shape.md` | issue-234 | Read-pointer target of proposal-shape-directive.sh | none | KEEP -- no retired-concept reference found |
| 3 | `core/directive/record-shape.md` | issue-234 | Read-pointer target of record-shape-directive.sh | none | KEEP -- no retired-concept reference found |
| 4 | `core/directive/session-protocol.md` | n/a | inlined by directive.sh at SessionStart | pre-diet full-blob content inlined unconditionally at SessionStart -- owned by #384(a), not touched | KEEP -- owned by sibling delivery, not fixed here |
| 5 | `core/directive/survey-order.md` | issue-234 | Read-pointer target of survey-order-directive.sh | none | KEEP -- no retired-concept reference found |
| 6 | `core/hooks/approval-gate.sh` | n/a | invoked by pretooluse-dispatcher.sh | comment at line 367 cites 'the retired mint design' as rationale for the current exact-match Approve signal -- historical explanation, not a relic of that design | KEEP -- no retired-concept reference found |
| 7 | `core/hooks/board-gate.sh` | n/a | invoked by pretooluse-dispatcher.sh | role-as-identity noun in denial message (line 846, `while this gate enforces role %r's write-set`) -- owned by #366, not touched | KEEP -- owned by sibling delivery, not fixed here |
| 8 | `core/hooks/citation-gate.sh` | issue-260 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 9 | `core/hooks/directive.sh` | n/a | SessionStart (core) | none | KEEP -- no retired-concept reference found |
| 10 | `core/hooks/facet-keyword-gate.sh` | issue-254 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 11 | `core/hooks/gh-guard.sh` | n/a | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 12 | `core/hooks/handbook-trigger-gate.sh` | issue-66 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 13 | `core/hooks/lib/gate-lib.py` | issue-72 | imported by pretooluse_dispatcher.py, test_board_gate.py | none | KEEP -- no retired-concept reference found |
| 14 | `core/hooks/lib/gate-lib.sh` | issue-72 | sourced by core/warrant gate scripts | none | KEEP -- no retired-concept reference found |
| 15 | `core/hooks/lib/role-directive.sh` | issue-66 | sourced by directive.sh (core, scout, warrant) | none | KEEP -- no retired-concept reference found |
| 16 | `core/hooks/ordering-gate.sh` | issue-240 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 17 | `core/hooks/pretooluse-dispatcher.sh` | issue-282 | PreToolUse .* (core) | none | KEEP -- no retired-concept reference found |
| 18 | `core/hooks/pretooluse_dispatcher.py` | issue-282 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 19 | `core/hooks/proposal-shape-directive.sh` | issue-234 | UserPromptSubmit (core) | none | KEEP -- no retired-concept reference found |
| 20 | `core/hooks/proposal-shape-gate.sh` | issue-234 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 21 | `core/hooks/record-fields-gate.sh` | issue-66 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 22 | `core/hooks/record-shape-directive.sh` | issue-234 | UserPromptSubmit (core) | none | KEEP -- no retired-concept reference found |
| 23 | `core/hooks/record-shape-gate.sh` | issue-234 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 24 | `core/hooks/survey-order-directive.sh` | issue-234 | UserPromptSubmit (core) | none | KEEP -- no retired-concept reference found |
| 25 | `core/hooks/survey-order-gate.sh` | issue-234 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 26 | `core/hooks/test_board_gate.py` | issue-198 | test harness, not hook-registered | none | KEEP -- no retired-concept reference found |
| 27 | `core/hooks/trailer-gate.sh` | issue-66 | invoked by pretooluse-dispatcher.sh | none | KEEP -- no retired-concept reference found |
| 28 | `freelunch/directive/freelunch-protocol.md` | n/a | Read-pointer target of freelunch.sh | none | KEEP -- no retired-concept reference found |
| 29 | `freelunch/hooks/freelunch.sh` | n/a | UserPromptSubmit (freelunch) | none | KEEP -- no retired-concept reference found |
| 30 | `freelunch/hooks/observe.sh` | n/a | PreToolUse Agent\|Task\|Workflow (freelunch) | none | KEEP -- no retired-concept reference found |
| 31 | `scout/directive/scout-protocol.md` | n/a | Read-pointer target of scout/hooks/directive.sh | none | KEEP -- no retired-concept reference found |
| 32 | `scout/hooks/directive.sh` | n/a | UserPromptSubmit (scout) | none | KEEP -- no retired-concept reference found |
| 33 | `scripts/extract-record-shape-config.py` | issue-263 | build-time generator, not hook-registered | none | KEEP -- no retired-concept reference found |
| 34 | `terse/directive/terse-style.md` | issue-278 | Read-pointer target of terse.sh | none | KEEP -- no retired-concept reference found |
| 35 | `terse/hooks/terse.sh` | n/a | UserPromptSubmit (terse) | STATE_FILE is the current terse-level sidecar (~/.claude/terse.level), unrelated to retired state-machine/state-gate concept | KEEP -- no retired-concept reference found |
| 36 | `warrant/directive/warrant-protocol.md` | issue-63 | Read-pointer target of warrant/hooks/directive.sh | none | KEEP -- no retired-concept reference found |
| 37 | `warrant/hooks/directive.sh` | issue-63 | UserPromptSubmit (warrant) | none | KEEP -- no retired-concept reference found |
| 38 | `warrant/hooks/hunt-guard.sh` | issue-63 | PreToolUse .* (warrant) | none | KEEP -- no retired-concept reference found |
| 39 | `warrant/hooks/hunt-state.sh` | issue-63 | SessionStart reset + SubagentStop release (warrant) | none | KEEP -- no retired-concept reference found |
| 40 | `warrant/hooks/hunt-tier.sh` | n/a | invoked by warrant-hunter dispatch (not hook-registered) | none | KEEP -- no retired-concept reference found |
| 41 | `warrant/hooks/lib/scope-gate.py` | issue-63 | sourced by scope-gate.sh | none | KEEP -- no retired-concept reference found |
| 42 | `warrant/hooks/scope-gate.sh` | issue-63 | PreToolUse .* (warrant) | none | KEEP -- no retired-concept reference found |
| 43 | `warrant/hooks/state.sh` | issue-63 | SessionStart (warrant) | unconditional top-level docs/proposals/ report, superseded by per-issue layout -- owned by #384(b), not touched | KEEP -- owned by sibling delivery, not fixed here |

No code changes were made in `core`, `terse`, `freelunch`, `scout`, or
`warrant`: the sweep's only two positive hits (row 7, row 4/43) are each
already owned by an in-flight sibling delivery (`#366`, `#384`), which the
issue explicitly instructed to report-and-leave-alone rather than widen
into.
derived: `git diff --stat origin/main -- core terse freelunch scout warrant scripts test tests` — result: empty (no output; zero-line diff)

## Why

The issue's own framing (tonight's finding: "the retirement missed whole
KINDS rather than scattered instances") is the reason a plain
content-vocabulary grep was not treated as sufficient. Four additional
surface kinds -- filenames, sidecar paths, env-var names, test filenames --
were searched explicitly for the same reason `#366` (gate denial messages)
and `#384` (SessionStart injections) were missed by `#2600`'s five kind
slices: none of those slices' categories (env vars / comments and
docstrings / prompt text / identifiers / persisted keys) cleanly claims a
file *name*, a sidecar *path*, or a message string either.

The two positive hits this sweep did surface (`core/hooks/board-gate.sh`
line 846's `role %r` denial-message noun, and the SessionStart
injections in `core/directive/session-protocol.md` /
`warrant/hooks/state.sh`) are exactly `#366` and `#384`'s own stated scope
-- confirmed by reading both issues directly, and by `git log --all`
showing `#384`'s prepared-but-unmerged commits
(`issue-384: rename role vocabulary to skill in
session-protocol-build-now.md`, `issue-384: condense build-now-unreachable
session-protocol content, scope warrant's proposal scan to the per-issue
directory`) already exist as dangling commits in this same repository's
object store. Per the issue's explicit instruction ("If your sweep finds
occurrences that belong to either, report them with file and line and leave
them alone"), neither was touched; both are reported here and in the issue
comment instead.

Two ambiguous "mint" hits (`core/contract/role-handoff-contract.md:1020`'s
"search-before-mint discipline" and `core/hooks/approval-gate.sh:367`'s
comment "the measured lesson from the retired mint design") were read in
full context rather than treated as string matches: the first uses "mint"
as a live current-design verb (allocating a `subject` identifier) unrelated
to any retired system; the second is a comment *explaining why the current
design does not replicate* a named-retired "mint design" -- it documents
the retirement's lesson rather than carrying the retired design forward, so
removing it would delete the rationale for the current (correct) behavior,
not a relic.

skill-verdict: overengineering-audit — not-applicable: this sweep is a
retired-vocabulary/surface-kind inventory against a retirement decision, not
a spec-vs-artifact excess audit (no abstraction layers, speculative
features, or unused artifacts were in question; the skill's own "is this
about naming or formatting" exclusion applies).
skill-verdict: work-in-english — applied: invoked; this record, the commit
message, the PR, and the issue comment are all written in English; only the
final user-facing turn summary is Korean.
skill-verdict: merge-gates — not-applicable: this is not a CI/branch-
protection merge-gate design question; the sibling-collision risk was
resolved by direct inspection (report-file-and-line, do-not-touch for #366
and #384's owned surfaces), not by designing a combined-state gate.

## Upstream basis

Chain-root record: no other role's artifact was depended on. Read directly:
`gh issue view 274`, `gh issue view 366`, `gh issue view 384` (all
`--repo tokenmaxxxer/tokenmaxxxer-core`), and the repository tree at
`HEAD` (`8c7cc8d4e05f5e2ee341a897f7a628c1ac74c778`, same-commit for this
record's own citations).

## Open findings

None requiring a fix issue in this repository: the sweep's only two
positive hits are already covered by existing, in-flight issues (`#366`,
`#384`) per the collision-avoidance instruction. No new fix issue was
filed. Dead weight to batch: none found (population came back clean beyond
the two sibling-owned hits).

## Next steps

None. `loop_state: complete`. The evidence table has been posted as a
comment on `#274`; `core`, `terse`, `freelunch`, `scout`, and `warrant`
carry no code diff from `origin/main`, so the standing invariants (retired
role-axis count, failing-test set, overhead, monitor/watch machinery) are
unchanged before/after by construction -- verified by re-running
`core/hooks/tests/run-all.sh` and the `warrant/hooks/tests/run-*.sh` suite
against the unmodified tree: pre-existing failures
`feasibility-spikes`, `ops-postmortems` (board-gate), `checkpoint-refusal-
names-await-approval`, `execute-without-remote` (approval-gate), and
`approval-gate: execution write, no approvers.md -> deny` (dispatcher-
equivalence) are identical before and after because no file changed.
