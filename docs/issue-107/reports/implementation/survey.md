---
kind: current-state-survey
subject: issue-107
produced_by: implementation
loop_state: surveyed
---

# Survey: issue-107 — wrapper-prefixed `cd` defeats board-gate's `cd_tail` tracker

## Scope

Issue #107 asks for a phase-1 proposal only (explicit in the issue body:
"phase 1 이므로 구현하지 않는다"). It formalizes Finding 1 of
`docs/issue-99/reports/execution-observation.md` (the merged
`execution-observation` record for PR #102, issue #99), which found by
static inspection — no suite run, no live gate invoked — that a
wrapper-prefixed `cd` segment (`timeout 30 cd docs/issue-49 && date >
x.md`, and seven other wrapper heads) reaches `allow()` on the merged
gate with no rule ever applied.

## The bug, read from the current tree (working tree == `origin/main`,
`git status` clean, HEAD `6bb63c0`)

Two functions answer two different questions about where a command
starts, using two different models:

- **Head detection** (`core/hooks/lib/gate-lib.py:238-245`,
  `gate_head_of`) delegates to `_resolve_transparent`
  (`core/hooks/lib/gate-lib.py:203-235`), which walks a segment's words
  through `TRANSPARENT = ("xargs", "env", "time", "nice", "command",
  "builtin", "timeout", "nohup")` (`gate-lib.py:194-195`), skipping one
  extra bare positional word for `timeout`
  (`TRANSPARENT_TAKES_ARG = ("timeout",)`, `gate-lib.py:200`), and
  returns `(head, trailing_words)` — the resolved head **and** every word
  after it in original order (`gate-lib.py:206-207`, docstring). For
  `"timeout 30 cd docs/issue-49"` this correctly resolves to `("cd",
  ["docs/issue-49"])`. `gate_head_of` itself discards the second element
  (`gate-lib.py:245`: `return _resolve_transparent(segment)[0]`) — it is
  the only accessor to this resolver current code exposes.
- **Argument extraction** for a `cd` segment
  (`core/hooks/board-gate.sh:259-269`, `_cd_target`) does NOT go through
  the resolver at all. It re-splits the raw segment itself —
  `stripped.split()[1:]` (`board-gate.sh:266`) — and returns the first
  non-flag word, on the hard assumption that the head sits at word 0.
  For `"timeout 30 cd docs/issue-49"` this returns `"30"` (the first
  non-flag word after splitting on whitespace), not the `cd` target.

The call site that composes them
(`core/hooks/board-gate.sh:326-335`, the `cd_tail`-tracking walk added by
issue #99's PR #102):

```
cd_tail = ""
for seg, stripped, failing in classified:
    if not failing:
        if gate_lib.gate_head_of(stripped) == "cd":      # :329 — resolver-based, correct
            target = _cd_target(stripped)                # :330 — raw split()[1:], wrong
            if target:
                tail = _docs_relative_tail(target)
                if tail:
                    cd_tail = tail
        continue
```

`gate_head_of` correctly says line 329 is a `cd`; `_cd_target` at line
330 then reads the wrapper's own argument (`"30"` for `timeout`, or the
literal head word for the six argument-less wrappers, e.g. `_cd_target`
on `"command cd docs/issue-49"` returns `"cd"` itself) instead of the
real target. `_docs_relative_tail("30")` / `_docs_relative_tail("cd")` is
`""`, so `cd_tail` is never set. The write segment
(`date > x.md`, no `docs/` token of its own) then contributes no
candidate under the `elif cd_tail:` arm (`board-gate.sh:339-340`), so
`candidates` stays empty, `hits` stays empty, and
`if not hits: allow()` (`board-gate.sh:349-350`) allows with no rule
ever applied — the exact failure class issue #99 was filed to close.

This reproduces for `nohup` and for the six pre-#98 wrappers
(`command`, `env`, `xargs`, `time`, `nice`, `builtin`) — all resolve
through `TRANSPARENT` the same way; only `timeout`'s extra positional
argument changes which wrong token gets read.

`gate_head_of` is called from exactly two sites, both in
`board-gate.sh` (`:214` inside `_segment_is_failing`, and `:329` above);
`grep` across `core/hooks/*.sh core/hooks/lib/*.py` confirms no third
call site. `gh-guard.sh` imports `gate_lib` but never calls
`gate_head_of` or `_resolve_transparent` — it uses a different function,
`gate_wrapper_head_before` (`gate-lib.py:258-307`), for an unrelated
question (is a quoted span about to be executed as code). So a change to
how `_resolve_transparent`'s second element is exposed has exactly one
consumer to update: `board-gate.sh`'s own `_cd_target`.

