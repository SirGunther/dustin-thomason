---
ticket: INT-141
tags: [neptune, proceeding-job-submission, proceedings, audit, europa, atlas]
author: Dustin Thomason
created: 2026-09-29
modified: 2026-09-29
modified_by: Dustin Thomason
---

# INT-141: CREATED audit records for AJSF proceeding creation

> **Parent epic:** _(not captured)_
>
> **Ticket:** INT-141
>
> **Repos (branch `INT-141`, cut from `INT-138`):** `callisto-back-end` sends the record, `europa-back-end` builds its path text, `atlas-front-end` lists the resource type and renders the path on the Europa audit page.
>
> **Depends on:** INT-138 ([spec](https://github.com/planetdepos/callisto-back-end/blob/INT-138/docs/specs/atlas-client-access/deliverable-management/8-story-INT-138-categorize-audit-events/8-story-INT-138-categorize-audit-events.md), callisto-back-end branch `INT-138`), for europa-back-end's `toDisplayValue` and atlas-front-end's path splitter and multi-line template. Neither is on `main`.
>
> **Delivery:** best-effort, the way every audit record is sent today. Guaranteed delivery is tracked separately. See [Known limitations](#known-limitations).

Citations are `file:line` on branch `INT-138`. Prefixes:

| Prefix | Path |
| --- | --- |
| `pjs/` | `callisto-back-end/src/proceeding-job-submission/` |
| `pa/` | `callisto-back-end/src/proceedings/domain/sub-domains/proceeding-audit/` |
| `pa-asm/` | `pa/infrastructure/dispatchers/proceeding-to-audit-event-assembler/` |
| `eu/` | `europa-back-end/src/audits-event/` |
| `eu-ts/` | `eu/domain/transaction-scripts/search-audit-events-paginated-TS/` |
| `atlas/` | `atlas-front-end/src/europa/` |

---

## Story and acceptance criteria (from the ticket)

As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.

- Ops can view a log in Europa for AJSF proceeding creation
- The log displays the following details:
  - user info
  - date/time
  - **AJSF proceeding creation** actions taken
- Event Type for this action is: **Created**
- The **Proceeding** Resource type is added to the Resource Type drop down in Europa
  - (this should already exist, it's just not visible)
- Path format:
  - Path: [path] (date/job ID/proceeding ID)
  - Proceeding Name: [proceeding name]

**Dev note (from the ticket):** two endpoints create proceedings. This ticket uses **AJSF**, `jobSubmissionService.createProceedings`. **File Navigator**, `proceedingsService.createProceedings`, is INT-140.

---

## Summary

The AJSF sends one `CREATED` audit record per proceeding it creates, through the proceeding audit chain Callisto already uses for `RENAMED`. europa-back-end builds the `Path | Proceeding Name` text, and atlas-front-end adds `PROCEEDING` to the Resource Type dropdown. There is no migration, route, DTO or europa-back-end schema change.

| In scope | Out of scope |
| --- | --- |
| The AJSF action, `POST /proceedings` on `ProceedingJobSubmissionController` (`pjs/application/controllers/actions/create-job-submission-proceedings-action/create-job-submission-proceedings.action.ts:15-24`) | File Navigator proceeding creation (INT-140). It shares `ProceedingAggregator.createProceedings` and `CreateProceedingsTS`, which this spec does not change |
| One `CREATED` record per created proceeding | Existing proceeding `RENAMED` records: output and display unchanged |
| europa-back-end paginated search path for `CREATED` + `PROCEEDING` | europa-back-end's `/search` endpoint |
| Europa audit page: Resource Type list and path rendering | A new event type or chip colour: `CREATED` exists, with `positive` (`atlas/utils/constants.ts:4`, `:21`) |
| | Guaranteed delivery: tracked separately under INT-138's concern C2 (see [Known limitations](#known-limitations)) |
| | Backfill of past proceeding creations |

---

## Problem

Creating a proceeding through the AJSF writes no audit record. `JobSubmissionService.createProceedings` creates the proceedings and returns (`pjs/domain/services/job-submission-service/job-submission.service.ts:247-260`). Ops can't see who created a proceeding or when. They also can't filter the log to proceedings, because `PROCEEDING` is missing from the Resource Type dropdown (`atlas/utils/constants.ts:18`), although Callisto already sends it for renames (`callisto-back-end/src/audits/constants.ts:5`).

## Requirement

Every proceeding created through the AJSF sends its own audit record with event type `CREATED` and resource type `PROCEEDING`, delivered best-effort like every audit record Callisto sends (see [Known limitations](#known-limitations)). Ops can filter to it by Resource Type, and it shows who created the proceeding, when, and:

`Path: <MMYYYY>/<jobId>/<proceedingId> | Proceeding Name: <proceeding name>`

`MMYYYY` is the job date's month and year. The path is the S3 prefix every file uploaded into the proceeding receives (`pjs/domain/transaction-scripts/multi-part-upload-proceeding-job-submission-file-ts/upload-start-proceeding-job-submission-file-ts/get-proceeding-file-key/get-proceeding-file-key.ts:12`, `:23`).

## Solution

- **callisto-back-end:**
  - `JobSubmissionService.createProceedings` reads the job date, creates the proceedings, then sends one record per proceeding.
  - The records go through a new port bound to `ProceedingAuditAggregator`.
  - The aggregator gains a `CREATED` method, and its converter gains a `path` input.
- **europa-back-end:** the paginated search builds the `Path | Proceeding Name` text for `CREATED` + `PROCEEDING` records.
- **atlas-front-end:**
  - `PROCEEDING` is added to `resourceTypes`.
  - `CREATED` + `PROCEEDING` paths render on two lines. The split stops at the first `' | '`, so a name can't add a field.

### The record Callisto sends

| Field | Value |
| --- | --- |
| `type` | `CREATED` |
| `createdAt` | the time the record is built, right after the create commits (`pa-asm/proceeding-to-audit-event.assembler.ts:26`, `createdAt: new Date()`; unchanged) |
| `identity` | the requesting user (`user.identity`, from `@VerifiedUserDecorator()`) |
| `resourceType` | `PROCEEDING` |
| `id` / `resourceId` | the proceeding id, as a string |
| `resourceName` | the proceeding name (`value`) |
| `resourcePath` | `<MMYYYY>/<jobId>/<proceedingId>` |
| `resourceBucket` | `''`. Creating a proceeding writes no S3 object |
| `oldState` / `newState` | `{ path: <MMYYYY>/<jobId>/<proceedingId>, value: <proceeding name> }`, the same in both, as for file `CREATED` records |

Displayed: `Path: 092026/5512/881 | Proceeding Name: Smith Deposition`, on two lines, with bold labels.

### Acceptance criteria trace

| Criterion | Met by | Verified by |
| --- | --- | --- |
| Ops can view a log in Europa for AJSF proceeding creation | One `CREATED` record per proceeding from `JobSubmissionService.createProceedings` (A.10 step 4) | A.11 service spec; manual step 2 |
| User info | `identity` (above). europa-back-end projects `userEmail` and `userName` (`eu-ts/search-audit-events-paginated.transaction.script.ts:105-107`); Atlas shows them in the User columns. Existing behaviour | A.11 service spec (`user` on each dispatch); manual step 2 |
| Date/time | `createdAt` (above). europa-back-end keeps the value sent, because Mongoose timestamps set `createdAt` only when it is missing (`node_modules/mongoose/lib/helpers/timestamps/setDocumentTimestamps.js:11-16`), and projects it (`eu-ts/search-audit-events-paginated.transaction.script.ts:104`). Atlas shows it in the Date column (`atlas/pages/HomePage/SearchDataGrid/auditEventColumns.ts:55-61`). Existing behaviour; no new code | Existing `proceeding-to-audit-event.assembler.spec.ts` `createdAt` assertions (`:94`, `:159`); manual step 2 |
| AJSF proceeding creation action taken | Event type `CREATED` with resource type `PROCEEDING` | A.11, B.3; manual step 2 |
| Event Type is Created | `AUDIT_EVENT_TYPE.CREATED` (`src/audits/constants.ts:11`); already in the Event Type dropdown | A.11 aggregator spec |
| Proceeding in the Resource Type dropdown | `'PROCEEDING'` in `resourceTypes` (C.2) | C.9 constants spec; manual step 3 |
| Path format | europa-back-end branch (B.2) and the two-segment Atlas render (C.2) | B.3, C.9; manual step 2 |

---

## Decisions

| Decision | Consequence |
| --- | --- |
| Event type `CREATED`, resource type `PROCEEDING` | Both literals exist in Callisto (`src/audits/constants.ts:5`, `:11`); no new constant |
| Send from `JobSubmissionService.createProceedings` only, after the create commits | No change to `ProceedingAggregator` or `CreateProceedingsTS` (`create-proceedings.transaction.script.ts:21` is `@Transactional()`), so File Navigator sends nothing new |
| One record per created proceeding | europa-back-end shows only resource `[0]` (`eu-ts/search-audit-events-paginated.transaction.script.ts:58`) |
| Path from the job date, read before the create | `JobAggregator.getJobDateById` (`src/jobs/domain/aggregators/job.aggregator.ts:12-18`), formatted with `GetProceedingFileKey.getMonthYear`. A missing job fails the request before anything is written |
| Callisto sends values; europa-back-end builds the labels | Same split as INT-138 and `PERMISSIONS_UPDATED` (`eu-ts/search-audit-events-paginated.transaction.script.ts:63-85`) |
| A port in `proceeding-job-submission`, bound with `useExisting: ProceedingAuditAggregator` | Same pattern as `CLIENT_ACCESS_FILE_AUDIT` (`src/proceedings/proceedings.module.ts:205-208`, `:220`) |
| The path is built by an assembler | Services may not import converters (`fitness-functions-rules/architecture-rules/services.rules.ts`, `services-no-converters`); services inject assemblers elsewhere, for example `JobSubmissionFormFileAttachmentAssembler` |
| No error after the commit reaches the caller | The service catches and logs assembler errors and dispatch rejections. A retry after an error would fail on the unique constraint (`create-proceedings.transaction.script.ts:43-51`) |
| Two-segment split in Atlas for `CREATED` + `PROCEEDING` | The path is digits and `/` only and comes first; the user-entered name comes last and is never split |
| `RENAMED` output unchanged | The converter takes the `CREATED` shape only when `path` is supplied |
| Best-effort delivery | Locked for INT-141. Guaranteed delivery is tracked separately (see [Known limitations](#known-limitations)) |

## Known limitations

- **Delivery is best-effort.** Every audit dispatcher sends straight to SQS through `AUDIT_EVENT_PRODUCER_TOKEN`, and the producer logs a failed send and returns `false` (`src/audits/infrastructure/adapters/outbound/producers/sqs/sqs-audit-event.producer.ts:23-34`). A proceeding can exist with no `CREATED` record if the send fails (a log line is written) or if the process stops between the commit and the send.
- **Why guaranteed delivery is not in scope:** it would write the record in the create transaction through an outbox and relay it to the audit queue. No audit record uses the outbox today, so that is a new pattern for every audit path. It is tracked separately under INT-138's concern C2.

---

## Part A — Callisto (`callisto-back-end`)

### A.1 Folder hierarchy

New (`+`) and changed (`~`):

```
src/
├── proceeding-job-submission/
│   ├── domain/
│   │   ├── ports/job-submission-proceeding-audit.port.ts                          +
│   │   ├── projections/job-submission-proceeding-created-audit.projection.ts      +
│   │   └── services/job-submission-service/
│   │       ├── job-submission.service.ts                                          ~
│   │       ├── job-submission-proceeding-audit.assembler.ts                       +
│   │       └── __specs__/
│   │           ├── job-submission.service.spec.ts                                 ~
│   │           └── job-submission-proceeding-audit.assembler.spec.ts              +
│   └── proceeding-job-submission.module.ts                                        ~
└── proceedings/
    ├── proceedings.module.ts                                                      ~
    └── domain/sub-domains/proceeding-audit/
        ├── domain/aggregators/
        │   ├── proceeding-audit.aggregator.ts                                     ~
        │   ├── proceeding-audit.param.ts                                          ~
        │   └── __specs__/proceeding-audit.aggregator.spec.ts                      ~
        └── infrastructure/dispatchers/proceeding-to-audit-event-assembler/
            ├── proceeding-to-audit.converter.ts                                   ~
            └── __specs__/
                ├── proceeding-to-audit.converter.spec.ts                          ~
                └── proceeding-to-audit-event.assembler.spec.ts                    ~
```

### A.2 New and changed classes

| Class / type | Path | Change |
| --- | --- | --- |
| `JobSubmissionProceedingAuditAssembler` | `pjs/domain/services/job-submission-service/job-submission-proceeding-audit.assembler.ts` | **New.** Builds one audit record per proceeding with its path |
| `JobSubmissionProceedingAuditPort`, `JOB_SUBMISSION_PROCEEDING_AUDIT`, `JobSubmissionProceedingCreatedAuditParams` | `pjs/domain/ports/job-submission-proceeding-audit.port.ts` | **New** |
| `JobSubmissionProceedingCreatedAuditProjection` | `pjs/domain/projections/job-submission-proceeding-created-audit.projection.ts` | **New** |
| `JobSubmissionService` | `pjs/domain/services/job-submission-service/job-submission.service.ts` | Injects the port and the assembler. `createProceedings` reads the job date, creates, then calls a private `dispatchProceedingCreatedAudits` |
| `ProceedingAuditAggregator` | `pa/domain/aggregators/proceeding-audit.aggregator.ts` | `implements JobSubmissionProceedingAuditPort`; adds `dispatchProceedingAuditCreatedEvent` |
| `ProceedingAuditParams` | `pa/domain/aggregators/proceeding-audit.param.ts:13-16` | `proceeding` gains optional `path` |
| `ProceedingToAuditEventResourceConverter` | `pa-asm/proceeding-to-audit.converter.ts:7-24` | Returns the `CREATED` shape when `proceeding.path` is set |

**Unchanged:** `ProceedingAuditDispatcher` and `ProceedingToAuditEventAssembler`. The event assembler passes `input.proceeding` to the converter as it is (`pa-asm/proceeding-to-audit-event.assembler.ts:16-22`), so `path` reaches the converter with no change.

### A.3–A.6 Entities and migrations

N/A: no table, entity or migration change.

### A.7 DTOs

N/A. `CreateJobSubmissionProceedingsRequestDTO`, the `{ id, value }[]` response and `CreateJobSubmissionProceedingsSwagger` are unchanged.

### A.8 Projections, params and port

```ts
// NEW pjs/domain/projections/job-submission-proceeding-created-audit.projection.ts
/** One CREATED audit record for a proceeding created through the AJSF. */
export type JobSubmissionProceedingCreatedAuditProjection = {
	readonly proceeding: {
		readonly id: number;
		readonly value: string;
		/** `<MMYYYY>/<jobId>/<proceedingId>`: the S3 prefix of the proceeding's files. */
		readonly path: string;
	};
};
```

```ts
// NEW pjs/domain/ports/job-submission-proceeding-audit.port.ts
import type { AuthUser } from 'src/generic/auth/constants';
import type { JobSubmissionProceedingCreatedAuditProjection } from '../projections/job-submission-proceeding-created-audit.projection';

export const JOB_SUBMISSION_PROCEEDING_AUDIT = Symbol(
	'JOB_SUBMISSION_PROCEEDING_AUDIT',
);

export type JobSubmissionProceedingCreatedAuditParams =
	JobSubmissionProceedingCreatedAuditProjection & {
		readonly user: Partial<AuthUser>;
	};

/**
 * The CREATED audit record for a proceeding created through the AJSF.
 * Resolves false when the record was not accepted for delivery.
 */
export type JobSubmissionProceedingAuditPort = {
	dispatchProceedingAuditCreatedEvent(
		params: JobSubmissionProceedingCreatedAuditParams,
	): Promise<boolean>;
};
```

```ts
// CHANGED pa/domain/aggregators/proceeding-audit.param.ts
export type ProceedingAuditParams = {
	eventType?: keyof typeof AUDIT_EVENT_TYPE;
	proceeding: {
		id: number;
		value: string;
		/** Set on a CREATED record only: `<MMYYYY>/<jobId>/<proceedingId>`. */
		path?: string;
	};
	user: Partial<AuthUser>;
	oldValue?: string;
};
```

### A.9 Module wiring

```ts
// CHANGED src/proceedings/proceedings.module.ts
import { JOB_SUBMISSION_PROCEEDING_AUDIT } from 'src/proceeding-job-submission/domain/ports/job-submission-proceeding-audit.port';

// providers, after the CLIENT_ACCESS_FILE_AUDIT binding (:205-208)
{
	provide: JOB_SUBMISSION_PROCEEDING_AUDIT,
	useExisting: ProceedingAuditAggregator,
},

// exports, after CLIENT_ACCESS_FILE_AUDIT (:220)
JOB_SUBMISSION_PROCEEDING_AUDIT,
```

- `ProceedingJobSubmissionModule` (`pjs/proceeding-job-submission.module.ts`) adds `JobSubmissionProceedingAuditAssembler` to its providers after `JobSubmissionFormFileAttachmentAssembler` (`:207`). It already imports `ProceedingsModule` (`:147`), so the token resolves in `JobSubmissionService`. It also already provides `GetProceedingFileKey` (`:223`).
- **Module boundaries:** `ProceedingsModule` and `ProceedingAuditAggregator` import the port file from `proceeding-job-submission`. `domain-module-boundary` allows cross-module imports of `*.port.*` files (`fitness-functions-rules/architecture-rules/cross-module-boundaries/domain-boundaries.rules.ts`). INT-138 uses the same pattern: `ProceedingFileAuditAggregator implements ClientAccessFileAuditPort`.

### A.10 Implementation

**1. Assembler.**

```ts
// NEW pjs/domain/services/job-submission-service/job-submission-proceeding-audit.assembler.ts
import { Injectable } from '@nestjs/common';
import { GetProceedingFileKey } from '../../transaction-scripts/multi-part-upload-proceeding-job-submission-file-ts/upload-start-proceeding-job-submission-file-ts/get-proceeding-file-key/get-proceeding-file-key';
import type { JobSubmissionProceedingCreatedAuditProjection } from '../../projections/job-submission-proceeding-created-audit.projection';

export type JobSubmissionProceedingAuditAssemblerInput = {
	readonly jobId: number;
	readonly jobDate: Date | string;
	readonly proceedings: readonly { readonly id: number; readonly value: string }[];
};

@Injectable()
export class JobSubmissionProceedingAuditAssembler {
	constructor(private readonly getProceedingFileKey: GetProceedingFileKey) {}

	apply(
		input: JobSubmissionProceedingAuditAssemblerInput,
	): JobSubmissionProceedingCreatedAuditProjection[] {
		const monthYear = this.getProceedingFileKey.getMonthYear(input.jobDate);
		return input.proceedings.map((proceeding) => ({
			proceeding: {
				id: proceeding.id,
				value: proceeding.value,
				path: `${monthYear}/${input.jobId}/${proceeding.id}`,
			},
		}));
	}
}
```

**2. Aggregator.**

```ts
// CHANGED pa/domain/aggregators/proceeding-audit.aggregator.ts
@Injectable()
export class ProceedingAuditAggregator
	implements JobSubmissionProceedingAuditPort
{
	// constructor and dispatchProceedingAuditRenamedEvent unchanged

	async dispatchProceedingAuditCreatedEvent(
		params: ProceedingAuditParams,
	): Promise<boolean> {
		return this.proceedingAuditDispatcher.apply({
			...params,
			eventType: AUDIT_EVENT_TYPE.CREATED,
		});
	}
}
```

Dispatcher errors still propagate from the aggregator, as for `RENAMED` (`pa/domain/aggregators/__specs__/proceeding-audit.aggregator.spec.ts:125-141`).

**3. Converter.**

```ts
// CHANGED pa-asm/proceeding-to-audit.converter.ts
apply(
	proceeding: { id: number; value: string; path?: string },
	oldValue?: string,
): AuditEventResourceDomainEvent {
	if (proceeding.path !== undefined) {
		return {
			id: proceeding.id.toString(),
			resourceType: AuditEventResourceType.PROCEEDING,
			resourceId: proceeding.id.toString(),
			resourceName: proceeding.value,
			resourcePath: proceeding.path,
			resourceBucket: '',
			oldState: { path: proceeding.path, value: proceeding.value },
			newState: { path: proceeding.path, value: proceeding.value },
		};
	}
	// existing RENAMED return, unchanged (:14-23)
}
```

**4. Service.**

```ts
// CHANGED pjs/domain/services/job-submission-service/job-submission.service.ts
// constructor: add before the logger
		@Inject(JOB_SUBMISSION_PROCEEDING_AUDIT)
		private readonly jobSubmissionProceedingAudit: JobSubmissionProceedingAuditPort,
		private readonly jobSubmissionProceedingAuditAssembler: JobSubmissionProceedingAuditAssembler,

	async createProceedings({
		jobId,
		values,
		user,
	}: {
		jobId: number;
		values: string[];
		user: AuthUser;
	}): Promise<{ id: number; value: string }[]> {
		const jobDate = await this.jobAggregator.getJobDateById(jobId);
		const proceedings = await this.proceedingAggregator.createProceedings({
			jobId,
			values,
			userId: user.identity.userId,
		});
		await this.dispatchProceedingCreatedAudits({
			jobId,
			jobDate,
			proceedings,
			user,
		});
		return proceedings;
	}

	/** Runs after the proceedings are committed, so an error is logged, not thrown. */
	private async dispatchProceedingCreatedAudits({
		jobId,
		jobDate,
		proceedings,
		user,
	}: {
		jobId: number;
		jobDate: Date;
		proceedings: { id: number; value: string }[];
		user: AuthUser;
	}): Promise<void> {
		let audits: JobSubmissionProceedingCreatedAuditProjection[];
		try {
			audits = this.jobSubmissionProceedingAuditAssembler.apply({
				jobId,
				jobDate,
				proceedings,
			});
		} catch (error) {
			this.logger.error(
				'Failed to assemble proceeding CREATED audit records',
				error as Error,
				{ jobId },
			);
			return;
		}
		await Promise.all(
			audits.map((audit) =>
				this.jobSubmissionProceedingAudit
					.dispatchProceedingAuditCreatedEvent({ ...audit, user })
					.catch((error: Error) => {
						this.logger.error(
							'Failed to dispatch proceeding CREATED audit record',
							error,
							{ jobId, proceedingId: audit.proceeding.id },
						);
						return false;
					}),
			),
		);
	}
```

- A dispatch that resolves `false` is not logged again; the SQS producer has already logged the failed send.
- The logger call follows the same service's existing log-and-continue code (`job-submission.service.ts:179-190`).

### A.11 Spec tests

| Spec | Cases |
| --- | --- |
| `pjs/…/job-submission-service/__specs__/job-submission.service.spec.ts` (new `createProceedings` block; provide the port with `createMock<JobSubmissionProceedingAuditPort>()` and a mocked assembler) | **Happy:** the job date is read before the create; the assembler gets `jobId`, the job date and the created proceedings; one dispatch per assembled record, each with `user`; the created proceedings are returned. **Failure:** the job-date read fails: no create, no dispatch, the error propagates. The create fails (`DuplicateProceedingError`): no assemble, no dispatch, the error propagates. **Graceful:** a dispatch rejects: the proceedings are returned, `logger.error` is called with `jobId` and that `proceedingId`, and the other records are still dispatched. A dispatch resolves `false`: the proceedings are returned, `logger.error` is not called. The assembler throws: the proceedings are returned, nothing is dispatched, `logger.error` is called with `jobId` |
| `pjs/…/job-submission-service/__specs__/job-submission-proceeding-audit.assembler.spec.ts` (real `GetProceedingFileKey`) | One record per proceeding, in order, with path `<MMYYYY>/<jobId>/<proceedingId>`; a single-digit month is zero-padded; a string job date gives the same path as the equivalent `Date`; the month-year equals `GetProceedingFileKey.getMonthYear` for the same date; an empty list returns `[]` |
| `pa/domain/aggregators/__specs__/proceeding-audit.aggregator.spec.ts` | `dispatchProceedingAuditCreatedEvent` calls the dispatcher once with `eventType: 'CREATED'` and returns its result, `true` or `false`; a dispatcher rejection propagates. Existing `RENAMED` cases unchanged |
| `pa-asm/__specs__/proceeding-to-audit.converter.spec.ts` | **`CREATED` shape** (`path` given, no `oldValue`): `resourcePath` = path, `resourceBucket` = `''`, `resourceName` = name, both states `{ path, value }`. **`RENAMED` shape** (no `path`): the existing cases, with and without `oldValue`, unchanged |
| `pa-asm/__specs__/proceeding-to-audit-event.assembler.spec.ts` | `proceeding.path` reaches the converter; the event `type` equals the input `eventType` (`CREATED`) |

### A.12 Neighbors that must not change

- File Navigator `ProceedingService.createProceedings` (`src/proceedings/domain/services/proceeding-service/proceeding.service.ts:54-64`) sends no audit record.
- Proceeding `RENAMED` records keep `resourcePath` = `resourceBucket` = name, `newState: { value }`, and `oldState` from `oldValue` (`pa-asm/proceeding-to-audit.converter.ts:14-23`).
- The AJSF response is still `{ id, value }[]`.
- **Behaviour change:** a `jobId` with no job now fails at `getJobDateById` (`'Job date not found'`) before the insert, instead of failing on the `proceedings.job_id` foreign key during the insert (`src/shared/shared-entities/entities/proceedings/proceeding.entity.ts:28-30`). Both are server errors, and nothing is written in either case.

---

## Part B — Europa (`europa-back-end`)

### B.1 Changed files

```
src/audits-event/domain/transaction-scripts/search-audit-events-paginated-TS/
├── search-audit-events-paginated.transaction.script.ts                            ~
└── __specs__/search-audit-events-paginated.transaction.script.spec.ts             ~
```

Entities, migrations, DTOs and schema: N/A. Each audit resource is stored as a free-form object (`AuditEventResource` has no `@Schema()`), so `value` in the states is kept as sent.

### B.2 Implementation

Next to the existing constants (`eu-ts/search-audit-events-paginated.transaction.script.ts:13-14`):

```ts
const CREATED = 'CREATED';
const PROCEEDING = 'PROCEEDING';
```

In `toItemProjection`, after the `CATEGORIZE` branch (`:75-85`) and before the default branch (`:86`):

```ts
} else if (
	event.type === CREATED &&
	firstResource?.resourceType === PROCEEDING
) {
	path = [
		`Path: ${this.toDisplayValue(firstResource.newState?.path ?? firstResource.oldState?.path)}`,
		`Proceeding Name: ${this.toDisplayValue(firstResource.resourceName)}`,
	].join(' | ');
	bucket = '';
}
```

`toDisplayValue` (`:120-122`) returns `N/A` for null, empty and whitespace-only values.

### B.3 Spec tests

| Spec | Cases |
| --- | --- |
| `eu-ts/__specs__/search-audit-events-paginated.transaction.script.spec.ts` | `CREATED` + `PROCEEDING`: path `Path: 092026/5512/881 \| Proceeding Name: Smith Deposition`, bucket `''`. A blank path or blank name gives `N/A` on that side. A name containing `' \| '` is passed through unchanged. No resources: the default branch |

### B.4 Neighbors that must not change

- File `CREATED` records (default branch).
- Proceeding `RENAMED` records (default branch).
- `CATEGORIZE` and `PERMISSIONS_UPDATED` branches, and `/search`.

---

## Part C — Atlas (`atlas-front-end`, Europa audit page)

### C.1 Changed files

```
src/europa/
├── utils/constants.ts                                                             ~
├── utils/__specs__/constants.spec.ts                                              ~
└── pages/HomePage/SearchDataGrid/
    ├── SearchDataGrid.vue                                                         ~
    └── __specs__/SearchDataGrid.spec.ts                                           ~
```

### C.2 Implementation

```ts
// CHANGED atlas/utils/constants.ts:18
export const resourceTypes = ['FILE', 'FOLDER', 'PERMISSION', 'PROCEEDING', 'USER'];
```

```ts
// CHANGED atlas/pages/HomePage/SearchDataGrid/SearchDataGrid.vue (:81-99)
// Split a multi-part path ("Label: value | Label: value") into one segment per line.
// Everything before the first ': ' is the label; the rest is the value.
// With maxSegments, the last segment keeps the rest of the path, separators included.
const toPathSegments = (path: string, maxSegments?: number): PathSegment[] => {
  const parts = path.split(' | ');
  const bounded =
    maxSegments && parts.length > maxSegments
      ? [
          ...parts.slice(0, maxSegments - 1),
          parts.slice(maxSegments - 1).join(' | '),
        ]
      : parts;
  return bounded.map((part) => {
    const [label = '', ...valueParts] = part.split(': ');
    return { label, value: valueParts.join(': ') };
  });
};

// A proceeding name is user-entered and comes last, so it is never split.
const PROCEEDING_CREATED_PATH_SEGMENTS = 2;

const toRowPathSegments = (item: SearchAuditEventItem): PathSegment[] | null => {
  if (MULTI_PART_PATH_TYPES.has(item.type)) {
    return toPathSegments(item.path);
  }
  if (item.type === 'CREATED' && item.resourceType === 'PROCEEDING') {
    return toPathSegments(item.path, PROCEEDING_CREATED_PATH_SEGMENTS);
  }
  return null;
};

// in displayRows (:97-99)
    pathSegments: toRowPathSegments(item),
```

The template (`:327-338`) is unchanged.

### C.3–C.8 Entities, migrations, DTOs, projections

N/A: front-end only.

### C.9 Spec tests

| Spec | Cases |
| --- | --- |
| `atlas/utils/__specs__/constants.spec.ts` | `resourceTypes` contains `PROCEEDING` exactly once |
| `atlas/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts` | `CREATED` + `PROCEEDING` renders two lines, `Path` and `Proceeding Name`, with bold labels. Name `Smith \| Path: 012026/999/888` renders one Proceeding Name line with that full value and no second Path line. Name `Smith: Day 2` renders value `Smith: Day 2`. `CREATED` + `FILE` renders the raw path on one line |

### C.10 Neighbors that must not change

- `CATEGORIZE` and `PERMISSIONS_UPDATED` rendering (existing `SearchDataGrid.spec.ts` cases).
- The Event Type dropdown and chip colours.
- The route permission, `AUDIT` + `READ`.

---

## Cross-cutting

- **Companion tickets:**
  - INT-138: the base branch.
  - INT-139 (`RECATEGORIZE`): also adds a branch to `SearchAuditEventsPaginatedTS` and lines to `atlas/utils/constants.ts`. Whichever merges second resolves adjacent-line conflicts.
  - INT-140 (File Navigator proceeding creation): can reuse the aggregator method and the path format from its own service.
- **Feature flags:** none.
- **HTTP surface:** N/A. No route, method, body, status or auth change in Callisto or europa-back-end.
- **Registries and module wiring:** see A.9. No registry file changes.
- **Ports:** `JobSubmissionProceedingAuditPort` (`JOB_SUBMISSION_PROCEEDING_AUDIT`), implemented by `ProceedingAuditAggregator`.
- **Domain events:** the audit event `CREATED` with resource type `PROCEEDING`, on the existing audit SQS queue.
- **Domain exceptions:** N/A.
- **Authorization:** N/A. `AjsfProceedingsCreateAuthGuard` is unchanged.

## Rollout

Deploy europa-back-end and atlas-front-end with or before Callisto.

- A record read before the europa-back-end branch is live falls through to the default branch and shows the raw proceeding path (`eu-ts/search-audit-events-paginated.transaction.script.ts:86-97`). It shows in full once the branch is deployed, because the text is built on read.
- Until the atlas-front-end change is live, the text shows on one line.

## Manual end-to-end

1. Create two proceedings in one AJSF request.
2. Expect two `CREATED` rows with resource type `PROCEEDING`. Each reads `Path: <MMYYYY>/<jobId>/<proceedingId> | Proceeding Name: <name>` on two lines, with an empty Bucket. The User columns show the requesting user. The Date column shows the time of the request, in the timezone selected on the page.
3. Filter by Resource Type `PROCEEDING`: both rows are returned.
4. Upload a file into one of the proceedings: its S3 key starts with that row's path.
5. Rename one of the proceedings through File Navigator: its `RENAMED` row shows as before.

## Complexity flags and estimate

- **Post-commit error handling:** the one piece with new control flow (A.10 step 4). It is covered by the graceful cases in A.11.
- **Merge overlap with INT-139** in europa-back-end and atlas-front-end.

**Small (2–3 points).** Every change extends an existing chain, with no schema, route or DTO work; most of the effort is the spec tests across three repos.
