---
subject: issue-72
role: implementation
loop_state: scope-proposed
---

# Survey — gate-house standard canonization

Phase 1 (proposal-only). Covers the current state of `core/hooks/*.sh`,
`core/hooks/lib/role-directive.sh`, the `core/hooks/tests/` harness, and
`docs/handbooks/canon-scripts.md` — everything issue #72's four requirements
touch — as actually found in this checkout, not assumed.

## Repo-scope caveat (same shape as issue-69's survey)

This checkout (`tokenmaxxxer-core`) contains `core/` plus addon plugins. It
does **not** contain the 43 external rulebook repos the issue's audit ("43룰북
실물 코드 감사") describes. This survey therefore cannot cite line numbers
from the 43 rulebooks' own gate copies — those are outside this repo's write
and read access, same caveat `docs/issue-69/reports/implementation/survey.md`
already recorded for a structurally identical situation. What it does instead:
survey `core/`'s own seven gate scripts in full (they are the shape every
rulebook gate is presumably descended from or should converge on) and note,
per issue item, whether core's own canon already meets the house standard the
issue wants written down and enforced, or itself shows the defect class named
in the issue's background. Every claim below points at a `core/hooks/*.sh`
line range in this checkout; nothing is asserted about the 43 external repos
beyond what the issue text itself states.

Files read in full: `core/hooks/approval-gate.sh`, `core/hooks/board-gate.sh`,
`core/hooks/directive.sh`, `core/hooks/gh-guard.sh`,
`core/hooks/handbook-trigger-gate.sh`, `core/hooks/record-fields-gate.sh`,
`core/hooks/trailer-gate.sh`, `core/hooks/lib/role-directive.sh`,
`core/hooks/tests/stub-check.sh`, `core/hooks/tests/canon-manifest.txt`,
`docs/handbooks/canon-scripts.md`, `core/contract/role-handoff-contract.md`.

## 1. Trap-at-top / fail-closed

All seven gate scripts install a fail-closed trap as their first or
near-first statement:

- `approval-gate.sh:37`, `board-gate.sh:41`, `directive.sh:9`,
  `gh-guard.sh:22`: `trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then
  exit 2; fi' EXIT` — inline trap before `set -uo pipefail`.
- `handbook-trigger-gate.sh:2-3`, `record-fields-gate.sh:2-3`,
  `trailer-gate.sh:2-3`: a named function `__fc()` doing the same
  remap-to-2, installed via `trap __fc EXIT` as literally the first two lines
  of the file, before the shebang comment block even starts (line 1 is the
  shebang, line 2 defines `__fc`, line 3 traps it).

**Finding**: core's own canon gates already satisfy "trap-at-top fail-closed"
uniformly — there is no dead fail-closed code and no gate missing the trap.
Two different textual idioms exist, though (inline trap vs. `__fc` function) —
this is the kind of shape a shared `gate-lib.sh` would collapse to one, per
the issue's ask, rather than a defect on its own.

Additionally, three of the seven (`handbook-trigger-gate.sh:128-130`,
`record-fields-gate.sh:222-224`, and their Python bodies) wrap their entire
Python payload in `try/except Exception` with a second fail-closed layer
(`_fc_sys.exit(2)`), and `trailer-gate.sh:56-62` installs
`sys.excepthook = _fail_closed` calling `os._exit(2)`. `approval-gate.sh` and
`board-gate.sh`'s Python bodies have **no** such internal
try/except-fail-closed wrapper — an uncaught Python exception there
propagates as a non-0/non-2 process exit, which is still caught by the outer
bash trap (`rc != 0 && rc != 2 -> exit 2`), so the net behavior is still
fail-closed, but the mechanism is two different depths of defense across the
seven files, not one.

## 2. Kill-switch default-on-unrecognized-value

Every kill switch in this repo (`CORE_OFF`, `TRAILER_GATE_OFF`,
`RECORD_FIELDS_GATE_OFF`, `HANDBOOK_TRIGGER_GATE_OFF`) uses the identical
shell idiom:

```sh
case "${CORE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
```

(`approval-gate.sh:40`, `board-gate.sh:44`, `directive.sh:12`,
`gh-guard.sh:25`, `trailer-gate.sh:30-33`, `record-fields-gate.sh:37-40`,
`handbook-trigger-gate.sh:29-32`.)

