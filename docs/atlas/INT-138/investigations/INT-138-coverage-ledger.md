# Coverage ledger — atlas/INT-138

**Investigation question:** where does a file's deliverable type and collection get set or changed, what does each of those paths send to the Europa audit log today, and what does each layer need so that a Categorize record shows the file, the categorization, the user and the time?

**Repos:** `callisto-back-end`, `europa-back-end`, `atlas-front-end`, plus `larry-adams` (read-only).

**Baseline commits** (all `main`, 2026-09-23): callisto `59b1abd3` · europa `1082fdad` · atlas `26eaa0bb`.

**Started:** 2026-09-23.

## Consulted

- `docs/atlas/*/investigations/*-coverage-ledger.md` and `docs/*/tickets/*/investigations/*-coverage-ledger.md`, searched for "audit", "event type", "categoriz", "recategor" and "europa": 14 ledgers exist and 7 matched.
  - **`atlas/PRDV-16192`: found and reused, with two areas reopened.**
    - **Reused without re-reading:**
      - area 3 (Europa storage: Mongo, schema-on-write, free-form `oldState`/`newState`, `type` a free string, `path` unindexed);
      - area 4 (SQS-only ingest, raw `JSON.parse` saved as-is).
    - **Reopened, because the code changed since the recorded commit:**
      - area 1: Europa paginated projection, `af49e79..1082fda` includes `d71f2bd`;
      - area 7: Atlas grid, `102e034d..26eaa0bb` includes `c2814144` and PRDV-14304's `ad0c807e`/`8b01c901`/`5b7c2aeb`.
    - **Reopened, because the behavior differs:**
      - area 10 (neighbour audit assemblers) was inspected for permissions, not file categorization;
      - `git log 47f5a841..HEAD -- src/audits` in callisto is empty, so the enum and domain-event shapes are unchanged.
  - **`atlas/PRDV-16312`: found, used as a pointer, not reopened.** Area 7 (three dynamic-collection creation sites) was cross-checked against, and is subsumed by, area 1 below. Its outbox coverage is about Dione events, a different behavior.
  - **`atlas/PRDV-16313`: found, used as a pointer.** Area 10's "no modified-by identity on the row" finding was reused for OQ-07's fact half. Its rename surfaces don't apply here.
  - **`atlas/PRDV-14184`, `PRDV-16402`, `PRDV-16403`, `PRDV-16461`:** matched only on "deliverable/collection/recategorize" in unrelated behavior (the upload-form defaults, transcode, read guards). Nothing reused.
- **`larry-adams/**`**, searched for "INT-138", "Categoriz" and "audit log|audit event": no INT-138 spec.
  - `systems/neptune/callisto/granting-client-acess/epic-PRDV-15736-…/dione-file-access-event-design.md` is about Dione outbox events. `:17` states Callisto's file audit events are "created, approved, unapproved, renamed".
  - `work breakdown structure/…/gca_consume_checklist.md` covers Dione consumer work. Not relevant.
- **`docs/system-architecture/domain-knowledge-system/domains/audit-log.md`:** "Status: Not written". Nothing to reuse.

## Areas examined

### 1. `callisto-back-end` — every path that writes a file's categorization (the surface)

