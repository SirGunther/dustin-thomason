---
ticket: INT-142
tags: [neptune, granting-client-access, contacts, audit, atlas]
author: Dustin Thomason
created: 2026-10-12
modified: 2026-10-12
modified_by: Dustin Thomason
---

# INT-142: CLIENT_ACCESS_UPDATED audit record (spec v2, revised after review)

> **Source of truth:** the original ticket and its acceptance criteria ([INT-142-original-ticket.md](../INT-142-original-ticket.md)). Every code change in this spec is in the [change inventory](#change-inventory). Each row names the AC line it serves and the existing code that was checked, with evidence that the existing code can't do it. **Nothing outside the inventory is built, and no test outside the [test inventory](#test-inventory) is written.**
>
> **Ticket:** [INT-142](https://pd-product-dev.atlassian.net/browse/INT-142) · **Parent:** INT-137 · **Ledger:** [INT-142-locked-decisions.md](INT-142-locked-decisions.md)
>
> **Repos:** `callisto-back-end` and `atlas-front-end`. **`europa-back-end` is not changed** (V-07): its existing default branch shows the path Callisto sends.
>
> **History:** supersedes spec v1, retired 2026-10-12 (see `../dnu/README.md`). Revised 2026-10-12 after the v2 review (ledger "Spec v2 review"): LD-006 reopened (V-07), A3 made optional (V-10), no-change saves not recorded (V-09). Revised again after the third review (ledger "Spec v2 review 3"): a missing contact or proceeding aborts the save (V-11); the rules for editing existing tests are stated precisely; T9 asserts `createdAt`.
>
> **Citations:** `file:line` on `main` (callisto-back-end `43121c53`, europa-back-end `434567f`, atlas-front-end `bb8be210`). Prefixes: `gca/` = callisto `src/granting-client-access/`; `save-ts/` = `gca/contacts/domain/transaction-scripts/save-contact-deliverable-type-grants-ts/`; `eu-ts/` = europa `src/audits-event/domain/transaction-scripts/search-audit-events-paginated-TS/`; `atlas/` = atlas `src/europa/`.

---

## Acceptance criteria (verbatim, labelled)

As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.

| Label | Criterion |
| --- | --- |
| AC-1 | Ops can view a log in Europa for granting access |
| AC-2a | The log displays: user info |
| AC-2b | The log displays: date/time |
| AC-2c | **granting access** actions taken: exactly which deliverable types were granted |
| AC-2d | **granting access** actions taken: exactly which deliverable types were revoked |
| AC-2e | **granting access** actions taken: to whom the types were granted |
| AC-3 | A new Event Type is created for this action: **CLIENT_ACCESS_UPDATED** |
| AC-3b | This event type is added to the Event Type drop down in Europa |
| AC-4 | A new Resource Type for this action is created called: **Contact** |
| AC-4b | This new resource type is also added to the resource type dropdown |
| AC-5 | Path format: Case: [case] · Job: [job] · Proceeding: [proceeding] · Access granted: [list of deliverable types] · Access revoked: [list of deliverable types] |

**AC-2a and AC-2b need no new code.** Every audit record already carries `identity` and `createdAt`. europa-back-end already returns them (`eu-ts/search-audit-events-paginated.transaction.script.ts:124-139`), and Atlas already shows them in the User and Date columns (`atlas/pages/HomePage/SearchDataGrid/auditEventColumns.ts:15-28`, `:55-61`).

## Out of scope

- Case-group grants (`SaveCaseGroupDeliverableTypeGrantsTS`); the ticket names resource type Contact.
- Grants removed by a database cascade.
- Search-specific code (V-08).
- A chip colour (LD-011); backfill; guaranteed delivery.
- Any change to existing behaviour of the save route. Its response, validation order, outbox write and flag handling stay as they are.

---

## The record

One record per save that grants or revokes at least one deliverable type (V-09), for one contact on one proceeding (LD-008), sent after the save commits (LD-016).

| Field | Value | AC |
| --- | --- | --- |
| `type` | `CLIENT_ACCESS_UPDATED` | AC-3 |
| `identity`, `createdAt`, `serviceName`, `id` | as every audit record (assembler pattern) | AC-2a, AC-2b |
| resource `resourceType` | `CONTACT` (upper case like every resource type, LD-002) | AC-4 |
| resource `id` / `resourceId` / `resourceName` | contact id (string) / contact id (string) / contact full name (LD-004) | AC-2e |
| resource `resourcePath` / `resourceBucket` | `''` (S-04) | — |
| resource `oldState` = `newState` | `{ path: <five-part text> }`, built by Callisto (V-07) | AC-2c, AC-2d, AC-5 |

The five-part text:

```
Case: Smith v. Jones | Job: 5512 | Proceeding: Day 1 | Access granted: MP4 Video › DepoView, Planet Draft | Access revoked: N/A
```

- An empty value or list reads `N/A` (S-09).
- Each item is `Collection › Type`, or the type alone for a track-level grant, joined with `, `. A name containing `,`, `›` or `"` is wrapped in double quotes, with embedded `"` doubled (LD-018).
- europa-back-end's default branch returns `newState.path` as the row's path and `''` as its bucket (`eu-ts/search-audit-events-paginated.transaction.script.ts:110-122`). Atlas splits it into five labelled lines (C3).

---

## Change inventory

### callisto-back-end

| # | File | Change | AC | Existing code checked → why it can't do this |
| --- | --- | --- | --- | --- |
| A1 | `src/audits/constants.ts` | Add `CONTACT` to `AuditEventResourceType`, `CLIENT_ACCESS_UPDATED` to `AUDIT_EVENT_TYPE` | AC-3, AC-4 | Neither literal exists (`constants.ts:3-21`) |
| A3 | `src/proceedings/domain/transaction-scripts/fetch-proceeding-detail-by-Id-ts/proceeding-detail.projection.ts` | Add **optional** `caseShortName?: string \| null` | AC-5 (Case) | `ProceedingRepository.findProceedingDetailById` already selects `case.short_name AS "caseShortName"` (`src/proceedings/infrastructure/repositories/proceeding.repository.ts:44`), but its type leaves the field out. Optional, so the existing typed fixtures without it still compile (`fetch-proceeding-detail-by-Id-ts.transaction.script.spec.ts:36`, `proceeding.service.spec.ts:205`; V-10). Type only: the row already holds the field, and `ProceedingDetailResponseDTO` is unchanged |
| A4 | `save-ts/save-contact-deliverable-type-grants.transaction.script.ts` | Read the contact's grants with the existing `grantRepository.findByContactAndProceeding` after the existing checks and before `replaceForContactAndProceeding` (`:77`) | AC-2c, AC-2d | The only read of the grants before the replace is inside `ValidateClientAccessManagerDeltaPermissions`, which returns `Promise<void>` (`gca/validators/validate-client-access-manager-delta-permissions.validator.ts:40-41`). Making it return them would change existing assertions (`resolves.toBeUndefined()`, validator spec `:48`, `:67`, `:113`, `:178`) |
| A5 | same file | Private `toGrantDelta(previous, current)` using the file's existing `buildSelectionKey` (`:25-28`): granted = after but not before, revoked = before but not after, each named from its own row | AC-2c, AC-2d | The validator computes only true/false for additions and removals (`validator:51-56`). No code produces the lists. Keyed by collection and type, because type names repeat across collections (E-14) |
| A6 | same file | Read the contact's full name with the existing `ContactsRepository.findActiveById` (`gca/contacts/infrastructure/repositories/contacts.repository.ts:88-95`). **A null result aborts the save** with the existing `BadRequestException(CONTACT_NOT_FOUND_MESSAGE)` (`gca/validators/validate-contact-exists.validator.ts:4`, `:19`) | AC-2e | `ValidateContactExists` reads the contact but returns `Promise<void>` (`validate-contact-exists.validator.ts:14-21`); its spec asserts `resolves.toBeUndefined()` (`:33`). The abort is needed because `ContactsRepository` doesn't read through `TransactionContext` (`contacts.repository.ts:22-25`), so the contact can be deactivated or removed between the validator's read and this one. A record must never be sent without the contact (V-11) |
| A7 | same file | Read case short name, job id and proceeding name with the existing `ProceedingRepository.findProceedingDetailById` (`proceeding.repository.ts:28-51`). **A null result aborts the save** with the existing `BadRequestException(PROCEEDING_NOT_FOUND_MESSAGE)` (`gca/validators/validate-proceeding-exists.validator.ts:4`, `:19`) | AC-5 | Nothing in the save path reads the case. `ValidateProceedingExists` uses `findById`, which has no case data. `ProceedingRepository` reads in the transaction (`proceeding.repository.ts:14-21`), but a proceeding deleted and committed in between can still return null (V-11) |
| A8 | same file | Return `{ selections, audit }` | AC-1 | The save path sends nothing to Europa (`save-ts/…transaction.script.ts:46-101`) |
| A9 | `save-ts/save-contact-deliverable-type-grants-ts.provider.ts` | Add `ContactsRepository` and `ProceedingRepository` to the factory parameters, the constructor call and `inject` | wiring for A6, A7 | The transaction script is built only by this factory (`gca/granting-client-access.module.ts:153`). Both repositories are already available to GCA (`gca/registries/repository.registry.ts:26`; `ProceedingRepository` in `validate-proceeding-exists.validator.ts:12`) |
| A10 | `gca/domain/ports/contact-access-audit-dispatcher.port.ts` (new) | `CONTACT_ACCESS_AUDIT_DISPATCHER`, `ContactAccessAuditPort`, and the input types | AC-1 | The only GCA audit port, `CLIENT_ACCESS_FILE_AUDIT`, takes file records only (`gca/domain/ports/client-access-file-audit.port.ts:12-19`) |
| A11 | `gca/infrastructure/dispatchers/contact-access-audit/contact-access-audit.dispatcher.ts` (new) | Sends the assembled record to the audit queue | AC-1 | Each existing audit chain (proceeding, proceeding file, case file, job-submission file, permissions) sends one fixed resource type. Adding `CONTACT` to one means changing that chain's port, dispatcher and assembler, and binding a GCA port in another module |
| A12 | `…/contact-access-audit/contact-access-to-audit-event.assembler.ts` (new) | Builds the record, its one resource inline, and the five-part text in `path`: `N/A` for empty values and lists, `Collection › Type` items joined with `, `, quoting per LD-018 | AC-1, AC-2c, AC-2d, AC-2e, AC-3, AC-4, AC-5 | Same as A11. The resource is built inline, as `permissions-to-audit-event.assembler.ts:17-23` does, so there is no converter. Callisto already builds display text in `path` for permissions (`:22-23`). No `N/A` helper exists in callisto `src` (`grep "'N/A'"` finds none), so the assembler has its own |
| A13 | `…/contact-access-audit/contact-access-audit.module.ts` (new) | Imports `AuditsModule`; provides the assembler; binds `CONTACT_ACCESS_AUDIT_DISPATCHER` to the dispatcher; exports the token | wiring | `GrantingClientAccessModule` doesn't import `AuditsModule`. Every audit dispatcher is bound in its own module that imports `AuditsModule` |
| A14 | `gca/granting-client-access.module.ts` | Import `ContactAccessAuditModule` | wiring | — |
| A15 | `gca/contacts/domain/services/contacts.service.ts` | Inject `CONTACT_ACCESS_AUDIT_DISPATCHER`. After the transaction script resolves, dispatch `{ ...audit, user }` **only when `audit.granted` or `audit.revoked` is non-empty**, then return `{ selections }` | AC-1, AC-2c, AC-2d | The service dispatches nothing today (`:66-84`). A service injecting a dispatcher port directly already exists (`job-submission.service.ts:46`). There is no `try/catch`: the producer never throws (`sqs-audit-event.producer.ts:23-33`), and `RecategorizeDeliverableFilesService` dispatches the same way (`:50-57`). The non-empty condition is V-09 |

**A2 is removed:** `ResourceState` already has `path?: string` (`src/audits/domain/domain-events/audit-event-resource.de.ts:13`), so no type change is needed (V-07).

**Not built (removed from v1 or the first v2, with the existing code that covers it):**

- A new names repository → A6 and A7 reuse existing reads.
- An aggregator, a param file and a converter → A10, A12 and A15.
- Separate assembler and delta classes → A5 is a private method using the existing `buildSelectionKey`.
- A save-result projection file → the audit types live in the port file.
- A `try/catch` → see A15.
- Registry entries → none needed.
- A structured state type (A2) and every europa-back-end change (B1–B4) → V-07.

### europa-back-end

**No change.** The default branch already returns `newState.path ?? oldState.path ?? resourcePath` and `newState.bucket ?? oldState.bucket ?? resourceBucket` (`eu-ts/search-audit-events-paginated.transaction.script.ts:110-122`). Ingest stores any `type`, `resourceType` and state as sent (no allow-list: `src/audits-event/application/listeners/sqs-audit-event.listener.ts:15-33`). The `type` and `resourceType` filters are exact matches on any string (`eu-ts/converters/search-params-to-mongo-query.converter.ts:33-46`).

### atlas-front-end

| # | File | Change | AC | Existing code checked → why it can't do this |
| --- | --- | --- | --- | --- |
| C1 | `atlas/utils/constants.ts` | Append `'CLIENT_ACCESS_UPDATED'` to `eventTypes` | AC-3b | Not in the list (`:3-17`); the Event Type dropdown renders this array (`atlas/pages/HomePage/SearchFilters/SearchFilters.vue:248-262`) |
| C2 | same file | Add `'CONTACT'` first in `resourceTypes` (alphabetical, S-07) | AC-4b | Not in the list (`:19-25`); the Resource Type dropdown renders this array (`SearchFilters.vue:265-280`) |
| C3 | same file | Add `'CLIENT_ACCESS_UPDATED'` to `MULTI_PART_PATH_TYPES` | AC-5 | Without it, the five fields run together on one line (`atlas/pages/HomePage/SearchDataGrid/SearchDataGrid.vue:90-92`, `:102`). Every other INT-137 path type is listed (`:40-44`). No `SearchDataGrid.vue` change (S-08) |

---

## Code

### callisto-back-end

```ts
// A1 src/audits/constants.ts
//   AuditEventResourceType: add   CONTACT: 'CONTACT',
//   AUDIT_EVENT_TYPE:       add   CLIENT_ACCESS_UPDATED: 'CLIENT_ACCESS_UPDATED',

// A3 proceeding-detail.projection.ts: add
	caseShortName?: string | null;
```

```ts
// A10 NEW gca/domain/ports/contact-access-audit-dispatcher.port.ts
import type { AuthUser } from 'src/generic/auth/constants';

export const CONTACT_ACCESS_AUDIT_DISPATCHER = Symbol('CONTACT_ACCESS_AUDIT_DISPATCHER');

export type ContactAccessAuditGrant = {
	readonly deliverableType: string;
	readonly collection: string | null;
};

/** One save of one contact's grants on one proceeding. */
export type ContactAccessAudit = {
	readonly contact: { readonly id: number; readonly fullName: string };
	readonly proceeding: { readonly id: number; readonly value: string };
	readonly jobId: number;
	readonly caseShortName: string | null;
	readonly granted: readonly ContactAccessAuditGrant[];
	readonly revoked: readonly ContactAccessAuditGrant[];
};

export type ContactAccessAuditPort = {
	apply(input: ContactAccessAudit & { readonly user: Partial<AuthUser> }): Promise<boolean>;
};
```

```ts
// A4–A8 save-ts/save-contact-deliverable-type-grants.transaction.script.ts
// constructor: add after validateDeltaPermissions
		private readonly contactsRepository: ContactsRepository,
		private readonly proceedingRepository: ProceedingRepository,

// apply(): return type becomes
//   Promise<ContactDeliverableTypeGrantsResult & { readonly audit: ContactAccessAudit }>
// everything up to `const userId` is unchanged; then:
		const previousSelections =
			await this.grantRepository.findByContactAndProceeding({
				contactId: params.contactId,
				proceedingId: params.proceedingId,
			});
		// replaceForContactAndProceeding, the re-read into `selections` and the
		// flag-gated outbox write are unchanged
		const contact = await this.contactsRepository.findActiveById(params.contactId);
		if (!contact) {
			throw new BadRequestException(CONTACT_NOT_FOUND_MESSAGE);
		}
		const proceeding = await this.proceedingRepository.findProceedingDetailById(
			params.proceedingId,
		);
		if (!proceeding) {
			throw new BadRequestException(PROCEEDING_NOT_FOUND_MESSAGE);
		}
		return {
			selections,
			audit: {
				contact: { id: params.contactId, fullName: contact.fullName },
				proceeding: { id: params.proceedingId, value: proceeding.value },
				jobId: proceeding.jobId,
				caseShortName: proceeding.caseShortName ?? null,
				...this.toGrantDelta(previousSelections, selections),
			},
		};

	private toGrantDelta(
		previous: readonly ContactDeliverableTypeGrantProjection[],
		current: readonly ContactDeliverableTypeGrantProjection[],
	): { granted: ContactAccessAuditGrant[]; revoked: ContactAccessAuditGrant[] } {
		const previousKeys = new Set(previous.map(buildSelectionKey));
		const currentKeys = new Set(current.map(buildSelectionKey));
		const toAuditGrant = (grant: ContactDeliverableTypeGrantProjection): ContactAccessAuditGrant => ({
			deliverableType: grant.deliverableTypeValue,
			collection: grant.deliverableCollectionValue,
		});
		return {
			granted: current.filter((grant) => !previousKeys.has(buildSelectionKey(grant))).map(toAuditGrant),
			revoked: previous.filter((grant) => !currentKeys.has(buildSelectionKey(grant))).map(toAuditGrant),
		};
	}
```

The two throws run inside the `@Transactional()` `apply`, so a missing contact or proceeding rolls back the replace and the outbox write, and no record is sent (V-11). They reuse the validators' existing messages, so the caller gets the same 400 as when the validators fail. `CONTACT_NOT_FOUND_MESSAGE` and `PROCEEDING_NOT_FOUND_MESSAGE` are imported from those validators. `caseShortName ?? null` covers both the optional field (V-10) and a job without a case.

```ts
// A11 NEW gca/infrastructure/dispatchers/contact-access-audit/contact-access-audit.dispatcher.ts
@Injectable()
export class ContactAccessAuditDispatcher implements ContactAccessAuditPort {
	constructor(
		private readonly contactAccessToAuditEventAssembler: ContactAccessToAuditEventAssembler,
		@Inject(AUDIT_EVENT_PRODUCER_TOKEN)
		private readonly auditEventProducer: ProducerInterface<AuditEventDomainEvent>,
		private readonly auditConfigAccessor: AuditConfigAccessor,
	) {}

	async apply(input: ContactAccessAudit & { readonly user: Partial<AuthUser> }): Promise<boolean> {
		return await this.auditEventProducer.apply(
			this.auditConfigAccessor.sqsAuditEventUrl,
			this.contactAccessToAuditEventAssembler.apply(input),
		);
	}
}
```

```ts
// A12 NEW …/contact-access-audit/contact-access-to-audit-event.assembler.ts
const NAME_NEEDS_QUOTING = /[,›"]/;

@Injectable()
export class ContactAccessToAuditEventAssembler {
	constructor(private readonly auditConfigAccessor: AuditConfigAccessor) {}

	apply(input: ContactAccessAudit & { readonly user: Partial<AuthUser> }): AuditEventDomainEvent {
		const state = { path: this.toPath(input) };
		return {
			id: uuidv4(),
			createdAt: new Date(),
			serviceName: this.auditConfigAccessor.serviceName,
			type: AUDIT_EVENT_TYPE.CLIENT_ACCESS_UPDATED,
			identity: input.user.identity,
			auditEventResources: [
				{
					id: input.contact.id.toString(),
					resourceType: AuditEventResourceType.CONTACT,
					resourceId: input.contact.id.toString(),
					resourceName: input.contact.fullName,
					resourcePath: '',
					resourceBucket: '',
					oldState: state,
					newState: state,
				},
			],
		};
	}

	// Atlas splits the path on ' | ' and bolds the text before the first ': '.
	private toPath(input: ContactAccessAudit): string {
		return [
			`Case: ${this.toDisplayValue(input.caseShortName)}`,
			`Job: ${input.jobId}`,
			`Proceeding: ${this.toDisplayValue(input.proceeding.value)}`,
			`Access granted: ${this.toGrantList(input.granted)}`,
			`Access revoked: ${this.toGrantList(input.revoked)}`,
		].join(' | ');
	}

	private toGrantList(grants: readonly ContactAccessAuditGrant[]): string {
		const items = grants.map((grant) =>
			grant.collection
				? `${this.toQuotedName(grant.collection)} › ${this.toQuotedName(grant.deliverableType)}`
				: this.toQuotedName(grant.deliverableType),
		);
		return items.length ? items.join(', ') : 'N/A';
	}

	private toDisplayValue(value: string | null): string {
		return value?.trim() ? value : 'N/A';
	}

	private toQuotedName(name: string): string {
		return NAME_NEEDS_QUOTING.test(name) ? `"${name.replace(/"/g, '""')}"` : name;
	}
}
```

```ts
// A13 NEW …/contact-access-audit/contact-access-audit.module.ts
@Module({
	imports: [AuditsModule],
	providers: [
		ContactAccessToAuditEventAssembler,
		{ provide: CONTACT_ACCESS_AUDIT_DISPATCHER, useClass: ContactAccessAuditDispatcher },
	],
	exports: [CONTACT_ACCESS_AUDIT_DISPATCHER],
})
export class ContactAccessAuditModule {}
```

```ts
// A15 gca/contacts/domain/services/contacts.service.ts
// constructor: add after featureFlagAggregator
		@Inject(CONTACT_ACCESS_AUDIT_DISPATCHER)
		private readonly contactAccessAuditDispatcher: ContactAccessAuditPort,

