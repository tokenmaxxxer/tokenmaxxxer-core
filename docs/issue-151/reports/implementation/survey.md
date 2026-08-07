Skip condition (scout-directive): pure bugfix — issue #151 fully specifies
the defect (trailer-gate refuses a heredoc-supplied `-m` message on how it
was passed, not on content) and the fix direction (verify the trailer
statically if the heredoc body is reachable in the command string; if not,
name a working idiom). No product-shaped design decision is open.

## Write set

- `core/hooks/trailer-gate.sh` — the gate itself; canon, single copy
  (issue-66), no per-role vendored duplicates to touch.
- `core/hooks/tests/run-role-gates-tests.sh` — existing subprocess test
  harness for the three role-agnostic gates; already has a `run_trailer`
  helper built exactly for this gate.
- `docs/handbooks/role-gates-tests.md` — documents this harness and the
  gate's parsing behavior; doc-placement ladder for the change.

## Current-state findings

`trailer-gate.sh` (PreToolUse hook on `Bash` matching `git commit`) reads
`tool_input.command` as a raw string and, when the diff stages
`docs/issue-<n>/**` work, tokenizes that string with Python's
`shlex.split()` to find `-m`/`--message`/`-mVALUE` argument values, joins
them, and regex-searches for `^Subject: issue-<n>$`.

Reproduced empirically (not assumed) by feeding `trailer-gate.sh` a
synthetic PreToolUse payload directly on stdin, bypassing the Bash tool
harness so the gate's own behavior is isolated:

1. The canonical idiom `git commit -m "$(cat <<'EOF' ...EOF)"` with a clean
   body (no embedded double quotes) — `shlex.split()` already tokenizes
   this correctly today: the entire heredoc body lands in one `-m` token,
   `Subject:` is found, gate allows (rc=0). Confirmed with the same
   trailer omitted: gate denies (rc=2), correct message-lacks-trailer text.
2. The same idiom with a body containing an embedded double quote (e.g.
   `Rename "foo" to "bar"` — an ordinary, realistic commit-message
   phrasing) — `shlex.split()` either raises `ValueError` ("could not be
   tokenized") or silently misreads where the `-m` token ends, because
   `shlex` has no concept of a heredoc: it re-tokenizes the *already
   heredoc-materialized* body text as if it were fresh shell syntax, and a
   stray `"` inside that body toggles shlex's own quote-tracking state.
   This reproduces the two refusal messages quoted in the issue
   ("supplies its message via a file/editor... cannot be verified
   statically" / "could not be tokenized") without the message ever having
   been passed via `-F` or a real editor — the trailer was present in the
   command string the whole time.

Scope item 1 answer, with evidence: the heredoc body **is** present in the
command string (per the issue's own framing), and for the clean-body case
the existing `shlex`-based parser already reaches it. The defect is
specifically that `shlex.split()` is not heredoc-aware, so any heredoc body
containing an unescaped double quote — not a rare or contrived case,
ordinary commit messages routinely quote a path, identifier, or error
string — breaks the parse. The fix is not "the information is
unreachable"; it is "the current parser's method of reaching it is wrong
for this idiom." A regex anchored on the heredoc terminator line, applied
to the raw command string before `shlex` ever runs, extracts the body
directly regardless of what characters it contains.

Scope item 2 (Bash-harness constraint): tested directly against this
session's own Bash tool. A single, standalone
`git commit -m "$(cat <<'EOF' ...multi-line body... EOF)"` command, issued
as the sole content of one Bash call, is accepted by the harness's static
analysis (verified: it ran and reached `git`, failing only on "nothing
staged" — not a harness refusal). The harness's "cannot be statically
analyzed" / "multiple operations" refusals reproduce reliably when that
heredoc command is *chained* with other statements (`cmd1; cmd2`) or
prefixed with inline env-var assignments (`FOO=bar cmd`) in the same Bash
call — not from the heredoc idiom alone. So a compliant multi-line commit
*is* reachable under both constraints simultaneously: the canonical idiom,
issued as one standalone Bash call with no chaining, satisfies both the
Bash harness and (after this fix) `trailer-gate.sh`, including bodies that
quote text.

## Alternatives considered (feeds proposal's Rationale)

- Fail-open when `shlex` can't parse: rejected by the issue's own item 3
  and by no-mock/no-footgun direction — an unverifiable trailer must still
  deny, not pass.
- Switch the whole gate off `shlex` onto a full heredoc-aware shell
  tokenizer (e.g. vendoring a POSIX-shell parser): rejected as
  disproportionate — the one idiom in scope has one well-defined
  materialization shape (`-m "$(cat <<[quote]DELIM[quote] ... DELIM)"`), a
  targeted regex handles it without a new dependency, and `shlex` is kept
  as the fallback path for every other invocation shape.