| Field | Value |
| --- | --- |
| Inspected | `file_attachments` columns; every repository injecting `FileAttachment`; every setter and its callers; `create()` callers; assignments to `.deliverableTypeId`/`.deliverableCollectionId`/`.trackTypeId`; runtime raw SQL touching `file_attachments` |
| Findings | Seven paths write categorization: **A** upload-complete (1 file), **B/C** approve v1/v2 (many), **D** recategorize (many), **E** unapprove (clears), **F** transcript-summary inbox (system, type `Planet Summary`), **G** legacy approve (tag only). The `FileAttachment` entity is injected into exactly 3 repositories (cases, GCA, proceedings). The GCA setters' only callers are the approve TS `:365,:369`, the recategorize TS `:119` and the unapprove TS `:152,:156`. `setDeliverableCollectionAndType` has no callers. The proceedings `create()` callers are submission upload (no type), transcript summary, and video transcode (copies the track). No runtime raw SQL touches the table |
| Status | fully-inspected — the list is closed (completeness claim above) |
| Commit | callisto `59b1abd3` · 2026-09-23 |
| Evidence | `file-attachment.entity.ts:39-54`; `granting-client-access/infrastructure/repositories/file-attachment.repository.ts:28-70`; `approve-deliverable-files.transaction.script.ts:354-373`; `recategorize-deliverable-files.transaction.script.ts:117-126`; `unapprove-deliverable-files.transaction.script.ts:152-159`; `persist-transcript-summary-derivatives.mapper.ts:83-96`; `proceedings/.../approve-files-for-delivery-transaction.script.ts:99-109` |
| Notes | Residual: `File.fileAttachment` has `cascade: true` (`file.entity.ts:48`), and a grep cannot fully rule out a loaded-entity save changing categorization. The FKs are `ON DELETE SET NULL` (migrations `1775761245349`, `1781121204473`), which clears categorization with no code path (concern C3). Drag-and-drop has no backend endpoint; it posts to A |

### 2. `callisto-back-end` — the audit pipeline for files

| Field | Value |
| --- | --- |
| Inspected | `ProceedingFileAuditAggregator` (all 6 methods); `ProceedingFileAuditParams`; `ProceedingFileToAuditEventAssembler`; `ProceedingFileToAuditEventResourceConverter`; `src/audits/constants.ts`; `audit-event.de.ts`, `audit-event-resource.de.ts`; `AuditsModule`, `audit-producer.provider.ts`, `SQSAuditEventProducer`; the audit call in the upload, approve v1/v2, unapprove and recategorize services |
| Findings | **Recategorize dispatches nothing** (service `:24-44`). Upload sends `CREATED` (`deliverable-upload.service.ts:112-115`); approve v1/v2 send `APPROVED`, one event per file (`v2.service.ts:140-146`); unapprove sends `UNAPPROVED`. Each is awaited after the TS returns (post-commit). The resource is FILE, with `resourceName: fileName`, `resourcePath: filePath`, `resourceBucket` and states `{path, bucket, fileName}`. **No type or collection is sent.** `identity: user.identity` sends the whole user. `AUDIT_EVENT_TYPE` has 8 past-tense literals and no categorize type; `AuditEventResourceType.FILE` exists. SQS failures are logged, return `false` and never throw. There is **no** `.catch(console.error)` anywhere in `src` any more, so PRDV-16192 area 5's note on that is out of date |
| Status | fully-inspected |
| Commit | callisto `59b1abd3` · 2026-09-23 |
| Evidence | `src/proceedings/domain/sub-domains/proceeding-file-audit/domain/aggregators/proceeding-file-audit.aggregator.ts:16-68`; `.../proceeding-file-audit.param.ts:18-29`; `.../proceeding-file-to-audit-event.assembler.ts:32-39`; `.../proceeding-file-to-audit.converter.ts:18-37`; `src/audits/constants.ts:1-19`; `audits.module.ts:13-25`; `SQSAuditEventProducer.apply:19-35` |
| Notes | Reopened relative to PRDV-16192 area 10 because the behavior differs. The formatted-`newState.path` precedent is `PermissionsToAuditEventAssembler`, inspected in PRDV-16192 area 5 and reused. The producer sends to the fixed name `SQS_AUDIT_EVENT_URL_OUTBOUND`, which matches the registered producer only if `AUDIT_EVENT_QUEUE_NAME` is unset or equal to it (a repro precondition) |

### 3. `callisto-back-end` — the data model (type, collection, path)

