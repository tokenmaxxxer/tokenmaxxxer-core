#!/usr/bin/env bash
# board-gate.sh, exercised as a real subprocess against real payloads.
#
# Five deny-only rules of the issue/PR interaction model (contract v3):
#   R1  docs/ layout: README.md, the six buckets, or issue-<n>/<bucket>
#   R2  a board write requires the repo contract to hash-match the canonical
#   R3  a write under docs/issue-<n>/ requires CLAUDE_ROLE
#   R4  a board write happens only on branch issue-<n>/<role>
#   R5  within issue-<n>/reports/, a role writes only its own record area
#
# want: "allow" (exit 0) | "deny" (exit 2)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/_tmp.sh"
GATE="$HERE/../board-gate.sh"
PLUGIN_ROOT="$(cd "$HERE/../.." && pwd -P)"

pass=0
fail=0

report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-34s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

# run <want> <name> <tool> <input-json-fragment> [env overrides...]
# Board repo: canonical contract planted, role qa, branch issue-3/qa.
run() {
  want="$1"; name="$2"; tool="$3"; tinput="$4"; shift 4
  mktd
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b issue-3/qa
  mkdir -p "$td/docs/specs" "$td/docs/issue-3/reports"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  payload="$(printf '{"tool_name":"%s","tool_input":%s,"cwd":"%s"}' "$tool" "$tinput" "$td")"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa "$@" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

# runb <want> <name> <branch> <role> <file_path> — branch/role matrix
runb() {
  want="$1"; name="$2"; branch="$3"; brole="$4"; fp="$5"
  mktd
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b "$branch"
  mkdir -p "$td/docs/specs"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$fp" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE="$brole" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

BOARD=docs/issue-3

# --- R1: docs/ layout -----------------------------------------------------
run deny  loose-docs-file        Write '{"file_path":"docs/notes.md","content":"x"}'
run deny  loose-issue-file       Write '{"file_path":"'$BOARD'/notes.md","content":"x"}'
run deny  nonbucket-issue-dir    Write '{"file_path":"'$BOARD'/tokens/k.token","content":"x"}'
run deny  nonbucket-standing-dir Write '{"file_path":"docs/product/one-pager.md","content":"x"}'
run allow docs-readme            Write '{"file_path":"docs/README.md","content":"x"}'
run allow standing-bucket        Write '{"file_path":"docs/specs/one-pager.md","content":"x"}'
run allow issue-proposal         Write '{"file_path":"'$BOARD'/proposals/2026-07-28-x.md","content":"x"}'

# --- R2: board writes require the canonical contract ----------------------
run allow write-own-record       Write '{"file_path":"'$BOARD'/reports/qa.md","content":"loop_state: observed"}'
run allow bash-append-record     Bash  '{"command":"echo note >> '$BOARD'/reports/qa.md"}'

drifted() {  # same harness, but approvers.md present/absent varies
  want="$1"; name="$2"; fp="$3"; mode="$4"; roleenv="$5"
  mktd
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b issue-3/qa
  mkdir -p "$td/docs/specs"
  case "$mode" in
    drift)   printf -- '- jw-human\n' > "$td/docs/specs/approvers.md" ;;
    missing) : ;;
  esac
  if [ -n "$roleenv" ]; then
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$fp" "$td" \
      | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_ROLE="$roleenv" \
        /bin/bash "$GATE" >/dev/null 2>&1
  else
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$fp" "$td" \
      | env -u CLAUDE_ROLE CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
        /bin/bash "$GATE" >/dev/null 2>&1
  fi
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

drifted allow board-approvers-valid     "$BOARD/reports/qa.md" drift   qa
drifted deny  board-no-approvers       "$BOARD/reports/qa.md" missing qa
drifted allow standing-write-w-role    "docs/specs/x.md"      drift   qa

# --- not every repo with a docs/ directory is a board ---------------------
# No contract and no role means no board: an ordinary repo's docs are none
# of this gate's business, whatever their layout.
drifted allow bystander-loose-docs    "docs/architecture.md" missing ""
drifted allow bystander-issue-path    "$BOARD/notes.md"      missing ""

# --- R3: no role, no board writes -----------------------------------------
drifted() { :; } # not reused below
noRole() {
  mktd
  git init -q "$td"; git -C "$td" checkout -q -b issue-3/qa
  mkdir -p "$td/docs/specs"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$1" "$td" \
    | env -u CLAUDE_ROLE CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" "board-write-no-role"
}
noRole "$BOARD/reports/qa.md"

# --- R4: the role's own issue branch --------------------------------------
runb deny  board-from-main       main       qa "$BOARD/reports/qa.md"
runb deny  board-wrong-issue     issue-4/qa qa "$BOARD/reports/qa.md"
runb deny  board-wrong-role      issue-3/coding qa "$BOARD/reports/qa.md"
runb allow board-right-branch    issue-3/qa qa "$BOARD/reports/qa.md"

# --- precondition: no remote, no board ------------------------------------
noremote() {
  mktd
  git init -q "$td"
  git -C "$td" checkout -q -b issue-3/qa
  mkdir -p "$td/docs/specs"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$BOARD/reports/qa.md" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" "board-without-remote"
}
noremote

# --- R5: reports/ ownership -----------------------------------------------
runb deny  foreign-record        issue-3/qa qa "$BOARD/reports/review.md"
runb deny  foreign-subtree       issue-3/qa qa "$BOARD/reports/coding/x.md"
runb allow own-subtree           issue-3/qa qa "$BOARD/reports/qa/run-1.md"
runb allow feasibility-spikes    issue-3/feasibility feasibility "$BOARD/reports/spikes/probe.md"
runb allow ops-postmortems       issue-3/ops ops "$BOARD/reports/postmortems/outage.md"
runb deny  qa-not-spikes         issue-3/qa qa "$BOARD/reports/spikes/probe.md"

# regression: mkdir/rm on the role's OWN bare record dir must be allowed,
# not fall through to the foreign-role denial (issue #12)
run allow bash-mkdir-own-dir     Bash  '{"command":"mkdir -p '$BOARD'/reports/qa"}'
run allow bash-rm-own-dir        Bash  '{"command":"rm -rf '$BOARD'/reports/qa"}'
# a foreign role's bare record dir must stay denied (fail-closed)
run deny  bash-mkdir-foreign-dir Bash  '{"command":"mkdir -p '$BOARD'/reports/review"}'
run deny  bash-rm-foreign-dir    Bash  '{"command":"rm -rf '$BOARD'/reports/review"}'

# --- the shell fast path must not change any verdict ----------------------
fastpath() {
  mktd
  git init -q "$td"
  printf '{"tool_name":"Read","tool_input":{"file_path":"src/app.py"},"cwd":"%s"}' "$td" \
    | env CLAUDE_ROLE=qa CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  rm -rf "$td"
  if [ "$rc" = 0 ]; then
    pass=$((pass + 1)); printf 'ok     %-34s allow (python3 never started)\n' "unrelated-tool-call"
  else
    fail=$((fail + 1)); printf 'FAIL   %-34s want=allow got=exit-%s\n' "unrelated-tool-call" "$rc"
  fi
}
fastpath

# --- outside docs/: not this gate's business ------------------------------
run allow write-src              Write '{"file_path":"src/app.py","content":"x"}'
run allow write-test             Write '{"file_path":"test/test_app.py","content":"x"}'
run allow bash-elsewhere         Bash  '{"command":"echo hi"}'
run allow bash-read-board        Bash  '{"command":"cat '$BOARD'/reports/qa.md"}'
run allow bash-sed-read-foreign  Bash  '{"command":"sed -n 1,40p '$BOARD'/reports/review.md"}'
run deny  bash-sed-inplace       Bash  '{"command":"sed -i s/a/b/ '$BOARD'/reports/review.md"}'

# --- s4 READ-broad: reading ANOTHER issue's tree is never a violation -----
# Every command below was refused by a live issue-53 coding session on
# 2026-07-30 (five refusals, all read-only). The gate's read allowance
# existed but was defeated by `|`, by the `>` of `2>&1`, and by a head check
# that looked only at the first word of a pipeline. A role cannot meet s19's
# survey rigor floor while `ls` and `git log` on another issue are refused.
run allow bash-ls-foreign-issue  Bash  '{"command":"ls docs/issue-49/proposals docs/issue-49/reports/coding 2>&1"}'
run allow bash-gitlog-pathspec   Bash  '{"command":"git log --oneline -1 -- docs/issue-49 2>&1 | head -30"}'
run allow bash-gitlog-glob       Bash  '{"command":"git log --all -- docs/issue-49/* 2>&1 | cat"}'
# Each of these reads a FOREIGN record or a foreign issue tree on purpose:
# a case pointing at the role's own qa.md, or at bare docs/, passes with or
# without the fix and would prove nothing.
run allow bash-pipe-to-reader    Bash  '{"command":"cat '$BOARD'/reports/review.md | head -20"}'
run allow bash-xargs-grep        Bash  '{"command":"find . -name *.md -print | xargs grep -l APPROVE 2>/dev/null | grep -v docs/issue"}'
run allow bash-grep-devnull      Bash  '{"command":"grep -rn loop_state docs/issue-49/ 2>/dev/null | sort | uniq -c"}'
run allow bash-wc-pipe           Bash  '{"command":"git diff -- docs/issue-49 | wc -l"}'

# ...and the write side must stay refused through the same paths.
run deny  bash-tee-foreign       Bash  '{"command":"cat a | tee '$BOARD'/reports/review.md"}'
run deny  bash-redirect-foreign  Bash  '{"command":"echo x > '$BOARD'/reports/review.md"}'
run deny  bash-stderr-to-file    Bash  '{"command":"git log 2>'$BOARD'/reports/review.log"}'
run deny  bash-xargs-rm-foreign  Bash  '{"command":"find . -name *.md | xargs rm -rf '$BOARD'/reports/review"}'
run deny  bash-subshell-write    Bash  '{"command":"echo $(cat '$BOARD'/reports/review.md)"}'

# --- git subcommand awareness (issue-60): `git` is not one read-only head -
# READ_ONLY_HEADS used to trust "git" whole-command, so write-shaped git
# subcommands bypassed the write scan before R1-R5 ever ran, on ANY issue
# tree. Acceptance criteria: rm/checkout --/restore deny on a foreign tree;
# log/diff/show keep allowing (s4 READ-broad, PR #59) with no regression.
run deny  bash-git-rm-foreign-issue       Bash '{"command":"git rm -r docs/issue-49/reports"}'
run deny  bash-git-checkout-foreign-issue Bash '{"command":"git checkout -- docs/issue-49/reports/x.md"}'
run deny  bash-git-restore-foreign-issue  Bash '{"command":"git restore docs/issue-49/reports/x.md"}'
# R5 integration: same issue/branch, foreign role's record — the write scan
# the bypass used to skip must reach R5, not just stop at R4.
run deny  bash-git-rm-foreign-record      Bash '{"command":"git rm -r '$BOARD'/reports/review.md"}'
# a role's own bare record dir stays allowed via `git rm`, same as the
# plain `rm -rf` case from issue #12 — the goal is R1-R5 adjudication, not
# a blanket `git rm` ban.
run allow bash-git-rm-own-subtree         Bash '{"command":"git rm -r '$BOARD'/reports/qa"}'
# explicit `git show` regression case — log/diff already covered above.
run allow bash-git-show-foreign-issue     Bash '{"command":"git show HEAD:docs/issue-49/reports/coding.md"}'

# --- quoted-pipe segment-split blindness, and cd read-classification -----
# (issue-88): SEGMENT used to split on any bare `|`/`;` with no
# quote-awareness, so a quoted BRE OR pattern like `grep -n "A\|B"` cut
# into fake segments whose second-fragment head was an arbitrary word —
# denied. And `cd` was absent from READ_ONLY_HEADS, so a `cd`-prefixed
# read was denied outright even though the identical read without the
# `cd` prefix was allowed.
run allow bash-quoted-pipe-grep      Bash '{"command":"grep -n \"A\\|B\" '$BOARD'/x.md"}'
run allow bash-quoted-pipe-classtest Bash '{"command":"grep -n \"^class \\|^    def test_\" '$BOARD'/x.md"}'
run allow bash-single-quoted-pipe    Bash '{"command":"grep -n '\''A|B'\'' '$BOARD'/x.md"}'
run allow bash-cd-then-cat           Bash '{"command":"cd '$BOARD' && cat '$BOARD'/x.md"}'
# negative-space siblings: neither fix may open a hole in R1-R5.
run deny  bash-cd-then-write-foreign Bash '{"command":"cd '$BOARD' && echo x > '$BOARD'/reports/review.md"}'
run deny  bash-quoted-pipe-then-redirect Bash '{"command":"grep -n \"A\\|B\" x | tee '$BOARD'/review.md"}'
# warrant-hunt regression (issue-88): a backslash-escaped quote CHARACTER
# outside any real shell quote must not be treated as opening a quoted
# span — that let the fake "quote" run to an unrelated later quote (here,
# one inside a `#` comment) and swallow the real `;` between two real
# commands, hiding a write in the second as if it were quoted content.
run deny  bash-escaped-quote-then-write  Bash '{"command":"ls \\\" ; rm -rf '$BOARD'/x #\""}'

# --- candidate scan scoped to failing segments only (issue-90) ------------
# _reads_only used to collapse per-segment classification to one bool, so
# when ANY segment failed, the candidate scan swept the WHOLE cmdline for
# docs/-shaped tokens — including tokens inside a different, already
# provably-read-only segment. A genuinely read-only command was refused
# solely because an unrelated segment on the same line couldn't be
# classified.
run allow bash-unresolved-head-then-read Bash '{"command":"date; grep -n foo docs/issue-49/reports/x.md"}'
# negative-space sibling: a real write INSIDE the failing segment itself
# must still deny — scoping narrows WHERE candidates are hunted, not
# WHETHER a real write in scope is caught.
run deny  bash-unresolved-head-real-write Bash '{"command":"date > docs/issue-49/reports/x.md"}'

# --- kill switch and fail-closed ------------------------------------------
run allow kill-switch            Write '{"file_path":"docs/loose.md","content":"x"}' CORE_OFF=1

# An unparseable payload that MENTIONS docs must refuse — the gate cannot
# tell what was about to be written. One that never mentions it cannot be a
# docs write at all.
garbage() {
  want="$1"; name="$2"; raw="$3"
  mktd; git init -q "$td"
  printf '%s' "$raw" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}
garbage deny  garbage-mentioning-docs 'not json docs/issue-3/reports/qa.md'
garbage allow garbage-unrelated       'not json at all'

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
