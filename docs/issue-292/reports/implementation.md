---
issue: 292
role: implementation
loop_state: landed
upstream:
  - path: docs/issue-290/reports/implementation.md
    sha: 94ba44311b6d8bf56244c9fa23ddf0e4ee2cb4e6
commit_sha: same-commit
code_under_review: same-commit
type: docs
breaking: false
verdict: pass
---

# issue-292 — implementation record

## What was done

Investigated the issue's claim that every gate parsing a `Bash` command's
TEXT to extract a target path via static regex can be defeated by
splitting the path across shell variables
(`d="docs"; i="issue-7"; printf x > "$d/$i/f"`). Enumerated every
`PreToolUse`-wired gate in `core/hooks/hooks.json` plus
`warrant/hooks/scope-gate.sh` and traced the extraction logic in each by
hand against the PoC command.

Confirmed vulnerable, blocking gates (deny on positive regex match,
allow by default otherwise — all defeated the same way): `approval-gate.sh`,
`board-gate.sh`, `record-shape-gate.sh`, `ordering-gate.sh` (three
mechanisms). Confirmed NOT affected: `warrant/hooks/scope-gate.sh`
(structurally different — never uses positive path extraction to arm
`Bash` write-set enforcement; already fails closed on unanalyzable
shapes and never vouches for an unproven write, per its own pre-existing
"A6" comment); `citation-gate.sh`/`facet-keyword-gate.sh`/
`handbook-trigger-gate.sh`/`survey-order-gate.sh`/`proposal-shape-gate.sh`
(demoted to advisory-only in issue-282, `deny()` always `exit(0)` — no
block to evade); `trailer-gate.sh`/`gh-guard.sh` (don't extract a target
file path at all — different concern).

Decided (c) from the issue's own options: accept and document the gap
rather than implement a fix, for the four vulnerable blocking gates.
Wrote `docs/decisions/2026-08-24-bash-variable-split-path-extraction-gap.md`
(the full enumeration, threat-model reasoning, and both rejected
alternatives with their reasons) and added a matching section to
`docs/handbooks/gate-house-standard.md` (the existing reference doc for
`gate_bash_write_targets`, the shared technique three of the four
gates use). No `core/hooks/*` or `warrant/hooks/*` file was modified —
this is a documentation-only decision, not a code fix, so no regression
test was authored (the issue's "if fixed" acceptance clause does not
apply).

## Why

**Threat model.** Every vulnerable gate is a `PreToolUse` hook
evaluating a command the SAME session is about to run via its own
`Bash` tool — there is no external adversary reaching this surface
without already holding that session's own `Bash` execution, at which
point strictly simpler, already-unaddressed bypasses exist (`python3 -c
"open(p,'w').write(x)"`, editing the gate script itself, or a session
that never sets `CLAUDE_ROLE`). This is a session-evading-its-own-
governance threat model, not an external-bypass one; issue-282 already
established this repo accepts several of these same gates as advisory
speed bumps rather than hard boundaries when hardening cost exceeds
benefit.

**Why not fix (a) PostToolUse actual-diff inspection.** The only
mechanism that closes the class completely, but it requires converting
four `PreToolUse`-blocking gates to a fundamentally different
enforcement model (detect-and-react-after-the-write instead of
refuse-before-the-write) — a gate-house-standard-level redesign, not a
single-issue fix.

**Why not fix (b) extend the regex for common variable-split idioms.**
The issue's own text already calls this "cheap but incomplete, an arms
race" and the investigation confirms it: Bash has unbounded ways to
build a path indirectly (indirect expansion, `printf -v`, arrays,
`eval`, multi-hop concatenation) beyond the one PoC idiom. Invoked the
`secure-coding-input-validation-injection-defense` skill (see
skill-verdict below) mid-decision to check this against standard
input-validation practice: its rule 2 states a denylist proposed as the
SOLE defense against injection-shaped input should be removed as the
primary control, not extended — exactly what the four vulnerable gates
already are (deny only on positive pattern match, allow by default).
The textbook-correct alternative is an allowlist (deny by default,
permit only what's provably safe), which `scope-gate.sh` already
implements for `Bash` — named in the decision doc as the correctly-
shaped fix a future issue should reach for instead of (b), but not
adopted now: flipping the four gates' default from allow-unless-
detected to deny-unless-proven-safe changes behavior for every ordinary
non-write `Bash` command a role already runs, a blast radius needing
its own proposal and full regression pass, not a documentation-only
decision.

## Upstream basis

- Issue #292 itself (hunter finding surfaced during #290's investigation,
  PR #291) — the PoC command and the three-option framing (fix a/b, or
  accept c).