| Field | Value |
| --- | --- |
| Inspected | `deliverable-type.entity.ts`, `deliverable-collection.entity.ts`, `deliverable-collection.constants.ts`, `file-proceeding-track-type.entity.ts`; the seed `1781121204472`; `validate-deliverable-collection-required-for-approve.validator.ts`; `validate-dynamic-collection-name.validator.ts`; `get-deliverable-file-key.ts`; the recategorize batch projection |
| Findings | The type is `deliverable_types.value`, unique per (value, track); names repeat across tracks. Collections exist only on Transcript and Video: static ones, plus dynamic ones per proceeding. A `*DYNAMIC*` placeholder is used only for validation. A Transcript or Video file can still have a null collection, because upload and approve v1 don't enforce it. Dynamic names reject `\ / : * ? " < > \| %`. Seeded type names contain no `' | '`. `filePath` is the S3 key `MMYYYY/jobId/proceedingId/<uuid>.ext`. **The recategorize batch projection has no `filePath`/`bucket`**, but it does carry the previous type and collection ids. Only ids are loaded on every path; there are no name lookups today |
| Status | fully-inspected |
| Commit | callisto `59b1abd3` · 2026-09-23 |
| Evidence | `deliverable-type.entity.ts:18-35`; `deliverable-collection.entity.ts:25-53`; `deliverable-collection.constants.ts:3-6`; `validate-deliverable-collection-required-for-approve.validator.ts:52-77`; `validate-dynamic-collection-name.validator.ts:5-12`; `get-deliverable-file-key.ts:18`; `recategorize-deliverable-files-data.projection.ts:5-13`; `proceedings/infrastructure/repositories/file-attachment.repository.ts:76-88` |
| Notes | Planet Suite seed `1784739200003` not checked for `' | '` (frontier) |

### 4. `callisto-back-end` — feature flag

| Field | Value |
| --- | --- |
| Inspected | `feature-flag.aggregator.port.ts`; the flag checks in the upload, approve v1/v2, recategorize and unapprove services |
| Findings | `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED` gates only the Dione outbox writes. The DB writes and the Europa audits are not gated. Approve v1 hard-codes `false` |
| Status | fully-inspected |
| Commit | callisto `59b1abd3` · 2026-09-23 |
| Evidence | `feature-flag.aggregator.port.ts:10-13`; `deliverable-upload.service.ts:98-102`; `recategorize-deliverable-files.service.ts:28-35`; `approve-deliverable-files-v2.service.ts:60-64` |
| Notes | — |

### 5. `callisto-back-end` — existing specs (the detection gap)

| Field | Value |
| --- | --- |
| Inspected | `proceeding-file-audit/**/__specs__/*` (aggregator, dispatcher, assembler, converter); the GCA service specs (approve v1/v2, upload, unapprove, recategorize); the TS `__specs__` for approve (5), recategorize (5), unapprove (2) and upload |
| Findings | The approve v1/v2, upload and unapprove service specs each assert their audit dispatch. **The recategorize service spec has no audit assertion, and the 5 recategorize TS specs never mention audit.** No test ties the Atlas literal list to Callisto's enum |
| Status | fully-inspected |
| Commit | callisto `59b1abd3` · 2026-09-23 |
| Evidence | `src/proceedings/domain/sub-domains/proceeding-file-audit/domain/aggregators/__specs__/proceeding-file-audit.aggregator.spec.ts`; `.../__specs__/proceeding-file-to-audit.converter.spec.ts`; `src/granting-client-access/domain/services/*/__specs__/`; `src/granting-client-access/domain/transaction-scripts/recategorize-deliverable-files-ts/__specs__/` |
| Notes | This is where the red→green test goes: the recategorize service spec |

### 6. `europa-back-end` — enums, filter, projection, auth, swagger

