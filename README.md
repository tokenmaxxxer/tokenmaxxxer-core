# tokenmaxxxer-core

Machinery every tokenmaxxxer role enables alongside its own rulebook.

Every agent session installs two plugin categories: its role's own rulebook
marketplace, and this one. The rulebook tells the role **what its job is**;
core tells it **how to interact with the user and where its output goes**.
The user's side of the deal is symmetric and small: file requirements as
issues, consume output as PRs.

## The interaction protocol (contract v3)

    issue   = user -> system    the requirement backlog; user-authored only
    PR      = system -> user    every role output, code and documents alike
    approve = go ahead          comment = feedback     close = refusal
    merge   = acceptance of the delivered work

Every PR runs in two phases. Phase 1: the role commits its research, its
current-state survey (`docs/issue-<n>/reports/<role>/`) and its proposal
(`docs/issue-<n>/proposals/`), opens the PR, and stops. Phase 2 — the
actual work, code included — opens only when a **human approver listed in
`docs/specs/approvers.md`** submits a PR review Approve. A bot's or an
agent's Approve never opens it: who counts as the human is an allowlist,
which is also what makes "no role approves its own PR" mechanical.

- A role wakes on an issue, works on branch `issue-<n>/<role>` (one branch
  per issue × role), and returns everything as a PR against `main`. No
  role pushes to `main`, files an issue, or merges anything.
- `subject` IS the issue: `issue-<n>`. `docs/issue-<n>/` is the subject's
  whole document tree.
- Output layout: code under `src/`, tests under `test/`, documents under
  `docs/` (`README.md` excepted). Under `docs/`: only the six standing
  buckets (`_assets`, `decisions`, `handbooks`, `proposals`, `reports`,
  `specs`) plus `docs/issue-<n>/` trees holding those same six buckets.
  A role's record lives at `docs/issue-<n>/reports/<role>.md`.
- The board is what is merged to `main`. An open PR is not on the board.
- **One account, by default.** Everything — the orchestrator's
  conversational session AND the spawned role sessions — runs on the
  user's own GitHub account. Identity separation is the session layer's
  job: `gh-guard.sh` refuses role sessions the human's acts (review
  verdicts, merge/close, issue authorship, APPROVE-shaped comments, their
  raw-API spellings, pushes to main), whatever the token could do.
  Because GitHub forbids approving your own PR, the single-account
  approval signal is a PR comment that is EXACTLY `APPROVE
  issue-<n>/<role>`, posted by an approvers.md login — the orchestrator
  posts it after the human says so in conversation; string equality,
  never prose interpretation. Merging your own PR is allowed by GitHub,
  so merge relays unchanged.
- **Hardening options (optional).** A separate agent identity — a machine
  account with a PAT, or a GitHub App (`<app>[bot]`) — moves the split
  from the session layer to the account layer: agent-authored PRs can
  then receive a real review Approve, and self-approval becomes
  impossible at the platform, not just the hook. Recommended where policy
  allows; the protocol works identically either way since approval-gate
  accepts both signals.
- **Precondition: the target is a git repository with a GitHub remote, and
  `gh` is authenticated.** Issues, PRs, and reviews are GitHub objects, and
  approval's forgery resistance comes from being a GitHub-authenticated
  act — no local substitute exists by design. `directive.sh` probes this
  at session start and tells the role what to have the human fix
  (`gh repo create … --private --source . --push`, `gh auth login`);
  the gates refuse board and execution writes until it is met.

## What is here

    hooks/directive.sh     SessionStart — tells the role session the protocol
    hooks/board-gate.sh    PreToolUse — deny-only: layout, board opt-in,
                           role, branch, ownership
    hooks/approval-gate.sh PreToolUse — deny-only: src//test/ writes wait
                           for the allowlisted human's PR review Approve
    hooks/gh-guard.sh      PreToolUse — deny-only: role sessions never
                           approve, merge, close, author issues, or push
                           main (two-account model)
    contract/              the canonical role-handoff contract (v3)
    hooks/tests/           run-all.sh runs everything

