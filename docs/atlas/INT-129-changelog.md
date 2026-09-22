# INT-129 — Atlas Prototype: Case Home page

## Ticket

- **Ticket:** INT-129
- **Repo:** `proteus-front-end` (product-authoring lane; ships the Atlas UI in React/shadcn)
- **Branch:** `INT-129`, cut from `prototype-main` at `4a76fa9b365eb7995c0b44a2d93dbde9ba402d44`
- **PR:** none — per the prototype lane, the branch is tested standalone and never merged
- **Reference (read-only):** `atlas-front-end` (visual/behavioral source of truth), `callisto-back-end` (response shapes only)
- **Artifacts:** [INT-129/](INT-129/) — original ticket
- **Precedent followed:** [PRDV-16936-changelog.md](PRDV-16936-changelog.md) (Case Details prototype) — same premise, same multi-agent method

---

## Requirements (verbatim)

_Paste from ClickUp, spec, or the user's first description. Do not paraphrase on first capture._

> As a Product Manager, I want a realistic, clickable prototype of the existing **Atlas Case Home page**, so that I can quickly create and iterate designs for new and upcoming features for stakeholders using components that will be consistent with our upcoming shadcn/react refactor work.
>
> * * *
>
> ## Acceptance Criteria
>
> -   Prototype includes the following
>     -   Home page with existing copy
>     -   Roughly the same design as existing Atlas

---

## Context

- Speed and functional completeness over polish. This is a facade for product design — no backend, no auth, no permissions.
- Atlas is the visual source of truth. Departures are allowed only where a Proteus shell constraint, semantic token, accessibility need, or missing shadcn behavior forces one — and each must be recorded.
- `prototype-main` already carried three finished pages when this branch was cut: Case Details (PRDV-16936), Job Details (PRDV-16934), Proceeding Details (PRDV-16935). This ticket built on that shell rather than greenfield.

---

## Scope finding — "Case Home" is the Atlas landing page

**There is no page called "Case Home" in Atlas.** Verified: no file, route, or i18n key matching `CaseHome` / `case-home` exists anywhere in `atlas-front-end`. The Callisto pages are `HomePage`, `SearchPage`, `CaseDetailPage`, `CaseMergePage`, `MyJobsPage`, `JobProceedingPages`, `JobSubmissionPages`, `NotificationsPages`.

The evidence resolves to `src/callisto/pages/HomePage/HomePage.vue`:

- It renders at both `/` and `/callisto-stuff`; the route name for the latter is `callisto-home`, and the rail item that reaches it is labeled **File Navigator**. Callisto is the case system, so "Case Home" maps to that page.
- Its copy is case-centric ("searching for a job number or case name"), matching the ticket's phrasing.
- In Proteus it was the only unported "home": `src/pages/Home/HomePage.tsx` was a 3-line stub and was **not routed** — the index route did `<Navigate replace to="/cases" />`. `docs/parity.md` recorded it as `Home / landing | Live | Stub | … open for a POC`, and listed **Home** as POC candidate #1.

The Atlas page body is three lines of text with no data fetching, no composable, no store, no table, and no clickable element of its own. Its only call to action points at the header search bar. That determined the shape of the work: port the body faithfully, route it, and bring the search bar the copy points at to Atlas parity.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-21 | Coordinator-authored architecture (this session, recorded below) | `implemented` | Two file-ownership-disjoint build agents (Home page body; global-search parity) plus coordinator-owned router/brand/parity-doc edits, then one central gate and a browser verification pass. |

---

## Session log

### 2026-09-21T18:20:00Z — proteus-front-end — second review pass: Jobs search, rail navigation, editorial cleanup

- **Scope determination first.** The reviewer confirmed that, strictly against INT-129's acceptance criteria, the implementation **passes**: Home renders at `/`, the Atlas copy is exact, the structure roughly matches, and Proteus architecture/styling rules are followed. The job-results, rail-navigation, and search-history findings came from the broader "realistic, clickable prototype" intent, not the AC, and are **parity observations rather than blockers**. The **search-history finding was explicitly withdrawn as out of scope** mid-flight; the agent carrying it had only read `GlobalSearch.tsx`, never edited it, so `replace: isOnSearchPage` survives untouched (verified: still present, and Back after two searches returns to `/`, not the prior query). The missing PR artifact is a review-process limitation, not an implementation defect — and it is downstream of the audit gate, which is what actually blocks the commit.

