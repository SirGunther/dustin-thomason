# Coverage ledger — atlas/PRDV-16402

Investigation question: **why does a video file uploaded to an already-submitted AJSF never get transcoded, and what is the complete set of surfaces and rules that govern transcode-request emission?**
Repo(s): `callisto-back-end`, `atlas-front-end`, `nova-back-end` (reference only) · Baseline commits: `47f5a841` (callisto `main`), `102e034d` (atlas `main`), `58a6182` (nova branch `PRDV-16398`) · Started: 2026-07-29

## Consulted

- `docs/*/tickets/*/investigations/*-coverage-ledger.md` and `docs/atlas/PRDV-*/investigations/*-coverage-ledger.md` for "transcode", "AJSF", "submitted jobs", "video conversion", "outbox" — **five ledgers found; one matched decisively.** `docs/nova/tickets/nova-applies-selected-transcode-preset/investigations/PRDV-16398-coverage-ledger.md`. Its **frontier item** reads: *"**The AJSF producer** ('Transcode video files uploaded through AJSF', linked in ClickUp activity by Shaye Lankford) — would answer whether a second emitter bypasses Callisto's two-value gate … Not present in any of the four repos read."* **That frontier item is this ticket.** **Reopened under condition 4** (*the current question concerns a different behavior*): PRDV-16398 investigated **Nova consuming** `video-transcode-requested`; this ticket investigates **Callisto emitting** it from a second surface. Findings **reused, not re-derived**: its **area 7** (`callisto-back-end` — the producer and the value authority) established the six `VIDEO_TRANSCODES` values, the two-value eligibility gate, and the id-renumbering history, so none of that was re-read here; its **areas 1–3** established that Nova carries `videoTranscodeValue` to `VideoJob.template` and **never reads it** (`grep '\.template\b'` → zero production reads), which is the entire basis of this report's §4 / AC8 finding and was **not** re-verified against Nova's source in this pass.
- `docs/atlas/PRDV-*/` and `docs/nova/` outside ledger format for "transcode" — found `docs/atlas/PRDV-16216/` (Callisto consuming Nova's *completed* event, incl. `docs/atlas/local/publish-test-transcode-event.sh`). **Not reopened as an investigation branch** — its question (duration write-back on completion) is orthogonal. Noted as the source of the event-injection technique should local verification be needed in Phase 5.
- `docs/nova/tickets/nova-applies-selected-transcode-preset/orchestration.md` + `docs/nova/PRDV-16398-changelog.md` — read to establish the companion ticket's **shipping state** (Phase 5 in-progress, uncommitted, `vid-mix.preset.ts` blocked on the HandBrake preset from ops). Load-bearing for the AC8 gate.

## Areas examined

### 1. `callisto-back-end` — completed-upload action, DTO, guard (the entry point)

| Field | Value |
| --- | --- |
| Inspected | `UploadCompleteProceedingCompletedJobSubmissionAction` in full; route + guard decorators; the shared request DTO's full field list; the Swagger helper; the pending twin for comparison |
| Findings | Route `@Post('/upload-complete-completed')` under `@ProceedingJobSubmissionController()`; guard `AjsfSubmissionProceedingFilesCreateAuthGuard` confirmed. DTO fields: `filename, key, uploadId, size, mimetype, trackTypeId, proceedingId, jobSubmissionFormId, partsCount, length?` — **no preset, and no `jobId`/`jobTaskId`**, so Atlas's copies of those are dropped by validation and unavailable in the service. Action declares no response type (the pending twin does); Swagger declares `200` with no schema |
| Status | contributing |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/upload-complete-proceeding-completed-job-submission-file.action.ts:12-31`; `…/upload-complete-proceeding-job-submission-file.request.dto.ts:16-99`; guard at `src/generic/auth/application/guards/role-auth-guard/role-based-guards.ts:340-343` |
| Notes | The missing `jobId` on the DTO is why the form must be loaded server-side even though Atlas sends a `jobId` |

### 2. `callisto-back-end` — `MultiPartUploadProceedingJobSubmissionFileCompleteUploadService` (the defect site)

| Field | Value |
| --- | --- |
| Inspected | Whole class (103 lines): all 5 injected deps, `uploadCompleteForCompletedJobSubmission`, `uploadCompleteForPendingJobSubmission`, private `createProceedingFile`; transaction-wrapping check |
| Findings | Completed method = `createProceedingFile` → `dispatchFileAuditCreatedEvent` → `dispatchProceedingFileUpload` (legacy SQS) → return. **No outbox writer, no feature-flag aggregator, no eligibility check, no MIME/track filtering anywhere in the file.** Pending method = create → audit → return (also silent, by design). `createProceedingFile` ends by writing the `jsffa` join row via the assembler, **guarded by `if (file.fileAttachment.id)`**. Only `@TODO` is `:16` "Split this class up" — none referencing transcode. **Not transaction-wrapped**: registered as a bare class, and `UploadCompleteProceedingFileTransactionScript` is spread **un-proxied** |
| Status | contributing — **the root cause** |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/multi-part-upload-proceeding-job-submission-file-complete-upload.service.ts:16, 19-27, 29-42, 44-73, 75-102`; module registration `proceeding-job-submission.module.ts:198`; un-proxied TS at `src/proceedings/registries/transaction-script.registry.ts:20` |
| Notes | Completeness claim: repo-wide grep for `JOB_SUBMISSION_VIDEO_TRANSCODE_OUTBOX_WRITER_TOKEN` never reaches this file |

### 3. `callisto-back-end` — `SubmitJobSubmissionFormTS` (the authority to mirror)

| Field | Value |
| --- | --- |
| Inspected | Whole TS (78 lines) — decorator, arg list, step order, early returns, writer call; its provider factory |
| Findings | `@Transactional() apply(formId, user, isVideoTranscodeOutboxEnabled)` — **flag is an argument, resolved by the caller**. Order: status lookup → form update (returns form with relations) → preset gate (early return) → form-scoped file query → empty-rows early return → **flag check last** → `writeRequestedEvents`. Emission is inside the transaction. Writer inputs: `jobId`/`jobDate` off the updated form; `videoTranscodeId`/`Value` off the eager-loaded relation; `createdUserEmail` = `user.identity.userEmail`, `createdUserName` = `user.identity.userFirstName` (**first name only**) |
| Status | contributing (the parity target) |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/submit-job-submission-form-ts/submit-job-submission-form.transaction.script.ts:26-77`; `…/submit-job-submission-form-ts.provider.ts:15-42` (`createTransactionalProxy` at `:32`) |
| Notes | Flag checked **after** the query, so the SELECT runs even when the flag is off — pinned by a spec (area 11). Any divergence in the new path needs a stated reason |

### 4. `callisto-back-end` — preset eligibility gate + `VideoTranscode` entity

| Field | Value |
| --- | --- |
| Inspected | `IsVideoTranscodeSelectionEligibleForOutbox` in full; `VideoTranscode` entity + `VIDEO_TRANSCODES` constant |
| Findings | Eligible = non-null **and** value ∈ {`'Standard'`, `'Video Mix'`}. Six values exist (others: `'Site Survey'`, `'Day in the Life'`, `'Other'`, `''`). The gate is a **type predicate over `VideoTranscode \| null \| undefined`** — relevant if a lean projection replaces the loaded relation |
| Status | contributing — reused unchanged |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/submit-job-submission-form-ts/is-video-transcode-selection-eligible-for-outbox.ts:9-17`; `src/shared/shared-entities/entities/proceedings/video-transcode.entity.ts:5-12, 19-26` |
| Notes | Value-list and renumbering history **reused from PRDV-16398 ledger area 7**, not re-derived |

### 5. `callisto-back-end` — writer, port, converter, deterministic-id helper

| Field | Value |
| --- | --- |
| Inspected | `JobSubmissionVideoTranscodeRequestedOutboxWriter` in full; the port + token; the descriptor converter's `toData()`; `DeterministicEventIdHelper`; `OutboxFacade` port + impl |
| Findings | `writeRequestedEvents({ files, jobId, jobDate, videoTranscodeId, videoTranscodeValue, createdUserEmail, createdUserName })`, loops per file. Runner name `'job-submission-video-transcode-command'`. Event id = `uuidv5('runnerName\|aggregateType\|aggregateId\|rowUpdatedAt-ms\|eventType')`, with `aggregateType = 'ProceedingFile'`, `aggregateId = String(file.fileId)`, `rowUpdatedAt = new Date(file.fileUpdatedAt)` — **so `fileUpdatedAt` is load-bearing**. `OutboxFacade.writeOutboxEvent` takes **no** transaction/manager; participation is ambient via ALS. **Port declares `jobDate: Date` but `job_date` is a `date` column → pg yields a `'YYYY-MM-DD'` string; the converter accepts `Date \| string`, so the port is already lying**. Converter reads 12 of the projection's 14 fields — never `proceedingValue` or `fileType` |
| Status | contributing — reused unchanged |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/infrastructure/outbox/writers/job-submission-video-transcode-requested-outbox.writer.ts:13, 24-54`; `…/domain/ports/job-submission-video-transcode-outbox-writer.port.ts:3-21`; `…/outbox/converters/job-submission-file-to-video-transcode-requested-descriptor.converter.ts:16, 23, 31-43, 60-81`; `src/generic/outbox-projector/domain/deterministic-event-id.helper.ts:4-29` |
| Notes | Neither command-driven writer guards with `existsById`; only the projector engine does (area 12) |

### 6. `callisto-back-end` — outbox projection + the form-scoped eligibility query (**the single definition**)

| Field | Value |
| --- | --- |
| Inspected | `JobSubmissionFormFileForVideoTranscodeOutboxProjection` (all 14 fields); `findProceedingsAndFilesByJobSubmissionFormIdForVideoTranscodeOutbox` in full — every join, predicate, and select alias; the non-outbox twin in the same file |
| Findings | **Track, MIME, and attachment-type eligibility exist ONLY here, and there are three predicates, not two**: `fa.attachedToType = 'Proceeding'`, `tt.value = 'Video'`, `LOWER(f.fileType) LIKE 'video/%'`. Root `jsffa`; joins `fa` (ManyToOne), `fa.files` (**OneToMany — the row multiplier**), `fa.trackType` (ManyToOne), plus a raw `leftJoin('proceedings', …)`. **Only `jsffa.jobSubmissionFormId` is form-scoped** — a single-file variant needs `f.id = :fileId` and nothing else structural. Track matched by **value string**, not id (ids: VIDEO = 3 in two separate maps) |
| Status | contributing — the wedge |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/infrastructure/repositories/job-submission-form-file-attachment.repository.ts:30-62 (twin), 64-107`; projection `…/domain/projections/job-submission-form-file-for-video-transcode-outbox.projection.ts:1-16`; `TRACK_TYPES` at `src/shared/shared-entities/entities/files/file-attachment/file-proceeding-track-type.entity.ts:7-13, 17-31` |
| Notes | **No repository in the repo exposes a genuine `byParentId` + `bySingleId` pair of the same projection query** — established by enumerating ~110 `async find*(` declarations. Nearest naming precedents: `file-attachments-file-tags.repository.ts:32-67`, `proceeding.repository.ts:24-73`, `job-task.repository.ts:19,59`, `case-file.repository.ts:141,157`. Also: existing specs use `trackTypeId: 1` next to `trackTypeName: 'Video'` — **no test pins the id** |

### 7. `callisto-back-end` — `JobSubmissionFormRepository` + `JobSubmissionForm` entity

| Field | Value |
| --- | --- |
| Inspected | All five methods; `JOB_SUBMISSION_FORM_RELATIONS`; entity columns for job id / job date / `videoTranscode`; `relationLoadStrategy` config search |
| Findings | **Only one repository in the whole repo touches the entity.** `findById` / `update` / `findAll` all load the same **14 relations** (13 ManyToOne + the `jobSubmissionFormFileAttachments` **OneToMany**); `findByJobTaskId` loads none. So `findById` is the **only** read exposing `videoTranscode`. No `relationLoadStrategy` anywhere → TypeORM default `'join'` → one SELECT whose row count **multiplies by the form's `jsffa` count**, over an ~80-column table. `job_id` and `job_date` are scalar columns (**no `job` relation**); `videoTranscode` is a nullable `@ManyToOne` on `video_transcode_id` |
| Status | contributing |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/infrastructure/repositories/job-submission-form.repository.ts:10-25, 39-83`; `…/domain/entities/job-submission/job-submission-form.entity.ts:35-38, 54-65, 81-90, 615-620` |
| Notes | `JobRepository.findJobDateById` exists but reads `jobs.job_date`, a **different** source than the form's denormalized copy — not equivalent, and that repository does not use `TransactionContext` |

### 8. `callisto-back-end` — feature-flag resolution pattern

| Field | Value |
| --- | --- |
| Inspected | `JobSubmissionService.submitJob`'s flag block; the aggregator port + flag-name constant; the completed-upload service's dep list |
| Findings | Service calls `featureFlagAggregator.isFeatureAllowed(FEATURE_FLAG_NAMES.IS_VIDEO_TRANSCODE_ENABLED, user)` and passes the **boolean** into the TS. Flag is a Cognito `custom:feature-flags` token. The completed-upload service injects **no** feature-flag aggregator. `FeatureFlagModule` is already imported by the module |
| Status | contributing |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/domain/services/job-submission-service/job-submission.service.ts:39-40, 76-85`; `src/feature-flag/domain/aggregators/feature-flag.aggregator.port.ts:11`; module import `proceeding-job-submission.module.ts:143` |
| Notes | A TS may **not** inject the concrete aggregator (area 9); resolving in the service is the sanctioned shape |

### 9. `callisto-back-end` — architecture rules and their enforcement

| Field | Value |
| --- | --- |
| Inspected | `transaction-scripts.rules.ts` and `services.rules.ts` in full; `layer-dependencies.rules.ts` domain↔infrastructure rule; `assemblers.rules.ts`; `.dependency-cruiser.ts`; `architecture.spec.ts`; `package.json` scripts; both Husky hooks |
| Findings | **TS→TS forbidden at `severity: error` with no `to`-side exemption**; TS→service forbidden; TS→aggregator forbidden except `*.port`/`port.` paths. Repositories are exempt for domain (`domain-no-infrastructure` `pathNot` includes `.*repository.*`); **`writers/` is not exempt** — hence the port token. Services may not depend on services/mappers/converters, but **may** inject repositories, aggregators, assemblers, and TSes. Enforced by `npm run test:architecture` → aggregated into `test:conventions` → wired as `pretest`, so it runs before `npm test`. **`architecture.spec.ts:6`'s claim of Husky enforcement is stale** — `pre-commit` runs prettier only, `pre-push` adds lint-staged + integration tests; neither runs it |
| Status | contributing — refutes the coworker spec's proposed flow |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `fitness-functions-rules/architecture-rules/transaction-scripts.rules.ts:12-45`; `services.rules.ts:12-37`; `layer-dependencies.rules.ts:32-52`; `assemblers.rules.ts:22-35`; `.dependency-cruiser.ts:22-47`; `src/__tests__/architecture.spec.ts:6, 26-34`; `package.json:29, 31, 37`; `.husky/pre-commit`, `.husky/pre-push` |
| Notes | `services.rules.ts:6-7`'s doc comment claims assemblers are forbidden for services; **no such rule exists**, and this very service already injects an assembler. Do not let the comment be cited as a rule |

### 10. `callisto-back-end` — module wiring for a new transaction script

| Field | Value |
| --- | --- |
| Inspected | `proceeding-job-submission.module.ts` providers/imports/controllers; `registries/` folder contents; the submit TS's provider as the transactional template; two sibling transactional-TS providers |
| Findings | **This module has no `transaction-script.registry.ts`** — only `actions.registry.ts`; TSes are registered directly in the module. Transactional template = `createSubmitJobSubmissionFormTSProvider()`; `useFactory` takes `TRANSACTION_CONTEXT_TOKEN` first, news the instance with explicit ctor args, returns `createTransactionalProxy(instance, transactionContext)`. Every collaborator a new TS needs is **already provided**: eligibility gate, writer token, converter, both repositories; `OutboxProjectorModule` and `FeatureFlagModule` already imported. Nothing new to export |
| Status | fully-inspected |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `proceeding-job-submission.module.ts:111-112, 143, 158, 181, 195, 198, 219-236`; `…/submit-job-submission-form-ts.provider.ts:15-42`; sibling providers `merge-case-ts.provider.ts:26-29`, `upload-complete-deliverable-file-ts.provider.ts:41-44` |
| Notes | Contradicts the coworker spec's "registries" line — there is no registry file to add to here |

### 11. `callisto-back-end` — existing test surface (**the detection gap**)

| Field | Value |
| --- | --- |
| Inspected | The submit-TS spec (all 7 tests + the three `.not.toHaveBeenCalled()` sites); the eligibility-gate spec; the writer spec; the converter spec; the job-submission-service spec's flag tests; the complete-upload service's `__specs__/` contents; search for action-level and e2e specs on the route |
| Findings | **No spec file exists for `MultiPartUploadProceedingJobSubmissionFileCompleteUploadService` at all** — its `__specs__/` holds only `job-submission-form-file-attachment.assembler.spec.ts`. No action-level spec for either upload-complete action; no e2e/integration spec for the route. **No test anywhere asserts that either upload path does or does not emit.** All three `writeRequestedEvents` `.not.toHaveBeenCalled()` assertions live in the submit-TS spec and concern ineligible preset / empty rows / flag-off. Flag-off test pins that the repository query **is** still called |
| Status | contributing — designs the red→green test |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/submit-job-submission-form-ts/__specs__/submit-job-submission-form.transaction.script.spec.ts:79, 122-127, 131, 186-196, 199, 267, 310-312, 316, 372-377`; `…/__specs__/is-video-transcode-selection-eligible-for-outbox.spec.ts:18-48`; `…/outbox/writers/__specs__/…writer.spec.ts:103, 167, 173-196`; `…/outbox/converters/__specs__/…converter.spec.ts:17`; `…/job-submission-service/__specs__/job-submission.service.spec.ts:294-306, 332-378` |
| Notes | Jest gate `pretest` → `test:conventions`; serial run per personal rule is `npm test -- --runInBand` |

### 12. `orbital-relay-pkg` — outbox write path and duplicate-id semantics

| Field | Value |
| --- | --- |
| Inspected | `write-outbox-event.transaction.script.js`, `outbox-event.repository.js` (all write paths: `create`, `markPublished`, `markFailed`, `claimBatch`, `existsById`), the entity, the `outbox_events` migration; TypeORM `EntityPersistExecutor` / `SubjectDatabaseEntityLoader` / `Subject` to determine insert-vs-update; the projector engine's guard |
| Findings | `create()` builds the entity with an **explicit PK** plus `status: PENDING, attempts: 0`, then `repo.save()`. With the row present, `mustBeInserted` is false → **UPDATE**, resetting `status` and `attempts` and thus **re-publishing an already-published event**; `published_at`/`locked_at`/`locked_by`/`last_error` are absent from the payload and left stale. Migration shows **PK only — no unique constraint**; no `orIgnore`/`orUpdate`/`ON CONFLICT` anywhere. `OutboxFacade` exposes only `writeOutboxEvent` and `existsById`. **`existsById` has exactly one caller in `src`** — the projector engine; neither command-driven writer guards |
| Status | **partial** — mechanism read from library + TypeORM source, **not observed at runtime** |
| Commit | `47f5a841` (installed dep) · 2026-07-29 |
| Evidence | `node_modules/@planetdepos/orbital-relay-pkg/dist/outbox/domain/transaction-scripts/write-outbox-event-ts/write-outbox-event.transaction.script.js:25-45`; `…/infrastructure/repositories/outbox-event.repository.js:31-96`; `…/domain/entities/outbox-event.entity.js:19-85`; `src/typeorm/migrations/1772165619858-create__outbox_events_table.ts:7-27`; `src/generic/outbox-projector/domain/outbox-projector.engine.ts:17, 88-93, 105-111`; `src/typeorm/outbox-transaction-context.module.ts:12-21` |
| Notes | **Unchecked:** the actual observed column set after a duplicate write. → frontier (report §8 A8) |

### 13. `callisto-back-end` — completed-event consumer, derivative persistence, and the AJSF file list

| Field | Value |
| --- | --- |
| Inspected | The AMQP listener + its bindings; the inbox poller/batch processor; `ProceedingVideoTranscodeCompletedInboxHandler`; the payload parser; `ProcessProceedingVideoTranscodeCompletedService`; the context assembler; `PersistVideoTranscodeDerivativeMapper` in full; `FileDerivation` entity + migration; the AJSF proceeding-files action → TS → `FileAttachmentRepository.fetchFilesByProceedingId` and the counts query; the read-time pairing converter and its response DTO |
| Findings | Callisto **does** consume `nova.proceeding.file.video-transcode-completed.v1` (inbox-mediated). The handler **INSERTs four rows** — new `file_attachments` (copying the source's `attachedToId`, `attachedToType`, **and `trackTypeId`**), a `Submission File` tag link, a new `files` row (`video/mp4`, name `<source stem>.mp4`), and a `file_derivations` edge — and **never updates the source row**. **No `job_submission_form_file_attachments` row is created for the derivative** (deliberate-looking: keeps it out of submit's re-emission query). Lineage is **not** a column on `files`/`file_attachments`; it lives in `file_derivations` and is projected at read time as `sourceFileId`/`lineageRole`. **The derivative satisfies every predicate of the AJSF list query, so it is returned today** — the counts query de-dups the source but the list does not, which is what the FE's indent-under-original renders. Idempotency: inbox dedupes on **envelope id** (`ON CONFLICT DO NOTHING`) and the handler runs in a DB transaction, but the destination-key check embeds a fresh `randomUUID()` so a re-emission with a new envelope id yields a **second derivative**; `FileDerivationRepository.findBySourceAndProcess` is exactly the missing guard and is **dead code** |
| Status | contributing — establishes there is **no new front-end-visible shape** |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/listeners/nova-proceeding-file-video-transcode-completed.listener.ts:20-33`; `src/proceedings/constants.ts:17-24`; `…/inbox-handlers/proceeding-video-transcode-completed-inbox.handler.ts:12-21`; `…/persist-video-transcode-derivative.mapper.ts:33-38, 41-122`; `…/resolve-video-transcode-processing-context.assembler.ts:89-150`; `src/shared/shared-entities/entities/files/file-derivation.entity.ts:41-56`; `src/typeorm/migrations/1776799165302-create__file_derivations_table.ts:12-33`; `…/fetch-job-submission-files-by-proceeding-id.action.ts:21-32`; `src/proceedings/infrastructure/repositories/file-attachment.repository.ts:37-91, 93-181`; `…/pair-original-and-processed.converter.ts:29-54`; `…/fetch-files-by-proceeding-id.response.dto.ts:68-83`; `file-derivation.repository.ts:36-46` (dead) |
| Notes | **partial:** the notification/failed-event side was not read line-by-line; no `video-transcode-failed` consumer exists in Callisto at all (referenced only in `docs/adr/ADR-002-notification-module.md:117`) → frontier |

### 14. `callisto-back-end` — the re-submit path (does submit ever re-emit?)

| Field | Value |
| --- | --- |
| Inspected | Every caller of `SubmitJobSubmissionFormTS.apply`; the submit action + route + guards; `JobSubmissionFormStatusValidator`; `SUBMISSION_STATUSES`; the form-create seed; the submit migration for constraints |
| Findings | One production caller (`JobSubmissionService.submitJob`). Route `POST /proceeding-job-submission/submit/:formId` carries **no `@UseGuards`** (only the `@VerifiedUserDecorator` param) and there is no global guard. **Re-submit IS blocked** — `JobSubmissionFormStatusValidator` throws on `DONE`, called **before** the TS. But it is a plain `Error` → HTTP 500, not a 409, and it runs **outside** the transaction, so two concurrent submits can both pass. No status precondition inside the TS, no DB constraint, no idempotency key. Statuses: `Partial`, `Done`, `''`; forms are created with `''` |
| Status | ruled-out as a duplicate-emission cause for the happy path; **contributing** to the concurrency residual |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/submit-job-submission-action/submit-job-submission.action.ts:13-25`; `…/domain/validators/job-submission-form-status.validator.ts:7-15`; `job-submission.service.ts:72-74, 81`; `…/entities/job-submission/submission-status.entity.ts:5-9, 17`; `…/fetch-or-create-job-submission-form.transaction.script.ts:53-60, 75-79`; `src/typeorm/migrations/1751768906094-create__job_submission_forms__table.ts:9-22` |
| Notes | Confirms the coworker spec's "emit only for the newly uploaded file" decision — there is no compensating dedupe elsewhere to lean on. `SUBMISSION_STATUSES.PARTIAL` has **no writer found** → frontier |

### 15. `callisto-back-end` — post-submit mutability of the preset

| Field | Value |
| --- | --- |
| Inspected | Every `jobSubmissionFormRepository.(update\|create\|save)` call site (grep-exhaustive, 3 hits); the PATCH action + DTO + TS; the create path; the submit write payload; cascade/trigger search on the `jsffa` relation and FKs |
| Findings | **`PATCH /proceeding-job-submission/job-submission-form` can change `videoTranscodeId` on a DONE form with no guard, no ownership check, no user context, and no status precondition** — its TS does a bare `repository.update` with no status read, and is not `@Transactional()`. Its DTO also accepts `submissionStatusId`. The create path only ever seeds `NONE`; submit writes only `submissionStatusId`/`submittedUserId`/`submittedUserEmail`/`updatedAt` — **the preset is never snapshotted**. The update touches the **form row only**: `Repository.update` does not cascade, the `jsffa` relation declares no cascade, FKs are `ON UPDATE NO ACTION`, and no migration adds a trigger — so `files.updated_at` is untouched and a changed preset is **not distinguishable by event id** |
| Status | contributing — the §8 A3 / OV-4 evidence |
| Commit | `47f5a841` · 2026-07-29 |
| Evidence | `…/update-job-submission-form-action/update-job-submission-form.action.ts:14-20`; `…/update-job-submission-form.request.dto.ts:16, 34, 81`; `…/update-job-submission-form.transaction.script.ts:13-32`; `submit-job-submission-form.transaction.script.ts:36-44`; `job-submission-form.repository.ts:61-74`; `job-submission-form.entity.ts:615-620`; `1773945357657-alter__rename_video_job_options_to_video_transcodes.ts:35` |
| Notes | Eligibility is evaluated **at emit time only** — a post-submit `NONE → Standard` change emits nothing for existing files, and `Standard → NONE` retracts nothing already emitted |

### 16. `atlas-front-end` — the submitted-AJSF upload surface graph (completeness)

| Field | Value |
| --- | --- |
| Inspected | Every literal `upload-complete*` occurrence; the URL constants; `useUploadComplete` and all 5 call sites; `SubmittedJobSubmissionPage` → `SubmittedFileUploadSection` → `FileUploadSectionCore` → `JobSubmissionProceedingFileUploadManager` / `ProceedingUploadArea` → `FilesUploadArea`; the `uploadHandler` provide/inject graph; `createUploadContext` callers; `DragDropZone` importers; row-action menus |
| Findings | **Exactly two upload surfaces on the submitted page** — a "main files" click-zone and an "exhibit files" click-zone, both hidden `<input type="file" accept="*/*" multiple>` — and **both route to `upload-complete-completed`**. Exactly one surface hits the AJSF *pending* endpoint (the pending page); the three other `upload-complete` variants are case/proceeding/deliverable flows that never carry `jobSubmissionFormId`. **No drag-and-drop, FAB, bulk action, or per-row re-upload exists on this page** — `DragDropZone` has one importer (`ProceedingDetailPage`), and the only per-row action is Rename |
| Status | fully-inspected — **the FE surface list is complete** |
| Commit | `102e034d` · 2026-07-29 |
| Evidence | `src/callisto/api/constants.ts:71-72`; `…/UploadManager/composables/requests/useUploadComplete.ts:16, 26-48`; `…/SubmittedJobSubmissionPage/sections/SubmittedFileUploadSection/SubmittedFileUploadSection.vue:66-69, 159`; `…/FilesUploadArea.vue:44-74, 76-106, 124-196`; `…/JobSubmissionProceedingFileUploadManager.vue:78-109`; `…/ProceedingUploadArea.vue:121-126` |
| Notes | **Completeness claim** established three ways: literal grep found no inline URLs; `uploadHandler` has exactly one `provide` and one `inject`; `createUploadContext` has exactly one caller — and each component in the chain has exactly one importer. Also: `useSubmittedJobFileUpload.ts` and `submitted-job-file-upload.ts` have **zero importers** (dead) |

### 17. `atlas-front-end` — request payload, track derivation, and the conversion selection

| Field | Value |
| --- | --- |
| Inspected | The completed-path request-body construction; `useFileUploadMapping`'s context factory and `getTrackTypeByRole`; `TRACK_TYPES` / `ROLE_TO_TRACK_MAPPING`; the mime-type helper and the extension gate; `BasicJobDetailsSection`'s `videoTranscode` field + its visibility rule; `useJobSubmissionOptions`; the submitted page's destructure |
| Findings | Payload = `uploadId, filename, jobId, trackTypeId, proceedingId, jobSubmissionFormId, jobTaskId?, size, key, mimetype, partsCount, length?` — all context values **stringified**, and **no preset field of any kind**; `perFileContextOverrides` is never passed by any AJSF component. `mimetype` is **not** the raw browser value: `file.type \|\| getMimeType(fileName)`, whose map covers 11 extensions and **falls back to `application/octet-stream`**; `isSupportedFileExtension` is dead (`return true` before its body) and `accept="*/*"`. Track is **not user-chosen** — derived from the job role (`Video → 3`, `Digital → 5`, Remote/Equipment Tech `→ 4`, Exhibit zone always `1`), so the UI **can** produce a video MIME on a non-video track and vice versa. The conversion selection is set only on the **pending** page, visible only to the `Video` role, options fetched from Callisto at runtime; it is **neither displayed nor editable on the submitted view** (though it is loaded into memory) |
| Status | contributing |
| Commit | `102e034d` · 2026-07-29 |
| Evidence | `…/useUploadComplete.ts:26-44`; `…/PendingJobSubmissionPage/composables/useFileUploadMapping.ts:10-24, 26-38`; `src/callisto/types/job-submission-form.ts:190, 193-215`; `…/UploadManager/helpers/mimeTypeMapping.ts:1-22`; `…/globalUtils/fileTypeLabel.ts:183-188`; `…/BasicJobDetailsSection.vue:172-186`; `…/fieldVisibilityConfig.ts:57-60`; `…/useJobSubmissionOptions.ts:35-40, 118-121`; `…/SubmittedJobSubmissionPage.vue:23-30, 74-109` |
| Notes | Confirms the preset must be re-read server-side, and that parity with submit means inheriting submit's MIME blind spots |

### 18. `atlas-front-end` — neighbours on the completed-upload path

| Field | Value |
| --- | --- |
| Inspected | The per-file `onSuccess` refetch cascade; the dialog-close refetch; the per-proceeding listener + query `staleTime`; the flat file list + count badge and the grouping helpers; error/toast handling and the request timeout; the upload-in-progress nav guards; the pending page's reachability for a submitted form |
| Findings | Every completion triggers a refetch cascade that fans a `refetch-proceeding-files` event to every proceeding; **there is no polling or websocket** on these lists (`staleTime` two minutes), so an async transcode result appears only on a manual refetch or navigation. A non-2xx from the completed endpoint → `markUploadFailed` → red "file failed to upload" toast **and** the cascade never fires, even though the bytes are in S3; `withUploadTimeout` aborts the completion request, so a slow synchronous emit surfaces as an upload failure. The submitted AJSF list renders files **flat** (it does not use the `sourceFileId` grouping helpers that the ops tables use). The pending route has **no `meta` and no guard**, so it is reachable by URL for a submitted form and its save is not status-gated |
| Status | contributing — the OV-1 / OV-2 consequence evidence |
| Commit | `102e034d` · 2026-07-29 |
| Evidence | `…/useUploadComplete.ts:46-48`; `…/FileUploadSectionCore.vue:204-230`; `…/JobSubmissionProceedingFileUploadManager.vue:55-76`; `…/useFetchJobSubmissionProceedingFilesByProceedingId.ts:12-18`; `…/ProceedingUploadArea.vue:51-100`; `…/useUploadItem.ts:41-95, 211-227`; `…/SubmittedFileUploadSection.vue:71-132`; `src/globalRouter/routes.ts:111-117` |
| Notes | The flat-render point is **not** a new-behaviour finding — area 13 shows derivatives already surface here today for pre-submit uploads |

## Not yet inspected (frontier)

- **Observed duplicate-deterministic-id behaviour in `outbox_events`** — area 12 is `partial`: the UPDATE-and-republish mechanism was read from library + TypeORM source but never run. An integration test would show the actual post-write `status`, `attempts`, and `published_at`. Decides whether the retry/concurrency exposure is "harmless overwrite" or "silent re-publish." (Report §8 A8.)
- **Nova's live behaviour after PRDV-16398 lands** — this ticket's AC8 depends on it, and 16398 is uncommitted with `vid-mix.preset.ts` blocked on the HandBrake preset. Would answer whether an emitted `Video Mix` request actually produces a Video Mix encode.
- **Whether `job_submission_forms.video_transcode_id` is edited by direct SQL in practice** — `docs/runbooks/pending-jobs-test-data.md:265, 298` writes it for seeding, which suggests operational direct-SQL edits are a real practice. Would sharpen the OV-4 risk from "possible via an unguarded API" to "happens."
- **Auth middleware populating `request.authUser`** — no `APP_GUARD`/`useGlobalGuards` and no `@UseGuards` on the submit or PATCH actions were found, but the middleware/interceptor chain was not traced. Would decide whether `PATCH /job-submission-form` is reachable **unauthenticated** or merely unauthorised (concern 1's severity).
- **Server-side role enforcement for `videoTranscodeId`** — the `Video`-role gate found is front-end-only; no global role interceptor was audited.
- **Callisto's `nova.proceeding.file.video-transcode-failed.v1` consumer** — none exists (referenced only in `docs/adr/ADR-002-notification-module.md:117`). Would answer whether a failed transcode is observable anywhere, which bears on the slow-feedback risk in report §7.
- **Nova's failed + notification outbox converters** — carried forward `partial` from the PRDV-16398 ledger (its area 6); not re-opened here.
- **`SUBMISSION_STATUSES.PARTIAL` writer** — defined but no write path found in this repo; may be legacy or external.
- **The proceedings-module `fetch-files-by-proceeding-id` action vs the AJSF one** — both terminate in the same TS and repository method, so area 13's conclusion holds either way, but which the submitted page calls was not pinned from the Atlas side.
