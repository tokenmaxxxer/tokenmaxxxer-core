---
kind: scout-brief
subject: issue-116
produced_by: execution-observation
loop_state: scouted
---

# Scout brief — what a strong audit of this change-class checks

Deliverable kind scouted: an **independent execution observation of a
fail-open carve-out on a policy-enforcement hook, keyed on an
environment-variable trust signal, plus its test harness**. Aimed at
survey.md's U1 (is the signal conversation-writable) and U2 (are the nine
tests effective). Segment fit: same class — a guard control that decides
deny-vs-allow from inherited process state, audited from artifacts.

**Mode and stages:** parallel fan-out, 4 concurrent subagents in one
turn (not batched-sequential). **1 stage total** — sweep only; JUDGE
POINT 2 hit saturation immediately because angles A and B converged on
the same single decisive fact, and no further round would change what
phase 2 checks.

## Category must-bes (table stakes for accepting this design)

- Trace who can set/override the trust variable across the **full
  process ancestry**, against actual invocation paths — "the platform
  sets it" is a claim to verify, not to assume.
  https://github.com/HKUDS/Vibe-Trading/issues/332
- Deny-by-default; a fail-open path is an explicit, justified exception,
  not the baseline. https://owasp.org/www-community/Fail_securely
- Every non-enforced (fail-open) event is logged with enough context to
  reconstruct what was not checked and why.
  https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- No tautological assertions: a test whose assertion reads back state the
  same test just set cannot fail.
  https://blog.ploeh.dk/2019/10/14/tautological-assertion/
- Deny-path and negative-path cases present, not allow-path only.
  https://blog.ploeh.dk/2019/10/14/tautological-assertion/

## Performance axes (what strong instances compete on)

1. **Signal trustworthiness** — value validation and ancestry analysis,
   not presence-only checks (`CI=1`-class bypasses).
   https://aembit.io/blog/ci-cd-security-checklist-eliminate-secrets-workload-identity/
2. **Would-it-fail-if-wrong** — mutation-style kill power on the guard's
   own decision predicate; coverage % is not adequacy.
   https://blog.trailofbits.com/2026/07/08/mutation-testing-comes-to-daml/ ,
   https://testsigma.com/blog/mutation-testing/
3. **Blast-radius scoping of the exception** — an ambiguous signal in one
   component must not propagate permissive access.
   https://cwe.mitre.org/data/definitions/636.html

## Adopt / skip

- **Adopt:** equivalence-class partitioning of the decision predicate
  (`entrypoint == "cli"` partitions into cli / known-non-cli / unknown /
  unset) as the frame for judging U2's nine cases.
  https://en.wikipedia.org/wiki/Equivalence_partitioning
- **Skip:** running mutation tooling against the hook. This role is
  barred from re-executing the observed code; mutation criteria are
  applied as a **reading** standard against the landed test file, never
  as an executed pass.

## Gap line

Met by the landed artifact on its face: fail-open event still logged
(the `session_entrypoint` field and retained `violations` entry), and the
exception's scope is narrowed to one violation kind. **Not met on its
face — the ancestry/who-can-set check:** `CLAUDE_CODE_ENTRYPOINT` is not
on the official env-vars page (absence checked:
https://code.claude.com/docs/en/env-vars ), its value set is documented
only in an unofficial community gist
(https://gist.github.com/unkn0wncode/f87295d055dd0f0e8082358a0b5cc467 ),
while the settings documentation states an `env` key supplies
"environment variables applied to every session and to subprocesses
Claude Code spawns from it", with settings files hot-reloaded mid-session
(https://code.claude.com/docs/en/settings ). That is the exact channel
class must-be 1 requires be enumerated before a non-spoofability claim is
accepted. Whether that channel is reachable from a role session in this
repo — and whether other channels (`--settings`, `.env`, plugin/MCP env)
exist — is unresolved here and is named as phase-2 evidence in the
proposal, not judged in phase 1.

Sources: all URLs inline above.
