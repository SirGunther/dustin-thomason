# INT-130 — Atlas Prototype: Job Search page

## Ticket

- **Ticket:** INT-130
- **Repo:** `proteus-front-end` (product-authoring lane; ships the Atlas UI in React/shadcn)
- **Branch:** `INT-130`, cut from `prototype-main` at `5343547fa8bb5570b952fc5e008cb985d7b936be`
- **PR:** none. The prototype lane does not use PRs; the user directed that this work land on `prototype-main` directly so QA can pick it up from GitHub — the same way INT-129 ended.
- **Reference (read-only):** `atlas-front-end` (visual/behavioral source of truth), `callisto-back-end` (response shapes only)
- **Artifacts:** [INT-130/](INT-130/) — original ticket
- **Precedent followed:** [PRDV-16936-changelog.md](PRDV-16936-changelog.md) (Case Details) and [INT-129-changelog.md](INT-129-changelog.md) (Home + Jobs search) — same premise, same multi-agent method

---

## Requirements (verbatim)

> As a Product Manager, I want a realistic, clickable prototype of the existing **Atlas Job Search page** using fake data, so that I can quickly create and iterate designs for new and upcoming features for stakeholders using components that will be consistent with our upcoming shadcn/react refactor work.
>
> * * *
>
> ## Acceptance Criteria
>
> -   Prototype includes the following
>     -   Search field
>     -   Jobs tab
>         -   All the same columns
>         -   Sortable columns remain sortable
>         -   All existing clickable links remain clickable and direct user to appropriate page
>     -   Cases tab
>         -   All the same columns
>         -   Sortable columns remain sortable
>         -   All existing clickable links remain clickable and direct user to appropriate page

---

## Context

- Speed and functional completeness over polish. A facade for product design — no backend, no auth, no permissions.
- Atlas is the visual source of truth. Departures are allowed only where a Proteus shell constraint, semantic token, accessibility need, or missing shadcn behavior forces one — and each must be recorded.
- **This ticket was not greenfield.** INT-129 had already built `src/pages/Search/` with a working Jobs tab, Cases tab, a Proteus-only Proceedings tab, and Atlas-parity global search. INT-130 is therefore a **parity gap-fix on an existing page**, not a build from scratch. The starting gap set was established by diffing the shipped React against the Atlas Vue source, not assumed.

---

## Scope finding — what was actually missing

Diffed `src/pages/Search/**` against `atlas-front-end/src/callisto/pages/SearchPage/**` before planning. AC-relevant gaps found:

| Gap | Atlas evidence | Proteus before |
| --- | --- | --- |
| **No sortable columns at all** | `SearchJobsTable/columns.ts` marks all 4 `sortable: true`; `SearchCasesTable/columns.ts` all 3; `SearchHeader.vue` renders clickable `th` with arrow + active state | Static `TableHead`, no click handler, no sort state, no icon |
| **No case restriction surfaced** | `SmallRestrictedBadge` in both tables' case-name cells | Nothing |
| **Restricted proceedings were live links** | `SearchJobsTable.vue:122-129` renders a plain `<span>`, never a `router-link`, for the `Restricted` placeholder | Every proceeding linked unconditionally |
| **No Case ID / Case number tooltips** | `SearchCasesTable.vue:89-109`, copy from `i18n/en-US/common.json` → `callisto.search` | Nothing |

Already satisfied by INT-129, confirmed not rebuilt: the **search field** (AC1 — header `GlobalSearch`/`SearchInput`, explicit submit, 2-char minimum), the column sets, and the job/proceeding links.

---

## Architecture decided before fan-out

**Sorting is `useQuerySort`-backed and server-side (mock route), not `useTableSort`.** The repo documents the choice at `src/hooks/useTableSort.ts:10-17`: `useQuerySort` belongs to paginated lists where the full set was never fetched; `useTableSort` sorts an array already in hand; *"Reach for `useQuerySort` instead the moment the rows outgrow one response."* Search is an infinite query at `SEARCH_PAGE_SIZE = 20`, so client-side sorting would have sorted **only the pages fetched so far** — a correctness bug, not a style preference. Atlas agrees: it sorts server-side and keys its query on `[query, sortBy, sortOrder]`.

