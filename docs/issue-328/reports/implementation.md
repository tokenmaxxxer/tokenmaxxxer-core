---
issue: 328
role: implementation
author: implementation
loop_state: landed
upstream:
  - path: N/A — build-now bypass (contract v3 s19a, CORE_BUILD_NOW=1 set by spawner); no phase-1 proposal round ran
    sha: same-commit
code_under_review:
  - docs/issue-328/reports/implementation.md
type: docs
breaking: "no — no src/hooks file in tokenmaxxxer-core was changed; this is an investigation-only deliverable, see Finding 3 below for why"
verdict: pass
---

# issue-328 — implementation record

skill-verdict: silent-failure-audit — applied: invoked; used its Handled/Silently-Absorbed/Unreachable taxonomy and its `site → return value → caller behavior → downstream consequence` trace format to structure Finding 2 (the missing-entry fail-open behavior in both gates) below.
skill-verdict: diagnose-first — applied: invoked; used its Stage-0/1/2/3 shape (define the compatibility question as a checkable statement, get a real baseline instead of a reading, verify the root blocker with evidence, then classify the actual-migration decision as a one-way door before acting on it) to decide to stop and report after Finding 3 rather than write a loader/migration on a guess.
skill-verdict: work-in-english — applied: invoked; record, commit message and PR body are in English per this skill's routing rule; the final chat summary to the user is in Korean.

## What was done

Answered the issue's four acceptance checks with executed evidence, not a
reading of the code. No source file in `tokenmaxxxer-core` was changed —
Finding 3 below is the evidence-backed reason the actual data move is not
safe to execute inside this PR, and the issue's own guardrail on Finding 1
("must not: proceed past a negative answer by writing a new loader") is
honored in spirit even though Finding 1 itself came back positive, because
Finding 3 is an independent blocker the issue text did not anticipate.

### Finding 1 — compatibility question: YES, a skill directory can carry a config file the mount path surfaces (real load, not a reading)

`resolved_skill_dirs()` returns the whole skill directory `Path`, not just
`SKILL.md`:

```
canonical: /home/jwjung/.claude/plugins/marketplaces/tokenmaxxxer/skills.py:110-129 (resolved_skill_dirs)
    123    available = sorted(p.name for p in repo_root.iterdir()
    124                        if p.is_dir() and not p.name.startswith("."))
    ...
    129    return [repo_root / n for n in names]
```

and the session already publishes the resolved skill-repository checkout
root as an env var — `printenv` in this session: `MUSTER_SKILL_REGISTRY_ROOT=/home/jwjung/skill-registry/skills`
(confirmed to be a real git checkout of `tokenmaxxxer/skill-repository` at
`297e350`, matching `MUSTER_SKILL_REPO_SHA` — `derived: cd /home/jwjung/skill-registry/skills && git remote -v && git log --oneline -1` → `origin git@github.com:tokenmaxxxer/skill-repository.git (fetch)` / `297e350 issue-109: retired-vocabulary sweep...`).

Real-load test executed (not a code reading): wrote a `citation-config.json`
fragment into a real skill directory
(`/home/jwjung/skill-registry/skills/architecture-decomposition-strategy/citation-config.json`,
containing the `architecture` row with a marker string
`SKILL-MOUNT-REAL-LOAD-TEST` appended to its deny message so the run could
be distinguished from the central file), resolved that path exactly the way
`resolved_skill_dirs()` resolves skill dirs (via
`Path(os.environ['MUSTER_SKILL_REGISTRY_ROOT']) / 'architecture-decomposition-strategy'`),
and ran the real `core/hooks/citation-gate.sh` against a real violating
payload with `CITATION_CONFIG` pointed at that skill-mounted file:

```
derived: CITATION_CONFIG="/home/jwjung/skill-registry/skills/architecture-decomposition-strategy/citation-config.json" CLAUDE_ROLE="architecture" CLAUDE_PROJECT_DIR="$(pwd)" bash core/hooks/citation-gate.sh < /tmp/issue328_violating_payload.json
citation-gate: asserts external/industry knowledge ('industry practice') with no URL or Sources: entry -- SKILL-MOUNT-REAL-LOAD-TEST
exit=0
```

The marker string in the output proves the gate genuinely loaded the config
from inside the skill directory (not a fallback to
`core/hooks/citation-config.json`). Same result repeated for
`facet-keyword-gate.sh` against `content-design-operational-playbook/facet-keyword-config.json`
(see Finding 4 for the full quoted before/after run). **Answer: compatible —
a skill directory can carry a config file that the existing skill-mount
path (the `MUSTER_SKILL_REGISTRY_ROOT`-published checkout that
`resolved_skill_dirs()` resolves into) actually surfaces to a real gate
invocation.**

