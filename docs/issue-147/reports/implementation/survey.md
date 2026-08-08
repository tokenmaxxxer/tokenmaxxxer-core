kind: implementation-record
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
  - path: core/hooks/tests/gate-prose-coverage-check.py
    sha: same-commit
  - path: docs/issue-146/proposals/2026-08-07-gate-prose-coverage-check.md
    sha: same-commit
  - path: docs/issue-140/reports/implementation.md
    sha: same-commit
loop_state: idle

# Phase-1 survey: issue-147 — core's own gates deny sessions on rules no session can read

## Issue summary (gh issue view 147)

Three bugs, all inside `core/hooks/`, all with plugin-wide blast radius
(core runs in every role session in every repo):

- **C1**: `record-fields-gate.sh:202-222,256-267` requires the §20 fields
  (what-was-done / why / upstream / `loop_state:` / open findings, plus
  next-steps + resolution-path when non-terminal) using specific accepted
  literal spellings, but `directive.sh:63-130`'s injected prose names none
  of them, and 0/43 rulebook repos carry the contract file, so a role has
  no way to learn the required spellings before its first denial.
- **C2**: `record-fields-gate.sh:95` defaults `RF_TERMINAL` (env var
  `RECORD_FIELDS_TERMINAL_STATES`) to a flat, hand-collected list
  (`landed complete closed done delivered phase-2-complete`) that has
  **empty intersection** with contract §2's actual per-kind terminal
  vocabulary (`cleared` for verify, `verified-fixed`/`not-a-defect`/
  `wont-fix` for qa, `steady` for ops, `round-done` for reflect, `verdict`
  for feasibility, `reported` for review). #140 (merged, referenced by
  this issue) widened the flat list from observed *implementation*-role
  guesses, not from the contract, and made the drift worse while looking
  fixed. Seven downstream repos tried to override the default and all
  seven failed silently, in five spellings: unsupported `env` keys inside
  a repo's `hooks/hooks.json`, a dead standalone JSON file
  (`record-fields.json`) nothing loads, and non-exported bash variable
  assignments inside a `SessionStart` subprocess that is a different OS
  process from the `PreToolUse` process the gate actually runs in.
- **C3**: `handbook-trigger-gate.sh:90-125` blocks a `git commit` that
  stages an operational-surface file (`package.json`, `pyproject.toml`,
  `Dockerfile`, `.env*`, `migrations/`, `.github/workflows/`,
  `(deploy|setup|run|install)*.sh`, etc.) without also staging a
  `docs/handbooks/*.md` file, but `directive.sh:111` mentions `handbooks`
  only as one of the six standing doc buckets — never as a commit-blocking
  obligation with a trigger set.

Acceptance the issue states: a fresh role session's injected prose
contains every literal `record-fields-gate.sh` and `handbook-trigger-gate.sh`
can deny on; a terminal-state override either takes effect or errors loudly;
#146's coverage check passes for core with no exceptions.

## C1 — how record-fields-gate.sh currently determines required fields

Read in full (`core/hooks/record-fields-gate.sh`). The gate is a
`PreToolUse` hook matching `Write|Edit|MultiEdit|NotebookEdit`. On a write
whose resolved target is `docs/issue-<n>/reports/<CLAUDE_ROLE>.md` (its own
record) or `docs/issue-<n>/proposals/*.md` (a lighter, separately-scoped
`sha:` placeholder check only), it reconstructs the post-write text via
`gate-lib.py`'s `gate_reconstruct_write` and runs a Python heredoc that
checks, via a local `has_any(*needles)` closure over a lowercased copy of
the text:

- what-was-done: `"what was done"`, `"what i did"`, `"## done"`,
  `"work done"`, `"summary of work"` (record-fields-gate.sh:242)
- why: `"why"`, `"rationale"`, `"reason:"` (:247)
- upstream-basis: `"upstream"`, `"based on"`, `"basis:"`, OR a bare
  7-40 char hex token, OR a `docs/issue-` path (:249-253)
- `loop_state`: a regex `^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$` (:255) —
  not a `has_any` literal, so #146's checker (below) does not currently
  extract a needle for it at all
- open-findings: `"open findings"`, `"open_findings"`, `"open finding"`
  (:259)
- conditionally, only when `loop_state`'s value does not normalize into
  the terminal set: next-steps (`"next steps"`, `"next-steps"`,
  `"next_steps"`, :296) and resolution-path (`"resolution path"`,
  `"resolution-path"`, `"resolution_path"`, :302)

