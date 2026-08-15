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

# wrapper-prefixed git subcommand extraction (issue-114, Finding 1 of
# docs/issue-107/reports/execution-observation.md): _git_subcommand used
# to re-split the raw segment for its own argument, so a TRANSPARENT
# wrapper prefix (e.g. `timeout 30`) shifted which word it read (the
# wrapper's own argument, not the git subcommand) -- an over-block, since
# gate_head_of already resolves the segment's head to "git" through the
# same wrapper. Mirrors bash-wrapper-timeout-cd-relative-foreign /
# bash-wrapper-command-cd-relative-foreign (issue-107, :304-305).
run allow bash-wrapper-timeout-git-log-foreign-issue Bash '{"command":"timeout 30 git log --oneline -1 -- docs/issue-49"}'
run allow bash-wrapper-command-git-log-foreign-issue Bash '{"command":"command git log --oneline -1 -- docs/issue-49"}'
# reverse direction: a wrapper-prefixed git WRITE segment stays denied,
# both before and after the fix (the misread was fail-closed only).
run deny  bash-wrapper-timeout-git-rm-foreign-issue  Bash '{"command":"timeout 30 git rm -r docs/issue-49/reports"}'

# git's own global value-taking flags (issue-124, R2): `_git_subcommand`
# had no notion that some of git's own global flags (`-C <dir>`, `-c
# <name>=<value>`) take a separate, space-joined value token, so
# `git -C /tmp log` read `/tmp` as the subcommand instead of `log` -- not
# in GIT_READ_SUBCOMMANDS, so a wrapper-free `git -C` read was
# misclassified as a write candidate (over-block only).
run allow bash-git-c-flag-log-foreign-issue Bash '{"command":"git -C /tmp log --oneline -- docs/issue-49"}'
# negative-space sibling: a `git -C ...` WRITE segment stays denied, both
# before and after -- the misread was fail-closed only.
run deny  bash-git-c-flag-rm-foreign-issue  Bash '{"command":"git -C /tmp rm -r docs/issue-49/reports"}'

# write-direction pin for a TRANSPARENT wrapper's own value-taking flag
# (issue-124 R3, closed out by issue-132 F1): _resolve_transparent only
# returns a head/trailing-words pair -- it has no allow/deny concept -- so
# R3's fix cannot be pinned from a write angle inside run-gate-lib-tests.sh
# (its four `headof` cases are read-shaped only, `... git log`). The
# allow/deny verdict for a `git`-headed segment is computed one layer up,
# here in board-gate.sh's _segment_is_failing, so the write-direction pin
# belongs in this file. `-s KILL` (unlike the bare-duration
# bash-wrapper-timeout-git-rm-foreign-issue sibling above) forces
# TRANSPARENT_FLAG_TAKES_ARG["timeout"]'s flag+value branch, the exact
# branch R3 added -- stays denied, unchanged before and after (the misread
# was fail-closed only, both pre- and post-fix: pre-fix the flag's value
# token derails head resolution to a non-"git" word, which still falls
# through to deny by default).
run deny  bash-wrapper-timeout-s-git-rm-foreign-issue Bash '{"command":"timeout -s KILL 30 git rm -r docs/issue-49/reports"}'

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

