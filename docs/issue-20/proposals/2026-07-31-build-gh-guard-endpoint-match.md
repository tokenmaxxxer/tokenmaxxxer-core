---
kind: build-proposal
subject: issue-20
produced_by: implementation
upstream:
  - path: docs/issue-20/reports/implementation/survey.md
    sha: HEAD
loop_state: proposed
---

# Proposal: match gh-guard on endpoint+verb, not on the `gh` token (issue #20)

## files

- `core/hooks/gh-guard.sh` — the `RULES` list and the Layer 0 pre-filter
  (`gh-guard.sh:34-41`, `68-89`).
- `core/hooks/tests/run-gh-guard-tests.sh` — one new `run` line per case
  confirmed in the survey, both the newly-denied cases and the still-open
  ones (recorded as `allow` tests so the gap stays visible instead of
  silently reappearing).
- `README.md` — reframe the two-account model (lines 37-55) from "optional
  hardening" to the structural fix, with gh-guard named explicitly as
  defense-in-depth rather than a complete answer, matching the issue's own
  "Direction" section.

No other file: `core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`,
`core/contract/role-handoff-contract.md`, and `spawn.py`/
`MUSTER_AGENT_GH_TOKEN` (which do not exist in this repository — the survey
confirmed this; they live in the `muster` repo the issue cites) are all out
of scope. See "Out of scope" below for why.

## Request

Issue #20: all seven of gh-guard's `RULES` (`core/hooks/gh-guard.sh:68-89`)
anchor on the literal token `gh` (or `git push`) appearing in the Bash
command string. The survey
(`docs/issue-20/reports/implementation/survey.md`) verified, by running
`gh-guard.sh` as a subprocess against fabricated `PreToolUse` payloads, that
this leaves two closable gaps and two structural, non-closable-by-regex
gaps:

- **Closable (Groups A/B in the survey):** a different HTTP client
  (`curl`, `wget`, …) reaching the exact same REST endpoints the rules
  already name; and `gh` itself, via call shapes the seven rules never
  enumerated (GraphQL mutations, raw-API PR close/reopen, raw-API issue
  edit/close/reopen). Every one of these still asks GitHub for the same
  documented REST/GraphQL surface, in the same single Bash command string —
  matchable by widening what Layer 1 looks for.
