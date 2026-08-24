---
proposal: none — contract v3 s19a build-now bypass (CORE_BUILD_NOW=1), no phase-1 proposal round
---

# Hunt record — issue-295-approval-gate-observer-exemption

## before-landing — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — the observer-role closed-issue exemption keys off GitHub's stateReason "COMPLETED", but GitHub sets that exact same reason when a human closes the issue via "Close as completed" as an explicit revocation act, not only when a bot auto-closes it via a merged PR's Closes trailer — so a human's deliberate close-to-revoke silently fails to block execution-observation/conformance-review if any standing PR-review APPROVED or matching issue comment already exists, even though the gate's own header (lines 27-29, 251-258) states the closed-issue precondition makes "the contract's revocation-by-closing guarantee mechanical... regardless of any standing PR review or APPROVE comment."
Kind: design-error
Seed: core/hooks/approval-gate.sh (OBSERVER_ROLES / observer_role_on_completed_close, lines ~284-298) + core/hooks/tests/run-approval-gate-tests.sh
cap_seconds: 180
tier: full (gates-or-hooks-path-touched)
diff_stat_lines: ~35 (approval-gate.sh) + test file additions
started_at: 2026-08-24T09:20:00Z
ended_at: 2026-08-24T09:33:00Z

### Reproduce
Two runs against the real hook (not a mocked unit), same stubbed `gh` reporting the issue CLOSED with stateReason COMPLETED and one standing PR review APPROVED from a listed approver (jw-human) — the exact shape GitHub also produces when a human clicks "Close as completed" on the issue page as a deliberate stop, indistinguishable from a bot's Closes-trailer auto-close via `gh issue view --json state,stateReason`. `CORE_BUILD_NOW` must be explicitly unset (`env -u CORE_BUILD_NOW`) since this session's own env otherwise short-circuits the whole gate via the unrelated build-now bypass.

```
GATE=core/hooks/approval-gate.sh
PLUGIN_ROOT=core
td=$(mktemp -d); git init -q "$td"
git -C "$td" remote add origin git@github.com:example/probe.git
git -C "$td" checkout -q -b issue-42/execution-observation
mkdir -p "$td/docs/specs" "$td/stub"
printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
cat > "$td/stub/gh" <<'SCRIPT'
#!/bin/sh
case "$1" in
  issue) printf '%s' '{"state":"CLOSED","comments":[],"stateReason":"COMPLETED"}' ;;
  pr)    printf '%s' '{"reviews":[{"author":{"login":"jw-human"},"state":"APPROVED"}]}' ;;
esac
SCRIPT
chmod +x "$td/stub/gh"
payload='{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"'"$td"'"}'
printf '%s' "$payload" | env -u CORE_BUILD_NOW CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
  CLAUDE_ROLE=execution-observation CORE_GH="$td/stub/gh" /bin/bash "$GATE"
echo "observer EXIT: $?"

# control: same closed/COMPLETED + same standing PR review, non-observer role
git -C "$td" checkout -q -b issue-42/coding
printf '%s' "$payload" | env -u CORE_BUILD_NOW CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
  CLAUDE_ROLE=coding CORE_GH="$td/stub/gh" /bin/bash "$GATE"
echo "control EXIT: $?"
rm -rf "$td"
```

### Observed
```
observer EXIT: 0
control EXIT: 2
approval-gate: issue #42 is not open (state: CLOSED, reason: COMPLETED) — a closed issue's board is not live for any role, regardless of any standing PR review or APPROVE comment. (contract v3 s19)
```
The observer-role session is allowed to write to `src/app.py` on a CLOSED/COMPLETED issue purely because a PR review that could have been posted at any earlier time (before the human closed the issue to revoke) is still on record — the same precondition the control run correctly treats as an unconditional, "regardless of any standing PR review" deny.

### Expected
The gate's own stated guarantee (approval-gate.sh lines 251-258: "a closed issue denies unconditionally regardless of any standing PR review or standing APPROVE comment... this is what makes the contract's revocation-by-closing guarantee mechanical rather than prose") should hold for every role, including the two observer roles, whenever a human closes the issue to stop work — but "Close as completed" and "auto-closed via a merged PR's Closes trailer" are the same stateReason in GitHub's API, so the exemption's discriminator cannot actually tell a human's deliberate revocation-by-closing apart from the merge side effect it was built to see through. The exemption needs an input GitHub actually maintains for that distinction (e.g. whether the closing event is linked to a merged PR, via timeline/closedByPullRequestsReferences, not stateReason alone) or it silently defeats revocation-by-closing for these two roles whenever the closer happened to pick (or GitHub defaulted to) "Completed" over "Not planned".

### Resolved
Replaced the stateReason-only discriminator with the exact signal this finding asked for: `observer_role_on_implementation_merge_close` now requires a MERGED pull request, on the issue's own `issue-<n>/implementation` branch, present in `closedByPullRequestsReferences` — checked via one extra `gh pr view <number> --json headRefName,state` call per candidate closer. `stateReason` is no longer read for this decision at all (still interpolated, unchanged, into the plain deny message below). Verified against real GitHub data in this repo: issues #288/#290 (still closed, never reopened) each show exactly the merged `issue-<n>/implementation` PR that closed them in `closedByPullRequestsReferences`; issue #292 (reopened after this issue's own live workaround) shows only its still-open `execution-observation` PR, not the already-merged/consumed implementation PR — matching the "already-fired keyword doesn't reappear" semantics this fix relies on. New regression test `observer-completed-close-no-merge-closer` reproduces this finding's exact repro shape (stateReason COMPLETED + standing PR-review APPROVED, no merged-implementation-branch closer) and asserts deny; `observer-completed-close-with-comment`/`-conformance-review` assert the legitimate merge-close shape still allows. Full suite: `env -u CORE_BUILD_NOW bash core/hooks/tests/run-approval-gate-tests.sh` — 66 passed, 0 failed.