# --- issue #99: dead empty-candidates fallback + cd-relative write-verb gap
# (issue-90 execution-observation Finding 1) --------------------------------
# The candidates.append(DOCS) fallback could never survive hit-extraction
# (posixpath.normpath("docs/") == "docs", whose .find("docs/") == -1), so a
# write whose target is expressed relative to a preceding `cd` into a
# foreign docs/ path always reached allow() with no adjudication at all.
# Fixed by tracking the most recent docs/-landing `cd` target as a sticky
# cd_tail and reconstructing DOCS + cd_tail as the candidate instead.
run deny  bash-cd-relative-redirect-foreign Bash '{"command":"cd docs/issue-49 && date > x.md"}'
# the gap is not specific to redirection: cp/mv carry no docs/ token of
# their own either once the directory comes only from a preceding cd.
run deny  bash-cd-relative-cp-foreign    Bash '{"command":"cd docs/issue-49 && cp /tmp/a x.md"}'
run deny  bash-cd-relative-mv-foreign    Bash '{"command":"cd docs/issue-49 && mv /tmp/a x.md"}'
# negative-space sibling: a role's own legitimate cd-then-write into its
# own issue tree must still allow — now via genuine R1-R4 adjudication
# (R4's branch check actually runs and actually matches), not by accident
# of the dead fallback's unconditional allow.
run allow bash-cd-relative-write-own-issue Bash '{"command":"cd docs/issue-3/reports && date > qa.md"}'
# pins the accepted over-blocking trade-off (proposal Rationale): cd_tail
# is sticky and never un-set, so cd-ing back OUT of docs/ before the write
# still denies even though the write's real target is /tmp, not docs/ —
# a deliberate, named cost of the simpler existential tracker, not a bug.
run deny  bash-cd-out-then-write-elsewhere Bash '{"command":"cd docs/issue-49 && cd /tmp && date > y.md"}'
# issue-107 (#99 execution-observation Finding 1): _cd_target used to
# re-split the raw segment (stripped.split()[1:]) instead of reading
# gate_head_of's own resolver output, so a wrapper-prefixed cd read the
# wrapper's own argument (timeout's duration, or the wrapper word itself
# for an argument-less wrapper) instead of the cd target -- cd_tail was
# never set and the write below reached allow() unadjudicated.
run deny  bash-wrapper-timeout-cd-relative-foreign Bash '{"command":"timeout 30 cd docs/issue-49 && date > x.md"}'
run deny  bash-wrapper-command-cd-relative-foreign Bash '{"command":"command cd docs/issue-49 && date > x.md"}'

# --- FILE_REDIR quote-awareness (issue-94) ---------------------------------
# FILE_REDIR used to run on raw segment text, so a `>` sitting INSIDE a
# quoted string (e.g. a grep pattern) was misread as a write and refused.
# Fixed via gate_lib.gate_outside_quotes, the shared quote-span primitive.
run allow bash-quoted-redirect-in-grep  Bash '{"command":"grep -n \"A > B\" '$BOARD'/x.md"}'
# negative-space sibling: a real, unquoted `>` into the board must still deny.
run deny  bash-real-redirect-then-quote Bash '{"command":"echo hi > '$BOARD'/x.md"}'
# warrant-hunt sibling of bash-escaped-quote-then-write, targeting
# FILE_REDIR instead of the segment splitter: a backslash-escaped quote
# CHARACTER outside any real shell quote must not open a fake quoted span
# that swallows the real `>` between two real tokens.
run deny  bash-escaped-quote-then-redirect Bash '{"command":"ls \\\" > '$BOARD'/x.md #\""}'
# SUBSHELL deliberately stays quote-blind: command substitution is live
# inside double quotes in real bash, so this must keep denying — if it
# ever starts allowing, that is a real security regression.
run deny  bash-quoted-subshell-write    Bash '{"command":"grep -n \"$(touch '$BOARD'/x.md)\" README.md"}'

# --- issue #98: wrapper-headed writes, and READ_UNLESS_INPLACE's awk/sed
# quoted-redirect gap ------------------------------------------------------
# The FILE_REDIR half is already covered by the unrecognized-head
# fail-closed default (survey, docs/issue-98/reports/implementation/survey.md)
# -- these three pin that as a regression guard, not a new fix.
run deny  bash-wrapper-bash-c-foreign     Bash '{"command":"bash -c \"echo hi > '$BOARD'/reports/review.md\""}'
run deny  bash-wrapper-timeout-foreign    Bash '{"command":"timeout 30 bash -c \"echo hi > '$BOARD'/reports/review.md\""}'
run deny  bash-wrapper-nohup-foreign      Bash '{"command":"nohup bash -c \"echo hi > '$BOARD'/reports/review.md\""}'
run allow bash-wrapper-own-record         Bash '{"command":"bash -c \"echo hi > '$BOARD'/reports/qa.md\""}'
# awk/sed real gap: neither uses -i, but both have their own write
# mechanism. Single-quote chars inside the JSON "command" value are
# spliced in via the standard '\''  idiom (end quote, literal quote,
# resume quote) since the surrounding tinput argument is itself
# single-quoted.
run deny  awk-quoted-redirect-foreign     Bash '{"command":"awk '\''{print > \"'$BOARD'/reports/review.md\"}'\'' f"}'
run deny  sed-w-cmd-foreign               Bash '{"command":"sed -n '\''/x/w '$BOARD'/reports/review.md'\'' f"}'
# negative-space sibling: an awk read using bare > only as a NUMERIC
# COMPARISON (not a redirect) has no clean regex-only way to tell apart
# from a real redirect (survey: awk '$1 > 5 {print}' ...). Over-blocking
# is this file's own established safe direction for exactly this
# ambiguity (repeated inline comment elsewhere in this file), so it is
# pinned here as an accepted, documented residual -- deny, not the
# "allow" a perfect awk parser would give -- kept visible rather than
# silently dropped, mirroring gap-c-*/gap-f-*. (Proposal:
# docs/issue-98/proposals/2026-08-03-wrapper-head-class-fix-for-dequote-bypass.md
# Rationale.)
run deny  gap-awk-comparison-over-block   Bash '{"command":"awk '\''$1 > 5 {print}'\'' '$BOARD'/reports/review.md"}'
run allow sed-plain-read-foreign          Bash '{"command":"sed -n 1,40p '$BOARD'/reports/review.md"}'

