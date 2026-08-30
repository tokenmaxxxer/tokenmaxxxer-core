---
proposal: docs/issue-233/reports/adversarial-review-a814c155.md
---

# Hunt record — adversarial-review-a814c155

## before-landing — stance 0: assume board-gate.sh/scope-gate.py (PR #367) is bypassable — find the bypass

Verdict: FINDING — round 5's per-head narrowing gives back `perl -c` as
allow on the false premise that `-c` means "check syntax, do not run",
but Perl actually executes BEGIN/UNITCHECK/CHECK blocks (and `use`
statements) during a `-c` syntax check, so `perl -c reports/evil.pl` is
now an ALLOWED real write, where the identical command was DENIED on
origin/main before this PR.
Kind: composition
Seed: PR #367 diff (core/hooks/board-gate.sh INLINE_FLAG_HEADS narrowing;
`gh pr diff 367 --repo tokenmaxxxer/tokenmaxxxer-core`)
cap_seconds: unspecified (not given by dispatcher this round)
tier: default
diff_stat_lines: 551 (gh pr diff 367 total line count across all 6 files
touched)
started_at: 2026-08-30T01:15:00Z
ended_at: 2026-08-30T01:38:00Z

### Reproduce

Independent confirmation that `perl -c` executes BEGIN blocks (real perl,
not the gate):

```
cat > /tmp/evil.pl <<'EOF'
BEGIN { open(my $fh, ">", "/tmp/pwn_perl_c_test.md") or die $!; print $fh "pwned via perl -c BEGIN block\n"; close $fh; }
print "this never runs under -c\n";
EOF
perl -c /tmp/evil.pl
cat /tmp/pwn_perl_c_test.md
```

Live against the real gate subprocess, PR #367 worktree
(`git worktree add /tmp/pr367-hunt <PR#367 head>`), harness modeled on
`run-board-gate-tests.sh`'s own `run()`:

```
source /tmp/pr367-hunt/core/hooks/tests/_tmp.sh
GATE="/tmp/pr367-hunt/core/hooks/board-gate.sh"
PLUGIN_ROOT="/tmp/pr367-hunt"
mktd
git init -q "$td"
git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
git -C "$td" checkout -q -b issue-3/qa
mkdir -p "$td/docs/specs" "$td/docs/issue-3/reports"
printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
CMD="cd docs/issue-3 && perl -c reports/evil.pl"
payload=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"%s"}' "$CMD" "$td")
printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_SKILL=qa /bin/bash "$GATE"
echo "RC=$?"
```

Same payload replayed against an `origin/main` worktree
(`/tmp/main-hunt`, same harness, `GATE`/`PLUGIN_ROOT` pointed at
`/tmp/main-hunt`) as the baseline.

### Observed

Real perl: `perl -c /tmp/evil.pl` prints `/tmp/evil.pl syntax OK` to
stderr (the syntax-check message) **and** creates
`/tmp/pwn_perl_c_test.md` containing `pwned via perl -c BEGIN block` —
the BEGIN block ran, despite `-c`.

PR #367's board-gate.sh, the exact command
`cd docs/issue-3 && perl -c reports/evil.pl`:
```
RC=0
VERDICT=allow
```
(no deny message at all — passes straight through as a provably-safe
invocation).

`origin/main`'s board-gate.sh, byte-identical payload:
```
board-gate: a Bash call carries an un-analyzable write-capable shape
(perl -c reports/evil.pl) while this gate enforces role 'qa''s
write-set. ... this refuses rather than risk a masked out-of-set write
(issue-225 — the on-the-record PR #1627 bypass).
RC=2
VERDICT=deny
```

### Expected

`perl -c reports/evil.pl` should stay denied (as it was on `origin/main`)
because it is not, in fact, a provably read-only or provably
analyzable invocation — Perl's own documented `-c` semantics ("BEGIN,
UNITCHECK, or CHECK blocks and any use statements ... are considered as
occurring outside the execution of your program" — i.e. they run) mean
a `reports/*.pl` file passed to `perl -c` can perform an arbitrary real
write (to any path, not just inside the analyzed write-set) purely
through a BEGIN block, with the gate having reclassified the whole
shape as safe on the strength of a flag-name assumption ("check syntax,
do not run") that does not hold for the interpreter it was applied to.
Round 5's own stated rationale for giving back `perl -c` (`the opposite
of inline execution`) is empirically false for Perl specifically; the
same allowlist entry does not need Perl's actual runtime semantics to
match its assumed ones in order to compile — it silently trusts the
assumption instead.
