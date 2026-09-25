# INT-138 — Phase 1 recon and plan (atlas/INT-138)

> This is the recon-and-plan doc. Once approved, Phase 2's first action saves it word for word as `docs/atlas/INT-138/investigations/INT-138-recon-and-plan.md`, and it is frozen from then on.
> Baselines: callisto `59b1abd3` · europa `1082fdad` · atlas `26eaa0bb` (all `main`, 2026-09-23).

## Context

Ops wants the Europa audit log to show who categorized a file's deliverable type, when, and what it was set to. The ticket asks for a new **Categorize** event type in the Event Type dropdown, resource type **File**, and a path that reads `Filepath / Deliverable Type / Collection (or N/A)`. Phase 0 drafted story 01 (6 criteria, 9 open questions). This recon traced all three repos to find where categorization happens, what the audit pipeline already does, and which open questions the code already answers.

**Headline:** this is not a new log. It is a **gap in what Callisto sends to the existing audit pipeline**:

- **Recategorize sends nothing to the audit log.**
- **Approve and upload** do send events, but without the deliverable type or collection.
- **Europa needs no code change.** It already stores and filters any event type string.
- **The dropdown lives in `atlas-front-end`.**

## Phase 1 checklist (from `steps.csv`)

- [x] `P1.consult` — ran before any code branch was opened (see Consult).
- [x] `P1.code-trace` — every question the code can answer was traced (see Findings and Reconcile).
- [x] `P1.method` — investigation steps 1–7 ran, Problem Check is included, and every open variable has an owner.
- [x] `P1.stage-story` — story reconcile is staged below.
- [x] `P1.stage-coverage` — consult line plus coverage rows are staged, each keyed to a commit.
- [x] `P1.stage-why` — problem class and the Phase 1 why-log entry are staged.
- [x] `P1.plan` — this doc: findings plus todos.

## Consult (the protocol runs first)

- **`docs/atlas/*/investigations/*-coverage-ledger.md`**, searched for "audit|event type|categoriz|europa": 7 ledgers matched.
  - **PRDV-16192: found and reused, with two areas reopened.** The Europa ingest (area 4) and storage (area 3) findings were reused without re-reading code. Callisto `src/audits` has not changed since `47f5a841` (`git log` empty). Two areas were reopened because the code changed since the recorded commit:
    - Europa paginated projection: commit `d71f2bd` (PRDV-16192) added a `PERMISSIONS_UPDATED`-only branch.
    - Atlas grid: `c2814144` added a multi-line path slot for `PERMISSIONS_UPDATED` only, and PRDV-14304 changed the date filters.
  - **PRDV-16312 and PRDV-16313: found, used only as pointers.** Their recategorize and outbox coverage is about Dione events, which is a different behavior. Their surface-enumeration notes (three dynamic-collection sites) were checked against the fuller enumeration below.
  - **The rest** (14184, 16402, 16403, 16461) matched only on "deliverable/collection" in unrelated behavior. Nothing reused.
- **`larry-adams`**, searched for "INT-138|Categoriz|audit log": there is no INT-138 spec.
  - `dione-file-access-event-design.md` covers Dione outbox events, not Europa audit. It confirms Callisto's file audit events are "created, approved, unapproved, renamed" and do not include recategorize.
  - `gca_consume_checklist.md` covers Dione consumer work. Not relevant.
- **`docs/system-architecture/.../domains/audit-log.md`**: its status is "Not written". Nothing to reuse.

## Findings

**F1 — Surface: every path that writes a file's categorization.**
- **Where it's stored:** `track_type_id`, `deliverable_type_id` and `deliverable_collection_id` on `file_attachments` (`file-attachment.entity.ts:39-54`).
- **Why the list is complete:**
  - The entity is injected into only 3 repositories.
  - The granting-client-access (GCA) repo's setters are called only by the approve TS (`:365,:369`), the recategorize TS (`:119`) and the unapprove TS (`:152,:156`).
  - The proceedings repo's `create()` is called only by submission upload (sets no type), the transcript summary, and video transcode (copies the track only).

