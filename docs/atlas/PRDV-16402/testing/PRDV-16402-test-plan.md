# Test plan — atlas/PRDV-16402

> Seeded from [PRDV-16402-investigation.md](../investigations/PRDV-16402-investigation.md) §9 on 2026-07-29. Refined by spec: _pending (Phase 3)_.

Status: **in-execution** — unit gate done (29 tests, 5 suites, serial). Sandbox verification below is the outstanding Phase 5 evidence.

---

# SANDBOX VERIFICATION (plain language)

## Confirm these two things first — everything below is meaningless without them

1. **Is the feature flag on for your sandbox user?** `IS_VIDEO_TRANSCODE_ENABLED` is a per-user Cognito flag (`custom:feature-flags`), not a global switch. If it's off for you, *nothing* will convert and every scenario below will look like a failure. **Not verified by me — check before you start.**
2. **Does sandbox Nova have the PRDV-16398 build?** The preset code merged to Nova `main` (`4128419`), but whether sandbox is running that build is a deploy question I have not checked. If sandbox Nova is older, every file comes back **Standard** regardless of what you pick — and Scenario 2 will fail for a reason that has nothing to do with this ticket.

## What to watch, in order of usefulness

- **The AJSF file list** on the submitted job. A converted file appears as a second row paired under the original ("Show Original" indent). This is the end-user proof.
- **Nova's logs.** Every job logs `Transcoding media` with an `appliedPreset` field. This is the *only* place that tells you which preset was actually used. If a value it doesn't recognise arrives, it logs a `warn` with `requestedValue` and `appliedPreset` — seeing that warn means something upstream sent a bad value.
- **The `outbox_events` table** (if you have DB access). One row per requested conversion, `aggregate_id` = the file's id, and the payload carries `videoTranscodeValue`. This distinguishes "Callisto never asked" from "Nova ignored the ask" — worth it if a scenario fails.

---

## The scenarios

### S1 — The whole point of the ticket
**Setup:** a job with the **Video** role. Fill out the AJSF, set the conversion type to **Video Mix**, submit it.
**Do:** reopen the job from My Jobs → Submitted. Upload an `.mp4` into the main "Upload proceeding files" zone.
**Expect:** the file uploads normally, and shortly after, a converted copy appears in that proceeding's file list, paired under the original.
**Proves:** the gap is closed — a video uploaded *after* submission now gets converted. Before this change it would upload and silently never convert. **If only this one scenario passes, the ticket works.**

### S2 — It uses the preset from the job, not a hardcoded one
**Setup:** two jobs, both Video role. One set to **Video Mix**, one set to **Standard**. Submit both.
**Do:** upload a video to each, after submission.
**Expect:** Nova's log shows `appliedPreset: Video Mix` for the first and `appliedPreset: Standard` for the second.
**Proves:** the preset is actually read off each job's form. This is the one scenario that catches the most likely silent bug — everything converting as Standard and looking fine. **Do not skip this one; S1 passing tells you nothing about which preset was used.**

### S3 — Nothing broke for files uploaded *before* submitting
**Setup:** a Video-role job set to Video Mix. Upload a video **while the form is still pending**. Then submit.
**Do:** watch what happens on submit.
**Expect:** exactly as it worked before — that file converts once. **Not twice.**
**Proves:** the existing behaviour is untouched and we didn't create double conversions. This is the regression check.

### S4 — Jobs that shouldn't convert, don't
**Setup:** a Video-role job with conversion set to **Site Survey** (or **None**). Submit it.
**Do:** upload a video after submission.
**Expect:** the file uploads and appears in the list. **No converted copy ever appears.** No error.
**Proves:** we only convert what's meant to be converted. Only Standard and Video Mix qualify.

### S5 — Non-video files are left alone
**Setup:** a Video-role job set to Video Mix, submitted.
**Do:** upload a PDF (or a Word doc) after submission.
**Expect:** it uploads and appears normally. No conversion, no error, no failure toast.
**Proves:** the file-type filter works and non-video uploads aren't disturbed.

