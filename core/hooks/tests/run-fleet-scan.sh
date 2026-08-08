#!/usr/bin/env bash
# Fleet silent-failure scan — orchestrator driver (issue-168).
#
# Enumerates the tokenmaxxxer rulebook fleet, shallow-clones each repo
# (read-only, plain HTTPS, no auth needed — see docs/issue-168/reports/
# architecture/survey.md), runs fleet-silent-failure-scan.sh against
# each clone, and prints one aggregated report row per repo. A clone
# failure is its own distinct row (`CLONE-FAILED`), never folded into
# `clean` and never printed as `blocked`.
#
# Usage: run-fleet-scan.sh [--org <org>]
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"

org="tokenmaxxxer"
while [ $# -gt 0 ]; do
  case "$1" in
    --org) org="${2:?--org requires a value}"; shift 2 ;;
    *) echo "run-fleet-scan: unknown argument: $1" >&2; exit 2 ;;
  esac
done

mktd
trap 'rm -rf "$td"' EXIT

mapfile -t repos < <(gh repo list "$org" --limit 200 --json name -q '.[].name' | grep 'rulebook$')

if [ "${#repos[@]}" -eq 0 ]; then
  echo "run-fleet-scan: no rulebook repos found for org '$org'" >&2
  exit 2
fi

total=0
clean=0
finding_rows=0
clone_failed=0

echo "repo | result"
echo "---- | ------"

for repo in "${repos[@]}"; do
  total=$((total + 1))
  dest="$td/$repo"
  if ! git clone --quiet --depth 1 "https://github.com/$org/$repo.git" "$dest" >/dev/null 2>&1; then
    echo "$repo | CLONE-FAILED"
    clone_failed=$((clone_failed + 1))
    continue
  fi

  if out="$("$HERE/fleet-silent-failure-scan.sh" "$dest" 2>&1)"; then
    clean=$((clean + 1))
  else
    finding_rows=$((finding_rows + 1))
  fi
  printf '%s\n' "$out"
done

echo "---- | ------"
echo "total=$total clean=$clean with-findings=$finding_rows clone-failed=$clone_failed blocked=0"

[ "$clone_failed" -eq 0 ]