Atlas semantics mirrored exactly (`composables/useSortParams.ts`):

- URL params per tab: `jobSortBy`/`jobSortOrder`, `caseSortBy`/`caseSortOrder`.
- Default column `id`, **default order `desc`** — Atlas's fallback is `SortOrder.DESC`, so a fresh column sorts descending first. Deliberate, not an oversight.
- Toggle: `sortBy === column && order === 'desc' ? 'asc' : 'desc'`.
- Written with `replace: true`, matching Atlas's `router.replace`.
- Tab change clears all four params (Atlas `SearchPage.vue:71-85` omits exactly those four).

---

## Plans

| Added | Plan | Status | One-line approach |
| ----- | ---- | ------ | ----------------- |
| 2026-09-21 | Coordinator-authored architecture (this session, recorded above) | `implemented` | Four file-ownership-disjoint build agents (data layer; shared sort/badge plumbing; Jobs tab; Cases tab) coded against a written contract, plus coordinator-owned `SearchView` wiring, then one central gate and five browser verification passes. |

---

## Session log

### 2026-09-22T00:40:00Z — proteus-front-end — code-review fix pass

- **Problem:** An external review of `1c87768` returned one Major and four Minor findings. The Major one was mine and real: **two job-column comparators measured the wrong quantity**, so "sortable columns remain sortable" was satisfied in form but not in behavior.
- **Requirement:** Each sort must reproduce the semantics of the **real Callisto backend**, since the AC is about preserving existing production behavior — not merely about a column being clickable.
- **Method:** Verified every claim against the cited sources first (Callisto SQL, `architecture.mdc`, `TableCell`), then four subagents on disjoint file sets, central gate, and a **rewritten** browser harness.

**Findings verified against source before any code changed** — all five were correct:

| Finding | Verified against | Verdict |
| --- | --- | --- |
| Job date ignores start time | `callisto-back-end` `search-job.repository.ts` `applyJobDateSort` | confirmed |
| Proceedings sorts by count, not alphabetically | same file, `applyProceedingsSort` | confirmed |
| Search queries run with no search term | `SearchView.tsx` + `usePaginatedInfiniteQuery.ts`; Atlas uses `enabled: !!query` | confirmed |
| `CaseRestrictionBadge` in the wrong layer | `.cursor/rules/architecture.mdc` local-first rule | confirmed |
| Magic `'asc'`/`'desc'`; false "flex child" comment | `useSearchSort.ts`, `routes.ts`; `TableCell` is a plain `<td>` | confirmed |

**Shipped:**

- **Job date now sorts by date + start time.** Callisto orders by `(job_date + COALESCE(start_time,'00:00:00'::time))`; the mock now compares the combined instant. Justified by the fixtures rather than assumed: `jobDate` is built as `startOfDay(proceedingDateTime)` and `startTime` is that same instant, so they are same-day by construction and `startTime` already *is* the combined value.
- **Proceedings now sorts alphabetically, not by count.** Callisto orders by `MIN(value)` ascending / `MAX(value)` descending, with the emptiness tier sorted **ascending in both directions** so rows without proceedings are always last. Byte comparison (`<`/`>`) rather than `localeCompare`, matching `COLLATE "C"`.
- **`sorted()` gained a direction-aware comparator form.** The old helper produced descending by inverting an ascending comparator, which **cannot express** the proceedings rule (the empty tier must not flip, and the key changes from MIN to MAX with direction). Plain comparators stay ascending-only; a `{ compareWithOrder }` comparator receives the order and its result is used verbatim. The unchanged-return path, the no-mutation copy, and `paginate` are all untouched.
- **Search queries are gated.** `usePaginatedInfiniteQuery` gained an optional `enabled` defaulting to `true` (so the Cases and Schedule callers are byte-unchanged), and all three search hooks pass `enabled: searchBy !== undefined`. Previously `/search` with no term, or a 1-character deep link, fetched **every** job, case and proceeding behind the empty state, because the mock treats a null needle as match-everything.
- **`CaseRestrictionBadge` moved to `pages/Search/components/`.** Every importer is on the Search page, and the repo's local-first rule promotes to `components/` only when a **second page** imports. Relocation only — file byte-identical.
- **`ORDER_ASC`/`ORDER_DESC`** added in `src/constants/sort.ts`, replacing bare literals in `useSearchSort.ts` and `routes.ts`.
- **The false comment was deleted.** It claimed the badge "stretches as a flex child"; its parent `TableCell` is a plain `<td>` with no flex. Deleted rather than reworded — replacing one unverified mechanism claim with another repeats the defect.

