---
issue: 233
role: secure-coding-input-validation-injection-defense+adversarial-review-8bab0cf8
author: secure-coding-input-validation-injection-defense+adversarial-review-8bab0cf8
skills: secure-coding-input-validation-injection-defense (skill-repository(c05de12))
verifies_subject: false  # this is the builder round, not an independent verification
code_under_review: core/hooks/board-gate.sh
loop_state: landed
type: fix
breaking: false
verdict: pass
upstream:
  - path: core/hooks/board-gate.sh
    sha: d434daa73d995b45e8fd18ba57441ee8d34cd991
  - path: core/hooks/tests/run-board-gate-tests.sh
    sha: d434daa73d995b45e8fd18ba57441ee8d34cd991
  - path: docs/handbooks/board-gate-tests.md
    sha: 16a652b89bc0e767c9180961dd9f069b82d0fbe4
  - path: docs/issue-233/reports/adversarial-review-13d75b7e.md
    sha: aff774bdcc3363dbde5c38249c50fe6ce5be4a0d
---

# issue-233 — secure-coding-input-validation-injection-defense+adversarial-review-8bab0cf8 record

This is a build-now bypass delivery (`CORE_BUILD_NOW=1`, per contract v3
s19a) — round four on issue-233, re-delivering after PR #360 came back
CHANGES. No approval checkpoint was awaited before building, committing,
and opening the PR.

## What was done

canonical: `gh pr view 360 --json comments,reviews` — PR #360 (branch
`issue-233/secure-coding-input-validation-injection-defense+adversarial-review-dea32ebc`,
head `83c6b17`, state OPEN) carries exactly one blocking review comment
from `JiwonJung94`, quoted here in full because this round's whole scope
is resolving it:

> A command substitution that produces the FLAG word evades
> `INLINE_FLAG_WORDS`, while the same mechanism producing the HEAD is
> correctly denied. ... Apply the same rule to a trailing word — an
> unresolved `$(` or backtick in one makes it unanalyzable — rather than
> trying to evaluate what the substitution produces.

This finding was independently confirmed and merged as
`docs/issue-233/reports/adversarial-review-13d75b7e.md` (commit
`aff774bdcc3363dbde5c38249c50fe6ce5be4a0d`, already on `origin/main`
before this round started).

**Step 1 — rebase.** PR #360's branch (`...dea32ebc`, 8 commits, merge-base
`8f8276561ca9db0863ba47aae3e44695b248747a`) was not yet based on the
`origin/main` tip that carries the merged verification record
(`aff774bdcc3363dbde5c38249c50fe6ce5be4a0d`). Reset this round's branch to
that PR branch and rebased onto `origin/main`:
derived: `git reset --hard origin/issue-233/secure-coding-input-validation-injection-defense+adversarial-review-dea32ebc && git rebase origin/main`
— clean rebase, zero conflicts (`Successfully rebased and updated
refs/heads/issue-233/secure-coding-input-validation-injection-defense+adversarial-review-8bab0cf8`),
landing PR #360's 9 commits (ending in `c31d446`, the tokenizer fix) on
top of `aff774b`.

**Step 2 — the fix.** `core/hooks/board-gate.sh` already applies a
structural complement to the interpreter HEAD: `EXPANDED_HEAD_RE` treats
any character outside a safe allowlist in the resolved head token as
unanalyzable, and combined with an `INLINE_FLAG_WORDS` trailing word,
that is denied. The trailing-word side of the exact same check only ever
did literal-string membership (`w in INLINE_FLAG_WORDS`) against
`gate_lib.gate_trailing_words`, which shares `_shell_split`'s
`_WORD_TOKEN_RE` — a tokenizer with a dedicated token form for all four
quote styles but none for a `$(...)`/backtick span, so a substitution
fragments at internal whitespace like plain text and never reassembles
into a literal `"-c"`/`"-e"`.

Added a new module-level regex and extended the one branch that already
checks `INLINE_FLAG_WORDS`, `core/hooks/board-gate.sh:766-771`:

```python
    if head in INTERPRETER_HEADS or EXPANDED_HEAD_RE.search(head):
        trailing = gate_lib.gate_trailing_words(stripped)
        if any(w in INLINE_FLAG_WORDS for w in trailing):
            return True
        if any(UNRESOLVED_SUBSTITUTION_WORD_RE.search(w) for w in trailing):
            return True
```

