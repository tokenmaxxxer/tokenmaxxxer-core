---
kind: scout-brief
subject: issue-98
produced_by: execution-observation
loop_state: phase-1
---

# Scout brief — what a strong audit of a shell-gate bypass fix checks

Pass shape: **2 stages** (stage 1 sweep, stage 2 judge; deepening stopped at
saturation — no further round would change an evidence line). Mode:
**parallel tool calls in one turn** (3 concurrent `WebSearch` angles), not
subagents — this session's directive bars Agent-tool dispatch unless the user
asks. Angles were aimed at the survey's gaps U1–U4, written before this sweep.

Segment fit: the deliverable is a review of a denylist-style command gate, so
the field scouted is security-gate auditing and refactor review, not product UX.

## Category must-bes (what strong audits of this change class assume)

- Bypass audits of shell allowlists start from **the parse gap, not the
  string list**: quoting/concatenation tricks (`w'h'o'am'i` concatenating at
  parse time to defeat keyword denylists), `$(…)`/backtick substitution,
  `>(…)`/`<(…)`, and `BASH_ENV` when the spawned shell is `bash -c`.
  [Trail of Bits; PayloadsAllTheThings; OWASP]
- A bug fix's regression test is credible only when it is shown **red before
  the fix, green after** — the reviewer's job is both "the fix addresses the
  issue" and "nothing existing broke". A surviving mutant (fault introduced,
  tests still pass) is the standard name for the gap this catches.
  [DevIQ; CircleCI]
- **Do not mix refactoring with behavior change**: when both are in one diff a
  reviewer cannot tell which is which. A useful review starts by asking what
  moved, which behavior changed, and which public contracts were touched.
  [Code with Jason; code-refactor-review gist]

## Performance axes this deliverable competes on

1. Coverage of the bypass *class* vs. the enumerated strings.
2. Precision cost — how much legitimate use the over-block eats.
3. Separability — refactor-vs-behavior legibility of the same diff.

## Adopt / skip

- **Adopt:** the moved-symbol question as an explicit evidence line — the
  `TRANSPARENT` 6→8 relocation (survey U2) is exactly the "shared helper moved
  and quietly extended" shape the third must-be warns about.
- **Adopt:** red-before-green as the test standard for U1, applied to the
  record's own stash/pop evidence rather than to a re-run.
- **Skip:** running the field's bypass payloads (`$(…)`, `BASH_ENV`,
  concatenation) against the gate. Tempting, and the first must-be points
  right at the record's own open finding — but re-executing the observed
  role's code is prohibited for this role. These enter as *record-vs-diff
  reading* only.

## Gap line

Met already: class-level (not string-level) framing, a named negative-space
case, an explicitly recorded residual. Missing / unverified from reading
alone: red-before-green proof for the 5 hunt cases (U1), and the
refactor-vs-behavior separation for the `TRANSPARENT` move (U2). Those two
gaps are where this observation aims.

Sources:
- https://blog.trailofbits.com/2025/10/22/prompt-injection-to-rce-in-ai-agents/
- https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Command%20Injection/README.md
- https://cheatsheetseries.owasp.org/cheatsheets/OS_Command_Injection_Defense_Cheat_Sheet.html
- https://deviq.com/practices/red-green-refactor/
- https://circleci.com/blog/what-is-mutation-testing/
- https://www.codewithjason.com/dont-mix-refactorings-behavior-changes/
- https://gist.github.com/jnsahaj/22806282b18a5c5136e0805d892dee39