**Coordinator corrections:**

- `npm run lint` failed with two errors the agents could not see (they are barred from running gates): `object-shorthand` in `routes.ts` and an import-order violation in `useSearchSort.ts`. Fixed with `lint:fix`; confirmed the autofix was cosmetic (arrow → method shorthand), not semantic.

**Verification — rewritten harness, Chromium, 0 console and 0 page errors:**

My earlier harness asserted only that the order *changed* after a click, which **passed the buggy count-based sort**. It now asserts Callisto's actual rule:

| Check | Result |
| --- | --- |
| Job date monotonic, both directions | pass |
| **Same-day pairs time-ordered** | pass — `9:00 AM → 2:00 PM` asc; `11:00 AM → 9:00 AM` desc |
| Proceedings alphabetical by MIN asc / MAX desc | pass — keys `1400 Harbor Blvd…` asc, `Zach Petrov…` desc |
| Proceedings empties always last, both directions | pass |
| id / caseShortName / caseNo unchanged | pass |
| Tooltips + restriction badge after relocation | pass |
| Links, tabs, `/cases` both sort tabs, 10-route sweep | pass |

**Gates:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | `proteus-front-end` | **fail — exit 1** | Same 4 pre-existing advisories; no dependency or lockfile change (both diffs empty). Waived, as on INT-129. |
| lint | `npm run lint` (after `lint:fix`) | `proteus-front-end` | pass — exit 0 | — |
| type-check | `npm run type-check` | `proteus-front-end` | pass — exit 0 | — |
| build | `npm run build` | `proteus-front-end` | pass — exit 0 | pre-existing chunk-size warning only |
| browser | Playwright/Chromium 1440×900 + 390×844 | table above | pass | 0 console, 0 page errors |

- **Commit:** `55a25f7b667dcdab14f4e5924114f05bdcc78cbf` — 10 files, 128 insertions / 17 deletions. Git recorded the badge move as a **100% rename**, confirming the relocation changed nothing. Type-check, lint, build and the browser suite were all re-run green against the post-hook tree. **Not pushed, not merged.**
- **Not independently observable in the browser:** the query-gating fix. The axios mock adapter resolves **in-process**, so a suppressed fetch produces no network traffic to count — my first probe "counted requests" but was actually matching Vite module URLs, which is not evidence. Gating is verified by the diff plus TanStack Query's `enabled` contract (a disabled query never runs its `queryFn`), and by confirming no user-visible regression: `/search` still shows the empty state with 0 rows, and a valid query still returns 20. Recorded as reasoned-not-measured rather than claimed as browser-verified.

---

### 2026-09-21T21:05:00Z — proteus-front-end — Atlas Search parity: sortable columns, restriction badges, tooltips

- **Problem:** The Search page shipped by INT-129 looked like Atlas but did not behave like it — none of Atlas's seven sortable columns sorted, case restriction was invisible on both tables, a restricted proceeding rendered as a live link that Atlas deliberately renders as plain text, and the Case ID / Case number tooltips were absent.
- **Requirement:** Every column Atlas marks sortable must sort, with Atlas's default column, default order, and toggle semantics; each table must surface case restriction as Atlas does; a restricted proceeding must not be a link; Case ID and Case number must carry Atlas's tooltip copy — without breaking the page's existing links or the `/cases` page that shares the same mock route.
- **Solution:** Four subagents on **disjoint file sets**, each coding against a contract written before fan-out (exact export names and signatures), all forbidden from running git or any npm command. Coordinator owned `SearchView.tsx`, gated centrally once, read every diff, then verified in Chromium.

**File ownership split (disjoint, zero collisions):**

