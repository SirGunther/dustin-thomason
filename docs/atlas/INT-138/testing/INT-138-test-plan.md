# Test plan — atlas/INT-138

> Seeded from [INT-138-investigation.md](../investigations/INT-138-investigation.md) §9 on 2026-09-23. Refined 2026-09-25 against the spec (`callisto-back-end` branch `INT-138-spec`: `docs/specs/atlas-client-access/deliverable-management/8-story-INT-138-categorize-audit-events/8-story-INT-138-categorize-audit-events.md`; copy at [../specs/INT-138-spec.md](../specs/INT-138-spec.md)) and [locked decisions](../specs/INT-138-locked-decisions.md) LD-001 to LD-015.
> **Criteria C1 to C9** are job story 01's ([accepted](../stories/INT-138-job-story-01-categorization-audit.md)). **[no criterion: neighbor]** marks a scenario that protects existing behavior rather than proving new behavior.

Status: executed. The automated gates are complete, on the final post-merge trees. Manual M-1 to M-4 and M-6 **pass** locally (2026-09-29); M-5 was not run (Planet Summary needs Mercury, so it can only be tested in the sandbox). Evidence: [screenshots/](./screenshots/).

## Scope and surfaces under test

- **Callisto, six paths:** upload-complete, approve v1, approve v2, recategorize, unapprove, and Planet Summary completion. Each dispatches one `CATEGORIZE` per file after its transaction script returns.
- **Callisto, audit core:** the new aggregator method and converter (spec Part A), and the GCA name-lookup assembler (Part B).
- **Callisto, Planet Summary identity:** the requester snapshot on `file_derivation_jobs` (Part C).
- **Atlas:** `src/europa/utils/constants.ts` (`eventTypes`, `eventTypeColors`, `MULTI_PART_PATH_TYPES`) and the `SearchDataGrid.vue` path cell (Part D).
- **Europa:** unchanged (LD-007). It is used only as the observation point: `GET /europa/audit-events/search-paginated`.

## Happy path

- [ ] **HP-1 (C1, C7):** recategorize 2 Transcript deliverables into an existing static collection → exactly 2 `dispatchFileAuditCategorizedEvent` calls, one per processed file, each with one FILE resource.
- [ ] **HP-2 (C4):** HP-1's events read `newState.path` = `Filepath: <filePath> | Deliverable Type: <type name> | Collection: <collection name>`, in that order, with names and not ids. `oldState.path` has the same shape with the prior values (LD-002).
- [ ] **HP-3 (C3):** every event has `type = CATEGORIZE` and `auditEventResources[0].resourceType = FILE`.
- [ ] **HP-4 (C2):** every request-path event carries `identity` = the requesting user and a `createdAt`. Europa returns `userEmail`, a non-empty `userName` and `createdAt`.
- [ ] **HP-5 (C5):** recategorize an Exhibits deliverable (a track with no collections) → the path ends `Collection: N/A`.
- [ ] **HP-6 (C1, C7):** approve v2 with 3 files, each with a type and a collection → 3 CATEGORIZE events, in addition to the unchanged 3 `APPROVED` events.
- [ ] **HP-7 (C1):** approve v1 with a type → 1 CATEGORIZE per processed file.
- [ ] **HP-8 (C1, LD-015):** approve v1 that sets a collection but no type → 1 CATEGORIZE, reading `Deliverable Type: N/A`.
- [ ] **HP-9 (C1, C5):** upload-complete of one Exhibits deliverable with a type → 1 CATEGORIZE (`Collection: N/A`), in addition to `CREATED`.
- [ ] **HP-10 (C1, C8):** unapprove a categorized file → 1 CATEGORIZE whose `newState.path` reads `Deliverable Type: N/A | Collection: N/A`, with the prior categorization in `oldState.path`. `UNAPPROVED` is unchanged.
- [ ] **HP-11 (C1, LD-013):** recategorize a file to its current type and collection → 1 CATEGORIZE with `oldState.path` equal to `newState.path`.
- [ ] **HP-12 (C4):** recategorize into a **newly created** dynamic collection → the path shows the new collection's name.
- [ ] **HP-13 (C1, C5, C9):** a Planet Summary completes with 2 artifacts → 2 CATEGORIZE events. Each has `Deliverable Type: Planet Summary | Collection: N/A`, and `identity` = the requester's id, email, first name and last name, with `ipAddress`/`userAgent` = `system` (LD-012, LD-014).
- [ ] **HP-14 (C6):** Europa `?type=CATEGORIZE` returns exactly the events from HP-1 to HP-13. The Atlas Event Type dropdown lists `CATEGORIZE`, and selecting it sends `type=CATEGORIZE`.
- [ ] **HP-15 (C3, C4):** the Atlas path cell for a `CATEGORIZE` row renders 3 lines, with bold `Filepath`, `Deliverable Type` and `Collection` labels. The type chip reads `CATEGORIZE` in `info` colour.

