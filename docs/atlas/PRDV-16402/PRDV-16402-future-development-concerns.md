---
ticket: PRDV-16402
tags: [atlas, callisto, video-transcode, ajsf, outbox, concerns]
author: Dustin Thomason
created: 2026-07-29
modified: 2026-07-29
---

# PRDV-16402 — Future-development concerns (post-submit AJSF transcode emission)

> **Context:** PRDV-16402 adds a second emission site for `callisto.proceeding.file.video-transcode-requested.v1` — the completed AJSF upload path. Investigating that one call site traversed the whole emission and consumption chain and surfaced ten risks that are **out of scope** for the ticket. Several are pre-existing; three are *widened* by adding a second emitter.
> **Purpose of this document:** a dated, code-verified record that these risks were identified and raised — for team discussion and, where needed, escalation.
> **Constructive path forward:** two exist and are named — the outbox-projector rearchitecture ([report §6 alternative 4](investigations/PRDV-16402-investigation.md)) retires concerns 3 and 4 by replacing both call sites with one idempotent, self-healing runner; and wiring the already-written-but-dead `FileDerivationRepository.findBySourceAndProcess` closes concern 7 cheaply. Concern 1 needs its own ticket and is arguably a security ticket.

## Executive summary (for escalation)

**One item here is materially more serious than the rest and does not belong to this ticket's subject matter at all.**

`PATCH /proceeding-job-submission/job-submission-form` accepts a target form id **in the request body** and has **no authorization guard, no ownership check, and no user context whatsoever** — it never reads the authenticated user. Its DTO accepts both `videoTranscodeId` and `submissionStatusId`, and its transaction script performs a bare `repository.update` with no submission-status precondition. So any caller who can reach the endpoint can rewrite the conversion preset **and the submission status** of **any** job submission form, including one already submitted, without being its owner.

Why it matters even if rare: the fallout is not a bad render. Submission status is what gates a form out of the pending queue and into the submitted queue; the preset is what determines how a deposition video is encoded for the video team. A wrong or malicious write is silent — nothing audits it, nothing notifies, and the existing `JobSubmissionFormStatusValidator` (which does exist and does work) is wired only into the submit service, not into this update path. Note this is a **general** exposure of the endpoint; PRDV-16402 does not create it and does not widen it, but the investigation could not verify whether the route is reachable **unauthenticated** or merely **unauthorized**, because the auth middleware chain was not traced.

**Decision requested**, from someone with authority over Callisto's AJSF surface:
- **(a)** Raise a separate ticket to add a guard + ownership check + status precondition to the update path — recommended, and treat it as a security ticket rather than a maintenance one.
- **(b)** Confirm by tracing the auth middleware that the route is at least authenticated, downgrade the severity accordingly, and still schedule (a).
- **(c)** Accept as-is and record that acceptance here, with the reasoning.

Concerns 2–10 are ordinary engineering risks: raise them for awareness, schedule the cheap ones, and do not let them expand this ticket.

---

## Concern 1 — `PATCH /job-submission-form` is unguarded and can rewrite preset *and* submission status on any form

The endpoint takes the target form id from the body, never reads the authenticated user, and applies whatever fields it is given. `videoTranscodeId` and `submissionStatusId` are both writable, on a form in any state. The one validator that would prevent post-submit mutation exists but is wired only into the submit service.

- **Evidence (verified 2026-07-29):** `src/proceeding-job-submission/application/controllers/actions/update-job-submission-form-action/update-job-submission-form.action.ts:14-20` — `@Patch('/job-submission-form')`, **no** `@UseGuards`, **no** `@VerifiedUserDecorator`; `…/update-job-submission-form.request.dto.ts:16` (`id`), `:34` (`submissionStatusId`), `:81` (`videoTranscodeId`); `…/update-job-submission-form.transaction.script.ts:13-22` — bare `repository.update`, no status read, not `@Transactional()`; the validator that is *not* called here: `…/domain/validators/job-submission-form-status.validator.ts:7-15`, whose only production call site is `…/job-submission-service/job-submission.service.ts:72-74`. No `APP_GUARD`/`useGlobalGuards` exists in `src`. Atlas reaches it via the pending route `src/globalRouter/routes.ts:111-117`, which has **no `meta` block at all** — no `requiresAuth`, no `requiredPermissions` — so a submitted form's pending page is reachable by URL and its save is not status-gated.
- **Unverified (labeled as such):** whether the route is reachable fully unauthenticated. The middleware/interceptor chain populating `request.authUser` was not traced, and no server-side enforcement of the `Video` role for `videoTranscodeId` was found — the role gate located is front-end-only (`…/fieldVisibilityConfig.ts:57-60`).
- **What would resolve it:** a dedicated ticket adding a create/update auth guard, an ownership check equivalent to `AjsfAccessGuard`'s, and a submission-status precondition reusing the existing validator. Tracing the auth middleware first would settle the severity.

