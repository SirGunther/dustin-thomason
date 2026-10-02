---
ticket: INT-139
tags: [neptune, granting-client-access, proceedings, audit, europa, atlas]
author: Dustin Thomason
created: 2026-09-29
modified: 2026-09-29
modified_by: Dustin Thomason
---

# INT-139: RECATEGORIZE audit records for deliverable type recategorization

> **Ticket:** INT-139
>
> **Repos (branch `INT-139`, cut from `INT-138`):** `callisto-back-end` sends the record, `europa-back-end` builds its path, `atlas-front-end` lists the type on the Europa audit page.
>
> **Depends on:** INT-138 (`CATEGORIZE` audit records). INT-139 changes code on the `INT-138` branch.

Citations are `file:line` on branch `INT-138`. Prefixes: `gca/` = callisto `src/granting-client-access/`; `pfa/` = callisto `src/proceedings/domain/sub-domains/proceeding-file-audit/`; `eu/` = europa-back-end `src/audits-event/`; `atlas/` = atlas-front-end `src/europa/`.

---

## Story and acceptance criteria (from the ticket)

As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.

- Ops can view a log in Europa for deliverable type recategorization
- The log displays the following details: file path; user info; date/time; recategorization actions taken
- A new Event Type is created for this action: Recategorize
  - This event type is added to the Event Type drop down in Europa
- Resource Type for this action is: File
- Path format:
  - Filepath: [file path]
  - Deliverable Type: [old deliverable type] → [new deliverable type]
  - Collection: (old collection if applicable, [collection], if not, "N/A") → (new collection if applicable, [collection], if not, "N/A")

---

## Problem

A recategorize already sends one audit record per file, but it is a `CATEGORIZE` record that carries only the categorization after the change.

- The recategorize service dispatches `dispatchFileAuditCategorizedEvent` (`gca/domain/services/recategorize-deliverable-files-service/recategorize-deliverable-files.service.ts:50-57`).
- The recategorize TS builds each record from the requested type and destination collection, with `priorCategorization: null` (`gca/domain/transaction-scripts/recategorize-deliverable-files-ts/recategorize-deliverable-files.transaction.script.ts:175-197`).
- The converter puts the same state in `oldState` and `newState` (`pfa/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/proceeding-file-categorization-to-audit.converter.ts:40-49`).

Ops can't see what a file was recategorized from, and can't filter recategorizations apart from other categorizations.

## Requirement

Every file a recategorize processes produces its own audit record with event type `RECATEGORIZE` and resource type `FILE`. Ops can filter to it from the Event Type dropdown, and it shows who did it, when, and:

`Filepath: <file path> | Deliverable Type: <old> → <new> | Collection: <old or N/A> → <new or N/A>`

## Solution

- **callisto-back-end:** the recategorize service sends `RECATEGORIZE` instead of `CATEGORIZE`. The record's `oldState` holds the type and collection names before the recategorize, and `newState` holds them after. Both are sent as separate fields, with no display text.
- **europa-back-end:** the paginated search builds the `RECATEGORIZE` path from `oldState` and `newState`.
- **atlas-front-end:** `RECATEGORIZE` is added to the Event Type dropdown and to the types whose path renders on multiple lines.

## Scope

| In scope | Out of scope |
| --- | --- |
| The recategorize action (`PATCH /recategorize-deliverable-files`, `gca/application/controllers/actions/recategorize-deliverable-files-action/recategorize-deliverable-files.action.ts:19`) | Upload, approve v1/v2 and unapprove: they keep dispatching `CATEGORIZE`, and their triggers and event type do not change. Their state payload does change, to structured fields, through the Prerequisite |
| One `RECATEGORIZE` record per processed file | Europa's `/search` endpoint: it returns the stored `newState.path`, as it does for `PERMISSIONS_UPDATED` |
| europa-back-end paginated search path for `RECATEGORIZE` | Free-text search by deliverable-type or collection name (LD-015) |
| Callisto sends structured state for `CATEGORIZE` too (Prerequisite, LD-002). This goes beyond the ticket, which asks only for recategorization; LD-001 and LD-002 authorize it because the current Callisto and europa-back-end contract disagree (Prerequisite) | |
| Europa audit page event type list | A chip colour for `RECATEGORIZE` (LD-011) |
| | Backfill of past recategorizations |

