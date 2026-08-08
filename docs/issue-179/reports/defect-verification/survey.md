# issue-179 phase-1 survey: today's core merges as a set

code_under_review: bb0d197aa80782a124c8318ab5d6fed123bbca3e (main tip at session start)

## Scope

Issue #179 asks for side-effect verification of today's landed set — not a
per-PR re-check — over four named hunt areas. This survey maps each area to
the actual code paths and existing records before proposing attempts.

## Hunt area 1 — gate interactions on one compound action

- `core/hooks/hooks.json` registers `board-gate.sh`, `approval-gate.sh`,
  `gh-guard.sh`, `trailer-gate.sh`, `record-fields-gate.sh`,
  `handbook-trigger-gate.sh` as independent `PreToolUse .*` entries — no
  shared transaction state.
- The budget cap (`gate_budget_exceeded`, `core/hooks/lib/gate-lib.sh:97-112`)
  is consumed by `warrant/hooks/hunt-guard.sh`, wired through a **separate**
  `warrant/hooks/hooks.json` registration, not core's chain.
- So "trailer-gate + handbook-trigger + record-fields + budget cap on one
  commit" is actually two independently-registered hook chains (core plugin,
  warrant plugin) firing on the same tool call. No dedicated review.md exists
  for #146/#155/#168 (implementation.md / architecture.md only) — no
  closed_checks entry to cite for cross-chain ordering; this is undocumented
  behavior, not a reviewed-and-closed claim.

## Hunt area 2 — #167 scope-gate fix vs warrant-hunt flows

- `docs/issue-167/proposals/2026-08-08-fix-163-defects.md` closed A2, A4, A5
  from #163. `docs/issue-167/reports/implementation.md` (phase-2-complete)
  records a mid-build correction: the quote-collapse regex missed
  single-char-split commit verbs, generalized to a full quote-strip with
  offset map (`core/hooks/trailer-gate.sh:92-111`).
- A4 fix: `warrant/hooks/scope-gate.sh` Bash-branch default-allow replaced
  with a narrow read-only allowlist.
- A2 fix: `warrant/hooks/hunt-guard.sh:87` agent-type check now matches
  `warrant-hunter` or `warrant:warrant-hunter`.
- A7 (gh-guard renamed-binary/PATH-shadowing gap) is explicitly out of scope
  for #167, recorded Low/advisory, still open
  (`docs/issue-163/reports/defect-verification.md:262`,
  repro at `tests/test_silent_failure_repros.py::test_A7_gh_guard_renamed_binary_bypass_still_holds`).
- `warrant/hooks/hooks.json:26-41` registers `scope-gate.sh` and
  `hunt-guard.sh` as two separate `PreToolUse .*` blocks.

## Hunt area 3 — canon scans vs core's own tree

- `core/hooks/tests/stub-check.sh` has **no explicit self-path exclusion in
  code** — exclusion of core's own tree is a caller-convention comment
  (lines 63-65), not an enforced check.
- `core/hooks/tests/compliance-check.sh --canon-duplication` does explicitly
  exclude core's own canonical sources (comment lines 29-30, 85-86; canon
  name list line 40).
- Content-hash duplication: `core/hooks/lib/gate-lib.sh:210-234`
  (`gate_content_hash_matches_canon`); `directive.sh` uses a structural check
  instead (`gate_is_role_directive_stub`, ~line 226).
- `canon-forms.txt` read at `core/hooks/lib/gate-lib.sh:131`, file at
  `core/hooks/tests/canon-forms.txt`. Related: #173, #175, #177.

## Hunt area 4 — terminal-state derivation vs record-fields e2e

- Override file `docs/specs/record-fields-terminal-states.json` is checked
  for at `core/hooks/record-fields-gate.sh:360` but **does not exist in the
  repo** — the override path is currently dead code; `KIND_TERMINAL_DEFAULTS`
  (issue-147) governs at runtime.
- Kind resolution precedence (`:352-359`): role→kind via `ROLE_TO_KIND` is
  authoritative; self-declared `kind:` frontmatter is fallback only — this
  was itself an issue-147 before-landing hunt fix (previously self-declared
  `kind:` was trusted unconditionally).
- Legacy `RECORD_FIELDS_TERMINAL_STATES` env var (line 112) still present,
  superseded by the per-kind path per issue-147's own comment block.
- Malformed-JSON / unrecognized-kind / bad-state-string validation exists
  (`:361-404`) but is **untested against an actual override file**, since
  none exists in the repo yet.

## Open findings inherited from prior verification

- #163's A7 remains open, accepted Low/advisory, unresolved by design —
  not re-litigated here, only reconfirmed still holds if exercised.
- #163's A8 (fleet scan across 43 repos) recorded `blocked:
  needs-repro-access` — unresolved by access constraint, not a coding
  finding.
- No other `addressed_to: coding` unresolved findings found across
  docs/issue-{141,142,146,147,155,167,168,63,173,175,177}/reports/.

## Scout skip record

Scouting (external exemplar sweep) is skipped: this is an internal
side-effect/regression hunt over a fixed, fully-internal source set (issue
text's named hunt areas, existing closed_checks, and this repo's own gate
code) — there is no external product category or comparable system whose
best-in-class practice would change which internal interaction points get
exercised. The spec (issue #179's hunt-area list) leaves no external design
decision open.
