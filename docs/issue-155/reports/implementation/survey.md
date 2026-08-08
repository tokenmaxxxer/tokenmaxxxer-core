# Current-state survey — issue-155

## Write surface

Single write surface: `core/contract/role-handoff-contract.md`, section
19 ("Pre-work approval gate: propose first, execute after Approve").

## F1 — phase-1 write-set branch-writability check

- `core/contract/role-handoff-contract.md:672-829` (section 19) states the
  phase-1 proposal step ("Phase 1 — propose", `:677-693`) and the phase-2
  execute step (`:786-790`) but names no requirement to check, before
  freezing a `files:` path, whether the role's own branch can write it.
- `core/hooks/board-gate.sh:24-28` (R4) denies any `docs/issue-<n>/...`
  write unless the current branch is exactly `issue-<n>/<CLAUDE_ROLE>` —
  unconditional, no override. R4's implementation is at
  `core/hooks/board-gate.sh:494-510`.
- `docs/issue-132/reports/execution-observation.md:343-372` (Finding 1)
  records the live occurrence: issue-132's phase-1 proposal froze a
  `docs/issue-124/...` path from branch `issue-132/implementation`; R4
  denied the write at execution time (`d9b4023`, `10:15:19Z`); the
  requirement (F2 of issue-132) went undelivered and is still open on
  `main` as of this survey.
- `docs/issue-100/reports/implementation.md:90-115` records the same
  class of block one round earlier: issue-100's proposal froze edits to
  `docs/issue-90/...` and `docs/issue-94/...` from branch
  `issue-100/implementation`; R4 denied both, unrecoverable from that
  branch. That record's own `## Next steps` flagged the pattern but
  section 19 was never amended, so issue-132 repeated it — the
  observation's own root-cause line
  (`docs/issue-132/reports/execution-observation.md:356-364`) states both
  routes (R4's own prose, and issue-100's record) were plain reads
  available before issue-132's proposal was frozen.
- Section 11 (`core/contract/role-handoff-contract.md:401-460`) already
  states path-ownership as a *table*, not a per-freeze branch check —
  it does not cover "can this branch write this path at all", which is
  what R4 gates. Section 19's proposal step is the right location for a
  branch-writability check because it runs before any write is attempted
  (the failure issue-132 hit was discovered only at write time).
- No existing prose in section 19, 11, or R4's own comment block requires
  a phase-1 survey to test cross-issue paths against R4 before freezing
  them. Unknown: whether any other section of the contract states this
  implicitly — searched sections 1-22 via `grep -n "R4\|branch-writ"
  core/contract/role-handoff-contract.md`; no other hit.

## F2 — phase-2 delivery PR description refresh

- `docs/issue-132/reports/execution-observation.md:374-406` (Finding 2)
  records PR #135 merging with a `propose(...)` title and a "no code,
  handbook, or record content changed" body while carrying phase-2 code,
  handbook, and record changes (commit `d9b4023`) — the description was
  never refreshed after the phase-1-only body was written.
- Same record (`:387-400`) contrasts PR #129, which rewrote its body at
  delivery to state "Phase 2 delivery for #128, approved via issue-level
  comment `APPROVE issue-128/implementation`" (title left as
  `propose(...)`), against PR #126, which merged with an unrevised
  phase-1 body over a branch whose second commit was a `deliver(...)`
  commit — the same failure shape as #135.
- Section 19's phase-2 execute paragraph
  (`core/contract/role-handoff-contract.md:786-790`) states what phase 2
  *does* (code, record, same branch, same PR) but not what the PR's
  title/body must say once phase 2 lands.
- Issue text (`gh issue view 155`) notes the `#441`-series Closes-trailer
  norm already forces a body edit on the *final* step's phase-2 PR
  (because the body must carry `Closes #n`), so this requirement's live
  gap is narrower than F2's raw statement: the PR *title*, and any
  *non-final-step* phase-2 delivery (a delivery PR that is not the last
  step in the issue's `## 실행 계획`, which carries no `Closes` trailer and
  so is never mechanically forced to touch its body), are what remain
  unnormed. `grep -n "Closes\|closes" core/contract/role-handoff-contract.md`
  found no existing hit for a Closes-trailer rule inside this contract
  file itself — it lives in the `#441`-series gate/hook work outside this
  file's text, referenced but not duplicated here.
- No existing prose anywhere in section 19 mentions PR title or body
  content at merge time at all — confirmed via
  `grep -n "title\|body" core/contract/role-handoff-contract.md`, no hit
  in section 19's range (`:672-839`).

## Constraint check — landed gates and open tracks

- `#441`-series gates (acceptance/pr_reference/contract-guard) — searched
  `core/hooks/` for `pr_reference`, `acceptance`: no hook file by that
  name exists yet in this tree (`find core/hooks -iname '*acceptance*'
  -o -iname '*pr_reference*'` → empty), so nothing here to collide with
  mechanically; the issue's own constraint says avoid conflict, and
  since this proposal's default (below) is prose-only, no gate script is
  touched.
- `#146` track ("산문↔게이트 전수", prose-vs-gate audit) — no open PR found
  under that number in this repo's visible branch list
  (`git branch -a`); nothing to check against directly. Unknown: exact
  scope of #146's open PR; not resolvable from this branch without
  network access to GitHub beyond `gh issue/pr view`, which was not
  queried for #146 specifically. Flagged as unknown rather than assumed
  clear.

## Mechanization cost (Acceptance criterion 3)

- F1: a mechanized check would mean simulating R4 (branch vs. frozen
  path) at proposal-commit time — i.e., for every `files:` entry under
  `docs/issue-<m>/`, assert `m == n` or deny. This is a small, well-scoped
  check (R4's own logic is ~15 lines,
  `core/hooks/board-gate.sh:494-510`) and could live in a new
  `proposal-shape`-style gate. Not built in this proposal (see
  Rationale) — recorded here as the concrete shape the next proposal
  would take if the human wants it mechanized instead of prose-only.
- F2: mechanizing "PR title/body was refreshed at phase-2 delivery"
  requires a live GitHub API read (PR title/body) at commit or push
  time, which none of this repo's existing hooks do (they are all
  local-file gates, confirmed by reading `core/hooks/*.sh` filenames and
  their header comments) — meaningfully higher cost and a new capability
  class (network-calling hook) for this repo's hook layer.

## Unknowns

- Exact open-PR content of the `#146` track — not queried.
- Whether the human wants F1 mechanized despite this being only the
  2nd occurrence (issue text notes "산문→뚫림 2회→기계화 관행 기준으로는
  요건 충족 상태" as context, not as a binding instruction to this
  proposal).
