#!/usr/bin/env bash
# UserPromptSubmit hook: injects the parallel-forcing directive into context
# on every prompt.
#
# Width-conditional policy: freeze the task's shared contract, count
# independently-producible units, then lean solo (one delegated background
# worker, or inline only when no repo tool call is needed) below threshold
# and lean fan-out of background Sonnet workers at width >= 2 with ~100+
# expected lines per unit. No verification passes, ever — in this stack the
# review/verify roles and the human's PR review are the verification layer.
#
# The rules were tuned and ablation-tested on coding-task benchmarks in
# coding-agent-rulebook (measurement records live there); promoted to the
# core marketplace 2026-07-28 as role-agnostic policy, unmeasured on the
# other roles. A rule that loses a future ablation comes out.
#
# To disable: export FREELUNCH_OFF=1

# Off means off: `X_OFF=0` and `X_OFF=false` read as "not off" to a user and to
# most tooling, but any non-empty value used to disable the hook — the kill switch
# silently killed it on exactly the spelling meant to keep it alive.
# Normalize (lowercase, trim whitespace) before matching so common spelling
# variants (`False`, `OFF`, trailing/leading whitespace) resolve the same as
# their canonical form. An unrecognized value is never silently treated as
# "off": it warns on stderr and falls through to printing the directive —
# fail-open to the directive, never silent suppression.
_freelunch_off_raw="${FREELUNCH_OFF:-}"
_freelunch_off_norm="$(printf '%s' "$_freelunch_off_raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
case "$_freelunch_off_norm" in
  ""|0|false|no|off) ;;
  1|true|yes|on) exit 0 ;;
  *) echo "freelunch: unrecognized FREELUNCH_OFF value '${_freelunch_off_raw}' — treating as not-off, directive will print" >&2 ;;
esac

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
cat <<EOF
[freelunch-directive absolute] write the STEP 1 tally paragraph (contract, unit count, lines each) before any other action. Width >= 2 and ~100+ lines each: fan-out; else solo. Any repo/env tool call: DELEGATE to background freelunch:freelunch-worker (Sonnet-pinned), never inline. No verification passes. Headless: consume delegated results in the same turn (contract v3 s22 outranks). Read ${ROOT}/directive/freelunch-protocol.md before the tally and any dispatch.
EOF
exit 0
