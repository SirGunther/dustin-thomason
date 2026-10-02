# Locked decisions — atlas/INT-144

> The locked-decision ledger and investigation record for INT-144 (export Europa results as CSV), per `agents/docs/qa-to-spec-traceability.md`. A decision here is no longer an open option. A later conflict is resolved by the latest explicit user correction, unless the user reopens the decision.
> Sources: [original ticket](../INT-144.md); the INT-138 and INT-139 artifacts in [../../INT-138/](../../INT-138/) and [../../INT-139/](../../INT-139/); atlas-front-end `INT-138` @ `36999e87` and europa-back-end `INT-138` @ `d9fb272`, read on 2026-09-29; the MongoDB `cursor.sort()` and OWASP CSV Injection pages (E5, E13); the INT-144 investigation conversation of 2026-09-29.
> Citations are `file:line` on those branches unless noted. atlas-front-end paths start at `src/`; europa-back-end paths start at `src/` and are marked `europa`.

## Verdict

**Proceed.** INT-144 is an atlas-front-end-only change. The export reuses the Europa page's existing filtered search request, fetches every page of the current result set at page size 100, turns the rows into CSV in the browser, and downloads the file with Quasar's `exportFile`. europa-back-end and callisto-back-end do not change: no route, DTO, swagger or migration change.

What this is not yet: a spec or an approved implementation. Two items stay open until the first manual run: the Excel display check (E14) and the time a 10,000-row export takes (E19).

The ticket's premise that "this work has already begun" holds for the filtered search read path the export is built on. No export or CSV code exists (E1).

## Terms

| Term | Means |
| --- | --- |
| Europa audit page | The page inside `atlas-front-end` (`src/europa/`, route `/europa-stuff`) that searches and lists audit events |
| europa-back-end | The audit service repo. Serves `GET /audit-events/search-paginated`, which filters, sorts, pages and builds the display `path` text |
| Page walk | Fetching `/search-paginated` page after page with the same filters until the result set is exhausted or the cap is reached |
| Result cap | The 10,000 limit europa-back-end applies to `totalItems` (`MAX_RESULTS_CAP`) |

## User directions

| Date | Direction | Effect |
| --- | --- | --- |
| 2026-09-29 | "Review @dustin-thomason/docs/atlas/INT-138/ and @dustin-thomason/docs/atlas/INT-139/ (just started this ticket). We are going to do @dustin-thomason/docs/atlas/INT-144/ now. This work has already begun, so this should be an easy extension. Investigate and report. You are rewarded on staying within scope on your assessment." | INT-138 and INT-139 were read for what bears on INT-144 only (E7, E8, E15). The "already begun" premise was tested (E1). Scope was held to the ticket's three acceptance criteria plus the requirements they imply; the one existing defect found (E17) was routed to a follow-up, not into INT-144 |
| 2026-09-29 | "For each finding, this is the process: write out the finding as a checklist item, review the relevant context, and provide evidence in the chat showing how you resolved that finding. You must provide evidence for each finding before marking it complete." | Every finding was re-checked against current code or a primary document and is recorded in the Evidence table below. E14 and E19 are not complete: their evidence requires a running system |
| 2026-09-29 | "Save the investigation in a decisions ledged in the Dustin Thomason repo for ref and any other details we have discussed" | This file |

**Process note.** The investigation skill asks for Plan mode before an investigation plan and for a report file under `investigations/`. The investigation ran read-only without Plan mode, the report was delivered in chat, and this ledger now holds its content. No `investigations/INT-144-investigation.md` exists.

## Problem, acceptance criteria, non-goals

**Problem.** Ops and IT managers can read Europa audit results only 10 to 100 rows at a time on screen, so they cannot analyze them locally. The ticket names no blocked person and no deadline (E20).

| ID | Acceptance criterion (checkable) | Source |
| --- | --- | --- |
| AC-1 | The Europa audit page has an Export control that produces a `.csv` file | INT-144.md:9 |
| AC-2 | The file's rows are every result for the current filters and search term, across all pages, up to the 10,000 result cap; each value equals what the grid displays for that row and column | INT-144.md:10; LD-002, LD-003, LD-004 |
| AC-3 | The browser saves the file to the local machine | INT-144.md:11; LD-008 |
| AC-4 | The file is valid and safe: RFC 4180 quoting, formula-leading cells neutralized, UTF-8 with a byte order mark | Implied by AC-2 and AC-3 for user-controlled values (E13); LD-007 |
| AC-5 | A failure during the export shows an error and saves no file | Implied by AC-2 (a partial file would not match the filtered results); LD-009 |

