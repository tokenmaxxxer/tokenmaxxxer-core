# Current-state survey — issue-149

## Scout skip record

Skip condition: pure bugfix. The issue names the exact defect (a `find`-anywhere
substring check in one function), the exact fix direction (classify the token as
a URL before extracting a docs tail; do not loosen the deny), and the exact
acceptance tests. No product-shaped or design decision is open — there is no
field to scout. Scouting is skipped under the scout-directive's own bugfix
exemption.

## Write set this touches

- `core/hooks/board-gate.sh` — the docs-tail extractor, `_docs_relative_tail`,
  and the `own_hits` regex in the `Bash` candidate-builder branch (~lines
  300-368).
- `core/hooks/tests/run-board-gate-tests.sh` — new cases (URL false positives
  fixed; genuine out-of-bucket writes still denied).
- `docs/handbooks/board-gate-tests.md` — the test-harness handbook already
  documents every prior fix to this file; this fix follows the same
  convention.

## What the extractor does today

`board-gate.sh` has two independent extraction paths that both funnel into
`_docs_relative_tail(token)` (`norm(token).find("docs/")`, tail = everything
after the first hit):

1. Write/Edit/MultiEdit/NotebookEdit: `tool_input.file_path` is the one
   candidate — realistically never a URL, out of scope for this defect.
2. Bash: when the raw `cmdline` contains the literal substring `docs`, the
   segment splitter (`_split_segments`) walks each `;`/`&&`/`|`-separated
   segment. A segment that cannot be proven read-only has its own
   `docs/`-shaped substrings pulled out by
   `re.findall(r"[\w./~$-]*docs/[\w./-]*", seg)` (line ~364, `own_hits`) and
   each hit becomes a candidate. Every candidate is then re-run through
   `_docs_relative_tail` at the bottom (`hits` loop, ~line 372) to produce the
   final tail list that `bucketed()` classifies.

`own_hits`'s character class (`\w . / ~ $ -`) excludes `:`. Repro:
`https://code.claude.com/docs/en/hooks.md` — the regex cannot cross the `:`
in `https:`, so the greedy prefix before `docs/` stops at `code.claude.com/`
(the char class does allow `.` and `/`), and the match is
`code.claude.com/docs/en/hooks.md`. `_docs_relative_tail` then finds `docs/`
inside that match and returns tail `en/hooks.md`. `bucketed("en/hooks.md")`
sees top-level component `en`, which is neither `README.md`, an
`issue-<n>` tree, nor one of the six standing buckets, so it denies — exactly
the observed refusal. `http://example.com/docs/api/v1.md` fails the same way
(tail `api/v1.md`).

There is no scheme/authority detection anywhere in this path today — the
extractor has no concept of "this token names an external resource," only
"this token contains the substring `docs/`."

## Prior related work in this file

`docs/handbooks/board-gate-tests.md` documents the full history of this
extractor: issue-90 (candidate scan scoping), issue-99 (dead fallback +
cd-relative write-verb gap), issue-107 (wrapper-prefixed `cd` argument
extraction), issue-88 (quoted-pipe segment-split blindness), issue-94
(`FILE_REDIR` quote-awareness), issue-98 (wrapper-headed writes, awk/sed
write mechanisms). The established convention in every one of these: fix the
classification, never the deny; pin the fix with a positive case and a
negative-space sibling proving the original deny still holds; document
residual, deliberately-accepted gaps as visible `gap-*` cases rather than
silently dropping them (`gap-awk-comparison-over-block` is the canonical
example). This issue's own scope item 3 states the same constraint directly.

## Alternatives visible from this survey

1. **Scheme/authority discriminator inside `_docs_relative_tail`** (add `:`
   to the extraction char class so a scheme is captured as part of the
   match, then classify the matched token as a URL — `scheme://...` or
   containing `://` before the `docs/` hit — and return `""` for it, same
   as "no docs/ token here at all").
2. **Reject at the segment level**: before running `own_hits`, strip any
   `scheme://host` prefix out of the segment text entirely (e.g. via a
   URL-matching regex pass that deletes matched URLs from `seg` before the
   `docs/`-hit regex ever runs).
3. **Allowlist known doc-hosting domains**: special-case `code.claude.com`
   (the one URL in the issue's repro) and similar.

Alternative 3 is a non-starter under the issue's own scope item 3 (classify
the token, don't special-case one deny path around it) and would not
generalize to `http://example.com/docs/api/v1.md`, the issue's own second
test case. Alternatives 1 and 2 both work; the proposal picks between them.
