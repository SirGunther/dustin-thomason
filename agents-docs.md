# agents-docs (generated — do not edit)

Source: `agents/docs/**`. Regenerate with `.\agents\scripts\sync-rules.ps1`.

## browser-loop-setup.md

# Browser-loop setup (dustin-thomason)

Task-oriented setup for the runtime browser-observation loop: wiring an agent to observe and drive a live browser during front-end work, so it observes truth (runtime layout, cascade, interaction state) instead of inferring it.

- **Boundary rules (mandatory, load first):** [browser-loop-guardrails.mdc](../rules/browser-loop-guardrails.mdc)
- **Authoritative spec:** [runtime-browser-loop-spec-1.md](../../docs/agents/runtime-browser-loop-spec-1.md)

## When to use

Diagnosing or verifying front-end layout, CSS cascade, or interaction (drag/resize/toggle) at runtime — especially "works at the start and end but breaks in between" bugs, cascade conflicts ("which rule won?"), and flush-to-edge / off-by-N geometry.

## One-time setup

**Stock browser MCP** (drive / screenshot / console / network). This repo ships a project-scoped `.mcp.json` with the Playwright MCP; for availability in **every** project, also register it at user scope:

```
claude mcp add --scope user playwright -- npx @playwright/mcp@latest
```

**Custom CDP tools** (cascade provenance, trajectory sampler, baselines) live in `scripts/browser/`:

```
cd scripts/browser
npm install
npx playwright install chromium
```

(Cursor / other harnesses: add the Playwright MCP to their MCP config. Chrome DevTools MCP is an alternative for driving + console + network.)

## Tools

| Capability | Tool | Status |
| ---------- | ---- | ------ |
| Navigate, click, drag, type; screenshot; console; network bodies | Stock browser MCP (Playwright MCP / Chrome DevTools MCP) | Available now |
| Cascade provenance — which rule won and what it struck through (`CSS.getMatchedStylesForNode`) | `scripts/browser/css-provenance.mjs` | Available |
| Stepped-drag trajectory sampler — per-step `getBoundingClientRect` for many elements + discontinuity flagging | `scripts/browser/trajectory-sampler.mjs` | Available |
| Per-component baseline capture/compare (geometry + visibility + threshold screenshot) | `scripts/browser/baseline.mjs` | Available |

The provenance/trajectory/baseline items are **not** reliably exposed by stock MCP tools; they are thin custom scripts the agent invokes via the shell (they use Playwright + a raw CDP session under the hood). Invocation examples below.

## Invoking the custom tools

Run from `scripts/browser/` (or with the full path). All emit JSON on stdout.

```bash
# Which rule won each property on an element, and what it struck through (spec 3.1):
node css-provenance.mjs --url http://localhost:5173 --selector ".panel"
#   attach to an already-open Chrome instead of launching one:
node css-provenance.mjs --cdp http://localhost:9222 --selector ".panel"

# Stepped drag; capture geometry of many elements per step; flag impossible jumps (spec 3.2-3.3).
# Exits 1 if a discontinuity is flagged. Prefer a --config file for real cases:
node trajectory-sampler.mjs --url http://localhost:5173 --handle ".resize-handle" \
  --dx -240 --dy 0 --steps 12 --watch ".panel,.panel .content,.neighbor" --threshold 50 \
  --trigger-click ".backdrop"

# Per-component baseline: capture once, compare on later changes (spec 3.4, 4).
node baseline.mjs capture  --url http://localhost:5173 --selectors ".panel,.panel .content" \
  --dir ../../docs/<project>/baselines/panel --clip ".panel"
node baseline.mjs compare  --url http://localhost:5173 --selectors ".panel,.panel .content" \
  --dir ../../docs/<project>/baselines/panel --clip ".panel" --max-diff-pixels 100
```

The trajectory sampler takes a `--config <file>` too (fields: `url`, `handle`, `delta:{dx,dy}`, `steps`, `watch:[…]`, `threshold`, `trigger:{action,selector}`) — use it for boundary conditions and multi-step scenarios.

## Method (from the spec)

- **Provenance over guessing.** Use matched styles to get *who won* and *what it overrode*, not just the final computed value.
- **Real interaction, not simulated state.** Dispatch real press -> move-through-intermediate-points -> release. Do not shortcut a resize by setting a width; that skips handle-specific behavior.
- **Sample the trajectory.** Step the interaction in increments; at each checkpoint capture geometry for the target *and* its contents *and* neighbors. Include boundary conditions (fully expanded/collapsed) and follow them with the triggering action (e.g. click-out) plus its assertion. Flag any tracked element that jumps size/position impossibly between adjacent steps.
- **Right tool for the assertion.** Geometry (`getBoundingClientRect`, computed styles) is sub-pixel exact and stable — use it for numeric position/size/spacing checks. Screenshot diffing is noisy — use it for holistic visual regression, always with a pixel tolerance.

## Baselines

Per component, store a baseline and assert future changes against it:

```
docs/<project>/baselines/<component>/
  baseline.json   # geometry (rects) + visibility
  baseline.png    # threshold screenshot
```

Keep the narrative changelog as context, but the baseline is what *tells* a later agent it broke something instead of letting it believe it did not. Note replication conditions (viewport, timing, external state) precisely — clean for deterministic layout/CSS bugs, flakier otherwise.

## Guardrails (always in effect)

The six boundary rules in [browser-loop-guardrails.mdc](../rules/browser-loop-guardrails.mdc) apply the entire time: no specificity band-aids, explain magic constants, keep independent constants independent, a green check is necessary-not-sufficient, fix the rule not the symptom, and **escalate after ~3 non-converging attempts** with a structured account instead of continuing to tune.

## Handoff checklist (spec section 7)