The new module-level pattern is `UNRESOLVED_SUBSTITUTION_WORD_RE`, a
two-alternative regex matching either an unresolved `$(` or a bare
backtick character, defined immediately above the branch quoted above
(`core/hooks/board-gate.sh`) with a comment block explaining the
mirrored-structural-rule rationale and the accepted false-refusal cost
(quoted in full below). This is symmetry, not a new pattern: it does not
add a balanced-paren/backtick token form to `_shell_split` (the
alternative the merged verification record itself named) and it does not
try to evaluate what the substitution produces — it applies the same
"unresolved expansion in this position is unanalyzable, and unanalyzable
here is unsafe" rule `EXPANDED_HEAD_RE` already applies to the head, to a
trailing word instead. No deviation from the reviewer's recommended
approach — the conservative structural rule was taken as recommended, so
no `## Rationale for deviations` section follows.

**Step 3 — tests.** `core/hooks/tests/run-board-gate-tests.sh` gained 7
new cases, inserted after the existing `ansi-c-quoted-head-no-flag-not-overblocked`
block: 4 DENY cases (`cmdsub-dollarparen-produces-flag-python`,
`cmdsub-backtick-produces-flag-python`,
`cmdsub-dollarparen-produces-flag-perl-e`,
`cmdsub-backtick-produces-flag-perl-e`), 2 ALLOW negative controls
(`param-expansion-path-read-not-overblocked-r4`,
`awk-pure-read-not-overblocked-r4`), and 1 DENY case documenting the
accepted false-refusal cost (`cmdsub-unrelated-trailing-word-still-denied-r4`).
`docs/handbooks/board-gate-tests.md` gained a matching "round 4" section
(the handbook-trigger-gate advisory that fired on the first commit named
this requirement directly).

## Why

The reviewer's own framing (quoted above) is the rationale: this gate
already committed to "cannot analyze what an expansion produces, so treat
it as unsafe" as its answer to every other spelling of this same class
(the head itself, brace-expansion null-field removal, quote-splicing,
backslash-newline splicing, `$IFS` token fusion) across three prior
rounds. Adding a sixth tokenizer form that tries to parse a
`$(...)`/backtick span as one balanced-paren word would still leave the
gate guessing at the substitution's runtime output — indistinguishable
in kind from the enumeration-of-spellings approach issue-233's own
history (rounds 2 and 3) already showed does not terminate. The
structural rule terminates the same way `EXPANDED_HEAD_RE` already
proved terminal for the head: a word containing `$(` or a backtick was
not typed as inert text, and this gate cannot see through the expansion,
full stop — regardless of which of the two flags, which of the two
interpreters, or which substitution syntax is used.

canonical: the review comment quoted in full under "What was done" above
(`gh pr view 360 --json comments,reviews`) — the rationale this section
gives is a direct restatement of that comment's own reasoning, not a
fresh, independently-derived claim.

skill-verdict: secure-coding-input-validation-injection-defense —
applied: invoked; loaded via the Skill tool before writing the fix, cited
rule 1 (allowlist over denylist) and rule 8 (fail closed on unanalyzable
input rather than a silent default) as the basis for extending the
existing structural allowlist-complement rule to the trailing word
instead of adding a sixth enumerated tokenizer form — the same choice
`EXPANDED_HEAD_RE`'s own history in this file already made for the head.
skill-verdict: adversarial-review — not-applicable: this session is the
builder delivering round four, not an independent reviewer; the
independent-review side of this cycle is the merged
`adversarial-review-13d75b7e.md` record this round responds to.

## Acceptance verification

