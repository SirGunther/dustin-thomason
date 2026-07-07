---
paths:
  - "rules/**/*.md"
  - ".cursor/skills/**/*"
---
<!-- generated from rules/agents-sync.md by scripts/sync-rules.ps1; edit the source, not this file -->

# Generated rule outputs (dustin-thomason)

The single source of truth is **`rules/*.md`** (tool-neutral). Three downstream outputs are generated from it and **must never be hand-edited**:

- **`.cursor/rules/*.mdc`** — Cursor (description + globs + alwaysApply frontmatter).
- **`.claude/rules/*.md`** — Claude Code (full body for always-on rules, `paths:`-scoped for on-demand rules).
- **`AGENTS.md`** — Codex mirror (concatenated bodies).

All three are committed and machine-neutral. `agents/scripts/sync-rules.ps1` regenerates them; direct edits to any output are overwritten on the next run.

When you **create, edit, rename, or delete** any file under `rules/` (or `.cursor/skills/`):

1. Run **`.gentsscriptssync-rules.ps1`** from the repo root before you finish.
2. Stage the regenerated outputs (`.cursor/rules`, `.claude/rules`, `AGENTS.md`) with the same work — do not leave them stale.

Each rule declares its own routing in frontmatter — `scope: always | scoped` (+ `globs:` when scoped) and `codex: include | exclude` — so classification lives **with the rule**, not in a manifest. Invalid or missing frontmatter makes `sync-rules.ps1` fail loudly rather than silently mis-generate.

The `scripts/git-hooks/pre-commit` hook runs this automatically at commit time when hooks are enabled (`git config core.hooksPath scripts/git-hooks`), so regeneration is enforced no matter which agent or human edited the rules. Running the sync by hand is the fallback when hooks are not set up.

```
Good: edit rules/<rule>.md, then run .gentsscriptssync-rules.ps1, then stage the outputs.
Bad:  hand-editing .cursor/rules, .claude/rules, or AGENTS.md (the next sync overwrites it).
```
