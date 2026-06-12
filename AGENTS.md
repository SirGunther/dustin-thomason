# AGENTS.md (generated — do not edit)

Source: `.cursor/rules/*.mdc`. Regenerate with `.\scripts\sync-agents-md.ps1`.

## agent-completion-notification

# Agent completion notification

At the end of **substantive** agent work, invoke `scripts/notify-agent-complete.ps1` in **dustin-thomason** (works from any cwd when you use the script’s full path).

**Skip** for pure Q&A, trivial doc-only housekeeping with no behavior change, or when the session produced no actionable outcome.

From **dustin-thomason** repo root:

    .\scripts\notify-agent-complete.ps1 -Status "Completed" -Message "<5–9 word result summary>"

From an **app repo** in a multi-root workspace (resolve dustin-thomason in the workspace):

    & "<dustin-thomason>\scripts\notify-agent-complete.ps1" -Status "Completed" -Message "<5–9 word result summary>"

Parameters:

- `Status` — always `Completed`
- `Message` — short result summary (about 5–9 words)

Example:

    .\scripts\notify-agent-complete.ps1 -Status "Completed" -Message "Work finished; all tests passed."

## build-implementation-guardrails

# Build guardrails — implementation & tests

Read this sheet **before** substantive feature work (**new endpoints, callers, transactions, integrations, sizeable refactors**) in Atlas / Nest services / Vue apps. Prefer matching the **patterns already documented** in repo-specific **`/.cursor/rules/**`** (architecture, layering, Nest patterns).

Frame every implementation as **Problem → Requirement → Solution** before writing code (see [problem-requirement-solution.mdc](./problem-requirement-solution.mdc)): state the problem, define what must be true to resolve it, then choose the change.

---

## 1. Automated tests — default obligation

Treat tests as **part of shipping**, not a follow-on ticket unless the repo standard explicitly waives (`jest-e2e` carve-outs, trivial config-only tweaks, docs-only churn).

**If executable tests do not yet exist for the unit you touch** (**new endpoint, adapter, composable, service, mapper, reducer, Vue surface**, …)—**create them immediately** beside that code using the repo’s **`__specs__` / **`*.spec.*`** layout. Leaving production logic uncovered—when sibling files already carry specs and no repo waiver applies—is unacceptable.

Each relevant **unit suite** tied to shipped behavior must be **comprehensive across the seams you influence**—not just a lone smoke assertion:

- **Happy path** — success returns / side effects asserted.
- **Failure paths** — invalid input, forbidden states, **`Promise.reject`**, mapped domain/application errors surfaced the way callers see them.
- **Edge cases** — boundaries that plausibly break behavior (**empty**/null payloads, extremes, concurrency-safe assumptions documented with at least minimal coverage where risk exists).
- **Graceful degradation** — not only “it throws”: assert **controlled handling**—no silent breakage, no leaky raw stack traces promised to callers. **Graceful handling is layer-specific** (see below).

When you introduce or materially change behavior, **add new specs or extend existing ones** so that:

- **Surface coverage** — the **new behavior** stays reflected in assertions across the bullets above—not just a lone green path.
- **Regression / isolation posture** — when shared infrastructure moves (**global filters, middleware, Axios interceptors, query clients, routers, caches, decorators**), extend or add **narrow contract tests** proving **neighbor API routes / callers / widgets** retain **happy**, **failure**, **edge**, and **graceful** guarantees wherever risk migrated—rather than brittle end-to-end guesswork alone.

Repos using **`__specs__/*.spec.{ts,vue,...}`**, **`vitest`**, **`jest`**—follow **existing layout and helpers** (**`createApplyMock`**, **`createComposableMock`**, etc.) rather than inventing parallel harnesses.

#### Two distinct test obligations

**Why:** "I ran the suite" and "I covered the change" are different duties; collapsing them lets a behavior change ship under a green-but-stale suite.

- **Running tests** — **required** at the **end of the session** when the repo has applicable test gates for the touched work. Exception **only** by explicit blocker or true out-of-scope condition. "Small tweak" is **not** a valid reason to skip running applicable test gates. Report per the **Verification-gate reporting** section of [ticket-changelog.mdc](./ticket-changelog.mdc) (exact command + scope + result).
- **Adding or updating tests** — **required** when behavior changed, a bug was fixed, or coverage for the touched behavior did not already exist. If **no** new tests were added, **name the existing suite or assertions** that already cover the changed behavior, or use the documented exception path below.