**Non-goals.** A europa-back-end export endpoint (LD-001). More than 10,000 rows (LD-003). A new permission (LD-010). XLSX or any other format. Scheduled or emailed exports. Splitting the multi-part path into separate columns. Fields the grid does not show, such as IP address and user agent (LD-004). Changing the grid's own paging or sort (LD-012).

## Question gates

### Resolved without asking (the answer already exists)

| Gate | Proposed question | Existing answer check | Outcome |
| --- | --- | --- | --- |
| G-01 | Does the export hold the visible page or every matching row? | **Answered by the ticket:** "Export matches the user's filtered results" (INT-144.md:10), for "ad hoc analysis on specific user behavior" (INT-144.md:3). A 10–100 row page is not the filtered result set | **LD-002** |
| G-02 | May the export exceed 10,000 rows? | **Answered by existing behavior:** the result set the user sees is capped at 10,000 and the grid says so (E4). Matching the filtered results means matching that set. Exceeding it requires a europa-back-end endpoint (E3, E4) | **LD-003** |
| G-03 | Which columns does the file hold? | **Answered by the ticket plus existing behavior:** "matches" (INT-144.md:10), and the page already lets the user choose and order columns (E10) | **LD-004** |
| G-04 | Which repo builds the CSV? | **Answered by evidence:** the request already carries every filter (E2), the backend accepts the needed parameters (E16), the display text is built only by `/search-paginated` (E7), and a backend export would collide with INT-139 (E8) | **LD-001** |
| G-05 | Which sort does the page walk use? | **Answered by evidence:** the sort has no unique tiebreaker and MongoDB's sort is not stable (E5) | **LD-006** |
| G-06 | Does export need its own permission? | **Answered by the ticket and evidence:** the ticket names none; the export calls the same endpoint behind the same route guard (E12) | **LD-010** |
| G-07 | Which branch does INT-144 start from? | **Answered by evidence:** the spec file INT-144 extends exists only on `INT-138` (E15); INT-139 LD-013 made the same call | **LD-011** |
| G-08 | Are labels translated? | **Answered by evidence:** `src/europa` has no i18n (E11) | **LD-009** |

