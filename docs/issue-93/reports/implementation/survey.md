---
kind: coding-record
subject: issue-93
produced_by: implementation
loop_state: proposed
upstream: []
---

# Current-state survey — issue-93

## 1. Defect 1 — freelunch.sh instructs a subagent_type name that does not exist at runtime

`freelunch/hooks/freelunch.sh` is the `UserPromptSubmit` hook that prints the
`<freelunch-directive>` block injected into every role session. Two lines
inside that literal directive text tell the session to dispatch background
workers with an unqualified `subagent_type`:

- `freelunch/hooks/freelunch.sh:46` (LEAN SOLO branch): "Dispatch ONE
  background worker owning the whole unit as subagent_type freelunch-worker
  (Sonnet-pinned), never run_in_background: false."
- `freelunch/hooks/freelunch.sh:50` (LEAN FAN-OUT branch): "Launch one
  background worker per group in a single batch as subagent_type
  freelunch-worker (Sonnet-pinned; any other agent type must carry model:
  sonnet explicitly) — never run_in_background: false."

The worker agent itself is defined at `freelunch/agents/freelunch-worker.md`,
whose frontmatter (`name: freelunch-worker`, line 2) is correctly
unqualified — that field is the agent's own declared name, not the runtime
dispatch key. The plugin is registered in `.claude-plugin/marketplace.json`
under `"name": "freelunch"` (confirmed against `freelunch/.claude-plugin/plugin.json`,
which also carries `"name": "freelunch"`), and the harness namespaces every
plugin-provided agent as `<plugin-name>:<agent-frontmatter-name>` at
registration time — this is directly observable in this very session's
available-agent-types listing: `freelunch:freelunch-worker` (not
`freelunch-worker`). So the directive text's instruction and the
runtime-registered name diverge, and every session that follows the
directive literally dispatches a `subagent_type` that does not exist,
matching the issue's reproduced error verbatim ("Agent type
'freelunch-worker' not found. Available agents: ... freelunch:freelunch-worker
...").

## 2. Defect 2 — observe.sh:71 exact-match rejects the correctly-qualified name

`freelunch/hooks/observe.sh` is the `PreToolUse` hook (matcher
`Agent|Task|Workflow`) that logs every dispatch and, under
`FREELUNCH_ENFORCE=1`, denies flagged ones. The Sonnet-pin check:

```python
# observe.sh:64-71
# Sonnet pin. Satisfied two ways: an explicit sonnet model, or the
# freelunch-worker agent type whose frontmatter supplies sonnet when no
# model override is passed. Any other agent type still passes as long as
# it carries model: sonnet — the rule pins the model, not the agent type.
# "sonnet", "claude-sonnet-5", "us.anthropic.claude-sonnet-…" are all the pin;
# exact-matching "sonnet" logged legitimate dispatches as violations, which
# quietly corrupts the record the stack uses to judge its own policies.
if "sonnet" not in model and not (model == "" and agent_type == "freelunch-worker"):
    row["violations"].append("non_sonnet_worker")
```

`agent_type` (line 57: `inp.get("subagent_type", "")`) is compared with `==`
against the literal string `"freelunch-worker"`. Trace for a session that
dispatches correctly, i.e. `subagent_type: "freelunch:freelunch-worker"`
with no `model` override (relying on the agent's own `model: sonnet`
frontmatter, exactly the case the surrounding comment describes as
legitimate):

- `model` is `""` → `"sonnet" not in model` is `True`.
- `agent_type` is `"freelunch:freelunch-worker"`, not `"freelunch-worker"`
  → `model == "" and agent_type == "freelunch-worker"` is `False` →
  `not (...)` is `True`.
- Both sides of the `and` are `True` → `"non_sonnet_worker"` is appended to
  `row["violations"]`, even though the dispatch is in fact correctly
  Sonnet-pinned via frontmatter.

Two consequences, both live today:

- **Observe-only mode (default, `FREELUNCH_ENFORCE` unset):** every
  correctly-qualified dispatch gets silently mis-logged as a
  `non_sonnet_worker` violation in `~/.claude/freelunch-observe.jsonl` — the
  exact "quietly corrupts the record" failure mode the comment at
  `observe.sh:68-70` names as the reason the check was loosened away from
  exact-matching `"sonnet"` in the first place, now reproduced one field
  over (`subagent_type` instead of `model`).
