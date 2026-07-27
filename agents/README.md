# Agents folder — index / table of contents

Why each file under `agents/` exists — what it represents, in one or two sentences — plus the orchestration flow at a glance.

**This file is deliberately un-synced.** `sync-rules.ps1` mirrors only `agents/rules/`, `agents/skills/`, and `agents/docs/`; this root README is never copied into `.cursor/`, `.claude/`, or the `agents-*.md` compilations, and never enters agent context. It is the human-facing map — and the table of contents the post-integration cleanup pass works from (see [cleanup-candidates](docs/cleanup-candidates.md)). The **generated inventory** in [workflow-index](docs/workflow-index.md) is the synced, auto-refreshed *what exists* list; this file is the hand-curated *why*.

**Maintenance rule:** adding a file under `agents/` requires adding its row here in the same session. A file with no row here is a cleanup candidate by definition.

---

## Orchestration flow at a glance

The standard ticket lifecycle, run end-to-end by the [`orchestrate` skill](skills/orchestrate/SKILL.md). Modes are user-controlled; the skill stops with a handoff block at every mode boundary and gates every phase exit.

| Phase | Name | Mode | What happens | Artifacts produced |
| --- | --- | --- | --- | --- |
| 0 | Capture | Working | The request is preserved verbatim as the source-of-truth artifact; the phase ledger is scaffolded; changelog aligned | `original-ticket.md`, `orchestration.md` |
| 1 | Investigate | Plan | Prior coverage ledgers consulted first; the investigation method runs with the software lens; an investigation plan is built for approval | approved plan (staged coverage rows) |
| 2 | Report | Working | The investigation report is written; coverage ledger, diagrams artifact, and test-plan seed materialize | `<slug>-investigation.md`, `<slug>-coverage-ledger.md`, `<slug>-diagrams.md`, `<slug>-test-plan.md` |
| 3 | Probe & spec | Working | grill-me resolves open variables under the traceability workflow; locked decisions inform the spec | locked-decision ledger, `<slug>-spec.md`, refined test plan, concerns entries |
| 4 | Prep | Plan | Brief implementation plan from the artifacts — no re-investigation | approved implementation plan |
| 5 | Implement | Working | Build under the guardrails; execute the test plan; session log + gates before commit; PR | code, executed test plan, PR |
| 6 | Manual review | Idle | Review summary citing test results; cruft check feeds cleanup-candidates; ledger closed; completion notification | closed ledger |

Per-ticket artifacts live in `docs/<Project>/tickets/<slug>/` (layout defined in the skill); superseded material moves to that ticket's `dnu/`.

---

## `agents/rules/` — always-on and scoped behavior rules

Tool-neutral rule sources; `sync-rules.ps1` generates the `.cursor/rules/`, `.claude/rules/`, and `AGENTS.md` outputs from them.

| File | What it represents / why we have it |
| --- | --- |
| `agent-completion-notification.md` | Ends every substantive session with a Power Automate ping (`notify-agent-complete.ps1`) so finished agent work is visible without watching the terminal. |
| `agents-sync.md` | The source-of-truth doctrine: `agents/` is hand-edited, everything downstream is generated; defines when and how to regenerate. Exists so nobody hand-edits a mirror. |
| `browser-loop-guardrails.md` | Boundary rules for runtime browser debugging and any CSS/layout fix — fix the responsible rule not the symptom, explain magic constants, escalate instead of tuning forever. Exists because a fast observe-fix loop makes symptom-patching fast too. |
| `build-implementation-guardrails.md` | The shipping obligations for substantive builds: tests as part of shipping, regression posture, layered graceful degradation, architecture fit, the §5 checklist. The quality floor for Phase 5. |
| `context-fanout.md` | Prefer read-only exploration subagents for multi-area investigation so the parent context stays compact. Exists because serial deep-reading burns the context that planning needs. |
| `git-commit-workflow.md` | The landing sequence: audit → lint → serial tests → status/add/commit/push → paste SHA; never tag reviewers. Exists so every commit clears the same gates in the same order. |
| `personal-methodology.md` | The router: maps plain-language intent ("write spec", "commit", "open PR") to the right rule or playbook in any workspace repo, and defines repo-rules-vs-personal-rules precedence. |
| `problem-requirement-solution.md` | The framing philosophy: reason Problem → Requirement → Solution, in that order, anywhere a change is explained. Exists because a solution without a stated problem isn't reviewable. |
| `source-truth.md` | The stop rule: source-dependent answers (exact labels, mappings, evidence) come from the artifact or not at all — never from memory or reconstruction. |
| `spec-writing.md` | The required sections for epic/story specs (classes, entities, migrations, DTOs, projections, cross-cutting callouts). The standard a Phase 3 spec is judged against. |
| `ticket-changelog.md` | Cross-session ticket memory: changelog alignment at task start, session log before every commit, Plans table discipline, verification-gate reporting standard. |
| `workflow-housekeeping.md` | Scoped rule: after workflow files change, sync the index and run `validate-workflows.ps1`. Keeps the meta-layer honest. |

## `agents/skills/` — invocable workflows

Folder name = invocation name. Mirrored verbatim to `.cursor/skills/` and `.claude/skills/`.

| Skill | What it represents / why we have it |
| --- | --- |
| `grill-me` | The interview method: one question at a time, current-behavior check, recommended answer — until a plan or design reaches shared understanding. The probe half of Phase 3. |
| `investigation` | The investigation method: ground in instances, classify, lock the contract, trace origin, stress-test, emit the Investigation Report. The engine Phase 1 executes. |
| `orchestrate` | The end-to-end ticket lifecycle conductor: seven phases, exit gates, mode handoffs, per-ticket ledger, full-rigor artifacts. The standard way to run a ticket when completeness matters. |
| `workflow-housekeeping` | The audit workflow for this meta-layer itself: drift, duplicates, missing index entries. |
| `write-spec` | Guided authoring of PRDV epic/story specs and dev notes against the wiki conventions. The PRDV route for Phase 3's spec output. |

