# issue-301 — warrant-hunt record

No phase-1 proposal exists for this delivery: `CORE_BUILD_NOW=1` was set by
the spawner, invoking the role-protocol build-now bypass (contract v3
s19a), which skips the proposal round entirely. There is therefore no
`proposal:` this record can key on; it is anchored to the issue instead.

## before-landing

tier computed via `warrant/hooks/hunt-tier.sh origin/main HEAD`:
```
tier=docs-only cap_seconds=60 max_stances=1 reason=docs-only-or-tiny-diff
```

Per warrant-protocol.md's DOCS-ONLY FAST PATH ("when every touched path is
under docs/, the before-landing dispatch is skipped"): the only file this
delivery touches is `docs/issue-301/reports/observability.md` (plus this
hunt record itself, also under `docs/`) — every touched path is under
`docs/`.

skip, docs-only, no before-landing dispatch.