| Field | Value |
| --- | --- |
| Inspected | `git log af49e79..HEAD -- src/audits-event`; `src/audits-event/constants.ts` and every use of it; `search-audit-events-paginated.request.dto.ts`; `search-params-to-mongo-query.converter.ts`; `search-audit-events-paginated.transaction.script.ts` (current); the projection, response DTO and responder; `configure-swagger.ts`; `search-audits-paginated.action.ts`; `auth.module.ts`, `auth.middleware.ts`; `__specs__` for the TS, the converter and the application layer |
| Findings | One commit since the baseline: `d71f2bd` (PRDV-16192) adds a `PERMISSIONS_UPDATED`-only path branch; every other type still uses `firstResource` with `newState.path ?? oldState.path ?? resourcePath`. Europa's `AUDIT_EVENT_TYPE` (`CREATED`, `LOGIN`, `LOGOUT`) is used only by the login/logout converters; `AuditEventResourceType` is unused. `type`/`resourceType` are `@IsOptional() @IsString()` with no enum anywhere, including swagger. The filter is an exact, case-sensitive equality on one value (`$and`, no `$in`). `searchTerm` does a regex over `newState.path`. The projection returns `userEmail`, `userName` (first + last), `createdAt`, `resourceName`, `resourceType`, `path` and `bucket`; there is no `userId`. **There are no role guards:** auth middleware verifies the Cognito tokens only. Swagger is local-only and publishes no type enum. No spec covers the `PERMISSIONS_UPDATED` branch or multi-resource events |
| Status | fully-inspected — **Europa needs no change** for a new type |
| Commit | europa `1082fdad` · 2026-09-23 |
| Evidence | `src/audits-event/constants.ts:3-12`; `search-audit-events-paginated.request.dto.ts:55-63`; `search-params-to-mongo-query.converter.ts:38-46, 68-102`; `search-audit-events-paginated.transaction.script.ts:13, 57-100`; `search-audit-events-paginated.projection.ts:21-41`; `auth.module.ts:48-73`; `auth.middleware.ts:27-51`; `configure-swagger.ts:28-60` |
| Notes | Reopened relative to PRDV-16192 area 1 because the code changed (`d71f2bd`). Repeated query params probably fail `@IsString` with a 400 (inferred, not tested); this only matters for multi-select, which is not requested |

### 7. `atlas-front-end` — the Europa audit page (dropdown, chip, path, columns, route)

| Field | Value |
| --- | --- |
| Inspected | `git log 102e034d..HEAD -- src/europa`; `src/europa/utils/constants.ts`; `SearchFilters.vue` (Event Type and Resource Type selects); `useAuditSearch.ts`; `fetchAuditEvents.ts`; `SearchDataGrid.vue` (type chip, resourceType chip and path slots, `q-table` wrap); `auditEventColumns.ts`; `useTimezoneToggle.ts`; `useColumnOrderSettings.ts`; `src/globalRouter/routes.ts`; `src/europa/**/__specs__` |
| Findings | The **only** options source is `eventTypes` (`constants.ts:3-15`, raw upper-case strings). The label equals the value, there is no i18n in `src/europa`, and chip colours come from `eventTypeColors` (`:19-30`, grey fallback). Values go through unchanged as `type=<literal>` to `/search-paginated`. `FILE` is already in `resourceTypes`. `SearchDataGrid.vue:309-324` splits the path on `' | '` with bold labels **only for `PERMISSIONS_UPDATED`**; other types render as one unwrapped line (`q-table--no-wrap`). Columns: Event Type, User Email, User Name, Resource (fileName), Resource Type, Path, Bucket, Date (Local/UTC). The route requires `AUDIT` + `READ`. There are only 2 specs in `src/europa` (`useAuditSearch`, `formatDateForDisplay`), and **none for the grid, the constants or the filters** |
| Status | fully-inspected |
| Commit | atlas `26eaa0bb` · 2026-09-23 |
| Evidence | `src/europa/utils/constants.ts:3-30`; `SearchFilters.vue:248-280`; `fetchAuditEvents.ts:26-45`; `SearchDataGrid.vue:146-148, 192-202, 289-324`; `auditEventColumns.ts:7-79`; `useTimezoneToggle.ts:28-44`; `src/globalRouter/routes.ts:35-52` |
| Notes | Reopened relative to PRDV-16192 area 7 because the code changed (`c2814144` added the path slot; PRDV-14304 changed the date filters). No new column is proposed, so the `localStorage` column-settings migration concern does not apply |

