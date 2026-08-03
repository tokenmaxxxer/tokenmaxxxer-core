---
kind: scout-brief
subject: issue-98
produced_by: implementation
---

# Scout brief — issue-98

Mode: 2 parallel WebSearch angles in one turn (by-category: restricted-shell
escape catalogs; by-mechanism: privileged-command-allowlist bypass), one
round, no fallback needed.

Must-bes a command-allowlist gate is expected to hold, per the field:
- Treat the well-known interpreter-escape family (`bash`/`sh`, `eval`, and —
  named explicitly by GTFOBins — `python`, `perl`, `awk`, even editors like
  `vi`/`less` via `:!`) as "still executes," not as inert text, regardless of
  quoting: "if you spot vi, less, python, perl, or awk, you're probably able
  to escape it."
- sudo's own `noexec` defense converges on the same root cause this issue
  names: `system()`/`popen()` reach `/bin/sh` through a call path the
  restriction never sees, because the restriction inspected the wrong layer
  (the binary being exec'd) instead of the layer that actually executes
  (the shell interpreting a string argument).

Performance axis this gate competes on: false-negative rate on the
interpreter-escape family vs. false-positive rate on legitimate quoted data
(a grep pattern, an awk comparison) — the two prior issues (#88, #90, #94)
already trade on this exact axis for other constructs.

Adopt: enumerate the interpreter family explicitly (bash/sh/dash/ksh/zsh,
eval, python/python3/python2, perl) rather than trying to detect "executes a
string" structurally — GTFOBins' own list is itself an enumeration, not a
generic rule, because there is no clean generic one.
Skip: chasing the full GTFOBins catalogue (vi/less/find -exec/etc.) — issue
#98's named repro set is the interpreter-`-c`/`eval` family specifically;
editors and `-exec`-style flags on read-only heads are a different, larger
surface (out of scope, see proposal).

Gap line: current state already has the *shape* of this defense (board-gate's
`TRANSPARENT`/`_head_of()` fail-closed-on-unrecognized-head default already
covers most of the family by accident — verified live, see survey). What's
missing is (a) gh-guard's dequote path has no such fail-closed fallback at
all for its 3 verb rules, and (b) board-gate's `READ_UNLESS_INPLACE` heads
(awk/sed) are a named exception to the fail-closed default that the field's
own must-be says should not be trusted blindly either.

Sources:
- https://gtfobins.org/
- https://www.verylazytech.com/linux/bypassing-bash-restrictions-rbash
- https://www.sudo.ws/security/advisories/noexec_bypass/