## Locked-decision ledger

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 | **atlas-front-end only.** No europa-back-end or callisto-back-end change; no route, DTO, swagger or migration change | E2, E7, E8, E16 | **Rejects** a europa-back-end export endpoint (A-1) | Scope |
| LD-002 | The file holds **every result for the current filters and search term across all pages**, not the visible page | G-01 | **Rejects** a current-page export (A-2) | Behavior |
| LD-003 | The export stops at **10,000 rows**, the same cap the grid applies. When it stops at the cap, the page says so in the grid's wording ("results capped at 10,000") | G-02; E4 | **Rejects** exports over 10,000 rows for INT-144. Reversing this needs a europa-back-end endpoint | Behavior |
| LD-004 | **Columns are the grid's visible columns, in the user's order, with the grid's labels**, including `Date (Local)` / `Date (UTC)`. Values come from the same column definitions (`getOrderedColumns`) applied to rows mapped the same way as `displayRows` (the `userName` field reads `userFirstName`/`userLastName`), with dates formatted by `formatDateTime`. The path is the API's `path` string in one cell | G-03; E10 | **Rejects** a fixed full field list (IP address, user agent, resource id, service name). Changing to a fixed list later is a column-list change only | Behavior; CSV builder |
| LD-005 | **Page walk:** `pageSize=100`; stop at the first page with fewer than 100 rows or when 10,000 rows are collected; remove duplicate `id`s; copy the search parameters at the moment of the click and use that copy for every page | E3, E4, E6 | **Rejects** walking to the page count returned by the first response (E6) | Export composable |
| LD-006 | The page walk requests **`sortBy=createdAt`**. The direction is the grid's when the grid is sorted by `createdAt`, otherwise `desc` (the default) | E5; `DEFAULT_SEARCH_PARAMS` (`types/audit-event.types.ts:88-93`) | **Rejects** walking under the grid's sort column (A-5) | Export composable |
| LD-007 | **CSV format:** every field wrapped in double quotes with embedded double quotes doubled; CRLF line endings; a header row of column labels; a cell whose first character is `=`, `+`, `-`, `@`, tab, carriage return or line feed is prefixed with a single quote inside its quotes; UTF-8 with a byte order mark | E9, E13 | — | CSV builder |
| LD-008 | **Download** with Quasar `exportFile`, MIME type `text/csv`, file name `europa-audit-<YYYY-MM-DD>.csv` | E9 | **Rejects** adding a CSV or download library (A-3) | Export composable |
| LD-009 | **UI:** an Export button in the `SearchDataGrid` `#top-right` toolbar, beside Column Settings and Toggle Timezone. It is disabled while a search request or an export is in flight, and when there are 0 results. Labels are hard-coded English. A failure shows an error and saves no file | E11, E22 | — | UI |
| LD-010 | **No new permission.** The export runs on the page already gated by `AUDIT` + `READ` and calls the same endpoint with the same token | G-06; E12 | — | Non-goals |
| LD-011 | atlas-front-end **`INT-144` branches from `INT-138`**. INT-139 also branches from `INT-138` and extends `SearchDataGrid.spec.ts`, so expect a small merge in that file between INT-139 and INT-144 | G-07; E15; INT-139 LD-013 | — | Ledger note |
| LD-012 | The **`_id` sort tiebreaker** in europa-back-end is a separate ticket, not INT-144 | E17 | — | Future concerns |
| LD-013 | **Accepted risks:** two rows with the same `createdAt` millisecond on either side of a page boundary may be returned inconsistently (E18); a single-quote prefix may not survive an Excel save and reopen (E13) | E13, E18 | Accepted cost of LD-001 and LD-007 | Future concerns |

## Evidence

Established 2026-09-29 from the code as it stands and from the primary documents named. Each row was checked before it was marked complete.

