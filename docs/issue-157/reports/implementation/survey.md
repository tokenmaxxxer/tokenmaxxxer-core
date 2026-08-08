---
kind: current-state-survey
subject: issue-157
produced_by: implementation
---

# Current-state survey — issue-157

## Scout skip record

Scouting was skipped. Skip condition: pure bugfix. All four findings (F1-F4)
are named against one already-landed change,
`core/hooks/record-fields-gate.sh`'s `placeholder_shas` function as it
stands after issue-153/PR #154 (`docs/issue-153/reports/execution-observation.md`),
each with an exact file:line locus. The one open design choice — F1's
fallback semantics when the frontmatter anchor does not match — is
internal implementation judgment about this repository's own gate script,
settled by this repository's own established convention (every real
record/proposal already opens with a `---`-delimited frontmatter block)
and by which existing test fixtures would flip, not by comparison against
external tooling. This is the same skip condition and the same reasoning
issue-153's own survey recorded for the same file.

## The gate today, at HEAD (`c2465e99fd9e0a83984ee2ea3debfcce8c1fab76`)

`core/hooks/record-fields-gate.sh:174-202` (`placeholder_shas`), landed by
`3f67436`, unchanged since:

```
def placeholder_shas(text):
    if text.startswith('﻿'):
        text = text[1:]
    fm = re.match(r'^---[ \t]*\r?\n(.*?\n)^---[ \t]*\r?$', text, re.M | re.S)
    region = fm.group(1) if fm else ""
    bad = []
    for m in re.finditer(r'^\s*sha:[ \t]*(.*)$', region, re.M):
        v = re.sub(r'[ \t]+#.*$', '', m.group(1)).strip()
        if v == "":
            continue
        if v == "same-commit" or re.match(r'^[0-9a-f]{40}$', v):
            continue
        bad.append(v)
    return bad
```

Baseline confirmed by direct run, this session:
`bash core/hooks/tests/run-role-gates-tests.sh` → `role-gates: 56 passed, 0
failed` — matches the count the issue-153 observation cited from the
delivering role's own record but did not itself re-run (`docs/issue-153/reports/execution-observation.md`,
"Evidence tiers" section). This survey re-ran it directly, so the 56/0
baseline below is independently confirmed, not merely relayed.

## F1 — frontmatter-less documents, fallback semantics

**Confirmed still live**, reproduced against the live regex (copied
verbatim from the source above, run standalone in `python3` this
session):

```python
>>> region = "" # fm is None: text has no leading '---' fence
>>> import re
>>> [m.group(1) for m in re.finditer(r'^\s*sha:[ \t]*(.*)$', region, re.M)]
[]
```

A document `"sha: HEAD\n"` (no leading fence at all) yields `region = ""`,
so `placeholder_shas` returns `[]` — the write is allowed regardless of
what the field says. Before #154 (whole-document scan), the same input
was denied: `re.finditer(r'^\s*sha:\s*(.*)$', "sha: HEAD\n", re.M)` finds
`sha: HEAD` and denies it. This is the exact permissive flip Finding 1
names.

