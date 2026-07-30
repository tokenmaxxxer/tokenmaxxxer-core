---
kind: coding-record
subject: issue-16
produced_by: coding
loop_state: done
upstream:
  - path: docs/issue-16/reports/coding/current-state.md
    sha: 9c481d360e25c0d05a065241404b273303d566de
  - path: docs/issue-16/reports/coding/research.md
    sha: 9c481d360e25c0d05a065241404b273303d566de
  - path: docs/issue-16/proposals/plugin-description.md
    sha: 9c481d360e25c0d05a065241404b273303d566de
code_under_review: 9c481d360e25c0d05a065241404b273303d566de
closed_checks:
  - name: json-parses
    code_sha: 9c481d360e25c0d05a065241404b273303d566de
  - name: no-mint-token-challenge-references
    code_sha: 9c481d360e25c0d05a065241404b273303d566de
  - name: version-field-rationale-verbatim
    code_sha: 9c481d360e25c0d05a065241404b273303d566de
  - name: no-version-key-introduced
    code_sha: 9c481d360e25c0d05a065241404b273303d566de
  - name: hooks-run-all-passes
    code_sha: 9c481d360e25c0d05a065241404b273303d566de
---

# Coding record — issue-16, phase 2

Approved via issue-level comment `APPROVE issue-16/coding` (single-account
mode) on issue #16.

## Why

`core/.claude-plugin/plugin.json:3`'s `description` field still advertised
the retired single-use approval-token-minting mechanism, deleted in commit
`1a69a08` ("Replace token machinery with the issue/PR interaction model
(contract v3)") along with `core/hooks/mint.sh`, `core/hooks/lib/
consent.py`, and `core/hooks/lib/judge.py`. That text was written one day
before the deletion (commit `8696dd5`) and was never revisited, so the
description — the first thing a plugin installer reads — described
machinery that no longer ships.

## Scope

`core/.claude-plugin/plugin.json` only, per the approved proposal
(`docs/issue-16/proposals/plugin-description.md`). Description-text
rewrite; no change to `core/contract/role-handoff-contract.md`,
`README.md`, `.claude-plugin/marketplace.json`, any hook file, or hook
tests. No `version` field introduced.

## What was done

Replaced the `description` value with the proposal's recommended (named)
candidate string:

> "Shared interaction-protocol machinery for every tokenmaxxxer role.
> Ships the canonical role-handoff contract (v3) and four hooks —
> directive.sh, board-gate.sh, approval-gate.sh, gh-guard.sh — the
> SessionStart briefing plus deny-only PreToolUse gates for docs layout,
> PR-Approve execution gating, and GitHub-act ownership. Gates refuse but
> never permit. No version field on purpose: for a git-distributed plugin
> the commit SHA is the version, so every commit is an update."

This drops every reference to minting, tokens, and challenge lines; names
the canonical contract as "the role-handoff contract (v3)"; enumerates
all four hooks by their on-disk filenames; restates the refuse-but-never-
permit invariant; and preserves the version-field rationale sentence
verbatim, unchanged.

Verification run after the edit:

- `python3 -c "import json; json.load(open('core/.claude-plugin/
  plugin.json'))"` exits 0 — valid JSON, `name`/`description`/`author`
  keys intact.
- `python3 -c "import json; print('version' in json.load(open(...)))"`
  prints `False` — no `version` key introduced.
- `grep -F "No version field on purpose: for a git-distributed plugin the
  commit SHA is the version, so every commit is an update."
  core/.claude-plugin/plugin.json` matches — rationale sentence survives
  verbatim.
- `bash core/hooks/tests/run-all.sh` — `ALL OK` (board-gate, approval-
  gate, gh-guard, parse-check across all four plugins all pass; the
  issue's stated "Done when" condition).

## What did not work

(none — single-field description rewrite, matched the proposal's
recommended candidate exactly)

## Open findings

None. Open-finding resolution path: not applicable — no `finding` block
is open against this record; should verify or review post one later, it
routes `addressed_to: coding` per section 5 and is closed via this
record's next revision.

## Next steps

None on this subject.

## Hunt (warrant-hunter, end of phase 2)

Stance: none dispatched. Change is a single-field, single-file manifest
description rewrite with mechanical verifications (JSON parse, grep
checks, full hook test suite) already run successfully; no code path, no
hook behavior, no composition surface for a warrant-hunter to probe.
Recorded per hunt-cadence requirement even though nothing was dispatched.

closed_checks:
- name: json-parses
  code_sha: 9c481d360e25c0d05a065241404b273303d566de
- name: no-mint-token-challenge-references
  code_sha: 9c481d360e25c0d05a065241404b273303d566de
- name: version-field-rationale-verbatim
  code_sha: 9c481d360e25c0d05a065241404b273303d566de
- name: no-version-key-introduced
  code_sha: 9c481d360e25c0d05a065241404b273303d566de
- name: hooks-run-all-passes
  code_sha: 9c481d360e25c0d05a065241404b273303d566de