### Finding 2 — missing-entry behavior: fails OPEN today, in both configs, unchanged when sourced from a skill dir (Silently-Absorbed pattern)

File:line citations for today's behavior:

```
canonical: core/hooks/citation-gate.sh:89-92
    89   role = os.environ.get("CIT_ROLE", "")
    90   rows = config.get(role) if isinstance(config, dict) else None
    91   if not rows:
    92       sys.exit(0)  # no citation row configured for this role -- empty state
```

```
canonical: core/hooks/facet-keyword-gate.sh:100-103
    100  role = os.environ.get("FK_ROLE", "")
    101  facets = config.get(role) if isinstance(config, dict) else None
    102  if not facets:
    103      sys.exit(0)  # no facet configured for this role -- empty state, pass through
```

Both files also state this in their own header comments
(`citation-gate.sh:20-22`, `facet-keyword-gate.sh:14-16`): "an acting role
with no config row, or a missing/unreadable config file, passes through
silently (exit 0)."

Silent-failure-audit trace (site → return value → caller behavior →
downstream consequence), classification **Silently Absorbed**: the missing
lookup at `citation-gate.sh:91-92` / `facet-keyword-gate.sh:102-103` returns
control via `sys.exit(0)` with no stderr, no `additionalContext`, no
`systemMessage` — the same exit code and same silence as "nothing matched,
nothing to check." The calling PreToolUse dispatcher sees a clean exit and
lets the write proceed. No downstream code path ever learns that a
config row was expected and absent; nothing reports it. **This is
today's behavior, unchanged by the location of the config file** — the same
`if not rows / if not facets` branch runs regardless of whether `config` was
loaded from `core/hooks/citation-config.json` or from a skill-repository
directory, because the branch only inspects the parsed dict's key lookup,
never its file origin.

Constructed a skill with no entry and ran the real gate against it (not a
reading):

```
derived: CITATION_CONFIG="/home/jwjung/skill-registry/skills/adversarial-review/citation-config.json" CLAUDE_ROLE="architecture" CLAUDE_PROJECT_DIR="$(pwd)" bash core/hooks/citation-gate.sh < /tmp/issue328_violating_payload.json ; echo "exit=$?"
exit=0
```
(no stdout/stderr at all — `adversarial-review` has no `citation-config.json`
file, so `open()` raises `OSError` and the gate exits 0 at the earlier
`except (OSError, ValueError): sys.exit(0)` branch, `citation-gate.sh:83-87`
in the python heredoc — same silent pass, one branch earlier than the
per-role lookup.)

```
derived: FACET_KEYWORD_CONFIG="/home/jwjung/skill-registry/skills/adversarial-review/facet-keyword-config.json" CLAUDE_ROLE="content-design" CLAUDE_PROJECT_DIR="$(pwd)" bash core/hooks/facet-keyword-gate.sh < /tmp/issue328_facet_violating_payload.json ; echo "exit=$?"
exit=0
```

Per the issue's explicit instruction ("must not: accept that a missing
entry silently passes; if that is today's behavior, say so plainly as a
finding rather than preserving it silently"): **this finding is stated
plainly. Today's missing-entry behavior is fail-open, and moving the data
onto the skill axis does not change that by itself** — every skill directory
that has not yet been given a config entry (which, on day one of any move,
is every skill directory except the ones actually populated) is silently
unchecked, exactly the `write_scope` risk shape named in
on-the-record#2539. Fixing that (a fail-closed default, or an explicit
coverage report of which skills carry no entry) is a design decision this
issue's Non-goals section places outside "what the data move requires," so
it is reported here, not fixed here.

### Finding 3 — the actual data move cannot be executed from this PR (new blocker, not the one the issue anticipated)

Two independent, evidence-backed reasons:

**3a. Cross-repo boundary.** The skill-mounted directories the gate would
need to read from live in `tokenmaxxxer/skill-repository`, a separate git
repository from `tokenmaxxxer-core`:

```
canonical: cd /home/jwjung/skill-registry/skills && git remote -v
origin  git@github.com:tokenmaxxxer/skill-repository.git (fetch)
origin  git@github.com:tokenmaxxxer/skill-repository.git (push)
```

