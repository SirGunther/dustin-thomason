# dustin-thomason

Personal engineering standards and AI-assistant rules, shared across every project I work in
(Atlas/Callisto PRDV work, WorkLists, Countdowns, OtterCopy, PDProjects, and more). One
tool-neutral source of truth, generated into whatever each AI system reads. Not application code.

## Arriving here as an AI agent? Read this first

**Source of truth: `rules/*.md`.** Every tool-specific format below is *generated* from it by
`scripts/sync-rules.ps1` — you never hand-edit the outputs.

| System | Reads | Generated? |
| ------ | ----- | ---------- |
| **Cursor** | `.cursor/rules/*.mdc` | generated from `rules/` |
| **Claude Code** | `.claude/rules/*.md` | generated from `rules/` |
| **Codex** (any AGENTS.md reader) | `AGENTS.md` | generated from `rules/` |
| **Humans / anything else** | `docs/workflow-index.md` | hand-written map |

All three outputs are committed and machine-neutral. If you skim only one file for "how does he
want things built," read [docs/workflow-index.md](docs/workflow-index.md).

## Generated files - NEVER hand-edit

`.cursor/rules/*.mdc`, `.claude/rules/*.md`, and `AGENTS.md` are **all generated** from
`rules/*.md` by `scripts/sync-rules.ps1`. Edit the `rules/` source; the next sync overwrites any
direct edit to an output. Each generated file carries a `<!-- generated ... -->` marker so it's
obvious in-editor.

## Changing or adding a rule

1. Edit (or add) `rules/<name>.md`.
2. Frontmatter declares the rule's routing (this is the *only* place classification lives):

   ```yaml
   ---
   description: <one-line summary>
   scope: always | scoped      # always = load unconditionally; scoped = on demand
   globs: a,b,c                # required iff scope: scoped
   codex: include | exclude    # whether it appears in AGENTS.md
   ---
   ```

3. If it is **new**, also add it to [docs/workflow-index.md](docs/workflow-index.md) and the
   `personal-methodology` router; if `scope: always`, add it to `$requiredAlwaysApply` in
   `scripts/validate-workflows.ps1`.
4. Commit. The pre-commit hook regenerates all three outputs and stages them. (Or run
   `.\scripts\sync-rules.ps1` then `.\scripts\validate-workflows.ps1` by hand if hooks are off.)

How `scope` maps downstream: `always` -> Cursor `alwaysApply: true`, Claude full inline (always
in context); `scoped` -> Cursor `alwaysApply: false` + `globs`, Claude `paths:`-scoped (loads
only when Claude touches matching files). `sync-rules.ps1` fails loudly on missing/invalid
frontmatter, so a rule can't be silently mis-generated.

## One-time machine setup

From the repo root (`c:\dustin-thomason` at home, `C:\Users\dustin.thomason\dustin-thomason`
at work):

```powershell
# 1) Enable the auto-regeneration + wiring-audit hook.
git config core.hooksPath scripts/git-hooks

# 2) Make Claude Code load these rules in EVERY project, not just this repo, by junctioning
#    the (committed) generated Claude rules into the user-level Claude rules directory.
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\rules" | Out-Null
New-Item -ItemType Junction `
  -Path   "$env:USERPROFILE\.claude\rules\dustin-thomason" `
  -Target (Join-Path (Get-Location) '.claude\rules')
```

`.claude/rules` is committed, so a fresh clone already has it and a `git pull` keeps it current
on every machine — no per-machine rebuild. (Running `.\scripts\sync-rules.ps1` is only needed if
you edit rules without committing.)

Optionally add this repo to `~/.claude/settings.json` so Claude can open repo files a rule
references (playbooks, specs) from other projects without a prompt (path is per-machine):

```json
{
  "permissions": { "additionalDirectories": ["c:/dustin-thomason"] }
}
```

Verify wiring at any time: `.\scripts\validate-workflows.ps1` (also run in CI on every push).

## Repo map

- `rules/*.md` - **source of truth** (tool-neutral; frontmatter: `description`, `scope`, `globs`, `codex`)
- `.cursor/rules/*.mdc` - generated for Cursor
- `.claude/rules/*.md` - generated for Claude Code (committed)
- `AGENTS.md` - generated for Codex (committed)
- `.cursor/docs/*.md` - task playbooks (session start, new branch, PR, browser-loop setup)
- `.cursor/skills/` - Cursor skills (`grill-me`, `write-spec`, `workflow-housekeeping`)
- `scripts/` - `sync-rules.ps1` (generator), `validate-workflows.ps1` (audit), `git-hooks/`, changelog + notify helpers
- `docs/` - `workflow-index.md` (the map), ticket changelogs, specs (`docs/agents/`), templates
