---
kind: coding-record
subject: issue-93
produced_by: implementation
code_under_review: 8f4ba9f887192054286b061fa86273513b8de929
loop_state: landed
upstream:
  - path: docs/issue-93/proposals/2026-08-03-qualify-freelunch-worker-subagent-type.md
    sha: 8f4ba9f887192054286b061fa86273513b8de929
---

# Implementation record — issue-93

## Why

Phase 2, approved via issue-level comment `APPROVE issue-93/implementation`
(exact string, posted by an approvers.md account:
https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/93#issuecomment-5161868317).
Delivering exactly the approved proposal's `## What will be done`: two
coupled defects in core's `freelunch` plugin — `freelunch/hooks/freelunch.sh`
instructs every role session to dispatch background workers with the
unqualified `subagent_type freelunch-worker`, which the harness does not
register under that name (the namespaced `freelunch:freelunch-worker` is
what actually resolves), so every session that follows the directive
literally fails its first delegation with "Agent type 'freelunch-worker'
not found"; and `freelunch/hooks/observe.sh`'s Sonnet-pin compliance check
exact-matched only the unqualified literal, so qualifying the directive's
instructed name alone would immediately trip that check instead, logging
(and, under `FREELUNCH_ENFORCE=1`, denying) a correctly Sonnet-pinned
dispatch as `non_sonnet_worker`.

## What was done

1. `freelunch/hooks/freelunch.sh:46` and `:50` — both dispatch
   instructions (LEAN SOLO's single-worker branch and LEAN FAN-OUT's
   per-group branch) now read `subagent_type freelunch:freelunch-worker`
   instead of the unqualified `freelunch-worker`.
2. `freelunch/hooks/observe.sh:77` (formerly line 71) — the Sonnet-pin
   comparison now reads:
   `if "sonnet" not in model and not (model == "" and agent_type in ("freelunch-worker", "freelunch:freelunch-worker")):`
   recognizing both the qualified and legitimate unqualified spellings,
   per the proposal's Rationale (explicit two-literal membership, not a
   loosened substring match).
3. `freelunch/hooks/observe.sh:8-10` and `:65-76` — the header comment and
   the inline comment above the Sonnet-pin check now describe both
   recognized `agent_type` forms, extending the existing
   exact-match-was-wrong reasoning that already covered `model`.
4. `freelunch/hooks/observe.sh:111-113`
   (`REASONS["non_sonnet_worker"]`) — the corrective denial text now
   tells a denied caller to re-issue with `subagent_type:
   freelunch:freelunch-worker` (qualified), not the bare unqualified name,
   so a deny's own guidance can no longer loop back into defect 1.
5. `bash freelunch/hooks/tests/parse-check.sh freelunch/hooks` — ran
   after the edits: `ok freelunch.sh`, `ok observe.sh`, `ok
   tests/parse-check.sh`, `parse-check: 3 file(s) under /bin/bash` — both
   edited files still parse under bash 3.2.

## Regression check (real delegation, not a string check — issue #93 requirement 3)

1. **Live Agent dispatch, defect 1**: issued an actual `Agent` tool call
   with `subagent_type: "freelunch:freelunch-worker"`,
   `run_in_background: true`, no `model` override, prompt "Reply with the
   single word: ready". The runtime accepted it (no "Agent type ... not
   found" error), the background agent started, and it returned `ready`
   in 1836ms — confirms defect 1 is fixed at the harness's actual
   agent-resolution step, the issue's reported symptom.
