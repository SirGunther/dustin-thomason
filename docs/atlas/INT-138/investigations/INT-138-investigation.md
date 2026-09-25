# Investigation Report: Categorize audit events for deliverable type categorization

> **What this is:** the results of running the `investigate` method on INT-138 inside the `orchestrate` lifecycle. It is written from the approved recon: [INT-138-recon-and-plan.md](./INT-138-recon-and-plan.md), which is frozen. **F1–F6** below refer to that doc's Findings section, which holds the full evidence tables.
> **What this is not:** a spec or a locked design. Decisions D1–D8 (§10) are open and go to Phase 3.

## Metadata
- **Status:** done (investigation)
- **Disposition:** proceed with conditions
- **Date:** 2026-09-23
- **Owner:** Dustin Thomason
- **Location:** `docs/atlas/INT-138/investigations/INT-138-investigation.md`
- **Ticket:** INT-138. Request text: [INT-138-original-ticket.md](../INT-138-original-ticket.md). The ClickUp URL was not captured.
- **Domain:** software
- **References / evidence:**
  - Baselines (all `main`, 2026-09-23): callisto `59b1abd3`, europa `1082fdad`, atlas `26eaa0bb`.
  - [Coverage ledger](./INT-138-coverage-ledger.md), [diagrams](./INT-138-diagrams.md), [job story 01](../stories/INT-138-job-story-01-categorization-audit.md), [why doc](../INT-138-why-these-changes.md), [concerns](../INT-138-future-development-concerns.md).

---

## 0. Verdict (bottom line up front)

**This is viable and smaller than the ticket's framing suggests.** The ticket reads like a new Europa log feature. It is really a **gap in the audit events Callisto sends**, on write paths that already feed an existing log.

- **The pieces already exist:** Europa already stores, filters and returns any event-type string, and the `FILE` resource type exists everywhere.
- **Three things are missing:**
  - an event that carries the deliverable type and collection;
  - any audit at all on **recategorize**;
  - the literal in Atlas's hand-maintained dropdown list, plus a multi-line render for the path.
- **Strongest path:**
  - Callisto emits one new event per categorized file from the service layer, after commit, reusing the proceeding-file-audit chain. The event carries a pre-formatted `Filepath | Deliverable Type | Collection` string in `newState.path`.
  - Atlas adds the literal and its colour, and extends the existing `PERMISSIONS_UPDATED` multi-line path render to cover it.
  - **Europa is untouched.**
- **Not yet proven / not approved:**
  - Which paths emit (D1) and the event's literal and label (D2) are unresolved Product decisions, and **both gate the spec**.
  - No live Callisto→SQS→Europa→Atlas event has been observed. That is proven in code only (the coverage-ledger frontier).
  - This is not a design approval. The spec reviewer (D8) owns that.

## 1. Problem class

- **Class the request assumed:** a new audit-log capability in Europa for Client Access actions. *Ticket text:* "Ops can view a log in Europa for **deliverable type categorization**"; "This event type is added to the Event Type drop down in Europa".
- **Confirmed class:** **a gap in the audit events sent from existing write paths.** The log, storage, filter, UI and resource type exist. The event is what's missing.
- **Reframed?** Yes. It moved from *new log capability (Europa)* to *audit coverage gap (Callisto emit + Atlas label)*.
  - *Trigger:* Step 1/2 evidence showed that Europa accepts any `type` string with no enum (F3), and that the dropdown is an `atlas-front-end` constant (F4).
  - *Step 4 confirmed it:* recategorize dispatches no audit (F1-D), and the approve and upload audits predate deliverable types (F2).
- **What the confirmed class implies:**
  - No new storage, endpoint, index or Europa deploy.
  - The work is: emit an event (Callisto), register a literal (Atlas), and render the path (Atlas).
  - The class also names the right regression guard: every write path that categorizes a file must be proven to audit.
  - Precedent in the same class: PRDV-12578 (`5ee0c174`), which added the `APPROVED`/`UNAPPROVED` audits.

## 2. Problem statement

