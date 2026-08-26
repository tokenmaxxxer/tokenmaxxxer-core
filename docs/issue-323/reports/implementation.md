---
issue: 323
role: implementation
author: implementation
loop_state: landed
upstream:
  - path: warrant/hooks/scope-gate.sh
    sha: f30c9120df4014602a119d7debe1f0e44f5bdb23
code_under_review:
  - warrant/hooks/scope-gate.sh
  - warrant/hooks/lib/scope-gate.py
type: fix
breaking: "no — same PreToolUse hook path (warrant/hooks/scope-gate.sh), same argv0/stdin/env contract, same exit codes; a new sibling file (warrant/hooks/lib/scope-gate.py) is added but nothing outside the plugin loads it directly"
verdict: pass
---

# issue-323 — implementation record

## What was done

- `warrant/hooks/scope-gate.sh`'s payload logic — previously a
  `WARRANT_PAYLOAD="$payload" python3 <<'PY' ... PY` heredoc — was extracted
  verbatim into a real sibling file, `warrant/hooks/lib/scope-gate.py`, and
  the shell script now runs `python3 "$SCOPE_GATE_DIR/lib/scope-gate.py"`
  (directory resolved from `${BASH_SOURCE[0]}`, independent of
  `CLAUDE_PLUGIN_ROOT_CORE`). No heredoc remains in the script; the Python
  logic itself is byte-for-byte unchanged (only a short header comment was
  added to the extracted file).
- Reproduced the exact ENOSPC-during-heredoc failure live (before fix),
  confirmed the fix removes the exposure (after fix), and reran the existing
  `scope-gate` and `role-gates` hook test suites for a normal-condition
  regression check. Details and commands are under Upstream basis /
  Open findings below.
- Audited the other 21 heredoc-using hook scripts named in the issue (this
  session's own audit actually surfaced 25 non-test scripts sharing the
  heredoc/here-string shell mechanism, a slightly wider net than the issue's
  grep count — see Open findings for the full list and why the counts
  differ). None of the 25 were changed in this pass; each is stated below
  with its exposure disposition per the issue's acceptance criterion.

## Why

Bash's own heredoc implementation is the root cause, and it is
size-dependent, which is why the issue's failure mode is confusing:

- Per bash 5.1's `NEWS` (verified against the installed `/usr/share/doc/bash/NEWS.gz`
  in this sandbox): *"Here documents and here strings now use pipes for the
  expanded document if it's smaller than the pipe buffer size, reverting to
  temporary files if it's larger."* The pipe buffer size on this Linux/glibc
  bash 5.1.16 build is the usual 65536 bytes.
- Below that threshold, bash forks a writer process and feeds the heredoc
  body through an in-memory `pipe2()` — confirmed via `strace`, zero
  `openat()` calls toward `$TMPDIR` regardless of how full `$TMPDIR` is.
  **A heredoc under ~64KB cannot hit ENOSPC at all**, because it never
  touches a filesystem.