2. **Defect 2, both modes, plus negative control**: the PreToolUse hook
   that mediates this session's own tool calls resolves to the
   marketplace-installed plugin copy at
   `~/.claude/plugins/marketplaces/tokenmaxxxer-core` (a separate git
   checkout pinned to `main`@`33bcb20`, predating this fix — outside this
   issue's frozen write set, and not updated by editing this working
   tree). Writes to the default observe log
   (`~/.claude/freelunch-observe.jsonl`) are also outside this session's
   sandboxed write permissions. Both are properties of the harness this
   session runs under, not something to route around. To still get a
   real-code-execution regression check rather than a text/string
   comparison, the literal python block was extracted verbatim from the
   just-edited `freelunch/hooks/observe.sh` (by locating it between its
   `python3 -c '` / closing-`'` markers, no retyping) and `exec()`'d
   in-process against three `PreToolUse`-shaped payloads, with
   `OBSERVE_PAYLOAD`/`FREELUNCH_ENFORCE`/`sys.argv[1]` set the equivalent
   way the real bash wrapper sets them:
   - Real-dispatch payload (`subagent_type:
     "freelunch:freelunch-worker"`, `model` unset), observe-only
     (`FREELUNCH_ENFORCE` unset): logged row `"violations": []` — no
     `non_sonnet_worker`. Matches proposal step 2.
   - Same payload, `FREELUNCH_ENFORCE=1`: logged row `"violations": []`,
     `"enforced": false`, no deny JSON printed — the dispatch is allowed
     under enforcement. Matches proposal step 3.
   - Negative control — `subagent_type: "general-purpose"`, `model:
     "haiku"`, `FREELUNCH_ENFORCE=1`: logged row `"violations":
     ["non_sonnet_worker"]`, `"enforced": true`, and a deny
     `hookSpecificOutput` was printed whose `permissionDecisionReason`
     names the corrected qualified name
     (`subagent_type: freelunch:freelunch-worker`) — a genuinely
     off-Sonnet, non-freelunch-worker dispatch is still denied, proving
     the tolerant match did not turn the check into a no-op. Matches
     proposal step 4.
   All temporary payload/driver files were removed after the check;
   nothing under this artifact survives in the diff.

## What did not work

- First attempt at the defect-2 regression check ran the real, unmodified
  `freelunch/hooks/observe.sh` directly via `bash ... < payload.json` /
  piped, pointed at both the default log path and a
  `FREELUNCH_OBSERVE_LOG`-redirected scratch path. Expected: a logged row
  reflecting the fixed comparison. Actual: the default log path
  (`~/.claude/freelunch-observe.jsonl`) is outside this session's
  sandboxed write permissions, so the script's own internal
  `except Exception` around the log write silently swallowed a
  `PermissionError` (the script's trailing `2>/dev/null` hid the warning
  it would otherwise have printed), producing a misleading `exit 0` with
  no new log entry; and setting `FREELUNCH_OBSERVE_LOG=<path>` as an
  inline env-var-prefixed shell command was independently blocked by
  this session's sandbox as requiring interactive approval (unavailable
  headless). Switched to the in-process `exec()` approach described above
  once it was clear that both blockers were legitimate sandbox
  properties of this specific session, not defects in the fix, and not
  something to bypass.
- A first version of the in-process driver used relative scratch log
  paths with no directory component (e.g. `.regcheck-log-1.jsonl`).
  Expected: the driver's `os.makedirs(os.path.dirname(log_path),
  exist_ok=True)` (copied verbatim from the real script) would no-op.
  Actual: `os.path.dirname` of a bare filename returns `""`, and
  `os.makedirs("", exist_ok=True)` raises `FileNotFoundError` — the same
  `except Exception` swallowed it again, same silent-failure shape as
  the point above. Fixed by prefixing the scratch paths with `./`.

## Doc-placement ladder

- No new env var, config key, dependency, or migration.
- No changed public signature or wire format — `observe.sh`'s
  `hookSpecificOutput` JSON shape and `freelunch-observe.jsonl`'s row
  schema are both unchanged; only which `agent_type` string values
  satisfy one existing boolean condition changed.
- The one library-or-format-shaped choice this delivery makes (explicit
  two-literal comparison vs. a loosened substring match) was already
  recorded in the phase-1 proposal's `## Rationale`
  (`docs/issue-93/proposals/2026-08-03-qualify-freelunch-worker-subagent-type.md`)
  before this session started — no separate `docs/issue-93/decisions/`
  entry needed at delivery time.
