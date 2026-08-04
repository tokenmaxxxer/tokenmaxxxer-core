---
kind: build-proposal
subject: issue-133
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-133/reports/implementation/survey.md
    sha: same-commit
---

files: `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`

## Request

Issue #133: `record-fields-gate.sh`'s `sha:` value check (added under
issue-128, `docs/issue-128/reports/execution-observation.md` Finding 1) is
a blacklist — it only denies a bracket-shaped placeholder
(`^<.*>$`) — so it misses any other unresolved spelling. Finding 1 traced
three admitted-but-unresolved inputs (`sha: HEAD`, `sha: TBD`,
`sha: <set at commit> — fix later`), and one of them is not hypothetical:
`docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md:7`
carries a live `sha: HEAD`. Three things are asked:

1. Convert the check to a whitelist: allow only the literal `same-commit`
   or a 40-character hex commit sha (empty `upstream` stays under the
   existing convention, untouched).
2. Demonstrate red→green: the three unresolved spellings above pass today
   (red) and must be denied after the fix (green); the two valid forms
   keep passing.
3. Confirm — without retroactively editing it — that the live
   `docs/issue-20/…` instance is left alone, and that the gate's
   new-commits-only property still holds.

Scouting was skipped for this proposal (spec leaves no design decision
open — see the survey's "Scout skip record").

## Constraints

- Issue #128's landed convention (`same-commit` as canon for a
  same-commit upstream citation) is unchanged.
