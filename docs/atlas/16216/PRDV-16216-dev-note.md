---
ticket: PRDV-16216
tags: [nova, media-duration, video, transcode, dev-note]
author: Dustin Thomason
created: 2026-07-13
modified: 2026-07-13
---

# PRDV-16216 — Dev note (Nova story)

> **SUPERSEDED, 2026-07-14** — see `PRDV-16216-lookup-display-investigation.md`; 16216 is now a Callisto read-time lookup and this Nova story was replaced by a separate validation ticket (probe + compare + fail; no protocol change, so the dependency and estimate below no longer apply).

**Full spec:** [[PRDV-16216-nova-emits-transcoded-output-duration]]

## What we're building

Nova probes the **transcoded output's** media duration after transcoding (it currently probes only the input and discards the value) and emits it as an optional `duration` field (integer whole seconds) on the `video-transcode-completed.v1` event. Complexity lives in the release choreography, not the code: the field must land in `orbital-docking-protocol` and be published before Nova can compile against it.

## Dependencies

- `orbital-docking-protocol` publish with optional `duration` on `NovaProceedingFileVideoTranscodeCompletedV1Data` — **before or alongside** this PR
- Version-anomaly reconciliation first: Nova repos declare `^1.0.5`, installed package reports `0.2.13`
- Downstream (does not block this story): Callisto companion story persists `duration` → `files.length`; Atlas needs nothing

## Backend

- **New endpoints** — none (event/outbox only)
- **New tables** — none (Nova has no relational store)
- **Modified tables** — none
- **New migrations** — none
- **Modified classes** — 4: `VideoConversionService` (output probe + threading), `VideoConversionOutboxWriterPort` (signature), `VideoConversionOutboxWriterAssembler` (forwarding), `VideoJobToCompletedOutboxDescriptorConverter` (payload mapping)
- **New classes / registries / wiring** — none; reuses `ProbeDurationStep`/`FfprobeAdapter` as-is

## Frontend

None — the Atlas Length column already renders any media file with a populated `length` (PRDV-9756 + PRDV-15875, merged); derivative filenames are always `.mp4`.

## Complexity flags

- Protocol publish gate: typed payload won't compile until the package version with `duration` is pinned
- Probe failure must be non-fatal (enrichment, not a delivery requirement) — needs deliberate error-path assertions
- `createMockVideoJob` shared test factory ripples across the touched spec files
- Parity rationale must survive review: value is probed from the output, never copied from the source

## Estimate

**Small–Medium (2–3 points).** Four-file threading change with existing utilities reused and no new infrastructure — but cross-repo release choreography (protocol publish + version pin) adds coordination overhead beyond a pure Small.
