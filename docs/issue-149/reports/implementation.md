---
code_under_review:
  - core/hooks/board-gate.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - docs/handbooks/board-gate-tests.md
loop_state: delivered
---

# Implementation record — issue-149

Phase 2, approved proposal:
`docs/issue-149/proposals/2026-08-07-board-gate-url-docs-tail-false-positive.md`.

## Why

`board-gate.sh`'s docs-tail extractor found the substring `docs/` anywhere
in a Bash-segment token with no concept of "this token is a URL, not a
repository path," so an external URL whose path contained `/docs/` got
misclassified as an out-of-bucket board write and denied — a plain read of
an external page failed for a reason unrelated to any actual write. The
approved proposal narrows classification (URL tokens stop being docs/
candidates) while leaving the deny path for genuine out-of-bucket writes
untouched.

## What was done

1. `core/hooks/board-gate.sh`:
   - Widened the `own_hits` regex char class from `[\w./~$-]` to
     `[\w./~$:-]` so a URL's scheme (`https:`) is captured as part of the
     match instead of severing the token at the colon.
   - Added `URL_SCHEME` (`^[A-Za-z][A-Za-z0-9+.-]*://`) and a check inside
     `_docs_relative_tail`: a token matching that pattern, or containing
     `://` before its first `docs/` occurrence, returns `""` immediately
     — the same "no docs/ token here" result already returned when the
     token carries no `docs/` substring at all. No new allow path; the
     token simply stops being a candidate.
2. `core/hooks/tests/run-board-gate-tests.sh`: added
   `url-docs-path-1`/`url-docs-path-2` (the issue's own two repro URLs,
   `allow`) and negative-space siblings `url-docs-negative-write`/
   `url-docs-negative-issue` (genuine out-of-bucket repository writes,
   `deny`, unchanged).
3. `docs/handbooks/board-gate-tests.md`: documented the fix, its cause,
   and scope item 2's survey findings, following this file's established
   per-issue convention.

## Scope item 2 — other find-anywhere false-positive shapes

Reported, not fixed (per the proposal's Out of scope):

1. Directory names merely *ending in* `docs` (e.g. `mydocs/x.md`,
   `autodocs/`) — `DOCS = "docs/"` is a plain substring search, so this is
   the same find-anywhere root cause as the URL case, reachable without
   any URL involved. Needs a path-component-boundary check; no concrete
   over-block observed in real use.
2. A `docs/`-shaped substring inside a quoted literal that is not a path
   (e.g. `grep -n "see docs/api reference" file.txt`) — `own_hits` runs on
   raw segment text, not a quote-stripped view (unlike `FILE_REDIR`, which
   already routes through `gate_lib.gate_outside_quotes` per issue-94).
3. Examined and ruled out: the `_cd_target`/`cd_tail` path does not carry
   the URL false positive (a `cd` to a URL is not a real shell operation);
   it carries finding 1 as the same root cause, not a new one.

## Test results (as run)

- `bash core/hooks/tests/run-board-gate-tests.sh` → `98 passed, 0 failed`
  (94 pre-existing + 4 new issue-149 cases).
- `bash core/hooks/tests/run-role-gates-tests.sh` → `47 passed, 0 failed`
  (observed count; differs from the prompt's stated expectation of 49 —
  reporting what was actually run, not the expectation).

## What did not work

None.

## Open findings

None open.

## Hunt dispatch note

Before-landing hunter dispatch attempted twice (stance 0: gate bypassability);
`hunt-guard.sh` refused both attempts — another hunter was already running
session-wide ("one at a time"). Per warrant-directive, a second dispatch is
never forced while one is running. No before-landing hunt was recorded by
this session for this transition.

## Closed checks

- closed_checks: url-docs-path-1, url-docs-path-2,
  url-docs-negative-write, url-docs-negative-issue — all four run as real
  subprocess cases in `run-board-gate-tests.sh`, code_under_review as
  listed in this record's frontmatter.