## `agents/docs/` — playbooks, methods, and artifact templates

Mirrored verbatim to `.cursor/docs/` and `.claude/docs/`.

| Doc | What it represents / why we have it |
| --- | --- |
| `README.md` | Router table mapping a task to the playbook doc to load. Entry point for agents/humans browsing `docs/` (distinct from this root README, which is the un-synced why-catalog). |
| `browser-loop-setup.md` | The wiring playbook for driving/observing a live browser during front-end debugging (capabilities, setup, tools); pairs with `browser-loop-guardrails`. |
| `cleanup-candidates.md` | The archive/consolidation ledger: known cruft, proposed fates, blockers. Fed by Phase 6 cruft checks; worked after the orchestrate integration proves out. |
| `current-vs-target-diagram.md` | The single-diagram delta convention: current and target in one Mermaid figure, lanes = owners, color = change status. Referenced by the diagrams artifact. |
| `future-development-concerns.md` | Template + rules for the per-ticket risk record: dated, code-verified concerns that ship out of scope but must stay findable and escalation-ready. |
| `why-these-changes.md` | Template for the per-ticket living **"Why"** doc — created Phase 1, updated every phase, finalized at close. Heart is the class of problem; logs the reasoning arc (obvious/not/changed/noise) and ends as the "why these changes" review. High-level; distinct from the testing-implementation scenarios. |
| `investigation-coverage-ledger.md` | Template + consult protocol for the per-ticket visited-state map: where the agent looked, how deeply, what it found or ruled out — so later agents reuse instead of re-traversing. |
| `investigation-diagrams.md` | Defines the standalone diagrams artifact (current-vs-target, flows, sequences for race conditions) so reports link visuals instead of embedding them. |
| `investigation-question-coverage.md` | Meta-audit proving the investigation method covers a collected question list. Historical justification, not operational input — an archive candidate. |
| `investigation-report.md` | The Investigation Report artifact template (§0 verdict through §12 definition of done). What Phase 2 fills in. |
| `investigation-software-gaps.md` | The adopted software lens for investigations: contract alignment, surface enumeration, protect-the-neighbors, detection gap, red→green test, repro recipe. Mandatory in Phase 1 for software tickets. |
| `new-branch-get-started.md` | The steps to start a `PRDV-*` branch and pick up a ticket. Referenced by Phase 4's branch step. |
| `original-ticket-artifact.md` | Template + rules for `original-ticket.md`: preserve the request verbatim as the baseline fact before any investigation or spec work. What Phase 0 executes. |
| `problem-check.md` | The framing lens (Asked / Answered / Should-ask + Conflation / Thin / Off) run on every investigation's problem statement; embedded in the investigation method's Step 1. |
| `pull-request-workflow.md` | The PR playbook: branch, commit evidence, body format, Slack post. Referenced by Phase 5. |
| `qa-to-spec-traceability.md` | The locked-decision workflow: every answered question becomes a cited, non-reaskable decision that lands in the spec. Governs Phase 3's grill-me pass. |
| `session-start.md` | Optional copy-paste snippets to point a fresh agent thread at a ticket/changelog. |
| `testing-implementation-artifact.md` | Template for the per-ticket, **scenario-first** record that explains to other devs *what was addressed* — the real situations stress-tested (why each matters; newly-uncovered ones flagged), with any code change hung off its scenario (file + observed → expected → fix). Assembled for the GitHub PR comment, never a code comment. Produced in Phase 5. |
| `test-plan-artifact.md` | Template + lifecycle for the per-ticket test plan: seeded from the report's validation plan, refined by the spec, executed at implementation, cited at review. |
| `ticket-changelog-workflow.md` | The end-to-end changelog playbook behind the `ticket-changelog` rule. |
| `ticket-orchestration.md` | Pointer stub → the `orchestrate` skill (the original prompt sheet was folded into it). Tracked for eventual deletion. |
| `wiki-spec-authoring.md` | PRDV wiki conventions: naming, frontmatter, Obsidian wiring, dev notes. Pairs with `write-spec` and the `spec-writing` rule. |
| `workflow-index.md` | The master map: layers, what-to-@ routing, and the generated complete inventory. |

## `agents/scripts/` — the generator layer

| Script | What it represents / why we have it |
| --- | --- |
| `bootstrap.ps1` | One-time per-machine wiring: hook, `~/.claude/CLAUDE.md` import, optional skills mirror. |
| `sync-rules.ps1` | The single generator: builds `.cursor/`, `.claude/`, `AGENTS.md`, and the workflow-index inventory from `agents/`; `-Check` fails on stale output. The reason hand-edited and generated content never mix. |
| `sync-agents-md.ps1` | Backwards-compatible shim to `sync-rules.ps1`; deletion tracked in cleanup-candidates. |

## Root of `agents/`

| File | What it represents / why we have it |
| --- | --- |
| `README.md` | This file — the un-synced index/TOC: why every `agents/` file exists, plus the orchestration flow at a glance. |

## Repo-level `scripts/` (used by the flow, not part of `agents/`)

`validate-workflows.ps1` (wiring audit + stale-output check), `new-ticket-changelog.ps1` (changelog scaffold), `notify-agent-complete.ps1` (completion ping), `gitcommit.ps1` / `git-maintenance.ps1` (commit helpers), `git-hooks/pre-commit` (runs the sync at commit time), `browser/*.mjs` (browser-loop tooling). Their authoritative list lives in the generated inventory.
