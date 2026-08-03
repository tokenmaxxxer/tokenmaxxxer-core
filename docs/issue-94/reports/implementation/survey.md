---
kind: current-state-survey
subject: issue-94
produced_by: implementation
loop_state: surveyed
---

# Survey: issue-94 — quoted strings still misread as real shell acts in board-gate's write judgment and all of gh-guard

## Scope

Two of the three gates in the "shell text seen as plaintext, not tokens"
family (issue-88 fixed board-gate's SEGMENT splitter; issue-90/c66aecc
fixed board-gate's candidate scoping and ported the fix to
approval-gate's WRITEISH) still misjudge quoted content as real shell
syntax:

1. `core/hooks/board-gate.sh` — `_write_candidate_segments`'s
   `SUBSHELL`/`FILE_REDIR` check, `board-gate.sh:226`.
2. `core/hooks/gh-guard.sh` — the entire `RULES` list, `gh-guard.sh:70-111`,
   applied via `re.search(pat, cmd)` on the whole raw command string.

## Current-state read

### board-gate.sh (defect 1)

`_split_segments` (`board-gate.sh:139-162`, backed by the `SEGMENT` regex
at `:136`) is already quote-aware: it puts quoted-span alternatives
*first* in its alternation, guarded by `(?<!\\)`, so `finditer` consumes
an entire quoted span as one match and a real separator (`;`, `|`, `&&`,
`||`) hiding inside quoted text never causes a false split. This is the
issue-88 fix.

But `_write_candidate_segments` (`:208-240`) then runs the **write-char**
check on each segment's raw text:

```python
if SUBSHELL.search(seg) or FILE_REDIR.search(seg):
    failing.append(seg)
```

`SUBSHELL = re.compile(r"[`]|\$\(")` and `FILE_REDIR = re.compile(r">>?(?!&)")`
(`:112`, `:118`) are applied with plain `.search()` — no quote exclusion
at all. Splitting sees quotes; this judgment does not. A quoted `>`
(`grep -n "A > B" docs/...`) fails classification and the segment becomes
a write candidate, which then denies under R4 (branch ownership) once a
`docs/issue-<n>/` token is extracted from it.

`approval-gate.sh` solved the analogous problem for its own single
`WRITEISH` char-class at `c66aecc` (issue-90): quoted-span alternatives
placed first in `WRITEISH`'s own alternation, then a `_writeish()` helper
(`approval-gate.sh:101-107`) that walks `finditer` and skips any match
starting with a quote character. The issue asks board-gate's fix to
reuse this exact mechanism rather than re-derive a new one.

### gh-guard.sh (defect 2)

`gh-guard.sh` has no segmentation and no quote awareness anywhere. Every
one of the 11 `RULES` (`:70-111`) is `re.search(pat, cmd)` against the
full, raw `tool_input.command` string. Two distinct pattern shapes are in
play:

- Simple contiguous patterns, e.g. `:74`
  `r"\bgh\s+pr\s+(merge|close|reopen)\b"`, `:77`, `:82`, `:85`, `:88`.
- Multi-clause `(?=.*X)(?=.*Y)` lookahead patterns (`:94`, `:98-99`,
  `:102-103`, `:106-107`) that independently confirm an endpoint
  substring and a verb/flag substring appear *somewhere* in `cmd`, in
  either order, to catch the same act spelled via `curl`/`wget`/raw `gh
  api`/GraphQL regardless of client (issue #20).

Neither shape excludes quoted content. A quoted phrase containing `gh pr
merge` (a grep pattern, a commit message, a comment body — any string
argument) matches `:74` exactly as if it were the literal invocation.

### Live reproduction (2026-08-03, this session)

Both issue-cited commands were reproduced against the **current,
unfixed** code — not synthetically, but as accidental self-hits: this
session's own board-gate/gh-guard hooks (wired into this very Claude Code
session, running the code on `main`/this branch before any fix) denied
two of this session's own diagnostic Bash calls the moment their command
text contained the two exact strings the issue names:

- A Bash call embedding `grep -n "A > B" docs/issue-49/reports/x.md`
  (issue defect 1's exact repro) was denied by this session's live
  board-gate with: `board-gate: writing docs/issue-49/ requires branch
  issue-49/implementation (current: issue-94/implementation)` — R4 firing
  on a pure read because the quoted `>` failed `FILE_REDIR` exclusion,
  exactly as defect 1 describes.
- A Bash call embedding `grep -n "^def \|gh pr merge\|pr merge" spawn.py`
  (issue defect 2's exact repro) was denied by this session's live
  gh-guard with: `gh-guard: refused for role session 'implementation':
  merging or closing a PR is the human's acceptance/refusal...` — the
  `:74` rule firing on a `grep` that never calls `gh`, exactly as defect
  2 describes.

Both denials are reproduced literally, dated today, against the exact
code this proposal targets — not a hypothetical.

### Existing regression-test conventions (precedent to extend, not invent)

- `run-board-gate-tests.sh:248-260` and `run-approval-gate-tests.sh:176-186`
  already carry the issue-88/issue-90 quote-awareness regression pairs
  (allow-when-quoted, deny-when-real-and-unquoted, deny-on-escaped-quote
  warrant-hunt case) in the `run <want> <name> ... cmd=...` shape this
  issue's new cases should match.
- `run-gh-guard-tests.sh` groups cases by defect/gap (`gap-a-*`,
  `gap-b-*`, `gap-c-*`, `gap-d-*`) with an explicit "kept visible rather
  than silently dropped" ALLOW case for what a fix does *not* close
  (`gap-c-*`). New cases fit this convention as a `gap-e-*` (or
  `quote-*`) group.
- `run-gate-lib-tests.sh` unit-tests `gate-lib.py` functions directly via
  the same `importlib.util.spec_from_file_location("gate_lib",
  os.environ["GATE_LIB_PY"])` load every gate's own heredoc payload
  already uses when it imports `gate_lib` (see next section) — this is
  the harness a new shared helper's own unit tests belong in.

### The consolidation precedent already exists in this codebase

`core/hooks/lib/gate-lib.py` / `gate-lib.sh` (issue-72) is exactly the
"one place" the issue's constraint asks for: a sourceable helper library,
`GATE_LIB_PY` already exported by `gate-lib.sh` for a gate's own Python
heredoc to load via `importlib`. `core/hooks/record-fields-gate.sh:147-151`
already does exactly this (`gate_lib.gate_reconstruct_write`) — the
import pattern is proven, not novel.

Neither `board-gate.sh` nor `approval-gate.sh` nor `gh-guard.sh` imports
`gate_lib` today (`grep -n "gate_lib\|importlib" core/hooks/*.sh` outside
`record-fields-gate.sh` and the `tests/` dir returns nothing) — each
still hand-rolls its own quote/segment logic inline in its heredoc.

Issue-90's own proposal (`docs/issue-90/proposals/2026-08-03-scope-
board-gate-candidates-and-port-approval-gate-fixes.md`, "Rationale")
explicitly *rejected* centralizing then: "`approval-gate.sh` is not
rewritten to import `board-gate.sh`'s segment model wholesale... the fix
ports the verified pattern... not the code," reasoning that a shared
module would be "a materially larger change" risking "a different,
un-warrant-hunted set of edge cases." That reasoning is directly relevant
prior art for this issue's own constraint ("가능하면 판정 헬퍼를 한 자리로
모은다") pushing the other way now that a third gate needs the same fix:
the quote-span-first + `(?<!\\)` mechanism has since gone through two
independent warrant-hunted rounds (issue-88 board-gate, issue-90
approval-gate) with regression coverage in both harnesses, and
`gate_lib`'s own load path is already proven via
`record-fields-gate.sh`. The risk profile issue-90 weighed against
centralizing is measurably lower now.

## Scout-directive skip record

Scouting (external prior-art sweep) is skipped for this survey. Reason:
this is an internal security-gate bugfix constrained by the issue's own
explicit ask (reuse `approval-gate.sh`'s already-shipped quote-span-first
`(?<!\\)` mechanism verbatim; check whether `board-gate.sh`'s
`_split_segments` can be reused by `gh-guard.sh`) — there is no external
product category ("best-in-class shell-command classifier gate") whose
exemplars would inform a PreToolUse hook internal to this plugin's own
role-handoff contract. The one open design question this survey found —
centralize the shared quote logic in `gate-lib.py` vs. duplicate the
pattern per-gate as issue-90 chose — is answered from this codebase's own
internal precedent (`gate-lib.py`'s stated purpose,
`record-fields-gate.sh`'s existing import of it, and issue-90's own
recorded rejection reasoning), which is current-state survey material,
not a scoutable external field.

## Hunt (warrant-hunter, end of phase 1)

A synchronous adversarial review pass (general-purpose agent, read-only,
foreground — this session is a single headless turn with no later turn to
receive a backgrounded hunter's notification, so the dispatch could not
be async) was run against a first-draft design (uniform `gate_dequote`:
blank every quoted span, route `board-gate.sh`'s `SUBSHELL`, all of
`gh-guard.sh`'s 11 `RULES`, and `approval-gate.sh`'s `WRITEISH` through
it; segment `gh-guard.sh` via a relocated `_split_segments` first). The
hunt's brief: try to break it — a real unquoted write/act that newly
slips through as allow, or a real command newly denied. Findings, all
against that first draft (not the design this proposal actually
specifies below, which was revised in response):

- **CONFIRMED, most severe**: blanking a *whole* double-quoted span hides
  a live `$(...)`/backtick command substitution nested inside it — double
  quotes do not suppress substitution in bash, only single quotes do.
  `grep -n "$(touch docs/issue-1/pwned.md)" README.md` really executes
  `touch`; `board-gate.sh`'s current raw-text `SUBSHELL` check catches
  this today (no quote awareness at all, by accident of the bug this
  issue fixes elsewhere); blanket-dequoting `SUBSHELL` the same way
  `FILE_REDIR` is fixed would newly **allow** it. `gh-guard.sh`'s
  `--body "$(gh pr merge 6)"` shape has the identical hole for rule
  `:74`.
- **CONFIRMED**: several `gh-guard.sh` `RULES` (comment-body `APPROVE`,
  the raw-API endpoint/state rules, the GraphQL mutation rule) exist
  specifically to detect content that legitimately lives *inside* a
  quoted argument to a real `gh`/`curl` invocation (a `--body` string, an
  `-f query='mutation{...}'` GraphQL body) — that is their true-positive
  path, not an edge case. Blanket quote-exclusion across all 11 `RULES`
  would silently disable detection for the common, expected shape of
  exactly the acts these rules exist to catch.
- **CONFIRMED**: giving `gh-guard.sh` segmentation for the four
  `(?=.*X)(?=.*Y)` lookahead rules (endpoint+verb, independent of client
  binary — issue #20) can let a real single invocation escape: those
  rules rely on `.*` reaching across the whole command line by design
  (verb and endpoint can appear in either order); if a real, unquoted
  separator-shaped character sits inside an unquoted `$(...)` (e.g. `curl
  -X POST $(cat token.txt || echo default) https://.../pulls/5/merge`),
  naive segmentation (quote-aware only, not paren-aware) splits what
  bash treats as one command into two, and the endpoint/verb no longer
  co-occur in either single segment.
- **CONFIRMED, minor**: single-space blanking can join two dequoted
  fragments into a new match a `\s+`/`\b`-anchored multi-word `RULES`
  phrase would not otherwise complete (e.g. `gh"a"pr"b"merge` — three
  bash-concatenated tokens with no real match today — dequotes to `gh pr
  merge`). Direction is over-blocking (new false deny), the accepted
  safe direction per this codebase's own stated posture
  (`board-gate.sh:173`), not a new hole.
- No finding: relocating `_split_segments`'s algorithm verbatim into
  `gate-lib.py` changes no observable output (regex/string semantics are
  identical across a heredoc `-c` string and an imported module; no
  capturing groups to renumber).

Consequence for this proposal's actual design (below): `SUBSHELL` is
left completely unchanged (raw-text, quote-blind) rather than routed
through the new dequote helper — its quote-blindness is a real
requirement for that character class, not a residual bug. `gh-guard.sh`
segmentation is dropped entirely (no correctness benefit for the rules
it is safe to fix once whole-command dequoting is used, and the only
place segmentation would add value — the lookahead rules — is exactly
where the hunt found it unsafe). `gh-guard.sh`'s fix narrows to the three
`RULES` that are pure command/verb invocation syntax with no legitimate
quoted-argument use (`:71-73`, `:74-76`, `:77-79`); the remaining eight
stay unchanged, named explicitly out of scope in the proposal with this
hunt's reasoning attached, rather than silently narrowed with no
explanation.

## Write set this proposal will name

`core/hooks/lib/gate-lib.py`, `core/hooks/board-gate.sh`,
`core/hooks/approval-gate.sh`, `core/hooks/gh-guard.sh`,
`core/hooks/tests/run-gate-lib-tests.sh`,
`core/hooks/tests/run-board-gate-tests.sh`,
`core/hooks/tests/run-approval-gate-tests.sh`,
`core/hooks/tests/run-gh-guard-tests.sh`,
`docs/handbooks/gate-house-standard.md`,
`docs/handbooks/board-gate-tests.md`, `docs/handbooks/approval-gate-tests.md`,
`docs/handbooks/gh-guard-tests.md`.
