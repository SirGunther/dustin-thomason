---
ticket: TBD (companion to PRDV-16216 — ClickUp ticket to be created after product buy-in)
tags: [nova, transcode, video, validation, notification]
author: Dustin Thomason
created: 2026-07-14
modified: 2026-07-14
---

# Story: Validate Transcoded Output Duration in Nova

> **Companion to:** [[PRDV-16216-callisto-lookup-display-spec]] (independent — neither blocks the other)
>
> **Investigation:** [[PRDV-16216-lookup-display-investigation]]
>
> **Product decisions pending:** blocking semantics confirmation; notification template choice (see Open Questions)

---

## Summary

Nothing in the transcode pipeline verifies that the converted file has the same runtime as its source — an incomplete or truncated transcode would complete silently and be delivered. In a legal videography pipeline, that is lost evidence in a client deliverable.

This story adds a duration comparison inside Nova, where both files sit on local disk during the job. Nova already probes the **input's** duration (`ProbeDurationStep`, currently only logged). The **output's** duration is not currently captured anywhere — `TranscodeStep` returns void and the only post-transcode measurement is file size — so the comparison requires **one additional call of the existing, path-agnostic `ProbeDurationStep` against the output file**. No new probing infrastructure; the comparison itself is plain arithmetic, and its result is logged the same way every other pipeline step logs.

On mismatch, the job **throws before the output is persisted to S3** — which lands in the pipeline's existing catch and rides the already-built failure flow unchanged: failed event + failure-notification email + inbox marked failed, no completed event, no derivative created. The videography team is alerted and no bad deliverable can reach a proceeding.

Together with PRDV-16216 this closes the loop: a completed transcode implies durations matched, so the source duration Callisto displays for the converted file is an enforced invariant, not an assumption.

---

## Acceptance Criteria

- After `TranscodeStep`, the output file's duration is measured (reusing `ProbeDurationStep` on `localOutputPath`) and **logged alongside the input duration** in the pipeline's structured logs, matching existing step logging style
- Input and output durations are compared within a defined tolerance (recommendation: round both to whole seconds, allow ≤ 1 second delta — confirm with ops)
- **Mismatch:** the job throws **before** `PersistOutputStep` — the existing failure flow then, unchanged: writes the failed event (with a mismatch-specific error message; `errorCode` populated per Open Question 3), writes the notification-requested event (failure email to initiator + videosubmissions@ + LitTechMgmt@), marks the inbox event failed, exits non-zero; **no S3 output, no completed event, no derivative row**
- **Match:** the pipeline proceeds exactly as today, with the comparison result visible in the logs
- The existing input probe and its `videoDurationSeconds` log line are unchanged

---

## Backend Changes (Nova)

### 1. New classes

| Class | Path | Purpose |
|---|---|---|
| `ValidateOutputDurationStep` | `src/video-conversion/domain/steps/validate-output-duration.step.ts` | Follows the existing step pattern (own logger, `apply()`): takes input duration + output path, probes the output via the injected `MediaProbePort`, logs both values and the delta, throws `DurationMismatchError` when outside tolerance |
| `DurationMismatchError` | `src/video-conversion/domain/errors/duration-mismatch.error.ts` (or co-located per repo convention) | Typed error carrying input/output/delta so the failure message is specific and the failed event's `errorCode` can be derived from the error type |

### 2. Modified classes

| Class / file | Path | Change |
|---|---|---|
| `VideoConversionService` | `src/video-conversion/domain/services/video-conversion-service/video-conversion.service.ts` | Invoke `ValidateOutputDurationStep` after `TranscodeStep` (lines ~118–121) and **before** `PersistOutputStep` (~127–130), passing `videoDurationSeconds` (already in scope from line ~113) and `materialized.localOutputPath`; add the output duration to the existing completion log |
| `VideoJobToFailedOutboxDescriptorConverter` *(only if Open Question 3 = populate `errorCode`)* | `.../video-conversion-outbox-writer-assembler/video-job-to-failed-outbox-descriptor.converter.ts` (line 28 currently hardcodes `errorCode: null`) | Accept an optional error code and emit it; port/assembler `writeFailedEvent` signatures gain the optional parameter |

### 3. New migrations

None in Nova (no relational store). If Open Question 2 selects a **distinct** notification template, the Callisto notifications module needs its documented recipe applied (new MJML template + template key + registry entry + typed template data + seed migration + new event code) — that work would ride this ticket but land in `callisto-back-end`.