- **Named instances:** none named in the ticket. The instance is structural and code-proven: **every recategorize performed today produces no audit record** (`recategorize-deliverable-files.service.ts:24-44` calls only the TS). No specific Ops user or case is named. A live observation is on the frontier.
- **One sentence:** when a file's deliverable type or collection is set or changed, the audit log records none of it (type, collection, who, when), and for recategorize it records nothing at all.
- **Distinct problems:**
  1. No record of what categorization was applied. This is a Callisto emit gap.
  2. No way to narrow the log to categorization. There is no event type, and it's missing from Atlas's literal list.
  Solving 1 without 2 leaves records Ops can only find by searching text. Solving 2 without 1 gives an empty filter.
- **Urgency:** the ticket gives no date or trigger. Open (D7).
- **Wedge:** recategorize, the only categorizing path with **zero** audit. The per-file Categorize builder written for it is reused as-is on approve and upload if D1 includes them, so it opens the rest of the class.

### Problem Check

- **Asked:** a log of categorization with named fields, a new event type, a resource type and a path format.
  - *Evidence:* "Ops can view a log in Europa for **deliverable type categorization**"; "A new Event Type is created for this action: **Categorize**"; "Resource Type for this action is: **File**"; "Path format: Filepath… Deliverable Type… Collection…".
- **Answered:** the ticket fixes *what a record shows*. It does not fix *which actions produce one*. It works on the display contract and leaves the emission trigger implicit.
  - *Evidence:* "The log displays the following details: file path, user info, date/time, **categorization** actions taken". "Actions" is never enumerated.
- **Should-ask:** *which write actions count as a categorization, and does each file get its own record?* This decides how many code paths change and whether batch operations are visible per file (§10 D1; story criterion 7).
- **Conflation:**
  - The story's motivation covers a class of actions; the criteria cover one action. *Evidence:* "an audit log of key actions related to Client Access" → "a log in Europa for **deliverable type categorization**" (OQ-09 → D6).
  - "Categorization" also bundles first-time categorization (upload or approve) with recategorization, which are separate code paths with different audit states today (F1).
- **Thin:**
  - "user info": which details? Resolved in §8 as parity.
  - "file path": readable, or the storage key? The fact is resolved in §8; the decision is D4.
  - "if applicable": when does a collection apply? Resolved in §8.
  - "categorization actions taken": one value, or old→new? D3.
  - *Evidence:* "user info"; "Filepath: \[file path\]"; "Collection: if applicable, \[collection\], if not, "N/A"".
- **Off:**
  - (a) The event name breaks the naming convention: "A new Event Type is created for this action: **Categorize**" → all 8 existing types are past-tense upper case (`CREATED` … `PERMISSIONS_UPDATED`, `src/audits/constants.ts:10-19`), and Atlas shows them raw (D2).
  - (b) The dropdown's location: "This event type is added to the Event Type drop down **in Europa**" → the dropdown's options are `atlas-front-end` `src/europa/utils/constants.ts:3-15`, and the Europa backend has no enum to add to (F3/F4). This is a location mismatch in the wording, not a contradiction in intent.
  - "Resource Type… File": nothing here, since `FILE` already exists.

## 3. The contract

### Acceptance criteria (story 01, [file](../stories/INT-138-job-story-01-categorization-audit.md))

| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| 1. Every categorization of a file's deliverable type shows up in Europa's audit log | needs-proof | D1 settles which paths count. Then one Categorize dispatch per categorized file on each of them, proven by service specs |
| 2. Each categorization record shows who did it and the date and time | covered (parity) | `identity: user.identity` + `createdAt`, the same as the existing converter. Europa returns `userEmail`, `userName` and `createdAt` (F3). Assert in the converter spec |
| 3. Each record reads Categorize as its action and File as what was acted on | needs-proof | `FILE` exists. The literal depends on D2 / OQ-10 |
| 4. Each record reads "Filepath: …", "Deliverable Type: …", "Collection: …", in that order | needs-proof | Callisto builds the string. Atlas renders it multi-line (F4). Needs a converter spec and the first `SearchDataGrid` path spec |
| 5. When no collection applies, the record reads "Collection: N/A" | needs-proof | A null `deliverable_collection_id` after the action gives `N/A` (F5). Converter spec |
| 6. Ops can narrow the audit log to just Categorize records | needs-proof | The literal goes in Atlas `eventTypes`. Europa's exact-match filter already works (F3). The literals must be byte-identical across Callisto and Atlas |
| 7. When several files are categorized at once, each file gets its own record | needs-proof | One event per file, never N resources per event, because Europa shows `[0]` only (F3). Service spec with N>1 files |