This role session's branch and PR authority (`issue-328/implementation`,
per the role-handoff contract) is scoped to `tokenmaxxxer-core` only. Moving
the actual config row content into skill directories means writing files
into `tokenmaxxxer/skill-repository`, which requires a separate PR against
that repository — out of scope for what this session can land.

**3b. No established role → skill selection convention (the config would
have to fan out to more than one skill directory per role, or a new
selection rule invented on the spot).** Every role key in both configs was
checked against the real skill-repository directory listing:

```
derived: python3 -c "
import json, os
roles = sorted(set(json.load(open('core/hooks/citation-config.json')).keys()) | set(json.load(open('core/hooks/facet-keyword-config.json')).keys()))
skills = sorted(os.listdir('/home/jwjung/skill-registry/skills'))
for r in roles:
    matches = [s for s in skills if s == r or s.startswith(r + '-')]
    print(f'{r}: {len(matches)} matching skill dir(s)')
"
api-design: 6 matching skill dir(s)
architecture: 5 matching skill dir(s)
capacity-planning: 5 matching skill dir(s)
conformance-review: 7 matching skill dir(s)
content-design: 1 matching skill dir(s)
customer-support: 6 matching skill dir(s)
finance-unit-economics: 6 matching skill dir(s)
interaction-design: 1 matching skill dir(s)
requirements-engineering: 1 matching skill dir(s)
sales: 3 matching skill dir(s)
security-threat-model: 1 matching skill dir(s)
technical-feasibility: 10 matching skill dir(s)
test-authoring: 1 matching skill dir(s)
```