| Owner | Files |
| ----- | ----- |
| Agent A | `src/api/jobs/jobs.types.ts`, `src/mocks/fixtures.ts`, `src/mocks/routes.ts` |
| Agent B | `src/pages/Search/components/SearchJobsTable.tsx`, `src/pages/Search/hooks/useSearchJobs.ts` |
| Agent C | `src/pages/Search/components/SearchCasesTable.tsx`, `src/pages/Search/hooks/useSearchCases.ts` |
| Agent D | `src/pages/Search/constants.ts`, `src/pages/Search/types.ts`, `src/pages/Search/hooks/useSearchSort.ts` (new), `src/components/CaseRestrictionBadge.tsx` (new) |
| Coordinator | `src/pages/Search/components/SearchView.tsx` |

**Shipped:**

- **All seven Atlas-sortable columns now sort.** Jobs: Job number, Job date, Proceedings, Case name. Cases: Case ID, Case number, Case name. Each reuses the repo's existing shared `SortableTableHead` (`aria-sort` + lucide arrows) rather than a new header component. Sorting is applied in the mock resolvers before pagination, so it sorts the whole result set rather than the pages already fetched.
- **`useSearchSort`** — a generic hook built *on top of* the existing `useQuerySort` (no URL-writing reimplemented) that supplies Atlas's default-column, default-`desc`, and desc→asc toggle semantics, and re-validates the order param that `useQuerySort` casts without checking.
- **Mock-route sorting is additive by construction.** A new `sorted()` helper returns the input array **unchanged** when `sortBy` is absent or unrecognized; `paginate` itself is untouched. That is what keeps every other caller of those routes byte-identical.
- **`CaseRestrictionBadge`** — one shared component used by both tables, because Atlas shares one (`SmallRestrictedBadge`) across both of its tables and the two must never drift. Renders nothing for an unrestricted case; otherwise a `StatusPill` (destructive at level 2, warning at level 1) with an `EyeOff` icon and a tooltip carrying the level-specific description.
- **Restricted proceedings are no longer links.** `JobSearchResult.proceedings` now reuses the existing `CaseJobProceeding` type (`id: number | null`) instead of the non-nullable `JobProceeding`, and the table renders `id === null` as plain muted text — matching `CaseJobsPanel.tsx` byte-for-byte, so the same job reads identically on Search and on Case Details.
- **Fixture consistency fix.** `getJobSearchResults` now applies the same restricted-placeholder substitution for the demo case that `getCaseJobsByCaseId` already applied. Before this, case 7's jobs showed real linked proceeding names in Search and "Restricted" on Case Details — the exact failure the fixture's own comment warns against ("Two screens disagreeing about one job reads as a bug in a demo"). No PRNG call was added, removed, or reordered, so the seeded demo data is unchanged.
- **Tooltips** on Case ID and Case number carry Atlas's copy verbatim from `i18n/en-US/common.json`, attached to the body cells as Atlas does.
- **Tab change clears all four sort params**, matching Atlas.

**Cross-page effect — deliberate, and it fixes a pre-existing silent no-op:**

The `cases` mock route is shared with the `/cases` page, which **already sent `sortBy: 'name'`** (`useCasesFilters.ts`) while the route ignored sort entirely — so the "Case name" sort tab on `/cases` had been doing **nothing**. Adding `name` to that route's comparators makes it work. Verified both directions: the "Case name" tab now returns genuinely alphabetical results, and the default "Last updated" tab round-trips to byte-identical order.

**Coordinator verification of subagent output** (each agent was forbidden from running gates):

- All four packets compiled together on the first central `tsc -b` — no corrections were required this session, in contrast to the two-of-five rate on PRDV-16936. The written-contract-before-fan-out approach (exact export names and signatures handed to every dependent agent) is the difference worth keeping.
- Every diff was read directly rather than accepted from the hand-back reports. Agent A's claims (that `paginate` was unmodified and no PRNG call changed) were confirmed against the actual diff, not its summary.
- Agent B and C each independently matched an existing repo precedent (`CaseJobsPanel` for the placeholder, `CaseHeader` for the tooltip-wrapped interactive element) rather than inventing a treatment.

**Verification — Chromium, five passes, 1440×900 and 390×844, 0 console errors and 0 page errors throughout:**