### 8. `atlas-front-end` — categorization request call sites (the Callisto UI)

| Field | Value |
| --- | --- |
| Inspected | Upload (GCA on/off) and drag-and-drop through `ProceedingDetailPage.vue` → `FileUploadWrapper` → `useUploadStart`/`useUploadComplete`; approve through `useApproveFlow` → `useApproveFiles` → `api/requests/approveFiles.ts`; recategorize through `useRecategorizeFlow` → `useRecategorizeDeliverableFiles` → `api/requests/recategorizeDeliverableFiles.ts`; `api/constants.ts` |
| Findings | Upload and drag-and-drop send **one file per request** to `POST …/upload-complete`, with a per-file `deliverableTypeId` when GCA is on and none when it's off. Approve sends **many files** to `POST …/approve-files-for-delivery` (v1) or `…/v2/…` (GCA on). Recategorize sends **many files** to `PATCH …/recategorize-deliverable-files`, with a single track per batch. Unapprove sends many to `POST …/unapprove-files-for-delivery` |
| Status | fully-inspected — confirms the Callisto surface (area 1) from the client side |
| Commit | atlas `26eaa0bb` · 2026-09-23 |
| Evidence | `ProceedingDetailPage.vue:220-223, 257-285, 309-368`; `useUploadComplete.ts:16-50`; `api/requests/approveFiles.ts:20-80`; `api/requests/recategorizeDeliverableFiles.ts:21-32`; `api/constants.ts:68-69, 114-117` |
| Notes | No front-end change is needed on these call sites; the change is server-side |

### 9. `callisto-back-end` — Phase 3 reconcile: result shapes, name lookups, architecture rules (reopened from the frontier)

| Field | Value |
| --- | --- |
| Inspected | Upload-complete DTO, command, params, `CreateDeliverableFileAttachmentAssembler`, TS return, projection; approve TS `plans` (`:140-154`), `resolveBatchCollection` (`:205-249`), `fetchFilesByIds`, the projection converter; `DeliverableTypeRepository`, `DeliverableCollectionRepository`, `DeliverableTypeDeliverableCollectionRepository`; module wiring of `ProceedingFileAuditModule`/`ProceedingsModule`/GCA; `.dependency-cruiser.ts` + `fitness-functions-rules/architecture-rules/*`; `.cursor/rules/architecture-patterns.mdc`, `type-files.mdc`, `type-colocation.mdc`; the `fetchFilesByProceedingId` select and its callers; every `deliverable_types` seed |
| Findings | **Upload:** `deliverableTypeId` is optional at every layer, and it is saved as `null` when absent (`create-deliverable-file-attachment.assembler.ts:25-45`). At runtime the returned object carries `fileAttachment.deliverableTypeId` and `deliverableCollectionId` (dynamic resolved), but the static projection hides them (`upload-complete-deliverable-file.projection.ts:5-11`). No collection name is returned. **Approve:** `processedFiles` are bare `File` rows with no attachment loaded (`proceeding-file.repository.ts:215-219`). The per-file resolved ids live only in TS-local `plans`. v2's dynamic collection id is known only inside the TS, so the TS projection must grow. **Names:** there is no bulk lookup method. `DeliverableTypeRepository` is available to GCA (via `DeliverableTypeLookupModule`) and to `ProceedingsModule`. `DeliverableCollectionRepository` is provided in GCA only, and `ProceedingsModule` can't import GCA (a cycle). No existing assembler resolves type or collection names for files. **Rules (depcruise, all `error`):** a TS may not import an aggregator; services may not import converters; converters may not import repositories or other converters; assemblers may not import assemblers. GCA is exempt from the domain-boundary rule as a source, and it already injects `ProceedingFileAuditAggregator` by class. **Recategorize:** adding `file.filePath` and `file.bucket` to the `fetchFilesByProceedingId` select touches 4 production callers, but low risk: the GET listing converter copies explicit fields. The TS returns only `{processedFileIds}`, so it must grow. **Seeds:** no type value contains `' \| '` or `': '` (Planet Suite: `Planet Draft`, `Planet Sync`), and there is no save method for types |
| Status | fully-inspected |
| Commit | callisto `59b1abd3` · 2026-09-23 |
| Evidence | `upload-complete-deliverable-file.request.dto.ts:91-94`; `upload-complete-deliverable-file.transaction.script.ts:59-63, 79-86, 104-148`; `approve-deliverable-files.transaction.script.ts:140-154, 205-249, 360-373`; `approve-deliverable-files-v2.service.ts:128-139`; `deliverable-type.repository.ts:18-44`; `deliverable-collection.repository.ts:26-99`; `granting-client-access.module.ts:82, 95, 100`; `proceedings.module.ts:113-115, 185, 212`; `proceeding-file-audit.module.ts:8-19`; `transaction-scripts.rules.ts`; `services.rules.ts`; `converters.rules.ts:14-35`; `assemblers.rules.ts:13-20`; `domain-boundaries.rules.ts:27-52`; `proceedings/infrastructure/repositories/file-attachment.repository.ts:37-91`; seeds `1781121204472:11-47`, `1784739200003` |
| Notes | Reopened from the Phase 2 frontier. Resolved facts are recorded in report §13. `architecture-patterns.mdc:1280` ("always use ports for cross-domain") conflicts with existing practice (class injection of the aggregator), which depcruise does not enforce for GCA. The spec follows precedent and records the deviation |

