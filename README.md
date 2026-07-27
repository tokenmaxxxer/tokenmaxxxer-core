# tokenmaxxxer-core

Machinery every tokenmaxxxer role enables alongside its own rulebook.

A role knows **which** of its transitions need a human. Core knows **whether**
a human approved. That is the whole boundary.

## What is here

    hooks/mint.sh          UserPromptSubmit — the user's turn -> a token
    hooks/lib/consent.py   find / consume, imported by a role's gate

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

## Token format

    <tokens_dir>/<kind>.token

      kind:    scope-proposed--scope-approved
      subject: alpha
      actor:   user
      phrase:  <the user's own words that minted it>

`kind` is a transition (`<from>--<to>`) or a field (`field-<name>`).
`tokens_dir` is supplied by the calling gate — qa keeps tokens outside the
repository, every other role keeps them on the board.

## Rules

- Gates refuse; they never permit. No `permissionDecision: "allow"`.
- Fail closed. Unreadable input, unresolvable path, failed removal: refuse.
- bash 3.2 is the target. Never nest a quoted heredoc inside `$( … )`.
