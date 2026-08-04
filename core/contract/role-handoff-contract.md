---
status: final
---

# Role handoff contract (v3: issue/PR interaction model)

Authority document for how the nine role rulebooks — coding, qa,
feasibility, product, ux-design, ops, review, verify, reflect — coordinate inside the
target repository each is working on. v1 modeled coordination as one-shot
parcel handoffs between adjacent roles; v2 replaces that with a shared
blackboard each role reads, writes its own record onto, and enters from. This
document defines the shared record format; it does not itself change any of
the nine rulebooks. Landing this contract in each rulebook is separate,
one proposal per repo.

## 1. Common header

Every role record carries this frontmatter block in addition to whatever
role-specific fields section 2 requires:

```yaml
kind: <artifact kind string, see section 2>
subject: <stable identifier for the piece of work, shared by every role
          touching it>
produced_by: coding | qa | feasibility | product | ux-design | ops | review | verify | reflect
upstream:
  - path: <repo-root-relative path>
    sha: <commit SHA the artifact was read at>
    acknowledged_sha: <optional; see section 4>
loop_state: <this role's own state-machine position; see section 2's
             per-kind loop_state vocabulary>
```

- `upstream` is a list; empty (`upstream: []`) for a record not derived from
  another role's artifact — a chain root. A chain-root record states its own
  `sha` (the commit that introduced the record itself) at write time; there
  is nothing to compare it against, so section 4's staleness rule is
  trivially satisfied for it and never fires against itself.
- `subject` is the issue number (`issue-<n>`, section 9), copied verbatim by every role
  touching the same piece of work.
