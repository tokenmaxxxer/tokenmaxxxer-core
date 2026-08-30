---
proposal: none — build-now bypass (contract v3 s19a, CORE_BUILD_NOW=1 set by spawner); round 6 correction on PR #367's branch per operator CHANGES comment, no phase-1 proposal file this round
---

# Hunt record — secure-coding-input-validation-injection-defense-bcd7fd6a

## before-landing — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — combined short-flag perl invocations (`perl -wc`, `perl -cw`, `perl -Ic`, ...) still perform the BEGIN-block write round 6 set out to deny, and both gates let at least one combined-flag spelling through by real subprocess execution
Kind: silent-failure
Seed: uncommitted diff in core/hooks/board-gate.sh (INLINE_FLAG_HEADS `"perl": ("-e","-c")`) and warrant/hooks/lib/scope-gate.py (UNANALYZABLE_WRITE_SHAPE new perl `-c` alternative `r"|(?:^|\s)perl\b[^\n|;&]*\s-[A-Za-z]*c(?:\s|=|$)"`)
cap_seconds: 180
tier: full (gates/hooks paths touched)
diff_stat_lines: ~40 (2 files, comment-heavy)
started_at: 2026-08-30T11:40:00Z
ended_at: 2026-08-30T11:58:00Z

### Reproduce

1. Live-execution proof that `perl -wc` still runs a BEGIN-block write (identical vector round 6 exists to close for bare `-c`):
```
td=$(mktemp -d) && cd "$td"
cat > pwn.pl << 'PERLEOF'
BEGIN { open(my $fh, '>', 'pwned.txt') or die $!; print $fh "owned via perl -wc BEGIN block\n"; close $fh; }
print "unreachable due to -c but BEGIN already ran\n";
PERLEOF
perl -wc pwn.pl; echo "exit=$?"; cat pwned.txt
```

2. board-gate.sh, real subprocess, mirroring the repo's own `run-board-gate-tests.sh` harness (`round6-perl-c-denied` case, just with a combined flag):
```
GATE=core/hooks/board-gate.sh
td=$(mktemp -d)
git init -q "$td"; git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
git -C "$td" checkout -q -b issue-3/qa
mkdir -p "$td/docs/specs" "$td/docs/issue-3/reports"
printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
board="$td/docs/issue-3"
tinput=$(python3 -c "import json,sys;print(json.dumps({'tool_name':'Bash','tool_input':{'command':sys.argv[1]},'cwd':sys.argv[2]}))" "cd $board && perl -wc reports/script.pl" "$td")
echo "$tinput" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$(pwd)" CLAUDE_SKILL=qa /bin/bash "$GATE"
echo "rc=$?"
```

3. scope-gate.sh (scope-gate.py), real subprocess, mirroring `run-scope-gate-tests.sh`'s `round6-perl-c-denied` case with a combined flag:
```
GATE=warrant/hooks/scope-gate.sh
td=$(mktemp -d); git init -q "$td"; mkdir -p "$td/docs/proposals"
printf -- '---\nstatus: approved\nfiles:\n  - src/app.py\n---\nbody\n' > "$td/docs/proposals/2026-08-08-probe.md"
tinput=$(python3 -c "import json,sys;print(json.dumps({'tool_name':'Bash','tool_input':{'command':sys.argv[1]},'cwd':sys.argv[2]}))" "perl -cw some/script.pl" "$td")
echo "$tinput" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="core/hooks/.." /bin/bash "$GATE"
echo "rc=$?"
```