- **Problem:** The Home copy directs users to search by job number, but search had no Jobs results at all — Atlas has **Jobs** and **Cases** tabs whose job rows link to Job Detail (`SearchPage/tabs.ts` is `[{value:'jobs'},{value:'cases'}]`), while Proteus had Proceedings and Cases with Cases as the default, so a job-number search opened on an empty tab. Separately, the File Navigator rail item routed to `/cases` and left the new Home page with no active rail item.
- **Requirement:** A job number typed into the header must produce Atlas-shaped job results that link to Job Detail, and the primary rail item must lead to and activate on Home as it does in Atlas.
- **Solution:** Three agents on disjoint file sets — jobs data layer, Jobs tab UI, navigation and editorial cleanup — then coordinator corrections and central verification.

**File ownership split:**

| Owner | Files |
| ----- | ----- |
| Agent A | `src/api/jobs/jobs.types.ts`, `src/api/jobs/jobs.api.ts`, `src/api/index.ts`, `src/mocks/fixtures.ts`, `src/mocks/routes.ts` |
| Agent B | `src/pages/Search/types.ts`, `constants.ts`, `components/SearchView.tsx`, `components/SearchJobsTable.tsx` (new), `hooks/useSearchJobs.ts` (new) |
| Agent C | `src/app/layouts/AppShell/constants.ts`, `src/pages/Search/hooks/useSearchQuery.ts`, `docs/parity.md` |

**Shipped:**

- **Jobs search, end to end.** New `JobSearchResult` / `JobSearchResponse` types and `jobsApi.search`, backed by a `GET jobs/search` mock route placed ahead of the `jobs/:jobId` catch-all. The fixture function reuses the existing `getJobDetailByJobId` and `getJobProceedingsByJobId` resolvers rather than introducing a parallel dataset, and touches no PRNG call, so the seeded demo data is unchanged. The haystack covers job number, case name, case number, and proceeding names.
- **Jobs tab, leading and default.** Tabs now read **Jobs, Cases, Proceedings** with Jobs selected on arrival. The table carries Atlas's four columns in order — Job number, Job date, Proceedings, Case name — with the job number linking to Job Detail and each proceeding to Proceeding Detail.
- **File Navigator routes to Home** (`RoutePaths.HOME`) and activates there, while keeping its highlight on the Cases routes.
- **Editorial cleanup on touched files:** the `useSearchQuery` doc comment no longer claims the header "owns the debounce" (removed earlier on this branch); `docs/parity.md` now reports Job detail as `Mock-ready` and describes the real search tabs. Agent C correctly declined to edit the "Deliberately different → Search tabs" bullet as out of its brief but flagged it; the coordinator fixed it.

**Coordinator corrections:**

- **Fixed an accessibility defect the rail change introduced.** `SidebarNav` used react-router's `NavLink`, which computes `aria-current` from its own `to` match and overrides the explicit prop. With `to="/"`, File Navigator on `/cases` was **visually active** (`bg-accent`, measured `rgb(237,238,241)`) but reported `aria-current: null` — sighted and screen-reader users got different answers. Previously the two agreed only because `to` happened to be `/cases`. Swapped to `Link`, since the component already computes `activeItemId` itself and used no other `NavLink` behavior. Re-measured: `aria-current="page"` on `/`, `/cases`, `/cases/1`, absent elsewhere, matching the visual state exactly.
- **Copy left stale by tab addition.** The Search empty state still read "Search cases and proceedings" and the header input's `aria-label` likewise; both now name jobs. Agent B had flagged the first rather than reaching outside its file list.
- **My own error, recorded.** I ran `npx prettier --write "src/**/*.{ts,tsx}"` instead of the changed-file list, which rewrote line endings across the tree and left ~100 files showing as modified. `git diff --numstat` confirms **17 files have real content changes** and the rest are 0-added/0-deleted — the known `core.autocrlf` artifact. No content was lost, but it reinforces the standing rule: **stage explicit paths, never `git add -A`.**

**Verification — Chromium 1440×900, 0 console errors, 0 page errors:**

