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

## before-landing — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — a leading UTF-8 BOM (Unicode codepoint U+FEFF) as the first character of the written content makes `placeholder_shas` return `[]` unconditionally, allowing any sha value (including unresolved placeholders like `HEAD`) inside otherwise well-formed frontmatter
Kind: silent-failure
Seed: core/hooks/record-fields-gate.sh, `placeholder_shas` (diff: 2026-08-08-narrow-sha-scan-scope-and-empty-value-carveout.md)
cap_seconds: 120
tier: default
diff_stat_lines: ~21 (record-fields-gate.sh only; test/handbook diffs mechanical per dispatcher note)
started_at: 2026-08-08T02:33:40Z
ended_at: 2026-08-08T02:41:00Z

### Reproduce

The new frontmatter-scoping regex uses `re.match(...)`, which anchors only
at position 0 of `text` (not "start of any line" — `re.match` never
retries at a later offset the way `re.search`/`finditer` would). `Write`
tool_input content is used verbatim by `gate_reconstruct_write` (no
`utf-8-sig`/BOM stripping — that only applies when *reading an existing
file* in the outer Python block, via `open(r, encoding="utf-8-sig")`). So a
`content` string that begins with codepoint U+FEFF before the opening
`---` fence makes the whole `fm = re.match(...)` fail to match at all, and
`region` silently falls back to `""` — meaning every `sha:` line in the
document, however malformed, escapes the scan.

Direct regex-level repro (extracted verbatim from the current on-disk
function):

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
    return bad

def placeholder_shas_old(text):  # pre-issue-153 behavior, for comparison
    bad = []
    for m in re.finditer(r'^\s*sha:\s*(.*)$', text, re.M):
        v = m.group(1).strip()
        if v == "same-commit" or re.match(r'^[0-9a-f]{40}$', v):
            continue
        bad.append(v)
    return bad

doc = "﻿---\nupstream: docs/issue-153/proposals/some-upstream.md\nsha: HEAD\n---\nbody text\n"

print("new (post-fix) bad:", placeholder_shas(doc))
print("old (pre-fix) bad :", placeholder_shas_old(doc))
```

Full end-to-end repro through the actual hook, via stdin, `Write` tool
shape, targeting `docs/issue-153/proposals/...` (the `is_proposal` path):

```bash
export CLAUDE_PROJECT_DIR="$(pwd)"
export CLAUDE_ROLE="implementation"

python3 - <<'PY'
import json
content = "﻿---\nupstream: docs/issue-153/proposals/some-upstream.md\nsha: HEAD\n---\nbody text\n"
json.dump({"tool_name": "Write", "tool_input": {
    "file_path": "docs/issue-153/proposals/2026-08-08-bom-bypass-poc.md",
    "content": content}}, open("/tmp/repro_payload.json", "w"))
PY

bash core/hooks/record-fields-gate.sh < /tmp/repro_payload.json
echo "EXIT_CODE=$?"
```

For comparison, the identical payload minus the leading BOM:

```bash
python3 - <<'PY'
import json
content = "---\nupstream: docs/issue-153/proposals/some-upstream.md\nsha: HEAD\n---\nbody text\n"
json.dump({"tool_name": "Write", "tool_input": {
    "file_path": "docs/issue-153/proposals/2026-08-08-bom-bypass-poc.md",
    "content": content}}, open("/tmp/repro_payload_control.json", "w"))
PY

bash core/hooks/record-fields-gate.sh < /tmp/repro_payload_control.json
echo "EXIT_CODE=$?"
```

### Observed

Direct regex-level:
```
new (post-fix) bad: []
old (pre-fix) bad : ['HEAD']
```

End-to-end, BOM-prefixed payload: `EXIT_CODE=0` — no denial message at
all, the write is allowed with `sha: HEAD` sitting in real frontmatter.

End-to-end, control (same payload, no BOM):
```
implementation: refused — sha: HEAD is not `same-commit` or a 40-character hex commit sha (issue-128/133). Per contract §1's same-commit convention, write `sha: same-commit` when `path` lands in this same commit; otherwise use the real 40-character commit sha.
EXIT_CODE=2
```

### Expected

The BOM character is invisible in virtually every editor and terminal and
does not change what a human reading the document sees; the frontmatter is
otherwise completely well-formed (`---` fence, `upstream:`, a bad `sha:`
value, closing `---`, real body text below). It is not a fenced quotation
and not body prose — it is exactly the region issue-153's own doc comment
says the scan must still cover. The gate should still deny `sha: HEAD` here,
the same way it does with the BOM stripped (see control run above), and the
same way the pre-issue-153 code did (whole-document `re.finditer`, which is
insensitive to what precedes the first `sha:` line). Because `re.match`
requires the *very first character of the string* to start the fence
pattern, this is not a hypothetical: any Write whose `content` begins with a
BOM — whether pasted in by a human, round-tripped through a tool that
prepends one, or supplied by an adversarial role deliberately probing the
gate — silently defeats the sha placeholder check for the entire document,
regardless of narrowing intent. `gate_reconstruct_write`'s existing
`utf-8-sig` handling shows the authors are aware BOMs occur in this
plugin's file I/O for *reads* of existing files; that awareness was not
carried into the `Write`-content path or into `placeholder_shas`'s anchor.

### Resolution

Fixed in the same commit this hunt gates: `placeholder_shas` now strips a
leading `﻿` (BOM) from `text` before running the frontmatter anchor
(`core/hooks/record-fields-gate.sh`, immediately above the `fm = re.match(...)`
line). Re-run of both repro cases above against the patched function:
end-to-end BOM-prefixed payload now exits 2 (denied, `sha: HEAD is not
`same-commit`...`), matching the no-BOM control. Regression-pinned as
`run_rf deny "before-landing hunt: leading BOM does not bypass the sha
check (issue-153)"` in `core/hooks/tests/run-role-gates-tests.sh`; full
suite: `role-gates: 56 passed, 0 failed`.
