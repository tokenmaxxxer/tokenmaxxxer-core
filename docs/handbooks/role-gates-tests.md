# role-agnostic gates test harness

`core/hooks/tests/run-role-gates-tests.sh` exercises the three
CLAUDE_ROLE-parameterized canon gates — `trailer-gate.sh`,
`record-fields-gate.sh`, `handbook-trigger-gate.sh` — as real subprocesses,
plus `core/hooks/tests/stub-check.sh`.

Run it directly, no setup required:

    bash core/hooks/tests/run-role-gates-tests.sh

Asserts, for each gate, that two distinct `CLAUDE_ROLE` values produce
role-correctly-labeled refusals from the one canon file (`"${role}: refused
— ..."`), that each gate's own kill switch (`TRAILER_GATE_OFF`,
`RECORD_FIELDS_GATE_OFF`, `HANDBOOK_TRIGGER_GATE_OFF`) disables it, and that
`record-fields-gate.sh`'s `RECORD_FIELDS_TERMINAL_STATES` override changes
which `loop_state` values count as terminal.

`record-fields-gate.sh` accumulates every §20 violation on a write (missing
sections, sha placeholder, bare-sha `code_under_review`, missing
next-steps/resolution-path) into one list and denies once with the complete
set, instead of exiting on the first violation found (issue-140 — a
sequential-deny staircase measured at 8,157s across 337 refusals). The deny
message also names the literal accepted strings for each missing section
(e.g. `"what was done"`, `"what i did"`), not just the abstract label, so
the requirement is discoverable from the message alone.

`RECORD_FIELDS_TERMINAL_STATES` defaults to
`landed complete closed done delivered phase-2-complete` (widened from the
former lone `landed`, issue-140). Before the terminal-state membership
test, `-`/`_` are normalized to `-`, and a `-` is also inserted across
every letter/digit boundary (`phase2` -> `phase-2`), so
`phase_2_complete`, `phase-2_complete`, `phase-2-complete`,
`phase2-complete`, and `phase2_complete` all normalize to the same
terminal state (PR #143 feedback on issue-140 — the digit-boundary gap
left `phase2-complete`/`phase2_complete` misclassified as non-terminal).

For `CLAUDE_ROLE` in `{"coding", "implementation"}` (the repo's known
coding/implementation naming double), `record-fields-gate.sh` additionally
denies a write to that role's own record when `code_under_review:`'s
value, stripped, matches a bare single commit-sha token
(`^[0-9a-f]{7,40}$`, nothing else on the line) instead of a file list —
the record is committed in the same commit as the code it describes, so a
sha it would cite does not exist yet when the file is written. See
`docs/issue-100/decisions/2026-08-03-record-citation-format-and-kind-convention.md`.

`record-fields-gate.sh` also runs a second, independently-scoped check
(issue-128, tightened to an allow-list by issue-133) against both a role's
own `reports/<role>.md` write and any `docs/issue-<n>/proposals/*.md`
write (a proposal is a different artifact kind, so it does not run the
five §20 checks above — only this narrower check applies to it): a `sha:`
line's value is allowed only when it is exactly the literal `same-commit`
or exactly a 40-character lowercase hex commit sha; every other value —
a bracket placeholder (`sha: <set at commit>`), a bare unresolved spelling
(`sha: HEAD`, `sha: TBD`), or a bracket with trailing prose
(`sha: <set at commit> -- fix later`) — is denied. Per contract §1's
same-commit convention, an `upstream` entry whose `path` lands in the same
commit as the citing record or proposal is written as the literal
`sha: same-commit` instead.

This check scans only the leading `---`-delimited YAML frontmatter block
(issue-153) — the region the `upstream:`/`sha:` convention actually
governs — not the whole document, so a record or proposal that *quotes* a
non-conforming value outside frontmatter (a fenced example documenting
this defect class, say) is not denied for it; the identical value written
live inside the frontmatter's own `upstream:` entry is still denied. A
`sha:` field present with no value on its own line is allowed (the
pre-existing convention for an empty value, carved out explicitly rather
than misread as denying whatever text starts the following line), and a
legitimate value followed by a trailing YAML comment (`sha: same-commit  #
landed same commit`) has the comment stripped before validation.