| Check | Result |
| ----- | ------ |
| Tab order and default | pass — `Jobs 1 / Cases 0 / Proceedings 1`, Jobs selected |
| Job-number search returns a job row | pass — `104809 · 12 / 05 / 2026 @ 3:00 PM · 3 proceedings · In re Bauer Estate · Case Number: No. 24-PR-5073` |
| Atlas column set and order | pass — Job number, Job date, Proceedings, Case name |
| Job number links to Job Detail | pass — `/jobs/104809` |
| Proceedings link to Proceeding Detail | pass — `/proceedings/604809`, `/700001`, `/700002` |
| Case-name search unaffected | pass — `q=bauer` → Jobs 14, Cases 1, Proceedings 13 |
| File Navigator → Home, active there | pass — `href="/"`, `aria-current="page"` |
| Rail highlight retained on Cases routes | pass — after the `Link` fix |
| All three rail destinations navigate | pass — `/`, `/schedule`, `/legacy-drives` |
| Withdrawn history finding not applied | pass — Back after two searches returns `/`, confirming `replace` intact |
| 11-route regression sweep | pass — every route renders, 0 new errors |

**Gates:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | `proteus-front-end` | **fail — exit 1** | Same 4 pre-existing advisories; no dependency or lockfile change on this branch. Still blocks the commit. |
| lint | `npm run lint` | `proteus-front-end` | pass — exit 0 | — |
| type-check | `npm run type-check` | `proteus-front-end` | pass — exit 0 | — |
| build | `npm run build` | `proteus-front-end` | pass — exit 0 | pre-existing >500 kB chunk warning only |
| browser | Playwright/Chromium 1440×900 | table above | pass | 0 console errors, 0 page errors |

- **Tests added/updated:** none — same standing exception (no harness). Residual risk grew again: `jobsApi.search`, the `jobs/search` mock filter, `getJobSearchResults`, and the rail's `activeRailItemId` branches are all uncovered.
- **Commits:** none — still blocked by the audit gate.

### 2026-09-21T17:34:00Z — proteus-front-end — review fixes: explicit search submission, Atlas minimum, job-number results, Escape scoping

- **Problem:** A review pass against Atlas found six behavioral divergences in the work from the prior entry. Two were real defects rather than polish: the header search never returned anything for a job number even though the Home copy and the placeholder both advertise it, and pressing Escape in the header search also cleared the Case Files selection.
- **Requirement:** The global search must submit only on explicit user action the way Atlas does, accept Atlas's two-character minimum, return results for the job numbers it advertises, and confine its keyboard handling to itself.
- **Solution:** Two agents on disjoint file sets, plus coordinator corrections and a central gate.

**File ownership split:**

| Owner | Files |
| ----- | ----- |
| Agent A | `src/components/SearchInput.tsx`, `src/app/layouts/AppShell/components/GlobalSearch.tsx` |
| Agent B | `src/constants/search.ts`, `src/pages/Search/hooks/useSearchQuery.ts`, `src/pages/Search/components/SearchView.tsx`, `src/mocks/routes.ts` |

**Shipped:**

- **The search icon is a real submit button.** `SearchInput` gained an optional `onSubmit`; when supplied it renders a focusable `<button type="button" aria-label="Search">` in place of the `pointer-events-none` decorative icon. Consumers that omit the prop (the Cases page filter) render exactly as before — verified: `/cases` still has no `button[aria-label="Search"]`.
- **Navigation is now explicit only.** The 600 ms debounced auto-navigate effect is gone. One `submitSearch` handler holds the length check and the `navigate` call; Enter and the button both call it, with no duplicated logic. Verified: typing and waiting 1400 ms stays on `/`; Enter and the button each navigate.
- **Two-character minimum,** matching Atlas's `filter.value.length > 1`.
- **Job numbers return results.** The `jobs/proceedings-witnesses` mock route now includes `jobId` in its `matches()` haystack. Verified: `/search?q=104809` returns a Proceedings match where it previously returned none.
- **Escape is scoped to the input.** It now calls `preventDefault()` (blocking the native `<input type="search">` clear, which would desync the controlled value) and `stopPropagation()` (blocking the document-level listener at `CaseFilesSelectedActionsBar.tsx:43`), then blurs.
- **`/` is inert while a dialog is open,** and bails on `event.defaultPrevented`.
- **Keyboard literals are named:** `GLOBAL_SEARCH_SHORTCUT_KEY`, `SEARCH_SUBMIT_KEY`, `SEARCH_DISMISS_KEY`, `OPEN_DIALOG_SELECTOR`, and a `TYPING_ELEMENT_TAG_NAMES` set, following the `DESELECT_ALL_SHORTCUT_KEY` precedent.

