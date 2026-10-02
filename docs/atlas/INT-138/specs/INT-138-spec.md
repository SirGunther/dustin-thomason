---
ticket: INT-138
tags: [neptune, granting-client-access, proceedings, audit, europa, atlas]
author: Dustin Thomason
created: 2026-09-25
modified: 2026-09-25
---

# INT-138: Audit log records for deliverable type categorization (CATEGORIZE)

> **Ticket:** [INT-138](https://pd-product-dev.atlassian.net/browse/INT-138)
>
> **Repos:** `callisto-back-end` (emit), `atlas-front-end` (Europa audit page). `europa-back-end` is **unchanged**.
>
> **Related specs:** [PRDV-15369 recategorize](../6-story-PRDV-15369-recategorize-files-by-deliverable-type-and-collection/6-story-PRDV-15369-recategorize-files-by-deliverable-type-and-collection.md) · [PRDV-16314 recategorize endpoint](../../epic-PRDV-15736-make-atlas-metadata-available-to-planet-portal/PRDV-16314-endpoint-recategorize-files.md). Neither one specifies an audit record, and that gap is what this spec closes.

---

## Problem

Ops reviews the Europa audit log to see who did what, and when, to Client Access. When a file's deliverable type or collection is set, changed or removed, the log records none of the categorization.

- **Recategorize** writes no audit at all (`recategorize-deliverable-files.service.ts:24-44`).
- **Upload and approve** write `CREATED` / `APPROVED`. Those events predate deliverable types, so they carry only `{path, bucket, fileName}`.
- **Unapprove** records nothing about the categorization it clears.

## Requirement

Every set, change or removal of a file's deliverable type or collection produces its own audit record. Ops can filter to those records in Europa, and each one reads:

`Filepath: <file path> | Deliverable Type: <type> | Collection: <collection or N/A>`

It also carries who did it and when. The yardstick is story 01's acceptance criteria (below), and they aren't restated elsewhere in this spec.

## Solution

- **Callisto** emits a new `CATEGORIZE` audit event: one per categorized file, each with one `FILE` resource.
  - It is dispatched from the service after the transaction script returns, on five paths: upload (when it sets a type or collection), approve v1, approve v2, recategorize and unapprove (cleared).
  - It reuses the existing proceeding-file-audit chain: aggregator → dispatcher → assembler → a new converter. The five Client Access services reach the aggregator through one post-commit transaction script and a GCA-owned port (Part B).
- **Atlas** adds `CATEGORIZE` to the Europa Event Type options and renders its path as three labelled lines.
- **Europa** already stores, filters and returns any event type string, so it doesn't change.

---

## Locked Decisions From Q and A

The full ledger, with question gates, sources and rejected paths, is in `dustin-thomason/docs/atlas/INT-138/specs/INT-138-locked-decisions.md`. Summary:

| Decision | Source | Implementation consequence |
| --- | --- | --- |
| LD-001 Scope is deliverable-type categorization only | Ticket AC | Other Client Access actions are untouched |
| LD-002 The path shows the categorization **after** the action | Ticket path format | Converter builds `newState.path`; `oldState.path` carries the same string, the existing FILE-event convention when no prior state is tracked. Europa shows `newState.path` |
| LD-003 `Filepath` = `file.filePath` (S3 key) | Parity with every FILE audit event | No path derivation |
| LD-005 One event per file, one `FILE` resource each | Europa shows only resource `[0]` | No batch events |
| LD-006 Dispatch in the service, after the TS returns | Sibling precedent; depcruise forbids TS → aggregator | Five service call sites |
| LD-007 Europa unchanged | No enum, exact-match filter, `newState.path` passthrough | No Europa PR |
| LD-009 Every set / change / removal emits: upload that sets a type or collection, approve v1/v2, recategorize (collection-only included), unapprove (both `N/A`) | An audit records every change | Five paths. No event when nothing is categorized: an upload with neither type nor collection, legacy approve, or unapprove of a never-categorized file |
| LD-010 Literal `CATEGORIZE` | Ticket's event name | Callisto enum and Atlas list, byte-identical |
| LD-011 No backfill | Callisto holds no who/when history to rebuild from | Records start at release |
| LD-013 A recategorize that leaves type and collection unchanged still emits | Ticket "**categorization** actions taken" | No unchanged-value filter; `oldState.path` equals `newState.path` |
| LD-015 A categorization that sets only a collection (no type) emits | LD-009 "type **or collection**" | Part B gate: type **or** collection set, or prior state had either |
| LD-016 Dispatch stays post-commit. The Client Access paths use `DispatchFileCategorizationAuditTS` plus a GCA port bound to the aggregator | Architecture rules: services may not inject assemblers; cross-domain calls go through ports | Supersedes LD-006's "in the service" wording; the post-commit guarantee is unchanged |

## Acceptance Criteria

The criteria are owned by job story 01 (`dustin-thomason/docs/atlas/INT-138/stories/INT-138-job-story-01-categorization-audit.md`, **accepted** 2026-09-25) and cited here by number:

| # | Criterion (story 01) | Proven by |
| --- | --- | --- |
| C1 | Every time a file's deliverable type or collection is set, changed or removed, a record shows up in Europa's audit log | Part B service specs |
| C2 | Each categorization record shows who did it and the date and time | Part A converter / assembler spec |
| C3 | Each categorization record reads CATEGORIZE as its action and FILE as what was acted on | Part A; Part D constants spec |
| C4 | Each categorization record reads "Filepath: …", "Deliverable Type: …" and "Collection: …", in that order | Part A converter spec; Part D path-cell spec |
| C5 | When no collection applies to the file, the record reads "Collection: N/A" | Part A converter spec |
| C6 | Ops can narrow the audit log to just Categorize records | Part D; Europa exact-match filter (unchanged) |
| C7 | When several files are categorized at once, each file gets its own record | Part B service specs (batch, shared attachment) |
| C8 | When a file's categorization is removed, its record reads "Deliverable Type: N/A" and "Collection: N/A" | Part A converter spec; Part B unapprove service spec |
| C9 | When a file is categorized for someone who asked for it, the record shows who asked | Out of scope: it covers only the Planet Summary path, which the ticket's acceptance criteria don't include |

## Spec-writing sections

| Section | Where |
| --- | --- |
| 1. Folder hierarchy | Part A §1, Part B §1, Part D §1 |
| 2. New classes | Part A §2 (converter, params), Part B §2 (`DispatchFileCategorizationAuditTS`, `FileCategorizationAuditAssembler`, `IsCategorizationAuditDuePredicate`, `RecategorizeDeliverableFilesProjectionConverter`) |
| 3. New entities | None |
| 4. Modified entities | None |
| 5. New migrations | None |
| 6. New migration classes | None |
| 7. New DTOs | None. No request or response DTO or Swagger changes (Part B §7) |
| 8. New projections / params | Part A §8, Part B §8 (incl. the GCA `domain/projections/` types) |

**Callouts**
- **HTTP surface:** no route, method, body, status or auth change on any endpoint.
- **Registries and wiring:**
  - `ProceedingFileAuditModule` gains the converter (Part A).
  - `transactionScriptRegistry` gains `DispatchFileCategorizationAuditTS`, `FileCategorizationAuditAssembler`, `IsCategorizationAuditDuePredicate` and `RecategorizeDeliverableFilesProjectionConverter`; `recategorizeDeliverableFilesTSProvider` injects the projection converter; `GrantingClientAccessModule` binds `FILE_CATEGORIZATION_AUDIT_PORT` (Part B).
- **Ports:**
  - `ProceedingFileAuditDispatcherPort` gains a separate `applyCategorized(input)`; `apply` is unchanged (Part A).
  - New GCA port `FILE_CATEGORIZATION_AUDIT_PORT` / `FileCategorizationAuditPort` (`src/granting-client-access/domain/ports/file-categorization-audit.port.ts`), bound `useExisting: ProceedingFileAuditAggregator` (Part B).
- **Domain events:** new `AUDIT_EVENT_TYPE.CATEGORIZE`, sent through the existing SQS audit producer.
- **Domain exceptions:** none.
- **Authorization:** unchanged. The Europa page still requires `AUDIT` + `READ` in Atlas.
- **Spec tests:** listed per part.

## Scope and non-goals

- **In scope:** the five Callisto paths above, and the Atlas Europa page literal and path render.
- **Not in scope:**
  - other Client Access actions;
  - Planet Summary (files categorized by Callisto when a Mercury summary completes);
  - the prior categorization (the record carries only the categorization after the action);
  - Europa's `[0]` collapse for multi-resource events;
  - Europa API role checks;
  - Dione outbox events;
  - backfill (LD-011).
- **Known limitations:**
  - Audit delivery is at most once, as for every existing audit. A failed SQS send is logged and not retried.

---

## Part A — Audit core (callisto-back-end)

Baseline: `main` @ `59b1abd3`. All paths are relative to `callisto-back-end/` unless prefixed `europa-back-end/`. Abbreviation: `pfa/` = `src/proceedings/domain/sub-domains/proceeding-file-audit/`.

### Design

**Problem.** The audit core can only emit a FILE resource whose `newState.path` is the S3 key. `ProceedingFileToAuditEventResourceConverter.apply` builds `oldState.path`/`newState.path` from `filePath`, or from a prior path on rename (`pfa/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/proceeding-file-to-audit.converter.ts:18-36`). It has no way to carry a deliverable type or collection, and `AUDIT_EVENT_TYPE` has no categorization literal (`src/audits/constants.ts:10-19`).

**Requirement.** For each categorized file, the core emits one audit event (LD-005) with:
- type `CATEGORIZE` (LD-010);
- exactly one `FILE` resource whose `newState.path` is the categorization after the action, in the path format below (LD-002), and whose `oldState.path` is the same string, as the existing converter does when there is no prior resource (`pfa/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/proceeding-file-to-audit.converter.ts:18`);
- the caller's identity forwarded unchanged.

The core runs only after the write transaction script has returned (LD-006). The Client Access services reach it through `DispatchFileCategorizationAuditTS` and the GCA port (Part B). It never reads repositories. Type and collection names arrive already resolved.

**Solution.**
1. `src/audits/constants.ts`: add `CATEGORIZE: 'CATEGORIZE'` to `AUDIT_EVENT_TYPE`. That is the only change under `src/audits`.
2. New param type `ProceedingFileAuditCategorizedParams`, with the sub-type `ProceedingFileAuditCategorization` in the same file, placed next to the aggregator. All fields are `readonly`. Its `file` is `ProceedingFileAuditFile`, a named type added to `proceeding-file-audit.param.ts` and shared with `ProceedingFileAuditParams.file` and the existing converter's `file` argument (same four fields as before).
3. `ProceedingFileAuditAggregator.dispatchFileAuditCategorizedEvent`: stamps `eventType: CATEGORIZE` and calls the dispatcher port's new `applyCategorized`. The other six methods keep calling `apply` (`proceeding-file-audit.aggregator.ts:16-68`).
4. The categorized path has its own method at each layer, with no union and no runtime routing:
   - `ProceedingFileAuditDispatcherPort` gains `applyCategorized(input: ProceedingFileAuditCategorizedParams)`. `apply(input: ProceedingFileAuditParams)` is unchanged.
   - `ProceedingFileAuditDispatcher.applyCategorized` calls `assembler.applyCategorized`. Both dispatcher methods send through one private `sendAuditEvent` (producer call unchanged).
   - `ProceedingFileToAuditEventAssembler.applyCategorized` calls the **new** `ProceedingFileCategorizationToAuditEventResourceConverter` with `{ file, categorization }`. `apply` keeps the existing converter and prior-resource logic (moved into a private `toFileResource`). Both methods build the envelope in a private `toAuditEvent`.
5. `ProceedingFileAuditParams.eventType` narrows to `Exclude<…, 'CATEGORIZE'>`. Without this, a legacy payload could carry `CATEGORIZE` with a plain-S3-key path. With it, and with the separate method per input type, "type is `CATEGORIZE`" and "path uses the categorization format" are enforced together at compile time.

**Path format (LD-002; Europa passthrough per LD-007).** Europa shows `newState.path` verbatim for every type except `PERMISSIONS_UPDATED` (`europa-back-end/src/audits-event/domain/transaction-scripts/search-audit-events-paginated-TS/search-audit-events-paginated.transaction.script.ts:62-79`). The string is always three segments in fixed order, joined by `' | '`:

```
Filepath: <file.filePath> | Deliverable Type: <deliverableTypeName or N/A> | Collection: <collectionName or N/A>
```

The labels come from `CATEGORIZATION_PATH_LABELS` (`FILEPATH`, `DELIVERABLE_TYPE`, `COLLECTION`), and each segment is `<label>: <value>`.

`Filepath` is always `file.filePath`, the S3 key (LD-003), in both states. None of the categorization transaction scripts move the S3 object: there is no `copyObject`, `CopyObjectCommand` or `filePath =` in `recategorize-deliverable-files-ts/`, `approve-deliverable-files-ts/` (shared by approve v1 and v2) or `unapprove-deliverable-files-ts/`. So the key is the same before and after the action. Deliverable keys have the form `MMYYYY/jobId/proceedingId/<uuid><ext>` (`upload-start-deliverable-file-ts/get-deliverable-file-key/get-deliverable-file-key.ts:18`).

| Case (LD-009 path) | `newState.path` (= `oldState.path`) |
| --- | --- |
| **Set**: upload with a type, approve of a file with no prior categorization | `Filepath: 092026/5512/881/3f2a9c1e-8b7d-4e21-9a55-0c6f1d2e7b44.pdf \| Deliverable Type: Full Size PDF \| Collection: Full Transcript` |
| **Change**: recategorize | `Filepath: 092026/5512/881/3f2a…7b44.pdf \| Deliverable Type: Condensed PDF \| Collection: Day 1` |
| **Clear**: unapprove | `Filepath: 092026/5512/881/3f2a…7b44.pdf \| Deliverable Type: N/A \| Collection: N/A` |
| Track with no collection (C5), e.g. Exhibits | `Filepath: 092026/5512/881/9b1d…e2.pdf \| Deliverable Type: Exhibit \| Collection: N/A` |

(Table cells escape `|` as `\|`. The actual separator is a literal space, pipe, space.)

**N/A rule.** A segment reads `N/A` when its name is `null`, `undefined`, or empty or whitespace-only. Non-blank names print verbatim.

**Separators.** Values are written verbatim; dynamic collection names reject `|` (`src/granting-client-access/validators/validate-dynamic-collection-name.validator.ts:7`), so a collection name cannot open an extra segment when Atlas splits on `' | '`.

A `': '` inside a value is harmless: Atlas takes the label from the text before the **first** `': '` in each segment, and every label is a fixed Callisto label.

**Behavior boundaries.**
- The converter is total: it never throws on null or blank names.
- The assembler and dispatcher propagate errors unchanged, matching the existing file-audit methods (`proceeding-file-audit.aggregator.spec.ts:300-322`).
- The SQS producer catches send failures and returns `false` (`src/audits/infrastructure/adapters/outbound/producers/sqs/sqs-audit-event.producer.ts:31-34`). That boolean is returned to the caller unchanged.
- The core does not suppress events. Whatever categorization it receives, it emits.

### 1. Folder hierarchy

```
src/
├── audits/
│   └── constants.ts                                                    (changed: + CATEGORIZE)
└── proceedings/domain/sub-domains/proceeding-file-audit/
    ├── proceeding-file-audit.module.ts                                 (changed: + converter provider)
    ├── domain/
    │   ├── aggregators/
    │   │   ├── proceeding-file-audit.aggregator.ts                     (changed: + dispatchFileAuditCategorizedEvent)
    │   │   ├── proceeding-file-audit.param.ts                          (changed: + ProceedingFileAuditFile; eventType excludes CATEGORIZE)
    │   │   ├── proceeding-file-audit-categorized.param.ts              (NEW)
    │   │   └── __specs__/
    │   │       └── proceeding-file-audit.aggregator.spec.ts            (changed)
    │   └── ports/
    │       └── proceeding-file-audit-dispatcher.port.ts                (changed: + applyCategorized)
    └── infrastructure/dispatchers/
        ├── proceeding-file-audit.dispatcher.ts                         (changed: + applyCategorized, private sendAuditEvent)
        ├── __specs__/
        │   └── proceeding-file-audit.dispatcher.spec.ts                (changed)
        └── proceeding-file-to-audit-event-assembler/
            ├── proceeding-file-to-audit-event.assembler.ts             (changed: + applyCategorized, new ctor dep)
            ├── proceeding-file-to-audit.converter.ts                   (changed: file typed as ProceedingFileAuditFile)
            ├── proceeding-file-categorization-to-audit.converter.ts    (NEW)
            └── __specs__/
                ├── proceeding-file-to-audit-event.assembler.spec.ts    (changed)
                └── proceeding-file-categorization-to-audit.converter.spec.ts   (NEW)
```

The placement follows the existing rules:
- **Param file next to the aggregator.** `check-domain-type-structure.ts:69-83` accepts a `.param.ts` only when its folder has a consumer. The aggregator is that consumer.
- **One type per file.** Follows `.cursor/rules/type-files.mdc:5-8`. The sub-type shares the file under the "closely related sub-types" exception at `:8`, as does `ProceedingFileAuditFile` in `proceeding-file-audit.param.ts`.
- **Converter file name.** `{source}-to-{target}.converter.ts` (`.cursor/rules/architecture-patterns.mdc:265`), mirroring `proceeding-file-to-audit.converter.ts`.

### 2. New / changed classes

| Class / type | Path | Status |
| --- | --- | --- |
| `ProceedingFileCategorizationToAuditEventResourceConverter` | `pfa/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/proceeding-file-categorization-to-audit.converter.ts` | **new** |
| `ProceedingFileAuditCategorizedParams`, `ProceedingFileAuditCategorization` (types) | `pfa/domain/aggregators/proceeding-file-audit-categorized.param.ts` | **new** |
| `ProceedingFileAuditAggregator` | `pfa/domain/aggregators/proceeding-file-audit.aggregator.ts` | changed: + `dispatchFileAuditCategorizedEvent` (calls `applyCategorized`), after `:68` |
| `ProceedingFileToAuditEventAssembler` | `pfa/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/proceeding-file-to-audit-event.assembler.ts` | changed: 3rd ctor dependency; + `applyCategorized`; `apply` signature unchanged, its resource selection moves to a private `toFileResource`; both methods share a private `toAuditEvent` envelope builder |
| `ProceedingFileAuditDispatcher` | `pfa/infrastructure/dispatchers/proceeding-file-audit.dispatcher.ts` | changed: + `applyCategorized`; `apply` and `applyCategorized` send through a private `sendAuditEvent` (the producer call from `:20-23`) |
| `ProceedingFileAuditDispatcherPort` (type) | `pfa/domain/ports/proceeding-file-audit-dispatcher.port.ts` | changed: + `applyCategorized(input: ProceedingFileAuditCategorizedParams)`; `apply` unchanged (`:7-9`) |
| `ProceedingFileAuditParams` (type) | `pfa/domain/aggregators/proceeding-file-audit.param.ts` | changed: `eventType` (`:19`) excludes `CATEGORIZE`; `file` typed as `ProceedingFileAuditFile` |
| `ProceedingFileAuditFile` (type) | `pfa/domain/aggregators/proceeding-file-audit.param.ts` | **new**: `{ readonly id: number; readonly fileName: string; readonly filePath: string; readonly bucket: string }`, the same four fields `file` already had, now `readonly` |
| `ProceedingFileToAuditEventResourceConverter` | `pfa/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/proceeding-file-to-audit.converter.ts` | changed: `file` argument typed as `ProceedingFileAuditFile` (same fields); body unchanged |
| `AUDIT_EVENT_TYPE` (const) | `src/audits/constants.ts` | changed: + `CATEGORIZE: 'CATEGORIZE'` after `PERMISSIONS_UPDATED` (`:18`) |

`ProceedingFileAuditParams`, `ProceedingFileAuditFile`, `ProceedingFileAuditDispatcherPort`, `ProceedingFileAuditPriorResource` and `ProceedingFileToAuditEventAssembler` have no importers outside `pfa/`, so those signature changes stay inside the sub-domain. `ProceedingFileAuditCategorizedParams` has no importer outside `pfa/` either: Client Access code uses its own projections instead (Part B).

**New converter (exact implementation).**

```ts
import { Injectable } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { AuditEventResourceDomainEvent } from 'src/audits/domain/domain-events/audit-event-resource.de';
import { AuditEventResourceType } from 'src/audits/constants';
import {
	ProceedingFileAuditCategorization,
	ProceedingFileAuditCategorizedParams,
} from '../../../domain/aggregators/proceeding-file-audit-categorized.param';

// Europa renders newState.path verbatim; Atlas splits it on this separator and
// bolds the text before ': ' in each segment (cross-repo display contract).
const CATEGORIZATION_PATH_SEPARATOR = ' | ';
const CATEGORIZATION_LABEL_SEPARATOR = ': ';
const CATEGORIZATION_PATH_LABELS = {
	FILEPATH: 'Filepath',
	DELIVERABLE_TYPE: 'Deliverable Type',
	COLLECTION: 'Collection',
} as const;
const NOT_APPLICABLE = 'N/A';

type ProceedingFileCategorizationToAuditEventResourceInput = Pick<
	ProceedingFileAuditCategorizedParams,
	'file' | 'categorization'
>;

@Injectable()
export class ProceedingFileCategorizationToAuditEventResourceConverter {
	apply({
		file,
		categorization,
	}: ProceedingFileCategorizationToAuditEventResourceInput): AuditEventResourceDomainEvent {
		const path = this.toCategorizationPath(file.filePath, categorization);
		return {
			id: uuidv4(),
			resourceType: AuditEventResourceType.FILE,
			resourceId: file.id.toString(),
			resourceName: file.fileName,
			resourcePath: file.filePath,
			resourceBucket: file.bucket,
			oldState: {
				path,
				bucket: file.bucket,
				fileName: file.fileName,
			},
			newState: {
				path,
				bucket: file.bucket,
				fileName: file.fileName,
			},
		};
	}

	private toCategorizationPath(
		filePath: string,
		categorization: ProceedingFileAuditCategorization,
	): string {
		return [
			[CATEGORIZATION_PATH_LABELS.FILEPATH, filePath],
			[
				CATEGORIZATION_PATH_LABELS.DELIVERABLE_TYPE,
				this.formatOrNotApplicable(categorization.deliverableTypeName),
			],
			[
				CATEGORIZATION_PATH_LABELS.COLLECTION,
				this.formatOrNotApplicable(categorization.collectionName),
			],
		]
			.map(
				([label, value]) =>
					`${label}${CATEGORIZATION_LABEL_SEPARATOR}${value}`,
			)
			.join(CATEGORIZATION_PATH_SEPARATOR);
	}

	private formatOrNotApplicable(value: string | null | undefined): string {
		return value?.trim() ? value : NOT_APPLICABLE;
	}
}
```

The converter matches the existing one on these fields: `resourceType`, `resourceId`, `resourceName`, `resourcePath` (the exact key), `resourceBucket`, and `bucket`/`fileName` in both states (`proceeding-file-to-audit.converter.ts:20-36`). Only the two `path` values differ. It passes the structural rules:
- It imports no repository or other converter (`fitness-functions-rules/architecture-rules/converters.rules.ts:13-35`) and no assembler, service or mapper (`:43-63`).
- It is `@Injectable()`, the formatters are private methods, and the constants are not exported, so `check-no-util-files.ts:122-134` is satisfied.
- The domain import goes infrastructure → domain `.param.ts`, the same direction the existing converter uses at `:5`.

**Changed assembler (exact shape).**

```ts
@Injectable()
export class ProceedingFileToAuditEventAssembler {
	constructor(
		private readonly auditConfigAccessor: AuditConfigAccessor,
		private readonly proceedingFileToAuditEventResourceConverter: ProceedingFileToAuditEventResourceConverter,
		private readonly proceedingFileCategorizationToAuditEventResourceConverter: ProceedingFileCategorizationToAuditEventResourceConverter,
	) {}

	async apply(
		input: ProceedingFileAuditParams,
	): Promise<AuditEventDomainEvent> {
		return this.toAuditEvent({
			type: input.eventType,
			identity: input.user.identity,
			auditEventResources: [this.toFileResource(input)],
		});
	}

	async applyCategorized(
		input: ProceedingFileAuditCategorizedParams,
	): Promise<AuditEventDomainEvent> {
		return this.toAuditEvent({
			type: input.eventType,
			identity: input.user.identity,
			auditEventResources: [
				this.proceedingFileCategorizationToAuditEventResourceConverter.apply(
					{
						file: input.file,
						categorization: input.categorization,
					},
				),
			],
		});
	}

	private toFileResource(
		input: ProceedingFileAuditParams,
	): AuditEventResourceDomainEvent {
		const { file, oldFilePath, oldFileName } = input;
		const priorResource: ProceedingFileAuditPriorResource | undefined =
			oldFilePath !== undefined || oldFileName !== undefined
				? { path: oldFilePath, fileName: oldFileName }
				: undefined;
		return this.proceedingFileToAuditEventResourceConverter.apply(
			file,
			priorResource,
		);
	}

	private toAuditEvent(
		event: Pick<
			AuditEventDomainEvent,
			'type' | 'identity' | 'auditEventResources'
		>,
	): AuditEventDomainEvent {
		return {
			id: uuidv4(),
			createdAt: new Date(),
			serviceName: this.auditConfigAccessor.serviceName,
			...event,
		};
	}
}
```

The assembler injects two converters and no assembler, service or mapper (`fitness-functions-rules/architecture-rules/assemblers.rules.ts:11-42`). The event envelope (`id`, `createdAt`, `serviceName`, `type`, `identity`) matches `assembler.ts:32-39` field for field.

**Changed aggregator (addition).**

```ts
async dispatchFileAuditCategorizedEvent(
	params: ProceedingFileAuditCategorizedParams,
): Promise<boolean> {
	return this.proceedingFileAuditDispatcher.applyCategorized({
		...params,
		eventType: AUDIT_EVENT_TYPE.CATEGORIZE,
	});
}
```

**Changed dispatcher (additions).**

```ts
async applyCategorized(
	input: ProceedingFileAuditCategorizedParams,
): Promise<boolean> {
	return this.sendAuditEvent(
		await this.proceedingFileToAuditEventAssembler.applyCategorized(
			input,
		),
	);
}

private async sendAuditEvent(
	auditEvent: AuditEventDomainEvent,
): Promise<boolean> {
	return await this.auditEventProducer.apply(
		this.auditConfigAccessor.sqsAuditEventUrl,
		auditEvent,
	);
}
```

`apply` becomes `return this.sendAuditEvent(await this.proceedingFileToAuditEventAssembler.apply(input));`, the same assembler → producer call as before.

**`AUDIT_EVENT_TYPE` consumers checked.** Adding a key breaks none of them.

| Consumer | Usage | Effect of a new key |
| --- | --- | --- |
| `src/audits/types/audit-event.types.ts:13` | `eventType: keyof typeof AUDIT_EVENT_TYPE` annotation | Union widens; nothing narrows on it |
| `pfa/domain/aggregators/proceeding-file-audit.param.ts:19` | optional `keyof typeof` | Narrowed on purpose (Solution step 5) |
| `src/proceedings/domain/sub-domains/proceeding-audit/domain/aggregators/proceeding-audit.param.ts:12`, `src/cases/.../case-file-audit-dispatcher/case-file-audit.types.ts:12`, `src/cases/.../case-merge-audit-dispatcher/case-merge-audit.types.ts:12`, `src/proceeding-job-submission/.../job-submission-file-audit.types.ts:12` | optional `keyof typeof` | Union widens; no switch or map |
| Aggregators and assemblers (`case-file-audit.aggregator.ts:28-64`, `proceeding-audit.aggregator.ts:21`, `job-submission-file-audit.aggregator.ts:21`, `permissions-to-audit-event.assembler.ts:30`, `proceeding-file-audit.aggregator.ts:21-66`) | member access only | None |
| All specs under `src/**/__specs__` | member access only | None |

A repo-wide search found no `switch` on `eventType` or `.type`, no `Record<keyof typeof AUDIT_EVENT_TYPE, …>`, no `Object.values`/`Object.keys(AUDIT_EVENT_TYPE)`, no `toMatchSnapshot`/`toMatchInlineSnapshot`, and no `__snapshots__` directory. There are no `*.integration.spec.ts` or `test/` suites touching audits (`jest-integration.json:5`). The only other occurrence is a copy of the constant in an older spec document (`docs/specs/atlas-maintenance/permissions/PRDV-15840-…md:283`). It is not code and does not need updating.

**Rest of `src/audits` (item 6): nothing changes except `constants.ts`.**

| File | Why unchanged |
| --- | --- |
| `src/audits/domain/domain-events/audit-event.de.ts:7` | `type: string` already accepts `'CATEGORIZE'` |
| `src/audits/domain/domain-events/audit-event-resource.de.ts:12-17` | `ResourceState.path?: string` already carries any string |
| `src/audits/infrastructure/adapters/outbound/producers/sqs/sqs-audit-event.producer.ts:19-35` | Serializes the whole message (`:26`) with no type-specific logic; one event per file, and each gets its own `groupId`/`deduplicationId` (`:27-28`) |
| `src/audits/infrastructure/adapters/outbound/producers/null/null.producer.ts:7-14` | No-op |
| `src/audits/audits.module.ts:27-32` | No new provider |

Europa already accepts `'CATEGORIZE'` unchanged (LD-007):
- the entity's `type` is a free string (`europa-back-end/src/audits-event/domain/entities/audit-event/audit-event.entity.ts:14-15`);
- the listener stores the body as-is (`application/listeners/sqs-audit-event.listener.ts:21-26`);
- the search filter is `@IsString()` with no enum (`search-audit-events-paginated.request.dto.ts:55-58`);
- `CATEGORIZE` falls into the non-permissions branch (`search-audit-events-paginated.transaction.script.ts:74-79`).

### 3–4. Entities

N/A. The audit core reads no entity and writes none. Type and collection names arrive resolved in the params, because converters may not import repositories (`converters.rules.ts:13-22`). The calling services resolve the names (Part B).

### 5–6. Migrations

N/A. No schema change: audit events go to SQS and are stored in Europa's Mongo collection, not Callisto's Postgres.

### 7. DTOs

N/A. No HTTP surface changes in this part. The core is only reachable through `ProceedingFileAuditAggregator`, which services inject. No route, request/response DTO, Swagger helper or status/auth decorator is touched.

### 8. Params / projections

`pfa/domain/aggregators/proceeding-file-audit-categorized.param.ts` (new):

```ts
import { AuthUser } from 'src/generic/auth/constants';
import { AUDIT_EVENT_TYPE } from 'src/audits/constants';
import { ProceedingFileAuditFile } from './proceeding-file-audit.param';

export type ProceedingFileAuditCategorization = {
	readonly deliverableTypeName: string | null;
	readonly collectionName: string | null;
};

export type ProceedingFileAuditCategorizedParams = {
	readonly eventType?: typeof AUDIT_EVENT_TYPE.CATEGORIZE;
	readonly file: ProceedingFileAuditFile;
	readonly user: Partial<AuthUser>;
	readonly categorization: ProceedingFileAuditCategorization;
};
```

`pfa/domain/aggregators/proceeding-file-audit.param.ts` (changed):

```ts
export type ProceedingFileAuditFile = {
	readonly id: number;
	readonly fileName: string;
	readonly filePath: string;
	readonly bucket: string;
};

export type ProceedingFileAuditParams = {
	eventType?: Exclude<
		keyof typeof AUDIT_EVENT_TYPE,
		typeof AUDIT_EVENT_TYPE.CATEGORIZE
	>;
	file: ProceedingFileAuditFile;
	user: Partial<AuthUser>;
	oldFilePath?: string;
	oldFileName?: string;
};
```

`pfa/domain/ports/proceeding-file-audit-dispatcher.port.ts` (changed):

```ts
export type ProceedingFileAuditDispatcherPort = {
	apply(input: ProceedingFileAuditParams): Promise<boolean>;
	applyCategorized(
		input: ProceedingFileAuditCategorizedParams,
	): Promise<boolean>;
};
```

**Field contract**

| Field | Contract | Evidence |
| --- | --- | --- |
| `file` | `ProceedingFileAuditFile`, the same shape as `ProceedingFileAuditParams.file`. `id: number` accepts the branded `FileId`. | `proceeding-file-audit.param.ts:20-25` (shape before extraction); `src/shared/shared-entities/entities/files/file.entity.ts:18,25` |
| `user` | `Partial<AuthUser>`, same as `:26`. Request paths pass the request's `AuthUser`. The assembler forwards `user.identity` unchanged. | `assembler.ts:37` |
| `categorization` | The state after the action. Both names `null` means cleared (unapprove, C8). | LD-002, LD-009 |

**Why the full identity matters for "who" (C2).**
- `AuditEventDomainEvent.identity` declares only four fields (`src/audits/domain/domain-events/audit-event.de.ts:9-14`). At runtime, though, the assembler forwards the whole `AuthUser.identity` object, and the producer `JSON.stringify`s all of it (`sqs-audit-event.producer.ts:26`).
- Europa builds `userName` from `identity.userFirstName` and `identity.userLastName` (`search-audit-events-paginated.transaction.script.ts:93-95`).
- Europa marks all six of `userId`, `userEmail`, `ipAddress`, `userAgent`, `userFirstName`, `userLastName` as `required: true` (`europa-back-end/src/audits-event/domain/entities/audit-event/identity.ts:4-15`).

So the identity a caller passes must carry all six fields. `Partial<AuthUser>` enforces this at compile time: once `identity` is present, its type requires every field (including `featureFlags`) (`src/generic/auth/constants.ts:40-48`). Had the param declared a narrower identity type such as `{ userId, userEmail }`, a caller would compile while blanking the "who" column in Europa, or failing the Europa write.

No projection: the core returns `Promise<boolean>`, the producer's result, like the existing methods.

### Module wiring

`pfa/proceeding-file-audit.module.ts:10-17`: add one provider. `exports` stays `[PROCEEDING_FILE_AUDIT_DISPATCHER]` (`:18`).

```ts
providers: [
	{ provide: PROCEEDING_FILE_AUDIT_DISPATCHER, useClass: ProceedingFileAuditDispatcher },
	ProceedingFileToAuditEventAssembler,
	ProceedingFileToAuditEventResourceConverter,
	ProceedingFileCategorizationToAuditEventResourceConverter, // new
],
```

Unchanged:
- `src/proceedings/proceedings.module.ts`: it imports `ProceedingFileAuditModule` (`:113`) and provides and exports `ProceedingFileAuditAggregator` (`:185`, `:212`), so the new aggregator method needs no module change. Its only caller is `DispatchFileCategorizationAuditTS` (Part B), through the GCA port (`src/granting-client-access/granting-client-access.module.ts:152-153`).

No module spec exists in `pfa/`, and `*module.ts` is excluded from coverage (`jest-e2e.json:21`). A missing provider would therefore show up only as a Nest DI error at app boot. Assembler specs build their own providers and would not catch it.

### Spec tests

These follow the repo conventions (`.cursor/rules/test-comments.mdc`): given/when/then, SUT named `target`, `…Mock` suffix, `// Arrange // Act // Assert`, `createApplyMock` (`src/test-utils/test-utils.ts:85-93`), `createMockAuthUser` (`src/generic/auth/test-utils.ts:28-49`). Path-format cases build the expected string from the generated fixture values and assert it exactly. Criteria: C2 who/when · C3 CATEGORIZE + FILE · C4 path order · C5 Collection N/A · C8 cleared = both N/A.

**NEW** `pfa/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/__specs__/proceeding-file-categorization-to-audit.converter.spec.ts`

| Case | Asserts | Criterion |
| --- | --- | --- |
| given a categorization → then new path shows type and collection | `newState.path === 'Filepath: <filePath> \| Deliverable Type: <typeName> \| Collection: <collectionName>'` | C4 |
| same → then old path is the same as the new path | `oldState.path === newState.path` | LD-002 |
| same → then returns one FILE resource at parity | `toEqual({ id: expect.any(String), resourceType: 'FILE', resourceId, resourceName, resourcePath: filePath, resourceBucket, oldState: {path, bucket, fileName}, newState: {path, bucket, fileName} })`, both paths the full categorization string | C3, LD-003, LD-005 |
| same → then segments are in fixed order | `newState.path.split(' \| ')` equals `['Filepath: …', 'Deliverable Type: …', 'Collection: …']` | C4 |
| given type with null collection → then `Collection: N/A` | `newState.path === 'Filepath: <filePath> \| Deliverable Type: <typeName> \| Collection: N/A'` | C5 |
| given cleared (both null) → then new path both N/A | `newState.path === 'Filepath: <filePath> \| Deliverable Type: N/A \| Collection: N/A'` | C8 |
| edge: blank or whitespace-only names → N/A | `deliverableTypeName: '  '`, `collectionName: ''` produce `N/A` in both segments; never an empty segment | C5 (graceful) |

**CHANGED** `pfa/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/__specs__/proceeding-file-to-audit-event.assembler.spec.ts`

| Case | Asserts | Criterion |
| --- | --- | --- |
| `beforeEach`: add `categorizationConverterMock = createApplyMock<ProceedingFileCategorizationToAuditEventResourceConverter>()` provider | Existing cases keep compiling and resolving through DI | regression |
| existing `apply` cases (without / with `oldFilePath`) + `expect(categorizationConverterMock.apply).not.toHaveBeenCalled()` | Legacy events still reach the old converter with `(file, undefined)` / `(file, prior)` | regression |
| `applyCategorized` → then routes to the categorization converter | `categorizationConverterMock.apply` called with `{ file, categorization }` | C3 |
| same → then never calls the legacy converter | `converterMock.apply` not called | C3 |
| same → then envelope has CATEGORIZE, identity, timestamp, one resource | `toEqual({ id, createdAt: expect.any(Date), serviceName, type: AUDIT_EVENT_TYPE.CATEGORIZE, identity: mockParams.user.identity, auditEventResources: [mockResource] })` | C2, C3, LD-005 |
| when user carries only `{ identity }` → then identity forwarded unchanged | `result.identity` is the supplied identity object (`toBe`) | C2 |
| when the categorization converter throws → then `applyCategorized` rejects with the same error | `rejects.toThrow(error)`; `converterMock.apply` not called | graceful (deterministic failure) |

**CHANGED** `pfa/domain/aggregators/__specs__/proceeding-file-audit.aggregator.spec.ts`: the dispatcher mock becomes `createMock<ProceedingFileAuditDispatcherPort>({ apply, applyCategorized })`; new `describe('when: dispatching file categorized audit event')`, mirroring the APPROVED block.

| Case | Asserts | Criterion |
| --- | --- | --- |
| then delegates to the categorized dispatch with CATEGORIZE | dispatcher `applyCategorized` called once with `{ ...params, eventType: AUDIT_EVENT_TYPE.CATEGORIZE }`, so `categorization`/`user` pass through untouched; returns `true` | C3, C2 (user passed) |
| then never calls the legacy dispatch | dispatcher `apply` not called | C3 |
| then returns false when the dispatcher returns false | `result === false` | graceful |
| then propagates dispatcher errors | `rejects.toThrow(mockError)` | graceful |

**CHANGED** `pfa/infrastructure/dispatchers/__specs__/proceeding-file-audit.dispatcher.spec.ts`: the assembler mock becomes `createMock<ProceedingFileToAuditEventAssembler>({ apply, applyCategorized })`, the existing 'applying audit event dispatch' success case also asserts `applyCategorized` is not called (regression), and a new `describe('when: applying categorized audit event dispatch')` is added.

| Case | Asserts | Criterion |
| --- | --- | --- |
| then passes the input to the assembler and the event to the producer | assembler `applyCategorized` called with the input unchanged; producer called with `(sqsAuditEventUrl, assembledEvent)`; returns `true` | C3 |
| then propagates an assembler error without producing | `rejects`; producer not called | graceful |
| then propagates a producer error | `rejects.toThrow` | graceful |
| then returns false when the producer returns false | `result === false` | graceful |

Gate for this part: `npm test -- --runInBand src/proceedings/domain/sub-domains/proceeding-file-audit`, plus `npm run test:conventions`. The latter covers the converter/assembler dependency rules, type structure and the no-util rule.

### Neighbors that must not change

| Surface | Why it stays the same | Existing spec that proves it |
| --- | --- | --- |
| `ProceedingFileToAuditEventResourceConverter` output for CREATED / DOWNLOADED / DELETED / APPROVED / UNAPPROVED (`path = filePath` in both states) | Type-only edit (`file` typed as `ProceedingFileAuditFile`, same fields); body unchanged. It takes no `eventType` (`converter.ts:9-17`), so every non-rename type gets the same output. | `proceeding-file-to-audit.converter.spec.ts:20-51` |
| Same converter, RENAMED (prior path and name in `oldState`) | Body unchanged | `proceeding-file-to-audit.converter.spec.ts:53-87` |
| Assembler `apply` (prior-resource derivation, envelope) | The prior-resource logic from `:21-30` moves into `toFileResource` (destructure narrowed to `file`, `oldFilePath`, `oldFileName`; the converter result is returned directly). The envelope is built in `toAuditEvent` with identical fields | `proceeding-file-to-audit-event.assembler.spec.ts` "when: assembling audit event" (without `oldFilePath` → `(file, undefined)`; with `oldFilePath` → prior resource) |
| Aggregator's six existing methods | Not edited; still call `apply` | `proceeding-file-audit.aggregator.spec.ts` CREATED, DOWNLOADED, RENAMED, DELETED, APPROVED, UNAPPROVED blocks |
| Dispatcher `apply` pass-through and error propagation | Same assembler → producer call, now through the private `sendAuditEvent` | `proceeding-file-audit.dispatcher.spec.ts` blocks "applying audit event dispatch", "assembler throws error", "producer throws error", "producer returns false" |
| Other audit sub-domains (cases, proceeding rename, job submission, permissions) | They only reference `AUDIT_EVENT_TYPE` members (consumer table above) | `src/cases/domain/sub-domains/audit/domain/aggregators/__specs__/case-file-audit.aggregator.spec.ts`, `src/proceedings/domain/sub-domains/proceeding-audit/domain/aggregators/__specs__/proceeding-audit.aggregator.spec.ts`, `src/proceeding-job-submission/domain/sub-domains/audit/domain/aggregators/__specs__/job-submission-file-audit.aggregator.spec.ts`, `src/generic/auth/domain/sub-domains/infrastructure/dispatchers/permissions-audit-dispatcher/__specs__/permissions-to-audit-event.assembler.spec.ts` |
| Europa `PERMISSIONS_UPDATED` rendering | Europa not edited (LD-007); CATEGORIZE takes the `else` branch | `europa-back-end/.../search-audit-events-paginated.transaction.script.ts:62-73` (read-only evidence, no Callisto spec) |

### Notes

- A recategorize that leaves the type and collection unchanged still emits, with equal `oldState.path` and `newState.path` (LD-013). The core never suppresses an event.
- How Atlas displays `CATEGORIZE` is specified in Part D.

---

## Part B — Dispatch on the Client Access write paths (callisto-back-end)

Baseline: `main` @ `59b1abd3`. All paths below are relative to `callisto-back-end/`, and `gca/` = `src/granting-client-access/`. Part A defines `ProceedingFileAuditAggregator.dispatchFileAuditCategorizedEvent(params)`. The Client Access CATEGORIZE path reaches it only through the GCA port below, and no GCA TS, projection or param imports a `pfa/` type.

### Design

**Problem.** None of the five Client Access write paths that set or clear a file's deliverable type/collection sends a categorization audit event. The service never sees the resolved categorization, because it stays inside the transaction script (TS). For the same reason, three of the five TS/projection outputs don't carry the data a categorization record needs.

**Requirement.** Once the TS has committed, each service must hold, for every file it categorized: the file's `id/fileName/filePath/bucket` and the resulting type and collection ids (LD-002). An unapprove also holds the ids it cleared, so the gate below can tell a cleared categorization from a never-categorized file (LD-009). Those ids must then become names before dispatch, because the Part A dispatcher/converter cannot query, with one event dispatched per file (LD-005). Request and response contracts don't change.

**Solution.**
- Each write TS's projection gets the missing per-file fields, typed with GCA-owned plain projections (`gca/domain/projections/`) and branded ids.
- Each service maps its TS result to entries in a private `toCategorizationAuditEntries(result)`. After `await ts.apply(...)` returns, and after its existing APPROVED/UNAPPROVED/CREATED dispatch, it calls one post-commit TS: `DispatchFileCategorizationAuditTS.apply({ entries, user })`.
- That TS owns the rest:
  - `FileCategorizationAuditAssembler` drops entries that `IsCategorizationAuditDuePredicate` rejects and bulk-loads the names.
  - Each event is dispatched through the GCA-owned port `FILE_CATEGORIZATION_AUDIT_PORT`, which the GCA module binds `useExisting: ProceedingFileAuditAggregator`.
- The write TS runs inside `TransactionContextService.runTransactional`, which calls `dataSource.transaction` and commits before it resolves (`src/typeorm/infrastructure/services/transaction-context.service.ts:17-25`). So the dispatch point is post-commit. `DispatchFileCategorizationAuditTS` is a plain provider with no transactional proxy.

| Path (service) | Files per call | Emits CATEGORIZE for | `previous` | `categorization` (after) | New data needed |
| --- | --- | --- | --- | --- | --- |
| Recategorize: `RecategorizeDeliverableFilesService` (`PATCH /recategorize-deliverable-files`) | 1..n; several may share one attachment | Every file in the TS processed set. That is all batch files, including siblings on a shared attachment (TS `:104-129`) | `null` | `{requestedDeliverableTypeId, resolvedDeliverableCollectionId}` (TS `:66`, `:157-181`; includes a found-or-created dynamic collection) | 1. The TS returns `RecategorizeDeliverableFilesProjection` (per-file `processedFiles[]`), built by the new `RecategorizeDeliverableFilesProjectionConverter`. 2. The batch projection gains `filePath`/`bucket`. 3. The shared `fetchFilesByProceedingId` select gains `file.filePath`, `file.bucket` |
| Approve v1: `ApproveDeliverableFilesService` (`POST /approve-files-for-delivery`) | 1..n | Processed (not skipped) files that pass the gate below | `null` | `plan.deliverableTypeId`, `plan.deliverableCollectionId` (TS `:140-154`) | The TS projection gains `processedFileCategorizations`, built from `plans` + `decisions` |
| Approve v2: `ApproveDeliverableFilesV2Service` (`POST /v2/approve-files-for-delivery`) | 1..n (same TS) | Processed files. The type is always set, because v2 rejects a null type (service `:86-90`) | Same as v1 | Same as v1. For a dynamic collection, `plan.deliverableCollectionId` is the id from `resolveBatchCollection` (TS `:104-105`, `:205-249`) | Same as v1 |
| Upload-complete: `DeliverableUploadService.uploadComplete` (`POST /upload-complete`) | 1 | The file, only if `fileAttachment.deliverableTypeId` or `deliverableCollectionId` ≠ null | `null` | `fileAttachment.deliverableTypeId/deliverableCollectionId` (the resolved dynamic id arrives through the mapper: TS `:79-86`, `create-deliverable-file-attachment.assembler.ts:38-40`) | Type-level change only: the runtime object already carries both ids |
| Unapprove: `UnapproveDeliverableFilesService` (`POST /unapprove-files-for-delivery`) | 1..n | Processed files whose previous type or collection ≠ null | The attachment's ids, read inside the TS before the clear (TS `:152-159`). Only the gate below reads them | `{null, null}` → `N/A \| N/A` | 1. New GCA repo read `findCategorizationsByIds`. 2. The TS projection gains `processedFileCategorizations` |

**LD-009 gate: `IsCategorizationAuditDuePredicate`, applied once by the assembler.** An entry is due if (a) `deliverableTypeId` or `deliverableCollectionId` ≠ null, or (b) `previous` has a non-null type or collection. Otherwise it is dropped. This one rule gives the right result on every path:

- **Upload or v1 approve with neither a type nor a collection:** dropped, because the write leaves the file uncategorized and `previous` is `null`.
- **v1 approve that sets only a collection:** kept. LD-009 counts a collection change.
- **Recategorize:** always kept, including when the type and collection are unchanged (LD-013). The type is required (`recategorize-deliverable-files.request.dto.ts:35`).
- **Unapprove of a categorized file:** kept (LD-009 "clear").
- **Unapprove of a never-categorized file:** dropped. Nothing was categorized, and its `UNAPPROVED` record already covers the action.

**Constraints this design respects:**

- **LD-006:**
  - TSs import no aggregator. `transaction-scripts-no-aggregators` in `fitness-functions-rules/architecture-rules/transaction-scripts.rules.ts:31-44` matches `.*aggregator.*`, and that pattern also catches Part A's params file under `…/proceeding-file-audit/domain/aggregators/`. So no TS or TS projection imports a `pfa/` type. The dispatch TS depends on the GCA port `FileCategorizationAuditPort` (`gca/domain/ports/file-categorization-audit.port.ts`), whose event type is the GCA projection `FileCategorizationAuditEventProjection`.
  - The port binding is `{ provide: FILE_CATEGORIZATION_AUDIT_PORT, useExisting: ProceedingFileAuditAggregator }` in `gca/granting-client-access.module.ts`. `FileCategorizationAuditEventProjection` is structurally assignable to `ProceedingFileAuditCategorizedParams` (branded `FileId` satisfies `id: number`). Nest does not type-check `useExisting`, so the dispatch TS spec assigns an aggregator mock to `FileCategorizationAuditPort` to make type-check fail on drift.
  - Services import no converter (`services.rules.ts:30-36`), and the header at `services.rules.ts:6-7` routes services to assemblers through transaction scripts. Each service therefore injects only `DispatchFileCategorizationAuditTS`; the assembler lives under that TS.
  - Assemblers may use repositories (`.cursor/rules/architecture-patterns.mdc:444`).
- **GCA is exempt from the cross-module boundary rule** (`cross-module-boundaries/domain-boundaries.rules.ts:36-37`), so the GCA module's import of `ProceedingFileAuditAggregator` for the binding is allowed.

**Dispatch style.** The CATEGORIZE call runs **after** the existing APPROVED/UNAPPROVED/CREATED dispatch in the same service, which leaves the sibling dispatch's timing and arguments unchanged. The call is awaited. Inside it, the TS dispatches the events with `Promise.all`. `SQSAuditEventProducer.apply` already catches a failed send and returns `false` (`src/audits/infrastructure/adapters/outbound/producers/sqs/sqs-audit-event.producer.ts:23-34`), and that SQS behaviour doesn't change.

**Post-commit failure handling: `DispatchFileCategorizationAuditTS` never rejects.**
- **No entries:** it returns at once, with no assembler call.
- **The assembler rejects** (a name lookup fails): it logs `logger.error('Failed to resolve CATEGORIZE audit events', error instanceof Error ? error : null, { fileIds, userId })`, where `userId` is `user.identity?.userId ?? user.sub`, and dispatches nothing.
- **A dispatch resolves `false` or throws:** it logs `logger.warn` with the `fileId` for that event, and the other events still go out.

So the service always returns its normal result. The precedent is `delete-deliverable-files.service.ts:72-96`: a post-commit side-effect failure is logged and the committed write still reports success. The residual risk is that a DB read failure or a failed send costs audit records, and that loss is logged.

**Prior-categorization read (implementation note).**
- **Unapprove** reads each fetched attachment's type and collection with `findCategorizationsByIds`, in the same `Promise.all` as `findFileAttachmentIdsByTag`, so the read finishes before `processFile` clears the columns. It is **not** flag-gated. Only the LD-009 gate reads the result.
- **Upload, approve and recategorize** read no prior categorization and pass `previous: null`.

### 1. Folder hierarchy

```
src/granting-client-access/
  granting-client-access.module.ts                                  CHANGED (+FILE_CATEGORIZATION_AUDIT_PORT useExisting binding)
  test-utils.ts                                                     CHANGED (+createMockDeliverableCollection)
  domain/ports/
    file-categorization-audit.port.ts                               NEW
  domain/projections/                                               NEW  (sanctioned home for shared projections,
                                                                          check-domain-type-structure.ts:140,159;
                                                                          precedent src/proceeding-job-submission/domain/projections/)
    categorization-audit-file.projection.ts                         NEW
    deliverable-categorization.projection.ts                        NEW
    file-attachment-categorization.projection.ts                    NEW
    file-categorization-audit-event.projection.ts                   NEW
  domain/services/
    recategorize-deliverable-files-service/recategorize-deliverable-files.service.ts          CHANGED
    approve-deliverable-files-service/approve-deliverable-files.service.ts                    CHANGED
    approve-deliverable-files-v2-service/approve-deliverable-files-v2.service.ts              CHANGED
    deliverable-upload-service/deliverable-upload.service.ts                                  CHANGED
    unapprove-deliverable-files-service/unapprove-deliverable-files.service.ts                CHANGED
  domain/transaction-scripts/
    dispatch-file-categorization-audit-ts/                          NEW
      dispatch-file-categorization-audit.transaction.script.ts      NEW
      dispatch-file-categorization-audit.param.ts                   NEW  (consumer = the TS in the same folder,
                                                                          check-domain-type-structure.ts:51-91)
      __specs__/dispatch-file-categorization-audit.transaction.script.spec.ts                 NEW
      file-categorization-audit-assembler/
        file-categorization-audit.assembler.ts                      NEW
        is-categorization-audit-due.predicate.ts                    NEW
        __specs__/file-categorization-audit.assembler.spec.ts       NEW
        __specs__/is-categorization-audit-due.predicate.spec.ts     NEW
    recategorize-deliverable-files-ts/
      recategorize-deliverable-files.projection.ts                  NEW
      recategorize-deliverable-files-projection.converter.ts        NEW
      __specs__/recategorize-deliverable-files-projection.converter.spec.ts                   NEW
      recategorize-deliverable-files-data.projection.ts             CHANGED
      recategorize-batch-files.converter.ts                         CHANGED
      recategorize-deliverable-files.transaction.script.ts          CHANGED
      recategorize-deliverable-files-ts.provider.ts                 CHANGED (+projection converter)
    approve-deliverable-files-ts/
      approve-deliverable-file-plan.projection.ts                   NEW  (TS-local plan type moved out, TS :59-64)
      approve-deliverable-files.projection.ts                       CHANGED
      approve-deliverable-files-projection.converter.ts             CHANGED
      approve-deliverable-files.transaction.script.ts               CHANGED
    upload-complete-deliverable-file-ts/
      upload-complete-deliverable-file.projection.ts                CHANGED (type only)
    unapprove-deliverable-files-ts/
      unapprove-deliverable-files.projection.ts                     CHANGED
      unapprove-deliverable-files.transaction.script.ts             CHANGED
  infrastructure/repositories/
    deliverable-type.repository.ts                                  CHANGED (+findByIds)
    deliverable-collection.repository.ts                            CHANGED (+findByIds)
    file-attachment.repository.ts                                   CHANGED (+findCategorizationsByIds)
    __specs__/file-attachment.repository.spec.ts                    NEW
  registries/transaction-script.registry.ts                         CHANGED (+dispatch TS, assembler, predicate, recategorize projection converter)
src/proceedings/infrastructure/repositories/file-attachment.repository.ts   CHANGED (select +2 columns)
```

### 2. New / changed classes

| Class | Path | Change |
| --- | --- | --- |
| `DispatchFileCategorizationAuditTS` (new) | `gca/domain/transaction-scripts/dispatch-file-categorization-audit-ts/dispatch-file-categorization-audit.transaction.script.ts` | Injects `FileCategorizationAuditAssembler`, `@Inject(FILE_CATEGORIZATION_AUDIT_PORT) FileCategorizationAuditPort` and `@InjectLogger(DispatchFileCategorizationAuditTS.name)`. `apply({ entries, user }): Promise<void>`: returns at once for no entries; a private `assembleEvents` calls the assembler, logs `error` and yields `[]` if it rejects; a private `dispatchEvent` per event, run with `Promise.all`, calls `dispatchFileAuditCategorizedEvent` and logs `warn` with `fileId` on `false` or a throw. Never rejects. |
| `FileCategorizationAuditAssembler` (new) | `gca/domain/transaction-scripts/dispatch-file-categorization-audit-ts/file-categorization-audit-assembler/file-categorization-audit.assembler.ts` | Injects `DeliverableTypeRepository`, `DeliverableCollectionRepository`, `IsCategorizationAuditDuePredicate` and a logger. `apply({ entries, user }): Promise<FileCategorizationAuditEventProjection[]>` works in five steps. **(1)** It keeps the entries the predicate accepts. **(2)** It returns `[]` without querying when nothing is left. **(3)** It collects the distinct non-null type and collection ids from the kept entries' post-write ids; `previous` is not looked up. **(4)** It makes one `findByIds` call per repository, in `Promise.all`. **(5)** It maps each id to `.value` for the event's `categorization`: a null id gives `null`, and an id that doesn't resolve gives `null`, with one `logger.warn` per repository kind listing the unresolved ids. `file` and `user` pass through by reference. Both FKs are `ON DELETE SET NULL` (see §5–6), so a current id can fail to resolve only through a concurrent delete. Repository errors propagate to the dispatch TS. |
| `IsCategorizationAuditDuePredicate` (new) | `…/file-categorization-audit-assembler/is-categorization-audit-due.predicate.ts` | `apply(entry: FileCategorizationAuditEntry): boolean`: true when the entry's type or collection is non-null, or `previous` is non-null with a non-null type or collection (the LD-009 gate above). |
| `FileCategorizationAuditPort` / `FILE_CATEGORIZATION_AUDIT_PORT` (new) | `gca/domain/ports/file-categorization-audit.port.ts` | `dispatchFileAuditCategorizedEvent(event: FileCategorizationAuditEventProjection): Promise<boolean>`; resolves `false` when the event was not accepted for delivery. Implemented by `ProceedingFileAuditAggregator` through the module binding. |
| `RecategorizeDeliverableFilesProjectionConverter` (new) | `…/recategorize-deliverable-files-ts/recategorize-deliverable-files-projection.converter.ts` | `apply({ processedBatchFiles, deliverableCollectionId }): RecategorizeDeliverableFilesProjection`. Returns `processedFileIds` (`Number(file.id)`, as before) and, per file, `{ file: { id, fileName, filePath, bucket }, deliverableTypeId: requestedDeliverableTypeId, deliverableCollectionId }`, casting to the branded ids. |
| `DeliverableTypeRepository` | `gca/infrastructure/repositories/deliverable-type.repository.ts` | Adds `findByIds(ids: readonly DeliverableTypeId[]): Promise<DeliverableType[]>`: `ids.length === 0 → []` with no query, else `this.repo.find({ where: { id: In([...ids]) } })`. `In` joins the import at `:3`. It sits next to `findById` (`:40-42`). |
| `DeliverableCollectionRepository` | `gca/infrastructure/repositories/deliverable-collection.repository.ts` | Adds `findByIds(ids: readonly DeliverableCollectionId[]): Promise<DeliverableCollection[]>`, with the same guard and `In`. It sits next to `findById` (`:36-40`). `In` joins the import at `:3`. |
| `FileAttachmentRepository` (GCA) | `gca/infrastructure/repositories/file-attachment.repository.ts` | Adds `findCategorizationsByIds(fileAttachmentIds: FileAttachmentId[]): Promise<Map<FileAttachmentId, FileAttachmentCategorizationProjection>>`. It mirrors `findProceedingIdsByIds` (`:78-97`): an empty-guard, then `find({ where: { id: In(ids) }, select: ['id', 'deliverableTypeId', 'deliverableCollectionId'] })`. Only the unapprove write uses it, and it must run before that write clears the columns, in the same transaction. |
| `FileAttachmentRepository` (proceedings) | `src/proceedings/infrastructure/repositories/file-attachment.repository.ts` | `fetchFilesByProceedingId` select (`:76-88`) adds `'file.filePath'`, `'file.bucket'`. Callers are listed below. |
| `RecategorizeBatchFilesConverter` | `…/recategorize-deliverable-files-ts/recategorize-batch-files.converter.ts` | The mapped object (`:29-39`) adds `filePath: file.filePath, bucket: file.bucket`. |
| `RecategorizeDeliverableFilesTS` | `…/recategorize-deliverable-files-ts/recategorize-deliverable-files.transaction.script.ts` | New constructor dependency `RecategorizeDeliverableFilesProjectionConverter` (last argument; `recategorize-deliverable-files-ts.provider.ts` passes and injects it). The return type changes from `{ processedFileIds }` (`:50`) to `RecategorizeDeliverableFilesProjection`. The local `processedFiles` (`:127-129`) is renamed `processedBatchFiles`, and at `:146-148` the TS returns `converter.apply({ processedBatchFiles, deliverableCollectionId: resolvedDeliverableCollectionId })`. The outbox block (`:130-145`) is unchanged. |
| `ApproveDeliverableFilesProjectionConverter` | `…/approve-deliverable-files-ts/approve-deliverable-files-projection.converter.ts` | The signature changes from `apply(fetchedFiles, decisions)` (`:10-13`) to `apply({ plans, decisions })`. Output: `processedFiles/processedFileIds/skippedFileIds` keep the same values in the same order (`plans[i].file` = `fetchedFiles[i]`, TS `:140`), plus `processedFileCategorizations`, built for `'processed'` rows only: `{ file: { id, fileName, filePath, bucket }, deliverableTypeId, deliverableCollectionId }`, with the plan's ids cast to the branded ids. |
| `ApproveDeliverableFilesTS` | `…/approve-deliverable-files-ts/approve-deliverable-files.transaction.script.ts` | Replace the local `ApproveDeliverableFilePlan` (`:59-64`) with an import of `ApproveDeliverableFilePlanProjection`, used for `plans` and in `EmitApprovedEventsInput` (`:66-72`). The converter call at `:175-179` passes `{ plans, decisions }`. The `findFileAttachmentIdsByTag` read (`:127-133`) is unchanged, and the TS reads no prior categorization. No new constructor dependency. |
| `UnapproveDeliverableFilesTS` | `…/unapprove-deliverable-files-ts/unapprove-deliverable-files.transaction.script.ts` | Adds `this.fileAttachmentRepository.findCategorizationsByIds(fileAttachmentIds)` to the `Promise.all` at `:77-95`. It is **unconditional** (not flag-gated) and completes before the `processFile` clears at `:96-105`/`:152-159`. `toProjection` (`:204-224`) takes `{ fetchedFiles, decisions, categorizationByAttachmentId }` and adds `processedFileCategorizations` for processed files, each `{ file: { id, fileName, filePath, bucket }, previousDeliverableTypeId, previousDeliverableCollectionId }`. A missing key gives `null, null`. No new constructor dependency: the repo is already injected at `:39`. |
| `RecategorizeDeliverableFilesService` | `…/recategorize-deliverable-files.service.ts` | Adds `DispatchFileCategorizationAuditTS`. It captures the TS result instead of returning it (`:36-43`), calls `dispatchFileCategorizationAuditTS.apply({ entries: this.toCategorizationAuditEntries(result), user: command.user })`, and returns `{ processedFileIds: result.processedFileIds }`. |
| `ApproveDeliverableFilesService` | `…/approve-deliverable-files.service.ts` | Adds `DispatchFileCategorizationAuditTS`. It calls it after the APPROVED block (`:62-68`) and before `return` (`:69`). |
| `ApproveDeliverableFilesV2Service` | `…/approve-deliverable-files-v2.service.ts` | Same, after `:140-146` and before `return` (`:147`). |
| `DeliverableUploadService` | `…/deliverable-upload.service.ts` | Adds `DispatchFileCategorizationAuditTS`. It calls it after CREATED (`:112-115`) and before `return file` (`:116`). The returned object is unchanged. |
| `UnapproveDeliverableFilesService` | `…/unapprove-deliverable-files.service.ts` | Adds `DispatchFileCategorizationAuditTS`. It calls it after UNAPPROVED (`:45-51`) and before `return` (`:52`). |

**Per-service entries.** Each service gets a private `toCategorizationAuditEntries(result): readonly FileCategorizationAuditEntry[]`; the TS projections already carry plain `CategorizationAuditFileProjection` files and branded ids:

| Path | `entries` |
| --- | --- |
| Recategorize | `result.processedFiles.map(f => ({ file: f.file, deliverableTypeId: f.deliverableTypeId, deliverableCollectionId: f.deliverableCollectionId, previous: null }))` |
| Approve v1 / v2 | `result.processedFileCategorizations.map(c => ({ file: c.file, deliverableTypeId: c.deliverableTypeId, deliverableCollectionId: c.deliverableCollectionId, previous: null }))` |
| Upload | `[{ file: { id: file.id as FileId, fileName, filePath, bucket }, deliverableTypeId: file.fileAttachment.deliverableTypeId as DeliverableTypeId \| null, deliverableCollectionId: file.fileAttachment.deliverableCollectionId as DeliverableCollectionId \| null, previous: null }]`. The upload projection carries plain numbers, so the branded types are applied here. |
| Unapprove | `result.processedFileCategorizations.map(c => ({ file: c.file, deliverableTypeId: null, deliverableCollectionId: null, previous: { deliverableTypeId: c.previousDeliverableTypeId, deliverableCollectionId: c.previousDeliverableCollectionId } }))` |

**Callers of the shared `fetchFilesByProceedingId`.** None is affected by the two extra selected columns:

| Caller | Why unaffected |
| --- | --- |
| `FetchFilesByProceedingIdTS` (`src/proceedings/domain/transaction-scripts/fetch-files-by-proceeding-id-ts/fetch-files-by-proceeding-id.transaction.script.ts:42`). It backs the GET files listing and, through `ProceedingAggregator.fetchFilesByProceedingId` (`proceeding.aggregator.ts:111-118`), the job-submission files endpoint (`job-submission.service.ts:269-274`) | The output is built field by field in `FileAttachmentToProceedingFilesProjectionConverter` (`…/file-attachment-to-proceeding-files-projection.converter.ts:20-31`), so `filePath`/`bucket` never reach a response |
| `ApproveFilesForDeliveryTS` (legacy, `src/proceedings/domain/transaction-scripts/approve-files-for-delivery-ts/approve-files-for-delivery-transaction.script.ts:54`) | Reads only `trackType.id`, `file.id`, `file.fileName` (`:135-153`) |
| `ApproveDeliverableFilesDataAssembler` (`…/approve-deliverable-files-data.assembler.ts:37`) | `toExistingDeliverableScopes` copies only `trackType.id`, `deliverableCollectionId`, `file.id`, `fileName` (`:84-104`) |
| `RecategorizeDeliverableFilesDataAssembler` (`…/recategorize-deliverable-files-data.assembler.ts:31`) | The intended consumer. `ExistingDeliverableScopesConverter` maps field by field (`existing-deliverable-scopes.converter.ts:15-32`) |

The only cost is two extra `varchar` columns per row on the listing query. The `src/typeorm/dev-dataset-usecases/verify__ajsf_transcoded_video_files.sql:15` "mirrors" comment describes the WHERE shape, not the select list, so it needs no change.

### 3–4. Entities

N/A. This part adds no entity and changes none. It only reads existing columns:

- `FileAttachment.deliverableCollectionId` and `deliverableTypeId` (`src/shared/shared-entities/entities/files/file-attachment/file-attachment.entity.ts:42-54`)
- `File.filePath` and `bucket` (`file.entity.ts:39-43`)
- `DeliverableType.value` (`src/granting-client-access/domain/entities/deliverable-type.entity.ts:27-28`)
- `DeliverableCollection.value` (`deliverable-collection.entity.ts:43-44`)

### 5–6. Migrations

N/A. The existing FKs make every current id resolvable once the write has committed:

- `deliverable_type_id → deliverable_types ON DELETE SET NULL` (`src/typeorm/migrations/1781121204473-alter__add_deliverable_type_id__file_attachments_table.ts:16-17`)
- `deliverable_collection_id → deliverable_collections ON DELETE SET NULL` (`1775761245349-alter__add_deliverable_collection_id__file_attachments_table.ts:16-17`)

### 7. DTOs

No change to any request or response DTO, and no change to any `*.action.swagger.ts`.

| Endpoint | Request DTO | Response | Why unchanged |
| --- | --- | --- | --- |
| Recategorize | `…/recategorize-deliverable-files-action/recategorize-deliverable-files.request.dto.ts` | `recategorize-deliverable-files.response.dto.ts:1-10` `{ processedFileIds }` | The action picks `processedFileIds` explicitly (`recategorize-deliverable-files.action.ts:38-40`), and the service return type stays `{ processedFileIds: number[] }` (the service strips `processedFiles`) |
| Approve v1 / v2 | `approve-files-for-delivery.request.dto.ts` | Built in the action from counts (`approve-files-for-delivery.action.ts:33-38`; `approve-files-for-delivery-v2.action.ts:35-40`) | The services still return `ApproveDeliverableFilesResultProjection` `{processedFileIds, skippedFileIds}` (v1 `:69-72`, v2 `:147-150`) |
| Unapprove | `unapprove-files-for-delivery.request.dto.ts` | Built in the action from counts (`unapprove-files-for-delivery.action.ts:31-36`) | The service still returns `{processedFileIds, skippedFileIds}` (`:52-55`) |
| Upload-complete | `upload-complete-deliverable-file.request.dto.ts` | `upload-complete-deliverable-file.response.dto.ts:43-79` | The action returns the service value verbatim (`upload-complete-deliverable-file.action.ts:27`), and there is no global serializer (no `ClassSerializerInterceptor`/`APP_INTERCEPTOR` in `src/`). So the runtime body **already** contains `fileAttachment.deliverableTypeId/deliverableCollectionId`: the mapper spreads the saved attachment (`create-deliverable-file.mapper.ts:44-50`). Widening the projection type changes compile time only. `DeliverableFileAttachmentDTO` (`:11-41`) stays as it is. |

### 8. Params / projections

GCA-owned types. None imports a `pfa/` type; the ids are branded (`FileId`, `DeliverableTypeId`, `DeliverableCollectionId`).

```ts
// NEW gca/domain/projections/categorization-audit-file.projection.ts
// The file fields a CATEGORIZE record names, as plain data (never a TypeORM entity).
export type CategorizationAuditFileProjection = {
	readonly id: FileId;
	readonly fileName: string;
	readonly filePath: string;
	readonly bucket: string;
};

// NEW gca/domain/projections/deliverable-categorization.projection.ts
export type DeliverableCategorizationProjection = {
	readonly deliverableTypeId: DeliverableTypeId | null;
	readonly deliverableCollectionId: DeliverableCollectionId | null;
};

// NEW gca/domain/projections/file-attachment-categorization.projection.ts
export type FileAttachmentCategorizationProjection = Pick<
	FileAttachment,
	'deliverableTypeId' | 'deliverableCollectionId'
>;

// NEW gca/domain/projections/file-categorization-audit-event.projection.ts
export type FileCategorizationAuditNamesProjection = {
	readonly deliverableTypeName: string | null;
	readonly collectionName: string | null;
};

export type FileCategorizationAuditEventProjection = {
	readonly file: CategorizationAuditFileProjection;
	readonly user: Partial<AuthUser>;
	readonly categorization: FileCategorizationAuditNamesProjection;
};
```

`FileCategorizationAuditEventProjection` is structurally assignable to Part A's `ProceedingFileAuditCategorizedParams`, which is what lets the port bind to the aggregator.

```ts
// NEW gca/domain/transaction-scripts/dispatch-file-categorization-audit-ts/dispatch-file-categorization-audit.param.ts
/**
 * One file a committed write touched: its categorization after the write and,
 * in `previous`, before it. `previous` is only read to decide whether a record
 * is due (an unapprove that cleared a categorization); it is null when the
 * caller has no prior categorization to report.
 */
export type FileCategorizationAuditEntry =
	DeliverableCategorizationProjection & {
		readonly file: CategorizationAuditFileProjection;
		readonly previous: DeliverableCategorizationProjection | null;
	};

export type DispatchFileCategorizationAuditParams = {
	readonly entries: readonly FileCategorizationAuditEntry[];
	readonly user: AuthUser;
};
```

```ts
// CHANGED recategorize-deliverable-files-data.projection.ts (:5-13)
export type RecategorizeBatchFileProjection = {
	readonly id: FileId;
	readonly fileAttachmentId: FileAttachmentId;
	readonly fileName: string;
	readonly filePath: string; // NEW
	readonly bucket: string; // NEW
	readonly currentTrackTypeId: number;
	readonly currentDeliverableCollectionId: number | null;
	readonly currentDeliverableTypeId: number | null;
	readonly requestedDeliverableTypeId: number;
};

// NEW recategorize-deliverable-files-ts/recategorize-deliverable-files.projection.ts
export type RecategorizedFileProjection = {
	readonly file: CategorizationAuditFileProjection;
	readonly deliverableTypeId: DeliverableTypeId;
	readonly deliverableCollectionId: DeliverableCollectionId | null;
};

export type RecategorizeDeliverableFilesProjection = {
	readonly processedFileIds: number[];
	readonly processedFiles: readonly RecategorizedFileProjection[];
};

// NEW recategorize-deliverable-files-projection.converter.ts (input)
export type RecategorizeDeliverableFilesProjectionInput = {
	readonly processedBatchFiles: readonly RecategorizeBatchFileProjection[];
	/** The destination collection every processed file moved into. */
	readonly deliverableCollectionId: number | null;
};
```

```ts
// NEW approve-deliverable-files-ts/approve-deliverable-file-plan.projection.ts (moved from TS :59-64, unchanged fields)
export type ApproveDeliverableFilePlanProjection = {
	readonly file: File;
	readonly fileInput: ApproveDeliverableFileInput | undefined;
	readonly deliverableCollectionId: number | null;
	readonly deliverableTypeId: number | null;
};

// CHANGED approve-deliverable-files.projection.ts
export type ApprovedFileCategorizationProjection =
	DeliverableCategorizationProjection & {
		readonly file: CategorizationAuditFileProjection;
	};

export type ApproveDeliverableFilesProjection =
	ApproveDeliverableFilesResultProjection & {
		processedFiles: File[]; // unchanged; still feeds APPROVED
		processedFileCategorizations: readonly ApprovedFileCategorizationProjection[]; // NEW, 'processed' rows only
	};

// CHANGED approve-deliverable-files-projection.converter.ts (input)
export type ApproveDeliverableFilesProjectionInput = {
	readonly plans: readonly ApproveDeliverableFilePlanProjection[];
	readonly decisions: readonly ApproveDeliverableFileDecision[];
};
```

```ts
// CHANGED upload-complete-deliverable-file.projection.ts (:5-11), type-only
type DeliverableFileAttachmentProjection = {
	id: number;
	trackType: DeliverableFileAttachmentTrackTypeProjection;
	trackTypeId: number;
	attachedToType: 'Proceeding';
	attachedToId: number;
	deliverableTypeId: number | null; // NEW (already present at runtime)
	deliverableCollectionId: number | null; // NEW (already present at runtime)
};
```

```ts
// CHANGED unapprove-deliverable-files.projection.ts
export type UnapprovedFileCategorizationProjection = {
	readonly file: CategorizationAuditFileProjection;
	readonly previousDeliverableTypeId: DeliverableTypeId | null;
	readonly previousDeliverableCollectionId: DeliverableCollectionId | null;
};

export type UnapproveDeliverableFilesProjection =
	UnapproveDeliverableFilesResultProjection & {
		processedFiles: File[]; // unchanged; still feeds UNAPPROVED + outbox
		processedFileCategorizations: readonly UnapprovedFileCategorizationProjection[]; // NEW
	};
```

### Module wiring

- **`transactionScriptRegistry`** (`gca/registries/transaction-script.registry.ts`):
  - `DispatchFileCategorizationAuditTS`, `FileCategorizationAuditAssembler` and `IsCategorizationAuditDuePredicate` sit next to `ResolveEffectiveDeliverableCollectionAssembler` (`:117`). They are plain providers: they only read after the commit, so they need no transactional proxy.
  - `RecategorizeDeliverableFilesProjectionConverter` sits next to `ExistingDeliverableScopesConverter`.
- **`recategorizeDeliverableFilesTSProvider`** (`recategorize-deliverable-files-ts.provider.ts`): passes `RecategorizeDeliverableFilesProjectionConverter` as the TS's last constructor argument and adds it to `inject`. No other TS provider factory changes. Unapprove reuses the injected GCA `FileAttachmentRepository`.
- **Port binding** (`gca/granting-client-access.module.ts` providers): `{ provide: FILE_CATEGORIZATION_AUDIT_PORT, useExisting: ProceedingFileAuditAggregator }`. `ProceedingFileAuditAggregator` is exported by `ProceedingsModule` (`src/proceedings/proceedings.module.ts:212`), which the GCA module already imports.
- **Assembler dependencies:**
  - `DeliverableTypeRepository` is exported by `DeliverableTypeLookupModule` (`deliverable-type-lookup.module.ts:27`), which `GrantingClientAccessModule` already imports (`granting-client-access.module.ts:100`).
  - `DeliverableCollectionRepository` is in `repositoryRegistry` (`repository.registry.ts:16`), spread at `granting-client-access.module.ts:140`.
  - `DeliverableTypeLookupPort` is not extended; the assembler injects the concrete repository, as `validate-deliverable-type-matches-collection.validator.ts` does.
- **Logger:** `@InjectLogger` on the dispatch TS and the assembler needs no wiring. `ObservabilityModule.forRootAsync` provides it (`src/config/observability.config.ts`).
- **Services:** each of the five adds only `DispatchFileCategorizationAuditTS`; none adds the aggregator, the assembler or a logger for this change.

### Spec tests

Test criteria:
- **C1:** every categorization is logged.
- **C5:** a missing collection renders N/A.
- **C7:** one record per file, including files that share an attachment.
- **C8:** a cleared categorization is logged.
- **Neg:** no dispatch.

"ids" below means the entry's `deliverableTypeId`/`deliverableCollectionId`. The service specs mock `DispatchFileCategorizationAuditTS` and assert the entries it receives. Every degradation path is asserted once, in the dispatch TS spec.

**Red → green first.** Start with the recategorize service spec, which today has no audit dispatch. Its existing identity assertion (`expect(actual).toBe(expectedProjection)`) becomes `toEqual({ processedFileIds })`, because the service no longer passes the TS object through.

| Spec path | Cases |
| --- | --- |
| `gca/domain/services/recategorize-deliverable-files-service/__specs__/recategorize-deliverable-files.service.spec.ts` (extend) | **C1 (red→green):** a TS with 2 processed files → the dispatch TS gets 2 entries, each with the TS's type and collection and `previous: null`, after the write. The response is exactly `{ processedFileIds }`. **C7:** 2 processed files sharing one attachment → 2 entries. **C5:** a null destination collection passes through as `null`. No processed files → `entries: []`, no ids. **Neg:** the input-mode validator throws, the data assembler rejects, or the TS rejects (rollback) → no dispatch-TS call. |
| `…/approve-deliverable-files-service/__specs__/approve-deliverable-files.service.spec.ts` (extend) | **C1:** one entry per `processedFileCategorizations` item, with `previous: null`. The dispatch TS is called only after every APPROVED event. All skipped → `entries: []`. **Neg:** the TS rejects → no CATEGORIZE. **Neighbor:** APPROVED is still dispatched `processedFiles.length` times with `{ file, user }`. |
| `…/approve-deliverable-files-v2-service/__specs__/approve-deliverable-files-v2.service.spec.ts` (extend) | The same as v1. Also: for a pending dynamic name, the entry carries the TS-resolved collection id. **Neg:** the collection-required/type-required/type-matches validators throw → no CATEGORIZE. |
| `…/deliverable-upload-service/__specs__/deliverable-upload.service.spec.ts` (extend) | **C1:** a TS file with a categorization → one entry (`previous: null`) handed to the dispatch TS after CREATED; the returned value is still the TS object (`toBe`). **C5:** a null `deliverableCollectionId` passes through. A pending dynamic name → the resolved id. **Neg:** the TS rejects → neither CREATED nor CATEGORIZE. |
| `…/unapprove-deliverable-files-service/__specs__/unapprove-deliverable-files.service.spec.ts` (extend) | **C8:** each `processedFileCategorizations` item → `{ deliverableTypeId: null, deliverableCollectionId: null, previous: {prev ids} }`. All skipped → `entries: []`. **Neg:** the TS rejects → no CATEGORIZE. **Neighbor:** UNAPPROVED count and args unchanged, and CATEGORIZE runs after them. |
| `gca/domain/transaction-scripts/dispatch-file-categorization-audit-ts/__specs__/dispatch-file-categorization-audit.transaction.script.spec.ts` (new) | No entries → resolves without assembling or dispatching. One event per entry → the assembler runs once and each event is dispatched once through the port. **Graceful:** the assembler rejects → `logger.error` with the file ids and user id (a null error for a non-`Error`; the token `sub` when there is no identity), nothing dispatched, resolves. One dispatch rejects → `logger.warn` with its `fileId` and message (the stringified value for a non-`Error`); the others still go out; resolves. A dispatch resolves `false` → `logger.warn` with its `fileId`. The assembler drops every entry → no dispatch and no log. **Binding:** an aggregator mock is assignable to `FileCategorizationAuditPort` (type-check fails on drift). |
| `…/file-categorization-audit-assembler/__specs__/file-categorization-audit.assembler.spec.ts` (new) | Resolves names from one `findByIds` per repository, called with the post-write ids deduplicated (the `previous` ids are not queried), mapped onto `categorization`. `user` and `file` pass through by reference. The predicate is asked about every entry, and only kept entries are mapped. All dropped, or empty `entries` → `[]` with no repository call. A clear of a collection-only categorization → null names, and the previous collection id is not looked up. A null id → a null name, not queried. An unresolved id → a null name plus `logger.warn` listing it. A repository rejects → the assembler rejects. |
| `…/file-categorization-audit-assembler/__specs__/is-categorization-audit-due.predicate.spec.ts` (new) | **LD-009 gate:** type left on the file → true. Only a collection left → true. A clear of a prior type-only or collection-only categorization → true. Neither, with `previous: null` → false. Neither before or after → false. |
| `gca/infrastructure/repositories/__specs__/deliverable-type.repository.spec.ts`, `deliverable-collection.repository.spec.ts` (extend) | `findByIds` calls `find({ where: { id: In(ids) } })`. `[]` → returns `[]` with no `find` call. |
| `gca/infrastructure/repositories/__specs__/file-attachment.repository.spec.ts` (new; harness as in `deliverable-collection.repository.spec.ts:15-40`) | `findCategorizationsByIds`: `find` is called with `In` and the 3-column select, and the result maps to a `Map` keyed by attachment id. Attachments the query didn't return are absent. `[]` → an empty `Map`, no query. |
| `…/recategorize-deliverable-files-ts/__specs__/recategorize-deliverable-files-projection.converter.spec.ts` (new) | Files moved into a collection → ids plus, per file, the plain file fields with the new categorization. No destination collection → null. No files → empty lists. |
| `…/recategorize-deliverable-files-ts/__specs__/recategorize-deliverable-files.transaction.script.spec.ts` (extend; real projection converter as a provider) | `processedFiles` carries `deliverableTypeId = requested` and `deliverableCollectionId` = the request id / the found-or-created dynamic id / `null` (no destination collection). **C7:** 2 batch files on one attachment → one `setTrackCollectionAndType` call and 2 `processedFiles`. **Neg:** a validator throws → rejects, and `setTrackCollectionAndType` is not called. |
| `…/recategorize-deliverable-files-ts/__specs__/recategorize-batch-files.converter.spec.ts`, `recategorize-deliverable-files-data.assembler.spec.ts` (extend) | `filePath`/`bucket` are carried from the attachment files onto each batch projection row. |
| `…/approve-deliverable-files-ts/__specs__/approve-deliverable-files-projection.converter.spec.ts` (update to `apply({ plans, decisions })`) | `processedFiles/processedFileIds/skippedFileIds` are identical to today for the same inputs. `processedFileCategorizations` covers processed rows only, carrying the plan's ids (null ids included). No plans → empty collections. |
| `…/approve-deliverable-files-ts/__specs__/approve-deliverable-files.transaction.script.spec.ts` (extend) | For both flag values: `findCategorizationsByIds` is not called, even when the attachments carry a categorization. `processedFileCategorizations` carries the plain file fields and the plan's type and collection for processed files only (an already-tagged file is skipped), including per-file collection ids and the id resolved for a pending dynamic name. |
| `…/unapprove-deliverable-files-ts/__specs__/unapprove-deliverable-files.transaction.script.spec.ts` (extend) | For both flag values: `findCategorizationsByIds` is called with the attachment ids **before** `setDeliverableTypeId`/`setDeliverableCollectionId` (`mock.invocationCallOrder`). `processedFileCategorizations` carries the prior ids for processed files only, and null prior ids when the attachment has no row. **Neg:** the digital-files validator rejects → `findCategorizationsByIds` is not called. |
| `…/upload-complete-deliverable-file-ts/__specs__/upload-complete-deliverable-file.transaction.script.spec.ts` (extend) | The returned `fileAttachment` carries the requested `deliverableTypeId` (or `null` when omitted) and the resolved dynamic `deliverableCollectionId`. |
| `src/proceedings/…/file-attachments-to-proceeding-files-by-track-type-assembler/__specs__/file-attachment-to-proceeding-files-projection.converter.spec.ts` (extend; neighbor) | An input `File` with `filePath`/`bucket` → neither key reaches the projection. |

### Neighbors that must not change

- **APPROVED:** v1 `approve-deliverable-files.service.ts:62-68` and v2 `approve-deliverable-files-v2.service.ts:140-146`. Still one event per `processedFiles` entry with `{ file, user }`, and still dispatched before CATEGORIZE.
- **UNAPPROVED:** `unapprove-deliverable-files.service.ts:45-51`. Same count and shape.
- **CREATED:** `deliverable-upload.service.ts:112-115`. Same `{ file, user }` object; only the type is widened.
- **Legacy approve:** the `proceedings` `ApproveFilesForDeliveryTS` still dispatches APPROVED inside its TS (`:104-109`) and emits no CATEGORIZE (LD-009).
- **Dione outbox payloads:** unchanged.
  - Recategorize `emitRecategorizedEvents` input is still built from `fileId/fileAttachmentId/requestedDeliverableTypeId` (TS `:131-144`).
  - Approve `emitApprovedEvents` still reads `plan.file/trackTypeId/deliverableCollectionId/deliverableTypeId` (TS `:309-342`); the plan type only moves files.
  - Unapprove `emitUnapprovedEvents` still reads `processedFiles` (TS `:170-202`).
  - Upload `writeFileCreatedEvents` is unchanged (TS `:91-103`).
  - The converter specs `file-recategorized-to-outbox-data.converter.spec.ts`, `file-approved-to-outbox-data.converter.spec.ts` and `file-unapproved-to-outbox-data.converter.spec.ts`, and the existing TS assertions on `clientAccessOutbox.*` arguments, stay green without edits.
- **Response bodies:** all five are unchanged (see §7).
- **GET files listing and job-submission files listing:** unchanged (see the caller table in §2, and the converter neighbor spec above).

### Notes

- **v1 approve and the type:** the v1 request DTO documents `deliverableTypeId` as "ignored" on v1 (`approve-files-for-delivery.request.dto.ts:38-46`), but the TS writes it (`approve-deliverable-files.transaction.script.ts:152`, `:369-372`). This design follows the code: v1 emits whenever it sets a type or a collection. The doc mismatch is recorded as a concern, not fixed here.
- **Unapprove of a never-categorized file:** it produces no CATEGORIZE. This can happen because legacy `ApproveFilesForDeliveryTS` tags files without setting a type (`approve-files-for-delivery-transaction.script.ts:99-102`).

---

## Part D — Atlas (Europa audit page) and Europa confirmation

Baselines: `atlas-front-end` `main` @ `ad059eec` (`src/europa/` is identical to `26eaa0bb`); `europa-back-end` `main` @ `1082fdad`. Paths below are relative to each repo root.

### Europa — unchanged (evidence table)

LD-007 holds. Europa needs no code change to store, filter, or return a `CATEGORIZE` / `FILE` event.

| # | Concern | Evidence (europa-back-end) | Result for `CATEGORIZE` |
| - | ------- | -------------------------- | ----------------------- |
| E1 | Type allow-list | `src/audits-event/constants.ts:3-7`. `AUDIT_EVENT_TYPE` = `CREATED`, `LOGIN`, `LOGOUT` only. Only two non-spec files use it (plus their `__specs__`): `create-login-event-params-to-audit-event.converter.ts:24` and `create-logout-event-params-to-audit-event.converter.ts:24`, and they use it to *emit* events, not to validate them | Not an enum gate. An unlisted literal is accepted |
| E2 | Ingest | `src/audits-event/application/listeners/sqs-audit-event.listener.ts:21-26`. `JSON.parse(message.Body)` → `auditEventService.create(messageBody)`, with no type check | Stored as sent |
| E3 | Persistence | `src/audits-event/domain/entities/audit-event/audit-event.entity.ts:14-15`. `@Prop({ required: true }) type: string` (no `enum`). The `audit_type_date` index at `:53` covers type + date filtering | Stored as a free string |
| E4 | Filter DTO | `src/audits-event/application/actions/search-audits-paginated/search-audit-events-paginated.request.dto.ts:55-58`. `type` is `@IsOptional() @IsString()` with **no** `@IsIn`. For contrast, `sortBy` `:41` and `sortDirection` `:47` do use `@IsIn` | `type=CATEGORIZE` passes validation |
| E5 | Filter query | `.../converters/search-params-to-mongo-query.converter.ts:38-40` `{ type: params.type }`, a case-sensitive Mongo equality match. `:42-46` `resourceType` is also an exact match on `auditEventResources.resourceType` | Only an exact `CATEGORIZE` matches. That is why the Atlas literal must equal Callisto's byte for byte |
| E6 | `path` projection | `.../search-audit-events-paginated.transaction.script.ts:13` `const PERMISSIONS_UPDATED`. The special case at `:62-73` rebuilds `path` as `<resourcePath>: <old> → <new>` joined by `' \| '`. For every other type, `:74-80` returns `firstResource?.newState?.path ?? oldState?.path ?? resourcePath ?? ''`, where `firstResource` = `auditEventResources[0]` (`:57`) | `newState.path` passes through verbatim. **Only the first resource is shown**, so Callisto's "one event per file" is load-bearing |

### Atlas design

**Problem.** Ops can't see deliverable-type categorizations in the Europa audit page. The Event Type filter doesn't offer `CATEGORIZE` (baseline `src/europa/utils/constants.ts:3-15`). Even when the event arrives, its three-part `path` renders as one long raw line, because the multi-line render is gated on the single literal `'PERMISSIONS_UPDATED'` (baseline `src/europa/pages/HomePage/SearchDataGrid/SearchDataGrid.vue:311`).

**Requirement.** Three things must hold:
- `CATEGORIZE` must be selectable in the Event Type filter and must display raw (LD-010).
- Its `path` must render as three lines in Callisto's order, with bold labels.
- `PERMISSIONS_UPDATED` and all other types must render exactly as they do today.

**Solution.**
- `constants.ts` appends `'CATEGORIZE'` to `eventTypes`, adds `CATEGORIZE: 'info'` to `eventTypeColors`, and adds a `MULTI_PART_PATH_TYPES` set of `'PERMISSIONS_UPDATED'` and `'CATEGORIZE'`.
- `SearchDataGrid.vue` gates the existing multi-line path markup on `MULTI_PART_PATH_TYPES.has(cellProps.row.type)` instead of `=== 'PERMISSIONS_UPDATED'`.

Traced facts behind the design:

- The Event Type dropdown is bound directly to `eventTypes` (`SearchFilters.vue:248-262`, `:options="eventTypes"` at `:251`).
- The selected value flows unchanged through the following steps. Nothing in Atlas whitelists `type`. The existing `useAuditSearch.spec.ts:210-213` already sets an arbitrary `type: 'DOWNLOAD'` and passes.
  1. `HomePage.vue:31-47`
  2. `useAuditSearch.ts:186-196` (`setFilters`)
  3. `useAuditSearch.ts:73` (URL read, no whitelist)
  4. `fetchAuditEvents.ts:26-28` (`params.append('type', …)`)
- The Resource Type filter already offers `FILE` (`constants.ts:18`). That equals Callisto's `AuditEventResourceType.FILE` (`callisto-back-end/src/audits/constants.ts:4`).
- The type chip renders the raw value (`SearchDataGrid.vue:294-300`, `{{ cellProps.value }}` at `:299`). Its colour comes from `getEventTypeColor` (`:149-151`), which falls back to `'grey'`.
- The path column has no `format` function (`auditEventColumns.ts:43-48`), so the slot's `cellProps.value` is the raw `row.path`.
- Path-cell render (`SearchDataGrid.vue:312-327`): `value.split(' | ')` produces one `<div>` per segment (`:317`). Each segment renders as `<strong>{{ part.split(': ')[0] }}</strong>: {{ part.split(': ').slice(1).join(': ') }}` (`:319-320`). The label is the text before the **first** `': '`, and the remainder is re-joined, so a `': '` inside the S3 key is preserved. `q-table` has no `wrap-cells`, so each line stays on one row.

**Colour for `CATEGORIZE`: `info`.** Based on the existing map (`constants.ts:20-32`). There is no documented colour convention:
- `info` marks events that change where a file sits or who can reach it without touching its content or name: `MOVED` (`:24`), `PERMISSIONS_UPDATED` (`:30`).
- Categorizing assigns a file to a deliverable type and collection without changing its bytes or name, so it belongs in the same family.

Rejected alternatives:
- `positive`: used for create/approve lifecycle (`CREATED`, `MERGED`, `APPROVED`).
- `warning`: used for content or name mutation (`UPDATED`, `RENAMED`).
- `negative`: used for removal or reversal.

**Placement.** `CATEGORIZE` is the last `eventTypes` entry (`constants.ts:15`), so it is the last Event Type option. `APPROVED` and `UNAPPROVED` (`:13-14`, added 2025-09-24) were appended after the alphabetical block, and this follows that precedent. The most recent addition on `main`, `PERMISSIONS_UPDATED` (`:10`, added 2026-06-30), went into alphabetical position instead, so the precedent is mixed. Appending was chosen so that every existing option keeps its position.

#### `src/europa/utils/constants.ts`

```ts
export const SERVICE_NAME = 'Atlas';

export const eventTypes = [
  'CREATED',
  'DELETED',
  'DOWNLOADED',
  'LOGIN',
  'MERGED',
  'MOVED',
  'PERMISSIONS_UPDATED',
  'RENAMED',
  'UPDATED',
  'APPROVED',
  'UNAPPROVED',
  'CATEGORIZE',
];

export const resourceTypes = ['FILE', 'FOLDER', 'PERMISSION', 'USER'];

export const eventTypeColors: Record<string, string> = {
  CREATED: 'positive',
  UPDATED: 'warning',
  DELETED: 'negative',
  MOVED: 'info',
  DOWNLOADED: 'primary',
  RENAMED: 'warning',
  MERGED: 'positive',
  APPROVED: 'positive',
  UNAPPROVED: 'negative',
  PERMISSIONS_UPDATED: 'info',
  CATEGORIZE: 'info',
};

export const MULTI_PART_PATH_TYPES: ReadonlySet<string> = new Set([
  'PERMISSIONS_UPDATED',
  'CATEGORIZE',
]);
```

- `eventTypes` keeps the eleven baseline values in baseline order and appends `CATEGORIZE` (`:15`). `eventTypeColors` keeps the baseline colours and adds `CATEGORIZE: 'info'` (`:31`).
- `resourceTypes` is unchanged.
- `MULTI_PART_PATH_TYPES` (`:34-37`) is the set of types whose `path` renders one segment per line.

#### `src/europa/pages/HomePage/SearchDataGrid/SearchDataGrid.vue`

```diff
@@ script (line 21)
-import { eventTypeColors } from '@europa/utils/constants';
+import {
+  eventTypeColors,
+  MULTI_PART_PATH_TYPES,
+} from '@europa/utils/constants';
@@ template (line 311)
       <template #body-cell-path="cellProps" v-if="!isLoading">
         <q-td :props="cellProps">
-          <template v-if="cellProps.row.type === 'PERMISSIONS_UPDATED'">
+          <template v-if="MULTI_PART_PATH_TYPES.has(cellProps.row.type)">
             <div
               :key="index"
               v-for="(part, index) in cellProps.value.split(' | ')"
             >
               <strong>{{ part.split(': ')[0] }}</strong
               >: {{ part.split(': ').slice(1).join(': ') }}
             </div>
           </template>
           <template v-else>
             {{ cellProps.value }}
           </template>
         </q-td>
       </template>
```

Notes on the diff:
- The path-cell markup is unchanged. Only the `v-if` gate changes, from the single `'PERMISSIONS_UPDATED'` literal to membership in `MULTI_PART_PATH_TYPES` (`SearchDataGrid.vue:314`). A `CATEGORIZE` row gets the same render as a `PERMISSIONS_UPDATED` row: one `<div>` per `' | '` segment, with the text before the first `': '` in bold.
- `PERMISSIONS_UPDATED` renders identically, edge cases included, because it is in the set and the markup is unchanged. Every type outside the set keeps the single raw line (`:323-325`).
- The import is split across lines because the one-line form is over Prettier's `printWidth: 80` (`.prettierrc`). Specifier order `eventTypeColors, MULTI_PART_PATH_TYPES` satisfies `importOrderSortSpecifiers` + `importOrderCaseInsensitive`.

Expected render for `Filepath: 5009/deliverables/depo.pdf | Deliverable Type: Transcript | Collection: N/A`:

```
**Filepath**: 5009/deliverables/depo.pdf
**Deliverable Type**: Transcript
**Collection**: N/A
```

### 1. Folder hierarchy (atlas-front-end/src/…)

```
src/europa/
├── utils/
│   ├── constants.ts                          (modified)
│   └── __specs__/
│       ├── formatDateForDisplay.spec.ts      (existing, unchanged)
│       └── constants.spec.ts                 (new)
└── pages/HomePage/SearchDataGrid/
    ├── SearchDataGrid.vue                    (modified)
    └── __specs__/                            (new folder)
        └── SearchDataGrid.spec.ts            (new)
```

### 2. Changed / new files

| File | Change |
| ---- | ------ |
| `src/europa/utils/constants.ts` | Appends `'CATEGORIZE'` to `eventTypes`. Adds `CATEGORIZE: 'info'` to `eventTypeColors`. Adds `MULTI_PART_PATH_TYPES` (`'PERMISSIONS_UPDATED'`, `'CATEGORIZE'`) |
| `src/europa/pages/HomePage/SearchDataGrid/SearchDataGrid.vue` | Imports `MULTI_PART_PATH_TYPES`. The path-cell multi-line branch is gated on `MULTI_PART_PATH_TYPES.has(cellProps.row.type)` |
| `src/europa/utils/__specs__/constants.spec.ts` | New unit spec |
| `src/europa/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts` | New component spec (path cell and type chip) |

No new classes, composables, or components. No `SearchFilters.vue`, `fetchAuditEvents.ts`, `useAuditSearch.ts` or `audit-event.types.ts` changes.

### 3–8. Entities, migrations, DTOs, projections — N/A (one line each, reason)

- **3. New entities:** N/A. Atlas is a Vue SPA with no persistence layer, and Europa's `AuditEvent` is untouched (E3).
- **4. Modified entities:** N/A. `SearchAuditEventItem` (`src/europa/types/audit-event.types.ts:5-19`) already types `type` and `path` as `string`, and `audit-event.types.ts` is unchanged.
- **5. New migrations (files):** N/A. No schema exists in Atlas, and Europa (MongoDB) needs none (E3).
- **6. New migration classes:** N/A. There are no migrations.
- **7. New DTOs:** N/A. The request params (`SearchAuditEventsParams.type?: string`, `audit-event.types.ts:65-83`) and the Europa request DTO (E4) are unchanged.
- **8. New projections:** N/A. Europa's `AuditEventItemProjection` shape is unchanged (E6), and Atlas consumes it as-is.

### Spec tests

Both specs follow the repo's conventions:
- `__specs__/` folders next to the unit.
- `given: / when: / then:` naming with `// Arrange / Act / Assert` (`formatDateForDisplay.spec.ts:4-15`).
- `test` from `vitest`, run under happy-dom (`vitest.config.mts:59`).

**`src/europa/utils/__specs__/constants.spec.ts`** (pure, no mounting; 6 cases)

The spec pins `const CALLISTO_CATEGORIZE = 'CATEGORIZE';` with a comment that it mirrors `callisto-back-end/src/audits/constants.ts` → `AUDIT_EVENT_TYPE.CATEGORIZE` (`constants.spec.ts:8-11`).
- The cases key on that pinned literal, so a typo in any Atlas site fails.
- It is a tripwire, not a live cross-repo check. The live check is the manual C3/C6 step against a Callisto-emitted event.

| Case | Criterion |
| ---- | --------- |
| `eventTypes` contains `CALLISTO_CATEGORIZE` exactly once | C6: this array is the dropdown option source, `SearchFilters.vue:251` |
| `eventTypes` has no duplicate entries (`new Set(eventTypes).size === eventTypes.length`) | C6 edge: no doubled option |
| `eventTypeColors[CALLISTO_CATEGORIZE] === 'info'` | C3: the chip shows in the chosen colour, not the grey fallback |
| `eventTypeColors` for `PERMISSIONS_UPDATED` and `MOVED` are still `'info'` | Neighbour: existing colours unchanged |
| `MULTI_PART_PATH_TYPES.has(CALLISTO_CATEGORIZE)` | C4: routes to the multi-line render |
| `Array.from(MULTI_PART_PATH_TYPES).sort()` equals `['CATEGORIZE', 'PERMISSIONS_UPDATED']` (not spread: the repo compiles to the ES5 default target, so spreading a `Set` fails `vue-tsc` with TS2802) | Neighbour: no other type silently switches to multi-line |

**`src/europa/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts`** (9 cases)

Harness, following existing precedents:
- **Quasar install:** `installQuasarPlugin()` from `@quasar/quasar-app-extension-testing-unit-vitest`, the dominant import form (e.g. `src/callisto/components/Dialogs/__specs__/DeleteCollectionDialog.spec.ts:7-10`). With Quasar installed, the real `q-chip` renders `bg-<color>`.
- **Mount:** `mount` from `@vue/test-utils`.
- **`q-table` stub:** renders the named body-cell slots per row, following `src/callisto/pages/CaseDetailPage/CaseJobsTable/__specs__/CaseJobsTable.spec.ts:67-79` (named `body-cell-*` slots per row) and `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/ClientDeliverablesTable/__specs__/ClientDeliverablesTable.spec.ts:243-247` (`props: ['rows']`, per-row `body` slot). Slot scope mirrors QTable's: `row` is the display row, and `value` is the raw field value, valid because the `path` column has no `format` (`auditEventColumns.ts:43-48`):
  ```ts
  const QTableStub = {
    props: ['rows'],
    template: `
      <div>
        <div v-for="row in rows" :key="row.auditEventId">
          <div :data-testid="'type-cell-' + row.auditEventId">
            <slot name="body-cell-type" :row="row" :value="row.type" />
          </div>
          <div :data-testid="'path-cell-' + row.auditEventId">
            <slot name="body-cell-path" :row="row" :value="row.path" />
          </div>
        </div>
      </div>`,
  };
  const stubs = {
    'q-table': QTableStub,
    'q-td': { props: ['props'], template: '<td><slot /></td>' },
    ColumnOrderSettingsDialog: true,
  };
  ```
- **Props:** `{ events, isLoading: false, pagination: null, sortBy: 'createdAt', sortDirection: 'desc', pageSize: 20 }`.
- **Event factory:** `buildEvent(overrides): SearchAuditEventItem` with every field populated (`userName: 'Ops User'`, because `displayRows` splits it). `type` is a string literal (default `'CREATED'`).
- **Line selector:** `findPathLines` = `findPathCell(target).findAll('td > div')`. Labels come from `strong` texts (`findPathLabels`).
- No other module mocks are needed. `useColumnOrderSettings` and `useTimezoneToggle` only touch `localStorage` through `createStorage`, which happy-dom provides.

| # | Case (`type` / `path` input) | Assertion | Criterion |
| - | ---------------------------- | --------- | --------- |
| 1 | `CATEGORIZE` / `Filepath: 5009/deliverables/depo.pdf \| Deliverable Type: Transcript \| Collection: Final` | 3 lines. `strong` texts in order `['Filepath','Deliverable Type','Collection']`. Line texts `Filepath: 5009/deliverables/depo.pdf`, `Deliverable Type: Transcript`, `Collection: Final` | C4 |
| 2 | `CATEGORIZE` / `Filepath: 5009/deliverables/depo.pdf \| Deliverable Type: Transcript \| Collection: N/A` | Third line text `Collection: N/A`, label `Collection` | C4 (no collection) |
| 3 | `CATEGORIZE` / `Filepath: 5009/Exhibit: A.pdf \| Deliverable Type: Exhibit \| Collection: N/A` | Still 3 lines. Line 1 label `Filepath`, text `Filepath: 5009/Exhibit: A.pdf` | C4 edge |
| 4 | `CATEGORIZE` / `5009/deliverables/depo.pdf` (no `': '`, e.g. Europa's `resourcePath` fallback, TS `:75-79`) | Mount does not throw. 1 line. `strong` texts `['5009/deliverables/depo.pdf']` (content kept) | Graceful: malformed producer value |
| 5 | `CATEGORIZE` (type chip) | Type cell `.q-chip` text `CATEGORIZE` (raw, LD-010) and has class `bg-info` | C3 |
| 6 | `PERMISSIONS_UPDATED` / `proceeding-files: read → read, update \| case-files: none → read` (shape from Europa TS `:66-72`) | 2 lines. Labels `['proceeding-files','case-files']`. Line 1 text `proceeding-files: read → read, update` (event built with `resourceType: 'PERMISSION'`) | Neighbour: unchanged |
| 7 | `CREATED` / `5009/deliverables/depo.pdf` | 0 `strong`, 0 `td > div`, cell text === raw path | Neighbour: single line |
| 8 | `CREATED` / `a: b \| c: d` | Still 0 `strong` and cell text === `a: b \| c: d`. The gate is the type, not content sniffing | Neighbour edge |
| 9 | `LOGOUT` (a type Europa emits, `constants.ts:6`, not in the Atlas list) / `x` | 0 `strong`, 0 `td > div`, cell text `x`. Chip has class `bg-grey` (the `getEventTypeColor` fallback) | Graceful: unknown type |

**C6 (Ops can narrow to `CATEGORIZE`)** is covered by:
- The `eventTypes` cases of `constants.spec.ts` (option present exactly once, no duplicates).
- The existing `useAuditSearch.spec.ts:210-213` (arbitrary `type` reaches `searchParams` unfiltered).
- `fetchAuditEvents.ts:26-28`, which appends `type` verbatim. It is unchanged, and `CATEGORIZE` needs no URL encoding.
- Europa E4/E5.

No new `SearchFilters` spec: its binding (`:251`) is unchanged, and the data it binds to is asserted directly.

**Gates (session end, in order):**
1. `npm audit --audit-level=high`
2. `npm run lint` (`--max-warnings 0`, so Prettier warnings fail it; `npm run lint:fix` if needed)
3. `npm run type-check`
4. `npx vitest run --maxWorkers 1 src/europa`

### Neighbors that must not change

| Surface | Why it stays unchanged | Pinned by |
| ------- | ---------------------- | --------- |
| `PERMISSIONS_UPDATED` path render (`SearchDataGrid.vue:315-321` markup) | The type is in `MULTI_PART_PATH_TYPES`, and the path-cell markup is unchanged | Spec row 6; constants set-equality case |
| Every other type renders one raw line (`:323-325`) | `MULTI_PART_PATH_TYPES.has` is false outside the two-member set | Spec rows 7, 8, 9 |
| Event Type option order and chip colours for existing types, and the grey fallback | Same values in the same order, plus one appended entry | constants colour cases; spec row 9 (grey fallback); option order has no case |
| `SearchFilters.vue` Event Type and Resource Type selects (`:248-280`) | Only the option data grows by one entry | constants `eventTypes` cases |
| `useAuditSearch.ts` / `fetchAuditEvents.ts` | No code change | Existing `useAuditSearch.spec.ts` stays green |
| Column config and ordering (`auditEventColumns.ts`, `useColumnOrderSettings.ts`) | No new column and no new row field, so a persisted `localStorage` column layout stays valid | No change |
| europa-back-end (all of E1–E6) | LD-007 | Evidence table above |
| Callisto ↔ Atlas literal | Must stay byte-equal (E5 is case-sensitive) | Pinned literal in `constants.spec.ts` |

### Notes

- **A `' | '` inside a CATEGORIZE value** opens an extra line, as it does for `PERMISSIONS_UPDATED`. Callisto writes the CATEGORIZE path values verbatim. Collection names reject `|` (`callisto-back-end/src/granting-client-access/validators/validate-dynamic-collection-name.validator.ts:7`).
- **Segments without `': '`** (either multi-part type) render the whole segment as the bold label followed by `: `, and an empty path renders one line reading `: `. Spec row 4 pins that such a segment stays on one line with its content kept.
- **Chip colour** is `info`. It is a one-token change if Ops prefers another.
