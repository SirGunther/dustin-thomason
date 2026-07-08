# dustin-thomason

Personal engineering standards and AI-assistant rules, shared across every project I work in
(Atlas/Callisto PRDV work, WorkLists, Countdowns, OtterCopy, PDProjects, and more). One
tool-neutral source of truth, generated into whatever each AI system reads. Not application code.

## Arriving here as an AI agent? Read this first

**Source of truth lives in `agents/`.** You only ever hand-edit `agents/`; everything each tool
reads is *generated* from it by `agents/scripts/sync-rules.ps1`.

| Source (edit here) | Generated output (tool reads) | For |
| ------------------ | ----------------------------- | --- |
| `agents/rules/*.md` | `.cursor/rules/*.mdc` | Cursor |
| `agents/rules/*.md` | `.claude/rules/*.md` | Claude Code |
| `agents/rules/*.md` | `AGENTS.md` (repo root) | Codex / any AGENTS.md reader |
| `agents/skills/<name>/` | `.cursor/skills/` + `.claude/skills/` | Cursor + Claude skills |
| `agents/docs/*.md` | `.cursor/docs/*.md` | Cursor playbooks/guides |

All outputs are committed and machine-neutral. If you skim only one file for "how does he want
things built," read `agents/docs/workflow-index.md`.

## Generated files - NEVER hand-edit

`.cursor/*`, `.claude/*`, and `AGENTS.md` are **all generated** from `agents/` by
`agents/scripts/sync-rules.ps1`. Edit the source under `agents/`; the next sync overwrites any
direct edit to an output. Generated rule/skill files carry a `<!-- generated ... -->` marker.

## Changing or adding a rule

1. Edit (or add) `agents/rules/<name>.md`.
2. Frontmatter declares the rule's routing (this is the *only* place classification lives):

   ```yaml
   ---
   description: <one-line summary>
   scope: always | scoped      # always = load unconditionally; scoped = on demand
   globs: a,b,c                # required iff scope: scoped
   codex: include | exclude    # whether it appears in AGENTS.md
   ---
   ```

3. If it is **new**, also add it to `agents/docs/workflow-index.md` and the
   `personal-methodology` router; if `scope: always`, add it to `$requiredAlwaysApply` in
   `scripts/validate-workflows.ps1`.
4. Commit. The pre-commit hook regenerates all outputs and stages them. (Or run
   `.\agents\scripts\sync-rules.ps1` then `.\scripts\validate-workflows.ps1` by hand if hooks are off.)

Skills are folders in `agents/skills/<name>/` (mirrored verbatim). Playbooks/guides are
`agents/docs/*.md` (mirrored to `.cursor/docs`). How `scope` maps downstream: `always` -> Cursor
`alwaysApply: true`, Claude full inline; `scoped` -> Cursor `globs`, Claude `paths:`-scoped.
`sync-rules.ps1` fails loudly on missing/invalid frontmatter, so a rule can't be silently mis-generated.

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
on every machine — no per-machine rebuild. (Run `.\agents\scripts\sync-rules.ps1` only if you
edit sources without committing.)

Optionally add this repo to `~/.claude/settings.json` so Claude can open repo files a rule
references from other projects without a prompt (path is per-machine):

```json
{
  "permissions": { "additionalDirectories": ["c:/dustin-thomason"] }
}
```

Verify wiring any time: `.\scripts\validate-workflows.ps1` (also run in CI on every push).

## Repo map

- `agents/` - **the source home** (only place you hand-edit for agent config):
  - `agents/rules/*.md` - tool-neutral rule source (frontmatter: `description`, `scope`, `globs`, `codex`)
  - `agents/skills/<name>/` - skill source (SKILL.md + supporting files)
  - `agents/docs/*.md` - playbooks + guides + `workflow-index.md` (the map)
  - `agents/scripts/` - `sync-rules.ps1` (generator) + `sync-agents-md.ps1` (shim)
- Generated outputs (do not edit): `.cursor/rules`, `.cursor/skills`, `.cursor/docs`, `.claude/rules`, `.claude/skills`, `AGENTS.md`
- `scripts/` - `validate-workflows.ps1` (audit), `git-hooks/`, `new-ticket-changelog.ps1`, `notify-agent-complete.ps1`
- `docs/` - ticket changelogs, specs (`docs/agents/`), `_templates/` (kept separate from `agents/`)
