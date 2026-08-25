---
proposal: docs/issue-304/proposals/2026-08-25-execution-observation-verify-pr307.md
---

# Hunt record — execution-observation-verify-pr307

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: NO FINDING
Seed: docs/issue-304/proposals/2026-08-25-execution-observation-verify-pr307.md (new file, commit e4683b1, PR #308) — probed against core/hooks/survey-order-gate.sh and core/hooks/approval-gate.sh per the dispatched angle (skip-marker text matching, CORE_BUILD_NOW, pinned-commit staleness, "files:" frontmatter trust).
cap_seconds: 60
tier: size:docs
diff_stat_lines: 104 (1 file changed, 104 insertions(+))
started_at: 2026-08-25T13:33:59+09:00
ended_at: 2026-08-25T13:35:46+09:00

### What was probed

1. survey-order-gate.sh's SKIP_MARKERS substring match against the
   proposal's actual Rationale text. Suspected the proposal's phrase "no
   open design decision" would NOT satisfy the gate's literal marker
   `"no design decision"` (word "open" breaks the substring). Checked
   with `grep -io "no design decision" docs/issue-304/proposals/2026-08-25-execution-observation-verify-pr307.md`
   — it DOES match, because a second sentence in the same Rationale
   paragraph ("the spec leaves no design decision open") contains the
   literal substring. So the marker legitimately fires; no false-skip
   here. (Moot regardless: survey-order-gate.sh's `deny()` always
   `exit 0` — issue-282 DEMOTE made it advisory-only, so it was never a
   blocking gate to bypass in the first place; this is stated in the
   file's own comment, not new.)
2. approval-gate.sh's pinned-commit trust: the proposal cites PR #307 at
   commit `e9b4299`. Checked `git ls-remote origin issue-304/implementation`
   and `gh pr view 307 --json headRefOid,state,headRefName` — both report
   `e9b4299b57e41fec5cbe1484a8f754937efd6472`, matching the proposal's
   citation and PR still OPEN. No staleness gap currently exists, and the
   proposal's own Constraints section already states the fallback ("if
   that commit changes materially ... stated explicitly rather than
   silently re-read") rather than assuming a phase-2 session would
   re-derive it silently.
3. approval-gate.sh's `execution_surface()`: confirmed it derives the
   phase-1/phase-2 boundary purely from the path pattern
   (`reports/<role>/` prefix, `proposals/` prefix) and CLAUDE_ROLE/branch
   match — it never reads the proposal's `files:` frontmatter, so listing
   `docs/issue-304/reports/execution-observation.md` in the proposal's
   frontmatter cannot be used to smuggle extra execution-surface access;
   the record file is still correctly classified as execution surface
   (must wait for Approve) regardless of what the proposal's frontmatter
   claims.
4. Incidentally reproduced an over-restriction (not a bypass, so out of
   stance and not filed as the finding): `mkdir -p
   docs/issue-304/reports/execution-observation` on this very session
   (role=execution-observation, branch issue-304/execution-observation,
   no Approve yet) was DENIED by approval-gate.sh, because the bare
   directory token's tail (`reports/execution-observation`, no trailing
   `/`) fails the `tail.startswith("reports/%s/" % role)` check that
   only matches a *file inside* the role's phase-1 subtree. This is a
   false-positive deny (blocks something that should be allowed), the
   opposite direction from this stance's target (something that should
   be denied but isn't), so not reported as this hunt's finding.

No case was found where the proposal's specific text, frontmatter, or
the pinned PR #307 commit citation lets a session obtain phase-2
execution-surface writes for issue-304/execution-observation without a
live Approve signal, nor where survey-order-gate's skip-marker check is
defeated by this proposal's actual wording.

## before-landing — skipped

docs-only, no before-landing dispatch — every path touched by this
transition (`docs/issue-304/proposals/2026-08-25-execution-observation-verify-pr307.md`)
is under `docs/`.
