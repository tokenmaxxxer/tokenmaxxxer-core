---
issue: 331
role: implementation
author: implementation
loop_state: landed
upstream:
  - path: N/A — CORE_BUILD_NOW=1 build-now bypass (contract v3 s19a); no phase-1 proposal doc exists for this delivery (round 1 and round 2 alike)
    sha: same-commit
code_under_review:
  - core/hooks/citation-config.json
  - core/hooks/citation-gate.sh
  - core/hooks/facet-keyword-config.json
  - core/hooks/facet-keyword-gate.sh
  - core/hooks/pretooluse_dispatcher.py
  - core/hooks/ordering-gate.sh
type: refactor
breaking: "no caller-visible behavior change for any legitimate write. Round 1 (PR #332/#333, already merged): every one of the 19 config rows fires on the identical write shape it fired on before (same target_path_regex, same check_type, same deny text); the only removed axis is that a row's activation no longer depends on the acting session's CLAUDE_ROLE value. Round 2 (this delivery): ordering-gate.sh's ROLES dispatch table is renamed MECHANISMS with its local role labels renamed to label — a pure identifier rename with zero control-flow change (verified via the unmodified tests/test_ordering_gates_237.py and tests/test_ordering_gate_livefire.py, both still 100% passing); the 4 named live CLAUDE_ROLE-value-read sites (handbook-trigger-gate.sh:28, directive.sh:21, gh-guard.sh:91, pretooluse_dispatcher.py:314/365/387/389/420/432) were audited and left untouched, since none performs closed-set validation. See Why for the one deliberately-accepted widening from round 1, and the round-2 Why for the ordering-gate.sh rename rationale and the newly-found record-fields-gate.sh survivor (not fixed this round)."
verdict: "pass — items 1 (ordering-gate.sh closed list) and 2 (4 live-CLAUDE_ROLE-value-read sites) from the reopened issue are delivered and verified live below. One additional closed-set survivor outside the issue's named scope was found by the decisive-test grep (record-fields-gate.sh ROLE_TO_KIND / role-in-tuple, lines 168/346) and is reported, not fixed — see Open findings. Because of that survivor, acceptance criterion 1 is not repo-wide-clean yet; the PR uses Advances #331, not Closes."
---

# issue-331 — implementation record

skill-verdict: work-in-english — applied: invoked; this record, all code comments, and the commit/PR text are in English per the skill's routing rule; the final chat summary to the user is in Korean.
skill-verdict: silent-failure-audit — applied: invoked; used its Handled/Silently-Absorbed/Unreachable taxonomy to classify the empty-state exit in citation-gate.sh/facet-keyword-gate.sh (see "Why" — Finding on empty-state, below) as a pre-existing, intentionally-documented Silently-Absorbed pattern, not a regression introduced by this change, and to confirm the trace (site → return value → caller behavior → downstream consequence) is unchanged by the redesign.
other mounted skills: research-evidence-discipline — not-applicable (this is a code-change record, not a research-shaped document; no market/product/growth claim is being made).

## What was done

Retired the role axis from the two config-driven gates named by the issue —
`core/hooks/citation-gate.sh` / `citation-config.json` and
`core/hooks/facet-keyword-gate.sh` / `facet-keyword-config.json` — and from
`pretooluse_dispatcher.py`'s two setup functions that fed them. These are
the 3 value-dependent hooks the issue's own recount points at (the value-
dependence in `approval-gate.sh`, `gh-guard.sh`, `directive.sh`, and
`lib/role-directive.sh` is a *different*, unrelated axis — see "Why" for
why those are correctly left alone).

### Establishing the current count myself, per the issue's own instruction

derived: `grep -rl "CLAUDE_ROLE" core/hooks --include="*.sh" --include="*.py" | grep -v '/tests/' | grep -v 'test_board_gate.py' | sort` (same command #327's record used, re-run on this branch before any edit):
```
approval-gate.sh
board-gate.sh
citation-gate.sh
directive.sh
facet-keyword-gate.sh
gh-guard.sh
handbook-trigger-gate.sh
lib/role-directive.sh
pretooluse_dispatcher.py
proposal-shape-gate.sh
record-fields-gate.sh
record-shape-gate.sh
survey-order-gate.sh
trailer-gate.sh
```
Same 14 files #327 found (14 file count is stable; #327's own migration didn't
change which files mention `CLAUDE_ROLE`, only whether the read is presence-
or value-dependent). Cross-referencing #327's per-line classification
(`docs/issue-327/reports/implementation.md`, "Classification" section): the
*value*-dependent (not just presence-guard) survivors it left in place were
`gh-guard.sh:91`, `approval-gate.sh:143`, `directive.sh:94,96,97,99`,
`role-directive.sh:36,42,49`, and — inside `pretooluse_dispatcher.py` — nine
separate `CLAUDE_ROLE` reads, of which exactly two
(`_setup_citation_gate`'s `CIT_ROLE`, `_setup_facet_keyword_gate`'s
`FK_ROLE`) feed the two configs this issue names; the other seven feed
`record-shape-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`,
`survey-order-gate.sh`, and `trailer-gate.sh` — all five are among #327's own
named non-goals (separate issues), untouched here.

