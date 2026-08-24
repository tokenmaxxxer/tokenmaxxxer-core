---
kind: decision
subject: issue-292
produced_by: implementation
loop_state: decided
upstream:
  - path: core/hooks/approval-gate.sh
    sha: 94ba44311b6d8bf56244c9fa23ddf0e4ee2cb4e6
  - path: core/hooks/board-gate.sh
    sha: 94ba44311b6d8bf56244c9fa23ddf0e4ee2cb4e6
  - path: core/hooks/record-shape-gate.sh
    sha: 94ba44311b6d8bf56244c9fa23ddf0e4ee2cb4e6
  - path: core/hooks/ordering-gate.sh
    sha: 94ba44311b6d8bf56244c9fa23ddf0e4ee2cb4e6
  - path: core/hooks/lib/gate-lib.sh
    sha: 94ba44311b6d8bf56244c9fa23ddf0e4ee2cb4e6
  - path: warrant/hooks/scope-gate.sh
    sha: 94ba44311b6d8bf56244c9fa23ddf0e4ee2cb4e6
---

# Decision: shell-variable-split target paths stay a documented gap, not a fix (issue-292)

## Context

Issue #292 (a hunter finding surfaced during #290's investigation, PR #291)
claims: every gate in this repo that extracts a target file path from a
`Bash` tool call's command TEXT via static regex can be defeated by
splitting the path across shell variables before the write —
`d="docs"; i="issue-7"; f="reports/coding.md"; printf x > "$d/$i/$f"` —
because the gate's regex never sees a literal path string, only the
literal characters `$d/$i/$f`.

## Investigation

**Enumeration.** Every gate wired into `core/hooks/hooks.json`'s
`PreToolUse` (plus `warrant/hooks/scope-gate.sh`) was checked for
whether it (a) handles the `Bash` tool at all, (b) extracts a candidate
target path from the command TEXT via regex, and (c) blocks (`exit 2`)
based on that extraction.

*Confirmed vulnerable — blocking, regex-token-extraction-gated:*

- `core/hooks/approval-gate.sh` — `for tok in re.findall(r"[\w./~$-]+",
  cmdline): if CODE_RE.search(tok) or ISSUE_RE.search(tok): ...`. Traced
  by hand against the issue's own PoC: the extracted tokens for
  `d="docs"; i="issue-7"; f="reports/coding.md"; printf x >
  "$d/$i/$f"` are `d`, `docs`, `i`, `issue-7`, `f`, `reports/coding.md`,
  `printf`, `x`, `$d/$i/$f` — none contains the literal substring
  `docs/issue-7/`, so `ISSUE_RE` never matches and `execution_surface()`
  never fires. The write proceeds unchecked, including pre-Approve.
- `core/hooks/board-gate.sh` — same class, via its own
  `re.findall(r"[\w./~$:-]*%s[\w./-]*" % re.escape(DOCS), target)` over
  masked command segments.
- `core/hooks/record-shape-gate.sh` — via the shared
  `gate_lib.gate_bash_write_targets()` token-scan (same character class,
  `grep -oE '[[:alnum:]_./~$-]+'` / its Python mirror) feeding a
  `target_path_regex` match; when a match IS found for a `Bash` call it
  already denies outright (unverifiable-content posture), but the
  variable-split case never produces a match to deny in the first place.
- `core/hooks/ordering-gate.sh` — three mechanisms
  (`mech_content_design`, `mech_devrel` via the shared `bash_targets`
  built from `gate_bash_write_targets()`; `mech_interaction_design` via
  its own inline `re.findall(r'[A-Za-z0-9_./~$-]+', bash_command)`) —
  same class.

*Not affected — different mechanism or no enforcement to bypass:*

- `warrant/hooks/scope-gate.sh` — does NOT use positive regex path
  extraction to arm write-set enforcement for `Bash`. Its own "A6"
  comment already states the write-set check "is never checked against
  the write set" for `Bash`; instead it requires PROVING a command is
  read-only (`readonly_allowed()`, which fails closed on any `[<>]`,
  `;`, `&`, backtick, `$(`, or pipe) to vouch for it, and separately
  hard-denies a narrow deny-list of shapes it knows it cannot read at
  all (heredoc body, interpreter `-c`/`-e`, `tee`/`dd`,
  `UNANALYZABLE_WRITE_SHAPE`). A plain-redirect `Bash` write —
  variable-split or not — already isn't checked against the frozen
  write set today; that is a pre-existing, already-documented (A6)
  limitation orthogonal to this issue, not a fresh hole #292 opens.
- `core/hooks/citation-gate.sh`, `core/hooks/facet-keyword-gate.sh`,
  `core/hooks/handbook-trigger-gate.sh`,
  `core/hooks/survey-order-gate.sh`, `core/hooks/proposal-shape-gate.sh`
  — all demoted to advisory-only in issue-282/PR#283 (every `deny()`
  path is `sys.exit(0)`, never `exit 2`). A detection bypass here
  changes nothing enforceable: there was no block to evade.
- `core/hooks/trailer-gate.sh`, `core/hooks/gh-guard.sh` — handle `Bash`
  but do not extract a target FILE path; they classify commit-message
  trailer shape and `gh`/`git` command VERBS respectively. Out of this
  issue's scope by its own framing ("extracts a target path from Bash
  command text").

