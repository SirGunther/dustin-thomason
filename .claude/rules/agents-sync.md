---
paths:
  - "rules/**/*.md"
  - ".cursor/skills/**/*"
---
<!-- generated from rules/agents-sync.md by scripts/sync-rules.ps1; edit the source, not this file -->

# Generated rule outputs (dustin-thomason)

The single source of truth is **`rules/*.md`** (tool-neutral). Downstream outputs are generated from it and **must never be hand-edited**:

- **`.cursor/rules/*.mdc`** — Cursor (description + globs + alwaysApply frontmatter).
- **`.claude/rules/*.md`** — Claude Code (full body for always-on rules, `paths:`-scoped for on-demand rules).
- **`.claude/CLAUDE.md`** — Claude Code manifest: `@`-imports the `scope: always` rules (+ the workflow index) so they load in **every** project via the `~/.claude/CLAUDE.md` import that `bootstrap.ps1` wires. Its contents are driven entirely by the `scope: always` frontmatter, so a new always-on rule flows into it automatically on the next sync — no bootstrap re-run.
- **`AGENTS.md`** — Codex mirror (concatenated bodies).
- **`agents/docs/workflow-index.md`** (the "Complete inventory" block only) — a generated table of every rule/skill/doc/script + its description, injected between `<!-- generated:inventory -->` markers. The editorial/routing content around it is hand-written; only the marked block is generated, so a new rule/skill/doc/script auto-appears in the index on the next sync.

All are committed and machine-neutral. `agents/scripts/sync-rules.ps1` regenerates them; direct edits to any output are overwritten on the next run.

When you **create, edit, rename, or delete** any file under `rules/` (or `.cursor/skills/`):

1. Run **`.\agents\scripts\sync-rules.ps1`** from the repo root before you finish.
2. Stage the regenerated outputs (`.cursor/rules`, `.claude/rules`, `.claude/CLAUDE.md`, `AGENTS.md`, and the mirrored skills/docs) with the same work — do not leave them stale.

Each rule declares its own routing in frontmatter — `scope: always | scoped` (+ `globs:` when scoped) and `codex: include | exclude` — so classification lives **with the rule**, not in a separate table. Invalid or missing frontmatter makes `sync-rules.ps1` fail loudly rather than silently mis-generate.

The `scripts/git-hooks/pre-commit` hook runs this automatically at commit time when hooks are enabled (`bootstrap.ps1` enables it, or `git config core.hooksPath scripts/git-hooks` by hand), regenerating **and re-staging** every output — including `.claude/CLAUDE.md` — no matter which agent or human edited the rules. `validate-workflows.ps1` (hook + CI) then fails on any stale output, so a new or changed rule cannot land with its outputs out of sync. Running the sync by hand is the fallback when hooks are not set up.

Machine wiring (loading these rules in every project) is separate and one-time: run `.\agents\scripts\bootstrap.ps1` once per machine. It is **not** part of the per-rule flow — adding a rule is just edit-source-and-commit.

```
Good: edit rules/<rule>.md, then run .\agents\scripts\sync-rules.ps1, then stage the outputs.
Bad:  hand-editing .cursor/rules, .claude/rules, .claude/CLAUDE.md, or AGENTS.md (the next sync overwrites it).
```
