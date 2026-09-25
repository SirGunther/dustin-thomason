# Test plan — atlas/INT-138

> Seeded from [INT-138-investigation.md](../investigations/INT-138-investigation.md) §9 on 2026-09-23. Refined by spec: pending (Phase 3).
> Criteria are story 01's ([file](../stories/INT-138-job-story-01-categorization-audit.md)): **C1**–**C7**. A scenario with no criterion behind it is flagged **[no criterion: neighbor]**, meaning it protects existing behavior rather than proving new behavior.
> The **literal** is written `<LIT>` until D2 fixes it. Paths A–G are the write paths from recon F1. Scenarios marked *(if D1)* exist only if D1 includes that path.

Status: seeded

## Scope and surfaces under test

- **Callisto:** the new categorize dispatch in the recategorize service, plus the approve v1/v2 and upload services if D1 includes them. Also the new converter that builds the three-part `newState.path`, and the new `ProceedingFileAuditAggregator` method.
- **Europa:** **unchanged**. It is tested only as the observation point (`GET /europa/audit-events/search-paginated`).
- **Atlas:** `src/europa/utils/constants.ts` (`eventTypes`, `eventTypeColors`), and the path cell in `SearchDataGrid.vue`.

## Happy path

- [ ] **HP-1 (C1, C7):** recategorize 2 Transcript deliverables into an existing static collection. Exactly 2 categorize dispatches are made, one per processed file, and each event carries one resource.
- [ ] **HP-2 (C4):** for HP-1's events, `newState.path` equals `Filepath: <filePath> | Deliverable Type: <type name> | Collection: <collection name>`, in that order, with names and not ids.
- [ ] **HP-3 (C3):** each event has `type = <LIT>` and `auditEventResources[0].resourceType = FILE`.
- [ ] **HP-4 (C2):** each event carries `identity` = the requesting user and a `createdAt`. Europa returns `userEmail`, a non-empty `userName`, and `createdAt`.
- [ ] **HP-5 (C5):** recategorize an Exhibits deliverable (a track with no collections). The path ends `Collection: N/A`.
- [ ] **HP-6 (C1, C7) (if D1):** approve v2 with 3 files, each with a type and a collection. There are 3 categorize dispatches in addition to the existing 3 `APPROVED` events.
- [ ] **HP-7 (C1, C5) (if D1):** upload-complete of one Exhibits deliverable with a type. There is 1 categorize dispatch, with `Collection: N/A`, in addition to `CREATED`.
- [ ] **HP-8 (C6):** Europa `?type=<LIT>` returns exactly the categorize events from HP-1 to HP-7. The Atlas Event Type dropdown lists `<LIT>`, and selecting it sends `type=<LIT>`.
- [ ] **HP-9 (C4):** the Atlas path cell for a `<LIT>` row renders 3 lines, with bold `Filepath`, `Deliverable Type` and `Collection` labels.
- [ ] **HP-10 (C4):** recategorize into a **newly created** dynamic collection. The path shows the new collection's name.

## Negative paths

