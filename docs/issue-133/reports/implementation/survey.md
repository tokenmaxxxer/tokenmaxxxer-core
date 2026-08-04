---
kind: current-state-survey
subject: issue-133
produced_by: implementation
---

# Current-state survey — issue-133

## Scout skip record

Scouting was skipped. Skip condition: the spec leaves no design decision
open. Issue #133's requirement 1 names the exact whitelist shape verbatim
— `same-commit` literal or 40-character hex — and this survey's own
first-hand check (below) confirms 40 hex is not an arbitrary choice but
the actual length of a git commit SHA-1 in this repository, so there is no
external "what should the value shape be" question left to research. The
remaining work is a same-file regex fix plus tests, closer to a bugfix
against a named defect (Finding 1 of
`docs/issue-128/reports/execution-observation.md`) than a design
decision.

## The defect, exactly

`core/hooks/record-fields-gate.sh:171-172`:

```python
def placeholder_shas(text):
    return [m.group(1).strip() for m in re.finditer(r'^\s*sha:\s*(<[^\n]*>)\s*$', text, re.M)]
```

This is a **blacklist**: it only flags a value shaped like `<...>` with
nothing but whitespace after the closing `>`. Two call sites consume it —
the proposal path's early exit (`:181-185`) and the record path's check
after the five §20 field checks (`:214-216`) — both via the same
`deny_placeholder()` message (`:174-179`), which is itself worded around
"bracket placeholder."

`docs/issue-128/reports/execution-observation.md` (Finding 1, "Probe A")
already traced three inputs that this regex admits despite being
unresolved: `sha: HEAD`, `sha: TBD` (no leading `<`, never reaches the
capture group), and `sha: <set at commit> — fix later` (bracket present,
but trailing prose after `>` fails the `\s*$` anchor, so the whole line
fails to match and passes through unflagged). Its stated action item is
exactly issue #133's requirement 1: "invert the check from deny-list to
allow-list — deny any `sha:` value that is neither 7-40 hex nor the
literal `same-commit`." Issue #133 pins the hex length itself to exactly
40, narrower than the observation's own suggested range — see "Existing
non-40-hex values" below for why this narrower choice is the one to keep.

## Real-world instance confirmed still present

`docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md:4-7`:

```yaml
upstream:
  - path: docs/issue-20/reports/implementation/survey.md
    sha: HEAD
```

Confirmed at this session's read, unchanged since Finding 1 was written.
Issue #133 requirement 3 says not to retroactively fix it (citing #100's
no-retroactive-fix precedent) and to confirm the gate's existing
new-commits-only property holds. That property is structural, not
something this change touches: `record-fields-gate.sh` only evaluates the
content of an actual `Write`/`Edit`/`MultiEdit` tool call
(`gate_reconstruct_write`, `:162`); a file nobody writes to never reaches
the check. `docs/issue-20/proposals/…` was last touched in its own
landing commit and nothing in this issue's write set (below) touches
`docs/issue-20/**`, so the property holds by construction, not by a new
guard.

## Repo-wide `sha:` value-shape tally (this session, read-only)

`grep -rhn "^\s*sha:\s*" --include="*.md" docs/` then grouped by value
shape:

| Shape | Count | Verdict under a `same-commit`-or-40-hex whitelist |
| --- | --- | --- |
| 40 lowercase hex | 51 | allow (unchanged) |
| `<set at commit>` | 23 | deny (unchanged — already denied today) |
| `same-commit` | 4 | allow (unchanged) |
| `HEAD` | 1 | **now denied (was admitted — the fix)** |
| `<commit SHA the artifact was read at>` | 1 | deny — this is the literal contract-template placeholder text embedded in `core/contract/role-handoff-contract.md:28` itself (inside a fenced example block, not a live frontmatter field of any record); already out of any gate's reach since the gate only scans `docs/issue-<n>/{reports,proposals}` paths, not `core/contract/` |
| 7-hex abbreviated (`ff9ad98`, `757eb07`, `6842c5f`, `2b769e6`, `b1ff18b`) | 5, across `docs/issue-{90,107,116,122,124}/reports/execution-observation.md` | **now denied if that exact file is ever rewritten** — see next section |

## Existing non-40-hex values: abbreviated shas in `execution-observation` records

`grep -rEn "^\s*sha:\s*[0-9a-f]{6,39}\s*$" --include="*.md" docs/` finds
five live `upstream[].sha` entries using a 7-character abbreviated commit
sha, all in `docs/issue-<n>/reports/execution-observation.md` files (issue
90, 107, 116, 122, 124) — a different role's own record, not this role's
(`implementation`'s record path is `reports/implementation.md`, matched
only when `CLAUDE_ROLE=implementation` writes to its own file). This is a
genuine, live divergence from issue #133's literal "40-character hex
only" spec, and worth naming explicitly rather than silently overriding:

- The issue's own text says 40 hex, not "7-40". `git rev-parse
  --show-object-format` in this repository returns `sha1` (confirmed this
  session), so every commit sha in this repo's history is exactly 40 hex
  characters; 40 is not an arbitrary pick, it is this repo's actual full
  sha length.
- The gate is content-based, not file-based: it only re-evaluates a
  record the moment a `Write`/`Edit`/`MultiEdit` targets that exact path.
  None of the five files above are in this issue's write set, so a
  40-hex-only whitelist does not retroactively break them — it only
  applies the next time (if ever) `execution-observation` rewrites one of
  its own already-landed records, which contract §11 forbids for a
  *merged* record in any case.
- Keeping the whitelist at exactly 40 hex (not 7-40) is therefore the
  narrower, spec-literal, and repo-consistent choice: it matches what the
  issue asked for, matches this repo's one git object format, and
  tightens rather than loosens the abbreviated-sha convention visible
  elsewhere — a session that later needs to cite a sha in a role's own
  record already has the full 40-hex value on hand (`git log -1
  --format=%H`), so nothing is lost by requiring it.

## Call sites and path scope — unchanged by this issue

`PROPOSALS_RE` (`^docs/issue-[0-9]+/proposals/.*\.md$`) and `RECORDS_RE`
(`^docs/issue-[0-9]+/reports/<role>\.md$`, `:117-118`) are not touched by
issue #133 — requirement 1 only asks to change what counts as an allowed
`sha:` *value*, not which paths or which of the five §20 field checks run.
Both existing call sites (`:181-185` proposal early-exit, `:214-216`
record path) call the same helper today and should keep doing so; the fix
is localized to the helper's regex and to `deny_placeholder()`'s message
text (currently worded "is a bracket placeholder, not a resolvable
value" — no longer accurate once non-bracket values like `HEAD` are also
denied).

## Test harness

`core/hooks/tests/run-role-gates-tests.sh:49-59` defines `run_rf()`, a
helper that drives `record-fields-gate.sh` as a real subprocess against a
synthetic `Write` payload. Five existing cases already exercise the
issue-128 check (`:84-98`): bracket-placeholder-deny (proposal and
record), `same-commit`-allow (proposal and record), and one real-hex-allow
(proposal only). None of the three red spellings issue #133 names (`HEAD`,
`TBD`, bracket+trailing-prose) has a case today — confirmed by grepping
the test file for those three literals, no hits. Issue #133 requirement 2
asks for a red→green demonstration of exactly these three, plus
confirmation the two valid forms keep passing.

## Handbook

`docs/handbooks/role-gates-tests.md:27-35` documents the current
bracket-only check in prose ("any `sha:` line whose value is a bracket
placeholder (`^<.*>$`, e.g. `sha: <set at commit>`) is denied"). This
sentence becomes inaccurate once the check is a whitelist and needs the
same-turn update the doctrine ladder requires for a changed check's
description.

## Constraint check against issue #128's landed convention

Issue #133's own constraint says "#128 랜딩 규약(same-commit 정본)과 §20
기존 검사 무변경" (the #128-landed same-commit convention and §20's
existing checks stay unchanged). Confirmed both hold under the planned
fix: `same-commit` remains one of exactly two allowed values (unchanged
convention), and none of the five §20 field checks
(`:192-206`, what-was-done/why/upstream-basis/loop_state/open-findings)
or the `code_under_review` bare-sha check (`:218-226`, its own separate
`[0-9a-f]{7,40}` pattern on a different field) are touched — only
`placeholder_shas()` and its two call sites' message text change.

## Unknowns

- Whether any role other than `execution-observation` has a live
  abbreviated-sha `upstream[].sha` entry in its own record was checked
  repo-wide (the tally above is repo-wide, not scoped to one role) — none
  found outside `execution-observation`.
- Whether `RECORD_FIELDS_TERMINAL_STATES` or any other env-var-driven
  gate behavior interacts with this check: no — that variable only feeds
  the unrelated `loop_state` terminal-set check (`:119`, `:228-229`),
  confirmed by reading its one use site.

## Write set this survey projects

- `core/hooks/record-fields-gate.sh` — replace `placeholder_shas()`'s
  deny-list regex with an allow-list check (`same-commit` or exactly
  40 lowercase hex); update `deny_placeholder()`'s message text to match.
- `core/hooks/tests/run-role-gates-tests.sh` — add red→green cases for
  `HEAD`, `TBD`, and bracket+trailing-prose (each currently `allow`,
  becoming `deny`); confirm the two valid-form cases stay `allow`.
- `docs/handbooks/role-gates-tests.md` — update the one paragraph
  describing the check's shape from deny-list to allow-list wording.
- No existing `docs/issue-<n>/proposals/*.md` or `reports/*.md` file is
  edited — issue #133's own constraint (requirement 3) forbids retroactive
  fixes, consistent with the #100 precedent this repo already follows.
