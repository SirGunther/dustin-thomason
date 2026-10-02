# Locked decisions — atlas/INT-139

> The locked-decision ledger for INT-139 (audit log for deliverable-type recategorization), per `agents/docs/qa-to-spec-traceability.md`. A decision here is no longer an open option. A later conflict is resolved by the latest explicit user correction, unless the user reopens the decision.
> Sources: [original ticket](../INT-139.md); the INT-138 artifacts in [../../INT-138/](../../INT-138/); the code on the `INT-138` branches of `callisto-back-end`, `europa-back-end` and `atlas-front-end`, read on 2026-09-29; the INT-139 investigation conversation of 2026-09-29.
> Citations are `file:line` on each repo's `INT-138` branch unless noted.

## Terms

| Term | Means |
| --- | --- |
| europa-back-end | The audit service repo. It stores audit records received over SQS and serves `/audit-events/search-paginated`, which builds the display `path` string. |
| Europa audit page | The page inside `atlas-front-end` (`src/europa/`, route `/europa-stuff`). It holds the Event Type dropdown (`src/europa/utils/constants.ts`) and renders the `path` string it receives. |
| Structured state | `oldState` / `newState` carry raw values as separate fields (`path`, `bucket`, `fileName`, `deliverableType`, `collection`), with no labels, separators or `N/A`. |

## Question gates

### Resolved without asking (the answer already exists)

| Gate | Proposed question | Existing answer check | Outcome |
| --- | --- | --- | --- |
| G-01 | Which service builds the path text: Callisto or europa-back-end? | **Answered by evidence**, E1–E10 below: the existing precedent for the same Callisto → europa-back-end pair (E4) and the INT-139 old → new requirement (E5) | **LD-001**, **LD-002** |
| G-02 | Does the recategorize action still send `CATEGORIZE` as well? | **Answered by the ticket:** "A new Event Type is created for this action: Recategorize" (INT-139.md:23). Sending both would log one action twice under two types | **LD-005** |
| G-03 | What is the event type string? | **Answered by the ticket plus convention:** the ticket names it "Recategorize"; every Atlas and Europa event type is an upper-case literal shown as-is; INT-138 LD-010 did the same for `CATEGORIZE`. europa-back-end's Event Type filter is an exact, case-sensitive match: `conditions.push({ type: params.type })` (`europa-back-end/src/audits-event/domain/transaction-scripts/search-audit-events-paginated-TS/converters/search-params-to-mongo-query.converter.ts:38-39`) | **LD-004** |
| G-04 | Does a recategorize that changes nothing still produce a record? | **Already locked** for the same action by INT-138 LD-013 | **LD-008** |
| G-05 | Do the old values need a new database read? | **Answered by evidence:** the batch file already carries `currentDeliverableTypeId` and `currentDeliverableCollectionId` (`recategorize-deliverable-files-data.projection.ts:12-13`), filled from the attachment before the write (`recategorize-batch-files.converter.ts:37-39`) | **LD-009** |
| G-06 | Do other europa-back-end endpoints need the formatting? | **Answered by evidence:** E7 | **LD-010** |
| G-07 | What chip colour does `RECATEGORIZE` get? | **Implied by existing behavior:** `CATEGORIZE` has no `eventTypeColors` entry, and unlisted types fall back to grey (`atlas-front-end` `SearchDataGrid.vue:163`). INT-138 mistakes §3.11 records a colour picked with no convention behind it | **LD-011** |
| G-08 | Which branch does INT-139 start from? | **Answered by evidence:** INT-139 changes the `CATEGORIZE` chain, which is on the `INT-138` branch (for example `AUDIT_EVENT_TYPE.CATEGORIZE`, `callisto-back-end/src/audits/constants.ts:19`). All three repos have `INT-138` checked out (`.git/HEAD`: `ref: refs/heads/INT-138`) | **LD-013** |

### User directions

