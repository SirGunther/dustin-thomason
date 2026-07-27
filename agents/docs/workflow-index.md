# Workflow index â€” what to @ in Cursor

One map for **dustin-thomason** personal workflows. When `@` shows too many matches, start here or type a filename from the table (e.g. `@new-branch`).

---

## Multi-root workspace (Callisto + dustin-thomason)

| Repo in workspace | Role |
| ----------------- | ---- |
| `callisto-back-end`, `atlas-front-end`, etc. | Code + **their** `.cursor/rules/` (Vue, Nest, `PRDV-X:` format) |
| `dustin-thomason` | **Your** methodology â€” rules load for the **entire** session |

### One rule: do you have to `@` or say â€œuse dustin-thomasonâ€?

| Kind | Loads automatically? | You must `@`? |
| ---- | -------------------- | ------------- |
| **Personal rules** (`alwaysApply: true` in dustin-thomason) | **Yes** â€” if `dustin-thomason` is in the workspace | **No** â€” say â€œwrite a specâ€ / â€œcommitâ€ / â€œopen a PRâ€ and [personal-methodology](../.cursor/rules/personal-methodology.mdc) routes to the right rule or playbook |
| **Ticket changelog** (data for one PRDV) | **Partially** â€” agents resolve + read at **task start** per `ticket-changelog` | **Optional** on new threads â€” `@` still helps when multiple tickets/repos are open |
| **Playbooks** (branch steps, PR template) | Yes when you use those **words** (router reads the `.md`) | No â€” unless the agent ignored you |

**You do not copy** `spec-writing.mdc` (or any personal rule) into Callisto. Keep one copy in dustin-thomason only.

**Example:** In Callisto you say *â€œWrite the story spec for PRDV-15263.â€* â†’ `spec-writing` applies. You do **not** say *â€œ@ spec-writing from dustin-thomason.â€*

**Example:** You say *â€œCommit.â€* â†’ `git-commit-workflow` + `ticket-changelog` apply; changelog file must still be updated under `dustin-thomason/docs/â€¦`.

### When app rules and personal rules both apply

- **Spec sections / tests / commit gates** â†’ your dustin-thomason rules.
- **`PRDV-12345:` commit prefix** on app branches â†’ app repo rule.
- **Nest/Vue architecture** â†’ app repo rules **plus** `build-implementation-guardrails`.

### Housekeeping

After you change workflow files: **â€œrun workflow housekeepingâ€** or `@workflow-housekeeping`. Script: `.\scripts\validate-workflows.ps1`

---

## Three layers (do not mix them up)

| Layer | Location | Loads how? |
| ----- | -------- | ------------ |
| **Rules** | `.cursor/rules/*.mdc` (generated from `rules/*.md`) | **Automatic** when `dustin-thomason` is in workspace (`alwaysApply: true`) |
| **Router** | `personal-methodology.mdc` | **Automatic** â€” maps â€œwrite specâ€ / â€œcommitâ€ / â€œopen PRâ€ to the right rule or playbook |
| **Playbooks** | `.cursor/docs/*.md` | **Automatic** when you name the task (router); not via `@` |
| **Artifacts** | `docs/**/PRDV-*-changelog.md`, `docs/<project>/*-changelog*` | Agents **read at task start** when substantive work begins; **`@`** optional pointer on new threads |

**Authoritative long content** lives in `docs/`. `.cursor/docs/` holds short, task-oriented playbooks that link into `docs/`. `.github/*.md` files are **stubs for GitHub browsing only** â€” do not `@` them.

---

## Generated outputs (how each system loads these rules)

`rules/*.md` (tool-neutral) is the **source of truth**. `agents/scripts/sync-rules.ps1` generates every tool-specific format from it, so no system keeps a duplicate copy:

| Output | Consumer | Committed? | Shape |
| ------ | -------- | ---------- | ----- |
| `.cursor/rules/*.mdc` | Cursor | **Yes** â€” machine-neutral | description + globs + alwaysApply |
| `.claude/rules/*.md` | Claude Code | **Yes** â€” machine-neutral | full body (always) or `paths:`-scoped (on-demand) |
| `AGENTS.md` | Codex (any AGENTS.md reader) | **Yes** â€” machine-neutral | concatenated bodies |

