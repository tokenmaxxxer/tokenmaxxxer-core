# Canon scripts: referenced, never copied

Standing clause for anyone drafting a rulebook transition or maturation
directive (issue-69, generalizing the `warrant` plugin's own precedent —
its marketplace description already states "role rulebooks reference it
rather than vendoring a copy").

> **Canon scripts are referenced, never copied.** Any script that lives
> under `core/hooks/` or `core/hooks/tests/` is invoked by a rulebook
> through a path resolved against the core plugin's own install root. A
> rulebook's own tree never contains a second copy of a core canon file.
> If a script needs to run inside a rulebook's own directory for a genuine
> technical reason (e.g. `parse-check.sh` must parse files that only exist
> in that rulebook), the transition directive making that call states the
> reason explicitly rather than defaulting to "copy it, like the last
> one."

Every transition/maturation write-up for a rulebook (the per-rulebook
follow-up docs issue-63 and issue-66 track, and any future promotion of a
script to `core/hooks/`) is expected to carry this clause or an explicit,
reasoned exception to it.

`core/hooks/tests/stub-check.sh` enforces this mechanically for the scripts
listed in `core/hooks/tests/canon-manifest.txt`: a rulebook tree containing
a copy of any manifest-listed file fails that rulebook's own test run. See
`docs/handbooks/role-gates-tests.md` for the invocation model and
`docs/issue-69/reports/implementation/reclaim-21-copies.md` for the
existing-copy rollout this clause's manifest-driven detector now catches
recurrence of.
