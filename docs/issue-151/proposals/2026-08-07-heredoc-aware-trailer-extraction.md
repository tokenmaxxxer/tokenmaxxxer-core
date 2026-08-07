files:
- core/hooks/trailer-gate.sh
- core/hooks/tests/run-role-gates-tests.sh
- docs/handbooks/role-gates-tests.md

Skip condition (scout-directive): pure bugfix — issue #151 fully specifies
the defect and the fix direction with no open design decision; see
docs/issue-151/reports/implementation/survey.md.

## Request

Fix `trailer-gate.sh` (#151): 4 of 9 observed refusals in one afternoon were
the gate refusing a heredoc-supplied multi-line `-m` commit message on *how*
it was passed rather than on its content, even though the trailer was
present in the message. Determine whether the heredoc body is statically
reachable in the Bash command string at all; if it is, verify it; if it
genuinely is not, name and verify a working idiom instead.

## Constraints

- Weaken no check: a heredoc message missing the `Subject: issue-<n>`
  trailer must still be denied (issue's own scope item 3).
- Any fix must be demonstrated to satisfy both this gate and the Bash tool
  harness's own static-analysis constraint — not merely this gate in
  isolation (issue's own scope item 2).
- Stay inside the three-file write set.

## Rationale

Considered rewriting the whole `-m` extraction path around a full
heredoc-aware POSIX shell tokenizer (e.g. hand-rolling or vendoring a
proper shell-syntax parser) instead of a targeted regex. Rejected: the
issue scopes exactly one idiom — `-m` wrapping a command substitution
around a quoted heredoc — and the survey confirmed `shlex.split()` already
parses that idiom correctly whenever the heredoc body contains no
unescaped double quote. A full parser rewrite would touch far more surface
than the actual defect (bodies containing `"`), add real complexity and a
new failure surface of its own, and gain nothing the issue asked for. A
regex anchored on the heredoc terminator line, tried before `shlex`, fixes
exactly the reachable-but-mis-tokenized case and leaves every other
invocation shape on the existing, already-correct `shlex` path.

Considered fixing this by *not* using shlex at all and just regex-scanning
the whole command for any line matching `^\s*Subject:\s*issue-N\s*$`,
skipping structured `-m` extraction entirely. Rejected: that would find a
`Subject:` trailer anywhere in the command string, including inside a
comment, an unrelated heredoc, or an entirely different git object being
constructed in the same Bash call — it verifies the trailer is *present
somewhere*, not that it is part of *this commit's message*, which is a
fail-open weakening the issue explicitly rules out (scope item 3).

## What will be done

1. In `trailer-gate.sh`'s Python payload, add a regex
   (`-m\s+"\$\(\s*cat\s+<<-?\s*(['"]?)(\w+)\1\s*\n(.*?)\n[ \t]*\2[ \t]*\n?\s*\)"`,
   `re.DOTALL`) matched against the raw `command` string before the
   existing `shlex.split()` call. On a match, the captured heredoc body
   becomes the message to check directly — bypassing `shlex` for this
   idiom entirely, so an embedded `"` in the body cannot break
   tokenization or truncate the extracted message.
2. Run the existing `Subject: issue-<n>` presence/absence check against
   that extracted body exactly as today: present -> allow, absent -> deny
   with the existing message-lacks-trailer text.
3. Leave the `shlex`-based path untouched as the fallback for every
   command that doesn't match the heredoc pattern (plain `-m "text"`,
   `-F file`, etc.) — no existing behavior for those shapes changes.
4. Add two pinning tests to `run-role-gates-tests.sh` using the existing
   `run_trailer` helper: the heredoc idiom with an embedded double-quoted
   phrase in the body plus the `Subject:` trailer -> allow; the same body
   without the trailer -> deny. Both exercise the exact refused command
   shape from the issue via a real subprocess call into `trailer-gate.sh`.
5. Document the heredoc-extraction behavior in
   `docs/handbooks/role-gates-tests.md`, including why `shlex` alone was
   insufficient.

## Out of scope

- The Bash tool harness's own static-analysis refusals ("cannot be
  statically analyzed" / "multiple operations") — these are not part of
  `trailer-gate.sh` and are not owned by this repo's hooks; survey
  confirmed the canonical heredoc idiom, issued as one standalone Bash
  call, already passes the harness today. No harness-side change is
  proposed or needed.
- `-F`/`--file`/editor-supplied messages — genuinely unverifiable
  statically (the content lives outside the command string entirely); the
  existing deny for those stays as-is, per the issue's scope item 3 (no
  fail-open).
- Per-rulebook vendored copies of this gate, if any exist outside
  `core/hooks/` — this file is core canon (issue-66); vendored-copy sync is
  a separate mechanism untouched here.

## How you'll know it worked

- `bash core/hooks/tests/run-role-gates-tests.sh` passes, including the two
  new issue-151 pinning tests, with zero regressions in the other 47+
  existing cases.
- Manual reproduction, recorded in the survey: the exact refused command
  shape from the issue (heredoc body containing a quoted phrase, `Subject:
  issue-N` trailer present) now allows; the same shape without the trailer
  still denies.
- A re-scan of session logs after landing (per the issue's acceptance)
  reporting Class A refusals at zero and the Class B count stated
  separately, deferred to a later observation window — not something this
  single-session fix can measure directly.