### 10. `callisto-back-end` — spec home and precedent specs

| Field | Value |
| --- | --- |
| Inspected | `docs/specs/README.md`; `docs/specs/atlas-client-access/deliverable-management/` listing; PRDV-15369 recategorize story spec and PRDV-16314 recategorize-endpoint spec, grepped for `audit\|europa\|categoriz`; `atlas-front-end/docs/specs/README.md` |
| Findings | Any ticket with backend work → `callisto-back-end/docs/specs/`, FE section included; the top-level folder is the kebab-case ClickUp **Project Name**. **Neither recategorize spec mentions audit or Europa**, which confirms the origin: the audit was never specified for recategorize. How specs are reviewed isn't documented in the repo |
| Status | fully-inspected |
| Commit | callisto `59b1abd3`, atlas `26eaa0bb` · 2026-09-23 |
| Evidence | `callisto-back-end/docs/specs/README.md`; `.../6-story-PRDV-15369-recategorize-files-by-deliverable-type-and-collection/*.md` (no audit hits); `.../PRDV-16314-endpoint-recategorize-files.md` (no audit hits); `atlas-front-end/docs/specs/README.md:5-12` |
| Notes | INT-138's ClickUp Project Name isn't in any artifact, so it's asked in the grill |

## Not yet inspected (frontier)

_Updated at Phase 3 reconcile, 2026-09-23. Items resolved by area 9 are struck through and kept for the record._

- **A live Callisto → SQS → Europa → Atlas event.** Everything is still proven in code only. This is the highest-value observation, and it is deferred to Phase 5 manual verification (test plan M-steps).
- ~~Whether upload-complete sets a deliverable type when GCA is off~~ → it doesn't: the type is saved as `null` (area 9).
- ~~Whether approve's `processedFiles` carries type and collection ids~~ → no. The ids live only in TS-local `plans`, so the TS projection must grow (area 9).
- ~~Bulk name-lookup methods and module boundaries~~ → there are none; they must be added or looped. The collection repo is GCA-only (area 9).
- ~~callisto `.cursor/rules` placement~~ → resolved by the depcruise rules (area 9).
- ~~Planet Suite seed `1784739200003` for `' | '`~~ → clean (area 9).
- **Dione outbox retention.** Only relevant if D5 chooses backfill.
- **Whether any admin path outside callisto creates deliverable types.** Not determinable from this repo. It would matter only if a user-created type name could contain `' | '`.