## Write set this proposal will name

- `core/hooks/lib/gate-lib.py` — expose `_resolve_transparent`'s
  `trailing_words` behind a new public accessor (naming below), leaving
  `gate_head_of`'s existing contract (bare string, both current call
  sites unchanged) untouched.
- `core/hooks/board-gate.sh` — `_cd_target` reads from that accessor's
  trailing words instead of `stripped.split()[1:]`.
- `core/hooks/tests/run-board-gate-tests.sh` — regression cases per
  issue #107 requirement 2.

No other file calls `_cd_target`, `gate_head_of`, or
`_resolve_transparent` (confirmed by grep above), so this is the full
write set; nothing under `docs/handbooks/` is a required edit under the
doctrine ladder (no new dependency, config key, migration, or changed
public *signature* — the change is a new accessor alongside an unchanged
one), so a handbook edit is left to phase-2 judgment rather than
committed to here.

## Existing test conventions (`run-board-gate-tests.sh`)

- Case-naming convention already in use for this exact class:
  `bash-wrapper-<wrapper>-foreign` for wrapper+write pairs added by
  issue #98 (`bash-wrapper-timeout-foreign`, `bash-wrapper-nohup-foreign`,
  `:322-323`) and `bash-cd-relative-<verb>-foreign` for the `cd`+write
  pairs issue #99 added (`bash-cd-relative-redirect-foreign`,
  `-cp-foreign`, `-mv-foreign`, `:283-297`). No existing case composes a
  wrapper with a `cd` — confirmed by grep across the whole file: every
  wrapper case's inner command is `bash -c "..."`, and every `cd` case
  has no wrapper prefix. The composition issue #107 must pin is
  genuinely new coverage, not a rename of an existing case.
- The harness's `run <want> <name> <tool> <input-json-fragment>` helper
  (`run-board-gate-tests.sh:30-45`) plants a fresh git repo per case with
  `docs/specs/approvers.md`, branch `issue-3/qa`, role `qa`; `$BOARD`
  expands to a foreign issue tree (`docs/issue-49/...` based on context
  around `:251-253`) the `qa` role does not own, so a `deny` case there
  exercises the same R4 path Finding 1 describes.
- Red-then-green evidence convention: issue #99's own record
  (`docs/issue-99/reports/implementation.md:151-162`, cited by the
  execution-observation record) stashed the pre-fix code, ran the new
  `deny` cases to confirm `FAIL want=deny got=allow`, then unstashed and
  re-ran to confirm `PASS`. Issue #107 requirement 2 asks for the same
  red→green proof.

## Design space for the argument-extraction fix

Issue #107's own action item names the minimal fix directly: extract the
`cd` argument from `_resolve_transparent`'s own trailing words rather
than from `stripped.split()[1:]`, since the resolver already computes
`(head, trailing_words)` and only `gate_head_of` (the sole current
accessor) throws the second element away. Two ways to expose it were
weighed (recorded in the proposal's Rationale, not decided here):

1. Add one new public function that returns just the trailing words
   (`_resolve_transparent(segment)[1]`), leaving `gate_head_of` and its
   two existing call sites completely unchanged.
2. Rename `_resolve_transparent` to a public name and have both
   `gate_head_of` and `board-gate.sh`'s `_cd_target` call the renamed
   function directly, `gate_head_of` becoming a one-line wrapper.

Both were hand-traced against the four shapes that matter — bare `cd
docs/issue-49`, `timeout 30 cd docs/issue-49`, `nohup cd docs/issue-49`,
`command cd docs/issue-49` — and both produce the correct trailing words
(`["docs/issue-49"]` in every case) for all four, since `_resolve_transparent`
already stops walking as soon as it reaches the non-wrapper word `cd`
regardless of what preceded it. The proposal picks one; see its
Rationale for which and why.

## Scout-directive skip record

**Skipped.** This is a pure bugfix to internal command-parsing logic
inside a security gate (board-gate.sh / gate-lib.py) — there is no
product-facing surface, no library or framework choice, and no
best-in-class category to compare against; the fix's direction (unify
argument extraction with the same resolver already used for head
detection) is fixed by the mechanism issue #107 itself names. No
scout-brief.md is produced for this issue.

## Open questions the proposal must resolve

- Which of the two accessor shapes above to pick (Rationale).
- Exact regression case set: issue #107 requirement 2 mandates the
  `timeout` shape plus at least one pre-#98 wrapper (`command` or
  `env`); which one, and whether `nohup` is worth a third case even
  though the issue does not require it.
