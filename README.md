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
| `agents/rules/*.md` (the `scope: always` ones) + `agents/docs/workflow-index.md` | `.claude/CLAUDE.md` (repo root manifest) | Claude Code, loaded in **every** project (see machine setup) |
| `agents/rules/*.md` | `AGENTS.md` (repo root) | Codex / any AGENTS.md reader |
| `agents/skills/<name>/` | `.cursor/skills/` + `.claude/skills/` | Cursor + Claude skills |
| `agents/docs/*.md` | `.cursor/docs/*.md` + `.claude/docs/*.md` | Cursor + Claude playbooks/guides |

All outputs are committed and machine-neutral. If you skim only one file for "how does he want
things built," read `agents/docs/workflow-index.md`.

## Generated files - NEVER hand-edit

`.cursor/*`, `.claude/*` (including the `.claude/CLAUDE.md` manifest), and `AGENTS.md` are
**all generated** from `agents/` by `agents/scripts/sync-rules.ps1`. Edit the source under
`agents/`; the next sync overwrites any direct edit to an output. Generated files carry a
`<!-- generated ... -->` marker.

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

3. Optionally add an **editorial routing row** to the hand-written part of
   `agents/docs/workflow-index.md` (task-to-words guidance) and wire it into the
   `personal-methodology` router if intent should route to it. You do **not** hand-add it to the
   index's **Complete inventory** section or to `$requiredAlwaysApply` — both are
   generated/derived from the folder + frontmatter now.
4. Commit. The pre-commit hook regenerates all outputs and stages them. (Or run
   `.\agents\scripts\sync-rules.ps1` then `.\scripts\validate-workflows.ps1` by hand if hooks are off.)

Everything downstream of the source is **automatic**: a new `scope: always` rule flows into the
`.claude/CLAUDE.md` manifest (loaded everywhere — no bootstrap re-run) and any new rule/skill/doc/script
flows into the generated **Complete inventory** block in `workflow-index.md`. The guard: the
pre-commit hook regenerates and re-stages every output, `validate-workflows.ps1` (hook + CI) derives
its own checks from the filesystem and fails on any stale output, so a new item cannot land without
its manifest + inventory entries. `bootstrap.ps1` is one-time-per-machine; adding a rule is just
edit-source-and-commit.

Skills are folders in `agents/skills/<name>/` (mirrored verbatim). Playbooks/guides are
`agents/docs/*.md` (mirrored to `.cursor/docs`). How `scope` maps downstream: `always` -> Cursor
`alwaysApply: true`, Claude full inline; `scoped` -> Cursor `globs`, Claude `paths:`-scoped.
`sync-rules.ps1` fails loudly on missing/invalid frontmatter, so a rule can't be silently mis-generated.

## One-time machine setup

From the repo root (`c:\dustin-thomason` at home, `C:\Users\dustin.thomason\dustin-thomason`
at work), run the bootstrap once:

```powershell
.\agents\scripts\bootstrap.ps1
```

That single command is the baseline for a fresh clone / new computer. It is idempotent (safe to
re-run) and:

1. Enables the auto-regeneration + wiring-audit pre-commit hook (`core.hooksPath scripts/git-hooks`).
2. Regenerates every output (`sync-rules.ps1`), including the `.claude/CLAUDE.md` manifest.
3. Wires `~/.claude/CLAUDE.md` to `@`-import this repo's `.claude/CLAUDE.md` (inside a managed
   marker block), so the `scope: always` rules load in **every** Claude Code session, in every
   project — even ones that do not include this repo as a workspace folder.
4. Sets user env var `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` so path-scoped rules and
   `CLAUDE.md` also load natively when this repo IS an `--add-dir` workspace root.

Options: `-MirrorSkills` also copies skills into `~/.claude/skills` (for sessions that don't
include this repo as a workspace folder); `-SkipEnvVar` leaves the env var alone; `-DryRun`
prints what would change without writing. Restart Claude Code sessions after running so the env
var and user memory are re-read.

> This supersedes the older manual setup (junctioning `.claude/rules` into `~/.claude/rules`).
> `bootstrap.ps1` is the one and only entry point now.

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
  - `agents/scripts/` - `sync-rules.ps1` (generator) + `sync-agents-md.ps1` (shim) + `bootstrap.ps1` (one-time machine setup)
- Generated outputs (do not edit): `.cursor/rules`, `.cursor/skills`, `.cursor/docs`, `.claude/rules`, `.claude/skills`, `.claude/docs`, `.claude/CLAUDE.md`, `AGENTS.md`, `agents-rules.md`, `agents-skills.md`, `agents-docs.md`
- `scripts/` - `validate-workflows.ps1` (audit), `git-hooks/`, `new-ticket-changelog.ps1`, `notify-agent-complete.ps1`
- `docs/` - ticket changelogs, specs (`docs/agents/`), `_templates/` (kept separate from `agents/`)
