---
proposal: docs/issue-187/proposals/2026-08-08-hook-content-inspect-and-board-gate-comment-fix.md
---

# Hunt record — hook-content-inspect-and-board-gate-comment-fix

## after-proposal — stance 1: assume this change and another plugin's rule cancel each other — find the pair

Verdict: NO FINDING
Seed: docs/issue-187/proposals/2026-08-08-hook-content-inspect-and-board-gate-comment-fix.md (proposal-only, no code yet); read warrant/hooks/scope-gate.sh, core/hooks/board-gate.sh, core/hooks/hooks.json, warrant/hooks/hooks.json, core/hooks/lib/gate-lib.sh, core/hooks/{approval-gate,record-fields-gate,trailer-gate,gh-guard,handbook-trigger-gate}.sh, core/hooks/tests/{run-canon-duplication-content-tests.sh,canon-manifest.txt,compliance-check.sh}
cap_seconds: 120
tier: default
diff_stat_lines: 0 (proposal doc only, no diff yet)
started_at: 2026-08-08T00:00:00Z
ended_at: 2026-08-08T00:03:00Z

Checked whether any sibling gate has a rule targeting `hooks/[^/]+\.sh$` writes
or board-write string extraction that the two planned changes could cancel with.
Confirmed gate_deny (exit 2) / gate_allow (exit 0) semantics in gate-lib.sh:
Claude Code composes PreToolUse hooks additively — any single hook's deny
blocks the call; an allow from one plugin's gate cannot override another
plugin's deny. So scope-gate.sh's proposed content-inspect (unconditional
deny -> conditional deny) cannot be "cancelled" by board-gate.sh's narrower
Bash write-candidate window, since they gate disjoint tool-call shapes
(scope-gate: Write/Edit/MultiEdit path checks in warrant plugin; board-gate:
Bash command-text scanning in core plugin) and neither references the other's
regex, state, or manifest. Grepped core/hooks/*.sh and warrant/hooks/*.sh for
any other unconditional deny/allow keyed on `hooks/[^/]+\.sh$` or on
board-write window extraction — none found (only comments/tests referencing
scope-gate.sh for the unrelated canon-duplication byte-identity check from
issue-185, which is a separate compliance-check.sh script, not a PreToolUse
hook, and is unaffected by either planned change). No reproducible
cancellation found; the two changes target independent hooks in independent
plugins with independent trigger conditions.

## before-landing — stance 1: assume this change and another plugin's rule cancel each other — find the pair

Verdict: FINDING — scope-gate.sh's new denylist pattern for "disabling a gate's fail-closed trap" (`trap - EXIT`) matches the standard fail-closed early-exit idiom used by every sibling gate hook (gh-guard.sh, board-gate.sh, and scope-gate.sh itself all use `{ trap - EXIT; exit 0; }` as their normal kill-switch / early-success-exit), so a legitimate hooks/*.sh edit whose content happens to contain that shared idiom (e.g. an edit that reproduces or extends another gate's actual shipped code) is refused as unsafe, even though it is the exact sanctioned pattern the whole hooks/lib/gate-lib.sh fail-closed convention depends on. The carve-out was built to remove the #476 scratchpad+mv workaround for legitimate hook edits, but collides with the idiom that legitimate hook edits normally contain.
Kind: design-error
Seed: warrant/hooks/scope-gate.sh UNSAFE_HOOK_CONTENT denylist (uncommitted working-tree diff), compared against core/hooks/gh-guard.sh and core/hooks/board-gate.sh which both use `trap - EXIT; exit 0` as their standard early-exit idiom
cap_seconds: 120
tier: default
diff_stat_lines: ~116 (warrant/hooks/scope-gate.sh +70, core/hooks/board-gate.sh +46, per git diff -- warrant/hooks/scope-gate.sh core/hooks/board-gate.sh)
started_at: 2026-08-08T00:06:00Z
ended_at: 2026-08-08T00:11:00Z

### Reproduce
Run (from repo root):

    GATE="warrant/hooks/scope-gate.sh"
    td=$(mktemp -d)
    git init -q "$td"
    mkdir -p "$td/docs/proposals"
    printf -- '---\nstatus: approved\nfiles:\n  - src/app.py\n---\nbody\n' > "$td/docs/proposals/2026-08-08-probe.md"
    python3 -c "
    import json
    content = open('core/hooks/gh-guard.sh').read()
    payload = json.dumps({'tool_name':'Write','tool_input':{'file_path':'some/hooks/gh-guard.sh','content':content},'cwd':'$td'})
    open('$td/payload.json','w').write(payload)
    "
    env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$PWD/core" \
        bash "$GATE" < "$td/payload.json"
    echo "rc=$?"

### Observed
    rc=2
    warrant: refused -- `some/hooks/gh-guard.sh` is a hook-script edit outside the write set frozen by docs/proposals/2026-08-08-probe.md, and its proposed content matched a denylist pattern (disabling a gate's fail-closed trap). Hook edits are content-inspected, not blanket-denied, but unsafe content still refuses.

### Expected
The content being written is byte-for-byte the actual, currently-shipped, benign source of core/hooks/gh-guard.sh -- a legitimate hook-script edit that should be allowed (it contains no malicious content, only the project-wide `trap - EXIT; exit 0` early-success-exit idiom that gh-guard.sh, board-gate.sh, and scope-gate.sh itself all use). Because that idiom is the standard convention for a gate's own fail-closed exit path, the denylist collides with ordinary hook maintenance across every plugin's gate scripts, not just with an attempt to disarm the trap on someone else's live invocation -- the exact class of edit the carve-out was meant to unblock.