### Non-goals / out of scope
- Other Client Access actions: grants, rename, approve and unapprove are already audited. Pending D6.
- Europa's `[0]` resource collapse for multi-resource events (PRDV-16192). It is moot here because each event has one resource.
- Dione outbox events (`file.recategorized.v1`): a separate channel, and must not change.
- Role gating of the audit log API. That is an existing concern, not this ticket.
- A general label layer for all event types. Only in scope if D2 demands a label for this one.
- Backfill of past categorizations. Pending D5, with none recommended.

## 4. What changed since the request was created
- **Shifted from:** "create an event type in Europa and add it to Europa's dropdown" → **to:** "emit a new event from Callisto's categorization paths, and register and render it in Atlas; Europa unchanged". This is a class change (§1).
- **What that buys us:** one fewer repo deployed, no schema or index work, and no Europa swagger change (F3).
- **What it still needs to prove:**
  - the literal matches byte-for-byte across two hand-maintained lists;
  - an end-to-end event renders as specified;
  - the recategorize path can supply `filePath`, `bucket` and names, which its projection lacks today (F5).

## 5. Why it exists
- **Origin traced to:**
  - The file audit chain (`ProceedingFileAuditAggregator` → dispatcher → `ProceedingFileToAuditEventAssembler` → `proceeding-file-to-audit.converter.ts:18-37`) carries only `{path, bucket, fileName}`.
  - `APPROVED`/`UNAPPROVED` were added in PRDV-12578 (2025-09), before deliverable types and collections existed (migrations `1781121204471`–`73`).
  - Recategorize was built later with only the Dione outbox wired. Its service never calls the aggregator.
- **Evidence:**
  - `callisto` `recategorize-deliverable-files.service.ts:24-44`, `recategorize-deliverable-files.transaction.script.ts:117-148`, `approve-deliverable-files-v2.service.ts:140-146`, `deliverable-upload.service.ts:112-115`, `src/audits/constants.ts:10-19`.
  - `europa` `search-audit-events-paginated.transaction.script.ts:57-100`, `search-params-to-mongo-query.converter.ts:38-46`.
  - `atlas` `src/europa/utils/constants.ts:3-30`, `SearchDataGrid.vue:309-324`.
- **Data paths:** see [INT-138-diagrams.md](./INT-138-diagrams.md). It holds the current-vs-target view of paths A–G and the recategorize → Atlas sequence.
- **Contract alignment:**
  - The authority for the event is Callisto (`AUDIT_EVENT_TYPE` + the proceeding-file-audit converter).
  - Europa mirrors nothing, because it stores a free string.
  - Atlas mirrors the literal list **by hand** (`eventTypes`). It already carries literals Callisto never sends (`MOVED`, `UPDATED`), which shows the two lists already disagree.
  - Because the filter is an exact, case-sensitive match, a one-character mismatch makes the Categorize filter return nothing, silently.
  - Re-drift risk is recorded as concern C4.
- **Detection gap:**
  - The recategorize service spec has **no** audit assertion, while the approve v1/v2, upload and unapprove service specs each assert their dispatch (F2/§coverage 5).
  - No test ties the Atlas literal list to Callisto's enum.
  - Atlas has zero specs for `SearchDataGrid`, `constants.ts` or `SearchFilters`.
  - So nothing could have caught a silent path, or a literal that doesn't match.
- **Class re-check:** held. The root-cause evidence (a silent service, old event shape, a hand-mirrored list) is exactly an audit coverage gap.

