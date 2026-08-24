---
proposal: docs/issue-290/reports/implementation.md
---

# Hunt record — bash-matcher-record-bypass

## after-proposal — stance 1: assume the gate this issue is about is still bypassable in some way the new tests don't catch

Verdict: FINDING — approval-gate.sh's Bash candidate-path extraction is a static regex scan of the literal command text; splitting the phase-2 record path across shell variables before the redirect (`d="docs"; i="issue-7"; f="reports/coding.md"; printf "pwned" > "$d/$i/$f"`) means no single token in the command text ever contains the contiguous substring `docs/issue-<n>/`, so CODE_RE/ISSUE_RE never match, `candidates` stays empty, and the gate allows the write with exit 0 — no approval required, no denial message, nothing logged. The identical literal-path command (no variables) correctly denies, confirming the variable-splitting is what defeats it. This generalizes: any Bash construct that assembles the target path outside the literal string handed to the redirect (command substitution, `printf -v`, `read`, `eval`, sourcing a var from a prior line, etc.) evades this gate the same way, because the gate never actually resolves what the shell will write to — it only pattern-matches the raw text.
Kind: silent-failure
Seed: task prompt — probe approval-gate.sh's Bash-command candidate-path extraction for a gap the issue-290 regression tests (bash-heredoc-record-before-approve / bash-heredoc-record-after-approve) don't cover
cap_seconds: unspecified (not given by dispatcher in this invocation)
tier: unspecified (not given by dispatcher in this invocation)
diff_stat_lines: unspecified (not given by dispatcher in this invocation) — session's only change was the two new tests in core/hooks/tests/run-approval-gate-tests.sh described in the task prompt
started_at: 2026-08-24T08:10:00Z
ended_at: 2026-08-24T08:26:00Z

### Reproduce
Ran directly against `core/hooks/approval-gate.sh` (same style as the existing test harness in `core/hooks/tests/run-approval-gate-tests.sh`: a fresh git repo with `origin` remote, branch `issue-7/coding`, `docs/specs/approvers.md` listing `jw-human`, a stub `gh` returning issue state OPEN with no comments and "no pull requests found" for `pr view` — i.e. exactly the `nopr` fixture, no approval anywhere), with `CORE_BUILD_NOW` and `CORE_CHECKPOINT` explicitly unset:

```
# control: literal path, no variables — correctly denied
cmd='printf "pwned" > "docs/issue-7/reports/coding.md"'
tinput="$(python3 -c "import json,sys; print(json.dumps({'command': sys.argv[1]}))" "$cmd")"
payload="$(printf '{"tool_name":"Bash","tool_input":%s,"cwd":"%s"}' "$tinput" "$td")"
printf '%s' "$payload" | env -u CORE_BUILD_NOW -u CORE_CHECKPOINT \
  CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
  CLAUDE_ROLE=coding CORE_GH="$td/stub/gh" /bin/bash core/hooks/approval-gate.sh
echo $?   # -> 2 (deny), with the expected "neither the PR ... nor issue #7 carries an approval" message

# exploit: same target path, split across shell variables — wrongly allowed
cmd='d="docs"; i="issue-7"; f="reports/coding.md"; printf "pwned" > "$d/$i/$f"'
tinput="$(python3 -c "import json,sys; print(json.dumps({'command': sys.argv[1]}))" "$cmd")"
payload="$(printf '{"tool_name":"Bash","tool_input":%s,"cwd":"%s"}' "$tinput" "$td")"
printf '%s' "$payload" | env -u CORE_BUILD_NOW -u CORE_CHECKPOINT \
  CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
  CLAUDE_ROLE=coding CORE_GH="$td/stub/gh" /bin/bash core/hooks/approval-gate.sh
echo $?   # -> 0 (allow) — no stderr, no denial, no approval on record
```

### Observed
```
=== control-literal-quoted -> rc=2 (DENY) ===
approval-gate: neither the PR for issue-7/coding nor issue #7 carries an approval from a listed human approver (jw-human): no Approve review on an open PR, and no issue comment that is exactly 'APPROVE issue-7/coding'. Free-text comments are feedback, a bot's or agent's Approve is not a human's, and phase 2 waits for the human. (contract v3 s19)
=== split-vars -> rc=0 (ALLOW) ===
```
(second block has no stderr output at all — the shell being handed to the model's Bash tool would run `printf "pwned" > "$d/$i/$f"` unopposed against `docs/issue-7/reports/coding.md`, the exact phase-2 record path, with zero approval and zero denial message.)

Confirmed with a debug trace of the gate's own python body (`traceback.print_stack()` inserted at `allow()`) that the split-vars run does NOT take the CORE_BUILD_NOW bypass or any other legitimate early-allow branch — it falls through to `hits = [c for c in candidates if execution_surface(c)]` with `candidates == []` because none of the regex-extracted tokens (`d="docs"`, `i="issue-7"`, `f="reports/coding.md"`, `printf`, `pwned`, `"$d/$i/$f"`) contain the literal substring `docs/issue-<n>/` that ISSUE_RE requires, so `hits` is empty and the gate takes the `if not hits: allow()` early-exit meant for "phase-1 material or unrelated: not this gate's business".

### Expected
A Bash command that writes to the exact phase-2 record path `docs/issue-<n>/reports/<role>.md` should be denied when no Approve exists, regardless of whether the path literal is written inline or assembled via shell variables in the same command string — the same way the control case (and the new issue-290 heredoc tests) correctly deny it.
