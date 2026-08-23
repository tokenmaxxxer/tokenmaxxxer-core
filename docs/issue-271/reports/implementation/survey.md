# Survey: issue-271 — survey-order-gate.sh hardcodes reports/implementation/survey.md

## Write surface

`core/hooks/survey-order-gate.sh` (single file, 184 lines). No test file
exists for it yet (`find . -iname '*survey-order*'` returns only the gate
itself and its companion `survey-order-directive.sh`). Companion gates in
the same directory (`record-shape-gate.sh`, `trailer-gate.sh`,
`proposal-shape-gate.sh`, `handbook-trigger-gate.sh`) each have a sibling
`core/hooks/tests/run-<name>-tests.sh` — that's the convention this fix's
regression test should follow.

## Current defect (lines 96, 124)

```
PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*\.md$')
...
issue_n = m.group(1)
survey_rel = "docs/issue-%s/reports/implementation/survey.md" % issue_n
```

The gate matches any `docs/issue-<n>/proposals/*.md` write (role-blind —
the regex has no role component) but then hardcodes the expected survey
path to `reports/implementation/survey.md`, regardless of which role's
session is writing. board-gate.sh R3 (line ~614-698) requires
`CLAUDE_ROLE` to match the write's own role segment for any
`docs/issue-<n>/` write — a non-implementation role session (e.g.
`product-discovery`, `accessibility`) is refused by board-gate if it
tries to write under `reports/implementation/`, since that's not its own
role's tree. So: the two gates jointly make phase-1 proposal writes for
any non-implementation role unsatisfiable — the survey board-gate lets
them write (`reports/<own-role>/survey.md`) is invisible to
survey-order-gate, and the path survey-order-gate demands
(`reports/implementation/survey.md`) is one board-gate refuses them to
write.

## How role identity is available to a gate (precedent)

`record-shape-gate.sh:37` and `handbook-trigger-gate.sh:28` both read
`role="${CLAUDE_ROLE:-<gate-name>}"` from the environment — `CLAUDE_ROLE`
is the standing mechanism session role is exposed to hooks throughout
this repo (also read by `trailer-gate.sh`, `board-gate.sh`,
`directive.sh`, `proposal-shape-gate.sh`). `survey-order-gate.sh`
currently reads no such variable at all — it has zero role-awareness.

board-gate.sh's own per-role tree convention (`docs/issue-<n>/reports/
<role>/`, e.g. line ~614 `role = os.environ.get("CLAUDE_ROLE", "").strip()`)
is the exact shape `docs/issue-<n>/reports/<role>/survey.md` that issue-271's
fix direction names.

## Accept-any-glob risk

A naive fix that instead globs `docs/issue-<n>/reports/*/survey.md` (any
role's survey satisfies the gate for any role's proposal) would defeat
the ordering check's purpose: a foreign role's stale survey (e.g. a
long-abandoned `product-discovery` session's old survey sitting on disk)
would satisfy the gate for an unrelated `accessibility` role's proposal
write, even though nothing was surveyed by *that* session. The fix must
resolve to the *acting* role's own survey path (from `CLAUDE_ROLE`), not
accept a match against any role directory.

## Fallback behavior needed

`CLAUDE_ROLE` is not always set (the gate today runs role-blind and
`board-gate.sh:698` treats an absent `CLAUDE_ROLE` as its own violation
class, "a write under docs/issue-<n>/ from a session with no CLAUDE_ROLE").
For survey-order-gate to fail closed rather than silently no-op when
`CLAUDE_ROLE` is unset, falling back to the existing hardcoded
`reports/implementation/survey.md` path preserves current behavior for
today's only real caller (the `implementation` role, which is also this
issue's own subject role) instead of introducing a new failure mode for
callers that already worked before this fix.

## No design decision left open — this is a pure bugfix

The fix direction is fully specified by the issue: derive the survey path
from `CLAUDE_ROLE` (`docs/issue-<n>/reports/<role>/survey.md`), fall back
to the current `implementation` path when role is unset, and add one
regression test for a non-implementation role's phase-1 proposal write.
There is no alternative shape for the corrected path (board-gate.sh
already established `reports/<role>/` as the per-role tree convention
this repo uses everywhere else), so this survey states its own
scout-skip condition per the scout directive: **pure bugfix, no design
decision left open** — the fix aligns one gate's hardcoded path with an
existing, already-adopted convention (board-gate.sh's per-role tree),
not a new design choice.
