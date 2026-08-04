---
kind: scout-brief
subject: issue-133
produced_by: execution-observation
phase: 1
---

# Scout brief — judging a denylist→allowlist tightening of a mechanical check (issue-133, step 2)

Mode: **parallel** — stage 1 ran 4 concurrent `WebSearch` angles in one turn
(allowlist-conversion review, red-half evidence, rule-tightening against an
existing corpus, Python regex-validator pitfalls), each aimed at a specific
survey unknown (1, 3, 2/6, 1). **2 stages**: judge point 1 found all four
angles on-segment and converging, judge point 2 saturated — another round
would not change a verdict-design decision. Segment fit: the deliverable is
a post-landing judgment on a *tightened* control, which is a different audit
than issue-128's (that one asked whether the rule caught enough; this one
asks what the tightened rule now refuses that it should not).

## Category must-bes (what strong work of this kind assumes)

- **A denylist→allowlist conversion is judged on false *positives*.** The
  denylist's failure mode is the miss; the allowlist's is refusing
  legitimate input — the classic example being a filter that rejects
  `O'Brian`. An allowlist is therefore specified as an exact shape,
  charset *and* length *and* case together (`^[a-zA-Z0-9_]{3,20}$`), so the
  audit reads the shape and asks which legitimate value classes fall
  outside it. [1][2]
- **The red half is demonstrated, not asserted.** The cycle a reviewer
  expects is run → revert the fix → *must fail* → restore → run; the
  failure mode it exists to catch is a test that cannot fail. Where the red
  run is not itself committed, the audit names the evidence tier it rests
  on rather than presenting it as inspected. [3][4]
- **Tightening a rule over an existing corpus is a scoping decision, and an
  explicit one.** The field's standard move is a baseline that grandfathers
  existing violations so only new code is flagged (linthell, Android lint
  baselines, lint-staged pre-commit). The audit checks that the scoping was
  decided rather than inherited, and that surviving violations are counted. [5][6]
- **Regex validators are traced against Python's actual semantics.**
  `re.match` anchors at string start and does not match at each line start
  even under MULTILINE; `$` matches before a trailing newline (`\Z` is the
  absolute end); `.` never matches a newline. A rule audit walks these
  explicitly instead of reading the pattern as prose. [7][8]

## Performance axes the field competes on

1. **False-positive reach** — which legitimate value classes the tightened
   shape now refuses (empty, case variants, abbreviated forms, quoted
   examples). [1][2]
2. **Evidence-tier honesty on the red half** — inspected vs. asserted. [3][4]
3. **Corpus-scoping discipline** — what survives the tightening, counted,
   and whether leaving it standing was a decision. [5][6]

## Adopt / skip

- **Adopt:** boundary-value probing performed *by reading* — construct
  candidate values on paper against the delivered pattern as it appears in
  the `778b810` diff, never by running the observed suite. [1][7]
- **Adopt:** a read-only corpus count of existing values against the new
  shape, as the concrete form of the scoping-discipline axis. [5]
- **Skip:** recommending baseline tooling — the gate sees only the write in
  front of it, so grandfathering is structural here, not a tool choice;
  what remains is whether that structural scoping was stated. [6]
- **Skip:** re-performance as an evidence tier at all (barred for this
  role); substitute an explicit per-claim tier statement. [3]

## Gap line

Already met by the current state: the false-*negative* direction issue-128
left open is closed by the conversion itself, and forward-traceability
inputs exist and are readable (three numbered requirements, the observed
proposal's four-item clause list, the record's item-by-item `## What was
done` and `## Verify`). **Missing:** (a) any false-positive analysis of the
newly-refused value classes — empty value, uppercase hex, 7-character
abbreviated hex (5 existing instances by the observed survey's own tally),
an unresolved spelling quoted as an example inside a proposal or record;
(b) a stated evidence tier for the red half, which exists only as the
observed record's prose about an uncommitted scratch run; (c) a
cognate-habitat sweep for the class *a validator enumerating bad values
instead of good ones* across the sibling gates. Those three are what the
proposal's step-level probes target.

Sources:
- [1] https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- [2] https://github.blog/2022-03-21-validate-all-things-input-validation/
- [3] https://deviq.com/practices/red-green-refactor/
- [4] https://simonwillison.net/guides/agentic-engineering-patterns/red-green-tdd/
- [5] https://pypi.org/project/linthell/
- [6] https://christiankohler.net/one-bite-at-a-time-how-to-introduce-new-lint-rules-in-a-large-codebase/
- [7] https://secjuice.com/python-re-match-bypass-technique/
- [8] https://learnbyexample.github.io/py_regular_expressions/anchors.html
