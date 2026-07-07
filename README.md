# dustin-thomason

Personal engineering standards and AI-assistant rules, shared across every project I work in
(Atlas/Callisto PRDV work, WorkLists, Countdowns, OtterCopy, PDProjects, and more). One source
of truth, mirrored to whatever each AI system reads. This repo is not application code.

## Arriving here as an AI agent? Read this first

**Source of truth: `.cursor/rules/*.mdc`.** Everything else is generated from it or supports it.

| System | What it loads | How |
| ------ | ------------- | --- |
| **Cursor** | `.cursor/rules/*.mdc` | Auto (`alwaysApply` / `globs`) |
| **Claude Code** | `.claude/rules/*.md` | In-repo: loaded as project rules automatically. Other projects: via a junction `~/.claude/rules/dustin-thomason` -> this repo's `.claude/rules` |
| **Codex** (and any AGENTS.md reader) | `AGENTS.md` | Committed at repo root |
| **Humans / anything else** | `docs/workflow-index.md` | The map: what to use for each task |

If you skim only one file for "how does he want things built," read
[docs/workflow-index.md](docs/workflow-index.md).

## Generated files - NEVER hand-edit

`AGENTS.md` (committed, machine-neutral) and `.claude/rules/*.md` (git-ignored, per-machine)
are **both generated** from `.cursor/rules/*.mdc` by `scripts/sync-rules.ps1`. Edit the `.mdc`
source; the next sync overwrites any direct edits to an output.

## Changing or adding a rule

1. Edit (or add) `.cursor/rules/<name>.mdc`.
2. If it is **new**, classify it in `scripts/sync-rules.ps1` (`$Manifest`: `full` | `pointer` |
   `scoped`), and add it to [docs/workflow-index.md](docs/workflow-index.md) and the
   `personal-methodology.mdc` router. If it is always-on, also add it to the
   `$requiredAlwaysApply` list in `scripts/validate-workflows.ps1`.
3. Commit. The pre-commit hook regenerates `AGENTS.md` + `.claude/rules` and stages
   `AGENTS.md`. (Or run `.\scripts\sync-rules.ps1` then `.\scripts\validate-workflows.ps1` by
   hand if hooks are not enabled.)

Manifest classes: `full` = inlined, always-on; `pointer` = a short stanza telling Claude to
read the heavy `.mdc` on demand (keeps always-on context light); `scoped` = loads only when
Claude touches matching files (path-scoped, translated from the rule's Cursor `globs`).

## One-time machine setup

From the repo root (`c:\dustin-thomason` at home, `C:\Users\dustin.thomason\dustin-thomason`
at work):

```powershell
# 1) Enable the auto-regeneration + wiring-audit hook.
git config core.hooksPath scripts/git-hooks

# 2) Build the Claude Code rules for this machine (git-ignored output).
.\scripts\sync-rules.ps1

# 3) Make the rules available to Claude Code in EVERY project, not just this repo,
#    by junctioning the generated rules into the user-level Claude rules directory.
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\rules" | Out-Null
New-Item -ItemType Junction `
  -Path   "$env:USERPROFILE\.claude\rules\dustin-thomason" `
  -Target (Join-Path (Get-Location) '.claude\rules')
```

Then let Claude read pointer-referenced rule files from other projects without a prompt by
adding this repo to `~/.claude/settings.json` (path is per-machine):

```json
{
  "permissions": { "additionalDirectories": ["c:/dustin-thomason"] }
}
```

(Forward slashes avoid backslash-escaping. This grants file-read access only - rule
*loading* comes from the junction in step 3. Use the work path on the work machine.)

Verify wiring at any time: `.\scripts\validate-workflows.ps1` (also run in CI on every push).

## Repo map

- `.cursor/rules/*.mdc` - source-of-truth rules (Cursor frontmatter: `description`, `globs`, `alwaysApply`)
- `.cursor/docs/*.md` - task playbooks (session start, new branch, PR, browser-loop setup)
- `.cursor/skills/` - Cursor skills (`grill-me`, `write-spec`, `workflow-housekeeping`)
- `AGENTS.md` - generated Codex mirror (committed)
- `.claude/rules/` - generated Claude Code rules (git-ignored, per-machine)
- `scripts/` - `sync-rules.ps1` (generator), `validate-workflows.ps1` (audit), `git-hooks/`, changelog + notify helpers
- `docs/` - `workflow-index.md` (the map), ticket changelogs, specs (`docs/agents/`), templates