# --- issue-149: URL false positives on the docs/ tail extractor -----------
# An external URL whose path contains /docs/ is not a repository path; the
# own_hits regex used to sever at the URL's own `:` and misclassify the
# post-scheme remainder as a docs-tail candidate.
run allow url-docs-path-1                 Bash '{"command":"curl https://code.claude.com/docs/en/hooks.md"}'
run allow url-docs-path-2                 Bash '{"command":"curl http://example.com/docs/api/v1.md"}'
# negative-space siblings: a genuine out-of-bucket repository write must
# still deny, both as a direct Write and via the Bash own_hits path.
run deny  url-docs-negative-write         Write '{"file_path":"docs/en/hooks.md","content":"x"}'
run deny  url-docs-negative-issue         Write '{"file_path":"docs/issue-1/notabucket/x.md","content":"x"}'

# --- issue-651: resolved write-target path, not command-text substring ----
# board-gate.sh used to decide a candidate is a board hit by finding the
# literal substring "docs/" in it, never checking whether the candidate,
# resolved as an actual filesystem path, falls under the repo root the
# gate itself already resolves (the #628 hunt bonus finding). An absolute
# path that merely contains a docs/issue-N-shaped component while
# resolving entirely OUTSIDE the repo must now pass; a genuine write whose
# resolved absolute path lands INSIDE the repo, at a foreign record, must
# still refuse -- both directions of the acceptance criterion, driven by
# real fixtures rather than assumed from the source diff alone.
run allow abs-write-outside-repo-docs-shaped Write '{"file_path":"/does/not/exist-651/'$BOARD'/reports/review.md","content":"x"}'
run deny  abs-write-inside-repo-foreign      Write '{"file_path":"'$BOARD'/reports/review.md","content":"x"}'