**Coordinator decisions and corrections:**

- **`SEARCH_MIN_LENGTH` was not lowered to 2.** It is shared: `useQuerySearch.ts:20` uses it as the default for page-local filters, including the Cases page search box. Changing it would have silently altered an unrelated screen. Added a separate `GLOBAL_SEARCH_MIN_LENGTH = 2` used by the header, the Search page gate, and the Search page's minimum-length message; `SEARCH_MIN_LENGTH` stays 3 for page-local filters. Two distinct scenarios, two constants.
- **The overlay guard selector was measured, not guessed.** Opened a real drawer and dumped the DOM: vaul's `data-slot="drawer-content"` carries `role="dialog"` and `data-state="open"`. Confirmed `[role="dialog"][data-state="open"], [role="alertdialog"][data-state="open"]` returns **0** matches across seven routes with nothing open, so the guard cannot permanently disable the shortcut.
- Reformatted two over-width lines and one hand-wrapped call that Prettier would have collapsed (agents cannot run the formatter).

**Verification — Chromium 1440×900, 0 console errors, 0 page errors:**

| Check | Result |
| ----- | ------ |
| Submit button is a real `<button type="button">`, `pointer-events: auto` | pass |
| Typing + 1400 ms does not navigate | pass — stays on `/` |
| Button click submits; Enter submits | pass — `/search?q=smith`, `/search?q=bauer` |
| 2 chars submit; 1 char does not | pass |
| Search page message reads "Enter at least 2 characters to search" | pass |
| `/search?q=104809` returns a Proceedings result | pass — 1 match |
| Escape preserves typed text **and** the Case Files selection | pass — value `"hello"` kept, checked 1 → 1, focus blurred |
| `/` while a drawer is open does not steal focus | pass — focus stayed in the dialog |
| `/` still focuses the header search on a normal page | pass |
| Cases page icon remains decorative (shared component unaffected) | pass |

- **Note on the job-number result count:** `/search?q=104809` returns **1** proceeding while the Job Detail page shows "3 proceedings" for the same job. That is not a defect in this fix — `PROCEEDINGS` (the witness-search dataset) carries one row per job (`fixtures.ts:481`, `:505`), while Job Detail reads a separate set via `getJobProceedingsByJobId` (`fixtures.ts:1081`). Pre-existing fixture modelling, untouched here.

**Gates:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | `proteus-front-end` | **fail — exit 1** | Same 4 pre-existing advisories as the prior entry; no dependency or lockfile change on this branch. Still blocks the commit. |
| lint | `npm run lint` | `proteus-front-end` | pass — exit 0 | — |
| type-check | `npm run type-check` | `proteus-front-end` | pass — exit 0 | — |
| build | `npm run build` | `proteus-front-end` | pass — exit 0 | pre-existing >500 kB chunk warning only |
| browser | Playwright/Chromium 1440×900 | table above | pass | 0 console errors, 0 page errors |

**Assessed but deliberately not changed** (review items 9–11, 12–13):