- [x] Claude Code (or equivalent) as the loop; no custom harness.
- [x] Playwright driving + raw `newCDPSession` for hidden domains (DOM/CSS) — used by the scripts below.
- [x] Stock browser MCP for drive / screenshot / console / network — `.mcp.json` (Playwright MCP).
- [x] Thin custom tool: `CSS.getMatchedStylesForNode` cascade/provenance query — `scripts/browser/css-provenance.mjs`.
- [x] Thin custom tool: stepped-drag trajectory sampler capturing multi-element `getBoundingClientRect` + discontinuity flagging — `scripts/browser/trajectory-sampler.mjs`.
- [x] Baseline store per component (geometry + visibility + threshold screenshot) — `scripts/browser/baseline.mjs` + `docs/<project>/baselines/`.
- [x] Boundary rules loaded as enforced agent rules **before** the loop is used — `browser-loop-guardrails` (alwaysApply).

Per-machine activation still required: `npm install` + `npx playwright install chromium` in `scripts/browser/` (see One-time setup).

## investigation-report.md

# Investigation Report: <short title>

> **What this is:** the delivered results of running the `investigate` method — findings and recommendation, plus the plan for what happens next. Use it as the shared reference for future discussions and decisions.
> **What this is not:** a plan *to* investigate. By the time this report exists, the investigating is done.
>
> **Reading order ≠ fill order.** The report reads verdict-first (bottom line up front), but it is filled in dependency order: instances → class → contract → root cause (class re-check) → solution → validation → verdict last.
>
> Copy this per investigation to `docs/investigations/<id>-<slug>.md`. Sections 0–10 are the findings; Section 11 is the emitted plan. Keep it updated as the source of truth while the work proceeds.

## Metadata
- **Status:** draft | investigating | planned | in-progress | done
- **Disposition:** proceed | proceed with conditions | blocked | rejected | needs more investigation
- **Date:**
- **Owner:**
- **Location:** `docs/investigations/<id>-<slug>.md`
- **Ticket:** <ClickUp link>
- **Domain:** software | workflow | policy | process | ...
- **References / evidence:** <primary sources — code paths, commits, docs, transcripts, clauses>

---

## 0. Verdict (bottom line up front — written last, read first)
<One paragraph: current viability, the strongest path forward, and — explicitly — what this is NOT yet (e.g. "viable, but not a production approval").>

- **Strongest path:**
- **Not yet proven / not approved:**

## 1. Problem class
> The single highest-leverage call in this report — everything below is checked against it. The class is derived from real instances (Section 2), held as provisional, and re-confirmed against root-cause evidence (Section 5). Get it wrong and the whole report solves the wrong problem.

- **Class the request assumed** (implied by how it was framed):
- **Confirmed class** (derived from instances, re-checked against root cause):
- **Reframed?** no — because: <argue why the assumed class held> | yes → from **<assumed>** to **<confirmed>**, triggered by: <what evidence flipped it, and at which step>
- **What the confirmed class implies** (how the solution space changes vs. the assumed class):

*Why this matters: a request framed as "data access — who can reach which systems" can turn out to be a knowledge-management problem — where the data lives and how people discover it. Same symptoms, different class, completely different solution. The framing was aimed at the wrong target, and everything downstream inherited the error.*

