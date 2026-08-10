---
proposal: docs/issue-189/proposals/2026-08-10-implement-rejection-withdrawal-lifecycle.md
---

# Hunt record — implement-rejection-withdrawal-lifecycle

## after-proposal — stance 2: assume this guard goes silent when its own input is malformed — find the state nothing maintains

Verdict: FINDING — the plan's REJECT/CHANGES_REQUESTED detection depends on `last[login]`, a dict that `core/hooks/approval-gate.sh` only ever creates inside `if pr_out.returncode == 0:` (lines 267-284); when no PR is open — the file's own comments (lines 34-35, 249-250, 285-286) call this an "expected gap ... not itself a denial" — `last` is never assigned, so code reading `last[login]` for the new rejection path will raise `NameError`, which the script's EXIT trap (line 40) converts into a fail-closed deny of the *whole* gate evaluation, including the still-valid comment-based `APPROVE` path that is explicitly designed to work with no PR open. The plan text (step 2 of "What will be done") never mentions guarding for this case; it just says "Use the existing `last[login]` state map."
Kind: design-error
Seed: docs/issue-189/proposals/2026-08-10-implement-rejection-withdrawal-lifecycle.md step 2, against core/hooks/approval-gate.sh lines 260-309
cap_seconds: 120
tier: default
diff_stat_lines: 213
started_at: 2026-08-10T10:41:14+09:00
ended_at: 2026-08-10T10:48:00+09:00

### Reproduce
```
python3 - <<'PY'
pr_out_returncode = 1  # simulate "no PR open" (gh pr view failed) — the
                        # file's own comment calls this an "expected gap"
if pr_out_returncode == 0:
    last = {}
    last['x'] = 'APPROVED'
    pr_approved = True
# the plan's step 2 reads last[login] here, outside the if-block, to
# detect CHANGES_REQUESTED / DISMISSED for the new reject-finding path
rejecting = any(v == "CHANGES_REQUESTED" for v in last.values())
PY
```

### Observed
```
NameError: name 'last' is not defined
```
Wrapped in the real script this becomes an uncaught python3 exit (rc=1),
caught by `trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT`
at line 40, turning into a blanket deny (exit 2) of the entire gate
evaluation for that invocation — including a legitimate `APPROVE
issue-<n>/<role>` issue comment, which the current code (lines 34-35,
285-286) explicitly says must still work with no PR open.

### Expected
The plan should guard the new CHANGES_REQUESTED/DISMISSED read for the
"no PR open" case (e.g. initialize `last = {}` unconditionally, or scope
the reject-detection inside the same `if pr_out.returncode == 0:` block)
so that the comment-only approval path documented as working with no PR
open keeps working once the reject-detection code lands, instead of
every write during that window failing closed regardless of a valid
APPROVE comment.
