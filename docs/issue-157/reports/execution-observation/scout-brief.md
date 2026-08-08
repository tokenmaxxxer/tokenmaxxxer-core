---
kind: scout-brief
subject: issue-157
produced_by: execution-observation
phase: 1
---

# Scout brief — issue-157, step 2 (execution-observation)

Pass: **1 stage (sweep only), parallel mode** — four `WebSearch` angles
issued concurrently in one turn, aimed at the survey's four thin surfaces
(acceptance-evidence form, fail-open→false-positive inversion, audit-trail
integrity, doc-vs-code drift), not at the issue's wording. Judge point 1:
angles 1 and 4 overlap on the same operative idea — a claim is audited by
being *individually re-derived against the artifact*, not by being read as
plausible — which is the strongest signal in the sweep. Angle 2 returned
mostly WAF/SAST material of only partial fit (segment mismatch, kept for
one line only). Judge point 2: another round would change no evidence-plan
decision, so the pass stopped at saturation, far inside the 5-stage /
3-minute budget.

## Category must-bes for an audit of "a fix that closes a fail-open gap and ships its own tests"

1. **Revert the fix and see whether the test still passes** — "if a test
   passes with its fix removed, the test is decoration"; the named failure
   modes are asserting the wrong property, a fixture that never reaches the
   code path, and code that does not do what it reads like. All three "look
   correct in the diff," so review alone does not catch them. [1]
2. **Fail-open removal is judged by what it now falsely rejects.** Removing
   a permissive fallback trades false negatives for false positives; the
   audit's question is what the new rejection costs and who absorbs it, and
   the standard framing is that a false negative ships the defect while a
   false positive costs review time. [2]
3. **Self-reported process metadata is audited for sequence continuity and
   timestamp consistency.** Irregular or out-of-order timestamps "hinder
   accurate event reconstruction" and let a reader challenge the record's
   reliability; the review step is explicitly completeness + sequence +
   timestamp consistency. [3]
4. **Documentation landed in the same change is verified claim-by-claim
   against the code in that change** — "highlight every claim with a
   command, endpoint, config key... and verify them one by one"; docs must
   reflect real behavior, not assumptions. [4]

## Performance axes this observation competes on

- **Traceability**: every verdict sentence → primary artifact (40-hex
  commit id, `file:line`, or comment URL).
- **Independence**: landed artifacts only; no re-execution of the observed
  suite, gate, or hunt reproductions.

## Adopt / skip

- **Adopt** must-be 1 as the lens on U2/U6 — for each of the four added
  assertions, ask against which pre-image it would go red, computed from
  the diff and the observed survey's quoted pre-image, never by running
  anything.
- **Adopt** must-be 2 on U1/U3 — read the before-landing hunt's FINDING as
  the false-positive side of the trade and judge the *disposition's
  evidence*, not the design choice itself.
- **Adopt** must-be 3 on U5 — check the hunt record's four audit fields for
  sequence continuity against the issue/PR/commit clock.
- **Adopt** must-be 4 on U7 — verify the handbook paragraph's two concrete
  claims one by one against the same commit's gate hunk.
- **Skip** must-be 1's literal method (actually reverting and re-running):
  the role directive forbids re-executing the observed role's code, so the
  revert is performed *on paper* against the pre-image the observed survey
  itself quotes, and any residue is stated as residual rather than closed.

## Gap line

Current state already meets must-be 4's *form* (a handbook edit shipped in
the same commit, `7cd6392e5fc0d3509bd3228232c2ba0b43b58f4d`) and must-be 2's
*disclosure* (the trade-off is named in the record's `closed_checks`).
**Missing**: must-be 1 — no artifact states, per added assertion, which
pre-image it discriminates against, and the one assertion the issue's
acceptance check names cannot be reverted against this change at all; and
must-be 3 — the hunt record's own timeline fields are unchecked. That pair
is what the phase-2 evidence plan aims at first.

Sources:
1. <https://theaioperator.io/p/every-test-passed-so-i-started-reverting>
2. <https://anchore.com/blog/false-positives-and-false-negatives-in-vulnerability-scanning/>
3. <https://aaronhall.com/audit-trail-inconsistencies-that-undermine-defense/>
4. <https://doc.holiday/blog/review-ai-generated-code-documentation-debt>
