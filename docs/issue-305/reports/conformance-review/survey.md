# issue-305 — conformance-review current-state survey

## Scout skip record

Skip condition: **spec leaves no design decision open**. This is a
conformance-review pass, not a build — verification methodology, sampling
criteria, verdict taxonomy, and record shape are all fixed in advance by
the mounted `conformance-review-*` skill set and the role-handoff
contract. There is no product/design choice to research prior art for.
Scouting (stage 1 sweep / stage 2 deepening / scout-brief) is skipped in
full; this line is the mandatory skip record.

Sampling-derivation skill: **invoked, applied — full enumeration, not
sampling**. Population = 19 named findings (F1-F14, F16, F18, F21, F22,
F23), each independently identified with its own file/line and repro in
`docs/issue-301/reports/observability.md`. Rule 5 (exempt the
highest-impact tier from sampling) is applied by treating the entire
population as one highest-impact tier rather than stratifying it further:
every finding lives in a `core/hooks/`, `warrant/hooks/`, or
`freelunch/hooks/` gate/dispatcher script, the exact class this repo's own
warrant-protocol already singles out for maximum scrutiny regardless of
diff size ("any diff touching a path under a `hooks/` or `gates/`
directory keeps the full 180s/two-stance treatment — the
composition-bypass class this repo has already caught has landed as
one-line diffs"). The issue's own text also instructs top-down traversal
of the full findings table, not a spot-check. A defined, small (19-item),
individually-named population with an issue-stated full-traversal
instruction does not meet this skill's trigger condition ("full
enumeration is infeasible") — sampling would under-cover exactly the
"which of the claimed 19 fixes actually landed as claimed" question this
review exists to answer, the same reasoning issue-304's review recorded
for its (smaller) 4-item population.

## Subject

Issue #305 ("Sweep remainder: silent zero-byte fail-closed on missing
python3 (4 gates) + remaining per-file findings from #301's inventory"):
work `docs/issue-301/reports/observability.md`'s Findings table top-down
for every finding not already covered by sibling issues #303 (F15/F17,
closed) and #304 (F19/F20, in review as of this survey — PR #309 phase-1
merged, phase-2 pending). Primary named ask: 4 core gates (`gh-guard.sh`,
`approval-gate.sh`, `board-gate.sh`, `pretooluse-dispatcher.sh`) fail
closed on missing python3 with zero bytes on either stream (F16/F18/F22);
fix keeps fail-closed but names the problem. Everything else: the
remaining 15 single-mechanism findings (F1-F8, F10-F14, F21, F23), each
fixed in its own commit with live-fire evidence and a regression check.

