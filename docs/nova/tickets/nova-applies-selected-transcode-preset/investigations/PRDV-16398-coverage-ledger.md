# Coverage ledger — nova/nova-applies-selected-transcode-preset

Investigation question: **why does a job submitted with `videoTranscodeValue: "Video Mix"` get encoded with the Standard preset, and what is the complete set of values that can reach Nova?**
Repo(s): `nova-back-end`, `nova-orbital-back-end`, `callisto-back-end`, `atlas-front-end` · Baseline commit: `02b56c0` (`nova-back-end`, branch `main`, clean) · Started: 2026-07-28

## Consulted

- `docs/*/tickets/*/investigations/*-coverage-ledger.md` for "transcode", "ffmpeg", "video-conversion", "nova", "preset" — **two ledgers found, neither matched**: `ClickUpWideLayout/export-clickup-ticket-to-markdown` and `Jaimie/shareplane-modularize-availability`. No prior coverage of this subsystem in ledger format.
- `docs/` repo-wide for "transcode|video-conversion|nova-back-end" — **found prior work outside ledger format**: `docs/atlas/PRDV-16216/` (Nova emits transcoded output duration). **Reopened under condition 4** (*the current question concerns a different behavior*): PRDV-16216 investigated **Callisto consuming Nova's `video-transcode-completed` event**; this ticket investigates **Nova consuming Callisto's `video-transcode-requested` event** — the opposite direction, a different service, a different behavior. Its findings were **reused, not re-derived**: `PRDV-16216-local-validation-plan.md`'s harness pattern and `docs/atlas/local/publish-test-transcode-event.sh` established the event-injection technique, which pointed directly at Nova's own equivalent harness (area 9 below).

## Areas examined

### 1. `nova-back-end` — TranscodeStep (the defect site)

| Field | Value |
| --- | --- |
| Inspected | `transcode.step.ts` in full — `apply()` signature, arg construction, logging, error propagation |
| Findings | `apply(localInputPath, localOutputPath)` takes **no** preset parameter; line 25 calls `template1(...)` unconditionally; no conditional or ternary exists anywhere in the file; errors propagate unwrapped |
| Status | contributing |
| Commit | `02b56c0` · 2026-07-28 |
| Evidence | `src/video-conversion/domain/steps/transcode-step/transcode.step.ts:16-32` |
| Notes | Not `@Injectable()` — constructed inline by the service. Governs the "no DI" design choice. |

### 2. `nova-back-end` — the only preset builder

| Field | Value |
| --- | --- |
| Inspected | `ffmpeg.template.ts` in full; every repo-wide reference to `template1` |
| Findings | Exactly one exported builder, `template1` (720p H.264, 950k CBR, 29.97 CFR, keyint 12, AAC 128k 48kHz stereo, dual micro-fade). **5 references total**: 1 definition, 1 production consumer, 3 spec files. No second builder has ever existed. |
| Status | contributing |
| Commit | `02b56c0` · 2026-07-28 |
| Evidence | `ffmpeg.template.ts:1-54`; `grep -n 'template1'` → `ffmpeg.template.ts:1`, `transcode.step.ts:2,25`, `__specs__/transcode.step.spec.ts:4,21,25`, `__specs__/ffmpeg.spec.ts:1,3,11,21,32,45,54,69` |
| Notes | **Completeness claim:** the grep is exhaustive over `src/`; deleting `ffmpeg.template.ts` has exactly three importers to update. |

### 3. `nova-back-end` — VideoJob + assembler (where the value arrives and stops)

| Field | Value |
| --- | --- |
| Inspected | `video-job.ts` type; `video-job.assembler.ts` `apply()` in full; every read of `.template` repo-wide |
| Findings | `payload.videoTranscodeValue` → `VideoJob.template` at assembler line 66. `grep '\.template\b'` across `src/` → **zero production reads.** The value is carried the full pipeline length and dropped. `sourcePayload` retains the whole payload for outbox forwarding. |
| Status | contributing |
| Commit | `02b56c0` · 2026-07-28 |
| Evidence | `domain/video-job.ts:8`; `domain/services/video-conversion-service/video-job.assembler.ts:64-80` |
| Notes | The field **name** `template` is itself evidence of the vocabulary mismatch (report §1). |

### 4. `nova-back-end` — VideoConversionService pipeline (the call site + neighbours)