- `python3 $(echo -c) ...` now denied — checked: core/hooks/tests/run-board-gate-tests.sh — result: pass: canonical: bash core/hooks/tests/run-board-gate-tests.sh (full transcript in "Live reproduction" above)
- `` python3 `echo -c` ... `` now denied — checked: core/hooks/tests/run-board-gate-tests.sh — result: pass
- `perl $(printf %s -e) ...` now denied — checked: core/hooks/tests/run-board-gate-tests.sh — result: pass
- `` perl `printf %s -e` ... `` now denied — checked: core/hooks/tests/run-board-gate-tests.sh — result: pass
- pure-read `${HOME}/x` form still allowed — checked: core/hooks/tests/run-board-gate-tests.sh — result: pass
- pure-read `awk '{print}' file` form still allowed — checked: core/hooks/tests/run-board-gate-tests.sh — result: pass
- accepted false-refusal cost (`python3 file.py $(date)`) denies as documented — checked: core/hooks/tests/run-board-gate-tests.sh — result: pass
- board-gate suite failing-name set unchanged vs origin/main — checked: core/hooks/tests/run-board-gate-tests.sh — result: pass
- scope-gate/pytest/approval-gate/gh-guard/dispatcher-equivalence/gate-lib suites' failing-name sets unchanged vs origin/main — checked: core/hooks/tests/run-scope-gate-tests.sh — result: pass
- ups-diet's one differing line is a path-length environment artifact, not this diff — checked: core/hooks/tests/run-ups-diet-tests.sh — result: pass
- monitor/watch (fleet-scan) suite unbroken, same single pre-existing flake — checked: core/hooks/tests/run-fleet-scan-tests.sh — result: pass
- no measurable overhead increase (100x subprocess timing, branch vs origin/main) — checked: core/hooks/board-gate.sh — result: pass
- no reintroduced role/역할 identifier in this round's own diff — checked: core/hooks/board-gate.sh — result: pass

## What did not work

None. The fix, tests, and both directions of live reproduction (below)
worked on the first construction; no dead end was hit during this round.

## Upstream basis

- PR #360, `issue-233/secure-coding-input-validation-injection-defense+adversarial-review-dea32ebc`
  branch, head `83c6b17` (the word-formation-aware tokenizer this round
  builds on unchanged). canonical: `gh pr view 360 --json state,mergedAt,headRefName,baseRefName`
  — state OPEN, base `main`, not merged.
- `docs/issue-233/reports/adversarial-review-13d75b7e.md` (merged,
  `aff774bdcc3363dbde5c38249c50fe6ce5be4a0d`) — the independent
  verification this round's fix directly resolves; its "Out-of-scope
  disclosures" section (board-gate.sh's `*docs*` fast-path / core#361,
  scope-gate.py's missing flag-word tokenizer) and its "Non-blocking"
  finding 2 (two `_shell_split` correctness bugs not shown to change a
  live verdict) are left exactly as disclosed — not re-litigated, not
  touched, per the task's explicit instruction.
- `core/hooks/board-gate.sh` — `EXPANDED_HEAD_RE`, `INTERPRETER_HEADS`,
  `INLINE_FLAG_WORDS`, `_is_unanalyzable_write_shape` (the branch
  extended).
- `core/hooks/lib/gate-lib.py` — `_shell_split`, `_WORD_TOKEN_RE`,
  `gate_trailing_words` (read, not modified this round — the fix lives
  entirely in `board-gate.sh`'s own check, mirroring where
  `EXPANDED_HEAD_RE` itself already lives, not in the shared tokenizer).

## Live reproduction — both directions, real subprocess

