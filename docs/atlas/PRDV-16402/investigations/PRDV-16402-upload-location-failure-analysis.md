# PRDV-16402 — Why the manual test produced no transcode: upload-location failure analysis

> **What this is:** a root-cause analysis of a specific manual test that produced no conversion, and a map of every post-submission upload surface.
> **What this is not:** a change to the investigation report, the spec, or the review verdict. §13 of the [investigation report](./PRDV-16402-investigation.md) and the [testing-implementation artifact](../testing/PRDV-16402-testing-implementation.md) stand as written.

## Metadata

| Field | Value |
| --- | --- |
| Date | 2026-07-30 |
| Owner | Dustin Thomason |
| Ticket | [PRDV-16402](https://app.clickup.com/t/43227262/PRDV-16402) |
| Trigger | Manual test on `atlas-dev` produced no conversion; two questions raised (other upload locations; why nothing was picked up) |
| Repos read | `callisto-back-end` (branch `PRDV-16402-reland`, `3ecab1b8`), `atlas-front-end` (`main`, `102e034d`) — read-only, no file touched |
| Verdict | **The implementation did not fail. The test exercised a different code path than the one the change modifies.** |

---

## 0. Bottom line

The URL you uploaded through — `…/callisto-stuff/job/5019/proceeding/897?tab=submission-files` — is the **Proceeding Detail page**, not the AJSF. Its Submission Files tab posts to `POST /proceedings/upload-complete`, in Callisto's `proceedings` module. The PRDV-16402 change adds the transcode-request emit to `POST /proceeding-job-submission/upload-complete-completed` only, in the `proceeding-job-submission` module. **Nothing on the path you used calls the new code**, so no outbox row was ever going to be written — with or without the fix, deployed or not.

Two things made this look like a code failure rather than a wrong door:

1. **Both paths produce an indistinguishable file row.** They converge on the same `UploadCompleteProceedingFileTransactionScript`, so the file lands with the same `attachedToType = 'Proceeding'`, the same track, and shows up in the same lists. The only difference is invisible in the UI: the AJSF path additionally writes a `job_submission_form_file_attachments` link row.
2. **That link row is exactly what the fix keys on.** The new lookup is rooted at `job_submission_form_file_attachments`, so a file created without that row is structurally outside what the fix can see — the surface you used is not merely unwired, it is not addressable by this design.

**The deployment hypothesis was tested and refuted.** `origin/main` does not contain the feature (it carries the revert), but dev does not run `main` — the last **successful** dev deploy of Callisto was Larry's `d97b1c4e` on 2026-07-28 19:19Z, which *is* the feature. Your `3ecab1b8` reland deploy on 2026-07-29 21:14Z **failed before registering a task definition** (`RegisterTaskDefinition … Container.image contains invalid characters` — the dispatched image tag carried a trailing space), so it did not change the running service. Dev has the feature; the test just did not reach it.

---

## 1. The instance (source truth)

Stated by you, 2026-07-30 — reproduced rather than paraphrased:

> I had gone to a previous job, uploaded a file. I went to the url
> https://atlas-dev.planetdepos.com/callisto-stuff/job/5019/proceeding/897?tab=submission-files
> […] When attempting to upload to this location, on the video track, with a job that was already processed, I was under the impression that my changes would allow the file to be picked up, and processed as whatever else the job was already submitted at. However, no processing seems to have taken place.

Route resolution — `atlas-front-end/src/globalRouter/routes.ts:73-79`:

```
{ name: ROUTES.CALLISTO_PROCEEDING_DETAIL,
  path: 'job/:id/proceeding/:proceedingId',
  component: () => import('@callisto/pages/.../ProceedingDetailPage/ProceedingDetailPage.vue') }
```

`?tab=submission-files` selects that page's first tab (`ProceedingDetailPage.vue:94`, `:621`). This is the internal Callisto proceeding view. It is **not** the AJSF.

---

## 2. Item 1 — where files can be uploaded after submission

Five distinct `upload-complete` endpoints exist in Callisto, reached from six Atlas surfaces. Only one is touched by PRDV-16402.

| # | Atlas surface | Callisto endpoint | Module | Writes `jsffa` link? | Emits transcode request (post-fix)? |
| --- | --- | --- | --- | --- | --- |
| 1 | **Submitted AJSF** — `submitted-job-submission-form/:jobTaskId`, File Upload section (`SubmittedFileUploadSection.vue:66-69`) | `POST /proceeding-job-submission/upload-complete-completed` | `proceeding-job-submission` | **yes** | **YES — this is the only one** |
| 2 | Pending AJSF — `pending-job-submission-form/:jobTaskId` (`PendingFileUploadSection.vue:71`) | `POST /proceeding-job-submission/upload-complete` | `proceeding-job-submission` | yes | no — submit still owns batch emission (deliberate; report §3 non-goals) |
| 3 | **Proceeding Detail → Submission Files tab, drag-and-drop** (`ProceedingDetailPage.vue:226-229`) | `POST /proceedings/upload-complete` | `proceedings` | **no** | no |
| 4 | **Proceeding Detail → Submission Files table upload control** (`SubmissionFilesTable.vue:136-139`) | `POST /proceedings/upload-complete` | `proceedings` | **no** | no |
| 5 | Proceeding Detail → Client Deliverables tab (`ClientDeliverablesTable.vue`, `ProceedingDetailPage.vue:230-233`) | `POST /granting-client-access/upload-complete` | `granting-client-access` | no | no |
| 6 | Case Detail → Case Files (`CaseFilesTable.vue:125`) | `POST /cases/upload-complete` | `cases` | no | no |

**You used surface 3 or 4.** Both post to `UPLOAD_COMPLETE_SUBMISSION_URL` = `/proceedings/upload-complete` (`atlas-front-end/src/callisto/api/constants.ts:59`), landing on `UploadCompleteSubmissionFileAction` → `MultiPartUploadProceedingFileService.uploadComplete`.

**Answer to the question as asked:** yes — there is a different location, and it is the one the ticket is about. **Surface 1**, the submitted AJSF's own File Upload section, reached via **My Jobs → Submitted → the job** (`MyJobsTable.vue:60-67` pushes `submitted-job-submission-form/:jobTaskId`). Note it is keyed by **`jobTaskId`**, not by `jobId`/`proceedingId` — so there is no way to hand-edit the URL you were on into the right page; the job task id is a different identifier.

There are exactly **two** upload affordances on that page (drop zone and file picker inside `FileUploadSectionCore`), and both post to the same completed endpoint — consistent with report §8 A14.

### 2.1 Product confirmation (2026-07-31) — independent agreement, with one catch

Asked *"where does an LTR go in to upload a subsequent file, a video file that was missed previously — what is the url of that location?"*, the product manager overseeing the project answered:

> https://atlas.planetdepos.com/callisto-stuff/my-jobs?tab=submitted

**This confirms surface 1 and independently rules out the surface that was tested.** It is the entry point to the submitted AJSF, and the navigation chain from it is verified in code:

| Step | Code |
| --- | --- |
| `my-jobs?tab=submitted` renders the submitted list | `MyJobsPage.vue:28-42` reads `route.query.tab`; `:93-98` renders `MyJobsTable` with `taskType = SUBMITTED` |
| Rows are keyed by **`jobTaskId`** | `MyJobsTable.vue:37-40` (`id: t.jobTaskId`) |
| Row click → job-number confirmation dialog | `MyJobsTable.vue:92-95` (`handleRowClick` → `openConfirmDialog` → `ConfirmJobNumberDialog`) |
| Confirm → the submitted AJSF | `MyJobsTable.vue:60-67` pushes `CALLISTO_SUBMITTED_JOB_SUBMISSION_FORM` → `submitted-job-submission-form/:jobTaskId` (`routes.ts:118-124`) |
| Upload there posts to the changed endpoint | `SubmittedFileUploadSection.vue:66-69` → `/proceeding-job-submission/upload-complete-completed` |

**Two precisions worth keeping, because neither is a disagreement with Product:**

1. **The URL given is the entry point, not the upload page.** The upload happens one hop deeper, at `submitted-job-submission-form/<jobTaskId>`, behind a dialog that requires typing the job number. There is no upload control on `my-jobs` itself. So "the URL of that location" is the door; the room is one click in.
2. **That is a `prod` host, and prod does not have this feature.** The last prod deploy was `v2026.15.1` on 2026-07-27T21:07Z — **before Larry's commit `d97b1c4e` existed (2026-07-28)** — and `main` has carried the revert ever since. Testing at `atlas.planetdepos.com` would show no conversion no matter what page is used. The equivalent test URL is:

   **`https://atlas-dev.planetdepos.com/callisto-stuff/my-jobs?tab=submitted`**

**Net effect on this analysis: none of the findings change, and the diagnosis is now corroborated from outside the code.** Product's answer and the code agree on the same surface, and it is not the surface the failed test used.

---

## 3. Item 2 — why nothing was picked up

### Problem

A video dropped on the Proceeding Detail page's Submission Files tab, on the video track, for an already-submitted job, produced no conversion — and no error, badge, or log visible to the uploader.

### Requirement (for the observed behaviour to be a defect in this change)

The request would have to reach `uploadCompleteForCompletedJobSubmission`, and the created file would have to be resolvable by `findVideoFileForVideoTranscodeOutboxByFileId(jobSubmissionFormId, fileId)`.

### What actually happened — the chain, stated as facts

1. **The request never entered the module the fix lives in.** `/proceedings/upload-complete` → `UploadCompleteSubmissionFileAction.apply` (`upload-complete-submission-file.action.ts:21-35`) → `MultiPartUploadProceedingFileService.uploadComplete` (`multi-part-upload-proceeding-file.service.ts:76-120`). That method does three things after the S3 completion: create the file, dispatch the legacy SQS proceeding-file-upload event, dispatch the file-audit event. **It injects nothing transcode-related and calls no outbox writer.** The new `WriteCompletedJobSubmissionVideoTranscodeOutboxTS` is invoked from exactly one place — `multi-part-upload-proceeding-job-submission-file-complete-upload.service.ts:102-110`, inside `uploadCompleteForCompletedJobSubmission`.

2. **The file has no AJSF link row, so it is not addressable by the new lookup even in principle.** `job_submission_form_file_attachments` rows are written by exactly one collaborator, `JobSubmissionFormFileAttachmentAssembler`, called only from `createProceedingFile` inside the AJSF upload service. The `proceedings` path never touches it. The new query is rooted at that table (`job-submission-form-file-attachment.repository.ts`, `buildVideoTranscodeOutboxQuery` → `.andWhere('f.id = :fileId')`), so for a file created on surface 3/4 it returns `null` **and would keep returning `null` even if the emit call were pasted into that service verbatim.**

3. **The TS also needs a `jobSubmissionFormId` the request does not carry.** `WriteCompletedJobSubmissionVideoTranscodeOutboxParams` requires it; the proceedings DTO (`upload-complete-submission-file.request.dto.ts`) carries `jobId`, `proceedingId`, `trackTypeId`, `mimetype`, `fileSize`, `partsCount`, `key`, `uploadId`, `fileName`, `length` — and **no** form id. There is no `findByJobId` on `JobSubmissionFormRepository` either; its read methods are `findByJobTaskId`, `findById`, `findAll`.

4. **The eligibility gate and the preset were never consulted**, because step 1 short-circuits everything. Nothing was rejected — nothing was asked.

### Why it looked like the same place

Both paths call the **same transaction script** to create the file: the AJSF service reaches it via `ProceedingAggregator.createProceedingFile` (`proceeding.aggregator.ts:73-77`), and the proceedings service injects `UploadCompleteProceedingFileTransactionScript` directly. Same `findDeletedFileByPath` upsert, same `CreateProceedingFileMapper`, same `attachedToType: 'Proceeding'` (`create-proceeding-file.mapper.ts:19`), same `Submission File` tag, same track. Both also fire the same legacy SQS dispatch and the same audit event.

So the file appeared, in the right track, looking exactly like a file uploaded the other way — and the **only** difference between them is one link row you cannot see in the UI. This is a genuinely misleading surface, not a careless test.

### Verdict

**The implementation did not fail.** It was not reached. There is no defect in `3ecab1b8` evidenced by this test, and nothing in the review verdict changes.

---

## 4. Hypotheses tested

| Hypothesis | Status | Evidence |
| --- | --- | --- |
| Wrong upload surface — the path used is not the path changed | **CONFIRMED — sufficient cause on its own; independently corroborated by Product** | §2 table, §3 steps 1–3, §2.1 |
| Prod would have shown the feature | **REFUTED** — the URL Product supplied is a prod host, and prod predates the commit | Last prod deploy `v2026.15.1`, 2026-07-27T21:07Z (run 30305547769); `d97b1c4e` authored 2026-07-28; `main` has carried the revert since |
| The file is structurally invisible to the new lookup (no `jsffa` row) | **CONFIRMED — independent second cause** | §3 step 2; sole `jsffa` writer is the AJSF assembler |
| Feature not deployed to dev (`main` carries the revert) | **REFUTED** | Last successful dev deploy = `d97b1c4e` (2026-07-28 19:19Z, run 30391422693), which contains the feature. Dev does not track `main`. |
| Your reland deploy replaced dev with something else | **REFUTED** | Run 30491618092 (2026-07-29 21:14Z) failed at `RegisterTaskDefinition`: *"Container.image contains invalid characters"* — trailing space in the dispatched image tag. No task definition registered ⇒ service unchanged. |
| Feature flag `IS_VIDEO_TRANSCODE_ENABLED` off for your user | **NOT REACHED — untested, still a live gate for the re-test** | Resolved from Cognito token claims only, no env override (`is-feature-allowed.transaction.script.ts`). Must be present in `identity.featureFlags` or the TS returns at its first line. |
| Preset on the form ineligible (not Standard / Video Mix) | **NOT REACHED — untested, still a live gate** | `IsVideoTranscodeSelectionEligibleForOutbox` |

**Limit of the deployment evidence:** it covers GitHub Actions deploys only. An out-of-band ECS update from the AWS console would not appear in that history and was not checked.

---

## 5. How to re-test so the code is actually exercised

1. Start at **`https://atlas-dev.planetdepos.com/callisto-stuff/my-jobs?tab=submitted`** — the surface Product named, on the **dev** host rather than prod (§2.1). Click the job, confirm the job number in the dialog, and verify you land on `…/callisto-stuff/submitted-job-submission-form/<jobTaskId>`. Do not hand-edit the proceeding URL; the AJSF is keyed by `jobTaskId`, which is a different identifier.
2. Confirm the form's conversion selection is **Standard** or **Video Mix**. Anything else is a designed no-op.
3. Confirm your Cognito user carries `IS_VIDEO_TRANSCODE_ENABLED` in `custom:feature-flags` **on dev**.
4. Upload the `.mp4` through that page's **File Upload section** (drop zone or picker), on the **Video** track.
5. Confirm the browser posted to `/proceeding-job-submission/upload-complete-completed` — DevTools → Network. **This is the check that would have caught the wrong door in seconds, and it is the one to run first from now on.**
6. Assert the outbox row directly, per report §9 happy path step 4: one new `outbox_events` row, `event_type = 'callisto.proceeding.file.video-transcode-requested.v1'`, `aggregate_id = <new fileId>`, payload `videoTranscodeValue` = the form's selection.
7. Only then judge the end-to-end conversion.

Before step 1, **re-run the dev deploy of `3ecab1b8` with a clean image tag** (no trailing space) if you want the reland specifically under test rather than `d97b1c4e`. The two are the same change — `3ecab1b8` is a cherry-pick — so a successful re-test on `d97b1c4e` is still a valid test of the *behaviour*, just not of the exact artifact you intend to merge.

---

## 6. If Product wants the surface you used covered

**This is a scope question, not a bug.** The ticket says *"files uploaded to the submitted jobs tab of the AJSF"* — surface 1. Surfaces 3 and 4 are the internal proceeding view, a different user journey, and were never in scope. But you found them by behaving like a real user, and the ticket's Original Request also says *"all files I upload for a job"*, so the tension is worth naming rather than burying.

Covering them is **not** a small addition, and would need its own ticket:

- **No form id in the request.** `jobId` → job submission form is not a resolvable lookup today (no `findByJobId`), and it is not obviously 1:1 — a form is keyed per `jobTaskId`, and nothing in the schema constrains a job to a single task/form. Two roles on one job would mean two forms with two independent `videoTranscodeId` values and no rule for which one governs a file uploaded outside either form.
- **No `jsffa` link row**, so the shared eligibility query cannot be reused as-is. Either the proceedings path starts writing that link (changing what "attached to the form" means), or eligibility gets a second definition keyed off `file_attachments` — which is precisely the drift the current design was chosen to avoid (report §6 alternative 1).
- **Blast radius crosses modules** — `proceedings` would take a dependency on `proceeding-job-submission`, against the direction the existing wiring runs.

This is the case that the **table-driven outbox projector runner** (report §6 alternative 4) answers cleanly: watermarked on `files.updated_at`, it covers every write path at once, including ones not yet built, and would retire the per-call-site emit entirely. If Product wants surfaces 3/4 covered, that follow-up is the vehicle — not a third emit call site.

**Recommended disposition:** re-land PRDV-16402 as scoped (surface 1), and raise surfaces 3/4 with Product as a separate question, with this document as the evidence.

---

## 7. What this changes in the ticket record

| Artifact | Change |
| --- | --- |
| Investigation report §13 | **No change.** The review verdict — nothing requires changing, re-land as-is — is unaffected. |
| Report §8 A14 ("the front-end surface list is complete") | **Still correct as scoped**, and worth reading precisely: it closed the import graph for *the submitted AJSF page*. It never claimed to enumerate every upload surface that can put a file in a proceeding. This document supplies that wider map. |
| Report §3 non-goals | **Add** surfaces 3–6 explicitly as out of scope, so the boundary is stated rather than implied. |
| Test plan | **Add a precondition to every manual scenario:** confirm the request went to `/proceeding-job-submission/upload-complete-completed` before judging the outcome. |
| Future-development concerns | **Add:** two visually equivalent upload surfaces write files that differ only by an invisible link row, and only one requests conversion — a UX trap for videographers, independent of this change. |
| PR draft | **Add one line** to the scope statement naming the covered surface by endpoint, so a reviewer testing it does not repeat this. |
