# Survey: issue-187 rollout-worker frictions

Two frictions reported from #171 session 7 rollout workers.

## 1. `*/hooks/*.sh` write wall

No gate does a literal `*/hooks/*.sh` glob-deny. The friction traces to
`warrant/hooks/scope-gate.sh`'s write-set enforcement, which is
content-blind by explicit design (its own header, lines 8-10):

```
# Both read the TOOL INPUT — a path, a command string — before anything happens.
# Neither reads generated content, and neither judges the work
```

Enforcement (~line 310):

```python
for entry in write_set:
    if relative == entry or relative.startswith(entry.rstrip("/") + "/"):
        allow()
...
print("warrant: refused — `%s` is outside the write set frozen by %s.\n" ...)
sys.exit(2)
```

Any `Write`/`Edit`/`MultiEdit`/`NotebookEdit` targeting a path outside the
approved proposal's frozen `write_set` is denied purely by path — a hook
script edit with entirely sanctioned content is refused the same as one
with malicious content, because content is never read.

Bash is exempt from this same check (the file's own "A6 (A4 fix)" comment,
~line 211): only a narrow read-only allowlist governs Bash, everything
else falls through to the normal permission prompt instead of a hard
`exit 2`. That asymmetry is what makes the scratchpad-write + `mv`
workaround succeed — `mv` via Bash never hits the write-set check that a
direct `Edit`/`Write` does.

No existing runtime test exercises this behavior; no `run-scope-gate-tests.sh`
exists (only a static-audit reference to `scope-gate.sh` inside
`core/hooks/tests/run-canon-duplication-content-tests.sh`).

## 2. board-gate false positive on `docs/issue-N`-shaped strings in content

`core/hooks/board-gate.sh`'s `Write`/`Edit`/`NotebookEdit` candidate
extraction only ever reads `tool_input.file_path` (~line 332) — content is
never read there, so this false positive is not a Write/Edit path.

It is the Bash path. For any command segment that can't be proven
read-only, board-gate extracts write candidates with (~line 376):

```python
own_hits = re.findall(r"[\w./~$:-]*%s[\w./-]*" % re.escape(DOCS), seg)
```

This scans the entire raw text of the segment `seg` — including heredoc
bodies, echoed strings, and commit messages passed inline — not just the
write-target argument. A `docs/issue-N/...`-shaped substring appearing
*anywhere* in that text (e.g. inside a comment being written into a
non-docs file, or inside a `-m` commit message) becomes a candidate and is
evaluated as if it names a real board-write target. There is no
distinction between "this token is the path being written" and "this
token is merely present in content that happens to be written somewhere
else."

`core/hooks/tests/run-board-gate-tests.sh` is the existing suite (custom
bash harness, `report()`/`run()` helpers, want/got string comparison —
same shape used across `core/hooks/tests/`). It has no case for a
`docs/issue-N`-shaped string living only inside comment/echoed/heredoc
content of an otherwise-legitimate non-board write.

## Related canon / decisions

`grep -rniE "board write|hooks path|blanket-deny|content-inspecting" docs/decisions docs/specs`
— no hits. Neither directory documents this behavior today.

## Write set for the proposal (confirmed against current code)

- `warrant/hooks/scope-gate.sh` — narrow content check for hook-script
  write-set misses.
- `core/hooks/board-gate.sh` — narrow the Bash candidate-extraction window
  to the actual write-target token, not the whole segment.
- `core/hooks/tests/run-scope-gate-tests.sh` — new, red-green pair for (1).
- `core/hooks/tests/run-board-gate-tests.sh` — red-green pair for (2).
- `core/hooks/tests/run-all.sh` — register the new suite if it isn't
  auto-discovered.