| Date | Direction | Effect |
| --- | --- | --- |
| 2026-09-29 | "The blocker, this has been a thing that I can't get another agent to settle on, I want you to ignore commits and when they happened. I need to know what needs to be established so you can do this ticket." Method: write each finding as a checklist item, review the relevant context, and show the evidence before marking it complete | G-01 was resolved only from current code, repo rules, tickets and precedent. Commit order and timing are not evidence for it. The E1–E10 table is that output |
| 2026-09-29 | Asked whether "Europa" meant europa-back-end or the Europa page in atlas-front-end | The Terms table. This ledger names the repo each time |
| 2026-09-29 | "Reconcile for the locked decisions", against a review that checked E1–E10 and LD-001–LD-015 against the current `INT-138` code only; "Then update the spec accordingly" | No decision reopened. E9 withdrawn; E10 corrected; E2 and E3 annotated; LD-015 wording narrowed; LD-001 and LD-013 no longer cite E9; G-03 and G-08 now cite code; the LD-002 prerequisite added to the scope list; a new open item for stored `CATEGORIZE` records. The spec was updated to match |

## Locked-decision ledger

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 | **Callisto sends structured state; europa-back-end builds the path text.** This applies to both `CATEGORIZE` and `RECATEGORIZE` | E4 (precedent), E5 (old → new), E2 (europa-back-end in scope). **Revised 2026-09-29 (review):** E9 withdrawn as support | **Rejects** a path string built in Callisto. **Conflicts with** INT-138 LD-007 ("Europa is unchanged"; "Rejects 'Europa builds the path'"). That INT-138 entry is not edited here (see Open items) | INT-139 spec §Contract |
| LD-002 | **Structured state fields.** Callisto's `ResourceState` gains `deliverableType?: string \| null` and `collection?: string \| null`. A `CATEGORIZE` record sends `oldState` = `newState` = `{ path: filePath, bucket, fileName, deliverableType, collection }`: names or null, with no labels, separators or `N/A`. europa-back-end's `CATEGORIZE` branch already reads these fields (`search-audit-events-paginated.transaction.script.ts:76-85`). atlas-front-end does not change | E1, E6 | This is an INT-138 change INT-139 depends on: today Callisto sends the labelled string (E1) | INT-139 spec §Prerequisites |
| LD-003 | **`RECATEGORIZE` state.** `oldState` carries the file's deliverable type and collection names from before the recategorize; `newState` carries them from after. `path`, `bucket` and `fileName` are the same in both | INT-139.md:31-35; E5 | **Rejects** copying one string into both states | INT-139 spec §Converter |
| LD-004 | The event type is **`RECATEGORIZE`**, added to Callisto `AUDIT_EVENT_TYPE` (`src/audits/constants.ts`) and atlas-front-end `eventTypes` with identical spelling | INT-139.md:23; INT-138 LD-010 | — | INT-139 spec §Event type, §Atlas |
| LD-005 | The recategorize action sends **`RECATEGORIZE` instead of `CATEGORIZE`**, never both. Upload, approve v1/v2 and unapprove keep sending `CATEGORIZE` | INT-139.md:23 ("for this action"); one action, one record | **Supersedes** INT-138 LD-009's recategorize path (D) once INT-139 lands. Knock-on edits: INT-138 test plan M-1 expects `RECATEGORIZE` rows; the recategorize service and TS specs that expect a `CATEGORIZE` dispatch change | INT-139 spec §Dispatch |
| LD-006 | europa-back-end's paginated search TS gains a `RECATEGORIZE` branch that builds `Filepath: <newState.path> \| Deliverable Type: <old> → <new> \| Collection: <old> → <new>`. Each side shows `N/A` when its value is null, empty or whitespace (existing `toDisplayValue`, `search-audit-events-paginated.transaction.script.ts:120`), which covers a file with no type before the recategorize | INT-139.md:29-35; E4 (`PERMISSIONS_UPDATED` already uses ` → ` and ` \| `) | — | INT-139 spec §Europa |
| LD-007 | One record per processed file, each with one `FILE` resource | INT-139.md:27 ("Resource Type for this action is: File"); INT-138 LD-005 (europa-back-end shows only resource `[0]`) | — | INT-139 spec §Dispatch |
| LD-008 | A recategorize that leaves the type and collection unchanged still sends a record, which reads `Transcript → Transcript` | INT-138 LD-013 | **Rejects** an unchanged-value filter | INT-139 spec §Dispatch |
| LD-009 | The old values come from the batch file's `currentDeliverableTypeId` / `currentDeliverableCollectionId`, which are already loaded. Their names are resolved in `FileCategorizationAuditAssembler`'s existing `findByIds` calls, together with the new ids. There is no new read for ids. The recategorize TS stops passing `priorCategorization: null` (`recategorize-deliverable-files.transaction.script.ts:191`) | G-05 | — | INT-139 spec §Callisto |
| LD-010 | Only `/search-paginated` builds the path text. `/search` keeps returning the stored `newState.path` | E7 | — | INT-139 spec §Europa |
| LD-011 | atlas-front-end adds `'RECATEGORIZE'` to `eventTypes` and `MULTI_PART_PATH_TYPES` (`src/europa/utils/constants.ts`). There is no `eventTypeColors` entry, so the chip shows the grey fallback | G-07; E8 (the existing splitter already handles `old → new` values) | **Rejects** choosing a chip colour without a convention | INT-139 spec §Atlas |
| LD-012 | No migration, no route, DTO or swagger change (the recategorize request and its `{ processedFileIds }` response are unchanged), and no europa-back-end schema change (`oldState` / `newState` are `type: Object`) | E6; `recategorize-deliverable-files.service.ts` returns `{ processedFileIds }` | — | INT-139 spec §Non-goals |
| LD-013 | INT-139 branches from `INT-138` in all three repos | G-08. **Revised 2026-09-29 (review):** E9 withdrawn as support | — | Ledger note |
| LD-014 | europa-back-end deploys with or before Callisto. A record sent earlier shows its raw S3 key until then, and displays in full afterwards, because the text is built when the record is read | E10 | Accepted cost of LD-001 | INT-139 spec §Rollout |
| LD-015 | Free-text search does not find these records by **deliverable-type or collection name**; Ops finds them with the Event Type filter. **Revised 2026-09-29 (review):** wording narrowed from "type or collection name", because free text does match the event `type` (E10) | E10; neither ticket asks for that search | Accepted cost of LD-001 | INT-139 spec §Non-goals |

