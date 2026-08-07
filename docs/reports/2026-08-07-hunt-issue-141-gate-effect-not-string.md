---
proposal: docs/issue-141/proposals/issue-141-gate-effect-not-string.md
---

# Hunt record — issue-141-gate-effect-not-string

## before-landing — stance: assume this guard goes silent when its own input is malformed — make it go silent

Verdict: FINDING — handbook-trigger-gate.sh's `git add` staged-set projection filters out any pathspec token that starts with `-`, which drops both the `--` end-of-options separator AND any real filename beginning with `-` (e.g. `-setup.sh`); when both are dropped, `pathspecs` is empty, `git add --dry-run` is never even invoked, and the operational file is silently absent from the projected staged set — the gate exits 0 (allow) on a commit that really does introduce an unhandbooked operational surface.
Kind: silent-failure
Seed: core/hooks/handbook-trigger-gate.sh (git add segment-splitting loop, lines ~105-138 of the diff)
cap_seconds: 180
tier: default
diff_stat_lines: 290 (67 handbook-trigger-gate.sh, 262 trailer-gate.sh net of diff --stat)
started_at: 2026-08-07T12:30:00+09:00
ended_at: 2026-08-07T13:05:00+09:00

### Reproduce

Scratch repo with a dash-prefixed run/setup script, not yet staged:

    git init -q "$SCRATCH"
    git -C "$SCRATCH" config user.email a@a.com
    git -C "$SCRATCH" config user.name a
    printf '#!/bin/sh\necho setup\n' > "$SCRATCH/-setup.sh"

Payload: a PreToolUse Bash call that stages the dash-named script and commits
in one compound command:

    tool_input.command = "git add -- -setup.sh && git commit -m 'add setup script'"

    echo '{"tool_name":"Bash","tool_input":{"command":"git add -- -setup.sh && git commit -m \x27add setup script\x27"}}' \
      | (cd "$SCRATCH" && CLAUDE_ROLE=implementation CLAUDE_PROJECT_DIR="$SCRATCH" \
         bash /home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-141-implementation/core/hooks/handbook-trigger-gate.sh)
    echo "EXIT=$?"

Control: same script content staged under an ordinary filename (`setup.sh`,
no leading dash) via `git add -- setup.sh && git commit -m '...'` correctly
denies with exit 2 and the §21 message — confirming the OP_PATTERNS match and
the staged-set read both work; only the dash-prefixed name bypasses.

Also verified directly, outside the gate, that real git stages the file
despite the leading dash:

    git -C "$SCRATCH" add --dry-run -- -setup.sh
    # -> add '-setup.sh'

And that the gate's own `shlex`-based filter drops it before it ever calls
`git add --dry-run`:

    python3 -c "
    import shlex
    argstr = ' -- -setup.sh'
    toks = shlex.split(argstr)
    pathspecs = [t for t in toks if not t.startswith('-')]
    print(toks, pathspecs)
    "
    # -> ['--', '-setup.sh'] []

### Observed

    EXIT=0

No stderr, no denial. `handbook-trigger-gate.sh` allows the commit.

Root cause: `pathspecs = [t for t in add_toks if not t.startswith("-")]`
(handbook-trigger-gate.sh) treats every `shlex`-split token starting with `-`
as a flag to discard, including the `--` end-of-options marker itself and any
literal pathspec that happens to start with `-`. Because `pathspecs` ends up
empty, the code hits `if not pathspecs: continue` and never even invokes
`git add --dry-run` for this segment — the file is silently dropped from the
judged `staged` set rather than being resolved (or explicitly denied as
unresolvable, the way `$`/backtick pathspecs already are one branch above).

### Expected

The gate should either preserve pathspec tokens that follow an explicit `--`
separator (git's own convention for "everything after this is a path, not a
flag") or otherwise still run `git add --dry-run --` with the raw argument
list so real git resolves what is and isn't a path, instead of filtering
every `-`-prefixed token out before the dry-run is invoked. As written, any
operational file whose name happens to start with `-`, or that is staged
via `git add -- <path>`, is invisible to the §21 projection and the commit
is silently allowed — the same class of hole the adjacent `$`/backtick check
was written to close, left open for this shape.