- **Home typography** (Atlas ~34px/700 + 14px body vs Proteus 30px/600 + 16px body) — left as-is. The review states the current version satisfies "roughly the same design", and closer matching was not requested.
- **Page spacing** (Atlas ~16px below the header vs the shell's `py-8`) — left as-is. `AppShell/index.tsx:23` is global, so changing it would move every Proteus screen, and no live Atlas instance was available to establish that a page-specific override is warranted.
- **Search focus/outline/clear styling** — kept on the Proteus design system; no Quasar styling imported.
- **No i18n infrastructure introduced.** Copy stays in `src/pages/Home/constants.ts`; the repo has no i18n dependency and adopting one is a repository-level decision, not an INT-129 task.
- Preserved per instruction: the exact Atlas copy, `/` → `HomePage`, brand → `/`, `HomePage` as a thin shell, `HomeView`/constants page-local, semantic tokens, and no data-fetching hook for static copy.

- **Tests added/updated:** none — same exception as the prior entry (no harness; `test:unit:ci` is a stub). Residual risk is now larger: the `/` overlay guard, the Escape propagation stop, and the single-submit path are all behavioral branches with no regression net. Smallest follow-up: a Vitest config covering `GlobalSearch`'s keydown handler and `submitSearch`.
- **Commits:** none — still blocked by the audit gate.

### 2026-09-21T16:51:29Z — proteus-front-end — Home page port, routing, and search parity

- **Problem:** Proteus had no landing page. The index route redirected to `/cases` — "My Cases", a browsable list **Atlas does not have** (`docs/parity.md` records it as Proteus-only). A PM opening the prototype never saw an Atlas-equivalent home, so there was no faithful surface to iterate new home-page features on.
- **Requirement:** Opening Proteus at `/` must present the Atlas landing screen — its exact copy and typographic hierarchy, inside chrome that behaves the way Atlas's does — without breaking any existing route, page, or shared component.
- **Solution:** Built out `src/pages/Home/`, routed it at `/`, pointed the brand logo at it, and closed the header-search parity gaps the page's own copy depends on.

**Method:** Two read-only exploration agents mapped the Atlas page and the Proteus conventions. The coordinator then read the Proteus shell first-hand (on this page the chrome *is* the screen), wrote the architecture, and fanned out two build agents split by **exclusive file ownership**, each told explicitly to run no git and no npm commands. Gated centrally once, read every diff, then verified in Chromium.

**File ownership split (disjoint, zero collisions):**

| Owner | Files |
| ----- | ----- |
| Agent A | `src/pages/Home/HomePage.tsx`, `src/pages/Home/components/HomeView.tsx`, `src/pages/Home/constants.ts` |
| Agent B | `src/app/layouts/AppShell/components/GlobalSearch.tsx`, `src/components/SearchInput.tsx` |
| Coordinator | `src/app/router/index.tsx`, `src/app/layouts/AppShell/components/BrandLink.tsx`, `docs/parity.md` |

**Shipped:**

- **Home page body** carries the Atlas copy verbatim — `Welcome to Atlas` / `Our new home for managing files.` / `**Get started** by searching for a job number or case name above.` Copy lives in `src/pages/Home/constants.ts` as an `as const` object, matching the repo's convention of keeping user-facing strings in the page's constants file.
- **`/` now renders the Home page.** The index route's `<Navigate replace to={RoutePaths.CASES} />` is gone. This also changes where login lands (`useLogin.ts:68` and `LoginPage.tsx:15` both target `RoutePaths.HOME`) and where the 404 page's "Back to home" goes — both now reach the real landing page, matching Atlas.
- **Brand logo points at `/`**, matching Atlas, where the logo's `to="/"` renders `HomePage`. Its `aria-label` changed from "Atlas — File Navigator" to "Atlas — home" to match the new destination.
- **Global search brought to Atlas parity.** Placeholder is now Atlas's own copy (i18n `common.callisto.search.placeholder`): "Search by job number, case number, case name, or proceeding name". Added `/` to focus the field from anywhere, `Esc` to blur, and `Enter` to submit immediately — measured at **12 ms**, bypassing the 600 ms debounce.
- **`SearchInput` gained two optional props** (`inputRef`, `onKeyDown`), additive only. Every existing consumer renders unchanged.

**Coordinator correction to subagent output** (invisible to the agent, which was instructed not to run gates):

- Agent B bound Escape/Enter with `input.addEventListener('keydown', …)` inside a `useEffect` whose deps included `query` — re-attaching a DOM listener on every keystroke. It read the packet's "the `inputRef` addition is the only change" wording literally and concluded it could not add an `onKeyDown` prop, even though the same packet specified `onKeyDown` by name. Replaced with a plain `onKeyDown` handler passed through `SearchInput`, removing one effect and the per-keystroke listener churn. The agent flagged the deviation itself rather than hiding it, which is what made the correction cheap.

**Deliberate departures from Atlas (each recorded, none accidental):**

- **Heading is `text-3xl font-semibold` (30px/600), not Atlas's 34px/700.** Atlas renders a Quasar `h4` wrapped in `<strong>`. `DESIGN.md` states "Avoid `font-bold` in product UI — the brand reserves it for marketing headlines", and the Proteus type scale has no 34px step. Measured result: `fontSize 30px, fontWeight 600, marginBottom 8px` — the 8px matches Atlas's `.title { margin-bottom: 0.5rem }` exactly.
- **File Navigator still points at `/cases`, not `/`.** In Atlas it lands on the welcome page because Atlas has no cases list. Repointing it in Proteus would orphan the Proteus-only Cases list, which other surfaces reach through. `activeRailItemId` is untouched, so no rail item is active on `/`.
- **Debounce-to-navigate kept.** `/search` depends on live filtering as you type; Enter was added *alongside* it, never as a replacement.
- **`SEARCH_MIN_LENGTH` stays 3** where Atlas requires >1 — it is a shared constant other pages read. Verified: Enter with a 2-character query does not navigate.
- **No clear ("x") button.** Atlas's `clearable` is a Quasar affordance; adding one would have meant changing shared `SearchInput` markup for every consumer.
- **Input is not cleared after submit** as Atlas does — the Proteus input mirrors `?q=` back from the URL, so clearing would fight that sync.

**Verification — Chromium, 1440×900 and 390×844:**

- Home copy is byte-identical to `HomePage.vue:7-12`.
- `/` focuses the search field and does **not** type the slash; `Esc` blurs; `Enter` navigates in 12 ms.
- `/` does **not** hijack while typing in another input — typing `a/b` into the Cases search yields `a/b`.
- Logo click from `/cases` returns to `/`. 404 "Back to home" reaches "Welcome to Atlas". `/login` lands on `/`.
- Regression sweep across `/cases`, `/cases/1`, `/schedule`, `/invoices`, `/search?q=…`, `/legacy-drives`, `/jobs/104809`, `/proceedings/604809`: all render, **0 console errors, 0 page errors**.

**Gates:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | `proteus-front-end` | **fail — exit 1** | 4 advisories (2 high: `fast-uri` via `hono`, `js-yaml`; 2 moderate: `qs`). **All pre-existing** — `git diff prototype-main...HEAD -- package.json package-lock.json` is empty, so this branch changed no dependency or lockfile. Per `git-commit-workflow` a non-zero audit **blocks the commit**; work is left uncommitted pending triage or waiver. |
| lint | `npm run lint` | `proteus-front-end` (`eslint "src/**/*.{ts,tsx}"`) | pass — exit 0 | — |
| type-check | `npm run type-check` (`tsc -b`) | `proteus-front-end` | pass — exit 0 | — |
| build | `npm run build` | `proteus-front-end` | pass — exit 0 | pre-existing >500 kB chunk-size warning only, unrelated |
| browser | Playwright/Chromium 1440×900 + 390×844 | 11 routes (listed above) | pass | 0 console errors, 0 page errors |

- **Tests added/updated:** none — **exception applies.** The repo has no runnable harness (`test:unit:ci` is `echo 'Skipping tests for now'`; zero `*.spec.*`/`*.test.*` under `src/`), and the prototype lane scopes automated tests as intentionally light. Behavior was verified end-to-end in a real browser instead. Residual risk: no regression net for the `/`-focus guard (the branch that ignores the key while another input is focused) or the Enter-submit minimum-length branch. Smallest follow-up that would unlock coverage: wire a Vitest config and start with `GlobalSearch`'s keydown handler.
- **API docs — not relevant.** No HTTP surface changed: no file under `src/api/**` or `src/mocks/**` was touched, and the Atlas page fetches nothing (`HomePage.vue` has no `<script>` data, no composable, no store). Checked surface: `src/api/` and `src/mocks/routes.ts` are byte-unchanged on this branch.
- **Regression impact:** the shell is shared, so `SearchInput` and `BrandLink` were the risk. Both changes are additive (two optional props; one `to` target), and the eleven-route browser sweep above is the evidence that adjacent pages still render clean.
- **Commits:** none — blocked by the audit gate above.

---

## Attempt history

_None. No approach was abandoned this session._

---

## Pre-existing issues observed but NOT fixed (out of scope for INT-129)

Found during the regression sweep. None are caused by this branch; recording them so they are not rediscovered.

- **Dead proceeding links on the Case Details Jobs tab.** `/cases/1?tab=jobs` renders links to `/proceedings/700001` and `/proceedings/700002`, which do not exist in the fixtures. `ProceedingDetailPageContent.tsx:41-42` then redirects to `/cases` on not-found, so the click silently bounces the user to the cases list. Fixture gap from PRDV-16936/16935.
- **Job Detail renders no heading element.** `/jobs/104809` renders its content correctly but has no `h1`/`h2`/`h3` — the page title is a styled non-heading element. Accessibility gap from PRDV-16934.
- **Shell does not collapse at narrow viewports.** At 390px the document `scrollWidth` is **571** on *every* route (`/`, `/cases`, `/schedule`, `/invoices`, `/legacy-drives`), because the 248px sidebar stays fixed. This matches the 571 baseline already recorded in the PRDV-16936 changelog — it is the shell's behavior, not this page's. The Home page's own `main` is the narrowest of all measured (143px).
- **`docs/parity.md` rows are stale for other tickets.** `Job detail` still reads `Not started` although PRDV-16934 landed it on `prototype-main`. Left alone to keep this diff minimal; only the `Home / landing` row was updated.

---

## Key technical learnings

- **"Case Home" does not exist in Atlas.** Anyone picking up a follow-on ticket in this family should expect ticket page names to be product shorthand, not file names — resolve them against the router and the rail labels before planning. Here, "Case Home" → `HomePage.vue`, reached by the **File Navigator** rail item.
- **When the page body is three lines, the chrome is the deliverable.** The Atlas landing page's only call to action is a sentence pointing at the header search bar, which made search-bar parity the substance of the ticket rather than scope creep. Reading the Proteus shell first-hand — not via an agent summary — was what made that scope call possible.
- **An over-literal ownership constraint can push an agent into a worse implementation.** Telling Agent B that `inputRef` was "the only change" to a shared file led it to reject the `onKeyDown` prop the same packet named, and hand back a per-keystroke `addEventListener`. Packets should state the *intent* of a file-ownership boundary ("do not change behavior for other consumers"), not only a literal edit whitelist.
- **The environment did not match the brief's assumption about port 9000.** The brief says port 9000 is the Atlas Vue app and Proteus bumps to 9001. In this session **both** 9000 and 9001 served Proteus (verified: react-refresh + `/src/main.tsx`, both resolving the same working tree). Atlas was not running, so a live side-by-side comparison was not possible; parity was established against the Atlas source files instead.
- **The ~175-file `core.autocrlf` artifact did not appear.** `git status --short` listed exactly the 8 intended paths. Explicit-path staging is still correct, but the working tree was clean here.

---

## Current state (as of 2026-09-21)

- **Shipped.** `INT-129` was committed as `5343547fa8bb5570b952fc5e008cb985d7b936be` (22 paths, 401 insertions / 54 deletions), fast-forward merged into `prototype-main`, and pushed. Local and `origin/prototype-main` both sit at that SHA. No PR, per the user's instruction.
- The user **waived the failing audit gate** by instructing the merge and push directly. The four advisories remain unaddressed and pre-existing; no dependency or lockfile changed on this branch.
- Both acceptance criteria are satisfied, confirmed by the reviewer. Beyond the AC, the branch also shipped an Atlas-shaped Jobs search and Atlas rail navigation.
- Lint, type-check, build and every browser sweep were green at merge time. The husky/lint-staged pre-commit hook re-ran type-check, `lint:fix` and `format` over the 22 staged paths and folded its edits into the commit.
- Only the 22 real paths were staged explicitly; the ~206 other files showing as modified are the `core.autocrlf` artifact with zero content diff and were deliberately left out. **Never `git add -A` in this repo.**
- The search-history parity finding was withdrawn as out of scope and is **not** implemented; `replace: isOnSearchPage` remains.
- Nothing in `dustin-thomason` is committed or pushed.

---

## New code introduced

| Path | What |
| ---- | ---- |
| `src/pages/Home/constants.ts` | **new** — `HOME_COPY`, the four Atlas landing strings as an `as const` object |
| `src/pages/Home/components/HomeView.tsx` | **new** — presentational body; heading + two paragraphs, all copy read from `HOME_COPY` |
| `src/pages/Home/HomePage.tsx` | rewritten from a 3-line stub into the repo's thin route-shell shape |
| `src/app/router/index.tsx` | index route renders `<HomePage />` instead of redirecting to `/cases`; `Navigate` import dropped |
| `src/app/layouts/AppShell/components/BrandLink.tsx` | logo targets `RoutePaths.HOME`; `aria-label` updated to match |
| `src/app/layouts/AppShell/components/GlobalSearch.tsx` | Atlas placeholder constant; document-level `/` focus shortcut with input/modifier guards; element-level `onKeyDown` for `Esc` blur and `Enter` immediate submit |
| `src/components/SearchInput.tsx` | two optional pass-through props: `inputRef`, `onKeyDown` |
| `docs/parity.md` | `Home / landing` row → `Mock-ready` with the INT-129 note; Home removed from "What to POC next" |
