#!/usr/bin/env python3
"""Gate-literal <-> injected-prose coverage check (issue-146).

For every unit (a directory holding a `hooks/directive.sh`) in one or more
repo roots, extracts the literal needles every sibling `hooks/*gate*.sh`
file checks for, and asserts each needle appears (case-insensitive
substring) somewhere in the unit's INJECTED prose corpus: `directive.sh`
itself, any `SKILL.md` under the same unit subtree, and any file
`directive.sh` names by relative path in its own text. A README or
`docs/handbooks/*.md` counts only if directive.sh literally names it —
that is the "injected" boundary the issue-146 audit found repeatedly
violated.

Static, read-only, regex-based extraction only — no execution of target
gates. Three needle shapes, taken from this repo's own
record-fields-gate.sh and the survey's api-design-rulebook example:

  1. has_any("a", "b", ...)              -> each string literal is a needle
  2. {"key": re.compile(...), ...}       -> each dict string key is a needle
  3. re.search(r'^\\s*(name):', ...)      -> the field-key name is a needle

A gate with no directive.sh sibling anywhere above it is attributed to the
repo root itself (e.g. this repo's own `core` unit is `core/hooks/`, whose
sibling directive.sh is `core/hooks/directive.sh`).

Usage: gate-prose-coverage-check.py [repo-root ...]   (default: ".")
Exit 0 if no violations, 1 if any violation found, 2 on a usage/IO error.
"""
import os
import re
import sys

HAS_ANY_RE = re.compile(r'has_any\s*\(([^)]*)\)', re.S)
STRING_LIT_RE = re.compile(r'"((?:[^"\\]|\\.)*)"|\'((?:[^\'\\]|\\.)*)\'')
DICT_KEY_RE = re.compile(
    r'["\']([^"\']+)["\']\s*:\s*re\.compile\s*\(', re.S
)
FIELD_KEY_RE = re.compile(
    r're\.search\s*\(\s*r?["\']?\^\\s\*\(([A-Za-z0-9_-]+)\)'
)


def find_units(root):
    """Return {unit_dir: directive_path} for every hooks/directive.sh under root."""
    units = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in (".git", "node_modules")]
        if os.path.basename(dirpath) == "hooks" and "directive.sh" in filenames:
            unit_dir = os.path.dirname(dirpath)
            units[unit_dir] = os.path.join(dirpath, "directive.sh")
    return units


def find_gate_files(root):
    """Return every hooks/*gate*.sh file under root, excluding directive.sh."""
    gates = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in (".git", "node_modules")]
        if os.path.basename(dirpath) != "hooks":
            continue
        for fn in filenames:
            if fn == "directive.sh":
                continue
            if "gate" in fn and fn.endswith(".sh"):
                gates.append(os.path.join(dirpath, fn))
    return gates


def nearest_unit(gate_path, units, root):
    """Attribute a gate to the nearest ancestor unit dir; fall back to root."""
    best = None
    gate_dir = os.path.dirname(gate_path)
    for unit_dir in units:
        hooks_dir = os.path.join(unit_dir, "hooks")
        if gate_dir == hooks_dir or gate_dir.startswith(hooks_dir + os.sep):
            depth = len(unit_dir.split(os.sep))
            if best is None or depth > best[1]:
                best = (unit_dir, depth)
    if best:
        return best[0]
    return os.path.abspath(root)


def needle_covered(needle, corpus_text):
    """True if `needle` appears in `corpus_text` as a whole match, not merely
    as a substring inside an unrelated longer word (e.g. "ip" inside "skip").
    Boundaries are non-word characters on both sides (or start/end of text)."""
    pattern = r'(?<![A-Za-z0-9_])' + re.escape(needle.lower()) + r'(?![A-Za-z0-9_])'
    return re.search(pattern, corpus_text) is not None


def unescape(s):
    try:
        return s.encode("utf-8").decode("unicode_escape")
    except Exception:
        return s