| Field | Value |
| --- | --- |
| Inspected | `video-conversion.service.ts` in full — `apply`, `runPipeline`, `commitCompletedOutboxAndInbox`, `commitFailedOutboxAndInbox`, `cleanupWorkspace`, `createChildLogger` |
| Findings | `TranscodeStep` constructed inline and called with two args (line 118-121). Five steps share `runPipeline`: Materialize, Validate, ProbeDuration, Transcode, PersistOutput — **the neighbours that must not move.** Failed path writes failed event + notification + `markFailed` in one DynamoDB transaction. |
| Status | contributing |
| Commit | `02b56c0` · 2026-07-28 |
| Evidence | `domain/services/video-conversion-service/video-conversion.service.ts:93-201` |
| Notes | Single call site for `TranscodeStep` — surface enumeration for the new third argument is complete at one. |

### 5. `nova-back-end` — existing test surface (the detection gap)

| Field | Value |
| --- | --- |
| Inspected | `transcode.step.spec.ts`, `ffmpeg.spec.ts` (reference list), `video-conversion.service.spec.ts` transcode assertion, `video-job.assembler.spec.ts` template assertions, `jest.config.json` |
| Findings | Three structurally un-failable layers: (1) `transcode.step.spec.ts:25` computes expected args by calling `template1` itself — tautological; (2) `video-conversion.service.spec.ts:203-208` asserts `expect.any(Array)`; (3) `video-job.assembler.spec.ts:49,95` asserts the value is *carried*, never *used*, with fixture `'template-1'`. Jest enforces **80% global coverage**, `collectCoverage` always on; `.preset.ts`/`.registry.ts` are not excluded. |
| Status | contributing |
| Commit | `02b56c0` · 2026-07-28 |
| Evidence | paths + lines above; `jest.config.json` `coverageThreshold.global` |
| Notes | This area **designs** the red→green regression test (report §9 step 6). |

### 6. `nova-back-end` — outbox descriptor converters

| Field | Value |
| --- | --- |
| Inspected | `video-job-to-completed-outbox-descriptor.converter.ts` in full; `omitUpdatedAuditFields`; existence of failed + notification converters |
| Findings | Completed event spreads `job.sourcePayload` verbatim (minus `updatedAt`/`updatedBy`), so it echoes the **requested** `videoTranscodeValue` and can never report an applied fallback. No field exists on the contract for an applied preset. |
| Status | contributing (to the A7 blind spot), ruled-out as a cause of this defect |
| Commit | `02b56c0` · 2026-07-28 |
| Evidence | `infrastructure/outbox/assemblers/video-conversion-outbox-writer-assembler/video-job-to-completed-outbox-descriptor.converter.ts:16-24,39-48` |
| Notes | **partial** — failed and notification converters were confirmed to exist but not read line-by-line; not required for this question. `omitUpdatedAuditFields` destructures `updatedBy`, a field absent from contract 1.0.5 → frontier. |

### 7. `callisto-back-end` — the producer and the value authority

| Field | Value |
| --- | --- |
| Inspected | `video-transcode.entity.ts` (`VIDEO_TRANSCODES`, entity, unique constraint); `is-video-transcode-selection-eligible-for-outbox.ts` in full; `job-submission-file-to-video-transcode-requested-descriptor.converter.ts` `toData()`; migrations `1751600004000` (seed), `1754574059506` (renumber), `1773945357657` (rename table) |
| Findings | Six values defined (`Standard`, `Video Mix`, `Site Survey`, `Day in the Life`, `Other`, `''`); the gate emits for **exactly two** — Standard and Video Mix. The converter passes `videoTranscodeValue` through verbatim. Renumber migration shifts `5→6, 4→5, 3→4, 2→3, 1→2`, making id 3 = Video Mix post-shift, matching the prod event's `videoTranscodeId: 3`. |
| Status | ruled-out as a cause — **Callisto is correct** |
| Commit | `callisto-back-end` working tree, 2026-07-28 (not SHA-pinned; read-only reference) |
| Evidence | `src/shared/shared-entities/entities/proceedings/video-transcode.entity.ts:5-12`; `src/proceeding-job-submission/domain/transaction-scripts/submit-job-submission-form-ts/is-video-transcode-selection-eligible-for-outbox.ts:12-16`; `src/typeorm/migrations/1754574059506-*.ts` |
| Notes | This area is the **authority** for the vocabulary Nova must mirror (report §5, contract alignment). |