- `loop_state` is this contract's field for that role's internal
  state-machine position (section 2 lists each role's vocabulary). A role's
  internal state machine remains its own business — this contract does not
  define its transitions — but the role must write its current state into
  `loop_state` at every transition it completes. `loop_state` is the shared
  truth other roles may depend on; a role's private notes about intermediate
  sub-steps are not, and are not required to appear here.

## 2. Artifact kind table (the blackboard's rows)

Every role writes exactly one status record onto the blackboard,
`docs/issue-<n>/reports/<role>.md`, plus zero or more per-item
sub-artifacts. All nine roles are sanctioned here, including product's and
coding's records, closing the trial's two unsanctioned-kind gaps.

| kind | produced by | path | `loop_state` vocabulary | required fields beyond common header |
|---|---|---|---|---|
| `hypothesis` | product | `docs/issue-<n>/proposals/<date>-<slug>.md` | `idle,scoping,researching,hypothesis-registered,measuring,decided` | Background/Context, Problem Statement, Candidate Hypotheses, Known Risks, Goals/Success Metrics |
| `product-record` | product | `docs/issue-<n>/reports/product.md` | same as `hypothesis`, plus `scope-proposed,scope-approved` — see section 19 | pointer to the governing `hypothesis`; running acceptance-criteria notes; scope statement per section 19 once `loop_state` reaches `scope-proposed` |
| `one-pager` | product | `docs/specs/one-pager.md` | n/a (standing doc, not per-subject) | Background/Context, Problem Statement, Candidate Hypotheses, Known Risks, Goals/Success Metrics |
| `opportunity-tree` | product | `docs/reports/opportunity-tree.md` | n/a (continuous interview log) | — |
| `build-proposal` | coding | `docs/issue-<n>/proposals/<date>-build-<slug>.md` | `proposed,approved,landed` | `files:` (write-set freeze list), `## Request`, `## Constraints`, `## What will be done`, `## Out of scope` |
| `coding-record` | coding | `docs/issue-<n>/reports/coding.md` | same as `build-proposal`, plus `finding-response` sub-entries per item 4, plus `findings-resolved` per section 15 | pointer to active `build-proposal`; commit shas landed; `resolved_findings:` list (when applicable) — see section 15 |
| `qa-record` | qa | `docs/issue-<n>/reports/qa.md` (fully in-repo; see section 6) | `observed,reproducing,reproduced,handed-off,re-verifying,verified-fixed,not-a-defect,wont-fix` | intake profile, bug reports, regression records, run stats — all in-repo under this record's area |
| `feasibility-record` | feasibility | `docs/issue-<n>/reports/feasibility.md` | `idle,scoped,probing,verdict`, plus `scope-proposed,scope-approved` when this record is the subject's front record — see section 19 | `market_argument_supplied: false`, `technical`/`prior_art`/`legal_regulatory`/`threat_model` (each `unresolved\|pass:<evidence>\|fail:<evidence>\|blocked:<evidence>`), `verdict: go\|no-go\|conditional` (required once `loop_state` reaches `verdict`), `measurement_design: <description or pointer>`; `technical` enumerates the deploy/runtime config surface (env var names the build must honor) whenever it is foreseeable at feasibility time — see section 17 |
| `spike-report` | feasibility | `docs/issue-<n>/reports/spikes/<spike-slug>.md` | n/a (closed report) | Spike Title, Description/Goal, Type, Timebox, Acceptance Criteria, Tasks, Outcomes, Recommendation, Open questions, Reversibility tag; fixture-N notation if fixtures are involved (records the fixture count it was authored against, so a downstream re-run can detect additions/removals) |
| `ux-design-record` | ux-design | `docs/issue-<n>/reports/ux-design.md` | `idle,drafting,reviewed` | pointer to the governing `hypothesis`/`product-record`; screen/flow/wireframe specs or pointers to them |
| `review-record` | review | `docs/issue-<n>/reports/review.md` | `idle,scoped,auditing,draft-reported,reported` | `closed_checks:` list keyed to the reviewed code sha — see section 16 |
| `verify-record` | verify | `docs/issue-<n>/reports/verify.md` | `idle,reproducing,reproduced,cleared` | what was attempted, what reproduced (if anything), reproduction evidence (repro steps, commit sha, run output); `closed_checks:` list keyed to the reviewed code sha — see section 16 |
| `finding` | any role | inline block within the addressing role's own record | n/a | `requirement`, `verdict` (`Present\|Surface\|Absent\|Incorrect\|Unverifiable`), `evidence`, `rationale`, `spec_vs_built` (required only when `verdict: Incorrect`), `addressed_to: <role>`, `severity: blocking\|advisory` — see item 4 |
| `ops-record` | ops | `docs/issue-<n>/reports/ops.md` | `idle,readiness,rollout,steady,incident` | `error_budget: ok\|exhausted`, `postmortem: <pointer>`, `## Checklist` (`- item: <desc> \| status: yes\|no \| artifact: <url/path/config key>`); `## Deploy-config` REQUIRED whenever `feasibility-record` did not enumerate the deploy/runtime config surface — see section 17 |
| `postmortem` | ops | `docs/issue-<n>/reports/postmortems/<incident-slug>.md` | n/a (closed report) | Impact, Actions taken during response, Root cause(s), Prevention follow-up (owner+tracking+closing-condition), Review (named human reviewer) |
| `reflect-record` | reflect | `docs/issue-<n>/reports/reflect.md` | `idle,reflecting,candidate-round-done,round-done` | pointer to the subject's other role records read; what went well, what failed, what pattern should change next time |

`kind` parsing by any gate must tolerate a trailing comment on the line
(`kind: build-proposal  # re-scoped`); a regex anchored to end-of-line with
no comment tolerance is a gate defect, not a contract violation by the
record's author.

## 3. Record states; routing is the orchestrator's judgment

Each role's loop enters when the board reaches one of its trigger
conditions, replacing v1's single accept/refuse-at-handoff moment.
Concurrent entries are the normal case: a board change may satisfy more than
one role's row at once, and all of them proceed in parallel — this is where
the model's parallelism comes from, not an edge case.

Records carry the `loop_state` values defined in this contract (the states
enumerated per section — `scope-proposed`, `scope-approved`,
`findings-resolved`, `cleared`, `round-done`, and the others named
throughout). Which role a given state summons is the orchestrating
session's judgment, made by reading the board directly — no routing
table, no host-doc pointer. This contract stays self-sufficient about
record FORMAT and STATES; it says nothing about, and defers nothing to a
document about, "who gets opened next."

**Who evaluates state changes.** No automated watcher exists yet in this
operating model. A human (or a future automated watcher, if one is built)
reads the board and opens the role its judgment names — this is the
intended narrowing of the human's job: judging "does the board match this
state," not carrying memory of what should happen next.

**Round-end value-gates edge.** A subject reaching candidate round-done
prompts the human to run section 18's two value gates before round-done may
be set: candidate-round-done -> (gates A and B run) -> round-done. Like
every role-entry in this contract, this edge is human-consulted, never
automated — see section 18.

**Pre-work approval-gate edge.** A subject's front record reaching
`loop_state: scope-proposed` prompts the human to review it and, on
approval, set `loop_state: scope-approved`: scope-proposed -> (human
review) -> scope-approved. Like every role-entry in this contract, this
edge is human-consulted, never automated, and it is the ONLY path to
`scope-approved` — no role may set that state on its own or any other
role's record. See section 19.

## 4. Consumption semantics

Replaces v1's ACCEPTS/refuse table with three separate questions, at the
right grain — v1 had one lever (accept/refuse a whole kind) and used it to
also answer "may this role even read that file," which conflated two
different concerns (see qa row below).

- **READ (broad).** The board exists to be read. Every role may read every
  other role's record, unconditionally, for context. Reading something is
  never itself a violation.
- **DEPENDS-ON (narrow, per role).** What a role's own conclusion is allowed
  to cite as its basis:
  - product depends on `feasibility-record` (a verdict causing it to react).
  - coding depends on `hypothesis`, `feasibility-record`, and `finding`
    blocks addressed to it.
  - qa's DEPENDS-ON list is empty. qa may READ `feasibility-record`'s
    `measurement_design` and any other record as advisory context, the same
    as any role — this is not a reading ban. But qa's verdict must be built
    from direct observation of the running system, never from another
    role's record. This is the direct-observation principle, restated as a
    DEPENDS-ON restriction rather than a refusal to open the file.
  - review depends on `build-proposal` (the change) to decide what should
    exist, and may READ `hypothesis`'s and `build-proposal`'s narrative
    sections freely for context on intent. What review may DEPEND ON for a
    `finding`'s `spec_vs_built` judgment is narrower: the finished change as
    built and the `build-proposal`'s stated `files:`/sections, not the
    hypothesis's aspirational narrative standing in for what was actually
    specified. Reading the narrative is allowed; building `spec_vs_built` on
    it alone is not.
  - ops depends on `build-proposal` (what merged) and `hypothesis` /
    `feasibility-record` (the measurement design).
  - ux-design depends on `hypothesis` and `product-record` (the accepted
    problem framing its screens/flows answer). `ux-design`'s contract entry
    enforces structure only — that a `ux-design-record` exists per subject
    — and does not dictate what counts as good design, or when it acts
    (that is the orchestrator's call, not this contract's); that judgment
    is ux-design's own.
  - verify depends on `coding-record`, `qa-record`, and `review-record` — it
    reads what was built, what qa already tried, and what review concluded,
    then goes looking for what none of them caught. It emits `finding`
    blocks per section 5, `addressed_to: coding`, with `severity: blocking`
    or `advisory`. A `verify` finding with `severity: blocking` is not
    overridden by a `review-record` in `loop_state: reported` with a clean
    verdict — review's and verify's verdicts are independent, and verify's
    blocking findings gate landing on their own terms, per this section's
    unchanged NEVER-OVERWRITE / ownership rule. `verify`'s contract entry
    enforces structure only — that a verify record exists and emits its
    blocking-finding channel per section 5 — and does not dictate what
    counts as a defect, or when it acts (that is the orchestrator's call,
    not this contract's); deciding what is a real defect is verify's own
    judgment.
  - reflect depends on the subject's other role records (`coding-record`,
    `qa-record`, `review-record`, `verify-record`, and any others present)
    and any `finding` blocks addressed to or from them — the retrospective
    material it reads to produce its retro. `reflect`'s contract entry
    enforces structure only — that a `reflect-record` exists per subject
    and that it may emit `finding` back-edges at `severity: advisory` —
    and does not dictate what the retro concludes, or when it acts (that
    is the orchestrator's call, not this contract's); that judgment is
    reflect's own.
- **NEVER OVERWRITE (unchanged from v1 §7).** Per-role write ownership
  (section 7 below) carries over without change. READ/DEPENDS-ON add
  semantics on top of an unchanged ownership rule; they do not loosen it.

## 5. The finding back-edge

Any role may post a `finding` addressed to any owning role via the board —
generalized from v1, where only review produced findings, to all nine roles.

- `addressed_to: <role>` names the role that owns the fix.
- `severity: blocking | advisory`. `blocking` means loops that DEPEND ON the
  addressed role's output pause until the finding is resolved. `advisory`
  means downstream loops continue; the finding is context, not a gate.
- Findings addressed to a role are visible on the board for the
  orchestrator to act on.
- **Response schema.** When the addressed role closes out a `finding`, its
  own record must carry a `finding-response` entry containing: the finding
  it responds to (a stable reference — record path plus finding
  identifier), the action taken or, if declined, the reason for declining,
  and — when code changed — proof of the fix (commit sha, targeted re-run
  result, or equivalent evidence). An entry missing any of these three parts
  does not close the finding.

## 6. Loop termination

- A role-entry is consumed by writing the resulting record entry (a
  `loop_state` change, a new `finding`, a `finding-response`, or
  equivalent). Writing nothing means the entry was not consumed.
- An unchanged board prompts no further entry. If a role's write leaves
  the board byte-identical to what the entering role already observed, no
  further entry is prompted from it.
- **qa↔coding cycle termination.** A `finding` from qa produces a
  `finding-response` from coding; coding's fix produces a new commit, which
  is a board change that may prompt the orchestrator to open the next
  role. This cycle terminates when an entry produces no new board change
  — i.e., qa observes the fix, and either verifies it (`loop_state:
  verified-fixed`, no new `finding`) or re-opens it with a new `finding`
  that itself constitutes a board change. A qa entry that results in
  neither a `verified-fixed` write nor a new `finding` is not a valid
  consumption of the entry and must not be treated as cycle-closing; but
  an entry that reproduces an *already-filed, unresolved* finding without
  adding new information is not a new board change either, and does not
  re-open the cycle. This is the rule that keeps qa↔coding ping-pong finite.
- **verify↔coding cycle termination.** Extends the above to verify: a
  `verify` entry is not a valid consumption unless it produces either a
  `cleared` `loop_state` (no unresolved reproduced findings) or a
  new/re-affirmed `finding`. A blocking finding resolves only when coding's
  `finding-response` supplies fix evidence that verify re-observes, or the
  human explicitly waives it under section 8's human-judgment seat.

## 7. `loop_state` authority

The board's `loop_state` field is the one piece of a role's state machine
that other roles may depend on. A role is free to run whatever internal
sub-states or scratch process it wants; none of that is visible or binding
to other roles unless reflected onto `loop_state`. A role must update
`loop_state` on the board at each transition it completes — a role that
completes a transition internally but leaves the board's `loop_state` stale
has not, for the purposes of this contract, completed the transition, since
no other role, or the orchestrator reading the board, can see it.

## 8. The human's seat

The human's role narrows to judgment points, named explicitly. Everything
else — which role runs next — is carried by the host's routing rules (see
section 3), not by a human relaying a handoff. Every decision on this list
is expressed
exclusively as a GitHub act per section 10 — a PR review Approve, a PR
merge, a PR comment, or an issue/PR close — never as prose a model reads
approval out of, and never as a token.

