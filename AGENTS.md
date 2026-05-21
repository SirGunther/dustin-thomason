# AGENTS.md (generated — do not edit)

Source: `.cursor/rules/*.mdc`. Regenerate with `.\scripts\sync-agents-md.ps1`.

## build-implementation-guardrails

# Build guardrails — implementation & tests

Read this sheet **before** substantive feature work (**new endpoints, callers, transactions, integrations, sizeable refactors**) in Atlas / Nest services / Vue apps. Prefer matching the **patterns already documented** in repo-specific **`/.cursor/rules/**`** (architecture, layering, Nest patterns).

---

## 1. Automated tests — default obligation

Treat tests as **part of shipping**, not a follow-on ticket unless the repo standard explicitly waives (`jest-e2e` carve-outs, trivial config-only tweaks, docs-only churn).

**If executable tests do not yet exist for the unit you touch** (**new endpoint, adapter, composable, service, mapper, reducer, Vue surface**, …)—**create them immediately** beside that code using the repo’s **`__specs__` / **`*.spec.*`** layout. Leaving production logic uncovered—when sibling files already carry specs and no repo waiver applies—is unacceptable.

Each relevant **unit suite** tied to shipped behavior must be **comprehensive across the seams you influence**—not just a lone smoke assertion:

- **Happy path** — success returns / side effects asserted.
- **Failure paths** — invalid input, forbidden states, **`Promise.reject`**, mapped domain/application errors surfaced the way callers see them.
- **Edge cases** — boundaries that plausibly break behavior (**empty**/null payloads, extremes, concurrency-safe assumptions documented with at least minimal coverage where risk exists).
- **Graceful degradation** — not only “it throws”: assert **controlled handling** (**HTTP/status shape**, **`onError`/toast flows**, deterministic fallbacks)—no silent breakage, no leaky raw stack traces promised to callers.

When you introduce or materially change behavior, **add new specs or extend existing ones** so that:

- **Surface coverage** — the **new behavior** stays reflected in assertions across the bullets above—not just a lone green path.
- **Regression / isolation posture** — when shared infrastructure moves (**global filters, middleware, Axios interceptors, query clients, routers, caches, decorators**), extend or add **narrow contract tests** proving **neighbor API routes / callers / widgets** retain **happy**, **failure**, **edge**, and **graceful** guarantees wherever risk migrated—rather than brittle end-to-end guesswork alone.

Repos using **`__specs__/*.spec.{ts,vue,...}`**, **`vitest`**, **`jest`**—follow **existing layout and helpers** (**`createApplyMock`**, **`createComposableMock`**, etc.) rather than inventing parallel harnesses.

If you truly cannot reach the target without heavy harness debt, spell out **blocked cases** plainly and propose the smallest scaffolding task—still avoid shipping **zero** tests for risky paths.

---

## 2. Architecture & framework fit

Implement **inside established folder patterns** (controller actions, services, repos, adapters, Vue composables, Pinia/query modules—whatever the codebase already favors). Prefer **thin glue at edges** (**HTTP**, **CLI**, UI) **+** cohesive domain/core units.

Defer to **architecture / DDD / hexagonal docs** pinned in **`/.cursor/rules/**`** for the touched repository when they conflict with guesses here.

---

## 3. SOLID class seams, functional internals

Bias toward **SOLID** composition at boundaries (**single responsibility coordinators**, invert dependencies via ports/interfaces as the repo dictates).

Prefer **implementations that stay easy to substitute**: **deterministic helpers**, **`async` pipelines with early returns**, **pure transforms** layered behind **narrow facades/classes** hosting DI (`@Injectable()` gateways, façade services). Avoid **kitchen-sink** classes accumulating unrelated branches—split or extract before growth.

Design so tests can **`vi.mock`** / **`jest.mock`** collaborators without booting the universe.

---

## 4. Data access — avoid brittle SQL

Default to **typed repository / TypeORM constructs / query-builder patterns** sanctioned in the codebase.

Do **not** sprinkle **vendor-locked Postgres** (or handwritten SQL blobs) purely for ergonomics unless the existing module already embraces that—and even then encapsulate aggressively and test defensively.

If only raw SQL qualifies, cite **why** narrowly, constrain surface area (**single repository method** / dedicated reader), guard against **`NULL`/column drift**, document parameters, prefer **migration-backed views** instead of duplicated logic.

