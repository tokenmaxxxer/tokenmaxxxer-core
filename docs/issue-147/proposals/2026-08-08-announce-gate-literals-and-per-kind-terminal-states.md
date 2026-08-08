kind: build-proposal
subject: issue-147
produced_by: implementation
upstream:
  - path: core/hooks/record-fields-gate.sh
    sha: same-commit
  - path: core/hooks/handbook-trigger-gate.sh
    sha: same-commit
  - path: core/hooks/directive.sh
    sha: same-commit
  - path: core/contract/role-handoff-contract.md
    sha: same-commit
  - path: docs/issue-147/reports/implementation/survey.md
    sha: same-commit
loop_state: proposed
files:
  - core/hooks/directive.sh
  - core/hooks/record-fields-gate.sh
  - core/hooks/handbook-trigger-gate.sh
  - core/hooks/tests/run-role-gates-tests.sh
  - core/hooks/tests/run-gate-prose-coverage-tests.sh
  - docs/handbooks/core.md

## Request

Core's own three `PreToolUse`/`SessionStart` hooks deny role sessions on
rules the session was never told:

1. `record-fields-gate.sh` requires §20's minimum record fields (using
   specific accepted spellings) but `directive.sh`'s injected prose never
   states them, so a role's first record write is denied for a
   requirement it had no way to learn (C1).
2. `record-fields-gate.sh`'s terminal-state check uses one flat,
   hand-collected list that has empty intersection with contract §2's
   actual per-`kind` terminal `loop_state` vocabulary, so a record written
   at its own contract-correct terminal state (e.g. `verify-record` at
   `cleared`) is denied as if still open. The only override channel
   (`RECORD_FIELDS_TERMINAL_STATES`) has been attempted seven times
   downstream and works zero times, in five different broken spellings,
   all silent (C2).
3. `handbook-trigger-gate.sh` blocks a commit that stages an operational
   surface file without a `docs/handbooks/` update, but the directive
   mentions `handbooks` only as a doc-bucket name, never as a
   commit-blocking obligation with its trigger-file set (C3).

Fix all three by moving the literal rules into the prose a role session
actually receives at session start (`directive.sh`), replacing C2's flat
terminal-state list with a per-`kind` mapping derived from contract §2,
and replacing the broken override channel with one that either takes
effect or fails loudly — then verifying all three against #146's
gate-literal↔injected-prose coverage checker so they cannot drift back
silently the way #140's C2 "fix" did.

## Constraints

