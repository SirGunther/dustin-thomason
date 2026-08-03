# Why these changes — atlas/PRDV-16402

> The living "Why" of this ticket. Created Phase 1 (materialized at Phase 2's first action), updated every phase, finalized at close. High-level — scenarios live in the testing-implementation doc; point-in-time classification lives in [the investigation report](investigations/PRDV-16402-investigation.md).

**Ticket:** [PRDV-16402](https://app.clickup.com/t/43227262/PRDV-16402) — Transcode additional video uploads to submitted AJSFs
**Companion:** PRDV-16398 (Nova applies the selected preset) — see "The dependency that reframes the AC" below.

---

## Problem class (the core — what are we actually solving?)

**A coverage gap in an event-emission surface.**

Three code paths create AJSF proceeding files. Exactly one of them emits the video-transcode request event. The other two are silent — one of them (the pending-upload path) *correctly* silent, because form submit emits for it in batch; the other (the completed-upload path, used by the submitted-jobs tab) silently drops the file out of the transcode pipeline forever.

This is **not** a new-capability problem, which is how the request frames it ("I want files … to *also* be transcoded"). Every part of the machinery already exists and works: the eligibility gate, the projection, the descriptor converter, the deterministic-id helper, the outbox writer, the port token, the feature flag, the docking-protocol event type, and Nova's consumer. Nothing needs inventing. What is missing is a **call site**.

That distinction is load-bearing, and it dictates the shape of the fix: **mirror the submit path exactly; do not re-express its rules.** A "new capability" framing invites writing fresh eligibility logic in the new path — which is precisely the mistake that would make the two paths drift the first time someone widens one of them. See report [§1](investigations/PRDV-16402-investigation.md).

## The code at the root (what/where is the problem)

`MultiPartUploadProceedingJobSubmissionFileCompleteUploadService.uploadCompleteForCompletedJobSubmission` —
`callisto-back-end/src/proceeding-job-submission/domain/services/multi-part-upload/multi-part-upload-proceeding-job-submission-file-complete-upload-service/multi-part-upload-proceeding-job-submission-file-complete-upload.service.ts:75-102`

It does three things — `createProceedingFile`, `dispatchFileAuditCreatedEvent`, `dispatchProceedingFileUpload` (legacy SQS) — and returns. The class injects **no** outbox writer, **no** feature-flag aggregator, and **no** eligibility check (`:19-27`). The absence is total, not partial: a repo-wide grep for `JOB_SUBMISSION_VIDEO_TRANSCODE_OUTBOX_WRITER_TOKEN` never reaches this file.

The authority it fails to mirror is `SubmitJobSubmissionFormTS:45-75` plus the eligibility predicates in `JobSubmissionFormFileAttachmentRepository.findProceedingsAndFilesByJobSubmissionFormIdForVideoTranscodeOutbox:64-107`. Full trace: report [§5](investigations/PRDV-16402-investigation.md).

## The problems we're solving

1. **Files uploaded after submit never enter the transcode pipeline.** The videographer's uploads are persisted and audited and look fine in the UI; nothing signals that they will never be converted. Slow, silent failure.
2. **The eligibility rule has one definition today, and the obvious fix would give it two.** Track, MIME, and attachment-type are expressed only in SQL. Any re-statement of them in TypeScript is a drift surface created on day one.
3. **The ticket's acceptance criterion cannot be satisfied by this ticket alone** — see below. That is a problem about the *ticket*, not the code, and it needed surfacing before implementation rather than after QA.

## The dependency that reframes the AC

The ticket asks for files "transcoded **matching the conversion specs** from the initial submission." PRDV-16402 can only make the *request* carry the correct preset. **Nova ignores it** — `videoTranscodeValue` arrives, lands on `VideoJob.template`, and is never read; `TranscodeStep` applies `template1` (Standard) unconditionally. Established in the PRDV-16398 coverage ledger (areas 1–3: zero production reads of `.template`), reused here rather than re-derived.

PRDV-16398 fixes that and is **unshipped** — its ledger shows Phase 5 in-progress, uncommitted, with `vid-mix.preset.ts` arg values blocked on the HandBrake Video Mix preset from ops.

So the ticket's single AC bundles two classes of problem owned by two tickets: *the request is never made* (16402) and *the request is ignored* (16398). Disposition is **proceed with conditions** — 16402's half is independently shippable and testable; the "matching" half is a named gate on AC sign-off.

---

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-07-29 — [NEW UNDERSTANDING]

- **Obvious from the start:** the completed-upload path does not write the outbox event. Larry Adams' spec said so, and direct reading confirmed it in full — his core claim is correct.
- **Not obvious #1 — the AC spans two tickets.** Nothing in the ticket, the AC, or the spec says that "matching the conversion specs" is currently impossible because Nova hardcodes Standard. It only surfaced because the coverage consult found the companion ticket's ledger. This is the single most consequential finding of the phase, and it is a *ticket-scope* finding, not a code finding.
- **Not obvious #2 — eligibility lives only in SQL, and there are three predicates, not two.** `fa.attachedToType = 'Proceeding'`, `tt.value = 'Video'`, and `LOWER(f.fileType) LIKE 'video/%'` all sit inside one query builder. Larry's spec proposes re-expressing two of them (and omits the third) as TypeScript checks in the new transaction script. That would create a second, already-incomplete definition of the rule. This flipped the fix shape from "new TS with its own guards" to "by-file-id sibling of the existing query."
- **Not obvious #3 — the preset is mutable after submit, and nothing snapshots it.** `PATCH /job-submission-form` has no guard, no ownership check, no user context, and no status precondition, and can rewrite `videoTranscodeId` *and* `submissionStatusId` on a submitted form; Atlas's pending page is reachable by URL for a submitted form and its save is not status-gated. Submit writes only status/submitter/`updatedAt` — never the preset. So "from the **initial** submission" is a phrase the data model cannot honour: the system cannot distinguish the submit-time selection from the current one. Recorded as the Step-7 "the structure genuinely cannot answer this" case, with the missing seam named.
- **Course correction inside the phase — the duplicate-emission story was wrong twice.** First hypothesis: re-submit re-emits and collides on the deterministic id. Refuted — `JobSubmissionFormStatusValidator` blocks re-submit sequentially, which incidentally *confirms* Larry's "emit only for the new file" decision. Second hypothesis: the deleted-file revival branch reuses a `files.id`. Half-refuted — `findDeletedFileByPath` is `.withDeleted()` with **no `deletedAt` filter**, so it is an upsert-by-`(bucket, filePath)` despite its name, and the real vector is an upload **retry**, which produces a *different* id (because `updated_at` moves) plus orphaned attachment rows. Consequence: an `existsById` guard, which was the intuitive fix, cannot catch the vector this change actually creates. Dropped it.
- **What was noise:** the front end. Two upload surfaces exist on the submitted AJSF page, both already call the completed endpoint, and transcoded outputs *already* appear in that file list today paired via `sourceFileId`/`lineageRole`. So the "backend-only change is secretly front-end-visible" worry dissolved — this ticket widens the trigger population, not the UI shape. Also noise: the `length`/duration field (no field for it on the contract) and the docking-protocol version skew.
- **Assumptions logged and resolved in-phase:** A1–A13 (report §8). Everything code-discoverable was traced rather than parked — including the two questions above that a lazier pass would have carried to the user as "decisions."
- **Genuine decisions isolated for Phase 3:** OV-1…OV-6 (report §10) — failure semantics, side-effect ordering, transaction scope, preset semantics, the dead `proceedingValue` column, and whether to ship ahead of 16398.
- **Discarded path (recorded, not chosen):** a table-driven outbox projector runner watermarked on `files.updated_at`. Genuinely better architecture — one idempotent, self-healing, backfillable path covering submit *and* post-submit, letting the submit call site be deleted rather than duplicated. Rejected for this ticket because changing `runnerName` changes every deterministic id (shipped files would re-emit unless the checkpoint is seeded past them) and it needs a poller, lock key, config accessor, and index migration. Filed as the follow-up that retires both call sites, so the second call site reads as deliberate interim duplication rather than the target architecture.

### Phase 2 — 2026-07-29

- Nothing moved. The report, coverage ledger, diagrams, test-plan seed, and concerns record Phase 1's findings; no new understanding, course change, or discarded path emerged while writing them.

---

## Changes made — categorized (filled as implementation locks; subject to update)

_Not yet — no code written. Populated in Phase 5._

## Why it shipped together

_Pending implementation._

## Scope

**In:** Callisto only — the completed AJSF upload path emits `callisto.proceeding.file.video-transcode-requested.v1` for the newly uploaded file when it meets submit's own eligibility rule.

**Out:** Nova, the docking protocol, and the legacy SQS proceeding-file-upload event; the pending-upload path (submit remains its batch emitter); backfilling post-submit uploads that never got outbox rows; the MIME/track heuristics; and every item in [future-development concerns](PRDV-16402-future-development-concerns.md).

## Net

_Pending — filled at Phase 6._

## Verified

_Pending — gates and manual evidence land in Phase 5, sourced from the test plan and testing-implementation doc._