- `record-fields-gate.sh`'s five existing §20 field checks
  (what-was-done/why/upstream-basis/loop_state/open-findings,
  `:192-206`) and the separate `code_under_review` bare-sha check
  (`:218-226`, issue #100) are unchanged — only the `sha:` value check
  changes.
- No retroactive fix to `docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md`
  or any other already-landed document (issue's own requirement 3, citing
  the #100 no-retroactive-fix precedent).

## Rationale

**Chosen: rewrite `placeholder_shas()` in place as a value allow-list,
keeping the existing two call sites and line-regex style.** The function
already runs once per write, matching `^\s*sha:\s*...` lines against the
full reconstructed text (`gate_reconstruct_write`); inverting its logic —
capture the full value after `sha:`, deny anything that is not exactly
`same-commit` or exactly 40 lowercase hex characters — is a same-shape,
same-file, same-style change consistent with every other check in this
gate (the five §20 checks are also line/substring regex over raw text, not
a structured parser).

**Rejected alternative: parse the frontmatter as YAML instead of
line-matching.** A `yaml.safe_load()` pass over the frontmatter block
would be more robust to multi-line or oddly-indented `upstream` lists, but
it adds a stdlib-external dependency this gate does not currently have
(Python's standard library ships no YAML parser; `gate-lib.sh`'s existing
checks and `record-fields-gate.sh` itself use only `json`, `re`, `os`,
`posixpath`) and changes the gate's fail-closed error surface — a subtly
malformed YAML block would need its own new failure path, where today a
line that merely fails the regex is simply not flagged (fails open on
shape, not closed). The line-regex approach's blind spots (documents
outside `docs/issue-<n>/{reports,proposals}` scope) are unchanged by
either approach, since neither touches `PROPOSALS_RE`/`RECORDS_RE`. Given
the fix only needs to widen a value check, not restructure how the file is
read, the smaller, same-style change is preferred.

**Rejected value range: 7-40 hex (matching the execution-observation
Finding 1 action item's own suggested range) instead of exactly 40.**
Issue #133's own requirement 1 text pins the value to "40자 16진 해시"
(40-character hex), not a range, and this survey's first-hand check
(`git rev-parse --show-object-format` → `sha1`) confirms every commit sha
in this repository's actual history is exactly 40 hex characters — 40 is
this repo's real full-sha length, not an arbitrary pick. The survey also
found five live 7-character abbreviated shas in `execution-observation`
role records (issue 90, 107, 116, 122, 124), which a 7-40 range would keep
legal but an exactly-40 whitelist newly excludes going forward. Exactly-40
is still chosen because: (a) it is what the issue literally asks for; (b)
the gate is content-based and only re-evaluates a path when it is actually
written, so none of those five already-landed files are broken by this
change unless rewritten, and contract §11 already forbids rewriting a
merged record; (c) the abbreviated-sha convention itself was never a
deliberate decision recorded anywhere this survey found — allow-listing it
here would quietly ratify an unreviewed pattern instead of asking the
human to make that call.

**Failure signal.** If exactly-40-hex turns out too strict, the signal is
a future `execution-observation` (or any role) session having its own
record write denied because it cited a real, correct, but abbreviated
sha — a false-positive deny distinguishable from a true unresolved
placeholder by inspecting the denied value: a valid short hex string
resolves via `git log -1 --format=%H` to a real commit, `HEAD`/`TBD`/a
bracket do not.

## What will be done

1. `core/hooks/record-fields-gate.sh`: replace `placeholder_shas()`'s
   bracket-only regex with an allow-list — match the full value of every
   `^\s*sha:\s*...` line, and collect any value that is not exactly the
   literal `same-commit` or exactly 40 lowercase hex characters (`^(a-f0-9`
   `){40}$`). Both existing call sites (`:181-185` proposal early-exit,
   `:214-216` record path) keep calling the same function unchanged.
2. `core/hooks/record-fields-gate.sh`: reword `deny_placeholder()`'s
   message (currently "is a bracket placeholder, not a resolvable value")
   to describe the allow-list ("is not `same-commit` or a 40-character hex
   commit sha") so a denied session sees an accurate reason.
3. `core/hooks/tests/run-role-gates-tests.sh`: add `run_rf` cases —
   `sha: HEAD` denied, `sha: TBD` denied, `sha: <set at commit> — fix
   later` (bracket + trailing prose) denied — each currently `allow`,
   asserted `deny` after the fix; re-confirm the existing `same-commit`-
   and real-40-hex-allow cases (proposal and record paths) still pass
   unchanged.
4. `docs/handbooks/role-gates-tests.md:27-35`: update the one paragraph
   describing the check from "denies a bracket placeholder" to "allows
   only `same-commit` or a 40-character hex value, denies everything
   else," same turn as the gate change.

## Out of scope

- Retroactively editing `docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md`
  or any other already-landed document carrying an unresolved `sha:`
  value — explicit issue constraint (requirement 3), consistent with the
  #100 no-retroactive-fix precedent.
- Widening the check's path scope (`PROPOSALS_RE`/`RECORDS_RE`) — issue
  #133 only asks to change what counts as a valid *value*, not which
  paths or which of the five §20 field checks run.
- Allow-listing abbreviated (7-39 char) hex shas — considered and
  rejected above; the five existing `execution-observation` instances are
  left as-is (gate is content-based, not retroactive) but not carried
  forward as a sanctioned form.
- SHA-256 object-format support (64-hex) — this repository's git object
  format is `sha1` (confirmed this session); no 64-hex value exists
  anywhere in the current `docs/` tree.

## How you'll know it worked

- `bash core/hooks/tests/run-role-gates-tests.sh` passes in full,
  including the new red→green cases, with all pre-existing cases (§20
  fields, `code_under_review`, trailer-gate, handbook-trigger-gate,
  stub-check) unaffected.
- A synthetic write with `sha: HEAD`, `sha: TBD`, or
  `sha: <set at commit> — fix later` is denied by `record-fields-gate.sh`;
  the same write with `sha: same-commit` or a real 40-hex sha is not —
  each demonstrable directly against the script as a subprocess, the same
  way the existing `run_rf` cases already do.
- `docs/issue-20/proposals/2026-07-31-build-gh-guard-endpoint-match.md`
  is byte-identical before and after (`git diff` empty on that path) —
  the gate never touches a file nobody writes to.
- `docs/handbooks/role-gates-tests.md` describes the allow-list shape
  accurately, readable without cross-referencing this proposal or issue
  #128's execution-observation record.
