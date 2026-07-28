#!/usr/bin/env bash
# Every check in this repository, in one command.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
rc=0

echo "=== bash 3.2 parse ==="
/bin/bash "$here/parse-check.sh" || rc=1

echo; echo "=== deny-only ==="
/bin/bash "$here/deny-only-check.sh" || rc=1

echo; echo "=== board gate ==="
/bin/bash "$here/run-board-gate-tests.sh" | tail -2 || rc=1

echo; [ "$rc" = 0 ] && echo "ALL OK" || echo "FAILURES ABOVE"
exit "$rc"