- Above that threshold, bash calls `mkstemp()`-equivalent
  `open(..., O_CREAT|O_EXCL)` under `$TMPDIR` (confirmed the same way).
  Under disk/inode exhaustion that `open()` fails, bash prints
  `cannot create temp file for here-document: <strerror>` to stderr and
  aborts the whole command — which `gate-lib.sh`'s
  `gate_trap_fail_closed` EXIT trap (the project's own by-design "any exit
  other than 0/2 is remapped to 2" safety net) then re-reports as
  `fail-closed: gate aborted (rc=1)`. Both lines land on stderr with a
  non-zero exit, identical in shape to this same gate's own ordinary
  refusal message — there is nothing in the output that says "the gate
  itself broke" versus "the gate refused your write."
- `warrant/hooks/scope-gate.sh`'s embedded Python body measured 22,941
  bytes at the pre-fix commit — under the ~64KB threshold on this sandbox's
  bash/kernel defaults, so today's exact bytes did not reproduce the failure
  through TMPDIR exhaustion alone (see "What did not work"). This does not
  make the heredoc form safe: the 64KB figure is bash's own internal pipe
  capacity, not a documented or guaranteed constant (it is
  `ulimit -p`/`fcntl(F_SETPIPE_SZ)`-tunable, and ordinary content growth over
  time — this file has grown by hundreds of lines across past issues — can
  cross it without any deliberate action). The one change that removes the
  exposure regardless of body size, TMPDIR state, or bash's internal
  threshold is not embedding the payload as shell-parsed input at all:
  loading a real file from disk needs no temp file, no pipe-vs-file size
  decision, and no `$TMPDIR` — `python3 <path>` opens a file that already
  exists in the repository checkout. This is acceptance option (a)
  ("succeeds without needing a heredoc temp file"), not option (b)
  (surfacing the cause distinctly while still failing closed); it was
  preferred because it removes the failure mode instead of relabeling it,
  and because the codebase already has an established, working precedent
  for this exact shape — `core/hooks/lib/gate-lib.sh` ships a sibling
  `gate-lib.py` loaded by every other gate via
  `importlib.util.spec_from_file_location(..., os.environ["GATE_LIB_PY"])`;
  this fix applies the same "real file, not heredoc" convention to a gate's
  *own* payload, not just the shared library it imports.
- Fail-closed behavior under exhaustion is preserved by construction: the
  fix does not touch any of the write-set/approval logic, only how the
  interpreter receives it, and the live before/after demonstration below
  confirms both the deny and allow branches still resolve correctly under
  the same exhausted `$TMPDIR`.

## What did not work

- First reproduction attempt used the unmodified, pre-fix
  `warrant/hooks/scope-gate.sh` heredoc (22,941 bytes) against a
  0-free-inode/0-free-byte tmpfs (`mount -t tmpfs -o size=16k,nr_inodes=2`,
  one filler file consuming the only spare inode, verified with
  `df -i` showing `100%`/`IFree=0`). The gate ran to completion normally
  (`warrant: refused — ... outside the write set ...`, exit 2) — no ENOSPC,
  no heredoc error. `strace -f -e trace=openat,pipe2` on this run showed
  only `pipe2()` calls and no `openat()` toward the constrained tmpfs at
  all, which is what led to identifying the ~64KB pipe/tempfile threshold
  above. Confirmed this is a real bash-version behavior (not a fluke) with
  four independent variations, all still using the pipe path: unquoted
  heredoc delimiter (parameter expansion active), `bash --posix`, a heredoc
  feeding the `read` builtin (no fork), and a heredoc feeding a shell
  function (no fork) — none of these forced the temp-file path either;
  only crossing the byte-size threshold did.
- Root-cause fixing all 25 other heredoc-using scripts in the same pass was
  out of scope for this issue (acceptance criterion 4 explicitly asks for
  audit + disposition, not a full fix) and was not attempted; see Open
  findings.

## Upstream basis

- `docs/issue-323/` issue body (verbatim, via `gh issue view 323`):
  acceptance criteria, the validity-consult, and the reporter's live
  observation of `warrant/hooks/scope-gate.sh:29`'s
  `here-document를 위한 임시 파일을 생성할 수 없음: 장치에 남은 공간이 없음`
  / `fail-closed: gate aborted (rc=1)`.
- `warrant/hooks/scope-gate.sh` @ `f30c9120df4014602a119d7debe1f0e44f5bdb23`
  (repo HEAD at session start) — pre-fix content, used as the basis for the
  extraction and for the padded reproduction copy.
- `core/hooks/lib/gate-lib.sh` @ same-commit — `gate_trap_fail_closed`
  (source of the `fail-closed: gate aborted (rc=$rc)` message) and the
  `GATE_LIB_PY` real-file-not-heredoc convention this fix follows.
- `core/hooks/tests/run-scope-gate-tests.sh`,
  `core/hooks/tests/run-role-gates-tests.sh` @ same-commit — regression
  suites rerun unchanged (see below).

### Live evidence (before / after)

Before (unmodified pre-fix `scope-gate.sh`, heredoc body padded from 22,941
to 94,599 bytes with an inert comment block *only* to cross this sandbox's
~64KB pipe/tempfile threshold — the padding changes no logic; see "Why" for
why the unpadded original does not cross it on this bash build), run inside
an unprivileged user+mount namespace with a tmpfs `$TMPDIR` at 0 free
inodes:

```
$ unshare --user --map-root-user --mount /bin/bash /tmp/repro_runner_before.sh "$CORE_ROOT"
/tmp/scope-gate-before-padded.sh: 줄 29: here-document를 위한 임시 파일을 생성할 수 없음: 장치에 남은 공간이 없음
fail-closed: gate aborted (rc=1)
outer-exit=2
```

This is byte-for-byte the failure mode the issue reports.

After (this session's fixed `warrant/hooks/scope-gate.sh`, real repo file,
unmodified — no padding needed or possible since there is no heredoc left),
same exhausted-tmpfs namespace, same deny-shape payload:

```
$ unshare --user --map-root-user --mount /bin/bash /tmp/repro_runner_after.sh "$CORE_ROOT" "$REPO_ROOT"
warrant: refused — `outside/thing.py` is outside the write set frozen by docs/proposals/p.md.
Approved paths: src/app.py
Finish what the proposal covers and report the rest; the discovered work becomes the next proposal. Widening the set mid-build is what the gate exists to prevent.
outer-exit=2
```

...and the allow-shape payload, same exhausted namespace:

```
$ unshare --user --map-root-user --mount /bin/bash /tmp/repro_runner_after_allow.sh "$CORE_ROOT" "$REPO_ROOT"
EXIT=0
outer-exit=0
```

Both the deny and allow branches resolve exactly as they would under a
normal, non-exhausted `$TMPDIR` — option (a) from the acceptance criteria:
the fixed gate needs no heredoc temp file at all, so there is nothing for
disk/inode exhaustion to break.

### Regression check (normal-condition behavior unchanged)

```
$ bash core/hooks/tests/run-scope-gate-tests.sh 2>&1 | tail -1
== 46 passed, 0 failed ==

$ bash core/hooks/tests/run-role-gates-tests.sh 2>&1 | tail -1
role-gates: 83 passed, 0 failed
```

Also ran (pre-existing state, to rule out a regression from this change —
confirmed identical pass/fail counts on unmodified HEAD via `git stash`):
`run-approval-gate-tests.sh` (64 passed, 2 failed — both pre-existing,
unrelated to scope-gate: `checkpoint-refusal-names-await-approval`,
`execute-without-remote`), `run-board-gate-tests.sh` (143 passed, 2 failed
— pre-existing, unrelated: `feasibility-spikes`, `ops-postmortems`),
`run-dispatcher-equivalence-tests.sh` (24 passed, 1 failed — pre-existing,
unrelated: `approval-gate: execution write, no approvers.md -> deny`),
`run-canon-duplication-content-tests.sh` (4 passed, 0 failed, including the
"vendored scope-gate.sh" byte-identity checks), and `parse-check.sh` (49/49
`ok`, bash-3.2 syntax parse of every `core/hooks` script — this fix does not
touch `core/hooks`).

## Open findings

Per acceptance criterion 4 — disposition of every other heredoc-using hook
script identified this session. The issue's own grep counted 22 scripts
total (scope-gate.sh + 21 others); this session's audit used a slightly
wider net (`<<DELIM` heredocs feeding any command, `<<'DELIM'`-into-`read`,
a `while ... done <<DELIM` loop redirection, and one here-string `<<<`) and
found 25 other non-test scripts sharing the identical shell-level mechanism
— the discrepancy is disclosed rather than silently reconciled, since the
issue text doesn't include its own file list to diff against. Test-only
fixture scripts under `*/hooks/tests/` (which construct throwaway heredocs
inside isolated subprocess fixtures, not live PreToolUse/SessionStart gates)
are excluded from this list as out of the issue's stated scope ("hook
scripts").

None of the 25 are fixed in this pass — deferred to a follow-up issue, with
the same "extract to a real sibling file, drop the heredoc" fix from this
PR as the recommended starting pattern. All share scope-gate.sh's exact
exposure mechanism (bash's pipe-if-small/tempfile-if-large heredoc
implementation); none currently exceeds the ~64KB threshold on this
sandbox's bash/kernel defaults, so none reproduce the failure today the way
the padded scope-gate.sh copy did above — but per "Why," that threshold is
an internal bash constant, not a safety property, so "under 64KB today" is
not a reason to leave any of them as-is long-term.

`python3 <<'PY'/<<'PYEOF' ...` payload heredocs (fork into an external
interpreter; same mechanism as scope-gate.sh's original form):
- `core/hooks/facet-keyword-gate.sh` — 11,860 bytes
- `core/hooks/record-shape-gate.sh` — two heredocs, 8,543 and 6,490 bytes
- `core/hooks/survey-order-gate.sh` — 4,565 bytes
- `core/hooks/handbook-trigger-gate.sh` — 7,319 bytes
- `core/hooks/proposal-shape-gate.sh` — 6,341 bytes
- `core/hooks/ordering-gate.sh` — 25,665 bytes (largest of this group)
- `core/hooks/citation-gate.sh` — 23,078 bytes
- `core/hooks/trailer-gate.sh` — 14,289 bytes
- `core/hooks/record-fields-gate.sh` — 18,445 bytes
- `warrant/hooks/hunt-guard.sh` — 4,233 bytes
- `warrant/hooks/state.sh` — 3,600 bytes

`IFS='' read -r -d '' VAR <<'PY' || true` heredocs (content lands in a shell
variable, later passed to `python3 -c "$VAR"` — same bash heredoc mechanism
at the point of creation, so the same exposure; the `-c` hop is a separate,
unrelated concern this issue doesn't cover):
- `core/hooks/board-gate.sh` — 43,685 bytes (closest to the ~64KB
  threshold of anything audited; highest-priority candidate for the
  follow-up fix)
- `core/hooks/approval-gate.sh` — 21,433 bytes
- `core/hooks/gh-guard.sh` — 4,459 bytes

`cat <<EOF ... EOF` heredocs (short, static help/reminder text to stdout;
same mechanism, but all measured well under 2KB so practically the lowest
priority in the group):
- `core/hooks/directive.sh` — three heredocs, 435/1,948/359 bytes
- `core/hooks/proposal-shape-directive.sh` — 260 bytes
- `core/hooks/survey-order-directive.sh` — 229 bytes
- `core/hooks/record-shape-directive.sh` — 260 bytes
- `core/hooks/lib/role-directive.sh` — 502 bytes
- `terse/hooks/terse.sh` — 282 bytes
- `freelunch/hooks/freelunch.sh` — 467 bytes
- `scout/hooks/directive.sh` — 303 bytes
- `warrant/hooks/directive.sh` — 462 bytes

Other forms found by this session's wider net, not counted in the issue's
"22":
- `warrant/hooks/hunt-tier.sh` — `done <<EOF2` (while-loop redirection),
  11 bytes — negligible in practice.
- `core/hooks/lib/gate-lib.sh` — `done <<< "$other"` here-string; body size
  is runtime-dependent (a filtered grep of the hook file under
  inspection), not statically bounded, but observed sizes are small.
  Included for completeness since it's the same bash mechanism, even
  though it's a here-string rather than a heredoc.

Filing the follow-up issue is left to the user/maintainers: this role
picks up an assigned issue and does not self-file new ones per the
role-handoff contract's invariants.

## Next steps

None for this issue — landed. Resolution path for the 25 other scripts in
Open findings: a follow-up issue (highest-priority target:
`core/hooks/board-gate.sh`, at 67% of the observed threshold), applying
this PR's "extract to a real sibling file, drop the heredoc" pattern to
each; filing that issue is left to the user/maintainers per the
role-handoff contract's invariants (this role does not self-file issues).

skill-verdict: work-in-english — applied: invoked; all commit messages, code comments, this record, and the PR body are written in English, with only the final chat reply to the user in Korean.
skill-verdict: implementation-blueprint — applied: invoked; ran `python3 <skill-dir>/scripts/prep.py classify --single-file`, got `VETO: single file, single concern, no callers -> no-structure` — confirms the mechanical heredoc-to-real-file extraction needed no architectural restructuring beyond what was done.
other mounted skills: not triggered (implementation-complexity-coupling-management, implementation-design-pattern-selection, implementation-performance-data-structure-choice, conformance-review-finding-record — none applicable to this bugfix).