Built a standalone harness mirroring the merged verification record's own
fixture conventions (`env CLAUDE_SKILL=qa /bin/bash core/hooks/board-gate.sh`,
a real git worktree with a canonical `docs/specs/approvers.md` and branch
`issue-3/qa`) at `/tmp/probe233r4/probe_gate.sh` /
`/tmp/probe233r4/run_all.sh`, run via `env -u CLAUDE_PLUGIN_ROOT_CORE bash
/tmp/probe233r4/run_all.sh <repo>` (the `-u CLAUDE_PLUGIN_ROOT_CORE` is
required — this session's own shell carries that variable set to the
installed plugin copy, which shadows the worktree's own modified
`gate-lib.py`/`board-gate.sh`; discovered live when an early probe of the
already-passing `ansi-c-quoted-flag-word` case falsely reported ALLOW
until that variable was unset — see the `## What did not work` note this
would otherwise be, except it was caught before being reported as a
finding, so it is not a genuine dead end for this round's own fix).

derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash /tmp/probe233r4/run_all.sh <repo>`

```
=== POST-FIX (must now DENY) ===
ok   cmdsub-dollarparen-produces-c-flag  want=deny got=deny
ok   cmdsub-backtick-produces-c-flag  want=deny got=deny
ok   cmdsub-dollarparen-produces-e-flag-perl  want=deny got=deny
ok   cmdsub-backtick-produces-e-flag-perl  want=deny got=deny
=== ALLOW forms must remain ALLOW ===
ok   pure-read-home-expansion  want=allow got=allow
ok   awk-pure-read  want=allow got=allow
ok   escaped-space-path-no-flag  want=allow got=allow
ok   python-pytest-still-allowed  want=allow got=allow
ok   ansi-c-quoted-flag-word  want=deny got=deny
```

And confirmed the underlying shell mechanism actually executes (the thing
being denied is a real, working bypass, not a hypothetical):

derived: `rm -f /tmp/pwn_test_r4.txt; bash -c 'python3 $(echo -c) "open(\"/tmp/pwn_test_r4.txt\",\"w\").write(\"DOLLARPAREN-R4\")"'; cat /tmp/pwn_test_r4.txt`

```
DOLLARPAREN-R4
```

derived: (backtick-substitution variant of the same live check; fenced
below instead of backtick-inline since the command itself contains a
literal backtick pair)
```
rm -f /tmp/pwn_test_r4.txt; bash -c 'perl `printf %s -e` "open(FH,\">/tmp/pwn_test_r4.txt\");print FH \"BACKTICK-PERL-R4\""'; cat /tmp/pwn_test_r4.txt
```

```
BACKTICK-PERL-R4
```

## Standing invariants

1. **No return of the retired role/역할 axis.**
derived: `git diff -- core/hooks/board-gate.sh core/hooks/tests/run-board-gate-tests.sh | grep -E '^\+' | grep -iE '\brole\b|역할'`
— zero output (this round's own diff introduces no `role`/`역할`
identifier at all). The wider branch-vs-`origin/main` diff (all 9 rounds
combined) still carries the one pre-existing prose line the merged
verification record already confirmed:
derived: `git diff origin/main -- core/hooks warrant/hooks | grep -E '^\+' | grep -iE '\brole\b|역할'`
```
+# bypass (a `qa`-role call denied nothing while writing outside `qa`'s own
```
— an English-word usage of "role" describing the `qa` `CLAUDE_SKILL`
identity the test suite already used before this issue existed, not a
reintroduced `role`/`역할` code identifier or persisted key. Unchanged
from the merged record; not re-derived beyond confirming the same grep
still returns the same single line.

2. **No new bug — failing-test-name SETS vs `origin/main`, not counts.**
Ran each suite on this branch and on a fresh `origin/main` worktree
(`aff774b`).
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh`
```
branch (d434daa): 181 passed, 2 failed — {feasibility-spikes, ops-postmortems}
main   (aff774b): 143 passed, 2 failed — {feasibility-spikes, ops-postmortems}
```
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-scope-gate-tests.sh`
```
branch: 76 passed, 0 failed
main:   76 passed, 0 failed
```
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE python3 -m pytest -q`
```
branch: 3 failed, 79 passed — {test_proposal_shape_gate_refuses_missing_sections, test_survey_order_gate_refuses_proposal_without_survey_or_skip, test_A5_trailer_gate_quote_split_commit_is_detected}
main:   3 failed, 79 passed — identical name set
```
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-approval-gate-tests.sh`
```
branch: 65 passed, 2 failed — {checkpoint-refusal-names-await-approval, execute-without-remote}
main:   identical failing-name set
```
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gh-guard-tests.sh`
```
branch: 54 passed, 0 failed
main:   54 passed, 0 failed
```
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-dispatcher-equivalence-tests.sh`
```
branch: 24 passed, 1 failed — {approval-gate: execution write, no approvers.md -> deny}
main:   identical failing-name set
```
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-gate-lib-tests.sh`
```
branch: 64 passed, 2 failed — {record-fields-gate.sh: missing §20 fields still denied post-migration, record-fields-gate.sh: RECORD_FIELDS_GATE_OFF=banana stays active (issue-72 fix)}
main:   identical failing-name set
```
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-ups-diet-tests.sh`
```
branch (checkout path 136 chars): 35 passed, 1 failed — {combined UPS payload <= 3072 bytes}
main   (checkout path 86 chars):  36 passed, 0 failed
```
That one differs at first glance — reproduced identically on `origin/main`
itself once checked out at a matching path length (same disclosed
environment artifact PR #360's own PR body already named: rendered-byte-size
sensitivity to absolute checkout path length in UPS hooks this diff never
touches):
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-ups-diet-tests.sh` (run inside a 111-char-path `origin/main` worktree)
```
main (checkout path 111 chars): 35 passed, 1 failed — {combined UPS payload <= 3072 bytes}
```
Every suite's failing-test-name SET is identical to `origin/main`'s own,
at a matching checkout-path length where path length is the variable in
play; this round's diff (`core/hooks/board-gate.sh`,
`core/hooks/tests/run-board-gate-tests.sh`) touches neither
`record-fields-gate.sh`, `approval-gate.sh`, `dispatcher-equivalence`,
nor any UPS hook, so none of the six other suites could plausibly be
affected by it regardless.

