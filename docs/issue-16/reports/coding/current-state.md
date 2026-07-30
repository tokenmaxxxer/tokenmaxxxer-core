---
subject: issue-16
role: coding
loop_state: scope-proposed
---

# Current-state survey: `core/.claude-plugin/plugin.json`

## Exact current description (line 3, verbatim)

```
"Human-approval machinery shared by every tokenmaxxxer role. Mints a single-use approval token from an exact challenge line in the user's own turn; a role's gate finds and consumes it. Ships the canonical role-handoff contract and a deny-only board gate. Gates in this plugin refuse but never permit. No version field on purpose: for a git-distributed plugin the commit SHA is the version, so every commit is an update."
```

Read directly from `core/.claude-plugin/plugin.json`, which is:

```json
{
  "name": "core",
  "description": "<above>",
  "author": { "name": "tokenmaxxxer" }
}
```

This description predates the token-machinery removal: commit `8696dd5`
("Publish without a version field, and document both modes") wrote this
exact text on 2026-07-27, one day *before* commit `1a69a08`
("Replace token machinery ... contract v3") on 2026-07-28 deleted
`mint.sh`/`consent.py`/`judge.py` and rewrote `board-gate.sh` into today's
five-rule form. `1a69a08` touched `README.md` and the hooks tree
extensively but never touched `plugin.json` — the description was simply
never revisited. That is the entire bug.

## What core actually ships today (read from the tree, not from the issue)

### a) The contract v3 canonical text

`core/contract/role-handoff-contract.md` — front matter `status: final`,
title "Role handoff contract (v3: issue/PR interaction model)", 21
numbered sections (`## 1. Common header` through `## 21. Document
placement beyond the role record`). No second copy exists anywhere in the
repo (`docs/specs/` holds only `approvers.md`); `board-gate.sh`'s own
comment (R2) explains why: *"planting per-repo copies carried zero
information (the hash check forced them identical) and made every
contract revision an atomic N-repo re-sync."* — i.e. per-repo duplication
was tried and deliberately abandoned. This plugin ships the one and only
copy.

### b) The four hooks

All confirmed against `core/hooks/hooks.json` (the actual PreToolUse/
SessionStart bindings) and each file's own header comment:

| file | event (from `hooks.json`) | what it denies (one line) |
|---|---|---|
| `core/hooks/directive.sh` | `SessionStart` | Not itself a deny — it is the *informing* half of the pair with `board-gate.sh` (the *enforcing* half): injects the role's protocol briefing and runs a precondition probe, only when `CLAUDE_ROLE` is set. |
| `core/hooks/board-gate.sh` | `PreToolUse`, matcher `.*` | Deny-only, 5 rules (R1-R5): docs/ layout, presence of `docs/specs/approvers.md` as the board marker, `CLAUDE_ROLE` required for issue-tree writes, writes must come from the matching `issue-<n>/<role>` branch, and a role may only write its own record/subtree under `reports/`. |
| `core/hooks/approval-gate.sh` | `PreToolUse`, matcher `.*` | Deny-only: refuses a role session's write to the execution surface (`src/`, `test/`, and the issue tree outside `proposals/**` and `reports/<role>/**`) until that issue's PR carries an allowlisted human's Approve — review or, in single-account mode, an exact `APPROVE issue-<n>/<role>` comment (contract v3 s19). Verdict is fetched live via `gh pr view --json reviews`, never cached. |
| `core/hooks/gh-guard.sh` | `PreToolUse`, matcher `.*` | Deny-only: refuses a role session (`CLAUDE_ROLE` set) from running the human's own GitHub acts — `gh pr review --approve/--request-changes`, `gh pr merge/close/reopen`, `gh issue create/close/reopen/edit`, `git push` to `main`/`master`, and the raw-API spellings of review/merge endpoints. |

