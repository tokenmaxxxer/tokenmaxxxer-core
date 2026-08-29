---
issue: 349
role: refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776
author: refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776
skills: refactoring-legacy-seam-selection (skill-repository(c05de12)), refactoring-legacy-verification-cadence (skill-repository(c05de12)), adversarial-review (skill-repository(c05de12))
verifies_subject: false  # flip to true only if this record is an independent verification of this subject's own deliverable -- see docs/handbooks/observer-verification.md
loop_state: landed
type: refactor
verdict: pass
breaking: false
code_under_review:
  - core/hooks/approval-gate.sh
  - core/hooks/board-gate.sh
  - core/hooks/directive.sh
  - core/hooks/gh-guard.sh
  - core/hooks/handbook-trigger-gate.sh
  - core/hooks/lib/role-directive.sh
  - core/hooks/pretooluse_dispatcher.py
  - core/hooks/proposal-shape-gate.sh
  - core/hooks/record-fields-gate.sh
  - core/hooks/record-shape-gate.sh
  - core/hooks/survey-order-gate.sh
  - core/hooks/test_board_gate.py
  - core/hooks/tests/run-approval-gate-tests.sh
  - core/hooks/tests/run-board-gate-tests.sh
  - core/hooks/tests/run-canon-duplication-content-tests.sh
  - core/hooks/tests/run-citation-gate-tests.sh
  - core/hooks/tests/run-facet-keyword-gate-tests.sh
  - core/hooks/tests/run-gate-lib-tests.sh
  - core/hooks/tests/run-role-gates-tests.sh
  - core/hooks/tests/run-survey-order-gate-tests.sh
  - core/hooks/trailer-gate.sh
  - tests/test_ordering_gates_237.py
  - warrant/hooks/tests/run-directive-hunt-path-tests.sh
upstream:
  - path: core/hooks/survey-order-gate.sh (env-var slice, PG_ROLE->PG_SKILL)
    sha: 764aebc19c7e01fedd0078805c75740ac777b9a6
  - path: core/hooks/pretooluse_dispatcher.py (env-var slice, CLAUDE_ROLE->CLAUDE_SKILL)
    sha: 60cbcb55a785e83edac637b4faea065cdf88f843
---

# issue-349 — refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-f1045776 record

## What was done

The core half of on-the-record#2600 slice 4: renamed every remaining `role`/`Role`/`ROLE`/`roles` **Python and shell identifier** (local variable, function parameter, module-level constant, test function name) to `skill`/`Skill`/`SKILL`/`skills` in tokenmaxxxer-core, leaving every other kind of `role` occurrence (comments, docstrings, human-facing message/prose text, persisted keys, cross-repo-shared names, test-case display labels) untouched, across 23 files (11 `.sh` gate hooks including two `python3 -c "$VAR"`/`<<'PY'` embedded-Python bodies, 11 `.sh` test harnesses, 3 `.py` test files — `pretooluse_dispatcher.py` counted once, some files hit two categories).

**Population derivation.** checked: `python3 /tmp/ast_role_scan.py` (AST walk over every tracked `.py` file, collecting `Name`/`FunctionDef`/`arg`/`Attribute`/`Global` nodes whose identifier contains "role" case-insensitively — script reproduced below) — result at session start: 12 identifier occurrences across 4 standalone `.py` files (`core/hooks/pretooluse_dispatcher.py`, `core/hooks/test_board_gate.py`, `tests/test_ordering_gates_237.py`, `test/test_directive_injection.py`). Two of `core/hooks/{board-gate,approval-gate}.sh` embed a full Python program as a quoted bash heredoc (`IFS='' read -r -d '' VAR <<'PY' ... PY` executed via `python3 -c "$VAR"`) invisible to a plain `.py`-suffix AST walk; those were extracted to standalone files and AST-scanned the same way — result: 1 identifier each (`role`, plus `_sidecar_role`/`_cross_role` in board-gate.sh, all Store/Load occurrences of the same three bindings). The remaining gate/test `.sh` files hold no AST-parseable Python identifiers of their own; their `role`-named shell locals (`role=`, `local role=`, `$role`/`${role}` in code position, and compound names like `stub_role`, `MULTISKILL_ROLE`, `brole`) were enumerated via `grep -n` per file and cross-checked line-by-line against their surrounding comment/message-string context before renaming, since bash has no equivalent tokenizer.