## 6. Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| Europa builds the path from structured state, as the `d71f2bd` `PERMISSIONS_UPDATED` branch does | Europa doesn't know the type or collection names. Extra state keys aren't returned in the projection. It would add a second type-specific branch and a Europa deploy for no gain |
| Add type and collection to the existing `APPROVED`/`CREATED` events | The ticket requires a distinct event type ("A new Event Type is created"). Recategorize has no event to extend |
| One event per batch with N resources (as `MERGED` does) | Europa shows only `auditEventResources[0]` (`:98-100`), so N−1 files would be invisible. That fails criterion 7 |
| Atlas formats the path from structured fields | Only the `path` string crosses the wire (`SearchAuditEventItem`) |
| Emit from inside the recategorize transaction | Breaks the post-commit precedent (upload, approve and unapprove all dispatch after the TS returns). A rollback could audit a change that never happened |
| Gate Categorize behind `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED` | No Europa audit is flag-gated (F6). Gating would hide categorizations made with the flag off |

## 7. Solution & stress-test
- **Proposed solution** (to be locked in Phase 3):
  1. **Callisto:**
     - Add the literal to `AUDIT_EVENT_TYPE` (D2).
     - Add `dispatchFileAuditCategorizedEvent` to `ProceedingFileAuditAggregator`.
     - Add a categorization params type and a converter:
       - `newState.path = "Filepath: <filePath> | Deliverable Type: <type> | Collection: <collection ?? 'N/A'>"`;
       - `oldState` carries the prior categorization (D3);
       - one FILE resource, with parity for `resourceName`, `resourcePath` and `resourceBucket`.
     - Dispatch from the **service after the TS returns**, once per processed file:
       - recategorize (D) must also surface `filePath`, `bucket` and bulk-loaded names;
       - approve (B/C) and upload (A) only if D1 includes them.
  2. **Europa:** no change.
  3. **Atlas:**
     - Add the literal to `eventTypes` and a colour to `eventTypeColors`.
     - Extend the `SearchDataGrid.vue:311` condition.
     - Add the first specs for the literal list and the path render.
- **Solves the confirmed class?** Yes. Every user path that categorizes gets an event with the categorization in it. The regression guard is a service spec per path.
- **Scale:** N files → N SQS messages, the same as approve today. Name lookups cost O(distinct type and collection ids) per request.
- **Generalization:** one converter and one aggregator method. No generic "categorization audit framework". Nothing beyond what 3–4 call sites need.
- **Fit:**
  - It reuses the proceeding-file-audit sub-domain and service-level dispatch, like the siblings.
  - The formatted `newState.path` string has precedent in Callisto (`PermissionsToAuditEventAssembler`).
  - Where the new converter and assembler live, and how names are looked up across modules, is checked against callisto `.cursor/rules` (TS→TS forbidden, port indirection). That is on the coverage-ledger frontier and resolved in Phase 3.
- **Adjacent issues:** all are follow-ups, recorded in [concerns](../INT-138-future-development-concerns.md), none in scope:
  - C1: no role checks on Europa's API.
  - C2: SQS failures are silently logged.
  - C3: `ON DELETE SET NULL` uncategorizes files with no audit.
  - C4: Atlas and Callisto literal drift.
  - C5: unapprove clears categorization.
  - C6: the recategorize DTO's id doc string is wrong.
  Fixing any of them now would widen the blast radius past the story.
- **Sufficiency:** it covers the categorization the criteria describe. The broader "key actions related to Client Access" is D6.
- **Feedback speed:**
  - Unit specs report in seconds.
  - The end-to-end check needs local Callisto + Europa + SQS, or a sandbox. The repro recipe is below. Sandbox feedback is roughly a day, so that is the slow loop to plan around.
- **Repro recipe:**
  - Run Callisto locally with `SQS_AUDIT_EVENT_URL_OUTBOUND` pointed at the queue Europa's `SqsAuditEventListener` consumes (per `docs/atlas/local/callisto-local.mdc` and `europa-local.mdc`). Run Europa locally against its Mongo.
  - Open Atlas `/europa-stuff` as a user whose role has `AUDIT` + `READ`.
  - Use a proceeding with Client Access enabled that has Transcript and Exhibits deliverables.
  - Recategorize, approve and upload, then filter Event Type = the new literal.
  - Precondition: `AUDIT_EVENT_QUEUE_NAME` unset, or equal to `SQS_AUDIT_EVENT_URL_OUTBOUND`. The producer sends to that fixed name.