```
Good: "Tests added: useTextTruncation.spec.ts (happy/empty/overflow). Tests run: npx vitest run --maxWorkers 1 src/composables — 8 passing."
Good: "No new tests — existing ProceedingFileTableDataRow.spec.ts already asserts tooltip-on-overflow; verified still green."
Bad:  "Covered by existing tests" with no suite named; or skipping the run because it was a "small tweak."
```

#### Graceful degradation by layer

**Why:** demanding UI-style assertions for backend-only work (or vice versa) produces noise, not safety. Assert the failure shape **the layer actually owns**:

- **Backend / HTTP** — assert controlled **status codes** and **error shapes**; do not leak raw internals/stack traces.
- **Frontend / UI** — assert **user-visible** error handling when applicable: `onError` behavior, fallback rendering, disabled states, toast/message handling.
- **Domain / utility / mapper** — assert deterministic failure behavior or an explicit fallback **only if** the unit is supposed to provide it.

Do **not** require UI-style assertions for backend-only work, or HTTP-style assertions for pure utility code.

#### Valid test exceptions (narrow)

**Why:** an open-ended "couldn't test" escape hatch erodes the whole obligation. A test exception is valid **only** when at least one is true:

- the repo has **no runnable test harness** for that layer;
- adding the **first meaningful test** would require **significant scaffolding unrelated** to the change;
- the touched code is **purely wiring/config/docs** with no meaningful behavior to assert;
- an **existing repo rule explicitly waives** tests for that category.

When using an exception, record (per [ticket-changelog.mdc](./ticket-changelog.mdc) **Exception & evidence reporting**): **why** tests were blocked, **what risk** remains uncovered, and the **smallest follow-up** that would unlock coverage.

```
Good: "Tests — blocked: no jest harness wired for the CLI entrypoint layer; risk: arg parsing untested; follow-up: add jest config for bin/ (PRDV-XXXXX)."
Bad:  "Couldn't easily test this."
```

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

Before calling work **done**, walk the **canonical shipping checklist** defined in [ticket-changelog.mdc](./ticket-changelog.mdc) (**Shipping checklist (canonical vocabulary)** — the standardized headings, triggers, and exceptions). That rule owns the checklist structure and the **Exception & evidence reporting** standard (not-relevant vs blocked, out-of-scope, concrete-surface verification). **This section adds the build-specific evidence** each heading needs. Do **not** redefine the checklist here.

**Absence of change must be verified against a concrete surface** (canonical rule in [ticket-changelog.mdc](./ticket-changelog.mdc)). "I only refactored" / "I only touched internals" is **not** sufficient — name the surface you checked and confirm it stayed unchanged. The per-heading evidence below is how you do that.

### Tests & regression (§1)

- **New or changed behavior** has specs per §1 (happy, failure, edge, graceful where risk exists).
- **Shared infrastructure** you touched (filters, interceptors, routers, global clients) has neighbor/regression coverage when behavior could leak sideways.
- **Isolation exception evidence:** if you omit regression coverage because the change is **strictly isolated**, **name the boundary** that isolates it **and** why that boundary prevents effect on adjacent callers, shared infrastructure, or neighboring surfaces. "isolated" by itself is **not** sufficient.

```
Good: "Regression — isolated: change confined to a private helper with no caller-contract change; public signature and exported types unchanged."
Good: "Regression — isolated: test-only change, no production code touched."
Bad:  "Isolated change, no regression risk."
```

### Changelog / session memory

Keep cross-session memory current in **`dustin-thomason`** (not in app repos, not in **`larry-adams`**); the changelog is the **canonical record** (see [ticket-changelog.mdc](./ticket-changelog.mdc) → **Canonical record**).

| Work context | Where to update | When |
| ------------ | --------------- | ---- |
| **`PRDV-*` ticket** (Atlas, Callisto, Europa, Triton, …) | `docs/<system>/PRDV-XXXXX-changelog.md` | **Before every commit** on PlanetDepos app repos — session log + **Current state**; see [ticket-changelog.mdc](./ticket-changelog.mdc) |
| **Personal / side project** (Countdowns, WorkLists, …) | `docs/<project>/` changelog for that project (e.g. `docs/countdowns/countdowns-app-changelog.mdc`) | **Task start** — read for alignment; **end of session** or before commit/push — session log |
| **No ticket, trivial dustin-thomason-only doc tweak** | — | Changelog optional |

