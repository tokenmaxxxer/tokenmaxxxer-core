# hunt-guard test harness

`warrant/hooks/tests/run-hunt-guard-tests.sh` exercises
`warrant/hooks/hunt-guard.sh` and `warrant/hooks/hunt-state.sh` as real
subprocesses.

Run it directly, no setup required:

    bash warrant/hooks/tests/run-hunt-guard-tests.sh

issue-200: the session-state pair (`.warrant-hunt.count`/`.warrant-hunt.lock`)
used to live at the worktree root, so parallel branches committed divergent
counter values and conflicted. Both scripts now resolve state under
`.git/warrant/` (via `git rev-parse --git-dir`), which is never staged,
diffed, or committed. Covers:

- `worktree-clean-*`: a real dispatch (`hunt-guard.sh`) followed by release
  (`hunt-state.sh release`) leaves no `.warrant-hunt.*` file under the
  worktree root — only under `.git/warrant/` — and `git status --porcelain`
  stays silent for it.
- `disjoint-report-paths-same-date-slug`: the hunt-report path derivation
  rule stated in `warrant/agents/warrant-hunter.md` and
  `warrant/hooks/directive.sh` (`docs/issue-<n>/proposals/...` →
  `docs/issue-<n>/reports/hunt-<slug>.md`), reimplemented here as a shell
  function matching that prose, produces disjoint paths for two different
  issue numbers sharing the same date and slug — the exact same-day
  similar-topic collision the issue reports. `flat-layout-path-unchanged`
  pins that a proposal path with no issue segment still yields the
  unchanged `docs/reports/<date>-hunt-<slug>.md` form.
- `empty-state-*`: a repo where the hunter has never run (no `.git/warrant/`
  directory at all) does not crash and holds no lock — the pre-existing
  `used = 0` fallback in `hunt-guard.sh`'s dispatch-count read is a
  regression check, not new behavior.