## Evidence for G-01 (where the path text is built)

Established 2026-09-29 from the code as it stands, with commit history and timing excluded by user direction.

| # | Question | Evidence | Result |
| --- | --- | --- | --- |
| E1 | What does each repo do with the `CATEGORIZE` path today? | Callisto writes the finished labelled string into both `oldState.path` and `newState.path` (`callisto-back-end/src/proceedings/domain/sub-domains/proceeding-file-audit/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/proceeding-file-categorization-to-audit.converter.ts:40-49`). Its `ResourceState` has no `deliverableType` or `collection` field (`callisto-back-end/src/audits/domain/domain-events/audit-event-resource.de.ts:12-17`). europa-back-end's `CATEGORIZE` branch adds labels itself, reading `state.path`, `state.deliverableType` and `state.collection` (`europa-back-end/src/audits-event/domain/transaction-scripts/search-audit-events-paginated-TS/search-audit-events-paginated.transaction.script.ts:76-85`) | The repos contradict each other. Together, a row reads `Filepath: Filepath: … \| Deliverable Type: … \| Collection: … \| Deliverable Type: N/A \| Collection: N/A`. One side has to change |
| E2 | Does either ticket name the service that builds the text? | Both tickets give only the displayed format (INT-139.md:29-35) and where Ops sees it ("Ops can view a log in Europa", INT-139.md:11). INT-138's kickoff scope includes `europa-back-end` (INT-138-original-ticket.md:39) | The tickets don't decide it. europa-back-end is in scope, so changing it is allowed. The 2026-09-29 review excluded E2 because its brief was code only; it did not contradict E2. LD-001 stands on E4 and E5 without it |
| E3 | Do the repo rules decide it? | In `.cursor/rules/` of callisto-back-end (9 files) and europa-back-end (6 files), a search for display, presentation, label and human-readable finds only the generic converter line "Transform data between different representations" (`architecture-patterns.mdc:258`, in both) | The rules don't decide it. **Excluded 2026-09-29 (review):** rule files in the other repos are treated as documentation under the user's direction. No decision cites E3 |
| E4 | What does the precedent for the same pair do? | `PERMISSIONS_UPDATED`: Callisto sends raw values, `resourcePath: entry.resourceKey`, `oldState: { path: entry.oldActions.join(', ') }`, `newState: { path: entry.newActions.join(', ') }` (`callisto-back-end/src/generic/auth/domain/sub-domains/infrastructure/dispatchers/permissions-audit-dispatcher/permissions-to-audit-event.assembler.ts:20-23`). europa-back-end builds `` `${r.resourcePath}: ${oldPath} → ${newPath}` `` joined with ` \| ` (`search-audit-events-paginated.transaction.script.ts:64-71`) | Callisto sends the values; europa-back-end builds the labels and arrows |
| E5 | Which design can carry INT-139's old → new? | The ticket requires `[old] → [new]` for both the type and the collection (INT-139.md:33-35). Both repos give each record separate `oldState` and `newState` (callisto `audit-event-resource.de.ts:8-9`; europa-back-end `audit-event-resource.entity.ts:16-30`). Callisto currently copies one string into both (E1) | Structured: old names in `oldState`, new names in `newState`, the same pattern as E4. Callisto-built: one string stored in both, so `oldState` holds no old values |
| E6 | Does europa-back-end store the extra state fields? | The listener passes `JSON.parse(message.Body)` to `auditEventService.create` (`sqs-audit-event.listener.ts:21-26`). The service and `CreateAuditEventTS` pass it on unchanged, and the repository saves it with `new this.auditEventModel(auditEvent)` and `.save()` (`audit-event.repository.ts:33`, `:39`). Nothing maps or filters fields. `oldState` / `newState` are `@Prop({ required: true, type: Object })` (`audit-event-resource.entity.ts:16`, `:24`), which Mongoose stores as a free-form object with every key kept | Stored as sent. Established from the schema; not yet observed in a stored record (see Open items) |
| E7 | Which europa-back-end endpoint does Atlas read? | atlas-front-end calls only `/search-paginated` (`src/europa/pages/HomePage/requests/fetchAuditEvents.ts:45`). europa-back-end's `/search` returns the stored `newState.path` (`audit-event-to-search-response-dto.converter.ts:9-14`), and `PERMISSIONS_UPDATED` is already unformatted there | Building the text in the paginated search TS is enough |
| E8 | Does the choice affect Atlas? | atlas-front-end splits `path` on ` \| ` and then at the first `: ` (`SearchDataGrid.vue:83-85`). Both designs deliver the same string. Dynamic collection names cannot contain `:` or `\|` (`callisto-back-end/src/granting-client-access/validators/validate-dynamic-collection-name.validator.ts:7`) | Atlas is unaffected either way |
| E9 | Does released data limit the choice? | ~~`git grep -nw CATEGORIZE origin/main -- src` finds no matches in callisto-back-end, europa-back-end or atlas-front-end (run 2026-09-29)~~ | **Withdrawn 2026-09-29 (review):** `origin/main` is not the checked-out code, and the absence of a literal in source does not show that no records exist in deployed storage. Whether released data exists is not established (see Open items). No decision cites E9 |
| E10 | What does the structured design cost? | europa-back-end builds the text when the record is read (`toItemProjection`, `search-audit-events-paginated.transaction.script.ts:56`). Until the new branch is deployed, a record falls through to the default branch and shows its raw S3 key (`:86-97`). Free-text search matches identity email and names, event `type`, `serviceName`, `resourceName`, `resourceType`, `oldState.path`, `newState.path` and `resourcePath` (`search-params-to-mongo-query.converter.ts:84-100`); it does not match `deliverableType` or `collection`. **Corrected 2026-09-29 (review):** the earlier text said free text matched only the two state paths | Two costs, neither blocking: deploy order (LD-014) and the search limitation (LD-015). The `type` match is a case-insensitive substring, so a free-text search for "categorize" also returns `RECATEGORIZE` records |