---

## Locked Decisions From Q and A

IDs match the ticket's locked-decision ledger.

| Decision | Implementation consequence |
| --- | --- |
| LD-001 Callisto sends structured state; europa-back-end builds the path text | No labels, separators or `N/A` in Callisto. europa-back-end owns the display format |
| LD-002 Structured `CATEGORIZE` state (INT-138 prerequisite) | See Prerequisite below |
| LD-003 `oldState` = names before, `newState` = names after | The converter builds `oldState` from the old names when present |
| LD-004 Event type `RECATEGORIZE` | Same spelling in Callisto `AUDIT_EVENT_TYPE` and atlas-front-end `eventTypes`; europa-back-end's Event Type filter is an exact, case-sensitive match (`eu/domain/transaction-scripts/search-audit-events-paginated-TS/converters/search-params-to-mongo-query.converter.ts:38-39`) |
| LD-005 Recategorize sends `RECATEGORIZE` instead of `CATEGORIZE` | The recategorize service calls the new port method; no `CATEGORIZE` from recategorize |
| LD-006 Path format with `→`; `N/A` per side | europa-back-end branch below |
| LD-007 One record per processed file, one `FILE` resource | Unchanged from INT-138 |
| LD-008 A no-op recategorize still records | `Transcript → Transcript` is a valid row |
| LD-009 Old values come from the batch file's `currentDeliverableTypeId` / `currentDeliverableCollectionId` | No new read for ids; old names resolve in the assembler's existing `findByIds` calls |
| LD-010 Only `/search-paginated` builds the path | No change to `/search` |
| LD-011 atlas-front-end: `eventTypes` + `MULTI_PART_PATH_TYPES`; no colour | Grey fallback chip (`atlas/pages/HomePage/SearchDataGrid/SearchDataGrid.vue:163`) |
| LD-012 No migration, route, DTO or europa-back-end schema change | Sections 3–7 are N/A |
| LD-013 Branch `INT-139` from `INT-138` | All three repos |
| LD-014 europa-back-end deploys with or before Callisto | See Rollout |
| LD-015 Free-text search does not match deliverable-type or collection names | The Event Type filter is how Ops finds the records. Free text does match the event `type` as a case-insensitive substring, so "categorize" also returns `RECATEGORIZE` rows (`…/search-params-to-mongo-query.converter.ts:84-100`) |

---

## Prerequisite: structured CATEGORIZE state (LD-002)

This change is part of INT-139 and is made first, as its own commit, unless `INT-138` already contains it when `INT-139` is cut. It is outside the ticket's literal scope (recategorization only) and is included under LD-001 and LD-002. Only the converter spec asserts the labelled string, so no other Callisto spec changes for it. Today Callisto builds one labelled string and copies it into both states (`pfa/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/proceeding-file-categorization-to-audit.converter.ts:32`, `:40-49`), and europa-back-end's `CATEGORIZE` branch labels it again (`eu/domain/transaction-scripts/search-audit-events-paginated-TS/search-audit-events-paginated.transaction.script.ts:76-85`). Until this lands, every `CATEGORIZE` row reads `Filepath: Filepath: … | … | Deliverable Type: N/A | Collection: N/A`.

