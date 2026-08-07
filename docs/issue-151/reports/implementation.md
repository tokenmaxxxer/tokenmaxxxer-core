---
code_under_review: `core/hooks/trailer-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`
loop_state: landed
---

upstream: docs/issue-151/proposals/2026-08-07-heredoc-aware-trailer-extraction.md, sha: same-commit

## What was done

Fixed `trailer-gate.sh` (#151), the heredoc-supplied commit message defect:

1. Added a regex
   (`-m\s+"\$\(\s*cat\s+<<-?\s*(['"]?)(\w+)\1\s*\n(.*?)\n[ \t]*\2[ \t]*\n?\s*\)"`,
   `re.DOTALL`) matched against the raw Bash `command` string before the
   existing `shlex.split()` call. On a match, the captured heredoc body is
   used directly as the message to check for `Subject: issue-<n>` — the
   `shlex`-based tokenizer is bypassed entirely for this idiom, so a body
   containing an unescaped double quote (an ordinary, realistic phrasing
   like `Rename "foo" to "bar"`) can no longer break tokenization or
   silently truncate the extracted `-m` value.
2. Every other invocation shape (plain `-m "text"`, `-F file`, editor) is
   untouched — the pre-existing `shlex`-based path still runs when the
   heredoc regex doesn't match, with identical behavior to before.
3. Added two pinning tests to `run-role-gates-tests.sh` using the existing
   `run_trailer` helper, exercising the exact refused command shape from
   the issue as a real subprocess call: the heredoc idiom with an embedded
   double-quoted phrase in the body plus the `Subject:` trailer -> allow;
   the same body without the trailer -> deny (companion test proving the
   fix is not a fail-open).
4. Documented the extraction behavior and why `shlex` alone was
   insufficient in `docs/handbooks/role-gates-tests.md`.

## Why

Issue #151 counted 4 of 9 `trailer-gate` refusals in one afternoon as
refusing a message on *how* it was passed (heredoc / command substitution)
rather than on its content, even though the message's trailer was present
in the command string the whole time. Scope item 1 required establishing —
with evidence — whether the parser could reach the heredoc body. Reproduced
directly against the gate (synthetic PreToolUse payloads on stdin,
bypassing the Bash tool so the gate's own behavior is isolated): the
canonical idiom with a clean body already parsed correctly via `shlex`
(rc=0 allow, rc=2 deny-when-missing, both confirmed); the same idiom with
an embedded double quote in the body broke `shlex.split()` — either a
`ValueError` ("could not be tokenized") or a silently mis-split `-m`
token — because `shlex` has no concept of a heredoc and re-tokenizes the
already-materialized body text as fresh shell syntax. That reproduces both
refusal messages quoted in the issue without `-F`/editor ever being used.
So the information was reachable; the existing extraction *method* was
wrong for this idiom. Fixed by extracting the heredoc body directly via a
terminator-anchored regex instead of routing it through `shlex`.

Scope item 2 (Bash-harness constraint) was also verified directly: a
single, standalone `git commit -m "$(cat <<'EOF' ...EOF)"` command, issued
as the sole content of one Bash tool call, was accepted by this session's
own Bash harness (it ran and reached `git`, failing only on nothing being
staged — not a harness refusal). The harness's "cannot be statically
analyzed" / "multiple operations" refusals reproduced reliably only when
that heredoc command was chained with other statements or prefixed with
inline env-var assignments in the same call — not from the heredoc idiom
alone. So a compliant multi-line commit is reachable under both
constraints simultaneously: the canonical idiom, issued as one standalone
Bash call, satisfies both the harness and (after this fix) the gate,
including bodies that quote text. This record's own commit uses that exact
idiom.

## What did not work

- First attempt at reproducing the issue used a single Bash call chaining
  `cd`, `git init`, and a heredoc together (`cmd1; cmd2; ...`) — the Bash
  tool's own harness refused it as "Contains shell syntax (string) that
  cannot be statically analyzed" before any of it ran, including the setup
  steps. Expected: the compound script to execute and let me inspect the
  gate's behavior on the heredoc. Actual: nothing executed; had to split
  into single-statement Bash calls (this reproduction *is* scope item 2's
  finding, not a dead end — see "Why" above).
- Second attempt prefixed a single command with inline `env`/export
  variable assignments (`CLAUDE_ROLE=x CLAUDE_PROJECT_DIR=y bash script`)
  in one Bash call — also refused by the harness as multiple operations.
  Worked once moved into a wrapper script file invoked as `bash
  run_gate.sh`, with the env assignments as separate lines inside the
  script rather than command-line prefixes.

## Doc placement

- [x] `docs/handbooks/role-gates-tests.md` updated: documents the
  heredoc-body regex extraction, why `shlex` alone was insufficient, and
  that the `shlex` fallback path is unchanged for every other shape.
- No decision record applies: no new env var, config key, dependency,
  migration, or changed public signature/wire format — the gate's
  externally-observable pass/deny behavior for every previously-passing
  and previously-failing case is unchanged; only the heredoc-with-quotes
  case, previously mis-refused, now resolves correctly.
- No report doc applies: the survey (`docs/issue-151/reports/implementation/survey.md`)
  already carries the reproduction evidence the issue's scope items asked
  for; no separate benchmark/investigation artifact is warranted.

## Open findings

None.

## Hunt

No warrant-hunter dispatch this session: this is a headless, single-shot
session (contract v3 s22) with no later turn to consume a background
dispatch's result before the session ends, so per the warrant directive's
own subordination clause the dispatch is skipped rather than fired and
abandoned. Verification instead ran directly and repeatedly against the
real gate via subprocess (both the ad hoc synthetic-payload
reproduction in the survey and the `run-role-gates-tests.sh` pinning
tests, 49/49 passing after the change, no regressions in the other 47
pre-existing cases). `verify` should re-derive coverage from the diff and
the new pinning tests rather than cite this record's own test run as
closed.