**Finding — this is the fail-open bug the issue names, present in core's own
canon today, not just a hypothetical the 43 rulebooks might have.** The
matched branch (empty / `0` / `false` / `no` / `off`) is "stay active,
continue past this line." The wildcard `*` branch — which fires for *any
other* value, including an unrecognized one like `CORE_OFF=banana` or a typo
like `CORE_OFF=1 ` with a stray character — exits `0`, i.e. **disables the
gate**. The issue's requirement text is explicit: "킬스위치 비인식 값에 무단
해제" (an unrecognized kill-switch value should not grant unauthorized
release/disable) and separately states the standard convention should be
"비인식 값=활성" (unrecognized value = active/enabled). Every kill switch in
this repo's own canon currently does the opposite: recognized-off-spellings
keep the gate on, and everything else — recognized-on spellings (`1`, `true`,
`yes`, `on`) as well as any unrecognized garbage — turns the gate off. This is
the single most concrete, in-repo-verifiable instance of the issue's item 2
defect class, and fixing it (flipping the case arms so only a recognized
off-spelling disables, and everything else — including unrecognized values —
keeps the gate active) is squarely inside `gate-lib.sh`'s stated scope
("표준 킬스위치 규약(비인식 값=활성)").

## 3. Absolute-path normalization / scope matching

Path-matching logic lives only in the Python payload bodies (`board-gate.sh`,
`approval-gate.sh`, `record-fields-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh`); none of the seven gates does bash-level regex
anchoring against a raw `file_path` string.

- `board-gate.sh:178-190`: `norm()` calls `posixpath.normpath(p.replace("\\",
  "/"))`, then searches for the **substring** `"docs/"` anywhere in the
  normalized path (`n.find(DOCS)`) rather than anchoring a regex to the
  string's start. This means an absolute path
  (`/home/user/repo/docs/issue-72/...`) and a relative path
  (`docs/issue-72/...`) both match, because the check is "does `docs/` occur
  somewhere," not "does the path start with `docs/`." This is the opposite of
  the issue's named dead-code shape (`^docs/...` failing to match an absolute
  `file_path`) — core's own board-gate does not have that bug.
  `approval-gate.sh:91-107`'s `execution_surface()` uses the same
  `norm()`+substring-search shape via `ISSUE_RE.search(n)` (a `re.search`,
  not `re.match`/`^`-anchored), so it likewise tolerates an absolute prefix.
- `record-fields-gate.sh:114-119`'s `resolve()` and `handbook-trigger-gate.sh`
  (via `_under()` in the surrounding bash, using `os.path.realpath`) both
  resolve the write target to an absolute, symlink-resolved path against a
  resolved project root *before* any pattern match, then strip the root
  prefix to get a root-relative tail (`record-fields-gate.sh:134-138`). This
  is the most defensive of the shapes present: it converts both relative and
  absolute inputs to the same canonical form before any regex sees them, so
  `./docs/...`, `docs/...`, and an absolute path all normalize identically.
- `trailer-gate.sh` and `handbook-trigger-gate.sh` do not match individual
  `file_path` values at all — they operate on `git diff --cached --name-only`
  output (repo-root-relative by construction, since it comes from git itself,
  not from tool-call JSON), so the absolute/relative distinction the issue
  raises does not arise for them the same way.

**Finding**: core's own gates do not exhibit the issue's dead-code path-match
bug (none anchor a bare `^docs/` against a raw absolute `file_path`), but they
achieve this through **three different techniques** (substring search after
normalize, `re.search` without anchor, and full realpath-then-strip-root)
scattered across five files, with no shared helper. `gate-lib.sh`'s
absolute-path-normalization function is exactly what would let a rulebook
gate reuse the third (most defensive) technique instead of reinventing one of
the first two, or a genuinely `^`-anchored one, from scratch. `./` prefix
handling is exercised implicitly by `posixpath.normpath` in `board-gate.sh`
and by `os.path.realpath` elsewhere — both collapse a `./` prefix — but no
gate has a test asserting this (see section 6).

## 4. stdout vs. stderr deny protocol