A document with no leading frontmatter fence at all (after tolerating one
incidental leading blank line or byte-order mark, the same tolerance
already applied when locating a real fence) has its *entire text* scanned
instead of being skipped (issue-157) — the fallback exists so a malformed
or absent fence cannot silently disable the check for a document that was
supposed to carry frontmatter but doesn't. The scanned frontmatter region
itself ends at the *first* column-0 `---` line found after the opening
fence, not the last (issue-157) — a stray `---` line appearing inside
what was intended as frontmatter content truncates the scanned region
there, and anything after it (including a `sha:` line) goes unscanned.

`trailer-gate.sh` extracts a heredoc-supplied `-m` message
(`git commit -m "$(cat <<'EOF' ...body... EOF)"` — the standard idiom for a
multi-line commit message) directly from the raw command string via a regex
anchored on the heredoc terminator line, before ever handing the command to
`shlex.split()` (issue-151). `shlex` has no concept of heredocs: it
re-tokenizes the heredoc body as ordinary shell syntax, so a body containing
an unescaped double quote — common in real commit messages quoting an
identifier or path — either aborts tokenization (`ValueError`) or silently
mis-splits the `-m` argument, in both cases losing the `Subject:` trailer the
gate is checking for even though the trailer is present in the message. The
heredoc-body regex sidesteps `shlex` entirely for this idiom; only commands
that don't match it fall through to the pre-existing `shlex`-based `-m`/`-F`
extraction. The trailer check itself (`Subject: issue-<n>` present/absent) is
unchanged in both paths — a heredoc message missing the trailer is still
denied.

`stub-check.sh` is checked against synthetic rulebook trees: a clean tree
passes, a reintroduced vendored copy of any of the five canon files (the
three gates, `parse-check.sh`, and `stub-check.sh` itself) is caught, a real
lib-call stub `directive.sh` passes, and a `directive.sh` that has regrown
boilerplate (a case statement, a role guard, raw output beyond the
`core_role_directive` call) is caught. The checked file list is not
hardcoded in the script — it is read from `core/hooks/tests/canon-manifest.txt`
(one filename per line); promoting a new script to core canon means adding
one manifest line, not editing detection logic.

issue-189: the shared `refused` `loop_state` value (contract §2 preamble)
is deliberately NOT added to `record-fields-gate.sh`'s
`KIND_TERMINAL_DEFAULTS` for any kind — it needed no gate code change at
all. Since `refused` is then treated as any other non-terminal state, the
gate's existing next-steps/resolution-path requirement already enforces
contract §2's "a bare `refused` with no pointer is not a valid
consumption of the refusal" mechanically: a `refused` record with no
next-steps/resolution-path is denied the same as any other non-terminal
state missing that pointer, and one paired with it is allowed.
`run-role-gates-tests.sh` pins both halves of that pair.

issue-189 (narrow negative-lifecycle remainder): `withdrawn` — the second
shared `loop_state` value added to the contract §2 preamble alongside
`refused` — is likewise deliberately NOT added to any kind's
`KIND_TERMINAL_DEFAULTS`; the existing next-steps/resolution-path
requirement for non-terminal states already enforces "a bare `withdrawn`
with no finding pointer is not a valid consumption" mechanically, same
as `refused`. `run-role-gates-tests.sh` pins both halves of that pair.
`deferred`, the third shared value, is deliberately non-terminal by
design (a deferred unit stays resumable) and gets no terminal-spelling
coverage here.

Wired into `core/hooks/tests/run-all.sh`.

## Canon invocation from a rulebook (issue-69)

`stub-check.sh` is core canon and is never vendored into a rulebook's own
tree. A rulebook's test harness invokes it by a path resolved against
core's own plugin install root — the same shape `core/hooks/hooks.json`
already uses for the four registered gates
(`${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh`) — passing the rulebook's own
directory as the scan target:

    "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/stub-check.sh" "$(dirname "$0")/.."

The first argument stays a rulebook-relative directory (what to scan); the
script binary itself is never copied. The exact `${CLAUDE_PLUGIN_ROOT}`
sibling-resolution expression should be verified against how a real
marketplace install resolves a sibling plugin path before this line is
copied verbatim into a rulebook's own harness — this repo's own test run
happens from a single checkout where `core/` and each rulebook plugin are
siblings, which may not match the external 43-repo marketplace-install
layout. A rulebook's own record notes only the invocation and its pass/fail
result, never a second copy of the file.

See `docs/handbooks/canon-scripts.md` for the general "reference, never
vendor" rule this invocation model follows, and
`docs/issue-69/reports/implementation/reclaim-21-copies.md` for the rollout
procedure retiring the 21 existing vendored copies of `stub-check.sh` in
favor of this invocation.