- `src/audits/domain/domain-events/audit-event-resource.de.ts:12-17`: `ResourceState` gains `deliverableType?: string | null` and `collection?: string | null`.
- `pfa/…/proceeding-file-categorization-to-audit.converter.ts`: for `CATEGORIZE`, `oldState` and `newState` become `{ path: file.filePath, bucket: file.bucket, fileName: file.fileName, deliverableType, collection }`, each name the value or null (blank and whitespace-only names become null). Remove the label, separator and `N/A` constants and `toCategorizationPath` / `formatOrNotApplicable` (`:10-19`, `:53-78`).
- The converter spec asserts the structured fields instead of the `' | '`-joined string (`__specs__/proceeding-file-categorization-to-audit.converter.spec.ts:126`, `:190-191`).

europa-back-end's `CATEGORIZE` branch already reads these fields (`:79-85`), and atlas-front-end does not change.

---

## Record contract

A `RECATEGORIZE` event carries one resource per file. What europa-back-end shows is built from these fields when the record is read.

| Field | Value |
| --- | --- |
| `type` | `RECATEGORIZE` |
| `resourceType` | `FILE` |
| `resourceId` / `resourceName` / `resourcePath` / `resourceBucket` | file id, file name, S3 key, bucket (same as `CATEGORIZE`) |
| `oldState` | `{ path, bucket, fileName, deliverableType: <name before or null>, collection: <name before or null> }` |
| `newState` | `{ path, bucket, fileName, deliverableType: <name after>, collection: <name after or null> }` |
| `identity` | the requesting user, set from `input.user.identity` by the event assembler (`pfa/…/proceeding-file-to-audit-event.assembler.ts:37`); europa-back-end returns it as `userEmail` and `userName` (`eu/…/search-audit-events-paginated.transaction.script.ts:105-107`) |
| `createdAt` | set to `new Date()` when Callisto builds the event (`pfa/…/proceeding-file-to-audit-event.assembler.ts:71`); europa-back-end returns it as an ISO string (`eu/…/search-audit-events-paginated.transaction.script.ts:104`) |

Both `identity` and `createdAt` come from the existing event assembly; INT-139 does not change them. atlas-front-end shows them in the User Email, User Name and Date columns (`atlas/pages/HomePage/SearchDataGrid/auditEventColumns.ts:16-24`, `:56-57`).

Displayed path, example:

`Filepath: 092026/5512/881/3f2a…7b44.pdf | Deliverable Type: Transcript → Word Document | Collection: Full Transcript → N/A`

Atlas renders it on three lines with the label in bold, using the existing splitter (`atlas/pages/HomePage/SearchDataGrid/SearchDataGrid.vue:83-85`).

---

## 1. Folder hierarchy

No new paths. Changed files (`~`):

```
callisto-back-end/src/
├── audits/constants.ts                                                        ~
├── audits/domain/domain-events/audit-event-resource.de.ts                     ~ (Prerequisite)
├── granting-client-access/domain/
│   ├── projections/file-categorization-audit.projection.ts                   ~
│   ├── assemblers/file-categorization-audit-assembler/
│   │   ├── file-categorization-audit.assembler.ts                            ~
│   │   └── __specs__/file-categorization-audit.assembler.spec.ts             ~
│   ├── predicates/is-categorization-audit-due.predicate.ts                   ~ (comment only)
│   ├── ports/client-access-file-audit.port.ts                                ~
│   ├── transaction-scripts/recategorize-deliverable-files-ts/
│   │   ├── recategorize-deliverable-files.projection.ts                      ~ (comment only)
│   │   ├── recategorize-deliverable-files.transaction.script.ts              ~
│   │   └── __specs__/recategorize-deliverable-files.transaction.script.spec.ts  ~
│   └── services/recategorize-deliverable-files-service/
│       ├── recategorize-deliverable-files.service.ts                         ~
│       └── __specs__/recategorize-deliverable-files.service.spec.ts          ~
└── proceedings/domain/sub-domains/proceeding-file-audit/
    ├── domain/aggregators/
    │   ├── proceeding-file-audit-categorized.param.ts                        ~
    │   ├── proceeding-file-audit.aggregator.ts                               ~
    │   └── __specs__/proceeding-file-audit.aggregator.spec.ts                ~
    └── infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/
        ├── proceeding-file-to-audit-event.assembler.ts                       ~
        ├── proceeding-file-categorization-to-audit.converter.ts              ~ (Prerequisite + RECATEGORIZE)
        └── __specs__/ (event assembler spec, converter spec)                 ~

europa-back-end/src/audits-event/domain/transaction-scripts/search-audit-events-paginated-TS/
├── search-audit-events-paginated.transaction.script.ts                       ~
└── __specs__/search-audit-events-paginated.transaction.script.spec.ts        ~

atlas-front-end/src/europa/
├── utils/constants.ts                                                        ~
├── utils/__specs__/constants.spec.ts                                         ~
└── pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts            ~
```