- **Happy-path story:** a staff user moves two transcripts into the "Full Transcript" collection. A minute later, an Ops manager opens the audit log, picks the Categorize event type, and sees two rows. Each row names the user and time, and a Path that reads *Filepath / Deliverable Type / Collection* on three bolded lines. Nobody had to ask engineering who did it.

## 8. Assumptions ledger

These are facts settled or to be settled by discovery.

- **Claim:** Recategorize dispatches no Europa audit.
  - **Status:** confirmed. `recategorize-deliverable-files.service.ts:24-44`; the TS (`:48-148`) writes only the Dione outbox.
  - **Confirm/revise by:** a red→green service spec (it fails today).
- **Claim:** The list of paths writing a file's categorization is closed at A–G (F1).
  - **Status:** confirmed directionally. The entity is injected into 3 repositories, the setter callers are enumerated, and there is no runtime raw SQL.
  - **Confirm/revise by:** the grep is re-run at Phase 3 on the then-current `main`. It remains possible that a loaded `File.fileAttachment` cascade save changes categorization (`file.entity.ts:48`). Treat that as the residual.
- **Claim:** Europa needs no code change to store, filter or return a new type.
  - **Status:** confirmed. `type` and `resourceType` are `@IsString` only, with no enum anywhere. The filter is exact-match (`:38-46`), and the projection passes `newState.path` through (`search-audit-events-paginated.transaction.script.ts:57-85`).
  - **Confirm/revise by:** the live end-to-end check (frontier).
- **Claim:** Europa shows only the first resource of an event.
  - **Status:** confirmed. `firstResource` is used at `:57, :98-100`, except for `PERMISSIONS_UPDATED`.
  - **Confirm/revise by:** n/a.
- **Claim:** A pre-formatted path using `' | '` and `': '` renders as bold-labelled lines if Atlas's condition includes the new type.
  - **Status:** confirmed in code (`SearchDataGrid.vue:311-321`; `slice(1).join(': ')` preserves colons inside values).
  - **Confirm/revise by:** the first `SearchDataGrid` spec, and the manual check.
- **Claim:** Collection names can't break the `' | '` split.
  - **Status:** confirmed for dynamic names (`/[\\/:*?"<>|%]/` is rejected, `validate-dynamic-collection-name.validator.ts:7`). Confirmed for deliverable types in seed `1781121204472`.
  - **Confirm/revise by:** check seed `1784739200003` (Planet Suite) for `' | '` in Phase 3 (frontier).
- **Claim (closes OQ-04):** "user info" and "date/time" means parity with existing records.
  - **Status:** confirmed. `identity: user.identity` is the whole user (`proceeding-file-to-audit-event.assembler.ts:32-39`). Europa returns `userEmail`, `userName` and `createdAt`, and Atlas shows User Email, User Name and Date (Local/UTC).
  - **Confirm/revise by:** n/a.
- **Claim (closes OQ-06):** a collection applies only on Transcript and Video tracks, and `N/A` is shown whenever `deliverable_collection_id` is null after the action.
  - **Status:** confirmed. `deliverable-collection.constants.ts:3-6`; the approve-v2 required-collection validator (`:52-77`); upload and approve v1 don't enforce it.
  - **Confirm/revise by:** n/a.
- **Claim (closes OQ-08):** Categorize records inherit the audit log's existing access.
  - **Status:** confirmed. The Atlas route requires `AUDIT` + `READ` (`src/globalRouter/routes.ts:35-52`). There is no per-type access in Europa.
  - **Confirm/revise by:** n/a.
- **Claim (fact half of OQ-02):** no path records type or collection today. Upload, approve and unapprove send `CREATED`, `APPROVED` and `UNAPPROVED` with `{path, bucket, fileName}` only; recategorize and the transcript summary send nothing.
  - **Status:** confirmed (F1/F2).
  - **Confirm/revise by:** n/a.
- **Claim (fact half of OQ-05):** "path" on existing FILE records is the S3 key (`file.filePath`), and the readable name is the Resource column.
  - **Status:** confirmed. `proceeding-file-to-audit.converter.ts:18-37`; `get-deliverable-file-key.ts:18`; `auditEventColumns.ts:30-46`.
  - **Confirm/revise by:** n/a.