| # | Finding | Evidence | Status |
| --- | --- | --- | --- |
| E1 | No CSV export work exists. "Already begun" holds only for the search read path | `git grep -il csv <ref> -- src/europa` over all 30 atlas-front-end refs: 0 files. The same over all 15 europa-back-end refs (`-- src`): 0 files. atlas `stash@{1}`: 5 matches, all `package-lock.json` integrity hashes; `stash@{0}` and both europa-back-end stashes: 0. proteus-front-end refs: `csv` appears only as a file-type label (`csv: 'CSV File'`, `src/lib/fileFormatting.ts:29`); its Europa matches are the permissions page, its i18n strings and mock fixtures (`src/pages/Permissions/constants.ts`, `src/i18n/en-US/permissionsManager.json`, `src/mocks/fixtures.ts`). `docs/`: only `INT-144/INT-144.md`. No INT-144 changelog | complete |
| E2 | The existing request sends every filter, the search term and the sort, and it is the only Europa API caller | `pages/HomePage/requests/fetchAuditEvents.ts:14-42` appends `page`, `pageSize`, `sortBy`, `sortDirection`, `userEmail`, `type`, `resourceType`, `createdAfter`, `createdBefore`, `searchTerm`; `:45` calls `/search-paginated`. `grep "getEuropaUri()" src/europa` (non-spec): 1 hit, that line | complete |
| E3 | Page size is at most 100; the page number has no upper bound | europa `search-audit-events-paginated.request.dto.ts:21` `@Min(1)` only on `page`; `:32` `@IsIn([10, 20, 50, 100])` on `pageSize` | complete |
| E4 | The total is capped at 10,000, the row offset is not, and the grid tells the user | europa `audit-event.repository.ts:10` `MAX_RESULTS_CAP = 10000`, `:137-138` caps `totalItems`; europa `search-params-to-mongo-query.converter.ts:18`, `:127-130` `skip = (page - 1) * pageSize` with no cap. `SearchDataGrid.vue:286-288` "(results capped at 10,000)"; `useAuditSearch.ts:138` `isResultsCapped` | complete |
| E5 | The sort has one key and no unique tiebreaker, and MongoDB does not order equal keys consistently | europa `search-params-to-mongo-query.converter.ts:122-124` `return { [field]: direction }`. MongoDB `cursor.sort()`, Sort Consistency: "When sorting on a field which contains duplicate values, documents containing those values may be returned in any order." … "If consistent sort order is desired, include at least one field in your sort that contains unique values." Sorting by `type`, `userEmail`, `resourceName` or `resourceType` has many equal keys, so a page walk under those sorts can repeat or skip rows | complete |
| E6 | New events sort first under the default order, so a walk that stops at the first response's page count can miss the last rows | `types/audit-event.types.ts:91-92` default `sortBy: 'createdAt'`, `sortDirection: 'desc'`; europa `audit-event.entity.ts:6` `@Schema({ timestamps: true })` sets `createdAt` at insert. A new event lands at offset 0 and pushes every later row back one place | complete |
| E7 | The display path text is built only by `/search-paginated`, so an export through it carries the `PERMISSIONS_UPDATED`, `CATEGORIZE` and (after INT-139) `RECATEGORIZE` text with no extra work | europa `search-audit-events-paginated.transaction.script.ts:63-91` (type branches, then the default `newState.path ?? oldState.path ?? resourcePath`). `/search` returns the stored path: europa `audit-event-to-search-response-dto.converter.ts:10-14`. INT-139 LD-010: "Only `/search-paginated` builds the path text"; LD-006 adds the `RECATEGORIZE` branch there | complete |
| E8 | A europa-back-end export endpoint would have to share `toItemProjection`, which INT-139 is changing | europa `search-audit-events-paginated.transaction.script.ts:56` `private toItemProjection`. INT-139 LD-006: "europa-back-end's paginated search TS gains a `RECATEGORIZE` branch" | complete |
| E9 | The download and the byte order mark need no new dependency | `node_modules/quasar/package.json` version `2.18.6`; `node_modules/quasar/dist/types/utils.d.ts:50-54` `exportFile(fileName, rawData, opts?)`, `:27-31` `ExportFileOpts { mimeType?, byteOrderMark?, encoding? }`. `package.json`: 0 matches for papaparse, csv*, export-to-csv, file-saver, xlsx | complete |
| E10 | What the grid shows comes from reusable pieces the export can apply to the same rows | `SearchDataGrid/auditEventColumns.ts:64-85` `getOrderedColumns` (labels; `createdAt` gets `Date (<tz>)` and the date formatter); `:22-28` `userName.field` is a function of `userFirstName`/`userLastName`, which exist only on `displayRows` (`SearchDataGrid.vue:90-101`); `useColumnOrderSettings.ts:29-33` persists order and visibility under the `europa-audit` storage prefix, `:45-48` `visibleColumnNames`; `composables/useTimezoneToggle.ts:28-48` `formatDateTime` and `getTimezoneLabel` | complete |
| E11 | `src/europa` has no i18n | `grep -rn "useI18n\|vue-i18n\|\$t(" src/europa` (non-spec): 0. For contrast, `src/callisto` components use `useI18n`. INT-138 coverage ledger area 7: "there is no i18n in `src/europa`" | complete |
| E12 | Export adds no access surface | `globalRouter/routes.ts:44-51` `requiresAuth` plus `AUDIT` + `READ`. europa `generic/auth/application/middlewares/auth.middleware.ts:34-48` verifies the access and id tokens and sets `req.authUser`; `grep UseGuards\|CanActivate\|@Roles\|RolesGuard` in europa `src` (non-spec): 0. proteus-front-end `src/i18n/en-US/permissionsManager.json:69` (origin/main): "not yet enforced by Europa's API" | complete |
| E13 | Cell values are stored text passed through unchanged, so the CSV must neutralize formula-leading cells | europa `search-audit-events-paginated.transaction.script.ts:110-114` copies `resourceId`, `resourceType`, `resourceName`, `path`, `bucket` as stored. OWASP CSV Injection (community.owasp.org/attacks/CSV_Injection): leading "Equals to (`=`), Plus (`+`), Minus (`-`), At (`@`), Tab (`0x09`), Carriage return (`0x0D`), Line feed (`0x0A`)" are read as formulas; mitigations: "Wrap each cell field in double quotes, Prepend each cell field with a single quote, Escape every double quote using an additional double quote"; caveat that these may not survive Excel saving and reopening the file | complete |
| E14 | Excel reads the file's non-ASCII text correctly with the byte order mark | The `byteOrderMark` option exists (E9). How Excel reads the file cannot be shown from code | **open**: validation plan H-6 |
| E15 | The spec file INT-144 extends exists only on `INT-138`, and `INT-138` is not merged | `git cat-file -e main:src/europa/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts`: absent; present on `INT-138`. `git merge-base --is-ancestor INT-138 origin/main`: false (`origin/main` = `ad059eec`, 2026-09-25). INT-138 orchestration Phase 5: "in-progress … no PR yet" | complete |
| E16 | The export uses only parameters the endpoint already accepts, so there is no API change | `pageSize=100` is in europa `request.dto.ts:32`; `sortBy=createdAt` is in `:41`; every filter is already sent (E2) | complete |
| E17 | The `_id` tiebreaker changes the grid's shared query and belongs in its own ticket | europa `audit-event.entity.ts:52-56` indexes `{ createdAt: -1 }`, `{ type: 1, createdAt: -1 }`, `{ 'identity.userEmail': 1, createdAt: -1 }`; none includes `_id`, so a sort with `_id` added is not the index key order and the grid's query plan changes. The effect is not measured, which is why it is a separate ticket | complete (scope decision); performance effect not measured |
| E18 | A same-millisecond `createdAt` tie at a page boundary can still be returned inconsistently | `createdAt` comes from Mongoose timestamps (europa `audit-event.entity.ts:6`), a millisecond Date. E5 applies to equal `createdAt` values | complete (recorded as accepted risk, LD-013) |
| E19 | A 10,000-row export finishes in acceptable time | Worst case is 100 sequential requests; each runs `countDocuments` and `find` in parallel with `maxTimeMS(10000)` (europa `audit-event.repository.ts:8`, `:131-135`). Not measurable without a running europa-back-end with data; INT-138 records "manual end-to-end blocked on AWS credentials" | **open**: validation plan H-7 |
| E20 | The ticket names no blocked instance and no deadline | INT-144.md:1-11: a user story and three acceptance criteria, no person, date or trigger | complete |
| E21 | No INT-144 changelog exists, and the scaffold script cannot create one | `ls docs/atlas`: no `INT-144-changelog.md`. `scripts/new-ticket-changelog.ps1:15` `[ValidatePattern('^PRDV-\d+$')]`. INT-138 copied the template by hand for the same reason | complete (action in Handoff) |
| E22 | The grid toolbar is the place for the Export button | `SearchDataGrid.vue:219-264` `#top-right` holds the page-size select, the search input, Column Settings (`:248-256`) and Toggle Timezone (`:258-263`) | complete |

