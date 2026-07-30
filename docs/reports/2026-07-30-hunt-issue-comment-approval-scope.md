---
proposal: docs/issue-53/proposals/issue-comment-approval-scope.md
---

# Hunt record — issue-comment-approval-scope

## after-proposal — stance 1: does the proposed gate design have an edge case that silently fails open/closed, and does the scope model's revocation coverage actually hold against the mechanism it's paired with?

Verdict: FINDING — the proposal's own "Revocation" text promises that closing the issue ends single-account authorization "unconditionally and independently of the comment," but the gate mechanism it specifies in the same document (item 3: `gh issue view <issue-num> --json comments`) requests only the `comments` field and never the issue's open/closed state, so the described implementation has no way to observe issue closure and the guarantee cannot mechanically hold.
Kind: design-error
Seed: docs/issue-53/proposals/issue-comment-approval-scope.md, item 3 ("core/hooks/approval-gate.sh") vs. item 2's "Revocation" paragraph in the same file; core/hooks/approval-gate.sh (current PR-only lookup, for comparison); core/hooks/board-gate.sh (no GitHub-state check either).

### Reproduce (trace against the described design; gate code does not exist yet)

1. Role `coding` posts `APPROVE issue-53/coding` on issue #53 (an
   `approvers.md` account, exact string). Per the proposal, this is now
   the canonical, branch-wide, revocable-only-by-delete/edit/close
   signal.
2. The human later closes issue #53 (refusal / subject retired), per
   section 8/9's "a closed issue's board is no longer live for any
   role" — exactly the event the proposal's Revocation clause cites as
   ending authorization "unconditionally and independently of the
   comment."
3. The `APPROVE issue-53/coding` comment is untouched (not deleted, not
   edited) — it is still present in the issue's comment list; GitHub
   does not remove or hide comments when an issue is closed.
4. A `coding` role session later runs again on branch `issue-53/coding`
   (e.g., a stray worktree, a re-invocation, or simply the orchestrator
   failing to check board state before invoking — the exact failure
   mode section 8 relies on the gate, not the orchestrator, to catch)
   and attempts an execution-surface write. The gate (per item 3) does:
   - derive issue number `53` from the branch regex,
   - run `gh issue view 53 --json comments` (verified above: this call,
     as specified, requests only `comments` — no `state`/`closed`
     field is in the requested JSON at all, confirmed against `gh
     issue view --help` and a live `--json comments` call, which
     returns only comment objects, no issue-state key),
   - scan `comments` for the exact-string match, find it, and set
     `approved = True`.
   - Nothing in the described logic ever calls `gh issue view ... --json
     state` or checks `state == "CLOSED"`, so there is no code path in
     the proposal's own design that can produce a deny here.
5. Grepping the two other hooks that exist today for any live
   open/closed check confirms this isn't covered elsewhere:
   `grep -n "issue view\|CLOSED\|state" core/hooks/*.sh` finds no
   issue-state lookup anywhere in `board-gate.sh`, `gh-guard.sh`, or the
   current `approval-gate.sh` — the only existing `gh issue view` call
   in the whole hooks tree is a `gh-guard` allow-list test fixture
   (`core/hooks/tests/run-gh-guard-tests.sh:29`), unrelated to state
   checking.

### Observed (per the proposal's own described mechanism)

`approved` evaluates `True` and the gate allows the write, even though
the issue is closed — contradicting the proposal's own sentence two
paragraphs earlier in the same file: "Closing the issue ends it
unconditionally and independently of the comment... no phase-2 work of
any kind proceeds on it regardless of any standing comment."

This gap is not caught by the proposal's own "How success will be
judged" checklist or item 4's new test list either: the enumerated new
cases (`issue-comment-approved-no-pr`, `pr-review-approved-no-issue-
comment`, `issue-comment-agent`, `issue-comment-prose`, `neither-
surface`) contain no closed-issue case, so a phase-2 implementation
following the proposal's test list to the letter would ship this hole
with green tests.

### Expected

Either (a) the gate design in item 3 should request and check the
issue's state (`gh issue view <n> --json comments,state`, deny/treat-
as-absent when `state == "CLOSED"`), with a corresponding test case
(e.g. `issue-closed-with-valid-comment` -> deny) added to item 4's
list, or (b) the Revocation paragraph should not claim a mechanical,
gate-enforced guarantee it doesn't implement and should instead be
scoped to what actually holds (a social/orchestrator-level convention,
not something `approval-gate.sh` itself checks) — as written, the
prose and the mechanism it describes disagree.
