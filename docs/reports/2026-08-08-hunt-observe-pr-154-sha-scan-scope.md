---
proposal: docs/issue-153/proposals/2026-08-08-observe-pr-154-sha-scan-scope.md
---

# Hunt record — observe-pr-154-sha-scan-scope

## after-proposal — stance 0: assume the gate just touched is bypassable; find the bypass

Verdict: FINDING — the phase-1 evidence plan's Level-3 item 1 scopes review of `placeholder_shas`'s new frontmatter anchor to only "what the permissive empty-region branch stops enforcing when the anchor does not match" (the whole-document BOM-style failure, already found and fixed in 3f67436). It never directs the observer to the sibling failure mode of the same regex — the anchor *matching too early* on an inner line that happens to equal `---`, which silently truncates the scanned region and drops a bad `sha:` value that the author still wrote as part of the same intended frontmatter block. A phase-2 record that follows the evidence plan verbatim, cites the BOM fix/regression test as satisfying item 1, and marks Level 3 item 1 "supports the observed role's account" would tick every stated success criterion (three levels addressed, adjacent citations, six step-level artifacts covered) while never noticing this second, untested truncation path is still open in the landed `record-fields-gate.sh`.
Kind: composition
Seed: docs/issue-153/proposals/2026-08-08-observe-pr-154-sha-scan-scope.md (Level 3 item 1 wording) against `git show 3f67436 -- core/hooks/record-fields-gate.sh`'s `placeholder_shas` regex `r'^---[ \t]*\r?\n(.*?\n)^---[ \t]*\r?$'`
cap_seconds: 60
tier: size:docs-only
diff_stat_lines: 3 files changed (survey.md, scout-brief.md, proposal — uncommitted phase-1 trio); admissible-evidence diff 3f67436 touches 5 files, 392 insertions / 10 deletions
started_at: 2026-08-08T02:51:37Z
ended_at: 2026-08-08T02:56:10Z

### Reproduce
Standalone python3, reasoning only over the `placeholder_shas` regex copied verbatim from `git show 3f67436 -- core/hooks/record-fields-gate.sh` (no hook/suite execution):

```python
import re

def placeholder_shas(text):
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
    return bad, region

doc = (
    "---\n"
    "upstream:\n"
    "  - path: alpha/survey.md\n"
    "    sha: same-commit\n"
    "---\n"                      # accidental/duplicate mid-block fence line
    "  - path: alpha/other.md\n"
    "    sha: HEAD\n"            # bad value the author still wrote as part of frontmatter
    "---\n"                      # the fence the author actually intended to close with
)

bad, region = placeholder_shas(doc)
print(repr(region))
print(bad)
```

### Observed
```
'upstream:\n  - path: alpha/survey.md\n    sha: same-commit\n'
[]
```
The non-greedy `(.*?\n)^---[ \t]*\r?$` closes on the *first* line that is exactly `---`, so the region silently truncates before the second `upstream` entry. `sha: HEAD` is never scanned; `bad` comes back empty, i.e. the hook would ALLOW a document containing a non-conforming `sha: HEAD` value that a reader (and the pre-issue-153 whole-document scan) would treat as inside the governed frontmatter block. No error, no partial-scan warning — a silent failure of the same class as the BOM bug the delivery already found and fixed, but on the opposite side of the anchor (matches early vs. doesn't match at all).

### Expected
Either the scan region should extend to the *last* `---`-only line before the next non-frontmatter content (or otherwise be robust to an interior `---`-shaped line), or `placeholder_shas`/its test suite should demonstrate that this shape cannot legitimately arise in this repo's frontmatter convention. Absent that, the phase-2 record's Level 3 item 1 — as scoped by the phase-1 evidence plan to the empty-region branch only — will not surface this, because the plan never asks the observer to test the anchor-matches-early case.