All three are committed, so `git pull` distributes rule changes to every machine. Claude Code loads `.claude/rules/` in-repo automatically, and in **other** project dirs via a one-time junction `~/.claude/rules/dustin-thomason` â†’ this repo's `.claude/rules`. Each rule's `scope`/`globs`/`codex` frontmatter (in `rules/`) drives how it lands in each output. **Never hand-edit a generated file** â€” edit `rules/` and run `sync-rules.ps1` (the pre-commit hook does this automatically). See `README.md` for one-time machine setup.

---

## What to `@` by task

| I want toâ€¦ | What you say or do | `@` needed? |
| ---------- | ------------------ | ----------- |
| **Pick a workflow** (unsure) | `@workflow-index` | Optional |
| **Write epic/story spec** (any repo) | â€œWrite the story spec â€¦â€ | **No** â€” `spec-writing` + `wiki-spec-authoring`; `@write-spec` for guided workflow |
| **Capture original ticket** | "Generate the original ticket artifact" / `@original-ticket-artifact` | Optional — creates `docs/<Project>/tickets/<slug>/original-ticket.md` before investigation/spec work |
| **Start ticket / branch** | â€œStart branch for PRDV-â€¦â€ | **No** â€” router reads `new-branch-get-started` |
| **Commit or push** | â€œCommitâ€ / â€œpush using git workflowâ€ | **No** â€” `git-commit-workflow` + `ticket-changelog` |
| **Open a PR** | â€œOpen PR for PRDV-â€¦â€ | **No** â€” router reads `pull-request-workflow` |
| **Implement code** | (normal implementation chat) | **No** â€” agent resolves changelog at **task start**; then `problem-requirement-solution` + `build-implementation-guardrails` + app repo rules |
| **Fix bug / regression** | (normal fix chat) | **No** â€” same **task-start** changelog alignment when a ticket or project log exists |
| **Debug front-end** layout/CSS/interaction at runtime | (drive/observe the live browser) | **No** â€” `browser-loop-guardrails` + [browser-loop-setup](../.cursor/docs/browser-loop-setup.md) |
| **Ticket context (new thread)** | `@docs/atlas/PRDV-XXXXX-changelog` | **Optional** â€” explicit pointer; agent should still resolve changelog from branch/ticket id |
| **Run a ticket end-to-end** | `orchestrate PRDV-...` / `orchestrate <project> <slug>` | No (skill by name) - seven phases, exit gates, mode handoffs, resumable ledger |
| **Stress-test a plan** | `@grill-me` | Yes (skill) |
| **Audit workflow docs** | â€œrun workflow housekeepingâ€ | Optional `@workflow-housekeeping` |

`@` a **rule** only when the agent **ignored** you â€” not as your normal habit.

---

## Personal rules (automatic â€” `alwaysApply: true`)

| Rule file | Purpose |
| --------- | ------- |
| `personal-methodology` | Routes intent â†’ spec / commit / PR / branch (no copy into app repos) |
| `spec-writing` | Epic/story sections in **Callisto, Atlas, anywhere** |
| `git-commit-workflow` | audit â†’ lint â†’ tests â†’ git â†’ paste SHA |
| `ticket-changelog` | task-start alignment + session log before commit |
| `build-implementation-guardrails` | Â§5 shipping checklist: tests/regression, changelog (PRDV + personal projects), Swagger when applicable |
| `context-fanout` | read-only exploration subagents for multi-area context compaction |
| `browser-loop-guardrails` | boundary rules for runtime browser observation + CSS/layout/interaction debugging |
| `problem-requirement-solution` | frame implementation/plans/specs as Problem â†’ Requirement â†’ Solution |
| `agent-completion-notification` | end of substantive sessions â€” `notify-agent-complete.ps1` â†’ Power Automate |

Not always-on: `workflow-housekeeping` (only when editing workflow files here); `agents-sync` (regenerate `AGENTS.md` + `.claude/rules` after rule/skill edits).

---

## Playbooks (`.cursor/docs/`)

| File | When |
| ---- | ---- |
| [new-branch-get-started.md](../.cursor/docs/new-branch-get-started.md) | New `PRDV-*` branch |
| [pull-request-workflow.md](../.cursor/docs/pull-request-workflow.md) | `gh pr create`, PR body, Slack post |
| [README.md](../.cursor/docs/README.md) | Pointer to this index |
| [browser-loop-setup.md](../.cursor/docs/browser-loop-setup.md) | Wire and observe a live browser for front-end debugging |

---

