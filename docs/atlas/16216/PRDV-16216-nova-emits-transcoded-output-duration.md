---
ticket: PRDV-16216
tags: [nova, media-duration, video, transcode]
author: Dustin Thomason
created: 2026-07-13
modified: 2026-07-13
---

# Story: Nova Emits Transcoded Output Duration

> **SUPERSEDED, 2026-07-14** — principal-dev direction changed the approach: PRDV-16216 is now a Callisto read-time lookup (no Nova/protocol change), and the integrity concern moves to a separate Nova validation ticket (probe + compare + fail via the existing failure pipeline — **no event emission, no protocol field**). See `PRDV-16216-lookup-display-investigation.md`. This spec is retained as raw material for the validation ticket's spec; its Data Flow, Modified classes, and probe mechanics remain accurate for the probe portion only.

> **Parent epic:** File length metadata (Atlas File Navigator) — *placement in the wiki tree pending Larry's ruling (see Open questions)*
>
> **Dev note:** [[PRDV-16216-dev-note]]
>
> **Prerequisites:** [[neptune/media-duration/PRDV-9756-view-duration-of-media-files]] (Length column display), PRDV-15875 (`files.length` column — merged)
>
> **Companion tickets (out of scope here):** Callisto persists `duration` onto the derived file (to be created) · Backfill of historical derived rows (to be created) · Atlas: **none required**

---

## Summary

When Nova finishes transcoding a video, it already measures the media duration with ffprobe — but only logs it and throws it away, and the `nova.proceeding.file.video-transcode-completed.v1` payload has no duration field. Downstream, every Nova-derived file row lands in Callisto with `length = NULL`, so the Atlas Length column shows "unavailable" for transcoded videos while every other video shows its duration.

This story makes Nova probe the **transcoded output file** (not the source) after transcoding and thread that value — as optional integer whole seconds — through the outbox-writer pipeline into the completed event. Nova emits the **output** duration only; the **source** duration is already captured and stored (the source `File.length`) and serves as the established reference — Nova does not re-communicate it.

**Driver — legal-deliverable integrity (non-negotiable, per principal-dev review):** this is a legal videography transcoding pipeline. A client deliverable whose runtime does not match the source is lost evidence, which can cost a client. QC must be able to *verify* the deliverable's length against the source, not assume equality. That requires the output length to be **independently measured**, never copied: a copied value matches the source by construction and could never reveal a truncated or incomplete transcode. Verification is the visual comparison of the stored source length against the converted length in Atlas's existing two-row (original/converted) view — no Atlas change (settled in the investigation).

Duration is enrichment, not a delivery requirement: if the probe fails, the transcode still completes and the event is emitted without the field.

Callisto-side persistence of the new field is a companion story, not part of this one. No Atlas change is needed at any point — the Length column already renders any media file whose `length` is populated (verified: `ProceedingFileTableDataRow.vue` keys only on file extension and `length`; derivative filenames are always `.mp4`).

---

## Acceptance Criteria

- After a successful transcode, the `nova.proceeding.file.video-transcode-completed.v1` outbox event includes `duration`: the **output** file's media duration, rounded to integer whole seconds
- The value is probed from the transcoded output (`localOutputPath`) — no code path copies or forwards the source/input duration into the payload
- Output-probe failure, or an invalid result (`NaN`, `<= 0`, non-finite), does **not** fail the transcode: the event is emitted with `duration` omitted and a warning is logged with job context
- When the value is absent, the `duration` key is omitted entirely — never emitted as `0`, `-1`, or `NaN`
- The existing input-side probe and its `videoDurationSeconds` log line are unchanged
- Existing tests are updated and new assertions added per Spec Tests below

---

## Docking Protocol Contract

**Repo:** `orbital-docking-protocol`

**File:** `src/nova/proceeding/file/video-transcode-completed/v1/nova-proceeding-file-video-transcode-completed.v1.ts`