---

## 5. Shipping checklist (address what applies)

Before calling work **done**, walk every item below. If an item does not apply, state **N/A** and a one-line reason (e.g. "N/A — UI-only, no HTTP contract") in your wrap-up or changelog entry—**do not skip silently**.

### Tests & regression (§1)

- **New or changed behavior** has specs per §1 (happy, failure, edge, graceful where risk exists).
- **Shared infrastructure** you touched (filters, interceptors, routers, global clients) has neighbor/regression coverage when behavior could leak sideways.
- Run the repo’s test command for affected suites when **`package.json`** defines one; note what you ran in the changelog session entry.
- If tests are blocked, document **risk + follow-ups**—do not treat "no tests" as done without that callout.

### Changelog / session memory

Keep cross-session memory current in **`dustin-thomason`** (not in app repos, not in **`larry-adams`**).

| Work context | Where to update | When |
| ------------ | --------------- | ---- |
| **`PRDV-*` ticket** (Atlas, Callisto, Europa, Triton, …) | `docs/<system>/PRDV-XXXXX-changelog.md` | **Before every commit** on PlanetDepos app repos — session log + **Current state**; see [ticket-changelog.mdc](./ticket-changelog.mdc) |
| **Personal / side project** (Countdowns, WorkLists, …) | `docs/<project>/` changelog for that project (e.g. `docs/countdowns/countdowns-app-changelog.mdc`) | **End of each implementation session** or before you commit/push project code—whichever comes first |
| **No ticket, trivial dustin-thomason-only doc tweak** | — | Changelog optional |

**Personal-project session entry** (match existing file shape): newest-first **Session log** with summary, files/areas, user-visible impact, tests run; refresh **Current state** when scope shifts. If no changelog file exists yet for that project, create one under `docs/<project>/` using the same sections (Purpose, Scope, Session log, Current state).

### Swagger / OpenAPI / API contract docs

**Check every shipping pass**—most sessions are **N/A**, but the check is mandatory:

- If the repo exposes **Swagger**, **OpenAPI**, route decorators, or **swagger helpers** (common on Callisto/Europa/Triton backends):
  - **New or changed HTTP surface** (path, method, body, status, auth) → update helpers, decorators, DTOs, and generated/spec artifacts per **that repo’s** `.cursor/rules/` and module conventions.
  - **No contract change** → record **N/A — no API surface change** (or equivalent) in changelog or wrap-up.
- UI-only or non-HTTP work → **N/A — no API docs in this repo**.
- When unsure whether Swagger applies, search the touched module for `swagger`, `@Api`, or `*swagger*` helpers before marking N/A.

### Tooling gates