- **Not closable by this gate's design (Groups C/D):** a script written to
  a file first and then executed (`bash file.sh`) is invisible because
  gh-guard never reads file contents; a renamed/copied `gh` binary defeats
  the subcommand-form rules specifically; an obfuscated destination host
  (literal IP) defeats even Layer 0's substring pre-filter; and any tool
  other than `Bash` is outside gh-guard's field of view entirely
  (`gh-guard.sh:35`). None of these are fixable by adding more regexes to a
  single-command-string matcher — they need either a materially different,
  stateful hook design, or removing the incentive at the account layer
  (the issue's own two-account-model "Direction").

This proposal builds the closable half and documents the rest as accepted,
named residual risk rather than leaving it as an unstated gap.

## Constraints

- Deny-only, fail-closed, bash 3.2-compatible — the same house rules
  `README.md`'s "Rules" section already states for every hook in this repo.
  No `permissionDecision: "allow"`; any unreadable/unexpected input still
  denies.
- No behavior change to the six cases `run-gh-guard-tests.sh` already
  asserts as `allow` today (`gh pr comment` without `APPROVE`,
  `git push -u origin issue-7/coding`, `gh pr create`, `gh pr view`,
  `gh issue view`, `git commit`) — the new rules must not turn ordinary
  phase-1 research or phase-2 delivery commands into false denials. This is
  this proposal's own stated failure signal (below), not just a constraint.
- Stay a defense-in-depth patch, not a claimed fix: the survey's Group
  C/D gaps stay open after this lands, and the README change must say so
  rather than imply completeness.
- No change to `approval-gate.sh` or `board-gate.sh` — neither is
  implicated; the bypasses all reach `api.github.com` directly, not the
  local `docs/`/`src/`/`test/` write surface those gates police.

## What will be done

1. **Endpoint+verb rules in `RULES`, independent of client binary.** Add
   patterns that match a GitHub REST path together with a mutating HTTP
   verb or `gh api`'s own write-field flags, with no `\bgh\b`/`\bcurl\b`
   prefix requirement, so the same pattern fires whether the call is spelled
   as `gh api …`, `curl -X … …`, or `wget --method=… …`:
   - `pulls?/\d+/(reviews|merge)` alongside a mutating verb
     (`-X\s*(POST|PUT|PATCH|DELETE)`, `--method[= ]`, or `-f\s`) — extends
     today's rule 4 to non-`gh` clients.
   - `pulls?/\d+\b` (bare, no `/merge` or `/reviews` suffix) alongside
     `state\s*=\s*(closed|open)` or `-f\s+state=` — closes the raw-API
     PR close/reopen gap (Group B).
   - `issues?/\d+\b` alongside a mutating verb or `-f\s+(state|title|body)=`
     — closes the raw-API issue edit/close/reopen gap (Group B), the raw-API
     counterpart to today's rule 3.
   - `/graphql\b` alongside one of the mutation names
     `mergePullRequest|addPullRequestReview|closePullRequest|
     reopenPullRequest|closeIssue|reopenIssue|updateIssue|deleteIssue` —
     closes the GraphQL gap (Group B), regardless of whether it's reached
     via `gh api graphql` or a raw POST to `/graphql`.
2. **Widen Layer 0's pre-filter** (`gh-guard.sh:38-41`) from `*gh*|*git*` to
   also include `*curl*`, `*wget*`, `*http://*`, `*https://*`, so a
   github.com-hostname call from a non-`gh`/`git`-named client reaches
   Layer 1 by design, not by the accidental "github" contains "git" side
   effect the survey documented. (This does not close the literal-IP case —
   documented as an explicit residual gap in item 4 below, not silently
   dropped.)
3. **Tests**: one `run deny …` line per newly-closed case (curl-merge,
   wget-merge, curl-review, gh-api raw PR close/reopen, gh-api raw issue
   edit/close/reopen, gh api graphql merge/approve), plus `run allow …`
   lines for the three constraint cases in "Constraints" above (unchanged
   behavior) and for the two Group C cases and the Write-tool Group D case,
   labeled in the test file as documented, accepted gaps — not silently
   passing, but visibly present so a future reader sees exactly what this
   gate does and does not cover.
4. **README.md**: change the "Hardening options (optional)" framing
   (line 49) to state plainly that the two-account model is the structural
   fix for the self-approval risk this issue names, that `gh-guard.sh`'s
   pattern rules are defense-in-depth over the common/accidental path only,
   and name the specific residual gaps (file-indirection, renamed binary,
   obfuscated host, non-Bash tools) with a pointer to
   `run-gh-guard-tests.sh`'s documented-gap test cases — so the next reader
   of this repo doesn't mistake the blocklist for a completed fix, which is
   exactly the mistake the issue itself warns against.

## Alternatives considered

- **Do nothing in this repo; treat gh-guard as vestigial until the
  two-account model is adopted everywhere.** Rejected: the two-account
  model needs a *different* repo's `spawn.py` change plus operator opt-in
  (`README.md` already calls it optional), so every single-account
  deployment — the documented default — stays exposed indefinitely, and the
  issue's own text calls the blocklist extension "worth doing... as
  defense in depth," not worth skipping.
- **Move enforcement to the network/sandbox layer** (deny outbound HTTPS to
  `api.github.com` from any process except `gh`). Rejected for this phase:
  no per-process network ACL mechanism exists in this repo's model — the
  `allowedDomains` config the issue cites is domain-scoped, not
  process-scoped — and building one is a different, much larger project
  than a `core/hooks/` deny-only regex gate is designed to be; worth naming
  as a longer-term idea in the README update (item 4) but not this phase
  2's implementation.

## Out of scope

- Closing the survey's Group C (renamed/copied `gh` binary, script-file
  indirection, literal-IP host obfuscation) and Group D (non-`Bash` tools)
  gaps. Doing so needs inspecting file contents and tracking them across
  tool calls — a stateful redesign this single-command-string, deny-only
  hook was not built for — or the account-layer fix the issue's own
  "Direction" section names. Both are explicitly recorded as open, not
  silently dropped (see "What will be done" item 3's documented-gap tests
  and item 4's README wording).
- `core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`,
  `core/contract/role-handoff-contract.md`: unaffected — none of the
  bypasses touch the local write-surface gates or the contract text.
- `spawn.py` / `MUSTER_AGENT_GH_TOKEN`: do not exist in this repository
  (confirmed by the survey); any change to how the agent token is minted or
  injected belongs to the `muster` repo the issue cites, not here.
- Deciding whether the two-account model becomes non-optional as a matter
  of project policy — this proposal only changes how the README *describes*
  the two options; it does not remove the single-account path or add any
  enforcement that requires it.

## Failure signal

If, after this lands, `run-gh-guard-tests.sh` still passes a `curl`/`wget`
call to `pulls/\d+/(reviews|merge)`, a raw-API PR close/reopen, a raw-API
issue mutation, or a `gh api graphql` merge/approve mutation as `allow`,
the fix did not work — those are exactly the deny-tests item 3 adds. If,
instead, any of the six previously-`allow` cases in "Constraints" above (or
ordinary phase-1 `curl`-free research work) starts getting denied, the new
rules are over-broad and need verb-scoping tightened before merge — that
regression is the concrete thing to watch for, checkable by re-running
`core/hooks/tests/run-gh-guard-tests.sh` and `core/hooks/tests/run-all.sh`.

## How we'll know it worked

- `/bin/bash core/hooks/tests/run-gh-guard-tests.sh` passes, including the
  new deny-cases for curl/wget REST hits, raw-API PR close/reopen, raw-API
  issue mutation, and `gh api graphql` merge/approve — and the pre-existing
  allow-cases still pass unchanged.
- `/bin/bash core/hooks/tests/run-all.sh` passes end to end (bash 3.2
  parse, deny-only shape check, board gate, approval gate, gh guard,
  sibling-plugin parse checks) — confirming the change is additive to
  `gh-guard.sh` only.
- `README.md`'s hardening section, read after the edit, states the
  two-account model as the structural fix and names gh-guard's residual
  gaps explicitly, rather than presenting the blocklist as sufficient on
  its own.
