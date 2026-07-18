# Cleanup candidates — archive and consolidation ledger

A running record of outdated references, superseded files, and structural warts across the `agents/` workspace, so cleanup is a worked list instead of a vague intention.

**Sequencing:** cleanup begins **after** the `orchestrate` integration has landed and proven out, using [agents-file-reference.md](./agents-file-reference.md) as the table of contents/map of what exists and why. Until then this file only accumulates candidates.

**Feeding it:** Phase 6 of every orchestrated run performs a cruft check ("did this run surface outdated references, superseded docs, or dead weight?") and appends findings here. Anyone may add a row anytime.

**Rules:** rows are proposals, not decisions — nothing is deleted or moved on the strength of a row alone. When a candidate is resolved, mark the Fate column done with a date; do not delete the row.

## Candidates

| Item | Why it's cruft | Proposed fate | Blocked by |
| --- | --- | --- | --- |
| `agents/docs/ticket-orchestration.md` (stub) | Superseded by the `orchestrate` skill; stub kept only to redirect previously circulated prompts | Delete after the skill proves out over a few real tickets | Skill adoption |
| `agents/docs/investigation-question-coverage.md` | Meta-audit proving the investigation SKILL covers a collected question list — documentation *about* the method, not operational input; not loaded by any flow | Archive (move under a `dnu/` or `archive/` convention for `agents/docs/`) | Decide the archive convention for agents/docs |
| `agents/skills/write-spec/SKILL.md` path references | Contains `.cursor/skills/grill-me/SKILL.md` and `../../rules/spec-writing.mdc` style links that only resolve in the `.cursor` tree — broken in `agents/` and `.claude/` mirrors | Switch to portable relative forms (`../grill-me/SKILL.md`; rules named in prose) | — |
| `agents/skills/investigation/` folder vs `name: investigate` frontmatter | Folder name (the actual invocation name) and frontmatter `name` disagree | Align frontmatter `name` to `investigation` | Confirm nothing keys off `investigate` |
| `agents/scripts/sync-agents-md.ps1` | Backwards-compatible shim to `sync-rules.ps1` | Delete once nothing invokes it | Validator's expected-scripts list includes it |
| `agents/docs/workflow-index.md` hand-written Skills table | Now complete (all 5 skills) but duplicates the generated inventory below it | Decide: slim the hand-written table to a pointer at the generated inventory, or keep maintaining both | — |
