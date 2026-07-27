#!/usr/bin/env bash
# Every check in this repository, in one command.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
rc=0

echo "=== bash 3.2 parse ==="
/bin/bash --version | head -1
for f in "$here"/../*.sh "$here"/*.sh; do
  [ -f "$f" ] || continue
  if /bin/bash -n "$f" 2>/dev/null; then
    printf 'ok    %s\n' "$(basename "$f")"
  else
    printf 'FAIL  %s\n' "$(basename "$f")"; /bin/bash -n "$f" 2>&1 | head -2; rc=1
  fi
done

echo; echo "=== deny-only ==="
/bin/bash "$here/deny-only-check.sh" || rc=1

echo; echo "=== consent lib ==="
python3 "$here/test_consent_lib.py" 2>&1 | tail -3 || rc=1

echo; echo "=== judge lib ==="
python3 "$here/test_judge_lib.py" 2>&1 | tail -3 || rc=1

echo; echo "=== mint ==="
/bin/bash "$here/run-mint-tests.sh" | tail -2 || rc=1

echo; echo "=== board gate ==="
/bin/bash "$here/run-board-gate-tests.sh" | tail -2 || rc=1

echo; [ "$rc" = 0 ] && echo "ALL OK" || echo "FAILURES ABOVE"
exit "$rc"
