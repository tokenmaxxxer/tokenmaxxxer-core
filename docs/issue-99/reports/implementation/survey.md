---
kind: current-state-survey
subject: issue-99
produced_by: implementation
loop_state: surveyed
---

# Survey: issue-99 — board-gate's dead fallback allows a relative-path write it should adjudicate, and non-redirect write verbs carry the same gap

## Scope

`core/hooks/board-gate.sh`'s `Bash` candidate builder
(`board-gate.sh:256-274` on the live file, `main` at the time of this
survey). Two defects, both confirmed live against the current file, not
just against the issue's prose:

1. The `candidates.append(DOCS)` fallback at `board-gate.sh:272` is
   annotated `# mentioned but unextractable: adjudicate` but structurally
   cannot adjudicate anything — it always reaches `allow()`.
2. The gap is not specific to `>`/`>>` redirection: any write-shaped
   command whose relative target carries no `docs/` token of its own
   (`cp`, `mv`, or any other write verb) hits the identical dead branch.

## 1. Defect 1 — the fallback can never survive hit-extraction

```python
# board-gate.sh:260-272 (current main)
if DOCS in cmdline:
    failing_segments = _write_candidate_segments(cmdline)
    if not failing_segments:
        allow()
    scan_text = "\n".join(failing_segments)
    for tok in re.findall(r"[\w./~$-]*%s[\w./-]*" % re.escape(DOCS), scan_text):
        candidates.append(tok)
    if not candidates:
        candidates.append(DOCS)   # mentioned but unextractable: adjudicate
```

`DOCS = "docs/"` (`:99`). Hit-extraction, a few lines later:

```python
# board-gate.sh:276-288
def norm(p):
    return posixpath.normpath(p.replace("\\", "/"))

hits = []
for c in candidates:
    n = norm(c)
    idx = n.find(DOCS)
    if idx >= 0:
        tail = n[idx + len(DOCS):]
        if tail:
            hits.append(tail)
if not hits:
    allow()
```

