---
issue: 303
role: secure-coding
code_under_review:
  - core/hooks/gh-guard.sh
  - core/hooks/approval-gate.sh
  - core/hooks/board-gate.sh
  - core/hooks/pretooluse_dispatcher.py
  - core/hooks/tests/run-gate-shape-tests.sh
  - core/hooks/tests/run-all.sh
loop_state: landed
type: fix
breaking: false
verdict: pass
upstream:
  - path: docs/issue-301/reports/observability.md
    sha: e7da480bbcc6aaf2b868a0da90733def23589f99
requirement_id: F15, F17 (docs/issue-301/reports/observability.md)
level: L2
---

# issue-303 — secure-coding record

## What was done

Closed the JSON `\uXXXX`-escape gate-bypass the #301 sweep found in
`gh-guard.sh` (F15) and `approval-gate.sh` (F17): both scripts' bash-level
fast paths ran `case "$payload" in *<substring>*) ;; *) exit 0 ;; esac`
against the **raw, unparsed** stdin JSON text before python3/`json.loads`
ever ran. A payload that JSON-escapes one character of the matched
substring — `gh` for `gh`, `src/` for `src/` — decodes to a
byte-identical command/path but never contains the literal substring the
`case` scans for, so the fast path silently fell through to `exit 0`
(allow) and the entire python judge — the deny logic itself — never ran.

Fix, in both files: a payload carrying any JSON `\u` escape now always
falls through to the python judge, regardless of whether it also happens
to match the plain-text patterns. This preserves the fast path's
performance intent (an ordinary payload with no relevant content and no
`\u` escape still skips python3 entirely) while removing its ability to
be blinded by escaping.

```bash
case "$payload" in
  *'\u'*) ;;
  *'"Bash"'*) ;;
  *) trap - EXIT; exit 0 ;;
esac
```

**Scope note (verified live, beyond F15/F17):** while reproducing the
#301 record's claim that `board-gate.sh` is "not vulnerable... its fast
path keys on the literal substring `docs`, which contains no escapable
`/`", I tested escaping a *letter* of `docs` instead of the `/` (e.g.
`docs/badbucket/x.md`) and it does bypass `board-gate.sh`'s fast
path today — the #301 check only ruled out the slash, not the whole
word. Same defect family, same fix pattern; applied to `board-gate.sh`
alongside the two named findings so the acceptance's own claim ("keep
[board-gate.sh] that way") is true rather than merely asserted.

**Scope note 2 (production surface, found during verification):**
`core/hooks/hooks.json` registers only `pretooluse-dispatcher.sh` →
`pretooluse_dispatcher.py` for `PreToolUse` — the `.sh` gates are the
on-disk policy source of truth, but `pretooluse_dispatcher.py`'s
`_setup_approval_gate`/`_setup_board_gate`/`_setup_gh_guard` functions
independently re-derive each gate's raw-text fast-path check (its own
module docstring: "replicates each gate's bash preamble... cheap
fast-path checks"). That duplication had drifted: the dispatcher's copy
carried the identical F15/F17/board-gate bug, live, in the script that
is actually enforced. A fix landed only in the `.sh` files would have
left production bypassable. Added a shared `_payload_escaped()` helper
and gated all three setup functions' skip conditions on it.

New regression suite `core/hooks/tests/run-gate-shape-tests.sh` (named
in the issue's Acceptance) pins all of this: escaped-vs-unescaped
identical verdict for gh-guard/approval-gate/board-gate, both directly
against the `.sh` files and through the dispatcher (`OTR_DISPATCH_ONLY`),
plus the empty-state case (an irrelevant payload still fast-skips and
never invokes python3, proving the performance intent survived) and a
pin that `ordering-gate.sh` still has no bash-level fast path to
regress. Wired into `run-all.sh`.

## Why

The record's own diagnosis (docs/issue-301/reports/observability.md:282-326)
names the fix pattern directly: "match after JSON normalization (or drop
the raw fast-path where it cannot be made escape-safe)." Decoding the
whole payload with `json.loads` before every fast-path check would also
close the hole, but it throws away the fast path's entire reason to
exist — the header comments on all three gates are explicit that the
point is avoiding a ~50ms python3 startup on the large majority of tool
calls the gate has no business in. Detecting the *presence* of a `\u`
escape is a single cheap substring scan (no parsing), so it keeps the
common case fast while making the fast path safe: it degrades from "skip
on no match" to "skip on no match AND no escape," which is a strictly
narrower — never wider — allow surface than before. This is the
[[secure-coding-input-validation-injection-defense]] skill's rule 9 in
practice for the dispatcher fix specifically: the `.sh` files and
`pretooluse_dispatcher.py` are two independently maintained copies of the
same raw-text check, and per rule 9 they had already diverged (the
dispatcher lagged and, before this fix, was the *only* copy an attacker
would actually meet). Full de-duplication of the two copies is the
larger issue #282 architecture and is out of scope for this fix; both
copies now carry the same corrected logic, and the duplication itself is
carried into Open findings below as a latent recurrence risk rather than
silently left for a future session to rediscover.