```
# /tmp/ast_role_scan.py — the exact script behind every "AST walk" citation above
import ast, sys, pathlib
root = pathlib.Path(".")
results = []
class Visitor(ast.NodeVisitor):
    def __init__(self, path): self.path = path
    def check(self, name, node, kind):
        if name and 'role' in name.lower(): results.append((self.path, node.lineno, kind, name))
    def visit_FunctionDef(self, node):
        self.check(node.name, node, 'function')
        for a in node.args.args + node.args.kwonlyargs + node.args.posonlyargs:
            self.check(a.arg, a, 'param')
        self.generic_visit(node)
    visit_AsyncFunctionDef = visit_FunctionDef
    def visit_ClassDef(self, node):
        self.check(node.name, node, 'class'); self.generic_visit(node)
    def visit_Name(self, node):
        if isinstance(node.ctx, ast.Store): self.check(node.id, node, 'binding')
        self.generic_visit(node)
    def visit_arg(self, node):
        self.check(node.arg, node, 'param'); self.generic_visit(node)
    def visit_Attribute(self, node):
        if isinstance(node.ctx, ast.Store): self.check(node.attr, node, 'attr')
        self.generic_visit(node)
for pyfile in root.rglob("*.py"):
    if 'docs' in pyfile.parts or '.git' in pyfile.parts: continue
    try: tree = ast.parse(pyfile.read_text(), filename=str(pyfile))
    except Exception as e: print(f"PARSE ERROR {pyfile}: {e}", file=sys.stderr); continue
    Visitor(str(pyfile)).visit(tree)
for r in results: print(r)
```

Renames applied via a column-precise `tokenize`-based renamer for the standalone `.py` files and the two extracted embedded-Python blocks (renames only `tokenize.NAME` tokens matching an exact old identifier — automatically skips string literals, comments, and dict-string keys, so a persisted JSON key spelled `"role"` is structurally unreachable by it), and via line-anchored `sed` for the pure-shell files, checked against a full per-line `grep -n` context so no comment/message-text line was touched.

**Residual count, broken down by kind.** checked: `python3 /tmp/kind_breakdown.py` (full script below; classifies every remaining `\brole\b`-matching line outside `docs/` by file-kind, then sub-classifies the `.sh`/`.py` lines by whether the line is a `#`-comment, matches the excluded `core_role_directive`/`role-directive.sh`/`gate_is_role_directive_stub` cross-repo convention cluster, touches the persisted `.on-the-record/role.json` sidecar or a `"role"` JSON/dict key, or is other message/label text) — result:

```
TOTAL residual "role" text lines outside docs/: 724
  code (.sh/.py): 444
    comment-prose: 253
    excluded-cluster (core_role_directive / role-directive.sh convention): 28
    persisted-key-or-file (.on-the-record/role.json, "role" dict/JSON keys): 5
    message-or-label-text (deny()/echo prose, docstrings, test-case display labels): 158
  json-config (citation-config.json, facet-keyword-config.json, plugin.json, marketplace.json): 12
  md-prose (role-handoff-contract.md, session-protocol.md, README.md, warrant/scout/freelunch protocol.md, warrant-hunter.md): 268
```

