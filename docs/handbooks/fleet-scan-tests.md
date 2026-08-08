# fleet-scan test harness

`core/hooks/tests/run-fleet-scan-tests.sh` exercises
`core/hooks/tests/fleet-silent-failure-scan.sh` and
`core/hooks/tests/run-fleet-scan.sh` (issue-168) against synthetic
throwaway repos, plus a live 43-repo fleet run when `gh`/network access is
available (clearly skipped otherwise, never silently passed).

Run it directly, no setup required:

    bash core/hooks/tests/run-fleet-scan-tests.sh

Covers: a clean synthetic repo scans to a `clean` row with exit 0; a
synthetic repo carrying a swallowed-error shape surfaces a `FINDING` row
(never `blocked`) with a non-zero exit; a nonexistent scan path is a hard
error (exit 2), never a `blocked` row; and, network-permitting, the live
43-repo fleet run produces exactly 43 result rows with zero `blocked`
rows.

**issue-173: `--canon-duplication` stub-vs-vendored red-green pair.**
`compliance-check.sh --canon-duplication` used to flag any file named
`directive.sh` as a vendored copy of core canon by filename alone, so a
correctly-rolled-out rulebook's sanctioned per-repo `directive.sh` stub
(`docs/handbooks/canon-rollout.md` step 3 — source `role-directive.sh`,
call `core_role_directive`) could never pass. Fixed by extracting
`stub-check.sh`'s existing structural stub classification into a shared
`gate_is_role_directive_stub()` (`core/hooks/lib/gate-lib.sh`), reused by
both `stub-check.sh` and `compliance-check.sh --canon-duplication`'s
`directive.sh`-specific branch, so a sanctioned stub passes and a
genuinely vendored full copy still flags. Pinned here by two synthetic
rulebook fixtures: a correct single-call `directive.sh` stub scans clean
(exit 0, no vendored-copy line) under `--canon-duplication`; a
full pre-promotion `directive.sh` body still flags (exit 1, vendored-copy
message present). Every other `canon-manifest.txt` entry keeps its
existing unconditional filename-match FAIL, unchanged.

**issue-180: `gate_is_role_directive_stub` is now a structural line
classifier, not a canon-forms.txt regex table.** Three rounds of
per-repo pattern rows added to `core/hooks/tests/canon-forms.txt` (#78,
#173, #175, #177) each still left real Batch-1 fleet-scan repos scanning
dirty against two structural gaps: a nested-double-quoted source path
expression broke every quote-anchored regex row, and a direct
`role-directive.sh` source with no preceding `gate-lib.sh` source
matched no registered row. `gate_is_role_directive_stub` now classifies
each remaining "other" line of a `directive.sh` against four structural
categories (a basename-anchored `.`/source of `gate-lib.sh` or
`role-directive.sh`, tolerant of arbitrary nested quoting; a single
`gate_<name>` call once a `gate-lib.sh` source has matched; a `set -e`
family preamble line; and sales-rulebook's narrow `for`/`do`/`done`
fragment-loop syntax) instead of matching against
`core/hooks/tests/canon-forms.txt` rows — that file now carries zero
`directive.sh` shape rows and nothing else reads it. Fixtures (byte-exact,
citing repo+sha for architecture-rulebook, accessibility-rulebook,
localization-rulebook, and capacity-planning-rulebook) live in
`core/hooks/tests/run-stub-canon-forms-tests.sh` — despite this file's
own name suggesting `run-fleet-scan-tests.sh` might own directive.sh
shape coverage, it does not; `run-stub-canon-forms-tests.sh` is the
correct suite, and it exercises `gate_is_role_directive_stub` directly
rather than through `stub-check.sh`, to sidestep the known
`canon-manifest.txt`/structural-check conflict documented in the "Known
gap" paragraph below.

**issue-185: third "custom-by-convention" category, canon-needle
anti-bypass.** The stub/vendored classification stayed binary even after
issue-180: any `directive.sh` failing `gate_is_role_directive_stub` read
as "vendored copy", with no outcome for a file that was never meant to
be a stub at all. Three real Batch-1 repos (accessibility-rulebook,
localization-rulebook, capacity-planning-rulebook) carry deliberately
custom, per-facet `directive.sh` SessionStart hooks — layered
additionally via `hooks.json` ordering, never sourcing
`role-directive.sh`/`gate-lib.sh`, never calling `core_role_directive` —
and false-positived as vendored. Fixed by adding
`gate_directive_custom_by_convention()` (`core/hooks/lib/gate-lib.sh`):
clean only when the file doesn't source `role-directive.sh`/`gate-lib.sh`,
carries no `core_role_directive`/`gate_[A-Za-z_]+` needle as a real
definition/call line (comment/heredoc-body lines are stripped first, so
a prose mention of the name never trips it), and doesn't hash-match
`role-directive.sh`/`gate-lib.sh` (defense-in-depth against a literal
byte-identical embed). The needle check is the load-bearing anti-bypass:
a vendored copy edited by one byte still hash-mismatches canon, but the
copied `gate_*`/`core_role_directive` name still carries over. Both
`stub-check.sh` and `compliance-check.sh --canon-duplication` now branch
three ways for a `directive.sh` hit — sanctioned stub / custom-by-
convention / FAIL — with a distinct "custom-by-convention" log line for
the middle case. Pinned in `run-fleet-scan-tests.sh` by the three real
byte-exact fixtures (accessibility-rulebook @
`ce5cbe5c4c55622001812ed18d8302221c2f5b21`,
`wcag-em-directive/hooks/directive.sh`; localization-rulebook @
`2c9f76b8b6ebc212845409413de7bb61c2de50c6`,
`localization/plugins/mqm-tagging/hooks/directive.sh`;
capacity-planning-rulebook @ `00273632123750aa3c5cff608729fa93f042b41`,
`capacity-forecast-method/hooks/directive.sh`) scanning clean under both
scripts, plus two re-based red fixtures that must still FAIL: a
one-byte-edited copy of `gate_is_role_directive_stub`'s own function
body (needle carried, hash mismatched) and a bare `gate_deny "denied"`
call with no source line at all. `core/hooks/tests/run-gate-lib-tests.sh`
adds direct unit coverage of `gate_directive_custom_by_convention`
(sanctioned stub, comment/heredoc-only mention, bare-call needle,
byte-identical hash match).

Known gap (out of this file's scope, recorded in
`docs/issue-173/reports/implementation.md`): `stub-check.sh`'s own
unconditional `CANON_GATES` manifest loop still flags `directive.sh` by
filename before its later structural check runs, so one invocation of
`stub-check.sh` can emit a contradictory FAIL/ok pair for the same
sanctioned stub — pre-existing, not introduced by this fix, and not
covered by this issue's approved write set (only `compliance-check.sh`'s
`--canon-duplication` mode was in scope).