**Personal-project session entry** (match existing file shape): newest-first **Session log** with summary, files/areas, user-visible impact, tests run; refresh **Current state** when scope shifts. If no changelog file exists yet for that project, create one under `docs/<project>/` using the same sections (Purpose, Scope, Session log, Current state).

### Swagger / OpenAPI / API contract docs

**Check every shipping pass**—most sessions are **not relevant**, but the check is mandatory:

- If the repo exposes **Swagger**, **OpenAPI**, route decorators, or **swagger helpers** (common on Callisto/Europa/Triton backends):
  - **New or changed HTTP surface** (path, method, body, status, auth) → update helpers, decorators, DTOs, and generated/spec artifacts per **that repo’s** `.cursor/rules/` and module conventions.
  - **No contract change** → record it with the **checked surface named** — "no API surface change" by itself is **not** sufficient.
- UI-only or non-HTTP work → record **not relevant — no API docs in this repo**.
- When unsure whether Swagger applies, search the touched module for `swagger`, `@Api`, or `*swagger*` helpers before marking not relevant.

```
Good: "API docs — not relevant: internal service refactor only; route path/method, DTO shape, and status/auth decorators checked, all unchanged."
Bad:  "No API surface change."
```

### Tooling gates

- Respect **`npm run lint`**, **`audit`** thresholds, and serial **`vitest`**/**`jest`** runs when the repo has them ([git-commit-workflow.mdc](./git-commit-workflow.mdc)).
- **Gate exception evidence:** if a gate is recorded **not applicable / out of scope**, **name the specific gate** and **why the work was outside that gate's scope**. "Not applicable" by itself is **not** sufficient.

```
Good: "audit — not applicable: this repo has no package.json."
Good: "lint — not applicable: touched files live outside the linted workspace (docs/ only)."
Bad:  "Tooling gates N/A."
```

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

## When subagents are unavailable (fallback)

**Why:** the exploration is the obligation; subagents are only the *preferred mechanism* for it. Tooling limits must not become a reason to skip needed context-gathering.

- If subagents **are** available → use them for qualifying read-only parallel exploration.
- If subagents are **not** available → perform the **same exploration serially** in the parent context.
- Lack of subagent support is **not** a reason to skip needed exploration.
- **Return concrete artifacts either way** (paths, signatures, snippets, migration names).

```
Good: "No subagents in this environment — read the three modules serially myself and returned the entity path, composable signature, and migration name."
Bad:  "Couldn't fan out, so I skipped checking the adjacent module."
```

---

## Relationship to other rules

This rule is **additive**. It does not override or replace:

- **`build-implementation-guardrails`** — still governs how you implement and test.
- **`spec-writing`** — still governs spec sections; fanout feeds context *into* spec drafting.
- **`ticket-changelog`** — still governs session logs and plans; fanout feeds context *into* ticket onboarding.
- **Existing Task tool judgment** — you may still spawn subagents for other reasons (implementation, best-of-n, etc.) outside this rule's scope. This rule only adds guidance for the **read-only exploration** case.

## git-commit-workflow

# Git commit & push (dustin-thomason)

Baseline for landing changes on the **current working branch**. Team or ticket tooling can override when it conflicts.

**Push target (default):** the **current working branch.** Feature branches are **normal and expected** when the repo or task uses them (e.g. `PRDV-XXXXX`). Use **`main`** **only** when the repo workflow is direct-to-`main` **or** the user explicitly says so. Do **not** imply `main` is preferred in branch-based workflows.

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

#### Order: audit → lint → tests

Run and report in a **fixed order — audit, then lint, then tests**:

- **audit first** to catch shipment blockers early, before you invest in fixes;
- **lint second** because it **may mutate files** (`eslint --fix`);
- **tests last**, against the **post-lint tree**.

Tests **must** run after lint against the **final post-lint state.** Do **not** add pedantic rerun requirements beyond this order — require an **extra rerun only** when a gate was run **before** a later file-mutating step in a nonstandard flow.

#### Use the repo-standard gate command

**Why:** an ad-hoc narrower command can pass while the real gate would fail. When a repo provides a standard verification command, **use that command by default.** Do **not** substitute a weaker or narrower command unless the standard one is **unavailable or blocked**, and only when the substitute **preserves the intent** of the standard gate for the changed scope. **Convenience alone is not a valid reason to substitute.** If you substitute, record: **why** the standard command was not used, **why** the substitute still verifies the relevant scope, and **what (if anything) remains unverified.**

#### Reporting verification gates

**Why:** "tests passed" is unfalsifiable — a reader cannot tell what ran or over what scope. For **tests, lint, and audit**, reporting **must** be auditable (canonical format in [ticket-changelog.mdc](./ticket-changelog.mdc) → **Verification-gate reporting**):

- Record the **exact gate command**, the **scope** it covered, and the **result**. "Tests passed" / "lint passed" / "audit passed" by itself is **not** sufficient.
- **Only session-end verification** is the official compliance record; exploratory runs **may** be mentioned but **do not** replace the final result.
- Report the **final post-change state only** — do **not** cite an earlier green run if later edits followed it.
- Use a **markdown table** (preferred by default; **required** when **multiple gates** or **any exception** are reported):

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto-back-end | pass | — |
| lint | `npm run lint` | callisto-back-end | pass | — |
| tests | `npm test -- --runInBand src/foo` | foo module | pass | — |

```
Good: the table above.
Bad:  "ran lint and tests, all good."
```

### Ticket changelog — before **`git commit`**

Follow [ticket-changelog.mdc](./ticket-changelog.mdc) (**Session log** + first-pass rules), then continue here.

### Git sequence

Once **§Pre-flight** is satisfied—or skipped because there is no npm workspace—continue:

**3.** **`git status`**—read staged vs unstaged vs untracked.

**4.** Stage with **`git add -A`** when **everything** listed should ride in **one** commit. If paths must remain out (**secrets**, stray scratch files, unrelated edits), **`git add <paths>`** selectively and—in one terse sentence—what you staged and why.

**5.** **`git commit -m "`** + §Commit-message subject below + **`"`**. If neither staging nor substantive working-tree changes remain, explain that **`main`** (or the current branch) already matches **`origin`** rather than forging an empty commit.

**6.** **`git push`** to **`origin`** for your **current working branch** (feature branch when the task uses one; `main` only for direct-to-`main` repos or when the user says so).

**7.** Leave **no temp helper files**. Delete ephemeral commit-message scratch paths.

**8.** **Paste one clean SHA**: after **`git push`**, capture **`HEAD`** and reply with **one fenced markdown block containing only that forty‑character hash** (no branch name, no `commit` prefix) so the reader copies it cleanly from Cursor.

- **PowerShell (preferred on Windows):** **`git rev-parse HEAD | Set-Clipboard`**, then **`git rev-parse HEAD`** so the hash is on the clipboard **and** visible in the terminal/chat output for a second copy.
- **Bash / sh:** **`git rev-parse HEAD`**

PR bodies and channel posts use the same fenced-block shape—see [pull-request-workflow.md](../docs/pull-request-workflow.md) (**Commit hash**).

---

**Commit SHA block example**

> Pushed the current branch with passing audit / lint / test gates; landing SHA:

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

Keep the subject short for readability: **aim for five to seven words** in the **descriptive** text, describing the **surface change**, not implementation detail. **Exceed that only when absolutely necessary.** A **ticket prefix** (e.g. `PRDV-14699:`) **does not count** toward the word limit.

```
Good: "PRDV-14699: Co-locate comparator with mapper"   (prefix excluded; 5 descriptive words)
Bad:  "PRDV-14699: Refactor the comparator so it now reads sort keys from the proceeding mapper instead of inline"
```

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
| Write / extend / review an **epic** or **story** **spec** | [spec-writing.mdc](./spec-writing.mdc) — all required sections; wiki naming/Obsidian/dev notes: [wiki-spec-authoring.md](../../docs/wiki-spec-authoring.md); guided flow: [write-spec](../skills/write-spec/SKILL.md) |
| **Commit**, **push**, git workflow | [git-commit-workflow.mdc](./git-commit-workflow.mdc) + [ticket-changelog.mdc](./ticket-changelog.mdc) |
| **New ticket**, **new branch**, start PRDV work | Read [new-branch-get-started.md](../docs/new-branch-get-started.md); update changelog in `dustin-thomason/docs/<system>/` |
| **Open PR**, PR description, `gh pr create` | Read [pull-request-workflow.md](../docs/pull-request-workflow.md) |
| **Implement** feature, endpoint, refactor, tests | [ticket-changelog.mdc](./ticket-changelog.mdc) — **task start**: resolve + read canonical changelog (**Current state**, **Plans**, **Attempt history**); then [problem-requirement-solution.mdc](./problem-requirement-solution.mdc) — frame as Problem → Requirement → Solution; then [build-implementation-guardrails.mdc](./build-implementation-guardrails.mdc) — §5 shipping checklist + that repo's `.cursor/rules/` |
| **Fix** bug or regression (substantive) | Same as **Implement** — changelog alignment first when a ticket or project log exists |
| **Explore** unfamiliar code, onboard to ticket, gather multi-area context | [context-fanout.mdc](./context-fanout.mdc) — read-only subagent fanout |

## Changelog memory (task start + commit)

Canonical changelog paths and **task-start alignment** live in [ticket-changelog.mdc](./ticket-changelog.mdc) (**Task start — changelog alignment**). Agents **must** resolve and read the relevant log **once at the start of each new substantive task** — not only when the user `@` mentions it.

| User does | You do |
| --------- | ------ |
| Starts implement / fix / refactor / spec / ticket work | **Resolve** canonical changelog (PRDV → `docs/<system>/`; personal project → `docs/<project>/`); read **Current state**, **Plans**, **Attempt history**, latest **Session log**; align before planning or coding |
| `@docs/.../PRDV-XXXXX-changelog` or says "working on PRDV-XXXXX" | Same — treat as explicit pointer; continue from **Current state** and **Session log** |
| New ticket, no file yet | Run `scripts/new-ticket-changelog.ps1` or template; **Requirements (verbatim)** on first pass |
| **Commit** / **push** | Append **Session log** in that file **before** `git commit` ([ticket-changelog.mdc](./ticket-changelog.mdc)) |

Optional human opener (still helps on new threads): [.cursor/docs/session-start.md](../docs/session-start.md).

## Skills (not automatic — user invokes)

| Skill | When |
| ----- | ---- |
| `write-spec` | Author or update PRDV specs and dev notes (wiki or app-repo paths) |
| `grill-me` | User wants plan/design stress-tested |
| `workflow-housekeeping` | User asks to audit/sync workflow docs after edits |

## Precedence — repo rules vs personal rules

**Why:** these personal rules travel into every repo, so a tie-break must be explicit or they will quietly override a repo's real conventions.

- **Repo-specific `.cursor/rules/**` win** for **repo behavior and technical conventions.**
- **`dustin-thomason` rules win** for **personal workflow habits** — but **only** when they do **not** conflict with the repo's technical conventions.

| Repo `.cursor/rules/**` wins | `dustin-thomason` wins |
| ---------------------------- | ---------------------- |
| architecture and layering | changelog location |
| testing harness and test placement conventions | session memory |
| file placement and module structure | cross-repo personal workflow habits |
| API / Swagger / DTO / contract conventions | |
| branch / commit / PR formats required by that repo | |

If a **direct conflict materially changes behavior**, note that **exception in the changelog**. Do **not** note conflicts when the rules were **compatible in practice**.

```
Good: "Conflict noted: repo mandates raw-SQL repository for this reader; followed repo rule over the personal 'avoid brittle SQL' default — recorded in changelog."
Bad:  Noting a "conflict" when the personal habit and repo rule never actually disagreed.
```

## AGENTS.md is generated

`AGENTS.md` is **generated output only** — **never edit it directly.** All behavioral changes go in the source `.mdc` files under `.cursor/rules/`; regeneration overwrites direct edits. Authoritative detail: [codex-agents-sync.mdc](./codex-agents-sync.mdc).

## Rule language semantics

**Why:** mixed strengths of wording make rules ambiguous. Use one vocabulary across all personal rules:

- **must / required** = mandatory unless an explicit exception applies.
- **default / normally** = expected baseline, but context may change it.
- **may / can** = optional.

Avoid soft wording in mandatory instructions.

## Reporting integrity (truthfulness / evidence)

**Why:** a status report is only useful if it maps to what actually happened. Agents **must not** claim a file was changed, a command was run, or a result was observed unless it **actually happened**. Status reporting **must** be grounded in observable evidence: if no file changed, do **not** imply it did; if a command was not run, do **not** present it as completed; if intended work was not completed, **say so directly.**

Distinguish clearly:

- **planned** = intended but not done.
- **attempted** = tried but not completed.
- **completed** = actually changed / performed.
- **verified** = completed **and** confirmed by an applicable check.

```
Good: "Spec planned but not written; impl completed; verified via npm test -- --runInBand (12 passing)."
Bad:  "Added tests and everything passes" when no test file was created or run.
```

## Overlap with app repos

- **Spec / build / commit habits** → personal rules above win for *how you work* (subject to **Precedence** above).
- **Commit subject on `PRDV-*` branches** → still use app repo `PRDV-X:` format when present.
- **Vue / Nest / architecture patterns** → app repo rules still apply alongside personal guardrails.

## problem-requirement-solution

# Problem → Requirement → Solution

**Philosophy (must be adhered to):** when addressing implementation, reason in a coherent, ordered line so the thinking stays clear for the end user — **Problem → Requirement → Solution.**

**Why:** jumping straight to a solution hides *what* was actually being solved and *why* the chosen change is the right one. Leading with the problem and the requirement makes the work reviewable, keeps scope honest, and gives the reader (and the next agent) a traceable rationale instead of an unexplained diff.

## The order

1. **Problem** — state the concrete problem or pain being addressed: what is broken, missing, or asked for. This is **not** a restatement of the task title; it is the underlying need.
2. **Requirement** — define what **must be true** for the system to resolve that problem (the condition(s) the system must deliver / satisfy). State it **independently of implementation** — the requirement should survive a change of solution.
3. **Solution** — only **then** determine the change to integrate as a result. The solution **must** trace back to the requirement, and the requirement back to the problem.

## Where it applies

Use this ordering in **implementation responses, plans, spec narratives, and changelog / PR descriptions** — anywhere you explain a change to a reader. It complements, and runs ahead of, the build checklist in [build-implementation-guardrails.mdc](./build-implementation-guardrails.mdc) and the spec sections in [spec-writing.mdc](./spec-writing.mdc).

## Example

```
Good:
  Problem:     Long filenames overflow the proceeding-file table cell and get visually clipped with no way to read them.
  Requirement: Long names must stay fully readable on demand without breaking the table's fixed layout.
  Solution:    Add a useTextTruncation composable + tooltip that reveals the full name when the text is ellipsized.

Bad:
  "Added a truncation composable and a tooltip."   (solution only — no stated problem, no requirement to verify it against)
```

## Relationship to other rules

This rule is **additive**. It does **not** override repo-specific `.cursor/rules/**` technical conventions (see precedence in [personal-methodology.mdc](./personal-methodology.mdc)); it governs **how you frame and explain** the work, not the repo's architecture or contracts.

## spec-writing

# Epic and story specs (Callisto / Atlas)

When the user asks you to **write, extend, or review** an **epic** or **story** spec — usually in app repos or spec folders the team uses — include the sections below. If requirements come from a coworker spec in **`larry-adams`**, treat that repo as **read-only input**; ticket memory and plan index stay in **`dustin-thomason`**. You do **not** need the user to `@` this file or copy it into the app repo.

If a section does not apply, add a one-line **N/A** with a short reason (e.g. "N/A — UI-only story") so reviewers know it was considered.

Frame the spec narrative as **Problem → Requirement → Solution** (see [problem-requirement-solution.mdc](./problem-requirement-solution.mdc)): the problem the story solves, what must be true to resolve it, then the design below.

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
| User starts a **new substantive task** (implement, fix, refactor, spec, ticket onboarding) | **Resolve** canonical changelog (below); **read** **Current state**, **Plans**, **Attempt history**, latest **Session log**; align before planning or coding |
| User starts a ticket / new branch | Scaffold changelog if missing; **first pass** verbatim requirements |
| User `@` or names `docs/.../PRDV-*-changelog`, branch `PRDV-*`, or ticket id in message | **Read** existing file or scaffold; treat as active ticket for this thread |
| User asks to **commit** / **push** / git workflow | **Session log** entry **before** `git commit` (then [git-commit-workflow.mdc](./git-commit-workflow.mdc) pre-flight + git) |
| User opens a PR | Summarize from changelog; do not paste the whole file |
| User or agent **generates a plan** | Add/update a row under **Plans** (path, status, one-line approach) |
| New implementation approach | Read **Plans** + **Attempt history** first; avoid repeating **superseded** / **abandoned** plans |

Skip only for trivial **`dustin-thomason`**-only edits with **no** ticket, pure Q&A with no implementation intent, or workflow/doc housekeeping that does not touch product code.

---

## Task start — changelog alignment (read before substantive work)

**Why:** the changelog is the cross-session **story** — requirements, chosen approach, what shipped, and what was abandoned. Reading it once at task start keeps new work aligned without re-reading it on every agent step.

**When (once per new task or agent thread, before planning or coding):**

- User asks to **implement**, **fix**, **refactor**, **write/extend a spec**, **onboard to a ticket**, or otherwise start substantive work — including when rules such as `personal-methodology`, `build-implementation-guardrails`, or generated **`AGENTS.md`** route you there.
- **Not** on every follow-up message, tool call, or micro-step within the same task.

**Resolve the canonical changelog** (same path you would **write** session log entries to):

| Work context | Where to read |
| ------------ | ------------- |
| **`PRDV-*` ticket** (Atlas, Callisto, Europa, Triton, …) | `dustin-thomason/docs/<system>/PRDV-XXXXX-changelog.md` |
| **Personal / side project** (Countdowns, WorkLists, OtterCopy, …) | `dustin-thomason/docs/<project>/` — project changelog (e.g. `*-app-changelog.mdc`) |
| **Changelog lives in the app repo** (rare; only when that repo is already the established home) | That repo's changelog path — **only** when prior session logs or project docs already use it |

**How to resolve it (in priority order — `@` is not required):**

1. **Explicit** — path or `@` in the user message wins.
2. **`PRDV-` id** — from user message, open files, or **`git branch --show-current`** in the app repo; then glob `dustin-thomason/docs/**/PRDV-XXXXX-changelog.md`.
3. **Personal project** — from workspace folder, app name, or `docs/<project>/` in dustin-thomason; read the project changelog there.
4. **Missing file** — scaffold (ticket: `new-ticket-changelog.ps1`; personal: create under `docs/<project>/` per [build-implementation-guardrails.mdc](./build-implementation-guardrails.mdc)) before deep work.

**What to read (minimum):**

- **Current state** — what is true now; do not contradict it without noting why.
- **Requirements (verbatim)** — scope boundary for the ticket or project.
- **Plans** — prefer **`active`** / **`implemented`** rows; do **not** repeat **`superseded`** / **`abandoned`** approaches.
- **Attempt history** — failures and dead ends to avoid.
- **Latest Session log** entry — most recent shipped direction.

**After reading — align before acting:**

- State briefly (in thinking or first reply when useful) which changelog you used and which **active Plan** or **Current state** line governs this task.
- If the user's new request **conflicts** with **Current state** or an **active Plan**, say so and confirm direction before a large refactor or new plan.

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

## Canonical record (source of truth)

**Why:** the reader needs one authoritative account of what shipped; a chat wrap-up scrolls away and drifts from the tree. When a changelog exists, **it is the canonical record**; a final chat wrap-up **may** summarize but is **not** the source of truth.

- **PRDV work** → canonical record is `dustin-thomason/docs/<system>/PRDV-XXXXX-changelog.md`.
- **Personal-project work** → canonical record is that project's changelog under `docs/<project>/`.
- **Trivial `dustin-thomason`-only doc tweak with no changelog** → the final wrap-up **may** be the only record.

```
Good: "Recorded in docs/atlas/PRDV-12264-changelog.md → Session log 2026-05-29T17:40:00Z; wrap-up below is a summary."
Bad:  Reporting results only in chat when a ticket changelog exists for the work.
```

---

## Shipping checklist (canonical vocabulary)

**Why:** a single standardized checklist keeps every session auditable and stops "looks fine" omissions. This is the **source of truth** for the checklist; other rules (`build-implementation-guardrails.mdc`, `git-commit-workflow.mdc`) **reference** these headings rather than redefining them.

**Structure rules:**

- The checklist is **required** for any session that **materially changes code or behavior**.
- Keep the **session narrative first**; **append** the checklist at the **end** of the session entry.
- A heading **may** be omitted **only** when its trigger is absent (**not relevant**) or an explicit exception applies. An omitted heading means **not relevant**.
- If a **triggered** heading is **not** performed, the exception **must** be recorded explicitly (see **Exception & evidence reporting**).
- **Do not** pad entries with irrelevant noise, and **do not** allow open-ended omission based on agent preference or assumption.

**Not required for:** trivial planning-only sessions, note-taking, or minor docs with no behavior impact.

**Standard headings** (append in this order; omit a heading only when its trigger is absent):

| Heading | Default trigger (required when…) | Valid exception |
| ------- | -------------------------------- | --------------- |
| **Tests run** | the repo has applicable lint/test/audit gates for the touched work | repo lacks the gate, work is truly outside its scope, or a documented blocker prevented running it |
| **Tests added/updated** | behavior/logic changed or a bug was fixed | documented test-blocker (see `build-implementation-guardrails.mdc` §1) |
| **Regression impact** | shared infrastructure, cross-cutting behavior, or adjacent surfaces were touched | change is strictly isolated **and** the note names the isolating boundary |
| **API docs** | an HTTP contract or API metadata changed | no contract / API-surface change (name the checked surface) |
| **Tooling gates** | the repo provides applicable lint/test/audit gates | repo lacks the gate, work is out of that gate's scope, or a documented blocker applies |
| **Conflicts / exceptions** | a normal rule was skipped, blocked, or overridden | — (record whenever it happens) |

**Posture:** do the check **by default**; skip **only** by explicit exception; **never** silently assume "it should be fine." Tooling gates are **verification steps, not optional confidence checks** — confidence or intuition is never a substitute for running the gate.

---

## Exception & evidence reporting (anti-handwave)

**Why:** a bare "N/A" or "blocked" hides whether a step was irrelevant or skipped, and whether risk remains. Every exception must be auditable.

**Not relevant vs blocked:**

- **Not relevant** = the trigger was **absent**.
- **Blocked / exception** = the trigger was **present**, but the action was **not** completed.
- A **blocked** item **must never** be recorded as `N/A`. If something was not done, the record **must** say why.

**Every exception must state:** (1) why the normal step was not done, (2) the exact check or action skipped, (3) the residual risk or the follow-up that resolves it. Vague notes like only "blocked" or "N/A" are **not** allowed.

**Out of scope** must define the **scope boundary** and explain why the skipped check falls outside it. "Out of scope" by itself is **not** sufficient.

**Absence of change must be verified against a concrete surface**, not inferred from intent. "I only refactored", "I only touched internals", and "this should not affect anything" are **not** sufficient by themselves — name the checked surface and confirm it stayed unchanged. (Layer-specific evidence examples — regression boundary, API surface, tooling gate — live in `build-implementation-guardrails.mdc`.)

```
Good: "API docs — not relevant: service-internal refactor only; route path/method, DTO shape, and auth/status decorators checked, all unchanged."
Good: "Tests — blocked: no Vitest harness for this CLI layer; risk: arg-parse path uncovered; follow-up: scaffold harness (PRDV-XXXXX)."
Bad:  "API docs: N/A"
Bad:  "tests: blocked"
```

---

## Verification-gate reporting

**Why:** "tests passed" is unfalsifiable; a reader cannot tell what ran or over what scope. Reporting must be reproducible and reflect the shipped tree.

- Record the **exact gate command**, the **scope** it covered, and the **result**. "Tests passed", "lint passed", or "audit passed" by itself is **not** sufficient. Applies to **tests**, **lint**, and **audit**.
- **Order** matches the workflow: **audit → lint → tests** (rationale and commands in `git-commit-workflow.mdc`).
- **Only session-end verification** counts as the official compliance record. Exploratory runs **may** be mentioned but **do not** replace the final gate result.
- Report the **final post-change state only.** Do **not** cite an earlier green run if later edits followed it; if the final state differs from an intermediate run, report the final state.

**Reporting format — markdown table.** Preferred by default; **required** when **multiple gates** or **any exception** are reported:

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | atlas-front-end | pass | — |
| lint | `npm run lint` | atlas-front-end | pass | — |
| tests | `npx vitest run --maxWorkers 1 src/foo` | foo composable | pass | — |

```
Good: the table above (exact command + scope + result per gate).
Bad:  "lint passed; tests passed."
```

---

## UTC timestamps for session entries

**Why:** a single canonical timezone-free format keeps cross-session ordering unambiguous across agents and machines.

- Session entries that record **implementation activity** **must** include a UTC timestamp.
- Use **one** canonical format: **ISO 8601 UTC with trailing `Z`**, reflecting when the entry was recorded.

```
Good: ### 2026-05-29T21:14:00Z — atlas-front-end
Bad:  ### 2026-05-29 — atlas-front-end   (no time, no zone, for implementation work)
```

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