- [ ] **NP-1 (C1):** a recategorize that fails validation (mixed tracks, or a type that doesn't match the collection) returns 400, and **no** categorize dispatch is made.
- [ ] **NP-2 (C1):** the recategorize TS throws after the attachment writes (rollback). **No** categorize dispatch is made.
- [ ] **NP-3 [no criterion: neighbor]:** the SQS send returns `false`. The request still succeeds with the same `{processedFileIds}`, and a failure is logged. This matches the existing audits (concern C2).
- [ ] **NP-4 [no criterion: neighbor]:** unapprove makes no categorize dispatch, and its `UNAPPROVED` count and shape are unchanged. *(Unless D1 includes E.)*
- [ ] **NP-5 (C7) (if D1):** approve with files already tagged deliverable (skipped). No categorize dispatch is made for the skipped files.
- [ ] **NP-6 (C6):** **contract test.** The Atlas `eventTypes` entry for categorize equals Callisto's `AUDIT_EVENT_TYPE` value byte for byte. A deliberate case or tense mismatch makes the test fail.
- [ ] **NP-7 [no criterion: neighbor]:** GCA flag off. A categorize dispatch is still made, because audits aren't flag-gated. The Dione outbox write is skipped, as today.

## Edge cases

- [ ] **EC-1 (C4):** a file path containing `": "` renders with the full value kept after the label (Atlas `slice(1).join(': ')`).
- [ ] **EC-2 (C5):** a Transcript deliverable with a null collection (possible via upload or approve v1). The path shows `Collection: N/A`.
- [ ] **EC-3 (C7):** a recategorize batch where 2 files share one attachment. There is one dispatch **per processed file**, not per attachment. The expected count must match `processedFileIds.length`.
- [ ] **EC-4 (C4):** a deliverable type name that exists on more than one track (e.g. `Other`). The name appears as stored. No track disambiguation is required unless the spec adds it.
- [ ] **EC-5 [no criterion: neighbor]:** `PERMISSIONS_UPDATED` rows still render as before in the Atlas path cell.
- [ ] **EC-6 [no criterion: neighbor]:** the Dione `file.recategorized.v1` outbox payload is unchanged (existing recategorize TS specs stay green without edits).

## Manual verification (required whenever a human runs a step)

**Before / after:**

| | Before | After |
| --- | --- | --- |
| Client Deliverables tab (recategorize, approve, upload) | categorize and approve work | **identical.** Nothing changes on this screen |
| Europa audit page, Event Type dropdown | no categorize option | `<LIT>` listed, with a coloured chip |
| Europa audit page, rows after a recategorize | **no row at all** | one row per file: Event Type `<LIT>`, Resource Type `FILE`, Path on 3 bold-labelled lines, User Email, User Name, Date |
| Europa audit page, rows after an approve (if D1) | 1 `APPROVED` row per file | the same `APPROVED` rows **plus** 1 `<LIT>` row per file |

**Preconditions:**
- Callisto and Europa running locally per `docs/atlas/local/callisto-local.mdc` and `europa-local.mdc`.
- Callisto's `SQS_AUDIT_EVENT_URL_OUTBOUND` pointed at the queue Europa's listener consumes, with `AUDIT_EVENT_QUEUE_NAME` unset or equal to `SQS_AUDIT_EVENT_URL_OUTBOUND`.
- Atlas running locally, signed in as a user whose role has `AUDIT` + `READ`.
- A proceeding with Client Access enabled that has at least 2 Transcript deliverables and 1 Exhibits deliverable.
- **Baseline:** filter the Europa page to Event Type `<LIT>` and note the count, which should be 0.

**Steps:** to be written at Phase 3 refine, once D1 fixes which flows are exercised. Placeholder order: M-1 recategorize 2 Transcripts; M-2 recategorize 1 Exhibit; M-3 approve (if D1); M-4 upload (if D1); M-5 filter the Europa page to `<LIT>`.

**Evidence:**

```text
GET {europa}/europa/audit-events/search-paginated?type=<LIT>&sortBy=createdAt&sortOrder=desc
```

Screenshot in frame: the Europa grid filtered to `<LIT>`, with the Path cell of one row showing the 3 labelled lines.

**Pass / fail:** to be written at Phase 3 refine. **Load-bearing:** M-1. If recategorize produces no row, the silent path is back.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| callisto-back-end | `src/granting-client-access/domain/services/recategorize-deliverable-files-service/__specs__/recategorize-deliverable-files.service.spec.ts` | HP-1, HP-3, HP-4, NP-1, NP-2, EC-3. **Red→green:** fails on today's code |
| callisto-back-end | new converter spec under `src/proceedings/domain/sub-domains/proceeding-file-audit/.../__specs__/` | HP-2, HP-5, HP-10, EC-2, EC-4 |
| callisto-back-end | `.../proceeding-file-audit.aggregator.spec.ts` | the new method dispatches `<LIT>` |
| callisto-back-end | approve v1/v2 and upload service specs *(if D1)* | HP-6, HP-7, NP-5; the existing `APPROVED`/`CREATED` assertions unchanged |
| callisto-back-end | the existing recategorize TS specs, unmodified | EC-6 |
| callisto-back-end | the existing unapprove service spec, unmodified | NP-4 |
| atlas-front-end | new `src/europa/utils/__specs__/constants.spec.ts` | HP-8 (literal listed and coloured), NP-6 (literal equals the Callisto value) |
| atlas-front-end | new `SearchDataGrid` path-cell spec | HP-9, EC-1, EC-5 |

## Gates

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` (callisto-back-end, atlas-front-end) |
| lint | `npm run lint` (both) |
| tests | callisto `npm test -- --runInBand`; atlas `npx vitest run --maxWorkers 1` |

Europa has no gate row, because nothing in it changes. If the spec changes that, add its gates.

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