### S6 — Exhibit uploads don't convert
**Setup:** same Video-role job set to Video Mix, submitted.
**Do:** upload a video through the **"Upload exhibit files"** zone instead of the main one.
**Expect:** it uploads and appears. **No conversion.**
**Proves:** conversion is scoped to the Video track. Exhibit uploads always land on the Exhibit track, so they're correctly excluded — worth confirming because it's an easy real-world mistake for a user to make, and it should behave gracefully rather than half-converting.

### S7 — Turning the flag off turns the feature off cleanly
**Setup:** remove `IS_VIDEO_TRANSCODE_ENABLED` from your sandbox user.
**Do:** upload a video to a submitted Video Mix job.
**Expect:** the file uploads fine. No conversion. No error.
**Proves:** the feature is safely gated and the upload path still works without it. This is your rollback safety check.

### S8 — Several uploads in one sitting
**Setup:** a Video-role job set to Video Mix, submitted.
**Do:** upload three videos, one after another.
**Expect:** each gets its own converted copy — three in, three out. No duplicates, no missing ones.
**Proves:** it emits per file rather than re-processing the whole job each time.

---

## If something fails, this is how to tell whose fault it is

| What you see | Where the problem is |
| --- | --- |
| No converted file, and no row in `outbox_events` for that file | **Callisto** — the request was never made. That's this ticket. |
| Row exists in `outbox_events`, but no converted file appears | **Nova or the queue** — the ask was made and not fulfilled. Not this ticket. |
| Converted file appears but with the wrong settings; Nova log shows `appliedPreset: Standard` when you chose Video Mix | **Nova's build** — check sandbox has PRDV-16398. Not this ticket. |
| Nova logs a `warn` with `requestedValue` | Something sent a value Nova doesn't recognise. Callisto only ever sends `Standard` or `Video Mix`, so this would be unexpected and worth capturing. |
| Red "file failed to upload" but the file is actually there | The conversion request threw after the file saved. Capture the Callisto error log — this is the one known rough edge (the request is the last step and isn't isolated). |

## Minimum viable pass

If you only have time for three: **S1** (it works), **S2** (right preset), **S3** (nothing broke). Those three cover the ticket's acceptance criterion and the regression risk.

---

## Scope and surfaces under test

- **Behaviour being proven:** a video file created by `POST /proceeding-job-submission/upload-complete-completed` on a submitted AJSF produces exactly one `callisto.proceeding.file.video-transcode-requested.v1` outbox row carrying the form's stored `videoTranscode` selection — under exactly the same eligibility rule the submit path uses, and under no other circumstances.
- **Surfaces:** `MultiPartUploadProceedingJobSubmissionFileCompleteUploadService` (both methods), the new transaction script, the new by-file-id repository query, the `outbox_events` table, and — read-only, for the manual pass — the Atlas submitted-AJSF upload zones.
- **Frozen surfaces that must be shown unchanged:** `SubmitJobSubmissionFormTS`'s emission, `ProceedingFileUploadDispatcher` (legacy SQS), `uploadCompleteForPendingJobSubmission`, and the writer / descriptor converter / deterministic-id helper / port token.
- **Repo:** `callisto-back-end` (branch `PRDV-16402`, off `main` `47f5a841`). No Atlas change.

## Happy path

- [ ] **HP-1 (the core AC).** Submitted AJSF, `videoTranscode` = **Video Mix**, flag `IS_VIDEO_TRANSCODE_ENABLED` on, file MIME `video/mp4`, track `Video` (3), `attachedToType` `Proceeding` → upload via `upload-complete-completed` → **exactly one** new `outbox_events` row with `event_type = 'callisto.proceeding.file.video-transcode-requested.v1'`, `aggregate_type = 'ProceedingFile'`, `aggregate_id = <new fileId>`, `status = 'pending'`, and payload `videoTranscodeValue = 'Video Mix'`.
- [ ] **HP-2 (preset is not hardcoded).** Same as HP-1 but `videoTranscode` = **Standard** → one row, payload `videoTranscodeValue = 'Standard'`. Both HP-1 and HP-2 must pass; a fix that emits Standard for both would satisfy HP-2 alone.
- [ ] **HP-3 (event id comes from the shared helper, not a parallel scheme).** The written id equals `uuidv5('job-submission-video-transcode-command|ProceedingFile|<fileId>|<files.updated_at in ms>|callisto.proceeding.file.video-transcode-requested.v1')`.
- [ ] **HP-4 (payload parity with submit).** For the same file, the descriptor payload the new path produces is field-for-field identical to what the submit path would produce — including the `jobDate` string shape (see EC-4).
- [ ] **HP-5 (preset read server-side).** The emitted preset comes from the stored form, proven by sending a *different* value in the request body (or none, which is the real case) and asserting the form's value wins.
- [ ] **HP-6 (manual, in a running environment).** Video-role AJSF submitted with Video Mix → My Jobs → Submitted → the job → drop an `.mp4` into the proceeding's main upload zone → HTTP 2xx, file appears in the list, and the `outbox_events` row asserted directly in the DB per HP-1.
- [ ] **HP-7 — BLOCKED on PRDV-16398 (AC8).** End to end: Nova encodes to Video Mix and the derivative appears indented under the original. **Cannot pass today** — Nova applies `template1` regardless. Residual risk: the ticket's written AC is unverifiable end-to-end until 16398 merges. Follow-up: re-run HP-7 after 16398.

## Negative paths

- [ ] **NP-1 (red→green — the regression test the detection gap designs).** A spec asserting the writer **is** called for an eligible completed upload must **fail** on `47f5a841` (no writer is injected in the service today) and pass after the change. Record the failing output before implementing.
- [ ] **NP-2 (the pending path stays silent).** `uploadCompleteForPendingJobSubmission` does **not** call the new TS or the writer. No such assertion exists anywhere in the repo today.
- [ ] **NP-3 (ineligible preset).** `videoTranscode` ∈ {`Site Survey`, `Day in the Life`, `Other`, `''`, `null`} × MIME `video/mp4` × track `Video` → file created, **no** outbox row.
- [ ] **NP-4 (non-video MIME).** `videoTranscode` = `Standard` × MIME `application/pdf` → file created, no outbox row.
- [ ] **NP-5 (non-video track).** `videoTranscode` = `Standard` × MIME `video/mp4` × track ∈ {`Exhibit` 1, `MVC` 4, `Audio` 5} → file created, no outbox row. Reachable in the real UI: an exhibit-zone upload always lands on track 1, and a Digital-role submitter's main zone lands on track 5.
- [ ] **NP-6 (wrong attachment type).** `attachedToType ≠ 'Proceeding'` → no outbox row. This is the eligibility predicate the ticket and the coworker spec both omit.
- [ ] **NP-7 (feature flag off).** Everything else eligible, flag off → file created, legacy SQS still dispatched, **no** outbox row, and no wasted work if the flag is checked first (a deliberate divergence from submit — see EC-3).
- [ ] **NP-8 (legacy SQS unchanged).** `dispatchProceedingFileUpload` is still called, with the same arguments as today, on every completed upload regardless of transcode eligibility.
- [ ] **NP-9 (submit path unmoved).** All seven existing `submit-job-submission-form.transaction.script.spec.ts` tests stay green with assertions unmodified, and the writer / converter / id-helper specs are untouched.
- [ ] **NP-10 (emit failure is visible, not silent).** Writer throws → the outcome is whatever **OV-1** locks, and it is observable: either a non-2xx Atlas surfaces, or a warn log carrying `fileId` and `jobSubmissionFormId`. **What must never happen is a 2xx with no outbox row and no log line** — there is no backfill runner for this event type, so a swallowed failure is unrecoverable without manual DB surgery.
- [ ] **NP-11 (cross-form file injection).** A `fileId` that belongs to a different form than the `jobSubmissionFormId` in the request yields **no** row — proving the query retains `jsffa.jobSubmissionFormId` as a second predicate. Both ids come from the request body, so this is the guard that stops file F being emitted with form G's preset.
- [ ] **NP-12 (missing `jsffa` row is logged, not swallowed).** When `file.fileAttachment.id` is falsy no join row exists and the query returns nothing — the same "nothing" that "not a video" produces. Assert the bug case is logged rather than returning mutely.

## Edge cases

- [ ] **EC-1 (upload retry — duplicate emission, characterised).** Retry the same `key` → `findDeletedFileByPath` UPDATEs the existing `files` row (its `.withDeleted()` has no `deletedAt` filter), `updated_at` moves, a second attachment + `jsffa` row is created, and a **second event with a different id** is written. Assert and **document** this outcome rather than assuming it away; whether it is mitigated depends on **OV-3**.
- [ ] **EC-2 (side-effect ordering pinned).** Assert the call order of create → outbox → audit → SQS (or whatever **OV-2** locks) using `mock.invocationCallOrder` or a shared call log. Unpinned, this drifts silently and changes the blast radius of a propagated failure.
- [ ] **EC-3 (flag-check position, deliberate divergence).** Submit checks the flag **after** its query — a behaviour its spec pins. If the new path checks first, assert that and carry a one-line reason, so the divergence reads as chosen rather than accidental.
- [ ] **EC-4 (`jobDate` real shape).** `job_date` is a `date` column, so pg hydrates a `'YYYY-MM-DD'` **string** while the port declares `Date`. Use a **string** fixture, not `new Date(...)` — the submit spec's `Date` fixture does not exercise production shape.
- [ ] **EC-5 (`fileSize` bigint).** pg returns a string; the converter does the `Number(...)` coercion. Assert via the converter rather than hand-building the payload.
- [ ] **EC-6 (`user.identity` optional under `strictNullChecks: false`).** `identity` is declared optional yet dereferenced unguarded on both paths. Assert behaviour when it is absent, or pass only `{ userEmail, userFirstName }` into the TS so the surface cannot be hit.
- [ ] **EC-7 (per-upload query cost).** `JobSubmissionFormRepository.findById` eager-loads 14 relations including a OneToMany that multiplies rows by the form's `jsffa` count — so cost grows with uploads per form. Assert the implementation uses a lean form-context query, or record the accepted cost.
- [ ] **EC-8 (architecture gate).** `npm run test:architecture` passes — the specific gate that rejects a TS→TS call. Worth naming separately because it is the check that refuted the coworker spec's proposed flow, and because no git hook runs it.
- [ ] **EC-9 — frontier (A8).** An integration test showing what a **duplicate deterministic id** actually does to a published `outbox_events` row: expected UPDATE resetting `status='pending'` and `attempts=0` while leaving `published_at` stale. Currently read from library + TypeORM source, **never observed**. If not run, record as blocked with the residual risk.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| `callisto-back-end` | `…/multi-part-upload-proceeding-job-submission-file-complete-upload-service/__specs__/multi-part-upload-proceeding-job-submission-file-complete-upload.service.spec.ts` — **new, the first spec this class has ever had** | NP-1, NP-2, NP-7, NP-8, EC-2, EC-6 — flag resolution, TS invocation, call order, pending-path silence |
| `callisto-back-end` | `…/domain/transaction-scripts/write-completed-job-submission-video-transcode-outbox-ts/__specs__/…spec.ts` — new | HP-1…HP-5, NP-3…NP-6, NP-10…NP-12, EC-3, EC-4, EC-5 — the eligibility matrix and payload parity |
| `callisto-back-end` | `…/infrastructure/repositories/__specs__/job-submission-form-file-attachment.repository.*` (extend or add) | NP-11, and that the by-file-id variant keeps all three eligibility predicates verbatim |
| `callisto-back-end` | `…/submit-job-submission-form-ts/__specs__/submit-job-submission-form.transaction.script.spec.ts` — **existing, must not be modified** | NP-9 — submit's emission unchanged |
| `callisto-back-end` | `src/__tests__/architecture.spec.ts` — existing | EC-8 |
| — | Manual, running environment | HP-6; HP-7 blocked on PRDV-16398 |

## Gates

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` |
| lint | `npm run lint` |
| tests | `npm test -- --runInBand` (triggers `pretest` → `test:conventions` → `test:architecture`) |

Run in that order — audit first as a shipment blocker, lint second because `eslint --fix` may mutate files, tests last against the post-lint tree. Report the **final post-change state only**.

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| | | | | | |