## Concern 2 — the conversion preset is mutable after submit, with no snapshot, so "the initial submission" is unrecordable

The ticket's requirement is that post-submit uploads are transcoded "matching the conversion specs from the **initial submission**." No such record exists. `SubmitJobSubmissionFormTS` writes only status, submitter id, submitter email, and `updatedAt` — it never captures the preset in force at submit time. So the only value any later code can read is the *current* one, and concern 1's endpoint can change it at will. PRDV-16402 will therefore emit against the current stored value (decision OV-4), which is the only thing the data model supports.

Two consequences that will look like bugs to someone later: a `None → Standard` change after submit emits **nothing** for files already on the form (eligibility is evaluated only at emit time), and a `Standard → None` change **retracts nothing** already emitted. A file uploaded before the edit and one uploaded after can legitimately be encoded to different presets on the same job.

- **Evidence (verified 2026-07-29):** `…/submit-job-submission-form.transaction.script.ts:36-44` (write payload — no preset); `…/job-submission-form.entity.ts:81-90` (the single mutable `video_transcode_id` column, no history table); `…/is-video-transcode-selection-eligible-for-outbox.ts:9-17` (gate applied at emit time only); concern 1's evidence for mutability.
- **What would resolve it:** either snapshot the selection at submit (a column or a small history row, written inside submit's existing transaction) or accept the current-value semantics explicitly and reword the requirement to say "the form's stored selection" rather than "the initial submission." The wording change is free; the snapshot is a schema change.

## Concern 3 — `findDeletedFileByPath` is named for deleted files but behaves as upsert-by-path, so an upload retry duplicates work

The method applies `.withDeleted()` with **no `deletedAt IS NOT NULL` predicate**, so it matches any file at that `(bucket, filePath)` — live or deleted. Combined with a mapper that always mints a **fresh** `FileAttachment` and a service that always **inserts** a new `jsffa` row, retrying a completed upload for the same key UPDATEs the existing `files` row, orphans the previous attachment, and — once PRDV-16402 ships — emits a **second** transcode request. Because the UPDATE moves `files.updated_at`, and `updated_at` is an input to the deterministic event id, the second event has a **different** id, so no same-id dedupe can catch it. Nova transcodes twice.

PRDV-16402 does not create this path but does add the duplicate-emission consequence to it. The name is the trap: a reader who greps for it will believe it only handles restorations.

- **Evidence (verified 2026-07-29):** `src/proceedings/infrastructure/repositories/proceeding-file.repository.ts:144-158` (`.withDeleted()`, no `deletedAt` filter); the revival branch `…/upload-complete-proceeding-file-ts/upload-complete-proceeding-file.transaction.script.ts:29-33`; unique index `src/shared/shared-entities/entities/files/file.entity.ts:21`; fresh attachment per call `…/create-proceeding-file.mapper.ts:31-37` → `…/create-file-attachment.assembler.ts:31-49`; unconditional join-row insert `…/job-submission-form-file-attachment.assembler.ts:17-28` (PK is `@PrimaryGeneratedColumn`, no unique constraint); id inputs `src/generic/outbox-projector/domain/deterministic-event-id.helper.ts:20-29`.
- **What would resolve it:** rename the method to what it does and add the `deletedAt` predicate if restoration was the intent; or wrap create + outbox in one transaction (decision OV-3), which at least removes the orphan rows. The projector rearchitecture removes the whole class.

## Concern 4 — an outbox write with an existing id resurrects a published event instead of no-op'ing

`OutboxEventRepository.create` builds the entity with an **explicit primary key** plus `status: PENDING, attempts: 0`, then calls `repo.save()`. TypeORM loads the existing row first, finds the PK populated, and therefore issues an **UPDATE** — resetting `status` and `attempts`, while leaving `published_at`, `locked_at`, `locked_by`, and `last_error` at their stale values, because they are not in the payload. The net effect of a duplicate write is an **already-published event queued for republication**, with a non-null `published_at` on a `pending` row. There is no unique constraint beyond the PK and no `ON CONFLICT` / `orIgnore` / `orUpdate` anywhere in the write path.

Callisto's own projector engine compensates with an explicit `existsById` pre-check. **Neither command-driven writer does** — including the one PRDV-16402 will call. The reachable interleaving is concurrent submit: the re-submit validator runs *outside* the transaction, so two simultaneous `POST /submit/:formId` calls can both pass it and both write the same id.

- **Evidence (verified 2026-07-29, read from library + TypeORM source):** `node_modules/@planetdepos/orbital-relay-pkg/dist/outbox/infrastructure/repositories/outbox-event.repository.js:37-50`; `…/domain/transaction-scripts/write-outbox-event-ts/write-outbox-event.transaction.script.js:25-45`; PK-only migration `src/typeorm/migrations/1772165619858-create__outbox_events_table.ts:7-27`; insert-vs-update decision in `node_modules/typeorm/persistence/Subject.js:107-108` and `…/SubjectDatabaseEntityLoader.js:28-45`; the compensating guard `src/generic/outbox-projector/domain/outbox-projector.engine.ts:88-93`; the unguarded writers `…/job-submission-video-transcode-requested-outbox.writer.ts:39-54` and `…/proceeding-outbox-writer.assembler.ts:57-76`; the concurrency window `…/job-submission.service.ts:72-74` vs `:81`.
- **Unverified (labeled as such):** the **observed** post-write column state. This was read from source, never run. It is on the coverage-ledger frontier and is test EC-9 / assumption A8.
- **What would resolve it:** an `insertOrIgnore` / `ON CONFLICT DO NOTHING` in the relay package's `create`, which is the correct home for it, since every writer inherits the fix. A per-writer `existsById` guard is the weaker local option and would make the writer look guarded while the submit path is not.

## Concern 5 — the MIME signal is a client-side heuristic, so some real videos never transcode on **either** path

Eligibility filters on `LOWER(f.fileType) LIKE 'video/%'`, and `f.fileType` is whatever the client sent. Atlas sends `file.type || getMimeType(fileName)`, and that fallback map covers only eleven extensions and otherwise returns **`application/octet-stream`**. So a `.ts`, `.amr`, `.opus`, `.alac`, or `.aif` file that the browser does not type — all of which are in Atlas's own `MEDIA_EXTENSIONS` list — arrives as `application/octet-stream` and is silently ineligible. The extension gate that might have caught it is dead code (`return true` before its body), and the file inputs use `accept="*/*"`.

Compounding it, the track signal is **role-derived, not content-derived**: the exhibit zone always sends track 1, and a `Digital`-role submitter's main zone sends track 5 (Audio), so a video dropped there is ineligible regardless of MIME — while a `Video`-role submitter's PDF lands on track 3 and passes the track test. Neither signal alone is safe, and the front end offers no third one.

This is **pre-existing and symmetrical** — parity with submit is PRDV-16402's goal, and parity means inheriting the blind spot. It is recorded because the ticket's user-facing promise is "all files I upload," which this quietly contradicts.

- **Evidence (verified 2026-07-29):** predicate `…/job-submission-form-file-attachment.repository.ts:86-88`; client MIME resolution `atlas-front-end/src/callisto/components/FileUploadWrapper/FileUploadWrapper.vue:82, 129-134` and `…/UploadManager/helpers/mimeTypeMapping.ts:1-22`; dead gate `…/globalUtils/fileTypeLabel.ts:183-188`; `accept="*/*"` at `…/FilesUploadArea.vue:126, 172`; role→track mapping `src/callisto/types/job-submission-form.ts:193-215` and `…/useFileUploadMapping.ts:12-24`.
- **What would resolve it:** server-side content sniffing on upload, or an explicit "this is a video for conversion" affordance in the UI. Both are product decisions well beyond this ticket.

## Concern 6 — a transcoded derivative can collide byte-for-byte on filename with its own source

Nova's derivative is named `<source stem>.mp4` and written with `fileType: 'video/mp4'`, copying the source attachment's `attachedToId`, `attachedToType`, **and** `trackTypeId`, then tagged `Submission File`. When the source is already an `.mp4` — the common case — source and derivative end up with the **identical `fileName`** in the same proceeding, same track, same tag. The persist mapper does **not** run the duplicate-name validator that the upload path uses. The AJSF list query returns both. More emission sites means more occurrences.

- **Evidence (verified 2026-07-29):** `…/resolve-video-transcode-processing-context.assembler.ts:146-150` (name) and `:24` (`video/mp4`); `…/persist-video-transcode-derivative.mapper.ts:57-68` (copied attachment fields), `:70-86` (tag), `:88-105` (file row); the validator it skips `…/domain/validators/duplicate-job-submission-file-name.validator.ts:26` and the check it does not call `…/proceeding-file.repository.ts:94`; the list query that returns both `src/proceedings/infrastructure/repositories/file-attachment.repository.ts:37-91`.
- **What would resolve it:** suffix the derivative (e.g. `<stem>-video-mix.mp4`) or include the preset in the name. Cheap, but it touches the completed-event path rather than this ticket's, and changes filenames users may already recognise.

## Concern 7 — the consumer-side idempotency guard is already written and is dead code

`FileDerivationRepository.findBySourceAndProcess` is keyed on exactly the right tuple — `(sourceFileId, processType, processTypeId)` — to prevent a second derivative for the same source and preset. **Nothing calls it.** The persist mapper's only collision check is the S3 destination key, which embeds a fresh `randomUUID()` per run and so can never collide by design (its own comment says as much). Inbox dedupe protects against a **repeated envelope id**, not against a genuine re-emission with a new one — and re-emission is precisely what concerns 3 and 4 produce. There is also no unique constraint on `file_derivations` to back it up.

- **Evidence (verified 2026-07-29):** the dead method `src/proceedings/infrastructure/repositories/file-derivation.repository.ts:36-46` (grep across `src` returns only its own definition); the mapper's dependency list `…/persist-video-transcode-derivative.mapper.ts:33-38` (no `FileDerivationRepository` read, only `create` at `:107-122`); the ineffective key check `…/resolve-video-transcode-processing-context.assembler.ts:99-111, 127-135`; envelope-only inbox dedupe `node_modules/@planetdepos/orbital-receiver-pkg/dist/inbox/infrastructure/repositories/inbox-event.repository.js:65`; no unique constraint in `src/typeorm/migrations/1776799165302-create__file_derivations_table.ts:12-33`.
- **What would resolve it:** call `findBySourceAndProcess` in the persist mapper and skip when a completed derivation already exists, and/or add a unique index. Cheapest item on this list. **Deliberately not ridden along** — it touches the proceedings module and the completed-event path, outside this ticket's blast radius, and needs its own tests.

## Concern 8 — the architecture fitness functions are not enforced by any git hook, and the code says they are

`src/__tests__/architecture.spec.ts:6` documents itself as *"executed in the pre-commit hook via Husky."* It is not. `.husky/pre-commit` runs prettier only; `.husky/pre-push` runs prettier, `lint-staged`, and integration tests. Neither invokes `test:architecture` or `test:conventions`. The rules do run via `pretest` before `npm test`, so a developer who runs the suite is covered — but a developer who trusts the docstring and relies on the hook is not. This matters concretely here: the TS→TS rule is the specific gate that rejects the shape the coworker spec proposed, so an unrun gate is how that shape reaches review.

- **Evidence (verified 2026-07-29):** the stale claim `src/__tests__/architecture.spec.ts:6`; actual hooks `.husky/pre-commit`, `.husky/pre-push`; the real wiring `package.json:29` (`pretest`), `:31` (`test:architecture`), `:37` (`test:conventions`).
- **What would resolve it:** either add `test:conventions` to `pre-push` or correct the docstring. Correcting the comment is free and stops the false assurance.

## Concern 9 — `SUBMISSION_STATUSES.PARTIAL` is defined with no writer found

`'Partial'` is one of three submission statuses and appears to be unreachable: forms are created with `''` and submit sets `'Done'`. No write path setting `'Partial'` was found in `callisto-back-end`. If it is genuinely dead, it invites a reader to assume a state machine that does not exist; if it is written by something outside this repo (or by the direct-SQL runbook practice noted below), then any status-based reasoning — including concern 2's — has a case it has not considered.

- **Evidence (verified 2026-07-29):** definition `…/entities/job-submission/submission-status.entity.ts:5-9`; create seeds `''` at `…/fetch-or-create-job-submission-form.transaction.script.ts:75-79`; submit sets `Done` at `…/submit-job-submission-form.transaction.script.ts:32-44`.
- **Unverified (labeled as such):** the search was not exhaustive across sibling services. Also relevant: `docs/runbooks/pending-jobs-test-data.md:265, 298` writes `video_transcode_id` via raw SQL for seeding, which indicates operational direct-SQL edits are a real practice — so form columns may be set by paths no code search will find.
- **What would resolve it:** confirm whether `Partial` is legacy and remove it, or document what writes it.

## Concern 10 — dead front-end code shadows the live upload path

`SubmittedJobSubmissionPage/composables/useSubmittedJobFileUpload.ts` and `SubmittedJobSubmissionPage/types/submitted-job-file-upload.ts` have **zero importers**, yet the composable exposes a `handleUploadComplete` that reads like the live handler. The real path is `FileUploadSectionCore.vue:223`. Anyone investigating this page's upload behaviour — as this ticket did — can lose time in the wrong file. Compounding it, there are **no specs anywhere** under `SubmittedJobSubmissionPage/`, so nothing asserts that the section uses the *completed* URL; a future refactor could repoint it to the pending endpoint silently and break this ticket's feature with no test failing.

- **Evidence (verified 2026-07-29):** zero-importer grep on both files; live handler `atlas-front-end/src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/sections/FileUploadSectionCore.vue:223-230`; the URL binding that has no test `…/SubmittedFileUploadSection/SubmittedFileUploadSection.vue:66-69`; no `__specs__` directory under `SubmittedJobSubmissionPage/`.
- **What would resolve it:** delete both dead files, and add one spec asserting the submitted section passes `UPLOAD_COMPLETE_PROCEEDING_AJSF_COMPLETED_URL`. The spec is worth more than the deletion — it is the only thing that would protect PRDV-16402's feature from a front-end refactor.

---

## Decision history

- **2026-07-28** — Larry Adams filed the coworker spec (`larry-adams/systems/neptune/callisto/video-transcode/PRDV-16402-…-submitted-ajsf.md`) and linked it on the ClickUp ticket. It raised two open questions of its own — whether the outbox write should share a transaction with file-attachment creation, and whether product wants a backfill — and flagged three complexity risks. Its core diagnosis was later confirmed correct in full.
- **2026-07-29** — Phase 1 investigation (`~/.claude/plans/go-melodic-rain.md`). Consulted the PRDV-16398 coverage ledger, whose own frontier item turned out to *be* this ticket. Established assumptions A1–A16 by evidence; concerns 1–10 above were surfaced as by-products of that traversal, none of them in the ticket's scope. Larry's first open question was resolved by evidence rather than by asking: the completed path is not transactional today, so a shared transaction is achievable but requires widening the scope to `UploadCompleteProceedingFileTransactionScript` — recorded as decision OV-3 rather than an open question.
- **2026-07-29** — User confirmed disposition **proceed with conditions** and directed Phase 3 to write an independent spec citing Larry's as input, on the strength of three code-verified divergences.
- **2026-07-29** — The outbox-projector rearchitecture was considered and **rejected for this ticket** with reasons recorded ([report §6 alternative 4](investigations/PRDV-16402-investigation.md)), and filed as the follow-up that would retire both emission call sites. Concerns 3 and 4 are its strongest justification.
- **Pending** — concerns 1–10 raised for team discussion; none has an accept/reject decision recorded yet.

## Open questions to settle

1. Is `PATCH /job-submission-form` reachable unauthenticated, or merely unauthorized? (Decides concern 1's severity, and whether it is a security ticket or a maintenance one.) — owner: **Dustin** to trace the auth middleware; then **Callisto lead / Product**
2. Should the conversion preset be snapshotted at submit, or should the requirement be reworded to "the form's stored selection"? — owner: **Product** (ties to decision OV-4)
3. Should `insertOrIgnore` semantics be added to the relay package's outbox `create`, so every writer inherits idempotency? — owner: **Callisto lead / whoever owns `orbital-relay-pkg`**
4. Is the MIME/track eligibility heuristic acceptable long-term, given the ticket promises "all files I upload"? — owner: **Product**
5. Should `findBySourceAndProcess` be wired in and a unique index added on `file_derivations` — as a fast-follow, or bundled with the projector work? — owner: **Dustin / Callisto lead**
6. Does anyone still rely on `SUBMISSION_STATUSES.PARTIAL`? — owner: **Callisto lead**
