---
issue: 233
role: secure-coding-input-validation-injection-defense+adversarial-review-dea32ebc
author: secure-coding-input-validation-injection-defense+adversarial-review-dea32ebc
skills: secure-coding-input-validation-injection-defense (skill-repository(c05de12)), adversarial-review (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
upstream:
  - path: docs/issue-233/reports/adversarial-review-e95fc262.md
    sha: 8f8276561ca9db0863ba47aae3e44695b248747a
  - path: core/hooks/lib/gate-lib.py
    sha: same-commit
  - path: core/hooks/board-gate.sh
    sha: d5331eb220dcbffa8150d01a6b139ee4f61e359b
  - path: warrant/hooks/lib/scope-gate.py
    sha: d5331eb220dcbffa8150d01a6b139ee4f61e359b
---

# issue-233 — secure-coding-input-validation-injection-defense+adversarial-review-dea32ebc record

## What was done

Re-delivers PR #358 after its CHANGES review (upstream e95fc262.md,
merged as #359) found a real over-refusal: `/opt/My\ Python/python3 -c
'...'` — an escaped-space path to a real interpreter, ordinary shell
syntax, confirmed live to execute — was ALLOWED by PR #354 and DENIED by
PR #358. Root cause named by the review: `gate_lib._resolve_transparent`
tokenized with a plain `segment.split()`, which does not understand
backslash-escaped or quoted whitespace, so `/opt/My\ Python/python3`
fragmented at the escaped space. Under PR #354's narrow `` [`$] ``
denylist the fragment (`"My\\"`) matched nothing and slipped through
ALLOWED; under PR #358's allowlist-complement, the same fragment's stray
backslash tripped the unsafe-character class and the call was DENIED —
right verdict, wrong reason, and (separately, confirmed live) the
QUOTED equivalent (`"/opt/My Python/python3" -c ...`) resolved to head
`"My"` — a fully safe-looking fragment — and was a genuine, undetected
BYPASS: a real `-c` invocation sailing through ALLOWED.

