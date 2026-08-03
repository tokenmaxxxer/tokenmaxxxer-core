---
kind: scout-brief
subject: issue-94
produced_by: execution-observation
loop_state: phase-1
---

# Scout brief — what a strong audit of a scoped quote-awareness fix checks

Deliverable kind scouted: **an independent audit of a narrowed security-gate
mitigation**, not a product. Angles were aimed at the survey's U1 (does a
regression case actually fail beforehand), U4/U5 (did the relaxation widen
the hole), U6/U8 (partial fix, residuals, drift). Mode: **parallel** — 3
concurrent subagents, one sweep round, one judge point, then stopped on
saturation (2 of 5 budgeted stages used; a further round would not change
any check below).

## Category must-bes

- A "regression test" claim is only credible if the test is shown failing
  against the unfixed code; the cheap manual form is revert-the-exact-fix
  and rerun — a test that passes with the fix removed is decoration.
  https://theaioperator.io/p/every-test-passed-so-i-started-reverting
- Denylist matching over shell text is CWE-184 *Incomplete Denylist*:
  quoting/encoding variants cannot be enumerated, so the posture, not the
  pattern, is the defect. https://cwe.mitre.org/data/definitions/184.html
- Quote-splicing (`ec"ho"`, `--appro"ve"`) defeats naive keyword matching
  because the shell concatenates across quote boundaries — so a
  blank-the-quoted-span primitive must be tested against spliced tokens,
  not only against wholly-quoted ones.
  https://medium.com/@ucihamadara/command-injection-bypass-cheatsheet-4414e1c22c99
- POSIX 2.2.2/2.2.3: single quotes preserve every character literally;
  double quotes leave `` ` `` and `$(` live. Any dequote step that treats
  both quote kinds alike is, by the standard, discarding live syntax.
  https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- A partial fix has to say what is *not* fixed, with the residual named;
  incomplete patches are a documented recurring failure class, not an edge
  case. https://cheatsheetseries.owasp.org/cheatsheets/Vulnerability_Disclosure_Cheat_Sheet.html
  · https://www.akamai.com/blog/security-research/incomplete-patch-apt28s-zero-day-cve-2026-32202
- A known-gap case needs a reason string *and* strict semantics, so it
  fails loudly if it silently starts passing; otherwise the gap marker
  rots. https://docs.pytest.org/en/stable/how-to/skipping.html
- Scope narrowing is legitimate when documented, evaluated and signed off
  by a named owner; the same narrowing without that is under-delivery.
  https://blog.asa.team/scope-creep-decision-problem-not-people-problem/

## Performance axes strong audits compete on

1. **Dynamic proof vs. static reasoning** — reruns against reverted code
   beat inspection; where reruns are barred, the audit must say so and
   bound its own confidence.
2. **False-negative rate under adversarial quoting** vs. false-positive
   rate on benign quoted text — a relaxation is judged on the first, not
   the second.
3. **Residual visibility** — is the untouched part carried by a live,
   checkable artifact, or only by prose.

## Adopt / skip

- **Adopt:** per-case before/after determination for every one of the 9
  new cases, and adversarial quote-splicing probes (`gh pr review 5
  "--approve"`, `--appro"ve"`) against the three dequoted rules — this is
  the field's own named evasion class, not an invented one.
- **Skip:** standing up mutation-testing tooling, and any AST/bashlex
  rewrite recommendation. Both are out of an observation's remit, and per
  CWE-184 a denylist stays bypassable regardless of parser fidelity.

## Gap line

Already met by the board state: residual named in prose and carried by a
test case (`gap-f-…`, per the record at
`docs/issue-94/reports/implementation.md:80-82`); rationale for the
narrowing written before delivery; single-quote/double-quote distinction
consciously handled on board-gate's side by leaving `SUBSHELL` quote-blind.
Missing against the field's must-bes: (i) no per-case before/after
statement anywhere in the record, (ii) no spliced-quote case among the 9
new ones, (iii) `gap-f`'s own comment says it denies for an unrelated
reason, which is exactly the "strict xfail vs. decorative marker"
distinction, (iv) the approval-gate call site folds `` ` ``/`$(` behind a
dequote, which the POSIX must-be says is live syntax inside double
quotes.

## Method limit found by the sweep

No source endorses pure static determination as a substitute for
executing the pre-change code. This role is barred from re-running the
observed role's code, so phase 2's before/after determinations are
analytic and must be labelled as such, with confidence bounded
accordingly — that limitation is stated in the plan rather than papered
over.

Sources: the URLs inline above, plus
https://docs.python.org/3/library/shlex.html ·
https://cwe.mitre.org/data/definitions/1173.html ·
https://blog.trailofbits.com/2025/09/18/use-mutation-testing-to-find-the-bugs-your-tests-dont-catch/ ·
https://sre.google/workbook/postmortem-culture/
