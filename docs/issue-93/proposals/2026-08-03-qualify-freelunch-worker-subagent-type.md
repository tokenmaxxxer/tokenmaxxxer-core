---
kind: build-proposal
subject: issue-93
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-93/reports/implementation/survey.md
    sha: <set at commit>
---

files: `freelunch/hooks/freelunch.sh`, `freelunch/hooks/observe.sh`

## Request

freelunch's own directive text tells every role session to dispatch
background workers with `subagent_type freelunch-worker` (unqualified), but
the harness registers the plugin's worker agent under the namespaced name
`freelunch:freelunch-worker`. Every session that follows the directive
literally fails its first delegation with "Agent type 'freelunch-worker' not
found" — reproduced live (core issue #90's execution-observation session,
three consecutive failures) and recorded, unfixed, across at least four
prior sessions per #93. Separately, `observe.sh:71`'s Sonnet-pin check
does an exact-match comparison of `subagent_type` against the same
unqualified literal, so simply renaming the directive's instructed value to
the qualified form immediately trips that check instead — a correctly
Sonnet-pinned dispatch gets logged (and, under `FREELUNCH_ENFORCE=1`,
denied) as `non_sonnet_worker`, with a corrective message that itself
repeats the wrong unqualified name. Both files need to change together.
#93.

## Constraints

- The fix lives in core's `freelunch` plugin only (`freelunch/hooks/*.sh`)
  — not `spawn.py`, not a role-session-side workaround (skipping the
  directive, inlining execution). Per #93's stated constraint.
- `observe.sh` must stay parseable by bash 3.2 (`freelunch/hooks/tests/parse-check.sh`
  guards this across every hook in the repo) — no new heredoc-inside-`$()`
  nesting, no apostrophes or unbalanced parens introduced into a quoted
  heredoc body.
- `observe.sh`'s embedded Python block is invoked once per `Agent`/`Task`/`Workflow`
  `PreToolUse` event; the comparison fix must not change behavior for the
  other flagged rule (`sync_agent_dispatch`) or for any dispatch that
  already carries an explicit `model:` value.
- The enforcement hook's comparison must recognize BOTH the qualified
  (`freelunch:freelunch-worker`) and legitimate unqualified
  (`freelunch-worker`) spellings — per #93's requirement 2, fixing only one
  side and calling it done is explicitly disallowed.
- Regression proof must be an actual successful delegation (a real
  Agent-tool dispatch to `subagent_type: freelunch:freelunch-worker`
  succeeding end to end), never a string/text-equality check on the
  directive or hook source — per #93's requirement 3.

## Rationale

**Directive fix shape: change the instructed name at the source
(`freelunch.sh:46,50`), not just the enforcement hook.** The alternative of
patching only `observe.sh`'s comparison logic (e.g. making it
suffix-tolerant so a qualified name would eventually pass) while leaving
the directive's instructed value as the bare `freelunch-worker` was
considered and rejected: `observe.sh` is a `PreToolUse` hook — it inspects
a tool call already issued with a `subagent_type` value chosen by the
model, which chose it by reading the directive text. If the directive still
says the wrong name, sessions still type the wrong name, and the dispatch
still fails at the runtime agent-resolution step (the issue's actual
reported symptom, "Agent type not found") regardless of what the
enforcement hook would have done with it. `observe.sh` cannot mutate the
tool call it observes — its `hookSpecificOutput` only supports
`permissionDecision: deny` plus a text reason (`observe.sh:111-121`), there
is no payload-rewrite path a `PreToolUse` hook can take in this harness.
Fixing the directive text is therefore the only lever available for the
primary defect; the enforcement hook can only ever be a second, dependent
fix.

