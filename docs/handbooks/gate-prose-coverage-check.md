# gate-prose coverage check

`core/hooks/tests/gate-prose-coverage-check.py` — issue-146's mechanical
check for the class of mismatch execution-observation-rulebook#20 first
found and record-fields-gate carries a note about: a PreToolUse gate
denying on a literal that appears in no prose surface a role session is
actually handed.

## What it checks

For every unit (a directory holding `hooks/directive.sh`) under a repo
root, and every sibling `hooks/*gate*.sh` file (excluding `directive.sh`
itself), the check:

1. extracts each gate's literal needles via three regex shapes observed in
   this repo and in `api-design-rulebook`'s gates: `has_any("a", "b", ...)`
   string-literal arguments, `{"key": re.compile(...)}` dict string keys,
   and `re.search(r'^\s*(name):` field-key names;
2. builds the unit's INJECTED prose corpus: `directive.sh` itself, any
   `SKILL.md` under the same unit subtree, and any file `directive.sh`
   names by relative path in its own text (the "pointed to" test);
3. asserts each needle appears (case-insensitive substring) somewhere in
   that corpus — a miss is one violation, reported as `gate:line
   needle=... shape=... unit=...`.

A README or `docs/handbooks/*.md` file does NOT count as prose a role
receives unless `directive.sh` literally names it — this is the boundary
the issue-146 audit found repeatedly violated (a gate enforcing a section
name only documented in a handbook nobody injects into the role's context).

A gate with no `hooks/directive.sh` sibling anywhere above it is
attributed to the repo root itself.

## Running it

    python3 core/hooks/tests/gate-prose-coverage-check.py [repo-root ...]

Defaults to `.` when no root is given; accepts multiple roots in one run.
Exit 0 when no violation is found, 1 when at least one is found, 2 on a
usage/IO error (e.g. a given root does not exist). Static and read-only:
it never executes a target gate, never needs `CLAUDE_PROJECT_DIR` or `gh`
auth, and makes no writes to any repo it is pointed at.

Tests: `bash core/hooks/tests/run-gate-prose-coverage-tests.sh`.

## Reading a violation line

    VIOLATION core/hooks/record-fields-gate.sh:202 needle='what i did' shape=has_any unit=/abs/path/to/core

- `gate:line` — the file and line the needle literal was found on (best
  effort; `line` is omitted if the exact substring can't be located).
- `needle` — the exact string the gate checks for.
- `shape` — which of the three extraction shapes produced it.
- `unit` — the directory whose `hooks/directive.sh` (and referenced
  SKILL.md/named files) was searched and did not contain the needle.

The fix for a violation is either adding the needle's concept to the
unit's injected prose (directive.sh or a file it names), or — if the gate
is checking something the role never needs to know verbatim — loosening
the gate. This check does not decide which; it only makes the gap visible.

## Known extraction limits

Static regex extraction over the three shapes actually observed, not a
full parser:

- A needle expressed as a computed string (string concatenation, an
  f-string, a variable built at runtime rather than a literal) is not
  extracted and produces a false negative — no violation reported, but no
  coverage confirmed either.
- A gate using a fourth needle shape not yet observed in this repo or
  `api-design-rulebook` is invisible to the extractor until that shape is
  added.
- Structural gates with no literal needles at all (e.g. this repo's
  `approval-gate.sh`, `board-gate.sh` — git/gh state checks, not string
  matches) correctly produce zero needles and are silently skipped; that
  is by design, not a gap.