## Artifacts (`docs/`)

| Path | When |
| ---- | ---- |
| [original-ticket-artifact.md](./original-ticket-artifact.md) | Capture the baseline request as `original-ticket.md` before investigation/spec work |
| `agents/README.md` (un-synced) | Why each `agents/` file exists + the orchestration flow at a glance — root TOC, never mirrored |
| [cleanup-candidates.md](./cleanup-candidates.md) | Archive/consolidation ledger - fed by orchestrated runs' cruft checks |
| [investigation-coverage-ledger.md](./investigation-coverage-ledger.md) | Per-ticket visited-state map: template + consult/reopen protocol |
| [investigation-diagrams.md](./investigation-diagrams.md) | Standalone diagrams artifact (delta, flows, sequences) for investigations |
| [future-development-concerns.md](./future-development-concerns.md) | Per-ticket risk record: dated, code-verified concerns shipped out of scope |
| [why-these-changes.md](./why-these-changes.md) | Per-ticket living "Why" doc — class of problem + reasoning arc across all phases, ending as the "why these changes" review |
| [test-plan-artifact.md](./test-plan-artifact.md) | Per-ticket test plan: seeded from the report, executed at implementation |
| [testing-implementation-artifact.md](./testing-implementation-artifact.md) | Per-ticket, scenario-first record of the real situations stress-tested (+ any change hung off each), explaining to other devs what was addressed — for the PR comment |
| [ticket-changelog-workflow.md](./ticket-changelog-workflow.md) | How changelogs work end-to-end |
| [wiki-spec-authoring.md](./wiki-spec-authoring.md) | PRDV wiki naming, Obsidian wiring, dev notes, author checklist |
| [docs/atlas/local/callisto-local.mdc](./atlas/local/callisto-local.mdc) | Callisto backend local runbook (Docker, migrations, DBeaver) |
| [docs/atlas/local/triton-local.mdc](./atlas/local/triton-local.mdc) | Triton backend local runbook |
| [docs/atlas/local/europa-local.mdc](./atlas/local/europa-local.mdc) | Europa backend local runbook |
| `docs/<system>/PRDV-XXXXX-changelog.md` | **This ticketâ€™s** memory in **dustin-thomason** only â€” `@` every new agent thread. `larry-adams` = read-only spec links in **Plans**, not a push target |
| [\_templates/TICKET-changelog.template.md](./_templates/TICKET-changelog.template.md) | Rarely â€” use `scripts/new-ticket-changelog.ps1` instead |
| `docs/WorkLists/` | One-off personal work lists |

**Do not** keep ticket changelogs under `.cursor/docs/` â€” only `docs/<system>/` to avoid duplicate `@` suggestions.

---

## Scaffold script (terminal, not `@`)

```powershell
# from the dustin-thomason repo root
.\scripts\new-ticket-changelog.ps1 -Ticket PRDV-15263 -System atlas -Title "Short title"
```

---

## Narrowing `@` suggestions in Cursor

1. Type more characters: `@new-branch`, `@pull-request`, `@PRDV-12264`.
2. Prefer **one playbook** or **one changelog** per message â€” not the whole repo.
3. Do not `@` `.github/` stubs or duplicate paths.
4. Rules with `alwaysApply: true` â†’ trust them; `@` only on failure.

---

## Skills (`.cursor/skills/`)

Skills are **not** `alwaysApply` â€” the user `@`â€™s the skill or asks in plain language.

| Skill | Invoke when |
| ----- | ----------- |
| `write-spec` | Author/update PRDV specs or dev notes (see [wiki-spec-authoring.md](./wiki-spec-authoring.md)) |
| `grill-me` | Stress-test a plan or design |
| `workflow-housekeeping` | Audit rules/playbooks/index after you change workflow files |
| `investigation` | Investigate a problem + proposed fix before committing to it (emits an Investigation Report) |
| `orchestrate` | Run a ticket end-to-end through all seven phases with full-rigor artifacts, gates, and a per-ticket ledger |

## Scripts (`scripts/`)