| # | Path | Files per call | Audit sent today |
|---|---|---|---|
| A | `POST /granting-client-access/upload-complete` (also used by drag-and-drop) | 1 | `CREATED` (`deliverable-upload.service.ts:112-115`), with no type or collection |
| B/C | `POST …/approve-files-for-delivery` (v1) and `…/v2/…` | many | `APPROVED`, 1 event per file (`approve-deliverable-files-v2.service.ts:140-146`), with no type or collection |
| D | `PATCH …/recategorize-deliverable-files` | many | **none.** The service (`recategorize-deliverable-files.service.ts:24-44`) only calls the TS, which writes the Dione outbox and nothing else |
| E | `POST …/unapprove-files-for-delivery` | many | `UNAPPROVED`. It clears the type and collection |
| F | Mercury transcript-summary inbox (system, no user) | 1 | none. Sets the type to `Planet Summary` |
| G | Legacy `POST /proceedings/files/approveFilesForDelivery` | many | `APPROVED`. It only adds the tag; type stays null |

**F2 — The audit pipeline in Callisto.**
- **Chain:** `ProceedingFileAuditAggregator` (`src/proceedings/domain/sub-domains/proceeding-file-audit/domain/aggregators/proceeding-file-audit.aggregator.ts`, with one `dispatchFileAudit<X>Event` per type) → dispatcher → `ProceedingFileToAuditEventAssembler` → `ProceedingFileToAuditEventResourceConverter` (`proceeding-file-to-audit.converter.ts:18-37`).
- **Resource fields:** `resourceType: FILE`, `resourceName: fileName`, `resourcePath: filePath`, `newState/oldState: {path: filePath, bucket, fileName}`, `identity: user.identity`.
- **Params:** `ProceedingFileAuditParams` = `{eventType?, file:{id,fileName,filePath,bucket}, user, oldFilePath?, oldFileName?}`.
- **Enums (`src/audits/constants.ts`):** event types are `CREATED`, `DOWNLOADED`, `DELETED`, `MERGED`, `RENAMED`, `APPROVED`, `UNAPPROVED`, `PERMISSIONS_UPDATED`. All are past-tense upper case, and none is a categorize type. Resource types are `FILE`, `PROCEEDING`, `FOLDER`, `PERMISSION`, so `FILE` already exists.
- **When it's sent:** the service awaits the audit **after** the transaction script returns, i.e. after commit. That holds for upload, approve and unapprove.
- **Failure handling:** SQS send failures are logged and return `false`; they never throw (`SQSAuditEventProducer.apply`).
- **Precedent:** `APPROVED` and `UNAPPROVED` were added in PRDV-12578 (`5ee0c174`, 2025-09), before deliverable types existed. `PermissionsToAuditEventAssembler` already builds a formatted string in Callisto and puts it in `newState.path`.

**F3 — Europa needs no change** (europa `1082fdad`).
- **No enum check:**
  - `type` and `resourceType` are free strings everywhere: entity, request DTO (`@IsString` only), and swagger (no enum).
  - `AUDIT_EVENT_TYPE` in Europa (`CREATED`, `LOGIN`, `LOGOUT`) is only used by the login and logout converters.
- **The filter is exact and case-sensitive** (`search-params-to-mongo-query.converter.ts:38-46`). So the Callisto literal and the Atlas literal must be **byte-identical**.
- **Path resolution:**
  - For every type except `PERMISSIONS_UPDATED`: `path = resource[0].newState.path ?? oldState.path ?? resourcePath` (`search-audit-events-paginated.transaction.script.ts:57-85`).
  - **Only resource `[0]` of an event is shown** (`:98-100`), so one event per file is required.
  - `searchTerm` does a regex over `newState.path`, so the deliverable type and collection would become searchable for free.
- **User fields returned:** `userEmail`, `userName` (first plus last name) and `createdAt`.
- **Access:** there are no role guards on the API; any authenticated Atlas user can read it.