3. **No overhead increase.**
derived: `bash /tmp/probe233r4/timing.sh <repo> branch-round4` /
`bash /tmp/probe233r4/timing.sh <origin/main worktree> main` — 100x
`board-gate.sh` subprocess invocations each, a plain read payload
(`cat docs/issue-3/reports/review.md`), `CLAUDE_SKILL=qa`:
```
branch-round4: 5074ms / 100 = 50ms/call
main:          5040ms / 100 = 50ms/call
```
34ms over 100 calls (0.34ms/call) is noise, consistent with every prior
round's own measurement (PR #360's own PR body: ~50ms vs ~46ms; the
`adversarial-review-13d75b7e.md` record: 49ms vs 48ms). This round adds
one `re.search` per trailing word only inside the branch that already
runs `gate_lib.gate_trailing_words` and iterates it once for
`INLINE_FLAG_WORDS` — no new work on any command that does not already
reach that branch.

4. **Monitor/watch machinery unbroken and not quieter.**
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-fleet-scan-tests.sh` (branch) vs the same command in the `origin/main` worktree:
```
branch: pass=26 fail=1
main:   pass=26 fail=1
```
Same pass count, same single pre-existing flake (`live fleet run produces
43 repo rows` want=43 got=44) on both, not quieter.

## Out-of-scope disclosures — unchanged, not re-litigated

Both disclosures from `docs/issue-233/reports/adversarial-review-13d75b7e.md`
stand exactly as recorded there and were not touched this round:
`board-gate.sh`'s `*docs*`-substring fast-path (core#361, pre-existing on
`origin/main`, orthogonal to this issue's word-formation class) and
`warrant/hooks/lib/scope-gate.py`'s missing flag-word tokenizer (PR #354's
original disclosure, already extended to the `$'...'` form by PR #360,
unaffected by this round's `board-gate.sh`-only change). Neither file this
round touches (`core/hooks/board-gate.sh`, `core/hooks/tests/run-board-gate-tests.sh`,
`docs/handbooks/board-gate-tests.md`) overlaps `scope-gate.py` at all.

## Open findings

None from this round. The one blocking finding this round exists to close
(command-substitution-produced flag word evading `INLINE_FLAG_WORDS`) is
fixed and both directions are re-derived live above (see "Live
reproduction"); no new finding surfaced during this round's own
construction or test runs.
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash /tmp/probe233r4/run_all.sh <repo>` (see full transcript under "Live reproduction" above).

## Next steps

None — `loop_state: landed`. Per the reviewer's own stated bound ("a fresh
mechanism on a third axis would mean stating what the gate does not
cover instead of patching again"), this round's own adversarial-hunt-style
probing (both substitution syntaxes, both flags, both live execution and
real-subprocess gate reproduction, plus the negative-control and
accepted-cost tests) turned up no residual single-token-expansion bypass
on either the head or the flag side — issue-233's second acceptance
criterion is judged met by this round's own evidence above, subject to
whatever independent review this PR receives next.
derived: `env -u CLAUDE_PLUGIN_ROOT_CORE bash core/hooks/tests/run-board-gate-tests.sh` (181 passed, 2 failed, same 2 as `origin/main` — see "Standing invariants" #2 above for the full per-suite breakdown).