absTargetTest() { # <want> <name> <template> -- {ROOT} -> repo root, {FOREIGN} -> sibling path outside root
  want="$1"; name="$2"; template="$3"
  mktd
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b issue-3/qa
  mkdir -p "$td/docs/specs" "$td/docs/issue-3/reports"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  foreign="${td}-outside-651/$BOARD/reports/review.md"
  cmd="${template//\{ROOT\}/$td}"
  cmd="${cmd//\{FOREIGN\}/$foreign}"
  payload="$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"%s"}' "$cmd" "$td")"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

# red before the fix: this redirect target resolves OUTSIDE the repo (a
# sibling fixture directory) yet carries a docs/issue-3-shaped component --
# the substring-only judge used to deny it.
absTargetTest allow bash-redirect-outside-repo-docs-shaped 'echo x > {FOREIGN}'
# green negative-space sibling: the same shape, but the redirect target
# actually resolves INSIDE the repo, at a foreign record -- must still deny.
absTargetTest deny  bash-redirect-inside-repo-foreign       'echo x > {ROOT}/'$BOARD'/reports/review.md'

# --- issue-187: comment/echoed text is not a write target -----------------
# `own_hits` used to scan a failing segment's full raw text, so a
# docs/issue-N-shaped string sitting only in an ECHOED comment was
# misread as a write candidate even though the real redirect target lay
# elsewhere. Red: this exact shape used to deny before the fix.
run allow bash-echo-comment-not-target    Bash '{"command":"echo \"see '$BOARD'/reports/review.md for context\" > /tmp/notes.txt"}'
# negative-space sibling: a real write into the board through the same
# echo/redirect shape must still deny.
run deny  bash-echo-comment-real-target   Bash '{"command":"echo \"see /tmp/notes.txt for context\" > '$BOARD'/reports/review.md"}'
# tee's own comment-vs-target split: piped text mentioning docs/issue-N
# must not itself become the candidate; tee's own destination argument
# still is.
run allow bash-tee-comment-not-target     Bash '{"command":"echo \"see '$BOARD'/reports/review.md\" | tee /tmp/notes.txt"}'
run deny  bash-tee-comment-real-target    Bash '{"command":"echo \"see /tmp/notes.txt\" | tee '$BOARD'/reports/review.md"}'

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

# --- issue-138: fail-closed trap must survive rc propagation --------------
# empty stdin (delivery failure) must deny outright, never fall through to
# the fast path's exit 0.
empty_payload() {
  mktd; git init -q "$td"
  printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" "empty-payload"
}
empty_payload

# a python3 that dies with an internal error (rc=1, e.g. an import/compat
# failure) must remap to exit 2 (deny), not exit 1 — Claude Code treats a
# non-2 hook exit as non-blocking (the header's fail-closed promise).
internal_error() {
  mktd; git init -q "$td"
  repo_td="$td"; mktd; stubdir="$td"; td="$repo_td"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$stubdir/python3"
  chmod +x "$stubdir/python3"
  printf '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-3/reports/qa.md","content":"x"},"cwd":"%s"}' "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=qa PATH="$stubdir:$PATH" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  rm -rf "$td" "$stubdir"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "python3-internal-error"
}
internal_error

# --- R4 maintenance-targets exception (issue-222) --------------------------
# stub_gh_maint <dir> <body>: gh issue view --json body returns {"body": body}.
# If <dir> is empty, no stub is written (the mismatch call errors --
# used to prove the same-issue path never invokes gh at all).
stub_gh_maint() {
  cat > "$1/gh" <<SCRIPT
#!/bin/sh
printf '%s' '{"body":$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$2")}'
SCRIPT
  chmod +x "$1/gh"
}

# maint_run <want> <name> <branch> <file_path> <issue-body> — always CLAUDE_ROLE=implementation
maint_run() {
  want="$1"; name="$2"; branch="$3"; fp="$4"; body="$5"
  mktd
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b "$branch"
  mkdir -p "$td/docs/specs"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  repo_td="$td"; mktd; stubdir="$td"; td="$repo_td"
  stub_gh_maint "$stubdir" "$body"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$fp" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=implementation CORE_GH="$stubdir/gh" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td" "$stubdir"
  report "$want" "$got" "$name"
}

maint_run deny  maint-refused-no-decl issue-222/implementation docs/issue-9/reports/implementation.md ""
maint_run allow maint-permitted-decl  issue-222/implementation docs/issue-9/reports/implementation.md "maintenance-targets: docs/issue-9/"
maint_run deny  maint-unlisted-refused issue-222/implementation docs/issue-9/reports/implementation.md "maintenance-targets: docs/issue-711/"

# own-issue writes never invoke gh: point CORE_GH at a nonexistent path so
# any invocation errors out (subprocess OSError -> deny), then assert allow.
maint_own_issue_no_gh_call() {
  mktd
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  git -C "$td" checkout -q -b issue-9/implementation
  mkdir -p "$td/docs/specs"
  printf -- '- jw-human\n' > "$td/docs/specs/approvers.md"
  printf '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-9/reports/implementation.md","content":"x"},"cwd":"%s"}' "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
      CLAUDE_ROLE=implementation CORE_GH="/nonexistent/gh-should-not-be-called" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report allow "$got" "maint-own-issue-never-calls-gh"
}
maint_own_issue_no_gh_call

# --- issue-225: script-heredoc writes must not mask their targets --------
# on-the-record PR #1627's exact live bypass: board-gate denied a direct
# cross-issue Edit, and the same session rewrote the file via
# `python3 - <<EOF` instead — the heredoc body (where the real write
# target lived) was masked before the segment scan ever ran, so the call
# contributed zero candidates and fell through to allow().
run deny  heredoc-python-mask-bypass      Bash '{"command":"python3 - <<'"'"'EOF'"'"'\nopen(\"'$BOARD'/reports/review.md\", \"w\").write(\"pwn\")\nEOF"}'
run deny  heredoc-bash-mask-bypass        Bash '{"command":"bash <<'"'"'EOF'"'"'\necho pwn > '$BOARD'/reports/review.md\nEOF"}'
run deny  inline-c-flag-mask-bypass       Bash '{"command":"cd '$BOARD' && python3 -c \"import sys; sys.stdout.write(1)\""}'
# an unrestricted session (no board contract at all -- no
# docs/specs/approvers.md, no CLAUDE_ROLE) is unaffected: same heredoc
# shape, but no write-set is being enforced for anyone to bypass.
runUnrestrictedHeredoc() {
  mktd
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  mkdir -p "$td/docs"
  printf '{"tool_name":"Bash","tool_input":{"command":"python3 - <<EOF\\nopen(\\"docs/notes.md\\", \\"w\\").write(\\"x\\")\\nEOF"},"cwd":"%s"}' "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report allow "$got" "heredoc-unrestricted-session-unaffected"
}
runUnrestrictedHeredoc
# provably read-only interpreter calls stay unaffected, even alongside an
# unrelated docs/ mention on the same line (the fast-path/word check).
run allow python-pytest-still-allowed     Bash '{"command":"echo see '$BOARD'/x.md ; python3 -m pytest -q"}'

# --- issue-227: residuals from #225's review -------------------------------
# (1) `${IFS}`/`$IFS` used as a literal-space substitute fuses what would
# otherwise be separate tokens (`python3${IFS}-c` reads as ONE word to
# gate_head_of's whitespace split), so the interpreter-head + `-c` shape
# above goes undetected -- the write it performs is invisible to the token
# scan and the call must still deny (fail-closed) rather than fall through
# `if not hits: allow()`.
run deny  ifs-fused-inline-c-mask-bypass  Bash '{"command":"cd '$BOARD' && python3${IFS}-c${IFS}\"open(1)\""}'
# unrestricted session: same $IFS shape, but no write-set is enforced.
runUnrestrictedIfs() {
  mktd
  git init -q "$td"
  git -C "$td" remote add origin git@github.com:tokenmaxxxer/probe.git
  mkdir -p "$td/docs"
  printf '{"tool_name":"Bash","tool_input":{"command":"python3${IFS}-c${IFS}%s"},"cwd":"%s"}' \
    "'open(1)'" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report allow "$got" "ifs-fusion-unrestricted-session-unaffected"
}
runUnrestrictedIfs
# (2) indirect tee: the write target arrives on stdin via `xargs`, never as
# a visible tee argument in the command text -- board-gate's unanalyzable
# set previously covered heredoc/-c/-e/dd only.
run deny  indirect-tee-via-xargs          Bash '{"command":"echo '$BOARD'/reports/x.md | xargs tee"}'
# a direct tee with a visible target keeps being caught the ordinary way
# (own_hits finds it -- unaffected by this fix).
run deny  direct-tee-visible-target       Bash '{"command":"echo pwn | tee '$BOARD'/reports/x.md"}'

# --- issue-227 review: blocking findings ------------------------------------
# (1) FALSE POSITIVE -- the IFS regex had no boundary after IFS, so any
# variable merely starting with the four letters IFS tripped it even though
# it is a distinct variable name, not the $IFS token-fusion shape at all.
run allow ifs-lookalike-var-ifshome-read  Bash '{"command":"cat \"$IFSHOME/notes.md\""}'
run allow ifs-lookalike-var-ifsdir-read   Bash '{"command":"cat \"${IFS_DIR}/x\""}'
# (2) the token-fusion class survives via other spellings than literal
# whitespace before -c/-e: $(...) fusion, backtick fusion, and a
# variable-indirected interpreter head.
run deny  dollar-paren-fused-inline-c     Bash '{"command":"cd '$BOARD' && python3$(printf '"'"' '"'"')-c '"'"'open(1)'"'"'"}'
run deny  backtick-fused-inline-c         Bash '{"command":"cd '$BOARD' && python3`printf '"'"' '"'"'`-c '"'"'open(1)'"'"'"}'
run deny  var-indirected-interpreter-head Bash '{"command":"cd '$BOARD' && P=python3; $P -c '"'"'open(1)'"'"'"}'
# awk/gawk/ed/ex are write-capable (redirection/`w` live inside the program
# text this gate does not parse) and were absent from the write-capable set.
run deny  awk-begin-block-write           Bash '{"command":"cd '$BOARD' && awk '"'"'BEGIN{print \"x\" > \"pwn.md\"}'"'"'"}'
run deny  ed-script-write                 Bash '{"command":"cd '$BOARD' && ed -s pwn.md"}'

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