## Alternatives rejected

| ID | Alternative | Why rejected |
| --- | --- | --- |
| A-1 | europa-back-end export endpoint (one query, streamed CSV) | Needs a route, DTO, swagger, specs and a deploy; must share the private `toItemProjection`, which INT-139 is changing (E8). Its only gain, more than 10,000 rows, is not asked for (LD-003) |
| A-2 | Export the visible page only | Does not match the filtered results (G-01) |
| A-3 | Add a CSV or download library | The serializer is a small pure function; `exportFile` covers the download (E9) |
| A-4 | Raise the `pageSize` limit so one request returns everything | A europa-back-end change that also changes the grid's validation (E3); not needed |
| A-5 | Walk under the grid's sort column and remove duplicates by `id` | Duplicate removal cannot restore rows the walk skipped (E5) |

## Scope assessment

### Already provided (reused as is)

- Filtered request: `fetchSearchAuditEventsPaginated` (E2).
- Filter and URL state: `useAuditSearch`.
- Column order, visibility and labels: `useColumnOrderSettings`, `getOrderedColumns` (E10).
- Date formatting and timezone label: `useTimezoneToggle` (E10).
- Display path text, including INT-138's `CATEGORIZE` and INT-139's `RECATEGORIZE`: europa-back-end `/search-paginated` (E7).
- Download: Quasar `exportFile` (E9).

