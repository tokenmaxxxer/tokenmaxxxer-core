---
status: proposed
files:
  - core/hooks/tests/canon-forms.txt
  - core/hooks/tests/run-stub-canon-forms-tests.sh
  - docs/handbooks/gate-house-standard.md
---

#177

## Request

#175's `unregistered-stub` and `layered-directive` canon-forms.txt patterns
were built from stated assumptions about repo content, not real bytes, and
were confirmed (by #171's Batch-1 live scan) to not match
architecture-rulebook's or accessibility-rulebook's actual `directive.sh`.
Replace the guessed patterns with ones derived from the real, transcribed
bytes of the four Batch-1 blocking repos (or a structural rule per the
issue's own suggested wording), citing repo+sha in the fixtures.

## Constraints

- Every registered pattern must cite the repo+sha it was derived from
  (issue acceptance) — no more assumption-built literals.
- `canon-forms.txt` patterns are only ever consulted for a `directive.sh`
  that already passes `gate_is_role_directive_stub`'s first two checks
  (sources `role-directive.sh`, calls `core_role_directive` —
  gate-lib.sh:143-148); a file that fails either check cannot be reached
  by any canon-forms.txt addition, no matter how the pattern is written.
- A genuinely vendored full copy of core's canon `directive.sh` must still
  flag (per #175's and #173's existing red-green convention) — a
  structural rule must not be so loose it accepts vendored boilerplate.
- The gate-lib.sh/gate_* patterns must not let an unbounded chain of
  sanctioned-looking lines through: `gate_is_role_directive_stub` applies
  every `canon-forms.txt` pattern per line with no cap on how many extra
  lines a file may carry, so a file chaining arbitrarily many distinct
  `gate_*` calls (or repeated `gate-lib.sh` sources) past the mandatory
  header would classify as a sanctioned stub even though that shape
  matches no real Batch-1 repo (found by the after-proposal warrant-hunter
  dispatch, `docs/reports/2026-08-08-hunt-canon-forms-real-bytes.md`). The
  real `architecture-rulebook` shape has exactly two such lines — the new
  patterns must be paired with a hard cap (at most one `gate-lib.sh`
  source line and at most one `gate_*` call line beyond the mandatory
  header) so the rule matches what was actually observed, not an
  open-ended generalization of it.

## Rationale

Considered replacing `layered-directive` with a corrected literal pattern
transcribed from `wcag-em-directive/hooks/directive.sh`'s real bytes
(matching its `case "${WCAG_EM_DIRECTIVE_OFF:-}"` guard line, its
`[ "${CLAUDE_ROLE:-}" = "accessibility" ]` line, etc.) and rejected it: that
file never sources `role-directive.sh` and never calls
`core_role_directive` — it fails `gate_is_role_directive_stub` at the
function's first two checks (gate-lib.sh:143-148), before `canon-forms.txt`
is ever consulted (gate-lib.sh:149-170). No pattern registered in
`canon-forms.txt`, however accurately transcribed, changes that file's
outcome. Writing a pattern for it anyway would be decorative — passing the
issue's letter (a pattern "derived from real bytes") while failing its
purpose (the repo scanning clean). The real fix for that file's class (five
files total, see survey) is a `gate-lib.sh` function-level decision — out
of this proposal's write set, named in "Out of scope" instead of silently
built here.

For `architecture-rulebook`, chose the structural rule (option (b) in the
issue) over a literal transcription of the two real lines: rejected the
literal-only alternative because it would only match this repo's exact
`ARCHITECTURE_CYCLE_OFF` variable name and this exact echo string,
re-breaking on the next repo that sources `gate-lib.sh` with a different
kill-switch variable — the same brittleness #175's assumption-built
patterns already demonstrated, just moved from "guessed" to "narrowly
correct". The structural rule (any line that only sources `gate-lib.sh` or
calls one of its exported `gate_*` functions) is derived from the real
line shapes but generalizes the variable/echo-text positions, matching the
issue's own preferred wording ("preferably (b)").

## What will be done

1. `core/hooks/tests/canon-forms.txt`:
   - Remove `layered-directive` (falsified by real bytes — see Rationale
     and survey; no Batch-1 repo's `directive.sh`-that-passes-the-first-
     two-checks has this shape, and it cannot fix the file it was written
     for).
   - Replace `unregistered-stub` with two structural patterns derived from
     `architecture-rulebook@da8565d615d9fb6c18487c9b338fa8b60bdf1120`'s
     real `architecture/hooks/directive.sh` lines 14-15:
     - a line that only sources `gate-lib.sh` (with an optional
       `|| { ...; exit N; }` fallback), matching the real line 14 shape;
     - a line that only calls an exported `gate_*` function (with an
       optional `|| exit N` fallback), matching the real line 15 shape
       (`gate_kill_switch_active "${ARCHITECTURE_CYCLE_OFF:-}" || exit 0`).
   - Cap: `gate_is_role_directive_stub`'s per-file classification (or a
     thin wrapper around it, whichever needs less change) rejects a file
     where more than one line matches the gate-lib-source pattern or more
     than one line matches the gate_*-call pattern, so the sanctioned shape
     stays bounded to what `architecture-rulebook`'s real bytes show
     instead of an open-ended chain (per the after-proposal hunt finding).
   - Each new/changed entry's comment cites repo+sha+path+lines, replacing
     the "stated assumption" comments #175 left.
