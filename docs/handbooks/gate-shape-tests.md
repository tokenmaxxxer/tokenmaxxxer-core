# gate-shape test harness (issue-303: JSON `\uXXXX`-escape fast-path bypass)

`core/hooks/tests/run-gate-shape-tests.sh` exercises the raw-text
bash-level fast path every `core/hooks/*.sh` PreToolUse gate runs before
its python3 JSON judge starts. Run it directly, no setup required:

    bash core/hooks/tests/run-gate-shape-tests.sh

## What it pins

Several of core's gates skip their python3 judge with a cheap
`case "$payload" in *<substring>*) ;; *) exit 0 ;; esac` match against the
**raw, unparsed** `PreToolUse` JSON on stdin — avoiding a python3
startup (~50ms) on the large majority of tool calls the gate has no
business adjudicating. That match runs before `json.loads`, so it is
fooled by JSON's own escaping: a payload that spells one character of the
matched substring as `\uXXXX` (e.g. `gh` as `gh`, `src/` as
`src/`, `docs` as `docs`) decodes to a byte-identical parsed
string but never contains the literal substring the `case` scans for. The
fast path then silently `exit 0`s — allow — without the python judge (the
gate's actual deny logic) ever running. Confirmed live for:

- `gh-guard.sh` (issue-301 F15, `docs/issue-301/reports/observability.md:282`)
- `approval-gate.sh` (issue-301 F17, `docs/issue-301/reports/observability.md:309`)
- `board-gate.sh` — the #301 record itself claimed this one was safe
  ("fast path keys on the literal substring `docs`, which contains no
  escapable `/`"), but that reasoning only ruled out escaping the slash.
  Escaping a *letter* of `docs` instead bypasses it the same way; found
  live while verifying the record's claim for issue-303, not assumed.
- `pretooluse_dispatcher.py` — `core/hooks/hooks.json` registers only this
  dispatcher for `PreToolUse`, not the `.sh` files directly (see
  `docs/handbooks/core.md`/the dispatcher's own module docstring). Its
  `_setup_approval_gate`/`_setup_board_gate`/`_setup_gh_guard` functions
  independently re-derive each gate's raw-text fast-path check rather than
  sourcing it from the `.sh` file, and that copy had drifted: it carried
  the identical bug in the script that is actually enforced in production,
  even after the `.sh` files were fixed. `core/hooks/pretooluse_dispatcher.py`'s
  `_payload_escaped()` helper is the fix, consulted by all three setup
  functions' skip conditions.

`ordering-gate.sh` has no bash-level substring fast path at all (payload
goes straight from stdin into `json.loads`), so nothing to fix there; this
harness pins that absence too (`ordering-gate-no-bash-fast-path`), so a
future change that adds one is caught by the same suite instead of
silently reintroducing the bug class in a fifth place.

## The fix pattern

Every fixed fast path gained one extra `case` arm, checked first: a raw
payload containing a JSON `\u` escape anywhere always falls through to
the real judge, regardless of whether it also happens to match the
existing plain-text patterns.

```bash
case "$payload" in
  *'\u'*) ;;
  *'"Bash"'*) ;;
  *) trap - EXIT; exit 0 ;;
esac
```

This is strictly narrower (never wider) than the pre-fix allow surface —
it turns "skip on no match" into "skip on no match AND no escape" — and
keeps the fast path's whole reason to exist: an ordinary payload with no
gate-relevant content and no `\u` escape still skips python3 entirely.
`pretooluse_dispatcher.py`'s `_payload_escaped(payload)` (`"\\u" in
payload`) is the same check, shared across its three setup functions
since they operate on the same raw stdin text.

## What each test case proves

For `gh-guard.sh`/`approval-gate.sh`/`board-gate.sh`, both directly
against the `.sh` file and routed through the dispatcher
(`OTR_DISPATCH_ONLY=<gate>.sh`):

- an unescaped payload that should deny, does;
- the same payload with one character of the matched substring `\uXXXX`-
  escaped denies *identically* (the regression pin itself);
- an irrelevant payload (no gate-relevant content, no `\u` escape) still
  allows *and* never invokes python3 — verified by stubbing `python3`
  with a script that writes a marker file, then asserting the marker was
  never created, so "fast-skipped" is distinguished from "the judge ran
  and happened to allow."

## Known duplication risk

`pretooluse_dispatcher.py`'s per-gate fast-path checks are a second,
independently maintained copy of each `.sh` file's own preamble — by
design (issue #282 Part 2: the dispatcher "replicates each gate's bash
preamble... cheap fast-path checks" so all PreToolUse gates run inside
one python process instead of N bash+python3 subprocess pairs). That
duplication is exactly what let this bug survive in production after this
same defect was fixed in the `.sh` source-of-truth files once already (see
issue-303's record, Open findings): a future change to any of
`gh-guard.sh`/`approval-gate.sh`/`board-gate.sh`'s fast-path pattern must
be mirrored into the matching `pretooluse_dispatcher.py` `_setup_*`
function by hand, or this harness's dispatcher-routed cases are what catch
the drift. De-duplicating the two copies into one source is a larger
issue #282-scale change and is out of scope here.