`directive.sh` is the informing half; `board-gate.sh` is the enforcing
half. They describe the same five rules:

- **R1 layout** — a `docs/` write lands at `docs/README.md`, in a standing
  bucket, or in `docs/issue-<n>/<bucket>/`. Nothing else exists.
- **R2 board opt-in** — a board write requires the repo's
  `docs/specs/approvers.md`: the user-authored file that both declares
  "this repository is a board" and lists the human approvers. The
  canonical contract lives ONLY in this plugin — per-repo copies are
  gone; they carried zero information (the old hash check forced them
  identical) and made every contract revision an N-repo re-sync.
- **R3 role** — a write under `docs/issue-<n>/` requires `CLAUDE_ROLE`.
  The orchestrator's own session has no business writing the board.
- **R4 branch** — writing `docs/issue-<n>/...` requires being on branch
  `issue-<n>/<role>`, exactly. Board writes from `main` are refused: output
  reaches `main` only through a PR the human merges.
- **R5 ownership** — within `docs/issue-<n>/reports/`, a role writes only
  `<role>.md`, `<role>/**`, and its contract-granted extra subtree
  (feasibility: `spikes/**`, ops: `postmortems/**`).
- **R6 phase** (approval-gate.sh) — a role session's write to the
  execution surface is refused while its `issue-<n>/<role>` PR lacks an
  Approve review from a listed human — including while no PR exists, which
  is what enforces proposal-first. The execution surface is `src/`,
  `test/`, and the whole issue tree except the two phase-1 homes
  (`proposals/**` and the role's research subtree `reports/<role>/**`) —
  so a document-producing role's record waits for the Approve exactly as
  code does. The check asks GitHub live (`gh pr view --json reviews`) and
  caches nothing: a cache file would be writable by the model's own tools,
  i.e. a forgeable approval. gh failing = deny.

## Why there is no token machinery

Earlier versions minted single-use approval tokens from an exact
`APPROVE <kind> <subject>` line in the human's turn, because three designs
that read approval out of prose all leaked — deciding what a sentence
*means* is a language problem, and a regex is the wrong tool for it.

The issue/PR model keeps the property and drops the machinery: a PR merge
is a GitHub-authenticated mechanical act by the human, recorded in
history. Nothing reads prose; nothing mints; there is nothing on disk to
forge. The forgery surface moves to "a role writing the board outside its
own branch/record", and that is exactly what R4/R5 deny. Unattended runs
do not get a substitute approver: the PR waits for the human.

## Rules

- Gates refuse; they never permit. No `permissionDecision: "allow"`.
- Fail closed. Unreadable input, unresolvable path or branch: refuse.
  Every gate traps non-0/2 exits to 2 — Claude Code treats any other
  non-zero exit as non-blocking.
- bash 3.2 is the target. Never nest a quoted heredoc inside `$( … )`.

## Install

    claude plugin marketplace add tokenmaxxxer/tokenmaxxxer-core
    claude plugin install core@tokenmaxxxer-core
    claude plugin install terse@tokenmaxxxer-core
    claude plugin install freelunch@tokenmaxxxer-core
    claude plugin install scout@tokenmaxxxer-core

on-the-record enables them per role; nothing else needs to. This marketplace
ships four plugins: `core` (the interaction protocol — its gates are not
meant to be turned off) and three role-agnostic session plugins promoted
from coding-agent-rulebook, each with its own kill switch:
[`terse`](terse/) (output-token compression, `TERSE_OFF=1` or
`/terse off`), [`freelunch`](freelunch/) (width-conditional parallel
execution, `FREELUNCH_OFF=1`), and [`scout`](scout/) (the phase-1
research protocol, `SCOUT_OFF=1`).

`plugin.json` carries **no `version` field**, deliberately. For a
git-distributed plugin the commit SHA is the version, so `claude plugin
update` sees every commit as an update.

## Run the checks

    /bin/bash core/hooks/tests/run-all.sh
