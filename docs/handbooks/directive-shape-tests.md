# directive shared-shape tests

`core/hooks/tests/run-directive-shape-tests.sh` renders
`core/hooks/directive.sh`'s interaction-protocol heredoc
(`CLAUDE_ROLE=implementation bash core/hooks/directive.sh`) and asserts
the rendered text states three gate-enforced shapes every role currently
learns only from a gate refusal (issue-204, on-the-record #726 rows 3,
4/14, 20):

1. spec-index regeneration (`docs/specs/reconciled-index.md` via
   `python3 gates/spec_index.py --update`) before a `docs/specs/*`
   commit — mirrors `spec-index-preflight.sh`.
2. the phase-1/phase-2 PR-trailer split (`Closes`/`Fixes`/`Resolves
   #<issue>` forbidden in phase-1, required in phase-2) — mirrors
   `pr-preflight.sh`'s `check_body`.
3. pytest `SKIPPED`-line and pass-count fidelity for test-pass claims —
   mirrors `role-test-claim-guard.sh`.

Run it directly, no setup required:

    bash core/hooks/tests/run-directive-shape-tests.sh

Each of the three assertions isolates its own bullet's text block
(via `awk`) before matching, rather than checking phrases anywhere in
the whole heredoc — a before-landing warrant hunt found the looser
whole-heredoc check would pass even when the phrases appeared in two
disconnected, unrelated bullets. Also asserts one empty-state fixture
per bullet (a fixture missing the phrase fails the check) and one
bypass fixture reproducing that hunt finding (disconnected bullets are
rejected).