Also present but out of this issue's three bugs (left alone): the
`sha:`-placeholder check (issue-128/133/153) and the
`code_under_review` bare-sha check for `coding`/`implementation` roles
(issue-100). Neither is named by C1/C2/C3 and neither is proposed for
change here.

## C2 — how the terminal-state set is currently derived, and why the override is dead

`RF_TERMINAL` is populated once, at shell level, before the Python
heredoc runs:

```
RF_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed complete closed done delivered phase-2-complete}"
```

It is a **flat, role/kind-agnostic space-separated set**. Inside the
heredoc, `norm_state()` normalizes both the record's own `loop_state`
value and every member of `TERMINAL` (hyphen/underscore folding, digit
boundary insertion) before membership-testing. There is no per-`kind`
dimension anywhere in this gate: it never reads the record's `kind:`
frontmatter field, so it cannot distinguish a `verify-record` from a
`qa-record` when deciding "is this loop_state terminal."

Contract §2 (`core/contract/role-handoff-contract.md:57-87`) is the
single source of truth for terminal states, and it is **per-kind**:
`verify-record` → `cleared`; `qa-record` → `verified-fixed` (plus
`not-a-defect`, `wont-fix` per the row's full vocabulary, though the issue
calls out `verified-fixed` as the terminal member); `ops-record` →
`steady`; `reflect-record` → `round-done`; `feasibility-record` →
`verdict`; `review-record` → `reported`; `coding-record`/
`build-proposal` → `landed`. None of `cleared`/`verified-fixed`/`steady`/
`round-done`/`verdict`/`reported` appear in the current flat default —
confirmed by grep against the default string. A verify role writing the
contract-correct `loop_state: cleared` is denied for missing next-steps +
resolution-path exactly as if it had written a non-terminal state.

**The override channel: why it is inert.** The comment block at
record-fields-gate.sh:14-40 documents `RECORD_FIELDS_TERMINAL_STATES` as
"configuration injected via [env var]... a rulebook whose terminal states
differ from the default sets that env var in its own hooks.json." This
repo's own test harness (`core/hooks/tests/run-role-gates-tests.sh:81-84`)
confirms the mechanism works **when the variable is genuinely exported
into the same process that execs `record-fields-gate.sh`** — the test
literally does `env CLAUDE_ROLE=... RECORD_FIELDS_TERMINAL_STATES=... bash
record-fields-gate.sh`. The bug is not in the gate's own env read; it is
that no supported channel gets the variable into that process in a real
role session:

- `core/hooks/hooks.json` (read in full) only supports a `"command"`
  string per hook entry — there is no `"env"` key anywhere in the schema
  this harness reads. Issue #147 names four repos that tried an `env` key
  in their own `hooks/hooks.json` (technical-feasibility, devrel x2,
  defect-verification): the harness silently ignores an unrecognized key,
  so nothing is ever exported.
- One repo (`risk-management`) wrote `[]` into a standalone
  `hooks/record-fields.json` — nothing in this codebase's gate scripts
  (`gate-lib.sh`, `gate-lib.py`, `record-fields-gate.sh` itself) reads a
  file by that name; it is dead configuration.
- Two repos (`release-engineering`, `issue-retrospective`) assigned the
  variable, non-exported, inside their own `hooks/directive.sh`
  (`SessionStart`). `SessionStart` and `PreToolUse` are each invoked as
  their own fresh subprocess by the harness (confirmed by `hooks.json`'s
  structure: separate top-level `SessionStart`/`PreToolUse` hook arrays,
  each `"type": "command"`, i.e. each a distinct process exec) — a bash
  variable assigned in one process, exported or not, cannot reach a
  sibling process's environment. `issue-retrospective`'s own directive.sh
  comment already flagged this as unconfirmed; it does not work.