## 2. New classes

N/A: no new classes. Modified classes:

| Class / file | Change |
| --- | --- |
| `ResourceState` (`src/audits/domain/domain-events/audit-event-resource.de.ts:12-17`) | Prerequisite: add `deliverableType?: string \| null` and `collection?: string \| null` |
| `AUDIT_EVENT_TYPE` (`src/audits/constants.ts:19`) | Add `RECATEGORIZE: 'RECATEGORIZE'` after `CATEGORIZE` |
| `FileCategorizationAuditAssembler` (`gca/domain/assemblers/…/file-categorization-audit.assembler.ts`) | Input gains optional `oldCategorization` (ids). The type and collection id lists passed to the existing two `findByIds` calls include the old ids, so a batch still makes one read per table. Each output carries `oldCategorization` (names) only when its input had it |
| `IsCategorizationAuditDuePredicate` (`gca/domain/predicates/is-categorization-audit-due.predicate.ts:11-12`) | Doc comment only: `priorCategorization` is null when "upload creates the attachment"; drop "and recategorize always sets a type", because recategorize now passes its prior ids. The predicate's logic is unchanged, and a recategorize is always due because it always sets a type |
| `RecategorizeDeliverableFilesTS.assembleCategorizationAudits` (`…/recategorize-deliverable-files.transaction.script.ts:175-197`) | Each candidate's `priorCategorization` is `{ deliverableTypeId: file.currentDeliverableTypeId, deliverableCollectionId: file.currentDeliverableCollectionId }` instead of `null` (`:191`). Each kept candidate goes to the assembler with `oldCategorization` set to that same value. Update the doc comment (`:170-174`) from CATEGORIZE to RECATEGORIZE records |
| `ClientAccessFileAuditPort` (`gca/domain/ports/client-access-file-audit.port.ts:15-19`) | Add `dispatchFileAuditRecategorizedEvent(params: ClientAccessFileCategorizedAuditParams): Promise<boolean>` |
| `RecategorizeDeliverableFilesService` (`…/recategorize-deliverable-files.service.ts:50-57`) | Call `dispatchFileAuditRecategorizedEvent` instead of `dispatchFileAuditCategorizedEvent`, once per record, after the TS resolves |
| `ProceedingFileAuditAggregator` (`pfa/domain/aggregators/proceeding-file-audit.aggregator.ts:72-78`) | Add `dispatchFileAuditRecategorizedEvent(params)`, which calls `proceedingFileAuditDispatcher.applyCategorized({ ...params, eventType: AUDIT_EVENT_TYPE.RECATEGORIZE })` |
| `ProceedingFileToAuditEventAssembler.applyCategorized` (`pfa/…/proceeding-file-to-audit-event.assembler.ts:32-47`) | Pass `oldCategorization: input.oldCategorization` to the converter along with `file` and `categorization` (`:41-42`) |
| `ProceedingFileCategorizationToAuditEventResourceConverter` (`pfa/…/proceeding-file-categorization-to-audit.converter.ts`) | Prerequisite: both states become structured for every record, replacing the labelled string (`:32`, `:40-49`). Then: input `Pick` adds `'oldCategorization'` (`:21-24`); `oldState` is built from `oldCategorization ?? categorization`, `newState` from `categorization`. A `CATEGORIZE` record (no `oldCategorization`) gets identical structured states |
| `SearchAuditEventsPaginatedTS` (`eu/…/search-audit-events-paginated.transaction.script.ts`) | Add `RECATEGORIZE` constant (next to `:14`) and branch (below) |
| `eventTypes`, `MULTI_PART_PATH_TYPES` (`atlas/utils/constants.ts:3-16`, `:33-36`) | Add `'RECATEGORIZE'` to both |