**Discrepancy vs. the invoking prompt:** the prompt calls these "the four
deny-only hooks." Three of the four (`board-gate.sh`, `approval-gate.sh`,
`gh-guard.sh`) are literally deny-only `PreToolUse` gates. `directive.sh`
is a `SessionStart` hook that injects context; it has no tool call to
allow or deny and is not one of contract v3's enforcement gates — it is
the *briefing* half the contract explicitly pairs with `board-gate.sh`'s
*enforcing* half ("the two must describe the same rules"). All four
filenames match the prompt exactly (no naming discrepancy), but calling
all four "deny-only" is imprecise; the proposal's description text
accounts for this by describing `directive.sh` separately from the three
gates rather than folding it into "deny-only."

A live, incidental confirmation that these gates are active: a read-only
`git log -- docs/issue-14/...` command issued from this very session (on
branch `issue-16/coding`, `CLAUDE_ROLE=coding`) was refused by
`board-gate.sh` R4 for referencing another issue's tree, even though the
command only reads. The gate's Bash fast-path matches on the command
string, not on read/write intent — fail-closed as designed, just worth
recording as an observed behavior rather than inferring it from docs
alone.

### c) Everything else `core/` ships

`find core -type f` lists exactly: `core/.claude-plugin/plugin.json`,
`core/contract/role-handoff-contract.md`, the four hook files above, and
`core/hooks/tests/{deny-only-check.sh, parse-check.sh, run-all.sh,
run-approval-gate-tests.sh, run-board-gate-tests.sh,
run-gh-guard-tests.sh}`. No `skills/`, `agents/`, or `commands/`
directory exists under `core/` — unlike `terse`/`scout`/`freelunch`,
`core` ships no slash commands or skills, only the contract text, the
hooks, and their tests. Nothing here is a plausible candidate for the
description to name beyond the contract and the four hooks already
covered above; the test scripts are CI/dev-loop plumbing, not something a
user-facing manifest description would enumerate (none of the sibling
plugins' descriptions name their own test scripts either).

## Ecosystem convention

See `research.md`'s scout brief. Summary: `.claude-plugin/
marketplace.json`'s four plugin entries and the three sibling
`plugin.json` files (`terse`, `scout`, `freelunch`) are the only relevant
exemplars; register is a single dense paragraph, 2-4 sentences, ~300-450
characters, naming mechanisms functionally more than by filename. Notably
`marketplace.json`'s own `core` entry (447 chars) already describes the
current issue/PR protocol accurately and never mentions token minting —
it is a working exemplar of "what this description should have said
already," just missing the four hook names by filename that this issue
also wants named.

## Version field: absence is intentional, rationale located

Confirmed no `version` key anywhere in `core/.claude-plugin/plugin.json`
(nor in any sibling plugin.json, nor in any `marketplace.json` plugin
entry — the whole marketplace follows the same no-version convention).
Full rationale and both locations it lives in (`plugin.json`'s own
description sentence, and `README.md:146-148`) are recorded in
`research.md`. The phase-2 proposal preserves the `plugin.json` sentence
**unchanged, verbatim**, so `README.md` does not need a synchronized edit
— it states the same fact independently, in its own words, and quotes
nothing from the `description` field.

## Projected write set for phase 2

**`core/.claude-plugin/plugin.json` only.** No second file needs to
change in lockstep:

- The contract (`core/contract/role-handoff-contract.md`) has exactly one
  copy and is not being amended — issue #16 is a description-text fix,
  not a contract change.
- `README.md` states the version-field rationale independently, not by
  quoting `plugin.json`'s description, so it stays untouched.
- `.claude-plugin/marketplace.json`'s `core` entry is already accurate
  and is a different field in a different file, out of this issue's
  scope.
- The `## Done when` criterion "`bash core/hooks/tests/run-all.sh`
  passes" requires no test changes: the tests exercise hook *behavior*
  (`board-gate.sh`, `approval-gate.sh`, `gh-guard.sh`, the parse check),
  none of which read or assert on the `description` string, so a
  description-only edit cannot regress them. This is a check to re-run
  after the edit, not a file this proposal needs to touch.