Every `deny()`/error path across all seven scripts writes to `sys.stderr` (in
the Python bodies: `approval-gate.sh:64`, `board-gate.sh:74`,
`gh-guard.sh:49`, `handbook-trigger-gate.sh:55`, `record-fields-gate.sh:95`,
`trailer-gate.sh:50`) or bash `>&2` (`handbook-trigger-gate.sh:27`,
`record-fields-gate.sh:35`, `trailer-gate.sh:28`, and the `__fc`/inline-trap
fail-closed message lines). No gate in this repo prints its deny JSON or deny
reason to stdout. `directive.sh` is a `SessionStart` hook, not a `PreToolUse`
deny gate, so its `cat <<EOF ... EOF` to stdout (`directive.sh:43,57`) is
correct for its purpose (informational text the model should read), not a
deny-reason leak.

**Finding**: core's own canon already satisfies the issue's item 5 (deny
reason must reach the model via stderr on exit 2) uniformly. This is a clean
bill, not a gap — worth stating explicitly in `gate-lib.sh`'s design as "codify
what already holds here," not "invent a new rule."

## 5. Malformed-JSON handling

Every Python gate body wraps its `json.loads(...)` call in `try/except
ValueError` and calls `deny(...)` (which exits 2) on failure:
`approval-gate.sh:70-73`, `board-gate.sh:81-84`, `gh-guard.sh:56-58`,
`handbook-trigger-gate.sh:59-61`, `record-fields-gate.sh:99-101`,
`trailer-gate.sh:66-68`. Each also checks `isinstance(event, dict)` /
`isinstance(ti, dict)` after parsing and denies if the shape is wrong, not
just if the JSON itself fails to parse.

**Finding**: malformed-JSON-denies is already universal in this repo's canon.
No gap found here either — `gate-lib.sh`'s malformed-JSON-deny helper
formalizes an existing, already-consistent convention rather than fixing a
live core-canon bug.

## 6. Edit / MultiEdit / replace_all / NotebookEdit reconstruction

Only `record-fields-gate.sh` reconstructs post-edit content (it must, to
check §20 fields against the *resulting* text of a record write). Its
reconstruction (`record-fields-gate.sh:150-171`):

- `Write`: takes `tool_input.content` directly — no reconstruction needed.
- `Edit`: `new_text = current.replace(o, n, 1)` — replaces the **first**
  occurrence of `old_string` only.
- `MultiEdit`: iterates `tool_input.edits`, applying each edit's `old_string`
  →`new_string` with `text.replace(o, n, 1)` in sequence.

**Finding — concrete, in-repo confirmation of the issue's item 3.** Neither
branch reads or honors an edit's `replace_all` field at all — the key is
never referenced anywhere in `record-fields-gate.sh`. A real `Edit` or
`MultiEdit` call carrying `"replace_all": true` (the tool's own documented
behavior: replace every occurrence, not just the first) is silently
mis-simulated by this gate as a single-occurrence replace. If the real edit's
`old_string` occurs more than once in the record, the gate's reconstructed
`new_text` diverges from the file Claude Code will actually write, and the
§20 field check runs against the wrong content. This is exactly the "Edit/
MultiEdit reconstruction: replace_all ignored" defect the issue's background
names — reproduced here in core's own single canon copy of the only gate that
does reconstruction at all, not merely inferred to exist in the 43 rulebooks.

`NotebookEdit` is not handled anywhere: `record-fields-gate.sh:127` restricts
reconstruction to `tool in ("Write", "Edit", "MultiEdit")` and exits 0
(`sys.exit(0)`, i.e. passthrough — not evaluated) for any other tool,
including `NotebookEdit`. A role writing its own record via a notebook cell
(unlikely in practice for a `.md` record, but not excluded by the gate's own
scope) bypasses the §20 field check entirely. `approval-gate.sh` and
`board-gate.sh`, by contrast, do include `NotebookEdit` in their
`tool in (...)` candidate lists (`approval-gate.sh:110`, `board-gate.sh:158`)
— but those two gates only need the *target path*, not reconstructed content,
so `NotebookEdit`'s presence there does not contradict the reconstruction gap
found in `record-fields-gate.sh`.

No test in `core/hooks/tests/` currently exercises `replace_all: true`,
`MultiEdit`, or `NotebookEdit` against `record-fields-gate.sh` (see section
8) — this is precisely why the gap went unnoticed rather than being covered
and passing.

## 7. Bash-tool file-write coverage