### Rejected alternative

Fully parsing the payload with `json.loads` inside the bash-level fast
path (via a `python3 -c` one-liner) before deciding to skip, instead of
the substring-presence check. Rejected: this reintroduces a python3
startup on every single tool call regardless of relevance, which is
exactly the cost the fast path exists to avoid (per each gate's own
header comment and the Acceptance's explicit "empty state... still skip
cheaply (fast-path performance intent preserved)" clause) — it does not
merely weaken the optimization, it deletes it.

## Upstream basis

docs/issue-301/reports/observability.md (sha
e7da480bbcc6aaf2b868a0da90733def23589f99), findings F15
(`core/hooks/gh-guard.sh:42-45`) and F17
(`core/hooks/approval-gate.sh:87-92`), plus the record's board-gate.sh
non-vulnerability claim (line 325-326) that this record's board-gate.sh
fix supersedes with a corrected, executed result.

## Open findings

- **`pretooluse_dispatcher.py` duplicates each `.sh` gate's fast-path
  check by design** (issue #282 Part 2's architecture) rather than
  sourcing it from one place; this is exactly the shape rule 9 of
  [[secure-coding-input-validation-injection-defense]] warns drifts over
  time — it already had, for this exact bug, before this record. Not
  fixed here (out of scope: a de-duplication would be an issue #282-
  scale refactor, not a bugfix), but left explicit rather than silent:
  a future change to any of the three gates' fast-path patterns must
  remember to mirror it into the matching `_setup_*` function, and
  `run-gate-shape-tests.sh`'s dispatcher-routed pins are the regression
  net if that mirroring is missed again.
- No other open findings; F15, F17, and the verified board-gate.sh
  extension are closed with executed evidence below.

## Acceptance verification (executed-live)

Gate command, per the issue's Acceptance:

```
$ env -u CORE_BUILD_NOW bash core/hooks/tests/run-gate-shape-tests.sh
ok     gh-guard-unescaped-merge-denies            deny
ok     gh-guard-escaped-merge-still-denies-F15    deny
ok     gh-guard-irrelevant-payload-fast-skips     allow
ok     gh-guard-irrelevant-payload-never-reaches-python3 not-invoked
ok     approval-gate-unescaped-src-write-denies   deny
ok     approval-gate-escaped-src-write-still-denies-F17 deny
ok     approval-gate-escaped-src-bash-write-still-denies-F17 deny
ok     approval-gate-irrelevant-payload-fast-skips allow
ok     approval-gate-irrelevant-payload-never-reaches-python3 not-invoked
ok     board-gate-unescaped-badbucket-denies      deny
ok     board-gate-escaped-badbucket-still-denies  deny
ok     board-gate-irrelevant-payload-fast-skips   allow
ok     board-gate-irrelevant-payload-never-reaches-python3 not-invoked
ok     ordering-gate-no-bash-fast-path            absent
ok     dispatcher-gh-guard-escaped-merge-denies-F15 deny
ok     dispatcher-approval-gate-escaped-src-denies-F17 deny
ok     dispatcher-board-gate-escaped-badbucket-denies deny
ok     dispatcher-irrelevant-payload-allows-full-chain allow

== 18 passed, 0 failed ==
```

Replaying the #301 record's exact F15 payload directly against the fixed
gate:

```
$ printf '{"tool_name": "Bash", "tool_input": {"command": "gh pr merge 42 --squash"}}' \
  | env CLAUDE_ROLE=implementation /bin/bash core/hooks/gh-guard.sh
gh-guard: refused for role session 'implementation': merging or closing a PR is the human's acceptance/refusal — a role session only opens PRs and pushes to its own issue branch. (two-account model, contract v3 s8)
exit:2
```

...identical to the unescaped baseline (`gh pr merge 42 --squash`, same
deny text, exit 2) — the escaped payload no longer bypasses. The F17
payload against `approval-gate.sh` and both against
`pretooluse_dispatcher.py` (the actual production hook) were verified
the same way; full transcripts are the individual `Bash` calls in this
session, condensed into the pinned test cases above rather than repeated
here.

Empty-state check (irrelevant payload, both gates): `run-gate-shape-tests.sh`'s
`*-irrelevant-payload-fast-skips`/`*-never-reaches-python3` pairs stub
`python3` with a marker-writing script and assert the marker is never
created — the fast path still short-circuits before python3 starts,
confirmed for `gh-guard.sh`, `approval-gate.sh`, and `board-gate.sh`
individually and for the dispatcher's full (non-`OTR_DISPATCH_ONLY`)
chain.

Full repository suite (`core/hooks/tests/run-all.sh`), run with
`CORE_BUILD_NOW` unset to avoid this session's own build-now bypass
stamp leaking into subprocess tests that don't explicitly clear it:
every suite passed except one pre-existing, environment-caused failure
— see What did not work.

## What did not work

- `core/hooks/tests/run-dispatcher-equivalence-tests.sh`'s
  "dispatcher end-to-end latency < 100ms" timing assertion failed
  (270ms-1321ms observed across repeated runs) under this shared
  machine's load at the time (`uptime`: load average ~235 on a 16-core
  box, from several other concurrent role/spawner sessions visible in
  `ps aux`). Confirmed environmental, not a regression: `git stash`-ing
  every change in this record and re-running the identical timing
  assertion against the unmodified pre-fix code reproduced the same
  failure (821ms) on the same loaded machine. The added code itself is
  one `"\u" in payload` substring scan per gate (three total across the
  chain) — negligible next to the already-dominant subprocess-spawn
  cost the assertion measures. Not re-run to a clean pass because the
  session has no way to quiet the other concurrent sessions on this
  shared box; left as an environment-flake note rather than silently
  omitted.
- The `#301` record's own board-gate.sh non-vulnerability claim (line
  325-326, reasoning "no escapable `/`") did not hold under a
  differently-escaped payload (a `docs` letter, not the slash) — not a
  process failure of this session, but recorded because that claim is
  quoted verbatim in this issue's own body, and the acceptance criteria
  assumed it was still true.

