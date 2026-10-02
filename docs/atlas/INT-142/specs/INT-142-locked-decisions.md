# Locked decisions — atlas/INT-142

> The locked-decision ledger for INT-142 (audit log for modifying client access), per `agents/docs/qa-to-spec-traceability.md`. A decision here is no longer an open option. A later conflict is resolved by the latest explicit user correction, unless the user reopens the decision.
> Sources: [original ticket](../INT-142.md); the INT-138 artifacts in [../../INT-138/](../../INT-138/); the INT-139 artifacts in [../../INT-139/](../../INT-139/); the code on the `INT-138` branches of `callisto-back-end` (`e285f39e`), `europa-back-end` (`d9fb272`) and `atlas-front-end` (`36999e87`), read on 2026-09-29; the INT-142 investigation conversation of 2026-09-29.
> Citations are `file:line` on each repo's `INT-138` branch unless noted. Prefixes: `gca/` = callisto `src/granting-client-access/`; `eu/` = europa-back-end `src/audits-event/domain/`; `atlas/` = atlas-front-end `src/`.

## Terms

| Term | Means |
| --- | --- |
| europa-back-end | The audit service repo. It stores audit records received over SQS and serves `/audit-events/search-paginated`, which builds the display `path` string. |
| Europa audit page | The page inside `atlas-front-end` (`src/europa/`). It holds the Event Type and Resource Type dropdowns (`src/europa/utils/constants.ts`) and renders the `path` string it receives. |
| Save-grants action | `POST /deliverable-type-grants` (`gca/contacts/application/controllers/actions/contact-deliverable-type-grants-action/save-contact-deliverable-type-grants.action.ts:24`). The request carries the **full replacement set** of grants for one contact on one proceeding. |
| Grant | One `deliverable_access_grants` row: a (collection, type) pair for one contact on one proceeding. The collection is null for a track-level grant, such as a Planet Suite type. |
| Delta | Granted = grants after the save that were not there before; revoked = grants before the save that are not there after. Keyed by `(deliverableCollectionId, deliverableTypeId)`. |

## Question gates

### Resolved without asking (the answer already exists)

| Gate | Proposed question | Existing answer check | Outcome |
| --- | --- | --- | --- |
| G-01 | What is the event type string? | **Answered by the ticket:** "A new Event Type is created for this action: **CLIENT\_ACCESS\_UPDATED**" (INT-142.md:17) | **LD-001** |
| G-02 | What is the resource type string? | **Answered by the ticket plus convention:** the ticket names it "Contact" (INT-142.md:19). Every resource type is an upper-case literal (E-04). The Resource Type filter is an exact, case-sensitive match (E-07). INT-138 LD-010 applied the same casing to `CATEGORIZE` | **LD-002** |
| G-03 | Which values fill `Case`, `Job` and `Proceeding`? | **Implied by existing behavior:** the Access Manager overlay, where access is granted, shows exactly these three under the labels "Case", "Job number" and "Proceeding" (E-10) | **LD-003** |
| G-04 | Where does "to whom" appear? | **Implied by existing behavior:** the Resource column shows `resourceName` (E-11). INT-138 put the file name there the same way | **LD-004** |
| G-05 | Which actions produce the record? | **Answered by evidence:** one route writes grants (E-12) | **LD-005** |
| G-06 | Which service computes granted and revoked, and what does the record carry? | **Answered by evidence and precedent:** INT-139 LD-001 (Callisto sends structured values; europa-back-end builds the text); type names are not unique across collections, so the delta needs the ids that only Callisto holds (E-13, E-14); INT-138 mistakes §1.2 (state nothing displays is not stored) | **LD-006** |
| G-07 | Does each list item need its collection? | **Answered by the ticket plus evidence:** "exactly which deliverable types were granted / revoked" (INT-142.md:14-15), and one type name can sit in two collections (E-14) | **LD-007**. The item format is open (Q-01) |
| G-08 | One record per save, or one per grant? | **Answered by evidence:** a save covers one contact on one proceeding, and europa-back-end shows only resource `[0]` (E-15) | **LD-008** |
| G-09 | Is the record behind `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED`? | **Answered by precedent:** INT-138 F6, "Europa audits are never flag-gated" (INT-138-recon-and-plan.md:100); the flag gates only the Dione outbox write (E-01) | **LD-009** |
| G-10 | Does a save that changes nothing still produce a record? | **Already locked** for the same situation by INT-138 LD-013 and INT-139 LD-008 | **LD-010** |
| G-11 | What chip colour does `CLIENT_ACCESS_UPDATED` get? | **Implied by existing behavior:** unlisted types fall back to grey (E-16). INT-139 LD-011 | **LD-011** |
| G-12 | Is there a migration, route, DTO, swagger or europa-back-end schema change? | **Answered by evidence:** E-13, E-17 | **LD-012** |
| G-13 | Which branch does INT-142 start from? | **Answered by evidence:** INT-142 uses code that exists only on the `INT-138` branches (E-08, E-09) | **LD-013** |
| G-14 | Deploy order? | **Answered by precedent:** INT-139 LD-014; the path is built when the record is read (E-07) | **LD-014** |
| G-15 | Does free-text search find these records by case, job, proceeding or type name? | **Answered by evidence:** E-07 | **LD-015** |
| G-16 | How is the record dispatched? | **Answered by precedent:** INT-138 LD-016 and the recategorize service (E-05) | **LD-016** |