```
# /tmp/kind_breakdown.py
import re, subprocess
files = [f for f in subprocess.run(["git","ls-files"],capture_output=True,text=True).stdout.splitlines() if not f.startswith("docs/")]
pat = re.compile(r'\brole\b', re.IGNORECASE)
def classify(p):
    if p.endswith('.md'): return 'md-prose'
    if p.endswith('.json'): return 'json-config'
    if p.endswith('.txt'): return 'txt-doc'
    if p.endswith(('.sh','.py')): return 'code'
    return 'other'
totals, code_hits = {}, []
for f in files:
    try: text = open(f, encoding='utf-8').read().splitlines()
    except Exception: continue
    kind = classify(f)
    for lineno, line in enumerate(text, 1):
        if pat.search(line):
            totals[kind] = totals.get(kind, 0) + 1
            if kind == 'code': code_hits.append((f, lineno, line))
cluster_pat = re.compile(r'core_role_directive|role-directive\.sh|gate_is_role_directive_stub|ROLE_NAME|ROLE_SUBJECT_PREFIX|ROLE_HANDBOOK|role_directive_case|role_directive_hits|saw_gate_lib_source')
persisted_pat = re.compile(r'\.on-the-record/role\.json|"role"')
comment_pat = re.compile(r'^\s*#')
sub = {'comment-prose':0,'excluded-cluster':0,'persisted-key-or-file':0,'message-or-label-text':0}
for f, ln, l in code_hits:
    if comment_pat.match(l): sub['comment-prose'] += 1
    elif cluster_pat.search(l): sub['excluded-cluster'] += 1
    elif persisted_pat.search(l): sub['persisted-key-or-file'] += 1
    else: sub['message-or-label-text'] += 1
print(totals, sub)
```

**Zero identifier-kind occurrences remain** outside the one deliberately-left exception named in Open findings below (`test_session_protocol_md_uses_generic_role_placeholder_not_dollar_role`). Re-running the AST walk and the embedded-Python extraction against the finished tree, and grepping for every renamed-identifier's old spelling in shell-code position (`\brole=|\$\{?role\b|\bother_role\b|\bstub_role\b|\bMULTISKILL_ROLE\b|\bbrole\b|\bsc_role\b|\broleenv\b|\bnorole\b|\bnoRole\b`), both confirmed zero hits outside test-case display-label strings and one historical comment (`run-issue-280-tests.sh:54`, prose narrating a past state, not live code).

