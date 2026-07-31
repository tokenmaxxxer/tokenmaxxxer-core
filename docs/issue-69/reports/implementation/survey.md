---
subject: issue-69
role: implementation
loop_state: scope-proposed
---

# Survey — stub-check location, rulebook-copy ban, 21-copy reclaim, recurrence guard

Phase 1 (proposal-only). Covers current-state findings for each of the four
items in issue #69.

## Repo-scope caveat (load-bearing for items 3 and 4)

This checkout (`tokenmaxxxer-core`) contains `core/` plus four addon
plugins (`freelunch`, `scout`, `terse`, `warrant`) registered in
`.claude-plugin/marketplace.json`. It does **not** contain the "43 external
rulebook repos" that issue-66's report (`docs/issue-66/reports/implementation.md`,
"Transition path" section) repeatedly refers to as out of this repo's write
access. The 21 rulebooks that copied `stub-check.sh` per issue #69's
background are among those external repos, not anywhere under this working
tree. `find . -name stub-check.sh` returns exactly one hit:
`core/hooks/tests/stub-check.sh`. Consequently this survey cannot list 21
concrete file paths from a `find`/`grep` over this repo — there is nothing
here to find. What it can do, and does below, is reconstruct from the
transition-plan text (issue-66's own report) which mechanism produced the
copies and what a verification pass would need once run against those
external repos.

## Item (a) — stub-check execution location

**Current state**: `core/hooks/tests/stub-check.sh` (89 lines) is the only
copy in this repo. Its own header (lines 22-25) states the *intended*
distribution model explicitly:

> Distributed to every rulebook the way `parse-check.sh` already is...
> Every rulebook copies this file verbatim and runs it over its own hooks/
> tree.

`docs/issue-66/reports/implementation.md`'s "Transition path" step 2 repeats
this as the planned per-rulebook follow-up: "Drop `core/hooks/tests/
stub-check.sh` alongside each rulebook's existing `parse-check.sh`/
`deny-only-check.sh` copies and add it to that rulebook's own CI/test
harness." `docs/handbooks/role-gates-tests.md` documents running it as
`bash core/hooks/tests/run-role-gates-tests.sh` — i.e. from a **local
checkout of core itself**, which is fine for core's own CI but is not the
invocation shape a rulebook uses (a rulebook has no local checkout of core;
it has a plugin install at `${CLAUDE_PLUGIN_ROOT}`).

**Why this is the problem the issue names**: the four already-canon gates
(`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`,
`parse-check.sh`) were promoted to `core/hooks/` and wired once in
`core/hooks/hooks.json` via `${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh` — no
rulebook carries its own copy of *those*. `stub-check.sh`, the tool built
specifically to catch a rulebook regrowing a copy of a canon file, was
itself designed to be vendored 43 times (one `stub-check.sh` file per
rulebook's `hooks/tests/`). That is a self-defeating shape: the
drift-detector is drift. `core/hooks/hooks.json` has no `stub-check.sh`
entry at all today (confirmed: only `directive.sh`, `board-gate.sh`,
`approval-gate.sh`, `gh-guard.sh`, `trailer-gate.sh`, `record-fields-gate.sh`,
`handbook-trigger-gate.sh` are registered) — it is a test-harness script,
never a `PreToolUse` hook, so it was never a candidate for the same
`${CLAUDE_PLUGIN_ROOT}` hooks.json registration the four gates got. It needs
its own core-referenced invocation path instead.

## Item (b) — rulebook copies of canon scripts, ban mechanism

**Current state**: no ban mechanism exists today. The only anti-drift
tooling is `stub-check.sh` itself, which checks for the four already-promoted
gate files (`trailer-gate.sh`, `record-fields-gate.sh`,
`handbook-trigger-gate.sh`, `parse-check.sh`) under a rulebook's `hooks/`
tree and fails if found (lines 34-53 of the script) — but it does **not**
check for a copy of itself (`stub-check.sh`), which is exactly the gap
issue #69 item 2 names. `CANON_GATES="trailer-gate.sh record-fields-gate.sh
handbook-trigger-gate.sh parse-check.sh"` omits `stub-check.sh` from its own
list.

`docs/issue-66/reports/implementation.md`'s "Transition path" step 2 is the
source of the copy instruction being audited here: it directs the
per-rulebook follow-up to physically drop `stub-check.sh` (and
`parse-check.sh`) into each rulebook. There is currently no lint/CI gate, no
handbook rule, and no directive-writing convention that says "reference
core's canon script path, never vendor it" — the only place this
distinction is drawn today is inside `stub-check.sh`'s own detection logic
for the *other* four files, not codified as a general instruction for
whoever writes a rulebook's maturation/transition directive.

## Item (c) — the 21 existing copies

**Current state**: unverifiable from this repo (see scope caveat above). The
21 count comes from issue #69's own background section, which states it was
identified from "43룰북 전환 과정" (the 43-rulebook transition process) — the
external per-rulebook rollout that issue-66's report explicitly marks as "not
executed here — no write access to the 43 rulebook repos." The transition PR
diff issue #69 points to for the target list is therefore a rollout applied
outside this checkout (or a partial application of issue-66/issue-63's
"batch into the same wave" plan against some of the 43 repos), not a diff
available in `git log` here. `git log --all --diff-filter=A -- '*stub-check.sh'`
in this repo shows exactly one add, in commit `2fd1fcb` (issue-66's landing),
adding only `core/hooks/tests/stub-check.sh` — no rulebook-side adds are
recorded here because those commits live in the 43 external repos.

**Why copies proliferated (root cause)**: `parse-check.sh` established the
"drop this file into every rulebook, run it from that rulebook's own harness"
pattern for a legitimate reason (a bash-3.2-parseability check has to run
inside each rulebook's own hook files, which live in that rulebook, not in
core) — see `core/hooks/tests/parse-check.sh`'s header. `stub-check.sh` was
modeled on that same distribution shape by analogy (its own header cites
"the way `parse-check.sh` already is") without noticing the disanalogy:
`parse-check.sh` must run against files that only exist inside each
rulebook, whereas `stub-check.sh` only needs read access to a rulebook's
directory tree from *outside* it — it never needs to *be* inside that tree.
A single core-side script pointed at an external directory can do the same
job without being copied there.

## Item (d) — recurrence-prevention clause

Issue #69's fourth requirement: transition/maturation directives must carry
an explicit clause — "canon scripts are referenced only, never copied."
**Current state**: no such clause exists in any handbook or directive
template in this repo today. `docs/handbooks/role-gates-tests.md` documents
how to *run* the existing tests but says nothing about vendoring rules for
future canon promotions. The nearest existing precedent for "reference, not
vendor" language is the `warrant` plugin's own marketplace description
(`.claude-plugin/marketplace.json`): "Canonical source for this plugin; role
rulebooks reference it rather than vendoring a copy" — i.e. the principle
issue #69 wants generalized already exists as prose for one plugin
(`warrant`) but is not: (1) written as a rule anyone drafting a future
transition/maturation directive is required to include, or (2) enforced by
any check comparable to `stub-check.sh`'s existing four-file detection.

## Summary table

| Item | Current state | Gap |
|---|---|---|
| (a) stub-check location | Distributed-copy model by design (script header + issue-66 report step 2); no hooks.json entry (never was a hook) | No core-pinned invocation path; docs say "run from core checkout," not "run against a rulebook from core's install" |
| (b) copy ban | `stub-check.sh` checks 4 files, not itself | No general "reference-not-vendor" rule or lint outside this one script's hardcoded list |
| (c) 21 copies | Exist in 43 external rulebook repos, not in this checkout | No enumerable list from this repo; reclaim requires per-rulebook-repo access this repo's role does not have |
| (d) recurrence clause | One prose sentence in `warrant`'s marketplace description | Not codified as a required directive clause or a gate |