**Unchanged:** `ProceedingFileAuditDispatcher` and its port. `applyCategorized` already passes the params, event type included, to the event assembler (`pfa/infrastructure/dispatchers/proceeding-file-audit.dispatcher.ts`). The upload, approve and unapprove services and TSs keep calling `dispatchFileAuditCategorizedEvent` and never set `oldCategorization`.

**Why a separate `oldCategorization` field:** approve and unapprove already pass `priorCategorization` ids to the assembler as part of each candidate, for the predicate only (`gca/…/approve-deliverable-files.transaction.script.ts:401-404`, `gca/…/unapprove-deliverable-files.transaction.script.ts:262-265`). If the assembler resolved names from that field, those two paths would read names no record displays. `oldCategorization` is set by recategorize alone.

## 3. New entities

N/A: no table or entity change.

## 4. Modified entities

N/A. europa-back-end's `AuditEventResource.oldState` / `newState` already declare optional `deliverableType` and `collection`, typed `@Prop({ required: true, type: Object })` (`eu/domain/entities/audit-event/audit-event-resource.entity.ts:16-30`). Callisto's `ResourceState` is a domain-event type (Prerequisite).

## 5. New migrations

N/A: no schema change in Callisto or europa-back-end.

## 6. New migration classes

N/A: no migrations.

## 7. New DTOs

N/A. The recategorize request and its `{ processedFileIds }` response are unchanged (`gca/…/recategorize-deliverable-files.service.ts:58`). europa-back-end's paginated search response already returns `path` as a string.

## 8. Projections and domain inputs

```ts
// CHANGED gca/domain/projections/file-categorization-audit.projection.ts
/** A deliverable type and collection by name; a name is null when unset. */
export type FileCategorizationNamesProjection = {
	readonly deliverableTypeName: string | null;
	readonly collectionName: string | null;
};

export type FileCategorizationAuditProjection = {
	readonly file: FileCategorizationAuditFileProjection;
	readonly categorization: FileCategorizationNamesProjection;
	/** The names before the write. Present on a RECATEGORIZE record only. */
	readonly oldCategorization?: FileCategorizationNamesProjection;
};
```

```ts
// CHANGED gca/domain/assemblers/file-categorization-audit-assembler/file-categorization-audit.assembler.ts
export type FileCategorizationAuditAssemblerInput = {
	readonly file: FileCategorizationAuditFileProjection;
	readonly categorization: FileAttachmentCategorizationProjection;
	/** The ids before a recategorize, resolved to names with `categorization`. */
	readonly oldCategorization?: FileAttachmentCategorizationProjection;
};
```

```ts
// CHANGED pfa/domain/aggregators/proceeding-file-audit-categorized.param.ts
export type ProceedingFileAuditCategorizedParams = {
	readonly eventType?:
		| typeof AUDIT_EVENT_TYPE.CATEGORIZE
		| typeof AUDIT_EVENT_TYPE.RECATEGORIZE;
	readonly file: ProceedingFileAuditFile;
	readonly user: Partial<AuthUser>;
	readonly categorization: ProceedingFileAuditCategorization;
	/** The names before the write. Present on a RECATEGORIZE record only. */
	readonly oldCategorization?: ProceedingFileAuditCategorization;
};
```

