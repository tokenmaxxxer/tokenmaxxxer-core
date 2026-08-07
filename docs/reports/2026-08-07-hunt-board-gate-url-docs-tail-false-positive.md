proposal: docs/issue-149/proposals/2026-08-07-board-gate-url-docs-tail-false-positive.md

## after-proposal

docs-only, no before-landing dispatch — every path in the frozen write set
(`core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`,
`docs/handbooks/board-gate-tests.md`) is under `docs/` at the transition
this hunt would fire on: this commit (survey + proposal) touches only
`docs/issue-149/reports/implementation/survey.md` and
`docs/issue-149/proposals/2026-08-07-board-gate-url-docs-tail-false-positive.md`.
Skipped per the docs-only fast path.
