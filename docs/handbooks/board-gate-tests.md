# board-gate test harness

`core/hooks/tests/run-board-gate-tests.sh` exercises `core/hooks/board-gate.sh`
as a real subprocess against synthetic git repos and JSON tool-call
payloads (`run`/`runb` helpers; `want allow|deny` maps to exit 0/2).

Run it directly, no setup required:

    bash core/hooks/tests/run-board-gate-tests.sh

Covers R1 (docs/ layout), R2 (canonical contract), R3 (role required),
R4 (branch matches issue/role), and R5 (reports/ ownership, including
the role's own bare record directory for Bash `mkdir`/`rm`, and the
foreign-role denial).