- **Claim (fact half of OQ-07):** Callisto keeps no who/when history for past recategorizes.
  - **Status:** confirmed directionally. `file_attachments` has no modified-by identity (PRDV-16313 ledger area 10). The only partial trace is Dione outbox rows, written only with GCA on.
  - **Confirm/revise by:** only if D5 = backfill. In that case, check outbox retention.
- **Claim:** The recategorize path can supply `filePath`, `bucket` and names with a projection change plus bulk lookups.
  - **Status:** open. The batch projection lacks `filePath`/`bucket` (`recategorize-deliverable-files-data.projection.ts:5-13`), and `DeliverableTypeRepository.findById` / `DeliverableCollectionRepository.findById` exist.
  - **Confirm/revise by:** Phase 3 traces the bulk-lookup methods and module boundaries (frontier).
- **Claim:** Approve's `processedFiles` (`File[]`) carries enough to build the path (`filePath`, `bucket`, and type and collection ids via the attachment).
  - **Status:** open.
  - **Confirm/revise by:** Phase 3 reads `approve-deliverable-files-projection.converter.ts` and the `File` load shape (frontier).
- **Claim:** Upload-complete sets a deliverable type only when the client sends one. With GCA off it may be null, and then there's nothing to categorize.
  - **Status:** open.
  - **Confirm/revise by:** Phase 3 reads `upload-complete…script.ts` and `CreateDeliverableFileAttachmentAssembler` (frontier).

## 9. Validation plan

**Happy path**
- Recategorize 2 Transcript files into an existing static collection. You get 2 events, one resource each, with type = the literal, `resourceType: FILE`, and `newState.path` = `Filepath: <key> | Deliverable Type: <name> | Collection: <name>`.
- Approve v2 with a type and a collection (if D1). One event per processed file.
- Upload an Exhibits deliverable with a type (if D1). One event, with `Collection: N/A`.
- Europa `GET /audit-events/search-paginated?type=<literal>` returns exactly those events, and `resourceType=FILE` still matches.
- Atlas: the dropdown lists the literal, the chip is coloured, and Path renders three bolded lines. User Email, User Name and Date are populated.

**Negative paths**
- Recategorize fails validation (mixed tracks, bad collection) → 400 and **no** event.
- The transaction rolls back → **no** event, because dispatch happens after the TS returns.
- The SQS send fails → logged and returns `false`; the request still succeeds (parity). The loss is visible in logs only (concern C2).
- Unapprove → **no** Categorize event. Its `UNAPPROVED` is unchanged.
- An approve with already-deliverable files (skipped) → no Categorize for the skipped files.
- A move into a newly created dynamic collection → the path shows the new name, not an id.
- The literal differs between Callisto and Atlas (case or tense) → the filter returns nothing. A contract test must fail first.
- **Neighbors that must not change (verified unchanged):**
  - the count and shape of `CREATED`, `APPROVED`, `UNAPPROVED` and `RENAMED` events per path;
  - the Dione `file.recategorized.v1` payload;
  - the recategorize response `{processedFileIds}`;
  - `PERMISSIONS_UPDATED` path rendering in Atlas;
  - Europa, byte-identical.
- **Red→green:** `recategorize-deliverable-files.service.spec.ts` asserts one categorize dispatch per processed file. It fails on today's code.

**Affected surfaces (completeness):** see F1's completeness claim in the [coverage ledger](./INT-138-coverage-ledger.md). On the Atlas side, `eventTypes` is the only options source. `SearchFilters.vue` has no other list and `src/europa` has no i18n.

## 10. Decisions, recommendation & open variables
- **Decisions (settled):** none yet. This phase settles facts only (§8).
- **Recommendation:**
  1. Settle D1 and D2 with Product.
  2. Spec the Callisto emit and the Atlas literal and render (Phase 3).
  3. Implement recategorize first (the wedge), then approve and upload if D1 includes them.
  4. Atlas last, against a proven literal.