- Opening or retiring a `subject` — filing the issue, or closing it (a
  closed issue's board is no longer live for any role; see section 9).
- Verdicts this contract reserves for a human (e.g. qa's is-this-a-defect
  call — expressed by merging or closing qa's PR, and by filing the
  resulting issue when the defect is judged valid).
- Resolving cross-role disputes that DEPENDS-ON rules (section 4) do not
  settle.
- Approving scope changes, including the pre-work approval gate that moves
  a subject's front record from `scope-proposed` to `scope-approved`
  before any building role's first entry on that subject — see section 19.
- Running section 18's two round-end value gates and setting a subject's
  `round-done` state — required before `round-done` may be set, never
  automated.

## 9. `subject` is the issue

A `subject` is never minted by a role. The user files an issue on the
target repository — issues are the user's requirement backlog, and only
the user authors them; no role ever files an issue — and the issue number
IS the subject: `subject: issue-<n>`. `docs/issue-<n>/` is that subject's
entire document tree.

A role receives its issue in the prompt that invokes its session — the
human, or the orchestrator on the human's behalf, names it; a role never
selects an issue for itself. Invoked without one, the role asks and stops
rather than choosing. A role that cannot point to an issue has no subject
to work on. v2's
derive-and-search minting rule (`<date>-<slug>` taken from the first
artifact, plus a dedup search over existing records) is deleted: the issue
backlog is the canonical registry of subjects, so there is nothing to
derive and nothing to search.

**Remoteless-repo identifier fallback.** Where any per-repo derived
identifier is needed in a rulebook (e.g. a local cache key), the naming
rule is: use the repo's directory name. This holds regardless of whether
the repo has a remote configured.

**Skill assessment before an issue is filed.** Before an issue is drafted,
the orchestrator judges per-request whether any of the user's available
skills apply to that request — a per-task judgment call, not a lookup
against a fixed skill-to-request mapping. A skill judged applicable is
invoked through the real `Skill` tool mechanism; reading the skill's file
as text and paraphrasing it does not satisfy this. The invoked skill's
procedural demands (required steps, evidence standards, stop conditions,
output shape) are folded into the drafted issue's requirements and
acceptance-criteria text — the skill invocation itself produces no
artifact of its own, so the issue text is the only output that carries
forward. Role sessions that later work the resulting issue remain
skill-isolated: no skill is injected into a role session; only the
issue's own requirements/acceptance-criteria text (already carrying any
folded-in skill demands) reaches the role. This subsection aligns with
on-the-record #258 / PR #259, which established the same procedure for
`on-the-record/commands/run.md` step 1.

## 10. Where records live: the board is the target repo's `main`

All role output lives inside the target repository — the repository the
issue was filed on. No separate org records repo participates. Role
records live at `docs/issue-<n>/reports/<role>.md`. Every `path` entry in
every `upstream` list is repo-root-relative.

**Precondition: the target is a git repository with a GitHub remote.**
Issues, PRs, and reviews are GitHub objects, and approval's forgery
resistance comes precisely from being a GitHub-authenticated act — a
local-only repository has no issue to start from, no PR to return through,
and no review to approve with, so this model cannot run on one. A role
session finding the precondition unmet does not improvise a local
substitute (a local approval artifact is writable by the model's own
tools, i.e. forgeable); it states what is missing and stops. Remediation
belongs to the human: publish the repository
(`gh repo create <owner>/<name> --private --source . --push` or
`git remote add origin <url>`), and authenticate `gh` (`gh auth login`).
GitHub Enterprise hosts work wherever `gh` does.

