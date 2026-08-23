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

echo; echo "=== scope gate (warrant) ==="
/bin/bash "$here/run-scope-gate-tests.sh" | tail -2 || rc=1

echo; echo "=== approval gate ==="
/bin/bash "$here/run-approval-gate-tests.sh" | tail -2 || rc=1

echo; echo "=== gh guard ==="
/bin/bash "$here/run-gh-guard-tests.sh" | tail -2 || rc=1

echo; echo "=== role-agnostic gates (trailer/record-fields/handbook-trigger) ==="
/bin/bash "$here/run-role-gates-tests.sh" | tail -2 || rc=1

echo; echo "=== facet-keyword gate ==="
/bin/bash "$here/run-facet-keyword-gate-tests.sh" | tail -2 || rc=1

echo; echo "=== ordering-norm gate ==="
/bin/bash "$here/run-ordering-norm-gate-tests.sh" | tail -2 || rc=1

echo; echo "=== citation gate ==="
/bin/bash "$here/run-citation-gate-tests.sh" | tail -2 || rc=1

echo; echo "=== record-shape gate (issue-263 fold) ==="
/bin/bash "$here/run-record-shape-gate-tests.sh" | tail -2 || rc=1

echo; echo "=== survey-order gate (issue-271 role-aware path) ==="
/bin/bash "$here/run-survey-order-gate-tests.sh" | tail -2 || rc=1

echo; echo "=== stub-check canon combination forms ==="
/bin/bash "$here/run-stub-canon-forms-tests.sh" | tail -2 || rc=1

echo; echo "=== compliance-check hooks.json scan scope ==="
/bin/bash "$here/run-compliance-scan-scope-tests.sh" | tail -2 || rc=1

echo; echo "=== compliance-check --canon-duplication content-hash ==="
/bin/bash "$here/run-canon-duplication-content-tests.sh" | tail -2 || rc=1

echo; echo "=== terse (sibling plugin) ==="
/bin/bash "$here/../../../terse/hooks/tests/parse-check.sh" || rc=1

echo; echo "=== freelunch (sibling plugin) ==="
/bin/bash "$here/../../../freelunch/hooks/tests/parse-check.sh" || rc=1

echo; echo "=== freelunch observe.sh enforcement (sibling plugin) ==="
/bin/bash "$here/../../../freelunch/hooks/tests/run-observe-tests.sh" | tail -2 || rc=1

echo; echo "=== scout (sibling plugin) ==="
/bin/bash "$here/../../../scout/hooks/tests/parse-check.sh" || rc=1

echo; [ "$rc" = 0 ] && echo "ALL OK" || echo "FAILURES ABOVE"
exit "$rc"