| Check | Result |
| ----- | ------ |
| Jobs: default state on arrival | pass — `Job number[aria-sort=descending]`, data genuinely id-descending |
| Jobs: all 4 columns, both directions | pass — **monotonicity asserted on the sorted column itself**, not merely "the order changed" |
| Cases: default state on arrival | pass — `Case ID[aria-sort=descending]` |
| Cases: all 3 columns, both directions | pass — monotonic in both directions, `aria-sort` tracks the active column |
| Toggle semantics | pass — new column starts `desc`; active `desc` flips to `asc`; matches Atlas |
| Tab change clears sort params | pass — URL returns to `?q=…` only |
| Job number link | pass — `/jobs/105879` |
| Proceeding links | pass — 5 of 5 sampled resolve to their own path (no dead links in search results) |
| Case ID link **through the tooltip wrapper** | pass — `/cases/20`; the tooltip did not swallow the click |
| Tooltips | pass — both render Atlas's verbatim copy on hover |
| Restriction badge + tooltip | pass — level-1 description renders on case 7 |
| Search field (AC1) | pass — Enter submits to `/search?q=bauer` |
| All three tabs still render | pass — Jobs 14 / Cases 1 / Proceedings 13, correct headers each |
| `/cases` regression (shared route) | pass — name tab now genuinely alphabetical; default tab round-trips identical |
| 10-route regression sweep | pass — every route renders, 0 new errors |

**Gates** (final post-change state, run in order):

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | `proteus-front-end` | **fail — exit 1** | Same 4 pre-existing advisories as INT-129 and PRDV-16936 (2 high, 2 moderate incl. `qs`). **No dependency or lockfile change on this branch** — both `git diff prototype-main...HEAD -- package.json package-lock.json` and the working-tree diff are empty. Per `git-commit-workflow` a non-zero audit blocks the commit pending the developer's triage or waiver. |
| lint | `npm run lint` (`eslint "src/**/*.{ts,tsx}"`) | `proteus-front-end` | pass — exit 0 | — |
| type-check | `npm run type-check` (`tsc -b`) | `proteus-front-end` | pass — exit 0 | — |
| build | `npm run build` | `proteus-front-end` | pass — exit 0 | pre-existing >500 kB chunk-size warning only |
| browser | Playwright/Chromium 1440×900 + 390×844 | table above | pass | 0 console errors, 0 page errors |

- **Commit:** `1c87768dccb580a13593a1167b67a47f85894d7a` on branch `INT-130` — 12 files, 448 insertions / 42 deletions. The user **waived the failing audit gate**, consistent with INT-129 and PRDV-16936 where the identical pre-existing advisories were waived. The husky/lint-staged pre-commit hook re-ran type-check, `lint:fix` and `format` over the 12 staged paths and folded its edits into the commit; type-check, lint, build and the browser pass were all re-run green against the post-hook tree. Only the 12 real paths were staged explicitly; the ~200 `core.autocrlf` files were deliberately left out. **Not pushed, not merged.**
- **Tests added/updated:** none — **exception applies.** The repo has no runnable harness (`test:unit:ci` is a stub; zero `*.spec.*`/`*.test.*` under `src/`) and the prototype lane scopes automated tests as intentionally light. Behavior was verified end-to-end in a real browser instead (table above). Residual risk: no regression net for the eight mock comparators, `useSearchSort`'s toggle/validation branches, or the `id === null` placeholder branch. Smallest follow-up that would unlock coverage: wire a Vitest config and start with `useSearchSort` and the `sorted()` helper, both pure.
- **API docs — not relevant:** no HTTP contract changed. Checked surface: `src/api/jobs/jobs.api.ts` and `src/api/cases/cases.api.ts` are byte-unchanged; `PaginationParams` already declared `sortBy` and `order`, so no request or response shape is new. Only the mock resolvers' behavior changed.
- **Regression impact:** the shared surfaces were the `cases` mock route, `paginate`, and `SortableTableHead`. `paginate` and `SortableTableHead` were not modified at all; the `cases` route change is additive by construction (unchanged-return path for absent/unknown sort keys) and was verified on `/cases` in both sort tabs plus a 10-route sweep.

---

## Deliberate departures and observed-not-fixed