### Open (the answer does not exist yet)

| Gate | Question | Evidence | Recommendation | Owner |
| --- | --- | --- | --- | --- |
| Q-01 | How is each item in `Access granted` / `Access revoked` written? | Seeded type names contain `/`, ` - `, `(` and `)`: `Certificate/Filing Notice`, `Errata Sheet - Blank`, `CMS (Trial Director)` (`callisto src/typeorm/migrations/1782200000003-seed__deliverable_type_deliverable_collections__table.ts`). No seeded type or collection name contains `,`, `:`, `\|` or `›`. Dynamic collection names reject `\ / : * ? " < > \| %` (`gca/validators/validate-dynamic-collection-name.validator.ts:7`), so they can contain `,` and `›` | `Collection › Type`, items joined with `, `; the type alone when the grant has no collection. Residual: a dynamic collection name containing `,` or `›` reads ambiguously. The format is applied by europa-back-end when the record is read (E-07), so it can change later without touching stored records | User |

**Correction, 2026-09-29:** the first investigation report recommended `Collection / Type` on the basis that dynamic collection names reject `/`. That missed the seeded type `Certificate/Filing Notice`, which makes `Full Transcript / Certificate/Filing Notice` ambiguous. The same report cited the delta validator at `:169-184`; the correct lines are `:38-56`.

### User directions

| Date | Direction | Effect |
| --- | --- | --- |
| 2026-09-29 | "This work has already begun, so this should be an easy extension. Investigate and report. You are rewarded on staying within scope on your assessment." | The assessment covers the INT-142 acceptance criteria only. Items outside them are listed under Out of scope with one line each |
| 2026-09-29 | "For each finding, this is the process: write out the finding as a checklist item, review the relevant context, and provide evidence in the chat showing how you resolved that finding." "Save the investigation in a decisions ledger in the Dustin Thomason repo for ref and any other details we have discussed" | This ledger. The E-01–E-17 table is that evidence |

