---
ticket: INT-140
tags: [neptune, file-navigator, proceedings, audit, europa, atlas]
author: Dustin Thomason
created: 2026-09-29
modified: 2026-10-02
modified_by: Dustin Thomason
---

# INT-140: CREATED audit records for File Navigator proceeding creation

> **Ticket:** INT-140
>
> **Repos (branch `INT-140`):**
> - `callisto-back-end` sends the record. Branch from `origin/main` @ `59b1abd3`.
> - `europa-back-end` builds its path. Branch from `origin/main` @ `1082fdad`.
> - `atlas-front-end` lists the resource type and renders the path. Branch from `origin/INT-138` @ `36999e87`, stacked on PR #582.
>
> **Decisions:** [INT-140-locked-decisions.md](INT-140-locked-decisions.md). LD and F IDs below refer to that ledger.
>
> **Companions:** INT-138 (`CATEGORIZE`; atlas-front-end's multi-part path render comes from its PR #582). INT-139 (`RECATEGORIZE`). INT-140 does not depend on INT-139 (LD-008).

Citation prefixes, each on the branch the repo starts from:
- `pa/` = callisto `src/proceedings/domain/sub-domains/proceeding-audit/`. These files are the same on `main` and `INT-138`.
- `ps/` = callisto `src/proceedings/domain/services/proceeding-service/`.
- `eu/` = europa-back-end `src/audits-event/`, on `main`.
- `atlas/` = atlas-front-end `src/europa/`, on `origin/INT-138`.

---

## Story and acceptance criteria (from the ticket)

As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.

- Ops can view a log in Europa for proceeding creation
- The log displays the following details: user info; date/time; **File Navigator proceeding creation** action taken
- Event Type for this action is: **Created**
- The **Proceeding** Resource type is added to the Resource Type drop down in Europa (this should already exist, it's just not visible)
- Path format:
  - Path: [path] (date/job ID/proceeding ID)
  - Proceeding Name: [proceeding name]

Dev note: two endpoints create proceedings. Only the File Navigator one (`proceedingsService.createProceedings`) is in scope. AJSF (`jobSubmissionService.createProceedings`) is not.

---

## Problem

Creating a proceeding in File Navigator leaves no audit record. `ProceedingService.createProceedings` returns the aggregator result without dispatching anything (`ps/proceeding.service.ts:54-64`). The transaction script writes only the Dione outbox (`src/proceedings/domain/transaction-scripts/create-proceedings-TS/create-proceedings.transaction.script.ts:36-38`). The Europa audit page also has no `PROCEEDING` option in its Resource Type dropdown (`atlas/utils/constants.ts:18`), even though Callisto already defines that resource type (`src/audits/constants.ts:5`).

## Requirement

Each proceeding created from File Navigator produces its own audit record, with event type `CREATED` and resource type `PROCEEDING`. Ops can filter to these records from the Resource Type dropdown. Each record shows who created the proceeding, when, and:

`Path: <MMYYYY>/<job id>/<proceeding id> | Proceeding Name: <name>`

## Solution

- **callisto-back-end:**
  - `ProceedingService.createProceedings` reads the job date, creates the proceedings, and then sends one `CREATED` event per proceeding. It uses the existing proceeding audit chain, which gains a typed `applyCreated` path.
  - The record carries raw values (`newState: { path, value }`), with no display labels.
  - The job date is read before the create, so that read can't fail after the write. Dispatch errors propagate the same way they do for rename.
- **europa-back-end:** the paginated search builds `Path: … | Proceeding Name: …` for `CREATED` records whose resource type is `PROCEEDING`.
- **atlas-front-end:** `PROCEEDING` joins the Resource Type dropdown, and the path splits onto two lines only for `CREATED` + `PROCEEDING`.

## Scope

| In scope | Out of scope |
| --- | --- |
| `POST /proceedings` → `CreateProceedingsAction` → `ProceedingService.createProceedings` (LD-001) | AJSF `POST /proceeding-job-submission/proceedings`. It shares `ProceedingAggregator.createProceedings` and `CreateProceedingsTS`, so the dispatch lives in the service (LD-002) |
| One `CREATED` / `PROCEEDING` record per created proceeding (LD-006) | Proceeding rename: its records, converter and error propagation are unchanged (LD-016) |
| europa-back-end paginated search text for that pair (LD-009) | europa-back-end `/search`: it returns the stored `newState.path` |
| Europa audit page: the `PROCEEDING` option and the two-line path for that pair (LD-004, LD-010) | A new event type or chip colour: `CREATED` and its `positive` chip already exist (LD-003) |
| `value?: string` on europa-back-end's declared `newState`, which the new branch reads (LD-011) | Any migration, route, DTO or Swagger change (LD-013) |
| | Correcting existing declared-type mismatches, such as `oldState: null` and states with no bucket, in Callisto or europa-back-end (LD-011; LD-019 withdrawn) |
| | New error-handling behavior on the create endpoint: no catching or logging of dispatch errors in the service (LD-017) |
| | Backfill of past proceeding creations |

---

## Locked Decisions From Q and A

| Decision | Implementation consequence |
| --- | --- |
| LD-001 File Navigator only | Only `ProceedingService.createProceedings` changes among the create paths |
| LD-002 Dispatch in the service, after the aggregator returns | `ProceedingAggregator` and `CreateProceedingsTS` don't change, so AJSF sends nothing |
| LD-003 Existing `CREATED` | No new literal in any repo |
| LD-004 Existing `PROCEEDING`; Atlas adds it to `resourceTypes` | The europa-back-end filter is unchanged (exact match, `eu/domain/transaction-scripts/search-audit-events-paginated-TS/converters/search-params-to-mongo-query.converter.ts:42-45`) |
| LD-005 Path `MMYYYY/jobId/proceedingId`; job date read before the create | The format is the proceeding file-key prefix. A parity spec enforces it (LD-021) |
| LD-006 One event per proceeding | `Promise.all` over the created proceedings |
| LD-007 Record shape; `oldState: null`; `resourceBucket: ''` | See Record contract |
| LD-008 Callisto sends raw values; europa-back-end builds the text | No labels in Callisto; the europa-back-end branch below |
| LD-009 europa-back-end branch on `CREATED` + `PROCEEDING`; no `toDisplayValue`, no `N/A` | Both values are never blank (F-07, F-14) |
| LD-010 Atlas splits `CREATED` only for `PROCEEDING` | A new resource-scoped constant; `MULTI_PART_PATH_TYPES` is unchanged |
| LD-011 europa-back-end's declared `newState` gains `value?: string`; `oldState` is unchanged; `type: Object` kept | The new branch reads `newState.value` only |
| LD-012 Blank Bucket | The europa-back-end branch returns `newState.bucket ?? ''` |
| LD-013 No migration, route, DTO or Swagger change | Sections 3, 5, 6 and 7 are N/A |
| LD-014 Branch bases | See the header |
| LD-015 europa-back-end deploys with or before atlas-front-end | See Rollout |
| LD-016 Neighbours unchanged | Regression cases in Spec tests |
| LD-017 Failure behavior: job date read before the create; dispatch errors propagate, as for rename | See Failure behavior |
| LD-018 Who and when from the existing envelope | Assembler assertions and a manual check |
| ~~LD-019~~ Withdrawn | Callisto's `audit-event-resource.de.ts` is not touched |
| LD-020 A typed `applyCreated` path, separate from rename's `apply` | New param type, port method, dispatcher, assembler and converter methods |
| LD-021 Private month-year formatter in the new converter, taking a `Date`, plus a parity spec | No dependency from the audit sub-domain on the upload key helper |

No open questions.

---

## Record contract

One event per created proceeding, each with one resource.

| Field | Value | Source |
| --- | --- | --- |
| `type` | `CREATED` | Stamped by `ProceedingAuditAggregator.dispatchProceedingAuditCreatedEvent` |
| `identity` | `user.identity` of the `@VerifiedUserDecorator()` user: `userId`, `userEmail`, `userFirstName`, `userLastName`, `ipAddress`, `userAgent` | `CreateProceedingsAction` (`src/proceedings/application/controllers/actions/create-proceedings-action/create-proceedings.action.ts:22`) → service → assembler |
| `createdAt` | `new Date()` when the event is built | Assembler envelope (`pa/infrastructure/dispatchers/proceeding-to-audit-event-assembler/proceeding-to-audit-event.assembler.ts:26`) |
| `serviceName` | `auditConfigAccessor.serviceName` | Unchanged |
| `resourceType` | `PROCEEDING` | New converter |
| `id`, `resourceId` | proceeding id as a string | The rename converter does the same (`pa/…/proceeding-to-audit.converter.ts:15,17`) |
| `resourceName` | proceeding name | |
| `resourcePath` | proceeding path | The FILE converter precedent: `resourcePath` holds the same value as `newState.path` |
| `resourceBucket` | `''` | A proceeding has no bucket (LD-012) |
| `oldState` | `null` | Accepted and stored by europa-back-end (F-13) |
| `newState` | `{ path: '<MMYYYY>/<jobId>/<proceedingId>', value: '<name>' }` | Raw values, no labels (LD-008) |

europa-back-end returns `identity` as `userEmail` and `userName` (first plus last), and `createdAt` as an ISO string (`eu/…/search-audit-events-paginated.transaction.script.ts:92-97` on `main`). atlas-front-end shows these in the User Email, User Name and Date columns (`atlas/pages/HomePage/SearchDataGrid/auditEventColumns.ts:15-17,22-24,55-57`).

Displayed path, example: `Path: 092026/5512/881 | Proceeding Name: Day 1`. Atlas renders it on two lines with bold labels.

## Failure behavior (LD-017)

| Step | Failure | Result |
| --- | --- | --- |
| 1. `jobAggregator.getJobDateById(jobId)` | Rejects (for example `'Job date not found'`, `src/jobs/domain/aggregators/job.aggregator.ts:14-16`) | The error propagates. Nothing is created or dispatched |
| 2. `proceedingAggregator.createProceedings(...)` | Rejects, including a 409 `DuplicateProceedingError` | The error propagates. Nothing is dispatched |
| 3. One proceeding's `dispatchProceedingAuditCreatedEvent` | Resolves `false` (the SQS send failed; the producer has already logged it, `src/audits/infrastructure/adapters/outbound/producers/sqs/sqs-audit-event.producer.ts:31-34`) | The response is the created proceedings |
| 3. One proceeding's `dispatchProceedingAuditCreatedEvent` | Rejects | The error propagates, as rename's dispatch does (`ps/proceeding.service.ts:84-93`). The service adds no catch and no logger |

Reading the job date before the create removes the only step after the commit that is known to throw. What runs after the commit is `uuidv4()`, `new Date()`, config getters that have defaults (`src/audits/config/audit-config.accessor.ts:9-18`), string building, and the producer. The producer catches send errors and returns `false`. `user.identity` has already been dereferenced before the create (`ps/proceeding.service.ts:62`) (F-29). A rejection after commit would therefore take a programming error, and it is handled the way rename handles one. The response is an error, and a retry returns 409 (F-21). This is the accepted residual risk.

---

## 1. Folder hierarchy

New (`+`) and changed (`~`) files:

```
callisto-back-end/src/
└── proceedings/domain/
    ├── services/proceeding-service/
    │   ├── proceeding.service.ts                                                  ~
    │   └── __specs__/proceeding.service.spec.ts                                   ~
    └── sub-domains/proceeding-audit/
        ├── proceeding-audit.module.ts                                             ~ (+ converter provider)
        ├── domain/
        │   ├── aggregators/
        │   │   ├── proceeding-audit-created.param.ts                              +
        │   │   ├── proceeding-audit.aggregator.ts                                 ~
        │   │   └── __specs__/proceeding-audit.aggregator.spec.ts                  ~
        │   └── ports/proceeding-audit-dispatcher.port.ts                          ~
        └── infrastructure/dispatchers/
            ├── proceeding-audit.dispatcher.ts                                     ~
            ├── __specs__/proceeding-audit.dispatcher.spec.ts                      ~
            └── proceeding-to-audit-event-assembler/
                ├── proceeding-to-audit-event.assembler.ts                         ~
                ├── proceeding-creation-to-audit.converter.ts                      +
                └── __specs__/
                    ├── proceeding-to-audit-event.assembler.spec.ts                ~
                    └── proceeding-creation-to-audit.converter.spec.ts             +

europa-back-end/src/audits-event/domain/
├── entities/audit-event/audit-event-resource.entity.ts                            ~ (LD-011: + newState.value?)
└── transaction-scripts/search-audit-events-paginated-TS/
    ├── search-audit-events-paginated.transaction.script.ts                        ~
    └── __specs__/search-audit-events-paginated.transaction.script.spec.ts         ~

atlas-front-end/src/europa/
├── utils/constants.ts                                                             ~
├── utils/__specs__/constants.spec.ts                                              ~
└── pages/HomePage/SearchDataGrid/
    ├── SearchDataGrid.vue                                                         ~
    └── __specs__/SearchDataGrid.spec.ts                                           ~
```

Where the new files go, and why:
- **Param file.** It sits next to its consumer, the aggregator, the same way `proceeding-file-audit-categorized.param.ts` does on `INT-138`.
- **Converter file name.** It follows `{source}-to-{target}.converter.ts`, the same pattern as `proceeding-to-audit.converter.ts` and `proceeding-file-categorization-to-audit.converter.ts`.

## 2. New classes

| Class / type | Path |
| --- | --- |
| `ProceedingCreationToAuditEventResourceConverter` | `pa/infrastructure/dispatchers/proceeding-to-audit-event-assembler/proceeding-creation-to-audit.converter.ts` |
| `ProceedingAuditCreatedParams` (type) | `pa/domain/aggregators/proceeding-audit-created.param.ts` |

Modified:

| Class / file | Change |
| --- | --- |
| `ProceedingAuditAggregator` (`pa/domain/aggregators/proceeding-audit.aggregator.ts:16-23`) | + `dispatchProceedingAuditCreatedEvent(params)`, which calls `applyCreated` with `eventType: AUDIT_EVENT_TYPE.CREATED` |
| `ProceedingAuditDispatcherPort` (`pa/domain/ports/proceeding-audit-dispatcher.port.ts:7-9`) | + `applyCreated(input: ProceedingAuditCreatedParams): Promise<boolean>`. `apply` is unchanged |
| `ProceedingAuditDispatcher` (`pa/infrastructure/dispatchers/proceeding-audit.dispatcher.ts:19-24`) | + `applyCreated`. `apply` and `applyCreated` send through a private `sendAuditEvent` that makes the same producer call |
| `ProceedingToAuditEventAssembler` (`pa/…/proceeding-to-audit-event.assembler.ts`) | Gains a third constructor dependency (the new converter) and `applyCreated`. `apply` keeps its converter call and output, and builds its envelope through a private `toAuditEvent` shared with `applyCreated` |
| `ProceedingAuditModule` (`pa/proceeding-audit.module.ts:10-17`) | + `ProceedingCreationToAuditEventResourceConverter` provider |
| `ProceedingService` (`ps/proceeding.service.ts`) | Gains a `JobAggregator` dependency. `createProceedings` is rewritten |
| `AuditEventResource` (`eu/domain/entities/audit-event/audit-event-resource.entity.ts:16-26` on `main`) | + `value?: string` in `newState` only (LD-011) |
| `SearchAuditEventsPaginatedTS` (`eu/…/search-audit-events-paginated.transaction.script.ts` on `main`) | + `CREATED` and `PROCEEDING` constants (next to `:13`) and a branch |
| `atlas/utils/constants.ts` | + `'PROCEEDING'` in `resourceTypes` (`:18`); + `MULTI_PART_PATH_RESOURCE_TYPES` |
| `atlas/pages/HomePage/SearchDataGrid/SearchDataGrid.vue` | The split check (`:97`) consults the new constant |

**Unchanged:**
- `ProceedingToAuditEventResourceConverter` (rename) and `ProceedingAuditParams`.
- `ProceedingAggregator.createProceedings` and `CreateProceedingsTS`.
- `JobSubmissionService`.
- `src/audits/constants.ts`.
- `src/audits/domain/domain-events/audit-event-resource.de.ts`.

**Wiring needs no change.** `JobAggregator` is exported by `JobModule` (`src/jobs/job.module.ts:62`), which `ProceedingsModule` imports (`src/proceedings/proceedings.module.ts:111`).

## 3. New entities

N/A: no table or collection.

## 4. Modified entities

- **europa-back-end `AuditEventResource`.** A domain-specific Mongo sub-document class (`europa-back-end/src/audits-event/domain/entities/audit-event/audit-event-resource.entity.ts`). Only its TypeScript declaration changes. `@Prop({ required: true, type: Object })` stays, so the schema and stored documents don't change.
- **No Callisto entity changes.** `AuditEventResourceDomainEvent` is a domain-event type, not an entity.

```ts
// europa-back-end — audit-event-resource.entity.ts (on main); oldState (:16-20) is unchanged
@Prop({ required: true, type: Object })
newState: {
	path: string;
	bucket: string;
	value?: string;
};
```

`newState.value?: string` is the only declaration the new branch needs, because it reads `newState.value` and nothing from `oldState`. `oldState` is not changed.

Some payloads don't match the declared types: `oldState: null` from login and logout (`eu/…/create-login-event-params-to-audit-event.converter.ts:32`); proceeding rename's `oldState` of `null` or `{ value }`; and states without `bucket` from `PERMISSIONS_UPDATED`. These predate INT-140, and INT-140 leaves them as they are. `strictNullChecks` is `false` in both repos, so neither the compiler nor the runtime is affected.

## 5. New migrations

N/A: no schema change in Callisto (Postgres) or europa-back-end (Mongo, `type: Object`).

## 6. New migration classes

N/A: no migrations.

## 7. New DTOs

N/A:
- The create request (`CreateProceedingsRequestDTO`) and the `CreateProceedingsResponseDTO[]` response are unchanged (`create-proceedings.action.ts:23-28`).
- No Swagger decorator changes.
- europa-back-end's paginated response already returns `path` and `bucket` as strings.

## 8. Projections and domain inputs

```ts
// NEW pa/domain/aggregators/proceeding-audit-created.param.ts
import { AuthUser } from 'src/generic/auth/constants';
import { AUDIT_EVENT_TYPE } from 'src/audits/constants';

export type ProceedingAuditCreatedParams = {
	readonly eventType?: typeof AUDIT_EVENT_TYPE.CREATED;
	readonly proceeding: {
		readonly id: number;
		readonly value: string;
	};
	readonly jobId: number;
	readonly jobDate: Date;
	readonly user: Partial<AuthUser>;
};
```

`jobDate` is typed `Date`, which is what `JobAggregator.getJobDateById` declares (`job.aggregator.ts:12`). At runtime it is a `Date`: node-postgres (`pg` 8.23.0, `pg-types` 2.2.0) turns a `date` column into a local-midnight `Date`, and neither TypeORM's Postgres driver nor Callisto registers a different parser (F-30).

---

## callisto-back-end

### New converter

```ts
// NEW pa/infrastructure/dispatchers/proceeding-to-audit-event-assembler/proceeding-creation-to-audit.converter.ts
import { Injectable } from '@nestjs/common';
import { AuditEventResourceDomainEvent } from 'src/audits/domain/domain-events/audit-event-resource.de';
import { AuditEventResourceType } from 'src/audits/constants';
import { ProceedingAuditCreatedParams } from '../../../domain/aggregators/proceeding-audit-created.param';

@Injectable()
export class ProceedingCreationToAuditEventResourceConverter {
	apply({
		proceeding,
		jobId,
		jobDate,
	}: Pick<
		ProceedingAuditCreatedParams,
		'proceeding' | 'jobId' | 'jobDate'
	>): AuditEventResourceDomainEvent {
		const path = `${this.toMonthYear(jobDate)}/${jobId}/${proceeding.id}`;
		return {
			id: proceeding.id.toString(),
			resourceType: AuditEventResourceType.PROCEEDING,
			resourceId: proceeding.id.toString(),
			resourceName: proceeding.value,
			resourcePath: path,
			resourceBucket: '',
			oldState: null,
			newState: { path, value: proceeding.value },
		};
	}

	// Must match the proceeding file-key prefix (GetProceedingFileKey.getMonthYear).
	private toMonthYear(jobDate: Date): string {
		const month = (jobDate.getMonth() + 1).toString().padStart(2, '0');
		return `${month}${jobDate.getFullYear()}`;
	}
}
```

The converter imports no repository, converter, transaction script, service, mapper or assembler (`fitness-functions-rules/architecture-rules/converters.rules.ts`). The formatter is a private method, as `fitness-functions-rules/naming-rules/check-no-util-files.ts:162` directs for converter helpers.

It does not inject `GetProceedingFileKey`, because that helper is only provided in `ProceedingsModule` (`proceedings.module.ts:160`). `ProceedingsModule` imports `ProceedingAuditModule` (`:113`), so importing the other way would be circular. The parity spec keeps the two formats identical (LD-021).

### Assembler, dispatcher, port, aggregator

```ts
// ~ pa/…/proceeding-to-audit-event.assembler.ts
constructor(
	private readonly auditConfigAccessor: AuditConfigAccessor,
	private readonly proceedingToAuditEventResourceConverter: ProceedingToAuditEventResourceConverter,
	private readonly proceedingCreationToAuditEventResourceConverter: ProceedingCreationToAuditEventResourceConverter,
) {}

async apply(input: ProceedingAuditParams): Promise<AuditEventDomainEvent> {
	const { eventType, proceeding, user, oldValue } = input;
	return this.toAuditEvent({
		type: eventType,
		identity: user.identity,
		auditEventResources: [
			this.proceedingToAuditEventResourceConverter.apply(proceeding, oldValue),
		],
	});
}

async applyCreated(
	input: ProceedingAuditCreatedParams,
): Promise<AuditEventDomainEvent> {
	return this.toAuditEvent({
		type: input.eventType,
		identity: input.user.identity,
		auditEventResources: [
			this.proceedingCreationToAuditEventResourceConverter.apply({
				proceeding: input.proceeding,
				jobId: input.jobId,
				jobDate: input.jobDate,
			}),
		],
	});
}

private toAuditEvent(
	event: Pick<AuditEventDomainEvent, 'type' | 'identity' | 'auditEventResources'>,
): AuditEventDomainEvent {
	return {
		id: uuidv4(),
		createdAt: new Date(),
		serviceName: this.auditConfigAccessor.serviceName,
		...event,
	};
}
```

```ts
// ~ pa/domain/ports/proceeding-audit-dispatcher.port.ts
export type ProceedingAuditDispatcherPort = {
	apply(input: ProceedingAuditParams): Promise<boolean>;
	applyCreated(input: ProceedingAuditCreatedParams): Promise<boolean>;
};

// ~ pa/infrastructure/dispatchers/proceeding-audit.dispatcher.ts
async apply(input: ProceedingAuditParams): Promise<boolean> {
	return this.sendAuditEvent(await this.proceedingToAuditEventAssembler.apply(input));
}

async applyCreated(input: ProceedingAuditCreatedParams): Promise<boolean> {
	return this.sendAuditEvent(
		await this.proceedingToAuditEventAssembler.applyCreated(input),
	);
}

private async sendAuditEvent(auditEvent: AuditEventDomainEvent): Promise<boolean> {
	return await this.auditEventProducer.apply(
		this.auditConfigAccessor.sqsAuditEventUrl,
		auditEvent,
	);
}

// ~ pa/domain/aggregators/proceeding-audit.aggregator.ts
async dispatchProceedingAuditCreatedEvent(
	params: ProceedingAuditCreatedParams,
): Promise<boolean> {
	return this.proceedingAuditDispatcher.applyCreated({
		...params,
		eventType: AUDIT_EVENT_TYPE.CREATED,
	});
}
```

This mirrors the two-method chain INT-138 added to `proceeding-file-audit` (`applyCategorized`, PR #464). Each input type has its own method, and nothing routes on the event type at runtime (LD-020).

### Service

```ts
// ~ ps/proceeding.service.ts
constructor(
	// …existing twelve dependencies unchanged…
	private readonly jobAggregator: JobAggregator,
) {}

async createProceedings(
	jobId: number,
	values: string[],
	user: AuthUser,
): Promise<{ id: number; value: string }[]> {
	const jobDate = await this.jobAggregator.getJobDateById(jobId);
	const proceedings = await this.proceedingAggregator.createProceedings({
		jobId,
		values,
		userId: user.identity.userId,
	});
	await Promise.all(
		proceedings.map((proceeding) =>
			this.proceedingAuditAggregator.dispatchProceedingAuditCreatedEvent({
				proceeding,
				jobId,
				jobDate,
				user,
			}),
		),
	);
	return proceedings;
}
```

- **Imports:** `JobAggregator` from `src/jobs/domain/aggregators/job.aggregator`.
- **Precedents:** `MultiPartUploadProceedingFileService` uses the same job-date read (`multi-part-upload-proceeding-file.service.ts:43`). The recategorize service uses the same `Promise.all` dispatch (`recategorize-deliverable-files.service.ts:50-57` on `INT-138`).

---

## europa-back-end

In `SearchAuditEventsPaginatedTS.toItemProjection` (`eu/…/search-audit-events-paginated.transaction.script.ts:55` on `main`), add the constants next to `PERMISSIONS_UPDATED` (`:13`). Add the branch after the `PERMISSIONS_UPDATED` branch (`:62-73`) and before the default branch (`:74`):

```ts
const CREATED = 'CREATED';
const PROCEEDING = 'PROCEEDING';

// …
} else if (
	event.type === CREATED &&
	firstResource?.resourceType === PROCEEDING
) {
	path = [
		`Path: ${firstResource.newState?.path ?? ''}`,
		`Proceeding Name: ${firstResource.newState?.value ?? ''}`,
	].join(' | ');
	bucket = firstResource.newState?.bucket ?? '';
}
```

- **Null guards only.** `?? ''` protects against missing fields. The path is always built from ids (F-07). The name always has 3–128 characters, with none of `\ / : * ? " < > | %` (F-14).
- **Other `CREATED` records** (FILE) keep the default branch (`:74-86`).
- **Separator.** It matches `PERMISSIONS_UPDATED` (`' | '`, `:72`), and the path is built when the record is read.

## atlas-front-end

```ts
// ~ atlas/utils/constants.ts
export const resourceTypes = ['FILE', 'FOLDER', 'PERMISSION', 'PROCEEDING', 'USER'];

// Event types whose path is multi-part only for the listed resource types.
// CREATED is shared with FILE records, whose path is a plain S3 key.
export const MULTI_PART_PATH_RESOURCE_TYPES: Readonly<
  Record<string, ReadonlySet<string>>
> = {
  CREATED: new Set(['PROCEEDING']),
};
```

```ts
// ~ atlas/pages/HomePage/SearchDataGrid/SearchDataGrid.vue (script)
const hasMultiPartPath = (item: SearchAuditEventItem): boolean =>
  MULTI_PART_PATH_TYPES.has(item.type) ||
  (MULTI_PART_PATH_RESOURCE_TYPES[item.type]?.has(item.resourceType) ?? false);

// displayRows (:97)
pathSegments: hasMultiPartPath(item) ? toPathSegments(item.path) : null,
```

- `MULTI_PART_PATH_TYPES` and its spec (`atlas/utils/__specs__/constants.spec.ts:32-38`) are unchanged.
- The template (`:325-340`) and `toPathSegments` (`:83-87`) are unchanged.

---

## Cross-cutting

- **Companion tickets:**
  - INT-138: Atlas's multi-part render. This PR is stacked on #582.
  - INT-139: no dependency. Its later changes to the same europa-back-end and Callisto files are textual neighbours (see Branches).
- **Feature flags:** none. `CreateProceedingsTS` has none, and the dispatch runs on every create.

## Optional callouts

- **HTTP surface:** N/A. No route, method, body, status or auth change in Callisto or europa-back-end. The create endpoint's success response is unchanged. Its failure responses are unchanged, except that a job-date failure now happens before the write (LD-017).
- **Registries and module wiring:** `ProceedingAuditModule` adds one provider. Nothing else.
- **Ports:** `ProceedingAuditDispatcherPort` gains `applyCreated`, implemented by `ProceedingAuditDispatcher` (bound to `PROCEEDING_AUDIT_DISPATCHER`, `pa/proceeding-audit.module.ts:11-14`).
- **Domain events:** the `CREATED` audit event with a `PROCEEDING` resource, sent on the existing audit SQS queue.
- **Domain exceptions:** N/A. None are added. Errors propagate unchanged (LD-017).
- **Authorization:** N/A. The existing `ProceedingsCreateAuthGuard` and `ProceedingsJobIdBodyRestrictionActionGuard` are unchanged (`create-proceedings.action.ts:18-19`).

## Spec tests

| Repo | Spec | Cases |
| --- | --- | --- |
| callisto | `ps/__specs__/proceeding.service.spec.ts`, "when: creating proceedings" (`:374`) | **Happy path:** the job date is read once with `jobId`; `createProceedings` gets `{ jobId, values, userId }`; one `dispatchProceedingAuditCreatedEvent` per proceeding with `{ proceeding, jobId, jobDate, user }`; the created proceedings are returned. **Job-date read rejects:** it rejects with that error; `createProceedings` and the dispatch are never called. **Create rejects**, with `DuplicateProceedingError` as one case: it rejects with that error; nothing is dispatched. **A dispatch resolves `false`:** the created proceedings are returned. **A dispatch rejects:** it rejects with that error, as rename does. Setup: add a `JobAggregator` mock (`createMock`). Existing cases are unchanged |
| callisto | `pa/domain/aggregators/__specs__/proceeding-audit.aggregator.spec.ts` | `dispatchProceedingAuditCreatedEvent` calls `applyCreated` with `eventType: 'CREATED'` and the params; it returns `true`/`false` as given; it propagates a rejection. The rename cases (`:41`, `:98`, `:125`) are unchanged |
| callisto | `pa/infrastructure/dispatchers/__specs__/proceeding-audit.dispatcher.spec.ts` | `applyCreated` assembles through `applyCreated` and produces the event on `sqsAuditEventUrl`. `apply` is unchanged (`:49`) |
| callisto | `pa/…/__specs__/proceeding-to-audit-event.assembler.spec.ts` | `applyCreated`: `type: 'CREATED'`, `identity: user.identity`, `createdAt` (the mocked date), `serviceName`, and exactly one resource from the new converter (LD-018). Existing `apply` cases (`:43`, `:101`) keep their exact expected output |
| callisto | `pa/…/__specs__/proceeding-creation-to-audit.converter.spec.ts` (new) | The full record shape per the Record contract. `oldState` is `null`. `resourceBucket` is `''`. A `Date` job date of 2026-09-15 gives `092026/5512/881`. **Parity:** for January, September and December dates, the path prefix equals `new GetProceedingFileKey().getMonthYear(date)` (LD-021) |
| europa | `eu/…/__specs__/search-audit-events-paginated.transaction.script.spec.ts` | `CREATED` + `PROCEEDING`: the path is `Path: 092026/5512/881 \| Proceeding Name: Day 1` and the bucket is `''`, with `oldState: null`. `CREATED` + `FILE`: the path is `newState.path` and the bucket is `newState.bucket` (default branch). `RENAMED` + `PROCEEDING` with `{ value }` states: the path and bucket are `resourcePath` / `resourceBucket` (default branch). Use `createMockAuditEvent` (`eu/test-utils.ts:16`) |
| atlas | `atlas/utils/__specs__/constants.spec.ts` | `resourceTypes` lists `PROCEEDING` exactly once; `MULTI_PART_PATH_RESOURCE_TYPES.CREATED` has `PROCEEDING` and not `FILE` |
| atlas | `atlas/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts` | `CREATED` + `PROCEEDING` renders two lines with bold `Path` and `Proceeding Name`. `RENAMED` + `PROCEEDING` renders the raw path on one line. The existing `CREATED` + `FILE` cases (`:200-230`) stay as the regression guard |

**Manual end-to-end (local, Callisto → SQS → europa-back-end → the Atlas `/europa-stuff` page):**
1. Create two proceedings on one job from File Navigator, in one request.
2. Filter on Event Type `CREATED` and Resource Type `PROCEEDING`.
3. Expect one row per proceeding, showing:
   - User Email, User Name and Date matching the signed-in user and the time;
   - Resource Type `PROCEEDING`;
   - Resource Name set to the proceeding name;
   - a Path on two lines, `Path: MMYYYY/jobId/proceedingId` and `Proceeding Name: <name>`, where `MMYYYY` matches the job date and the prefix of a file uploaded to that proceeding;
   - a blank Bucket.
4. Upload a file and confirm its `CREATED` row is unchanged.
5. Create a proceeding from AJSF and confirm no `CREATED` / `PROCEEDING` row appears.

## Verification gates

| Repo | Commands |
| --- | --- |
| callisto-back-end | `npm audit --audit-level=high`; `npm run lint`; `npm run type-check`; `npx jest --config jest-e2e.json --runInBand src/__tests__/architecture.spec.ts`; `npx jest --config jest-e2e.json --runInBand` |
| europa-back-end | `npm audit --audit-level=high`; `npm run lint`; `npm run type-check`; `npx jest --config jest-e2e.json --runInBand` |
| atlas-front-end | `npm audit --audit-level=high`; `npm run lint`; `npm run type-check`; `npx vitest run --maxWorkers 1` |

## Acceptance criteria trace

| Ticket criterion | Where the spec covers it | Verified by |
| --- | --- | --- |
| Ops can view a log in Europa for proceeding creation | Solution; LD-001, LD-002; Service | Service spec; manual steps 1–3 |
| user info | Record contract (`identity`); LD-018 | Assembler spec; manual (User Email, User Name) |
| date/time | Record contract (`createdAt`); LD-018 | Assembler spec; manual (Date) |
| File Navigator proceeding creation action taken | LD-001, LD-003; `type: CREATED` | Aggregator spec; manual step 5 (not from AJSF) |
| Event Type: Created | LD-003 | Aggregator spec; manual filter |
| Proceeding added to the Resource Type drop down | LD-004; atlas-front-end | `constants.spec.ts`; manual filter |
| Path: [path] (date/job ID/proceeding ID) | LD-005; converter; europa-back-end branch | Converter spec (format and parity); europa-back-end spec; manual |
| Proceeding Name: [proceeding name] | LD-007, LD-009; europa-back-end branch; atlas-front-end split | europa-back-end spec; `SearchDataGrid.spec.ts`; manual |

## Rollout

- **Deploy order:** europa-back-end with or before atlas-front-end (LD-015). If Atlas's new check is live while europa-back-end still returns the raw path (`092026/5512/881`), the row renders as a bold label with an empty value (F-12).
- **Callisto order:** Callisto can deploy in any order. A record sent before europa-back-end's branch is live shows the raw path until then, and displays in full afterwards, because the text is built when the record is read.

## Branches

- **callisto-back-end:** `INT-140` from `origin/main` @ `59b1abd3`.
- **europa-back-end:** `INT-140` from `origin/main` @ `1082fdad`, without the unpushed `d9fb272`.
- **atlas-front-end:** `INT-140` from `origin/INT-138` @ `36999e87`. The PR targets `INT-138` until #582 merges, then retargets `main`. If #582 changes before then, rebase.
- **Expected conflicts** with INT-138/INT-139 work, resolved by keeping both sides:
  - europa-back-end `audit-event-resource.entity.ts` (`d9fb272` adds `deliverableType` / `collection`) and the search TS (`d9fb272` adds the `CATEGORIZE` branch and `toDisplayValue`);
  - atlas-front-end `constants.ts` (INT-139 adds `RECATEGORIZE` next to these lines).

## Complexity flags

- **A rejection after commit returns an error for proceedings that exist** (LD-017), the same as rename. Moving the job-date read before the create leaves no step after the commit known to throw (F-29).
- **The Atlas path check runs for every row.** The existing `CREATED` + `FILE` cases (`:200-230`) guard that rows other than `CREATED` + `PROCEEDING` render as before.
- **Deploy order** between europa-back-end and atlas-front-end.

## Estimate

**Small.** Each repo extends an existing pattern: the proceeding audit chain, a europa-back-end display branch, and a constant-driven Atlas render. There is no migration, API change or new module. Points are left for refinement.
