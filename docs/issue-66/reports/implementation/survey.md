---
subject: issue-66
role: implementation
---

# Survey: role-agnostic rulebook plugin files (issue-66)

## Scope note

Scouting per the scout-directive is **skipped** for this issue: this is
an internal single-repo plugin-architecture decision (which files become
canon, how role-name injection generalizes), not a product-facing
deliverable with an external field of comparables. The one directly
relevant precedent — issue-63's warrant-hunt canon promotion — is
internal and is used below as the transition template, per the issue's
own instruction to batch with it.

## What exists today, counted directly

43 rulebook checkouts are reachable read-only under
`~/.claude/plugins/marketplaces/tokenmaxxxer/` (skeleton assets under
`docs/issue-170/_assets/rulebook-skeleton/*` and
`docs/issue-167/_assets/rulebook-skeleton/*`, plus a handful of live
rulebook runs under `runs/rulebooks/*`). File counts and content-hash
diversity, measured directly (`find` + `md5sum`):

| File | copies found | unique md5 |
|---|---|---|
| `trailer-gate.sh` | 40 | 38 |
| `record-fields-gate.sh` | 40 | 38 |
| `handbook-trigger-gate.sh` | 40 | 38 |
| `parse-check.sh` | 13 | 5 |
| `directive.sh` (rulebook role directives; excludes `core`/`scout`/`warrant`/orchestrate copies) | 43 | ~43 (boilerplate+unique mixed, see below) |

Copy counts here are lower than the issue's "43" for the gate files
because this checkout only has read access to a subset of rulebook repos
via the marketplace cache; the issue's own hash-scan (43/43, 43/43,
43/43, 10/10) is taken as authoritative for full-repo-set counts. The
near-total md5 diversity (38/40, 38/40, 38/40) independently confirms
the issue's drift claim on the accessible subset: **every copy differs**,
and not just in role name — see below.

## Confirmed: differences are role-name substitution, not logic changes

Diffing two `trailer-gate.sh` copies (`product` vs `coding` roles) shows
the entire diff is mechanical substitution of the role token, in two
distinct casings:

- Uppercase, as part of env var names: `PRODUCT_CYCLE_OFF` /
  `CODING_CYCLE_OFF`, `PRODUCT_PAYLOAD` / `CODING_PAYLOAD`,
  `PRODUCT_CPD` / `CODING_CPD`, `PRODUCT_CWD` / `CODING_CWD`.
  Same pattern in Python-embedded exception hook names:
  `_product_fail_closed` / `_coding_fail_closed`.
- Lowercase, in human-facing message prefixes: `"product: refused — ..."`
  / `"coding: refused — ..."`.

No other line differs. This means the promotion is mechanically simple:
these gates do not need the role name baked into the file at all — they
only need it to (a) label output and (b) namespace one kill-switch env
var. Both are already solvable via the `CLAUDE_ROLE` env var that core's
own canon files (`board-gate.sh`, `approval-gate.sh`) already read at
runtime (`core/hooks/board-gate.sh:213`, `core/hooks/approval-gate.sh:89`)
— there is an existing, established convention in this repo for reading
role identity from the environment rather than from a per-copy literal.

`parse-check.sh`'s 5 unique hashes among 13 copies is the smallest drift
footprint of the four gates — plausibly because it is role-*blind* by
design (it walks a directory tree, no role token appears at all per its
own header comment), so the file should be byte-identical everywhere;
5 distinct hashes on a role-blind file is itself a drift signal worth
flagging, likely representing stale versions picked up before a fix
propagated (the file's own header describes exactly this failure mode:
"the regression test lived in only one of the two repositories").

## `directive.sh`: boilerplate + role-unique content, mixed in one file

Diffing two rulebook `directive.sh` copies (`finance-unit-economics` vs
`risk-management`) shows a clean, consistent split:

**Boilerplate (identical structure across roles, differs only by role
token substitution):**
- Header comment shape: `# SessionStart: <role>'s role directive — how
  this role fills the core lifecycle. Kill switch: export
  <ROLE>_CYCLE_OFF=1`
- The `trap`/`set -uo pipefail` preamble (byte-identical, not shown in
  the two-line diff — confirmed separately)
- Kill-switch case statement: `case "${<ROLE>_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;; *) trap - EXIT; exit 0 ;; esac`
- Role guard: `[ "${CLAUDE_ROLE:-}" = "<role>" ] || { trap - EXIT; exit 0; }`
- Opening line: `[<role>] Role directive (on top of core's protocol):`
- Closing `RECORD:` line: `docs/issue-<n>/reports/<role>.md, phase-gated
  per contract v3 s19`

**Role-unique (genuinely different content per role, must stay in the
rulebook):**
- `YOU DECIDE:` — the role's one-line decision framing
- `USE_WHEN:` — trigger condition
- `PRODUCES:` — required record fields
- `HAND-OFF:` — routing to adjacent roles

This is a template-with-slots shape, not a monolith: the fix is a shared
formatting function in core that takes the four role-unique fields as
input and renders the fixed boilerplate around them, plus the guard/
kill-switch logic factored out entirely (role name and kill-switch
namespacing both derivable from `CLAUDE_ROLE`, same as the gates above).

## Existing convention already in this repo (design precedent)

`core/hooks/directive.sh` (core's own SessionStart hook) already uses
exactly this shape: a single generic kill switch (`CORE_OFF`, not
role-prefixed), a `CLAUDE_ROLE` guard read from the environment
(`role="${CLAUDE_ROLE:-}"`), and role-name interpolation done via shell
variable substitution (`${role}`) into a heredoc template, not via
per-role file copies. The four gate/boilerplate files under survey
should converge on the same shape core already uses for itself — this
is not a new pattern, it is applying core's existing pattern to files
that currently don't follow it.

## Transition precedent: issue-63

Issue-63's proposal (`docs/issue-63/proposals/2026-07-31-build-warrant-
hunt-canon-and-efficiency.md`) already establishes the promotion
mechanics this repo uses: canon content lands under a plugin directory
in this repo (mirroring `scout/`'s structure), each of the 43 rulebooks'
vendored copy is replaced by a one-line reference stub (declared
marketplace dependency, not a vendored file — "the same pattern `core`,
`scout`, `terse`, `freelunch` already use"), and the 43-rulebook rollout
is tracked as a follow-up this repo cannot execute directly (no write
access to rulebook repos). Issue-66 batches into the same rollout wave
per its own "순서 제약" — both promotions should ship as one per-rulebook
change, not two.

## Drift-detection gap

No file in `core/hooks/tests/` currently checks whether a rulebook's
"reference stub" actually stays a stub. `parse-check.sh` checks syntax
validity, not content shape — a stub that grows a locally-patched copy
of gate logic (exactly the failure mode that produced today's 38/40
unique hashes) would still parse cleanly and pass every existing check.
This is the gap issue-66 item 4 asks to close.