## 2. Problem statement (the raw facts — collected before classification)
- **Named instances** (specific people/cases, blocked right now, on real tasks):
- **One sentence** (a stranger could confirm or deny):
- **Distinct problems** (don't merge them):
- **Urgency** (date or trigger event when it bites next):
- **Wedge** (smallest reusable issue *within the confirmed class* that opens the space):

## 3. The contract (locked before any solutioning)
### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
|           | covered / needs-proof / documented / gap |  |

### Non-goals / out of scope
- <what this explicitly does NOT cover, and why — this is what prevents scope churn later>

## 4. What changed since the request was created
- **Shifted from:** <original framing> → **to:** <current framing>
  *(If the class itself changed, lead with that and point to Section 1 — it's the most important kind of shift.)*
- **What that buys us:**
- **What it still needs to prove:**

## 5. Why it exists
- **Origin traced to:**
- **Evidence** (primary-source pointers):
- **Class re-check:** held | flipped → <what the root-cause evidence showed; if flipped, confirm the wedge and acceptance criteria were redone>

## 6. Alternatives considered
> Pre-answers the future "why didn't we just X?"

| Alternative | Rejected because |
|-------------|------------------|
|             |                  |

## 7. Solution & stress-test
- **Proposed solution:**
- **Solves the confirmed class** (not the assumed one, not just this occurrence)?
- **Scale:**
- **Generalization** (abstract, or overreach?):
- **Fit** (conventions / philosophy):
- **Adjacent issues** (fix now vs. follow-up + effort tradeoff):
- **Sufficiency** (covers the pain that convened this, or a corner of it?):
- **Feedback speed** (how fast reality tells us we're wrong):
- **Happy-path story** (30 seconds — who does what, without whom):

## 8. Assumptions ledger
> Populated throughout the investigation as claims are made — not backfilled at the end. Each is a falsifiable claim with a test. "Confirmed directionally" still owes proof of performance, accuracy, and parity.

- **Claim:** <…>
  - **Status:** open | confirmed | confirmed directionally | revised | refuted
  - **Confirm/revise by:** <method / test>
- **Claim:** <…>
  - **Status:**
  - **Confirm/revise by:**

## 9. Validation plan
**Happy path**
- <the sequence that should work, step by step>

**Negative paths**
- <what must fail *visibly* rather than corrupt silently>
- <volume / limit / threshold breaches>
- <removed or trimmed dependencies proven non-required>
- <timing / refresh / latency bounds that must hold>

## 10. Decisions, recommendation & open variables
- **Decisions** (settled):
- **Recommendation** (what to do, in order):
- **Sequencing & gates:** <what proceeds first; what stays gated behind which proof or artifact — e.g. "Do not start Y until X proves parity, performance, ownership, and security controls">

### Open variables to collect
> Logged as they surfaced during the investigation. Assign an owner where possible.

- [ ] <value / mapping / threshold / owner / boundary> — owner:
- [ ] <…> — owner:

---

## 11. Plan — Next steps
*This is the emitted plan. The agent works it from here; check items off as they land.*

### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
|        |       |                         |

### Checklist
#### Investigation
- [x] This report (Sections 0–10)

#### Project Spec
- [ ] Draft open questions / unknowns
- [ ] Create project spec

#### Development
- [ ] Create new branch
- [ ] Begin implementation

#### Testing & Validation
- [ ] Test and validate implementation locally

#### Deploy & PR
- [ ] Push to GitHub
- [ ] Deploy to sandbox + verify there
- [ ] Open PR
- [ ] Address feedback / wait for approval
- [ ] Merge to main
- [ ] Deploy to test

#### Ticket Closeout
- [ ] Update ClickUp: merged to test
- [ ] Set ticket to Ready for QA
- [ ] (If bug) Document root cause / why it slipped through

---

## 12. Definition of done (investigation gate)
Don't move past investigation until each is answered:
- [ ] **Class derived from instances, re-confirmed against root cause — and "reframed?" answered with a justification either way (Section 1)**
- [ ] Problem in one plain sentence
- [ ] Named blocked instance
- [ ] Date it bites next
- [ ] Wedge + why it's reusable within the confirmed class
- [ ] Acceptance criteria + non-goals locked before the solution was proposed
- [ ] Alternatives recorded with rejection reasons
- [ ] 30-second happy-path story
- [ ] Metric that proves it works + how fast it arrives
- [ ] Verdict + disposition stated
- [ ] Open variables each have an owner
- [ ] Tracked action with a falsifiable done-when

## new-branch-get-started.md

# Start a new branch

Do this when you pick up a ticket.

**Map of all workflows:** [workflow-index.md](./workflow-index.md)

**Ticket memory:** Create or open the changelog in `dustin-thomason` before deep work — see [ticket-changelog-workflow.md](./ticket-changelog-workflow.md).

## 1. Go to the right repo

`atlas-front-end`, `callisto-back-end`, `europa-back-end`, or `triton-back-end` — whichever owns the work.

## 2. Update main and create the branch

Replace `PRDV-15263` with your ticket number. **The branch name is only the ticket number.**

```bash
git checkout main
git pull origin main
git checkout -b PRDV-15263
```

If that branch already exists on your machine:

```bash
git checkout PRDV-15263
```

## 3. Confirm you're on it

```bash
git branch --show-current
```

Should print `PRDV-15263` (your ticket).

## 4. Create the ticket changelog (first pass)

In **`dustin-thomason`** (this personal repo), not the app repo:

```powershell
cd C:\Users\dustin.thomason\dustin-thomason
.\scripts\new-ticket-changelog.ps1 -Ticket PRDV-15263 -System atlas -Title "Your one-line title"
```

(`<system>` = `atlas`, `callisto`, `europa`, `triton`, or `other` — use `-Repo` when `other`.)

Optional: `-RequirementsFile .\paste-from-clickup.txt` to fill **Requirements (verbatim)** from a file.

Then paste or verify **Requirements (verbatim)** from ClickUp — do not paraphrase the first time.

Agents: [ticket-changelog.mdc](../rules/ticket-changelog.mdc). Playbook: [ticket-changelog-workflow.md](./ticket-changelog-workflow.md).

## 5. Work, then commit

When you have changes ready:

```bash
git status
git add <files you changed>
git commit -m "PRDV-15263: Short description of what you did"
git push -u origin PRDV-15263
```

Commit message format: **`PRDV-12345: What you changed`** (imperative, short).

## 6. Open the PR

Use your repo’s PR template. Title: **`PRDV-15263: Same short description`**. Pull description bullets from the ticket changelog ([ticket-changelog-workflow.md](./ticket-changelog-workflow.md)).

---

That’s the starting point. For PR body text, screenshots, and commit hash in the description, use [pull-request-workflow.md](./pull-request-workflow.md) when you’re ready to open the PR—not before.

## pull-request-workflow.md

# Pull request workflow (reference)

Personal playbook for opening branches, commits, and PRs with consistent ticketing and evidence. Use this in PlanetDepos repos (and similar) where tickets follow the `PRDV-*` pattern.

**Not sure which doc to use?** [workflow-index.md](./workflow-index.md)

## Where this fits (doc vs Cursor rule)

| Approach | What it is | When to use |
| -------- | ---------- | ----------- |
| **This file** (`.cursor/docs/pull-request-workflow.md`) | Reference; copy/paste templates | Bookmark it; `@`-mention it in Cursor when you want this followed; paste into PRs or channels |
| **Cursor Rules** (`.cursor/rules/*.mdc`) | Always-on or path-scoped AI hints | Use for repo-specific conventions (e.g. “never commit `.env`”) inside a **code** project—not required for this personal folder |

**Starting a branch?** Use [new-branch-get-started.md](./new-branch-get-started.md) first (includes creating the ticket changelog). Use **this file** when you open the PR.

**Ticket changelog (source of truth):** [docs/ticket-changelog-workflow.md](./ticket-changelog-workflow.md) and `docs/<system>/PRDV-XXXXX-changelog.md` — summarize **Requirements**, **Current state**, and the latest **Session log** entry into the PR Description; do not paste the whole changelog.

---

## Branch and PR framing

- Create work on a **new branch** and push a **PR** (do not merge straight to `main` without review unless policy says otherwise).
- **Branch name:** `<TICKET_NUMBER>` (example: `PRDV-15263`).
- **Session rule:** Only create the branch **once per session**. If the branch for this ticket already exists locally from earlier in the same session, reuse it (`git checkout <TICKET_NUMBER>`) instead of creating again.

---

## Commit message format

```
<TICKET_NUMBER>: <Short imperative description>

<Optional longer body explaining what and why>
```

Examples:

- `PRDV-15263: Turn off Swagger for Callisto outside local`
- Body: bullet points or paragraphs for reviewers—what changed, why, any risks or follow-ups.

---

## PR template

The shared template (when present in the target repo) lives at:

`.github/pull_request_template.md`

Fill it out consistently:

| Field | Guidance |
| ----- | -------- |
| **Title** | `<TICKET_NUMBER>: <Short description>` |
| **Clickup** | Full ClickUp URL for the task |
| **Description** | What changed and why (bullets welcome). Include a **fenced code block with the tip commit hash** (see **Commit hash** below). |
| **Test Evidence** | See **Testing & verification** below—prefer screenshots; call out automated tests only when they matter |
| **Checklist** | All boxes checked before requesting review |

### Commit hash

After you push, capture the revision reviewers should look at (usually **latest commit on the PR branch**). The same habit applies when you land work on **`main`** via [git-commit-workflow.mdc](../rules/git-commit-workflow.mdc): agents and tooling should leave you a **copy-pasteable** hash, not only a narrative “pushed successfully.”

**PowerShell (preferred on Windows):** copy to the clipboard **and** echo to the terminal so you can paste again from chat output if needed:

```powershell
git rev-parse HEAD | Set-Clipboard
git rev-parse HEAD
```

**Bash / sh:**

```bash
git rev-parse HEAD
```

**Cursor agents (after `git push`):** run **`git rev-parse HEAD`**, then reply with **one fenced markdown block containing only the forty-character hash** (no branch name, no `commit` prefix)—same shape as the PR body example below.

In the PR body (often under **Description** or its own short heading), include the hash in a **markdown fenced code block** so it stays easy to copy:

````markdown
### Commit

```
abc123def4567890abcd0123456789abcdef01234567
```
````

Use the same pattern in **Slack / Teams** PR announcements when you paste the hash for quick reference.

---

## Steps (happy path)

1. **Changelog** — In `dustin-thomason`, ensure `docs/<system>/PRDV-XXXXX-changelog.md` has a fresh **Session log** entry for this push (agents do this automatically per [git-commit-workflow.mdc](../rules/git-commit-workflow.mdc)).
2. **`git status` / `git diff`** — Confirm only intended files are staged or modified.
3. **`git log`** — Match recent commit message style in that repo.
4. **`git checkout -b <TICKET_NUMBER>`** — Skip if the branch already exists **in this session**; then `git checkout <TICKET_NUMBER>`.
5. **`git add <only relevant files>`** — Do **not** add unrelated changes.
6. **`git commit`** — Ticket-prefixed subject line; optional body.
7. **`git push -u origin <TICKET_NUMBER>`**
8. **Commit hash** — **`git rev-parse HEAD | Set-Clipboard`** (pwsh) or **`git rev-parse HEAD`**; paste the hash into the PR body (see **Commit hash** above).
9. **`gh pr create`** — Use the repo PR template; **`--base main`** unless the team uses a different default branch. Include the **commit hash** in a fenced code block in the PR body (see **Commit hash** above).

### CLI example (`gh`)

Adapt flags to whatever `gh pr create` prompts your repo for (template bodies often work best pasted from this doc):

```bash
gh pr create --base main --title "PRDV-15263: Short description" --body-file pr-body.md
```

---

## Do not commit

- `.env` files or environment files with secrets  
- Secrets, tokens, private keys  
- Unrelated **`package-lock.json`** / lockfile churn (unless this PR *is* the dependency change)

---

## PR description reference example

Use this structure in the GitHub PR body (adjust headings if the template differs):

### [Clickup - PRDV-15262 - [BE] Turn off Swagger for Triton in higher environments](https://app.clickup.com/t/43227262/PRDV-15262)

### Description

- Gate Swagger setup behind `ENV_NAME === 'local'` in `configure-swagger.ts` so API docs are only exposed during local development.
- Mirrors the Callisto implementation (PRDV-15263): env check lives solely in the swagger bootstrap module, not `main.ts`.
- Swagger UI (`/triton/swagger`) and JSON endpoint (`/triton/swagger-json`) are now only registered when `ENV_NAME` is `local`. All other environments (`dev`, `tst`, `sb`, `prod`, `undefined`) return nothing.

### Commit

```
a1b2c3d4e5f678901234567890abcd1234567890
```

### Testing and Verification

https://atlas-sb.planetdepos.com/triton/swagger  
https://atlas-dev.planetdepos.com/triton/swagger

<img width="1133" height="493" alt="image" src="https://github.com/user-attachments/assets/a1f590c7-8b19-48be-9103-f67ce9551a27" />

### Checklist

- [x] Description provided  
- [x] Clickup link  
- [x] Evidence provided  

---

## Testing & verification (expectations)

- **Default expectation:** You will **build/run** the change and capture **screenshots** as primary evidence. That is the normal bar for “Testing and Verification.”
- **Automated tests:** Only spell out commands/output when specific tests are relevant to the change; otherwise you usually **do not** need long test logs.
- **Section headers:** Keep **### Testing and Verification** (or whatever the template uses) **even when the body is minimal**—for example a short note plus screenshots, or a sentence like “Verified locally; see screenshots below.”
- **Agents / drafts:** If a PR is drafted before you have run the app, leave the section present with a placeholder you replace after verification (do not skip the heading).

---

## Channel comment (Slack / Teams / etc.)

Paste and fill in the blanks:

````
PR for **PRDV-15263 - [BE] Turn off Swagger for Callisto in higher environments**
https://app.clickup.com/t/43227262/PRDV-15263
https://github.com/planetdepos/callisto-back-end/pull/312
```
a1b2c3d4e5f678901234567890abcd1234567890
```
````

Swap ticket title, ClickUp URL, GitHub PR URL, and commit hash per task. The inner triple-backtick block is the **commit hash code block** (easy to copy in Slack/Teams).

## README.md

# Cursor docs (playbooks)

**Unsure what to `@`?** → [workflow-index.md](./workflow-index.md) (or type `@workflow-index`).

| Task | `@` this file |
| ---- | ------------- |
| New agent on a ticket (optional) | [session-start.md](./session-start.md) |
| New branch / ticket | [new-branch-get-started.md](./new-branch-get-started.md) |
| Open PR | [pull-request-workflow.md](./pull-request-workflow.md) |
| Wiring audit | run `scripts/validate-workflows.ps1` |

Ticket changelogs live in **`docs/<system>/PRDV-XXXXX-changelog.md`**; personal projects use **`docs/<project>/*-changelog*`**. Not under `.cursor/docs/`.

**Personal rules load automatically** when `dustin-thomason` is in the workspace — including while you edit Callisto/Atlas. Agents **resolve and read** the canonical changelog at **task start** for substantive work ([ticket-changelog.mdc](../rules/ticket-changelog.mdc)). Say *“write a spec”* or *“commit”*; do **not** copy rules into app repos. Router: `personal-methodology.mdc`.

**`@` the changelog** on a new agent thread is **optional** but helpful when several tickets or repos are open.

**Multi-root:** [workflow-index.md](./workflow-index.md#multi-root-workspace-callisto--dustin-thomason)

## session-start.md

# Session start (optional)

Rules in `.cursor/rules/` (and generated **`AGENTS.md`**) already load automatically. Agents **must** resolve and read the canonical changelog **once at the start of each new substantive task** — see [ticket-changelog.mdc](../rules/ticket-changelog.mdc) (**Task start — changelog alignment**). You do **not** have to `@` the file for that to happen.

Copy-paste below only when you want to **point** the agent at a specific ticket or scaffold a missing log.

**Existing changelog:**

```text
Working on PRDV-XXXXX. Ticket log: @docs/atlas/PRDV-XXXXX-changelog
(read Plans + Attempt history before proposing a new approach)
```

Replace `atlas` and the filename for your system/ticket.

**No changelog yet:**

```text
Working on PRDV-XXXXX (atlas). Scaffold changelog and capture requirements verbatim.
```

**Personal project** (Countdowns, WorkLists, …):

```text
Working on Countdowns. Project log: @docs/countdowns/countdowns-app-changelog.mdc
```

## ticket-changelog-workflow.md

# Ticket changelog workflow

Personal, ticket-scoped memory that travels with you across repos, sessions, and agents. One file per ticket keeps context out of chat history so you do not re-explain requirements every time you commit or open a PR.

**Authoritative location:** `docs/` in this repo (`dustin-thomason`) only. Cursor references live under `.cursor/docs/` and `.cursor/rules/` but point here.

### Repo boundaries (important)

| Repo | Role for this workflow |
| ---- | ---------------------- |
| **dustin-thomason** | **Home** for changelogs, **Plans** index, session logs, rules, and scripts. **Commit and push here** for ticket memory. |
| **larry-adams** | **Read-only** when a coworker spec or plan already lives there. **Link to it** in the **Plans** table — do **not** create or push changelog/workflow files into `larry-adams`. |
| **Atlas / Callisto / etc.** | Application code and app-repo PRs. Ticket changelog stays in **dustin-thomason**, not in the app repo. |

Nothing in this workflow is “uploaded” to Larry Adams. You only **reference** his specs when they are the source of requirements or an agreed plan.

---

## When to use this

| Moment | Doc to follow | Changelog action |
| ------ | ------------- | ---------------- |
| Pick up a ticket, create branch | [new-branch-get-started.md](../.cursor/docs/new-branch-get-started.md) | **Create** changelog (first pass — see below) |
| Work in Cursor / another agent | — | **Append** session notes as you go (optional but cheap insurance) |
| Commit or push (any PlanetDepos repo) | [git-commit-workflow.mdc](../.cursor/rules/git-commit-workflow.mdc) | **Update** changelog before `git commit` (required for agents) |
| Open PR | [pull-request-workflow.md](../.cursor/docs/pull-request-workflow.md) | **Mine** changelog for Description / learnings |

---

## File layout

```
docs/
  ticket-changelog-workflow.md          ← this file
  _templates/
    TICKET-changelog.template.md       ← copy when starting a ticket
  <system>/                            ← atlas | callisto | europa | triton | other
    PRDV-12345-changelog.md
```

- **`<system>`** — short name for where the code lives (`atlas`, `callisto`, `europa`, `triton`, or `other` for cross-cutting / personal-only work).
- **Filename** — `PRDV-12345-changelog.md` (ticket number + `-changelog`).

Example: [atlas/PRDV-12264-changelog.md](./atlas/PRDV-12264-changelog.md).

---

## First pass (branch / new ticket)

Do this **once** when you start the ticket (step 4 in [new-branch-get-started.md](../.cursor/docs/new-branch-get-started.md)), or the **first time** an agent touches commit workflow for that ticket.

### Scaffold script (preferred)

From repo root:

```powershell
.\scripts\new-ticket-changelog.ps1 -Ticket PRDV-12345 -System atlas -Title "One-line title"
```

| Parameter | Purpose |
| --------- | ------- |
| `-Ticket` | `PRDV-12345` (required) |
| `-System` | `atlas` \| `callisto` \| `europa` \| `triton` \| `other` (required) |
| `-Title` | H1 subtitle (optional) |
| `-Repo` | Overrides default repo for the system (required when `-System other`) |
| `-RequirementsFile` | Path to text file → pasted into **Requirements (verbatim)** as blockquote lines |
| `-Plan` | Path or label → first row in **Plans** table (repeat `-Plan` for multiple) |
| `-Force` | Overwrite existing changelog (use sparingly) |

Default repos: `atlas` → `atlas-front-end`, `callisto` → `callisto-back-end`, `europa` → `europa-back-end`, `triton` → `triton-back-end`.

Manual fallback: copy `docs/_templates/TICKET-changelog.template.md` → `docs/<system>/PRDV-XXXXX-changelog.md`.

### After scaffold

1. Paste or verify **Requirements (verbatim)** — **do not paraphrase** on first capture.
2. Add **Context** only if the user supplied constraints (env, related PRs, read-only spec paths, etc.).
3. Link any existing **plan** under **Plans** in **this repo** (Cursor plan, in-session approach, or **read-only** pointer to a coworker spec in `larry-adams` if one exists).

Agents always load [.cursor/rules/ticket-changelog.mdc](../.cursor/rules/ticket-changelog.mdc). Treat the changelog as the source of truth for "what we agreed the ticket means."

---

## Plans (reference, not repeat)

Use **Plans** when:

- Cursor or an agent **generates a plan** for the ticket
- A coworker spec already exists in **`larry-adams`** (link only — do not copy or push changelog there), or a Cursor/in-session plan
- You need to know whether an approach was **already tried** without re-reading full **Attempt history**

| Status | Meaning |
| ------ | ------- |
| `active` | Current agreed direction — read before inventing a new plan |
| `implemented` | Done; see session log / commits |
| `superseded` | Replaced by a newer plan — do not retry unless user asks |
| `abandoned` | Rejected or failed — pair with **Attempt history** |

**Agent habit:** Before a new plan → read **Plans** + **Attempt history**. After generating a plan → add a **Plans** row the same day. On commit → set **Plan used** in session log; move plan to **`implemented`** when that approach shipped.

---

## Before every commit (agents)

When [git-commit-workflow.mdc](../.cursor/rules/git-commit-workflow.mdc) runs (user asks to commit/push, or agent lands code):

1. **Resolve ticket** — from branch name (`PRDV-12345`), commit subject, or user message.
2. **Locate changelog** — `docs/<system>/PRDV-12345-changelog.md`. If missing, run **First pass** using whatever ticket text is in the current conversation.
3. **Append a Session log entry** (newest at top under `## Session log`):
   - **Date** (YYYY-MM-DD)
   - **Repos touched** (e.g. `atlas-front-end`)
   - **Summary** — what changed this conversation (files/areas, behavior)
   - **Commits** (optional) — short subject or SHA after commit
4. If the attempt failed or taught something durable, add or extend **Attempt history** / **Key technical learnings**.
5. Refresh **Current state** so the next agent knows what is done vs pending.
6. Then run pre-flight (audit/lint/test) and git steps per git-commit-workflow.

**Gate:** Do not `git commit` without a session log entry that covers work from **this** conversation (unless the user explicitly waives changelog for a trivial doc-only tweak in `dustin-thomason` only).

---

## Session log entry shape

```markdown
### 2026-05-20 — atlas-front-end

- **Summary:** Added `useTextTruncation`; wired ProceedingFileTableDataRow tooltip when ellipsis active.
- **Files:** `useTextTruncation.ts`, `ProceedingFileTableDataRow.vue`, …
- **Plan used:** Plans table → `larry-adams/.../PRDV-12264-truncate-long-filenames.md` (partial)
- **Commits:** `PRDV-12264: Add truncation composable` (pending)
- **Notes:** Parent tables still need `table-layout: fixed` — see Current state.
```

Keep entries short; link to attempt history for long debugging threads.

---

## Pull requests

When drafting a PR ([pull-request-workflow.md](../.cursor/docs/pull-request-workflow.md)):

- **Description** — pull bullets from **Requirements**, **Current state**, and the latest **Session log** entry.
- **What not to do** — do not paste the entire changelog into GitHub; summarize and link to this repo path if reviewers need depth.

---

## Tips for humans

- `@` mention `docs/ticket-changelog-workflow.md` or the ticket file when starting a new agent thread.
- One changelog per ticket, even if you touch multiple repos — use **Session log** to note which repo each slice landed in.
- For long tickets, keep **Attempt history** so you do not retry dead ends across sessions.
- Link **Plans** when a Cursor plan or external spec exists — future agents check there before re-proposing the same approach.

## wiki-spec-authoring.md

# Wiki spec authoring (Callisto / Atlas)

Canonical conventions for PRDV epic/story specs and dev notes in the team **Obsidian wiki** (`systems/` tree). Technical spec sections 1–8 live in [spec-writing](../.cursor/rules/spec-writing.mdc); this doc covers naming, frontmatter, vault wiring, and dev notes.

Guided workflow: [write-spec](../.cursor/skills/write-spec/SKILL.md) skill. Ticket memory stays in `docs/<system>/PRDV-XXXXX-changelog.md`.

---

## File naming and folder conventions

### File naming

Spec filenames **must be prefixed with their PRDV ticket number**, followed by a dash and a short kebab-case description. All parts lowercase kebab-case — no spaces, camelCase, or underscores:

```
{PRDV-#####}-{short-kebab-description}.md
```

Examples:

- `PRDV-14699-display-client-deliverables.md`
- `PRDV-15738-story-2-set-track-and-collection-on-drag-and-drop-upload.md`

Apply the prefix at the file level; folder names do not need the ticket prefix.

### Folder structure

Each epic gets its own folder, named in kebab-case after the epic. Story specs for that epic live directly inside:

```
systems/
  {platform}/
    {feature-folder}/
      epics/
        {epic-kebab-name}/
          {PRDV-#####}-{story-description}.md
          {PRDV-#####}-{story-description}.md
```

Story files are never placed at the top level alongside epic folders.

---

## Spec frontmatter (required on every spec)

Every spec — epic or story — opens with YAML frontmatter:

```yaml
---
ticket: PRDV-#####
tags: [system-name, feature-area]
author: Firstname Lastname
created: YYYY-MM-DD
modified: YYYY-MM-DD
modified_by: Firstname Lastname   # omit if file has never been modified
---
```

Rules:

- `tags` — lowercase kebab-case array for Obsidian graph filtering. Always include the platform (`neptune`, `nova`, `saturn`) and at least one feature tag.
- `author` — person who first wrote the spec.
- `created` — date first committed.
- `modified` — updated every edit; must match the actual edit date.
- `modified_by` — who made the most recent change. Omit on brand-new specs; required after first edit.
- When modifying a spec, update `modified` and `modified_by` — do not change `author`.

Dev notes use the same frontmatter. Include platform + feature tags + `dev-note`.

---

## Obsidian vault integration

Specs and dev notes are not done until wired into the graph — not only readable as standalone markdown.

### Checklist — every new or updated spec

1. **Frontmatter `tags`** — platform + at least one feature tag (e.g. `file-navigator`, `media-duration`, `pdf`).
2. **Index entry** — wiki-link line in `systems/README.md` under the correct platform section (create a subsection if needed).
3. **Wiki-links for internal vault paths** — `[[neptune/.../PRDV-#####-name]]` (no `.md` extension) for specs, dev notes, runbooks, patterns, companion tickets. Full URLs for ClickUp and external docs only.
4. **Cross-link companions** — parent epic, prerequisites, dev notes, follow-on tickets link to each other with wiki-links when practical.
5. **Dev note** — `{PRDV-#####}-dev-note.md` when estimation is needed; `dev-note` tag; spec ↔ dev note wiki-links; index in `systems/README.md`.

Do **not** add Obsidian plugins, change `.obsidian/` config, or create folder READMEs unless the team explicitly requests them.

### Tag examples

```yaml
# Story spec
tags: [neptune, media-duration, files, file-navigator]

# Dev note
tags: [neptune, media-duration, files, file-navigator, dev-note]
```

### Wiki-link examples

```markdown
**ClickUp:** [PRDV-9756](https://app.clickup.com/t/43227262/PRDV-9756)
**Dev note:** [[neptune/media-duration/PRDV-9756-dev-note]]
**Companion:** [[neptune/pdf-page-count/PRDV-9933-view-page-count-of-pdf-files]]
See [[runbooks/operations-critical-file-list]] for supported file types.
```

### Index entry example (`systems/README.md`)

```markdown
#### File length metadata (Atlas File Navigator)

- [[neptune/pdf-page-count/PRDV-9933-view-page-count-of-pdf-files]] — PDF page count
- [[neptune/media-duration/PRDV-9756-view-duration-of-media-files]] — Media duration
- [[neptune/media-duration/PRDV-9756-dev-note]] — Dev note (estimation)
```

---

## Dev note (estimation artifact)

Companion doc named `{PRDV-#####}-dev-note.md`. High-level only — enough for refinement, not a duplicate of the full spec.

Link to the full spec with a wiki-link. Add the dev note to `systems/README.md` when used for estimation.

### What we're building

One or two sentences. What the story delivers and where complexity lives.

### Dependencies

Epics or stories that must merge first.

### Backend

- **New endpoints** — method + route
- **New tables** — table name + one-line purpose
- **Modified tables** — table name + columns added/changed
- **New migrations** — count + DDL vs seed
- **New DTOs / projections** — request/response shape names
- **Registries / wiring** — anything that needs registration

### Frontend

- **New API call** — method + route
- **New components / composables** — name + one-line purpose
- **Modified components** — name + what changes
- **New specs** — count + scope

### Complexity flags

Short bullets on the riskiest or most uncertain pieces.

### Estimate

**Small / Medium / Large (X–Y points).** One sentence justifying it.

---

## Author checklist (before marking a spec complete)

- [ ] Frontmatter: `ticket`, `tags`, `author`, `created`, `modified` (+ `modified_by` if edited)
- [ ] All applicable [spec-writing](../.cursor/rules/spec-writing.mdc) sections filled or N/A with reason
- [ ] Problem → Requirement → Solution narrative (per [problem-requirement-solution](../.cursor/rules/problem-requirement-solution.mdc))
- [ ] Wiki-links to companion tickets, dev note, and runbooks (not relative paths)
- [ ] Entry added to `systems/README.md`
- [ ] Dev note created and indexed when the story needs estimation
- [ ] Changelog **Plans** row updated in `docs/<system>/PRDV-XXXXX-changelog.md` when ticket is active

## workflow-index.md

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
| **Ticket changelog** (data for one PRDV) | **Partially** — agents resolve + read at **task start** per `ticket-changelog` | **Optional** on new threads — `@` still helps when multiple tickets/repos are open |
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
| **Rules** | `.cursor/rules/*.mdc` (generated from `rules/*.md`) | **Automatic** when `dustin-thomason` is in workspace (`alwaysApply: true`) |
| **Router** | `personal-methodology.mdc` | **Automatic** — maps “write spec” / “commit” / “open PR” to the right rule or playbook |
| **Playbooks** | `.cursor/docs/*.md` | **Automatic** when you name the task (router); not via `@` |
| **Artifacts** | `docs/**/PRDV-*-changelog.md`, `docs/<project>/*-changelog*` | Agents **read at task start** when substantive work begins; **`@`** optional pointer on new threads |

**Authoritative long content** lives in `docs/`. `.cursor/docs/` holds short, task-oriented playbooks that link into `docs/`. `.github/*.md` files are **stubs for GitHub browsing only** — do not `@` them.

---

## Generated outputs (how each system loads these rules)

`rules/*.md` (tool-neutral) is the **source of truth**. `agents/scripts/sync-rules.ps1` generates every tool-specific format from it, so no system keeps a duplicate copy:

| Output | Consumer | Committed? | Shape |
| ------ | -------- | ---------- | ----- |
| `.cursor/rules/*.mdc` | Cursor | **Yes** — machine-neutral | description + globs + alwaysApply |
| `.claude/rules/*.md` | Claude Code | **Yes** — machine-neutral | full body (always) or `paths:`-scoped (on-demand) |
| `AGENTS.md` | Codex (any AGENTS.md reader) | **Yes** — machine-neutral | concatenated bodies |

All three are committed, so `git pull` distributes rule changes to every machine. Claude Code loads `.claude/rules/` in-repo automatically, and in **other** project dirs via a one-time junction `~/.claude/rules/dustin-thomason` → this repo's `.claude/rules`. Each rule's `scope`/`globs`/`codex` frontmatter (in `rules/`) drives how it lands in each output. **Never hand-edit a generated file** — edit `rules/` and run `sync-rules.ps1` (the pre-commit hook does this automatically). See `README.md` for one-time machine setup.

---

## What to `@` by task

| I want to… | What you say or do | `@` needed? |
| ---------- | ------------------ | ----------- |
| **Pick a workflow** (unsure) | `@workflow-index` | Optional |
| **Write epic/story spec** (any repo) | “Write the story spec …” | **No** — `spec-writing` + `wiki-spec-authoring`; `@write-spec` for guided workflow |
| **Start ticket / branch** | “Start branch for PRDV-…” | **No** — router reads `new-branch-get-started` |
| **Commit or push** | “Commit” / “push using git workflow” | **No** — `git-commit-workflow` + `ticket-changelog` |
| **Open a PR** | “Open PR for PRDV-…” | **No** — router reads `pull-request-workflow` |
| **Implement code** | (normal implementation chat) | **No** — agent resolves changelog at **task start**; then `problem-requirement-solution` + `build-implementation-guardrails` + app repo rules |
| **Fix bug / regression** | (normal fix chat) | **No** — same **task-start** changelog alignment when a ticket or project log exists |
| **Debug front-end** layout/CSS/interaction at runtime | (drive/observe the live browser) | **No** — `browser-loop-guardrails` + [browser-loop-setup](../.cursor/docs/browser-loop-setup.md) |
| **Ticket context (new thread)** | `@docs/atlas/PRDV-XXXXX-changelog` | **Optional** — explicit pointer; agent should still resolve changelog from branch/ticket id |
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
| `ticket-changelog` | task-start alignment + session log before commit |
| `build-implementation-guardrails` | §5 shipping checklist: tests/regression, changelog (PRDV + personal projects), Swagger when applicable |
| `context-fanout` | read-only exploration subagents for multi-area context compaction |
| `browser-loop-guardrails` | boundary rules for runtime browser observation + CSS/layout/interaction debugging |
| `problem-requirement-solution` | frame implementation/plans/specs as Problem → Requirement → Solution |
| `agent-completion-notification` | end of substantive sessions — `notify-agent-complete.ps1` → Power Automate |

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
| [ticket-changelog-workflow.md](./ticket-changelog-workflow.md) | How changelogs work end-to-end |
| [wiki-spec-authoring.md](./wiki-spec-authoring.md) | PRDV wiki naming, Obsidian wiring, dev notes, author checklist |
| [docs/atlas/local/callisto-local.mdc](./atlas/local/callisto-local.mdc) | Callisto backend local runbook (Docker, migrations, DBeaver) |
| [docs/atlas/local/triton-local.mdc](./atlas/local/triton-local.mdc) | Triton backend local runbook |
| [docs/atlas/local/europa-local.mdc](./atlas/local/europa-local.mdc) | Europa backend local runbook |
| `docs/<system>/PRDV-XXXXX-changelog.md` | **This ticket’s** memory in **dustin-thomason** only — `@` every new agent thread. `larry-adams` = read-only spec links in **Plans**, not a push target |
| [\_templates/TICKET-changelog.template.md](./_templates/TICKET-changelog.template.md) | Rarely — use `scripts/new-ticket-changelog.ps1` instead |
| `docs/WorkLists/` | One-off personal work lists |

**Do not** keep ticket changelogs under `.cursor/docs/` — only `docs/<system>/` to avoid duplicate `@` suggestions.

---

## Scaffold script (terminal, not `@`)

```powershell
# from the dustin-thomason repo root
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
| `write-spec` | Author/update PRDV specs or dev notes (see [wiki-spec-authoring.md](./wiki-spec-authoring.md)) |
| `grill-me` | Stress-test a plan or design |
| `workflow-housekeeping` | Audit rules/playbooks/index after you change workflow files |

## Scripts (`scripts/`)

| Script | Purpose |
| ------ | ------- |
| `new-ticket-changelog.ps1` | Create `docs/<system>/PRDV-XXXXX-changelog.md` |
| `notify-agent-complete.ps1` | Post session completion to Power Automate (`agent-completion-notification` rule) |
| `validate-workflows.ps1` | Wiring audit (incl. generated-output staleness) — run after changing rules/docs |
| `sync-rules.ps1` | **Primary generator** — rebuilds `.cursor/rules/` (Cursor) + `.claude/rules/` (Claude Code) + `AGENTS.md` (Codex) from `rules/*.md`. `-Check` fails on stale output. |
| `sync-agents-md.ps1` | Backwards-compatible shim → `sync-rules.ps1` |

## GitHub (stubs only — never `@`)

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
| Framing implementation | `problem-requirement-solution` — Problem → Requirement → Solution |
| Multi-area exploration | `context-fanout` — read-only subagent fanout |
| Front-end runtime debugging | `browser-loop-guardrails` + `browser-loop-setup` playbook |
| Spec | `spec-writing` + `wiki-spec-authoring`; `@write-spec` for guided flow |
| Agent finished substantive work | `agent-completion-notification` → `notify-agent-complete.ps1` |

If a new workflow type appears (e.g. release, hotfix), add **one row** above, **one** playbook, update `personal-methodology.mdc`, run `validate-workflows.ps1`.