- **Enforce mode (`FREELUNCH_ENFORCE=1`):** the call is denied
  (`observe.sh:111-121`) with the `non_sonnet_worker` reason text
  (`observe.sh:102-108`):

  ```python
  "non_sonnet_worker": (
      "freelunch: every worker runs on Sonnet (measured: an identical 12-worker "
      "fan-out took 78s on Haiku vs 21s on Sonnet; per-request latency dominates). "
      "Re-issue the SAME call with model: sonnet, or with subagent_type: "
      "freelunch-worker and no model override. Any agent type is fine as long as "
      "the model is Sonnet."
  ),
  ```

  Line 106's corrective text itself instructs `subagent_type:
  freelunch-worker` (unqualified) — the same wrong name defect 1 names. A
  session that re-issues the call as told would revert to the unqualified
  name and hit the runtime "Agent type not found" failure again.

## 3. The coupling between the two defects

The issue states fixing only one defect immediately trips the other; traced
against the live code, that is exactly right, and the failure shape is:

- **Only defect 1 fixed** (directive says `freelunch:freelunch-worker`,
  `observe.sh:71` unchanged): the dispatch now reaches the runtime with a
  name that exists, so it no longer fails with "Agent type not found" — but
  it now fails `observe.sh:71`'s exact match every single time (per §2
  above), because `agent_type` is never exactly `"freelunch-worker"` once
  qualified. In enforce mode this becomes a hard deny whose corrective text
  instructs going back to the wrong unqualified name (line 106) — closing a
  loop back to defect 1's original failure. In observe-only mode it
  silently and permanently mis-labels every legitimate dispatch as a
  violation in the telemetry log.
- **Only defect 2 fixed** (observe.sh loosened to accept
  `freelunch:freelunch-worker` too, directive text unchanged): the
  directive still instructs the unqualified name, so sessions still
  dispatch `subagent_type: freelunch-worker` and still fail at the runtime
  agent-resolution step before `observe.sh` (a `PreToolUse` hook) is even
  in a position to matter — the hook only inspects an already-issued tool
  call; it cannot repair a `subagent_type` string the runtime is about to
  reject as unknown.

Both files have to change together: the directive must instruct the name
that actually resolves at runtime, and the enforcement hook's comparison
must recognize that (now-correct) qualified form without regressing
recognition of legitimate unqualified/explicit-`model:` dispatches.

## 4. Sibling audit — warrant (`warrant-hunter`)

`warrant/hooks/directive.sh:60` (the `<warrant-directive>` text) instructs
the same unqualified-name pattern for its own background probe agent:

> "dispatch ONE background agent — `subagent_type: warrant-hunter`, `model:
> sonnet`, `run_in_background: true` — and carry on without waiting for
> it."

`warrant/agents/warrant-hunter.md:2` carries `name: warrant-hunter`
(correctly unqualified, same as `freelunch-worker.md` — this is the
agent's declared name, not the dispatch key). `warrant/.claude-plugin/plugin.json`
registers `"name": "warrant"`, matching `.claude-plugin/marketplace.json`'s
`"name": "warrant"` entry — so by the same plugin-namespacing mechanism
traced in §1, the runtime-registered name is `warrant:warrant-hunter`, not
`warrant-hunter`. A session following `directive.sh:60` literally would hit
the identical "Agent type not found" failure the issue reports for
`freelunch-worker` (not reproduced live this phase — out of this issue's
asked scope, see Out of scope in the proposal — but the code-level
mechanism is identical and directly traceable).

The enforcement half also exists, at `warrant/hooks/hunt-guard.sh`:

```python
# hunt-guard.sh:66
agent_type = (tool_input.get("subagent_type") or "").strip()
...
# hunt-guard.sh:90
if agent_type != "warrant-hunter":
    allow()