2. `core/hooks/tests/run-stub-canon-forms-tests.sh`: replace the
   `unregistered_stub_file`/`layered_directive_file` fixtures (currently
   built from the issue-175 gap wording) with:
   - a fixture transcribing architecture-rulebook's real lines 14-16
     verbatim (want=pass);
   - a genuinely vendored-copy fixture (core's actual canon
     `directive.sh` content, unmodified) that must still fail (want=fail),
     proving the structural rule doesn't over-match;
   - drop the layered-directive pass case (no real repo bytes support that
     shape passing); keep/add a case showing a file with a `. ".../
     wcag-em-directive.sh"`-style line that is NOT a `gate-lib.sh`/`gate_*`
     line still fails, so the structural rule stays narrow.
   - a case chaining three-plus distinct `gate_*` calls beyond the header
     (want=fail), proving the one-line cap holds and closing the
     after-proposal hunt finding.
3. `docs/handbooks/gate-house-standard.md`: update the canon-forms.txt
   entry description to reflect the real-bytes-derived patterns and note
   the standalone-hook gap (pointer only, not a fix).

## Out of scope

- Fixing `gate_is_role_directive_stub` (gate-lib.sh) to recognize
  standalone, non-stub `directive.sh` files (wcag-em-directive,
  capacity-planning's four methodology plugins) as a sanctioned shape.
  This needs its own design decision and its own proposal — flagged in the
  survey, not built here.
- `localization-rulebook`'s plugin `directive.sh` files — not attributed
  to a specific unmatched canon-forms.txt shape by the runbook's own
  finding row; no real-bytes basis yet to derive a pattern from.
- Any push to the four sibling rulebook repos, or re-running the live
  43-repo fleet scan — #171's own next session, per its own record.
- Any change to `compliance-check.sh` or `stub-check.sh` beyond wiring the
  new fixtures into the existing test file.

## How you'll know it worked

`core/hooks/tests/run-stub-canon-forms-tests.sh` red-green: the
architecture-rulebook-real-bytes fixture passes, a genuinely vendored full
`directive.sh` copy still fails, and the run stays green end to end
(`bash core/hooks/tests/run-all.sh` shows no new failures). The fixture
comments cite repo+sha+path+lines, satisfying the acceptance's "cited by
repo+sha" requirement for the one repo whose gap this proposal's write set
can actually close.