- **Sequencing & gates:**
  - Do not lock the spec until D1 and D2 are answered.
  - Do not write product code until the spec reviewer (D8) responds (Phase 5 gate).
  - Do not ship the Atlas literal without a test pinning it to Callisto's value.

### Open variables to collect

These are decisions only; every one is a choice, not a lookup.

- [ ] **D1** — Which paths emit Categorize: upload (A), approve v1/v2 (B/C), recategorize (D), unapprove (E), the system transcript summary (F), legacy approve (G)? Covers story OQ-01 and OQ-02's decision half. *Recommendation:* A, B/C, D; not E, F or G. — owner: Product
- [ ] **D2** — The event literal and how it displays: `CATEGORIZED` (convention, shown raw), `CATEGORIZE`, or a label layer showing "Categorize"? Covers story OQ-10, and criterion 3 depends on it. *Recommendation:* `CATEGORIZED`, with Product confirming criterion 3 or rewriting it on the record. — owner: Product + principal dev
- [ ] **D3** — Show old→new, or the new value only? Covers story OQ-03. *Recommendation:* store the prior value in `oldState` and display the new one, as the ticket's format does. — owner: Product
- [ ] **D4** — Should "Filepath" be the storage key (parity with every FILE record) or something readable? Covers the decision half of story OQ-05. *Recommendation:* parity. The Resource column already shows the file name. — owner: Product
- [ ] **D5** — Backfill past categorizations? Covers the decision half of story OQ-07. The evidence that the current structure can't reconstruct history: there is no modified-by identity on `file_attachments`, and no audit exists for recategorize. *Recommendation:* no backfill. — owner: Product
- [ ] **D6** — Is categorization all of INT-138? Covers story OQ-09. — owner: Product / principal dev
- [ ] **D7** — Urgency or target date. — owner: Product
- [ ] **D8** — Who reviews the spec, and where it lives (a Callisto-primary change touching Atlas). — owner: principal dev

---

## 11. Plan — Next steps

### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Resolve D1 | Product | The locked-decision ledger has an LD row naming exactly which of A–G emit |
| Resolve D2 | Product + principal dev | An LD row fixes the byte-exact literal, and story criterion 3 either matches it or is rewritten on the record |
| Resolve D3 | Product | An LD row says whether the Path shows the prior value; the spec's converter section matches |
| Resolve D4 | Product | An LD row defines what "Filepath" contains |
| Resolve D5 | Product | An LD row says backfill yes or no; if yes, a feasibility check on outbox retention is in the test plan |
| Resolve D6 | Product / principal dev | Story OQ-09 is closed, with scope stated in spec §Scope |
| Resolve D7 | Product | A date or "none" is recorded in the ledger notes |
| Resolve D8 | principal dev | The spec is submitted through the named reviewer's surface (PR link in the ledger), or recorded `not-applicable` with the owner named |
| Close the frontier facts (bulk lookups, approve load shape, upload type when GCA is off, Planet Suite names, `.cursor/rules` placement) | agent (Phase 3 reconcile) | Each frontier line in the coverage ledger has a status other than `not-inspected` |

### Checklist
#### Investigation
- [x] This report (Sections 0–10)

#### Project Spec
- [ ] Draft open questions / unknowns
- [ ] Create project spec

#### Development
- [ ] Create new branch
- [ ] Begin implementation

#### Testing & Validation
- [ ] Test and validate implementation locally

#### Deploy & PR
- [ ] Push to GitHub
- [ ] Deploy to sandbox + verify there
- [ ] Open PR
- [ ] Address feedback / wait for approval
- [ ] Merge to main
- [ ] Deploy to test

#### Ticket Closeout
- [ ] Update ClickUp: merged to test
- [ ] Set ticket to Ready for QA
- [ ] (If bug) Document root cause / why it slipped through

---

