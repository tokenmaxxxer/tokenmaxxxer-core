# Survey — issue-200: conflict-free system-generated writes

Skip condition: N/A — scouting was not skipped; this is an internal audit of this repo's own hook scripts, not a product-shaped surface with external exemplars. Scout protocol's own text limits itself to "product-shaped surfaces" for exemplar sweeps; this issue is a design decision within an existing internal system (path construction inside shell/python hooks), so the applicable prior art is the codebase's own established pattern (docs/issue-<n>/ tree, contract v3 s19) rather than an external category. No exemplar sweep was run; the design choice below reuses tokenmaxxxer-core's own existing issue-scoping convention, which is the load-bearing prior art.

## Write set (confirmed)

- `warrant/hooks/hunt-guard.sh` — writes `$root/.warrant-hunt.lock` and `$root/.warrant-hunt.count` (both worktree-root files) at lines ~137-158 (python heredoc).
- `warrant/hooks/hunt-state.sh` — removes the same two files (`rm -f "$root/.warrant-hunt.lock" "$root/.warrant-hunt.count"`) on `release`/`reset`.
- `warrant/agents/warrant-hunter.md` — line 81: "One file per work unit, named for its proposal: `docs/reports/<date>-hunt-<proposal-slug>.md`." Line 150/153 repeat the same path pattern.
- `warrant/hooks/directive.sh` — line 76: tells the dispatching role the same `docs/reports/<date>-hunt-<proposal-slug>.md` path to hand the hunter.
- test file to add: none exists yet for hunt-guard/hunt-state path construction — `warrant/hooks/tests/run-hunt-guard-tests.sh` (new, matching this repo's existing `run-*-tests.sh` convention in `core/hooks/tests/` and `freelunch/hooks/tests/`).

## Audit of every other core-plugin write into a target-repo worktree

Grepped `core/hooks`, `terse/hooks`, `scout/hooks`, `warrant/hooks`, `freelunch/hooks` (`.sh`+`.py`) for `open(...,'w'/'a')`, `.write(`, `os.makedirs`, and shell redirects into `$root`. Full result set (test-directory noise excluded):

| Site | Target | Classification |
|---|---|---|
| `warrant/hooks/hunt-guard.sh:155-158` | `$root/.warrant-hunt.lock`, `$root/.warrant-hunt.count` | **collision risk** — worktree root, unconditional overwrite, no issue key. Subject of this issue's item 1. |
| `warrant/hooks/hunt-state.sh` | same two files (delete only) | tracks the above; fixed by the same relocation. |
| `warrant/agents/warrant-hunter.md` / `warrant/hooks/directive.sh` | `docs/reports/<date>-hunt-<proposal-slug>.md` | **collision risk** — date+slug key, not issue-scoped. Subject of this issue's item 2. |
| `freelunch/hooks/observe.sh:114-116` | `${FREELUNCH_OBSERVE_LOG:-$HOME/.claude/freelunch-observe.jsonl}` | **out-of-tree** — defaults under `$HOME`, not the repo worktree; append-only telemetry log, one path per user machine, never committed. No fix needed. |
| `core/hooks/approval-gate.sh:196` | reads `docs/specs/approvers.md` | read-only, not a write. |
| `core/hooks/*-gate.sh` (board-gate, record-fields-gate, trailer-gate, handbook-trigger-gate, gh-guard) | none — these gate/deny tool calls (PreToolUse), they do not themselves write files; the actual content write is the role's own Edit/Write tool call the gate approves or denies. | not a generator — out of this issue's scope (contract v3 s19 already keys role output paths by `docs/issue-<n>/`). |
| `terse/hooks/terse.sh` | no file writes found (state kept in hook env only) | no risk. |
| `scout/hooks/directive.sh` | prose directive only, no writes | no risk. |
| `warrant/hooks/state.sh` | read-only (SessionStart summary print) | no risk. |
| `warrant/hooks/scope-gate.sh` | read-only (gate) | no risk. |

Also noted, not in this issue's fix list (recorded for completeness, not a hidden scope-widen): the warrant plugin's own standing proposal-doc convention (`docs/proposals/YYYY-MM-DD-<slug>.md`, `warrant/hooks/directive.sh:27,53`) carries the same date+slug key shape as the hunt-report risk, but it is human-authored/approved content (the proposal itself), not purely system-generated, and this repo's actual proposals under contract v3 s19 already land at `docs/issue-<n>/proposals/` — issue-scoped by directory, no fix needed here. Left as-is; out of scope for this issue's item 3 audit since it is not "system-generated."

## Empty-state behavior (current)

`hunt-guard.sh`'s python block does `os.path.exists(lock)` / `open(count)` with `except (OSError, ValueError): used = 0` — a repo where warrant has never run has neither file; the guard already tolerates their absence (falls through to `used = 0`, no lock). This existing tolerance must be preserved after relocation — the empty-state test in the acceptance criteria is a regression check on this fallback, not new behavior to build.

## Existing test conventions to match

`warrant/hooks/tests/` currently has only `parse-check.sh`. Sibling plugins keep one `run-<hook>-tests.sh` per hook plus `tests/_tmp.sh`-style scratch helpers (see `core/hooks/tests/run-board-gate-tests.sh`, `freelunch/hooks/tests/run-observe-tests.sh`). New test file follows that naming: `warrant/hooks/tests/run-hunt-guard-tests.sh`.
