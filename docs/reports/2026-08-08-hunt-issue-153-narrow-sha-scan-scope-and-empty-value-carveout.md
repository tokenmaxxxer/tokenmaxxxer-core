---
proposal: docs/issue-153/proposals/2026-08-08-narrow-sha-scan-scope-and-empty-value-carveout.md
---

# Hunt record — narrow-sha-scan-scope-and-empty-value-carveout

## after-proposal — stance 0: assume the fix is bypassable / breaks a currently-working case

Verdict: FINDING — a frontmatter-only document with no trailing newline after the closing `---` fence makes the proposed frontmatter-boundary regex fail to match at all, so `placeholder_shas` scans an empty region and silently allows a `sha:` value (e.g. `HEAD`) that the current (unfixed) code correctly denies.
Kind: design-error
Seed: docs/issue-153/proposals/2026-08-08-narrow-sha-scan-scope-and-empty-value-carveout.md "## What will be done" item 1 (frontmatter-boundary extraction `^---\r?\n(.*?\n)---\r?\n`, re.DOTALL, matched from the start of the reconstructed text; "a document with no such block yields an empty region"); compared against `core/hooks/record-fields-gate.sh:174-181` (current `placeholder_shas`)
cap_seconds: 60
tier: default (docs-only fast path)
diff_stat_lines: 0 (phase-1, docs only — no code diff yet; proposal text ~224 lines, survey ~252 lines)
started_at: 2026-08-08T01:49:52Z
ended_at: 2026-08-08T01:52:58Z

### Reproduce

Standalone Python exercising the exact pattern text from "## What will be
done" item 1-3 (frontmatter extraction, value pattern, comment strip, empty
carve-out) side by side with the current pattern at
`core/hooks/record-fields-gate.sh:176`:

```python
import re

FRONTMATTER_RE = re.compile(r'^---\r?\n(.*?\n)---\r?\n', re.DOTALL)

def placeholder_shas_proposed(text):
    m = FRONTMATTER_RE.match(text)
    region = m.group(1) if m else ""
    bad = []
    for lm in re.finditer(r'^\s*sha:[ \t]*(.*)$', region, re.M):
        v = re.sub(r'[ \t]+#.*$', '', lm.group(1)).strip()
        if v == "":
            continue
        if v == "same-commit" or re.match(r'^[0-9a-f]{40}$', v):
            continue
        bad.append(v)
    return bad

def placeholder_shas_current(text):
    bad = []
    for m in re.finditer(r'^\s*sha:\s*(.*)$', text, re.M):
        v = m.group(1).strip()
        if v == "same-commit" or re.match(r'^[0-9a-f]{40}$', v):
            continue
        bad.append(v)
    return bad

# A well-formed frontmatter block whose content ends exactly at the closing
# fence, with no trailing newline after it (file/content simply stops there).
doc = "---\nkind: build-proposal\nupstream:\n  - path: P\n    sha: HEAD\n---"

print("current (unfixed) gate:", placeholder_shas_current(doc))
print("proposed gate        :", placeholder_shas_proposed(doc))
```

### Observed

```
current (unfixed) gate: ['HEAD']
proposed gate        : []
```

`FRONTMATTER_RE.match(doc)` returns `None` because the pattern hard-requires
`---\r?\n` (a newline literally present) after the closing fence; the
document ends at `---` with zero trailing bytes, so the match fails
entirely. Per the proposal's own stated fallback ("a document with no such
block yields an empty region"), `region` becomes `""`, the per-line scan
runs over nothing, and `HEAD` — one of the exact values issue-128/133's
existing test suite denies — is never inspected. `deny_placeholder` is
never called; the write is allowed.

### Expected

The value `sha: HEAD`, sitting inside a genuine, well-formed `---`-delimited
frontmatter block (not fenced-code quotation, not body text — precisely the
region the proposal says the check should still cover), should be denied
before and after the fix, exactly as the current code already denies it.
The proposal's rationale for the empty-region fallback — "other gates
already require a well-formed proposal/record shape" — only argues for the
case where no frontmatter exists at all; no gate in this repository is shown
to require a trailing newline character immediately after the closing `---`
fence, so a document whose content simply happens to end there (a plausible
shape for a Write-tool `content` string, which nothing forces to end with a
newline) silently loses sha coverage entirely under the proposed design,
regressing a case the current, unfixed code gets right. None of the
proposal's listed test cases (F1 red→green, F1 regression, F1 comment case,
F2 red→green, F2 message-accuracy, or the six named regression cases) covers
a frontmatter-only/no-trailing-newline document, so this gap would ship
untested.
