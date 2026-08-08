#!/usr/bin/env bash
# Fleet silent-failure scan — per-repo driver (issue-168).
#
# Runs against ONE already-checked-out rulebook path (a clone, made by
# run-fleet-scan.sh, or any local checkout for a dry run). Two passes:
#   1. compliance-check.sh --canon-duplication — the existing
#      path-parameterized canon-duplication surface (issue-66).
#   2. a grep-based sweep for the six silent-failure signal categories
#      from issue-142/163's survey (swallowed errors, fail-open-on-
#      internal-error, absent-input-allows, string-judged commands,
#      mktemp footguns, dead deny branches), scoped to the repo's own
#      hooks/tests shell + python files.
#
# Never emits `blocked` for a path that exists — only `clean` or
# `FINDING: <text>` (possibly more than one FINDING line per repo).
#
# Usage: fleet-silent-failure-scan.sh <repo-path>
set -uo pipefail

repo_path="${1:?fleet-silent-failure-scan: repo path required}"
[ -d "$repo_path" ] || { echo "fleet-silent-failure-scan: no such directory: $repo_path" >&2; exit 2; }
repo_path="$(cd "$repo_path" && pwd -P)"
name="$(basename "$repo_path")"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

findings=()

# Pass 1: canon-duplication (reuses compliance-check.sh unmodified).
if ! dup_out="$("$HERE/compliance-check.sh" --canon-duplication "$repo_path" 2>&1)"; then
  while IFS= read -r line; do
    [[ "$line" == *"FAIL"* ]] && findings+=("canon-duplication: $line")
  done <<< "$dup_out"
fi

# Pass 2: six signal categories, grep-based, scoped to shell/python
# hook and test files anywhere under the repo (rulebooks nest hooks/
# and tests/ at varying depth — no fixed -maxdepth, same reasoning as
# compliance-check.sh's --canon-duplication mode).
mapfile -d '' scan_files < <(find "$repo_path" \( -name '*.sh' -o -name '*.py' \) -type f -print0 2>/dev/null)

for f in "${scan_files[@]:-}"; do
  [ -n "$f" ] || continue
  rel="${f#"$repo_path"/}"

  # 1. swallowed errors: stderr discarded immediately followed by an
  #    unconditional success exit.
  if grep -nE '2>/dev/null.*&&.*exit 0|2>/dev/null[[:space:]]*$' "$f" >/dev/null 2>&1 \
      && grep -nE '^[[:space:]]*exit 0[[:space:]]*$' "$f" >/dev/null 2>&1; then
    findings+=("swallowed-errors: $rel")
  fi

  # 2. fail-open-on-internal-error: python3/jq presence checked, absence
  #    path falls through to allow rather than deny.
  if grep -nE 'command -v (python3|jq).*\|\|.*exit 0' "$f" >/dev/null 2>&1; then
    findings+=("fail-open-on-internal-error: $rel")
  fi

  # 3. absent-input-allows: unset-variable guard that silently no-ops
  #    (":-}" default immediately followed by return/continue with no
  #    logged warning).
  if grep -nE '\$\{[A-Za-z_]+:-\}.*(return|continue)[[:space:]]*$' "$f" >/dev/null 2>&1; then
    findings+=("absent-input-allow: $rel")
  fi

  # 4. string-judged commands: raw regex match against a command string
  #    used as the sole gate for a dangerous verb.
  if grep -nE '\[\[.*\$\{?(command|cmd|tool_input)\}?.*=~' "$f" >/dev/null 2>&1; then
    findings+=("string-judged-command: $rel")
  fi

  # 5. mktemp footguns: mktemp -d used without the mktd-style output
  #    validation (no -p "$TMPDIR" or no subsequent non-empty check).
  if grep -nE 'mktemp -d' "$f" >/dev/null 2>&1 \
      && ! grep -nE 'mktemp -d.*-p ' "$f" >/dev/null 2>&1; then
    findings+=("mktemp-footgun: $rel")
  fi

  # 6. dead deny branches: a case/if arm that echoes a deny decision but
  #    has no matching exit/return non-zero on that same arm.
  if grep -nE 'deny' "$f" >/dev/null 2>&1 \
      && grep -nE '"deny"' "$f" >/dev/null 2>&1 \
      && ! grep -nE 'exit 1|return 1' "$f" >/dev/null 2>&1; then
    findings+=("dead-deny-branch: $rel")
  fi
done

if [ "${#findings[@]}" -eq 0 ]; then
  echo "$name | clean"
  exit 0
fi

joined="$(IFS='; '; echo "${findings[*]}")"
echo "$name | FINDING: $joined"
exit 1