Delivered by a separate role/session on branch `issue-305/implementation`,
now open as **PR #313** ("issue-305: sweep remainder — python3 fail-closed
consistency + 15 remaining silent-failure findings"), authored by
JiwonJung94, carrying a `Closes #305` trailer, 16 files changed (15 hook
scripts + `docs/issue-305/reports/implementation.md`, 270 lines, not yet
present on this review branch since PR #313 is unmerged — read via
`git show origin/issue-305/implementation:docs/issue-305/reports/implementation.md`
in phase 2), and 11 commits — one per finding-cluster, each with a
messageBody containing "Verified live:" repro output and a named test
suite pass count. This review's own environment does **not** carry
`CORE_BUILD_NOW=1` (checked: empty), so the two-phase default applies
regardless of what the implementation role did — phase 2 (the actual
review + this role's filled `conformance-review.md` record) opens only
after an Approve on *this* role's PR.

Operator-frozen constraint (issue comment, 2026-08-25, same operator
account as issue-304's identical comment): "The fix must hold
systemically for every session that installs on-the-record and works
against any target repo — not just this self-hosted checkout — and must
land without side effects: no added per-spawn overhead or steady-state
load, no new conflict surfaces, no stall/deadlock modes, no consumer-tree
pollution. Reviewers grade against this: a delivery that works here but
not for a generic consumer target repo is NOT met."

## Requirement extraction (conformance-review-requirement-extraction applied)

Dimension-tagged, one-obligation-per-line, bundled clauses split:

1. [functional] `gh-guard.sh`'s missing-python3 fail-closed path now names
   the problem (via `gate_deny` or equivalent) while keeping the identical
   fail-closed exit code (F16).
2. [functional] `approval-gate.sh`'s missing-python3 fail-closed path: same
   (F18a).
3. [functional] `board-gate.sh`'s missing-python3 fail-closed path: same
   (F18b).
4. [functional] `pretooluse-dispatcher.sh`'s missing-python3 fail-closed
   path: same, via an inline message (the dispatcher shim must never grow a
   gate-lib dependency, per its own design constraint) (F22).
5. [functional] `facet-keyword-gate.sh`'s bash-level python3 check
   demoted from hard `gate_deny` (exit 2) to match the file's own
   advisory-only design (issue-282 DEMOTE: exit 0 + hookSpecificOutput)
   (F9).
6. [process/evidence] Acceptance gate `core/hooks/tests/run-gate-shape-tests.sh`:
   18/18, byte-identical to baseline with python3 present — issue's own
   stated acceptance gate for requirements 1-5, to be independently
   re-executed (not trusted from the implementation record's pasted
   output), per this repo's verify-at-landing convention.
7. [process/evidence] Provenance for requirements 1-5: executed-live
   PATH-without-python3 run for each of the 5 affected sites, each
   showing a named message with fail-closed semantics preserved (exit 2
   for the 4 hard gates, exit 0 + hookSpecificOutput for facet-keyword's
   advisory demote) — issue's own stated acceptance provenance, to be
   independently re-executed.
8. [functional] F1 — `hunt-tier.sh` distinguishes a real git-diff failure
   (bad ref, exit 128) from a genuinely empty diff instead of reporting
   both as `reason=empty-diff`.
9. [functional] F2 — `hunt-guard.sh` refuses (not silently allows) a
   malformed/truncated JSON dispatch payload that raw-text mentions an
   Agent/Task/Workflow tool_name, at session cap.
10. [edge-case] F2 (negative control, stated in the finding's own repro) —
    a malformed payload for an unrelated tool type (matcher is `.*`)
    still allows through unchanged, since failing closed on every JSON
    hiccup regardless of content would block ordinary unrelated tool
    calls.
11. [functional] F3 — a corrupted (non-integer) `.warrant-hunt.count` file
    now refuses loudly instead of silently resetting the session cap to
    `used=0`.
12. [functional] F4 — `scope-gate.sh`'s missing-python3 fail-open path
    (deliberate, documented) now emits a stderr message; the fail-open
    behavior itself (exit 0) stays unchanged.
13. [functional] F5 — `state.sh`'s SessionStart report loop surfaces a
    proposal with broken frontmatter (opening fence, no closing fence) in
    a new section, distinguished from "no opening fence" (genuinely not a
    proposal, still silently skipped).
14. [functional] F6 — `observe.sh` appends an anomaly log row
    (`tool: unknown, violations: [unparseable_payload]`) for unparseable
    payloads under `FREELUNCH_ENFORCE=1`, instead of leaving the audit
    trail untouched; never a deny (tool_name unrecoverable from broken
    JSON).
15. [functional] F7 — `terse.sh`'s I/O read failure on `terse.level`
    (e.g. permission denied) now embeds a NOTE inside the emitted
    directive text, the same channel the unrecognized-value case already
    uses; the fallback-to-`full` behavior itself stays unchanged.
16. [functional] F8 — `facet-keyword-gate.sh` distinguishes a malformed
    (broken-JSON) `FACET_KEYWORD_CONFIG` from a missing one: malformed now
    goes through the file's own `deny()` (visible, advisory exit 0);
    missing stays silent (documented empty-state behavior, unchanged).
17. [functional] F10 — `handbook-trigger-gate.sh` projects `git add
    -A`/`--all`/`-u`/`--update` into the staged-set pathspec (via `git add
    --dry-run`) instead of dropping them as ignored option tokens.
18. [functional] F11 — `ordering-gate.sh` fails closed with a named reason
    on a non-dict `tool_input` or non-string `file_path` for
    Write/Edit/MultiEdit, instead of silently falling through to
    `sys.exit(0)`.
19. [functional] F12 — `ordering-gate.sh`'s `update_status` declines to
    write back at all on a corrupt/unreadable `.status.json`, instead of
    resetting the entire multi-issue document to `{}`.
20. [functional] F13 — the status-file write-back warning (F12's path
    included) is now also emitted via `hookSpecificOutput
    additionalContext`, visible on the allow path, not only stderr.
21. [functional] F14 — `citation-gate.sh` keeps the `gate_trap_fail_closed`
    EXIT trap armed through the file's own final exit, instead of
    disarming it (`trap - EXIT`) before re-exiting a raw non-0/2 Python
    exit code.
22. [functional] F21 — `pretooluse_dispatcher.py` merges every DEMOTE
    gate's finding into one combined stdout `hookSpecificOutput` JSON
    payload, instead of shoving every gate but the first into stderr
    only.
23. [functional] F22 — covered by requirement 4 above (same finding
    number reused for the dispatcher's python3-missing site; observability.md
    lists it once).
24. [functional] F23 — `OTR_DISPATCH_ONLY` refuses (exit 2, naming the bad
    value and the registered gate list) on a typo'd gate name, instead of
    falling through to a bare `return 0` indistinguishable from "gate ran
    and found nothing wrong."
25. [error-handling] Each of requirements 8-24's fix keeps the
    pre-existing fail-open/fail-closed *decision* for that mechanism
    unchanged — only the communication around it, or a demonstrated
    silent-bypass path, changed (issue's own stated invariant, PR body
    restates it).
26. [process/evidence] Each of requirements 8-24 has a live-fire
    before/after repro pasted in its own commit message, per this repo's
    verify-at-landing convention — to be independently re-executed, not
    trusted from the commit message alone.
27. [error-handling] Full sweep `core/hooks/tests/run-all.sh` after all
    commits: no NEW failures relative to baseline (PR claims two
    pre-existing/unrelated failures, confirmed via `git stash` A/B on
    unmodified HEAD — a latency-assertion flake under host contention and
    a pre-existing `approvers.md`-dependent failure).
28. [scope-boundary] The 15-file diff does not touch, re-fix, or conflict
    with the mechanisms sibling issues #303 (F15/F17: `gh-guard.sh`,
    `approval-gate.sh` `\uXXXX`-escape fast-path bypass) and #304 (F19/F20:
    kill-switch propagation in `role-directive.sh` + 3 directive hooks)
    already cover.
29. [scope-boundary] **UNVERIFIABLE-AS-WRITTEN**: "no added per-spawn
    overhead or steady-state load" (operator-frozen constraint) — no
    observable threshold or measurement baseline is stated.
30. [scope-boundary] **UNVERIFIABLE-AS-WRITTEN**: "no new conflict
    surfaces, no stall/deadlock modes" — same issue, no observable success
    condition given.
31. [scope-boundary] "systemic for every consumer session against any
    target repo... no consumer-tree pollution" — cannot be executed
    against "any target repo" from inside this one repo. Checkable only
    as a proxy by Analysis: does the diff stay confined to this repo's own
    plugin tree (`core/hooks/**`, `warrant/hooks/**`, `freelunch/hooks/**`,
    `terse/hooks/**`) plus this role's own `docs/issue-305/` area,
    introducing nothing repo-specific (hardcoded paths, self-hosted-only
    assumptions) a consumer repo would need to carry itself?

Not listed as a checkable requirement: `infrastructure/no-direct-requirement`
is a classification label on the issue itself, not an obligation to
verify.

## Verification method selection (conformance-review-verification-method-selection applied)

- Requirements 1-5: **Demonstration** — independently re-run the
  PATH-without-python3 live-fire repro for each of the 5 sites (rule 3:
  qualitative functional claim, exercise the actual flow) rather than
  trust the commit messages' pasted output.
- Requirement 6: **Test** — `run-gate-shape-tests.sh` already exists;
  reuse and re-execute it (rule 4) rather than hand-deriving a parallel
  check.
- Requirement 7: subsumed by requirements 1-5's Demonstration method.
- Requirements 8-24: **Demonstration** (re-run each finding's own pasted
  repro command against the implementation branch) + **Test**, where an
  existing per-file suite covers the touched mechanism (e.g.
  `run-hunt-guard-tests.sh`, `run-citation-gate-tests.sh`,
  `run-scope-gate-tests.sh`, `run-dispatcher-equivalence-tests.sh`), reused
  per rule 4 rather than re-derived.
- Requirement 10: **Demonstration** — re-run the stated negative control
  alongside its parent finding's positive repro.
- Requirement 25: **Inspection** — diff the touched lines against a
  `git show` of the pre-fix version to confirm the decision branch
  (fail-open vs fail-closed exit code) is byte-identical, only the
  message/communication path changed.
- Requirement 26: subsumed by requirements 8-24's Demonstration method.
- Requirement 27: **Test** — re-execute `run-all.sh` independently against
  the implementation branch; cross-check the claimed two pre-existing
  failures via the same `git stash` A/B the PR describes.
- Requirement 28: **Inspection** — diff `git show` of PR #313 against the
  file/line ranges #303 (PR #306) and #304 (PR #307) touched, confirm no
  overlap or reintroduction.
- Requirements 29-30: stay **Unverifiable** — no realistic reproduction
  target for "overhead/load" or "conflict/stall surfaces" is stated;
  Analysis would require inventing the threshold the issue itself omits
  (same conclusion issue-304's review reached for the identical
  boilerplate).
- Requirement 31: **Analysis** — trace the diff's file scope against the
  repo model; the multi-repo "any target repo" condition cannot be
  reproduced in this session (rule 2).

## What phase 2 will actually do

Independently re-execute `run-gate-shape-tests.sh` and `run-all.sh`
against `issue-305/implementation` (not trust the implementation record's
pasted output alone); re-run each of the 24 checkable
Demonstration-method repros (5 python3-missing sites + 19 findings' own
stated live-fire commands, minus the 4 duplicate/subsumed line items);
inspect the diff for the fail-open/fail-closed-decision-unchanged
invariant and for sibling-issue non-overlap; trace diff scope for the
consumer-tree-residue proxy; and record one verdict per requirement above
(minus the two stated-unverifiable items, recorded as Unverifiable) in
`docs/issue-305/reports/conformance-review.md`, using the existing
skeleton's frontmatter and headings, with file/line/sha citations
(conformance-review-traceability-and-evidence).