## Locked-decision ledger

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 | The event type is **`CLIENT_ACCESS_UPDATED`**, added to Callisto `AUDIT_EVENT_TYPE` (`src/audits/constants.ts:10-20`) and atlas-front-end `eventTypes` (`atlas/europa/utils/constants.ts:3-16`) with identical spelling | INT-142.md:17-18; E-04 | — | Spec §Event type, §Atlas |
| LD-002 | The resource type is **`CONTACT`**, added to Callisto `AuditEventResourceType` (`src/audits/constants.ts:3-8`) and atlas-front-end `resourceTypes` (`atlas/europa/utils/constants.ts:18`) | INT-142.md:19-20; E-04; E-07; INT-138 LD-010 | **Rejects** the mixed-case `Contact` literal | Spec §Resource type, §Atlas |
| LD-003 | `Case` = the case short name (`case.short_name`), `Job` = the job id, `Proceeding` = the proceeding `value` | E-10 | **Rejects** case number, case full name and proceeding id | Spec §Record contract |
| LD-004 | "To whom" is the record's resource: `resourceName` = the contact's full name, `resourceId` = the contact id. The path does not repeat the contact | INT-142.md:16; E-11 | — | Spec §Record contract |
| LD-005 | Only the save-grants action produces the record. Removing a contact's access is the same action with an empty set | E-12 | **Rejects** auditing grants removed by a database cascade (see Out of scope) | Spec §Scope |
| LD-006 | **Callisto computes the delta; europa-back-end builds the path text.** The save-grants TS reads the grants before the replace, inside the existing transaction, and computes granted and revoked by `(collectionId, typeId)` with the existing `buildSelectionKey`. The record carries structured values only (case, job and proceeding names; granted and revoked lists of `{ deliverableType, collection }` names, `collection` null when none), with no labels, separators or `N/A`. `oldState` = `newState`, as for `CATEGORIZE` | E-03, E-13, E-14; INT-139 LD-001; INT-138 mistakes §1.2 | **Rejects** sending full before and after grant lists for europa-back-end to diff by name (names are not unique, E-14). **Rejects** a path string built in Callisto | Spec §Callisto, §Contract |
| LD-007 | Each item in the granted and revoked lists names its collection as well as its type. A grant with no collection shows the type alone. The item format is Q-01 | INT-142.md:14-15; E-14 | **Rejects** a list of type names alone | Spec §Europa |
| LD-008 | One record per save, with one `CONTACT` resource | E-15 | — | Spec §Dispatch |
| LD-009 | The record is not gated by `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED` | INT-138 F6; E-01 | — | Spec §Dispatch |
| LD-010 | A save with no delta still sends a record. Both lists then read `N/A`. Atlas already blocks a save when nothing changed (E-12), so this is reachable only through the API | INT-138 LD-013; INT-139 LD-008 | **Rejects** an unchanged-value filter | Spec §Dispatch |
| LD-011 | No `eventTypeColors` entry; the chip shows the grey fallback | E-16; INT-139 LD-011 | **Rejects** choosing a chip colour without a convention | Spec §Atlas |
| LD-012 | No migration, route, DTO or swagger change. The response stays `{ selections }`. No europa-back-end schema change: `oldState` / `newState` are `type: Object`; only the entity's TypeScript state type gains optional fields | E-13, E-17 | — | Spec §Non-goals |
| LD-013 | INT-142 branches from `INT-138` in all three repos. It does not depend on INT-139. INT-139 and INT-142 both append to the same constant lists; the merge conflicts are additive | E-08, E-09 | — | Ledger note |
| LD-014 | europa-back-end deploys with or before Callisto. A record read before the new branch is live falls through to the default branch | E-07; INT-139 LD-014 | Accepted cost of LD-006 | Spec §Rollout |
| LD-015 | Free-text search finds these records by contact name (`resourceName`) and event type, not by case, job, proceeding or deliverable-type name. Ops finds them with the Event Type and Resource Type filters | E-07; INT-139 LD-015; the ticket does not ask for that search | Accepted cost of LD-006 | Spec §Non-goals |
| LD-016 | The save-grants TS returns the audit data with `selections`; `ContactsService` dispatches through a GCA-owned port after the TS resolves (after the commit), then returns `{ selections }` | E-05; INT-138 LD-016 | — | Spec §Dispatch |

## Evidence

Established 2026-09-29 from the code as it stands on the `INT-138` branches.