**Enforcement-hook fix shape: recognize both forms explicitly, rather than
loosen the match into a broad substring/pattern test.** Considered making
`observe.sh:71` a loose containment check — `"freelunch-worker" in
agent_type` — instead of an explicit two-literal comparison. Rejected:
the whole reason the check is an exact match today (per its own comment,
`observe.sh:68-70`) is that an earlier version exact-matched `"sonnet"`
against `model` and a looser match was rejected as corrupting the record
in the other direction (too permissive, not too strict) — the design
intent here is precision, not maximum leniency. A bare substring test would
also pass any future, unrelated agent type whose name happens to contain
`freelunch-worker` as a substring (e.g. a hypothetical
`other-freelunch-worker-v2`), silently widening what counts as the Sonnet
pin's second satisfaction path well past what the comment describes ("the
freelunch-worker agent type whose frontmatter supplies sonnet"). The chosen
shape instead recognizes exactly the two strings that legitimately mean
"the freelunch-worker agent, dispatched with or without the plugin
namespace prefix" — `agent_type in ("freelunch-worker",
"freelunch:freelunch-worker")` (or the equivalent: strip a literal
`"freelunch:"` prefix before comparing to `"freelunch-worker"`) — keeping
the check exact everywhere except the one specific case #93 identifies as
broken.

**Canonical spelling going forward: the qualified form, in the directive;
the hook stays tolerant of both.** #93 leaves choice of canonical spelling
to this proposal but requires the hook accept both regardless. The
directive is fixed to instruct `freelunch:freelunch-worker` because that is
the only spelling that resolves at dispatch time — instructing the
unqualified form would just reintroduce the original failure. The hook
keeps accepting the bare `freelunch-worker` alongside it (rather than
narrowing to only the qualified form) because nothing in this repo's
plugin-namespacing mechanism guarantees `subagent_type` is always
harness-injected with a plugin prefix in every context this hook might see
(e.g. the same agent loaded without the marketplace prefix), and #93's
requirement 2 asks explicitly for both to be recognized.

## What will be done

- [ ] `freelunch/hooks/freelunch.sh:46` — replace `subagent_type
  freelunch-worker` with `subagent_type freelunch:freelunch-worker` in the
  LEAN SOLO branch's dispatch instruction.
- [ ] `freelunch/hooks/freelunch.sh:50` — same replacement in the LEAN
  FAN-OUT branch's dispatch instruction.
- [ ] `freelunch/hooks/observe.sh:71` — change the comparison to accept
  both recognized forms, e.g.:
  `if "sonnet" not in model and not (model == "" and agent_type in ("freelunch-worker", "freelunch:freelunch-worker")):`
  (exact code shape — explicit tuple vs. prefix-strip-then-compare — settled
  during implementation per the Rationale above; either satisfies the same
  requirement).
- [ ] `freelunch/hooks/observe.sh:8-9,64-70` — update the explanatory
  comments so they describe both recognized forms, keeping the comment in
  sync with the code it explains (the existing comment already documents
  why exact-matching `model` against `"sonnet"` was rejected; extend the
  same reasoning to `agent_type`).
- [ ] `freelunch/hooks/observe.sh:102-108` (`REASONS["non_sonnet_worker"]`)
  — update the corrective text so a denied call is told to use the
  qualified name `freelunch:freelunch-worker` (or an explicit `model:
  sonnet`), not the bare unqualified one, so a deny's own guidance cannot
  loop back into defect 1.
- [ ] `bash freelunch/hooks/tests/parse-check.sh freelunch/hooks` — confirm
  both edited files still parse under bash 3.2.
- [ ] Regression check per "How you'll know it worked" below — executed as
  part of phase 2, not deferred to a future session.

## Out of scope

- `warrant/hooks/directive.sh:60` and `warrant/hooks/hunt-guard.sh:90` —
  the survey confirms these carry the same defect family (unqualified
  `subagent_type: warrant-hunter` in the directive; brittle exact-match in
  the paired enforcement hook, with an inverted fail-open polarity since
  `hunt-guard.sh`'s guard sits behind an `allow()` early-return rather than
  a deny). #93 explicitly asks only that this be checked at proposal
  stage ("같은 결함이 있는지 제안 단계에서 확인할 것"), not fixed here, and
  its Constraints section frames the check as investigation. Left
  unfixed this issue because: (a) `warrant`'s guard bounds a different,
  higher-stakes surface (background hunters that read arbitrary repo
  state and write to `docs/reports/`) with its own single-flight/session-cap
  invariants, whose regression proof needs its own real-dispatch check
  against those specific invariants, not a drive-by fix riding on this
  issue's write set; (b) bundling it here would widen this proposal's
  frozen write set past `freelunch/hooks/*.sh` into a second plugin with
  its own test/README surface, for a defect not yet reproduced live (only
  traced code-side). Recommended as a follow-up issue.
- `scout/hooks/directive.sh` — audited, no instance of this defect family
  found (scout never pins a specific `subagent_type` for its fan-out
  angles). Nothing to fix.
- Any other freelunch directive rule (width/threshold logic, worker
  liveness, mode re-decision, etc.) beyond the two named defects.
- `freelunch/agents/freelunch-worker.md`'s own `name: freelunch-worker`
  frontmatter field — correct as-is; it is the agent's declared local name,
  and the plugin-namespace prefix is applied by the harness at
  registration, not something the agent's own file should carry.
- Reproducing the `warrant-hunter` failure live (spinning up a session
  that actually attempts the broken dispatch) — the code-level trace in
  the survey is sufficient for the audit #93 asks for; live reproduction
  is deferred to whatever issue eventually fixes it.

## How you'll know it worked

A string or text-equality check is explicitly insufficient (#93's
requirement 3) — grepping `freelunch.sh` for `freelunch:freelunch-worker`
proves the text changed, not that delegation works. Phase 2's regression
check is a real dispatch:

1. From a session with the `freelunch` plugin enabled, issue an actual
   `Agent` tool call with `subagent_type: "freelunch:freelunch-worker"`,
   `run_in_background: true`, and no `model` override, on a trivial task
   (e.g. "reply with the word ready"). Confirm it is accepted by the
   runtime (no "Agent type ... not found" error) and that the background
   agent starts and returns a result.
2. Inspect the row `observe.sh` appended to `$FREELUNCH_OBSERVE_LOG` (or
   `~/.claude/freelunch-observe.jsonl` by default) for that exact dispatch:
   `violations` must NOT contain `"non_sonnet_worker"`.
3. Re-run the same dispatch with `FREELUNCH_ENFORCE=1` set: it must be
   allowed (no deny), confirming the fix holds under enforcement, not just
   observe-only mode.
4. Negative control, same enforce mode: dispatch a call that is genuinely
   off-Sonnet and not `freelunch-worker`-shaped (e.g. `subagent_type:
   general-purpose` with an explicit non-Sonnet `model` and no Sonnet
   pin) and confirm it is still denied with `non_sonnet_worker` — proving
   the fix recognized the two legitimate forms without turning the check
   into a no-op for everything else.

Only after steps 1-4 all hold does phase 2 count the fix as verified.