```

This is the same "directive says unqualified name, hook does brittle
exact-match" shape — but the **polarity is inverted** relative to
`observe.sh:71`. `hunt-guard.sh` exists to *bound* hunter dispatches
(single-flight lock, `WARRANT_HUNT_MAX` session cap, no-nesting refusal —
see its header comment, lines 1-19). Its exact-match sits behind an `allow()`
early-return: when `agent_type` is anything other than the literal string
`"warrant-hunter"`, the guard treats the call as *not a hunter dispatch at
all* and waves it through unconditionally, skipping all three limits. Today
(both defects present, `directive.sh` still instructs the unqualified name,
which fails at the runtime level before ever reaching a real hunter run)
this doesn't manifest in practice — no hunter ever actually launches to
exercise the cap. But if `directive.sh` alone were repointed to the
qualified `warrant:warrant-hunter` name without also changing
`hunt-guard.sh:90`'s comparison, the guard would stop recognizing legitimate
hunter dispatches as hunter dispatches at all: the single-flight lock, the
3-dispatch session cap, and the no-nesting refusal would all go silently
unenforced — a fail-open regression, the opposite direction from
`observe.sh`'s fail-closed/false-positive-deny. This is a second,
independently-confirmed instance of the exact defect family the issue names
(unqualified name in a directive + brittle exact-match in its paired
enforcement hook), with an inverted failure direction. Recorded per the
issue's explicit ask; not fixed this issue (see proposal's Out of scope).

No other `subagent_type` hardcoding was found in
`warrant/hooks/hunt-state.sh`, `warrant/hooks/scope-gate.sh`,
`warrant/hooks/state.sh`, or `warrant/README.md` (grepped for
`subagent_type`, `agent_type`, `warrant-hunter`: no matches).

## 5. Sibling audit — scout

`scout/hooks/directive.sh` (the entire `<scout-directive>` text) never
names a `subagent_type` at all. Its only fan-out instruction (STAGE 1
SWEEP, line 44) reads: "Run several such angles concurrently in one turn —
e.g. by-category, by-content, by-citation/links, by-time — as parallel
subagents (Agent tool, one message with multiple calls) or parallel tool
calls (e.g. multiple WebSearch calls in one message)" — no specific
`subagent_type` is pinned; whatever general-purpose or role-appropriate
agent type the session already has access to is implied. `scout` also ships
no `agents/*.md` of its own: `find scout -type f` lists only
`.claude-plugin/plugin.json`, `hooks/directive.sh`, `hooks/hooks.json`,
`hooks/tests/parse-check.sh`, `README.md` — no `agents/` directory. Scout
does not carry this defect family: **none found.**

## 6. Prior decisions

No `docs/decisions/` directory exists anywhere in this repo (checked both
directly — `ls docs/decisions` fails — and via a repo-wide
`find . -type d -iname decisions`, no hits). Nothing to reconcile this
survey against.

## 7. Evidence-citation note

The issue cites four on-the-record occurrences of this failure:
`docs/issue-216/reports/implementation.md:96`,
`docs/issue-218/reports/implementation.md:108,154`,
`docs/issue-220/reports/implementation.md:115,157`, and
`docs/reports/2026-08-03-hunt-issue-222-*.md:4`. None of these paths exist
in this repo checkout — `docs/` here contains issues up through issue-90
only (confirmed via `ls docs/`), and no `docs/reports/2026-08-03-hunt-issue-222*`
file is present (confirmed via `find`). These are presumably records from a
downstream repository that installs the `freelunch` plugin from this
marketplace (a role-session workspace, not `tokenmaxxxer-core` itself) —
noted honestly rather than claiming a citation check that could not
actually be performed against this repo's contents.

## 8. Write-set projection (for phase 2)

- `freelunch/hooks/freelunch.sh:46,50` — replace the unqualified
  `subagent_type freelunch-worker` wording with the runtime-correct
  `freelunch:freelunch-worker`.
- `freelunch/hooks/observe.sh` — `:71`'s comparison (plus the explanatory
  comment at `:8-9,64-70` and the corrective text at `:102-108`, which
  repeats the unqualified name at `:106`) needs to recognize the qualified
  name; exact mechanism is a proposal-stage decision (see Rationale in the
  proposal).
- Sibling, identified this phase, disposition decided in the proposal:
  `warrant/hooks/directive.sh:60`, `warrant/hooks/hunt-guard.sh:90`.

## Skip record (scout-directive)

Scouting skipped — **skip condition 1** ("the task is a pure bugfix")
applies. Reason: issue #93 names the exact two defect lines, the exact
wrong string, the exact runtime-correct string, and both required
properties of the fix (the directive's instructed name must match a name
that actually resolves at runtime; the enforcement hook's comparison must
recognize both the qualified and legitimate unqualified/explicit-`model:`
forms) — there is no external/product-facing design question that would
need field reconnaissance to answer. The only open question is an internal
implementation-shape choice among a few concrete alternatives (normalize at
the comparison site vs. accept-both-literals vs. normalize once at
injection time), which is decided in the proposal's Rationale, not sourced
from best-in-class field practice.
