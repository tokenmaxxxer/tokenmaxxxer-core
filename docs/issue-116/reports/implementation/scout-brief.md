---
kind: scout-brief
subject: issue-116
produced_by: implementation
---

# Scout brief — issue-116

Mode: 2 parallel WebSearch angles in one turn (by-symptom: non-interactive/
headless CLI mode detection patterns; by-symptom: approval-gate
near-miss/exact-match handling in CI/CD), one round. Judged saturated
after round 1 — this issue is primarily an internal-consistency repair
(the fix pattern to reuse for requirement 2 already exists inside this
repo, at `freelunch/hooks/freelunch.sh:39`; see survey.md), so the field
check exists only to validate the two genuinely open sub-decisions
(requirement 1's headless-detection mechanism, requirement 3's near-miss
handling shape) against category norms, not to source the overall
design from outside. No deepening round run.

Must-bes the field converges on:
- Non-interactive-mode detection is standard practice via environment
  variables and/or `isatty()`/tty-presence checks, not a bespoke
  mechanism — e.g. `sys.stdin.isatty()` gating interactive vs. piped
  behavior, and CLI tools shipping an explicit non-interactive flag/env
  var (`MCPM_NON_INTERACTIVE`, `is_non_interactive()`/
  `should_force_operation()` utilities) alongside tty checks. This
  supports the *mechanism* survey.md proposes (read the hook's own
  inherited environment/tty state) as an ordinary pattern, not a novel
  one.
- Approval/status-check systems that rely on exact-string matching
  treat a near-miss as a distinct, visible failure mode to guard
  against, not a silent pass-through — GitHub's own branch-protection
  status checks are exact-string and a well-documented failure class is
  the *mismatch going unnoticed* (job-name vs. workflow-name drift on
  reusable workflows); the field's fix is to make the mismatch
  explicit/named rather than let it silently fail one way or the other.

Performance axis: fail-safe direction under uncertainty. For headless
detection, the field does not converge on "assume interactive when
unsure" or "assume headless when unsure" universally — it converges on
making the signal explicit and erring toward not breaking the caller's
correct-but-unusual invocation. Applied here: when observe.sh's
headless signal is absent or ambiguous, the fix should fail toward NOT
denying (favors §22 compliance, matches requirement 1's explicit
floor: "최소한 헤드리스 맥락에서 동기 위임을 거부하지 않을 것") rather than
toward denying by default.

Adopt: (1) headless carve-out keyed on environment/tty signals already
inherited by the `PreToolUse` subprocess, fail-open toward not-denying
when the signal can't be read confidently; (2) treat a near-miss
approval comment as a distinct, explicitly-surfaced event (role session
states it plainly, once) rather than silent fallthrough into "just
feedback."
Skip: inventing a new dedicated env var or config flag for headless
detection — the field's own pattern is to read signals the process
already has, and this hook already runs inside the session's own
environment (confirmed in survey.md), so no new plumbing is needed.

Gap line: this repo already has the *conflict-resolution* pattern
(subordination note, `freelunch.sh:39`) and the *fail-toward-safety*
framing (contract §22's own "if a same-turn wait is not possible... do
not delegate that unit at all") as established internal must-bes; what
it is missing is (a) applying either to the mechanically-enforcing
surface (`observe.sh`) rather than only the prose-instructing surfaces,
and (b) any stated behavior for a role session that itself observes a
near-miss comment (current text only states what a near-miss does NOT
authorize, not what the session should DO about noticing one). Both
gaps are internal-consistency gaps, not missing category knowledge —
the field check above only confirms the chosen mechanisms are
ordinary practice, not exotic.

Sources:
- https://www.mindstick.com/forum/161329/how-does-sys-stdin-isatty-help-in-detecting-interactive-mode
- https://github.com/ruvnet/ruflo/wiki/Non-Interactive-Mode
- https://www.aikido.dev/blog/checklist-github-actions
- https://devactivity.com/insights/streamlining-github-actions-resolving-required-status-check-mismatches-for-enhanced-productivity/