---

## Data Flow

```
MaterializeInputStep ─► ValidateInputStep ─► ProbeDurationStep(INPUT)   (existing —
    │                                         videoDurationSeconds       unchanged)
    ▼
TranscodeStep (ffmpeg) ─► output at localOutputPath
    │
    ▼
ValidateOutputDurationStep                                              ← NEW
    │   outputDuration = mediaProbe.getDuration(localOutputPath)
    │   log { videoDurationSeconds, outputDurationSeconds, deltaSeconds }
    │
    ├─ within tolerance ─► PersistOutputStep ─► completed event         (existing —
    │                                            (exactly as today)      unchanged)
    │
    └─ mismatch ─► throw DurationMismatchError
                        │
                        ▼  existing catch (video-conversion.service.ts :138)
                   commitFailedOutboxAndInbox   (existing — unchanged)
                        ├─ writeFailedEvent            errorMessage: mismatch detail
                        │                              errorCode: 'DURATION_MISMATCH'?  (OQ 3)
                        ├─ writeNotificationRequested  → failure email  (template per OQ 2)
                        └─ inbox.markFailed
                   no S3 output · no completed event · no derivative · exit 1
```

---

## Spec Tests

| Test | Path |
|---|---|
| New step (primary) | `src/video-conversion/domain/steps/__specs__/validate-output-duration.step.spec.ts` |
| Service pipeline | `src/video-conversion/domain/services/video-conversion-service/__specs__/video-conversion.service.spec.ts` |
| Failed-event converter *(if errorCode populated)* | `.../__specs__/video-job-to-failed-outbox-descriptor.converter.spec.ts` (currently asserts `errorCode: null` at line 47) |

**Key assertions:**

- Step probes `localOutputPath`, logs input/output/delta, returns normally within tolerance
- Delta beyond tolerance → throws `DurationMismatchError` with both values in the message
- Service: step runs after transcode and before persist; mismatch → failed commit invoked, `PersistOutputStep` and completed-event write **never** called
- Match → pipeline output identical to today (completed event unchanged — no new fields)
- Input probe call and its log line byte-for-byte unchanged
- *(If OQ 3)* failed event carries `errorCode: 'DURATION_MISMATCH'` for this error type, `null` otherwise

Gates: `npm audit --audit-level=high` → `npm run lint` → `npm test -- --runInBand` (nova-back-end).

---

## Scope Boundaries

- **No protocol change** — the comparison is internal to Nova; the completed event is untouched; the failed event's `errorCode` field already exists in the contract
- **No persistence of measured durations** — values live in logs and, on failure, in the failed event's message; storing them as data is a possible future enhancement, deliberately out of scope
- **No new notification pipeline** — failure alerting reuses the existing outbox → relay → Callisto inbox → MJML → MS Graph flow end-to-end
- **PRDV-16216 is independent** — neither ticket blocks the other; this one upgrades the displayed value from assumption to enforced invariant

---

## Open Questions

| # | Question | Owner |
|---|---|---|
| 1 | Tolerance: recommend whole-second rounding with ≤ 1 s delta (ffprobe-vs-ffprobe removes browser rounding skew; container timestamps can differ sub-second) — confirm with ops | Principal dev / ops |
| 2 | Notification: reuse the existing `VIDEO_TRANSCODE_FAILED` email (zero extra work; mismatch email reads like any conversion failure) vs a distinct "Duration Mismatch" event code + template (clearer for ops; Callisto template recipe + seed migration + Nova converter passes the new event code) | Product |
| 3 | Populate the failed event's `errorCode` (currently always `null`) with a first enumeration value `DURATION_MISMATCH`? Small signature threading; makes failures machine-distinguishable | Principal dev |
| 4 | Output-probe failure semantics: if the output can't be probed at all, treat as mismatch (fail safe — recommended for a legal pipeline) or complete with a warning log? | Product / principal dev |
| 5 | Confirm blocking semantics: mismatch = job fails, nothing delivered (recommended) vs deliver-with-warning | Product |

---

## Suggested point range

**Small–Medium (2–3 points).** One new step class following an established pattern, one service call-site insertion, reuse of the existing probe adapter and the entire existing failure/notification flow. Rises toward 3 only if Open Question 2 selects a distinct template (adds the Callisto notifications-module recipe).
