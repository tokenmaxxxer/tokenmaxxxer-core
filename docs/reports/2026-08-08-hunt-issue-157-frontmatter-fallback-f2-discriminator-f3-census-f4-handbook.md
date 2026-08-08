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