`ClientAccessFileCategorizedAuditParams` (`gca/domain/ports/client-access-file-audit.port.ts:6-9`) picks up `oldCategorization` through `FileCategorizationAuditProjection`, so both port methods take the same params type. `RecategorizeDeliverableFilesProjection` (`…/recategorize-deliverable-files.projection.ts:6`) keeps its `categorizationAudits` field name and type.

---

## europa-back-end: RECATEGORIZE branch

Added to `SearchAuditEventsPaginatedTS.toItemProjection` (`eu/…/search-audit-events-paginated.transaction.script.ts:56`), after the `CATEGORIZE` branch (`:75-85`) and before the default branch (`:86`):

```ts
} else if (
	event.type === RECATEGORIZE &&
	event.auditEventResources?.length
) {
	const oldState = firstResource?.oldState;
	const newState = firstResource?.newState;
	path = [
		`Filepath: ${this.toDisplayValue(newState?.path ?? oldState?.path)}`,
		`Deliverable Type: ${this.toDisplayValue(oldState?.deliverableType)} → ${this.toDisplayValue(newState?.deliverableType)}`,
		`Collection: ${this.toDisplayValue(oldState?.collection)} → ${this.toDisplayValue(newState?.collection)}`,
	].join(' | ');
	bucket = newState?.bucket ?? oldState?.bucket ?? '';
}
```

`toDisplayValue` (`:120`) already returns `N/A` for null, empty and whitespace-only values. The separators match `PERMISSIONS_UPDATED` (`:64-71`).

---

## Cross-cutting

- **Companion ticket:** INT-138 (`CATEGORIZE`). INT-139 changes one of its paths: recategorize stops sending `CATEGORIZE` (LD-005).
- **Feature flags:** none added. The recategorize service dispatches audits whether or not `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED` is on (`…/recategorize-deliverable-files.service.ts:50-57`); the flag gates only the Dione outbox write (`…/recategorize-deliverable-files.transaction.script.ts:145-160`). Unchanged.

## Optional callouts

- **HTTP surface:** N/A. No route, method, body, status or auth change in Callisto or europa-back-end.
- **Registries and module wiring:** N/A. No new providers; every change is to an existing class.
- **Ports:** `ClientAccessFileAuditPort` gains `dispatchFileAuditRecategorizedEvent`, implemented by `ProceedingFileAuditAggregator` (bound to `CLIENT_ACCESS_FILE_AUDIT` by INT-138).
- **Domain events:** the audit event type `RECATEGORIZE`, sent on the existing audit SQS queue.
- **Domain exceptions:** N/A.
- **Authorization:** N/A.

## Spec tests

