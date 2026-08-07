---
status: proposed
files:
  - core/hooks/board-gate.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - docs/handbooks/board-gate-tests.md
---

## Request

`board-gate.sh`'s docs-tail extractor (`_docs_relative_tail`, fed by the
`own_hits` regex in the Bash candidate-builder branch) finds the substring
`docs/` anywhere in a token, with no concept of "this token is a URL, not a
repository path." Any external URL whose path contains `/docs/` — e.g.
`https://code.claude.com/docs/en/hooks.md` — gets its post-`docs/` tail
extracted and classified against the six standing buckets, which it
predictably fails, denying a plain read of an external page. Scope item 1:
fix the classification. Scope item 2: survey the same `find`-anywhere logic
for other false-positive shapes and report them. Scope item 3: this stays
fail-closed — the fix narrows what counts as a docs/ token, it does not
loosen what happens once something is classified as one.

## Constraints

- Fail-closed by design must survive unchanged: a genuine out-of-bucket
  repository write still denies.
- No prose-only discharge (on-the-record#310) — every claim here is backed
  by an executable test in `run-board-gate-tests.sh`, run as a real
  subprocess the same way every other case in that file runs.
- Per this repo's own established convention in this file (documented in
  `docs/handbooks/board-gate-tests.md`): every fix is pinned by a positive
  case AND a negative-space sibling proving the original deny still holds.
- Scope item 2's answer must be a list, or, if empty, a statement of what
  shapes were examined — not skippable.

## Rationale

**Chosen: scheme/authority discriminator inside the extractor** — widen the
`own_hits` character class to include `:` (so a scheme like `https:` is
captured as part of the match instead of truncating it), then add a URL
check to `_docs_relative_tail`: a token that starts with
`<scheme>://` or contains `://` before its first `docs/` occurrence is
classified as a URL, not a repository path, and returns `""` (the same
"not a docs/ token" result `_docs_relative_tail` already returns when no
`docs/` substring is present at all — no new code path in the callers, no
new allow logic, the token simply stops being a candidate).

**Rejected: strip URLs out of the segment text before running `own_hits`**
(delete `scheme://host/path`-shaped spans from `seg` first, then run the
existing extraction unchanged). Rejected because it duplicates the
scheme-detection regex in two places (a deletion pass AND the extraction
pass would each need to recognize the same shape) for no behavioral
difference, and it changes what `own_hits` sees, which is the exact
regex every existing test in this file already exercises — widening the
regex's own character class and adding one classification check inside
`_docs_relative_tail` touches strictly fewer of the paths this file's own
test suite already pins.

**Rejected: allowlist known documentation domains** (special-case
`code.claude.com`). Rejected outright by the issue's own scope item 3 — this
would not be classifying the token, it would be carving a deny-side
exception around one specific domain, and it does not generalize to the
issue's own second repro case, `http://example.com/docs/api/v1.md`.

## What will be done

1. In `core/hooks/board-gate.sh`, widen the `own_hits` regex's character
   class from `[\w./~$-]` to `[\w./~$:-]` so a URL's scheme is captured as
   part of the same match instead of being severed at the first `:`.
2. Add a URL classifier (module-level regex, `^[A-Za-z][A-Za-z0-9+.-]*://`)
   and use it inside `_docs_relative_tail`: if the token matches that
   pattern, or contains `://` at any position before its first `docs/`
   occurrence, return `""` immediately — the token carries no repository
   docs-tail, exactly as if it had no `docs/` substring at all.
3. Add test cases to `run-board-gate-tests.sh`:
   - `allow` for a Bash read of `https://code.claude.com/docs/en/hooks.md`
     and of `http://example.com/docs/api/v1.md` (the issue's own two repro
     shapes) — failing before the fix, passing after.
   - `deny` companions proving a genuine out-of-bucket board write is still
     refused: `docs/en/hooks.md` as an actual repo-relative Write
     `file_path`, and `docs/issue-1/notabucket/x.md`.
4. Extend `docs/handbooks/board-gate-tests.md` with a section documenting
   this fix, its cause, and the new cases, following the file's own existing
   per-issue convention.
5. Answer scope item 2 (other `find`-anywhere false-positive shapes) as a
   list in this proposal's Out of scope section, since fixing them is not
   what scope item 2 asks for — reporting is.

## Out of scope

Scope item 2's survey findings — reported, not fixed, because the issue asks
for a list, and fixing either would be a second, independently-scoped
change under this file's own "over-blocking is the safe default, a real
gap gets a `gap-*` pin, not a silent fix" convention:

1. **Directory names that merely end in `docs`, not `docs/` itself** — e.g.
   `mydocs/x.md`, `userdocs/notes.md`, `autodocs/`. `DOCS = "docs/"` is a
   plain substring search: `"mydocs/x.md".find("docs/")` returns `2` (the
   substring `docs/` sits inside `mydocs/`), so a segment writing into an
   unrelated directory that happens to end in `docs` gets a candidate
   extracted and classified the same as a real `docs/` write. This is the
   same `find`-anywhere root cause as the URL case, reachable without any
   URL involved. Not fixed here: closing it needs a directory-boundary
   check (does `docs/` start at a path-component boundary — start of
   string or immediately after `/`), which is a second, independent
   discriminator from the scheme/authority one this proposal adds, and no
   concrete over-block from it has been observed in real use (this file's
   own `gap-awk-comparison-over-block` convention: expand on a concrete
   hit, not speculatively).
2. **A `docs/`-shaped substring inside a quoted literal that is not a
   path at all** — e.g. `grep -n "see docs/api reference" file.txt`. The
   `own_hits` regex runs on the raw segment text, not a quote-stripped
   view (unlike `FILE_REDIR`, which already routes through
   `gate_lib.gate_outside_quotes` per issue-94). A `docs/`-looking string
   sitting inside a quoted grep pattern or commit message argument
   becomes a false-positive candidate the same way the URL case does. Not
   fixed here: quote-stripping `own_hits` the way `FILE_REDIR` already is
   is a real, separate fix with its own regression-test surface (does a
   real write target still get caught when quoted content sits earlier
   on the same segment?) and is not implicated by this issue's own repro.
3. Examined and found not to be a distinct false-positive shape: the
   `_cd_target`/`cd_tail` path (`_docs_relative_tail` called on a `cd`
   argument) — `cd` targets are shell paths by construction, a `cd` to a
   URL is not a real shell operation, so this path does not carry the
   URL false positive; it does carry finding 1 above (a `cd` into a
   directory ending in `docs`) as the same root cause, not a new one.

Neither finding above is fixed by this change; this proposal's write set
does not touch the directory-boundary or quote-stripping logic.

## How you'll know it worked

`bash core/hooks/tests/run-board-gate-tests.sh` passes with the two new
`allow` cases (the issue's own URL repros) and the two new `deny` companions
(`docs/en/hooks.md`, `docs/issue-1/notabucket/x.md`), alongside every
pre-existing case in that file staying green — the fix must not regress any
of the R1-R5 write-side denials the file already pins.