1. **Atlas's Jobs "Case name" header carries a `secondLabel: 'Case Number'` sub-label**; Proteus renders `Case Number:` in the cell only (as Atlas also does). Closing this would mean adding a sub-label slot to the **shared** `SortableTableHead` for a cosmetic header line. Recorded as a departure; the information itself is present on every row.
2. **Search tab count badges use `variant="secondary"`, including at zero.** In this theme `secondary` is *brighter* than `default` (`rgb(42,31,255)` vs `rgb(6,36,126)`) — the trap recorded in PRDV-16936, which used `outline` for muted/zero states. These badges are INT-129's surface and outside INT-130's AC, so they were left alone rather than widened into scope.
3. **`/search` measures `scrollWidth` 598 at 390px against the shell's 571 baseline.** **Proven not to be this ticket's doing:** with `table { display: none }` injected the page still measures **598**, and every change here is inside the table. The table itself sits correctly inside an `overflow-x-auto` container. Pre-existing on the Search page from INT-129.
4. **The Cases tab is not URL-addressable** (tab state is local `useState`, not a query param as in Atlas), so a sorted Cases view cannot be deep-linked. Out of AC scope; noted because it also means sort params can only be reached by clicking, which is what Atlas's tab-change clearing intends anyway.
5. **The Proceedings tab has no sortable columns.** It is a Proteus-only tab with no Atlas equivalent, so Atlas defines no sort for it and the AC does not cover it. Left untouched.
6. **The `/cases` `name` comparator is out-of-scope and was kept deliberately — explicitly approved, not overlooked.** A second review correctly observed that Search's Cases tab only ever sends `caseShortName`, so the `name` key added to the shared `cases` mock route serves the separate My Cases page and is independently removable. It is kept because removing it would **re-break a working control**: `/cases` already sent `sortBy: 'name'` to a route that ignored it, so its "Case name" tab was a silent no-op, and it is now verified genuinely alphabetical with the default "Last updated" tab round-tripping to byte-identical order. Reverting would restore the no-op to buy scope purity. Recorded here as a conscious scope decision so it is auditable rather than incidental.
7. **String columns still collate with `localeCompare`, not Callisto's `COLLATE "C"`.** Raised during the review fix pass and **deliberately not changed**. `applyCaseShortNameSort` uses `LTRIM(NULLIF(case.short_name,'')) COLLATE "C"` with `NULLS LAST`; the mock's `caseShortName`, `caseNo` and `name` comparators use `localeCompare`. The two agree on this fixture data (ASCII, title-case, no diacritics or blank names) but diverge on case-mixing, since byte order sorts all uppercase before lowercase. The reviewer flagged only `jobDate` and `proceedings`; changing the collation of three already-passing columns is a systematic decision about every string sort on the page, not a drive-by fix, so it is recorded for a deliberate call rather than silently altered.
8. **i18n (review Pattern A) — not applicable, recorded rather than marked compliant.** Proteus has no i18n package and no locale tree; page copy lives in `constants.ts` per repo convention. Introducing i18n architecture would exceed this ticket. The Atlas strings this ticket needed were copied verbatim with their source cited in-file.
9. **Keyboard focus does not open the Case ID / Case number tooltips** — the trigger span carries `tabIndex={-1}`, so focus lands on the inner link. This is inherited from the existing `CaseHeader.tsx` pattern rather than introduced here; changing it would change a repo-wide precedent.

---

## Attempt history

_None. No approach was abandoned this session._

---

## Key technical learnings

