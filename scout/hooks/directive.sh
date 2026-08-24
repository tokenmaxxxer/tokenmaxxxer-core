#!/usr/bin/env bash
# UserPromptSubmit hook: injects the pre-build reconnaissance directive.
#
# Methodology lineage (v0.1.0, 2026-07-19): the protocol is a compression of
# three established research methods into a generation-time steering rule —
#  - Competitive benchmarking (Camp 1989, Xerox): compare against BEST-in-class,
#    convert the observed gap into build targets. Not "who else exists" but
#    "who sets the bar".
#  - Kano model (Kano 1984): customer expectations come in tiers — must-be
#    (assumed; absence ruins the product), performance (the competitive axis),
#    attractive/delighters (which drift into must-bes over time). The baseline
#    to extract is the category's current must-be set.
#  - Theoretical sampling + saturation (grounded-theory lineage): each next
#    lookup is chosen by judgment on what was just learned, and collection
#    stops when new sources stop changing decisions. This is what makes scout
#    directional instead of deep-research fan-out.
# Kill switch: export SCOUT_OFF=1

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "directive.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${SCOUT_OFF:-}" || { trap - EXIT; exit 0; }

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
cat <<EOF
[scout-directive] scout before proposing; a skip (pure bugfix, or no open design decision) is recorded in the survey. Survey first; parallel sweep; 5 stages / 3 min cap. scout-brief.md with Sources is mandatory when scouting ran. Read ${ROOT}/directive/scout-protocol.md before proposal-round research.
EOF
exit 0