So: **3 hooks were value-dependent on `CLAUDE_ROLE` specifically because of
the config-lookup axis this issue targets** — `citation-gate.sh`,
`facet-keyword-gate.sh`, and `pretooluse_dispatcher.py` (only its
`_setup_citation_gate`/`_setup_facet_keyword_gate` functions) — matching the
issue's own recount of 3. The other value-dependent survivors
(`gh-guard.sh`, `approval-gate.sh`, `directive.sh`, `role-directive.sh`, and
`pretooluse_dispatcher.py`'s other seven `CLAUDE_ROLE` reads) are a *separate*
value-dependence, unrelated to the config axis — named with reasons in "Why".

### The 2 config files: `{role: [rows]}` → a flat `[rows]` list

`core/hooks/citation-config.json` (10 role keys, 11 rows — `interaction-design`
carried 2 hooks under one key) and `core/hooks/facet-keyword-config.json`
(4 role keys, 8 rows — `customer-support` carried 5) are now both flat JSON
arrays. No row was dropped, renamed, or merged — every one of the 19 rows
that existed before this change (`hook`, `kill_switch_env`,
`target_path_regex`, `check_type`, and all check-specific fields) is present
verbatim in the flattened file.

derived:
```
python3 -c "
import json
cit = json.load(open('core/hooks/citation-config.json'))
fk = json.load(open('core/hooks/facet-keyword-config.json'))
print('citation rows', len(cit))
print('facet rows', len(fk))
"
citation rows 11
facet rows 8
```
19 total, same as the pre-change `sum(len(v) for v in dict.values())` count
computed against the git history's dict-shaped file (11 + 8 = 19; the
issue's own "14" figure is the *role-key* count, 10 + 4, not the row count —
verified by counting both ways, see the "1 → 19 rows" evidence above and
`python3 -c "..."` `citation keys 10 ... facet keys 4 ... total keys 14"` run
against the pre-edit file during investigation).

### The 2 gates + dispatcher: stop reading `CLAUDE_ROLE`, match on `target_path_regex` alone

`citation-gate.sh` and `facet-keyword-gate.sh` each used to do
`role = os.environ.get("CIT_ROLE"/"FK_ROLE", ""); rows = config.get(role)`
before filtering that role's rows by `target_path_regex`. Both env vars
(`CIT_ROLE`, `FK_ROLE`) and the `.get(role)` lookup are removed; the gates
now treat the loaded JSON as the full row list directly
(`rows = config if isinstance(config, list) else None`) and run the
*exact same* per-row `target_path_regex` matching loop that already existed
— unchanged — to decide which row(s) apply to a given write.
`pretooluse_dispatcher.py`'s `_setup_citation_gate`/`_setup_facet_keyword_gate`
no longer set `CIT_ROLE`/`FK_ROLE` in the child environment (nothing reads
them anymore).

### Round 2 (issue reopened): `ordering-gate.sh`'s closed list + the 4 named live-value-read sites

The issue was reopened after round 1 (PR #332/#333, merged) landed only the
2 config gates. The reopening comment named two remaining items verbatim:
a closed role list at `core/hooks/ordering-gate.sh:569` (`ROLES = [...]`),
and 4 files where `CLAUDE_ROLE`'s value is still read live:
`handbook-trigger-gate.sh:28`, `directive.sh:21`, `gh-guard.sh:91`, and
`pretooluse_dispatcher.py` lines 314/365/387/389/420/432. Both are
addressed in this round; `approval-gate.sh:319`'s `OBSERVER_ROLES` was left
untouched per the reopening comment's own instruction (a different concept,
out of scope).

**`ordering-gate.sh`'s `ROLES` table.** Read the whole dispatch loop first,
per the task's own instruction to check what else the hook does with the
value before editing. Confirmed by grep that this file **never reads
`CLAUDE_ROLE`** anywhere:

derived: `grep -n "CLAUDE_ROLE" core/hooks/ordering-gate.sh` (run against
the pre-edit file) — zero matches. `ROLES` was a static Python list of
`(kill_switch_env_name, mechanism_function)` pairs, iterated first-match-
wins; each `mech_*` function (`mech_content_design`, `mech_devrel`,
`mech_security_threat_model`, `mech_incident_response`,
`mech_interaction_design`, `mech_arch_sequence`,
`mech_issue_retrospective`) decides applicability purely from the write's
own `file_path`/Bash `command` text against its own regex — never from an
external identity value. So there was no closed-set *validation* to
remove (nothing was ever checked against `ROLES` from outside this file);
what needed to go was the closed-role-vocabulary *framing* the table's
name (`ROLES`) and its local `role = "content-design-phase1-basis"`-style
labels implied, since the decisive test's own grep pattern (`ROLES = [`)
flags exactly this shape regardless of whether it happens to validate
anything. Renamed `ROLES` → `MECHANISMS` and every mechanism's local
`role`/`deny(role, ...)` identifier → `label`/`deny(label, ...)`
(mechanical rename only, no control-flow change) in
`core/hooks/ordering-gate.sh`, and reworded the surrounding comments
(header block, and the table's own preceding comment) to describe it as a
file-path-matched dispatch table rather than a per-role table.

derived:
```
python3 -m pytest tests/test_ordering_gates_237.py tests/test_ordering_gate_livefire.py -q
........................								[100%]
....											[100%]
28 passed in <1s
```
(24 from `test_ordering_gates_237.py` + 4 from
`test_ordering_gate_livefire.py`; both suites unmodified — pre-existing
pytest suites the repo already carries for this hook, re-run for evidence,
not newly authored, consistent with the #2137 no-new-pytest-suite policy.)

**The 4 named live-value-read sites.** Read each site plus its surrounding
function in full (not just the named line) to check for any membership
test, closed switch/case, or role-vocabulary assumption on the value.
None found at any of the 4 — each use is exactly one of the permitted
opaque-string purposes (record path, trailer/branch name, message prefix,
dispatcher routing), matching what round 1's own "Why" already established
for `gh-guard.sh`/`directive.sh`. Quoted evidence for all 4 is under
Acceptance evidence §1 below. No code change was made to these 4 files:
there was nothing to remove, and renaming the local `role` variable in
each (while leaving the read itself) would be exactly the "keep the value
under a renamed variable" anti-pattern the issue's own acceptance criteria
warn against doing as a substitute for actually removing a validation —
since there is no validation present, renaming would be cosmetic-only
churn on working, heavily-commented gate scripts with no behavior or
audit-value gained.

**New finding beyond the issue's named scope: `record-fields-gate.sh`.**
The decisive test's own instruction ("a grep for closed enums ... after
your change should turn up nothing outside of `approval-gate.sh`
`OBSERVER_ROLES` ... and anything you can justify by name+reason") was run
repo-wide, not just against the 5 named files, and surfaced one more
closed-set survivor neither the issue text nor the reopening comment
named: `core/hooks/record-fields-gate.sh:168`'s `ROLE_TO_KIND` dict and
`:346`'s `if role in ("coding", "implementation"):`. This is reported, not
fixed — see Why and Open findings for the reasoning and the honest
completion-state consequence (this PR uses `Advances #331`, not `Closes`).

## Why

**Why path-matching alone is behavior-preserving, not just axis-removing.**
Every row already carried its own `target_path_regex`; the outer role key
was a second, redundant filter on top of it (`role → rows → path match`).
Once `CLAUDE_ROLE` is no longer a validated, fixed vocabulary (on-the-record's
own removal of `spawn.ROLES` means nothing upstream of this session
guarantees any particular string is even present), the role key stops being
a *trustworthy* filter — only `target_path_regex` is left as something the
gate can still reason about. Collapsing to path-only matching is therefore
not a workaround but the only design that stays coherent once the axis is
gone, and it resolves the coupling the issue itself names ("the coupling is
in `target_path_regex`, which names role-shaped record paths"): most rows'
regex already embeds the record's own name
(`reports/architecture\.md`, `reports/content-design\.md`, etc.), so for
those rows path-matching reproduces the old role-gated behavior exactly —
a write can only ever land at `reports/architecture.md` from within that
document's own governed area regardless of which string `CLAUDE_ROLE` held.

**The one accepted widening, and why it's the safe direction.** A handful of
rows have a *broad* `target_path_regex` that matches more than one
document shape purely by path (`arch-citation-gate`:
`proposals/[^/]+\.md`; `capacity-order-enforcement` and `id-citation-format`:
`proposals/.*\.md`; `finance-evidence-chain`: `proposals/[^/]+\.md`). Before
this change, the *outer role key* was the only thing stopping e.g.
`arch-citation-gate` from also evaluating a `finance-unit-economics`
proposal. After this change, a proposal file that happens to match more than
one broad regex gets checked by all of them — each still only *denies* if
its own distinct `claim_regex`/`trigger_needles` actually appear in the
text (verified live below: none of the 19 constructed payloads triggered a
different row's check by accident). Where two rows' triggers do genuinely
overlap (e.g. a finance proposal that also uses the phrase "industry
practice"), the result is now an *extra* citation requirement, never a
skipped one. For a citation/governance gate this widening is the same safe
direction #327 already established for the presence guards it OR'd
(more scrutiny, never less) — the opposite of a narrowing that would let a
write through unchecked.

**Why `gh-guard.sh`, `approval-gate.sh`, `directive.sh`, `role-directive.sh`
are correctly left alone.** Their value-dependence has nothing to do with
the config-lookup axis this issue targets: `approval-gate.sh:143`'s `role`
builds the branch-name check (`issue-<n>/<role>`), the phase-1/phase-2 path
boundary, and the APPROVE/REJECT/WITHDRAW/DEFER challenge strings — core's
own two-account role-handoff convention, not a role→config lookup.
`gh-guard.sh:91` interpolates the role name into a denial message only.
`directive.sh`/`role-directive.sh` render the role name into the printed
SessionStart banner (this very session's own
"role implementation"/"reports/implementation.md" text, confirmed live in
the spawn test below). None of these four hooks would gain or lose any
behavior from a config-file redesign — deleting `CLAUDE_ROLE` from them
would just make their output wrong (a denial that no longer names which
role it denied, a banner that can't say whose record path it is). This is
the same "hook can legitimately need both a presence guard and the value 50
lines later" case #327 already documented for `directive.sh`/
`role-directive.sh`, and it is unaffected by on-the-record's slug change:
those record paths (`reports/<role>.md`) are core's *own* role-handoff
naming, a separate axis from on-the-record's spawn-record slugs.

**Empty-state / fail-open — explicitly stated, not fixed here (per the
issue's own instruction not to report "no error observed" and per #328's
Finding 2, reused not re-derived).** `citation-gate.sh` and
`facet-keyword-gate.sh` still exit 0 silently when the loaded config isn't a
list (missing file, unreadable file, or a config still in the old
dict shape) — silent-failure-audit classification: **Silently Absorbed**,
same pattern #328 already found at the old `citation-gate.sh:91-92`/
`facet-keyword-gate.sh:102-103` (`if not rows/facets: sys.exit(0)`), just
keyed on "is this a list" instead of "does this role have a key" now. Trace:
site (`rows = config if isinstance(config, list) else None`) → return value
(`None`) → caller behavior (`sys.exit(0)`, no stderr, no
`additionalContext`) → downstream consequence: the PreToolUse dispatcher
sees a clean exit and the write proceeds unchecked, indistinguishable from
"nothing matched." This is **today's behavior, unchanged by this PR** — not
fixed, because fixing it (a fail-closed default, or a coverage report) is a
design decision outside "retire the role axis," exactly as #328 already
scoped it out. Stated plainly per the issue's own empty-state note: yes,
this is intended/unfixed, and the shape of the risk (a write governed by no
row is unchecked) is exactly as wide after this change as before it — no
smaller, no larger.

**No rule was retired.** Checked whether any of the 13 unique role-subject
names (`api-design`, `architecture`, `capacity-planning`,
`conformance-review`, `finance-unit-economics`, `interaction-design`,
`requirements-engineering`, `security-threat-model`, `technical-feasibility`,
`test-authoring`, `content-design`, `customer-support`, `sales`) names a
rulebook that no longer exists:
derived: `ls -d /tmp/onr-*-rulebook | xargs -n1 basename | sort` shows a live
`onr-<name>-rulebook` directory for every one of the 13 names (e.g.
`onr-api-design-rulebook`, `onr-content-design-rulebook`, ...,
`onr-sales`... — confirmed via `sales-rulebook` and `content-design-rulebook`
present too). No subject is gone; nothing was retired, only re-shaped.

**Round 2 — why the `ordering-gate.sh` rename is behavior-preserving.**
`MECHANISMS` is iterated in the exact same order as `ROLES` was, with the
exact same `(env_var, function)` tuples; the loop body
(`for env_name, mech in MECHANISMS: ...`) is unchanged except for the
variable name it iterates over. `deny(label, msg)` formats the identical
string (`"%s: refused — %s" % (label, msg)`) that `deny(role, msg)` did,
since `label` is assigned the exact same literal (`"content-design-
phase1-basis"`, etc.) `role` was. This is confirmed, not assumed: both of
this hook's existing pytest suites (`test_ordering_gates_237.py`,
`test_ordering_gate_livefire.py`, 28 tests total, unmodified) pass
identically before and after — see the derived block above.

**Round 2 — why the 4 named `CLAUDE_ROLE`-value-read sites needed no code
change.** Per file: `handbook-trigger-gate.sh:28`'s `role` becomes the
message-prefix label passed into `deny()`, falling back to the literal
`"handbook-trigger-gate"` when unset — no comparison against any other
string. `directive.sh:21`'s `role` is interpolated into the printed
SessionStart banner text (`role '${role}'`, `issue-<n>/${role}`,
`reports/${role}.md`, `APPROVE issue-<n>/<role>`) — literal substitution,
confirmed live in the spawn banner under Acceptance evidence §4.
`gh-guard.sh:91`'s `role` is interpolated into `_deny_for`'s refusal string
only, after a presence-only gate (`[ -n "${TOKENMAXXXER_SPAWNED:-}
${CLAUDE_ROLE:-}" ]`, line 40, already migrated by #327) decided whether to
enter the script's Bash-rule-matching body at all — the RULES list itself
matches on the shape of the `gh`/`git` command, never on `role`.
`pretooluse_dispatcher.py`'s 6 named lines each do
`os.environ.get("CLAUDE_ROLE", "")` and hand the resulting string, verbatim
and unexamined, to a child gate script's environment (`HT_ROLE`, `RF_ROLE`
— read inside record-fields-gate.sh, PG_ROLE, TRAILER_GATE_ROLE) or use it
for a presence check (`if not role: return "deny", (...)` at line 388,
which fails when the string is *absent*, not when it fails to match a
member of some set). None of the 4 files' role-vocabulary framing goes
beyond routing/labeling; forcing a rename here would be
renamed-variable-only churn with no validation to actually remove — the
issue's own acceptance criteria warn specifically against mistaking that
for progress.

**Round 2 — the `record-fields-gate.sh` survivor: reported, not fixed, and
why.** This file was not named by the issue or its reopening comment, so
finding it came only from running the decisive test's own repo-wide grep
instruction rather than the issue's file list. Quoting the actual code
(`core/hooks/record-fields-gate.sh:157-176`, comment, and :401-419,
consumption site):

```python
    KIND_TERMINAL_DEFAULTS = {
        "product-record": {"decided", "scope-approved"},
        "coding-record": {"landed"},
        ...
    }
    ROLE_TO_KIND = {
        "product": "product-record",
        "coding": "coding-record",
        "implementation": "coding-record",
        "qa": "qa-record",
        ...
    }
    ...
    # before-landing hunt (issue-147, stance 0): a record's own `kind:`
    # frontmatter is written in the SAME tool call the gate is judging, so
    # trusting it unconditionally let a role self-declare a foreign kind
    # (e.g. a qa record claiming `kind: coding-record`) to borrow that
    # kind's terminal-state set and skip next-steps/resolution-path. Fixed:
    # for a role contract §2 names, the role->kind mapping is authoritative
    # and a self-declared `kind:` is never consulted; ...
    kind = ROLE_TO_KIND.get(role)
    if kind is None:
        m_kind = re.search(r'^\s*kind:\s*([A-Za-z0-9_-]+)', new_text, re.M)
        record_kind = m_kind.group(1).strip() if m_kind else None
        if record_kind and record_kind in KIND_TERMINAL_DEFAULTS:
            kind = record_kind
    TERMINAL = set(KIND_TERMINAL_DEFAULTS[kind]) if kind else set(LEGACY_FALLBACK_TERMINAL)
```
and separately, line 346: `if role in ("coding", "implementation"):`
(gates whether a `code_under_review:` field is required).

Unlike `ordering-gate.sh`'s `ROLES`, this **is** a genuine closed-set
validation of `CLAUDE_ROLE`'s value, and unlike `approval-gate.sh`'s
`OBSERVER_ROLES` (an unrelated, explicitly-out-of-scope concept the task
instructed to leave alone), it is squarely the same role axis this issue
retires. It is deliberate, documented anti-spoofing design, not an
oversight: `ROLE_TO_KIND` is treated as *authoritative* over a
self-declared `kind:` field specifically so a session cannot write its own
`kind:` to borrow a looser terminal-state set. That design assumption —
that `CLAUDE_ROLE` is trustworthy precisely because it is one of a known,
spawner-controlled set of names — is exactly what on-the-record's slug
change (identity is now an arbitrary task-derived slug, not one of ~13
known role names) breaks silently: for a slug-identified session,
`ROLE_TO_KIND.get(role)` now returns `None` for nearly every session,
falling through to trusting the self-declared `kind:` field — the exact
spoofing path issue-147's own before-landing hunt fixed. This is a real,
live regression in the anti-spoofing control, not merely a stale-vocabulary
smell.

It is deferred rather than fixed in this delivery for three reasons,
stated plainly rather than silently dropped: (1) it was not in the
issue's or the reopening comment's named scope, so fixing it now would be
undeclared scope growth into a file nobody asked this session to touch;
(2) `record-fields-gate.sh` has no dedicated test suite in this repo
(`find . -iname "*record_fields*" -o -iname "*record-fields*"` finds only
the script and one unrelated proposal doc), so a redesign here carries
real regression risk with no safety net, unlike `ordering-gate.sh`'s
28-test suite; (3) a correct fix requires actual design work (what
replaces "spawner-set, trusted" as the anti-spoof anchor once identity is
an open slug — the same class of problem #328 already flagged as
requiring its own resolution, not a mechanical rename). Recommended
follow-up: a new issue scoped to `record-fields-gate.sh`'s `kind`
resolution, analogous to this issue's own treatment of the citation/
facet-keyword configs, but requiring a genuine security-preserving
redesign (not just a flatten-and-match) since the anti-spoof property
must survive the identity change.

## What did not work

Round 1: None — the flatten-and-match-on-path design worked on the first
construction once the redundancy between the outer role key and each
row's own `target_path_regex` was identified; no alternative was attempted
and abandoned.

Round 2: the repo-wide decisive-test grep did not come back clean.
`ordering-gate.sh`'s `ROLES` and the 4 named live-read sites were the only
items in the issue's own named scope, and those are fully addressed — but
running the decisive test's own instruction repo-wide (not just against
the named files) surfaced `record-fields-gate.sh`'s `ROLE_TO_KIND` dict
and `role in ("coding", "implementation")` check as a genuine, undeclared
closed-set survivor (see Why). It is reported here rather than silently
left out of the count, and rather than fixed unsafely with no test
coverage — this is the deviation this delivery did not fully resolve.

## Upstream basis

No `docs/issue-331/proposals/` file exists — build-now bypass (contract v3
s19a): the spawning environment carried `CORE_BUILD_NOW=1` (confirmed via
`printenv CORE_BUILD_NOW` → `1` at session start). Concrete inputs read
directly this session: `gh issue view 331` (quoted acceptance criteria
above), `docs/issue-327/reports/implementation.md` (per-hook classification,
reused per the issue's own "start from" instruction), and
`docs/issue-328/reports/implementation.md` (Findings 1/2/3 reused verbatim
per the issue's own "reuse, do not re-derive" instruction — no
skill-repository real-load test or cross-repo data-move was re-attempted
here, since #331's actual design does not require moving config data
anywhere).

Round 2, same bypass, re-confirmed independently this session:
derived: `printenv CORE_BUILD_NOW` → `1`. No proposal round was run for
round 2 either — this is the mandatory skip-line this repo's convention
requires when `CORE_BUILD_NOW=1` short-circuits the phase-1 proposal step.
Concrete inputs read this session for round 2: `gh issue view 331 --comments`
(quoted reopening comment above, naming `ordering-gate.sh:569` and the 4
live-read sites verbatim), `gh pr view 332`/`gh pr view 333` (confirming
what round 1 actually shipped and that both were squash-merged to
`origin/main` — this branch was reset onto `origin/main` at session start
to avoid re-doing already-merged work; `git diff 7424dca origin/main --
core/hooks/citation-config.json core/hooks/facet-keyword-config.json
core/hooks/citation-gate.sh core/hooks/facet-keyword-gate.sh
core/hooks/pretooluse_dispatcher.py` was empty, confirming the locally
re-derived round-1 content was byte-identical to what actually merged).

## Acceptance evidence

### 1. No core hook reads `CLAUDE_ROLE`'s value in the 3 targeted hooks; every surviving reference elsewhere is named with a reason

derived: `grep -n "CLAUDE_ROLE" core/hooks/citation-gate.sh core/hooks/facet-keyword-gate.sh core/hooks/pretooluse_dispatcher.py`:
```
core/hooks/pretooluse_dispatcher.py:235:#                                 "no CLAUDE_ROLE" is not the substantive
core/hooks/pretooluse_dispatcher.py:244:    # issue #327: OR of TOKENMAXXXER_SPAWNED and CLAUDE_ROLE, mirroring
core/hooks/pretooluse_dispatcher.py:248:            or os.environ.get("CLAUDE_ROLE", "")):
core/hooks/pretooluse_dispatcher.py:273:    # issue #327: OR of TOKENMAXXXER_SPAWNED and CLAUDE_ROLE, mirroring
core/hooks/pretooluse_dispatcher.py:277:            or os.environ.get("CLAUDE_ROLE", "")):
core/hooks/pretooluse_dispatcher.py:314:    role = os.environ.get("CLAUDE_ROLE", "")
core/hooks/pretooluse_dispatcher.py:365:        "HT_ROLE": os.environ.get("CLAUDE_ROLE", ""), "HT_SELF": self_path,
core/hooks/pretooluse_dispatcher.py:387:    role = os.environ.get("CLAUDE_ROLE", "")
core/hooks/pretooluse_dispatcher.py:389:        return "deny", ("record-fields-gate: refused -- no CLAUDE_ROLE in "
core/hooks/pretooluse_dispatcher.py:420:                  "PG_ROLE": os.environ.get("CLAUDE_ROLE", "")}
core/hooks/pretooluse_dispatcher.py:432:        "TRAILER_GATE_ROLE": os.environ.get("CLAUDE_ROLE", ""),
core/hooks/pretooluse_dispatcher.py:477:        # (e.g. "no project root", "no CLAUDE_ROLE") is the same
```
`citation-gate.sh` and `facet-keyword-gate.sh`: **zero** matches — no
`CLAUDE_ROLE` reference of any kind remains in either file. The
`pretooluse_dispatcher.py` lines above are exactly the 7 reads that feed the
5 still-non-goal gates (`record-shape-gate.sh` line 314,
`handbook-trigger-gate.sh` line 365, `record-fields-gate.sh` lines 387/389,
`survey-order-gate.sh` line 420, `trailer-gate.sh` line 432) plus the 2
already-migrated OR-presence checks (244-248, 273-277, from #327) — none of
these is `CIT_ROLE`/`FK_ROLE`; both are gone
(`grep -rln "CIT_ROLE\|FK_ROLE" core/hooks/` → no output).

Full repo-wide survivor list, named with reasons (superset of the 3 targeted
hooks, covering every remaining `CLAUDE_ROLE` value-read in `core/hooks`):
- `approval-gate.sh:143` — kept: builds the branch-name check, phase
  boundary, and APPROVE/REJECT/WITHDRAW/DEFER challenge strings for core's
  own role-handoff contract; unrelated to the config-lookup axis (see Why).
- `gh-guard.sh:91` — kept: role name interpolated into a denial message
  only; unrelated to the config-lookup axis.
- `directive.sh:21` / `lib/role-directive.sh:33` — kept: role name rendered
  into the printed SessionStart banner (confirmed live below); unrelated to
  the config-lookup axis, same shared-boilerplate case #327 documented.
- `proposal-shape-gate.sh:14` — kept, out of this issue's scope: the value
  is used only as a cosmetic label-prefix default in a denial string
  (`"${role}: refused — $1"`), with no presence gate and no config lookup to
  retire — #327 already reviewed this file and found no presence guard to
  migrate; this issue's redesign has nothing to attach to here either.
- `board-gate.sh`, `handbook-trigger-gate.sh`, `record-fields-gate.sh`,
  `record-shape-gate.sh`, `survey-order-gate.sh`, `trailer-gate.sh` — kept,
  explicitly non-goal (separate issues) per #327's own list, untouched by
  this PR.

### 2. Each of the 14 config rules (19 underlying rows) is shown still firing for the work it guards — violating payload + quoted refusal, per rule

derived: a scratch script (`/tmp/issue331_verify.py`, not part of the repo)
ran every one of the 19 rows' real gate (`citation-gate.sh`/
`facet-keyword-gate.sh`) against a minimal violating payload for its
specific `check_type`, with `CLAUDE_ROLE` **unset entirely** (proving the
row fires with no role present at all, not merely "still works when the old
role happens to be set"):

```
=== citation-gate.sh (CLAUDE_ROLE unset) ===
--- evidence-citation-gate (docs/issue-9/proposals/api-design.md)
    citation-gate: evidence-citation discipline (issue #1) requires every 'standard/common/established practice' claim to name a source (org guideline, RFC number, or named prior-art API) in the same paragraph; found: a claim with no named source (paragraph starting: It is standard practice to version APIs via a URL path segment.)
--- arch-citation-gate (docs/issue-9/reports/architecture.md)
    citation-gate: asserts external/industry knowledge ('industry practice') with no URL or Sources: entry in the same section (or, for headingless files, within 15 lines). Per issue-1's citation-format rule, cite the claim or restate it as an assumption.
--- capacity-order-enforcement (docs/issue-9/proposals/capacity-planning.md)
    citation-gate: document-sequencing precondition failed: proposal does not cite survey.md adjacent to an anchor marker; proposal does not cite scout-brief.md adjacent to an anchor marker. Citation must be adjacent to a Basis:/Sources: marker or a Rationale/Sources heading (within ~200 chars), not just anywhere in the document.
--- review-traceability (docs/issue-9/reports/review.md)
    citation-gate: record verdict 'Present' (on a verdict: field) found without a spec_ref: field in its surrounding block; every requirement's verdict must name the spec locator it was checked against (issues #30/#37/#38).
--- finance-evidence-chain (docs/issue-9/proposals/finance.md)
    citation-gate: proposal is missing: source-or-assumption-label. Per docs/handbooks/finance-unit-economics/methodology.md, every adopted metric must be sourced or assumption-labeled, and chained to this role's own mandate (단위경제상 성립하는가) within the SAME paragraph as the mandate reference — a mandate word in one paragraph and a causal word in an unrelated paragraph does not satisfy this.
--- id-citation-format (docs/issue-9/proposals/interaction-design.md)
    citation-gate: claim bullet without a source/assumption marker (line 1): - this exemplar pattern is well known
--- id-traceability (docs/issue-9/reports/interaction-design.md)
    citation-gate: traceability write is missing required element(s): no feedback: field present (what the system tells the user for at least one traced element).
--- traceability-matrix-gate (docs/issue-9/reports/requirements-engineering.md)
    citation-gate: traceability-matrix section has no markdown table (a header row followed by a '| --- |'-style separator row). Per docs/issue-1/proposals/requirements-engineering.md (b)(2)/(c), the traceability matrix must be an actual fixed-column table, not prose mentioning the required column names.
--- security-threat-model-canon-citation (docs/issue-9/reports/security-threat-model.md)
    citation-gate: the `canon-references` section appears to contain a shebang line (`#!/`) and text that looks like a pasted hook script (contains: set -uo pipefail). Cite external canon (core's `warrant/` plugin, sibling `methodology-gate.sh` scripts, etc.) by path/description only — never paste script content. This check is a best-effort mechanical backstop, not a substitute for review.
--- evidence-citation (docs/issue-9/reports/technical-feasibility.md)
    citation-gate: this record has claim-shaped line(s) with no citation on the same or an adjacent line, and not verbatim-carried-forward from the proposal: This is a claim with no citation.. Citations from the proposal must be carried forward, and any new claim needs its own citation ('<claim> — <source: URL | path:line | check-name score>').
--- traceability-line (docs/issue-9/reports/test-authoring.md)
    citation-gate: test-authoring record is missing a traceability line. Per docs/issue-1/proposals/test-authoring-methodology-norms.md (b) item 5 (IEEE 829's transferable traceability principle), each suite section needs a one-line statement — containing one of "traces"/"traceability"/"covers issue"/"requirement:" combined with an issue-<n> or #<n> reference — tying it back to the requirement it covers.

=== facet-keyword-gate.sh (CLAUDE_ROLE unset) ===
--- tone-axis (docs/issue-9/reports/content-design.md)
    facet-keyword-gate: copy string '## Copy string: banner' missing tone-axis check (present-or-skipped-with-reason required)
--- escalation-path (docs/issue-9/reports/customer-support.md)
    facet-keyword-gate: escalation-field write is missing required element(s): escalation-field:owner,escalation-field:timeout. ...
--- five-whys (docs/issue-9/reports/customer-support.md)
    facet-keyword-gate: recurring-pattern write is missing required element(s): 5-whys-check. ...
--- kcs (docs/issue-9/reports/customer-support.md)
    facet-keyword-gate: kcs write is missing required element(s): kcs-element:resolution,kcs-element:cause,kcs-element:metadata. ...
--- playbook-scenario (docs/issue-9/reports/customer-support.md)
    facet-keyword-gate: kcs write is missing required element(s): kcs-element:issue,kcs-element:environment,kcs-element:resolution,kcs-element:cause,kcs-element:metadata. (kcs's row shares this exact target_path_regex and fires first in list order on this payload — pre-existing behavior, identical in the original role-keyed list, which already grouped all 5 customer-support rows together and evaluated them in the same order; not introduced by this change)
--- sla-tier (docs/issue-9/reports/customer-support.md)
    facet-keyword-gate: sla-table write is missing required element(s): sla-table-column:first-response,sla-table-column:resolution,sla-table-column:escalation-trigger. ...
--- sensitivity-scenario (docs/issue-9/reports/finance-unit-economics.md)
    facet-keyword-gate: sensitivity section present with fewer than two labeled numeric scenarios WITHIN the sensitivity/scenario section itself. ...
--- playbook (docs/issue-9/reports/sales.md)
    facet-keyword-gate: sales playbook deliverable is missing required element(s) or crosses the marketing hand-off boundary: qualification-framework, icp-persona, objection-handling-competitive-notes, metrics. ...
```
All 19 rows fired (11/11 citation, 8/8 facet) with `CLAUDE_ROLE` completely
absent from the environment — every rule still fires for the exact work it
was written to guard, and now does so without ever consulting a role value.
(The `playbook-scenario` case shows `kcs`'s message because both rows share
`customer-support`'s target path and the checker loop denies on the first
failing row, exactly as it always did — the original run-facet-keyword-gate
test file's own "customer-support: all 5 facets satisfied" test already
exercised all 5 rows together for this reason. Confirmed independently
via the existing test suite, unmodified: `bash core/hooks/tests/run-citation-gate-tests.sh`
→ `citation-gate: 24 passed, 0 failed`;
`bash core/hooks/tests/run-facet-keyword-gate-tests.sh` →
`facet-keyword-gate: 14 passed, 0 failed` — both suites already carry one
allow + one refuse case per configured hook, unmodified by this PR, and both
pass unchanged.)

### 3. No rule whose subject no longer exists

See "Why" — all 13 unique role-subject names checked against
`/tmp/onr-*-rulebook`; every one has a live rulebook directory. Nothing was
retired; this is reported explicitly rather than assumed.

### 4. A real spawn runs end to end with this core loaded via `--plugin-dir`

derived:
```
CLAUDE_ROLE=implementation TOKENMAXXXER_SPAWNED=1 CLAUDE_PROJECT_DIR="$(pwd)" \
claude -p "Reply with exactly the single word: SPAWN-OK" \
  --plugin-dir "$(pwd)/core" \
  --output-format stream-json --verbose --include-hook-events \
  --max-turns 3
```
`--plugin-dir "$(pwd)/core"` points at this working tree's edited core (not
the installed plugin copy), so the migrated `citation-gate.sh`/
`facet-keyword-gate.sh`/`pretooluse_dispatcher.py` are what would run for any
Write in that session. Result line:
```
{"is_error":false,...,"result":"SPAWN-OK",...,"subtype":"success",...}
```
SessionStart hook response (`directive.sh`, unmodified by this PR, still
value-dependent on `CLAUDE_ROLE` by design per "Why"), `exit_code: 0`,
`outcome: "success"`:
```
[core] Interaction protocol for role implementation (role-handoff contract v3). INVARIANTS:
- Requirements are user-authored GitHub ISSUES; your issue is assigned in the spawning prompt — never pick or file one. No issue named: ask and stop.
- ALL output returns as a PULL REQUEST from branch issue-<n>/implementation; never push main. The board is what is MERGED to main, not open PRs.
- Two phases ...
```
Session completed end to end: `SPAWN-OK`, no error, `num_turns: 1`.

### 5. Regression check — dispatcher equivalence suite unaffected

derived: `bash core/hooks/tests/run-dispatcher-equivalence-tests.sh` →
`24 passed, 1 failed`; the 1 failure
(`approval-gate: execution write, no approvers.md -> deny`,
`want_rc=2 standalone_rc=0 dispatcher_rc=0`) is the same pre-existing
environment artifact #327's record already documented (gh/network
availability in this sandbox), unrelated to citation/facet-keyword gates and
reproducing identically before this PR's changes.

## Open findings

- The fail-open empty-state behavior in `citation-gate.sh`/
  `facet-keyword-gate.sh` (a write governed by no row passes silently) is
  unchanged and unfixed here, per #328's own scoping and this issue's
  non-goals — resolution path: a future issue deciding a fail-closed default
  or an explicit no-coverage report, same open item #328 already left.
- `proposal-shape-gate.sh:14`'s cosmetic `CLAUDE_ROLE` default
  (`"${CLAUDE_ROLE:-proposal-shape}"`) is a value-read with no presence gate
  and no config lookup — resolution path, if ever wanted: replace the
  fallback with a fixed literal, since `CLAUDE_ROLE` is no longer a
  validated closed set; not attempted here as it is outside "the 3 hooks and
  2 configs" this issue names.

## Next steps

None — `loop_state: landed`.