`posixpath.normpath("docs/")` is `"docs"` (trailing slash stripped), and
`"docs".find("docs/")` is `-1`. The `DOCS` candidate the fallback appends
can never produce a hit, regardless of what actually happened — the
branch its own comment says exists to adjudicate always ends at
`allow()` instead. This exact defect is already root-caused, independent
of this survey, by `docs/issue-90/reports/execution-observation.md`
("Finding 1", produced observing PR #91/issue-90) — that record traces
the identical mechanism against the same commit still on `main` and
recommends fixing it as an action item for the human to judge, which is
this issue.

### Traced repro (this survey, live file)

Session: role `qa`, branch `issue-3/qa` (the shape the issue's own
report uses). Command: `cd docs/issue-49 && date > x.md`.

- `_split_segments` cuts on `&&`: `"cd docs/issue-49"`, `" date > x.md"`.
- Segment 1: head `cd` is in `READ_ONLY_HEADS` (`:103`) → classified
  read-only, dropped from `failing_segments`.
- Segment 2: `FILE_REDIR` matches `> x.md` → the only segment scanned.
- `re.findall` over `"date > x.md"` finds no `docs/`-shaped token (there
  isn't one — the path is relative, established only by segment 1's
  `cd`, which the scan never revisits).
- `candidates` is empty → fallback appends `DOCS` → yields no hit → 71/71
  of the existing harness's cases are unaffected, but this exact shape
  reaches `allow()` at `:288` with **no adjudication at all**, even
  though the write lands at `docs/issue-49/x.md` from a session branched
  `issue-3/qa` — precisely what R4 exists to refuse.

Confirmed empirically this session, against the live `board-gate.sh`,
using the existing test harness's own `run()`/`mktd` fixtures
(`core/hooks/tests/_tmp.sh`, `core/hooks/tests/run-board-gate-tests.sh`)
in a disposable scratch copy, never committed:

| command | got |
|---|---|
| `cd docs/issue-49 && date > x.md` | **allow** (want: deny, R4) |

## 2. Defect 2 — the same gap for non-redirect write verbs

`FILE_REDIR = re.compile(r">>?(?!&)")` (`:116`) only recognizes
`>`/`>>`. A write-capable command whose target is a plain argument, not
a redirect — `cp`, `mv` — is not in `READ_ONLY_HEADS`
(`:100-103`), so `_write_candidate_segments` already correctly marks it
"not proven read-only" (unaffected by Defect 1's fix). But its target
argument (`x.md`) still carries no `docs/` token of its own when the
directory context comes only from a preceding `cd`, so it falls into the
identical dead fallback:

| command | got |
|---|---|
| `cd docs/issue-49 && cp /tmp/a x.md` | **allow** (want: deny) |
| `cd docs/issue-49 && mv /tmp/a x.md` | **allow** (want: deny) |

This is not fixed by patching `FILE_REDIR` — `cp`/`mv` never match it —
and it is not fixed by Defect 1's fix alone either, since both defects
share the same root: the candidate builder never carries a preceding
`cd`'s directory context forward to a later segment.

## 3. Negative space that must not regress

Two shapes must keep their current `allow` verdict; both were confirmed
this session against the live file:

- **Issue-90's own case 1** — `date; grep -n foo
  docs/issue-49/reports/x.md` (a genuinely read-only `grep` on a foreign
  issue's path, sharing a line with an unrelated, unclassifiable `date`)
  — `allow`, unchanged. This is the false positive issue-90 fixed; a
  naive "fail closed whenever candidates end up empty" fix would
  reintroduce it, because this shape *also* reaches the same empty-
  candidates fallback, for an unrelated, safe reason (the `docs/` mention
  lives in an already-read-only segment, not a write-classified one).
- **A role's own legitimate `cd`-then-write into its own issue tree** —
  `cd docs/issue-3/reports && date > qa.md` (role `qa`, branch
  `issue-3/qa`, writing its own record) — `allow`, and must stay `allow`
  through genuine R1-R5 adjudication, not by accident of the same dead
  fallback that currently allows Defect 1's foreign-issue case for the
  wrong reason.

## 4. What distinguishes the two "empty candidates" cases

Whether the docs/ mention that satisfied the outer `if DOCS in cmdline:`
guard sits inside a segment already proven read-only (negative space,
safe) or was established by a **preceding `cd` into a `docs/` path**
that a later write-classified segment inherits (Defect 1/2, unsafe).
`_write_candidate_segments` already computes per-segment
read/fail classification (issue-90); it does not currently track `cd`
targets or segment order relative to a `cd`. The report attached to this
issue names the same discriminator: "앞선 읽기 전용 세그먼트가 `docs/`
경로로 `cd` 했는가" (did a preceding read-only segment `cd` into a
`docs/` path).

## 5. A related, pre-existing gap this issue's fix does not close

Reconstructing only the `cd`-target **directory** (not the exact write
target filename) is enough to re-run R1-R4 correctly (bucket layout,
contract, role, branch), because none of those need the filename. It is
**not** enough for R5 (per-file ownership inside `reports/`), which
needs the exact filename to compare against `<role>.md`. Confirmed this
session, against the live (unpatched) file — this gap already exists on
`main`, independent of any fix in this issue:

| command | got | R5 would want |
|---|---|---|
| `cd docs/issue-3/reports && cp /tmp/a qa.md` (own record) | allow | allow (correct by luck) |
| `cd docs/issue-3/reports && cp /tmp/a review.md` (foreign role's record, same issue) | allow | **deny** |

This is a same-issue, cross-role variant of the exact defect class this
issue reports, reachable today with no `cd`-tracking fix at all (the
existing dead fallback already allows it). Closing it needs extracting
the actual write-target filename per write verb (which argument is the
destination differs by command — `cp src dst`, `mv src dst`, redirect's
target follows `>`), which is a materially larger, per-command surface
than reconstructing a directory. The proposal accompanying this survey
decides whether this belongs in this issue's write set or is named
explicitly as an out-of-scope residual for a follow-up issue.

## 6. Verified fix shape and empirical reachability check

A prototype (disposable scratch copy of `board-gate.sh`, plus a scratch
copy of `run-board-gate-tests.sh` pointed at it, both deleted before this
survey was committed) restructured the `Bash` candidate builder to walk
`_split_segments` output in **order**, tracking the most recent
`docs/`-mentioning `cd` target as `cd_tail` (sticky — never cleared by a
later non-`docs/` `cd`, deliberately not a full relative-path resolver),
and reconstructing `DOCS + cd_tail` as a candidate for any later
write-classified segment that carries no `docs/` token of its own.

Result against the full existing harness plus the cases above:

- `bash core/hooks/tests/run-board-gate-tests.sh` (pointed at the
  prototype): **71 passed, 0 failed** — zero regressions.
- `cd docs/issue-49 && date > x.md` → **deny**, `board-gate: writing
  docs/issue-49/ requires branch issue-49/qa (current: issue-3/qa)...`
  — the exact R4 reason, matching this issue's own reported local
  experiment.
- `cd docs/issue-49 && cp /tmp/a x.md` and `... && mv /tmp/a x.md` →
  **deny**, same R4 reason — the write-verb gap closes for `cp`/`mv`
  specifically, and generically for any other write verb, because the
  fix does not depend on identifying which argument is the write target.
- `date; grep -n foo docs/issue-49/reports/x.md` → **allow**, unchanged
  (negative space held).
- `cd docs/issue-3/reports && date > qa.md` → **allow**, unchanged, and
  now via genuine R1-R4 adjudication (R4's branch check actually runs
  and actually matches), not via the dead fallback's accidental allow.
- `cd docs/issue-49 && cd /tmp && date > y.md` (cd's back out of docs/
  before the write) → **deny** — a false positive the sticky, no-un-set
  design deliberately accepts (over-blocking, this file's established
  "safe direction" — `board-gate.sh:267`), traced and named rather than
  silently produced.
- The section 5 (same-issue cross-role) gap above is **not** closed by
  this prototype — reproduces identically before and after, confirming
  it is pre-existing and independent of this fix, not a new hole this
  fix opens.

This satisfies the issue's explicit pitfall warning against adding a
branch whose reachability is not proven by measurement (its own cited
example: a "rescan the whole line, deny if still nothing" fallback would
be structurally unreachable — the entry guard `if DOCS in cmdline`
already guarantees the literal `docs/` is present somewhere on the line,
so a whole-line rescan for that same literal can never come back empty).
That exact shape was considered and rejected for this reason; see the
proposal's Rationale.

## Existing test harness baseline

`bash core/hooks/tests/run-board-gate-tests.sh` on `main`, unmodified:
**71 passed, 0 failed** (2026-08-03, this session).
