
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

## before-landing — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — the new gate-lib-source/gate-call one-line-each cap counts matching *physical lines*, not semantic gate_* invocations, so a directive.sh that semicolon-joins an unbounded chain of `gate_*` calls onto a single physical line is accepted as a sanctioned stub (returns 0) even though it is exactly the "chains multiple gate_* lines" shape the cap was added to reject.
Kind: design-error
Seed: core/hooks/lib/gate-lib.sh (gate_is_role_directive_stub, gate-lib-source/gate-call one-line-each cap), core/hooks/tests/canon-forms.txt (gate-call pattern), core/hooks/tests/run-stub-canon-forms-tests.sh
cap_seconds: 120
tier: default
diff_stat_lines: gate-lib.sh +26/-4, canon-forms.txt (new gate-lib-source/gate-call entries replacing unregistered-stub/layered-directive), run-stub-canon-forms-tests.sh new fixtures, gate-house-standard.md doc update
started_at: 2026-08-08T20:35:19+09:00
ended_at: 2026-08-08T20:37:14+09:00

### Reproduce
```
cd /home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-177-implementation
cat > /tmp/case-semicolon-chain.sh <<'SCRIPT'
#!/usr/bin/env bash
. "core/hooks/lib/role-directive.sh"
. "core/hooks/lib/gate-lib.sh"
gate_a x; gate_b y; gate_c z; gate_d w; gate_e v
core_role_directive
SCRIPT
bash -c 'cd /home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-177-implementation
source core/hooks/lib/gate-lib.sh
gate_is_role_directive_stub /tmp/case-semicolon-chain.sh
echo exit=$?'
```

### Observed
```
exit=0
```
No fail reason printed, `gate_is_role_directive_stub` treats the file as a sanctioned canon stub. (Sanity check: replacing the single semicolon-joined line with the same 5 `gate_*` calls on 5 separate physical lines is correctly rejected with `exit=1` and "has non-stub line(s), looks like regrown boilerplate: gate_b x" — confirming the cap only counts physical lines, not calls.)

### Expected
A directive.sh chaining more than one `gate_*` call beyond the mandatory single call should be rejected regardless of whether the extra calls are newline- or semicolon-separated; `gate_is_role_directive_stub` should return 1 with a "has non-stub line(s)" (or equivalent) fail reason for this file.