### Observed
- Step 1: `perl -wc pwn.pl` prints `pwn.pl syntax OK` (exit 0, does NOT run the main body) but `pwned.txt` is created on disk containing "owned via perl -wc BEGIN block" — the BEGIN block ran anyway, exactly the vector round 6's commit message says perl's `-c` cannot be trusted for.
- Step 2: board-gate.sh's `_is_unanalyzable_write_shape` returns `allow` (rc=0) for `perl -wc reports/script.pl`, and likewise for `perl -cw ...` and `perl -Ic ...`, while the bare `perl -c reports/script.pl` case (same working tree, same harness) correctly returns `deny` (rc=2). Root cause: `INLINE_FLAG_HEADS[head]` membership at board-gate.sh line ~638 is `any(w in INLINE_FLAG_HEADS[head] for w in gate_trailing_words(stripped))` — an exact string-equality check against the literal tuple `("-e", "-c")`. The trailing word for `perl -wc script.pl` is the single token `-wc`, which is not string-equal to `-c` or `-e`, so the branch never fires for ANY combined short-flag spelling that bundles `c` with another letter, regardless of order.
- Step 3: scope-gate.py's new perl alternative `r"(?:^|\s)perl\b[^\n|;&]*\s-[A-Za-z]*c(?:\s|=|$)"` requires the letter immediately after the flag run to be end-of-token — it matches `-wc` (c is the last letter, followed by space) but NOT `-cw` (c is not the last letter, followed by `w` not `\s|=|$`). Real subprocess: `perl -cw some/script.pl` -> allow (rc=0); `perl -wc some/script.pl` -> deny (rc=2); bare `perl -c` -> deny (rc=2). So scope-gate.py catches `-wc` but misses `-cw`, and board-gate.sh misses both — the two gates are neither internally complete nor mutually consistent for perl's give-back removal.

### Expected
Every `perl -c`/`perl -e` invocation regardless of flag bundling/ordering (`-c`, `-e`, `-wc`, `-cw`, `-Ic`, `-cIe`, etc.) should be denied identically by both board-gate.sh and scope-gate.py, since perl's `-c` was just proven (by this same round's own live-execution methodology) to still execute BEGIN/UNITCHECK/CHECK blocks regardless of which other letters ride along in the same flag bundle. Instead board-gate.sh's exact-string INLINE_FLAG_HEADS membership check and scope-gate.py's end-anchored `-[A-Za-z]*c(?:\s|=|$)` alternative each admit at least one common flag-bundling spelling as a silent "allow", reopening the exact write-shape round 6 says it closed.

### Addendum — disposition (verified by the round 6 session, not the hunter)

The finding is real and independently reproduced (`bash /tmp/probe_bundled_flags.sh`, a standalone harness using the repo's own `run-board-gate-tests.sh` temp-repo pattern). But it is pre-existing and NOT specific to perl or to this round's change:

```
derived: git show origin/main:core/hooks/board-gate.sh | grep -n "INLINE_FLAG_WORDS"
529:INTERPRETER_HEADS = (...)
531:INLINE_FLAG_WORDS = ("-c", "-e")
588:        if any(w in INLINE_FLAG_WORDS for w in gate_lib.gate_trailing_words(stripped)):
```

`origin/main` (before round 5 ever existed) already used the identical exact-string-membership check against a flat `("-c", "-e")` tuple, applied uniformly to every one of the 10 interpreter heads. Re-running the same bundled-flag probe against that check confirms the gap predates rounds 5/6 and hits every head, not just perl:

```
perl -we (bundled, should deny like -e)   => allow   (bare `perl -e` already denies)
bash -xc (bundled -c)                     => allow   (bare `bash -c` already denies)
python3 -Wc (bundled -c)                  => allow   (bare `python3 -c` already denies)
ruby -wc (bundled -c)                     => allow
```

So this is a systemic completeness gap in the flag-word-matching mechanism itself (exact-token membership, no per-character bundle scan), present since before issue-233 started and orthogonal to the single-token-expansion class the issue's acceptance criteria named (`${...}`/`$(...)`/backtick-reached heads). Round 6's scope was narrowly "drop perl from the give-back list, re-derive the rest by execution" — adding `-c` to perl's tuple / the perl regex alternative makes perl's bare-`-c` detection exactly as complete (and exactly as incomplete against bundling) as every other head's existing `-c`/`-e` detection already was. It does not make anything WORSE than origin/main, and fixing flag-bundle detection properly means redesigning the match for all 10 heads on both gates — a materially larger, separate change than this round's mandate ("do not widen the diff"). Not fixed here; left as a disclosed, confirmed follow-up (bundled short-flag detection is incomplete for every interpreter head on both gates, not only perl) for a future issue.