Fix (`core/hooks/lib/gate-lib.py`): added `_shell_split`, a shell-word
tokenizer aware of (1) a backslash escaping any character including a
literal space, (2) single/double-quoted spans (including their
`$'...'`/`$"..."` ANSI-C and locale-translated forms), and (3)
backslash-newline line-continuation splicing with zero residual (odd/even
backslash-run counting, mirroring `_split_segments`'s own logic).
`_resolve_transparent` (backing both `gate_head_of` and
`gate_trailing_words`, used by `core/hooks/board-gate.sh`) now calls
`_shell_split` instead of `segment.split()`. This makes word formation
legible to the tokenizer BEFORE `EXPANDED_HEAD_RE`/`INTERPRETER_HEADS`
ever inspects a "head", rather than exempting characters from the
allowlist-complement after the fact — the fix shape the review named as
consistent with this drive's own backslash-newline splice.

A before-landing background `warrant-hunter` round (blind to this
session's reasoning) found the first version of `_shell_split` had no
notion of bash's ANSI-C quoting (`$'...'`): its leading `$` was consumed
by the generic bare-character fallback before the quote-span
alternatives saw the following `'`, fusing `$'-c'` into the two-character
word `$-c` instead of resolving it to the plain word `-c`. Live
reproduction: `python3 $'-c' "..."` runs as an ordinary `-c` invocation in
real bash, but `gate_trailing_words()` never contained the literal string
`"-c"`, so `INLINE_FLAG_WORDS` membership in
`_is_unanalyzable_write_shape` never fired — a full, confirmed bypass
(full hunt record: `docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-dea32ebc/2026-08-30-hunt-gate-lib-shell-split-ansi-c-quote.md`).
Fixed in the same delivery: `_WORD_TOKEN_RE` now matches `$'...'`/`$"..."`
as a single quote-opening token (the `$` consumed as part of the syntax,
not a separate character), verified against the hunt's own reproduction.

Test coverage added (`core/hooks/tests/run-board-gate-tests.sh`,
`core/hooks/tests/run-scope-gate-tests.sh`): for each of escaped-space
path, quoted path with spaces, a path containing a safe-but-unusual
character (`+`), and the ANSI-C-quoted flag word, both directions are
tested — DENY with a trailing `-c`/`-e`, ALLOW with none (pure read, not
over-blocked).

## Why

The tokenizer route (fixing `_resolve_transparent`'s word-splitting
itself) was chosen over the alternative the review also named
(recognizing the fragmentation artifact after the split) because it is
the one consistent with what this same PR already did for
backslash-newline splicing in `_split_segments` — one shell-word-formation
primitive the rest of the pipeline can trust, instead of a second
per-symptom patch layered on top of the existing allowlist-complement
character class. It also incidentally corrected `gate_trailing_words`
(used by `_is_unanalyzable_write_shape`'s `INLINE_FLAG_WORDS` check), which
a fragmentation-artifact-only fix touching just `gate_head_of` would not
have reached — the exact surface the before-landing hunt found still
broken (the ANSI-C-quoted FLAG word, not the head).

The allowlist-complement structure itself (denylist → allowlist-of-safe-word-characters,
landed in PR #358) is unchanged and is not revisited here — the review
called it "the right structural answer" and this session's own reading
agrees: `secure-coding-input-validation-injection-defense`'s rule 1/2
(allowlist over denylist for a field with known-finite structure — a
plain program name or path's character set is exactly such a field) is
already satisfied by that choice, and this delivery's job was narrowing
the boundary the allowlist-complement is compared against (the head
string itself), not re-litigating denylist-vs-allowlist.

## What did not work

The first `_shell_split` implementation (committed to the working tree
mid-session, before the before-landing hunt ran) omitted `$'...'`/`$"..."`
ANSI-C/locale-string quoting entirely — its regex only covered
backslash-escapes, plain single/double quotes, and backslash-newline. The
hunt agent found this gap and it was fixed in the same delivery (see
"What was done"); no separate commit or record exists for the
intermediate, incomplete version since it was never pushed.

## Upstream basis

- `docs/issue-233/reports/adversarial-review-e95fc262.md` (merged to
  `main` as #359, sha `8f82765`) — the CHANGES review this record
  responds to; names the escaped-space over-refusal, the tokenizer fix
  shape, and the two additional shapes to exercise (quoted path with
  spaces, safe-but-unusual-character path).
- `core/hooks/board-gate.sh`, `warrant/hooks/lib/scope-gate.py` at
  `d5331eb` (PR #358's own branch, `issue-233/...-711fc48d`, cherry-picked
  onto this branch unchanged) — the allowlist-complement structure, `eval`
  closure, and backslash-newline segmenter fix this delivery builds on
  without modifying.
- `docs/issue-233/reports/secure-coding-input-validation-injection-defense+adversarial-review-dea32ebc/2026-08-30-hunt-gate-lib-shell-split-ansi-c-quote.md`
  (same-commit) — the before-landing hunt finding this delivery fixes.

## Open findings

1. **Pre-existing, out-of-scope, NOT fixed here — recommend a new issue.**
   `core/hooks/board-gate.sh`'s own performance fast path (`case "$payload"
   in *docs*) ;; *) exit 0 ;; esac`, ahead of ever starting python3) skips
   ALL analysis — including issue-225's own unanalyzable-write-shape deny
   — whenever no literal `docs` substring appears anywhere in the raw Bash
   command text. A write-capable `-c` invocation whose target path is
   computed at interpreter runtime (e.g. `''.join(chr(c) for c in
   [...])`, spelling `docs/issue-3/reports/pwned.md` with no `docs`
   substring ever appearing in the visible command) sails through this
   fast path unconditionally, regardless of any interpreter-head-masking
   fix — confirmed live on a fresh `origin/main` checkout with a PLAIN,
   undecorated `python3 -c "..."` (no `$'...'`, no escaping, no expansion
   at all): `derived: python3 /tmp/verify_hunt_fix2.py /tmp/main_verify`
   → `rc= 0` (ALLOW) against `core/hooks/board-gate.sh` at `origin/main`
   commit `8f82765`. This is a materially different, much broader gap
   than issue-233's word-formation/interpreter-head class (it defeats
   EVERY write-shape this gate protects — heredoc, `dd`, `tee` — not only
   `-c`/`-e`), pre-dates this session's changes, and closing it means
   removing or redesigning the fast-path optimization itself (documented
   in the code as a deliberate ~50ms-startup-cost trade, "never a
   verdict") rather than a tokenizer fix. `warrant/hooks/lib/scope-gate.py`
   does NOT share this gap — it has no equivalent fast path; its
   `UNANALYZABLE_WRITE_SHAPE` check runs unconditionally and correctly
   denied the identical plain (non-`$'...'`-decorated) reproduction:
   `derived: python3 /tmp/verify_scope_chr2.py` → `rc= 2` (DENY,
   "un-analyzable write-capable shape").
2. **Pre-existing, disclosed, extended (not newly introduced or fixed).**
   `warrant/hooks/lib/scope-gate.py` has no tokenizer for FLAG words
   (only `_splice_line_continuations` feeds its HEAD-adjacent
   character-class scan); PR #354's own "Out of scope" list already named
   a quoted `-c`/`-e` flag on a literal interpreter head as an accepted
   residual, and the e95fc262.md review separately confirmed a
   backslash-escaped flag (`python3 \-c ...`) reproduces the identical
   gap. The before-landing hunt's `$'-c'` finding reproduces the same
   class on this gate too (`ansi-c-quoted-flag-word-not-caught-preexisting-gap`
   in `core/hooks/tests/run-scope-gate-tests.sh`, `want=allow` — recorded
   as the disclosed gap, not a fix). `core/hooks/board-gate.sh` does not
   share this residual: its tokenizer now resolves `$'-c'` (and any other
   quoted/escaped flag decoration) to the plain word `-c` before
   `INLINE_FLAG_WORDS` membership is checked.

## Next steps

None — this record is terminal (`loop_state: landed`). Finding 1 above
should be filed as its own issue by whoever triages this record; finding
2 needs no action beyond the disclosure already recorded.

## Verification

- `derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh`
  → `174 passed, 2 failed` (`feasibility-spikes`, `ops-postmortems` —
  identical failing-name set confirmed against a fresh `origin/main`
  worktree at commit `8f82765`, same two names, same count before this
  session's new tests: `143 passed, 2 failed`).
- `derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-scope-gate-tests.sh`
  → `76 passed, 0 failed`.
- `derived: env -u CLAUDE_PLUGIN_ROOT_CORE python3 -m pytest -q`
  → `3 failed, 79 passed` — identical failing-name set
  (`test_proposal_shape_gate_refuses_missing_sections`,
  `test_survey_order_gate_refuses_proposal_without_survey_or_skip`,
  `test_A5_trailer_gate_quote_split_commit_is_detected`) confirmed against
  the same `origin/main` worktree: `3 failed, 79 passed`, same three
  names.
- `derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-approval-gate-tests.sh` → `65 passed, 2 failed` (`checkpoint-refusal-names-await-approval`,
  `execute-without-remote`) — identical to `origin/main`.
- `derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gh-guard-tests.sh` → `54 passed, 0 failed`, identical to `origin/main`.
- `derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-dispatcher-equivalence-tests.sh` → `24 passed, 1 failed` (`approval-gate: execution write, no approvers.md -> deny`) — identical to `origin/main`.
- `derived: env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-fleet-scan-tests.sh` → `pass=26 fail=1` (`live fleet run produces 43 repo rows`, want=43 got=44) — identical to `origin/main`; monitor/watch machinery (`run-fleet-scan-tests.sh`) unbroken, same count and same pre-existing flake, not quieter.
- `run-ups-diet-tests.sh`'s "combined UPS payload <= 3072 bytes" check is
  unverifiable for a pass/fail comparison in this session: it measures the
  rendered byte size of seven UNRELATED UPS hooks (proposal-shape/
  record-shape/survey-order/terse/freelunch/scout/warrant directives —
  none of which this delivery touches) and that size is dominated by the
  ABSOLUTE CHECKOUT PATH LENGTH embedded in each hook's rendered "Read
  <file>" trigger line, not by repository content — confirmed by running
  the identical `origin/main` code from a worktree path of matching
  length (`/home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-233-secure-coding-input-validation-injection-defense-adversarial-review-samelen-pad`,
  139 chars): `derived: bash core/hooks/tests/run-ups-diet-tests.sh` on
  that `origin/main` worktree → `combined UPS bytes/turn: 3333`,
  `35 passed, 1 failed` — the SAME failure this session's own (much
  longer, ~247-char) working-tree path produces, on code this session
  never touched. Not caused by this delivery's diff.
- No overhead increase: `derived: bash /tmp/timing_probe.sh
  <this-branch-checkout>` → `100 runs: 5046ms total, 50ms avg` vs.
  `derived: bash /tmp/timing_probe.sh <origin/main-worktree>` →
  `100 runs: 4694ms total, 46ms avg` — within measurement noise (matches
  PR #358's own ~44.9ms vs ~45.8ms measurement).
- No return of the retired role/역할 axis: `derived: git diff origin/main
  -- core/hooks/lib/gate-lib.py core/hooks/board-gate.sh
  core/hooks/tests/run-board-gate-tests.sh
  core/hooks/tests/run-scope-gate-tests.sh warrant/hooks/lib/scope-gate.py
  | grep -E '^\+.*\brole\b|^\+.*역할'` → no output (zero additions).
- Acceptance check 1 (gate tests — the 4 original shapes DENIED, pure
  reads ALLOWED): the four PR #354/#358 shapes
  (`expanded-head-param-default-dash`,
  `expanded-head-cmdsub-produces-head`, `brace-expansion-null-field-head`,
  `quote-splice-single-quotes`, `backslash-escape-spelling`,
  `backslash-newline-splice`, etc.) and the pure-read forms
  (`param-expansion-path-read-allowed`, `awk-pure-read-not-overblocked`)
  all still pass in the `174 passed` run above; both full suites are
  green modulo the pre-existing, `origin/main`-identical failures cited
  above.
- Acceptance check 2 (adversarial hunt finds no remaining bypass): one
  before-landing hunt round found and this session fixed the ANSI-C
  quoting gap (see "What was done"); a second verification pass by this
  session (the runtime-computed-path reproduction) found the pre-existing,
  out-of-scope board-gate.sh fast-path gap (Open finding 1) but confirmed
  it is unrelated to and pre-dates the word-formation class this issue
  targets, and confirmed scope-gate.py does not share it.

skill-verdict: secure-coding-input-validation-injection-defense — applied: invoked; confirmed the landed allowlist-complement structure (denylist→allowlist for the interpreter-head character set) already satisfies rules 1/2 before narrowing the tokenizer boundary compared against it; no structural change made as a result
skill-verdict: adversarial-review — not-applicable: this delivery responds to an adversarial review already performed by a separate session (e95fc262.md) and dispatches its own before-landing warrant-hunter for fresh adversarial coverage of the new code; running the full adversarial-review skill workflow on my own delivery in the same session would not be structurally independent
skill-verdict: verify-finding-record — not-applicable: this repo's issue-233 convention records defect findings in adversarial-review-*.md files, not docs/issue-<n>/reports/defect-verification.md; the finding under fix here was already reproduced and recorded by the upstream review (e95fc262.md), not a fresh reproduction this record initiates
other mounted skills: not triggered
