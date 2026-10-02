@dustin-thomason/docs/atlas/PRDV-16934/  
Digest all content first, then report back with a 3-5 sentence understanding of the task.

# Ticket artifacts: <<PASTE ARTIFACT FOLDER PATH HERE>>

Read that folder first. Change nothing until I say so — ingest, report what you understand, then stand by.

---

## 1. Repos

| Path | Role |
| --- | --- |
| `C:\Users\dustin.thomason\proteus-front-end` | **Target.** React 19 + TS + shadcn/Tailwind + TanStack Query. All code changes go here. |
| `C:\Users\dustin.thomason\atlas-front-end` | **Visual and behavioral source of truth.** Vue/Quasar. STRICTLY READ-ONLY — read freely, never write. Its `.vue`, `.module.scss`, `columns.ts` and `src/i18n/en-US/common.json` define what "correct" means. |
| `C:\Users\dustin.thomason\callisto-back-end` | Response shapes only. READ-ONLY. Never call it. |
| `C:\dustin-thomason\docs\atlas\` | Ticket artifacts and changelogs. |

## 2. Read before planning

- The ticket artifact folder above.
- **The worked precedent — same premise, same method, already done:**
  `C:\dustin-thomason\docs\atlas\PRDV-16936-changelog.md` and
  `C:\dustin-thomason\docs\atlas\PRDV-16936\PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md`.
  That was the Case Details page. Reuse the approach; don't re-derive it.
- In proteus: `CLAUDE.md`, `AGENTS.md`, `PRODUCT.md`, `DESIGN.md`, `.cursor/rules/**`.

## 3. Premise

Product needs a realistic, clickable React/shadcn prototype of an existing Atlas page, running
entirely on in-repo mock data, so PMs can iterate on designs without waiting for the production
refactor. Speed and functional completeness over polish. It is a facade — no backend, no auth, no
permissions, no Azure.

Atlas is the source of truth. Side by side, the Proteus version should read as the same screen
reimplemented in the new stack, not a redesign. Depart only where a Proteus shell constraint,
semantic token, accessibility need, or missing shadcn behavior forces it — and record each departure.

## 4. Branching — one branch per ticket, never merged

- **Before any edit**, branch off the current `prototype-main` tip and record the starting SHA:
  `git switch -c PRDV-XXXXX prototype-main`
- **All work stays on that branch.** Do not merge into `prototype-main` or `main`, do not
  fast-forward, do not open a PR. The branch is tested standalone; I decide what happens to it after.
- **Never commit directly on `prototype-main`.**
- Ask before pushing. If I say push, push **the ticket branch only**.
- **Subagents never run git at all** — no branch, add, commit, or stash. The coordinator owns the branch.
- The two tickets **may** run in parallel, but only in separate worktrees — never two sessions in one
  checkout, which collides regardless of branch because there is one working tree:
  `git worktree add ../proteus-worktrees/PRDV-XXXXX -b PRDV-XXXXX prototype-main`
- **Cross-ticket dependency:** Job Detail and Proceeding Detail both extend `src/api/**` and
  `src/mocks/**`. Since nothing merges, a branch cut from `prototype-main` will not see the other
  ticket's additions. If you depend on them, branch off *that ticket's branch*, state which SHA, and
  record the dependency in the changelog. Do **not** duplicate a parallel set of types, fixtures, or
  routes to work around it — say so and stop.

## 5. Starting state (verified 2026-09-17 — re-confirm before relying on it)

- `src/pages/JobDetail/` **does not exist** — Job Detail is greenfield.
- `src/pages/ProceedingDetail/` **does exist** and is substantive (`ProceedingDetailPage.tsx`,
  `ProceedingDetailPageContent.tsx`, `useProceedingDetail.ts`, constants, types, plus shared
  `src/components/ProceedingDetailView.tsx` and `ProceedingDrawer.tsx`). **Extend it, don't replace
  it**, and don't break its other consumers.
- **`/jobs/:jobId` is currently wired to `ProceedingDetailPage`** in `src/app/router/index.tsx` — a
  placeholder. Job-number links from the Case Details Jobs tab land on the wrong page today.
  Replacing that element is part of the Job Detail work.
- Route helpers exist and are already in use — reuse them, never hardcode paths:
  `jobDetailPath(jobId)` → `/jobs/:jobId`, `proceedingDetailPath(proceedingId)` → `/proceedings/:proceedingId`.
- Atlas sources:
  - `src/callisto/pages/JobProceedingPages/JobDetailPage/JobDetailPage.vue` (+ `components/`, `__specs__/`)
  - `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/ProceedingDetailPage.vue` (+ `components/`, `composables/`)
  - `src/callisto/pages/JobProceedingPages/components/` — `CaseInfo`, `JobInfoCompact`, `JobRow` are
    **shared by both pages** in Atlas. Expect the Proteus versions to share components too.
- **Case Details is a live consumer of both routes.** After wiring either page, re-check that the
  Jobs tab's job-number and proceeding links still navigate and `/cases/:caseId` is otherwise untouched.

## 6. Method

These tickets start empty, so the shape is **build → review your own output → fix**.

1. **Decide the architecture yourself, in writing, before fanning out.** Agents execute a
   specification well and invent badly.
2. **Build. Fan out subagents split by FILE OWNERSHIP, never by finding.** Give each an exclusive,
   disjoint file list and say so in its prompt. Splitting by finding puts two agents in one file —
   that already caused a collision and lost work on this ticket family.
3. **Agents edit only.** Tell them explicitly: no git, no `npm run gate`/`lint`/`build`/`dev` — they
   contend over `dist/` and `tsbuildinfo`. Tell them to stop and report the exact missing decision
   rather than improvise one.
4. **Carry your measured evidence into each agent prompt.** An agent that doesn't know *why* a value
   is wrong will often "fix" it back into the bug.
5. **Gate centrally, once, after they all land — then read every diff yourself.** Do not trust agent
   reports. On the Case Details ticket, two of five hand-backs needed correction and one didn't compile.
6. **Then run an AC-by-AC pass against your own output**, a header per AC, enumerating defects with
   `file:line` evidence on both sides. Trim clean ACs from the final write-up.
7. **Verify in a real browser, not by reading source.** Not optional: on Case Details, ten defects
   survived type-check, lint, build and a source-read parity claim — including one where a headline
   action silently did nothing.
8. Fix what the pass finds, re-gate, re-verify.

## 7. Constraints

- All fake data lives in `src/mocks/**`. Feature components never import fixtures or branch on mock mode.
- Data flows through typed services in `src/api/**` and TanStack Query hooks.
- Reuse existing shadcn / Planet Depos / shared components. Tailwind utilities and semantic theme
  tokens only — no raw hex, no inline styles, no CSS Modules, no second UI library.
- No dependency or lockfile changes.
- No test harness exists (`test:unit:ci` is a stub, zero spec files) and the ticket scopes tests as
  intentionally light. Do not add one.
- Don't delete or modify shared components other screens depend on.

## 8. Traps that already cost time on this ticket family

- `window.open()` on a `data:` URI is silently blocked by Chrome as top-level navigation — no error,
  no tab. Use a programmatic `<a download>` click.
- In this theme `Badge variant="secondary"` is **brighter** than `"default"` (`rgb(42,31,255)` vs
  `rgb(6,36,126)`). For a muted or zero state use `outline`.
- `Object.fromEntries` returns a string-indexed type and does **not** satisfy `Record<0|1|2, T>` (TS2739).
- Piping `npm audit` into `tail` makes `$?` read tail's exit code — a failing gate looks like a pass.
- ~175 files show permanently as modified from a `core.autocrlf` stat-cache artifact with zero real
  diff (`git diff --shortstat` is empty). **Stage explicit paths; never `git add -A`.**
- Port 9000 is the Atlas Vue app. Proteus auto-bumps to **9001**.
- Playwright: the npm package's expected browser build won't match what's cached. Install `playwright`
  in the scratchpad and pass
  `executablePath: 'C:/Users/dustin.thomason/AppData/Local/ms-playwright/chromium-1228/chrome-win64/chrome.exe'`.
- A husky/lint-staged pre-commit hook runs type-check, `lint:fix` and `format` over staged files and
  folds its edits into the commit.

## 9. When the work is done

- Write the changelog at `C:\dustin-thomason\docs\atlas\PRDV-XXXXX-changelog.md`, matching the other
  files in that folder and `PRDV-16936-changelog.md`. Gates go in a table with exact commands and
  **true** exit codes; exceptions are recorded as blocked-with-reason, never "N/A".
- Don't commit or push `dustin-thomason` unless I ask.
- Commit on the ticket branch with a `PRDV-XXXXX ` subject prefix, five to seven descriptive words.
  Run audit → lint → build in that order first and show me the results. Ask before pushing. Never merge.
- Notify on completion:
  `& "C:\dustin-thomason\scripts\notify-agent-complete.ps1" -Status "Completed" -Message "<5-9 words>"`

notably, use spawn agents for workers, you will be the coordinator and reconciler of mistakes, and ensure you're on a branch unique to this feature.

Lastly, 
If you have a question, this is the process: write out the question as a checklist item, search the codebase, and provide evidence showing why the question cannot be answered without user input. Asking a question without providing evidence will return the question back to the you for clarification.