- Respect **`npm run lint`**, **`audit`** thresholds, and serial **`vitest`**/**`jest`** runs when the repo has them ([git-commit-workflow.mdc](./git-commit-workflow.mdc)).

---

## 6. Local app-server checks

Do **not** run a local test whose only purpose is to confirm the app server is already listening. Only start or probe a local server when it directly verifies requested behavior (**browser automation**, endpoint checks, or a manual repro path), and state the behavioral signal it provides.

## context-fanout

# Context fanout — parallel exploration subagents

When a task requires understanding **multiple independent areas** of code before you can act, prefer spawning **read-only** exploration subagents in parallel over serial investigation in the parent context. The goal is **context compaction**: each subagent goes deep, distills what matters, and returns a tight result so the parent stays lean.

---

## When to fan out

Fan out when **all** of these hold:

1. The task requires reading across **two or more independent modules, repos, or layers** (e.g. backend entity + frontend composable + migration history).
2. Serial investigation in the parent would consume **significant context** (many files, deep folder trees) that the parent does not need to carry forward verbatim.
3. The areas are **independently explorable** — no subagent's search depends on another's result.

### Typical triggers

| Task shape | Fan-out example |
| ---------- | --------------- |
| **Ticket onboarding / new branch** | Changelog + target repo module scan + coworker specs in `larry-adams` |
| **Spec writing** | Backend entity/service structure + frontend component conventions + migration history |
| **Implementation planning** | Existing patterns in touched module + test conventions + related modules for cross-cutting impact |
| **Unfamiliar code investigation** | Multiple modules or repos needed to answer a cross-cutting question |

---

## When NOT to fan out

- **Single-file or single-module reads** — just read directly.
- **Already-familiar code** — context from earlier in the conversation suffices.
- **Trivial tasks** — overhead of subagent dispatch exceeds benefit.
- **Dependent investigation** — when the second search depends on the first result, run them serially (subagent or not).
- **Implementation / code writing** — this rule covers **exploration only**. Do not spawn subagents to write code or modify files under this rule.

---

## Subagent constraints

- **Type:** `explore` (read-only). Never `generalPurpose` or `best-of-n-runner` under this rule.
- **Return artifacts, not prose:** file paths, type shapes, function signatures, pattern snippets, migration names. Avoid vague summaries — the parent needs concrete references to act on.
- **Scope each subagent narrowly:** one module, one layer, one question per subagent. Broad "explore everything" prompts defeat the purpose.
- **Run in background** when possible so the parent can continue reasoning or dispatch additional subagents.

---

## Relationship to other rules

This rule is **additive**. It does not override or replace:

- **`build-implementation-guardrails`** — still governs how you implement and test.
- **`spec-writing`** — still governs spec sections; fanout feeds context *into* spec drafting.
- **`ticket-changelog`** — still governs session logs and plans; fanout feeds context *into* ticket onboarding.
- **Existing Task tool judgment** — you may still spawn subagents for other reasons (implementation, best-of-n, etc.) outside this rule's scope. This rule only adds guidance for the **read-only exploration** case.

## git-commit-workflow

# Git commit & push (dustin-thomason)

Baseline for landing changes on **`main`** when that matches the workflow the user invokes. Team or ticket tooling can override when it conflicts.

**Browsing on GitHub?** [.github/git-commit-workflow.md](../../.github/git-commit-workflow.md) jumps here—we keep authoritative text **in `.cursor/rules/`** so Cursor keeps loading it automatically (**`alwaysApply`**); we do **not** relocate solely under **`.github/`**.

**Ticket changelog (before commit):** [ticket-changelog.mdc](./ticket-changelog.mdc) and [docs/ticket-changelog-workflow.md](../../docs/ticket-changelog-workflow.md). Scaffold: `scripts/new-ticket-changelog.ps1`.

Repositories such as **`atlas-front-end`**, **`callisto-back-end`**, **`europa-back-end`**, and **`triton-back-end`** expose **`npm run lint`**—often with **`eslint --fix`** wired into that script (**backend** repos and **Triton**). **`atlas-front-end`** uses **`npm run lint`** (no fix; **`eslint . --max-warnings 0`**) plus a separate **`npm run lint:fix`** when autofix helps; **`npm run lint`** must succeed before you commit here. Those app repos also ship **`test`** scripts—run them **serially** (**`--runInBand`** for Jest, **`vitest run --maxWorkers 1`** for Atlas) so local runs do not spawn enough parallel workers to overwhelm the machine.

If the repo root has **no** **`package.json`** (many **`dustin-thomason`** changes are doc-only)—**skip §Pre-flight** entirely.

---

## For Cursor agents (read this first)

When the user tells you to **push**, **commit**, **follow the git workflow**, **use `.cursor/rules/git-commit-workflow.mdc`**, or similar, do **not** stop at proposing commands unless they **explicitly** ask for command text only.

### Pre-flight (**npm**)—before **`git commit`**

From **the repo root whose changes you intend to ship** (`package.json` at that cwd):

**A.** Run **`npm audit --audit-level=high`**.

- If it exits non‑zero (**HIGH** or **CRITICAL** vulns)—**STOP immediately**. Do **not** run **`git commit`** or **`git push`**. Give a short recap of **`npm audit`** for the developer to triage (**`npm audit fix`**, policy exception, downgrade, fork). Only proceed after they resolve audits or waive them.

**B.** Run **`npm run lint`**.

- If it exits non‑zero—**STOP before commit.** Fix surfaced issues (including rerunning **`npm run lint`** after edits). **`atlas-front-end`**: **`npm run lint:fix`** is available when ESLint autofix clears noise; rerun **`npm run lint`** afterward until it passes.
- Scripts that embed **`eslint --fix`** (**e.g.** Callisto/Europa/Triton backend packages) **may mutate files.** After any fixes land, rerun **`git status`** and fold those changes into the next **`git add`** so the pushed tree matches ESLint reality.

**C.** Run tests when **`package.json`** defines a **`test`** script (skip for doc-only **`dustin-thomason`** commits with no code under test). **Always serialize** so parallel workers do not overload the machine:

- **Jest** (Callisto, Europa, Triton backends): **`npm test -- --runInBand`**
- **Vitest** (**`atlas-front-end`**): non-watch only—**`npx vitest run --maxWorkers 1`** (or **`npm run test:unit:ci -- --maxWorkers 1`**). Do **not** run bare **`npm test`** / **`vitest`** without **`run`**; watch mode blocks agents.

If tests exit non‑zero—**STOP before commit.** Fix or report failures; rerun the same command until green.

Audit first, lint second, tests third—you avoid patching code only to discover **`npm audit`** or a red suite would have blocked shipment anyway.

### Ticket changelog — before **`git commit`**

Follow [ticket-changelog.mdc](./ticket-changelog.mdc) (**Session log** + first-pass rules), then continue here.

### Git sequence

Once **§Pre-flight** is satisfied—or skipped because there is no npm workspace—continue:

**3.** **`git status`**—read staged vs unstaged vs untracked.

**4.** Stage with **`git add -A`** when **everything** listed should ride in **one** commit. If paths must remain out (**secrets**, stray scratch files, unrelated edits), **`git add <paths>`** selectively and—in one terse sentence—what you staged and why.

**5.** **`git commit -m "`** + §Commit-message subject below + **`"`**. If neither staging nor substantive working-tree changes remain, explain that **`main`** (or the current branch) already matches **`origin`** rather than forging an empty commit.

**6.** **`git push`** to **`origin`** (your current branch—usually **`main`**).

**7.** Leave **no temp helper files**. Delete ephemeral commit-message scratch paths.

**8.** **Paste one clean SHA**: after **`git push`**, capture **`HEAD`** and reply with **one fenced markdown block containing only that forty‑character hash** (no branch name, no `commit` prefix) so the reader copies it cleanly from Cursor.

- **PowerShell (preferred on Windows):** **`git rev-parse HEAD | Set-Clipboard`**, then **`git rev-parse HEAD`** so the hash is on the clipboard **and** visible in the terminal/chat output for a second copy.
- **Bash / sh:** **`git rev-parse HEAD`**

PR bodies and channel posts use the same fenced-block shape—see [pull-request-workflow.md](../docs/pull-request-workflow.md) (**Commit hash**).

---

**Commit SHA block example**

> Pushed **`main`** with passing audit / lint / test gates; landing SHA:

```
0123456789abcdef0123456789abcdef01234567
```

(Replace with output from **`git rev-parse HEAD`**. On pwsh, run **`git rev-parse HEAD | Set-Clipboard`** first.)

---

### Commit subject sanity

The **`git`** subject stays **exactly** the short §phrase below—no stray trailers merging into the title. Run **`git log -1 --pretty=%s`**; **`git commit --amend`** once when tooling corrupts **`HEAD`**’s subject line, then push again when history rewrite is allowed (**`--force-with-lease`** sparingly).

### Command-only mode

When the human demands **literally paste four git commands**, deliver **§Human quick reference** verbatim with the filled **`message`**. Omit npm blocks unless asked for full gate steps.

---

## Human quick reference (git only)

```bash
git status
git add -A
git commit -m "message"
git push
```

Swap **`git add -A`** for explicit paths anytime one commit shouldn’t sweep the tree.

---

## Human quick reference (Node repo—before commit)

Typical prelude when **`package.json`** ships **`lint`**:

```bash
npm audit --audit-level=high
npm run lint
# Jest backends (serial):
npm test -- --runInBand
# atlas-front-end (serial, non-watch):
npx vitest run --maxWorkers 1
```

Whenever **`eslint --fix`** rewrote tracked files (`npm run lint` exits **0**, but **`git status`** gains diffs—common on backends), rerun **`git status`**, **`git add`**, rerun **`npm run lint`** once more until clean, **then** run the bash block in **Human quick reference (git only)**.

**atlas-front-end:** run **`npm run lint:fix`** first when ESLint autofix likely helps—**`npm run lint`** must exit **0** before **`git commit`**. Use **`npx vitest run --maxWorkers 1`** for tests—not watch-mode **`npm test`**.

Omit the test lines when the repo has no **`test`** script or the change is doc-only with nothing to exercise.

---

## Commit messages

### Length & focus

Roughly **five to seven words** describing **surface change**—keep implementation chatter out unless the ticket truly is infra.

### Wording starts

**Add**, **fix**, **update**, **remove**, **refactor**, **revert**, etc.—telegram-style headline.

Examples: **`PRDV-14699: Co-locate comparator with proceeding mapper`** (ticket-prefixed repos such as Callisto/Europa/Triton back-end and atlas-front-end), **`Add natural-sort QA text fixtures`**, **`Fix upload validation empty file`**.

### One narrative per commit

Unrelated deltas → split commits or refrain from **`git add -A`** wholesale.

---

## Out of scope (defaults here)

Heavy **rebase/merge choreography**, tagging, signatures, husky internals. This memo covers **straight line**: optional **audit + lint + serial test gates → git status/add/commit/push** when Node repo applies.

## personal-methodology

# Personal methodology (dustin-thomason)

**dustin-thomason** is in the workspace so your standards apply while you work in **any** app repo. Ticket changelogs and **Plans** live **only** in `dustin-thomason/docs/`. **Larry-adams** may be linked read-only when a coworker spec exists there — never push workflow or changelog files to it. The user does **not** need to say "use dustin-thomason rules" or `@` this file. Do **not** ask them to copy these rules into `callisto-back-end`, `atlas-front-end`, etc.

## Intent → what to follow

| User says or means | Apply automatically |
| ------------------ | ------------------- |
| Write / extend / review an **epic** or **story** **spec** | [spec-writing.mdc](./spec-writing.mdc) — all required sections, any repo path |
| **Commit**, **push**, git workflow | [git-commit-workflow.mdc](./git-commit-workflow.mdc) + [ticket-changelog.mdc](./ticket-changelog.mdc) |
| **New ticket**, **new branch**, start PRDV work | Read [new-branch-get-started.md](../docs/new-branch-get-started.md); update changelog in `dustin-thomason/docs/<system>/` |
| **Open PR**, PR description, `gh pr create` | Read [pull-request-workflow.md](../docs/pull-request-workflow.md) |
| **Implement** feature, endpoint, refactor, tests | [build-implementation-guardrails.mdc](./build-implementation-guardrails.mdc) — §5 shipping checklist (tests, changelog, Swagger when applicable) + that repo's `.cursor/rules/` |
| **Explore** unfamiliar code, onboard to ticket, gather multi-area context | [context-fanout.mdc](./context-fanout.mdc) — read-only subagent fanout |

## Ticket memory (`@` changelog when starting a thread)

Changelog **content** lives in `dustin-thomason/docs/<system>/PRDV-XXXXX-changelog.md`.

| User does | You do |
| --------- | ------ |
| `@docs/.../PRDV-XXXXX-changelog` or says "working on PRDV-XXXXX" | **Read** that file first; continue from **Current state** and **Session log** |
| New ticket, no file yet | Run `scripts/new-ticket-changelog.ps1` or template; **Requirements (verbatim)** on first pass |
| **Commit** / **push** | Append **Session log** in that file **before** `git commit` ([ticket-changelog.mdc](./ticket-changelog.mdc)) |

Optional human opener: [.cursor/docs/session-start.md](../docs/session-start.md).

## Skills (not automatic — user invokes)

| Skill | When |
| ----- | ---- |
| `grill-me` | User wants plan/design stress-tested |
| `workflow-housekeeping` | User asks to audit/sync workflow docs after edits |

## Overlap with app repos

- **Spec / build / commit habits** → personal rules above win for *how you work*.
- **Commit subject on `PRDV-*` branches** → still use app repo `PRDV-X:` format when present.
- **Vue / Nest / architecture patterns** → app repo rules still apply alongside personal guardrails.

## spec-writing

# Epic and story specs (Callisto / Atlas)

When the user asks you to **write, extend, or review** an **epic** or **story** spec — usually in app repos or spec folders the team uses — include the sections below. If requirements come from a coworker spec in **`larry-adams`**, treat that repo as **read-only input**; ticket memory and plan index stay in **`dustin-thomason`**. You do **not** need the user to `@` this file or copy it into the app repo.

If a section does not apply, add a one-line **N/A** with a short reason (e.g. "N/A — UI-only story") so reviewers know it was considered.

Reference shape: `epics/set-track-and-collection/story-2-set-track-and-collection-on-drag-and-drop-upload.md`.

## 1. Folder hierarchy

- Tree of **new** paths under `callisto-back-end-neptune/src/` (and `og-atlas-front-end/src/` when relevant).
- Follow module layout from Callisto rules: `application/controllers/actions/…`, `domain/transaction-scripts/{name}-ts/`, `infrastructure/repositories/`, `registries/`, etc.

## 2. New classes (name + path)

- Table or bullet list: **PascalCase class name** → **file path** (kebab-case filename).
- Include actions, services, transaction scripts, repositories, responders, swagger helpers, assemblers, mappers, converters when applicable.

## 3. New entities

- **Entity class name** and **table name** (`@Entity('…')`).
- Columns and relationships at a level that matches existing story specs (snippet or table).
- **Entity ownership** — call out whether the entity is domain-specific (`{module}/domain/entities/`) or shared (`src/shared/shared-entities/entities/`), with the full file path. For Callisto-owned tables, note audit column convention (`created_user_identity` / `modified_user_identity`).

## 4. Modified entities

- **Entity class name** and path.
- **Only new or changed properties** (column name, type, nullability, FK).
- **Entity ownership** — call out whether the entity is domain-specific or shared, with the full file path. This helps reviewers understand cross-domain impact (e.g. modifying a shared entity affects multiple modules).

## 5. New migrations (file names)

- Ordered list of migration **files** as they should appear under `src/typeorm/migrations/` (timestamp prefix + descriptive kebab name), e.g. `{ts}-create__deliverable_collections__table.ts`.
- Distinguish DDL vs seed when both exist.

## 6. New migration classes

- **TypeScript class name** per migration file (TypeORM migration class), aligned with the filename.

## 7. New DTOs

- **Request/response class names** and paths under `application/` (or action colocation).
- Note required vs optional fields when it affects API contract.

## 8. New projections (and domain inputs if relevant)

- **Projection type names** and file paths (`.projection.ts` next to the transaction script or per team convention).
- For new commands/params used by services or TS, call those out explicitly so domain layer stays free of `Dto` in names.

## Cross-cutting

- Link **parent epic**, **feature flags**, and **companion tickets** when the story depends on or establishes shared work.
- Frontend-only stories still benefit from sections 1–2 scoped to `og-atlas-front-end/`; use N/A for 3–8 when no API or schema change.

## Optional callouts (when applicable)

Use **N/A** when none; otherwise a short list is enough.

- **HTTP surface** — method(s), path(s), and whether the contract is new or a breaking change to an existing route.
- **Registries and module wiring** — new entries in `action.registry.ts`, `transaction-script.registry.ts`, `repository.registry.ts`, `*.module.ts` providers/imports/exports.
- **Ports** — new or extended domain ports (`Symbol` tokens + type shape) and which infrastructure class implements them.
- **Domain events / dispatchers / outbox** — new emission points or runners when messaging is part of the story.
- **Domain exceptions** — new thrown types or error codes consumers rely on.
- **Authorization** — new or changed guards, roles, or policy checks.
- **Spec tests** — new `__specs__/*.spec.ts` paths (or explicit “deferred” with reason).

## ticket-changelog

# Ticket changelog (agents)

Cross-session memory for **`PRDV-*`** work. Full playbook: [docs/ticket-changelog-workflow.md](../../docs/ticket-changelog-workflow.md).

**Path:** `dustin-thomason/docs/<system>/PRDV-XXXXX-changelog.md` — **all changelog and Plans data stays in this repo.**  
**Larry-adams:** optional **read-only** link in the **Plans** table when a coworker spec exists there. **Do not** create, edit, or push workflow/changelog files to `larry-adams`.  
**Scaffold (human or agent):** `scripts/new-ticket-changelog.ps1` (see script help).

---

## When this rule applies

| Trigger | Action |
| ------- | ------ |
| User starts a ticket / new branch | Scaffold changelog if missing; **first pass** verbatim requirements |
| User `@` or names `docs/.../PRDV-*-changelog` or branch `PRDV-*` | **Read** existing file or scaffold; treat as active ticket for this thread |
| User asks to **commit** / **push** / git workflow | **Session log** entry **before** `git commit` (then [git-commit-workflow.mdc](./git-commit-workflow.mdc) pre-flight + git) |
| User opens a PR | Summarize from changelog; do not paste the whole file |
| User or agent **generates a plan** | Add/update a row under **Plans** (path, status, one-line approach) |
| New implementation approach | Read **Plans** + **Attempt history** first; avoid repeating **superseded** / **abandoned** plans |

Skip only for trivial **`dustin-thomason`**-only edits with **no** ticket.

---

## First pass (file missing)

1. Run scaffold (preferred):

   ```powershell
   cd C:\Users\dustin.thomason\dustin-thomason
   .\scripts\new-ticket-changelog.ps1 -Ticket PRDV-12345 -System atlas -Title "One-line title" -Repo atlas-front-end
   ```

   Or copy `docs/_templates/TICKET-changelog.template.md` manually.

2. Under **Requirements (verbatim)** — paste ClickUp / user text **verbatim** (blockquote). **Do not paraphrase** the initial capture.

3. Fill **Ticket** metadata and **Context** if the user gave constraints.
4. If a **plan** already exists (Cursor plan, in-session approach, or read-only coworker spec in `larry-adams`), add a **Plans** row in **dustin-thomason** with status **`active`** (link only for `larry-adams`).

---

## Plans (avoid duplicate approaches)

- **Before** proposing a new plan or large refactor, read **Plans** and **Attempt history** on the ticket changelog.
- **When** a plan is created in chat or saved to disk, append a **Plans** table row in **dustin-thomason**: date, path or title, status (`active` first), one-line summary. Coworker specs in `larry-adams` → **link** the path; do not write files there.
- When an approach is **replaced**, set the old plan to **`superseded`** and add the new row — do not delete old rows.
- When work **lands**, set plan to **`implemented`** and point to session log / commits.
- In **Session log**, optional **Plan used:** links which plan row this session followed.

---

## Before every `git commit` (PlanetDepos repos)

1. Resolve ticket from branch name, user message, or commit subject.
2. Ensure `docs/<system>/PRDV-XXXXX-changelog.md` exists (scaffold if not).
3. Append a **Session log** entry (newest first):
   - Date, repo(s), summary of **this conversation**, files/areas, intended commit message.
4. Update **Current state** when scope changes; update **Plans** status if the approach shipped or was abandoned.
5. Proceed with audit → lint → tests → git per [git-commit-workflow.mdc](./git-commit-workflow.mdc).

**Gate:** No `git commit` without a session log entry covering this conversation's code changes.

---

## System → default repo

| `<system>` | Default repo |
| ---------- | ------------ |
| `atlas` | `atlas-front-end` |
| `callisto` | `callisto-back-end` |
| `europa` | `europa-back-end` |
| `triton` | `triton-back-end` |
| `other` | _(set `-Repo` explicitly)_ |

## workflow-housekeeping

# Workflow housekeeping (dustin-thomason)

Triggers when you edit playbooks, rules, scripts, or workflow docs in **this repo**.

## After any workflow change

1. Run **`.\scripts\validate-workflows.ps1`** from repo root; fix reported gaps.
2. Update [docs/workflow-index.md](../../docs/workflow-index.md):
   - **What to @ by task** — add/remove rows
   - **Personal rules**, **Skills**, **Scripts** tables
   - **Playbooks** table — match `.cursor/docs/*.md` (exclude README, session-start)
3. Update [personal-methodology.mdc](./personal-methodology.mdc) intent table if a new top-level task was added.
4. If you added a playbook, link it from [.cursor/docs/README.md](../docs/README.md) when it is a top-level task.
5. Do **not** duplicate ticket changelogs under `.cursor/docs/` — only `docs/<system>/`.

## Do not auto-run across other repos

This rule applies to **dustin-thomason** files only. App repos (Atlas, Callisto, etc.) keep their own `.cursor/rules/`; do not copy personal playbooks there.

For a full audit on demand, user invokes the **workflow-housekeeping** skill.