**Scope of exploitability.** Every one of the vulnerable gates above is a
`PreToolUse` hook running in-process, evaluating a command the SAME
session is about to execute via its OWN `Bash` tool. There is no
external actor reaching this surface independent of that session
already holding full `Bash` execution — at which point strictly simpler,
already-unaddressed bypasses exist and require no cleverness: writing
via `python3 -c "open(p,'w').write(x)"`, `base64 -d <<< ... > `, editing
the gate script or `hooks.json` registration itself before the write, or
a `Bash`-only session that never triggers `CLAUDE_ROLE` at all.
`scope-gate.sh`'s own long-standing A6 comment names one such
already-accepted case (`F=-rf; rm $F`) as a known, deliberately
un-chased limitation. This is a session-evading-its-own-governance
threat model, not an external-bypass one — issue-282 already
established, by demoting 7 of these same gates to advisory, that this
repo accepts several of its path-detection gates as speed bumps against
a cooperative-but-imperfect session rather than hard boundaries against
an adversarial one, when the cost of hardening exceeds the benefit.

## Decision — chosen: (c) accept the gap, document it, across every
affected gate

No code change. This decision document, plus the note added to
`docs/handbooks/gate-house-standard.md`, IS the fix: a session running
under this contract should never mistake a `Bash`-content-parsing gate
for a hard boundary against its own deliberate evasion — it is advisory
strength for that threat, backed by the merge-time human review and
`warrant`'s frozen-write-set-plus-hunter compensating controls
elsewhere in the stack.

**Rejected alternative (a): PostToolUse actual-diff inspection**
(inspect files that actually changed after the `Bash` call, rather than
pre-parsing command text). This is the only mechanism that closes the
class completely — it does not care how the path was constructed,
because it looks at the result. Rejected for this issue's scope: it is
not a patch to the four vulnerable gates as they exist. `approval-gate.sh`
et al. are `PreToolUse` blockers — the entire point is refusing the
write BEFORE it lands; a `PostToolUse` check can only detect and react
after the write has already happened (revert it, deny the session,
flag it for review), which is a different enforcement model requiring
its own design across every blocking gate (approval, board, ordering,
record-shape) plus a decision on what "react after the fact" even means
under contract v3's PreToolUse-blocking framing. That is a
gate-house-standard-level redesign, not a single-issue fix, and belongs
to its own proposal if the failure signal below is ever tripped.

**Rejected alternative (b): extend the regex to catch common
variable-split idioms.** The issue's own text already names this
"cheap but incomplete, an arms race," and the investigation confirms
why: Bash offers unbounded ways to construct a path indirectly beyond
the one PoC idiom — indirect expansion (`${!ref}`), `printf -v`, arrays,
`read`, associative arrays, `eval`, sourcing a second file that sets the
variable, multi-hop concatenation across several statements. Closing
one idiom via pattern-matching produces a strictly worse outcome than
documenting the gap: it creates false confidence that "the bypass is
fixed" while leaving an effectively unbounded set of siblings open, and
turns every future PoC into a fresh whack-a-mole PR against the same
regex instead of a settled, named trade-off. This matches standard
input-validation guidance independent of this repo's own reasoning: the
four vulnerable gates already run as a denylist/pattern-detection
mechanism (deny only when a candidate token positively matches
`ISSUE_RE`/`CODE_RE`/`target_path_regex`; allow by default otherwise),
and OWASP's Input Validation Cheat Sheet states plainly that a denylist
proposed as the SOLE defense against injection-shaped input should be
removed as the primary control, not extended — "it is trivial for an
attacker to bypass such filters." The textbook-correct alternative is
an allowlist (deny by default, permit only what is provably safe) —
which `warrant/hooks/scope-gate.sh` already implements for `Bash`
(`readonly_allowed()`: vouch only for a narrow set of provably
read-only shapes; everything else, including every write, falls through
un-vouched). Converting the four blocking gates to that same
fail-closed shape is NOT adopted here either: it would flip their
default from "allow unless a write is positively detected" to "deny
unless positively proven safe," which changes behavior for every
ordinary non-write `Bash` command a role already runs today (test
runners, `git`, read-only shell pipelines) — a blast radius requiring
its own proposal and full regression pass across every existing gate
test suite, not a documentation-only decision. Named here as the
correctly-shaped fix a future issue should reach for instead of (b), if
the failure signal below is ever tripped.

## Effect

- No `core/hooks/*.sh`, `core/hooks/lib/*`, or `warrant/hooks/*.sh`
  behavior changes; nothing here alters an existing test's expected
  result.
- `docs/handbooks/gate-house-standard.md` gains a short section naming
  `gate_bash_write_targets` (and its inline-regex siblings in
  `approval-gate.sh`/`board-gate.sh`/`ordering-gate.sh`) as literal-text
  token-scanning, not shell evaluation, with a pointer to this decision.
- The four vulnerable gates listed above keep their current behavior:
  advisory-strength detection against a session that is not deliberately
  evading its own governance, with the real backstops being (1) merge
  time human review of the delivered PR and (2) `warrant`'s frozen
  write-set plus hunter-dispatch pass, which is a structurally different
  (proposal-scoped, not regex-scoped) control.

**Failure signal.** If this decision is wrong, the signal is: a role
session's variable-split (or otherwise regex-evading) `Bash` write
reaches `main` through a merged PR without a human reviewer or a
warrant-hunter catching the out-of-scope write before merge. That would
mean the compensating controls this decision relies on (human PR review,
warrant's write-set/hunter pass) are not load-bearing in practice, and
option (a)'s PostToolUse redesign should be revisited as its own issue.