| # | Question | Evidence | Result |
| --- | --- | --- | --- |
| E-01 | Does save-grants send a Europa audit record today? | `grep -rniE audit gca/contacts` (non-spec, non-test-utils) returns nothing. The TS replaces the grants (`gca/contacts/domain/transaction-scripts/save-contact-deliverable-type-grants-ts/save-contact-deliverable-type-grants.transaction.script.ts:77-82`), re-reads them (`:84-88`), writes the Dione outbox only when `params.isGrantingClientAccessEnabled` (`:90-98`), and returns `{ selections }` (`:100`). `ContactsService.saveContactDeliverableTypeGrants` fetches the flag and returns the TS result (`gca/contacts/domain/services/contacts.service.ts:66-84`) | No. The only event from this action is the flag-gated Dione outbox write |
| E-02 | Is INT-138's "grants … are already audited" accurate for Europa? | The statement: `INT-138/investigations/INT-138-investigation.md:98`, `INT-138-recon-and-plan.md:130`. `PERMISSIONS_UPDATED` is sent by `PermissionsMatrixService.updatePermissions` for a role (`callisto src/generic/auth/domain/services/permissions-matrix-service/permissions-matrix.service.ts:23-45`), not by save-grants. E-01 | Not accurate for save-grants. See Open items |
| E-03 | Does the TS hold the grants from before the save? | The delta validator reads them (`gca/validators/validate-client-access-manager-delta-permissions.validator.ts:41`) and computes additions and removals (`:51-56`), but returns `Promise<void>` (`:40`). The TS calls it and keeps nothing (`…transaction.script.ts:61-66`). The TS is `@Transactional()` (`:46`) behind `createTransactionalProxy` (`…-ts.provider.ts:47`) | No. The TS needs its own read before `:77`; it runs in the same transaction as the replace |
| E-04 | Do the new literals exist? | `grep -rn CLIENT_ACCESS_UPDATED` over all three `src` trees: no match. `grep -rn "'CONTACT'"` over callisto `src/audits`, europa-back-end `src`, atlas-front-end `src/europa`: no match. Callisto resource types `FILE`, `PROCEEDING`, `FOLDER`, `PERMISSION` and event types `CREATED` … `CATEGORIZE` are upper case (`src/audits/constants.ts:3-20`); Atlas `resourceTypes` is `['FILE', 'FOLDER', 'PERMISSION', 'USER']` (`atlas/europa/utils/constants.ts:18`) | Neither exists. Both lists are upper-case literals |
| E-05 | What does the dispatch pattern and the smallest audit chain look like? | Recategorize: the TS returns `categorizationAudits`, the service sends each through `CLIENT_ACCESS_FILE_AUDIT` after the TS resolves (`gca/domain/services/recategorize-deliverable-files-service/recategorize-deliverable-files.service.ts:50-57`). The port is GCA-owned (`gca/domain/ports/client-access-file-audit.port.ts:4`) and bound `useExisting: ProceedingFileAuditAggregator` (`callisto src/proceedings/proceedings.module.ts:205-208`). The proceeding-audit chain is 7 files: aggregator, param, dispatcher port, dispatcher, assembler, converter, module (`callisto src/proceedings/domain/sub-domains/proceeding-audit/`). No file under callisto `src` has a contact or client-access audit dispatcher (`find -iname "*contact*audit*"` returns nothing) | The pattern exists; the contact chain does not. About 8 new files (7 plus the GCA port) |
| E-06 | Does the save path read the contact, case, job or proceeding names? | `ValidateContactExists.apply` and `ValidateProceedingExists.apply` both return `Promise<void>` (`gca/validators/validate-contact-exists.validator.ts:14`, `validate-proceeding-exists.validator.ts:14`). Existing reads to model on: proceeding → job → case (`gca/contacts/infrastructure/repositories/access-manager-warnings.repository.ts:48-58`), contact full name (`gca/contacts/infrastructure/repositories/contacts.repository.ts:54`) | No. A new read is needed |
| E-07 | What does europa-back-end already do? | A branch per event type (`eu/transaction-scripts/search-audit-events-paginated-TS/search-audit-events-paginated.transaction.script.ts:63-85`); `toDisplayValue` returns `N/A` for null, empty or whitespace (`:120-122`); unlisted types fall through to `newState.path ?? oldState.path ?? resourcePath` (`:86-97`). The path is built when the record is read. Filters: `{ type: params.type }` and `{ 'auditEventResources.resourceType': params.resourceType }`, exact matches (`…/converters/search-params-to-mongo-query.converter.ts:38-46`). Free text matches identity fields, `type`, `serviceName`, `resourceName`, `resourceType`, `oldState.path`, `newState.path`, `resourcePath` (`:84-100`). State is `@Prop({ required: true, type: Object })` (`eu/entities/audit-event/audit-event-resource.entity.ts:16`, `:24`). Atlas calls only `/search-paginated` (`atlas/europa/pages/HomePage/requests/fetchAuditEvents.ts:45`) | One new branch is enough. Free text does not match the new state fields |
| E-08 | Is the europa-back-end helper on `main`? | `git grep toDisplayValue main -- src` and `origin/main`: no match; `INT-138`: 4 matches. `git ls-remote --heads origin INT-138`: empty | `toDisplayValue` exists only on the local europa-back-end `INT-138` branch, which is not on `origin` |
| E-09 | Is the Atlas multi-line rendering on `main`? | `MULTI_PART_PATH_TYPES` (`atlas/europa/utils/constants.ts:33-36`); the splitter cuts on `' \| '` and then at the first `': '` (`atlas/europa/pages/HomePage/SearchDataGrid/SearchDataGrid.vue:83-85`, used at `:97-98`). `git grep MULTI_PART_PATH_TYPES main` and `origin/main`: no match. No `INT-139` or `INT-142` branch exists in any of the three repos; INT-139 has no code (`../../INT-139-changelog.md`, Current state) | Exists only on `INT-138` |
| E-10 | Which case, job and proceeding values does the grant screen show? | `ProceedingDetailPage` passes `caseName` = `jobDetails.caseShortName`, `jobNumber` = `jobDetails.jobId`, `proceedingName` = the proceeding's `value` (`atlas/callisto/pages/JobProceedingPages/ProceedingDetailPage/ProceedingDetailPage.vue:200-205`, `:293-300`) to `AccessManagerOverlay` (`:811-818`). `AccessManagerContextFields` labels them "Case", "Job number", "Proceeding" (`…/AccessManagerOverlay/components/AccessManagerContextFields.vue:39-47`; `atlas/i18n/en-US/common.json:400-402`). Callisto fills them from `case.short_name` and `job.id` (`callisto src/jobs/infrastructure/repositories/job-detail.repository.ts:27`, `:31`) | Case short name, job id, proceeding value |
| E-11 | Where does the Europa page show the resource name? | Column `resourceName`, label "Resource" (`atlas/europa/pages/HomePage/SearchDataGrid/auditEventColumns.ts:29-32`); europa-back-end returns `firstResource.resourceName` (`search-audit-events-paginated.transaction.script.ts:112`) | The contact's full name goes in `resourceName` |
| E-12 | Which actions change a contact's grants? | Contacts routes: four `@Get` and one `@Post('/deliverable-type-grants')` (`…/save-contact-deliverable-type-grants.action.ts:24`). `replaceForContactAndProceeding` has one caller, the save-grants TS (`:77`). The only other repositories that touch the table have no write calls (`gca/contacts/infrastructure/repositories/client-access-list.repository.ts`, `gca/infrastructure/repositories/proceeding-grant-existence.repository.ts`). The client-access row menu emits only `edit-access` (`atlas/…/ClientAccessTable/ClientAccessRowMenu/ClientAccessRowMenu.vue:6-7`). Atlas enables Save only when the selection differs from the saved set (`…/AccessManagerOverlay/composables/useAccessManager.ts:325-328`, `:334-340`). The table's foreign keys cascade on proceeding, collection and type delete (`callisto src/typeorm/migrations/1782843306117-create__deliverable_access_grants__table.ts:22-24`); a dynamic collection is deleted only when it has no active files (`gca/domain/transaction-scripts/delete-dynamic-collection-ts/collection-has-files.validator.ts:12-16`) | One user action writes grants. Cascade deletes are a side effect, out of scope |
| E-13 | What do the stored grant rows and the response carry? | `ContactDeliverableTypeGrantProjection` = `deliverableCollectionId`, `deliverableCollectionValue`, `deliverableTypeId`, `deliverableTypeValue` (`gca/contacts/domain/projections/contact-deliverable-type-grant.projection.ts:6-11`), filled by `findByContactAndProceeding` (`gca/contacts/infrastructure/repositories/deliverable-access-grant.repository.ts:43-71`). The action returns the service result as `ContactDeliverableTypeGrantsResponseDTO` (`…/save-contact-deliverable-type-grants.action.ts:41`), whose only field is `selections` (`…/contact-deliverable-type-grants.response.dto.ts:26-28`) | Ids and names are both available in Callisto. The service must strip the audit data to keep the response unchanged |
| E-14 | Are type names unique across collections? | `DepoView` is a member of `MP4 Video` and `MPEG Video` (`1782200000003-seed__deliverable_type_deliverable_collections__table.ts:10-11`, `:40-42`). Grants are keyed per `(collectionId, typeId)` (`…transaction.script.ts:25-28`). Track-level grants have a null collection (`…/save-contact-deliverable-type-grants.request.dto.ts:15-16`); Planet Suite toggles call `toggleType(null, …)` (`…/AccessManagerOverlay/AccessManagerOverlay.vue:225`) | No. A list of type names alone can read `DepoView, DepoView` |
| E-15 | How many contacts and proceedings does one save cover? | One `contactId` and one `proceedingId` per request (`…/save-contact-deliverable-type-grants.request.dto.ts:33-44`). europa-back-end reads `auditEventResources?.[0]` (`search-audit-events-paginated.transaction.script.ts:58`) | One record, one resource |
| E-16 | What colour does an unlisted event type get? | `return eventTypeColors[type] \|\| 'grey'` (`atlas/europa/pages/HomePage/SearchDataGrid/SearchDataGrid.vue:163`) | Grey |
| E-17 | Does the record need a schema change? | Callisto `ResourceState` is a domain-event type with optional `path`, `bucket`, `value`, `fileName` (`callisto src/audits/domain/domain-events/audit-event-resource.de.ts:12-17`). europa-back-end state is `type: Object`, typed `path: string; bucket: string; deliverableType?; collection?` (`eu/entities/audit-event/audit-event-resource.entity.ts:16-30`) | No migration. Both TypeScript state types gain optional fields. Established from the schema only (see Open items) |