So of the two structurally-possible channels (env var actually exported
into the gate's process, or a file the gate script reads by path), only
the first has ever been demonstrated to work, and nothing in the current
plugin surface (`hooks.json`'s schema, or a same-process route) gets an
env var from repo-level configuration into a `PreToolUse` gate's process
without editing the `hooks.json` `"command"` string itself (which *is*
shell-executed and could carry an inline `VAR=value` prefix, but that is
per-repo, per-line hand edits with no schema validation — exactly the
"believed configured, silently no-op" shape the issue is about, just
moved to `hooks.json` instead of a JSON `env` key).

## C3 — how handbook-trigger-gate.sh's trigger set is defined

`core/hooks/handbook-trigger-gate.sh` is a `PreToolUse` hook matching
`Bash` calls containing `git ... commit`. It reads `git diff --cached
--name-only` (plus a static projection of any preceding `git add` segment
in the same command string) to get the staged set, then tests each staged
path against a hardcoded list `OP_PATTERNS` (record-fields-gate.sh has no
equivalent; this is local to handbook-trigger-gate.sh) — a Python list of
`(compiled-regex, "kind label")` tuples, **not** a `has_any(...)` call, a
`{"key": re.compile(...)}` dict, or a `re.search(r'^\s*(name):' ...)`
field-key pattern:

```
package.json / package-lock.json / pyproject.toml / requirements*.txt /
go.mod / Cargo.toml / Gemfile / Dockerfile / docker-compose.y*ml /
.env* / migrations?/ / .github/workflows/ / (deploy|setup|run|install)*.sh
```

If any staged path matches and no staged path matches
`^docs/handbooks/.+`, the commit is denied. `directive.sh:111` currently
says only `"...six standing buckets (_assets, decisions, handbooks,
proposals, reports, specs)..."` — `handbooks` appears as a bucket name,
never as a trigger-file list or a commit-blocking rule.

**Coverage-check implication (see next section): this trigger set is
invisible to #146's automated checker as currently written**, because
`OP_PATTERNS` is a list-of-tuples, not one of the three needle shapes the
checker's regexes recognize (`has_any(...)`, `{"str": re.compile(...)}`,
or `re.search(r'^\s*(name):' ...)`). Phase 2 must either (a) reshape
`OP_PATTERNS` into a `has_any`- or dict-key-compatible literal form the
checker can extract from, or (b) accept that C3's directive coverage is
verified by a new synthetic fixture/manual assertion rather than by the
existing generic extractor picking it up automatically. This is a design
decision the proposal below makes explicit rather than assuming (a) for
free.

## The #146 gate-prose-coverage check — what it scans and what it requires

Landed in `core/hooks/tests/gate-prose-coverage-check.py`
(commit `5735daf`, PR #148/#146; proposal at
`docs/issue-146/proposals/2026-08-07-gate-prose-coverage-check.md`).
Static, read-only, regex-based; no gate execution.

1. **Units**: every directory whose `hooks/` subdir contains
   `directive.sh` (`find_units`). For this repo, `core` itself is a unit:
   `core/hooks/directive.sh`.
2. **Gates**: every `hooks/*gate*.sh` file other than `directive.sh`
   (`find_gate_files`) — for `core`, this includes
   `record-fields-gate.sh` and `handbook-trigger-gate.sh` among others
   (`board-gate.sh`, `approval-gate.sh`, `trailer-gate.sh`, `gh-guard.sh`).
3. **Attribution**: each gate is attributed to its nearest ancestor unit
   (`nearest_unit`); a gate with no ancestor unit falls back to the repo
   root.
4. **Needle extraction** (`extract_needles`), three shapes only:
   - `has_any("a", "b", ...)` → each string literal is a needle
   - `{"key": re.compile(...), ...}` → each dict string key is a needle
   - `re.search(r'^\s*(name):' ...)` → the captured field-key name is a
     needle
5. **Corpus** (`build_corpus`) per unit: the unit's own `directive.sh`
   text, plus any `SKILL.md` anywhere under the unit subtree, plus any
   file `directive.sh` names by relative path in its own text (matched via
   a generic `\.(?:md|sh|py)` filename regex, resolved against both the
   unit dir and the directive's own dir) — this is the "injected"
   boundary: a handbook or doc the directive never names does not count
   (case3 fixture in `run-gate-prose-coverage-tests.sh` pins this).
6. **Coverage test** (`needle_covered`): a needle passes if it appears as
   a case-insensitive **whole-word** substring (non-word-char boundaries)
   anywhere in the corpus. Not covered → one `VIOLATION` line; exit 1 if
   any violations, 0 if none, 2 on usage/IO error.

For `record-fields-gate.sh`, the needles the checker currently extracts
are exactly the `has_any(...)` literals enumerated in the C1 section
above (what-was-done/why/upstream/open-findings/next-steps/
resolution-path spellings) — 14 literals total across the six `has_any`
call sites. It does **not** currently extract a needle for `loop_state`
itself (regex-matched, not `has_any`), nor for any terminal-state value
(those live in a shell-level default string, not a Python literal the
checker's regexes reach), nor for anything in
`handbook-trigger-gate.sh`'s `OP_PATTERNS` (wrong shape, per C3 above).
So passing #146's check today for `record-fields-gate.sh`'s 14 `has_any`
needles is close to (2 already partially covered by adjacent prose
mentioning "record" and "why" in `directive.sh`'s bullet list, but not as
whole-word matches of the exact needles) — not yet run in this survey;
phase 2 must run `gate-prose-coverage-check.py .` against this repo and
treat its output as the authoritative pass/fail signal for C1/C3, not a
manual literal-by-literal check.

## What will change (honest write-set projection)

- **`core/hooks/directive.sh`** — new prose block(s) naming: (C1) the
  §20 required-field labels and every accepted spelling `has_any` checks
  for, including `loop_state:` itself and the two conditional next-steps/
  resolution-path fields; (C3) the handbook-trigger-gate's file-pattern
  trigger set and the `docs/handbooks/` requirement. This is the file
  #146's checker actually scans, so its wording must literally contain
  each needle as a whole-word match — not a paraphrase.
- **`core/hooks/record-fields-gate.sh`** — replace the flat
  `RF_TERMINAL` default with a per-kind terminal-state mapping keyed by
  the record's own `kind:` frontmatter field (which the gate does not
  currently read at all — new parsing needed), sourced from contract §2;
  plus a redesigned override channel that fails loudly on
  misconfiguration instead of silently no-op'ing. Comment block
  (:14-40) needs rewriting to match the new mechanism; the existing
  role-identity-via-config framing (`RECORD_FIELDS_TERMINAL_STATES` as
  free-form per-role override) is superseded.
- **`core/hooks/handbook-trigger-gate.sh`** — possibly restructure
  `OP_PATTERNS` into a checker-legible shape (open design question flagged
  above), or leave as-is if phase 2 elects a non-checker verification
  path for C3 and documents why.
- **`core/contract/role-handoff-contract.md`** — possibly touched only if
  phase 2 needs a single canonical per-kind terminal-state table distinct
  from (or clarifying) §2's existing `loop_state` vocabulary column; §2
  already states the vocabulary, so this may turn out to be a read-only
  reference, not a write, in phase 2 — flagged as possible, not certain.
- **`core/hooks/tests/run-role-gates-tests.sh`** — new fixtures per the
  issue's acceptance criterion ("for each record kind in §2, a record
  written at that kind's contract-defined terminal state is ALLOWED, and
  one written at a non-terminal state of that kind still requires
  next-steps" — pin every kind, not a sample) plus fixtures for the new
  override channel's fail-loud behavior.
- **`core/hooks/tests/run-gate-prose-coverage-tests.sh`** — possibly a
  new fixture case if `OP_PATTERNS` is reshaped for checker legibility.
- **`docs/handbooks/`** — only if the redesigned override mechanism
  introduces a new setup step (e.g. a config file role maintainers must
  create) that itself counts as an operational-surface change under
  contract §21 (a "run/setup step" a maintainer must follow); this would
  need its own `docs/handbooks/<component>.md` entry, most likely
  `docs/handbooks/core.md` if it exists, or a newly-derived slug — not
  determined yet, flagged as conditional.

## Prior related decisions

- `docs/issue-140/reports/implementation.md` — widened
  `RECORD_FIELDS_TERMINAL_STATES`'s default from `landed` to `landed
  complete closed done delivered phase-2-complete`, from observed
  `implementation`-role denial spellings, not from the contract. This
  issue (#147, C2) documents that #140's fix does not intersect any
  contract-defined terminal state and must be superseded, not built on.
- `docs/issue-146/proposals/2026-08-07-gate-prose-coverage-check.md` —
  the proposal that introduced the coverage checker this issue's C1/C3
  fix must satisfy. Its own text (line 50) already names
  `RECORD_FIELDS_TERMINAL_STATES` as "an inert, hand-maintained config
  channel" and (line 99) explicitly scoped "making
  `RECORD_FIELDS_TERMINAL_STATES` actually work or deleting it" as **out
  of #146's own scope** — i.e. #146 knowingly deferred C2 to a future
  issue, which is this one.
- `docs/issue-66/reports/implementation.md` — the record-fields-gate.sh
  promotion-to-canon record; documents the original rationale for making
  terminal states configurable per-role rather than hardcoded (predates
  the per-kind vs per-role distinction this issue draws).
- `docs/issue-153/proposals/2026-08-08-narrow-sha-scan-scope-and-empty-value-carveout.md`
  — unrelated `sha:` scan-scope fix, touches the same file
  (`record-fields-gate.sh`) but a different check (placeholder-sha
  validation, not terminal states or required fields); listed here only
  because phase 2's diff will sit next to it in the same file.
- No `docs/decisions/` entry addresses terminal-state derivation or the
  override channel; `docs/decisions/` currently holds exactly one file
  (`2026-08-01-s19-no-pr-refusal-retired.md`), unrelated to this issue.