**Status:** Not yet updated — `duration` must be added as an **optional** field and published **before or alongside** this PR (the converter's typed payload literal will not compile without it). Optional keeps the change additive: consumers on the current version are unaffected, and mid-rollout events from older Nova versions parse cleanly.

```typescript
export type NovaProceedingFileVideoTranscodeCompletedV1Data = {
  proceedingId: number;
  jobId: number;
  fileId: number;
  fileSize: number;
  year: number;
  month: number;
  day: number;
  key: string;
  fileName: string;
  bucketName: string;
  proceedingTrackType: string | null;
  proceedingTrackTypeId: number;
  transcodedfilePath: string;
  transcodedbucketName: string;
  videoTranscodeValue: string;
  videoTranscodeId: number;
  createdAt: string;
  createdBy: string;
  duration?: number;    // NEW — transcoded output's media duration, integer whole seconds
};
```

> Version note: `nova-back-end`/`nova-orbital-back-end` declare `^1.0.5` but the installed package reports `0.2.13`. This anomaly must be reconciled before pinning the new version (see Open questions).

---

## Backend Changes (Nova)

### 1. Modified classes

| Class | Path | Change |
|-------|------|--------|
| `VideoConversionService` | `src/video-conversion/domain/services/video-conversion-service/video-conversion.service.ts` | After `TranscodeStep`, probe `materialized.localOutputPath` via `ProbeDurationStep` (non-fatal wrapper → `null` on error/invalid); `Math.round` the result; pass into `commitCompletedOutboxAndInbox(job, workerId, outputDurationSeconds)` and through both `writeCompletedEvent` call sites; add the value to the existing completion log line |
| `VideoConversionOutboxWriterPort` | `src/video-conversion/domain/ports/video-conversion-outbox-writer.port.ts` | `writeCompletedEvent(job: VideoJob)` → `writeCompletedEvent(job: VideoJob, outputDurationSeconds: number \| null)` |
| `VideoConversionOutboxWriterAssembler` | `src/video-conversion/infrastructure/outbox/assemblers/video-conversion-outbox-writer-assembler/video-conversion-outbox-writer.assembler.ts` | Forward `outputDurationSeconds` into `completedConverter.apply(job, outputDurationSeconds)` |
| `VideoJobToCompletedOutboxDescriptorConverter` | `src/video-conversion/infrastructure/outbox/assemblers/video-conversion-outbox-writer-assembler/video-job-to-completed-outbox-descriptor.converter.ts` | Map `duration` into the completed-event payload when non-null; omit the key when null |

Not modified (deliberate): `VideoJob` — it is assembled by `video-job.assembler.ts` **before** the pipeline runs, so it is not a natural carrier for a value discovered mid-pipeline; explicit parameter threading is the minimal path. `ProbeDurationStep`, `MediaProbePort`, and `FfprobeAdapter` are reused unchanged (`getDuration` is path-agnostic). The existing **input** probe keeps its current failure semantics.

### 2. New classes

None.

### 3. New migrations

None — Nova has no relational store (DynamoDB inbox/outbox + S3 only).

---

## Data Flow

```
TranscodeStep completes
    │
    │  materialized.localOutputPath (transcoded .mp4 on local disk)
    ▼
ProbeDurationStep (ffprobe -show_entries format=duration)   ← reused, now aimed at the OUTPUT
    │
    │  float seconds → Math.round → integer  |  error / NaN / <= 0 → null + warning log
    ▼
VideoConversionService.commitCompletedOutboxAndInbox(job, workerId, outputDurationSeconds)
    │
    ▼
VideoConversionOutboxWriterPort.writeCompletedEvent(job, outputDurationSeconds)
    │
    ▼
VideoConversionOutboxWriterAssembler ──▶ VideoJobToCompletedOutboxDescriptorConverter.apply(job, outputDurationSeconds)
    │
    │  maps into outbox event data (key omitted when null)
    ▼
nova.proceeding.file.video-transcode-completed.v1
  data: {
    ...existing fields,
    duration: 3723,    // NEW — output runtime, whole seconds
  }
```

The existing **input** probe (`localInputPath`, logged as `videoDurationSeconds`) is untouched and continues to serve ops telemetry — giving input vs output durations side by side in the completion log.

---

## Spec Tests

| Test | Path |
|------|------|
| Service pipeline spec | `src/video-conversion/domain/services/video-conversion-service/__specs__/video-conversion.service.spec.ts` |
| Completed-descriptor converter spec | `src/video-conversion/infrastructure/outbox/assemblers/video-conversion-outbox-writer-assembler/__specs__/video-job-to-completed-outbox-descriptor.converter.spec.ts` |
| Outbox writer assembler spec | `src/video-conversion/infrastructure/outbox/assemblers/video-conversion-outbox-writer-assembler/__specs__/video-conversion-outbox-writer.assembler.spec.ts` |
| Shared test factory | `src/test-utils/test-utils.ts` (`createMockVideoJob`, `sourcePayload` mock — signature ripple) |

**Key assertions:**

- Service invokes the output probe with `localOutputPath` after transcode, and passes the rounded value to `writeCompletedEvent`
- Probe throws → event still emitted, `duration` omitted, warning logged, transcode resolves successfully
- Probe returns `NaN` / `<= 0` / non-finite → treated as null (same as failure)
- Converter maps `duration` into event `data` when provided; omits the key when null
- Assembler forwards the parameter to the converter unchanged
- Input-probe invocation and its log line remain byte-for-byte as today

---

## Scope Boundaries

- **Nova (`nova-back-end`) only** — Callisto persistence of `duration` onto the derived `File.length` is a companion story
- **No Atlas changes** — display path is complete and merged (PRDV-9756 + PRDV-15875); derived filenames are always `.mp4`, so the Length column renders automatically once Callisto persists the value
- **No backfill** — historical derived rows stay `NULL` under this story; remediation is a separate ticket (a source-copy backfill is display-only and cannot serve parity validation)
- **No change to the normal-upload capture path** (client-measured `length` at upload stays as is)
- **No retry/queue semantics** — a missed probe is not retried; the value is enrichment
- **Not the `video-transcoded` sibling event** — that v1 type is unused in-workspace (never emitted by Nova, never consumed by Callisto); do not extend it

---

## Cross-cutting

- **Docking protocol:** `orbital-docking-protocol` must be published with optional `duration` on `NovaProceedingFileVideoTranscodeCompletedV1Data` before or alongside this PR; both Nova repos then pin the new version (blocked by the version-anomaly reconciliation below)
- **Downstream dependency:** the Callisto companion story reads `duration` from the completed event and persists it to `files.length` — it depends on this story, but this story does **not** depend on it (the field is optional, so Nova can release first with no consumer impact)
- **Rollout safety:** old-Nova events without `duration` and new-Nova events with it must both parse downstream; the optional field guarantees this in both directions

## Open Questions

| # | Question | Owner |
|---|----------|-------|
| 1 | Wiki placement of this spec: `neptune/media-duration/` (feature family, with PRDV-9756/16229/16231) vs the Nova platform tree (`systems/nebula/`, per PRDV-15828 precedent)? | Larry |
| 2 | Contract field name: `duration` (matches unsuffixed protocol style, e.g. `fileSize`) vs `durationSeconds` (self-documenting units)? | Larry / protocol owner |
| 3 | Additive optional field on v1 (recommended; no v2 precedent exists in the package) vs introducing a v2 event? | Larry / protocol owner |
| 4 | Version anomaly: Nova repos declare `^1.0.5` but the installed package is `0.2.13` — which is authoritative, and what version do we pin? | Nova devs / protocol owner |
| 5 | Ticket decomposition: does product split PRDV-16216 into per-repo tickets (protocol / Nova / Callisto / backfill), or keep one ticket with coordinated PRs? | Product |
| 6 | **Source-reference coverage:** the comparison relies on the stored source `File.length`. Investigation found source length is captured **only** browser-side, which is `null` for non-web formats (`.mts`/AVCHD, `.mkv`, `.avi`, `.wmv`…) — common in legal video. Larry indicates it is captured "through other means"; confirm whether a non-browser source capture exists. If not, the source side is blank for exactly those formats and QC has nothing to compare the output against — a verification gap, not a display gap. | Dustin / Larry |