// saveContactDeliverableTypeGrants: replace the final `return await …apply(…)` (:80-83) with
		const { selections, audit } = await this.saveContactDeliverableTypeGrantsTS.apply({
			...command,
			isGrantingClientAccessEnabled,
		});
		if (audit.granted.length > 0 || audit.revoked.length > 0) {
			await this.contactAccessAuditDispatcher.apply({ ...audit, user: command.user });
		}
		return { selections };
```

### atlas-front-end

```ts
// C1–C3 atlas/utils/constants.ts
eventTypes:            append 'CLIENT_ACCESS_UPDATED'
resourceTypes:         add 'CONTACT' as the first entry
MULTI_PART_PATH_TYPES: add 'CLIENT_ACCESS_UPDATED'
```

---

## Test inventory

Only the cases below. **Existing assertions stay unchanged, except for T17's `MULTI_PART_PATH_TYPES` exact-set assertion.** Existing spec files change in exactly three ways:

- **New dependencies get providers.** In the transaction-script spec, the `ContactsRepository` and `ProceedingRepository` mocks resolve a contact and a proceeding by default, so the existing cases don't hit the A6 / A7 aborts. In the service spec, the dispatcher mock is added.
- **The service spec's existing fixtures follow the new result contract.** The two existing tests mock the transaction script's result as `{ selections }` (`contacts.service.spec.ts:80-82`, `:118-120`). A15 reads `audit.granted`, so each mocked result gains an `audit` value, with both lists empty so their existing assertions keep holding.
- **The one Atlas exact-set test** that C3 forces (T17).

A3 is optional, so no existing `ProceedingDetailProjection` fixture changes.

| # | Spec | Case | Covers |
| --- | --- | --- | --- |
| T1 | `save-ts/__specs__/save-contact-deliverable-type-grants.transaction.script.spec.ts` | With previous and current grants that differ, `audit.granted` lists only the added grants and `audit.revoked` only the removed ones, each named from its own row | A4, A5 · AC-2c, AC-2d |
| T2 | same | `DepoView` in `MP4 Video` replaced by `DepoView` in `MPEG Video` gives one granted and one revoked item | A5 · AC-2c, AC-2d (E-14) |
| T3 | same | `audit` carries the contact's full name, case short name, job id and proceeding name from the two reads | A6, A7 · AC-2e, AC-5 |
| T4 | same | The previous grants are read before `replaceForContactAndProceeding` (call order) | A4 · AC-2d: removals can't be known after the replace |
| T5 | same | A null contact lookup rejects with `Contact not found`; a null proceeding lookup rejects with `Proceeding not found` (no `audit` returned) | A6, A7 · AC-2e: no record without the contact (V-11) |
| T6 | `gca/contacts/domain/services/__specs__/contacts.service.spec.ts` | A save that grants or revokes something: the dispatcher gets `{ ...audit, user }` once after the transaction script resolves, and the service returns `{ selections }` | A15 · AC-1 |
| T7 | same | A save where both lists are empty: nothing is dispatched, and `{ selections }` is returned | A15 · V-09 |
| T8 | same | The transaction script rejects: nothing is dispatched | A15 · AC-1: no record for a save that didn't happen |
| T9 | `gca/infrastructure/dispatchers/contact-access-audit/__specs__/contact-access-to-audit-event.assembler.spec.ts` (new; fake timers) | Record: `type` `CLIENT_ACCESS_UPDATED`; one resource with `resourceType` `CONTACT`, contact id and full name, empty `resourcePath` and `resourceBucket`; `oldState` equals `newState`, which is `{ path }`; `identity` from the user; **`createdAt` equals the faked current time** | A12 · AC-1, AC-2a, AC-2b, AC-2e, AC-3, AC-4 |
| T10 | same | Full path: `Case: Smith v. Jones \| Job: 5512 \| Proceeding: Day 1 \| Access granted: MP4 Video › DepoView, Planet Draft \| Access revoked: Full Transcript › LEF (LiveNote)` | A12 · AC-5, AC-2c, AC-2d |
| T11 | same | An empty `revoked` list gives `Access revoked: N/A`; a null case short name gives `Case: N/A` | A12 · S-09 |
| T12 | same | A null collection gives the type alone | A12 · LD-007 |
| T13 | same | Collection `Smith, Day 1` gives `"Smith, Day 1" › DepoView`; a name `Exhibit "A"` gives `"Exhibit ""A"""` | A12 · LD-018 |
| T14 | `…/__specs__/contact-access-audit.dispatcher.spec.ts` (new) | Sends the assembled record to `sqsAuditEventUrl` and returns the producer's result | A11 · AC-1 |
| T15 | `atlas/utils/__specs__/constants.spec.ts` | `eventTypes` lists `CLIENT_ACCESS_UPDATED` exactly once | C1 · AC-3b |
| T16 | same | `resourceTypes` lists `CONTACT` exactly once | C2 · AC-4b |
| T17 | same (existing test, `:53-63`) | The `MULTI_PART_PATH_TYPES` exact set becomes the four sorted entries | C3 (forced edit) |
| T18 | `atlas/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts` | A `CLIENT_ACCESS_UPDATED` row renders five lines with bold labels `Case`, `Job`, `Proceeding`, `Access granted`, `Access revoked` | C3 · AC-5 |

**Not tested, because it is unchanged or outside the AC:**

- The permission-check order, the outbox write, the feature flag and the response shape (covered by existing specs).
- europa-back-end, which has no change.
- Chip colour; logging; transaction connections.
- Values that can't occur.

---

## Decisions

| Ref | Decision |
| --- | --- |
| LD-001, LD-002 | Event type `CLIENT_ACCESS_UPDATED`; resource type `CONTACT` |
| LD-003 | Case = case short name, Job = job id, Proceeding = proceeding name |
| LD-004, LD-008 | One `CONTACT` resource per save; `resourceName` = contact full name |
| LD-005 | Only the contact save route records |
| LD-007 | Each item names its collection; a track-level grant shows the type alone |
| LD-009 | Not gated by `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED` |
| LD-011 | No chip colour |
| LD-016 | Dispatch after the save commits, through a GCA-owned port |
| LD-018, LD-019 | Item format with conditional quoting, now applied in Callisto (A12); a `\|` inside a name is an accepted limitation |
| S-02 | The audit data is built inside the save transaction (A4–A8). A failed read, or a missing contact or proceeding (V-11), rolls back the save, as with the recategorize records |
| V-11 | A null contact or proceeding lookup in A6 / A7 aborts the save with the validators' existing not-found errors, so no record is ever sent without the contact |
| S-03 | The transaction script reads the previous grants itself (A4) |
| S-04 | `resourcePath` and `resourceBucket` are `''` |
| S-07, S-08, S-09 | Atlas list order; no `SearchDataGrid.vue` change; `N/A` for an empty value or list |
| V-07 | **LD-006 reopened and replaced:** Callisto builds the five-part text in `oldState.path` = `newState.path`. europa-back-end is unchanged |
| V-08 | **LD-014 and LD-015 revised:** only Callisto and Atlas deploy; Atlas goes with or before Callisto. europa-back-end's free-text search already matches `oldState.path` / `newState.path` (`eu-ts/converters/search-params-to-mongo-query.converter.ts:84-100`), so case, job, proceeding and deliverable type names become searchable as a side effect; no search code is added |
| V-09 | **LD-010 replaced:** a save that neither grants nor revokes anything sends no record (A15) |
| V-10 | **A3 optional:** `caseShortName?: string \| null` keeps the existing typed fixtures compiling |

Superseded by V-01 to V-06 (first v2): S-01, S-05, S-06.

## Rollout and manual check

Deploy atlas-front-end with or before Callisto (V-08). europa-back-end is not deployed for this ticket. Until Atlas is live, the dropdowns lack the new values and the path shows on one line.

Manual check, one step per AC:

1. In the Access Manager, grant a contact one type inside a collection and one track-level type, then save.
2. In Europa, one row shows type `CLIENT_ACCESS_UPDATED` (AC-1, AC-3), resource type `CONTACT` (AC-4), the contact's name (AC-2e), the user (AC-2a) and the date (AC-2b). The five path lines show the overlay's case, job and proceeding, both types under `Access granted` and `N/A` under `Access revoked` (AC-5, AC-2c).
3. Remove one type and save: `Access revoked` lists it (AC-2d).
4. Both dropdowns offer the new values, and each filter returns the rows (AC-3b, AC-4b).
