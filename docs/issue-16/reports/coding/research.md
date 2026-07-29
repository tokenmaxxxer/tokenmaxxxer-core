---
subject: issue-16
role: coding
loop_state: scope-proposed
---

# Research: plugin.json advertises the retired token machinery

## Issue, as read

`gh issue view 16 --comments` could not reach the GitHub API in this
sandbox: every `gh` call against `api.github.com` (both `gh issue view`,
which uses GraphQL, and `gh api repos/.../issues/16`, which uses REST)
failed identically with `tls: failed to verify certificate: x509:
OSStatus -26276`, while `curl https://api.github.com` from the same shell
returned `200`. `gh auth status` also reported the `GH_TOKEN` in this
environment as invalid. This looks like a sandbox-local TLS/keychain-trust
gap specific to the `gh` Go binary rather than a network-policy block
(`api.github.com` is on the allowed-hosts list and `curl` reached it
fine). Retried twice; not transient.

Worked around with the `WebFetch` tool against
`https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/16`, once for a
summary pass and once explicitly asking for verbatim reproduction. Both
passes agree on substance and match what direct repository inspection
shows (below), but `WebFetch` runs the page through a small summarizing
model, not a byte-exact API response — so this survey treats the repo
tree, not the fetched issue text, as ground truth for every factual claim,
per the task's own instruction. Where the two diverge, that is called out
in `current-state.md`.

Issue #16, "plugin.json advertises the retired token machinery as core's
purpose" (open, no assignee, no comments): `core/.claude-plugin/
plugin.json:3` still describes a single-use approval-token minting
mechanism that was deleted in commit `1a69a08`. The description is the
first thing a user reads on install and it names something that no longer
ships. The issue lists what core ships today (contract v3, `directive.sh`,
`board-gate.sh`, `approval-gate.sh`, `gh-guard.sh`), asks that the missing
`version` field stay missing with its rationale sentence preserved, and
states "done when" as: the description matches what ships, and `bash
core/hooks/tests/run-all.sh` passes. The last part is a phase-2 (code
already correct, no test changes needed) sanity condition, not something
phase-1 documents can satisfy — noted here so the proposal's closing
section can point at it as an existing check rather than inventing a new
one.

## Commit 1a69a08: confirmed

`git show --stat 1a69a08` / `git log --oneline -5 1a69a08`:

```
1a69a08 Replace token machinery with the issue/PR interaction model (contract v3)
de22610 Merge pull request #1 from tokenmaxxxer/feat/parse-check-conformance
ba7066c Make the board gate cheap enough, and narrow enough, to enable everywhere
e3ea21f Distribute the bash 3.2 parse check the way deny-only-check is distributed
872d5d7 The judge-log test could not fail; fix it and stop writing outside the tempdir
```

Files the commit deleted outright: `core/hooks/mint.sh` (174 lines),
`core/hooks/lib/consent.py` (162 lines), `core/hooks/lib/judge.py` (168
lines), plus their test files `core/hooks/tests/run-mint-tests.sh`,
`core/hooks/tests/test_consent_lib.py`, `core/hooks/tests/
test_judge_lib.py`. Same commit added `core/hooks/directive.sh` (new,
SessionStart) and rewrote `core/hooks/board-gate.sh` and `README.md`
substantially. This matches the issue's claim exactly — nothing to
correct here.

## Scout brief: ecosystem convention for the `description` field

Scouting was bounded to ONE round over in-repo convention (no external
web search performed) because the deliverable is a single manifest string
with no external product category to benchmark against — the only
relevant "competitors" are this repo's own sibling plugin manifests and
its marketplace listing, which is exactly what Claude Code's own
plugin-manifest format expects a `description` field to look like (a
single dense paragraph, no markdown, read by `claude plugin install`
output and marketplace listings).

Exemplars actually found (all in-repo, byte counts via `jq -r
.description ... | wc -c`):

1. `terse/.claude-plugin/plugin.json` (321 chars): "Output-token
   compression for every tokenmaxxxer role session: strips conversational
   filler, code echoes, formatting scaffolding, and repeated summaries
   from the session's prose while exempting code, worker prompts, frozen
   contracts, and safety-critical messages. Composes with freelunch where
   present. Levels via `/terse`."
2. `scout/.claude-plugin/plugin.json` (385 chars): capability-first,
   names its mechanisms ("Camp benchmarking + Kano expectations +
   saturation stop rule") and its output path.
3. `.claude-plugin/marketplace.json`'s own `core` entry (447 chars) —
   notably, this listing entry is **already accurate**: "Shared machinery
   every tokenmaxxxer role enables alongside its own rulebook. Owns the
   issue/PR interaction protocol (contract v3): ... Gates enforce layout,
   contract sync, role, branch, ownership, and the propose-first phase."
   It never mentions token minting. This means the marketplace listing
   and the plugin manifest have already drifted apart — issue #16 is
   `plugin.json` catching up to a description that the marketplace
   listing beside it already carries correctly.

Register observed: one dense paragraph, 2-4 sentences, ~300-450 chars,
technical/precise voice, no marketing language, mechanisms named by what
they do more often than by filename (only the current stale `core`
description names one thing by role — "board gate" — and even that isn't
a filename). `core`'s own manifest description has historically run the
longest of the four plugins (419 chars currently vs. 268-385 for the
other three), so `core` naming more surface area than its siblings is
already the established pattern, not a departure from it.

## Version field: rationale located

`core/.claude-plugin/plugin.json` has no `version` field. This is
deliberate, and stated in two places:

1. Inline, as the closing sentence of the `description` field itself
   (added in commit `8696dd5`, "Publish without a version field, and
   document both modes"): *"No version field on purpose: for a
   git-distributed plugin the commit SHA is the version, so every commit
   is an update."*
2. `README.md:146-148` (prose, same commit): *"`plugin.json` carries **no
   `version` field**, deliberately. For a git-distributed plugin the
   commit SHA is the version, so `claude plugin update` sees every commit
   as an update."*

The commit message for `8696dd5` gives the "why now": *"All nine
rulebooks sat at 0.1.0 and `claude plugin update` answered 'already
latest' regardless of how far the installed cache had fallen behind the
marketplace clone — the measured pitfall that forced muster's
uninstall/reinstall dance. This repo does not reproduce it."*

`README.md`'s sentence is prose about the same fact, not a verbatim echo
of the `plugin.json` sentence, and nothing else in the repo quotes the
`plugin.json` description verbatim — so preserving sentence 1 unchanged
inside the rewritten description does not require touching `README.md`
in lockstep. See `current-state.md` for the full reasoning on why the
phase-2 write set stays a single file.
