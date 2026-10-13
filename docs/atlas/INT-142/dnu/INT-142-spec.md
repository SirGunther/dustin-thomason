---
ticket: INT-142
tags: [neptune, granting-client-access, contacts, audit, europa, atlas]
author: Dustin Thomason
created: 2026-10-12
modified: 2026-10-12
modified_by: Dustin Thomason
---

# INT-142: CLIENT_ACCESS_UPDATED audit records for contact grant changes

> **Parent epic:** [INT-137](https://pd-product-dev.atlassian.net/browse/INT-137) — Audit Client Access Actions
>
> **Ticket:** [INT-142](https://pd-product-dev.atlassian.net/browse/INT-142)
>
> **Repos (branch `INT-142`, cut from `main`, ledger LD-017):** `callisto-back-end` sends the record, `europa-back-end` builds its path text, `atlas-front-end` lists the new event and resource types and renders the path on the Europa audit page.
>
> **Builds on (all on `main`):** INT-138 `CATEGORIZE` (callisto #464, atlas #582), INT-139 `RECATEGORIZE` (europa #72, which also carries `toDisplayValue`), INT-140 proceeding `CREATED` (callisto #474, europa #74, atlas #590). INT-141 (europa #75, open) changes the same Atlas files; see [Cross-cutting](#cross-cutting).
>
> **Decisions:** [INT-142-locked-decisions.md](INT-142-locked-decisions.md) (LD-001 to LD-019). This spec settles the ledger's open implementation items as S-01 to S-09 below. The review questions are locked on the reviewer's recommendation: Q-01 → LD-018 (conditional double-quoting), Q-02 → LD-019 (accepted limitation). See [INT-142-spec-review-response.md](INT-142-spec-review-response.md).
>
> **Implementation readiness:** ready. The review blocker cleared on 2026-10-12, once Q-01 and Q-02 were locked.
>
> **Delivery:** best-effort, the way every audit record is sent today. See [Known limitations](#known-limitations).

Citations are `file:line` on `main` (callisto-back-end `43121c53`, europa-back-end `434567f`, atlas-front-end `bb8be210`), checked 2026-10-12. Prefixes:

| Prefix | Path |
| --- | --- |
| `gca/` | `callisto-back-end/src/granting-client-access/` |
| `gca-c/` | `gca/contacts/` |
| `save-ts/` | `gca-c/domain/transaction-scripts/save-contact-deliverable-type-grants-ts/` |
| `cau/` | `gca-c/domain/sub-domains/contact-access-audit/` (new) |
| `eu/` | `europa-back-end/src/audits-event/` |
| `eu-ts/` | `eu/domain/transaction-scripts/search-audit-events-paginated-TS/` |
| `atlas/` | `atlas-front-end/src/europa/` |

---

## Story and acceptance criteria (from the ticket)

As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.

- Ops can view a log in Europa for granting access
- The log displays the following details:
  - user info
  - date/time
  - **granting access** actions taken
    - exactly which deliverable types were granted
    - exactly which deliverable types were revoked
    - to whom the types were granted
- A new Event Type is created for this action: **CLIENT_ACCESS_UPDATED**
  - This event type is added to the Event Type drop down in Europa
- A new Resource Type for this action is created called: **Contact**
  - This new resource type is also added to the resource type dropdown
- Path format:
  - Case: [case]
  - Job: [job]
  - Proceeding: [proceeding]
  - Access granted: [list of deliverable types]
  - Access revoked: [list of deliverable types]

---

## Summary

Saving a contact's deliverable-type grants sends one `CLIENT_ACCESS_UPDATED` audit record with resource type `CONTACT`. Callisto computes which grants the save added and removed, inside the save's transaction, and sends the names as structured state once the save commits. europa-back-end builds the five-part path text. atlas-front-end adds both literals to its dropdowns and renders the path on five lines. There is no migration, route, DTO or europa-back-end schema change.

| In scope | Out of scope |
| --- | --- |
| The save-grants action, `POST /callisto/granting-client-access/contacts/deliverable-type-grants` (`gca-c/application/controllers/actions/contact-deliverable-type-grants-action/save-contact-deliverable-type-grants.action.ts:24-46`) | Case-group grants (`SaveCaseGroupDeliverableTypeGrantsTS`, INT-42). They write the same table for principal `CaseGroup`; the ticket names resource type Contact |
| One record per save, including a save that removes all of a contact's access (LD-005) | Grants removed by a database cascade when a collection or deliverable type is deleted (`1782843306117-create__deliverable_access_grants__table.ts` foreign keys) |
| europa-back-end paginated search path for `CLIENT_ACCESS_UPDATED` | europa-back-end's `/search` endpoint |
| Europa audit page: Event Type and Resource Type lists, five-line path rendering | A chip colour for `CLIENT_ACCESS_UPDATED` (LD-011: grey fallback) |
| | Free-text search by case, job, proceeding or deliverable type (LD-015) |
| | Guaranteed delivery; backfill of past grant changes |

---

## Problem

Changing which deliverable types a contact can see writes no audit record. `ContactsService.saveContactDeliverableTypeGrants` runs the save transaction script and returns its result (`gca-c/domain/services/contacts.service.ts:66-84`). The transaction script replaces the contact's grants and writes a Dione outbox event only for flagged users (`save-ts/save-contact-deliverable-type-grants.transaction.script.ts:77-98`). Neither sends anything to Europa, and neither keeps the grants as they were before the save, so nothing can say what was granted or revoked. Ops can't see who changed a contact's access, when, or what changed. Neither the event type nor the resource type exists anywhere (`callisto-back-end/src/audits/constants.ts:3-21`, `atlas/utils/constants.ts:3-25`).

## Requirement

Every successful save of a contact's grants on a proceeding sends one audit record with event type `CLIENT_ACCESS_UPDATED` and resource type `CONTACT`. It is delivered best-effort, like every audit record Callisto sends. Ops can filter to it by either dropdown, and it shows who saved, when, which contact, and:

`Case: <case short name> | Job: <job id> | Proceeding: <proceeding name> | Access granted: <items> | Access revoked: <items>`

Each item names its deliverable type and, when the grant has one, its collection (LD-007), written as LD-018 sets out. An empty list reads `N/A`.

## Solution

- **callisto-back-end:**
  - The save transaction script reads the contact's grants before it replaces them. After the replace, a new assembler compares before and after, reads the contact, case, job and proceeding names, and returns the audit data with `selections`.
  - `ContactsService` dispatches the audit data through a new GCA port once the transaction has committed, logs a failed dispatch, and still returns `{ selections }`.
  - A new GCA sub-domain, `contact-access-audit`, holds the aggregator, dispatcher, assembler and converter. It binds the port and sends the record to the audit SQS queue.
- **europa-back-end:** the paginated search builds the five-part text for `CLIENT_ACCESS_UPDATED`. A name that contains `,`, `›` or `"` is quoted in the lists (LD-018).
- **atlas-front-end:** `CLIENT_ACCESS_UPDATED` joins `eventTypes` and `MULTI_PART_PATH_TYPES`; `CONTACT` joins `resourceTypes`.

### The record Callisto sends

| Field | Value |
| --- | --- |
| `type` | `CLIENT_ACCESS_UPDATED` |
| `createdAt` | the time the record is built, right after the save commits (`new Date()` in the event assembler, as in every chain) |
| `serviceName` | `AuditConfigAccessor.serviceName` |
| `identity` | the requesting user's `identity` (`@VerifiedUserDecorator()` on the action; `UserAddressAndAgentMiddleware` fills `ipAddress` and `userAgent`) |
| `auditEventResources` | one resource (LD-008) |
| resource `id` / `resourceId` | the contact id, as a string |
| resource `resourceType` | `CONTACT` |
| resource `resourceName` | the contact's full name (LD-004) |
| resource `resourcePath` / `resourceBucket` | `''` (S-04) |
| resource `oldState` = `newState` | `{ caseShortName, jobId, proceedingName, granted, revoked }`. `granted` and `revoked` are lists of `{ deliverableType, collection }` names, `collection` null for a track-level grant. Raw values only: no labels, separators or `N/A` (LD-006) |

Displayed (LD-018: `Collection › Type`, or the type alone for a track-level grant, items joined with `, `):

```
Case: Smith v. Jones
Job: 5512
Proceeding: Day 1
Access granted: MP4 Video › DepoView, Planet Draft
Access revoked: N/A
```

A name containing `,`, `›` or `"` is wrapped in double quotes, with any embedded `"` doubled. Only a custom (dynamic) collection name can contain `,` or `›` today, for example `Access granted: "Smith, Day 1" › DepoView`.

### Acceptance criteria trace

| Criterion | Met by | Verified by |
| --- | --- | --- |
| Ops can view a log in Europa for granting access | One record per save, dispatched by `ContactsService` (A.10 step 6) | A.11 service spec; manual steps 2–4 |
| User info | `identity`. europa-back-end projects `userEmail` and `userName` (`eu-ts/search-audit-events-paginated.transaction.script.ts:124-139`); Atlas shows them in the User columns. Existing behaviour | A.11 event assembler spec (`identity`); manual step 2 |
| Date/time | `createdAt`, projected by europa-back-end and shown in the Date column (`atlas/pages/HomePage/SearchDataGrid/auditEventColumns.ts:55-61`). Existing behaviour | A.11 event assembler spec (`createdAt`); manual step 2 |
| Granting access actions taken | Event type `CLIENT_ACCESS_UPDATED` | A.11 aggregator spec; manual step 2 |
| Exactly which types were granted / revoked | `granted` and `revoked`, computed per `(collection id, type id)` (A.10 step 3) and listed with their collections (B.2) | A.11 delta converter spec; B.3; manual steps 2–3 |
| To whom the types were granted | `resourceName` = contact full name, shown in the Resource column (`auditEventColumns.ts:29-35`); `resourceType` = `CONTACT` | A.11 converter spec; manual step 2 |
| New Event Type `CLIENT_ACCESS_UPDATED`, in the Event Type dropdown | `AUDIT_EVENT_TYPE.CLIENT_ACCESS_UPDATED` (A.10 step 1); `'CLIENT_ACCESS_UPDATED'` in `eventTypes` (C.2) | C.4 constants spec; manual step 4 |
| New Resource Type Contact, in the Resource Type dropdown | `AuditEventResourceType.CONTACT` (A.10 step 1); `'CONTACT'` in `resourceTypes` (C.2). Shown as `CONTACT`, like every other resource type (LD-002) | C.4 constants spec; manual step 4 |
| Path format | europa-back-end branch (B.2); five-line render (C.2) | B.3, C.4; manual step 2 |

---

## Decisions

Locked in the ledger and applied here:

| Ledger | Decision | Consequence in this spec |
| --- | --- | --- |
| LD-001, LD-002 | Event type `CLIENT_ACCESS_UPDATED`; resource type `CONTACT` (upper case, like every resource type; the Resource Type filter is an exact match) | Same literal in Callisto, Atlas and the europa-back-end branch |
| LD-003 | `Case` = case short name, `Job` = job id, `Proceeding` = proceeding `value` | The values the Access Manager overlay shows |
| LD-004, LD-008 | One `CONTACT` resource per save; `resourceName` = contact full name | The path does not repeat the contact |
| LD-005 | Only the save-grants action records | Removing all access is the same action with an empty selection set |
| LD-006, LD-007 | Callisto computes the delta by `(collection id, type id)` and sends names; europa-back-end builds the text | Type names repeat across collections (`DepoView` is in `MP4 Video` and `MPEG Video`), so a name-only diff would be wrong |
| LD-009 | Not gated by `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED` | The flag still gates only the outbox write (`save-ts/…transaction.script.ts:90-98`) |
| LD-010 | A save with no delta still records; both lists read `N/A` | Atlas disables Save when nothing changed, so this is reachable only through the API |
| LD-011 | No chip colour | Grey fallback (`atlas/pages/HomePage/SearchDataGrid/SearchDataGrid.vue:165-167`) |
| LD-012 | No migration, route, DTO or Swagger change; no europa-back-end schema change | The response stays `{ selections }` |
| LD-014, LD-015 | Deploy order; search limitation | See [Rollout](#rollout) and [Known limitations](#known-limitations) |
| LD-016 | The transaction script returns the audit data; the service dispatches through a GCA port after the commit | A.10 steps 5–6 |
| LD-018 | List items: `Collection › Type` or the type alone, joined with `, `; a name containing `,`, `›` or `"` is quoted, with embedded `"` doubled | B.2 `toGrantListDisplay` and `toQuotedName`; B.3 |
| LD-019 | A ` \| ` inside a case or proceeding name is an accepted, documented limitation | [Known limitations](#known-limitations); no code |

Settled by this spec (the ledger's open implementation items):

| # | Decision | Why |
| --- | --- | --- |
| S-01 | The chain lives in a new GCA sub-domain, `cau/`, with its own `ContactAccessAuditModule`. The module imports `AuditsModule`, provides the aggregator, and binds `CLIENT_ACCESS_CONTACT_AUDIT` to it with `useExisting`. `GrantingClientAccessModule` imports the module | A contact record has no proceedings owner, so binding the port in `ProceedingsModule` (as `CLIENT_ACCESS_FILE_AUDIT` is, `src/proceedings/proceedings.module.ts:209-212`) would put contact code in proceedings. A GCA-owned module that depends on neither consumer is the existing cycle-free pattern (`gca/infrastructure/outbox/writers/client-access-outbox/client-access-outbox.module.ts:12-18`). `CaseFileAuditModule` already provides and exports its own aggregator. depcruise treats both `granting-client-access` and `audits` as non-domain modules (`fitness-functions-rules/architecture-rules/cross-module-boundaries/domain-boundaries.rules.ts:27-38`) |
| S-02 | The audit data is built inside the save transaction: the grants before the replace are read in the transaction script, and the names are read after the existence checks | The recategorize transaction script builds its records the same way (`gca/domain/transaction-scripts/…/recategorize-deliverable-files.transaction.script.ts:169-181`). A failure while building rolls back the save, so a committed save never lacks its audit data |
| S-03 | The transaction script reads the previous grants itself; `ValidateClientAccessManagerDeltaPermissions` is unchanged | The validator returns `Promise<void>` and keeps only two booleans (`gca/validators/validate-client-access-manager-delta-permissions.validator.ts:38-83`). Leaving it alone keeps the permission check's contract; the cost is one more indexed read in the same transaction |
| S-04 | `resourcePath` and `resourceBucket` are `''`. The states carry no `path` or `bucket` | A contact has no file path. A record read before the europa-back-end branch is live shows an empty path (europa's default branch, `eu-ts/…transaction.script.ts:110-122`); LD-014 deploys europa-back-end first |
| S-05 | `ContactsService` catches a dispatch rejection, logs it with `contactId` and `proceedingId`, and returns `{ selections }`. A dispatch that resolves `false` is not logged again | The grants are committed by then; an error would tell the user a saved change failed. The SQS producer already logs a failed send and resolves `false` (`src/audits/infrastructure/adapters/outbound/producers/sqs/sqs-audit-event.producer.ts:19-33`). Same handling as INT-141 |
| S-06 | The names come from a new GCA repository, `ContactGrantsAuditContextRepository`, that reads on the transaction's connection | `ContactsRepository.findActiveById` returns the whole entity and does not use `TransactionContext` (`gca-c/infrastructure/repositories/contacts.repository.ts:88-95`). `ProceedingRepository.findProceedingDetailById` selects `case.short_name`, but its projection type leaves the field out (`src/proceedings/infrastructure/repositories/proceeding.repository.ts:28-51`), and changing it means editing proceedings code. `JobDetailRepository` is not exported to GCA (`src/jobs/job.module.ts:62`) |
| S-07 | Atlas: `'CONTACT'` goes first in `resourceTypes`; `'CLIENT_ACCESS_UPDATED'` goes last in `eventTypes` | `resourceTypes` is alphabetical (`atlas/utils/constants.ts:19-25`); `eventTypes` is not, and INT-138 and INT-139 appended to it (`:15-16`) |
| S-08 | No change to `SearchDataGrid.vue` | `MULTI_PART_PATH_TYPES` already gates the five-line render (`SearchDataGrid.vue:90-92`), and only the first `': '` in a segment separates the label (`:80-88`) |
| S-09 | An empty `Access granted` or `Access revoked` list reads `N/A`, including on a save that only grants or only revokes. This is the accepted answer to the QA comment's open question (PDN-1873, [comments](../INT-142-comments.md)) | Precedent: every multi-part branch shows `N/A` for an empty value, because Atlas would otherwise render a label with nothing after it (`eu-ts/…transaction.script.ts:142-146`, comment and `toDisplayValue`); INT-138 LD-013 and INT-139 LD-008 lock the same for a no-change action; ledger LD-010. The user ruled the pending PO clarification not relevant (2026-10-12). The comment's second question, several contacts in one save (PDN-1879), cannot occur: a request carries one `contactId` and one `proceedingId` (`…/save-contact-deliverable-type-grants.request.dto.ts:33-55`; LD-008) |

### Review questions (locked 2026-10-12)

| # | Question | Locked answer | Ledger |
| --- | --- | --- | --- |
| Q-01 | How is each item in `Access granted` / `Access revoked` written, and are names escaped? | `Collection › Type`, or the type alone when the grant has no collection; items joined with `, `. A collection or type name containing `,`, `›` or `"` is wrapped in double quotes, and any embedded `"` is doubled (conventional CSV-style escaping, B.2). Today no name can contain `"` (dynamic collection names reject it, `gca/validators/validate-dynamic-collection-name.validator.ts:7`; deliverable types are seed-only, `gca/infrastructure/repositories/deliverable-type.repository.ts` has reads only). Handling it keeps the formatter correct if validation changes. Readable, keeps the five-part path, and needs no structural change | LD-018 |
| Q-02 | Is a ` \| ` inside a case short name or proceeding name neutralised, or accepted? | Accepted and documented as an inherited limitation (see [Known limitations](#known-limitations)). Replacing `\|` would make the audit display differ from the stored name, and event-specific parsing in Atlas is out of proportion for a low-probability issue every multi-part event shares. Any future fix addresses multi-part paths consistently across event types | LD-019 |

## Known limitations

- **Delivery is best-effort.** Every audit dispatcher sends straight to SQS through `AUDIT_EVENT_PRODUCER_TOKEN`; the producer logs a failed send and resolves `false`. A save can commit with no record if the send fails (a log line is written) or the process stops between the commit and the send.
- **A ` | ` inside a case short name or proceeding name adds a line on the Europa page.** Accepted as an inherited limitation (LD-019); any future fix addresses multi-part paths consistently across event types, not this event alone. Atlas splits the whole path on `' | '` (`SearchDataGrid.vue:80-88`), as it does for every multi-part path; INT-141 bounds the split only for a value that comes last. How a name can get a `|`:
  - **Proceeding names:** File Navigator create and rename reject it (`@NoSpecialChars()`, `src/proceedings/validators/no-special-chars.validator.ts:5`, on `create-proceedings.request.dto.ts:18` and `rename-proceeding.request.dto.ts:18`), and so do both Atlas proceeding forms (regex `/[\\/:*?"<>|%]/` in `atlas-front-end/src/callisto/pages/JobSubmissionPages/sections/FileUploadSection/AddProceedingForm/AddProceedingForm.vue:75-77` and `…/JobDetailPage/components/NewProceedingsOverlay/NewProceedingsOverlay.vue:87-89`). The AJSF create API does not check (`CreateJobSubmissionProceedingsRequestDTO` is `@IsString({ each: true })` only), so only a direct API call can create one.
  - **Case short names:** Callisto never writes cases (no create or update path for `short_name`), so it can't check them.
- **Free-text search** finds these records by contact name and event type, not by case, job, proceeding or deliverable type (LD-015; `eu-ts/converters/search-params-to-mongo-query.converter.ts:80-102`).

---

## Part A — Callisto (`callisto-back-end`)

### A.1 Folder hierarchy

New (`+`) and changed (`~`):

```
src/
├── audits/
│   ├── constants.ts                                                                   ~
│   └── domain/domain-events/audit-event-resource.de.ts                                ~
└── granting-client-access/
    ├── granting-client-access.module.ts                                               ~
    ├── domain/
    │   ├── ports/client-access-contact-audit.port.ts                                  +
    │   └── projections/client-access-updated-audit.projection.ts                      +
    ├── registries/
    │   ├── repository.registry.ts                                                     ~
    │   └── transaction-script.registry.ts                                             ~
    └── contacts/
        ├── domain/
        │   ├── projections/proceeding-audit-context.projection.ts                     +
        │   ├── services/
        │   │   ├── contacts.service.ts                                                ~
        │   │   └── __specs__/contacts.service.spec.ts                                 ~
        │   ├── sub-domains/contact-access-audit/                                      +
        │   │   ├── contact-access-audit.module.ts
        │   │   ├── domain/
        │   │   │   ├── aggregators/
        │   │   │   │   ├── contact-access-audit.aggregator.ts
        │   │   │   │   ├── contact-access-audit.param.ts
        │   │   │   │   └── __specs__/contact-access-audit.aggregator.spec.ts
        │   │   │   └── ports/contact-access-audit-dispatcher.port.ts
        │   │   └── infrastructure/dispatchers/
        │   │       ├── contact-access-audit.dispatcher.ts
        │   │       ├── __specs__/contact-access-audit.dispatcher.spec.ts
        │   │       └── contact-access-to-audit-event-assembler/
        │   │           ├── contact-access-to-audit-event.assembler.ts
        │   │           ├── contact-access-to-audit.converter.ts
        │   │           └── __specs__/
        │   │               ├── contact-access-to-audit-event.assembler.spec.ts
        │   │               └── contact-access-to-audit.converter.spec.ts
        │   └── transaction-scripts/save-contact-deliverable-type-grants-ts/
        │       ├── save-contact-deliverable-type-grants.transaction.script.ts          ~
        │       ├── save-contact-deliverable-type-grants-ts.provider.ts                ~
        │       ├── save-contact-deliverable-type-grants.projection.ts                 +
        │       ├── __specs__/save-contact-deliverable-type-grants.transaction.script.spec.ts  ~
        │       └── contact-grants-audit-assembler/                                    +
        │           ├── contact-grants-audit.assembler.ts
        │           ├── contact-grants-to-audit-delta.converter.ts
        │           └── __specs__/
        │               ├── contact-grants-audit.assembler.spec.ts
        │               └── contact-grants-to-audit-delta.converter.spec.ts
        └── infrastructure/repositories/
            ├── contact-grants-audit-context.repository.ts                             +
            └── __specs__/contact-grants-audit-context.repository.integration.spec.ts  +
```

### A.2 New and changed classes

| Class / type | Path | Change |
| --- | --- | --- |
| `AuditEventResourceType`, `AUDIT_EVENT_TYPE` | `src/audits/constants.ts:3-8`, `:10-21` | Add `CONTACT` and `CLIENT_ACCESS_UPDATED` |
| `ResourceState`, `AuditGrantState` | `src/audits/domain/domain-events/audit-event-resource.de.ts:12-19` | `ResourceState` gains optional `caseShortName`, `jobId`, `proceedingName`, `granted`, `revoked`. New exported `AuditGrantState` |
| `ClientAccessUpdatedAuditProjection`, `ClientAccessAuditGrant` | `gca/domain/projections/client-access-updated-audit.projection.ts` | **New** |
| `ClientAccessContactAuditPort`, `CLIENT_ACCESS_CONTACT_AUDIT`, `ClientAccessUpdatedAuditParams` | `gca/domain/ports/client-access-contact-audit.port.ts` | **New.** Sibling of `client-access-file-audit.port.ts` |
| `ProceedingAuditContextProjection` | `gca-c/domain/projections/proceeding-audit-context.projection.ts` | **New** |
| `ContactGrantsAuditContextRepository` | `gca-c/infrastructure/repositories/contact-grants-audit-context.repository.ts` | **New.** Reads the contact's full name and the proceeding's case short name, job id and name |
| `ContactGrantsToAuditDeltaConverter` | `save-ts/contact-grants-audit-assembler/contact-grants-to-audit-delta.converter.ts` | **New.** Pure: before and after grants to `granted` / `revoked` |
| `ContactGrantsAuditAssembler` | `save-ts/contact-grants-audit-assembler/contact-grants-audit.assembler.ts` | **New.** Reads the names and runs the delta converter |
| `SaveContactDeliverableTypeGrantsProjection` | `save-ts/save-contact-deliverable-type-grants.projection.ts` | **New.** The transaction script's result: `selections` plus `audit` |
| `SaveContactDeliverableTypeGrantsTS` | `save-ts/save-contact-deliverable-type-grants.transaction.script.ts` | Injects the assembler; reads the previous grants before the replace; returns `audit` |
| `createSaveContactDeliverableTypeGrantsTSProvider` | `save-ts/save-contact-deliverable-type-grants-ts.provider.ts:21-61` | Passes the assembler to the constructor |
| `ContactsService` | `gca-c/domain/services/contacts.service.ts` | Injects the port; dispatches after the transaction script resolves; returns `{ selections }` |
| `ContactAccessAuditAggregator` | `cau/domain/aggregators/contact-access-audit.aggregator.ts` | **New.** `implements ClientAccessContactAuditPort` |
| `ContactAccessAuditParams` | `cau/domain/aggregators/contact-access-audit.param.ts` | **New** |
| `ContactAccessAuditDispatcherPort`, `CONTACT_ACCESS_AUDIT_DISPATCHER` | `cau/domain/ports/contact-access-audit-dispatcher.port.ts` | **New** |
| `ContactAccessAuditDispatcher` | `cau/infrastructure/dispatchers/contact-access-audit.dispatcher.ts` | **New** |
| `ContactAccessToAuditEventAssembler` | `cau/infrastructure/dispatchers/contact-access-to-audit-event-assembler/contact-access-to-audit-event.assembler.ts` | **New** |
| `ContactAccessToAuditEventResourceConverter` | `cau/infrastructure/dispatchers/contact-access-to-audit-event-assembler/contact-access-to-audit.converter.ts` | **New** |
| `ContactAccessAuditModule` | `cau/contact-access-audit.module.ts` | **New** |

**Unchanged:** `SaveContactDeliverableTypeGrantsAction`, its request and response DTOs and Swagger; `ValidateClientAccessManagerDeltaPermissions`; `DeliverableAccessGrantRepository`; `ContactDeliverableTypeGrantsToReplacedOutboxConverter`; the case-group save path.

### A.3–A.6 Entities and migrations

N/A: no table, entity or migration change. `TypeOrmModule.forFeature` in `GrantingClientAccessModule` already registers `Contact`, `Case`, `Job` and `Proceeding` (`gca/granting-client-access.module.ts:84-101`).

### A.7 DTOs

N/A. `SaveContactDeliverableTypeGrantsRequestDTO`, `ContactDeliverableTypeGrantsResponseDTO` and `SaveContactDeliverableTypeGrantsSwagger` are unchanged; the service strips `audit` before the action returns (A.10 step 6).

### A.8 Projections, params and ports

```ts
// CHANGED src/audits/constants.ts
export const AuditEventResourceType = {
	FILE: 'FILE',
	PROCEEDING: 'PROCEEDING',
	FOLDER: 'FOLDER',
	PERMISSION: 'PERMISSION',
	CONTACT: 'CONTACT',
} as const;

export const AUDIT_EVENT_TYPE = {
	// … existing entries (:11-20) unchanged
	RECATEGORIZE: 'RECATEGORIZE',
	CLIENT_ACCESS_UPDATED: 'CLIENT_ACCESS_UPDATED',
} as const;
```

```ts
// CHANGED src/audits/domain/domain-events/audit-event-resource.de.ts
/** One deliverable type in a CLIENT_ACCESS_UPDATED record; collection is null for a track-level grant. */
export type AuditGrantState = {
	readonly deliverableType: string;
	readonly collection: string | null;
};

type ResourceState = {
	path?: string;
	bucket?: string;
	value?: string;
	fileName?: string;
	deliverableType?: string | null;
	collection?: string | null;
	caseShortName?: string | null;
	jobId?: number | null;
	proceedingName?: string | null;
	granted?: readonly AuditGrantState[];
	revoked?: readonly AuditGrantState[];
};
```

```ts
// NEW gca/domain/projections/client-access-updated-audit.projection.ts
/** One deliverable type granted or revoked, by name. `collection` is null for a track-level grant. */
export type ClientAccessAuditGrant = {
	readonly deliverableType: string;
	readonly collection: string | null;
};

/** The CLIENT_ACCESS_UPDATED record for one save of one contact's grants on one proceeding. */
export type ClientAccessUpdatedAuditProjection = {
	readonly contact: { readonly id: number; readonly fullName: string };
	readonly proceeding: { readonly id: number; readonly value: string | null };
	readonly jobId: number | null;
	readonly caseShortName: string | null;
	readonly granted: readonly ClientAccessAuditGrant[];
	readonly revoked: readonly ClientAccessAuditGrant[];
};
```

```ts
// NEW gca/domain/ports/client-access-contact-audit.port.ts
import type { AuthUser } from 'src/generic/auth/constants';
import type { ClientAccessUpdatedAuditProjection } from 'src/granting-client-access/domain/projections/client-access-updated-audit.projection';

export const CLIENT_ACCESS_CONTACT_AUDIT = Symbol('CLIENT_ACCESS_CONTACT_AUDIT');

export type ClientAccessUpdatedAuditParams = ClientAccessUpdatedAuditProjection & {
	readonly user: Partial<AuthUser>;
};

/** Resolves false when the record was not accepted for delivery. */
export type ClientAccessContactAuditPort = {
	dispatchClientAccessUpdatedEvent(
		params: ClientAccessUpdatedAuditParams,
	): Promise<boolean>;
};
```

```ts
// NEW gca-c/domain/projections/proceeding-audit-context.projection.ts
export type ProceedingAuditContextProjection = {
	readonly proceedingValue: string;
	readonly jobId: number;
	/** Null when the job has no case (`Job.caseId` is nullable). */
	readonly caseShortName: string | null;
};
```

```ts
// NEW save-ts/save-contact-deliverable-type-grants.projection.ts
import type { ClientAccessUpdatedAuditProjection } from 'src/granting-client-access/domain/projections/client-access-updated-audit.projection';
import type { ContactDeliverableTypeGrantsResult } from '../../projections/contact-deliverable-type-grant.projection';

/** The save's result: the saved grants, and the audit record the service dispatches once it commits. */
export type SaveContactDeliverableTypeGrantsProjection = ContactDeliverableTypeGrantsResult & {
	readonly audit: ClientAccessUpdatedAuditProjection;
};
```

```ts
// NEW cau/domain/aggregators/contact-access-audit.param.ts
import type { AUDIT_EVENT_TYPE } from 'src/audits/constants';
import type { ClientAccessUpdatedAuditParams } from 'src/granting-client-access/domain/ports/client-access-contact-audit.port';

export type ContactAccessAuditParams = ClientAccessUpdatedAuditParams & {
	readonly eventType: typeof AUDIT_EVENT_TYPE.CLIENT_ACCESS_UPDATED;
};
```

```ts
// NEW cau/domain/ports/contact-access-audit-dispatcher.port.ts
import type { ContactAccessAuditParams } from '../aggregators/contact-access-audit.param';

export const CONTACT_ACCESS_AUDIT_DISPATCHER = Symbol('CONTACT_ACCESS_AUDIT_DISPATCHER');

export type ContactAccessAuditDispatcherPort = {
	apply(input: ContactAccessAuditParams): Promise<boolean>;
};
```

### A.9 Module wiring

```ts
// NEW cau/contact-access-audit.module.ts
@Module({
	imports: [AuditsModule],
	providers: [
		{
			provide: CONTACT_ACCESS_AUDIT_DISPATCHER,
			useClass: ContactAccessAuditDispatcher,
		},
		ContactAccessToAuditEventAssembler,
		ContactAccessToAuditEventResourceConverter,
		ContactAccessAuditAggregator,
		{
			provide: CLIENT_ACCESS_CONTACT_AUDIT,
			useExisting: ContactAccessAuditAggregator,
		},
	],
	exports: [CLIENT_ACCESS_CONTACT_AUDIT],
})
export class ContactAccessAuditModule {}
```

- `GrantingClientAccessModule` adds `ContactAccessAuditModule` to `imports`, after `ProceedingGrantExistenceModule` (`gca/granting-client-access.module.ts:111`). It does not need to export it.
- `gca/registries/repository.registry.ts`: add `ContactGrantsAuditContextRepository` after `AccessManagerWarningsRepository` (`:29`).
- `gca/registries/transaction-script.registry.ts`: add `ContactGrantsAuditAssembler` and `ContactGrantsToAuditDeltaConverter` next to `FileCategorizationAuditAssembler` (`:132-133`).
- `createSaveContactDeliverableTypeGrantsTSProvider` (`save-ts/save-contact-deliverable-type-grants-ts.provider.ts`): add `ContactGrantsAuditAssembler` in all three places: the `useFactory` parameters, the `new SaveContactDeliverableTypeGrantsTS(...)` call (`:21-47`), and the `inject` array, after `ValidateClientAccessManagerDeltaPermissions` (`:49-60`). The transaction script is provided only through this factory (`gca/granting-client-access.module.ts:153`), not the registry.

### A.10 Implementation

**1. Constants and state type.** As in A.8.

**2. Repository.** Reads on the transaction's connection, as `DeliverableAccessGrantRepository` does (`gca-c/infrastructure/repositories/deliverable-access-grant.repository.ts:51-53`).

```ts
// NEW gca-c/infrastructure/repositories/contact-grants-audit-context.repository.ts
@Injectable()
export class ContactGrantsAuditContextRepository {
	constructor(
		@InjectRepository(Contact)
		private readonly defaultContactRepo: Repository<Contact>,
		@InjectRepository(Proceeding)
		private readonly defaultProceedingRepo: Repository<Proceeding>,
		private readonly transactionContext: TransactionContext,
	) {}

	private get contactRepo(): Repository<Contact> {
		return this.transactionContext.resolveRepository(this.defaultContactRepo);
	}

	private get proceedingRepo(): Repository<Proceeding> {
		return this.transactionContext.resolveRepository(this.defaultProceedingRepo);
	}

	async findContactFullName(contactId: number): Promise<string | null> {
		const row = await this.contactRepo
			.createQueryBuilder('contact')
			.where('contact.id = :contactId', { contactId })
			.select('contact.full_name', 'fullName')
			.getRawOne<{ fullName: string }>();
		return row?.fullName ?? null;
	}

	async findProceedingContext(
		proceedingId: number,
	): Promise<ProceedingAuditContextProjection | null> {
		const row = await this.proceedingRepo
			.createQueryBuilder('proceeding')
			.innerJoin(Job, 'job', 'job.id = proceeding.job_id')
			.leftJoin(Case, 'case', 'case.id = job.case_id')
			.where('proceeding.id = :proceedingId', { proceedingId })
			.select([
				'proceeding.value AS "proceedingValue"',
				'job.id AS "jobId"',
				'case.short_name AS "caseShortName"',
			])
			.getRawOne<{ proceedingValue: string; jobId: number | string; caseShortName: string | null }>();
		if (!row) return null;
		return {
			proceedingValue: row.proceedingValue,
			jobId: Number(row.jobId),
			caseShortName: row.caseShortName ?? null,
		};
	}
}
```

The join chain and the `Job` / `Case` entity imports are the ones `AccessManagerWarningsRepository.findCaseWarnings` uses (`gca-c/infrastructure/repositories/access-manager-warnings.repository.ts:48-67`). `Contact.fullName` is a non-null column (`src/shared/shared-entities/entities/contacts/contact.entity.ts:27-28`).

**3. Delta converter.** The key is the one `buildSelectionKey` builds (`save-ts/…transaction.script.ts:25-28`). That function is module-private in four files, so this converter keeps its own copy rather than changing the others. Order follows the repository read: collection id, then type id (`deliverable-access-grant.repository.ts:55-74`).

```ts
// NEW save-ts/contact-grants-audit-assembler/contact-grants-to-audit-delta.converter.ts
type GrantDeltaInput = {
	readonly previous: readonly ContactDeliverableTypeGrantProjection[];
	readonly current: readonly ContactDeliverableTypeGrantProjection[];
};

type GrantDelta = {
	readonly granted: ClientAccessAuditGrant[];
	readonly revoked: ClientAccessAuditGrant[];
};

const toGrantKey = (grant: ContactDeliverableTypeGrantProjection): string =>
	`${grant.deliverableCollectionId ?? 'none'}:${grant.deliverableTypeId}`;

const toAuditGrant = (
	grant: ContactDeliverableTypeGrantProjection,
): ClientAccessAuditGrant => ({
	deliverableType: grant.deliverableTypeValue,
	collection: grant.deliverableCollectionValue,
});

@Injectable()
export class ContactGrantsToAuditDeltaConverter {
	/** Granted = after but not before; revoked = before but not after, each named from its own side. */
	apply({ previous, current }: GrantDeltaInput): GrantDelta {
		const previousKeys = new Set(previous.map(toGrantKey));
		const currentKeys = new Set(current.map(toGrantKey));
		return {
			granted: current
				.filter((grant) => !previousKeys.has(toGrantKey(grant)))
				.map(toAuditGrant),
			revoked: previous
				.filter((grant) => !currentKeys.has(toGrantKey(grant)))
				.map(toAuditGrant),
		};
	}
}
```

**4. Audit assembler.** Runs inside the save transaction, after the replace (S-02).

```ts
// NEW save-ts/contact-grants-audit-assembler/contact-grants-audit.assembler.ts
export type ContactGrantsAuditAssemblerInput = {
	readonly contactId: number;
	readonly proceedingId: number;
	readonly previous: readonly ContactDeliverableTypeGrantProjection[];
	readonly current: readonly ContactDeliverableTypeGrantProjection[];
};

@Injectable()
export class ContactGrantsAuditAssembler {
	constructor(
		private readonly contactGrantsAuditContextRepository: ContactGrantsAuditContextRepository,
		private readonly contactGrantsToAuditDeltaConverter: ContactGrantsToAuditDeltaConverter,
	) {}

	/** Callers run it inside the save's transaction, after the replace. */
	async apply(
		input: ContactGrantsAuditAssemblerInput,
	): Promise<ClientAccessUpdatedAuditProjection> {
		const fullName =
			await this.contactGrantsAuditContextRepository.findContactFullName(input.contactId);
		const context =
			await this.contactGrantsAuditContextRepository.findProceedingContext(input.proceedingId);
		const { granted, revoked } = this.contactGrantsToAuditDeltaConverter.apply({
			previous: input.previous,
			current: input.current,
		});
		return {
			contact: { id: input.contactId, fullName: fullName ?? '' },
			proceeding: { id: input.proceedingId, value: context?.proceedingValue ?? null },
			jobId: context?.jobId ?? null,
			caseShortName: context?.caseShortName ?? null,
			granted,
			revoked,
		};
	}
}
```

The reads run one after the other: both use the transaction's single connection. A missing row can't happen after the existence checks in the same transaction; it falls back to empty values instead of throwing, so it can't roll back a save.

**5. Transaction script.** Two additions to `apply` (`save-ts/…transaction.script.ts:46-101`); everything else is unchanged.

```ts
// CHANGED save-ts/save-contact-deliverable-type-grants.transaction.script.ts
// constructor: add after validateDeltaPermissions (:43)
		private readonly contactGrantsAuditAssembler: ContactGrantsAuditAssembler,

	@Transactional()
	@TraceSpan()
	async apply(
		params: SaveContactDeliverableTypeGrantsParams,
	): Promise<SaveContactDeliverableTypeGrantsProjection> {
		// … logging, dedupe, delta permission check, existence checks and
		// validateSelections unchanged (:51-75)

		const previousSelections =
			await this.grantRepository.findByContactAndProceeding({
				contactId: params.contactId,
				proceedingId: params.proceedingId,
			});

		// … replaceForContactAndProceeding, the re-read into `selections`
		// and the flag-gated outbox write unchanged (:77-98)

		const audit = await this.contactGrantsAuditAssembler.apply({
			contactId: params.contactId,
			proceedingId: params.proceedingId,
			previous: previousSelections,
			current: selections,
		});

		return { selections, audit };
	}
```

The previous-grants read comes after the permission and existence checks, so a rejected request reads nothing new. It runs before `replaceForContactAndProceeding` in the same transaction.

**6. Service.**

```ts
// CHANGED gca-c/domain/services/contacts.service.ts
// constructor: add after featureFlagAggregator (:40)
		@Inject(CLIENT_ACCESS_CONTACT_AUDIT)
		private readonly clientAccessContactAudit: ClientAccessContactAuditPort,

	@TraceSpan()
	async saveContactDeliverableTypeGrants(
		command: SaveContactDeliverableTypeGrantsCommand,
	): Promise<ContactDeliverableTypeGrantsResult> {
		// … debug log and flag read unchanged (:70-79)
		const { selections, audit } =
			await this.saveContactDeliverableTypeGrantsTS.apply({
				...command,
				isGrantingClientAccessEnabled,
			});
		await this.dispatchClientAccessUpdatedAudit(audit, command.user);
		return { selections };
	}

	/** Runs after the grants are committed, so an error is logged, not thrown. */
	private async dispatchClientAccessUpdatedAudit(
		audit: ClientAccessUpdatedAuditProjection,
		user: AuthUser,
	): Promise<void> {
		try {
			await this.clientAccessContactAudit.dispatchClientAccessUpdatedEvent({
				...audit,
				user,
			});
		} catch (error) {
			this.logger.error(
				'Failed to dispatch CLIENT_ACCESS_UPDATED audit record',
				error instanceof Error ? error : null,
				{ contactId: audit.contact.id, proceedingId: audit.proceeding.id },
			);
		}
	}
```

- The transaction commits when the proxied `apply` resolves (`src/typeorm/infrastructure/factories/transactional-proxy.factory.ts:9-47`), so the dispatch is after the commit. A rejected `apply` dispatches nothing.
- The `logger.error` call shape matches the module's existing calls (`gca-c/domain/transaction-scripts/search-contacts-ts/search-contacts.transaction.script.ts:45-49`).

**7. Aggregator, dispatcher, event assembler, converter.** Same shape as `proceeding-audit/` (`src/proceedings/domain/sub-domains/proceeding-audit/`).

```ts
// NEW cau/domain/aggregators/contact-access-audit.aggregator.ts
@Injectable()
export class ContactAccessAuditAggregator implements ClientAccessContactAuditPort {
	constructor(
		@Inject(CONTACT_ACCESS_AUDIT_DISPATCHER)
		private readonly contactAccessAuditDispatcher: ContactAccessAuditDispatcherPort,
	) {}

	async dispatchClientAccessUpdatedEvent(
		params: ClientAccessUpdatedAuditParams,
	): Promise<boolean> {
		return this.contactAccessAuditDispatcher.apply({
			...params,
			eventType: AUDIT_EVENT_TYPE.CLIENT_ACCESS_UPDATED,
		});
	}
}
```

```ts
// NEW cau/infrastructure/dispatchers/contact-access-audit.dispatcher.ts
@Injectable()
export class ContactAccessAuditDispatcher implements ContactAccessAuditDispatcherPort {
	constructor(
		private readonly contactAccessToAuditEventAssembler: ContactAccessToAuditEventAssembler,
		@Inject(AUDIT_EVENT_PRODUCER_TOKEN)
		private readonly auditEventProducer: ProducerInterface<AuditEventDomainEvent>,
		private readonly auditConfigAccessor: AuditConfigAccessor,
	) {}

	async apply(input: ContactAccessAuditParams): Promise<boolean> {
		const auditEvent = this.contactAccessToAuditEventAssembler.apply(input);
		return await this.auditEventProducer.apply(
			this.auditConfigAccessor.sqsAuditEventUrl,
			auditEvent,
		);
	}
}
```

```ts
// NEW cau/infrastructure/dispatchers/contact-access-to-audit-event-assembler/contact-access-to-audit-event.assembler.ts
@Injectable()
export class ContactAccessToAuditEventAssembler {
	constructor(
		private readonly auditConfigAccessor: AuditConfigAccessor,
		private readonly contactAccessToAuditEventResourceConverter: ContactAccessToAuditEventResourceConverter,
	) {}

	apply(input: ContactAccessAuditParams): AuditEventDomainEvent {
		return {
			id: uuidv4(),
			createdAt: new Date(),
			serviceName: this.auditConfigAccessor.serviceName,
			type: input.eventType,
			identity: input.user.identity,
			auditEventResources: [
				this.contactAccessToAuditEventResourceConverter.apply(input),
			],
		};
	}
}
```

```ts
// NEW cau/infrastructure/dispatchers/contact-access-to-audit-event-assembler/contact-access-to-audit.converter.ts
/** Europa builds the display path, so this converter sends raw state values. */
@Injectable()
export class ContactAccessToAuditEventResourceConverter {
	apply(input: ClientAccessUpdatedAuditProjection): AuditEventResourceDomainEvent {
		const state: AuditEventResourceDomainEvent['newState'] = {
			caseShortName: input.caseShortName,
			jobId: input.jobId,
			proceedingName: input.proceeding.value,
			granted: input.granted,
			revoked: input.revoked,
		};
		return {
			id: input.contact.id.toString(),
			resourceType: AuditEventResourceType.CONTACT,
			resourceId: input.contact.id.toString(),
			resourceName: input.contact.fullName,
			resourcePath: '',
			resourceBucket: '',
			oldState: state,
			newState: state,
		};
	}
}
```

### A.11 Spec tests

Conventions: `__specs__/<file>.spec.ts`, `given:` / `when:` / `then:`, `// Arrange` `// Act` `// Assert`, `target`, `*Mock` names, `createMock` / `createApplyMock` from `src/test-utils/test-utils.ts`, `createMockAuthUser` from `src/generic/auth/test-utils.ts`.

| Spec | Cases |
| --- | --- |
| `gca-c/domain/services/__specs__/contacts.service.spec.ts` (provide `CLIENT_ACCESS_CONTACT_AUDIT` as `createMock<ClientAccessContactAuditPort>({ dispatchClientAccessUpdatedEvent: jest.fn().mockResolvedValue(true) })`) | **Happy:** dispatches once with the transaction script's `audit` and `command.user`, after the transaction script (`invocationCallOrder`, as in `recategorize-deliverable-files.service.spec.ts:199-206`); returns `{ selections }` with no `audit` key. **Flag off:** still dispatches (LD-009). **Failure:** the transaction script rejects: the error propagates and nothing is dispatched. **Graceful:** the dispatch rejects: `{ selections }` is returned and `logger.error` is called with `contactId` and `proceedingId`. The dispatch resolves `false`: `{ selections }` is returned and `logger.error` is not called |
| `save-ts/__specs__/save-contact-deliverable-type-grants.transaction.script.spec.ts` (add `createApplyMock<ContactGrantsAuditAssembler>()`) | **Happy:** `findByContactAndProceeding` is called before `replaceForContactAndProceeding` and again after it; the assembler gets the first read as `previous` and the second as `current`; the result is `{ selections, audit }`. **Flag off:** the assembler still runs. **Empty selection set:** the assembler still runs with `current` from the re-read. **Failure:** delta permission check, contact check, proceeding check or a selection check fails: no previous-grants read, no replace, no assemble. The replace rejects: no assemble, the error propagates. The assembler rejects: the error propagates (the transaction rolls back). Existing cases keep passing with the assembler mocked; any assertion that `findByContactAndProceeding` was called once becomes twice |
| `save-ts/contact-grants-audit-assembler/__specs__/contact-grants-to-audit-delta.converter.spec.ts` (real converter) | Added only; removed only; both; no change (both lists empty); empty before (all granted); empty after (all revoked). A track-level grant (null collection) gives `collection: null`. `DepoView` in `MP4 Video` replaced by `DepoView` in `MPEG Video` gives one granted and one revoked item. A revoked item takes its names from `previous`. Order follows the input order |
| `save-ts/contact-grants-audit-assembler/__specs__/contact-grants-audit.assembler.spec.ts` (repository via `createMock`, real delta converter) | **Happy:** reads the contact full name and the proceeding context once each with the given ids; returns contact, proceeding, job id, case short name and the converter's lists. **Edge:** no case: `caseShortName` null. **Graceful:** no contact row: `fullName` `''`; no proceeding row: `proceeding.value`, `jobId` and `caseShortName` null, and nothing throws. **Failure:** a repository rejection propagates |
| `gca-c/infrastructure/repositories/__specs__/contact-grants-audit-context.repository.integration.spec.ts` (`createRepositoryTestContext`, as `deliverable-access-grant.repository.integration.spec.ts` does; seed a contact, case, job and proceeding with the existing seed helpers, adding one where none exists) | `findContactFullName` returns the full name, or `null` for an unknown id. `findProceedingContext` returns proceeding name, job id (a number) and case short name; `caseShortName` is `null` for a job with no case; `null` for an unknown proceeding id |
| `cau/domain/aggregators/__specs__/contact-access-audit.aggregator.spec.ts` | Calls the dispatcher once with the params and `eventType: 'CLIENT_ACCESS_UPDATED'`; returns its result, `true` or `false`; a dispatcher rejection propagates |
| `cau/infrastructure/dispatchers/__specs__/contact-access-audit.dispatcher.spec.ts` (producer via `createApplyMock`, `AuditConfigAccessor` as `{ sqsAuditEventUrl: 'test-queue-url' }`) | Sends the assembled event to `'test-queue-url'` and returns `true`; returns `false` when the producer does; an assembler throw and a producer rejection propagate |
| `cau/…/__specs__/contact-access-to-audit-event.assembler.spec.ts` (`jest.mock('uuid')`, fake timers, converter via `createApplyMock`) | Envelope `{ id, createdAt, serviceName, type: 'CLIENT_ACCESS_UPDATED', identity: params.user.identity, auditEventResources: [converter result] }`; the converter gets the params |
| `cau/…/__specs__/contact-access-to-audit.converter.spec.ts` (real converter) | `resourceType` `CONTACT`; `id` = `resourceId` = contact id as a string; `resourceName` = full name; `resourcePath` and `resourceBucket` `''`; `oldState` equals `newState`; the state carries `caseShortName`, `jobId`, `proceedingName`, `granted`, `revoked` as given, including `collection: null`, a null `caseShortName`, and empty lists as `[]` |

### A.12 Neighbors that must not change

- The save-grants response is `{ selections }` with the same items (`SaveContactDeliverableTypeGrantsAction` spec; `ContactDeliverableTypeGrantsResponseDTO`).
- The `grants.replaced.v1` outbox write: same payload, still only for flagged users (`save-ts/…transaction.script.ts:90-98`; existing `'when: the granting client access flag is off'` case).
- The permission check still runs first, so an unauthorised caller gets a 403 before learning whether the contact or proceeding exists (`:59-66`), and no record is sent.
- `GET` grants, the client access list, the warnings route and the case-group save path send no record.
- Existing `CATEGORIZE`, `RECATEGORIZE`, `CREATED` and `RENAMED` records: no shared converter or dispatcher changes. `ResourceState` gains optional fields only.

---

## Part B — Europa (`europa-back-end`)

### B.1 Changed files

```
src/audits-event/
├── domain/entities/audit-event/audit-event-resource.entity.ts                            ~
└── domain/transaction-scripts/search-audit-events-paginated-TS/
    ├── search-audit-events-paginated.transaction.script.ts                               ~
    └── __specs__/search-audit-events-paginated.transaction.script.spec.ts                ~
```

Migrations, DTOs, schema and ingest: N/A.

- **Ingest:** there is no allow-list for `type` or `resourceType`; the SQS listener passes the parsed body straight to the repository (`eu/application/listeners/sqs-audit-event.listener.ts:15-33`).
- **Schema:** `AuditEventResource` has no `@Schema()`, so each resource is stored as sent, nested lists and `collection: null` included. Unknown top-level fields would be dropped (`strict`), which is why the new values travel inside `oldState` / `newState`.
- **Search filters:** `type` and `resourceType` are `@IsString()` only and are exact matches (`eu/application/actions/search-audits-paginated/search-audit-events-paginated.request.dto.ts:55-63`; `eu-ts/converters/search-params-to-mongo-query.converter.ts:33-46`).

### B.2 Implementation

```ts
// CHANGED eu/domain/entities/audit-event/audit-event-resource.entity.ts
/** One deliverable type in a CLIENT_ACCESS_UPDATED record; collection is null for a track-level grant. */
export type ClientAccessGrantState = {
	deliverableType: string;
	collection: string | null;
};

// add to both the oldState (:17-22) and newState (:25-31) types:
		caseShortName?: string | null;
		jobId?: number | null;
		proceedingName?: string | null;
		granted?: ClientAccessGrantState[];
		revoked?: ClientAccessGrantState[];
```

Next to the existing constants (`eu-ts/search-audit-events-paginated.transaction.script.ts:13-17`):

```ts
const CLIENT_ACCESS_UPDATED = 'CLIENT_ACCESS_UPDATED';
// One item per grant, "Collection › Type", or the type alone for a
// track-level grant. Neither may be ' | ', which Atlas splits segments on.
const GRANT_COLLECTION_SEPARATOR = ' › ';
const GRANT_LIST_SEPARATOR = ', ';
// A name holding either separator character, or a quote, is quoted so the
// list can't be misread.
const NAME_NEEDS_QUOTING = /[,›"]/;
```

In `toItemProjection`, after the `CREATED` + `PROCEEDING` branch (`:101-109`) and before the default branch (`:110`):

```ts
} else if (
	event.type === CLIENT_ACCESS_UPDATED &&
	event.auditEventResources?.length
) {
	const state = firstResource?.newState ?? firstResource?.oldState;
	path = [
		`Case: ${this.toDisplayValue(state?.caseShortName)}`,
		`Job: ${this.toDisplayValue(state?.jobId?.toString())}`,
		`Proceeding: ${this.toDisplayValue(state?.proceedingName)}`,
		`Access granted: ${this.toGrantListDisplay(state?.granted)}`,
		`Access revoked: ${this.toGrantListDisplay(state?.revoked)}`,
	].join(' | ');
	bucket = '';
}
```

After `toDisplayValue` (`:142-146`):

```ts
// A list renders as one value after its label, so an empty or missing list
// reads N/A like any other empty value.
private toGrantListDisplay(grants?: ClientAccessGrantState[] | null): string {
	const items = (grants ?? [])
		.filter((grant) => grant?.deliverableType?.trim())
		.map((grant) => {
			const type = this.toQuotedName(grant.deliverableType);
			return grant.collection?.trim()
				? `${this.toQuotedName(grant.collection)}${GRANT_COLLECTION_SEPARATOR}${type}`
				: type;
		});
	return items.length ? items.join(GRANT_LIST_SEPARATOR) : 'N/A';
}

// CSV-style: wrap in double quotes and double any embedded quote. No name can
// hold a quote today, but the escape keeps the list unambiguous if that changes.
private toQuotedName(name: string): string {
	return NAME_NEEDS_QUOTING.test(name) ? `"${name.replace(/"/g, '""')}"` : name;
}
```

Case short name, job and proceeding name are not quoted: each is the only value in its segment, so a `,`, `›` or `"` in it can't be misread.

### B.3 Spec tests

| Spec | Cases |
| --- | --- |
| `eu-ts/__specs__/search-audit-events-paginated.transaction.script.spec.ts`, new `describe('when: apply maps a CLIENT_ACCESS_UPDATED audit event')` (fixtures via `createMockAuditEvent` and a `CONTACT` resource, like the `CATEGORIZE` cases at `:290-440`) | Full path: `Case: Smith v. Jones \| Job: 5512 \| Proceeding: Day 1 \| Access granted: MP4 Video › DepoView, Planet Draft \| Access revoked: Full Transcript › LEF (LiveNote)`, bucket `''`. A null collection renders the type alone. An empty `granted` and an empty `revoked` each render `N/A`. Missing lists render `N/A`. A null case short name, null job id or blank proceeding name renders `N/A` on that segment. Type names with ` - `, `/` and parentheses pass through unquoted (`Errata Sheet - Blank`, `Certificate/Filing Notice`, `CMS (Trial Director)`). **Quoting (LD-018):** collection `Smith, Day 1` renders `"Smith, Day 1" › DepoView`; collection `Day 1 › Rough` renders `"Day 1 › Rough" › DepoView`; a name with an embedded quote, `Exhibit "A"`, renders `"Exhibit ""A"""`; a type name needing quotes is quoted on its own side only; a case short name or proceeding name containing `,` is not quoted. Falls back to `oldState` when `newState` is missing. No resources: the default branch's empty path |

### B.4 Neighbors that must not change

- `PERMISSIONS_UPDATED`, `CATEGORIZE`, `RECATEGORIZE`, `CREATED` + `PROCEEDING`, and the default branch (existing cases from `:290`).
- `/search`, the search filters and free-text fields.

---

## Part C — Atlas (`atlas-front-end`, Europa audit page)

### C.1 Changed files

```
src/europa/
├── utils/constants.ts                                                                   ~
├── utils/__specs__/constants.spec.ts                                                    ~
└── pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts                       ~
```

### C.2 Implementation

```ts
// CHANGED atlas/utils/constants.ts
export const eventTypes = [
  // … existing entries (:4-16) unchanged
  'RECATEGORIZE',
  'CLIENT_ACCESS_UPDATED',
];

export const resourceTypes = [
  'CONTACT',
  'FILE',
  'FOLDER',
  'PERMISSION',
  'PROCEEDING',
  'USER',
];

export const MULTI_PART_PATH_TYPES: ReadonlySet<string> = new Set([
  'PERMISSIONS_UPDATED',
  'CATEGORIZE',
  'RECATEGORIZE',
  'CLIENT_ACCESS_UPDATED',
]);
```

- **Dropdowns:** `SearchFilters.vue` passes both arrays as plain-string options (`atlas/pages/HomePage/SearchFilters/SearchFilters.vue:248-280`). The Europa page has no i18n, so the label is the raw string.
- **Filter values** go to europa-back-end unchanged (`atlas/pages/HomePage/requests/fetchAuditEvents.ts:26-31`).
- **Rendering:** no change (S-08). `hasMultiPartPath` returns true for `CLIENT_ACCESS_UPDATED` whatever the resource type (`SearchDataGrid.vue:90-92`). The splitter keeps everything after a segment's first `': '` as its value (`:80-88`), so `Access granted: MP4 Video › DepoView, Planet Draft` renders as one line.
- **Chip:** grey fallback (LD-011).

### C.3–C.8 Entities, migrations, DTOs, projections

N/A: front-end only. `SearchAuditEventItem` types `type` and `resourceType` as `string` (`atlas/types/audit-event.types.ts:5-19`).

### C.9 Spec tests

| Spec | Cases |
| --- | --- |
| `atlas/utils/__specs__/constants.spec.ts` | `eventTypes` lists `CLIENT_ACCESS_UPDATED` exactly once; `resourceTypes` lists `CONTACT` exactly once; `MULTI_PART_PATH_TYPES` includes `CLIENT_ACCESS_UPDATED`. **Update** `'then: should hold only CATEGORIZE, PERMISSIONS_UPDATED and RECATEGORIZE'` (`:53-63`) to the four sorted entries. The existing no-duplicates case covers the new entries |
| `atlas/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts` | `CLIENT_ACCESS_UPDATED` + `CONTACT` renders five lines with bold labels `Case`, `Job`, `Proceeding`, `Access granted`, `Access revoked`, in order, with the values after the labels (`buildEvent`, `findPathLines`, `findPathLabels`). `Access revoked: N/A` renders as one line with value `N/A`. The type chip shows `CLIENT_ACCESS_UPDATED` in the grey fallback colour |

### C.10 Neighbors that must not change

- `CATEGORIZE`, `RECATEGORIZE`, `PERMISSIONS_UPDATED` and `CREATED` + `PROCEEDING` rendering (existing `SearchDataGrid.spec.ts` cases).
- Chip colours of existing types; the route permission, `AUDIT` + `READ`.

---

## Cross-cutting

- **Companion tickets:**
  - INT-141 (open, europa #75 and its Callisto and Atlas PRs): changes `SearchDataGrid.vue` and adds `MULTI_PART_PATH_MAX_SEGMENTS` to `atlas/utils/constants.ts`. INT-142 changes `constants.ts` too. Whichever merges second resolves adjacent-line conflicts; the two changes are independent.
  - INT-138 to INT-140 (merged): the europa-back-end branches, `toDisplayValue`, `MULTI_PART_PATH_TYPES` and the multi-line render this spec extends.
- **Feature flags:** none. `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED` is unchanged and does not gate the record (LD-009).
- **HTTP surface:** N/A. No route, method, body, status or auth change in Callisto or europa-back-end. Swagger is unchanged.
- **Registries and module wiring:** A.9 (`repository.registry.ts`, `transaction-script.registry.ts`, the transaction-script provider, `GrantingClientAccessModule.imports`, new `ContactAccessAuditModule`).
- **Ports:** `ClientAccessContactAuditPort` (`CLIENT_ACCESS_CONTACT_AUDIT`), implemented by `ContactAccessAuditAggregator`; `ContactAccessAuditDispatcherPort` (`CONTACT_ACCESS_AUDIT_DISPATCHER`), implemented by `ContactAccessAuditDispatcher`.
- **Domain events:** audit event `CLIENT_ACCESS_UPDATED` with resource type `CONTACT`, on the existing audit SQS queue.
- **Domain exceptions:** N/A.
- **Authorization:** N/A. `ClientAccessManagerReadAuthGuard` and the delta permission check (CREATE to grant, DELETE to revoke) are unchanged.
- **Wiki wiring:** N/A. INT ticket specs live under `docs/atlas/INT-xxx/specs/` in dustin-thomason, as INT-138 to INT-141 do; there is no `systems/` tree to index.
- **Dev note:** N/A. The ticket is already estimated (2 points); see the estimate below.

## Rollout

Deploy europa-back-end and atlas-front-end with or before Callisto (LD-014).

- A record read before the europa-back-end branch is live falls through to the default branch and shows an empty path (S-04). It shows in full once the branch is deployed, because the text is built on read.
- Until the atlas-front-end change is live, the dropdowns don't offer the new values and the text shows on one line.

## Manual end-to-end

1. Open the Access Manager for a contact on a proceeding. Grant one type inside a collection (for example `MP4 Video › DepoView`) and one track-level type (for example a Planet Suite type), then save.
2. In Europa, expect one `CLIENT_ACCESS_UPDATED` row with resource type `CONTACT`, the contact's full name in the Resource column, the saving user in the User columns, and five lines: `Case`, `Job`, `Proceeding` matching the overlay's context fields, `Access granted` listing both types, `Access revoked: N/A`. The chip is grey and the Bucket is empty.
3. Remove `DepoView` and save. Expect a new row with `Access granted: N/A` and `Access revoked: MP4 Video › DepoView`.
4. Filter by Event Type `CLIENT_ACCESS_UPDATED`, then by Resource Type `CONTACT`: both rows are returned each time.
5. Remove all of the contact's access and save: `Access revoked` lists every remaining type.
6. As a user without the client-access-manager CREATE permission, try to grant a type: the save is refused with 403 and no new row appears.
7. Repeat step 1 as a user without the granting-client-access flag: the row still appears.
8. On the proceeding, create a dynamic collection named `Smith, Day 1`, grant the contact a type in it, and save. Expect `Access granted: "Smith, Day 1" › <type>` (LD-018).

## Complexity flags and estimate

- **New chain:** seven new files in `cau/`, plus the port, two projections, a repository, a converter and an assembler. Each follows an existing pattern, but it is the first audit chain owned by GCA.
- **Transaction script and provider:** the previous-grants read must stay before the replace, and the new dependency must be added in all three places in the provider factory.
- **Merge overlap with INT-141** in atlas-front-end `constants.ts`.
- **List quoting (LD-018):** one small europa-back-end helper and its B.3 cases.

**Medium (3–5 points).** The ticket carries 2 points. The europa-back-end and Atlas parts are small extensions, but Callisto needs a new GCA-owned audit chain and a delta that no existing code computes, with specs across all three repos.
