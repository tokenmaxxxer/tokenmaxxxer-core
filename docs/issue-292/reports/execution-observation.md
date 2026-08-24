---
issue: 292
role: execution-observation
loop_state: cleared
upstream:
  - path: docs/decisions/2026-08-24-bash-variable-split-path-extraction-gap.md
    sha: e3ff185a807cf7f8d416d8ed074871a0f38e8b79
  - path: docs/handbooks/gate-house-standard.md
    sha: e3ff185a807cf7f8d416d8ed074871a0f38e8b79
  - path: docs/issue-292/reports/implementation.md
    sha: e3ff185a807cf7f8d416d8ed074871a0f38e8b79
subject: PR #293 (issue-292/implementation, merged as e3ff185), its two
  central claims — gate-enumeration accuracy and "no core/hooks/*  or
  warrant/hooks/* behavior changed"
test: manual source-line re-derivation of each named gate's Bash-path-
  extraction/blocking behavior against the PoC
  `d="docs"; i="issue-7"; f="reports/coding.md"; printf x > "$d/$i/$f"`,
  cross-checked against PR #293's own decision doc and implementation
  record; `git diff` of the merge commit against its parent to confirm
  the no-code-change claim
result: failed
assertedBy: execution-observation session, issue-292 (phase 2)
---

# issue-292 — execution-observation record

## What was done

Independently re-derived, from the actual gate source in this workspace
(not from PR #293's own narration), whether each gate PR #293 names
matches its claimed vulnerable/not-vulnerable classification against the
issue's PoC, and separately confirmed the PR's "no `core/hooks/*` or
`warrant/hooks/*` behavior changed" claim against the actual merge diff.

PR #293 was already merged to `main` (squash-merge `e3ff185`,
2026-08-24T09:10:29Z) by the time this phase-2 work started — a material
change from the phase-1 proposal's "still open" premise, noted here
per that proposal's own caveat. The merge is a plain squash of the PR
branch's single commit (`6e9befa`) with an identical tree; content read
is unaffected, only its landed/open status is.

**Claim 2 (no enforcement code changed): PASSED.** `git diff 94ba443
e3ff185 -- core/hooks/... warrant/hooks/...` (94ba443 is the pre-PR
commit both this branch and `issue-292/implementation` forked from) is
empty. The merge touches only `docs/decisions/...`,
`docs/handbooks/gate-house-standard.md`, and
`docs/issue-292/reports/implementation.md` — all `docs/`, matching the
PR's own "2 files, 207 insertions" test-plan line (the record itself is
the third, expected addition).

**Claim 1 (gate-enumeration accuracy): FAILED, with a passing core and
two concrete undercounts.**

Confirmed accurate as claimed, read directly from source:
- `core/hooks/approval-gate.sh` (`core_hooks/approval-gate.sh:157-159`):
  `re.findall(r"[\w./~$-]+", cmdline)` over the PoC yields tokens `d`,
  `docs`, `i`, `issue-7`, `f`, `reports/coding.md`, `printf`, `x`,
  `$d/$i/$f` — none matches `ISSUE_RE`
  (`r"(^|/)docs/(issue-[0-9]+)/(.*)$"`); the write proceeds unchecked.
  Vulnerable, matches PR's claim.
- `core/hooks/board-gate.sh` (`_write_target_windows` /
  `re.findall(r"[\w./~$:-]*docs/[\w./-]*", target)`, lines ~412-446,
  620-624): the dequoted redirect-target window is `$d/$i/$f`, which
  contains no literal `docs/` substring, so `own_hits` is empty and
  `_is_unanalyzable_write_shape` also returns False for a plain
  `printf > "..."` — no candidate, no unanalyzable flag, allowed.
  Vulnerable, matches PR's claim.
- `warrant/hooks/scope-gate.sh`: traced the PoC through
  `UNANALYZABLE_WRITE_SHAPE` (no match — `printf` isn't an interpreter
  head, no heredoc/tee/dd/IFS-fusion) into `withheld()`, where the bare
  `>` redirect matches `WITHHELD`'s
  `(?<![0-9&])>{1,2}(?![&|])` "writing a file by shell redirection"
  entry — the gate `allow()`s (declines to vouch) regardless of what
  path text follows `>`. Structurally immune as claimed: it never
  attempts positive path extraction for `Bash` at all, so variable-
  splitting changes nothing.
- The 5 advisory-only gates (`citation-gate.sh`, `facet-keyword-gate.sh`,
  `handbook-trigger-gate.sh`, `survey-order-gate.sh`,
  `proposal-shape-gate.sh`): grepped each for `exit 2`/`sys.exit(2)`
  outside the shared source-guard/fail-closed-on-internal-error
  boilerplate. `citation-gate.sh` and `facet-keyword-gate.sh` have none.
  The other three define their own `deny()` and each calls
  `sys.exit(0)` inside it with an explicit `# issue-282 DEMOTE: advisory,
  not blocking` comment (confirmed by reading the actual `deny()` body in
  each). None can block regardless of extraction accuracy. Matches PR's
  claim.
- `trailer-gate.sh`/`gh-guard.sh`: confirmed both classify commit-trailer
  shape / `gh`/`git` verbs respectively, not a target file path — out of
  this issue's own framing, as the PR states.

**Undercount 1 — `core/hooks/ordering-gate.sh`.** PR #293 names "three
mechanisms (`mech_content_design`, `mech_devrel` ... `mech_interaction_
design` ...)" as vulnerable. Reading `ordering-gate.sh`'s `ROLES` table
(lines 517-525) shows **seven** role mechanisms, not three:
`mech_content_design`, `mech_devrel`, `mech_security_threat_model`,
`mech_incident_response`, `mech_interaction_design`, `mech_arch_sequence`,
`mech_issue_retrospective`. Of the four PR #293 does not mention:
- `mech_incident_response` (lines 180-268) and `mech_arch_sequence`
  (lines 386-468) both DO handle the `Bash` tool for their scoped paths
  — the former via the same shared `gate_lib.gate_bash_write_targets()`
  tokenizer as `mech_content_design`/`mech_devrel`, the latter via its
  own `BASH_WRITE_RE` redirect-target regex — and both are defeated by
  the identical variable-split PoC the same way `mech_content_design`/
  `mech_devrel` are (their `SURFACE_RE`/`PROPOSAL_RE`/`RECORD_RE` never
  see a `docs/issue-N/...` literal in the extracted token, so the
  mechanism returns `None` — "not my business" — instead of denying).
  These are the same vulnerability class PR #293 already documents, just
  two more instances of it, uncounted.
- `mech_security_threat_model` (lines 161-177) and
  `mech_issue_retrospective` (lines 471-505) each open with
  `if tool not in ("Write", "Edit", "MultiEdit") ...: return None` —
  they never inspect a `Bash` `tool_input` at all. This is a *different
  and broader* gap than #292's regex-defeated-by-splitting class (no
  variable-splitting is even needed — a Bash write with the literal,
  unobfuscated target path also sails past these two mechanisms
  untouched), and it is absent from both the decision doc and the
  handbook section entirely, not merely under its enumerated count.

**Undercount 2 — `core/hooks/record-shape-gate.sh`.** PR #293's
description ("via the shared `gate_lib.gate_bash_write_targets()`
token-scan ... feeding a `target_path_regex` match; when a match IS
found for a `Bash` call it already denies outright") is accurate for
the file's config-driven `CHECKERS` dispatch (issue-263 fold, lines
300-467) — confirmed: `candidate_paths()` calls
`gate_lib.gate_bash_write_targets` for `tool == "Bash"`
(line 346-347), and an unmatched candidate set (the variable-split
case) reaches `if not matched_rows: sys.exit(0)` (line 365-366),
allowing it through. But the file's *other*, hardcoded check — the one
this same PR's own record targeted and that this repo's
`record-shape-directive` (frontmatter/`## What did not work`/deviation-
section floor) actually governs — is scoped to
`tool in ("Write", "Edit", "MultiEdit")` only (lines 168-173): `path =
None; if tool in (...): ...; if path is None: sys.exit(0)`. It does not
attempt to read a `Bash` `tool_input` at all, so a `Bash`-tool write to
`docs/issue-<n>/reports/implementation.md` — variable-split or with a
fully literal path — bypasses the hardcoded record-shape floor
entirely, regardless of this issue's specific PoC. PR #293's phrasing
does not distinguish this from the config-dispatch mechanism it
describes, so a reader could reasonably take "record-shape-gate.sh is
vulnerable [to the variable-split class]" as covering the whole file,
when one of its two independent checks has a wider, unrelated gap.

## Why

The proposal's own "How you'll know it worked" bar was a stated,
evidenced verdict on PR #293's two central claims, citing actual gate
source lines rather than restating the PR's text. Re-deriving from
source (rather than trusting the PR's own enumeration) is exactly what
surfaced the two undercounts above — a narration-only read would have
reproduced PR #293's own blind spots. Both undercounts sit squarely
inside PR #293's own stated method ("every gate ... checked for whether
it (a) handles the Bash tool at all, (b) extracts a candidate target
path... via regex, and (c) blocks... based on that extraction") — the
method is sound, but its application to `ordering-gate.sh` (whose
`ROLES` table has seven entries, not three) and to
`record-shape-gate.sh` (whose hardcoded check is a second, Bash-blind
mechanism distinct from its config-dispatch one) was incomplete. This
does not reopen or re-litigate PR #293's accept-vs-fix decision itself
(out of this observation's scope, per the approved proposal) — the
OWASP denylist-as-sole-defense reasoning for rejecting option (b), and
the redesign-cost reasoning for rejecting option (a), do not depend on
the exact mechanism count. What is inaccurate is narrower: the
enumeration PR #293 presents as complete is not complete, and the
decision doc/handbook section a future reader relies on to know "which
gates are already known-vulnerable to this class" currently omits four
real instances of exactly the pattern that document exists to name.

## Upstream basis

- `docs/decisions/2026-08-24-bash-variable-split-path-extraction-gap.md`
  (sha `e3ff185a807cf7f8d416d8ed074871a0f38e8b79`) — the claims verified
  here.
- `docs/handbooks/gate-house-standard.md` (same sha) — the handbook
  section added alongside the decision doc, sharing the same
  enumeration and thus the same undercounts.
- `docs/issue-292/reports/implementation.md` (same sha) — PR #293's own
  phase-2 record; its "What was done" and "Why" sections restate the
  same enumeration checked here.
- `core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`,
  `core/hooks/record-shape-gate.sh`, `core/hooks/ordering-gate.sh`,
  `core/hooks/lib/gate-lib.sh`, `warrant/hooks/scope-gate.sh`,
  `core/hooks/citation-gate.sh`, `core/hooks/facet-keyword-gate.sh`,
  `core/hooks/handbook-trigger-gate.sh`, `core/hooks/survey-order-gate.sh`,
  `core/hooks/proposal-shape-gate.sh` — the actual gate source read in
  this workspace, confirmed unchanged since commit `94ba443` (`git diff
  94ba443 e3ff185 -- core/hooks/... warrant/hooks/...` is empty).
- Issue #292 itself — the PoC command and the three-option framing this
  record's `test:` re-runs against each named gate.

## Open findings

1. `core/hooks/ordering-gate.sh`'s `mech_incident_response` and
   `mech_arch_sequence` are vulnerable to the same variable-split class
   PR #293 already accepts-and-documents for `mech_content_design`/
   `mech_devrel`/`mech_interaction_design`, but are named in neither the
   decision doc nor the handbook section. Resolution path: a follow-up
   docs-only edit to
   `docs/decisions/2026-08-24-bash-variable-split-path-extraction-gap.md`
   and the matching `gate-house-standard.md` section, adding these two
   mechanisms to the existing enumeration — same accept-and-document
   posture, no code change implied, no new issue needed unless the
   human wants one filed for tracking.
2. `core/hooks/ordering-gate.sh`'s `mech_security_threat_model` and
   `mech_issue_retrospective` never inspect the `Bash` tool at all (a
   broader gap: no variable-splitting needed, a plain literal-path Bash
   write to their scoped surfaces also bypasses them). This is adjacent
   to but distinct from issue #292's own framing ("extracts a target
   path from Bash command text" — these two mechanisms extract nothing
   from Bash because they never look). Resolution path: worth its own
   observation or a note in the same decision doc, at the human's
   discretion — flagging here rather than deciding scope unilaterally.
3. `core/hooks/record-shape-gate.sh`'s hardcoded
   `docs/issue-<n>/reports/implementation.md` floor check (frontmatter/
   `## What did not work`/deviation-section) is `Write`/`Edit`/
   `MultiEdit`-only and never examines a `Bash` `tool_input`, independent
   of the config-dispatch mechanism PR #293's decision doc actually
   describes. Resolution path: same as (2) — a documentation note (or a
   correction to the existing decision doc distinguishing the file's two
   independent check paths) at the human's discretion.

## Next steps

None from this record's own scope — `loop_state: cleared` (this
record's kind carries no repo-defined terminal-state override in
`docs/specs/record-fields-terminal-states.json`, which does not exist in
this repo; `cleared`, the `verify-record` terminal value, is used here as
the closest analog given this skeleton's verify-shaped
`subject/test/result/assertedBy` fields). This verification pass is
complete; whether to act on the three open findings above (correct the
decision doc's enumeration, and/or open a further issue for the
Bash-blind mechanisms) is the human's call, not this observation's to
decide or schedule.
