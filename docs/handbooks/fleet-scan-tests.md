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

Known gap (out of this file's scope, recorded in
`docs/issue-173/reports/implementation.md`): `stub-check.sh`'s own
unconditional `CANON_GATES` manifest loop still flags `directive.sh` by
filename before its later structural check runs, so one invocation of
`stub-check.sh` can emit a contradictory FAIL/ok pair for the same
sanctioned stub — pre-existing, not introduced by this fix, and not
covered by this issue's approved write set (only `compliance-check.sh`'s
`--canon-duplication` mode was in scope).
