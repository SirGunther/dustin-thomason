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
| Q-02 | Is a ` \| ` inside a case short name or proceeding name accepted as a display limitation, or neutralised before the path is built? | E-21: proceeding names can get a `\|` only through the AJSF create API; Callisto never writes case short names. Atlas splits every multi-part path on `' \| '` | Accept and record as a known limitation | User; asked of the reviewer (R-3) |

**Both gates closed, 2026-10-12:** Q-01 → **LD-018**, Q-02 → **LD-019**, on the reviewer's recommendation, forwarded by the user. The rows above are kept for history.

**Correction, 2026-09-29:** the first investigation report recommended `Collection / Type` on the basis that dynamic collection names reject `/`. That missed the seeded type `Certificate/Filing Notice`, which makes `Full Transcript / Certificate/Filing Notice` ambiguous. The same report cited the delta validator at `:169-184`; the correct lines are `:38-56`.

**Update, 2026-10-12 (spec review R-1):** the Q-01 recommendation now adds quoting: a name containing `,` or `›` is wrapped in double quotes. E-20 shows no collection or deliverable type name can contain `"`, so a quoted name can't be misread. The question is with the reviewer and the user.

**Precedent check, 2026-10-12 (user: "check how other tickets did it"):** no earlier ticket writes a list of items into one path segment. On europa-back-end `main`, `CATEGORIZE` and `RECATEGORIZE` give the type and the collection separate labelled segments, type first: `Deliverable Type: … | Collection: …`, with `→` between old and new values and `N/A` for an empty value (`eu/transaction-scripts/search-audit-events-paginated-TS/search-audit-events-paginated.transaction.script.ts`, `CATEGORIZE` and `RECATEGORIZE` branches). `PERMISSIONS_UPDATED` joins one segment per resource with ` | `. That segment layout cannot hold a list here, because the ticket puts each list in one segment (`Access granted: [list]`) and ` | ` starts a new segment. Q-01 stays open.

### User directions