| Script | Purpose |
| ------ | ------- |
| `new-ticket-changelog.ps1` | Create `docs/<system>/PRDV-XXXXX-changelog.md` |
| `notify-agent-complete.ps1` | Post session completion to Power Automate (`agent-completion-notification` rule) |
| `validate-workflows.ps1` | Wiring audit (incl. generated-output staleness) â€” run after changing rules/docs |
| `sync-rules.ps1` | **Primary generator** â€” rebuilds `.cursor/rules/` (Cursor) + `.claude/rules/` (Claude Code) + `AGENTS.md` (Codex) from `rules/*.md`. `-Check` fails on stale output. |
| `sync-agents-md.ps1` | Backwards-compatible shim â†’ `sync-rules.ps1` |

## GitHub (stubs only â€” never `@`)

| File | Points to |
| ---- | --------- |
| `.github/git-commit-workflow.md` | `.cursor/rules/git-commit-workflow.mdc` |
| `.github/pull_request_template.md` | Fields for PlanetDepos PRs (use with `pull-request-workflow` playbook) |

## Wiring audit (run anytime)

```powershell
# from the dustin-thomason repo root
.\scripts\validate-workflows.ps1
```

Checks: required `alwaysApply` rules, expected scripts, playbooks, router links, no changelogs under `.cursor/docs/`, skills listed, index links.

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
| Framing implementation | `problem-requirement-solution` â€” Problem â†’ Requirement â†’ Solution |
| Multi-area exploration | `context-fanout` â€” read-only subagent fanout |
| Front-end runtime debugging | `browser-loop-guardrails` + `browser-loop-setup` playbook |
| Spec | `spec-writing` + `wiki-spec-authoring`; `@write-spec` for guided flow |
| Agent finished substantive work | `agent-completion-notification` â†’ `notify-agent-complete.ps1` |

If a new workflow type appears (e.g. release, hotfix), add **one row** above, **one** playbook, update `personal-methodology.mdc`, run `validate-workflows.ps1`.

<!-- BEGIN generated:inventory (agents/scripts/sync-rules.ps1) - do not edit; regenerate with sync-rules.ps1 -->
## Complete inventory (generated)

Every rule, skill, doc, and script under `agents/` (and `scripts/`), auto-built from the folder + frontmatter by `agents/scripts/sync-rules.ps1`. `-Check` fails if this is stale, so nothing you add can silently miss the index. The routing/editorial sections above are hand-written.

### Rules (`agents/rules/`)

| Rule | Load | Purpose |
| ---- | ---- | ------- |
| `agent-completion-notification` | always | At the end of substantive agent work in dustin-thomason, run notify-agent-complete.ps1. |
| `agents-sync` | scoped | After editing rules or skills in dustin-thomason, regenerate all downstream outputs (.cursor/rules, .claude/rules, .claude/CLAUDE.md, AGENTS.md) with sync-rules.ps1. |
| `browser-loop-guardrails` | always | Boundary rules for a runtime browser-observation loop (Playwright/CDP/MCP) and for any CSS/layout/interaction debugging — fix the responsible cascade rule not the symptom, explain magic constants, keep independent constants independent, treat a green check as necessary-not-sufficient, and escalate after bounded iteration instead of spiraling. |
| `build-implementation-guardrails` | always | Mandatory tests, changelog, Swagger (when applicable), architecture guardrails for Codex/agent builds — shipping checklist, coverage, non-regression, graceful failure, SOLID shaping, avoid raw Postgres/SQL unless unavoidable. |
| `context-fanout` | always | Prefer read-only exploration subagents for multi-area investigation so the parent context stays compact and focused. |
| `git-commit-workflow` | always | Standard commit/push habit for dustin-thomason—runs to completion via npm audit/lint/serial-test gates (when applicable), git status → add → commit → push when an agent pushes work here or in sibling Node repos. |
| `personal-methodology` | always | Routes dustin-thomason personal standards into any workspace repo (Atlas, Callisto, etc.) without copying rules there or requiring @-mentions. |
| `problem-requirement-solution` | always | Coherent implementation philosophy — reason in order Problem → Requirement → Solution so the line of thinking stays clear for the end user, in implementations, plans, specs, and changelog/PR narratives. |
| `source-truth` | always | Stop and ask for the source artifact rather than inferring exact labels, mappings, wording, or evidence from memory or partial context. |
| `spec-writing` | always | Required sections when authoring epic and story specs (artifacts, schema, migrations, DTOs, projections) — any repo in the workspace. |
| `ticket-changelog` | always | Changelog alignment at task start; scaffold on branch start; verbatim requirements on first pass; session log before every PlanetDepos commit. |
| `workflow-housekeeping` | scoped | When workflow docs or rules change in dustin-thomason, sync workflow-index and run validate-workflows.ps1. |

