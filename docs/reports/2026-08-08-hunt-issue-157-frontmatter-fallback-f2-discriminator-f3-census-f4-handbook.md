---
proposal: docs/issue-157/proposals/2026-08-08-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md
---

# Hunt record — frontmatter-fallback-f2-discriminator-f3-census-f4-handbook

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — the proposed F1 fallback (`region = fm.group(1) if fm else text`) is scoped by byte-exact position-0 fence matching, not by "does this document have real frontmatter"; a document with fully-conforming frontmatter preceded by a single stray leading blank line falls into the whole-document-scan fallback branch, so a denied spelling legitimately quoted in the body (the exact idiom this proposal's own survey.md and proposal.md use to cite examples) is now falsely denied — contradicting the Rationale's claim that "for a document that has [a fence], behavior is byte-for-byte unchanged."
Kind: design-error
Seed: docs/issue-157/proposals/2026-08-08-frontmatter-fallback-f2-discriminator-f3-census-f4-handbook.md "## Rationale" / F1 (`region = fm.group(1) if fm else text`, one-token change) and its claim "For a document that *has* a leading `---` fence, behavior is byte-for-byte unchanged"; compared against `core/hooks/record-fields-gate.sh:174-190` (`placeholder_shas`, unmodified on this branch)
cap_seconds: 60
tier: default (docs-only fast path)
diff_stat_lines: 0 (phase-1, docs only — no code diff yet; proposal ~242 lines, survey ~372 lines)
started_at: 2026-08-08T01:57:00Z
ended_at: 2026-08-08T02:04:30Z

### Reproduce

Standalone Python, the live regex from `core/hooks/record-fields-gate.sh:174-202`
(`region_old`, current/post-#154 behavior) run side by side with the proposed
one-token change (`region_proposed`, `region = fm.group(1) if fm else text`),
against a document that: (1) has fully-conforming frontmatter (`sha:
same-commit`), (2) is preceded by exactly one stray leading blank line before
its opening `---`, and (3) legitimately quotes a denied spelling (`sha:
HEAD`) on its own line inside a fenced body example — the same idiom
`docs/issue-157/reports/implementation/survey.md` itself uses (its own
`'    sha: HEAD\n'` python-repro lines), and the shape this proposal's own
"Out of scope"/writability constraint says must stay allowed:

```python
import re

def region_old(text):
    if text[:1] == chr(0xFEFF):
        text = text[1:]
    fm = re.match(r'^---[ \t]*\r?\n(.*?\n)^---[ \t]*\r?$', text, re.M | re.S)
    return fm.group(1) if fm else ""

def region_proposed(text):
    if text[:1] == chr(0xFEFF):
        text = text[1:]
    fm = re.match(r'^---[ \t]*\r?\n(.*?\n)^---[ \t]*\r?$', text, re.M | re.S)
    return fm.group(1) if fm else text

def bad_shas(region):
    bad = []
    for m in re.finditer(r'^\s*sha:[ \t]*(.*)$', region, re.M):
        v = re.sub(r'[ \t]+#.*$', '', m.group(1)).strip()
        if v == "":
            continue
        if v == "same-commit" or re.match(r'^[0-9a-f]{40}$', v):
            continue
        bad.append(v)
    return bad

doc = ("\n---\nkind: build-proposal\nupstream:\n  - path: reports/y.md\n"
       "    sha: same-commit\n---\n\n"
       "Quoted denied-spelling example, indented inside a fence:\n"
       "```\n    sha: HEAD\n```\n")

print("current (post-#154):", bad_shas(region_old(doc)))
print("proposed (one-token fallback):", bad_shas(region_proposed(doc)))
```

### Observed

```
current (post-#154): []
proposed (one-token fallback): ['HEAD']
```

The one stray leading `\n` makes `re.match` fail at position 0 (the pattern
is anchored to the literal string start, not to "the first non-blank
line"), so `fm` is `None` even though the document's actual frontmatter
block, two lines down, is completely well-formed and every one of its own
`sha:` values conforms. Under the proposed fix this routes to `region =
text` — the *whole* document, including the fenced body example — and the
legitimately-quoted `sha: HEAD` line gets caught and denied.

### Expected

Per the proposal's own Rationale: "For a document that *has* a leading
`---` fence, behavior is byte-for-byte unchanged — the fallback branch is
never reached." This document has one (two lines down, fully valid); the
proposal's classification of "has a fence" vs. "has none" is purely
syntactic (exact byte-0 anchor match), not semantic, so a realistic,
extremely mundane input shape (one leading blank line — an editor or
copy-paste artifact) is silently reclassified as "has none" and routed
into the whole-document scan the same paragraph says only applies to "the
narrow, currently-nonexistent-in-corpus shape of a frontmatter-less
document that also needs to quote a `sha:` value." This document is not
frontmatter-less in any sense a human or the survey's own fixture-based
verification would recognize; the survey's F1 fixture check (`grep`-ing
the 25 existing fence-less `run_rf` fixtures for `sha:` lines) cannot see
this gap at all, since it only inspects documents that are *already*
fence-less by the same byte-0 test the code itself is using, not documents
that have real frontmatter shifted by leading whitespace.

## before-landing — stance 1: composition regression between the F1 fence-less fallback and issue-153's frontmatter-scoping

Verdict: FINDING — the F1 fallback (scan the whole document when no leading `---` fence is found) reintroduces the exact issue-153 bug it was built on top of: a fence-less record/proposal that merely quotes a bad `sha:` spelling as a documentation example (indented, outside any frontmatter -- because it has no frontmatter at all) is now denied by record-fields-gate.sh, even though real records in this repo routinely have no leading `---` fence (e.g. the coding record for an earlier issue in this repo's docs tree) and issue-153's own stated rationale is "a record or proposal quoting a non-conforming value outside frontmatter (e.g. inside a fenced example) must not be denied for it."
Kind: composition
Seed: core/hooks/record-fields-gate.sh `placeholder_shas`, diff hunk changing `region = fm.group(1) if fm else ""` to match against `text.lstrip()` and fall back to `region = text` (full document) when unmatched
cap_seconds: 120
tier: default
diff_stat_lines: 82 insertions(+), 2 deletions(-) across 3 files
started_at: 2026-08-08T00:00:00Z
ended_at: 2026-08-08T00:20:00Z

### Reproduce
Payload (a role-record write with no leading `---` fence, all section-20 fields present, and an indented documentation example quoting a bad sha spelling -- the exact shape issue-153 exists to permit):

```
$ printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"REDACTED-role-record-path.md","content":"loop_state: landed\n\n## what was done\nx\n\n## why\ny\n\nExample of a bad value that must be denied:\n\n    sha: HEAD\n\nupstream: abc1234\n\n## open findings\nnone\n"}}' \
    | env CLAUDE_ROLE=implementation CLAUDE_PROJECT_DIR=/tmp /bin/bash core/hooks/record-fields-gate.sh
implementation: refused — record has 1 unmet requirement(s): sha: HEAD is not `same-commit` or a 40-character hex commit sha (issue-128/133). ...
$ echo $?
2
```
(REDACTED-role-record-path.md stands in for the real target path
`docs/issue-157/reports/implementation.md`; the literal substring is
elided here only because this repo's own board-gate.sh statically greps
Bash command text for issue-tree paths and misfires on it appearing
inside a JSON payload string. The actual command run during the hunt used
the real path and reproduced exactly as shown.)

Isolated regex trace (region computed both the pre-diff and post-diff way, from the same fence-less body text):
```
OLD region repr: ''
OLD bad: []
NEW bad: ['HEAD']
```

### Observed
Post-diff, the fence-less record above is denied (`rc=2`), citing the quoted example text `sha: HEAD` as if it were an actual frontmatter field, even though the record satisfies every section-20 requirement and the `sha: HEAD` only appears as an indented illustrative example in prose, not as a real `sha:` field.

### Expected
Per issue-153's own rationale (restated verbatim in this same function's comments: "a record or proposal quoting a non-conforming value outside frontmatter... must not be denied for it"), a fence-less document -- which by definition has no frontmatter region -- should not have its body prose treated as frontmatter and scanned for `sha:` values; the write should be allowed (`rc=0`), same as the pre-diff behavior for this shape, which happened to allow it (for the wrong reason: an empty region) but reached the correct outcome (for the right reason: the value is not a frontmatter field).