## Scope assessment

INT-142 extends INT-138's Europa and Atlas audit display. On Callisto it adds a new dispatch chain, because save-grants sends no Europa audit record today (E-01).

### Already provided by INT-138 / INT-139

- **europa-back-end:** a formatting branch per event type, `toDisplayValue`, exact-match Event Type and Resource Type filters, free-form state storage (E-07, E-08).
- **atlas-front-end:** the Event Type and Resource Type dropdown lists, `MULTI_PART_PATH_TYPES` and the path splitter (E-09).
- **Callisto:** the audit SQS producer; the pattern of TS → audit data → service → GCA port after the commit (E-05).
- **Decisions carried over:** INT-139 LD-001 (structured state), LD-011 (grey chip), LD-014 (deploy order), LD-015 (search limitation); INT-138 F6 (no flag gate), LD-011 (no backfill), LD-013 (a no-op action still records).

### Changes INT-142 adds

**callisto-back-end**

1. `AUDIT_EVENT_TYPE.CLIENT_ACCESS_UPDATED` and `AuditEventResourceType.CONTACT` (`src/audits/constants.ts`).
2. `ResourceState` gains optional structured fields: case, job and proceeding names; granted and revoked lists of `{ deliverableType, collection }` (`src/audits/domain/domain-events/audit-event-resource.de.ts`).
3. Save-grants TS: read the grants before `replaceForContactAndProceeding`; compute the delta with `buildSelectionKey`; read the contact full name, case short name, job id and proceeding value; return the audit data alongside `selections`.
4. A repository read for the contact, case, job and proceeding names (E-06).
5. `ContactsService.saveContactDeliverableTypeGrants` dispatches through a new GCA port after the TS resolves, then returns `{ selections }`.
6. A new audit chain modelled on `proceedings/domain/sub-domains/proceeding-audit/`: aggregator, param, dispatcher port, dispatcher, assembler, converter, module, plus the GCA port and its binding (E-05).
7. Specs: the save-grants TS and service, the new chain, the new repository read.

