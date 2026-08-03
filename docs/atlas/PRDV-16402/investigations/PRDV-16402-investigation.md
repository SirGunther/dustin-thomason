# Investigation Report: Transcode additional video uploads to submitted AJSFs

> **What this is:** the delivered results of running the `investigate` method — findings and recommendation, plus the plan for what happens next.
> **What this is not:** a plan *to* investigate.

## Metadata
- **Status:** planned
- **Disposition:** **proceed with conditions**
- **Date:** 2026-07-29
- **Owner:** Dustin Thomason
- **Location:** `docs/atlas/PRDV-16402/investigations/PRDV-16402-investigation.md` — orchestrated tickets override the template's default `docs/investigations/` path
- **Ticket:** [PRDV-16402](https://app.clickup.com/t/43227262/PRDV-16402)
- **Domain:** software (backend event emission; Vue front end read-only in scope)
- **References / evidence:**
  - `callisto-back-end` `main` `47f5a841` (pre-existing local edits `.swcrc`, `notification-template-preview.html`, untracked `scripts/` — untouched)
  - `atlas-front-end` `main` `102e034d` (clean)
  - `nova-back-end` branch `PRDV-16398` `58a6182`
  - Coworker spec (read-only input): [`larry-adams/systems/neptune/callisto/video-transcode/PRDV-16402-…-submitted-ajsf.md`](https://github.com/planetdepos/larry-adams/blob/main/systems/neptune/callisto/video-transcode/PRDV-16402-transcode-additional-video-uploads-to-submitted-ajsf.md)
  - Prior coverage reused: `docs/nova/tickets/nova-applies-selected-transcode-preset/investigations/PRDV-16398-coverage-ledger.md`
  - Traversal index for this ticket: [`PRDV-16402-coverage-ledger.md`](PRDV-16402-coverage-ledger.md) · Diagrams: [`PRDV-16402-diagrams.md`](PRDV-16402-diagrams.md)

---

## 0. Verdict (bottom line up front)

The gap is real, narrowly scoped, and entirely wireable from parts that already exist and already work — this is a missing call site, not missing machinery. Callisto's completed-upload path (`POST /proceeding-job-submission/upload-complete-completed`) creates the file, audits it, and fires the legacy SQS event, but writes no `callisto.proceeding.file.video-transcode-requested.v1` outbox row, so every video uploaded to a submitted AJSF drops out of the transcode pipeline silently. Reuse submit's whole outbox stack and add a **by-file-id sibling of submit's own eligibility query**, so track / MIME / attachment-type keep exactly one definition and the two paths cannot drift. What this is **not** is a ticket that can satisfy its own written acceptance criterion: "transcoded **matching** the conversion specs" depends on PRDV-16398, which is unshipped, so the *matching* half is unverifiable end-to-end today. It is also not an approval of the coworker spec as-written — that spec's proposed flow would fail `npm run test:architecture`, and it re-states an eligibility rule it also under-counts.

- **Strongest path:** new `@Transactional`-proxied transaction script invoked by the completed-upload service after `createProceedingFile`; it loads the form's stored preset, applies the existing `IsVideoTranscodeSelectionEligibleForOutbox` gate, runs a new single-file variant of the existing outbox query, and calls the **existing** `writeRequestedEvents` with a one-element `files` array. Feature flag resolved in the *service* and passed in as a boolean, exactly as `JobSubmissionService.submitJob` does. First-ever spec for the touched service supplies the red→green proof.
- **Not yet proven / not approved:** the "matching the specs" half of the AC (gated on PRDV-16398); the outbox duplicate-`save()` republish behaviour (read from library source, not yet proven by an integration test); six genuine decisions in §10 that Phase 3 must lock before implementation.

## 1. Problem class

- **Class the request assumed** (implied by how it was framed): a **new capability** — "I want files uploaded to the submitted jobs tab … to *also* be transcoded." Framed as behaviour to be added.
- **Confirmed class** (derived from instances, re-checked against root cause): a **coverage gap in an event-emission surface**. Three code paths create AJSF proceeding files; exactly one emits the transcode request. Every component needed by the other one already exists and is exercised in production: the eligibility gate, the projection, the descriptor converter, the deterministic-id helper, the writer, the port token, the feature flag, the docking-protocol event type, and Nova's consumer chain. What is absent is a **call site**.
- **Reframed?** **Yes** → from **new capability** to **coverage gap / missed emission surface**, triggered at Step 4 when the root-cause trace showed the completed-upload service injects no outbox collaborator at all while a fully-built stack sits one module away. The ticket's own ClickUp tag — "missed requirement" — independently agrees. The reframe is a sharpening rather than a redirect: the target file is the same either way. Its consequence is not.
- **What the confirmed class implies:** the solution space collapses from "design emission for this path" to "**mirror the existing emitter exactly**." Any freshly-written eligibility logic is a defect surface, not a feature. Concretely it rules out the shape the coworker spec proposes (§6, alternative 1) and rules in a single-file variant of the query that already owns those rules. It also means correctness is checkable by *comparison* — the new path either produces the same event the submit path would have produced for that file, or it is wrong.

## 2. Problem statement (the raw facts)

- **Named instances:** **none individually named — stated plainly per the method.** The ticket carries no named blocked user, no support ticket, and no reproduction from a specific job. The instance is class-level and unbounded: every LTR videographer who uploads a video through the submitted-jobs tab, on every job, since the feature shipped. Its ClickUp provenance is a **missed requirement / sprint addition** raised internally (Larry Adams filed the spec; Kat Giangiulio asked about assignment) — i.e. it was found by inspection, not by a user complaint. That weakens urgency evidence, not the defect: the code path is proven silent by direct read, and the silence is invisible to the uploader, so absence of complaints is exactly what this defect predicts.
- **One sentence:** A video file uploaded to an already-submitted AJSF is stored successfully but never queued for transcoding, and nothing tells the uploader.
- **Distinct problems** (kept apart):
  1. **The request is never made** — the completed-upload path writes no outbox row. *This ticket.*
  2. **The request is ignored** — Nova receives `videoTranscodeValue` and applies `template1` regardless. *PRDV-16398.* The ticket's single AC bundles both; §4 and §10 unbundle them.
  3. **The eligibility rule would gain a second definition** under the obvious fix — a drift surface created by the repair itself.
  4. **"From the initial submission" is not a thing the data model records** — the preset is mutable post-submit with no snapshot (§8 A3).
- **Urgency:** No date in the ticket. Status READY FOR WORK, Priority High, 2 points, sprint addition, Owning Team NASA, Primary Stakeholder Product. It bites **on the next post-submit video upload** and has been biting continuously; there is no future trigger event to wait for. The honest framing is *ongoing silent loss*, not a deadline.
- **Wedge:** the **single-file, by-file-id variant of submit's own eligibility query**. Smallest change that opens the space, and reusable by any future emission surface (the pending path, a replace-file path, a re-drop) without re-deriving eligibility. It is reusable *within the confirmed class* precisely because the class is "another surface needs the same rule."

### Problem Check

- **Asked:** files uploaded post-submit should be transcoded to the same spec as the initial submission — *evidence:* "files uploaded to the submitted jobs tab of the AJSF to also be transcoded matching the conversion specs from the initial submission".
- **Answered:** what this ticket can deliver is that an outbox **request** is emitted carrying the form's stored preset. Drift named: *emitted-with* ≠ *transcoded-matching* — *evidence:* AC reads "are transcoded matching the specs of the initial job submission", which is Nova's behaviour, not Callisto's.
- **Should-ask:** "Does a transcode request get made, with the form's stored selection, for files uploaded after submit?" — *why:* it is the half this ticket owns and can prove; it decides whether 16402 is verifiable independently of 16398, which §10 answers yes.
- **Conflation:** two distinct problems treated as one, and additionally an over-broad file scope. (a) *request never made* (16402) vs *request ignored* (16398) — solving either alone leaves the user-visible outcome unchanged; both are needed for the AC as written. (b) *evidence:* "so that **all files** I upload for a job are transcoded" vs the AC's "All **video** files"; neither matches what will ship, since eligibility is attachment-type `Proceeding` **and** track `Video` **and** MIME `video/%` **and** preset ∈ {Standard, Video Mix} **and** the feature flag. A Video-role user's exhibit-zone upload lands on track 1 and will not transcode.
- **Thin:** "the conversion specs from the initial submission" — *evidence:* that phrase. Resolved by evidence to `job_submission_forms.video_transcode_id` (the only per-form conversion selection), but the qualifier **"initial"** is undefined against the data: nothing snapshots the value at submit, and it is mutable afterwards through an unguarded endpoint (§8 A3). The system cannot distinguish "what was selected at submit" from "what is selected now."
- **Off:** nothing here on intent — the story and AC agree in direction. One internal tension worth stating rather than a contradiction: *evidence:* "transcoded matching the specs of the initial job submission" → the same AC is unverifiable end-to-end until PRDV-16398 ships, so as written it cannot be signed off on this ticket alone.

## 3. The contract

### Acceptance criteria

| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| AC1 — All eligible video files uploaded to a submitted AJSF (`upload-complete-completed`) emit a transcode request carrying the **same** `videoTranscode` selection stored on that form | needs-proof | Unit proof that the writer is called once with that file and the form's preset; manual repro per §9 |
| AC2 — Eligibility matches submit exactly: attachment-type `Proceeding`, track `Video`, MIME `video/%`, preset ∈ {Standard, Video Mix}, flag `IS_VIDEO_TRANSCODE_ENABLED` on | needs-proof | Satisfied structurally by reusing the same SQL predicates + the same gate object; asserted by the eligibility matrix in the test plan. **Note the ticket/spec state four conditions; there are five — `fa.attachedToType` is the omitted one** |
| AC3 — Event type and payload identical to the submit path (`callisto.proceeding.file.video-transcode-requested.v1` via `JobSubmissionVideoTranscodeRequestedOutboxWriter`) | covered by design | Guaranteed by calling the existing writer unchanged; assert the descriptor payload in the new spec |
| AC4 — Non-video uploads, ineligible presets, and flag-off create the file as today and write **no** outbox row | needs-proof | Negative assertions across the eligibility matrix |
| AC5 — Pending path (`upload-complete`) remains unchanged; submit still owns batch emission | needs-proof | A pin asserting `uploadCompleteForPendingJobSubmission` does not call the new TS (no such assertion exists anywhere today — §8 A11) |
| AC6 — Legacy SQS `ProceedingFileUploadDispatcher` behaviour on the completed path unchanged | needs-proof | Call-order + call-args assertion in the new service spec |
| AC7 *(added by this investigation)* — Upload outcome on emit failure is the **deliberate** behaviour, not an accident | gap | Blocked on decision OV-1; then asserted |
| AC8 *(added by this investigation)* — "transcoded **matching**" the selected preset | **gap — not closeable on this ticket** | PRDV-16398 must ship. Nova applies `template1` regardless today. Named gate, see §10 |

### Non-goals / out of scope

- **Nova, the docking protocol, and nova-orbital** — no consumer, contract, or transport change.
- **The legacy SQS proceeding-file-upload event** — stays exactly as-is; outbox is additive.
- **The pending upload-complete path** — submit remains its batch emitter. Adding emission there would double-emit at submit.
- **Backfilling** post-submit uploads that never got outbox rows, and re-emitting for files whose preset changed after submit.
- **The MIME/track heuristics themselves** — `mimetype` is an extension-map guess with an `application/octet-stream` fallback, and track is role-derived; parity with submit is the goal, and parity means inheriting submit's blind spots (concern 5).
- **Every item in [future-development concerns](../PRDV-16402-future-development-concerns.md)** — including the unguarded `PATCH /job-submission-form`, which is a genuine security finding but not this ticket's remit.
- **The projector-runner rearchitecture** (§6 alternative 4) — filed as the follow-up that retires both call sites.
- **Any front-end change** — §8 A12/A14.

## 4. What changed since the request was created

- **Shifted from:** "add transcoding to the submitted-jobs upload path" → **to:** "add the *missing call site* on one of three file-creating paths, mirroring the existing emitter exactly — and unbundle an acceptance criterion that spans two tickets."
  The class change is the headline; see §1. Two further shifts sit on top of it:
  - The AC as written cannot be met by this ticket. **Nova ignores the preset today.** That was not visible in the ticket, the AC, or the coworker spec; it surfaced from the companion ticket's coverage ledger.
  - The coworker spec — a strong, code-grounded input whose core claim is correct — has three code-verified divergences from what the repo will actually accept (§6, §7 Fit).
- **What that buys us:** a fix whose correctness is checkable by comparison rather than by reasoning ("does it emit what submit would have emitted for this file?"); a single definition of eligibility preserved rather than duplicated; and an honest AC split, so QA is not handed an unverifiable criterion.
- **What it still needs to prove:** that the by-file-id query returns exactly the row submit's query would have returned for that file; that emission behaves correctly under the four negative conditions; that the pending path and legacy SQS are untouched; and — separately, on 16398 — that Nova honours the value.

## 5. Why it exists

- **Origin traced to:** video-transcode emission was built **at the form-submit moment**, with batch semantics — one query over all files linked to the form, one emission pass. The completed-upload path was built earlier and separately, for a different purpose (attach a file to an already-submitted form), and was never revisited when transcode emission landed. `SubmitJobSubmissionFormTS:54-75` reads *all* eligible rows for the form; the completed-upload service has no notion of transcode at all. There is no dead code, no disabled branch, no TODO referencing it — the path was simply not in view. Larry's spec puts it precisely: "Video transcode outbox emission exists only on **form submit** … Files uploaded after submit never enter Nova's transcode pipeline."
- **Evidence** (primary-source pointers):
  - The gap: `multi-part-upload-proceeding-job-submission-file-complete-upload.service.ts:75-102` (three steps, no outbox) and `:19-27` (five injected deps, none transcode-related). The only `@TODO` is `:16` "Split this class up."
  - The emitter it should mirror: `submit-job-submission-form.transaction.script.ts:45-75`; flag resolved by the caller at `job-submission.service.ts:76-85`.
  - The eligibility authority — **all in SQL**: `job-submission-form-file-attachment.repository.ts:80-88` (`fa.attachedToType = 'Proceeding'`, `tt.value = 'Video'`, `LOWER(f.fileType) LIKE 'video/%'`) plus the separate preset gate `is-video-transcode-selection-eligible-for-outbox.ts:9-17`.
  - Downstream proof the machinery works: Callisto's completed-event consumer chain persists a derivative file + `file_derivations` edge (`persist-video-transcode-derivative.mapper.ts:41-122`), and that derivative already surfaces on the submitted AJSF view via `pair-original-and-processed.converter.ts:29-54`.
- **Class re-check:** **held, and sharpened.** The root-cause evidence is the *absence* of a collaborator rather than a wrong computation — which is what a coverage gap looks like, and is the opposite of what a "new capability" would look like (no partial implementation, no placeholder, nothing to finish). The wedge and acceptance criteria were set after this re-check, not before.
- **Detection gap (why the net missed it):** there is **no spec file for `MultiPartUploadProceedingJobSubmissionFileCompleteUploadService` at all** — its `__specs__/` folder holds only `job-submission-form-file-attachment.assembler.spec.ts`. There is no action-level spec for either upload-complete action, no e2e coverage of the route, and **no assertion anywhere that either upload path does or does not emit**. The three `.not.toHaveBeenCalled()` assertions on `writeRequestedEvents` all live in the submit-TS spec and concern ineligible presets / empty rows / flag-off. Nothing could have caught this, and nothing would catch its regression. That directly designs the red→green test in §9.
- **Contract alignment note:** the writer port declares `jobDate: Date`, but `job_date` is `@Column({ type: 'date' })`, which pg hydrates as a `'YYYY-MM-DD'` **string**. The port is already lying; it works only because the converter accepts `Date | string` and branches on `typeof`. The submit spec's `new Date(...)` fixture therefore does **not** exercise production shape. Widen the port in this ticket — the lie is about to gain a second call site.

## 6. Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| **1. Re-express track/MIME as TypeScript predicates in the new TS** (the coworker spec's shape) | Creates a second definition of the eligibility rule on day one — and an already-incomplete one, since the spec lists two of the three SQL predicates and omits `fa.attachedToType`. The likely future drift is someone widening the SQL (e.g. to include MVC) and never touching the TypeScript copy. Also, its flow calls `FetchJobSubmissionFormTS` **from inside a transaction script**, which `transaction-scripts-no-other-transaction-scripts` forbids at `severity: error` and `npm run test:architecture` (run by `pretest`) would fail. |
| **2. Assemble the projection in memory from the `createProceedingFile` result** | Rejected on **fragility, not availability** — worth stating precisely, because the coworker spec's "Complexity flag 2" claims the fields are missing and that is only true at the *type* level. At runtime the returned object does carry `fileType`, `createdUserIdentity`, `modifiedUserIdentity`, `createdAt`, and `updatedAt` (TypeORM writes them back onto the spread plain object), and `fileAttachment.trackType.value` / `attachedToId` are present too; only `proceedingValue` is genuinely absent. The objection is that it needs casts and depends on write-back behaviour of a spread plain object, and it still leaves eligibility to be re-derived — alternative 1's problem. |
| **3. Add an `existsById` guard in the writer** | Ineffective against the vector this change actually creates. `findDeletedFileByPath` is `.withDeleted()` with no `deletedAt` filter — an upsert-by-`(bucket, filePath)` despite its name — so an upload **retry** UPDATEs the `files` row, moving `updated_at` and therefore producing a **different** deterministic id. A same-id guard cannot catch a different-id duplicate. It would also make the writer *look* guarded while the submit path, which shares it, remains unguarded. |
| **4. Table-driven outbox projector runner** watermarked on `files.updated_at` | **Genuinely the better architecture**, and the infrastructure already exists unused for this event (`OutboxProjectorEngine`, `OutboxProjectorRunnerPort`, `ProjectorCheckpointRepository`, advisory-lock poller precedents). It would cover submit *and* post-submit *and* late track-type changes in one path, be idempotent for free (the engine guards with `existsById`), self-heal missed writes, allow backfill, and let the submit call site be **deleted** rather than duplicated. Rejected for *this* ticket: changing `runnerName` changes every deterministic id, so already-shipped files re-emit unless the checkpoint is seeded past them (double-transcoding history); and it needs a poller, lock key, config accessor, env plumbing, and an index migration — several times this ticket's surface. It also converts a synchronous user action into an up-to-poll-interval delay, a product decision. **Filed as the follow-up that retires both call sites**; named in the spec so the second call site reads as deliberate interim duplication rather than the target architecture. |
| **5. Re-query and re-emit all eligible videos on the form at upload time** | Duplicate Nova work for files submit already requested. Single-file emit is the correct command-driven semantics for "this upload." Larry's design decision 1, independently confirmed — and now evidence-backed, since re-submit is blocked so there is no compensating dedupe elsewhere. |
| **6. Emit from the pending path too, for symmetry** | Would double-emit: submit re-reads all form files and would request the same file again. Correctly out of scope. |
| **7. Trust a client-supplied preset** | The front end sends none, and `perFileContextOverrides` is never populated on any AJSF component, so there is nothing to trust — but stated explicitly because it is the assumption that would make "Frontend: N/A" false. Server-side load from the stored form is the only correct source. |

## 7. Solution & stress-test

- **Proposed solution:** after `createProceedingFile` in `uploadCompleteForCompletedJobSubmission`, call a new `@Transactional`-proxied `WriteCompletedJobSubmissionVideoTranscodeOutboxTS`. It injects the two repositories, the existing `IsVideoTranscodeSelectionEligibleForOutbox`, and the outbox writer **port token** (never the concrete writer — `domain-no-infrastructure` forbids it, which is why the token exists). It: returns early when the flag boolean is false → loads the form's preset + `jobId` + `jobDate` → applies the preset gate → runs a **new single-file variant of the existing outbox query** (same root, same joins, same three eligibility predicates, plus `f.id = :fileId` and `jsffa.jobSubmissionFormId` retained) → returns early when that yields nothing → calls the existing `writeRequestedEvents` with a one-element `files` array. The **service** resolves `IS_VIDEO_TRANSCODE_ENABLED` via the feature-flag aggregator and passes the boolean in, mirroring `JobSubmissionService.submitJob`. Two new specs: the first ever for the completed-upload service, and one for the new TS. Exact class/file/registration shape is Phase 3's spec.
- **Solves the confirmed class?** Yes, and it is the reason the shape was chosen. Because eligibility stays in one query, a *third* emission surface later needs only a `where` clause, not a re-derivation. It fixes the instance and hardens the class against recurrence. What it does **not** solve is the class of "an emission surface can be added without anyone noticing the rule exists" — that is alternative 4's job, filed as follow-up.
- **Scale:** one extra indexed single-row `SELECT` plus one `INSERT` per completed upload. Negligible against what the path already does (S3 HEAD + CompleteMultipartUpload, a restriction-level fetch, and a `findByIdWithJobSingle` inside the SQS assembler). One caveat found and worth acting on: `JobSubmissionFormRepository.findById` is the *only* method loading the `videoTranscode` relation, and it eager-loads **thirteen ManyToOne joins plus a OneToMany** whose row count multiplies by the form's `jsffa` count — so the 20th upload in a session pays ~20× the row cost of the first. Submit pays that once per submit; this path would pay it once per upload. A lean projection method is justified, not premature (OV-3-adjacent; Phase 3 to spec).
- **Generalization:** deliberately minimal. One new query variant, one new TS, no new event type, no new port, no schema change, no migration. The tempting abstraction — a shared "emit transcode request for these files" service used by both paths — is **overreach for two call sites** and would fight the architecture rules (service→service forbidden). The genuinely correct generalization is alternative 4, and it is correctly deferred rather than half-built here.
- **Fit:** follows the established idioms — repository query returning a projection, TS injecting repositories + a port token, flag resolved one layer up and passed as a boolean, provider built with `createTransactionalProxy` beside the submit TS's provider. **Two fit corrections the coworker spec needs** (§6 alternative 1): no TS→TS call, and eligibility not re-expressed. **One honest caveat:** `@Transactional()` is a metadata marker only, and the proxy wraps any method named `apply` regardless — and since the completed path is *not* transactional today (`UploadCompleteProceedingFileTransactionScript` is registered un-proxied), a transaction opened by the new TS spans two SELECTs and one INSERT and makes **nothing meaningful atomic** — least of all the file row and the outbox row, which is the one guarantee the outbox pattern exists to give. Either keep the proxy for symmetry and stop claiming atomicity, or actually earn it by wrapping the create+outbox span. That is OV-3, and it must be decided deliberately rather than inherited.
- **Adjacent issues:** ten surfaced and recorded in [future-development concerns](../PRDV-16402-future-development-concerns.md). One deserves a ride-along judgement: `FileDerivationRepository.findBySourceAndProcess` is *exactly* the missing consumer-side idempotency guard and is **dead code** — wiring it into the persist mapper (or adding a unique index) is cheap and directly reduces the duplicate-derivative exposure this ticket widens. Tradeoff: it touches the proceedings module and the completed-event path, i.e. outside this ticket's blast radius, and would need its own tests. **Recommend follow-up, not ride-along** — but state it in the spec so the exposure is a known accepted risk rather than an oversight. The unguarded `PATCH /job-submission-form` (concern 1) is a separate ticket and arguably a security ticket; it must not be quietly absorbed here.
- **Sufficiency:** it covers the pain that convened this — post-submit uploads get requested with the right preset — for the **eligible** population. It does **not** cover: files whose MIME never resolves to `video/*` (an `application/octet-stream` fallback affects both paths equally), video files a user puts on a non-video track, historical uploads (no backfill), or the "matching" half of the AC. Those are named in §3 non-goals and §10 rather than left implied.
- **Feedback speed:** **slow, and this is the main risk of the whole ticket.** The unit specs give instant feedback on emission. The end-to-end signal — "the video actually came back transcoded, in the right preset" — requires Nova, and Nova currently applies Standard to everything, so the *distinguishing* signal does not exist until PRDV-16398 ships. Worse, the failure mode is silent: no user-visible error, no badge, no polling, no `video-transcode-failed` consumer in Callisto at all. The mitigations available now are the red→green spec, the manual outbox-row assertion in §9, and OV-1's failure-semantics decision.
- **Happy-path story (30 seconds):** An LTR videographer finishes a job whose AJSF was submitted with "Video Mix," then realises a camera-B file was missed. She opens the job from My Jobs → Submitted, drops the file into the proceeding's upload zone, and sees it appear in the file list. Nothing else is asked of her — no re-submit, no preset re-selection, no call to the video team. Behind that, Callisto stores the file and writes one outbox row carrying "Video Mix"; Nova picks it up, encodes to that preset, and Callisto files the converted output as a derivative that shows up indented under the original. **Without whom:** without the video team chasing missing conversions, without an ops engineer replaying events by hand, and without her needing to know the transcode pipeline exists.

## 8. Assumptions ledger

- **A1 — The completed-upload path writes no video-transcode outbox row.**
  - **Status:** confirmed
  - **Confirm/revise by:** read `…complete-upload.service.ts:19-27, 75-102` in full; repo-wide grep for `JOB_SUBMISSION_VIDEO_TRANSCODE_OUTBOX_WRITER_TOKEN` never reaches the file. Sole emitter of the event type is `SubmitJobSubmissionFormTS:63-75`.
- **A2 — A submitted form cannot be re-submitted, so submit will not re-emit for a post-submit upload.**
  - **Status:** confirmed (with a named residual)
  - **Confirm/revise by:** `JobSubmissionFormStatusValidator:7-15` throws on `SUBMISSION_STATUSES.DONE`, called at `job-submission.service.ts:72-74` before the TS. Residual, not refutation: the validator runs **outside** the transaction (only `apply` is proxied), so two concurrent `POST /submit/:formId` calls can both pass; and that route carries no `@UseGuards`. Sequentially blocked, concurrently racy. Pre-existing, not introduced here.
- **A3 — `videoTranscodeId` is mutable after submit, and no submit-time snapshot exists.**
  - **Status:** confirmed — this is the "structure cannot answer it" evidence for OV-4
  - **Confirm/revise by:** `PATCH /proceeding-job-submission/job-submission-form` (`update-job-submission-form.action.ts:14`) has no `@UseGuards`, no `@VerifiedUserDecorator`, and takes the target id from the body; `UpdateJobSubmissionFormTS:13-22` performs a bare `repository.update` with **no** status read and no `JobSubmissionFormStatusValidator` call (that validator's only production call site is the submit service). Its DTO also accepts `submissionStatusId`. Atlas's pending route (`routes.ts:111-117`) has no `meta`/guard and `fetch-or-create` returns a DONE form unchanged, so the pending page renders and saves for a submitted form. `SubmitJobSubmissionFormTS:36-44` writes only `submissionStatusId`, `submittedUserId`, `submittedUserEmail`, `updatedAt` — **the preset is never snapshotted**. The missing seam: there is no column, table, or event on the form recording the selection as-of-submit.
- **A4 — The client supplies no preset, so it must be loaded server-side.**
  - **Status:** confirmed
  - **Confirm/revise by:** request body built at `useUploadComplete.ts:26-44` + context at `useFileUploadMapping.ts:32-38`; no transcode field anywhere, and `perFileContextOverrides` is never passed by any AJSF component. Backend DTO (`upload-complete-proceeding-job-submission-file.request.dto.ts:16-99`) declares no preset — and notably no `jobId`/`jobTaskId` either, so Atlas's copies of those are dropped by validation and are **not** available in the service.
- **A5 — Every non-file writer input is obtainable on the upload path.**
  - **Status:** confirmed
  - **Confirm/revise by:** `AuthUser` (`generic/auth/constants.ts:29-49`) is the identical type on both paths; `identity.userEmail` → `createdUserEmail`, `identity.userFirstName` → `createdUserName` (note: first name only, matching submit). `jobId` and `jobDate` are scalar columns on the form entity (`:54-55`, `:64-65`); `videoTranscode` is a nullable `@ManyToOne` (`:81-90`).
- **A6 — `findById` is the only method loading `videoTranscode`, and it is heavier than this path wants.**
  - **Status:** confirmed
  - **Confirm/revise by:** only one repository references the entity; its four read methods are `findByJobTaskId` (no relations), `findById` / `update` / `findAll` (all 14 of `JOB_SUBMISSION_FORM_RELATIONS`). No `relationLoadStrategy` is configured anywhere, so TypeORM's default `'join'` applies and the `jobSubmissionFormFileAttachments` OneToMany multiplies row count per `jsffa`.
- **A7 — A by-file-id variant of the outbox query is feasible with predicates preserved verbatim.**
  - **Status:** confirmed
  - **Confirm/revise by:** `job-submission-form-file-attachment.repository.ts:64-107` read in full — only `jsffa.jobSubmissionFormId` is form-scoped; the row multiplier is the `fa.files` OneToMany, collapsed by `f.id = :fileId`. Retaining `jsffa.jobSubmissionFormId` as a second predicate is **not** merely defensive: both `jobSubmissionFormId` and `proceedingId` come from the request body, so it is the only thing guaranteeing the preset read off the form belongs to the file emitted for. Timing constraint: the `jsffa` row is written by `JobSubmissionFormFileAttachmentAssembler` inside `createProceedingFile`, guarded by `if (file.fileAttachment.id)` — so the query must run after that, and a falsy id yields no row.
- **A8 — Outbox writes are not idempotent; a duplicate id resurrects a published row.**
  - **Status:** **confirmed directionally** — owes an integration test
  - **Confirm/revise by:** `outbox-event.repository.js` `create()` builds the entity with an explicit PK plus `status: PENDING, attempts: 0` then calls `repo.save()`; TypeORM's `SubjectDatabaseEntityLoader` loads the existing row so `mustBeInserted` is false and it UPDATEs. Migration `1772165619858` shows PK-only, no unique constraint; no `orIgnore`/`orUpdate`/`ON CONFLICT` anywhere. Read from library source and TypeORM internals, **not observed** — so the precise column set overwritten (and whether `published_at` is really left stale) is unproven. → coverage-ledger frontier.
- **A9 — The completed path is not transactional, and `@Transactional` is a marker only.**
  - **Status:** confirmed
  - **Confirm/revise by:** `UploadCompleteProceedingFileTransactionScript` is spread un-proxied via `proceedings/registries/transaction-script.registry.ts:20`, unlike siblings built by `createTransactionalProxy`. `transactional.decorator.ts:5-6` is `SetMetadata`; `transactional-proxy.factory.ts:34` wraps on `Boolean(isTransactional) || prop === 'apply'`. Outbox inserts *do* enlist in an ambient ALS transaction when one exists (`outbox-transaction-context.module.ts:12-21` → `activeRepoForCreate()`), so wrapping is *possible* — it is simply not happening today.
- **A10 — Module wiring is a single file, and every collaborator is already provided.**
  - **Status:** confirmed
  - **Confirm/revise by:** `proceeding-job-submission.module.ts` — eligibility gate `:236`, writer token `:224-227`, converter `:223`, both repositories `:181`/`:219`, `OutboxProjectorModule` `:112`, `FeatureFlagModule` `:143`; transactional-TS provider precedent `:222`. This module has **no** `transaction-script.registry.ts` (only `actions.registry.ts`), so registration is direct in the module — contrary to what the coworker spec's "registries" line implies.
- **A11 — Nothing tests either upload path's emission behaviour.**
  - **Status:** confirmed
  - **Confirm/revise by:** the service's `__specs__/` contains only `job-submission-form-file-attachment.assembler.spec.ts`; no spec for either upload method, no action-level spec, no e2e for the route. All three `writeRequestedEvents` `.not.toHaveBeenCalled()` assertions live in the submit-TS spec and concern ineligible preset / empty rows / flag-off.
- **A12 — Transcoded outputs already appear on the submitted AJSF view; this ticket adds no new UI shape.**
  - **Status:** confirmed
  - **Confirm/revise by:** the persist mapper copies the source attachment's `attachedToId`, `attachedToType`, and `trackTypeId` and tags the derivative `Submission File` (`persist-video-transcode-derivative.mapper.ts:57-105`), which satisfies every predicate of the list query (`file-attachment.repository.ts:37-91`); pairing is projected at read time via `pair-original-and-processed.converter.ts:29-54`, and the response DTO documents the FE's indent-under-original behaviour. Pre-submit uploads already exercise this end-to-end today. Two deltas that are *not* new shapes: the derivative gets no `job_submission_form_file_attachments` row (same as today), and its filename is `<source stem>.mp4`, which collides with the source when the source is already `.mp4` (concern 6).
- **A13 — Architecture rules permit the proposed injections and forbid the coworker spec's flow.**
  - **Status:** confirmed
  - **Confirm/revise by:** `transaction-scripts.rules.ts:14-45` — TS→TS forbidden with **no** `to`-side exemption; TS→service forbidden; TS→aggregator forbidden except `*.port` files. Repositories are exempted for domain by `layer-dependencies.rules.ts` (`domain-no-infrastructure` `pathNot` includes `.*repository.*`), and `writers/` is **not** exempt — hence the port token. Enforced by `src/__tests__/architecture.spec.ts` via `npm run test:architecture`, aggregated into `test:conventions`, wired as `pretest`. Note: that spec's own docstring claims Husky enforcement and is stale — neither hook runs it (concern 8).
- **A14 — The front end needs no change, and the surface list is complete.**
  - **Status:** confirmed
  - **Confirm/revise by:** two upload surfaces on the submitted AJSF page, both routing to the completed endpoint (`SubmittedFileUploadSection.vue:66-69`); completeness established by closing the import graph — `uploadHandler` has exactly one `provide` and one `inject`, `createUploadContext` exactly one caller, and each component in the chain exactly one importer. No drag-drop, FAB, bulk, or per-row re-upload exists there. Front-end neighbours sensitive to this change: the per-file `onSuccess` refetch cascade and the red "file failed to upload" toast on a non-2xx — both relevant to OV-1.
- **A15 — The eligibility rule has five conditions, not the four the ticket and spec state.**
  - **Status:** confirmed
  - **Confirm/revise by:** SQL predicates `fa.attachedToType = 'Proceeding'`, `tt.value = 'Video'`, `LOWER(f.fileType) LIKE 'video/%'` (`:80-88`) + preset gate (`is-video-transcode-selection-eligible-for-outbox.ts:9-17`) + the feature flag. The coworker spec's eligibility list omits `attachedToType`.
- **A16 — Of the projection's 14 selected fields, only 12 reach the event.**
  - **Status:** confirmed
  - **Confirm/revise by:** `job-submission-file-to-video-transcode-requested-descriptor.converter.ts:60-81` never reads `proceedingValue` or `fileType`. `fileType` earns its place as a predicate; `proceedingValue` and its `leftJoin('proceedings', …)` are dead weight on this query (its only consumer uses the *other* projection). → OV-5.

## 9. Validation plan

**Happy path**
1. Video-role AJSF, form submitted, `videoTranscode` = **Video Mix**, `IS_VIDEO_TRANSCODE_ENABLED` on for the user (Cognito `custom:feature-flags`).
2. Open My Jobs → Submitted → the job; drop an `.mp4` into the proceeding's main upload zone (role `Video` maps to track 3).
3. Assert HTTP 2xx, the file appears in the list, and the legacy SQS dispatch still fired.
4. Assert **exactly one** new `outbox_events` row: `event_type = 'callisto.proceeding.file.video-transcode-requested.v1'`, `aggregate_type = 'ProceedingFile'`, `aggregate_id = <new fileId>`, `status = 'pending'`, and payload `videoTranscodeValue = 'Video Mix'` (**not** Standard — the bug the companion ticket exists for).
5. Assert the id equals `uuidv5('job-submission-video-transcode-command|ProceedingFile|<fileId>|<files.updated_at ms>|<eventType>')` — i.e. produced by the same helper, not a parallel scheme.
6. *(Gated on PRDV-16398 — AC8.)* End to end: Nova encodes to Video Mix and the derivative appears indented under the original.

**Negative paths**
- **Red→green (the regression test the detection gap designs):** a spec asserting the writer **is** called for an eligible completed upload. It must fail on `47f5a841` (no writer is even injected) and pass after. Plus its twin: `uploadCompleteForPendingJobSubmission` must **not** call it — an assertion that exists nowhere today.
- **Eligibility matrix, all writing the file and emitting nothing:** preset ∈ {Site Survey, Day in the Life, Other, `''`, null} × MIME `video/mp4`; preset Standard × MIME `application/pdf`; preset Standard × MIME `video/mp4` × track ∈ {Exhibit 1, Audio 5, MVC 4}; preset Standard × `attachedToType ≠ Proceeding`; flag **off** with everything else eligible.
- **Must fail visibly, not corrupt silently:** the OV-1 decision made observable — either a non-2xx that Atlas surfaces, or a warn-level log with `fileId` + `jobSubmissionFormId`. What must **never** happen is a 2xx with no outbox row and no log line, because there is **no backfill runner for this event type** (the command-driven writer is its sole producer), so a swallowed failure is unrecoverable without manual DB surgery.
- **Ambiguity in the null path:** the by-file-id query returns nothing for *both* "not a video" (expected) and "no `jsffa` row because `file.fileAttachment.id` was falsy" (a bug). The query cannot distinguish them. Log the second case rather than returning mutely.
- **Neighbours proven unchanged, against concrete surfaces:** submit's emission (its existing 7 specs still green, byte-identical assertions); the legacy SQS dispatcher (call args + call order asserted); the pending path (no emission); the writer / converter / deterministic-id helper / port token (not modified at all).
- **Call order pinned** (`mock.invocationCallOrder` or a shared call log) — OV-2's decision will otherwise drift silently.
- **Timing / latency:** the completion request is abort-wrapped by `withUploadTimeout` on the client, so a slow synchronous emit surfaces as "file failed to upload." Assert the added work is one indexed SELECT + one INSERT, and prefer the lean form query over `findById` (A6) so per-upload cost does not grow with the form's file count.
- **Duplicate-emission vector, characterised rather than fixed:** retrying the same upload UPDATEs the `files` row (moving `updated_at` → a **different** event id), mints a fresh attachment + `jsffa` row, and re-dispatches SQS → two transcode requests for one logical file. Accepted and recorded (concerns 3, 4) unless OV-3 chooses the transaction-wrapping option, which removes the orphan rows.
- **Frontier item to prove separately (A8):** an integration test showing what a duplicate deterministic id actually does to a published `outbox_events` row.

## 10. Decisions, recommendation & open variables

- **Decisions (settled):**
  1. **Disposition: proceed with conditions.** 16402's half is independently shippable and testable; AC8 is a named gate, not a blocker on the work. *(User, 2026-07-29.)*
  2. **Phase 3 writes our own spec**, citing Larry Adams' as a read-only input and naming each divergence with its code evidence. *(User, 2026-07-29.)*
  3. **Mirror submit's eligibility by reusing its query**, not by re-expressing its predicates — the fix shape follows from the confirmed class.
  4. **Emit for the newly uploaded file only** — Larry's design decision 1, confirmed by A2.
  5. **Load the preset server-side from the stored form** — A4 leaves no alternative.
  6. **No new event type, port, schema change, or migration**; the writer, converter, id helper, and token are untouched.
- **Recommendation (in order):**
  1. Lock OV-1…OV-6 in Phase 3 (grill-me, under the Q-and-A traceability workflow).
  2. Write the spec: the by-file-id query (+ a lean form-context query per A6), the new TS, the service change, module registration, and the widened `jobDate` port type.
  3. Write the red→green spec **first** and watch it fail on `47f5a841`.
  4. Implement; run `npm audit --audit-level=high` → `npm run lint` → `npm test -- --runInBand` (which triggers `pretest` → `test:conventions` → `test:architecture`, the gate that would have caught the coworker spec's flow).
  5. Verify manually per §9 happy path steps 1–5, asserting the outbox row directly.
  6. Open the PR with the testing-implementation doc's assembled block; state the AC8 gate explicitly so QA is not handed an unverifiable criterion.
- **Sequencing & gates:**
  - **AC1–AC7 proceed now.** They are provable against Callisto alone.
  - **AC8 is gated on PRDV-16398 merging** — do not accept "transcoded matching the selected preset" as verified on this ticket. 16398 is itself blocked on the HandBrake Video Mix preset from ops.
  - **Implementation is gated on OV-1, OV-2, and OV-3** — failure semantics, side-effect ordering, and transaction scope each change the code, and OV-3 changes the blast radius.
  - **The projector rearchitecture (§6 alternative 4) is gated behind a checkpoint-seeding strategy** — it must not re-emit history.

### Open variables to collect

- [ ] **OV-1 — Emit failure semantics: propagate or catch-and-log?** Propagate → 500, Atlas's red "file failed to upload" toast, refetch cascade skipped, though the bytes are in S3 and the file row exists. Catch-and-log → clean 2xx, file present, silently never transcoded. *Structure-can't-answer evidence:* there is **no backfill runner** for this event type — the command-driven writer is its only producer — so nothing downstream recovers a swallowed failure. *Recommendation:* **propagate**, matching `ProceedingFileUploadDispatcher`, which logs and re-throws. — owner: **Dustin / Product**
- [ ] **OV-2 — Side-effect ordering: where does the emit sit relative to audit and SQS?** *Recommendation:* create → **outbox** → audit → SQS. Ordering it last means a propagated failure has already sent the notification email, and a retry sends a second one; ordering it second means a failure costs orphan attachment rows only. The counter-argument (audit completeness outranks notification duplication) is legitimate and is the team's to make. — owner: **Dustin**
- [ ] **OV-3 — Transaction scope: symmetry-only proxy, or actually wrap create + outbox so they commit together?** Wrapping earns real atomicity (outbox inserts enlist in the ambient ALS transaction) and removes the retry orphan rows; its cost is making `UploadCompleteProceedingFileTransactionScript` transactional — blast radius contained, since `ProceedingAggregator.createProceedingFile` has exactly one consumer. Symmetry-only is defensible but must not *claim* atomicity (A9). — owner: **Dustin**
- [ ] **OV-4 — Preset semantics: current stored value, or a submit-time snapshot?** *Structure-can't-answer evidence:* A3 — nothing records the selection as-of-submit, and the value is mutable through an unguarded endpoint, so the system cannot distinguish "initial" from "current." *Recommendation:* use the current stored value; a snapshot is a schema change and out of scope; record the mutability as a concern. — owner: **Product**
- [ ] **OV-5 — `proceedingValue` is selected but never read (A16): drop it from the projection and query, or knowingly copy the dead join?** Dropping touches the submit path and three specs. *Recommendation:* knowingly copy for this ticket; file the removal as cleanup. — owner: **Dustin**
- [ ] **OV-6 — Ship 16402 before 16398 merges?** *Recommendation:* yes — emission is independently valuable and testable, and shipping it first means 16398 lands into a pipeline already receiving post-submit requests. Gate only AC8. — owner: **Product**

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Lock OV-1…OV-6 | Dustin (+ Product on OV-4/OV-6) | `specs/PRDV-16402-locked-decisions.md` has an `LD-###` row per OV, each citing its source; no OV left open |
| Write `specs/PRDV-16402-spec.md` | Dustin | All `spec-writing` sections present (N/A lines where inapplicable) **and** a divergences-from-Larry's-spec section naming all three with `file:line` evidence |
| Refine the test plan | Dustin | `testing/PRDV-16402-test-plan.md` status `refined`; every resolved OV appears as a concrete assertion |
| Red→green regression spec | Dustin | A named test fails on `47f5a841` and passes after the change; the pending-path pin exists |
| Implement per spec | Dustin | New query + TS + service change + registration on branch `PRDV-16402`; `test:architecture` green |
| Gates | Dustin | Reported as a table: exact command + scope + result for audit, lint, tests — post-change state only |
| Manual verification | Dustin | §9 happy path steps 1–5 observed, including the asserted `outbox_events` row with `videoTranscodeValue = 'Video Mix'` |
| Raise the AC split with Product | Dustin | AC8 recorded on the ticket/PR as gated on PRDV-16398, acknowledged by Product |
| Prove A8 (duplicate-id behaviour) | Dustin | An integration test shows observed status/attempts/`published_at` after a duplicate `writeOutboxEvent`; frontier item closed or revised |
| File the projector follow-up | Dustin | A ticket exists referencing §6 alternative 4 and the checkpoint-seeding constraint |

### Checklist
#### Investigation
- [x] This report (Sections 0–10)
- [x] Coverage ledger, diagrams, test-plan seed, concerns

#### Project Spec
- [ ] Lock open variables via grill-me → locked-decision ledger
- [ ] Create project spec (own spec; Larry's cited as input)

#### Development
- [ ] Create branch `PRDV-16402` in `callisto-back-end`
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
- [ ] (Bug/missed requirement) Document root cause + why it slipped through — §5 detection gap

---

## 12. Definition of done (investigation gate)

- [x] **Class derived from instances, re-confirmed against root cause; "reframed?" answered — yes, new capability → coverage gap (§1, re-check §5)**
- [x] Problem Check pass recorded (§2) with trimmed-quote evidence per flag; "nothing here" used honestly on **Off**
- [x] Problem in one plain sentence (§2)
- [x] Named blocked instance — **explicitly recorded as absent**, with why that does not weaken the defect (§2)
- [x] Date it bites next — no date; ongoing silent loss, stated as such (§2)
- [x] Wedge + why it's reusable within the confirmed class (§2)
- [x] Acceptance criteria + non-goals locked before the solution was proposed (§3 precedes §7)
- [x] Alternatives recorded with rejection reasons (§6 — seven)
- [x] 30-second happy-path story (§7)
- [x] Metric that proves it works + how fast it arrives (§7 Feedback speed; §9 step 4) — and the slow-feedback risk flagged
- [x] Verdict + disposition stated (§0, Metadata)
- [x] Every open question reconciled (Step 7): A1–A16 resolved by evidence in §8; only genuine decisions in §10, each with an owner; OV-1 and OV-4 carry the structure-can't-answer evidence
- [x] Tracked action with a falsifiable done-when (§11)

---

## §13. Post-Investigation Addendum — the implementation already exists (2026-07-29)

**Sections 0–12 above are left exactly as written. They were correct given what was in view at the time, and the reasoning trail is worth preserving. This addendum records what changed and what it means.**

### What was found

After Dustin met with Larry Adams — the principal lead who authored the ticket and the spec, and who said the work "should be basically done" — a search for his branch found it. **The change is fully implemented.**

| Fact | Value |
| --- | --- |
| Branch | `origin/PRDV-16402` in `callisto-back-end` |
| Commit | `d97b1c4e78f5f145933ca4313a6b7a25fe2905f5`, Larry Adams, 2026-07-28 15:00:55 -0400 |
| Size | 622 insertions across 7 files — **506 of them specs** |
| Merged | to `main` via **PR #397** |
| Reverted | **7 minutes later**, `f6ae2bf5`, via **PR #398** |
| Revert reason (verbatim, PR #398 body) | *"I should not have merged before. I was moving too fast. I thought it was a different PR. Sorry"* |
| Technical objection | **none** — no human review comment on either PR; CI clean (ESLint, Prettier, type-check all pass) |
| Re-applies onto current `main`? | **Yes, no conflict** (`git merge-tree` clean) |

**Baseline correction:** §Metadata keys this report to `callisto-back-end` `main` `47f5a841`. `origin/main` is now **four commits ahead** of that, and all four are this sequence: `d97b1c4e` (implement) → `331c1202` (merge #397) → `f6ae2bf5` (revert) → `67c1b973` (merge #398). Net production code on `main` is unchanged from `47f5a841`, so every finding in §5 and §8 still holds — but the report's implicit premise that *nothing had been built* was wrong.

### Correction to §6 alternative 1 and §4

§6 rejected "re-express track/MIME as TypeScript predicates in the new TS" as *the coworker spec's shape*, and §4 recorded three divergences. **That was a review of the spec's prose and flow diagram. His code does not have that shape.** What the code actually does:

- Extracts a shared private `buildVideoTranscodeOutboxQuery(jobSubmissionFormId)` and adds `findVideoFileForVideoTranscodeOutboxByFileId(jobSubmissionFormId, fileId)` on top of it, so the single-file lookup **inherits all three eligibility predicates** rather than restating them — precisely the wedge §2 identified, and it keeps `jobSubmissionFormId` as the second predicate (§8 A7's cross-form guard).
- Injects `JobSubmissionFormRepository` **directly**, not `FetchJobSubmissionFormTS` — so there is no transaction-script-to-transaction-script dependency and `test:architecture` is not violated (§8 A13's concern does not apply to the code).
- Resolves `IS_VIDEO_TRANSCODE_ENABLED` in the **service** and passes the boolean into the TS, matching `JobSubmissionService.submitJob` (§7's recommendation).
- Reuses `IsVideoTranscodeSelectionEligibleForOutbox`, the writer port token, the converter, and the id helper unchanged; single-file emit; no new event type.

**So two of the three recorded divergences exist only in the spec document, not in the shipped-then-reverted code, and the third is moot as a consequence.** The verdict in §0 stands, but its "strongest path" is now *re-land Larry's branch with two changes*, not *build the fix*.

### Which open variables the code has already decided

| OV | Status after reading the code |
| --- | --- |
| **OV-1** failure semantics | **Decided by the code: propagate.** The TS call is `await`ed un-guarded, so a write failure surfaces as a 500. Matches this report's recommendation. |
| **OV-2** side-effect ordering | **Decided by the code: outbox last**, after audit *and* SQS — the opposite of this report's recommendation, and the basis of review finding F1. |
| **OV-3** transaction scope | **Decided by the code: no proxy at all** — the TS is registered as a plain provider, so no transaction is opened. Defensible given the path was never transactional; means the file row and outbox row are not atomic, which is why F1's ordering is the only lever available. |
| **OV-4** preset semantics | **Decided by the code: current stored value** (`findById` → `form.videoTranscode`). Matches the recommendation; the mutability risk stands as concern 2. |
| **OV-5** dead `proceedingValue` | **Decided by the code: knowingly copied** — the shared builder retains the `proceedings` join. Matches the recommendation. |
| **OV-6** ship before 16398 | Still Product's. Unaffected. |

Only OV-2 diverges from this report's recommendation, and OV-6 remains open.

### Review findings (the new deliverable)

Six findings, with plain-language scenarios — real situation, what happens today, what we'd expect, why the current implementation won't get us there — in [`../testing/PRDV-16402-testing-implementation.md`](../testing/PRDV-16402-testing-implementation.md), and as an actionable checklist in [`../PRDV-16402-pr-draft.md`](../PRDV-16402-pr-draft.md).

- **Change before re-landing:** **F1** move the outbox call ahead of audit + SQS (a failure currently costs a duplicate notification email, an orphaned attachment row, and a double conversion on retry). **F2** add a repository-level test for the new by-file-id lookup — because eligibility now lives in the shared query, the unit tests physically cannot verify it, so nothing proves the four conditions or the cross-job rejection survived.
- **Comments:** **F3** `findById` loads 14 relations per upload for three fields. **F4** ~6 unrelated blank-line deletions. **F5** `jobDate` string-vs-`Date` mislabel now at two call sites.
- **Not a code issue:** **F6** the ClickUp AC is unverifiable until PRDV-16398 ships — AC8 in §3, unchanged.

**F2 is a genuinely new finding, not a restatement.** §9 assumed the eligibility matrix (NP-3…NP-6, NP-11) was coverable by unit tests. Reading the implementation shows it is not: with a mocked repository, "ineligible" and "returned nothing" are indistinguishable. Larry's six TS tests are well-constructed and cover flag-off, missing form, ineligible preset, no-eligible-file, Standard, and Video Mix — but by construction none of them can reach the predicates. **That gap is created by the correct design decision**, and closing it needs a test at a different level. Test plan EC-9 and NP-3…NP-6 are re-scoped accordingly.

### What this does not change

§1 (problem class), §2 (problem statement and Problem Check), §3 (the contract, including AC7 and AC8), §5 (why it exists, and the detection gap — which the branch's 506 lines of specs now partly close), and all ten entries in the concerns record stand as written.