## Scope assessment

INT-139 extends INT-138's audit chain. There is no migration, API change or europa-back-end schema change (LD-012).

### Already provided by INT-138

- **Dispatch:** recategorize already sends one record per processed file after its transaction commits (`recategorize-deliverable-files.service.ts:52`), through port → aggregator → dispatcher → event assembler → categorization converter, with resource type `FILE`.
- **Old values:** already loaded on each batch file (G-05).
- **Name lookup:** `FileCategorizationAuditAssembler` resolves type and collection names by id, one query each per batch, inside the transaction.
- **Atlas display:** the Event Type dropdown list and the multi-line path rendering exist. The splitter cuts each part at its first `': '`, so `Deliverable Type: Transcript → Word Document` renders as label and value without change.

### Changes INT-139 adds

**callisto-back-end** (about 11 source files, plus their specs)

0. **Prerequisite (LD-002), added 2026-09-29 (review):** add `deliverableType?: string | null` and `collection?: string | null` to `ResourceState` (`src/audits/domain/domain-events/audit-event-resource.de.ts:12-17`), and change the categorization converter so `CATEGORIZE` also sends structured state instead of the labelled string it builds today (`proceeding-file-categorization-to-audit.converter.ts:32`, `:40-49`). Without this, europa-back-end keeps producing the double-labelled row in E1. It is part of INT-139 unless INT-138 makes it first.
1. Add `RECATEGORIZE` to `AUDIT_EVENT_TYPE` (`src/audits/constants.ts`).
2. Pass the real old ids from the recategorize TS instead of `priorCategorization: null` (`recategorize-deliverable-files.transaction.script.ts:191`).
3. Have `FileCategorizationAuditAssembler` and `FileCategorizationAuditProjection` also return the old names.
4. Add `dispatchFileAuditRecategorizedEvent` to `ClientAccessFileAuditPort` and `ProceedingFileAuditAggregator`. Widen the event-type field on `ProceedingFileAuditCategorizedParams`, which allows only `CATEGORIZE` today (`proceeding-file-audit-categorized.param.ts:11`), and carry the old categorization through `ProceedingFileToAuditEventAssembler`.
5. Build `oldState` from the old values in the categorization converter (LD-003).
6. Call the new port method from the recategorize service.

