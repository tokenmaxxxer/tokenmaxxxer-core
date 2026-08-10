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

## before-landing — stance 1: assume this change and another plugin's rule cancel each other — find the pair

Verdict: FINDING — a second approver's plain APPROVE review silently cancels a first approver's CHANGES_REQUESTED rejection finding in the same gate, in the same PR
Kind: composition
Seed: core/hooks/approval-gate.sh working-tree diff (REJECT/CHANGES_REQUESTED finding logic, design decision 2)
cap_seconds: 180
tier: size:>5-files
diff_stat_lines: 8 files, 162 insertions(+), 20 deletions(-) (working-tree diff)
started_at: 2026-08-10T10:54:38+09:00
ended_at: 2026-08-10T11:07:00+09:00

### Reproduce
Stub `gh pr view` to return two reviews on the same PR — one from an
approver who APPROVED, one from a different approver who requested
changes with a blocking rationale — then run approval-gate.sh directly:

```bash
cd /home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-189-implementation
td=$(mktemp -d "$TMPDIR/ag-repro-XXXX")
git init -q "$td"
git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
git -C "$td" checkout -q -b issue-7/coding
mkdir -p "$td/docs/specs" "$td/stub"
cp core/contract/role-handoff-contract.md "$td/docs/specs/role-handoff-contract.md"
printf -- '- jw-human\n- jw-human2\n' > "$td/docs/specs/approvers.md"
cat > "$td/stub/gh" <<'SCRIPT'
#!/bin/sh
case "$1" in
  issue) printf '%s' '{"state":"OPEN","comments":[]}' ;;
  pr) printf '%s' '{"reviews":[{"author":{"login":"jw-human"},"state":"APPROVED"},{"author":{"login":"jw-human2"},"state":"CHANGES_REQUESTED","body":"blocking security issue, do not merge"}]}' ;;
esac
SCRIPT
chmod +x "$td/stub/gh"
printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$(pwd)/core" \
        CLAUDE_ROLE=coding CORE_GH="$td/stub/gh" /bin/bash core/hooks/approval-gate.sh
echo "EXIT=$?"
rm -rf "$td"
```

### Observed
`EXIT=0` — the write is allowed with no output at all. approval-gate.sh
correctly builds `rejection_finding` from jw-human2's CHANGES_REQUESTED
review (lines 317-327 of the working-tree diff), but that finding is
only ever consulted inside `if not approved:` (lines 345-348). `approved
= pr_approved or comment_approved`, and `pr_approved` is computed as
`any(login in approvers and state == "APPROVED" for login, state in
last.items())` — an OR across *all* approvers on the PR, not scoped to
the approver who requested changes. jw-human's unrelated APPROVED review
sets `pr_approved = True`, so `approved` is True, the `if not approved:`
branch is skipped entirely, and jw-human2's blocking CHANGES_REQUESTED
finding — the exact contract §5 finding block design decision 2 was
built to surface — is silently discarded: never denied, never printed,
never logged anywhere.

### Expected
A blocking CHANGES_REQUESTED from any listed approver should either
block the write or at minimum surface the finding (per the gate's own
deny message: "issue-%s/%s was rejected, not merely unapproved"),
regardless of whether a different approver separately approved. As
written, the pre-existing "any approver approves -> pr_approved" OR
logic (correct on its own, for the pre-issue-189 single-signal world)
and the new per-review rejection_finding logic (also correct on its own)
cancel each other the moment both appear in the same PR's review list —
each is right alone and wrong together.
