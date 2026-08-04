# freelunch observe.sh enforcement test harness

`freelunch/hooks/tests/run-observe-tests.sh` exercises
`freelunch/hooks/observe.sh` as a real subprocess against synthetic
`PreToolUse` `Agent`-dispatch payloads (`run` helper; `want allow|deny`
checks stdout for a `permissionDecision: deny` JSON block). Wired into
`core/hooks/tests/run-all.sh` (the "freelunch observe.sh enforcement"
entry, alongside `freelunch`'s own `parse-check.sh`).

Run it directly, no setup required:

    bash freelunch/hooks/tests/run-observe-tests.sh

What it pins (issue-116): under `FREELUNCH_ENFORCE=1`, `observe.sh`'s
`sync_agent_dispatch` check (an `Agent`/`Task` call with
`run_in_background: false`) denies only when `CLAUDE_CODE_ENTRYPOINT`
clearly marks the session interactive (`cli`); the confirmed headless
value (`sdk-cli`), an unset value, or any other value all fail toward NOT
denying — a headless/single-shot session obeying contract v3 s22 must be
able to make that one call shape without being mechanically blocked. The
violation is still logged either way (full audit trail, including a
`session_entrypoint` field), and `non_sonnet_worker` is untouched: it
denies in every session type. Without this test, a future edit to
`observe.sh`'s enforcement logic could silently reintroduce the
contradiction contract v3 s22 exists to close (`docs/issue-106/reports/execution-observation.md`
Finding 1), with nothing to catch it before it reaches a headless role
session running with `FREELUNCH_ENFORCE=1`.

Defaults without this test present: none change — the test only pins
existing, already-shipped `observe.sh` behavior; it introduces no new
environment variable, config key, or default of its own.