| Repo | Spec | Cases |
| --- | --- | --- |
| callisto | `file-categorization-audit.assembler.spec.ts` | Old ids given: old names resolved, and each repository's `findByIds` is called once with the distinct new and old ids together. Old id with no row: that old name is null. No old ids: the output has no `oldCategorization` (existing cases unchanged). A repository read failure rejects (existing `:223`) |
| callisto | `recategorize-deliverable-files.transaction.script.spec.ts` | Each record's old names come from the file's current type and collection. A file with no prior collection: old `collectionName` null. Two files on one attachment: each gets its own record with the same old names. The name lookup failing rolls back the recategorize (existing name-read failure case) |
| callisto | `recategorize-deliverable-files.service.spec.ts` | One `dispatchFileAuditRecategorizedEvent` per record, carrying `user`; `dispatchFileAuditCategorizedEvent` never called. No records: no dispatch. Validator, assembler or TS failure: no dispatch (existing `:340-377`) |
| callisto | `proceeding-file-audit.aggregator.spec.ts` | `dispatchFileAuditRecategorizedEvent` calls `applyCategorized` with `eventType: 'RECATEGORIZE'` and returns its result, true or false |
| callisto | `proceeding-file-to-audit-event.assembler.spec.ts` | `oldCategorization` reaches the converter; the event `type` is `RECATEGORIZE` |
| callisto | `proceeding-file-categorization-to-audit.converter.spec.ts` | Prerequisite: a `CATEGORIZE` record's states carry `path`, `bucket`, `fileName`, `deliverableType` and `collection` as raw values, with no labels, separators or `N/A`; a missing collection is null; blank and whitespace-only names are null (replacing the string assertions at `:126`, `:190-191`). `oldCategorization` given: `oldState` carries the old names, `newState` the new. Not given: `oldState` equals `newState` |
| europa | `search-audit-events-paginated.transaction.script.spec.ts` | Old and new type and collection: `Deliverable Type: A → B`, `Collection: C → D`. No old type: `N/A → B`. No collection either side: `Collection: N/A → N/A`. Blank values: `N/A`. No resources: path and bucket `''`. `CATEGORIZE` rows unchanged (existing `:285-435`) |
| atlas | `constants.spec.ts` | `eventTypes` and `MULTI_PART_PATH_TYPES` contain `RECATEGORIZE` |
| atlas | `SearchDataGrid.spec.ts` | A `RECATEGORIZE` path renders three lines with bold labels and the `→` values; the chip text is `RECATEGORIZE` with the grey fallback (the `CATEGORIZE` chip case, `:162-172`) |

**Knock-on edits to INT-138 tests:** the recategorize service and TS specs that expect a `CATEGORIZE` dispatch or record change to `RECATEGORIZE`. INT-138's manual test M-1 (recategorize two Transcript deliverables) now expects `RECATEGORIZE` rows.

**Manual end-to-end:** recategorize two files, one of them into a different collection. Expect:

- one `RECATEGORIZE` row per file, filterable from the Event Type dropdown, with Resource Type `FILE`;
- the Path showing the file path and the before and after type and collection;
- User Email and User Name matching the signed-in user who ran the recategorize, and a Date matching when it ran;
- no `CATEGORIZE` row from that recategorize;
- the stored record keeping `deliverableType` and `collection` in both `oldState` and `newState`.

## Acceptance criteria trace

| Ticket criterion | Where the spec covers it | Verified by |
| --- | --- | --- |
| Ops can view a log in Europa for recategorization | Solution; LD-005; europa-back-end branch | Manual end-to-end |
| file path | Record contract (`newState.path`); europa-back-end branch | europa-back-end spec; manual |
| user info | Record contract (`identity`) | Manual (User Email, User Name) |
| date/time | Record contract (`createdAt`) | Manual (Date) |
| recategorization actions taken | Record contract (`oldState` / `newState`); LD-003 | Converter, recategorize TS and europa-back-end specs; manual |
| New Event Type: Recategorize | LD-004 | Aggregator and service specs |
| Added to the Event Type drop down | LD-011 | atlas-front-end `constants.spec.ts`; manual |
| Resource Type: File | Record contract; LD-007 | Converter spec; manual |
| Path format, type old → new, collection old → new with N/A | LD-006; europa-back-end branch | europa-back-end spec; atlas-front-end `SearchDataGrid.spec.ts`; manual |

## Rollout

Deploy europa-back-end with or before Callisto (LD-014). A `RECATEGORIZE` record read before the new branch is live falls through to the default branch and shows its raw S3 key (`eu/…/search-audit-events-paginated.transaction.script.ts:86-97`). It displays in full once the branch is deployed, because the path is built on read.

Whether any deployed Europa already holds `CATEGORIZE` records written with the labelled-string path is not established. Check each environment before release: any such record renders double-labelled while europa-back-end's `CATEGORIZE` branch is live, whether or not the Prerequisite has shipped, because that branch labels the stored `newState.path` again (`eu/…/search-audit-events-paginated.transaction.script.ts:76-85`).