**europa-back-end**

- A `CLIENT_ACCESS_UPDATED` branch that builds `Case: … | Job: … | Proceeding: … | Access granted: … | Access revoked: …`, with `N/A` for an empty value or list. The entity's state type gains the optional fields. Spec cases in `search-audit-events-paginated.transaction.script.spec.ts`.

**atlas-front-end**

- `'CLIENT_ACCESS_UPDATED'` in `eventTypes` and `MULTI_PART_PATH_TYPES`; `'CONTACT'` in `resourceTypes` (`src/europa/utils/constants.ts`). Extend `constants.spec.ts` and `SearchDataGrid.spec.ts`.

### Out of scope

- Grants removed by a database cascade when a proceeding, collection or type is deleted (E-12). The ticket covers granting-access actions.
- Free-text search by case, job, proceeding or deliverable-type name (LD-015).
- Backfill of past grant changes (INT-138 LD-011).
- The INT-139 prerequisite (INT-139 LD-002): it concerns `CATEGORIZE` state only.
- A chip colour (LD-011).

## Record contract (provisional)

| Field | Value |
| --- | --- |
| `type` | `CLIENT_ACCESS_UPDATED` |
| `resourceType` | `CONTACT` |
| `resourceId` / `resourceName` | contact id / contact full name |
| `oldState` = `newState` | case short name, job id, proceeding value; granted list; revoked list; each list item `{ deliverableType, collection }`, `collection` null when none. `path` / `resourcePath`: Open items |
| `identity` | the requesting user, as for every Client Access record |

