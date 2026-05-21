# Workflow index — what to @ in Cursor

One map for **dustin-thomason** personal workflows. When `@` shows too many matches, start here or type a filename from the table (e.g. `@new-branch`).

---

## Multi-root workspace (Callisto + dustin-thomason)

| Repo in workspace | Role |
| ----------------- | ---- |
| `callisto-back-end`, `atlas-front-end`, etc. | Code + **their** `.cursor/rules/` (Vue, Nest, `PRDV-X:` format) |
| `dustin-thomason` | **Your** methodology — rules load for the **entire** session |

### One rule: do you have to `@` or say “use dustin-thomason”?

| Kind | Loads automatically? | You must `@`? |
| ---- | -------------------- | ------------- |
| **Personal rules** (`alwaysApply: true` in dustin-thomason) | **Yes** — if `dustin-thomason` is in the workspace | **No** — say “write a spec” / “commit” / “open a PR” and [personal-methodology](../.cursor/rules/personal-methodology.mdc) routes to the right rule or playbook |
| **Ticket changelog** (data for one PRDV) | No — it is a file, not a rule | **Yes** on a **new agent thread**: `@docs/atlas/PRDV-XXXXX-changelog` |
| **Playbooks** (branch steps, PR template) | Yes when you use those **words** (router reads the `.md`) | No — unless the agent ignored you |

**You do not copy** `spec-writing.mdc` (or any personal rule) into Callisto. Keep one copy in dustin-thomason only.

**Example:** In Callisto you say *“Write the story spec for PRDV-15263.”* → `spec-writing` applies. You do **not** say *“@ spec-writing from dustin-thomason.”*

**Example:** You say *“Commit.”* → `git-commit-workflow` + `ticket-changelog` apply; changelog file must still be updated under `dustin-thomason/docs/…`.

### When app rules and personal rules both apply

- **Spec sections / tests / commit gates** → your dustin-thomason rules.
- **`PRDV-12345:` commit prefix** on app branches → app repo rule.
- **Nest/Vue architecture** → app repo rules **plus** `build-implementation-guardrails`.

### Housekeeping

After you change workflow files: **“run workflow housekeeping”** or `@workflow-housekeeping`. Script: `.\scripts\validate-workflows.ps1`

---

## Three layers (do not mix them up)

| Layer | Location | Loads how? |
| ----- | -------- | ------------ |
| **Rules** | `.cursor/rules/*.mdc` | **Automatic** when `dustin-thomason` is in workspace (`alwaysApply: true`) |
| **Router** | `personal-methodology.mdc` | **Automatic** — maps “write spec” / “commit” / “open PR” to the right rule or playbook |
| **Playbooks** | `.cursor/docs/*.md` | **Automatic** when you name the task (router); not via `@` |
| **Artifacts** | `docs/**/PRDV-*-changelog.md` | **`@` the ticket file** on new agent threads |

**Authoritative long content** lives in `docs/`. `.cursor/docs/` holds short, task-oriented playbooks that link into `docs/`. `.github/*.md` files are **stubs for GitHub browsing only** — do not `@` them.

---

## What to `@` by task

| I want to… | What you say or do | `@` needed? |
| ---------- | ------------------ | ----------- |
| **Pick a workflow** (unsure) | `@workflow-index` | Optional |
| **Write epic/story spec** (any repo) | “Write the story spec …” | **No** — `spec-writing` + `personal-methodology` |
| **Start ticket / branch** | “Start branch for PRDV-…” | **No** — router reads `new-branch-get-started` |
| **Commit or push** | “Commit” / “push using git workflow” | **No** — `git-commit-workflow` + `ticket-changelog` |
| **Open a PR** | “Open PR for PRDV-…” | **No** — router reads `pull-request-workflow` |
| **Implement code** | (normal implementation chat) | **No** — `build-implementation-guardrails` + app repo rules |
| **Ticket context (new thread)** | `@docs/atlas/PRDV-XXXXX-changelog` | **Yes** — this is the ticket **data** file |
| **Stress-test a plan** | `@grill-me` | Yes (skill) |
| **Audit workflow docs** | “run workflow housekeeping” | Optional `@workflow-housekeeping` |

`@` a **rule** only when the agent **ignored** you — not as your normal habit.

---

## Personal rules (automatic — `alwaysApply: true`)

