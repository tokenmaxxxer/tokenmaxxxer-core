---
proposal: docs/issue-304/proposals/review-kill-switch-drift-propagation.md
---

# Hunt record — review-kill-switch-drift-propagation

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — record-shape-gate.sh's config-driven dispatch for CLAUDE_ROLE=conformance-review never matches the phase-2 record path this proposal commits to (`docs/issue-304/reports/conformance-review.md`), so the gate silently no-ops on that write regardless of content.
Kind: silent-failure
Seed: docs/issue-304/proposals/review-kill-switch-drift-propagation.md, docs/issue-304/reports/conformance-review/survey.md (218 added lines, 2 files)
cap_seconds: 180
tier: size:>200-lines
diff_stat_lines: 218
started_at: 2026-08-25T04:31:17Z
ended_at: 2026-08-25T04:35:30Z

### Reproduce
core/hooks/record-shape-config.json's "conformance-review" role rows have
target_path_regex values `docs/issue-<n>/proposals/review.md` (the `<n>`
is a literal, never-interpolated placeholder — `<` and `>` are not regex
metacharacters) and `docs/issue-42/proposals/conformance-review.md`
(hard-pinned to issue 42, and to `proposals/` rather than `reports/`).
Neither matches this proposal's own declared phase-2 deliverable path.

```
python3 -c "
import re, json
cfg = json.load(open('core/hooks/record-shape-config.json'))
target = 'docs/issue-304/reports/conformance-review.md'
for row in cfg['conformance-review']:
    print(row['target_path_regex'], '->', bool(re.search(row['target_path_regex'], target)))
"
# -> docs/issue-<n>/proposals/review.md -> False
# -> docs/issue-42/proposals/conformance-review.md -> False
```

Direct gate invocation, simulating the phase-2 Write this proposal
describes ("What will be done" / "How you'll know it worked": record
lands at `docs/issue-304/reports/conformance-review.md`), with content
that has zero frontmatter, no `loop_state`/`verdict`/`type`, no headings
at all:

```
export CLAUDE_ROLE=conformance-review
export CLAUDE_PROJECT_DIR=<repo root>
printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-304/reports/conformance-review.md","content":"garbage content, no frontmatter, no verdict, no loop_state, nothing at all"}}' \
  | core/hooks/record-shape-gate.sh; echo "EXIT_CODE=$?"
```

### Observed
`EXIT_CODE=0` — the gate allows the write unconditionally. The hardcoded
implementation-role check inside record-shape-gate.sh only matches
`docs/issue-<n>/reports/implementation.md` (regex
`^docs/issue-[0-9]+/reports/implementation\.md$`), so it skips this path
entirely; the config-driven CHECKERS dispatch loads the `conformance-review`
role's two rows but both target_path_regex values fail to match the real
path (shown above), so `matched_rows` stays empty and the script exits 0
with no shape check performed at all.

### Expected
Since this proposal names `docs/issue-304/reports/conformance-review.md`
as the phase-2 record this role is accountable for, and phase 2 depends
on record-shape-gate.sh (or an equivalent config row) to enforce that the
record is actually filled with the required verdict/citation shape, the
gate should either match that path via a properly-interpolated `<n>` (or
generic `docs/issue-[0-9]+/reports/conformance-review\.md`) regex, or the
proposal should flag this coverage gap explicitly instead of silently
depending on a gate that currently no-ops for this exact write. As
written, phase 2 could write an empty or garbage `conformance-review.md`
and no PreToolUse gate in this repo would refuse it on shape grounds.