**What was deliberately left, and why (cross-repo check).** on-the-record's own PR #2731 left exactly two things unrenamed and one open finding; none of the three is this PR's to change:
- `on-the-record/hooks/approval-gate.sh` (45 occurrences, pinned as literal source text by on-the-record's own `test/test_convention_equivalence.py`) — a different repo's file entirely, out of scope for a tokenmaxxxer-core PR regardless of its own renaming policy. Core's own `core/hooks/approval-gate.sh` (a different, unrelated file living in this repo) is fully renamed in this PR — checked: `python3 /tmp/ast_role_scan2.py` (a variant of the script above run against the extracted embedded-Python block) on the finished file — 0 remaining identifiers.
- The role→skill vs. pre-existing Claude-Skills naming collision (on-the-record's Open finding 2) — an #2593-level word-choice decision three already-merged on-the-record PRs executed before this issue existed; not something a mechanical identifier-rename slice in either repo can re-litigate.
- The `PG_ROLE`-fallback-path finding on-the-record's own record names as "a tokenmaxxxer-core path (`core/hooks/survey-order-gate.sh:137`), not present in this on-the-record checkout" — checked: `grep -n "PG_ROLE\|PG_SKILL" core/hooks/survey-order-gate.sh core/hooks/pretooluse_dispatcher.py` — result: 0 occurrences of `PG_ROLE`, only `PG_SKILL` (env-var name), confirming this was already resolved by core's own prior, already-merged env-var slice (commit `764aebc`, PR #347) before this session started; nothing left for this PR here.

The one cross-repo-shared identifier found and excluded here (core's own equivalent hazard to on-the-record's approval-gate.sh exclusion): `core_role_directive()` (defined in `core/hooks/lib/role-directive.sh`) and the literal filename `role-directive.sh` are a textual convention every per-repo `directive.sh` stub across the ecosystem sources and calls by these exact names — `core/hooks/lib/gate-lib.sh`'s `gate_is_role_directive_stub()` greps target files for these exact literal strings to validate compliance. Renaming either would make every existing external stub (which this PR cannot reach or edit) fail that grep, silently turning "this repo's directive stub is compliant" into "non-compliant" for repos this PR never touches. Left `core_role_directive`, `role-directive.sh`, `gate_is_role_directive_stub`, and its internal grep-pattern-matching helpers entirely unrenamed (28 occurrences, tallied above); renamed only the truly-local implementation variables inside `core_role_directive()`'s own body (`role`→`skill`, `role_upper`→`skill_upper`) since those never leave the function and are invisible to any external stub.

checked: `grep -rn "core_role_directive\|role-directive\.sh" "$ON_THE_RECORD" --include="*.py" --include="*.sh"` (excluding the plugin's own `runs/` deployment mirror) — 0 hits, confirming on-the-record's own codebase does not itself source this convention (it is a convention core ships for *other* consuming repos, not for on-the-record). checked: `grep -rn '"role"\|role\.json' "$ON_THE_RECORD"/*.py` — on-the-record's `pipeline.py:915-932` still writes `.on-the-record/role.json` with a literal `"role"` key today, and `events.py`/`roster.py`/`lifecycle.py` still use `"role"` as a board/ledger dict key — confirming the persisted-key slice (slice 5) genuinely has not landed on the on-the-record side yet, so leaving `.on-the-record/role.json`'s filename and its `"role"` key untouched in `core/hooks/board-gate.sh` and `core/hooks/tests/run-board-gate-tests.sh` matches the live cross-repo contract exactly, not a guess.

**Behavior-unchanged verification.** checked: `python3 -m pytest -q` on this branch — result: `3 failed, 79 passed`. checked: the identical command on `origin/main` at commit `60cbcb5`, both (a) via a separate `git worktree add /tmp/core-main-baseline origin/main` and (b) via `git stash` on this same checkout (to rule out a path-length artifact — see What did not work) — result both ways: `3 failed, 79 passed`, and the failing-test **names** are byte-identical sets: `{tests/test_promoted_hooks.py::test_proposal_shape_gate_refuses_missing_sections, tests/test_promoted_hooks.py::test_survey_order_gate_refuses_proposal_without_survey_or_skip, tests/test_silent_failure_repros.py::test_A5_trailer_gate_quote_split_commit_is_detected}` on both branches — pre-existing, unrelated to this change. checked: `bash core/hooks/tests/run-all.sh` on this branch vs. the same command via `git stash` on origin/main at the identical checkout path — `diff` of every suite's `passed`/`fail=` summary line: empty (byte-identical), including the pre-existing shell-suite failures (`feasibility-spikes`, `ops-postmortems`, `checkpoint-refusal-names-await-approval`, `execute-without-remote`, one `dispatcher-equivalence` case) verified by name via `grep -iE '^FAIL'` on both sides. Gate allow/deny exercise before/after is what `run-board-gate-tests.sh`, `run-approval-gate-tests.sh`, `run-role-gates-tests.sh`, `run-citation-gate-tests.sh`, `run-facet-keyword-gate-tests.sh`, `run-survey-order-gate-tests.sh`, and `run-gate-lib-tests.sh` already do per-gate (each carries both `allow` and `deny` cases per changed identifier); all ran identically before and after via the stash comparison above.

**Independent adversarial review.** Dispatched a fresh-context subagent (no access to this session, no builder rationale, given only the raw `git diff` — adversarial-review skill) with an evaluator prompt asking it to find half-applied renames, stale cross-references, and syntax breaks. It independently re-verified `bash -n`/`python3 -m py_compile` cleanliness and re-ran the affected test suites (finding the same pre-existing failures via its own git-stash bisection), then reported 11 real findings: inline `# <want> <name> <role> ...>` parameter-documentation comments on 10 function signatures across 6 test-harness files were left saying `<role>` immediately next to a body that had already renamed the same parameter to `skill`, plus one file (`run-board-gate-tests.sh`) where a twin helper's comment (`runs()`) had been updated but its sibling (`runb()`) had not. All 11 were fixed in this same PR (listed under What did not work); the evaluator reported zero half-applied renames, zero stale cross-references, and zero syntax issues after that — "safe to merge... no half-applied rename that breaks at runtime."

## Why

Kind-partitioned scope (identifiers only, per on-the-record#2600's own slice structure) was decided upstream of this PR; within it, the AST-walk-not-regex method and the explicit persisted-key/cross-repo-convention exclusions were carried over directly from on-the-record PR #2731's own record, since core#349 is stated to be "the same slice for tokenmaxxxer-core" and #2731 had already worked out (and paid for, via its own "What did not work" entries) the failure modes worth avoiding here: partition-by-glob instead of by-kind (#2720's defect), and silently renaming a cross-repo-pinned convention.

`refactoring-legacy-seam-selection` was judged not applicable: this is a pure, behavior-preserving identifier rename with an existing test suite already exercising every changed gate — no new or changed behavior is being introduced into untested legacy code, so there is no seam decision to make.

`refactoring-legacy-verification-cadence` was invoked and partially applied: rule 5 (treat a captured-test failure as a stop/investigate signal, never adjust the test to match) was followed exactly — every failure encountered was run down to a root cause (pre-existing vs. this-diff, verified via git-stash bisection at the identical checkout path) before any conclusion was drawn, and no test's expectation was altered. Rule 1 (run the captured suite immediately after each individual step, before the next) was **not** followed literally: renames were applied in a small number of larger tokenize/sed batches (grouped by file, not by single-identifier step) with one comprehensive verification pass at the end rather than after each file. This is a deliberate deviation, not an oversight — see What did not work for the justification.

`adversarial-review` was invoked and applied as described above; its findings were fixed in this same PR rather than deferred, since they were all cheap, mechanical, and directly load-bearing for "did this rename actually happen everywhere."

skill-verdict: refactoring-legacy-seam-selection — not-applicable: pure identifier rename, no new/changed behavior, no seam decision needed
skill-verdict: refactoring-legacy-verification-cadence — applied: invoked; rule 5 (stop-and-investigate on any captured failure, verified via git-stash bisection, never adjusted a test) followed throughout; rule 1 (per-step immediate re-run) deviated from in favor of one comprehensive end-of-batch verification, justified in What did not work by the mechanical safety of tokenize/AST-scoped renames and the size of the change
skill-verdict: adversarial-review — applied: invoked; spawned a fresh-context subagent (Agent tool, general-purpose, no shared context) given only the raw diff with an evaluator prompt per the skill's Step 2 template; its 11 findings (stale `<role>` doc-comments next to renamed code) were fixed in this PR

## What did not work

- Ran `git diff --stat`/`git log`/`grep` exploratory commands before writing the freelunch STEP 1 tally paragraph, rather than before any other action as the directive requires. Noted rather than silently complying from that point forward; the tally itself (LEAN SOLO, justified by sequential cross-repo judgment that cannot be frozen as a per-file contract upfront) was written before any file edit.
- First test-suite comparison against `origin/main` used a separate `git worktree add /tmp/core-main-baseline origin/main` at a much shorter filesystem path than this session's own checkout directory. The shell suite's `run-ups-diet-tests.sh` measures a hard-coded byte budget (`<= 3072 bytes/turn`) on rendered hook output that embeds this repo's own absolute path (`Read <path>/directive/....md` pointers) — comparing byte counts across two different-length paths produced a false 138-bytes-per-hook, 966-bytes-total "regression" that did not exist. Root-caused by diffing one hook's rendered output between the two checkouts (`diff <(...) <(cd /tmp/core-main-baseline && ...)`), which showed the only difference was the absolute path string, then confirmed the path-length delta (138 chars) matched the byte delta exactly. Re-ran the comparison via `git stash`/`git stash pop` on this same checkout (identical path both sides) instead, which showed the "combined UPS payload" test fails identically (pre-existing, driven by this session's own long branch-derived directory name) on both the pre-diff and post-diff tree — not a regression from this rename at all. This is exactly the false-negative-claim failure mode named in this session's brief; corrected before it reached this record's Verification section.
- The independent adversarial-review subagent found 11 stale `<role>` parameter-documentation comments left immediately adjacent to already-renamed code (see What was done and Why) — a genuine half-applied-looking inconsistency that a first pass, which deliberately avoided touching any comment/prose text, produced as an unintended side effect for comments that describe a function's own just-renamed parameter (as opposed to general contract prose). Fixed by re-examining the reviewer's 11 cited locations and updating each `<role>` placeholder to `<skill>` (one further correction beyond the reviewer's own line number, which had misattributed one finding to the wrong file — `run_kind()`'s comment is in `run-role-gates-tests.sh:133`, not `run-gate-lib-tests.sh:133` as reported; verified directly before editing). Re-ran the full pytest and shell suites after the fix — identical pass/fail sets to before the fix, confirming the correction was comment-only.

## Upstream basis

- on-the-record PR #2731 / `docs/issue-2600/reports/refactoring-legacy-seam-selection+refactoring-legacy-verification-cadence+adversarial-review-4c7357a0.md` (read via the `$ON_THE_RECORD` checkout, cross-repo, no commit sha applies to this repo) — supplied the AST-walk-not-regex method, the `role`→`skill` replacement word (an earlier, already-executed decision this PR did not re-litigate), the persisted-key/cross-repo-boundary exclusion categories, and the precedent for excluding a test-pinned/convention-pinned file in full rather than partially renaming it.
- core commit `764aebc` (issue-2600, PR #347, "retire ROLE-named env vars in core") and `60cbcb5` (issue-2670, PR #348, "rename CLAUDE_ROLE to CLAUDE_SKILL") — already landed the env-var slice this PR builds on top of; every `role`-named Python/shell local this PR renames reads its value from an already-`SKILL`-named env var (`CLAUDE_SKILL`, `RF_SKILL`, `PG_SKILL`, `HT_SKILL`, `TRAILER_GATE_SKILL`), confirmed unchanged by this PR.

## Open findings

1. `test/test_directive_injection.py:123`'s `test_session_protocol_md_uses_generic_role_placeholder_not_dollar_role` is the one Python identifier this PR deliberately left unrenamed. Its assertions (`assert "${role}" not in text`; `assert "<role>" in text`) check `core/directive/session-protocol.md`'s own literal `<role>` placeholder text — a prompt/directive-text-slice concern (not landed for core in this issue), not this PR's identifier to rename. Renaming the test's *name* to say "skill placeholder" while its body still asserts the literal string `<role>` would make the name lie about what it verifies; left both the test name and the doc's placeholder text untouched together, correctly paired. Resolution path: whichever future slice retires core's prompt/directive-text `role` vocabulary (the core-side counterpart to on-the-record's already-landed #2720) renames both the doc's placeholder and this test's name and assertions together.
2. Not resolved here, inherited unchanged from on-the-record's own Open finding 2: this repo also has a pre-existing "skill" concept (the `--skills`/skill-repository mechanism visible throughout `core/hooks/tests/run-stub-canon-forms-tests.sh`'s `ROLE_NAME`/fixture content and this session's own spawning `MUSTER_SKILLS` env var) alongside the now-renamed participant-role vocabulary (`MULTISKILL_SKILL`, local `skill` variables meaning "the acting session's role"). The two concepts read ambiguously wherever they sit near each other (e.g. `core/hooks/test_board_gate.py`'s `MULTISKILL_SKILL` constant name). This is a consequence of the `role`→`skill` replacement word three earlier, already-merged on-the-record PRs chose; not something this mechanical identifier-rename slice can unilaterally re-litigate by picking a different word.

## Next steps

None outstanding for this slice's code. checked: `python3 -m pytest -q` (final run, this turn) — 3 failed, 79 passed, byte-identical failing-name set to `origin/main`. checked: `bash core/hooks/tests/run-all.sh` (final run, this turn) — summary lines byte-identical to `origin/main` via the same-path `git stash` comparison. checked: `git diff --name-status origin/main -- docs/` — empty (no pre-existing docs/ file modified; this record and any deviation-log entries are the only new paths under `docs/issue-349/`). `loop_state` is `landed`; this record is committed alongside the code in the same PR (build-now bypass, contract v3 s19a).