**F4 — Atlas** (atlas `26eaa0bb`).
- **The dropdown** is `src/europa/utils/constants.ts:3-15` (`eventTypes`). Its values are raw upper-case literals shown as-is, and there is no label map. Chip colours come from `eventTypeColors` (`:19-30`); an unknown type falls back to grey.
- **Resource type:** `FILE` is already in `resourceTypes`.
- **Path column** (`SearchDataGrid.vue:309-324`): values are split on `' | '` into lines, with each label before `': '` in bold, **only for `PERMISSIONS_UPDATED`**. Every other type renders as one line because Quasar tables don't wrap.
- **Columns shown:** Event Type, User Email, User Name, Resource (the file name), Resource Type, Path, Bucket, Date (Local or UTC).
- **Route guard:** `routes.ts:35-52` requires `AUDIT` + `READ`.
- **Tests:** there are no specs for `SearchDataGrid`, `constants.ts` or `SearchFilters`.

**F5 — Data model.**
- **Deliverable type** is `deliverable_types.value`, unique per track. The same name can appear on more than one track (e.g. "Other").
- **Collections:**
  - Only Transcript and Video have them (static ones, plus user-named dynamic ones).
  - Exhibits, MVC, Audio and Planet Suite have none.
  - A Transcript or Video file can still have a null collection, because upload and approve v1 don't require one.
  - Dynamic collection names can't contain `|` or `:` (`validate-dynamic-collection-name.validator.ts:7`). Seeded type names (`1781121204472`) contain no `' | '`.
- **File path:** `file.filePath` is the S3 key (e.g. `MMYYYY/jobId/proceedingId/<uuid>.ext`). The readable file name is already in the Resource column.
- **What recategorize is missing for an audit:**
  - Its batch projection (`recategorize-deliverable-files-data.projection.ts:5-13`) lacks `filePath` and `bucket`.
  - Only ids are loaded; the type and collection names are never read.
  - The previous ids *are* available (`currentDeliverableTypeId`, `currentDeliverableCollectionId`).

**F6 — Feature flag.** `IS_GRANTING_CLIENT_ACCESS_COGNITO_ENABLED` controls only the Dione outbox writes. Europa audits are never flag-gated.

## Investigation method (steps 1–7)

**Step 1 — Raw facts and Problem Check.**
- **Problem in one sentence:** when someone sets or changes a file's deliverable type, nothing in the audit log records the type, the collection, who did it or when. For recategorize, nothing is recorded at all.
- **Named instance:** the ticket names none. The instance is structural: every recategorize today (F1-D) leaves no audit record. A live check is on the frontier.
- **Urgency:** the ticket gives no date. This is an open decision for Product.
- **Problem Check** (each flag is grounded in the ticket's words):
  - *Asked:* "a log in Europa for deliverable type categorization", a "new Event Type… Categorize", "Resource Type… File", and the "Path format".
  - *Answered:* the ticket itself fixes which fields show, the resource type, the event name and the path layout.
  - *Should ask:* which actions count as categorization (upload, approve, recategorize, unapprove); one record per file or per batch; old→new values; history; what "file path" means; the literal's casing.
  - *Conflation:*
    - The story's motivation is "key actions related to Client Access", but every criterion is about categorization only. That mixes the epic's motivation with this ticket's scope (OQ-09).
    - "Categorization" covers both first-time categorization (at upload or approve) and recategorization, which are two different code paths (F1).
  - *Thin:* "user info", "file path", "if applicable", "categorization actions taken".
  - *Off:*
    - "Categorize" doesn't match the naming of the 8 existing types, which are all past tense (F2).
    - "added to the Event Type drop down in Europa": that dropdown lives in `atlas-front-end`, and the Europa backend needs no change (F3, F4).
    - "Resource Type… File": nothing is off; `FILE` already exists.

**Step 2 — Class.**
- *Assumed:* a new audit-log feature or view for Client Access.
- *From the evidence:* an **audit-coverage gap on existing write paths**. The pipeline, log, filter and resource type all exist, and one write path emits nothing. This is the same class as PRDV-12578, which added approve and unapprove audits, and PRDV-16313's C5 concern (the epic's audit never covered two modules).
- *What that means for the solution:* emit a new event and register its label. No new log, storage or endpoint.
- *Wedge:* recategorize (D), which emits zero events today. The per-file Categorize builder written for it can then be reused on approve and upload.