## 12. Definition of done (investigation gate)
- [x] Class derived from instances, re-confirmed against root cause, and "reframed?" answered with a justification (§1, reframed)
- [x] Problem Check recorded (§2), with each flag grounded in trimmed quotes
- [x] Problem in one plain sentence
- [x] Named blocked instance: **none named in the ticket.** A structural instance is code-proven (every recategorize today); stated rather than invented
- [x] Date it bites next: **not stated in the ticket.** Carried as D7 with an owner
- [x] Wedge, and why it's reusable within the class (§2)
- [x] Acceptance criteria and non-goals locked before the solution (§3)
- [x] Alternatives recorded with rejection reasons (§6)
- [x] 30-second happy-path story (§7)
- [x] Metric that proves it works: a Europa `type=<literal>` query returns one event per categorized file with the three-part path. It arrives in seconds via unit specs and about a day via sandbox (§7, §9)
- [x] Verdict and disposition stated (§0)
- [x] Every open question reconciled: facts in §8, only decisions in §10, each with an owner
- [x] Tracked actions with a falsifiable done-when (§11)

## 13. Post-Investigation Addendum — Phase 3 reconcile facts (2026-09-23)

> This addendum is appended, not edited in place. It resolves the §8 claims left `open` and the coverage-ledger frontier, using code only (callisto `59b1abd3`). The verdict (§0) and the class (§1) are unchanged. Evidence is in [coverage ledger](./INT-138-coverage-ledger.md) areas 9–10.

**Resolved §8 claims:**
- **Upload-complete sets a type only when the client sends one.** Status: **confirmed.** `deliverableTypeId` is optional at every layer, and it is saved as `null` when absent (`create-deliverable-file-attachment.assembler.ts:25-45`). The GCA-off Atlas client never sends it. Consequence: on path A, a file uploaded with no type has no deliverable type categorized. Whether that emits anything is folded into D1.
- **Approve's `processedFiles` carries the ids.** Status: **refuted.** They are bare `File` rows with no attachment loaded (`proceeding-file.repository.ts:215-219`). The per-file resolved type and collection ids exist only in the TS-local `plans` (`approve-deliverable-files.transaction.script.ts:140-154`). v2's new dynamic collection id is known only inside the TS (`:205-249`). Consequence: the approve TS projection must return per-file `{file, deliverableTypeId, deliverableCollectionId}` if D1 includes approve.
- **Recategorize can supply `filePath`, `bucket` and names.** Status: **confirmed, with changes:**
  - add `file.filePath` and `file.bucket` to the shared `fetchFilesByProceedingId` select (4 production callers, low risk because the GET listing converter copies explicit fields);
  - grow the TS return beyond `{processedFileIds}` to include the resolved collection id;
  - resolve names in GCA.
  There is no bulk lookup method on either repository, and `DeliverableCollectionRepository` is GCA-only.
- **Seeded type names are safe for the `' | '` / `': '` split.** Status: **confirmed.** No seed value contains either (`1781121204472`, `1784739200003`), and `DeliverableTypeRepository` has no save method.

**Architecture constraints the spec must honor** (dependency-cruiser, all `severity: error`):
- A TS may not import an aggregator, so dispatch happens in the service.
- A service may not import a converter, so the path formatter can't sit in the service.
- A converter may not import a repository, so names are resolved before the converter runs.
- An assembler may not import another assembler.

Resulting shape:
- A **GCA-side step** (the service, via repositories or a GCA assembler) resolves the type and collection names per file.
- It passes them to a new aggregator method.
- A **new converter in `proceeding-file-audit/infrastructure/dispatchers/proceeding-file-to-audit-event-assembler/`**, injected by the assembler, formats `newState.path`.
- Deviation to record in the spec: `architecture-patterns.mdc:1280` says "use ports for cross-domain communication". The GCA services already inject `ProceedingFileAuditAggregator` by class, which depcruise doesn't enforce for GCA. Follow precedent.

**Spec home (fact):** `callisto-back-end/docs/specs/<clickup-project-kebab>/…`, including the FE section (`atlas-front-end/docs/specs/README.md:5-12`; `callisto-back-end/docs/specs/README.md`). The precedent specs PRDV-15369 (recategorize story) and PRDV-16314 (recategorize endpoint) **never mention audit**, which confirms §5's origin.

**Open after this addendum:** only the §10 decisions, plus two new inputs that no artifact holds: INT-138's **ClickUp Project Name** (for the spec folder) and the **spec reviewer** (D8).
