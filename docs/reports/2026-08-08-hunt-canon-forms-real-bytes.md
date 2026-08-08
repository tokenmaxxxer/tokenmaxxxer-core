
## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — the proposed structural rule (a line that only sources gate-lib.sh, or only calls one gate_* function, is sanctioned) is matched per-line with no cap on repetition, so a directive.sh can chain arbitrarily many distinct gate_* calls after the stub header and still classify as a sanctioned stub, not a vendored/injected copy.
Kind: design-error
Seed: docs/issue-177/proposals/2026-08-08-canon-forms-real-bytes.md (planned canon-forms.txt patterns for "sources gate-lib.sh" / "calls one gate_* function", not yet written)
cap_seconds: 120
tier: default
diff_stat_lines: 0 (phase-1 proposal, no code diff yet; proposal doc is ~90 lines)
started_at: 2026-08-08T00:00:00Z
ended_at: 2026-08-08T00:02:00Z

### Reproduce
Built a scratch copy of the real `core/hooks/lib/gate-lib.sh` and `core/hooks/tests/canon-forms.txt`, appended the two patterns literally implied by the proposal's wording ("sources gate-lib.sh with optional `|| { ...; exit N; }` fallback" and "calls one exported gate_* function with optional `|| exit N` fallback"):

```
gate-source-only:^[[:space:]]*\.[[:space:]]+"[^"]*gate-lib\.sh"([[:space:]]*\|\|[[:space:]]*\{[^}]*\})?[[:space:]]*$
gate-call-only:^[[:space:]]*gate_[A-Za-z_]+([[:space:]].*)?(\|\|[[:space:]]*exit[[:space:]]+[0-9]+)?[[:space:]]*$
```

Fixture directive.sh (passes the two mandatory checks, then chains five separate gate_* lines):
```
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/role-directive.sh"
core_role_directive "a" "b" "c" "d"
. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh" || { echo x; exit 2; }
gate_kill_switch_active "${FOO_OFF:-}" || exit 0
gate_trap_fail_closed
gate_budget_exceeded "$started" "$cap" "$now"
gate_content_hash_matches_canon "$a" "$b"
gate_is_role_directive_stub "$c"
```
Ran `gate_is_role_directive_stub` (sourced from the scratch gate-lib.sh, forms_manifest resolved relative to it exactly as production does) against this fixture.

### Observed
`gate_is_role_directive_stub` returns `exit=0` (sanctioned stub, no fail reason printed) for a file containing five distinct, functionally unrelated gate_* invocations plus an extra gate-lib.sh source line beyond the stub header — a shape that is materially a custom multi-step program, not "a stub that only sources gate-lib.sh or only calls one gate_* function."

### Expected
The described rule's own prose ("only sources gate-lib.sh", "only calls one ... gate_* function") implies at most one such extra line should be tolerated per file; as statable in per-line regex form with no companion count/uniqueness check in `gate_is_role_directive_stub`'s loop, the rule instead accepts any number of such lines, so a vendored or attacker-modified directive.sh can smuggle arbitrary additional gate_* logic past the "sanctioned stub" classification one line at a time.