- Contract §2 (`core/contract/role-handoff-contract.md:57-87`) is the
  single source of truth for each record `kind`'s `loop_state`
  vocabulary; the gate's terminal-state derivation must trace to it, not
  to an inventory of previously-observed denial spellings (the mistake
  #140 made).
- The override mechanism must **fail loudly** (nonzero exit, explicit
  error text naming what is wrong) on misconfiguration — never silently
  no-op the way all seven downstream attempts did.
- Any new literal a gate can deny on that belongs in `directive.sh` must
  be phrased so #146's `gate-prose-coverage-check.py` extractor actually
  finds it (whole-word, case-insensitive match against the needle shapes
  it recognizes: `has_any(...)` string literals, `{"key": re.compile}`
  dict keys, or `re.search(r'^\s*(name):' ...)` field keys) — restating
  the rule in different words that the checker cannot match does not
  satisfy the issue's acceptance criterion ("#146 check passes for core
  with no exceptions carved out").
- Existing behavior for the two checks this issue does not touch (the
  `sha:` placeholder validation, the `code_under_review` bare-sha check)
  must be preserved unchanged.
- No rulebook repo carries `core/contract/role-handoff-contract.md`
  (0/43, per the issue) — the fix must not assume any repo other than
  `core` itself can read the contract file at role-session time.
- Kill switches (`RECORD_FIELDS_GATE_OFF`, `HANDBOOK_TRIGGER_GATE_OFF`,
  `CORE_OFF`) and the existing `fail-closed`-on-internal-error wrapper in
  every hook stay as-is; this issue does not touch failure-mode plumbing
  unrelated to C1/C2/C3.

## Rationale

**Inline the literals into `directive.sh` rather than shipping the
contract file into every rulebook repo and pointing the directive at
it.** The issue's own "Fix direction" section names both options and
declines to pick; the survey resolves it: 0 of 43 rulebook repos
currently carry `docs/specs/role-handoff-contract.md` or any equivalent,
so "point the directive at the contract" requires a second, independent
distribution mechanism (deciding *how* the contract file reaches every
repo, keeping it in sync, and handling repos that already have their own
`docs/specs/` conventions) before the literals become reachable at all —
exactly the kind of new cross-repo machinery C2 shows this project should
not add speculatively. Inlining into `directive.sh` uses a distribution
channel that already demonstrably works: `directive.sh` is injected via
`SessionStart` into every role session in every repo today (that is the
entire reason C1/C3 are bugs — the channel exists and is simply
under-populated). It also is the one place #146's coverage checker
already scans as the "injected" boundary, so satisfying the issue's third
acceptance line ("#146 check passes for core with no exceptions") falls
out of the same edit rather than requiring the checker to also learn a
new corpus source for a shipped contract file.

**Derive terminal states from a per-`kind` mapping keyed off the
record's own `kind:` field, rather than widening the flat list again.**
This is the second rejected alternative, already tried and already
disproved: #140 widened the same flat `RECORD_FIELDS_TERMINAL_STATES`
default from `landed` to six spellings and produced a set with **zero**
intersection with contract §2's real vocabulary (`docs/issue-140/reports/
implementation.md`; confirmed by grep in the survey). A flat list is
structurally incapable of being correct here: `cleared` is terminal for a
`verify-record` and meaningless (not even a defined state) for an
`ops-record`; `steady` is the reverse. Any single global set either
under-admits (misses valid terminal states for some kinds, C2's
manifestation) or over-admits (accepts a state as terminal for a kind
where the contract does not define it as terminal, silently weakening the
next-steps/resolution-path requirement for that kind). Reading `kind:`
already happens implicitly wherever `RECORDS_RE`/`PROPOSALS_RE` resolve
which record this write is; adding an explicit `kind:` frontmatter parse
and a `{kind: {terminal states}}` table sourced from contract §2 is a
same-shape addition, not new machinery.

**Replace the override channel with a repo-committed config file the
gate reads by path, not with a "get `hooks.json` to support an `env`
key" fix.** The survey traced all seven downstream failures to one root
structural fact: `core/hooks/hooks.json`'s schema has no `env` key at
all (only `"type": "command"`), and `SessionStart` and `PreToolUse` are
separate OS processes, so nothing assigned in one reaches the other
without going through a channel this harness actually reads. The only
channel this repo's own tests demonstrate working
(`run-role-gates-tests.sh:81-84`) is an env var exported directly into
the same process that execs the gate script — which in a real role
session means editing `hooks.json`'s `"command"` string itself to prefix
an inline `VAR=value`, per repo, by hand, with zero schema validation.
That reproduces the exact "believed configured, silently divergent"
failure mode this issue is about, just moved one layer down (a typo'd
inline assignment fails exactly as silently as an unsupported JSON key
did). A config file the gate script opens by a fixed repo-relative path
(e.g. `docs/specs/record-fields-terminal-states.json` or similar,
resolved off the same `root` the gate already computes) has no
process-boundary problem — reading a file does not depend on which
process wrote it — and turns "fail loudly" into a natural property
instead of an added feature: a present-but-unparseable file, or a file
naming a `kind` or state the gate does not recognize, is a JSON-decode or
schema-validation error the gate can `deny()` on with a specific message,
the same fail-closed pattern the gate already applies to its own internal
errors. This was weighed against keeping the env-var channel and just
documenting the inline-command-string workaround; rejected because
"correctly documented but easy to mistype with no validation" is not the
same bar as "fails loudly," and the issue's C2 was created by exactly
that gap between documented-intent and actually-enforced.

**Restructure `handbook-trigger-gate.sh`'s `OP_PATTERNS` into a
checker-legible dict rather than leaving it as a tuple list and hand-
verifying C3's directive coverage.** `OP_PATTERNS` is currently
`[(compiled_regex, "kind label"), ...]`, a shape none of #146's three
needle extractors (`has_any`, `{"key": re.compile}`, field-key regex)
recognize. Two options existed: (a) reshape it to
`{"package.json": re.compile(...), ...}` so the dict-key extractor picks
up the literal filenames/patterns as needles automatically, forever
enforced by the same checker C1 relies on; or (b) leave the shape as-is
and add a one-off synthetic test asserting C3's trigger set is named in
`directive.sh`, verified once and never re-checked automatically. (a) is
chosen: the issue explicitly asks to "Pin all three with #146's
prose↔gate check so they cannot drift back," and a hand-verified-once
fixture is exactly the kind of check that stops catching drift the
moment someone edits `OP_PATTERNS` without remembering the parallel
manual assertion — the same silent-drift shape #140 demonstrated for C2.
The dict-key reshape is mechanical (tuple list → dict with identical
regex values) and changes no runtime matching behavior.

## What will be done

- **C1** — Add a new bullet block to `core/hooks/directive.sh`'s injected
  heredoc stating: every §20 field a role record must contain, using the
  literal accepted spellings `has_any` checks for (`"what was done"`,
  `"what i did"`, `"## done"`, `"work done"`, `"summary of work"`; `"why"`,
  `"rationale"`, `"reason:"`; `"upstream"`, `"based on"`, `"basis:"`;
  `loop_state:`; `"open findings"`, `"open_findings"`, `"open finding"`),
  and the two conditional fields (`"next steps"`/`"next-steps"`/
  `"next_steps"`, `"resolution path"`/`"resolution-path"`/
  `"resolution_path"`) with the rule that triggers them (non-terminal
  `loop_state`).
- **C2** — In `record-fields-gate.sh`: parse the record's own `kind:`
  frontmatter field (new); replace the flat `RF_TERMINAL` default with a
  `{kind: {terminal states}}` table whose defaults are copied verbatim
  from contract §2 (`verify-record`→`cleared`; `qa-record`→
  `verified-fixed,not-a-defect,wont-fix`; `ops-record`→`steady`;
  `reflect-record`→`round-done`; `feasibility-record`→`verdict`;
  `review-record`→`reported`; `coding-record`/`build-proposal`→`landed`);
  fall back to a documented safe default only for an unrecognized `kind`
  (fail-closed treats it as non-terminal, same posture as today's
  code-path for missing `loop_state`). Add a config-file override channel
  read by the gate directly (fixed repo-relative path resolved off the
  same `root` computation the gate already does), validated against the
  same per-kind schema — malformed JSON, an unrecognized `kind` key, or a
  state value produces a `deny()` naming the exact problem, never a
  silent fallback to the default. Rewrite the `record-fields-gate.sh:14-40`
  comment block to describe the new per-kind default and the new override
  file, retiring the `RECORD_FIELDS_TERMINAL_STATES` env-var framing.
  Add the directive prose stating the per-kind terminal states and where
  the override file lives (also required for #146 coverage, since the
  gate's new config-path reference becomes a literal directive.sh should
  name if the checker's file-reference resolution is to pick it up — or,
  if not machine-checked, stated in prose regardless per C1's spirit).
- **C3** — Reshape `handbook-trigger-gate.sh`'s `OP_PATTERNS` from a
  tuple list into a `{"pattern-literal": re.compile(...), "kind"}`-
  compatible dict-key shape #146's extractor recognizes (exact literal
  choice — e.g. keying on the human-readable trigger token rather than
  the raw regex source — decided during implementation, not this
  document, since it is a mechanical low-risk edit with no behavior
  change to matching). Add the directive prose naming the full trigger
  file set (`package.json`, `Dockerfile`, `.env*`, `migrations/`,
  `.github/workflows/`, `(deploy|setup|run|install)*.sh`, etc.) and the
  `docs/handbooks/` requirement as a commit-blocking obligation, not
  merely a bucket name.
- Run `python3 core/hooks/tests/gate-prose-coverage-check.py .` against
  this repo after the `directive.sh`/gate edits and treat a clean (exit 0)
  run as the authoritative pass signal for C1/C3 — not a manual
  literal-by-literal comparison.
- Extend `core/hooks/tests/run-role-gates-tests.sh` with, per the issue's
  acceptance text, one allow-fixture and one deny-fixture **per record
  kind** in contract §2 (pin every kind, not a sample): each kind's
  contract-defined terminal state written with all other §20 fields
  present is ALLOWED with no next-steps/resolution-path required; the
  same kind at a non-terminal state with next-steps/resolution-path
  omitted is DENIED. Add fixtures for the new override file: a
  well-formed override takes effect (a state it declares terminal is
  allowed), and each distinct misconfiguration shape (malformed JSON,
  unrecognized `kind`, unrecognized state spelling) produces a distinct
  loud deny, not a silent pass-through to defaults.
- Add a case to `core/hooks/tests/run-gate-prose-coverage-tests.sh`
  covering the reshaped `OP_PATTERNS` dict-key extraction, if the C3
  reshape changes what the generic checker's own existing fixtures
  exercise (most likely not required since the generic checker fixtures
  are shape-based, not gate-specific; confirmed/adjusted during
  implementation).
- If the override-file mechanism counts as a new "run/setup step" under
  contract §21 (a maintainer creating/editing this file to change gate
  behavior), create or update `docs/handbooks/core.md` documenting: what
  the file is, its schema, what it defaults to when absent, what breaks
  (loudly) on malformed content, and the concrete steps to add or change
  a kind's terminal-state override.

## Out of scope

- Any change to the `sha:` placeholder-validation logic (issue-128/133/
  153) or the `code_under_review` bare-sha check (issue-100) inside
  `record-fields-gate.sh` — untouched, unrelated to C1/C2/C3.
- Migrating the seven downstream repos that attempted a broken
  `RECORD_FIELDS_TERMINAL_STATES` override to the new mechanism — that is
  per-repo follow-up work in each of those repos, not core's own
  phase-2 write set; core's obligation here is to make the mechanism
  work and fail loudly, not to touch other repos.
- Adding a routing table, watcher, or any automation for "who acts next"
  — contract §3 explicitly keeps that a human/orchestrator judgment; this
  issue is about literal-visibility and terminal-state correctness only.
- Restructuring `board-gate.sh`, `approval-gate.sh`, `trailer-gate.sh`, or
  `gh-guard.sh`, or their directive coverage — not named by this issue's
  C1/C2/C3, and the survey found no drift evidence for them here.
- Building a general-purpose contract-distribution mechanism for the 43
  rulebook repos to carry `role-handoff-contract.md` itself — rejected in
  Rationale above; out of scope for this issue specifically.
- External product scouting — this is an internal infra bugfix with no
  product-shaped decision to benchmark against other tools; scout's
  product-scouting stage does not apply.

## How you'll know it worked

- `python3 core/hooks/tests/gate-prose-coverage-check.py .` exits 0 for
  this repo (`core`'s unit), with zero `VIOLATION` lines attributed to
  `record-fields-gate.sh` or `handbook-trigger-gate.sh`.
- `core/hooks/tests/run-role-gates-tests.sh` passes, including new
  fixtures asserting: for every `kind` in contract §2, a record at that
  kind's contract-defined terminal state is ALLOWED with no next-steps/
  resolution-path present, and the same kind at a non-terminal state
  without next-steps/resolution-path is DENIED.
- A fixture proves the override file, when well-formed, changes gate
  behavior (a state it names terminal is allowed that the per-kind
  default would have denied) — the override channel demonstrably works,
  not merely "is documented."
- A fixture per misconfiguration shape (malformed JSON, unrecognized
  `kind`, unrecognized state) proves the gate denies loudly with a
  message naming the specific problem, and does not silently fall back
  to defaults.
- `core/hooks/directive.sh`'s injected text, read cold with no other file
  open, states: every §20 field and its accepted spellings including
  `loop_state:` and the two conditional fields; the per-kind terminal
  state table (or a pointer to where it lives) sourced from contract §2;
  and `handbook-trigger-gate.sh`'s full trigger-file set plus the
  `docs/handbooks/` requirement stated as a commit-blocking rule, not a
  bucket name.
- `core/hooks/tests/run-gate-prose-coverage-tests.sh` continues to pass
  unmodified (or with an added case, if the `OP_PATTERNS` reshape
  warrants one) after the C3 edit.