- `docs/issue-290/reports/implementation.md` (sha
  `94ba44311b6d8bf56244c9fa23ddf0e4ee2cb4e6`) — the sibling finding
  (Bash heredoc writes to phase-2 record paths) that this issue's own
  body names as the trigger for filing #292, and confirms
  `approval-gate.sh`'s `Bash` handling has covered `elif tool == "Bash"`
  since its first commit.
- `docs/decisions/2026-08-01-s19-no-pr-refusal-retired.md` — precedent
  for this repo's decision-doc shape (Context / Decision / Rejected
  alternatives / Effect / Failure signal) and for `docs/decisions/`
  being the right bucket for a repo-wide, hard-to-reverse posture call.
- `docs/handbooks/gate-house-standard.md` (pre-existing content) — the
  canonical description of `gate_bash_write_targets` as "the technique
  approval-gate.sh/board-gate.sh already used," which independently
  confirmed the shared-helper enumeration.

## Open findings

None. The decision doc's own "Failure signal" section names the
condition under which this call should be revisited (a variable-split
or otherwise regex-evading `Bash` write reaching `main` unmerged-caught
by neither human PR review nor a warrant-hunter pass) — that is a
standing watch condition, not an open finding against this record.

## What did not work

Nothing attempted here was undone or replaced; no expectation held here
failed. (Considered, but did not attempt, converting the four gates to
`scope-gate.sh`'s fail-closed allowlist shape — ruled out at the
reasoning stage, before any edit, for the blast-radius reason stated
above under "Why," not because an attempt broke.)

## Next steps

None — `loop_state: landed`, terminal for a `coding-record`. Future work
is conditional on the decision doc's own failure signal, not a
scheduled next step.

## Skill check

Skills mounted for this role: `implementation-complexity-coupling-
management`, `implementation-design-pattern-selection`,
`implementation-performance-data-structure-choice`,
`implementation-blueprint`, `secure-coding-input-validation-injection-
defense`. This turn produced zero code changes (a decision doc plus a
handbook section) and no new module structure, coupling change, design-
pattern call, or data-structure/performance choice, so the first four
are not-applicable by their own trigger text.

skill-verdict: secure-coding-input-validation-injection-defense — applied: invoked; loaded via Skill tool mid-decision to weigh option (b) (extend the gate regex) against standard input-validation practice — its rule 2 (denylist-as-sole-defense should be removed, not extended) directly informed the "Why not fix (b)" section and surfaced `scope-gate.sh`'s existing allowlist shape as the correctly-shaped future fix, named in the decision doc.
other mounted skills: not triggered (implementation-complexity-coupling-management, implementation-design-pattern-selection, implementation-performance-data-structure-choice, implementation-blueprint — no code/structure change in this turn).

## Warrant-hunter dispatch

Skipped, both transitions. No proposal round ran (`CORE_BUILD_NOW=1`,
contract v3 s19a build-now bypass), so there is no "after-proposal"
moment. The before-landing dispatch is skipped per warrant-protocol's
own DOCS-ONLY FAST PATH: every touched path in this change
(`docs/decisions/2026-08-24-bash-variable-split-path-extraction-gap.md`,
`docs/handbooks/gate-house-standard.md`, this record) is under `docs/`
— `git diff --cached --stat` against HEAD (`94ba443`) shows 2 files, 207
insertions, 0 deletions, both `docs/`.