**The interaction channels.** The user talks to the system through exactly
two channels, and the system answers through exactly one:

- **Issue = user → system.** Requirements enter as issues, authored by the
  user only (section 9).
- **PR = system → user.** Every role returns ALL of its output — code,
  records, reports, documents — as a pull request against `main`. No role
  pushes to `main` directly, ever. A role enters, checks out `main`, works
  on its own branch `issue-<n>/<role>` (one branch per issue × role, never
  shared between roles), and opens a PR.
- **Human decisions are GitHub acts, and only GitHub acts**: a PR review
  Approve is permission to proceed from proposal to execution (section
  19), merging a PR is acceptance of the delivered work, commenting on a
  PR is feedback (the role revises on the same branch and pushes to the
  same PR), closing an issue or PR unmerged is refusal. These are
  GitHub-authenticated mechanical acts recorded in history — never textual
  inference by a model. A free-text comment is never an approval, however
  affirmative it reads: deciding what a sentence means is a language
  problem, and the review Approve state exists precisely so no one has to.
  The one structural exception is section 19's single-account path: an
  issue-level comment — posted on the subject's issue (`issue-<n>`), not
  on any PR — whose entire body is the exact string `APPROVE
  issue-<n>/<role>`, posted by an `approvers.md` account, is a mechanical
  string match, not textual inference — free-text approval commentary of
  any other shape remains categorically rejected. This is the one signal
  that lives on the issue rather than the PR: contract v3's own practice
  produces two PRs per subject/role (phase 1's proposal PR, then phase
  2's build PR, opened after phase 1's PR has already merged and closed —
  section 19), and the issue is the one anchor stable across both.
  Feedback, acceptance, and refusal comments stay attached to the PR
  under review, exactly as before; only this one Approve signal is
  issue-attached.
- **Who counts as the human.** The target repo names its human approvers
  in `docs/specs/approvers.md` (one GitHub login per list line). Only an
  Approve review authored by a listed account satisfies a human seat.
  System accounts (CI, bots, security scanners) may Approve for their own
  purposes and may be required by branch protection, but never satisfy a
  human seat; agent accounts are simply not listed, which is what makes
  "no role approves its own PR" mechanical.

**The board is what is merged.** An open PR is not yet on the board;
Routing judgment (section 3) is made against `main` plus the issue backlog. A
role's output is invisible to other roles until the human merges it — the
human pacing the pipeline is the intended structuring of "human-consulted,
never automated", not a defect.

**Fixed output layout.** Enforced for every PR: code under `src/` only;
test code under `test/` only; documents under `docs/` only, with a single
exception for `README.md` at any level. Directly under `docs/` exist only
the six standing-document directories — `_assets`, `decisions`,
`handbooks`, `proposals`, `reports`, `specs`, for documents tied to no
single issue — and the `issue-<n>/` trees, each containing only those same
six subdirectories.

**qa's evidence moves in-repo.** v1 kept qa's bulk evidence (intake
profile, run logs, regression history) in `$QA_WORKSPACE`, an external,
host-local, uncommitted tree, with only a thin pointer record left inside
the repo. That exception is abolished. qa's evidence — intake profile, bug
reports, regression records, run stats — now lives entirely inside the work
repo, under qa's own record area
(`docs/issue-<n>/reports/qa/**`, alongside `qa.md` itself). No
role's cross-role-visible status escapes the repo; there is no external
workspace path left for a future hunter to find qa's status having leaked
out of.

**`ops-record` tension, carried forward.** `ops-record` is rewritten in
place as current system state changes (steady, incident, error-budget), not
appended to as a dated record, unlike the rest of `reports`. This document
states the mismatch rather than papering over it; it does not invent a
seventh bucket to fit it.

## 11. Per-role path ownership (never-overwrite)

| role | writes |
|---|---|
| product | `docs/issue-<n>/proposals/<date>-<slug>.md` (`kind: hypothesis`), `docs/issue-<n>/reports/product.md`, `docs/specs/one-pager.md`, `docs/reports/opportunity-tree.md` |
| coding | `docs/issue-<n>/proposals/<date>-build-<slug>.md` (`kind: build-proposal`), `docs/issue-<n>/reports/coding.md` |
| qa | `docs/issue-<n>/reports/qa.md`, `docs/issue-<n>/reports/qa/**` (all in-repo, section 10) |
| feasibility | `docs/issue-<n>/reports/feasibility.md`, `docs/issue-<n>/reports/spikes/<spike-slug>.md` |
| ux-design | `docs/issue-<n>/reports/ux-design.md` |
| review | `docs/issue-<n>/reports/review.md` (including inline `finding` blocks) |
| ops | `docs/issue-<n>/reports/ops.md`, `docs/issue-<n>/reports/postmortems/<incident-slug>.md` |
| verify | `docs/issue-<n>/reports/verify.md` (including inline `finding` blocks) |
| reflect | `docs/issue-<n>/reports/reflect.md` (including inline `finding` blocks) |

A role finding an existing record already present at a path section 11
assigns to a different role must refuse to write there and report the
conflict to the user, rather than overwriting or merging into it silently.

`docs/issue-<n>/proposals/` stays shared between product and coding, disambiguated by
filename tag: coding's `build-proposal` filenames carry `-build-`
(`<date>-build-<slug>.md`), distinct on its face from product's
`<date>-<slug>.md`.

**Section 21 grant.** Each role additionally owns, in the target project,
the specific `docs/decisions/<date>-<slug>.md`, `docs/reports/<date>-<slug>.md`,
and `docs/specs/` entries that role itself authors under section 21's
trigger — never the directory as a whole, only the file(s) it writes there.
This mirrors this table's existing `docs/issue-<n>/reports/<role>.md` grain: a
role that makes a hard-to-reverse choice owns its own
`docs/decisions/<date>-<slug>.md`; a role that produces a measurement,
benchmark, test run, or investigation owns its own
`docs/reports/<date>-<slug>.md`; a role whose work is system design tied to
the code owns its own `docs/specs/` entry. Two roles never collide on the
same file because each owns only the file it itself authored. This grant is
what makes section 21's placement obligation satisfiable under this
section's ownership scoping.

