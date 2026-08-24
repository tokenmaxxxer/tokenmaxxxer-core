---
issue: 290
role: implementation
loop_state: landed
upstream:
  - path: core/hooks/approval-gate.sh
    sha: same-commit
code_under_review: same-commit
type: test
breaking: false
verdict: pass
---

# issue-290 — implementation record

## What was done

Investigated the issue's claim ("approval-gate.sh's PreToolUse tool
matcher only covers Write|Edit|MultiEdit") against the current state of
this repo and found it already false: `core/hooks/hooks.json`'s
`PreToolUse` registration has used the union matcher `".*"` since the
gate's very first commit (`5cdf5ec`, 2026-07-28), and `approval-gate.sh`'s
own python body has handled `tool == "Bash"` — extracting candidate paths
from the command text via `CODE_RE`/`ISSUE_RE` token regex, independent
of any redirect/heredoc syntax — from that same first commit onward
(`git log -S'elif tool == "Bash"' -- core/hooks/approval-gate.sh` shows
one hit: `5cdf5ec`). Confirmed empirically: a Bash heredoc write
(`cat > docs/issue-290/reports/implementation.md <<'EOF' ... EOF`)
targeting this exact phase-2 record path, fed through both
`approval-gate.sh` directly and through the real
`pretooluse_dispatcher.py` entrypoint (issue #282/#283's single
dispatcher), is denied identically to the equivalent `Write` tool call
when no Approve exists.

The actual gap was the one the issue's own Acceptance section named
explicitly but the Fix section undersold: no regression test exercised
a Bash heredoc write against a `docs/issue-<n>/reports/<role>.md` path at
all — every existing Bash-tool test in
`core/hooks/tests/run-approval-gate-tests.sh` targeted `src/app.py`, and
every record-path test used the `Write` tool. Added the missing pair to
that suite, placed next to the existing Write-tool
`record-before-approve`/`record-after-approve` tests they mirror:

- `bash-heredoc-record-before-approve` — `cat > docs/issue-7/reports/coding.md <<EOF\nfoo\nEOF` with no PR/no approval → `deny`
- `bash-heredoc-record-after-approve` — same command, `human` PR-approval stub → `allow`

No change to `core/hooks/approval-gate.sh` or
`core/hooks/pretooluse_dispatcher.py` — the behavior the issue asked for
was already correct; this closes the untested-but-correct gap with a
locking regression test.

## Why

