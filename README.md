# tokenmaxxxer-core

Machinery every tokenmaxxxer role enables alongside its own rulebook.

A role knows **which** of its transitions need a human. Core knows **whether**
a human approved. That is the whole boundary.

## What is here

    hooks/mint.sh          UserPromptSubmit — the human's own turn -> a token
    hooks/board-gate.sh    PreToolUse — deny-only: tokens, contract, role
    hooks/lib/consent.py   find / consume, imported by a role's gate
    hooks/lib/judge.py     unattended runs: an independent session decides
    contract/              the canonical role-handoff contract
    hooks/tests/           run-all.sh runs everything

## Why it exists

Nine rulebooks each implemented human approval separately. On 2026-07-27 a
full-history review of all ten repositories found seven exploitable defects;
four were in this one concept, implemented three different ways:

- a negated verdict minted the affirmative one, and the refusal was recorded
  in the token as its own evidence
- the *name* of the target state read as an approval, so quoting the contract
  minted a token
- an approval naming subject A minted a token for subject B
- one repository consumed tokens it had no code to mint, so the only actor who
  could satisfy the gate was the model itself

One implementation, one test suite.

## The challenge line

A token is minted when the user's **whole turn**, stripped, is exactly:

    APPROVE <kind> <subject>

and never otherwise. Not a sentence containing it, not a paraphrase, not an
approval written in prose.

Three earlier designs read approval out of natural language and all three
leaked — quoted contract text, reported speech, conditionals, past tense,
negation-then-affirmation, and seven Korean refusals all minted. Deciding what
a sentence *means* is a language problem and a regex is the wrong tool for it.
Deciding whether two strings are *equal* is not a language problem.

The split: the model asks the human clearly and prints the exact line to send
— that half **is** a language problem, and the model is good at it. This hook
only checks equality. It stays a hook rather than becoming the model's own
judgment because the model is the thing being gated, and an LLM reading
adversarial text to decide authorization is injectable. String equality is not.

## Two modes

| | who approves | actor in the token |
|---|---|---|
| attended | the human types the challenge line in their own session | `user` |
| unattended | an independent judge session, spawned by the orchestrator | `judge` |

`actor:` records which path produced a token, and `consume()` takes an
explicit allow-list: a gate opts into `("user", "judge")` only when its
session is unattended, so a stale judge token can never satisfy an attended
gate. The four contract §8/§19 human-reserved decisions — scope approval,
defect adjudication, metric freeze, round-end — never accept `judge`.

Four properties keep the judge from being self-certification. All are
load-bearing:

1. **The orchestrator spawns it**, between sessions, and builds the prompt
   from its own arguments. The working model never writes the question.
2. **No task context.** A fresh session has no work in flight and no reason to
   want the run to continue.
3. **Mechanical facts** from git ride alongside the prose. An agent can write
   a persuasive record; it cannot make `git diff --stat` say something else.
4. **No tools** (`--tools ""`). It answers from what it is handed.

Verdicts are `APPROVE` / `REFUSE` / `HOLD`, read from a schema-constrained
JSON answer. Anything that is not a clean `APPROVE` mints nothing — `HOLD` is
the correct answer whenever the judge cannot tell, and is not a failure.

Only the human, or the orchestrator on the human's behalf, can set unattended
mode: an agent's `export` inside a Bash call does not reach the hook's
environment, and a repository shipping its own `.claude` config is refused at
spawn.

## Token format

    <tokens_dir>/<kind>.token

      kind:    scope-proposed--scope-approved
      subject: alpha
      actor:   user
      phrase:  APPROVE scope-proposed--scope-approved alpha

`kind` is a transition (`<from>--<to>`) or a field (`field-<name>`).
`tokens_dir` is supplied by the calling gate — qa keeps tokens outside the
repository, every other role keeps them on the board.

Tokens are single-use: `consume()` claims the file by rename before reading
it, and the directory ignores itself in git — a committed token could be
restored by `git checkout` and replayed, which is the standing-approval bug
removal exists to prevent.

## The board gate

`board-gate.sh` is deny-only and enabled for every role:

- **No tool writes tokens.** Any write under `records/*/tokens/` or to any
  `*.token` under `records/` is refused, for every role. A token written by a
  tool is a forged human approval.
- **A record write requires the canonical contract.** The repo's
  `docs/specs/role-handoff-contract.md` must hash-match `contract/` here. The
  contract has no version field, so the hash is the only discriminator — and
  six repos were measured 188 lines apart while all claiming `status: final`.
- **A record write requires `CLAUDE_ROLE`.** The orchestrator's own session
  carries no rulebook gates and has no business writing the board.

## Rules

- Gates refuse; they never permit. No `permissionDecision: "allow"`.
- Fail closed. Unreadable input, unresolvable path, failed removal: refuse.
  Every gate traps non-0/2 exits to 2 — Claude Code treats any other non-zero
  exit as non-blocking.
- bash 3.2 is the target. Never nest a quoted heredoc inside `$( … )`.

## Install

    claude plugin marketplace add tokenmaxxxer/tokenmaxxxer-core
    claude plugin install core@tokenmaxxxer-core

muster enables it per role; nothing else needs to.

`plugin.json` carries **no `version` field**, deliberately. For a
git-distributed plugin the commit SHA is the version, so `claude plugin
update` sees every commit as an update. The rulebooks all sat at `0.1.0` and
were reported "already latest" no matter how far the cache had fallen behind.

## Run the checks

    /bin/bash core/hooks/tests/run-all.sh