### Skills (`agents/skills/`)

| Skill | Purpose |
| ----- | ------- |
| `grill-me` | Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me". |
| `investigation` | The method for investigating a problem and its proposed fix before committing to it — in any domain (software, workflow, policy, process, etc.). Ground in real instances, classify the problem, lock acceptance criteria, trace why it exists, re-confirm the class, then stress-test the solution against scale, generalization, and fit. Emits an Investigation Report (see the investigation-report template): verdict, problem class, assumptions-to-test, a happy/negative validation plan, recommendation with gates, and open variables to collect. Use when scoping a change, validating assumptions, writing a spec, or when the user says "investigate". |
| `orchestrate` | Conduct a ticket end-to-end through the seven-phase lifecycle — capture original ticket, investigate, report, probe and spec, prep for implementation, implement, manual review — with full-rigor artifacts, phase exit gates, and a standardized handoff at every mode boundary. Resumable from the per-ticket ledger. Use when the user says "orchestrate", "orchestrate PRDV-XXXXX", "run the ticket workflow", "take this ticket through the phases", or "resume/continue orchestration". |
| `workflow-housekeeping` | Audit dustin-thomason workflow docs, rules, and index for drift, duplicates, and missing entries. Use when user asks to housekeeping workflows, sync workflow-index, validate personal Cursor setup, or after adding a new playbook or rule. |
| `write-spec` | Create or update epic/story specs and dev notes for Callisto/Atlas. Use when the user asks to write a spec, author PRDV ticket documentation, create a dev note for estimation, or extend specs under a systems/ wiki tree. |

### Docs & playbooks (`agents/docs/`)

| Doc | About |
| --- | ----- |
| `browser-loop-setup.md` | Browser-loop setup (dustin-thomason) |
| `cleanup-candidates.md` | Cleanup candidates — archive and consolidation ledger |
| `current-vs-target-diagram.md` | Current vs Target diagram — a single-diagram delta convention |
| `future-development-concerns.md` | Future-development concerns — the risk record artifact |
| `investigation-coverage-ledger.md` | Investigation coverage ledger — the visited-state map |
| `investigation-diagrams.md` | Investigation diagrams — the standalone visuals artifact |
| `investigation-question-coverage.md` | Investigation method — question coverage checklist |
| `investigation-report.md` | Investigation Report: <short title> |
| `investigation-software-gaps.md` | Investigation method — software lens |
| `new-branch-get-started.md` | Start a new branch |
| `original-ticket-artifact.md` | Original Ticket Artifact |
| `problem-check.md` | Problem Check — is the question even the right question? |
| `pull-request-workflow.md` | Pull request workflow (reference) |
| `qa-to-spec-traceability.md` | Q and A to Spec Traceability |
| `README.md` | Cursor docs (playbooks) |
| `session-start.md` | Session start (optional) |
| `testing-implementation-artifact.md` | Testing-implementation artifact — the scenarios stress-tested |
| `test-plan-artifact.md` | Test plan artifact — how to test the implementation |
| `ticket-changelog-workflow.md` | Ticket changelog workflow |
| `ticket-orchestration.md` | Ticket orchestration — superseded by the `orchestrate` skill |
| `why-these-changes.md` | Why these changes — the living "Why" of the whole ticket |
| `wiki-spec-authoring.md` | Wiki spec authoring (Callisto / Atlas) |

### Scripts (`scripts/`, `agents/scripts/`)

| Script | Purpose |
| ------ | ------- |
| `bootstrap.ps1` | One-time per-machine baseline: wire dustin-thomason's agent rules into Claude Code globally. |
| `gitcommit.ps1` |  |
| `new-ticket-changelog.ps1` | Scaffold docs/<system>/PRDV-XXXXX-changelog.md from the ticket template. |
| `notify-agent-complete.ps1` | POST agent session completion to a Power Automate manual-trigger webhook. |
| `start-apps.ps1` |  |
| `sync-agents-md.ps1` | Backwards-compatible shim. The generator is now scripts/sync-rules.ps1, which produces |
| `sync-rules.ps1` | Generate every tool-specific rule artifact from the single neutral source of truth (rules/*.md). |
| `validate-workflows.ps1` | Audits dustin-thomason workflow wiring: rules, playbooks, skills, scripts, duplicates. |
<!-- END generated:inventory -->