### 8. Contract package + Atlas + nova-orbital (the rest of the pipeline)

| Field | Value |
| --- | --- |
| Inspected | `CallistoProceedingFileVideoTranscodeRequestedV1Data` `.d.ts` in both installed versions (`0.2.13` in nova's `node_modules`, `1.0.5` in callisto's); `package-lock.json` pin; Atlas `useJobSubmissionOptions.ts` (`fetchVideoTranscodes`); nova-orbital `video-conversion-requested.constants.ts` |
| Findings | `videoTranscodeValue: string` — a bare string, **no union**, so the type system gives Nova no exhaustiveness help. Atlas fetches options **at runtime** from Callisto (2-min `staleTime`), so the selectable set is data, not code. nova-orbital is transport only — binds queue/retry/DLQ routing keys, never inspects the payload. Version skew is a **stale local install**: lock pins `1.0.5`, `node_modules` has `0.2.13`. |
| Status | ruled-out as a cause; contributing to the fallback rationale (A6) |
| Commit | `02b56c0` (nova); others read-only working tree, 2026-07-28 |
| Evidence | `node_modules/@planetdepos/orbital-docking-protocol/dist/callisto/.../v1.d.ts` (both repos); `package-lock.json:4128-4131`; `atlas-front-end/src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/composables/useJobSubmissionOptions.ts:35-40,118-122`; `nova-orbital-back-end/src/inbox-ingestion/application/listeners/video-conversion-requested.constants.ts` |
| Notes | Closes the Phase 0 skew flag (A5). |

### 9. `nova-back-end` — local verification harness + the vocabulary sites

| Field | Value |
| --- | --- |
| Inspected | `docs/local-docker-transcode.md` in full; `scripts/run-local-transcode.sh` (arg handling, env defaults, inbox seeding); `scripts/` listing; `payload-local.json`, `payload-s3.json`; `package.json` scripts; entry point `video-conversion-task.handler.ts` |
| Findings | A **working end-to-end local harness exists** (LocalStack S3 + DynamoDB Local + `ffmpeg-worker` container); output is downloadable, so `ffprobe` can compare real encodes. Nova is a **one-shot task** — `onModuleInit` → `apply` → `process.exit`, no HTTP, one job per invocation. **Five sites encode `template1` as a `videoTranscodeValue`**, all needing convergence. `run-local-transcode.sh:116` hardcodes it and is **not parameterised**. Repo has no `.cursor/rules/`; `lint` = `eslint .`; `test` = `jest --config jest.config.json`. |
| Status | fully-inspected |
| Commit | `02b56c0` · 2026-07-28 |
| Evidence | `docs/local-docker-transcode.md:5,148,299`; `scripts/run-local-transcode.sh:116`; `payload-local.json`, `payload-s3.json`; `src/video-conversion/application/handlers/video-conversion-task-handler/video-conversion-task.handler.ts:26-42` |
| Notes | This is the area that produced the reclassification (report §1) and the only path that can satisfy AC 1/AC 2 for real. |

## Not yet inspected (frontier)

- **The AJSF producer** ("Transcode video files uploaded through AJSF", linked in ClickUp activity by Shaye Lankford) — would answer whether a second emitter bypasses Callisto's two-value gate, which decides whether the fallback path is reachable in production (report §10, D5). Not present in any of the four repos read.
- **The HandBrake Video Mix preset** (ops / Lit Tech) — the source artifact for `vid-mix.preset.ts`'s arg values, and the reference for whether `template1` still matches HandBrake Standard (D4, D6). External to all repos; will not be inferred.
- **`omitUpdatedAuditFields` field-name drift** — destructures `updatedBy`, absent from contract `1.0.5` (which has `modifiedUserIdentity`). Harmless via untyped `Record` passthrough; would answer whether the completed event forwards audit fields it shouldn't. Unrelated to preset selection.
- **`nova-back-end` failed + notification outbox converters** — confirmed to exist, read only at the call-site level (area 6, `partial`). Would answer whether either path also needs the applied-preset value if D2 were ever pursued.
- **`nova-video-transcoder/` directory and `devops/`** at `nova-back-end` root — not opened; no indication they carry transcode configuration, but not proven empty of preset references.
- **Sandbox/production log retention** — would answer whether the existing `Transcoding media` log lines are queryable enough to audit which preset historical jobs used. Relevant only if Product asks how many jobs were affected.