Every one of the 13 unique role keys has at least one prefix-matching skill
directory (good — no role is orphaned), but 9 of the 13 have *more than
one* (up to 10, for `technical-feasibility`). There is no file, manifest, or
function found anywhere in `tokenmaxxxer-core`, the `on-the-record` plugin
root, or `skills.py`'s role-resolution helpers
(`resolve_role_source`/`resolve_skill_source`, `skills.py:360-448`) that
declares "these N skill directories are *the* skills for role X" for this
purpose — `resolved_skill_dirs()` only resolves an explicit `--skills a,b,c`
CSV the spawner already named, it does not derive membership from a role
name. Writing a citation/facet row into one arbitrarily-chosen skill
directory per role (e.g. picking `architecture-decomposition-strategy` the
way this investigation's test did) would silently stop covering every write
governed by the other 4 `architecture-*` skills — the same fail-open shape
as Finding 2, self-inflicted by the migration itself. Fanning the row out
to all N directories is possible but is a design decision (which N, kept in
sync how) this issue's Non-goals section excludes ("do not migrate the
hooks... beyond what the data move requires").

Per diagnose-first's Stage 3 (decision reversibility): deleting the two
central config files and pointing both gates at a skill-scoped lookup is a
one-way door for every governed role in the system, not a two-way-door
experiment — Gate G2/G3 (evidence-backed cause, documented rationale, no
proceeding on a guess) argue for reporting this now rather than picking an
arbitrary skill-per-role mapping to make the diff look complete.

### Finding 4 — both gates shown still refusing a real violating payload, quoted before and after

**citation-gate.sh, BEFORE** (today's central `core/hooks/citation-config.json`):
```
derived: CLAUDE_ROLE="architecture" CLAUDE_PROJECT_DIR="$(pwd)" bash core/hooks/citation-gate.sh < /tmp/issue328_violating_payload.json
citation-gate: asserts external/industry knowledge ('industry practice') with no URL or Sources: entry in the same section (or, for headingless files, within 15 lines). Per issue-1's citation-format rule, cite the claim or restate it as an assumption.
exit=0
```

**citation-gate.sh, AFTER** (config sourced from the real skill-mounted directory):
```
derived: CITATION_CONFIG="/home/jwjung/skill-registry/skills/architecture-decomposition-strategy/citation-config.json" CLAUDE_ROLE="architecture" CLAUDE_PROJECT_DIR="$(pwd)" bash core/hooks/citation-gate.sh < /tmp/issue328_violating_payload.json
citation-gate: asserts external/industry knowledge ('industry practice') with no URL or Sources: entry -- SKILL-MOUNT-REAL-LOAD-TEST
exit=0
```

**facet-keyword-gate.sh, BEFORE** (today's central `core/hooks/facet-keyword-config.json`):
```
derived: CLAUDE_ROLE="content-design" CLAUDE_PROJECT_DIR="$(pwd)" bash core/hooks/facet-keyword-gate.sh < /tmp/issue328_facet_violating_payload.json
facet-keyword-gate: copy string '## Copy string: welcome banner' missing tone-axis check (present-or-skipped-with-reason required)
exit=0
```

**facet-keyword-gate.sh, AFTER** (config sourced from the real skill-mounted directory):
```
derived: FACET_KEYWORD_CONFIG="/home/jwjung/skill-registry/skills/content-design-operational-playbook/facet-keyword-config.json" CLAUDE_ROLE="content-design" CLAUDE_PROJECT_DIR="$(pwd)" bash core/hooks/facet-keyword-gate.sh < /tmp/issue328_facet_violating_payload.json
facet-keyword-gate: copy string '## Copy string: welcome banner' missing tone-axis check (present-or-skipped-with-reason required) -- SKILL-MOUNT-REAL-LOAD-TEST
exit=0
```

Both gates still refuse the same violating payload identically (modulo the
`-- SKILL-MOUNT-REAL-LOAD-TEST` marker deliberately added to prove the
config source) whether the config is loaded from `core/hooks/*.json` or
from inside a real skill-repository directory.

### Acceptance-check status

- Check 1 (compatibility, real load) — met. See Finding 1.
- Check 2 (missing-entry behavior, file:line, unchanged, plain finding) — met. See Finding 2.
- Check 3 (key-set diff, both sets shown, no "all migrated" claim) — **not executed as a physical move**; a readiness mapping is shown in Finding 3b (13/13 role keys have at least one candidate skill directory) instead of a before/after diff of an actually-moved file, because Finding 3 blocks the move itself. No key was dropped, none was moved — this check's literal form ("diff the key sets... quote the comparison") does not apply to a move that did not happen, and is not claimed as satisfied.
- Check 4 (both gates refuse a real violating payload, before/after) — met. See Finding 4.

### Test-artifact cleanup

The scratch config files written into the `skill-repository` checkout for
the real-load tests were removed before finishing:
```
derived: cd /home/jwjung/skill-registry/skills && git status --short && git checkout -- . && git clean -fd architecture-decomposition-strategy content-design-operational-playbook && git status --short
?? architecture-decomposition-strategy/citation-config.json
?? content-design-operational-playbook/facet-keyword-config.json
architecture-decomposition-strategy/citation-config.json 제거
content-design-operational-playbook/facet-keyword-config.json 제거
(second git status --short: empty — clean)
```

## Why

The issue frames Finding 1 (compatibility) as the single gate that must be
checked before any building happens. That check came back positive, but the
investigation surfaced a second, independent blocker (Finding 3) that the
issue text did not anticipate: the actual destination for the moved data is
a different git repository this session has no PR authority over, and the
role→skill mapping needed to place each config row correctly does not exist
as an established convention — every role maps to *multiple* skill
directories, not one. Writing the migration anyway would mean either (a)
picking an arbitrary single skill directory per role, which silently
stops covering every other skill sharing that role's prefix (the exact
fail-open shape Finding 2 already flags as a live risk), or (b) inventing a
fan-out/sync mechanism, which the issue's own Non-goals section excludes.
Reporting both findings with executed evidence, rather than picking one of
those two unreviewed inventions to make the diff look complete, is the
correct instance of the issue's own instruction not to proceed past a
negative signal.

## What did not work

None.

## Upstream basis

No upstream proposal document — build-now bypass (contract v3 s19a): the
spawning environment carried `CORE_BUILD_NOW=1`, authorizing direct
delivery without the phase-1 proposal round. All evidence in this record was
produced live in this session (see the `derived:`/`canonical:` citations
above); nothing was carried forward from a prior document.

## Open findings

- Finding 3 (cross-repo boundary + no role→skill selection convention) is
  the resolution path for continuing this work: it needs (a) a decision,
  made by someone with authority over both repos, on whether a role's
  config fans out to every prefix-matching skill directory or picks one
  canonical directory per role, and (b) a `tokenmaxxxer/skill-repository`
  PR to actually place the data, coordinated with a `tokenmaxxxer-core` PR
  that changes `citation-gate.sh`/`facet-keyword-gate.sh` to resolve config
  by skill instead of by `CLAUDE_ROLE`. Neither is started here.
- Finding 2's fail-open missing-entry behavior is an existing condition,
  not introduced by this investigation; it is not fixed here per the
  issue's own Non-goals ("do not migrate the hooks... beyond what the data
  move requires") — flagged for whoever picks up Finding 3's follow-up to
  decide whether the fan-out/selection design should also close this gap.

## Next steps

None from this record — `loop_state: landed`. Follow-up work is the two
items under Open findings, to be scoped as a new issue/proposal by whoever
picks this up next.