**Step 3 — Contract.**
- *Acceptance criteria:* story 01 (6 criteria, plus 1 staged below).
- *Non-goals:*
  - other Client Access actions (grants, rename, approve and unapprove are already audited);
  - Europa's `[0]` collapse;
  - Dione outbox events;
  - role gating of the audit log;
  - a label layer for all event types;
  - backfill, pending D5.

**Step 4 — Why it exists, and a re-check of the class.**
- *Origin:* the approve and unapprove audits (PRDV-12578, 2025-09) came before deliverable types and collections (migrations `17811212044xx`). Recategorize was built later, and it wired only the Dione outbox.
- *Contract authority:* Callisto `AUDIT_EVENT_TYPE` plus the proceeding-file-audit converter. Europa mirrors nothing, because it takes a free string. Atlas mirrors the literal list **by hand**, and it already carries literals Callisto never sends (`MOVED`, `UPDATED`), so the two can drift apart again.
- *Detection gap:* the recategorize service spec has no audit assertion, while the approve, upload and unapprove service specs each assert their audit call. No contract test ties the Atlas and Callisto literals together.
- *Class re-check:* confirmed; not reclassified.

**Step 5 — Solution (recommended; to be locked in Phase 3).**
1. **Callisto:**
   - Add the literal to `AUDIT_EVENT_TYPE` (value pending D2).
   - Add `dispatchFileAuditCategorizedEvent` to `ProceedingFileAuditAggregator`.
   - Add a categorization params type, `{file:{id,fileName,filePath,bucket}, user, deliverableTypeName, collectionName|null, previous?}`, and a converter that builds `newState.path = "Filepath: <filePath> | Deliverable Type: <type> | Collection: <collection ?? 'N/A'>"`, where `oldState` holds the previous categorization (D3). The resource stays FILE, `resourceName`/`resourcePath`/`resourceBucket` keep parity, and the event carries one resource.
   - Dispatch from the **service, after the TS returns** (the same post-commit precedent), **one event per processed file**:
     - recategorize (D): the TS or projection must also return `filePath` and `bucket` for each processed file, plus the type and collection names (looked up in bulk by the distinct ids);
     - approve B/C and upload A: only if D1 includes them.
2. **Europa:** no code change. At most, a note in the README.
3. **Atlas:**
   - Add the literal to `eventTypes` and give it a colour in `eventTypeColors`.
   - Extend the `SearchDataGrid.vue:311` multi-line path condition to cover the new type.
   - Add the first specs for that rendering and for the literal list.

**Alternatives considered and rejected:**
- *Europa builds the path from structured state* (the d71f2bd pattern). Europa doesn't know the names, and extra state keys aren't returned, so it would need a second type-specific branch and a Europa deploy, with no gain.
- *Add type and collection to the existing APPROVED/CREATED events.* The ticket requires a distinct Categorize type, and recategorize has no event at all.
- *One event per batch with N resources.* Only resource `[0]` is shown (F3), so N−1 files would be invisible, the same defect `MERGED` has.
- *Atlas formats the path from structured fields.* Only the `path` string crosses the wire.
- *Emit from inside the recategorize transaction.* That breaks the post-commit precedent, and a rollback could audit a change that never happened.

**Stress test:**
- *Scale:* N files send N SQS messages, which approve already does. Name lookups cost O(distinct ids).
- *Generalization:* one converter and one aggregator method. No framework.
- *Fit:* the proceeding-file-audit sub-domain and service-level dispatch. Where the new assembler and converter go is checked against callisto `.cursor/rules` (frontier).
- *Adjacent issues:* all go to the concerns doc, none into scope:
  - no role checks on Europa's API;
  - silent SQS loss;
  - `ON DELETE SET NULL` uncategorizes files without an audit;
  - drift in Atlas's literal list;
  - unapprove clears the categorization;
  - the recategorize DTO's id doc string is wrong.
- *Sufficiency:* it covers categorization only. The rest of "key actions" is OQ-09.
- *Feedback speed:* unit specs give feedback in seconds. The end-to-end view needs local SQS or a sandbox (see the repro todo).
- *Actor, action, moment:* after staff categorize deliverables in Atlas, an Ops user with `AUDIT READ` filters Event Type = Categorize.

