---
status: proposed
files:
  - core/hooks/lib/gate-lib.sh
  - core/hooks/tests/stub-check.sh
  - core/hooks/tests/compliance-check.sh
  - core/hooks/tests/run-fleet-scan-tests.sh
  - docs/issue-173/reports/implementation/survey.md
  - docs/issue-173/proposals/2026-08-08-canon-duplication-stub-distinction.md
---

## Request

`compliance-check.sh --canon-duplication` currently flags any file named
`directive.sh` found under a scanned rulebook path as a vendored copy of
core canon, with no content check. But per the canon-rollout checklist,
a correctly-rolled-out rulebook keeps a small per-repo `directive.sh`
stub (source `role-directive.sh`, call `core_role_directive`) instead of
deleting it — so a correctly-rolled-out repo can never pass this scan.
Add a content-based distinction so a sanctioned stub scans clean while a
genuinely vendored full copy still flags, per the issue's Acceptance.

## Constraints

- `directive.sh` is the only manifest entry with "keep a stub" semantics
  today (`docs/handbooks/canon-rollout.md` step 1 vs step 3); every other
  manifest name keeps its existing absence-only check unchanged.
- No change to `stub-check.sh`'s own observable pass/fail behavior — its
  classification logic is reused, not altered.
- Stay inside the existing bash 3.2-compatible, `set -uo pipefail` shell
  style already used throughout `core/hooks/tests/` and `core/hooks/lib/`.

## Rationale

Considered duplicating the stub-vs-boilerplate classification (source
line + `core_role_directive` call + `canon-forms.txt`-matched line shapes)
directly inside `compliance-check.sh`, independent of `stub-check.sh`.
Rejected: `stub-check.sh` already implements this exact classification for
this exact file, and a second, independently-maintained copy inside
compliance-check.sh is precisely the drift class this codebase's own
`canon-manifest.txt` reuse already exists to prevent (compliance-check.sh's
own header states this concern about the manifest; the same logic applies
to the classification code, not just the file list).

Also considered a simpler size/marker heuristic (e.g. "under N lines and
contains the string `core_role_directive`") instead of reusing
stub-check.sh's full line-by-line shape check. Rejected: a marker/size
heuristic would accept a stub that calls `core_role_directive` but also
regrows removed boilerplate around it (the exact failure stub-check.sh
was built to catch, issue-78/83) — weakening the check compliance-check.sh
is meant to strengthen, and diverging from what stub-check.sh already
treats as "ok" for the identical file.

Chosen approach: extract stub-check.sh's directive.sh classification into
a shared `gate_is_role_directive_stub <file>` function in `gate-lib.sh`
(the library both scripts already source), have stub-check.sh call it in
place of its inline block (behavior-preserving refactor), and have
compliance-check.sh's `--canon-duplication` loop call it for any hit named
`directive.sh` — flagging only when the function says "not a stub" —
while every other manifest name keeps the current unconditional
filename-match FAIL.

## What will be done

- Add `gate_is_role_directive_stub <file>` to `core/hooks/lib/gate-lib.sh`:
  loads `canon-forms.txt` from `core/hooks/tests/` (same path stub-check.sh
  resolves today), runs the same source-line / `core_role_directive` /
  remaining-line-shape checks stub-check.sh currently runs inline, and
  returns 0 (is a sanctioned stub) or 1 (not) plus a reason string.
- Update `stub-check.sh` to call the new function for each `directive.sh`
  hit instead of running the check inline, preserving its existing output
  messages and exit behavior.
- Update `compliance-check.sh`'s `--canon-duplication` loop: when
  `name = directive.sh`, for each `find` hit, call
  `gate_is_role_directive_stub` on it — pass (no FAIL, "ok" line) when it
  reports a sanctioned stub, FAIL (existing vendored-copy message) when it
  does not. All other manifest names keep the current unconditional
  filename-match behavior.
- Add the red-green pair to `core/hooks/tests/run-fleet-scan-tests.sh`:
  a synthetic rulebook dir with a correct `directive.sh` stub scans clean
  under `--canon-duplication`; a synthetic rulebook dir with a full/vendored
  `directive.sh` body (e.g. copying `scout/hooks/directive.sh`'s shape)
  still flags.

- Wiring `run-fleet-scan-tests.sh` into `run-all.sh` — pre-existing gap
  (warrant hunt, `docs/reports/2026-08-08-hunt-canon-duplication-stub-distinction.md`):
  `run-all.sh` already did not invoke `run-fleet-scan-tests.sh` before this
  proposal (introduced with that file in the #170/issue-168 work), so this
  proposal's new red-green pair inherits that pre-existing gap rather than
  creating it. Fixing the aggregate wiring is a separate, unrelated concern.

## Out of scope

- Running the live `--canon-duplication` scan against any of the 43
  sibling rulebook repos, or updating the #171 pilot record — this repo
  has no write access there; `docs/handbooks/canon-rollout.md`'s "What
  this repo does NOT do" section already states this boundary. The
  issue's second acceptance line (pilot repo re-scans clean, recorded on
  #171) is for #171's own branch/session once this fix lands, not this
  proposal's write set.
- Any change to `canon-manifest.txt`'s entries, `canon-forms.txt`'s
  registered shapes, or `role-directive.sh` itself.
- Extending "keep a stub" content-based checking to any manifest entry
  other than `directive.sh` — no other entry has stub semantics today.

## How you'll know it worked

- `core/hooks/tests/run-fleet-scan-tests.sh` passes, including the new
  stub-vs-vendored red-green pair.
- `core/hooks/tests/run-stub-canon-forms-tests.sh` still passes unchanged
  (stub-check.sh's own behavior is preserved through the refactor).
- Manually: `compliance-check.sh --canon-duplication <dir>` against a
  synthetic dir containing only a sanctioned `directive.sh` stub exits 0;
  against a synthetic dir containing a full vendored `directive.sh` body
  exits 1.