- **Two sort mechanisms exist in this repo and picking the wrong one is a correctness bug, not a style slip.** `useTableSort` sorts only what is already in memory; on a 20-per-page infinite query that silently sorts a fraction of the result set. The hook's own doc comment states the rule — reading it first is what prevented the wrong choice.
- **A shared mock route can hide a silent no-op for a whole page.** `/cases` had been sending `sortBy: 'name'` to a route that ignored sort entirely, so its "Case name" tab did nothing and nothing failed. Sorting was added at the resolver, never inside `paginate`, precisely so the blast radius stayed inspectable.
- **"The order changed" is not "the order is correct."** The first browser pass only compared the first column before and after a click — every sort looked fine. Asserting **monotonicity on the column actually being sorted** is what would have caught a wrong comparator, and it is the check worth keeping for any future sortable table.
- **A harness can manufacture a false defect.** Deep-linking `?caseSortBy=…` and then clicking the Cases tab showed all three case sorts "broken" — because tab change clears sort params by design. The app was right and the test was wrong; the fix was to drive the tab the way a user does before concluding anything.
- **Attribute an overflow before fixing it.** Rather than nudging widths to chase 598 → 571, hiding the entire table and re-measuring proved in one step that the overflow belongs to the page shell, not to this ticket's table changes.
- **A contract written before fan-out removes the correction round.** Every dependent agent got exact export names and signatures for code that did not exist yet; all four packets compiled together on the first central type-check, against two-of-five needing coordinator repair on PRDV-16936.
- **Measure a style before deleting its justification.** A review flagged the `align-middle` comment on the restriction badge as inaccurate. Rather than just deleting the sentence, stripping the declaration at runtime and re-measuring showed the class was inert in one call site and made rows 1px *taller* in the other — the opposite of its stated purpose. The comment was not merely wrong about the mechanism; the class had no reason to exist. Deleting a rationale without testing the thing it justified would have left unexplained cruft behind.

---

## Current state (as of 2026-09-22)

- Branch `INT-130` is **three commits**: `1c87768` (build), `55a25f7` (review fixes), `4087a1a` (badge alignment cleanup), cut from `prototype-main` at `5343547`.
- **`prototype-main` has been fast-forwarded locally to `4087a1a`** at the user's direction, so QA can pick the work up from GitHub. The merge was verified as a clean fast-forward first — `origin/prototype-main` had not moved off `5343547`, so all three commits land with no divergence and no merge commit.
- **Pushed.** `origin/prototype-main` is at `4087a1a4b55bd331eee537a3b282bc65ad943b5a` (`5343547..4087a1a`), verified equal to local. The work is on GitHub and available to QA.
- All three acceptance criteria are satisfied on the running page, verified in a real browser rather than by source reading.
- lint, type-check and build are green on the committed tree; **audit fails with 4 pre-existing advisories** and no dependency change on this branch — waived by the user.
- The working tree also carries the standing ~200-file `core.autocrlf` artifact with **zero** content diff (`git diff --numstat` is all `0 0` for them). Only the 12 real paths below may be staged. **Never `git add -A` in this repo.**
- Nothing in `dustin-thomason` is committed or pushed.

---

## New code introduced

| Path | What |
| ---- | ---- |
| `src/pages/Search/hooks/useSearchSort.ts` | **new** — generic URL-backed sort state over `useQuerySort`, implementing Atlas's default-column / default-`desc` / desc→asc toggle semantics |
| `src/pages/Search/components/CaseRestrictionBadge.tsx` | **new** — restriction pill + tooltip shared by both search tables so they cannot drift. Created under `src/components/` and **moved here** in the review fix pass, per the local-first rule (both importers are on the Search page) |
| `src/pages/Search/constants.ts` | `JOB_SORT_COLUMNS`, `CASE_SORT_COLUMNS`, `JOB_SORT_PARAMS`, `CASE_SORT_PARAMS`, `SEARCH_SORT_PARAM_NAMES` |
| `src/pages/Search/types.ts` | `JobSortColumn`, `CaseSortColumn` derived from those constants |
| `src/pages/Search/components/SearchJobsTable.tsx` | four sortable headers; restricted placeholder as non-link text; restriction badge in the case-name cell |
| `src/pages/Search/components/SearchCasesTable.tsx` | three sortable headers; Atlas tooltips on Case ID and Case number; restriction badge beside the case name |
| `src/pages/Search/hooks/useSearchJobs.ts` | sort state in the query key and the request |
| `src/pages/Search/hooks/useSearchCases.ts` | sort state in the query key and the request |
| `src/pages/Search/components/SearchView.tsx` | passes sort state to both tables; clears all four sort params on tab change |
| `src/mocks/routes.ts` | `sorted()` helper; comparators wired into the `jobs/search` and `cases` resolvers |
| `src/mocks/fixtures.ts` | restricted-placeholder substitution in `getJobSearchResults`, matching `getCaseJobsByCaseId` |
| `src/api/jobs/jobs.types.ts` | `JobSearchResult.proceedings` reuses `CaseJobProceeding` so a search row can carry the non-link placeholder |