**The candidate semantics, evaluated against this repository's actual
write set (not just the issue's abstract framing):**

1. **Fail-closed — a record/proposal write with no leading `---` fence is
   denied outright**, as a new, separate check ahead of the sha scan.
   Traced against the existing test fixtures: `run-role-gates-tests.sh:75-92`
   (`"coding record w/ all §20 fields allowed"`,
   `"implementation record code_under_review file list allowed
   (issue-100)"`, and three more) are all currently-passing `allow`
   fixtures for records that satisfy §20 via flat text with **no**
   leading `---` fence at all — `record-fields-gate.sh`'s five §20 field
   checks (`has_any(...)`, `:222-243`) are substring checks over the
   whole document and never required frontmatter. Fail-closed would deny
   all five of these legitimate, currently-allowed fixtures, which is a
   behavior change to the §20 field-completeness check, not to the sha
   check — outside what issue #157 or #153 scopes ("fallback 의미론·핀
   강도·기록 완결성", not "require frontmatter on every record").
2. **Fallback: when the anchor does not match, scan the whole document
   instead of an empty region** — `region = fm.group(1) if fm else text`,
   one token changed from the line above. This restores exactly the
   pre-#154 whole-document behavior, but **only** for documents that lack
   a frontmatter fence; a document that has one keeps #154's narrowed,
   quote-safe scan verbatim. Traced against all 25 `run_rf` fixtures
   already in the suite (`:73-216`): none of the frontmatter-less
   fixtures (`:73-92`, `:162-216`) contains a `sha:` field line at all —
   grepped this session, zero hits — so this change flips no existing
   fixture's expected verdict. It only starts inspecting `sha:` lines in
   a document shape (no fence) that today has zero live corpus instances
   (issue-153's own census: 69/69 `docs/` documents carrying a `sha:`
   field line open with a `---` block) and that no currently-passing test
   relies on staying unscanned.

**Chosen for the proposal: candidate 2 (fallback).** Reasoning developed
fully in the proposal's Rationale; the survey-level fact that decides it
is the fixture trace above — fail-closed breaks 5 currently-legitimate,
currently-passing fixtures that have nothing to do with the sha check,
while fallback breaks none.

**Disposition of the `:92`-region allow fixture the observation cited**
(`"implementation record code_under_review file list allowed
(issue-100)"`, now at `run-role-gates-tests.sh:90-92`): its content is
`` loop_state: landed\n\ncode_under_review: `a.sh`, `b.sh`\n\n## what was
done\nx\n\n## why\ny\n\nupstream: abc1234\n\n## open findings\nnone\n ``
— no line anywhere in it matches `^\s*sha:`. It was never a test of the
sha check (it tests the `code_under_review` bare-sha-vs-file-list check
and the §20 field-completeness check only), so its expected verdict
(`allow`) is unaffected by either candidate above — there is nothing in
it for `placeholder_shas` to find under any semantics. The gap this
fixture demonstrates (a legitimate, currently-passing record shape with
no frontmatter fence) is real and is exactly what candidate 1
(fail-closed) would have broken; candidate 2 leaves it untouched while
still closing F1 for a document of that same shape that *does* carry a
bad `sha:` value. No fixture edit is needed at `:90-92`; a **new** fixture
(fence-less content plus a bad `sha:` value) is what pins the fix, per the
issue's own red-green instruction.

**F1 red-green plan (to execute in phase 2):** a `run_rf` case with
content `"sha: HEAD\n"` (no fence), role `coding`, path under
`docs/issue-3/proposals/...`. Pre-fix: `allow` (red — reproduced above by
direct regex trace: `region=""`, `bad=[]`). Post-fix: `deny` (green:
`bad=["HEAD"]`).

**Hunt result, this session's after-proposal dispatch (stance 0):
FINDING against the first draft of candidate 2.** Matching the anchor
against the raw `text` directly (the literal one-token change,
`region = fm.group(1) if fm else text`) turned out to be scoped by
byte-exact position-0 fence matching, not by "does this document have
real frontmatter": a document with fully-conforming frontmatter preceded
by a single stray leading blank line falls into the fallback branch too,
so a denied spelling legitimately quoted in that document's body — the
same idiom this survey's own F1/F2 python reproductions use — would be
falsely denied. Reproduced by the hunter and re-verified independently
this session (`python3`, side by side): the first-draft fallback returns
`['HEAD']` (deny) for such a document; both the current gate and the
revised fix return `[]` (allow). Full record:
`docs/reports/2026-08-08-hunt-issue-157-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md`.

**Resolution, verified this session:** attempt the anchor match against
`text.lstrip()` (leading whitespace stripped, after the existing BOM
strip) instead of `text` directly, but still fall back to scanning the
full, unstripped `text` when even that fails to match — `region =
fm.group(1) if fm else text`, with `fm` now matched against the stripped
copy. Re-run against the hunter's exact repro doc, the leading-spaces
variant, and all seven existing F1/F2 fixtures (the F1 regression,
red-green, no-trailing-newline, comment, and BOM cases, plus the F2
carve-out and message-accuracy cases): every one now returns the value
this survey and the proposal already claim for it. This is the design
carried into the proposal below, not the original one-token draft.

## F2 — message-accuracy discriminator

**The existing case does not discriminate**, confirmed independently this
session (not just by re-reading the observation's claim). Reproduced in
`python3`, the two patterns side by side against the existing fixture's
content (a *non-empty* value directly on the field-name line):

```python
>>> import re
>>> old = lambda t: [m.group(1).strip() for m in re.finditer(r'^\s*sha:\s*(.*)$', t, re.M)]
>>> new = lambda t: [re.sub(r'[ \t]+#.*$','',m.group(1)).strip() for m in re.finditer(r'^\s*sha:[ \t]*(.*)$', t, re.M)]
>>> t = "    sha: HEAD\n"
>>> old(t); new(t)
['HEAD']
['HEAD']
```

Identical result either pattern — the existing fixture's value character
(`H`) blocks the old pattern's trailing `\s*` from ever reaching the
newline, so it never exercises the swallowing bug the case is named for.

**A discriminating fixture, verified this session** — reuse the *shape*
of the already-landed `"F2 red->green: value-less line followed by
another entry allowed (carve-out)"` fixture (`run-role-gates-tests.sh:141-143`:
one entry with an empty `sha:`, a second entry with `sha: same-commit`),
but change the **second** entry's value to a non-conforming one:

```python
>>> b = "---\nupstream:\n  - path: a\n    sha:\n  - path: other\n    sha: HEAD\n---\n"
>>> old_full = lambda t: [m.group(1).strip() for m in re.finditer(r'^\s*sha:\s*(.*)$', t, re.M) if not (m.group(1).strip() in ("same-commit",) or re.match(r'^[0-9a-f]{40}$', m.group(1).strip()))]
>>> old_full(b)
['- path: other', 'HEAD']
```

Under the pre-#154 whole-document pattern, the first (empty) `sha:`
line's trailing `\s*` crosses the newline and swallows `- path: other` —
literal YAML-structure text, not anything the author wrote as a value —
as `bad[0]`; `deny_placeholder` reports only `bad[0]`, so the denial
message would read `sha: - path: other is not \`same-commit\`...`, naming
neither the true field nor its value. Under the current (fixed) pattern,
scoped to the frontmatter region:

```python
>>> new_region = "\nupstream:\n  - path: a\n    sha:\n  - path: other\n    sha: HEAD\n"
>>> [re.sub(r'[ \t]+#.*$','',m.group(1)).strip() for m in re.finditer(r'^\s*sha:[ \t]*(.*)$', new_region, re.M)]
['', 'HEAD']
```

The empty entry is carved out (skipped), and the second entry's own line
is matched independently — `bad = ["HEAD"]`, message `sha: HEAD is not
\`same-commit\`...`. **Discrimination check, done by substring, the same
way the existing inline probe checks it:** the string `sha: HEAD is not`
does **not** appear anywhere in the old message (`sha: - path: other is
not \`same-commit\`...` — `bad[1]="HEAD"` is computed but never included
in the deny text, since `deny_placeholder` only reports `bad[0]`), and
does appear in the new message. A simpler fixture (field-name line empty,
the *very next* line also starting with the literal `sha:`, e.g.
`"    sha:\n    sha: HEAD\n"`) was traced and rejected for this role
first: the old pattern's swallow captures the whole next line including
its own `sha:` prefix (`bad[0] = "sha: HEAD"`), and the message `sha: sha:
HEAD is not ...` **still contains** the substring `sha: HEAD is not` as
its tail — a false negative, not a real discriminator. The two-entry
`path:`/`sha:` shape above avoids this because the swallowed text
(`- path: other`) never contains the literal string `HEAD` anywhere.

**F2 plan (to execute in phase 2):** add this fixture as a second inline
message-content probe next to the existing one at
`run-role-gates-tests.sh:145-151`, asserting the denial message contains
`sha: HEAD is not` and reporting failure otherwise. No production-code
change — #154 already fixed the underlying behavior; only the test was
non-discriminating. Keep the existing non-empty-value case too (it still
pins a real, if different, behavior: a genuinely non-conforming value
directly on the field-name line is named correctly).

## F3 — class census, expanded to the 11 previously-uncensused files

Issue-153's own census method (`docs/issue-153/reports/implementation/survey.md:141`)
was "grep across every `core/hooks/*.sh` (excluding `tests/`) for
`re.(search|match|finditer|sub)` calls" — a glob that matches 7 of the
repository's 18 tracked non-test `*.sh` files. This session re-ran that
same census against the 11 files outside the glob (confirmed count:
`git ls-tree -r --name-only c2465e9` filtered to non-test `*.sh` → 18
total, unchanged since issue-153):

`core/hooks/lib/gate-lib.sh`, `core/hooks/lib/role-directive.sh`,
`freelunch/hooks/freelunch.sh`, `freelunch/hooks/observe.sh`,
`scout/hooks/directive.sh`, `terse/hooks/terse.sh`,
`warrant/hooks/directive.sh`, `warrant/hooks/hunt-guard.sh`,
`warrant/hooks/hunt-state.sh`, `warrant/hooks/scope-gate.sh`,
`warrant/hooks/state.sh`.

**Method correction, noted for the next role to re-run this:** issue-153's
literal grep pattern (`re\.(search|match|finditer|sub)`) only catches
calls of the form `re.search(...)` — it misses a precompiled-pattern call
site like `STATUS.search(block)`, which is exactly the form two of these
11 files use. This session's grep instead searched broadly for
`re.compile|\.search\(|\.match\(|\.finditer\(|\.sub\(|\.findall\(` across
all 11 files and read every hit.

**Result, file by file:**

- `warrant/hooks/state.sh:36-48` and `warrant/hooks/scope-gate.sh:41,115-126`
  each define their own `frontmatter(path)` helper: `if not
  text.startswith("---"): return None`, then `text.find("\n---", 3)` for
  the closing fence — a bounded string search, not a regex whose failure
  mode is a silently-empty scan region. Both callers treat `None`
  explicitly: `state.sh` (`:56`) skips the document from its open-units
  listing (a read-only `SessionStart` informational hook, not an
  enforcement gate); `scope-gate.sh` (`:135-136`) appends it to
  `malformed` and **denies** (`sys.exit(1)`, `"the frontmatter has no
  closing \`---\`... The gate is standing down until it is valid"`,
  `:156-164`) — the opposite direction from F1: fail-closed, not
  fail-open, on a missing/malformed fence. Neither is F1's class; neither
  needs a fix. `scope-gate.sh`'s `STATUS`/`FILE_ITEM` regexes then run
  only against `block`, the already-bounded substring — same shape as
  `record-fields-gate.sh`'s fixed (post-#154) code, not its pre-#154 one.
- `scope-gate.sh:187-203`'s `WITHHELD` regex list (`git push`, `git
  merge`, `rm -rf`, shell redirection, etc.) and `GIT_COMMIT` (`:44`)
  match against a **Bash command string**, not a repository document — a
  different concern from F1's "canonical surface vs. whole document"
  class entirely; not applicable.
- `core/hooks/lib/gate-lib.sh:94` (`gate_bash_write_targets`) is a
  bash-only `grep -oE` over a command string, same non-applicable
  category.
- The remaining 8 — `core/hooks/lib/role-directive.sh`,
  `freelunch/hooks/freelunch.sh`, `freelunch/hooks/observe.sh`,
  `scout/hooks/directive.sh`, `terse/hooks/terse.sh`,
  `warrant/hooks/directive.sh`, `warrant/hooks/hunt-guard.sh`,
  `warrant/hooks/hunt-state.sh` — contain no regex- or pattern-based
  document-content parsing at all (confirmed by the broad grep above
  returning zero hits in each), so F1's class cannot occur in them: there
  is no scan whose region could be too wide or fail open.

**Census verdict: 11/11 examined, 0 additional instances of F1's class.**
Two files (`state.sh`, `scope-gate.sh`) turn out to already implement the
"bound the scan to the frontmatter block" idea independently, and in the
stricter (fail-closed) direction record-fields-gate.sh's own F1 bug went
the wrong way on. This is a full-count result, not a boundary exclusion —
requirement 3 is satisfied by extension, with the finding written down
here rather than left implicit.

**In-flight coordination note:** PR #145 (issue-142, open,
`issue-142/implementation`) is currently editing 7 of these same 11 files
(`scout/hooks/directive.sh`, `terse/hooks/terse.sh`,
`warrant/hooks/directive.sh`, `warrant/hooks/hunt-guard.sh`,
`warrant/hooks/hunt-state.sh`, `warrant/hooks/scope-gate.sh`,
`warrant/hooks/state.sh`) — confirmed by `gh pr diff 145`. Its hunks in
`state.sh` and `scope-gate.sh` (`gh pr diff 145` read this session) are
confined to the kill-switch/`gate-lib.sh`-sourcing preamble (both files'
top ~15 lines); neither touches the `frontmatter()`/`STATUS`/`FILE_ITEM`
region this census read. No line-level conflict with this survey's
findings; noted per this repository's adjacent-track convention
(issue-153's own survey did the same for #141/#146/#147) in case #145
lands first and a future re-run needs current line numbers.

## F4 — closing-anchor boundary, undocumented

Confirmed by direct read of the anchor:
`^---[ \t]*\r?\n(.*?\n)^---[ \t]*\r?$` — the middle group is non-greedy
(`.*?`), so the match's closing `^---...$` binds to the **first**
column-0 `---` line after the opening fence, not the last. A `---` line
appearing inside what the author intended as frontmatter (invalid YAML,
but nothing in this regex-based check parses YAML, so nothing rejects it
structurally) truncates the scanned region there; every `sha:` line below
the truncation point goes unscanned — same silent-permissive direction as
F1, from the closing side of the anchor instead of the opening side.

This was reproduced once already, by the observing role's own phase-1
hunt against a standalone copy of the pattern
(`docs/reports/2026-08-08-hunt-issue-153-narrow-sha-scan-scope-and-empty-value-carveout.md`,
referenced at `docs/issue-153/reports/execution-observation.md:456-458`);
not independently re-reproduced this session, since the fact needed here
is only the regex's documented shape, not a new repro of a rare-to-nonexistent
input.

**Corpus check, this session, corrected mid-survey.** A first pass
(`grep -rn '^---$' docs/issue-*/reports/*.md docs/issue-*/proposals/*.md
2>/dev/null | awk -F: '{print $1}' | sort | uniq -c`) found several files
with **more than two** column-0 `---` lines — `docs/issue-23/reports/review.md`
(11), `docs/issue-12/reports/review.md` (10),
`docs/issue-18/reports/review.md` (6), and three `execution-observation.md`
records with 3-4 — which would have been a wrong claim of "0 instances"
if reported without checking what those extra lines are. Reading each
file's `---` and `sha:` line numbers together
(`grep -n '^---$\|^[[:space:]]*sha:' <file>`) resolves it: `re.match`
anchors at position 0 and stops at the *first* `---`...`---` pair from the
start of the document, so every extra `---` line these files carry lands
in the document's **body** (a second, third, or later quoted citation
block further down the file, e.g. `docs/issue-12/reports/review.md:44`
onward) — outside what `fm` ever inspects, not a second attempt at the
same anchor. The one comparison that actually tests F4 is: does any
`sha:` line number fall *after* the first closing `---` following line 1?
Checked directly for the 6 flagged files — in every one, every `sha:`
line number is *less than* the first closing `---` line number
(e.g. `docs/issue-90/reports/execution-observation.md`: `sha:` at `:14`,
closing `---` at `:15`; `docs/issue-99/reports/execution-observation.md`:
`sha:` lines at `:12,14,16`, closing `---` at `:17`) — so none of them is
a live early-truncation instance. Net result unchanged from the first
(too-hasty) pass — 0 live corpus instances of a `sha:` line lost to
early closure — but the corrected reasoning is the one that actually
supports that conclusion; the original one-line awk check did not.
Severity stays low; this is a documentation-only close, not a code
change.

## Test harness

`core/hooks/tests/run-role-gates-tests.sh`'s `run_rf` helper
(`:60-71`) and the existing F1/F2 `run_rf` cases (`:129-159`) are the
harness both new cases extend — same helper, same style, consistent with
issue-153's own approach. No new test infrastructure needed.

## Handbook

`docs/handbooks/role-gates-tests.md:61-71` documents the current (#154)
scan-scoping and carve-out behavior in prose; it says nothing about (a)
what happens when no frontmatter fence is found at all (F1's gap) or (b)
where the region's closing boundary sits (F4's gap). Both are additions
to this same paragraph block, not a new section.

## Adjacent tracks — file-level overlap check

- **#141** (open PR #144): touches `core/hooks/handbook-trigger-gate.sh`,
  `core/hooks/trailer-gate.sh`, and their own test files — no line in
  `core/hooks/record-fields-gate.sh` or `run-role-gates-tests.sh`. No
  overlap.
- **#142** (open PR #145): see F3's coordination note above — touches 7 of
  the 11 newly-censused files, but not the lines this survey read in any
  of them.
- **#146** (open PR #148, phase 1 only): `docs/issue-146/proposals/*.md`
  and `docs/issue-146/reports/implementation/survey.md` only — no code.
  Its stated direction (gate-literal ↔ injected-prose coverage) would, if
  it reaches phase 2, most plausibly touch `core/hooks/directive.sh`'s
  injected prose and the five §20 field checks — a different region of
  `record-fields-gate.sh` than this issue's write set (the sha check and
  the handbook's sha-check paragraph). Flagged, not a present conflict.

No currently-open PR edits a line this issue's write set touches.