| Date | Direction | Effect |
| --- | --- | --- |
| 2026-09-29 | "This work has already begun, so this should be an easy extension. Investigate and report. You are rewarded on staying within scope on your assessment." | The assessment covers the INT-142 acceptance criteria only. Items outside them are listed under Out of scope with one line each |
| 2026-09-29 | "For each finding, this is the process: write out the finding as a checklist item, review the relevant context, and provide evidence in the chat showing how you resolved that finding." "Save the investigation in a decisions ledger in the Dustin Thomason repo for ref and any other details we have discussed" | This ledger. The E-01–E-17 table is that evidence |
| 2026-10-12 | "yeah, just get up to main, that's our jumping off point. the other itckets are part of the epic, should prove useful" | LD-013 is superseded by LD-017. INT-138 to INT-141 are reference work for the spec |
| 2026-10-12 | "I don't see the relevance here", in reply to "QA cases PDN-1873 and PDN-1879 are waiting on a PO reply" | The PO clarification is not pursued. Spec S-09 records the precedent as the accepted resolution (review finding R-2) |
| 2026-10-12 | "For each finding, this is the process: write out the finding as a checklist item, review the relevant context, and provide evidence in the chat showing how you resolved that finding." "Save the investigation in a decisions ledged in the Dustin Thomason repo for ref and any other details we have discussed" | The [spec review](#spec-review-2026-10-12) section below |
| 2026-10-12 | "Put these questions into a format for a reviewer, we can ask them about best practices along with any other updates you made" | Q-01 and Q-02 go to the reviewer in [INT-142-spec-review-response.md](INT-142-spec-review-response.md); they stay open here until answered |
| 2026-10-12 | Forwarded the reviewer's decisions, with the finding / context / evidence method: "Q-01: Choose Option A, conditional double-quoting … quote any name containing `,`, `›`, or `"`, and double embedded quotes." "Q-02: Choose Option A, accept and document the inherited limitation." "R-2: Accepted as resolved." | Taken as the user's lock: LD-018 and LD-019. The [Reviewer response](#reviewer-response-2026-10-12) section records the evidence |

## Locked-decision ledger

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 | The event type is **`CLIENT_ACCESS_UPDATED`**, added to Callisto `AUDIT_EVENT_TYPE` (`src/audits/constants.ts:10-20`) and atlas-front-end `eventTypes` (`atlas/europa/utils/constants.ts:3-16`) with identical spelling | INT-142.md:17-18; E-04 | — | Spec §Event type, §Atlas |
| LD-002 | The resource type is **`CONTACT`**, added to Callisto `AuditEventResourceType` (`src/audits/constants.ts:3-8`) and atlas-front-end `resourceTypes` (`atlas/europa/utils/constants.ts:18`) | INT-142.md:19-20; E-04; E-07; INT-138 LD-010 | **Rejects** the mixed-case `Contact` literal | Spec §Resource type, §Atlas |
| LD-003 | `Case` = the case short name (`case.short_name`), `Job` = the job id, `Proceeding` = the proceeding `value` | E-10 | **Rejects** case number, case full name and proceeding id | Spec §Record contract |
| LD-004 | "To whom" is the record's resource: `resourceName` = the contact's full name, `resourceId` = the contact id. The path does not repeat the contact | INT-142.md:16; E-11 | — | Spec §Record contract |
| LD-005 | Only the save-grants action produces the record. Removing a contact's access is the same action with an empty set | E-12 | **Rejects** auditing grants removed by a database cascade (see Out of scope) | Spec §Scope |
| LD-006 | **Superseded by V-07 (2026-10-12, spec v2 review).** **Callisto computes the delta; europa-back-end builds the path text.** The save-grants TS reads the grants before the replace, inside the existing transaction, and computes granted and revoked by `(collectionId, typeId)` with the existing `buildSelectionKey`. The record carries structured values only (case, job and proceeding names; granted and revoked lists of `{ deliverableType, collection }` names, `collection` null when none), with no labels, separators or `N/A`. `oldState` = `newState`, as for `CATEGORIZE` | E-03, E-13, E-14; INT-139 LD-001; INT-138 mistakes §1.2 | **Rejects** sending full before and after grant lists for europa-back-end to diff by name (names are not unique, E-14). **Rejects** a path string built in Callisto | Spec §Callisto, §Contract |
| LD-007 | Each item in the granted and revoked lists names its collection as well as its type. A grant with no collection shows the type alone. The item format is Q-01 | INT-142.md:14-15; E-14 | **Rejects** a list of type names alone | Spec §Europa |
| LD-008 | One record per save, with one `CONTACT` resource | E-15 | — | Spec §Dispatch |
| LD-009 | The record is not gated by `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED` | INT-138 F6; E-01 | — | Spec §Dispatch |
| LD-010 | **Superseded by V-09 (2026-10-12, spec v2 review).** A save with no delta still sends a record. Both lists then read `N/A`. Atlas already blocks a save when nothing changed (E-12), so this is reachable only through the API | INT-138 LD-013; INT-139 LD-008 | **Rejects** an unchanged-value filter | Spec §Dispatch |
| LD-011 | No `eventTypeColors` entry; the chip shows the grey fallback | E-16; INT-139 LD-011 | **Rejects** choosing a chip colour without a convention | Spec §Atlas |
| LD-012 | No migration, route, DTO or swagger change. The response stays `{ selections }`. No europa-back-end schema change: `oldState` / `newState` are `type: Object`; only the entity's TypeScript state type gains optional fields | E-13, E-17 | — | Spec §Non-goals |
| LD-013 | **Superseded by LD-017 (2026-10-12).** INT-142 branches from `INT-138` in all three repos. It does not depend on INT-139. INT-139 and INT-142 both append to the same constant lists; the merge conflicts are additive | E-08, E-09 | — | Ledger note |
| LD-014 | **Superseded by V-08 (2026-10-12, spec v2 review).** europa-back-end deploys with or before Callisto. A record read before the new branch is live falls through to the default branch | E-07; INT-139 LD-014 | Accepted cost of LD-006 | Spec §Rollout |
| LD-015 | **Superseded by V-08 (2026-10-12, spec v2 review).** Free-text search finds these records by contact name (`resourceName`) and event type, not by case, job, proceeding or deliverable-type name. Ops finds them with the Event Type and Resource Type filters | E-07; INT-139 LD-015; the ticket does not ask for that search | Accepted cost of LD-006 | Spec §Non-goals |
| LD-016 | The save-grants TS returns the audit data with `selections`; `ContactsService` dispatches through a GCA-owned port after the TS resolves (after the commit), then returns `{ selections }` | E-05; INT-138 LD-016 | — | Spec §Dispatch |
| LD-017 | INT-142 branches from `main` in all three repos. Branches cut 2026-10-12 at `origin/main`: callisto-back-end `43121c53`, europa-back-end `434567f`, atlas-front-end `bb8be210` | User direction 2026-10-12; E-18 | **Supersedes** LD-013 | Ledger note |
| LD-018 | Each list item is `Collection › Type`, or the type alone when the grant has no collection; items are joined with `, `. A collection or type name containing `,`, `›` or `"` is wrapped in double quotes, with any embedded `"` doubled (CSV-style). Case, job and proceeding values are not quoted | Reviewer decision on Q-01, forwarded by the user 2026-10-12; E-20 | **Closes** Q-01. **Rejects** unquoted lists and structural alternatives (one segment per item) | Spec B.2, B.3, manual step 8 |
| LD-019 | A ` \| ` inside a case short name or proceeding name is an accepted, documented limitation. Any future fix addresses multi-part paths consistently across event types | Reviewer decision on Q-02, forwarded by the user 2026-10-12; E-21 | **Closes** Q-02. **Rejects** replacing `\|` in Europa (the display would differ from the stored name) and event-specific label parsing in Atlas | Spec Known limitations |

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
| E-18 | Is the INT-138 code on `main` now? (re-checked 2026-10-12; E-08 and E-09 describe 2026-09-29) | atlas-front-end PR #582 and callisto-back-end PR #464 (`INT-138`) merged 2026-10-02 (`gh pr list`). europa-back-end `git grep -c toDisplayValue origin/main -- src`: 7 matches, landed through INT-139 PR #72, merged 2026-10-06. atlas-front-end `main` has `MULTI_PART_PATH_TYPES` (`src/europa/utils/constants.ts`). INT-140 is merged; INT-141 is open (europa-back-end PR #75) and adds `MULTI_PART_PATH_MAX_SEGMENTS` to the same Atlas constants file | Yes. INT-142 starts from `main` (LD-017) |
| E-19 | Has the grant-writing surface changed since E-12? (re-checked on `main` 2026-10-12) | INT-42 (commit 56c0f927, 2026-10-05) added `findByCaseGroupAndProceeding` / `replaceForCaseGroupAndProceeding` to `DeliverableAccessGrantRepository` and a case-group save transaction script (`gca/case-groups/domain/transaction-scripts/save-case-group-deliverable-type-grants-ts/`). The proceeding foreign key on `deliverable_access_grants` was dropped by `1788382218951-alter__drop_fk_proceeding_id__deliverable_access_grants_table.ts`, so deleting a proceeding no longer cascades to grants; collection and type deletes still cascade. The contact save path (action, service, transaction script, delta validator) is unchanged since 2026-09-03 | The contact save route is still the only writer for principal `Contact`. E-12's cascade note now covers collections and types only |
| E-20 | Can a collection or deliverable type name contain `"`, `,` or `›`? (2026-10-12, spec review R-1) | Dynamic collection names: `/[\\/:*?"<>\|%]/` is rejected (`gca/validators/validate-dynamic-collection-name.validator.ts:7`), and Atlas checks the same before saving (`atlas-front-end/src/callisto/utils/validate-dynamic-collection-name.ts:22`). Deliverable types: `DeliverableTypeRepository` has reads only (`fetchAll`, `fetchByTrack`, `findByValueAndTrack`, `findById`, `findByIds`, `existsForTrack`; `gca/infrastructure/repositories/deliverable-type.repository.ts:18-57`), and no other non-migration code injects `Repository<DeliverableType>`, so types are seed-only. No seeded type or static collection name contains `,`, `›`, `\|`, `:` or `"` (seed check of 2026-10-12) | No name can contain `"`. Only a dynamic collection name can contain `,` or `›` |
| E-21 | Can a case short name or proceeding name contain `\|`? (2026-10-12, spec review R-3) | Proceedings: `@NoSpecialChars()` (`/[\\/:*?"<>\|%]/`, `src/proceedings/validators/no-special-chars.validator.ts:5`) on File Navigator create (`create-proceedings.request.dto.ts:18`) and rename (`rename-proceeding.request.dto.ts:18`). `CreateJobSubmissionProceedingsRequestDTO` (AJSF) is `@IsString({ each: true })` only. Both Atlas proceeding forms reject the same characters (`AddProceedingForm.vue:75-77`, `NewProceedingsOverlay.vue:87-89`). Cases: Callisto has no create or update of `short_name` (`case.repository.ts` has `findById` and a soft `delete`; `cases-projector.repository.ts` and the search repositories only read) | A proceeding name gets a `\|` only through a direct AJSF API call. Case short names are written outside Callisto and are not checked |
| E-22 | How do existing branches show an empty value, and can one save cover several contacts? (2026-10-12, spec review R-2) | `toDisplayValue` returns `N/A` for null, empty or whitespace-only values, with the comment "Atlas splits the path on ' \| ' and bolds the label before ': ', so an empty value would render a dangling label instead of an explicit N/A" (`eu-ts/…transaction.script.ts:142-146`). INT-138 LD-013 and INT-139 LD-008 lock `N/A` for a no-change action. The save request has one `contactId` and one `proceedingId` (`…/save-contact-deliverable-type-grants.request.dto.ts:33-55`) | An empty list reading `N/A` follows the precedent. Several contacts in one save cannot happen |

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

## Spec review, 2026-10-12

Review of [INT-142-spec.md](INT-142-spec.md). Verdict: architecture conditionally approved; not implementation-ready until the display format is resolved. Process per the user direction of 2026-10-12: each finding as a checklist item, its context reviewed, its evidence recorded, marked complete only with that evidence. Questions for the reviewer: [INT-142-spec-review-response.md](INT-142-spec-review-response.md).

- [x] **R-1 (Blocker): Q-01 is open while the spec hard-codes an answer; the proposed format is ambiguous for collection names containing `,` or `›`.** Status: **complete (2026-10-12): Q-01 locked as LD-018; blocker cleared.**
  - *Context reviewed:* spec Open questions, B.2, B.3, displayed example, manual steps; E-20.
  - *Evidence:* E-20. No name can contain `"`; only dynamic collection names can contain `,` or `›`.
  - *First round:* the spec marked every use of the format as provisional and listed what Q-01 blocked; the recommendation gained quoting.
  - *Resolution:* the reviewer chose option A with conventional escaping (quote any name containing `,`, `›` or `"`, and double embedded quotes); the user forwarded that decision (see [Reviewer response](#reviewer-response-2026-10-12)). The spec now specifies `toQuotedName` (B.2), quoting cases in B.3, the quoted example, and manual step 8. The provisional markers are removed.
- [x] **R-3 (Low): a `|` in a case or proceeding name breaks the five-part display.** Status: **complete (2026-10-12): Q-02 locked as LD-019.**
  - *Context reviewed:* spec Known limitations; E-21.
  - *Evidence:* E-21. Proceeding names reach Callisto with a `|` only through the AJSF API; Callisto doesn't write case short names.
  - *Resolution:* the reviewer chose option A, accept and document. The spec's Known limitations records it as an accepted inherited limitation; any future fix addresses multi-part paths consistently across event types. No code.
- [x] **R-2 (Medium): `N/A` for an empty list is a product-confirmation gap.** Status: **complete.**
  - *Context reviewed:* `INT-142-comments.md:18`; LD-010; europa-back-end `toDisplayValue`.
  - *Evidence:* E-22, and the user's direction of 2026-10-12 ruling the pending PO clarification not relevant.
  - *Resolution:* spec S-09 names the precedent as the accepted resolution, and records that the comment's second question (several contacts in one save) cannot happen.
Reviewer's assessment, recorded for reference: the spec follows the ticket; there is no material scope creep (collection names justified; case groups, cascade removals, backfill, free-text search and chip colour correctly excluded); it is not materially overbuilt (the Callisto file count follows the repository's audit architecture; the extra previous-grants read is a minor inefficiency); and the approach is appropriate once the display decisions are resolved.

### Reviewer response, 2026-10-12

The reviewer answered [INT-142-spec-review-response.md](INT-142-spec-review-response.md), and the user forwarded the answer with the same finding / context / evidence method. Each item below is checked against the spec as now written.

- [x] **D-1: Q-01, option A with conventional escaping.** "Quote any name containing `,`, `›`, or `"`, and double embedded quotes." Locked as **LD-018**. *Evidence in the spec:*
  - B.2 defines `NAME_NEEDS_QUOTING = /[,›"]/` and `toQuotedName`, which returns `"${name.replace(/"/g, '""')}"` when the regex matches.
  - `toGrantListDisplay` passes both the collection and the type through `toQuotedName`.
  - B.3 cases: `"Smith, Day 1" › DepoView`, `"Day 1 › Rough" › DepoView`, `"Exhibit ""A"""`, a type quoted on its own side only, and an unquoted case or proceeding name containing `,`.
  - The displayed example shows the quoted form; manual step 8 checks it end to end.
- [x] **D-2: Q-02, option A, accept and document.** Locked as **LD-019**. *Evidence in the spec:* Known limitations reads "Accepted as an inherited limitation (LD-019); any future fix addresses multi-part paths consistently across event types, not this event alone." The review-questions table carries the reviewer's reasons. No code is specified for it.
- [x] **D-3: R-2 accepted as resolved.** "The existing `N/A` precedent and single-contact request contract are sufficient." *Evidence:* spec S-09 and E-22, unchanged.
- [x] **D-4: blocker cleared, spec implementation-ready.** The reviewer: "Once the user locks Q-01 and Q-02 accordingly, my review blocker is cleared and the spec is implementation-ready." *Evidence:* LD-018 and LD-019 are locked below. The spec header reads "Implementation readiness: ready". A search of the spec for "provisional", "with the reviewer" and open Q-01 / Q-02 wording returns only the locked review-questions table and the header.

## Implementation review, 2026-10-12

One subagent per repo, each in its own worktree. Each piece was reviewed against the original ticket, this ledger and the spec before it was applied to the `INT-142` integration worktree. Details and gate tables are in `docs/atlas/INT-142-changelog.md`.

- [x] **R-C1 (callisto): a code comment gave design rationale.** `ContactAccessAuditModule`'s JSDoc said the port is bound "rather than in ProceedingsModule". Under the build guardrail, why a change was made belongs in the PR, not the code. *Resolution:* trimmed to the constraint: "Owns the CLIENT_ACCESS_CONTACT_AUDIT binding. It depends on neither of its consumers, so GrantingClientAccessModule can import it without a cycle." *Evidence:* the integration worktree's file matches; lint, type-check and prettier passed after the edit.
- [x] **europa and atlas pieces:** approved on the first pass. The europa production diff matches B.2 line for line, including `toQuotedName` (LD-018). The atlas diff matches C.2, `SearchDataGrid.vue` is unchanged (S-08), and there is no `eventTypeColors` entry (LD-011).
- **Subagent findings accepted without change:**
  - callisto `seedCase` `shortName` override.
  - Integration specs on a separate `TEST_DB_NAME`.
  - Europa fixtures keep `path` / `bucket` as `undefined` rather than widening the entity type.
  - The atlas spec placement avoids conflicts with INT-141's open PR.

## Spec v2 (AC-traced), 2026-10-12

User directions: "Then tear it all down, and back to the spec … The AC is the source of truth, you didn't check it, we can't trust your implementation on ANYTHING," then "Start."

Spec v1 is retired to `../dnu/` (see its README). Spec v2 lists every code change against an AC line, with the existing code checked and evidence that the existing code can't do it. These decisions replace v1's:

| ID | Decision | Evidence | Supersedes |
| --- | --- | --- | --- |
| V-01 | **No aggregator, param file or converter.** The GCA port `CONTACT_ACCESS_AUDIT_DISPATCHER` (with its types in the port file) is implemented directly by `ContactAccessAuditDispatcher`. `ContactsService` injects it. The assembler builds the resource inline. One small module binds it and imports `AuditsModule` | A service injecting a dispatcher port directly already exists (`job-submission.service.ts:46`). The permissions assembler builds its resource inline (`permissions-to-audit-event.assembler.ts:17-23`). Types in a port file match existing ports (INT-141 review) | S-01 |
| V-02 | **No `try/catch` in the service.** It dispatches after the transaction script and returns `{ selections }` | The producer catches its own errors and returns `false` (`sqs-audit-event.producer.ts:23-33`). `RecategorizeDeliverableFilesService` dispatches the same way (`:50-57`) | S-05 |
| V-03 | **No new repository.** The contact's full name comes from `ContactsRepository.findActiveById` (`contacts.repository.ts:88-95`), and the case short name, job id and proceeding name from `ProceedingRepository.findProceedingDetailById` (`proceeding.repository.ts:28-51`). `caseShortName` is added to `ProceedingDetailProjection`, a type-only change: the query already selects it (`:44`), and `ProceedingDetailResponseDTO` is unchanged | Both reads exist, and both repositories are already available to GCA | S-06 |
| V-04 | **The validators are not changed.** The previous grants and the contact are read by the transaction script, not returned from the validators | Making them return what they read would change existing assertions (`resolves.toBeUndefined()`: delta validator spec `:48`, `:67`, `:113`, `:178`; contact validator spec `:33`) | — (confirms S-03) |
| V-05 | **The delta is a private method of the transaction script** using its existing `buildSelectionKey` (`:25-28`). There is no separate assembler or converter class | `buildSelectionKey` already keys a grant by collection and type in the same file | v1 A.10 steps 3–4 |
| V-06 | **Only the tests in the v2 test inventory (T1–T16) are written.** Existing assertions are not edited; only providers are added, plus the one exact-set test C3 forces | The user's review rejected tests outside the ticket's scope | v1 A.11, B.3, C.9 |

~~Open: LD-006 is the one locked decision that adds code beyond what the AC alone requires.~~ Resolved by the spec v2 review below (V-07).

## Spec v2 review, 2026-10-12

The user forwarded the reviewer's findings with the finding / context / evidence method. The verdict: "Spec v2 is materially better and no longer broadly overbuilt, but I would not approve it unchanged." The forward is taken as the user reopening LD-006, the question the previous turn put to the user. V-06's test numbers (T1–T16) are renumbered T1–T17 in the revised spec.

- [x] **R2-1: reopen LD-006; Callisto builds the text and europa-back-end is unchanged.**
  - *Context reviewed:* the AC (AC-5 requires the five-part path in Europa, not structured state); europa-back-end's default branch; Callisto's permissions audit; the free-text search fields.
  - *Evidence:*
    - The default branch sets `path = newState.path ?? oldState.path ?? resourcePath ?? ''` and `bucket = newState.bucket ?? oldState.bucket ?? resourceBucket ?? ''` (`eu-ts/search-audit-events-paginated.transaction.script.ts:110-122`).
    - Callisto already builds display text in `path` (`permissions-to-audit-event.assembler.ts:22-23`).
    - `ResourceState` already has `path?: string` (`audit-event-resource.de.ts:13`).
    - Ingest has no allow-list (`sqs-audit-event.listener.ts:15-33`).
    - Free-text search matches `oldState.path` and `newState.path` (`search-params-to-mongo-query.converter.ts:84-100`).
    - No `N/A` helper exists in callisto `src` (`grep "'N/A'"`: none).
  - *Resolution:* **V-07** replaces LD-006: A12 builds the five-part text, sends `oldState = newState = { path }`, and applies `N/A` and the LD-018 quoting. A2 and B1–B4 are removed. T9–T12 move to the Callisto assembler spec (now T9–T12 under A12). **V-08** revises LD-014 (only Callisto and Atlas deploy; Atlas with or before Callisto) and LD-015 (the existing free-text search matches the stored path as a side effect; no search code is added).
- [x] **R2-2: A3's required field breaks existing typed fixtures outside the test inventory.**
  - *Context reviewed:* every use of `ProceedingDetailProjection` in callisto `src`.
  - *Evidence:* typed fixtures without `caseShortName` exist at `fetch-proceeding-detail-by-Id-ts.transaction.script.spec.ts:36` and `proceeding.service.spec.ts:205`. The other uses are the type file and `proceeding.repository.ts:9`, `:30`, `:48`.
  - *Resolution:* **V-10**, A3 becomes `caseShortName?: string | null`. The transaction script's `proceeding?.caseShortName ?? null` already turns `undefined` into `null`. The spec's test inventory now says no existing fixture changes.
- [x] **R2-3: under the strict source-of-truth rule, a save with no change is not a "granting access action taken".**
  - *Context reviewed:* AC-2c and AC-2d ("actions taken: exactly which deliverable types were granted / revoked"); LD-010; the Atlas save guard.
  - *Evidence:* Atlas enables Save only when the selection changed (`isDirty` and `canSave`, `useAccessManager.ts:348-361`; `AccessManagerOverlay.vue:441` `:disable="!canSave"`, `:103`). So only a direct API save can send an unchanged set. LD-010 rested on INT-138 / INT-139 precedent, not on this ticket's AC.
  - *Resolution:* **V-09** replaces LD-010: `ContactsService` dispatches only when `audit.granted` or `audit.revoked` is non-empty (A15), with new test T6 (now T7). A real save that changes one side still shows `N/A` on the other (S-09, then T10, now T11).

| ID | Decision | Supersedes |
| --- | --- | --- |
| V-07 | Callisto builds the five-part text in `oldState.path` = `newState.path` (A12), with `N/A` and LD-018 quoting; europa-back-end is unchanged; no `ResourceState` change | LD-006 |
| V-08 | Only Callisto and Atlas deploy, Atlas with or before Callisto. The existing free-text search matches the stored path as a side effect; no search code is added | LD-014, LD-015 |
| V-09 | No record when a save neither grants nor revokes anything | LD-010 |
| V-10 | `ProceedingDetailProjection.caseShortName` is optional | first-v2 A3 |

## Spec v2 review 3, 2026-10-12

The user forwarded the third review with the finding / context / evidence method. The verdict: "conditionally appropriate, but not yet approval-ready because of R3-1"; V-07 to V-10 stand. Test numbers in the spec are now T1–T18. V-09's test is T7, and the assembler record test, which was T8, is now T9.

- [x] **R3-1 (Medium): a missing contact or proceeding produced a record with an empty name or `N/A` values.**
  - *Context reviewed:* the spec's A6, A7 and transaction-script code; both repositories; both validators; the entity columns.
  - *Evidence:*
    - `ContactsRepository` injects a plain `Repository<Contact>`, with no `TransactionContext` (`contacts.repository.ts:22-25`), and `findActiveById` filters `isActive: true` (`:88-95`). So a contact deactivated or removed after `ValidateContactExists` returns null on the second read. The spec's claim that the earlier check guaranteed the row was wrong.
    - `ProceedingRepository` does read through `TransactionContext` (`proceeding.repository.ts:14-21`). A proceeding deleted and committed in between can still read null.
    - The validators export `CONTACT_NOT_FOUND_MESSAGE` and `PROCEEDING_NOT_FOUND_MESSAGE` and throw `BadRequestException` with them (`validate-contact-exists.validator.ts:4`, `:19`; `validate-proceeding-exists.validator.ts:4`, `:19`).
    - `proceedings.job_id` is a non-null integer column (`proceeding.entity.ts:31-32`), and `contacts.full_name` is a non-null varchar (`contact.entity.ts:27-28`).
  - *Resolution:* **V-11**. A null lookup in A6 or A7 throws the validator's existing not-found error inside the transactional `apply`, which rolls back the save; no record is sent.
    - Port types tightened: `proceeding.value: string`, `jobId: number`. The assembler writes `Job: ${jobId}` with no `N/A`.
    - New test T5.
    - The reviewer's leaner alternative (return the contact from `ValidateContactExists`) is not taken, because it would edit an existing assertion (`resolves.toBeUndefined()`, contact validator spec `:33`; V-04).
- [x] **R3-2 (Low): the existing service fixtures must change, contrary to the spec's test-edit rule.**
  - *Evidence:* the two existing service tests mock the transaction script's result as `{ selections }` (`contacts.service.spec.ts:80-82`, `:118-120`), and A15 reads `audit.granted`.
  - *Resolution:* the spec's test inventory now lists exactly three kinds of change to existing spec files:
    - providers for the new dependencies, with the contact and proceeding mocks resolving rows by default so the existing transaction-script cases don't hit the V-11 aborts;
    - the existing service fixtures gaining an `audit` value with both lists empty, so their assertions still hold;
    - the one Atlas exact-set test.
    No existing assertion is edited, except that exact-set test (corrected in review 4, R4-1).
- [x] **R3-3 (Low): date/time (AC-2b) was not asserted.**
  - *Evidence:* the assembler record test asserted `identity` only.
  - *Resolution:* T9 (formerly T8) runs with fake timers and asserts `createdAt` equals the faked current time. No extra test case was added.

| ID | Decision | Supersedes |
| --- | --- | --- |
| V-11 | A null contact or proceeding lookup aborts the save with the validators' existing not-found errors; no record is sent without the contact | the earlier v2 fallback to `''` / `N/A` |

## Spec v2 review 4, 2026-10-12

The user forwarded the fourth review with the finding / context / evidence method. The verdict: rejected as it stood because of one low-severity internal contradiction. "The implementation design itself is otherwise ready … V-07 through V-11 are coherent … No production-design change is required."

- [x] **R4-1 (Low): the test-edit rule contradicted T17.**
  - *Context reviewed:* the spec's test-inventory intro and T17; every statement about editing existing assertions in the spec and this ledger.
  - *Evidence:* the spec's intro said "**No existing assertion is edited.**", while T17 changes the existing Atlas `MULTI_PART_PATH_TYPES` exact-set assertion (`atlas-front-end/src/europa/utils/__specs__/constants.spec.ts:53-63`). A search of the spec for "existing assertion" finds two places. The other is A4's rationale ("would change existing assertions"), which describes the rejected validator change, not a rule, so it is not a contradiction. A search of this ledger finds V-06 and the R3-2 resolution: V-06 already names the exact-set test as the exception; R3-2's sentence did not.
  - *Resolution:*
    - The spec's intro now reads, using the reviewer's wording: "**Existing assertions stay unchanged, except for T17's `MULTI_PART_PATH_TYPES` exact-set assertion.**"
    - The R3-2 sentence in this ledger now names the same exception.
    - No production-design change.

## Spec v2 approval and implementation review, 2026-10-12

- **Approved:** "The spec is approved as it currently stands. It can proceed to implementation." The reviewer confirmed all AC are followed, there is no scope creep or overbuild, V-07 to V-11 are valid, and no decisions are open.
- [x] **callisto-back-end piece (A1, A3–A15, T1–T14).**
  - *Evidence:* each production hunk was read against its spec block and matches: constants, the optional `caseShortName`, the transaction script's previous read before the replace, the null aborts using the validators' constants, `toGrantDelta` with `buildSelectionKey`, the provider entries, the port, dispatcher, assembler and module, and the service's non-empty condition.
  - The new tests are exactly T1–T14, with T5 written as two tests in one `describe`. The only removed line in an existing spec file is the service's mocked transaction result (allowed by the test inventory).
  - Applied to `INT-142`; committed `9f2df650`.
  - **Deviation D-1:** the A10 port's JSDoc (`/** One save of one contact's grants on one proceeding. */`) was left out, because the orchestrator's prompt allowed only A12's comment. It has no behaviour, and no AC is affected. Restoring it is a one-line documentation change if wanted.
- [x] **atlas-front-end piece (C1–C3, T15–T18).**
  - *Evidence:* three one-line production hunks (C1, C2, C3); T15 and T16 new; T17 the permitted exact-set edit, with its title renamed to match; T18 new.
  - Applied to `INT-142`, staged, held for the audit waiver. **Since then:** committed `96a5354e` after the draft-PR request was taken as the waiver, pushed, and opened as [atlas-front-end #601](https://github.com/planetdepos/atlas-front-end/pull/601). callisto was pushed with [callisto-back-end #481](https://github.com/planetdepos/callisto-back-end/pull/481) (both drafts, base `main`).

## PR review, 2026-10-12

The user forwarded the PR review with the finding / context / evidence method. The verdict: "Approved for implementation correctness and scope … no functional, integration, scope-creep, or overbuilding defect. Three low-severity convention issues remain." The reviewer also noted the handoff above was stale; it is updated.

- [x] **R-1 (Low): new Callisto tests use hand-written casts.**
  - *Context reviewed:* the three new or changed specs; `src/contacts/test-utils/contact.test-utils.ts:13` (`createMockContact`); the repo's audit spec pattern; `planetdepos.mdc:27` ("Test data: use test-utils"); depcruise rules.
  - *Evidence:*
    - Casts at the transaction-script spec `:68` and `:620` (`} as Contact`), the dispatcher spec `:26` and the assembler spec `:34` (`as unknown as jest.Mock`).
    - Importing `createMockContact` into the GCA spec fails `npx depcruise --config load-depcruise-config.js --output-type err src` with `no-cross-module-test-utility-imports` (`fitness-functions-rules/architecture-rules/test-utility-boundaries.rules.ts`).
    - The existing pattern for the config is `createMock<AuditConfigAccessor>({ … })` from `@golevelup/ts-jest` (`case-merge-audit.dispatcher.spec.ts:26`, `:43`).
  - *Resolution:*
    - Contacts became `Object.assign(new Contact(), { fullName: 'Jane Doe' } satisfies Partial<Contact>)`. That is the `Object.assign(new Entity(), …)` shape from `src/granting-client-access/test-utils.ts`, with `satisfies` already used in the same spec.
    - The config mocks use `@golevelup/ts-jest` `createMock` with plain values.
    - A search for casts in the three specs now finds none.
    - Test counts are unchanged (27 / 27).
- [x] **R-2 (Low): one assertion doesn't use ordinal matching.**
  - *Evidence:* `contacts.service.spec.ts:206` used `toHaveBeenCalledWith`; `planetdepos.mdc:31` prefers `toHaveBeenNthCalledWith`.
  - *Resolution:* changed to `toHaveBeenNthCalledWith(1, { ...audit, user: mockUser })` (`:206-211`). The test already asserts one call, so coverage is unchanged.
- [x] **R-3 (Low/process): commit subjects conflict with the checked-in `PRDV-X` rule.**
  - *Evidence:* both repos' `.cursor/rules/git-commit-messages.mdc` say every commit must start with a ticket number in `PRDV-X` format. Both repos' `origin/main` already carry many merged `INT-*` commits from several tickets: callisto `55431e07`, `46aa7822`, `02afcce2` (INT-140), `3a199f58` (INT-121), `9ece2f8d` (INT-232); atlas `cacfd124` (INT-140), `e88f6262` (INT-42), `ed565ae3` (INT-32). INT-141 already recorded this as rule-governance debt from INT-138.
  - *Resolution:* the `INT-142:` subjects are kept. They name the real ticket, which the merged history shows is the team's practice. No PRDV number is invented. The repo rule file is not edited; that is outside this ticket and a governance decision. Recorded as an exception in the changelog.
- **Fix delivery:** a subagent made the test-only change in `wt\callisto-INT-142-review` (4 spec files, +22 / −20). It was reviewed, applied to `INT-142` (byte-identical), re-gated, committed as `94f2f8a0` `INT-142: Use typed mocks in audit specs`, and pushed. PR #481's commit block now shows `94f2f8a0`. atlas has no change.

## Open items

| Item | Area | Next action |
| --- | --- | --- |
| ~~Q-01: the format of each list item~~ Locked 2026-10-12 as LD-018 | INT-142 spec | — |
| ~~Q-02: a `\|` inside a case or proceeding name~~ Locked 2026-10-12 as LD-019 | INT-142 spec | — |
| ~~The `path` and `resourcePath` of a `CONTACT` record~~ Settled (S-04, V-07): `resourcePath` and `resourceBucket` are `''`; `oldState.path` = `newState.path` holds the five-part text | INT-142 spec | — |
| ~~Where the new audit chain lives~~ Settled (V-01): port `CONTACT_ACCESS_AUDIT_DISPATCHER` in `gca/domain/ports/`; dispatcher, assembler and module in `gca/infrastructure/dispatchers/contact-access-audit/` | INT-142 spec | — |
| Case-group grants (INT-42, 2026-10-05) also write `deliverable_access_grants`, through `SaveCaseGroupDeliverableTypeGrantsTS`, for principal `CaseGroup` (E-19). The ticket names resource type Contact | INT-142 scope | Out of scope in the spec; raise with the PO if case-group changes need a record |
| INT-138's "grants … are already audited" (`INT-138-investigation.md:98`, `INT-138-recon-and-plan.md:130`) is not accurate for save-grants (E-02) | INT-138 docs | Annotate the INT-138 investigation |
| E-17 is established from the schema only: arrays inside `type: Object` state | INT-142 testing | On the end-to-end run, confirm a stored record keeps both lists |
| ~~No INT-142 changelog~~ Created 2026-10-12: `docs/atlas/INT-142-changelog.md` | docs | — |
