# PRDV-16934 — Atlas Prototype: Job Details Page

## Ticket

- **ClickUp:** [PRDV-16934](https://app.clickup.com/t/43227262/PRDV-16934)
- **Repo:** `proteus-front-end` (product-authoring lane; ships the Atlas UI in React/shadcn)
- **Branch:** `PRDV-16934-job-detail`, cut from `prototype-main` at `f07d2e37c723e8ce2b9cb86b08212b7abb88f1f9`
- **Worktree:** `C:\Users\dustin.thomason\proteus-worktrees\PRDV-16934` (isolated — see **Attempt history**)
- **PR:** none — the prototype lane is not merged; the branch is tested standalone
- **Reference (read-only):** `atlas-front-end` (visual/behavioral source of truth), `callisto-back-end` (response shapes only)
- **Artifacts:** [PRDV-16934/](PRDV-16934/) — original ticket
- **Precedent:** [PRDV-16936-changelog.md](PRDV-16936-changelog.md) — Case Details, same premise and method

---

## Requirements (verbatim)

> **Original Request**
> As a Product Manager, I want a realistic, clickable prototype of the existing **Atlas Job Details page** using fake data, so that I can quickly create and iterate designs for new and upcoming features for stakeholders using components that will be consistent with our upcoming shadcn/react refactor work.
>
> Dev Notes:
>
> - Utilize React & Shadcn
> - Utilize “json mock server” data structures as “backend” to enable prototyping
> - (if it doesnt exist) Create a branch in proteus called "prototype-main" for this work. This branch will be maintained with prototyping resources and updated with pages built out properly in proteus from main branch until all pages have been built out correctly, then this branch will be retired
>
> **Acceptance Criteria**
>
> - Shaye is able to load the prototype into claude code to make structural and design changes as needed
> - Prototype includes the following
> - All existing Job Info fields
> - Job Number
> - Proceeding count badge
> - Job Date, Job Time
> - Proceedings list
> - Add proceeding action
> - All current add-proceeding functionality

---

## Context

- Speed and functional completeness over polish. Facade only — no backend, auth, permissions, or Azure.
- Atlas is the **visual source of truth**; departures are allowed only where a Proteus shell constraint, semantic token, accessibility need, or missing shadcn behavior forces one, and must be recorded.
- Atlas's Job Details page is far smaller than Case Details: three stacked label/content rows (CASE / JOB / PROCEEDINGS), a name-only proceedings list, and one substantial interaction — the "New proceeding" overlay.
- The repo has no test harness (`test:unit:ci` is a stub, zero spec files) and the ticket scopes tests as intentionally light.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-17 | Coordinator-owned contract + three parallel agents split by file ownership (this session) | `implemented` | Coordinator writes types/constants/router; agents own disjoint file sets for the mock lane, the page UI, and the add-proceeding form; central gate + browser verification; coordinator fixes every defect. |

---

## Session log

### 2026-09-18T17:32:00Z — proteus-front-end — PR-review-pattern pass, rebase, local merge

- **Problem:** the build was complete but had not been checked against `docs/reviewers/pr-review-patterns.md`, whose patterns are known to be requested in review; and `prototype-main` had advanced to `0c8fa3c`, so the branch was stale.
- **Requirement:** every pattern in that doc checked one by one with `file:line` evidence, all findings fixed, gate green, then a local-only merge into `prototype-main` — the branch is the deliverable and nothing is pushed.
- **Solution:** eight-pattern review, six fixes, rebase onto `0c8fa3c`, re-gate, fast-forward merge.

**Review result — 4 of 8 patterns clean, 4 with findings:**

| Pattern (Class) | Verdict |
| --- | --- |
| 1 — i18n/string externalization (A) | 2 findings |
| 2 — magic literals (B) | 1 finding |
| 3 — test-mock casts (C) | clean — no test surface exists |
| 4 — mirror coverage (D) | clean — no test surface exists |
| 5 — extract handlers (E) | 1 finding |
| 6 — justify removed safety net (F) | **1 significant finding** |
| 7 — comment cleanup (G) | 1 finding |
| 8 — cross-cutting decisions (H) | 2 findings |

**Fixes shipped:**

- **A failed proceedings fetch no longer reads as an empty job (Pattern 6).** `JobDetailView` destructured `useJobProceedings` without consuming `isError`/`isLoading`, so a failed request rendered the grey `No proceedings` pill and an empty list — indistinguishable from a job that genuinely has none, one line below a sibling query whose `isError` *was* consumed. Now renders `PROCEEDINGS_ERROR_TITLE` on failure and a loading line while fetching. **Verified** by temporarily returning `500` from the mock proceedings route (reverted after; `git checkout` confirmed clean): the error renders after TanStack's default 3 retries, and the Job row still renders.
- **Restriction labels and levels promoted to `src/constants/caseRestrictions.ts` (Patterns 1, 2, 8).** `JobCaseInfo` had its own inline copy of the labels plus a bare `=== 2` comparison. The new shared module holds `CASE_RESTRICTION_LEVELS` and `CASE_RESTRICTION_ACCESS_LABELS`; `CaseDetail/constants.ts` now imports and re-exports them so `CaseHeader` is unchanged. This removes the duplication rather than adding a forbidden cross-page import.
- **Loading/breadcrumb copy moved into `constants.ts` (Pattern 1).** `JOB_DETAIL_LOADING_LABEL`, `PROCEEDINGS_LOADING_LABEL`, `PROCEEDINGS_ERROR_TITLE`, `CASES_BREADCRUMB_LABEL`, `jobBreadcrumbLabel`.
- **Breadcrumb extracted to `JobDetailBreadcrumb.tsx` (Pattern 5).** `JobDetailView` was 152 lines, over the repo's ~150 split guidance.
- **Removed a comment restating the code (Pattern 7)** above `initialFormValues`.
- **Duplicate `formatJobDateTime` resolved (Pattern 8).** `prototype-main` had landed a byte-for-byte identical copy; the rebase deduplicated it and `src/lib/time.ts` dropped out of this branch's diff entirely. Confirmed exactly one definition remains.

**Reuse confirmed, per instruction:** `SortableTableHead` and `useTableSort` are **not** duplicated — this page has no sortable table, matching Atlas, so neither is referenced.

**Rebase note:** the rebase was initially blocked by the known `core.autocrlf` stat-cache artifact (`git diff` empty, index/worktree differing only in line endings). Cleared with `git checkout -- .` after verifying zero content diff and zero untracked files. The same artifact blocked the merge on three files, each verified `diff-vs-HEAD=0` before clearing.

**Merge:** fast-forward `0c8fa3c..e86964b` into `prototype-main`. Before merging, five superseded leftover files from the original shared-checkout phase were discarded from the main checkout after diffing each against the branch — four identical, one (`fixtures.ts`) older than the branch version, so nothing unique was lost.

- **Gates (post-merge, on `prototype-main`):**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | `proteus-front-end` | **not re-run** | 2 high + 2 moderate transitive advisories, pre-existing and unchanged (`package-lock.json` untouched all session). **User explicitly waived** this gate for the prototype lane. |
| type-check | `npm run type-check` | `proteus-front-end` | pass (exit 0) | — |
| lint | `npm run lint` | `proteus-front-end` | pass (exit 0) | — |
| build | `npm run build` | `proteus-front-end` | pass (exit 0) | pre-existing chunk-size warning only |
| browser | Playwright/Chromium, 1440×900 | `/cases/1`, `/cases/2`, `/jobs/104809` | pass | 0 console errors, 0 page errors |

- **Post-merge browser verification:** Jobs tab → job-number link → Job Detail (three rows, `3 proceedings`, `12 / 02 / 2026 @ 3:00 PM`); added a proceeding end-to-end (drawer closed, `Successfully added 1 proceeding`, list grew, pill `4 proceedings`); `/cases/2` header still reads `Restricted: U.S. Only` through the promoted labels module.
- **Known minor, not fixed:** during a proceedings fetch error the count pill still reads `No proceedings` beside the error alert. The adjacent alert disambiguates it, and suppressing the pill would add an error-aware prop for a state Atlas has no equivalent of.
- **Not pushed.** `prototype-main` is **2 commits ahead of `origin/prototype-main`**, which remains at `0c8fa3c`. No fetch, pull, or push was run.

### 2026-09-18T12:00:00Z — proteus-front-end — Job Details prototype build

- **Problem:** `/jobs/:jobId` rendered `ProceedingDetailPage` as a placeholder, so every job-number link from the Case Details Jobs tab landed on the wrong screen. No Job Details page existed.
- **Requirement:** A Job Details page matching Atlas field-for-field — job number, proceeding count badge, job date/time, the proceedings list, and the complete add-proceeding flow — running entirely on in-repo mock data behind typed services and TanStack Query.
- **Solution:** New `src/pages/JobDetail/**`, a new job-detail/proceedings/create API surface with matching mock routes and session-local fixture mutation, and `RoutePaths.JOB_DETAIL` repointed to the real page.

**Method:** Three read-only exploration subagents (Atlas source + i18n, Proteus data layer, Proteus UI conventions), then the coordinator wrote the contract files, then implementation agents on disjoint file sets. Gated centrally once, every diff read by the coordinator, then verified in Chromium at 1440×900 and 390×844.

**What shipped:**

- **Three-row Atlas layout** — `JobDetailRow` reproduces Atlas's `6.25rem` uppercase label column with a hairline under rows 1 and 2 only.
- **Case row** — case short name linking to case detail, `Case ID:` / `Case number:` with bold inline labels, and a restriction badge for levels 1 and 2 (`Restricted` / `Restricted: U.S. Only`) with an `EyeOff` icon.
- **Job row** — large plain job number (Atlas does not link it on this page), the count pill, and the `Job Date` line using `formatJobDateTime`.
- **Count pill** — `proceedingCountLabel` reproduces Atlas's **missing singular** verbatim: one proceeding renders as `1 proceedings`. Zero renders `No proceedings` using `variant="outline"`; `secondary` is the brightest badge in this theme and can never be a muted state.
- **Proceedings list** — name-only rows, full-row click to proceeding detail, no empty-state text (the grey pill is Atlas's only zero signal). Deliberately **not** built on the shared `ProceedingList`/`ProceedingRow`, which render a date block, gavel chip, status and meta that Atlas does not show here — reusing them would have been a redesign.
- **Add proceeding** — right-side drawer, 1–20 repeatable name rows with 1-based numbering, per-row remove (disabled at one row), `Add another proceeding` (disabled at 20 with the cap hint), react-hook-form + `useFieldArray` + Zod. All five Atlas validation rules in Atlas's first-failure-wins precedence. 409/400/other are discriminated by HTTP status and surfaced inline.
- **Mock lane** — `GET jobs/:jobId/detail`, `GET jobs/:jobId/proceedings`, `POST jobs/:jobId/proceedings` inserted ahead of the `jobs/:jobId` catch-all; session-local `addJobProceedings`; the POST returns a real **409** when a submitted name already exists on the job, so Atlas's duplicate warning is demoable.

**Coordinator corrections to agent output** (each invisible to the agent, which was instructed not to run gates):

- **Dead breadcrumb link.** `JobDetailView` used `render={<Link/>}` on a `BreadcrumbLink`, which supports only `asChild` — the case breadcrumb would have rendered an `<a>` with no `href`.
- **Two screens disagreeing about one job.** The data agent added the demo extra proceedings only to the Job Details store to avoid changing the Jobs tab, so the same job showed 3 proceedings on one screen and 1 on the other. `getCaseJobsByCaseId` now reads the same live per-job list, with the restricted-placeholder substitution preserved.
- **Stale Jobs tab after an add.** The mutation invalidated only the job-proceedings key, so the Case Details Jobs tab kept its pre-add list across a client-side navigation. `CASE_JOBS_QUERY_KEY` was promoted to `src/constants/query.ts` (a cross-page import would have been forbidden) and is now invalidated too.
- **Banned import.** Both `useCreateJobProceedings` and `AddProceedingDrawer` imported `isHttpStatusError` from `@/lib/http`, which ESLint forbids under `src/pages/**`. The repo's sanctioned wrapper `@/hooks/isHttpStatusError` is what `useCaseDetail` already uses. **This was the coordinator's own error** — the agent prompts specified the banned path, and one agent flagged it rather than silently disabling the rule.
- **Button parity.** The "New proceeding" trigger shipped as a plain outline button; Atlas renders a flat primary button with an `add` icon.
- Duplicate `@/api` type import in `JobCaseInfo.tsx`; two auto-fixable lint errors cleared with `lint:fix`.

**Deliberate departures from Atlas (recorded):**

- **Dangling `@`.** Atlas concatenates unconditionally and renders `" @ "` with blanks when `startTime` is missing; we omit the segment. Preserves the PRDV-16936 decision. Verified on job `999000`, which renders `09 / 18 / 2026`.
- **Toasts → inline alerts.** Atlas raises add-proceeding success/conflict/failure as `vue3-toastify` toasts. No toast library exists here and adding a dependency is forbidden, so the same copy renders inline: success above the list, failures inside the drawer. Copy is unchanged.
- **No access-denied variant.** Atlas swaps the whole proceedings list for a `Restricted` placeholder when the viewer lacks access. The prototype's persona is permissive, so the list always renders; the restriction badge still demos levels 1 and 2.

**Verified in Chromium** (1440×900 and 390×844, **0 console errors, 0 page errors** across every flow):

- `/jobs/104809` — three rows, case link, `Case ID: 1`, `Case number: No. 24-PR-5073`, `3 proceedings`, `12 / 02 / 2026 @ 3:00 PM`, three named proceedings.
- All five validation rules fire with Atlas's exact copy, in precedence order.
- **409** against an existing name shows the duplicate warning and keeps the drawer open with input intact.
- Successful save closes the drawer, shows `Successfully added 1 proceeding` / `2 proceedings` (correct plural), and updates both list and pill.
- Cross-screen consistency via client-side navigation: a proceeding added on Job Details appears on the Case Details Jobs tab, and the job-number link navigates back to the real Job Details page.
- Zero state `/jobs/999000` — `No proceedings`, transparent `outline` badge, empty list.
- 20-row cap — add disabled, cap hint shown, rows numbered 1–20.

- **Gates:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | `proteus-front-end` worktree | **fail (exit 1)** | 2 high (`fast-uri`, `js-yaml`) + 2 moderate (`hono`, `qs`), all transitive. **Pre-existing, not introduced here** — `package-lock.json` is byte-for-byte unchanged and `npm ci` installed from it. Per `git-commit-workflow` this is a hard STOP before commit; awaiting user triage or waiver. |
| lint | `npm run lint` (after `npm run lint:fix`) | `eslint "src/**/*.{ts,tsx}"` | pass (exit 0) | — |
| type-check | `npm run type-check` (`tsc -b`) | worktree | pass (exit 0) | — |
| build | `npm run build` | worktree | pass (exit 0) | pre-existing >500 kB chunk-size warning only, unrelated |
| browser | Playwright/Chromium 1228, 1440×900 + 390×844 | `/jobs/*`, `/cases/1`, `/cases`, `/schedule` | pass | 0 console errors, 0 page errors |

- **Tests added/updated:** none — **exception applies.** The repo has no runnable harness (`test:unit:ci` is a stub; zero `*.spec.*`/`*.test.*` under `src/`) and the ticket scopes automated tests as intentionally light. Behavior was verified end-to-end in a browser instead (above). Residual risk: no regression net for the Zod precedence chain, `proceedingCountLabel`'s plural rule, or `formatJobDateTime`. Smallest follow-up that would unlock coverage: wire a Vitest config for `src/pages/JobDetail/**` and start with those three pure functions.
- **API docs — not relevant:** this repo exposes no Swagger/OpenAPI surface. Checked: no `swagger`/`@Api` helpers anywhere in `proteus-front-end`; the only "API" here is the in-repo mock adapter, whose new routes are recorded above.
- **Regression impact:** three shared surfaces were touched. `src/lib/time.ts` (additive export only), `src/constants/query.ts` (additive export), and `src/pages/CaseDetail/hooks/useCaseJobs.ts` (imports the promoted key; behavior identical). `getCaseJobsByCaseId` now reads the live per-job list — verified on `/cases/1` that the Jobs tab still renders every job, date, and proceeding link, and that the restricted demo case still substitutes its placeholder.
- **Commits:** none — blocked by the failing audit gate above.

---

## Attempt history

### Attempt 1 — building in the shared `proteus-front-end` checkout (superseded 2026-09-17)

Work started on branch `PRDV-16934` in the main checkout. Mid-run, a second writer editing that same checkout reverted the `formatJobDateTime` addition to `src/lib/time.ts` and rewrote `CaseJobsPanel.tsx`, and added `SortableTableHead.tsx` / `useTableSort.ts` — none of which belonged to this ticket. A branch is not an isolation boundary: one checkout has one working tree, so concurrent sessions overwrite each other's files regardless of branch. Moved to a dedicated worktree at `proteus-worktrees/PRDV-16934`; only this ticket's files were carried over and the other writer's work was left untouched in the main checkout.

Two implementation agents also died mid-task in that checkout, each missing its primary file (`JobDetailPage.tsx`, `AddProceedingDrawer.tsx`); both were completed in the worktree.

**Branch-name note:** `PRDV-16934` remains checked out in the main repo, and git refuses the same branch in two worktrees. Freeing it would have moved the other writer's uncommitted work onto a different branch, so the worktree branch is `PRDV-16934-job-detail`. Commit subjects still carry the `PRDV-16934 ` prefix.

---

## Key technical learnings

- **A unique branch does not prevent a collision; a unique worktree does.** Branches version history, not the working tree. Two sessions in one checkout write the same files on disk whatever branch each is on.
- **`page.goto` resets mock state.** A full reload re-evaluates `fixtures.ts`, discarding every session-local mutation. Cross-screen mock behavior can only be tested through client-side navigation — a `goto` made a working consistency fix look broken.
- **Agents cannot catch what gates catch, and gates cannot catch what a browser catches.** The banned-import violation and the dead breadcrumb needed the gate; the stale Jobs-tab cache needed the browser. Neither was visible in an agent's self-report.
- **A "safe" choice can create the defect.** Keeping the demo proceedings out of the Jobs tab avoided changing existing output, and by doing so made two screens contradict each other about the same job — worse, in a tool whose entire purpose is side-by-side demos.
- **Measure the baseline before calling it a defect.** Job Details shows 571px horizontal extent at 390px — identical to `/cases`, `/cases/1` and `/schedule`. It is the app shell header, pre-existing, not this page.

---

## Current state (as of 2026-09-18)

- **Merged locally into `prototype-main`** (fast-forward to `e86964b`), which is **2 commits ahead of `origin/prototype-main`** (`0c8fa3c`). **Nothing pushed; no fetch or pull run.**
- Branch `PRDV-16934-job-detail` holds the two commits: `388e649` (build) and `e86964b` (PR-review-pattern fixes). Worktree `proteus-worktrees/PRDV-16934` still exists and can be removed once the merge is confirmed good.
- Every ticket AC is satisfied on the running page, verified post-merge in a browser. All eight PR-review patterns are addressed.
- Open items: the three recorded deliberate Atlas departures, the one known minor (count pill during a proceedings error), and the waived audit advisories.

---

## New code introduced

| Path | What |
| ---- | ---- |
| `src/pages/JobDetail/JobDetailPage.tsx` | Thin route shell |
| `src/pages/JobDetail/components/JobDetailView.tsx` | Page composition: breadcrumb, three rows, success alert, drawer wiring |
| `src/pages/JobDetail/components/JobDetailRow.tsx` | Atlas's `6.25rem` label column + content, optional hairline |
| `src/pages/JobDetail/components/JobCaseInfo.tsx` | Case link, Case ID / Case number, restriction badge |
| `src/pages/JobDetail/components/JobInfo.tsx` | Job number, count pill, `Job Date` line |
| `src/pages/JobDetail/components/ProceedingCountPill.tsx` | Count badge; `outline` at zero |
| `src/pages/JobDetail/components/JobProceedingList.tsx` | Name-only clickable proceedings list |
| `src/pages/JobDetail/components/AddProceedingDrawer.tsx` | Right-side 1–20 row add-proceeding form |
| `src/pages/JobDetail/schemas/addProceedingsFormSchema.ts` | Zod schema reproducing Atlas's rule precedence |
| `src/pages/JobDetail/hooks/{useJobDetail,useJobProceedings,useCreateJobProceedings}.ts` | Queries + create mutation with invalidation |
| `src/pages/JobDetail/constants.ts` | Every user-visible string and limit, verbatim from Atlas i18n |
| `src/api/jobs/jobs.types.ts` | `JobDetail`, `JobProceeding`, `CreateJobProceedingsParams` |
| `src/lib/time.ts` | `formatJobDateTime` (`MM / dd / yyyy @ h:mm a`) |
| `src/constants/query.ts` | `CASE_JOBS_QUERY_KEY`, promoted for cross-page invalidation |
