# Nova applies selected video transcode preset (Video Mix) - Original Ticket

## Capture Metadata

| Field | Value |
| --- | --- |
| Project | nova |
| Ticket slug / ID | PRDV-16398 / `nova-applies-selected-transcode-preset` |
| Captured on | 2026-07-28 |
| Source | Active ClickUp browser page |
| Formatting | Browser DOM converted to Markdown |
| URL | https://app.clickup.com/t/43227262/PRDV-16398 |
| Implementation repo | `C:\Users\dustin.thomason\nova-back-end` (git) |
| Capture relocated | Moved 2026-07-28 from `docs/atlas/PRDV-16398-original-ticket.md` to the canonical ticket folder under `docs/nova/`. Original Request unchanged. |

## ClickUp Location

MBL LIST > Sprint 2026-15 (7/22-8/4)

## Ticket Metadata

| Field | Value |
| --- | --- |
| Status | READY FOR WORK |
| Assignees | DT Dustin Thomason |
| Dates | Start Due |
| Priority | High |
| Sprint points | 2 |
| Tags | hot fix sprint addition |

## Omitted Fields

| Field | Reason |
| --- | --- |
| Time estimate | No visible value in the active ClickUp page |
| Track time | No visible value in the active ClickUp page |

## Activity And Comments

_Visible ClickUp activity and comments captured from the active browser page. Attachments and embedded media are not retrieved._

- **Activity:** Larry Adams created this task 2 hours ago

- **Activity:** Shaye Lankford added link to Transcode video files uploaded through AJSF 59 mins

## Original Request

## Summary

Product selected **Video Mix** in production; the returned file was encoded as ** Standard**.

Callisto is correct — the outbox event carries `videoTranscodeValue: "Video Mix"` (and `videoTranscodeId: 3`). Nova receives that value into `VideoJob.template` via `VideoJobAssembler`, but **never uses it**. `TranscodeStep` hardcodes `template1` (Standard) for every job. Nova has never had a second preset.

**Root cause:** Callisto half of PRDV-14800 shipped; Nova consumer half was never built.

**Fix scope:** `nova-back-end` only — preset registry keyed on `videoTranscodeValue`, wire `job.template` / `transcodeValue` into `TranscodeStep`, add Standard + Video Mix FFmpeg presets. No Callisto, docking-protocol, or infra changes.

**Spec:** [PRDV-16398-nova-applies-selected-transcode-preset.md](https://github.com/planetdepos/larry-adams/blob/main/systems/nebula/video-transcode/PRDV-16398-nova-applies-selected-transcode-preset.md)

**Origin:** [PRDV-14800](https://app.clickup.com/t/43227262/PRDV-14800)

## Developer note

Video Mix FFmpeg args are not in the codebase. Look up the existing HandBrake **Video Mix** preset (ops / Lit Tech) and translate into `vid-mix.preset.ts`. While there, confirm current `template1` still matches HandBrake ** Standard**; fix in the same PR if it drifts.

Key on `videoTranscodeValue` (display label), **not** `videoTranscodeId` — IDs were renumbered historically and are not a stable contract.

Unknown / empty values: fall back to Standard + `warn` log with `requestedValue` and `appliedPreset`.

## Acceptance criteria

- Given a `callisto.proceeding.file.video-transcode-requested.v1` event with `videoTranscodeValue: "Video Mix"`, Nova encodes with the Video Mix FFmpeg preset (not Standard).
- Given the same event type with `videoTranscodeValue: "Standard"`, Nova encodes with the Standard FFmpeg preset and output matches today's `template1` behaviour (no regression).
- Structured logs for every job include the applied preset value on start and completion.
- Given an unrecognised or empty `videoTranscodeValue`, Nova falls back to Standard and emits a `warn` log with both `requestedValue` and `appliedPreset`.
- Unit tests assert that `'Video Mix'` and `'Standard'` resolve to distinct preset arg builders, and that the registry keys are exactly `['Standard', 'Video Mix']` (rename without Nova update fails CI).
- No Callisto, docking-protocol, or infrastructure changes are required for this fix.

## Verification

After deploy, re-process / replay the known prod case (`fileId: 666549`, `jobId: 644345`) and confirm with Product the output matches Video Mix expectations.

## Explicit Constraints In Original Request

_Quoted from the Original Request section above; not paraphrased._

- "**Fix scope:** `nova-back-end` only" — "No Callisto, docking-protocol, or infra changes."
- "Key on `videoTranscodeValue` (display label), **not** `videoTranscodeId` — IDs were renumbered historically and are not a stable contract."
- "Unknown / empty values: fall back to Standard + `warn` log with `requestedValue` and `appliedPreset`."
- "Video Mix FFmpeg args are not in the codebase. Look up the existing HandBrake **Video Mix** preset (ops / Lit Tech)."
- "While there, confirm current `template1` still matches HandBrake ** Standard**; fix in the same PR if it drifts."
- Acceptance criterion: "the registry keys are exactly `['Standard', 'Video Mix']` (rename without Nova update fails CI)."

## Context Paths In Original Request

- Coworker spec (read-only): `larry-adams/systems/nebula/video-transcode/PRDV-16398-nova-applies-selected-transcode-preset.md`
- Origin ticket: [PRDV-14800](https://app.clickup.com/t/43227262/PRDV-14800)
- Linked by Shaye Lankford in activity: "Transcode video files uploaded through AJSF"
- Production case named for verification: `fileId: 666549`, `jobId: 644345`

## Downstream Artifacts

- Orchestration ledger: `orchestration.md`
- Ticket changelog: `docs/nova/PRDV-16398-changelog.md`
- Why these changes (living): `PRDV-16398-why-these-changes.md`
- Investigation: `investigations/PRDV-16398-investigation.md`
- Coverage ledger: `investigations/PRDV-16398-coverage-ledger.md`
- Diagrams: `investigations/PRDV-16398-diagrams.md`
- Test plan: `testing/PRDV-16398-test-plan.md` (status: seeded)
- Future-development concerns: `PRDV-16398-future-development-concerns.md`
- PR draft: `PRDV-16398-pr-draft.md` (unfilled shell)
- Spec: Not created yet (Phase 3)
- Q and A ledger: Not created yet (Phase 3 — `specs/PRDV-16398-locked-decisions.md`)
