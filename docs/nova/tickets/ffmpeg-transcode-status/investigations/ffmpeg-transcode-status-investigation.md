# FFmpeg Transcode Status Investigation

**Status:** Investigation complete; implementation not authorized  
**Date:** 2026-08-03  
**Disposition:** Proceed with conditions  
**Purpose:** Determine the professional, end-to-end scope required to show live video-transcode stage and percentage information in Callisto while Nova performs FFmpeg conversion.  
**Companion evidence record:** `ffmpeg-transcode-status-coverage-ledger.md`  
**Companion design decision register:** `../ffmpeg-transcode-status-design-decisions.md`  
**Revised:** 2026-08-03 — see the [validation addendum](#validation-addendum--independent-verification-pass-2026-08-03). One finding withdrawn (routing-key mismatch), one gate closed (FFmpeg compatibility), decision gates reduced from nine to four blocking. The recommended architecture is unchanged.
**Design-decision expansion:** 2026-08-03 — URL, LTR audience, authorization, feature-flag, and rollout choices were separated into the companion decision register. The AJSF file-list authorization boundary below was added from primary-source inspection.

## Executive verdict

The feature is viable, but it is not an FFmpeg-only change. The current system has no durable representation of a transcode between Callisto writing the request and Callisto successfully persisting the converted derivative. A professional implementation therefore needs all of the following:

1. Nova must read FFmpeg's structured progress output, translate it into domain progress, and publish bounded, durable progress events.
2. The shared docking protocol must define that progress event.
3. Callisto must persist a transcode run independently of the eventual derivative, consume progress and failure events idempotently, and project the latest run through its API.
4. Atlas/Callisto UI must render the lifecycle and conditionally refresh only while work is active.
5. Messaging throughput, retention, stale-run behavior, and rollout order must be treated as production constraints rather than deferred cleanup.

The recommended user-visible lifecycle is:

`queued → preparing → transcoding (0–99%) → finalizing → completed (100%)`

Any non-terminal stage may transition to `failed`. The original uploaded file remains available after failure. Progress must survive page refreshes and reconnects, and a terminal event must always win over late or duplicate progress.

This report does **not** approve implementation. Before implementation begins, the conditions in [Decision gates](#decision-gates) must be resolved.

## Requirements and sanity-check checklist

These questions restate the requested behavior as checks. They are referenced throughout the report so the investigation remains tied to its purpose.

- [x] **R1 — Initiation:** What exact user action creates a transcode, and how can Callisto show `queued` immediately rather than waiting for Nova?
- [x] **R2 — FFmpeg signal:** Can Nova obtain a structured, trustworthy percentage from FFmpeg without parsing human-oriented log text?
- [x] **R3 — Complete lifecycle:** How are the non-FFmpeg stages—materializing, validating, probing, publishing, and Callisto finalization—represented?
- [x] **R4 — Transport:** Can the existing Nova outbox/RabbitMQ/Callisto inbox path carry intermediate status with acceptable latency and bounded volume?
- [x] **R5 — Durability:** Does status survive refresh, navigation, reconnects, worker restarts, and missed intermediate events?
- [x] **R6 — Frontend behavior:** Where will Callisto render the status, how will it refresh, and how will it prevent percentage regression or premature 100%?
- [x] **R7 — User language:** What should the UI say while queued, preparing, converting, finalizing, completed, and failed?
- [x] **R8 — Failure:** How do Nova failures and Callisto finalization failures become safe, visible terminal state without exposing FFmpeg stderr?
- [x] **R9 — Distributed-system safety:** What happens with duplicates, out-of-order delivery, retries, concurrent files, late progress, and stale runs?
- [x] **R10 — Change map:** Which repositories, contracts, schemas, modules, API types, UI components, tests, and operational controls must change?
- [x] **R11 — Architecture quality:** Does the design extend existing durable conventions instead of adding a direct broker side channel, log scraper, or process-local workaround?
- [x] **R12 — Investigation boundary:** Are assumptions, decisions, validation gates, and non-goals explicit while leaving production code untouched?

## Problem classification

**Confirmed class:** Distributed lifecycle/state propagation and presentation across an asynchronous, one-shot, at-least-once workflow.

The request initially points at “FFMPEG's conversion indicator,” but the absence of a percentage parser is only the first missing link. Callisto currently writes a request and later learns about success after Nova finishes. It has no durable active run, no proceeding-level failed-event consumer, no intermediate contract, and no frontend refresh behavior. Solving only the parser would produce information that has nowhere reliable to go.

### Problem Check

| Check                     | Evidence                                                                      | Finding                                                                                                             |
| ------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| User evidence             | “live representation of transcoding process”                                  | The desired experience is clear; no named affected user or production job was supplied.                             |
| Conflation                | “conversion indicator to communicate from nova back to callisto”              | This combines process observation, event transport, durable state, API projection, and UI behavior.                 |
| Thin term                 | “live representation”                                                         | The acceptable delay was not defined. This report proposes a measurable target rather than assuming real-time push. |
| Proposed solution         | FFmpeg conversion indicator                                                   | Supported as the observation mechanism, but insufficient as the system design.                                      |
| Actual decision requested | “what it takes to put it together and where the implementations are required” | The needed output is an end-to-end scope, dependencies, risks, and validation plan—not code.                        |

### Plain-language problem statement

After Callisto submits a video-transcode request, users cannot tell whether that specific file is queued, preparing, converting, finalizing, stalled, completed, or failed. The system only creates a user-queryable derivative after successful finalization, and Callisto has no proceeding-level path for Nova's failed event.

### Concrete system instances

1. A video selected for Standard Deposition or Video Mix during form submission.
2. An eligible video uploaded after submission through the AJSF flow introduced on Callisto branch `PRDV-16402-reland`.

No named person or production incident was provided. Product should add one observed customer/job example before treating urgency or acceptance as validated user evidence. The next eligible transcode after this feature is exposed is the practical trigger; no dated release deadline was supplied.

## Acceptance criteria

These criteria are the implementation target implied by R1–R12. Values marked **proposed** require owner approval.

1. The same Callisto transaction that writes a requested event also creates a durable run in `queued` state.
2. Nova uses FFmpeg's machine-readable `-progress` channel and `out_time_us`; it does not parse human `stderr` lines such as `time=`.
3. `preparing`, `transcoding`, and `finalizing` transitions are explicit and use the same request/run correlation ID.
4. During `transcoding`, the displayed percentage is monotonic and clamped to 0–99. It becomes 100 only after Callisto has persisted the successful derivative.
5. Refreshing or reopening a proceeding reconstructs the latest state from Callisto's database; no correctness depends on an open browser or in-memory worker state.
6. Duplicate and out-of-order progress does not regress state. Progress received after a terminal state is ignored and observed as an invariant violation if appropriate.
7. A Nova processing failure or permanent Callisto finalization failure produces a safe `failed` status. The original file remains available and raw stderr is never returned to the browser.
8. The frontend refreshes only while at least one visible run is active and stops after all visible runs are terminal.
9. **Proposed live target:** p95 from a progress event being emitted in Nova to its updated state being visible in Callisto is at most 15 seconds under supported concurrency.
10. Intermediate event production is bounded: immediate stage transitions, then no more than one percentage event per five seconds and no more than 100 percentage events per transcode.
11. Existing completed-derivative behavior, notifications, preset selection, and output media behavior remain unchanged.
12. Tests cover parser chunking, unknown duration, retries, duplicates, out-of-order delivery, terminal races, multiple files, refresh, and failure copy.

## Non-goals

- Implementing any production code during this investigation.
- Changing FFmpeg presets, output encoding, or output storage semantics.
- Adding pause, resume, cancel, retry, ETA, or a global transcode dashboard.
- Adding WebSocket/SSE infrastructure unless measured polling cannot meet the approved freshness target.
- Exposing raw FFmpeg logs or internal exception messages to end users.
- Using CloudWatch/log scraping as product state.
- Defining long-term transcode analytics beyond the retention needed for reliable user state and operations.

## Evidence baseline

| System               | Inspected baseline                                                                          | Notes                                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Nova backend         | `C:\Users\dustin.thomason\nova-back-end`, commit `58a6182`, branch `PRDV-16398`             | Clean. Contains selected-preset implementation.                                                      |
| Nova Orbital backend | `C:\Users\dustin.thomason\nova-orbital-back-end`, commit `bfd5094`, `main`                  | Local branch was two commits behind its remote at inspection time.                                   |
| Callisto backend     | `C:\Users\dustin.thomason\callisto-back-end`, commit `3ecab1b8`, branch `PRDV-16402-reland` | User-owned unrelated changes existed and were not modified.                                          |
| Atlas frontend       | `C:\Users\dustin.thomason\atlas-front-end`, commit `102e034d`, `main`                       | Contains the Callisto frontend under `src/callisto`; local branch was six commits behind its remote. |
| Docking protocol     | Installed compiled package in Nova/Callisto dependencies                                    | Protocol source repository was not locally available.                                                |
| Documentation        | `C:\dustin-thomason`, commit `19c8d09`, `main`                                              | Existing user changes were not modified.                                                             |

Remote changes beyond these commits are not silently assumed. The implementation specification must rebase/reinspect the selected target branches.

## Current-state trace

### 1. Initiation in Callisto — R1, R5

Callisto creates `callisto.proceeding.file.video-transcode-requested.v1` events from two observed paths:

- `SubmitJobSubmissionFormTS`, when an eligible file and transcode selection are submitted.
- `WriteCompletedJobSubmissionVideoTranscodeOutboxTS`, for eligible uploads after a form is already complete.

The request includes proceeding, job, file, storage path, selected transcode, and user context. No transcode-run row is created. Therefore Callisto cannot query `queued` immediately, even though it is the authority that initiated the work.

The initial form-submit frontend navigates to My Jobs after submission, while the post-submission upload surface remains on the proceeding/upload view. That creates a real product decision about where “live” status must be visible; it is not only a component-placement detail.

### 2. Nova task and FFmpeg — R2, R3

Nova Orbital receives the request and launches a one-shot ECS/Fargate task. Nova's conversion pipeline is:

`MaterializeInput → Validate → ProbeDuration → Transcode → PersistOutput`

Relevant code:

- `src/video-conversion/domain/services/video-conversion-service/video-conversion.service.ts`
- `src/video-conversion/domain/steps/transcode-step/transcode.step.ts`
- `src/video-conversion/infrastructure/adapters/ffmpeg.adapter.ts`
- `src/video-conversion/domain/ports/transcoder.port.ts`

`ProbeDuration` already obtains total duration before transcoding. The FFmpeg adapter then spawns `/usr/local/bin/ffmpeg`, streams stdout only to logs, accumulates stderr, and resolves or rejects only when the child exits. The `TranscoderPort` returns `Promise<void>`, so no progress crosses the adapter boundary.

FFmpeg officially supports `-progress <url>`, which emits periodic `key=value` blocks ending in `progress=continue` or `progress=end`; cadence is controlled by `-stats_period`. Its source emits `out_time_us`, which can be divided by the probed duration to calculate progress. `-nostats` prevents reliance on human-oriented statistics output.

Sources:

- [FFmpeg command-line documentation](https://www.ffmpeg.org/ffmpeg.html)
- [FFmpeg source showing `out_time_us`](https://www.ffmpeg.org/doxygen/trunk/ffmpeg_8c_source.html)

The bundled Linux FFmpeg binary could not be executed from the inspected Windows environment. It was, however, inspected directly: `Dockerfile:18-22` copies `./bin/ffmpeg` to `/usr/local/bin/ffmpeg` — the exact path the adapter spawns — and that binary contains the option strings `progress`, `stats_period`, and `out_time_us`. Structured-progress support is therefore evidenced against the shipped production artifact, not merely expected of a modern build. A container run of `-version` plus a progress fixture is still worth doing as confirmation, but it is no longer an open question. See the [validation addendum](#validation-addendum--independent-verification-pass-2026-08-03).

### 3. Nova terminal events — R3, R8

Nova writes completed or failed events through its DynamoDB outbox. Completion is transactionally coupled with the processed inbox state. Failure is likewise written with inbox failure state and a notification request.

There is no progress event or stage publisher. The failed payload has `originEventId`, but `errorCode` is currently null and `errorMessage` can derive from accumulated FFmpeg stderr. That raw value is useful for protected diagnostics but is unsuitable as browser copy.

Nova's failure path also writes a **notification-requested** outbox event carrying `eventCode: VIDEO_TRANSCODE_FAILED` (`video-job-to-notification-outbox-descriptor.converter.ts:28`), which Callisto's `notification-requested` listener renders through `video-transcode-failed.template`. The docking protocol additionally already ships `callisto.alert.nova-video-transcode-failed.v1`. An **internal** failure-notification vocabulary therefore already exists; the stable failure codes proposed in §D should align with it rather than introduce a parallel taxonomy.

### 4. Nova relay capacity — R4, R9

Nova Orbital's generic relay polls its outbox every five seconds with a batch size of 20 and publishes using `event.eventType` as the RabbitMQ routing key. At those defaults its maximum drain rate is approximately four events per second before processing overhead. At one event per active job every five seconds, roughly 20 simultaneous jobs would consume that entire nominal capacity, leaving no headroom for terminal or unrelated events.

This does not prove production overload because actual concurrency, event duration, deployed configuration, and shared traffic were not available. It does prove that unthrottled FFmpeg output—approximately every 0.5 seconds by default—must not be relayed one-for-one and that a load/capacity gate is mandatory.

### 5. Callisto consumption and finalization — R5, R8, R9

Callisto currently registers a proceeding handler for completed transcodes only. No proceeding handler persists Nova's `nova.proceeding.file.video-transcode-failed.v1` event. (An internal failure-notification path _does_ exist — see §3 — so "no failure handling" would overstate it; what is absent is durable, user-visible, proceeding-level failed state.) The completion service copies Nova's output into Callisto's jobs bucket and then persists the derivative. This means Nova completion is not end-to-end completion: while Callisto copies and records the file, the user-visible stage must be `finalizing`.

> **Correction (2026-08-03) — this section originally reported a "blocking baseline issue": a routing-key mismatch between Nova's published event type and Callisto's listener binding. That finding does not hold.** It read a queue _name_ as a _binding_. The paragraphs below are the corrected account; the original claim and why it was wrong are recorded in the [validation addendum](#validation-addendum--independent-verification-pass-2026-08-03).

The naming across the completion route is asymmetric but internally consistent, and Callisto's application code creates no binding at all:

- Nova's protocol converter and generic relay publish with routing key `nova.proceeding.file.video-transcode-completed.v1`.
- Callisto's listener **consumes from a queue named** `callisto.proceeding.file.video-transcode-completed.v1` — a consumer-owned queue name, per the constant's own name `CALLISTO_..._INBOX_QUEUE` (`src/proceedings/constants.ts:17-19`).
- `buildRabbitSubscribeOptions` (`src/shared/inbox-events/inbox-listener.decorator.ts:21-29`) forwards only `queue`, `connection`, and `createQueueIfNotExists: false` to `RabbitSubscribe`. The decorator's `exchange`, `routingKey`, and `retryRoutingKey` **never reach RabbitMQ**; at runtime only `dlqExchange`, `dlqRoutingKey`, and `maxRequeueRetries` are read (`inbox-events.listener.ts:80-88`). Those three fields are declarative documentation of an infra-owned topology.
- In-app dispatch is keyed on the **envelope's event type**, which is Nova's: `ProceedingVideoTranscodeCompletedInboxHandler.eventType = NOVA_PROCEEDING_FILE_VIDEO_TRANSCODE_COMPLETED_V1.eventType`.

So the route is producer-namespaced routing key → infra-declared binding → consumer-namespaced queue → handler matched on the producer's event type. There is no code-level mismatch capable of breaking completion, and nothing about progress is being layered onto a broken route. What remains true and worth doing is ordinary infra hygiene: the exchange/queue bindings, retry, and DLQ topology live outside these repositories and should be confirmed against the deployed environment before new event types are added to them. That is a frontier item, not a precondition.

### 6. Callisto persistence and API — R5, R6, R8

`file_derivations` cannot represent an active run:

- Its statuses are terminal-oriented.
- `derived_file_id` is non-null.
- A row is created only after successful finalization.
- Existing file queries return only completed transcode derivatives.

Adding nullable percentage columns to that table would blur a requested process with a produced file and still fail before a derivative exists. A dedicated lifecycle model is the appropriate boundary.

The file DTO returned to Atlas has file and lineage fields but no transcode state. Both major file-list surfaces ultimately use the proceeding-files aggregation, giving the backend a single useful projection seam.

### 7. Atlas/Callisto UI — R6, R7

The inspected frontend has no EventSource/WebSocket client and no active-query polling for this data. The proceeding-files queries use a two-minute stale time and have no `refetchInterval`.

Two existing rows can host a shared status component:

- The read-only/AJSF `FileListItem` surface.
- `ProceedingFileTableDataRow` on proceeding details.

The initial submission redirect may require status in My Jobs as well. Product must either select that third surface or explicitly accept that users reach live status by opening the proceeding.

## Root cause

The root cause is the absence of a correlated, durable transcode-run lifecycle owned by Callisto and updated through the existing reliable event path. Current code models the request and final derivative, but not the process between them.

Contributing gaps are:

1. Nova's FFmpeg port discards structured progress.
2. The docking protocol defines requested/completed/failed but no intermediate lifecycle event.
3. Callisto does not persist an active run and does not consume proceeding failures into user-visible state.
4. ~~The completed listener appears to bind a routing key that differs from Nova's published type.~~ **Withdrawn 2026-08-03 — not a gap.** The application binds nothing; the completion route is consistent (§5, validation addendum). What is genuinely outside these repositories is the exchange/queue/retry/DLQ topology itself.
5. The API and UI contain no status projection or conditional refresh behavior.
6. Current relay defaults require explicit event coalescing and capacity validation.

## Alternatives considered

| Alternative                                                             | Decision              | Reason                                                                                                                                              |
| ----------------------------------------------------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Parse FFmpeg stderr `time=`                                             | Reject                | Human-oriented, formatting-sensitive, mixed with diagnostics, and brittle across chunk boundaries/version changes.                                  |
| Publish every FFmpeg progress block                                     | Reject                | Default cadence would multiply durable event volume without improving the user-perceived update rate.                                               |
| Publish directly from the Nova worker to RabbitMQ                       | Reject                | Bypasses the established outbox, loses restart durability, and couples a one-shot conversion task to broker availability.                           |
| Add Nova HTTP/SSE or WebSocket endpoint                                 | Reject for this scope | Nova is a one-shot task with no serving lifecycle, and neither Callisto nor Atlas has an existing push channel for this feature.                    |
| Poll CloudWatch/worker logs                                             | Reject                | Treats telemetry as product state, has poor correlation/latency, and is the kind of operational workaround this investigation is intended to avoid. |
| Share a database/snapshot store across services                         | Reject                | Introduces cross-service persistence coupling and conflicting ownership.                                                                            |
| Durable progress events + Callisto run table + conditional REST polling | Recommend             | Extends current outbox/inbox conventions, survives reconnects, and limits new infrastructure.                                                       |
| Add Callisto push delivery later                                        | Defer                 | Reconsider only if measured polling cannot meet the approved freshness/load target or a shared push capability is adopted platform-wide.            |

### Investigation decision log

These are scope recommendations, not implementation approvals.

| Decision                                                                        | Status                            | Requirement link |
| ------------------------------------------------------------------------------- | --------------------------------- | ---------------- |
| Use FFmpeg `-progress`/`out_time_us`; never parse stderr statistics.            | Recommended                       | R2, R11          |
| Represent the end-to-end lifecycle in a dedicated Callisto run model.           | Recommended                       | R1, R3, R5, R8   |
| Carry bounded snapshots through the existing durable event path.                | Recommended                       | R4, R9, R11      |
| Reserve 100% for Callisto derivative commit, not FFmpeg exit.                   | Recommended                       | R3, R6           |
| Begin with active-only REST polling and a measurable freshness SLO.             | Recommended with product/SRE gate | R4, R6           |
| Treat capacity, retention, and finalization exhaustion as prerequisites.        | Required gate                     | R4, R8, R9       |
| Confirm deployed exchange/queue/retry/DLQ topology before adding an event type. | Recommended (not blocking)        | R4, R9           |
| Build WebSocket/SSE, log polling, or direct worker-to-broker delivery.          | Rejected/deferred                 | R11              |

## Recommended design

### A. Lifecycle model — R1, R3, R5, R8

Create a Callisto `video_transcode_runs` model keyed by the original request/outbox event ID. Suggested fields for specification review:

- `origin_event_id` / run ID (UUID, primary correlation key)
- `source_file_id`, `proceeding_id`, `job_id`, selected transcode/preset
- `status` or `stage`: `queued`, `preparing`, `transcoding`, `finalizing`, `completed`, `failed`
- nullable `progress_percent`
- monotonic `sequence`
- `started_at`, `latest_event_at`, `completed_at`, `failed_at`
- nullable stable `failure_code`; protected diagnostic reference separately from user text
- nullable resulting derivative ID
- created/updated timestamps and indexes for active/latest-by-source queries

Naming precedent: `file_derivations` already carries a `processing_run_id` varchar column, so a run-correlation concept exists in the schema vocabulary even though the table cannot host an active run. Align the new model's correlation field with that name rather than inventing a third term.

Callisto must create `queued` atomically with the requested outbox event for both initiation paths. If either write fails, neither should commit.

Callisto update rules:

- Apply an event only when its sequence is newer than the stored sequence.
- Never move backward to an earlier stage or lower percentage.
- Ignore progress after `completed` or `failed`.
- Make terminal updates idempotent.
- If contradictory terminal events appear, keep the first committed terminal outcome and raise an operational signal.
- Treat active source-file deletion as a guarded operation or define a deterministic cancellation/failure policy; current finalization depends on resolving that source file.

### B. Nova FFmpeg observation — R2, R3

Extend the transcoder port with a domain progress callback/observer rather than leaking child-process chunks outside the adapter. The adapter should:

1. Add `-progress pipe:1`, `-nostats`, and an approved `-stats_period` while preserving preset/output argument semantics. This is achievable **without touching either preset**: each preset returns the complete argument vector (`-y -i <src> … <out>`), and the three additions are global options that can be prepended by the adapter. The adapter is therefore the correct and sufficient seam. `stdout` is already piped and consumed only for logging, so `pipe:1` is free — no output media travels on it.
2. Parse newline-delimited `key=value` records correctly across arbitrary stdout chunks.
3. Emit only after a complete progress block.
4. Use `out_time_us` and the already-probed total duration.
5. Handle `N/A`, missing, zero, or invalid duration as indeterminate progress.
6. Clamp numeric progress and maintain monotonicity.
7. Keep stderr as protected diagnostics and exit-code evidence, not user state.

Suggested semantic transitions from `VideoConversionService`:

- Request claimed/materialization begins: `preparing`
- FFmpeg begins: `transcoding`, 0 or indeterminate
- FFmpeg exits successfully and output persistence begins: `finalizing`
- Nova output persisted: existing completed event; Callisto remains `finalizing` until its own derivative transaction commits
- Any Nova exception: existing failed event with a stable failure code

Avoid exposing every internal step to users. `preparing` intentionally covers materialize/validate/probe, while logs and traces retain engineering detail.

### C. Progress contract and coalescing — R4, R9, R11

Add a versioned protocol event such as:

`nova.proceeding.file.video-transcode-progressed.v1`

Proposed data:

- `originEventId`
- `proceedingId`, `jobId`, `fileId`
- `sequence`
- `stage`
- nullable `progressPercent`
- optional `processedDurationMs` and `totalDurationMs` for diagnostics/future use
- `occurredAt`

The event carries state, not English UI text. Each emitted message gets a deterministic/idempotent event ID derived from origin ID plus sequence.

Nova should coalesce parser callbacks before writing to the outbox:

- Emit stage changes immediately.
- During transcoding, emit only after at least one percentage-point increase **and** at least five seconds since the previous percentage event.
- Always preserve terminal completed/failed events separately.
- Enforce an absolute maximum of 100 percentage events per job.

The stdout read path must not wait on a durable write for every FFmpeg callback. The coalescer should serialize accepted snapshots through a bounded publisher, observe publisher failures, and flush all accepted writes before the task emits a terminal event and exits. This avoids backpressuring FFmpeg while preserving the ordering boundary.

These are safe starting bounds, not validated production capacity. Actual peak concurrency and relay backlog data may require a longer cadence, larger relay/inbox capacity, or both.

### D. Callisto consumers and finalization — R5, R8, R9

Add proceeding listeners/handlers/services for progressed and failed events using protocol event-type constants as routing keys. Pass the completed event envelope ID into the completion service so it can correlate the run; the current handler discards the envelope.

Completion processing should leave the run at `finalizing` while it copies and validates the Nova output. The transaction that persists the derivative should also mark the run `completed`, link the derivative, and set 100%. A retryable copy/DB error remains `finalizing`; the inbox's permanently exhausted failure path needs an explicit policy that marks the run failed or alerts/repairs it. Silent indefinite finalizing is not acceptable.

Nova failures should set a stable machine code such as validation, transcode, output-persist, or internal failure. Callisto maps that code to safe UI language. Raw error detail remains restricted to logs/telemetry.

### E. API and frontend — R6, R7

Extend the proceeding-file projection with the latest transcode-run summary rather than requiring one request per file. Atlas then extends its `ProceedingFileDTO` and renders one reusable status component in both existing file-row families.

The two HTTP surfaces that currently return proceeding files do **not** have equivalent authorization:

- `GET /proceedings/:proceedingId/files`, used by proceeding detail, applies `ProceedingsProceedingIdParamRestrictionViewGuard`.
- `GET /proceeding-job-submission/proceedings/:proceedingId/files`, used by AJSF, is globally authenticated but explicitly has no endpoint-level restriction or job-task-ownership guard.

Therefore, “share the projection” must not become “blindly add status to both responses.” The proceeding-detail endpoint can extend its guarded response. The LTR/AJSF view should use a job-task-owner-scoped status read, an ownership-guarded form projection, or equivalent authorization. If My Jobs is selected as the immediate post-submit surface, it also needs a batch/aggregate summary rather than per-file N+1 calls. The audience, URL, and flag decisions are enumerated in `../ffmpeg-transcode-status-design-decisions.md`.

Recommended display behavior:

| State         | UI copy                                                  | Progress control                                |
| ------------- | -------------------------------------------------------- | ----------------------------------------------- |
| `queued`      | Queued for conversion                                    | Indeterminate                                   |
| `preparing`   | Preparing video                                          | Indeterminate                                   |
| `transcoding` | Converting video — `{percent}%`                          | Determinate when known; otherwise indeterminate |
| `finalizing`  | Finalizing converted file                                | Indeterminate; never show 100 yet               |
| `completed`   | Conversion complete                                      | 100%; converted derivative row is available     |
| `failed`      | Conversion failed. The original file is still available. | Terminal error state, no raw diagnostic         |

Use localized strings and an accessible text status in addition to color/progress graphics. Keep the original file row visible throughout; the converted derivative appears through existing behavior after completion.

Use conditional Vue Query polling as the first delivery mechanism:

- Approximately every two seconds only while the returned proceeding contains an active run.
- Do not poll in the background by default.
- Stop after all visible runs are terminal.
- Immediately refetch after a local upload/request succeeds.

The two-second UI interval does not make backend data two seconds fresh; with five-second Nova outbox and Callisto inbox polls, an inferred end-to-end update can approach 10–12 seconds before processing. The proposed p95 ≤15-second acceptance target must be measured. If product means sub-second “live,” this architecture will not meet that meaning without broader push/transport work.

## Implementation location map — R10

No files in this section were changed by this investigation.

### Docking protocol package

- Add and export the versioned progressed event schema/type/constant.
- Define stage enum, correlation, sequence, timestamps, and nullable percentage rules.
- Add schema compatibility and serialization tests.
- Keep completed/failed v1 contracts compatible; Nova can populate the existing nullable `errorCode`.

### `nova-back-end`

- `TranscoderPort`: introduce domain progress reporting.
- `FfmpegAdapter`: structured progress flags, streaming parser, error separation, and unit tests.
- `TranscodeStep` / `VideoConversionService`: pass duration, publish lifecycle stages, and preserve terminal behavior.
- Outbox domain/port/assemblers/converters/module registration: add progressed events and deterministic IDs.
- Add a coalescer with cadence/count limits and metrics.
- Tests: fragmented/multiple stdout chunks, CRLF, `N/A`, unknown/zero duration, monotonic clamp, >100%, nonzero exit, callback failure isolation, stage ordering, coalescing, and event correlation.

### `nova-orbital-back-end`

- No event-specific publisher is expected because the relay is generic.
- Validate/tune deployed outbox poll interval, batch size, task concurrency, alarms, and retention for the added traffic.
- Confirm the new event routes by exact protocol event type and does not starve completed/failed events.

### `callisto-back-end`

- Add migration/entity/repository/service for `video_transcode_runs`.
- Create `queued` runs atomically in both existing request writers.
- Add progressed and failed proceeding listener/handler/service registration. Follow the existing convention: consumer-namespaced queue constant, handler `eventType` set from the **protocol constant of the publishing system**, and infra-owned bindings.
- Confirm — do not "correct" — the deployed completed-event topology; the application code is consistent (§5).
- Pass completion envelope correlation into finalization and commit derivative + run terminal state together.
- Implement sequence/terminal conditional updates and stable failure-code mapping.
- Project the latest run through proceeding file DTO/aggregation.
- Define stale-run detection, retention/cleanup, and permanently exhausted finalization behavior.
- Guard or explicitly handle deletion of an actively transcoding source.
- Add contract, transaction, idempotency, retry, routing, query, and negative-path tests.

### `atlas-front-end` (`src/callisto`)

- Extend generated/local proceeding file types with transcode state.
- Add a shared accessible `FileTranscodeStatus` component.
- Use it in `FileListItem` and `ProceedingFileTableDataRow`.
- Add localized state/failure strings and progress semantics.
- Add conditional active-only query polling and an immediate post-request refetch.
- Decide whether My Jobs must also expose active status after initial submit.
- Test each state, indeterminate/determinate behavior, polling start/stop, refresh restoration, concurrent files, failure copy, and accessibility.

### Deployment/operations/documentation

- Release the docking protocol before producers/consumers use the new event.
- Deploy tolerant Callisto consumer/schema first, then Nova producer, then Atlas presentation behind a feature flag.
- Add outbox/inbox lag, queue depth, active/stale run, terminal rate, progress-volume, and invalid-transition metrics/alerts.
- Define retention/TTL for progress outbox/inbox records and lifecycle rows.
- Add a runbook for stale `preparing`/`transcoding`/`finalizing`, missing terminal events, and reconciliation.

## Capacity and operational analysis — R4, R9

Current inspected defaults:

- Nova outbox poll: 5 seconds, batch 20.
- Callisto generic inbox default: 5 seconds, batch 20.
- Relay attempts: four by default.
- No repository-local retention/cleanup policy was found for the relevant Nova outbox or Callisto proceeding inbox.

The recommended coalescing bound produces at most 100 percentage records plus a small number of stages per job. That is bounded but not automatically safe. Before implementation approval, measure:

- Peak and p95 concurrent conversions.
- p50/p95/p99 conversion duration.
- Existing shared outbox/inbox traffic and oldest-event lag.
- Resulting database row growth and retention cost.
- Poller service time and RabbitMQ queue depth at 2× expected peak.
- Atlas API request increase when many users watch active proceedings.

If supported concurrency is 15 active jobs, one progress event per five seconds consumes about three events/second before stage and other events—already most of the nominal four-events/second Nova relay rate. This is an illustrative bound, not a measured safe capacity.

## Failure and race semantics — R8, R9

| Scenario                                           | Required result                                                                               |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Validation fails before FFmpeg                     | `preparing → failed`; safe code/copy, original remains.                                       |
| FFmpeg exits nonzero after partial progress        | Latest percentage may remain diagnostically, but UI becomes terminal `failed`.                |
| Nova output upload fails                           | `finalizing → failed` through Nova's terminal event.                                          |
| Callisto output copy/DB transiently fails          | Remain `finalizing`, retry idempotently, expose no false completion.                          |
| Callisto finalization permanently exhausts retries | Explicitly mark failed/reconciliation-required and alert; never silently stay active forever. |
| Duplicate progress                                 | Conditional update is a no-op.                                                                |
| Older progress arrives after newer progress        | Ignore by sequence.                                                                           |
| Progress arrives after terminal                    | Ignore; terminal wins.                                                                        |
| Completed and failed conflict                      | First committed terminal result remains; alert and investigate.                               |
| Missing intermediate events                        | Next snapshot/stage or terminal event converges state; percentage can jump.                   |
| Unknown duration / `N/A`                           | Show indeterminate `transcoding`, not fabricated 0% or division error.                        |
| Multiple files in one proceeding                   | Independent correlation and state for each source file.                                       |
| Browser refresh/offline period                     | Rehydrate from Callisto's durable latest state.                                               |
| Source deleted during active run                   | Backend guard or explicit failure policy; never orphan finalization silently.                 |

## Validation plan

### Static/contract validation

- Verify exact event type constants in protocol source, producer, and handler registry. Note that in-app dispatch matches the **envelope event type**, not the routing key, and that queue names are consumer-namespaced by convention — do not treat a name difference between the two as a defect (§5 correction).
- Confirm the bundled FFmpeg supports the required options inside the same container image used in production. This is now confirmatory: the shipped binary has already been inspected (§2, A5).
- Prove request-event and queued-run writes share one transaction in both initiation paths.
- Prove derivative creation and completed-run update share one transaction.
- Prove no API field can expose raw `errorMessage` or stderr.

### Automated validation

- Parser unit tests use realistically fragmented byte chunks and multiple progress blocks per chunk.
- Domain tests prove stage order, percentage calculation, coalescing, terminal priority, and callback isolation.
- Consumer tests deliver duplicates and all relevant permutations of out-of-order progress/completed/failed.
- API tests cover no run, each active state, terminal states, multiple runs, and latest-run selection.
- Frontend tests use fake timers to prove polling begins/stops and status survives refetched data.
- End-to-end test drives a short sample video through request, visible progress, Callisto finalization, and derivative appearance.
- Negative end-to-end tests inject FFmpeg, Nova output upload, Callisto copy, and final DB failures.

### Load/operational validation

- Replay 2× expected peak concurrent progress volume through both pollers.
- Demonstrate p95 visibility freshness meets the approved target without terminal starvation.
- Confirm queue/outbox/inbox oldest-event lag returns to steady state after burst.
- Exercise worker/task termination and poller restart; verify durable convergence.
- Validate cleanup/TTL cannot delete records required by an unprocessed consumer or active run.

### Observability

Correlate all logs/metrics with `originEventId`, file ID, stage, and sequence. Track:

- Active runs by stage and age.
- Progress events created, coalesced, relayed, applied, ignored as duplicate/old, and received after terminal.
- Nova outbox and Callisto inbox depth/oldest age.
- Time from request → preparing → first percentage → Nova completion → Callisto completion.
- Failure counts by stable code and permanently exhausted finalization.
- Stale-run count above approved thresholds.

Fastest feedback is a local/container integration test with a small fixture; the authoritative gate is a deployed sandbox run through real outbox, RabbitMQ, inbox, S3 copy, API, and browser polling. Capacity validation must follow with representative concurrency before production rollout.

## Assumptions ledger

| ID  | Claim                                                                                                                                                                                                                                                                         | Basis                                                                                                                                                    | Consequence if false                                                                                  | Validation/owner                            |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| A1  | Callisto should own user-queryable lifecycle state.                                                                                                                                                                                                                           | It creates the request and serves the UI/API.                                                                                                            | Ownership/API design changes materially.                                                              | Callisto architecture owner.                |
| A2  | Existing outbox/inbox transport is the required durable path.                                                                                                                                                                                                                 | Current request and terminal events use it.                                                                                                              | A broader platform transport decision is needed.                                                      | Platform owner.                             |
| A3  | Eventual updates around 15 seconds can qualify as “live.”                                                                                                                                                                                                                     | Inferred from two five-second pollers plus UI polling.                                                                                                   | Push or poller redesign may be required.                                                              | Product + SRE.                              |
| A4  | FFmpeg `out_time_us / duration` is sufficiently representative of conversion progress.                                                                                                                                                                                        | Official structured output plus existing duration probe.                                                                                                 | UI may need indeterminate-only or a different metric.                                                 | Nova owner; sample validation.              |
| A5  | The bundled FFmpeg build supports `-progress`, `-stats_period`, and `out_time_us`.                                                                                                                                                                                            | **Upgraded 2026-08-03 to evidenced.** `Dockerfile:18-22` ships `./bin/ffmpeg` as `/usr/local/bin/ffmpeg`; that binary contains all three option strings. | Flags/parser must adapt to the deployed build.                                                        | Confirmatory container run only.            |
| A6  | A five-second percentage cadence is acceptable.                                                                                                                                                                                                                               | Balances UX with current relay defaults.                                                                                                                 | Capacity or UX bounds must be retuned.                                                                | Product + SRE load test.                    |
| A7  | Proceeding file surfaces are primary status locations.                                                                                                                                                                                                                        | Both current file views share the relevant file projection.                                                                                              | Additional My Jobs/global API and UI scope is needed.                                                 | Product/UX.                                 |
| A8  | The original file remains usable after a failed transcode.                                                                                                                                                                                                                    | Current derivative model does not replace it.                                                                                                            | Failure copy and recovery actions must change.                                                        | Callisto product owner.                     |
| A9  | Stable error codes can be assigned within existing failed v1 schema.                                                                                                                                                                                                          | `errorCode` is nullable string today.                                                                                                                    | Protocol versioning expands.                                                                          | Protocol + Nova owners.                     |
| A10 | ~~Production has no hidden routing-key rewrite for completion.~~ **Withdrawn 2026-08-03 — the premise was wrong; no rewrite is needed.** Replacement: the exchange/queue/retry/DLQ bindings that the listener config documents exist as declared in the deployed environment. | Decorator forwards only `queue`/`connection` to `RabbitSubscribe`; in-app dispatch is by envelope event type.                                            | Bindings must be created/extended when the progressed event is added — an infra task, not a redesign. | Messaging owner confirms deployed topology. |
| A11 | Conditional REST polling is acceptable initially.                                                                                                                                                                                                                             | Existing UI/API patterns and no push stack.                                                                                                              | Shared push infrastructure enters scope.                                                              | Atlas architecture owner.                   |
| A12 | Intermediate progress need not be exactly-once.                                                                                                                                                                                                                               | State snapshots plus monotonic sequence tolerate loss/duplicates.                                                                                        | Transport and producer complexity increases sharply.                                                  | Architecture review.                        |
| A13 | Source deletion can be guarded while active.                                                                                                                                                                                                                                  | Completion resolves the source file; deletion would jeopardize finalization.                                                                             | A cancellation/orphan strategy is required.                                                           | Product + Callisto owner.                   |
| A14 | Protocol consumer can deploy before producer.                                                                                                                                                                                                                                 | Additive event and tolerant schema migration.                                                                                                            | Rollout needs dual-write/version bridge.                                                              | Release owner.                              |

## Decision gates

Implementation should not begin until owners resolve these variables:

**Revised 2026-08-03.** The original list had nine gates. Gate 1 was withdrawn (the routing finding it rested on does not hold) and gate 5 was closed by direct inspection of the shipped binary. Four gates genuinely change the design and are listed first as blocking; the rest are spec inputs to resolve during specification, not before it.

**Blocking — these change the design:**

1. **Freshness — Product/SRE:** Approve a measurable “live” SLO; accept or reject the proposed p95 ≤15 seconds. If Product means sub-second, the recommended architecture does not apply.
2. **Capacity — Nova/SRE:** Supply peak concurrency/duration/backlog data and approve coalescing plus poller capacity with headroom.
3. **Terminal semantics — Callisto/SRE:** Define stalled thresholds, permanently exhausted finalization behavior, reconciliation, and source deletion behavior.
4. **Experience — Product/UX:** Select exact surfaces, approve copy/accessibility behavior, decide completed-state persistence, and decide whether My Jobs must show active state after redirect.

Experience approval must include the actor/authorization matrix: assigned LTR, other LTR, authorized internal user, insufficient-restriction user, and feature-flag-off viewer. The companion design register recommends My Jobs summary + ownership-scoped submitted-form detail for the LTR and the restriction-guarded proceeding-detail view for internal users.

**Resolve during specification — inputs, not gates:**

5. **Data lifecycle — Platform/data owners:** Approve retention/TTL for progress outbox/inbox data and lifecycle rows.
6. **Contract/release — Protocol/platform:** Confirm protocol repository ownership, event schema, package order, feature flag, and rollback sequence.
7. **Messaging topology — Messaging owner:** Confirm the deployed exchange/queue/retry/DLQ bindings and add the progressed event's binding. _(Downgraded from blocking gate 1; see §5 correction and the validation addendum.)_
8. **User evidence — Product:** Add a named observed user/job instance and urgency/release trigger rather than relying only on technical inference.

**Closed:**

9. ~~**FFmpeg compatibility — Nova:** Record the bundled binary version and run a container feature test for structured progress.~~ **Closed 2026-08-03** by inspecting the binary the Dockerfile ships (§2, A5). A container run remains a confirmation step in the validation plan.

## Handoff table

| Work item                                   | Owner role            | Done when                                                                                                                                                                                |
| ------------------------------------------- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Approve UX surface, audience, and freshness | Product/UX + Security | R6/R7 behavior, actor/route authorization matrix, feature-flag visibility, and numeric SLO are signed off.                                                                               |
| Confirm messaging topology                  | Callisto/messaging    | Deployed exchange/queue/retry/DLQ bindings for the completed route are documented, and the progressed event's binding is added. _(Was "resolve routing baseline"; rescoped 2026-08-03.)_ |
| Specify protocol                            | Protocol/platform     | Progressed v1 schema, sequence rules, compatibility, and package release plan are approved.                                                                                              |
| Specify Nova changes                        | Nova                  | Parser, domain observer, stages, coalescer, codes, metrics, and tests have file-level design and estimates.                                                                              |
| Validate capacity                           | Nova/Callisto SRE     | 2× expected peak meets freshness and terminal-starvation criteria with retention calculated.                                                                                             |
| Specify Callisto lifecycle                  | Callisto              | Schema, transactions, consumers, conflict/stale/failure rules, API projection, and migrations are reviewed.                                                                              |
| Specify Atlas presentation                  | Atlas                 | Shared component, polling, surfaces, accessibility, and tests are reviewed.                                                                                                              |
| Validate end-to-end                         | Cross-team QA         | Sandbox proves happy, failure, duplicate/out-of-order, restart, refresh, and multiple-file paths.                                                                                        |
| Approve rollout                             | Release owner         | Consumer-first deployment, producer enablement, UI flag, metrics, rollback, and runbook are ready.                                                                                       |

## Final recommendation

Proceed to a cross-repository implementation specification only after the decision gates are closed. The smallest professional wedge is not “draw a progress bar”; it is:

1. structured FFmpeg progress in Nova,
2. a bounded versioned progress event,
3. a durable Callisto transcode-run lifecycle with failure and terminal guarantees, and
4. an active-only polling presentation shared by existing file surfaces.

That wedge preserves current service ownership and delivery patterns while creating a foundation that can later support retry, cancellation, ETA, or push delivery without rebuilding progress semantics. No production implementation was performed as part of this investigation.

Before writing that specification, resolve the Before-spec rows in `../ffmpeg-transcode-status-design-decisions.md`; they are the product and security choices the codebase cannot decide.

---

## Validation addendum — independent verification pass (2026-08-03)

**What this is:** a second pass that re-opened the primary sources behind this report's load-bearing claims. The recommended architecture survived; two findings did not. Sections above have been corrected in place with dated markers so no reader inherits a withdrawn finding, and this addendum records what changed and why.

**Baselines re-inspected:** `callisto-back-end` `3ecab1b8` (`PRDV-16402-reland`), `nova-back-end` `58a6182` (`PRDV-16398`), `nova-orbital-back-end` `bfd5094`, `atlas-front-end` `102e034d`. No file in any repository was modified.

### Verdict on the approach

**Confirmed.** The reframe from "read FFmpeg's percentage" to "there is no durable representation of a transcode between request and derivative" is correct, and the four-part wedge follows from it. Every rejected alternative is rejected for a reason that holds. Proceed to specification.

### Withdrawn — the routing-key mismatch (was §5 "blocking baseline issue", root cause 4, decision gate 1, A10)

**Claimed:** Nova publishes `nova.proceeding.file.video-transcode-completed.v1`; Callisto's listener binds `callisto.…`; the completion route must be proved or corrected before progress is layered on it.

**Why it does not hold:**

| Evidence                                                      | Finding                                                                                                                                                        |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `inbox-listener.decorator.ts:21-29`                           | `buildRabbitSubscribeOptions` forwards only `queue`, `connection`, `createQueueIfNotExists: false`. `exchange` and `routingKey` never reach `RabbitSubscribe`. |
| `inbox-events.listener.ts:80-88`                              | The only config fields read at runtime are `dlqExchange`, `dlqRoutingKey`, `maxRequeueRetries`. `routingKey` and `retryRoutingKey` are never read anywhere.    |
| `src/proceedings/constants.ts:17-19`                          | The constant is `CALLISTO_..._INBOX_QUEUE` — a queue name, not a binding. Consumer-namespaced by convention.                                                   |
| `proceeding-video-transcode-completed-inbox.handler.ts:13-14` | `eventType = NOVA_PROCEEDING_FILE_VIDEO_TRANSCODE_COMPLETED_V1.eventType`. Dispatch is by envelope event type; the routing key plays no part.                  |

The application creates no binding and asserts none (`createQueueIfNotExists: false`). Bindings are infra-owned. A consumer-namespaced queue fed by a producer-namespaced routing key is the intended design, not a defect.

**How the error was made — the reusable lesson.** A queue name was read as a binding because the decorator field is _called_ `routingKey`. The field is real, the config is real, and the value is genuinely mismatched with Nova's — the missing step was checking whether anything **consumes** that field. One grep for its usages would have settled it. This is the same shape as the failures recorded in `docs/atlas/PRDV-16402/PRDV-16402-investigation-failure-analysis.md`: a plausible reading of a real artifact, promoted to fact, then built into a gate. **Extension worth adding to the method: when a config value is about to become load-bearing, verify it is read at runtime, not merely declared.**

**Consequence:** decision gate 1 removed; root cause 4 struck; A10's premise replaced; the handoff row rescoped from "resolve routing baseline" to "confirm messaging topology."

### Closed — FFmpeg compatibility (was decision gate 5, A5)

`Dockerfile:18-22` copies `./bin/ffmpeg` to `/usr/local/bin/ffmpeg`, the exact path `FfmpegAdapter` spawns, so the repository contains the production binary. That binary contains the option strings `progress`, `stats_period`, and `out_time_us`. The original framing ("not executable from Windows, therefore unverified") stopped one step short: the artifact was inspectable without executing it.

### Confirmed against source

| Claim                                                                 | Result                                                                                               |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Adapter discards progress; `TranscoderPort` returns `Promise<void>`   | Confirmed (`ffmpeg.adapter.ts:30-45`)                                                                |
| Duration is probed before transcode but not passed to `TranscodeStep` | Confirmed (`video-conversion.service.ts:113-125`) — the plumbing change in §B is real                |
| `file_derivations` cannot model an active run                         | Confirmed — `derived_file_id` non-nullable, statuses `completed`/`failed` only                       |
| No proceeding-level consumer for Nova's failed event                  | Confirmed repo-wide                                                                                  |
| No progressed event in the protocol                                   | Confirmed — requested / completed / failed only                                                      |
| Completed handler discards the envelope                               | Confirmed — `_envelope` explicitly unused                                                            |
| Atlas has no polling or push                                          | Confirmed — zero `refetchInterval`, zero `EventSource`/`WebSocket` in `src`; `TWO_MINUTES` staleTime |
| Nova outbox poll 5 s, batch 20                                        | Confirmed (`POLL_INTERVAL_MS: 5000`, `BATCH_SIZE: 20`)                                               |

### Added for completeness

1. **Presets need not change.** Each preset returns the full argument vector, and the three progress flags are global options the adapter can prepend. This strengthens rather than alters §B — the adapter is the sufficient seam, and `stdout` is already piped and carries no media.
2. **An internal failure-notification path already exists.** Nova's failure also writes a notification-requested event (`eventCode: VIDEO_TRANSCODE_FAILED`) that Callisto renders via `video-transcode-failed.template`, and the protocol ships `callisto.alert.nova-video-transcode-failed.v1`. §D's stable failure codes should align with that vocabulary. "No failure handling exists" would have overstated the gap; what is missing is durable user-visible failed state.
3. **`file_derivations.processing_run_id` is a naming precedent** for the run model's correlation key.
4. **Gate count.** Nine preconditions is heavy for a progress indicator and blurs "this changes the design" with "this is a spec input." Reduced to four blocking gates: freshness SLO, capacity, terminal semantics, surfaces.

### What this does not change

The problem classification, the plain-language problem statement, the recommended lifecycle and stage vocabulary, the reserved-100% rule, the coalescing bounds, the alternatives table, the failure/race semantics table, the implementation location map (apart from the two rescoped bullets), and the validation plan all stand as written.