| Rule file | Purpose |
| --------- | ------- |
| `personal-methodology` | Routes intent → spec / commit / PR / branch (no copy into app repos) |
| `spec-writing` | Epic/story sections in **Callisto, Atlas, anywhere** |
| `git-commit-workflow` | audit → lint → tests → git → paste SHA |
| `ticket-changelog` | session log before commit |
| `build-implementation-guardrails` | tests + architecture when shipping code |
| `context-fanout` | read-only exploration subagents for multi-area context compaction |

Not always-on: `workflow-housekeeping` (only when editing workflow files here); `codex-agents-sync` (regenerate `AGENTS.md` after rule/skill edits).

---

## Playbooks (`.cursor/docs/`)

| File | When |
| ---- | ---- |
| [new-branch-get-started.md](../.cursor/docs/new-branch-get-started.md) | New `PRDV-*` branch |
| [pull-request-workflow.md](../.cursor/docs/pull-request-workflow.md) | `gh pr create`, PR body, Slack post |
| [README.md](../.cursor/docs/README.md) | Pointer to this index |

---

## Artifacts (`docs/`)

| Path | When |
| ---- | ---- |
| [ticket-changelog-workflow.md](./ticket-changelog-workflow.md) | How changelogs work end-to-end |
| `docs/<system>/PRDV-XXXXX-changelog.md` | **This ticket’s** memory in **dustin-thomason** only — `@` every new agent thread. `larry-adams` = read-only spec links in **Plans**, not a push target |
| [\_templates/TICKET-changelog.template.md](./_templates/TICKET-changelog.template.md) | Rarely — use `scripts/new-ticket-changelog.ps1` instead |
| `docs/WorkLists/` | One-off personal work lists |

**Do not** keep ticket changelogs under `.cursor/docs/` — only `docs/<system>/` to avoid duplicate `@` suggestions.

---

## Scaffold script (terminal, not `@`)

```powershell
cd C:\Users\dustin.thomason\dustin-thomason
.\scripts\new-ticket-changelog.ps1 -Ticket PRDV-15263 -System atlas -Title "Short title"
```

---

## Narrowing `@` suggestions in Cursor

1. Type more characters: `@new-branch`, `@pull-request`, `@PRDV-12264`.
2. Prefer **one playbook** or **one changelog** per message — not the whole repo.
3. Do not `@` `.github/` stubs or duplicate paths.
4. Rules with `alwaysApply: true` → trust them; `@` only on failure.

---

## Skills (`.cursor/skills/`)

Skills are **not** `alwaysApply` — the user `@`’s the skill or asks in plain language.

| Skill | Invoke when |
| ----- | ----------- |
| `grill-me` | Stress-test a plan or design |
| `workflow-housekeeping` | Audit rules/playbooks/index after you change workflow files |

## Scripts (`scripts/`)

| Script | Purpose |
| ------ | ------- |
| `new-ticket-changelog.ps1` | Create `docs/<system>/PRDV-XXXXX-changelog.md` |
| `validate-workflows.ps1` | Wiring audit — run after changing rules/docs |
| `sync-agents-md.ps1` | Regenerate root `AGENTS.md` from `.cursor/rules/*.mdc` (Codex mirror) |

## GitHub (stubs only — never `@`)

| File | Points to |
| ---- | --------- |
| `.github/git-commit-workflow.md` | `.cursor/rules/git-commit-workflow.mdc` |
| `.github/pull_request_template.md` | Fields for PlanetDepos PRs (use with `pull-request-workflow` playbook) |

## Wiring audit (run anytime)

```powershell
cd C:\Users\dustin.thomason\dustin-thomason
.\scripts\validate-workflows.ps1
```

Checks: five `alwaysApply` rules, playbooks, router links, no changelogs under `.cursor/docs/`, skills listed, index links.

## Consistency checklist (nothing missing)

| Step in real work | Covered by |
| ----------------- | ---------- |
| Workspace includes `dustin-thomason` | All `alwaysApply` rules load automatically |
| New agent on a ticket | `@docs/<system>/PRDV-XXXXX-changelog` ([session-start](../.cursor/docs/session-start.md) snippet) |
| Branch + changelog | `new-branch-get-started` + script + `ticket-changelog` rule |
| Work + agents | Changelog updated; link **Plans** when a plan exists |
| Commit | `git-commit-workflow` + `ticket-changelog` rules |
| PR | `pull-request-workflow` (via `personal-methodology` router) |
| Code quality | `build-implementation-guardrails` + app repo rules |
| Multi-area exploration | `context-fanout` — read-only subagent fanout |
| Spec | `spec-writing` (via router) |

If a new workflow type appears (e.g. release, hotfix), add **one row** above, **one** playbook, update `personal-methodology.mdc`, run `validate-workflows.ps1`.