- No `docs/handbooks/` entry exists for `freelunch`'s hooks (unlike
  `board-gate`/`approval-gate`, which have test handbooks); this
  delivery's write set matches the proposal's frozen `files:` exactly
  (`freelunch/hooks/freelunch.sh`, `freelunch/hooks/observe.sh`) and adds
  no new one.

## Hunt

`warrant-hunter` is not among this session's available `Agent`-tool
subagent types (same absence noted in `docs/issue-88/reports/implementation.md`
and `docs/issue-90/reports/implementation.md`). In its place, before
declaring this delivery done, dispatched a `general-purpose` subagent
(`model: sonnet`) with an explicit adversarial stance ("hostile
bypass-hunter — assume the fix is wrong until you can't find a hole"),
pointed at the exact diff and asked specifically whether the two-literal
tuple membership check (`agent_type in ("freelunch-worker",
"freelunch:freelunch-worker")`) introduces any new false-negative (some
non-`freelunch-worker` dispatch now silently passing the Sonnet pin) or
false-positive (a legitimate `freelunch-worker`-on-Sonnet dispatch still
wrongly flagged) beyond what the regression check above already covers —
case sensitivity, whitespace, `model` being `None`/non-string, and
whether qualifying the directive's instructed name could leave some other
part of the repo referencing a name that no longer resolves anywhere.

closed_checks:
- name: two-literal tolerant match — false-negative/false-positive sweep
  code_sha: 8f4ba9f887192054286b061fa86273513b8de929
  result: No finding. Widening a disjunction (`in (A, B)` vs `== A`) is
    monotonic — it can only turn a prior false-positive into a
    true-negative, never introduce a new false-positive; confirmed no new
    false-positive path exists. The added literal
    `"freelunch:freelunch-worker"` is the actual, sole registered name
    for this agent (checked against the live agent-type listing and
    `freelunch/agents/freelunch-worker.md`'s frontmatter). Only one
    plugin named `freelunch` exists in the marketplace
    (`.claude-plugin/marketplace.json`), so no namespace collision lets
    another plugin's agent literally equal either tuple string. Grepped
    the repo: no other live directive text still instructs the
    unqualified `subagent_type freelunch-worker` outside the two
    now-fixed lines. Noted, not a defect of this diff: `agent_type` is
    unnormalized (no `.strip()/.lower()`, unlike `model`) — a
    whitespace/case variant would false-positive — but that asymmetry
    predates this change (the original single-string exact-match had it
    too); and `model = (inp.get("model") or "").strip().lower()` would
    raise on a non-string truthy `model`, silently allowing the call via
    an uncaught crash — real, but lives entirely in the unchanged `model`
    line, orthogonal to the tuple addition. Neither is in this issue's
    frozen write-set scope.

## Open findings

None raised against this record.

## Next steps

None — delivery complete, both edited files still parse under bash 3.2,
regression check (real delegation, both observe/enforce modes, plus
negative control) passes per proposal steps 1-4, PR ready for merge.

## Resolution path

Any open finding against this record is resolved by amending this file
with a `resolved_findings:` entry referencing the finder's record, per
contract v3 s16, before further build commits proceed.

## Verify

`bash freelunch/hooks/tests/parse-check.sh freelunch/hooks` →
`ok freelunch.sh`, `ok observe.sh`, `ok tests/parse-check.sh`,
`parse-check: 3 file(s) under /bin/bash`.
Regression check detailed above (real `Agent` dispatch + real-code
execution of the edited comparison against real-dispatch and
negative-control payloads in both observe-only and
`FREELUNCH_ENFORCE=1` modes) — all four proposal-specified steps hold.