**Handbook grant (component-scoped shared-write).** `docs/handbooks/<component>.md`
is owned by the component, not by a single first-author role: any role that
changes that component's operational surface (an environment variable,
config key, dependency, migration, or run/setup/deploy step, per section
21's handbook trigger) may create or update that component's handbook.
This is deliberately different from this section's other grants, which are
single-author write-once; a handbook is a living current-state doc that
must track whichever role most recently touched the component's
operational surface, per section 21's write-time maintenance rule.
`<component>` itself is derived, not chosen, and creating a new handbook
file requires a search for an existing one first — see section 21's
"Deriving `<component>`" and "Search before write" paragraphs.

**Carried over, unenforced (v1 §7's flagged tension).** warrant's
`scope-gate.sh` allows any write under `docs/` unconditionally, regardless
of an approved proposal's `files:` write set. Nothing mechanical stops one
role from writing into another role's record path. This table is the
normative rule, not a description of what warrant already enforces;
enforcing it is each role's own rulebook's responsibility (a
`placement-gate.sh`-style check), same as v1. This proposal does not add
the gate.

## 12. Staleness rule

Before acting on a handed-over artifact, a role compares each `upstream`
entry's recorded `sha` against the current commit touching `path`
(`git log -1 --format=%H -- <path>`). If they differ, the role stops and
asks the user:

> `<path>` has changed since this record was written (recorded at `<sha>`,
> now at `<current-sha>`). Proceed on the version at `<sha>`, or re-confirm
> against the current version?

The role does not decide this itself and does not silently re-read and
continue. It waits for the user's answer.

**Chain-root exemption.** An `upstream: []` record has nothing to compare
against; it states its own `sha` at write time and the check is trivially
satisfied — this is not a gap, it is the defined behavior for the first
record in a chain.

**When it fires.** Exactly once per role-entry, at the point the role
begins acting on a handed-over artifact, before work starts. It does not
re-fire mid-build; a change landing in `path` while the role is already
working is caught on the *next* entry into that artifact, not immediately —
deliberate, so the check does not collide with warrant's rule against
pausing mid-build.

**First-read `acknowledged_sha`.** On a role's first read of an upstream
artifact there is no prior `acknowledged_sha` to compare against, so the
full staleness prompt above applies exactly once, unconditionally.
`acknowledged_sha` is written only *after* that first answer — it is
omitted from the `upstream` entry until then, never populated with a guess
or a placeholder.

**Acknowledging a sha instead of re-confirming it.** Once the user has
answered the prompt for a given `path`/`sha` pair, the role records
`acknowledged_sha: <sha>` next to that entry. On a later re-entry, if the
current sha at `path` equals the recorded `acknowledged_sha`, the role
treats it as already confirmed and does not re-prompt, even though it
differs from the original `sha`. If the current sha matches neither `sha`
nor `acknowledged_sha`, the full prompt fires again.

## 13. Commit trailer requirement

Every commit a role's rulebook makes as part of landing a record or a
build must carry the trailer format its own rulebook's hook enforces
(e.g. a `Subject:` or `Kind:` trailer identifying the record the commit
belongs to). This requirement is documented here, in the contract body,
rather than being discoverable only via a hook rejection at commit time.
The exact trailer keys are each rulebook's own concern; this contract only
requires that some machine-checkable trailer identifying `subject` and
`kind` be present, and that it be stated in the rulebook's own docs, not
left implicit. Wherever a trailer names the subject, its value is the
issue-keyed form (`Subject: issue-<n>`, per section 9) — the branch name
`issue-<n>/<role>` and the trailer therefore agree on their face.

## 14. Mechanical checks are not substantive checks

- **`kind` is self-declared and unverified.** No rulebook adopting this
  contract checks that a declared `kind` matches the artifact's actual
  content. Routing judgment and DEPENDS-ON both read the declared value
  only.
- **Sha equality (section 12) proves a file did not move — nothing more.**
  A matching sha means the bytes at `path` are byte-identical to what was
  read; it says nothing about whether the conclusion drawn from it still
  holds.
- **Section 11's path ownership is a table, not a gate.** No mechanical
  check in this contract enforces it; a role staying inside its own path is
  a structural guarantee this contract's prose implies but that no hook
  actually provides unless the role's own rulebook adds one.

A passing structural check (kind matched, sha matched, the role entered) clears a
role to proceed under this contract; it is not evidence the artifact is
sound. That judgment stays with the role reading it.

## 15. Finding-resolution handshake

Section 5 defines how a `finding` is raised and how the addressed role's
`finding-response` closes it out. It does not define how the role that
*raised* the finding learns to re-verify it — this section does.

- The fixer (the role that addressed the finding) records resolution in its
  **own** record only. Per section 4's NEVER-OVERWRITE rule, the fixer must
  never write to the finder's record — resolution is signaled forward, not
  written backward.
- The fixer's record carries a `resolved_findings:` list, each entry naming
  the finder record's path and the finder-record sha it addresses:

  ```yaml
  resolved_findings:
    - finder_path: <path to the finder's record>
      finder_sha: <sha of the finder's record at the finding it addresses>
  ```

- The fixer sets `loop_state: findings-resolved` on its own record when it
  writes a `resolved_findings` entry. This is in addition to, not instead
  of, the `finding-response` entry section 5 already requires.
- **State transition.** finding-raised -> (fix) -> `findings-resolved` ->
  re-verify. Which role opens next on `findings-resolved` is the
  orchestrator's judgment call, same as section 3. Like all state
  transitions in this contract, resolving it is human-consulted, not
  automated.
- Re-verification itself is the finder's own judgment (per section 4's
  per-role DEPENDS-ON rules for that role); reaching `findings-resolved`
  clears the fixer's side of the handshake, it does not itself close the
  finding — only the finder's re-verification does that.

## 16. Closed-checks cite-and-skip (verify/review division of labor)

verify (adversarial) and review (5-lens) both read the same built code and
can re-derive the same conclusions blind to each other's work. This section
gives them a hand-off mechanism, without turning either into a rubber stamp
for the other.

- A role's record declares which checks/lenses/probes it CLOSED, via a
  `closed_checks:` list keyed to the exact code sha it closed them on:

  ```yaml
  closed_checks:
    - check: <lens/probe name>
      code_sha: <commit sha of the code this check was closed against>
  ```

- A downstream role MAY cite-and-skip a check another role already closed —
  citing the `closed_checks` entry instead of re-deriving it — **only when**
  the closing entry's `code_sha` equals the code sha currently under review.
  A check closed on a different sha does not count as closed; the code
  changed since, so the downstream role MUST run it itself.
- Any check not present in a prior role's `closed_checks` at the current
  code sha MUST still be run by the downstream role. This section is not a
  mandate to skip — it is a mechanism to avoid blind re-derivation of checks
  someone has already closed on the exact code being looked at.