**Step 6 — Validation (to seed the test plan).**
- *Happy path:*
  - Recategorizing 2 Transcript files into a collection gives 2 events with the right three-part path.
  - Approve v2 with a type and a collection gives an event.
  - Uploading an Exhibits file gives `Collection: N/A`.
  - Europa `type=<literal>` returns them.
  - Atlas renders bold labels on separate lines, and shows the user email, user name and date.
- *Negative paths:*
  - A recategorize that fails validation, or a rollback, sends no event.
  - An SQS failure is logged and the request still succeeds (parity).
  - Unapprove sends no Categorize event.
  - An approve with skipped (already-deliverable) files sends none for them.
  - When a dynamic collection is created, its name appears in the path.
  - A literal mismatch between Atlas and Callisto returns nothing, which a test must catch.
- *Neighbors that must not change:* the counts and shapes of CREATED, APPROVED, UNAPPROVED and RENAMED; the Dione `file.recategorized.v1` payload; the recategorize response `{processedFileIds}`; `PERMISSIONS_UPDATED` path rendering; Europa.
- *Red→green:* a recategorize service spec asserting one categorize dispatch per processed file. It fails today.

**Step 7 — Reconcile: answered by evidence (these are facts).**
- **OQ-04** "user info" and date/time: they match existing events. `identity` is the whole user, and the grid shows User Email, User Name and Date (Local/UTC). Resolved.
- **OQ-06** when a collection applies: only on Transcript and Video. `Collection: N/A` whenever the file's `deliverable_collection_id` is null after the action. Resolved.
- **OQ-08** who can see it: the Atlas route requires `AUDIT READ`. Europa has no access rules per event type, so the new records inherit the existing access. Resolved.
- **OQ-02** fact half: the paths are enumerated (F1); categorization isn't logged under any type today; and one event per file is required (F3). The decision half moves into D1.
- **OQ-05** fact half: "path" for a FILE event today is the S3 key, and the file name sits in the Resource column. The decision half becomes D4.
- **OQ-07** fact half: Callisto keeps no who/when history for past recategorizes. `file_attachments` has no modified-by column (PRDV-16313 area 10); the only trace is Dione outbox rows, and only when GCA was on. The decision half becomes D5.

**Open decisions (the only things left open):**

| # | Decision | Recommendation | Owner |
|---|---|---|---|
| D1 | Which paths emit Categorize (OQ-01/02) | A upload, B/C approve, D recategorize. Not E, F or G | Product |
| D2 | The literal and how it displays | `CATEGORIZED`, matching the 8 past-tense siblings and shown raw like them. Product then confirms that criterion 3's "reads Categorize" accepts that, or the criterion is rewritten on the record | Product + principal dev |
| D3 | Show old→new (OQ-03) | Store the previous value in `oldState` and show only the new value, as the ticket's format does | Product |
| D4 | What Filepath means (OQ-05) | Keep parity: the S3 key | Product |
| D5 | Backfill (OQ-07) | None; new events only | Product |
| D6 | Scope (OQ-09) | Categorization only | Product / principal dev |
| D7 | Urgency / target date | — | Product |
| D8 | Spec reviewer and where the spec lives (Callisto-primary change) | Settle at Phase 3 | principal dev |

## Staged writes (land at Phase 2's first action)

**Story reconcile** (`stories/INT-138-job-story-01-categorization-audit.md` plus the index):
- Close OQ-04, OQ-06 and OQ-08 by evidence.
- Split OQ-02, OQ-05 and OQ-07: close the fact halves, and point each decision half at D1, D4 and D5.
- Add one criterion: "When several files are categorized at once, each file gets its own record." It rests on the batch paths (F1) and the one-resource display (F3).
- Flag criterion 3 as depending on D2. It is not invalidated.
- No split.
- Story log entry: "Phase 1: 3 questions closed, 3 split, 1 criterion added (6→7)".