## Skill verdicts

skill-verdict: secure-coding-input-validation-injection-defense —
applied: invoked; loaded after gh-guard.sh/approval-gate.sh/board-gate.sh
were already fixed but before the pretooluse_dispatcher.py duplication
fix and this record were written (process gap: should have loaded before
the first code edit per invoke-before-apply, noted rather than repeated
— matches the #301 record's own prior note about the same ordering gap).
Rule 9 (duplicate validation layers drift; keep validation at the
trust-boundary crossing point, or when duplication must stay, keep both
copies identical) is cited directly in Why above to justify fixing
`pretooluse_dispatcher.py`'s independent copy of the fast-path checks
rather than treating the `.sh` files as sufficient, and its "diverge over
time" framing is exactly what was found live (the dispatcher's copy had
already diverged from a-would-be-fixed `.sh` file, in production, before
this record). Rules 1/3/4/6/7 (allowlist regex fields, fixed-option
exact-match, free-form-text sink encoding, SQL parameterization, HTML/JS/
URL sink encoding) are not applicable: no such input shapes appear in
this change. Rule 2 (remove denylist-only defenses) does not apply as
written — the fast path is documented as "an optimization, never a
verdict," not the security control itself (the python judge downstream
is), so there was no denylist-as-sole-defense to remove; the actual
defect was closer to rule 8's "fail open on inputs the validator
couldn't confidently classify," fixed by making the fast path abstain
(fall through) rather than allow whenever it meets an escape it doesn't
understand. Rule 5 (parameterized OS calls) does not apply: no shell
command is built from untrusted data in this change. Rule 10 (scope a
review pass to changed trust boundaries) matches this record's own
scope discipline in spirit (F15/F17 plus the two live-verified
extensions, not a repo-wide re-audit) but was not itself consulted as a
review-scoping instruction, since this was a fix delivery, not a review
pass.
other mounted skills: not triggered (secure-coding-authorization-access-control,
secure-coding-cryptography-secrets-management,
secure-coding-dependency-supply-chain-security,
secure-coding-session-authentication — none of authorization/permission
grants, encryption/secret lifecycle, third-party dependency vetting, or
session/cookie/token handling is decided by this change)