- This does not loosen section 4's independence rule: a `verify` finding
  with `severity: blocking` is still not overridden by a clean
  `review-record`, and vice versa. Citing a closed check narrows what must
  be re-derived; it does not merge the two roles' verdicts.

## 17. Deploy-config ownership

No role owned naming deploy/runtime config (e.g. `PORT` and other env var
names the build must honor) prior to this section, which let it be invented
unilaterally wherever it was first needed. This section assigns ownership.

- **Default: feasibility owns it when foreseeable.** feasibility's
  `technical` field (section 2's `feasibility-record` row) enumerates the
  deploy/runtime config surface — the env var names and their meaning — when
  that surface is foreseeable at feasibility time. When feasibility's record
  states it, that record is the authority coding and ops build against.
- **Fallback: ops's REQUIRED deploy-config section.** When feasibility did
  not foresee a piece of the deploy-config surface, `ops-record`'s
  `## Deploy-config` section (section 2's `ops-record` row) is REQUIRED and
  becomes the authority for the config it names. This is a fallback, not a
  parallel default — ops only originates naming for what feasibility could
  not have foreseen.
- Whichever record does the naming, the other role's DEPENDS-ON reading of
  it (section 4) is unchanged: this section assigns naming authority, it
  does not add a new DEPENDS-ON edge.

## 18. Round-end value gates

A subject's round is not done merely because every role produced its
record. Two standing goals of this whole system — that the multi-role
procedure actually improves the deliverable, and that the git records alone
let a zero-context reader pick the work back up — are not guaranteed by
following the process; they must be MEASURED as outcomes at round end, not
assumed from process compliance. This section defines the two gates and the
round-done state they gate.

**(A) Procedure-value gate.** A role or handoff mechanism earns its place
only if removing it would measurably worsen the deliverable. At round end,
each role/mechanism that ran during the round is judged: did it change the
outcome or catch something real — cite the evidence (a bug caught, a
decision a later reader needed, a genuine handoff) — or did it only produce
a record because the process said to? Anything that cannot show it changed
the outcome is marked `ritual` for that round. Persisting `ritual` across
rounds is a defect the next contract revision must remove or convert to
real value. This gate never asserts "the step was performed" — it asserts
"the step earned its keep."

**(B) Blind-onboarding gate.** Before a round is declared done, an agent
with ZERO session context, given only the repository, must (1) reconstruct
what was asked/built/decided for the round's subject from records alone,
and (2) state what to do next and act on it — recording every stuck point,
contradiction, or unverifiable claim it hits along the way. The round
passes only if a no-context reader can both reconstruct AND continue
without out-of-band help; any stuck point is a records defect to fix, not a
gate to route around.

**(C) `round-done` definition and trigger.** A subject reaches `round-done`
when its `reflect-record` (section 2) — the last record to act in a round —
has its `loop_state` set to `round-done`, from `candidate-round-done`, the
same two states named in section 3's round-end value-gates edge. Gates A
and B above are a REQUIRED
human-consulted judgment-point that must fire BEFORE `round-done` may be
set — registered per section 3's round-end value-gates edge and section 8's
human's-seat entry, named in the structure exactly like every other
handoff. This stays human-routed: the human runs the gates and sets
`round-done`; it is NOT an automated watcher. A `round-done` set without
both gates having fired is a contract violation the structure can point to.

**Mechanism is out of scope.** How a round PASSES these gates — sha
conventions, single-source-of-truth numbering, or any other concrete
mechanism — is out of scope for this section. Passing the gate is what
matters; the mechanism is each round's own choice.

## 19. Pre-work approval gate: propose first, execute after Approve

EVERY role, on EVERY issue, works its PR in two phases. This generalizes
v2's coding-only scope gate to the whole system.

- **Phase 1 — propose.** The role's FIRST commits on `issue-<n>/<role>`
  are, before any execution work: its research (what is known about the
  problem), its current-state survey (what exists today and how this issue
  meets it), and its proposal (what this role intends to do, the intended
  write surface, what is out of scope, and how success will be judged).
  Proposal commitments are expressed as an enumerable clause checklist
  (one line per commitment), not prose alone; phase 2 marks, per clause,
  the commit or hunk that fulfilled it, or states the clause was dropped
  and requires re-approval before the drop stands. The proposal also
  names 1-2 alternatives it considered, one line each stating why it was
  not chosen, and one line stating the failure signal — a check that
  would fail, a behavior that would regress, or a complaint that would
  recur — if this proposal turns out wrong. A proposal missing any of the
  three is incomplete and not ready for the human's Approve.
  Research and survey live under `docs/issue-<n>/reports/<role>/`; the
  proposal under `docs/issue-<n>/proposals/`. The role opens the PR at
  this point and stops.
- **Current-state survey rigor floor.** The survey's quality depended
  entirely on which rulebook happened to bring its own discipline, absent
  any floor here — this closes that gap with a minimum, not a template:
  every factual claim in the survey carries a pointer to its evidence
  (a file path/line, a board record, a PR/issue number — something the
  next reader can open and check); the survey MUST cover the current
  state of every surface the proposal intends to write to, not a subset
  chosen for convenience; and unknowns are listed as unknowns, stated
  plainly, never silently omitted because no evidence was found for them.
- **The human's verdict on the proposal.** Two paths open phase 2:
  - **Two-account mode (stricter, preferred where available).** A PR
    review **Approve** from an approver listed in
    `docs/specs/approvers.md` (section 8), authored by an account
    different from the PR's author.
  - **Single-account mode.** When the PR author and the approver are
    the same GitHub account (the default setup — section 10 — under
    which GitHub structurally forbids a review Approve on your own
    PR), an issue-level comment — posted on issue `<n>` itself, never
    on a PR — whose entire body is the exact string `APPROVE
    issue-<n>/<role>` — this role's own subject and role name,
    verbatim, nothing else in the comment — posted by an account
    listed in `docs/specs/approvers.md`, is a valid phase-2 approval.
    The issue, not the PR, is the anchor: this role's own
    two-PR-per-subject practice (phase 1's proposal PR merges and
    closes before phase 2's build PR opens) means a PR-scoped comment
    on PR A is invisible to a gate resolving PR B once A is closed;
    the issue survives both PRs, so it is the only location one
    comment can authorize both phases from. String equality, never
    prose interpretation; an agent account's comment never counts,
    listed or not, since agent accounts are never in `approvers.md`
    (section 8). This closes the comment-vs-review discrepancy
    recorded in the muster issue-31 and issue-38 rounds, and the
    PR-vs-issue location discrepancy recorded in issue-53: verify's
    strict review-only reading, coding/qa/review's comment-accepting
    reading, and on-the-record's issue-canonical reading now converge
    on this text.

    **Scope.** One `APPROVE issue-<n>/<role>` comment authorizes every
    PR opened on the `issue-<n>/<role>` branch, past and future, for as
    long as the comment stands — not only the PR open at the moment the
    comment was posted (phase 2's PR typically does not exist yet when
    phase 1 is approved), and not a separate approval per phase (this
    section defines one gate transition, `scope-proposed` ->
    `scope-approved`; a per-phase split would add a second human
    judgment point this contract does not otherwise require). This is
    deliberately branch-wide rather than PR-specific: `issue-<n>/<role>`
    already names exactly one role working exactly one issue (section
    10, never shared), so "every PR on the branch" is the same unit of
    work the human already approved, not a wider one.

    **What this does and does not authorize.** A role opening a later
    PR on an already-approved branch does not need a human to have seen
    that PR's specific diff before starting the work — unchanged from
    the PR-scoped model's own "later entries are unaffected" rule
    (below); moving the signal to the issue does not create this, it
    only lets it survive the branch's second PR. What still bounds the
    work is (i) the approved proposal's own stated scope (`files:`,
    "What will be done" / "Out of scope") — a role exceeding it is a
    violation of its own rulebook's scope discipline, not something this
    gate checks mechanically — and (ii) the merge decision on every PR,
    unconditional and separate from the Approve, where the human reviews
    the actual diff before accepting it. The Approve authorizes doing
    the work; the merge accepts its result — that division, not a second
    approval, is this contract's answer to a changed artifact needing a
    fresh look.

    **Revocation.** Deleting or editing the `APPROVE issue-<n>/<role>`
    comment away ends the authorization for any gate check after that
    point (unchanged from the PR-comment model, re-anchored to the
    issue). Closing the issue ends it unconditionally and independently
    of the comment — mechanically, not just as a stated norm: the gate
    checks the issue's open/closed state before either approval path
    (see `core/hooks/approval-gate.sh`), so a closed issue denies
    phase-2 work of any kind regardless of any standing comment or PR
    review.

    A role recording provenance for this signal must cite the issue
    comment (its URL or comment id), never a PR — a PR comment is never
    approval provenance for the single-account path.
  - Any other comment is feedback on the proposal — revise and push to
    the same PR. A close is refusal. Nothing else — no free-text
    comment, no reaction, no bot Approve — opens phase 2. When the
    comment a role session's own approval check surfaces is itself
    approval-shaped but fails this test — a near-match on the exact
    string, or an affirmative-sounding comment, from a listed or
    unlisted account — the role session must, beyond not treating it as
    approval, state that fact plainly once (not repeatedly), in its
    reply or its record: the human learns of the near-miss from the
    session that actually read the comment, rather than depending
    solely on an external orchestrator noticing the same event
    separately. This is complementary to, not a replacement for, any
    warn duty a spawning orchestrator carries under its own rulebook.
- **Phase 2 — execute.** Only after the Approve does the role perform its
  actual work (code to `src/`, tests to `test/`, its record and report
  documents) on the same branch, reported through the same PR. Merge of
  the PR is acceptance of the delivered work — the Approve authorizes
  doing the work; the merge accepts its result.
- **`loop_state: scope-proposed` / `scope-approved`.** The scope states
  map onto the phases: `scope-proposed` in the proposal's own frontmatter
  when phase 1 is submitted, `scope-approved` once one of the two Approve
  signals above exists on the PR — recorded then in the role's record,
  whose first write is itself phase-2 work. The Approve signal is the
  authority; any `loop_state` write is its bookkeeping, never the other
  way around.
- **What the gate blocks, mechanically.** The execution surface is `src/`,
  `test/`, and everything under `docs/issue-<n>/` EXCEPT the two phase-1
  homes — `proposals/**` and the role's own research subtree
  `reports/<role>/**`. A role session's writes to that surface are refused
  while its `issue-<n>/<role>` PR lacks one of the two Approve signals
  above — including while no PR exists at all, which is what makes "open
  the proposal PR first" enforced rather than customary. The record file
  `reports/<role>.md` is on the execution surface: a document-producing
  role's deliverable waits for the Approve exactly as code does.
- **Later entries are unaffected.** The precondition binds a role's first
  entry into execution on a subject. A later role-entry on a subject whose
  PR already carries the Approve — a fix for a finding, a qa regression —
  proceeds
  without re-clearing this gate, unless the human has since dismissed the
  approving review or deleted/edited away the approving comment.
- **Never self-served.** No role approves, merges, or relays an approval.
  Agent accounts are not listed in `approvers.md`, so neither their
  reviews nor their `APPROVE issue-<n>/<role>` comments can satisfy this
  gate — the exclusion is mechanical, not behavioral.
- **Unattended runs.** A run with no human present does not skip this
  gate and does not let the working role decide. The PR waits for the
  human. The v2 judge-session mechanism (an independent no-tools session
  returning APPROVE/REFUSE/HOLD) is retired along with the token layer;
  if a future unattended mode needs a substitute approver, it must be
  specified as its own proposal — until then, unattended means the
  pipeline pauses at every human seat. **The four decisions section 8
  reserves for the human's seat — scope approval among them — are never
  delegated.**

## 20. Per-role record minimum content

Every role record (`docs/issue-<n>/reports/<role>.md`, per section
11) must, at every point it is read by another role or a human, contain
enough for a next reader to pick the work up cold. This section makes that
requirement explicit rather than leaving it implicit in section 18 gate B's
after-the-fact measurement.

A role record must state, at minimum:

1. **What was done** — the concrete work this record's role performed for
   the subject.
2. **Why** — including the alternative considered and why it was not taken,
   whenever the role made a real choice (not required when there was no
   choice to make).
3. **The concrete basis the next reader needs to continue** — the upstream
   commit sha or record path this record's conclusions rest on, this
   record's own current `loop_state`, and any open (unresolved) `finding`
   entries touching this subject.

Additionally, whenever the role leaves work open, the record must state:

4. **A next-steps backlog** — what a continuer should do next, concrete
   enough to act on without re-deriving it from scratch.
5. **An open-finding resolution path** — for any open finding or advisory
   the role is aware of touching this subject, the intended resolution path
   or who owns resolving it, not just the fact that it is open.

This is a minimum, not a template — role-specific required fields (section
2's table) are additional, not replaced by this list. This section pairs
with section 18 gate B: gate B measures, after a round, whether a
zero-context reader can reconstruct and continue from the records alone;
this section is what each role does at write time so that measurement
passes instead of failing on records that only show completion, not basis.

## 21. Document placement beyond the role record

The role record (section 11) is the subject-scoped work trail; it is not
the only place durable project knowledge belongs. In the target project's
own `docs/`, a role that produces one of the following must file it at the
stated location instead of folding it into the role record. Section 11's
"Section 21 grant" paragraph is what gives each role write-ownership of the
file it authors here — this section states the obligation, that paragraph
grants the ownership it requires:

- **A hard-to-reverse choice** — a library, file format, schema, protocol,
  storage engine, or interface picked over a named alternative, or any
  change to a public/on-disk/wire shape — goes in
  `docs/decisions/<date>-<slug>.md`, stating what was chosen, over what
  alternative, and why.
- **A measurement, benchmark, test run, or investigation** that produced
  numbers or findings goes in `docs/reports/<date>-<slug>.md`, stating what
  was run, what came back, and what it means.
- **System design tied to the code** goes in `docs/specs/`.
- **An operational surface change** — a role that introduces or changes an
  environment variable, a config key, a dependency, a migration, or a
  run/setup/deploy step in the target project — must create or update
  `docs/handbooks/<component>.md`: what it is, what it defaults to, what
  breaks without it, and the concrete commands to install, run, and operate
  the deliverable (not only how to test it).

  **Deriving `<component>`.** Mirroring section 9's `subject` derivation,
  `<component>` is not asked-for but derived, deterministically, from the
  artifact being changed: it is the name of the module, service, or
  config-area that owns the operational surface being touched — e.g. the
  directory or package containing the env var's consuming code, the
  dependency's declaring manifest (service directory for a per-service
  manifest, repo root for a repo-wide one), the migration's target
  service/database, or the run/setup/deploy step's script or workflow
  directory. Use that owning directory's own name (its `package.json`/
  `pyproject.toml` name field, or failing that its directory basename) as
  the slug, lowercased and hyphenated. Because the slug is read off the
  surface's owning location rather than chosen by the role, two roles
  independently changing the same logical surface derive the same slug.

  **Search before write.** Before creating `docs/handbooks/<component>.md`,
  a role must search `docs/handbooks/*` for a handbook already filed under
  the derived `<component>` slug (or an evident naming variant of it) and,
  if found, update that existing file in place rather than creating a new
  one — mirroring section 9's search-before-mint discipline for `subject`.
  Skipping this search is what would split one component's operational
  surface into multiple never-converging handbook files.

  A handbook is a living current-state doc, not a write-once record, so
  section 11's "Section 21 grant" single-author ownership does not apply to
  it. Instead, section 11 grants `docs/handbooks/<component>.md`
  component-scoped shared-write ownership: any role that changes that
  component's operational surface may create or update that component's
  handbook, keyed to the component rather than to whichever role authored
  it first — explicitly distinct from the per-role write-once record
  ownership, which stays single-author unchanged.

  **Write-time maintenance.** The role that changes a component's
  operational surface must update that component's handbook in the same
  unit of work that made the change (same-turn-sync), not on a separate
  entry. This resolves the living-doc-vs-single-author-ownership
  contradiction: last change wins as current state, and the surface-changer
  owns the update, so no handbook is ever asserted-current-but-unmaintained.

The role record links to these documents rather than duplicating their
content — the record stays the per-role trail (what this role did, why,
and where to look next); the decision/report/spec is the durable artifact
future work depends on. This is the target project's own obligation,
stated here in the contract body so it holds without any external
doc-classification hook installed on the agents doing the work — the
pre-work approval gate (section 19) and this placement rule are both
contract-internal now, not dependent on host tooling the spawned agents do
not carry.

## 22. Headless execution: delegation requires same-turn consumption

A role session invoked headless/single-shot — `claude -p` and equivalent
non-interactive invocations, where no human is present to notice an idle
wait and no later turn exists for an async completion notification to
land in — must not end its turn having delegated work (any `Agent`/`Task`-
style subagent dispatch, backgrounded or not) whose result it has not yet
consumed within that same turn. Delegating and then narrating that the
turn will wait for a completion notification is the failure this section
closes: the process exits once its own main loop is idle, the delegated
worker's output may land on disk with no session left to commit it, and
the outcome is `failed-no-commit` — not a crash, and not distinguishable
from success in either dispatched agent's own result record
(`repo-status-board` issue #29 phase 2 is the incident this section
answers; `on-the-record` issue #247 is the fuller writeup).

- **The rule.** If delegating, the same turn must wait for the delegated
  result and act on it — through commit, where a commit is the applicable
  action — before the turn ends. If a same-turn wait is not possible (the
  delegated unit cannot report back before the turn's own end), the role
  must not delegate that unit of work at all; it does the work itself, in
  the foreground, inside the turn.
- **Priority over delegation-mandating directives.** This rule takes
  priority over any directive that recommends or mandates delegation —
  naming `freelunch`'s `priority="absolute"` directive specifically,
  since its own text (`freelunch/hooks/freelunch.sh`) instructs
  unconditional background dispatch whenever a turn needs any repo tool
  call ("YES → DELEGATED, always ... never `run_in_background: false`"),
  with no headless-session carve-out. Whenever a role session is running
  headless/single-shot, this section's same-turn-consumption requirement
  is the higher-priority rule: a directive that mandates delegation does
  not authorize ending a turn still waiting on the delegation it caused.
- **Scope.** This section binds headless/single-shot sessions
  specifically. An interactive session has a human present who can notice
  an idle wait and does not exit its process merely because its main loop
  is idle — this section does not restrict delegation behavior there.
- **What this does not do.** This section does not prohibit delegation or
  subagent use outright — only the pattern of delegating and then ending
  the turn still waiting on the result. It does not alter or replace
  `on-the-record`'s own after-the-fact safety net (auto-respawn triggered
  off a `failed-no-commit` verdict, `on-the-record` issue #247/PR #256):
  that mechanism recovers the outcome after the fact; this section is the
  prevention half, stopping a role session from producing that outcome in
  the first place.
