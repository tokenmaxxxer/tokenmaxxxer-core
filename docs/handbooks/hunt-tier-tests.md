# hunt-tier test harness

`warrant/hooks/tests/run-hunt-tier-tests.sh` exercises
`warrant/hooks/hunt-tier.sh` as a real subprocess against fixture git repos.

Run it directly, no setup required:

    bash warrant/hooks/tests/run-hunt-tier-tests.sh

issue-214: warrant-hunt dispatch cost should be proportional to the diff.
`hunt-tier.sh <base-ref> [<head-ref>]` classifies a `git diff` into
`tier=none|docs-only|small|full`, `cap_seconds`, and `max_stances`. Covers:

- `empty-diff-*`: identical base/head -> `tier=none`, `cap_seconds=0` (no
  hunt).
- `docs-only-*`: a diff wholly under `docs/` -> `tier=docs-only`,
  `cap_seconds<=180`, `max_stances=1`.
- `gates-hooks-*`: a one-line diff inside a `hooks/` directory ->
  `tier=full`, `cap_seconds=180`, `max_stances=2` regardless of its size —
  the regression guard keeping the composition-bypass class (caught
  historically via small gates/hooks diffs) in the full tier.
- `hookspec-substring-does-not-trip-override`: a path merely containing the
  substring "hooks" (`hookspec/`, not a `hooks/` directory segment) does not
  trigger the override.
- `docs-path-mentioning-hooks-stays-docs-only`: a docs/ report path that
  happens to mention "hooks" in its own path (a report *about* hooks) stays
  `docs-only` — the override only matches non-`docs/` paths, since a
  docs-only diff should still take `directive.sh`'s docs-only fast path
  even when its path text mentions hooks/gates.

`max_stances` is a ceiling the tier permits, not a dispatch count the
script drives itself — escalating from one hunt stance to a second within
that ceiling stays a session-level judgment call gated on the first hunt
returning a FIND, per `warrant/hooks/directive.sh`'s existing
adaptive-cadence rule; the script has no cross-call state to track that.
