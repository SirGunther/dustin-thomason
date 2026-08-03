# PRDV-16402 — Transcode additional video uploads to submitted AJSFs

## Ticket

- **ClickUp:** [PRDV-16402](https://app.clickup.com/t/43227262/PRDV-16402)
- **Repo:** _TBD — determined in Phase 1._ Docs system is `atlas` (ClickUp Project Name "Atlas Video Conversion"); candidate implementation repos are `callisto-back-end` (coworker spec filed under `systems/neptune/callisto/video-transcode/`), `nova-back-end` / `nova-orbital-back-end` (transcode execution), and `atlas-front-end` (AJSF submitted-jobs upload surface).
- **Branch:** `PRDV-16402` _(not created yet — repo undetermined)_
- **PR:** _(link when opened)_

---

## Requirements (verbatim)

_Paste from ClickUp, spec, or the user's first description. Do not paraphrase on first capture._

Captured verbatim in `docs/atlas/PRDV-16402/PRDV-16402-original-ticket.md` (ClickUp browser capture, 2026-07-29). Reproduced here unchanged:

**Original Request**

> As an LTR videographer, I want files uploaded to the submitted jobs tab of the AJSF to also be transcoded matching the conversion specs from the initial submission, so that all files I upload for a job are transcoded for the video team

**Acceptance Criteria**

> - All video files uploaded to the AJSF submitted jobs tab for a given job are transcoded matching the specs of the initial job submission

---

## Context

_Optional: related tickets, environment, files to avoid, spec paths, team decisions._

- **Orchestrated ticket.** Running the `orchestrate` skill; per-ticket artifacts and phase ledger live in `docs/atlas/PRDV-16402/` (`orchestration.md` is the phase-state ledger). Folder convention follows the atlas precedent `docs/atlas/PRDV-XXXXX/` (see PRDV-16192, PRDV-14055), not the skill's nominal `docs/atlas/tickets/<slug>/`.
- **Coworker spec (read-only input):** [`larry-adams/systems/neptune/callisto/video-transcode/PRDV-16402-transcode-additional-video-uploads-to-submitted-ajsf.md`](https://github.com/planetdepos/larry-adams/blob/main/systems/neptune/callisto/video-transcode/PRDV-16402-transcode-additional-video-uploads-to-submitted-ajsf.md) — authored by Larry Adams, linked in ClickUp 2026-07-28. Read-only; never write to `larry-adams`.
- **ClickUp metadata:** Status READY FOR WORK; Priority High; Sprint points 2; Tags `missed requirement`, `sprint addition`; Issue type Story; Owning Team NASA; Primary Stakeholder Product.
- **Possibly-related prior ticket:** PRDV-16216 (transcoded media duration / Nova emits transcoded output duration) — same Atlas video-conversion domain; check its artifacts during the Phase 1 coverage consult.
- **Capture gap (carried from Phase 0):** the original-ticket artifact's *Explicit Constraints In Original Request* and *Context Paths In Original Request* sections hold placeholder text only. The user chose reuse-as-is over a ClickUp refresh, so they were not filled. The substantive links (ClickUp URL, spec URL) are captured elsewhere in that artifact and are reproduced above.

---

## Plans

_Lives in **dustin-thomason** only. Reference plans here so future agents do not repeat abandoned approaches. **Larry-adams** paths are **read-only links** to coworker specs — never create or push changelog/plan files there._

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-07-28 | [`larry-adams/systems/neptune/callisto/video-transcode/PRDV-16402-transcode-additional-video-uploads-to-submitted-ajsf.md`](https://github.com/planetdepos/larry-adams/blob/main/systems/neptune/callisto/video-transcode/PRDV-16402-transcode-additional-video-uploads-to-submitted-ajsf.md) — coworker spec by Larry Adams, **read-only link** | `active (input, partially superseded)` | New TS on the completed-upload path reusing submit's outbox stack, with in-TS track/MIME guards and a form load via `FetchJobSubmissionFormTS`. Core diagnosis confirmed correct; **three code-verified divergences** found (TS→TS forbidden at `severity: error`; eligibility re-expressed rather than reused, and under-counted at two predicates instead of three; the projection-fields flag is type-level only). |
| 2026-07-29 | `~/.claude/plans/go-melodic-rain.md` — Phase 1 investigation plan (orchestrate) | `implemented` | Executed the investigation method; emitted the report, coverage ledger, diagrams, test-plan seed, Why doc, and concerns. See `docs/atlas/PRDV-16402/orchestration.md`. |
| 2026-07-29 | `docs/atlas/PRDV-16402/investigations/PRDV-16402-investigation.md` §10 recommendation | `active` | Reuse submit's outbox stack; add a **by-file-id sibling of submit's own eligibility query** so track/MIME/attachment-type keep one definition; new `@Transactional`-proxied TS injecting repositories + the writer port token; feature flag resolved in the service. Disposition **proceed with conditions** — AC8 ("transcoded *matching* the preset") gated on PRDV-16398. |

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-07-31T00:00:00Z — dustin-thomason (docs only) — **Product confirmed the surface; prod-host catch found**

- **Summary:** Dustin asked the product manager overseeing the project where an LTR uploads a subsequently-missed video file. Answer, verbatim: `https://atlas.planetdepos.com/callisto-stuff/my-jobs?tab=submitted`. **This corroborates the 2026-07-30 diagnosis from outside the code** — it is the entry point to the submitted AJSF (surface 1), not the Proceeding Detail page that the failed test used. Navigation chain verified in code: `MyJobsPage.vue:28-42, 93-98` → `MyJobsTable.vue:37-40` (rows keyed by `jobTaskId`) → `:92-95` row click → `ConfirmJobNumberDialog` → `:60-67` push → `routes.ts:118-124` `submitted-job-submission-form/:jobTaskId` → `SubmittedFileUploadSection.vue:66-69` → `POST /proceeding-job-submission/upload-complete-completed` — the changed endpoint.
- **Two precisions, neither a disagreement with Product.** (1) The URL is the **entry point, not the upload page** — `my-jobs` has no upload control; the upload is one hop deeper at `submitted-job-submission-form/<jobTaskId>`, behind a dialog requiring the job number to be typed. (2) **It is a `prod` host, and prod does not have this feature** — last prod deploy is `v2026.15.1` (2026-07-27T21:07Z, run `30305547769`), which **predates Larry's `d97b1c4e` (2026-07-28)**, and `main` has carried the revert since. Testing at `atlas.planetdepos.com` would show no conversion regardless of page. Correct test URL: **`https://atlas-dev.planetdepos.com/callisto-stuff/my-jobs?tab=submitted`**.
- **Findings unchanged.** No conclusion from the 2026-07-30 analysis was revised; the wrong-surface cause is now confirmed by two independent sources.
- **Plan used:** none — diagnostic follow-up.
- **Files:** `docs/atlas/PRDV-16402/investigations/PRDV-16402-upload-location-failure-analysis.md` (new §2.1 with Product's answer verbatim + verified chain; hypothesis table gained the prod-host row; re-test step 1 now names the dev URL); this changelog; `docs/atlas/PRDV-16402/orchestration.md`.
- **Commits:** none. `atlas-front-end` read-only (`main`, `102e034d`); no implementation-repo file touched.

**Verification gates:** not triggered — docs-only session, no code changed in any repo. The 2026-07-29 gate table remains the compliance record for `3ecab1b8`.

### 2026-07-30T00:00:00Z — dustin-thomason (docs only) — **Manual test produced no transcode: wrong upload surface, not a code defect**

- **Summary:** Dustin manually tested on `atlas-dev` by dropping a video on the **video track** at `…/callisto-stuff/job/5019/proceeding/897?tab=submission-files` for an already-submitted job, and nothing was converted. Investigated both questions he raised. **The implementation did not fail — it was never reached.** That URL is the **Proceeding Detail page**, not the AJSF; its Submission Files tab posts to `POST /proceedings/upload-complete` (Callisto `proceedings` module), while the change adds the emit to `POST /proceeding-job-submission/upload-complete-completed` only (`proceeding-job-submission` module).
- **Second, independent cause found:** the file created on that path gets **no `job_submission_form_file_attachments` row** — that table's only writer is `JobSubmissionFormFileAttachmentAssembler`, called only from the AJSF upload service. The new lookup `findVideoFileForVideoTranscodeOutboxByFileId` is rooted at that table, so the file is **structurally unaddressable by this design** — pasting the emit call into the proceedings service verbatim would still return `null`. The request also carries no `jobSubmissionFormId`, and `JobSubmissionFormRepository` has no `findByJobId`.
- **Why it looked like the same place (the real trap):** both paths converge on the *same* `UploadCompleteProceedingFileTransactionScript` (the AJSF path via `ProceedingAggregator.createProceedingFile`), so the file lands with the same `attachedToType: 'Proceeding'`, same `Submission File` tag, same track, same legacy SQS dispatch and audit event, and appears in the same lists. The **only** difference is one link row invisible in the UI. Not a careless test.
- **Deployment hypothesis tested and refuted.** `origin/main` does not contain the feature (it carries the revert), but dev does not track `main`: the last **successful** dev deploy was Larry's `d97b1c4e` (2026-07-28T19:19Z, run `30391422693`), which **does** contain the feature. The `3ecab1b8` reland deploy (2026-07-29T21:14Z, run `30491618092`) **failed before registering a task definition** — `RegisterTaskDefinition … Container.image contains invalid characters`, a trailing space in the dispatched image tag — so it did not change the running service. **Dev has the feature; the test just did not reach it.** Evidence covers GitHub Actions deploys only; an out-of-band ECS console update would not appear and was not checked.
- **Full surface map produced:** five `upload-complete` endpoints reached from six Atlas surfaces; **exactly one** (submitted AJSF, `submitted-job-submission-form/:jobTaskId`) is covered. Note it is keyed by **`jobTaskId`** — the URL Dustin was on cannot be hand-edited into it.
- **Two gates never reached and therefore still untested for the re-test:** `IS_VIDEO_TRANSCODE_ENABLED` on the dev Cognito user (token claims only, no env override), and the form's preset being Standard or Video Mix.
- **Scope question raised, not absorbed:** the ticket says "the submitted jobs tab of the AJSF" (covered), but the Original Request also says "all files I upload for a job". Covering the proceeding-view surfaces needs its own ticket — `jobId` → form is not resolvable and not obviously 1:1 (a form is keyed per `jobTaskId`), and it would either change what the AJSF link row means or give eligibility a second definition. The **projector-runner follow-up** (report §6 alternative 4) is the clean vehicle.
- **Plan used:** none — diagnostic session against the re-landed branch.
- **Files:** `docs/atlas/PRDV-16402/investigations/PRDV-16402-upload-location-failure-analysis.md` (new); this changelog; `docs/atlas/PRDV-16402/orchestration.md`.
- **Commits:** none. Read-only across `callisto-back-end` (branch `PRDV-16402-reland`, `3ecab1b8`) and `atlas-front-end` (`main`, `102e034d`) — no implementation-repo file touched; callisto's three pre-existing local edits untouched.

**Verification gates:** not triggered — docs-only session in `dustin-thomason`, no code changed in any repo, so the audit/lint/test gates have no scope. The prior session's gate table (below) remains the compliance record for `3ecab1b8`.

### 2026-07-29T00:00:00Z — callisto-back-end — **Re-landed Larry's implementation; two agent errors corrected**

- **Summary:** Review concluded **nothing requires changing**. Re-landed Larry's implementation on branch `PRDV-16402-reland` — created off `origin/main` `67c1b973` and **cherry-picked `d97b1c4e`**, which preserves his authorship. Cherry-pick chosen over rebasing or merging his branch: the revert is in `main`, so merging `main` into `origin/PRDV-16402` would have deleted the implementation again (the classic revert-then-merge trap), and rebasing would have required force-pushing over a branch a principal lead pushed.
- **Two agent errors corrected, both stated as fact without verification.** (1) A claim that the completed-upload path "emails the team," on which review finding F1 and a whole duplicate-email/double-conversion scenario were built — **never verified**; the dispatcher publishes to an outbound SQS queue whose consumer lives outside this repo. (2) A claim that **PRDV-16398 was unshipped**, which drove a `proceed with conditions` disposition and a recommended AC split with Product — **it shipped**: Nova `main` `4128419` has `resolveTranscodePreset` keyed on `'Standard'`/`'Video Mix'`, both presets, and the wiring `video-job.assembler.ts:66` → `video-conversion.service.ts:124`. Source of the bad data was PRDV-16398's own orchestration ledger, still reading `in-progress` after merge. **The acceptance criterion is fully verifiable end to end.**
- **Failure analysis written** at `docs/atlas/PRDV-16402/PRDV-16402-investigation-failure-analysis.md` at Dustin's direction — third consecutive day of this failure class. Root cause: derived artifacts (coverage ledgers, dispatcher names) treated as primary sources; `source-truth` has no trigger for a *stale or adjacent* artifact, only a missing one. Six proposed rule changes, including plain-language-first as a **verification** mechanism rather than a presentation preference, and a rule that merging a ticket must update the ledger it will be read from.
- **Plan used:** re-land as-is (report §13 addendum), superseding §10's build-it recommendation.
- **Files:** `callisto-back-end` — 7 files, 622 insertions, unchanged from `d97b1c4e` (2 new specs, new TS + param, service, repository, module). `dustin-thomason` — new `PRDV-16402-investigation-failure-analysis.md`; rewritten `testing/PRDV-16402-testing-implementation.md` (fabricated claims removed); `PRDV-16402-pr-draft.md` findings marked superseded with F1/F6 withdrawn; `docs/nova/tickets/nova-applies-selected-transcode-preset/orchestration.md` corrected to record that 16398 shipped.
- **Commits:** `3ecab1b8` on `PRDV-16402-reland` (author Larry Adams, cherry-picked).
- **Notes:** No reviewers requested on the PR, per instruction and standing rule.

**Verification gates — final post-change state:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto-back-end | **fail (exit 1)** — 98 vulns, 68 high | **Pre-existing and unrelated, proven not asserted:** the change touches no dependency file and `package-lock.json` is byte-identical to `origin/main`, so this is `main`'s existing state (typeorm→glob, uuid, aws-sdk). Shipped on Dustin's explicit instruction. Residual risk: unchanged from `main`. Follow-up: dependency remediation is its own ticket. |
| lint | `npm run lint` | callisto-back-end (`eslint . --fix`) | pass | `--fix` mutated nothing; `git status` shows only the three pre-existing local edits (`.swcrc`, `notification-template-preview.html`, untracked `scripts/`), which were **not** committed |
| tests | `npm test -- --runInBand <write-completed-…-outbox-ts> <services/multi-part-upload> <submit-job-submission-form-ts>` | the new TS, the completed-upload service, and the submit path | pass — **5 suites, 29 tests** | Also ran the naming fitness-function via `pretest`. Full-suite run not performed; scope chosen as the changed unit plus the shared-path neighbour it must not disturb |

### 2026-07-29T00:00:00Z — dustin-thomason (docs only) — **Larry's implementation found; review recorded as scenarios**

- **Summary:** Dustin met with Larry Adams (principal lead, author of the original ticket and spec), who said the work "should be basically done" and that we should be reviewing whether it can be implemented as-is. **It can.** Located `origin/PRDV-16402` in `callisto-back-end` — commit `d97b1c4e`, 622 lines across 7 files, including 506 lines of specs and the **first spec this service has ever had**. It merged to `main` as PR #397 and was **reverted 7 minutes later** by PR #398. The revert reason is in Larry's own words and is **not technical**: *"I should not have merged before. I was moving too fast. I thought it was a different PR. Sorry."* No reviewer raised an objection; CI (ESLint, Prettier, type-check) was clean. The branch re-applies onto current `main` with **no conflict**.
- **Correction to the prior session's finding.** The earlier entry recorded "three code-verified divergences" from Larry's spec. That was a review of his spec's **prose and flow diagram** — the branch had not been found. **His code already resolves two of them, the better way:** it injects `JobSubmissionFormRepository` directly (no transaction-script-to-transaction-script call, so no `test:architecture` failure) and extracts a shared private `buildVideoTranscodeOutboxQuery` so the new single-file lookup **inherits** the eligibility predicates instead of restating them — which is exactly the shape this investigation was going to recommend. The third divergence (an under-counted predicate list) is moot for the same reason. **The recommendation is now: re-land his branch with two changes, not write a new implementation.** Plans row updated accordingly.
- **Review outcome — 2 changes, 3 comments, 1 ticket issue.** (F1) the conversion request is the **last** step, after the SQS notification, so a failure returns "file failed to upload" *after* the team has been emailed, and the user's retry sends a second email, orphans a file-attachment record, and converts the video twice — move it ahead of audit/SQS. (F2) because eligibility now lives in the shared query, unit tests **cannot** verify it; nothing at any level proves the new lookup still filters on proceeding attachment, Video track, and video MIME, or still rejects a file from a different job — add one repository-level test. (F3) `findById` loads the full job record plus 14 relations once per upload to read three fields. (F4) ~6 unrelated blank-line deletions inflate the diff. (F5) `jobDate` is a `'YYYY-MM-DD'` string passed into a port typed `Date`. (F6) not a code issue — the ClickUp AC is unverifiable until PRDV-16398 ships.
- **Plan used:** `docs/atlas/PRDV-16402/investigations/PRDV-16402-investigation.md` §10, now amended by that report's §13 addendum.
- **Files:** `docs/atlas/PRDV-16402/testing/PRDV-16402-testing-implementation.md` (new — plain-language scenarios per finding, started early by request); `docs/atlas/PRDV-16402/specs/PRDV-16402-larry-adams-spec.md` (new — verbatim copy of Larry's spec with a provenance block, read-only input); `docs/atlas/PRDV-16402/PRDV-16402-pr-draft.md` (Review findings section added; Description/Testing/Commit still unfilled); `docs/atlas/PRDV-16402/investigations/PRDV-16402-investigation.md` (§13 addendum appended, earlier sections unchanged); `docs/atlas/PRDV-16402/orchestration.md`.
- **Commits:** none. No code touched in any implementation repo.
- **Notes:** Two deliberate deviations from the `orchestrate` skill, both recorded in the ledger: the testing-implementation artifact was started at Phase 3 instead of Phase 5, and the PR draft received review content before Phase 5. Both at Dustin's explicit request, and both scoped to review findings rather than verified outcomes. `larry-adams` remains read-only and untouched — `git status` clean. **Baseline correction:** `origin/main` is now 4 commits ahead of the `47f5a841` baseline the report was keyed to, and those 4 commits are the implement/merge/revert sequence.

### 2026-07-29T00:00:00Z — dustin-thomason (docs only)

- **Summary:** Orchestration started (`orchestrate` skill). Phase 0 Capture closed: relocated the pre-existing ClickUp capture into the canonical ticket folder, scaffolded this changelog, and scaffolded the phase ledger. No implementation repo touched; no branch created.
- **Plan used:** none yet — Phase 1 investigation plan pending.
- **Files:** `docs/atlas/PRDV-16402/PRDV-16402-original-ticket.md` (moved, contents unchanged), `docs/atlas/PRDV-16402/orchestration.md` (new), `docs/atlas/PRDV-16402-changelog.md` (new).
- **Commits:** none.
- **Notes:** Original Request preserved verbatim — never rewritten. Implementation repo still undetermined (see Ticket → Repo).

---

## Root cause analysis

_Optional — fill when debugging._

---

## Attempt history

_Optional — one subsection per failed or partial approach._

### Attempt 1 — short label (commit `abc1234` optional)

**What:**

**Result:**

---

## Key technical learnings

1. 

---

## Current state (as of 2026-07-30)

_What is merged / on branch / reverted / still pending._

- **The implementation exists and is re-landed on `PRDV-16402-reland` (`3ecab1b8`, Larry's authorship preserved). Not merged to `main` — `main` still carries the revert.**
- **Manual test on 2026-07-30 produced no conversion, and that is not a defect.** The test used the Proceeding Detail page (`/job/:id/proceeding/:proceedingId?tab=submission-files` → `POST /proceedings/upload-complete`), not the submitted AJSF (`/submitted-job-submission-form/:jobTaskId` → `POST /proceeding-job-submission/upload-complete-completed`). Full analysis: `docs/atlas/PRDV-16402/investigations/PRDV-16402-upload-location-failure-analysis.md`.
- **Surface confirmed by Product (2026-07-31):** `my-jobs?tab=submitted` → click job → confirm job number → `submitted-job-submission-form/<jobTaskId>` is where an LTR uploads a missed video. Chain verified in code; it posts to the changed endpoint.
- **Dev runs `d97b1c4e`, which contains the feature. Prod does not** — last prod deploy `v2026.15.1` (2026-07-27) predates the commit, and `main` carries the revert. **Test on `atlas-dev`, not `atlas`.** The `3ecab1b8` dev deploy failed on a malformed image tag (trailing space) and did not change the service — re-run it with a clean tag if the exact reland artifact must be the thing under test.
- **The behaviour is still unverified end to end.** Two gates were never reached by the failed test and remain untested: `IS_VIDEO_TRANSCODE_ENABLED` on the dev Cognito user, and the form's preset being Standard or Video Mix. Re-test per the analysis §5, confirming in DevTools that the request hits `upload-complete-completed` **before** judging the outcome.
- **Superseded below.** The following four bullets were written at Phase 2 and are kept for the reasoning trail; two are now known wrong — Larry's implementation existed all along, and PRDV-16398 **shipped** (Nova `main` `4128419`), so the acceptance criterion is fully verifiable and AC8 is no longer gated.
- **Phases 0–2 done.** Investigated and reported; **no code written, no branch, no PR.**
- **Repo resolved: `callisto-back-end`** is the sole implementation repo. Atlas needs no change — both submitted-tab upload surfaces already call `upload-complete-completed`, and the client sends no preset, so the backend must re-read the stored form. Nova is out of scope (its half is PRDV-16398).
- **Disposition: proceed with conditions.** The gap is confirmed at `multi-part-upload-proceeding-job-submission-file-complete-upload.service.ts:75-102` — the completed-upload path injects no outbox writer, feature flag, or eligibility check at all.
- **Headline: the ticket's AC spans two tickets.** Nova ignores `videoTranscodeValue` and always applies `template1`, so "transcoded *matching* the specs" is PRDV-16398's half — and 16398 is unshipped (Phase 5, uncommitted, blocked on the HandBrake Video Mix preset from ops). AC8 is recorded as a named gate, not a blocker on this work.
- **Class reframed** from "new capability" to **coverage gap in an event-emission surface** — the whole outbox stack exists; a call site is missing. That dictates *mirror submit exactly, do not re-express its rules*.
- **Two open concerns worth flagging outside this ticket:** `PATCH /job-submission-form` is unguarded with no ownership check and can rewrite `videoTranscodeId` *and* `submissionStatusId` on a submitted form; and nothing snapshots the preset at submit, so "the initial submission" is unrecordable. Both in `PRDV-16402-future-development-concerns.md` (ten concerns total).
- Next: **Phase 3 — Probe & spec (Working mode)** — lock OV-1…OV-6 via grill-me, then write our own spec citing Larry's as input.

---

## New code introduced

_Optional — new modules, composables, endpoints._