Mixed, per gate, not uniform:

- `approval-gate.sh:114-123` and `board-gate.sh:162-176` **do** scan `Bash`
  `tool_input.command` strings for path-shaped tokens matching their
  respective patterns (`CODE_RE`/`ISSUE_RE` in approval-gate; the `docs/`
  substring scan in board-gate) — a `Bash` call such as
  `echo x > docs/issue-72/proposals/y.md` is caught by both, because both
  gates deliberately widen their `tool in (...)` check to include `"Bash"` as
  a fourth candidate-source alongside `Write`/`Edit`/`MultiEdit`.
- `record-fields-gate.sh:127-132` explicitly does **not** cover Bash writes:
  its own comment states "Only Write/Edit/MultiEdit reach the record in a
  form whose full resulting content we can read... A Bash write to the record
  is out of this gate's scope (board-gate/scope-gate handle Bash); passed
  through." A role session running `cat <<EOF > docs/issue-72/reports/
  implementation.md ... EOF` (or any other Bash-based write to its own
  record) reaches `path is None -> sys.exit(0)` and is never checked against
  §20's required fields at all.
- `trailer-gate.sh` and `handbook-trigger-gate.sh` match `Bash` calls, but
  only ones containing `git ... commit` (`trailer-gate.sh:85`,
  `handbook-trigger-gate.sh:73`) — a deliberate, narrow scope (commit-time
  checks), not a general Bash-file-write gap, so it is not counted as a
  defect of the same kind.

**Finding**: this repo's own canon already demonstrates both the covered and
uncovered shape side by side — `approval-gate.sh`/`board-gate.sh` show Bash
coverage is achievable with a token-scan-over-command-string approach;
`record-fields-gate.sh` shows the exact "gate only matches Write/Edit-family
tool calls" bypass the issue names, for its own §20-field-check purpose. A
shared `gate-lib.sh` Bash-write-matching helper, used consistently, would
close this specific record-fields-gate gap along with giving future rulebook
gates the same option approval-gate/board-gate already use.

## 8. Existing test harness

`core/hooks/tests/` contains `run-all.sh`, `run-approval-gate-tests.sh`,
`run-board-gate-tests.sh`, `run-gh-guard-tests.sh`, `run-role-gates-tests.sh`,
`deny-only-check.sh`, `parse-check.sh`, `stub-check.sh`, plus a scratch
`_tmp.sh`. (Not read line-by-line in this pass — out of the issue's four
required items' direct scope, except as the shape a new shared test harness
should sit alongside; `run-role-gates-tests.sh` is the harness that exercises
`trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh` per its
name.) No file in this directory is named for `replace_all`, `MultiEdit`,
`NotebookEdit`, `malformed-json`, `kill-switch`, or `absolute-path` — the six
case classes the issue's item 2 requires a shared runner to make mandatory.
This is consistent with section 6's finding that `replace_all` coverage is
genuinely absent, not merely under-tested.

## 9. `canon-scripts.md` — the reference-not-copy convention

`docs/handbooks/canon-scripts.md` (23 lines) exists and states the exact rule
issue #72 invokes:

> **Canon scripts are referenced, never copied.** Any script that lives under
> `core/hooks/` or `core/hooks/tests/` is invoked by a rulebook through a path
> resolved against the core plugin's own install root. A rulebook's own tree
> never contains a second copy of a core canon file.

It also documents the one deliberate, reasoned exception (`parse-check.sh`,
which must run against files that only exist inside each rulebook) and states
that `core/hooks/tests/stub-check.sh` mechanically enforces the rule today —
but **only** for the five filenames listed in
`core/hooks/tests/canon-manifest.txt` (`trailer-gate.sh`,
`record-fields-gate.sh`, `handbook-trigger-gate.sh`, `parse-check.sh`,
`stub-check.sh`). A future `gate-lib.sh` (and any test-harness/
compliance-detector scripts issue #72 adds) is not yet in that manifest and
would not be caught by `stub-check.sh` if a rulebook vendored a copy of it
instead of referencing it — adding the new filename(s) to
`canon-manifest.txt` is a one-line, already-established mechanism (per
`stub-check.sh`'s own header, `core/hooks/tests/stub-check.sh:44-48`: "CANON_
GATES is derived from canon-manifest.txt ... so a future promotion ... adds
one manifest line instead of an edit to this detection logic").

`role-directive.sh` (`core/hooks/lib/role-directive.sh`) is the one existing
precedent in this repo for a genuine shared *library* (as opposed to a
canon-pinned standalone script): a rulebook's own `directive.sh` sources it
and calls `core_role_directive` with four role-specific string arguments,
rather than vendoring the boilerplate. `stub-check.sh:76-108` enforces this
one *structurally* (grep-based: the stub must source
`role-directive.sh`, call `core_role_directive`, and contain no other
non-blank/non-comment/non-assignment lines) rather than by literal-file-copy
detection, because every rulebook's `directive.sh` is necessarily a distinct
small file (it carries the four role-unique strings) — this is the
closest existing precedent for how a `gate-lib.sh`-sourcing stub in a
rulebook's own gate file should be checked by the new compliance detector
issue #72 asks for, as opposed to `stub-check.sh`'s absence-only check for
the five fully-promoted files.

## Summary table

| Issue item | Core canon's current state (this checkout) | Gap for gate-lib.sh / detector to close |
|---|---|---|
| Trap-at-top fail-closed | Present in all 7 gates (2 idioms: inline trap vs. `__fc` fn); 3/7 also add an internal Python try/except layer | Not a defect; collapse to one shared idiom |
| Kill-switch default-on-unrecognized | **Present bug**: `case ... in ""\|0\|false\|no\|off) ;; *) exit 0 ;; esac` in all 4 switches — unrecognized value disables, not enables | Real fix needed: flip default so only recognized off-spellings disable |
| Absolute-path / scope matching | No `^docs/`-anchored dead-code bug found; 3 different normalize techniques across 5 files, none shared | Extract one canonical normalize+match helper |
| stdout-vs-stderr deny | All denies go to stderr; `directive.sh`'s stdout use is a SessionStart informational hook, not a deny | Clean; codify, don't fix |
| Malformed JSON | All 6 Python gate bodies deny on `json.loads` failure and non-dict shape | Clean; codify, don't fix |
| Edit/MultiEdit/replace_all | **Present bug**: `record-fields-gate.sh` ignores `replace_all`, always does first-occurrence replace; `NotebookEdit` not reconstructed at all | Real fix + shared reconstruction helper |
| Bash-write coverage | Inconsistent: approval-gate/board-gate cover it; record-fields-gate explicitly does not (own comment says so) | Extend record-fields-gate (or its gate-lib successor) to match approval-gate/board-gate's existing technique |
| Test harness | No case files for replace_all / MultiEdit / NotebookEdit / malformed-JSON / kill-switch / absolute-path | Build the shared mandatory-case runner issue #72 asks for |
| canon-scripts.md / reference-not-copy | Documented and enforced today for 5 manifest-listed files; role-directive.sh is the shared-library precedent | New gate-lib.sh + detector script(s) must be added to canon-manifest.txt and to the stub-check structural-check style for anything not fully absence-checkable |

## Unknowns, stated plainly

- The 43 external rulebook repos' actual gate code was not read (no access
  from this checkout) — every specific claim above is scoped to `core/`'s own
  seven gates, not to the 43 repos the issue's audit covers. The proposal
  below treats the issue's own audit summary as given fact for the 43 repos
  and this survey's findings as what a shared library inherits/fixes for
  core's own canon at the same time.
- `core/hooks/tests/run-*.sh` files were not read line-by-line (listed by
  name only, section 8) — their exact current assertions are unverified
  beyond "no filename suggests replace_all/MultiEdit/NotebookEdit/
  malformed-json/kill-switch/absolute-path coverage exists." A phase-2 spike
  should read them in full before writing the new shared runner, in case
  partial coverage already exists under a differently-named test.
- Whether `directive.sh`'s relative-path core dependency (issue background
  item 6, "directive의 core 상대경로 의존이 환경 따라 파손") reproduces in
  this checkout was not separately investigated beyond noting
  `role-directive.sh`'s own header already documents the intended resolution
  expression (`core/hooks/lib/role-directive.sh:13`,
  `${CLAUDE_PLUGIN_ROOT_CORE:-$(cd ... /../core && pwd -P)}`) as a fallback
  chain, not a hardcoded relative path alone — flagged as unverified rather
  than asserted fixed or broken.