Extending already-correct matcher/extraction logic would be a no-op
change with no test to justify it; the issue's Acceptance criterion
("Add a regression test: a Bash heredoc write to
`docs/issue-<n>/reports/<role>.md` without a prior APPROVE comment is
denied, matching existing Write/Edit denial behavior") is satisfiable
and valuable on its own — it turns "denies today, empirically" into
"denies, and a future change that breaks this silently fails CI." Adding
an unneeded matcher change on top would be scope creep against a
behavior that was never actually broken.

## Upstream basis

- Issue #290 body (Fix / Acceptance sections).
- `core/hooks/approval-gate.sh` and `core/hooks/pretooluse_dispatcher.py`
  at `7d8ff3a` (HEAD of `issue-290/implementation` at session start,
  same commit this session's diff lands on top of).
- `core/hooks/tests/run-approval-gate-tests.sh`'s existing
  `record-before-approve`/`record-after-approve` (Write-tool) and
  `bash-redirect-src`/`bash-cd-then-write-src` (Bash-tool, non-record-path)
  tests, whose pattern the two new tests follow.

## Open findings

A background `warrant-hunter` (stance: assume the gate this issue is
about is still bypassable in a way the new tests don't catch) ran before
landing and returned one FINDING, out of this issue's frozen scope —
see
`docs/issue-290/reports/implementation/2026-08-24-hunt-bash-matcher-record-bypass.md`:
`approval-gate.sh`'s Bash candidate-path extraction is a static regex
scan of the raw command *text*, not a real shell-semantics resolution —
splitting the target path across shell variables before the redirect
(e.g. `d="docs"; i="issue-7"; f="reports/coding.md"; printf x >
"$d/$i/$f"`) means no single token contains the contiguous
`docs/issue-<n>/` substring `ISSUE_RE` requires, so `candidates` stays
empty and the write is silently allowed (`rc=0`, no stderr) where the
identical literal-path command correctly denies (`rc=2`). Reproduced
directly against `approval-gate.sh` with `CORE_BUILD_NOW`/
`CORE_CHECKPOINT` unset and no approval anywhere (see the hunt record
for the exact commands and output). This generalizes past heredocs and
past record paths to any Bash write anywhere this gate (or any other
Bash-command-text gate in this repo, e.g. `gh-guard.sh`, `board-gate.sh`)
adjudicates by pattern-matching rather than resolving: command
substitution, `printf -v`, `read`, `eval`, or a var set on a prior line
all evade the same way.
Resolution path: not fixed in this session — it is a different, broader
bug than issue #290 named (which was specifically the heredoc/matcher
claim, already shown above to be a non-issue) and fixing it correctly
needs either real shell-token resolution (a materially larger design
change, likely spanning every Bash-command-text gate in
`core/hooks/`, not just this one) or an explicit accepted-limitation
note in `docs/handbooks/gate-house-standard.md`. Needs a new issue filed
by a human/orchestrator against this repo, the same way issue #290 itself
originated from a hunt finding surfaced in another repo's PR review.

## What did not work

None — the fix scope narrowed from "extend the matcher" to "add the
missing test" after empirical verification showed the matcher already
covers this case; no attempted approach was discarded.

## Skill verdicts

skill-verdict: implementation-blueprint — not-applicable: single-file
test addition mirroring an existing test pattern, no multi-module
structure decision (blueprint's own classify step excludes this)
skill-verdict: implementation-complexity-coupling-management —
not-applicable: no coupling/cohesion metric, accessor chain, or
cross-module import direction involved
skill-verdict: implementation-design-pattern-selection —
not-applicable: no GoF-pattern introduction/removal decision involved
skill-verdict: implementation-performance-data-structure-choice —
not-applicable: no data structure, algorithm, or communication-scheme
choice involved
other mounted skills: not triggered

## Next steps

None — loop_state is terminal (`landed`). Acceptance evidence below.

## Acceptance evidence

Targeted approval-gate suite, clean environment (`CORE_BUILD_NOW`
unset — this session's own ambient `CORE_BUILD_NOW=1`, set by the
spawner for this delivery-only session, leaks into two unrelated
existing tests' subprocess `env` calls; this is the same pre-existing,
unrelated artifact issue-288's own record already documented and traces
to none of this diff):
```
$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-approval-gate-tests.sh
...
ok     bash-heredoc-record-before-approve deny
ok     bash-heredoc-record-after-approve  allow
...
== 60 passed, 0 failed ==
```

Full repo test suite (`core/hooks/tests/run-all.sh`), same clean
environment:
```
$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-all.sh
...
=== approval gate ===
== 60 passed, 0 failed ==
...
=== PreToolUse dispatcher equivalence (issue #282 Part 2) ===
dispatcher-equivalence: 25 passed, 0 failed
...
$ echo EXIT=$?
EXIT=0
```

Direct manual reproduction, dispatcher entrypoint, before writing any
test (recorded here since it's what established the diagnosis above):
```
$ echo '{"tool_name":"Bash","tool_input":{"command":"cat > docs/issue-290/reports/implementation.md <<'"'"'EOF'"'"'\nfoo\nEOF"},"cwd":"."}' \
    | env -u CORE_BUILD_NOW CLAUDE_ROLE=implementation CLAUDE_PROJECT_DIR="$PWD" python3 core/hooks/pretooluse_dispatcher.py
approval-gate: neither the PR for issue-290/implementation nor issue #290 carries an approval from a listed human approver (jiwonjung94, jjongkwann): ...
$ echo exit=$?
exit=2
```