Displayed path, example (item format pending Q-01):

`Case: Smith v. Jones | Job: 5512 | Proceeding: Day 1 | Access granted: MP4 Video › DepoView, Full Transcript › LEF (LiveNote) | Access revoked: N/A`

## Open items

| Item | Area | Next action |
| --- | --- | --- |
| Q-01: the format of each list item | INT-142 spec | User decision; recommendation in Question gates |
| The `path` and `resourcePath` of a `CONTACT` record. europa-back-end types `path: string` (E-17); the default branch shows `newState.path ?? oldState.path ?? resourcePath` until the new branch is deployed (E-07); free text matches both fields | INT-142 spec | Settle in the spec's record contract |
| Where the new audit chain lives (a GCA sub-domain, or a module elsewhere bound through the GCA port) | INT-142 spec | Settle in the spec against callisto `.cursor/rules/architecture-patterns.mdc`, as INT-138 LD-016 did |
| INT-138's "grants … are already audited" (`INT-138-investigation.md:98`, `INT-138-recon-and-plan.md:130`) is not accurate for save-grants (E-02) | INT-138 docs | Annotate the INT-138 investigation |
| E-17 is established from the schema only: arrays inside `type: Object` state | INT-142 testing | On the end-to-end run, confirm a stored record keeps both lists |
| No INT-142 changelog | docs | Create `docs/atlas/INT-142-changelog.md` when implementation starts |