### Changes INT-144 adds (atlas-front-end)

1. `src/europa/utils/buildAuditEventsCsv.ts`: a pure function from columns and rows to a CSV string, per LD-004 and LD-007.
2. `src/europa/composables/useAuditExport/useAuditExport.ts`: the page walk (LD-005, LD-006), the cap (LD-003), the download (LD-008), and `isExporting` / `error` state (LD-009).
3. `SearchDataGrid.vue`: the Export button (LD-009). `HomePage.vue`: passes the search parameters and totals the export needs.

### Specs to add or extend

- New `src/europa/utils/__specs__/buildAuditEventsCsv.spec.ts`: header row; quoting of commas, double quotes and newlines; formula-leading cells; empty row set gives a header only; `N/A` and empty values pass through.
- New `src/europa/composables/useAuditExport/__specs__/useAuditExport.spec.ts`: every filter passed; `sortBy=createdAt` forced; multi-page walk; stop on a short page; stop at 10,000; duplicate `id`s removed when pages shift; a request failure sets `error` and calls no download; parameters copied at the click.
- Extend `src/europa/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts`: button renders; disabled while fetching, while exporting and at 0 results; click emits the export event.

## Validation plan

**Happy path**

| ID | Step | Pass when |
| --- | --- | --- |
| H-1 | Apply three different filter sets and export each | The CSV row count equals the grid footer total each time |
| H-2 | Sort the grid by date and export | The first and last rows equal the grid's first and last rows |
| H-3 | Export a result set that contains a `CATEGORIZE` row | Its path cell equals the grid's text for that row |
| H-4 | Hide one column and move another, then export | The CSV omits the hidden column and follows the new order |
| H-5 | Switch the timezone to UTC and export | The header reads `Date (UTC)` and the values are UTC |
| H-6 | Open a file that contains non-ASCII names in Excel | The names display correctly (closes E14) |
| H-7 | Export a 10,000-row result set | Time is recorded (closes E19) |

**Negative paths**

| ID | Condition | Pass when |
| --- | --- | --- |
| N-1 | 0 results | The Export button is disabled |
| N-2 | More than 10,000 results | The export stops at 10,000 rows and the page says it is capped |
| N-3 | A request fails mid-export | An error shows and no file is saved |
| N-4 | Values containing commas, double quotes, newlines, or starting with `=`, `+`, `-`, `@` | The file opens in Excel with the values intact and no formula runs |
| N-5 | Events arrive during the export (unit test with shifting mocked pages) | No duplicate `id` and no missing row |
| N-6 | Double-click on Export | One export runs |
| N-7 | A filter changes while an export is running | The running export keeps the parameters from the click |

## Open items

| Item | Area | Next action |
| --- | --- | --- |
| E14: Excel display with the byte order mark | INT-144 testing | Run H-6 |
| E19: 10,000-row export time | INT-144 testing | Run H-7 against a europa-back-end with data |
| The `_id` sort tiebreaker (E5, E17) | europa-back-end follow-up | Record as a future concern; open a separate ticket that measures the grid query plan before and after |
| No INT-144 changelog (E21) | docs | Create `docs/atlas/INT-144-changelog.md` from the template by hand when implementation starts, with the ticket text verbatim |

## Handoff

| Action | Owner | Done when |
| --- | --- | --- |
| Create `docs/atlas/INT-144-changelog.md` | agent | The file exists and quotes INT-144.md:1-11 verbatim under Requirements |
| Branch atlas-front-end `INT-144` from `INT-138` | agent | `git merge-base --is-ancestor INT-138 INT-144` returns true |
| Implement the three changes and their specs (Scope assessment) | agent | `npx vitest run --maxWorkers 1 src/europa` passes and `npm run lint` passes |
| Run H-1 to H-7 and N-1 to N-7 | agent, with Dustin for the Excel checks | Each row's "Pass when" is met, or the failure is recorded here |
| Record the `_id` tiebreaker as a future concern | agent | An entry exists in `docs/atlas/INT-144/INT-144-future-development-concerns.md` naming E5 and E17 |