## Negative paths

- [ ] **NP-1 (C1):** a recategorize that fails validation (mixed tracks, or a type that doesn't match the collection) → 400, and no name lookup and no CATEGORIZE dispatch.
- [ ] **NP-2 (C1):** a transaction script rejects on any of the six paths (rollback) → no CATEGORIZE for that request.
- [ ] **NP-3 [no criterion: neighbor]:** the SQS send returns `false` → the request still succeeds with its unchanged response, and a failure is logged. This matches the existing audits.
- [ ] **NP-4 [no criterion: neighbor]:** the name-lookup assembler rejects after commit → the request still returns its normal result, `logger.error` is called, no CATEGORIZE is sent, and the sibling `APPROVED`/`CREATED`/`UNAPPROVED` is still dispatched.
- [ ] **NP-5 (C7):** approve with files already tagged deliverable (skipped) → no CATEGORIZE for the skipped files.
- [ ] **NP-6 (C1):** upload with neither a type nor a collection, or legacy `proceedings` approve (which sets no type) → no CATEGORIZE.
- [ ] **NP-7 (C8):** unapprove of a file that was never categorized → no CATEGORIZE. `UNAPPROVED` still fires.
- [ ] **NP-8 (C6):** a contract test pins Atlas's `CATEGORIZE` to Callisto's `AUDIT_EVENT_TYPE.CATEGORIZE` value. A case or tense change fails it.
- [ ] **NP-9 [no criterion: neighbor]:** GCA flag off → CATEGORIZE still dispatched, because audits aren't flag-gated. The Dione outbox write is skipped, as today.
- [ ] **NP-10 (C9):** a Planet Summary completion that is redelivered or re-emitted (job no longer pending) → no second CATEGORIZE.
- [ ] **NP-11 (C9):** a Planet Summary aggregator send fails for file 1 → file 2 is still dispatched, a WARN is logged, the handler returns `success: true`, and the derived files are **not** cleaned up.

## Edge cases

- [ ] **EC-1 (C4):** a file path containing `": "` → Atlas keeps the full value after the first label.
- [ ] **EC-2 (C5):** a Transcript deliverable with a null collection (possible through upload or approve v1) → `Collection: N/A`.
- [ ] **EC-3 (C7):** a recategorize batch where 2 files share one attachment → one CATEGORIZE **per processed file** (2), and one attachment write.
- [ ] **EC-4 (C4):** a deliverable type name that exists on more than one track (e.g. `Other`) → the name appears as stored.
- [ ] **EC-5 (C5, C8):** a blank or whitespace-only name → `N/A`, never an empty segment.
- [ ] **EC-6 (C9):** a Planet Summary job requested before release (`requester_identity` null) → the record keeps the real `userId`, with email and name placeholders `unknown` / `Unknown Requester`, and a WARN logged (concern C8).
- [ ] **EC-7 [no criterion: neighbor]:** `PERMISSIONS_UPDATED` rows still render as before in the Atlas path cell. All other types stay single-line.
- [ ] **EC-8 [no criterion: neighbor]:** Dione outbox payloads (`file.recategorized/approved/unapproved/created`) are unchanged, so the existing outbox converter and TS specs stay green without edits.
- [ ] **EC-9 [no criterion: neighbor]:** the GET files listing and the job-submission files listing expose no `filePath`/`bucket` after the shared select gains those columns.

## Manual verification (required whenever a human runs a step)

**Before / after:**

| | Before | After |
| --- | --- | --- |
| Client Deliverables tab (upload, approve, recategorize, unapprove) | works | **identical**. Nothing changes on this screen |
| Planet Summary create/complete | works | **identical** in the UI. The only change is a DB column on `file_derivation_jobs` |
| Europa audit page, Event Type dropdown | no categorize option | `CATEGORIZE` listed, with an `info` chip |
| Europa audit page, rows after a recategorize | **no row** | one row per file: `CATEGORIZE`, `FILE`, the path on 3 bold-labelled lines, User Email, User Name, Date |
| Europa audit page, rows after an approve | 1 `APPROVED` per file | the same `APPROVED` rows **plus** 1 `CATEGORIZE` per file |
| Europa audit page, rows after an unapprove | 1 `UNAPPROVED` per file | the same, **plus** 1 `CATEGORIZE` (N/A / N/A) per file that was categorized |

**Preconditions:**
- Callisto and Europa running locally per `docs/atlas/local/callisto-local.mdc` and `europa-local.mdc`.
- Callisto `SQS_AUDIT_EVENT_URL_OUTBOUND` pointed at the queue Europa's listener consumes, with `AUDIT_EVENT_QUEUE_NAME` unset or equal to `SQS_AUDIT_EVENT_URL_OUTBOUND`.
- The new migration applied.
- Atlas running locally, signed in as a user with `AUDIT` + `READ`.
- A proceeding with Client Access on that has at least 2 Transcript deliverables, 1 Exhibits deliverable and 1 submission file.
- **Baseline:** filter the Europa page to `CATEGORIZE` and note the count (expect 0).

**Steps:**
1. **M-1:** recategorize the 2 Transcript deliverables to another type in the same collection.
2. **M-2:** approve the submission file with a type and collection.
3. **M-3:** unapprove one of the M-1 files.
4. **M-4:** upload an Exhibits file with a type.
5. **M-5:** request a Planet Summary on a transcript and wait for completion.
6. **M-6:** filter the Europa page to `CATEGORIZE` and read each row.

**Evidence:**

```text
GET {europa}/europa/audit-events/search-paginated?type=CATEGORIZE&sortBy=createdAt&sortOrder=desc
```

Screenshot in frame: the Europa grid filtered to `CATEGORIZE`, with one row's Path cell showing the 3 labelled lines.

**Pass / fail:**

| Step | Passes | Fails |
| --- | --- | --- |
| M-1 | 2 new `CATEGORIZE` rows with the new type name | 0 rows: recategorize is silent again (the original defect) |
| M-2 | 1 `APPROVED` + 1 `CATEGORIZE` | `CATEGORIZE` missing: the approve path isn't dispatching |
| M-3 | 1 `UNAPPROVED` + 1 `CATEGORIZE` reading N/A / N/A | the N/A row is missing: the clear isn't audited |
| M-4 | 1 `CREATED` + 1 `CATEGORIZE` with `Collection: N/A` | a missing row, or an empty Collection segment |
| M-5 | 1 `CATEGORIZE` per summary file naming the **requester** | a blank user, or the transcript creator named |
| M-6 | a count of 7 or more new rows, each with the 3-line path | the path shows as one line: the Atlas condition is missing |

**Load-bearing step:** M-1. It proves the original defect (a silent recategorize) is closed.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| callisto-back-end | `…/proceeding-file-to-audit-event-assembler/__specs__/proceeding-file-categorization-to-audit.converter.spec.ts` (new) | HP-2, HP-5, HP-10 (path), EC-5 |
| callisto-back-end | `…/proceeding-file-to-audit-event.assembler.spec.ts`, `proceeding-file-audit.aggregator.spec.ts`, `proceeding-file-audit.dispatcher.spec.ts` (extended) | HP-3, HP-4, routing; neighbors unchanged |
| callisto-back-end | `…/recategorize-deliverable-files.service.spec.ts` (extended). **Red→green:** fails on today's code | HP-1, HP-11, NP-1, NP-2, NP-4, EC-3 |
| callisto-back-end | approve v1 / v2, upload, unapprove service specs (extended) | HP-6 to HP-10, NP-4 to NP-7 |
| callisto-back-end | `…/file-categorization-audit.assembler.spec.ts` (new) | gate (LD-009, LD-013, LD-015), name resolution, EC-4 |
| callisto-back-end | the recategorize, approve, unapprove and upload TS and projection specs (extended); repository `findByIds` / `findCategorizationsByIds` specs | data shape for each path; HP-12 |
| callisto-back-end | the Planet Summary completion service, requester-converter, context assembler, persist mapper and create-summary TS specs | HP-13, NP-10, NP-11, EC-6 |
| callisto-back-end | the existing outbox converter / TS specs, unmodified; the proceeding-files projection converter neighbor spec | EC-8, EC-9 |
| atlas-front-end | `src/europa/utils/__specs__/constants.spec.ts` (new) | HP-14, NP-8 |
| atlas-front-end | `src/europa/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts` (new) | HP-15, EC-1, EC-7 |

## Gates

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` (callisto-back-end, atlas-front-end) |
| lint | `npm run lint` (both) |
| architecture / conventions | callisto `npm run test:architecture` and `npm run test:conventions` |
| types | atlas `npm run type-check` |
| tests | callisto `npm test -- --runInBand`; atlas `npx vitest run --maxWorkers 1` |

Europa has no gate row: nothing in it changes (LD-007).

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| 2026-09-25 | baseline tests | `npx jest --config jest-e2e.json --runInBand --silent` | callisto `main` `59b1abd3`, full suite | pass: 444 suites, 2361 tests | — |
| 2026-09-25 | audit | `npm audit --audit-level=high` | callisto `INT-138` `9d4ce4e9` | pass (1 low) | — |
| 2026-09-25 | lint | `npm run lint` (`eslint --fix`) | callisto `INT-138`, whole repo | pass; 0 files changed | — |
| 2026-09-25 | type-check | `npm run type-check` | callisto `INT-138` | pass | — |
| 2026-09-25 | architecture | `npx jest --config jest-e2e.json --runInBand src/__tests__/architecture.spec.ts` (default shell) | callisto `INT-138`, depcruise rules | pass: 1/1 | fails under `COMSPEC`=Git Bash (test-harness artifact, concern C12) |
| 2026-09-25 | conventions | `npm run test:naming`, `test:dto-structure`, `test:type-structure`, `test:migration-naming`, `test:no-util-files`, `test:exchange-ownership`, each with `COMSPEC='C:\Program Files\Git\bin\bash.exe'` | callisto `INT-138` | pass: all six, 0 path errors | under the default Windows shell these checks don't scan (concern C12) |
| 2026-09-25 | tests | `npx jest --config jest-e2e.json --runInBand --silent` (default shell) | callisto `INT-138`, full suite | pass: 448 suites, 2455 tests (+4 suites and +94 tests vs baseline) | — |
| 2026-09-25 | audit | `npm audit --audit-level=high` | atlas `INT-138` `e5a29a4a` | **fail**: 24 vulns (11 high, 12 moderate, 1 low) | pre-existing: `package.json`/`package-lock.json` unchanged vs `origin/main`. Not introduced by INT-138; not fixed here |
| 2026-09-25 | lint | `npm run lint` (`eslint . --max-warnings 0`) | atlas `INT-138`, whole repo | pass | — |
| 2026-09-25 | type-check | `npm run type-check` (`vue-tsc --noEmit`) | atlas `INT-138` | pass | — |
| 2026-09-25 | tests | `npx vitest run --maxWorkers 1` | atlas `INT-138`, full suite | pass: 160 files, 1438 tests (4 skipped) | — |
| 2026-09-25 | red→green | recategorize service spec against the pre-change service | callisto `INT-138-gca-dispatch` | 6/11 failed before, 11/11 pass after | — |
| 2026-09-25 | mutation | Atlas path-cell condition reverted to `=== 'PERMISSIONS_UPDATED'` | `SearchDataGrid.spec.ts` | the 4 CATEGORIZE cases failed, as expected; restored | — |
| 2026-09-26 | audit | `npm audit --audit-level=high` | callisto `INT-138` `ef894a18` (after the convention-review fixes) | pass (1 low) | — |
| 2026-09-26 | lint | `npm run lint` | callisto `INT-138` `ef894a18` | pass; 0 files changed | — |
| 2026-09-26 | type-check | `npm run type-check` | callisto `INT-138` `ef894a18` | pass | — |
| 2026-09-26 | architecture | `npx jest --config jest-e2e.json --runInBand src/__tests__/architecture.spec.ts` (default shell) | callisto `INT-138` `ef894a18` | pass: 1/1 | — |
| 2026-09-26 | conventions | six find-based checks with `COMSPEC`=Git Bash | callisto `INT-138` `ef894a18` | pass: 6/6, 0 path errors | — |
| 2026-09-26 | tests | `npx jest --config jest-e2e.json --runInBand --silent` | callisto `INT-138` `ef894a18`, full suite | pass: 451 suites, 2479 tests | — |
| 2026-09-26 | port pin | the port return type deliberately changed to `Promise<string>`, then `tsc` | callisto `INT-138` | 5 TS errors, as expected; restored and clean | proves `useExisting` drift is caught at type-check |
| 2026-09-26 | lint / type-check | `npm run lint`; `npm run type-check` | atlas `INT-138-review-atlas` working tree (uncommitted) | pass | — |
| 2026-09-26 | tests | `npx vitest run --maxWorkers 1` | atlas `INT-138-review-atlas` working tree, full suite | pass: 161 files, 1447 tests (4 skipped) | — |
| 2026-09-26 | audit | `npm audit --audit-level=high` | atlas `INT-138-review-atlas` | **fail**: 11 high | pre-existing, no dependency change. **Blocks the commit** under the commit rule until the user waives it |
| 2026-09-25 | M-1 to M-6 | manual end-to-end | local Callisto → SQS → Europa → Atlas | **blocked** | needs AWS credentials (Planet Portal SSO) for Callisto's SQS producer. Risk: the cross-service contract is proven in code only. Follow-up: run with credentials, or in sandbox |
| 2026-09-29 | setup | upload 2 Transcript deliverables (`INT138-transcript-A.pdf`, `-B.pdf`) as `Full Size PDF` / `Full Transcript` | local end-to-end run (see note below the table) | pass: 2 `CREATED` + 2 `CATEGORIZE` | not a numbered step; it put the M-1 files in place and exercises path A with a collection |
| 2026-09-29 | M-1 | recategorize the 2 Transcript deliverables to `Word Document`, same collection | local end-to-end run | **pass**: 2 new `CATEGORIZE` rows reading `Deliverable Type: Word Document`, `Collection: Full Transcript`, same timestamp | — |
| 2026-09-29 | M-2 | approve `INT138-submission-D.pdf` as `Condensed PDF` / `Full Transcript` (v2) | local end-to-end run | **pass**: 1 `APPROVED` + 1 `CATEGORIZE` | — |
| 2026-09-29 | M-3 | unapprove (withdraw approval) | local end-to-end run | **pass**: 1 `UNAPPROVED` + 1 `CATEGORIZE` reading `Deliverable Type: N/A`, `Collection: N/A` | **deviation:** unapproved the M-2 file, not one of the M-1 files as written |
| 2026-09-29 | M-4 | upload `INT138-exhibit-C.pdf` to Exhibits as `Exhibit` | local end-to-end run | **pass**: 1 `CREATED` + 1 `CATEGORIZE` reading `Collection: N/A` | — |
| 2026-09-29 | M-5 | Planet Summary | — | **not run** | needs Mercury; sandbox only. Risk: criterion C9 is proven by unit specs only. Follow-up: run in the sandbox after deploy |
| 2026-09-29 | M-6 | Atlas `/europa-stuff`, Event Type = `CATEGORIZE`, Last hour | local end-to-end run | **pass**: `CATEGORIZE` is listed in the dropdown; 7 rows, each FILE, with the Path on 3 bold-labelled lines, user email, user name and date | 7 rows without M-5, because the setup upload added 2 |
| 2026-09-29 | neighbors | same page, Resource Type = `FILE`, Last hour | local end-to-end run | **pass**: `CREATED`, `APPROVED` and `UNAPPROVED` rows still arrive, one per file, with their one-line storage-key path | [no criterion: neighbor] |

**2026-09-29 run:** driven with Playwright over CDP in the user's signed-in Chrome, on job 112233, proceeding 3002 (Medical Proceedings Review). Trees: callisto `INT-138` `ef894a18`; atlas `INT-138` `e5a29a4a` plus the uncommitted review fixes; europa `main` `1082fda`. Path: Callisto → `sqs-triton-sb-ue1-derrick-auditevent.fifo` → local Europa → local Atlas. Records were read from `GET /europa/audit-events/search-paginated` and from the grid.

**Evidence** ([screenshots/](./screenshots/)):
- `01-event-type-dropdown-lists-categorize.png`: C6.
- `02-categorize-records-for-every-action.png`: C1, C2, C3, C4, C5, C7, C8.
- `03-existing-file-events-unchanged.png`: neighbors, and the order each action's records arrived in.
- `04-client-deliverables-current-categorization.png`: the files' current types match the latest records.

C9 has no screenshot (M-5).