**Coverage rows** (`investigations/INT-138-coverage-ledger.md`):
- The Consult lines above.
- One area per finding:
  - F1 surface — callisto `59b1abd3`, fully-inspected;
  - F2 audit pipeline — callisto `59b1abd3`, fully-inspected; reopened because the behavior differs;
  - F5 data model — fully-inspected;
  - F6 flag — fully-inspected;
  - Callisto specs — fully-inspected (the detection gap);
  - F3 Europa — `1082fdad`; PRDV-16192 areas 3/4 reused, area 1 reopened because of `d71f2bd`;
  - F4 Atlas grid — `26eaa0bb`; reopened because of `c2814144`;
  - Atlas categorization request call sites — fully-inspected;
  - `larry-adams` design doc — consulted.
- **Frontier:**
  - a live Callisto→SQS→Europa→Atlas event;
  - whether upload-complete sets a type when GCA is off;
  - Planet Suite seeded type names (`1784739200003`) checked for `' | '`;
  - whether approve's `processedFiles` carries type and collection ids;
  - whether bulk name-lookup repository methods exist, and the module boundaries;
  - callisto `.cursor/rules` placement for the new converter and assembler.

**Why doc** (`INT-138-why-these-changes.md`):
- Class: an audit-coverage gap.
- Root code: `RecategorizeDeliverableFilesService.apply`, which dispatches no audit; `ProceedingFileAuditAggregator` and `AUDIT_EVENT_TYPE`, which have no categorize entry; the converter, which puts no type or collection into state; and Atlas `eventTypes`.
- Phase 1 entry:
  - *Obvious:* a new type is needed, and FILE already exists.
  - *Not obvious:* Europa needs no change; recategorize is completely silent; approve and upload already audit, but without categorization; one event per file is forced by the display; the path is an S3 key; the literal casing convention.
  - *Assumptions:* D1–D8.

## Phase 2 todos (emission, in order)

1. **Ledger:** mark Phase 1 `done` and Phase 2 `in-progress`. Send the deferred Phase 1 notification. **Board:** re-read the card. If its title now carries INT-138, set `currentStep`; if not, the guard still stops the write — log it and notify.
2. **Save the plan:** save this plan word for word as `investigations/INT-138-recon-and-plan.md`. Then create the why doc, apply the story reconcile, and append the index movement log.
3. **Report:** write `investigations/INT-138-investigation.md` from the template. Put the verdict first: **proceed with conditions** (D1 and D2 gate the spec). Reconcile every software-lens point explicitly:
   - contract alignment: the literal must match exactly across Callisto and Atlas, and they can drift again;
   - surface enumeration: F1 plus its completeness claim;
   - protect the neighbors: the Step 6 list;
   - detection gap;
   - the red→green spec;
   - the **repro recipe:** Callisto and Europa running locally with `SQS_AUDIT_EVENT_URL_OUTBOUND` → the Europa listener queue (per `docs/atlas/local/callisto-local.mdc` and `europa-local.mdc`), Atlas `/europa-stuff` as a user with `AUDIT READ`, and a GCA-enabled proceeding with Transcript and Exhibits files.
4. **Coverage ledger:** write `investigations/INT-138-coverage-ledger.md` from the staged rows plus the frontier.
5. **Diagrams:** write `investigations/INT-138-diagrams.md`:
   - current vs target: paths A–G mapped to the events they send;
   - a sequence diagram: recategorize → TS commit → service → aggregator → SQS → Europa → Atlas render;
   - N/A lines for the kinds that don't apply.
6. **Test plan:** seed `testing/INT-138-test-plan.md` from Step 6. Map each scenario to a story 01 criterion, or flag it as having no criterion behind it (the neighbor checks).
7. **Concerns:** write `INT-138-future-development-concerns.md` with the adjacent issues from Step 5.
8. **PR draft:** create the `INT-138-pr-draft.md` shell, with headings only.
9. **Changelog:** add the Phase 2 session log entry (UTC). Notify, then auto-advance to Phase 3.

## Verification (Phase 2 exit)

- `scripts/check-steps.ps1 -TicketFolder docs/atlas/INT-138 -ThroughPhase 2` reports no MISSING or EMPTY.
- The report's §11 handoff table has a done-when that could be proven false for each of D1–D8.
- No file in an implementation repo has been touched. `git status` is clean in all three repos.