**europa-back-end**

- The `RECATEGORIZE` branch in the paginated search TS (LD-006), with specs.

**atlas-front-end**

- `'RECATEGORIZE'` in `eventTypes` and `MULTI_PART_PATH_TYPES` (LD-011). Extend `constants.spec.ts` and `SearchDataGrid.spec.ts`.

**Specs to extend:** recategorize TS and service specs; `FileCategorizationAuditAssembler` spec; categorization converter spec; event assembler and aggregator specs (the dispatcher passes params through unchanged, so its spec does not change); europa-back-end search TS spec; atlas-front-end `constants.spec.ts` and `SearchDataGrid.spec.ts`.

**Reference material:** callisto commit `e66c784c` removed an old-name lookup that INT-139 needs back, for recategorize only. Its file layout differs from the current code, so use it as a reference, not a cherry-pick.

## Open items

| Item | Area | Next action |
| --- | --- | --- |
| The repos disagree on the `CATEGORIZE` path (E1) | INT-138 | Change Callisto's `ResourceState` and categorization converter per LD-002 before INT-139 builds on them |
| INT-138 LD-007 ("Europa is unchanged"; "Rejects 'Europa builds the path'") contradicts LD-001 | INT-138 docs | Revise INT-138 LD-007 |
| INT-138 LD-009's recategorize path (D) is superseded by LD-005 | INT-138 docs | Record the supersession in the INT-138 ledger when INT-139 lands |
| Whether any deployed Europa holds `CATEGORIZE` records written with the labelled-string path is not established (E9 withdrawn) | INT-138 / INT-139 rollout | Check each deployed Europa before release. Any such record renders double-labelled once europa-back-end's `CATEGORIZE` branch is deployed, whether or not the prerequisite converter change has shipped, because that branch labels the stored `newState.path` again (`search-audit-events-paginated.transaction.script.ts:76-85`) |
| E6 is established from the schema only | INT-139 testing | On the end-to-end run, confirm a stored record keeps `deliverableType` and `collection` in both states |
| No INT-139 changelog | docs | Create `docs/atlas/INT-139-changelog.md` when implementation starts |