def extract_needles(gate_text):
    """Return [(needle, shape)] for one gate file's text."""
    needles = []
    for m in HAS_ANY_RE.finditer(gate_text):
        args = m.group(1)
        for lit in STRING_LIT_RE.finditer(args):
            val = lit.group(1) if lit.group(1) is not None else lit.group(2)
            if val:
                needles.append((unescape(val), "has_any"))
    for m in DICT_KEY_RE.finditer(gate_text):
        needles.append((unescape(m.group(1)), "dict-key"))
    for m in FIELD_KEY_RE.finditer(gate_text):
        needles.append((m.group(1).replace("_", " "), "field-key"))
    # dedupe, case-insensitive, preserving first-seen casing
    seen = {}
    for needle, shape in needles:
        key = needle.strip().lower()
        if not key:
            continue
        if key not in seen:
            seen[key] = (needle.strip(), shape)
    return list(seen.values())


def build_corpus(unit_dir, directive_path):
    """Return (lowercased corpus text, list of source files it was built from)."""
    parts = []
    sources = []

    def add(path):
        if not os.path.isfile(path):
            return
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                text = f.read()
        except OSError:
            return
        parts.append(text)
        sources.append(path)

    add(directive_path)
    directive_text = parts[0] if parts else ""

    for dirpath, dirnames, filenames in os.walk(unit_dir):
        dirnames[:] = [d for d in dirnames if d not in (".git", "node_modules")]
        for fn in filenames:
            if fn == "SKILL.md":
                add(os.path.join(dirpath, fn))

    # files directive.sh names by relative path (its "pointed to" surfaces)
    for m in re.finditer(r'[A-Za-z0-9_.\-/]+\.(?:md|sh|py)', directive_text):
        rel = m.group(0)
        candidate = os.path.normpath(os.path.join(unit_dir, rel))
        if os.path.isfile(candidate) and candidate not in sources:
            add(candidate)
        candidate2 = os.path.normpath(os.path.join(os.path.dirname(directive_path), rel))
        if os.path.isfile(candidate2) and candidate2 not in sources:
            add(candidate2)

    return "\n".join(parts).lower(), sources


def check_repo(root):
    root = os.path.abspath(root)
    units = find_units(root)
    gates = find_gate_files(root)

    corpora = {}
    for unit_dir, directive_path in units.items():
        corpora[unit_dir] = build_corpus(unit_dir, directive_path)

    violations = []
    gates_seen = set()
    units_with_violations = set()

    for gate_path in gates:
        try:
            with open(gate_path, "r", encoding="utf-8", errors="replace") as f:
                gate_text = f.read()
        except OSError as e:
            print("ERROR reading %s: %s" % (gate_path, e), file=sys.stderr)
            continue

        unit_dir = nearest_unit(gate_path, units, root)
        needles = extract_needles(gate_text)
        if not needles:
            continue
        gates_seen.add(gate_path)

        if unit_dir in corpora:
            corpus_text, _sources = corpora[unit_dir]
        else:
            corpus_text = ""

        lines = gate_text.splitlines()
        for needle, shape in needles:
            if needle_covered(needle, corpus_text):
                continue
            lineno = None
            for i, line in enumerate(lines, start=1):
                if needle in line:
                    lineno = i
                    break
            violations.append({
                "gate": gate_path,
                "line": lineno,
                "needle": needle,
                "shape": shape,
                "unit": unit_dir,
            })
            units_with_violations.add(unit_dir)

    return violations, gates_seen, set(units.keys())


def main(argv):
    roots = argv[1:] or ["."]
    all_violations = []
    all_gates_seen = set()
    all_units = set()

    for root in roots:
        if not os.path.isdir(root):
            print("not a directory: %s" % root, file=sys.stderr)
            return 2
        violations, gates_seen, units = check_repo(root)
        all_violations.extend(violations)
        all_gates_seen |= gates_seen
        all_units |= units

    for v in sorted(all_violations, key=lambda x: (x["gate"], x["line"] or 0)):
        loc = "%s:%s" % (v["gate"], v["line"]) if v["line"] else v["gate"]
        print("VIOLATION %s needle=%r shape=%s unit=%s" % (
            loc, v["needle"], v["shape"], v["unit"]))

    gates_with_violations = {v["gate"] for v in all_violations}
    units_with_violations = {v["unit"] for v in all_violations}

    print(
        "\nsummary: %d violation(s), %d gate(s) with needles checked, "
        "%d gate(s) with >=1 violation, %d unit(s) with >=1 violation"
        % (len(all_violations), len(all_gates_seen), len(gates_with_violations),
           len(units_with_violations))
    )

    return 1 if all_violations else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
