---
ticket: PRDV-16398
tags: [nova, nebula, video-transcode, ffmpeg, presets, concerns]
author: Dustin Thomason
created: 2026-07-28
modified: 2026-07-28
---

# PRDV-16398 — Future-development concerns (transcode preset observability and vocabulary durability)

> **Context:** PRDV-16398 makes Nova apply the transcode preset the customer selected, resolving `videoTranscodeValue` against a two-entry registry with a Standard fallback. These concerns attach to what that fix deliberately does **not** cover — chiefly that a fallback is invisible to every system downstream of Nova.
> **Purpose of this document:** a dated, code-verified record that these risks were identified and raised — for team discussion and, where needed, escalation.
> **Constructive path forward:** Concern 1 is closed by adding an applied-preset field to the Nova completed-event contract (three repos, deploy-ordered). Concern 2 is partly mitigated in-scope by the registry contract-guard test. Concern 3 is closed by whatever PRDV-16398's Phase 3 rules on the AJSF producer.

## Executive summary (for escalation)

**The vulnerability:** after this fix, when Nova receives a transcode value it does not recognise, it will encode with Standard and continue — by design, because failing the job would deny the customer a usable deliverable. But **nothing outside Nova's own logs can tell that a substitution happened.** Nova's completed event forwards the *requested* value verbatim; there is no field on the contract for the preset actually applied. Callisto stores it, Atlas displays it, and Product reviews the file — all three believing the customer's selection was honoured.

**Why it matters even if rare:** this is precisely the failure mode PRDV-16398 exists to fix, reintroduced one level up. The original bug was invisible for the entire life of the feature — from PRDV-14800's ship date until Product happened to notice a wrong-looking deliverable — because no signal existed. A fallback leaves the same shape of blind spot: correct-looking metadata over a wrong encode, discoverable only by a human eye on the video or an engineer grepping CloudWatch. The cost is not a failed job; it is a delivered artifact that everyone believes is right.

**The decision requested,** from whoever owns the `orbital-docking-protocol` contract:

- **(a)** Add an optional `appliedVideoTranscodeValue` to `nova.proceeding.file.video-transcode-completed.v1`, and have Callisto persist it. Optional keeps historical replay parsing. Cost: three repos, deploy ordering, a companion ticket.
- **(b)** Accept log-only detection and add a CloudWatch alarm on the `warn` (`requestedValue` ≠ `appliedPreset`). Cheap, no contract change, but detection depends on alarm hygiene rather than data.
- **(c)** Accept the risk unmitigated. Defensible **only while Callisto's two-value gate remains the sole producer** — see Concern 3, which is exactly the assumption that may already be untrue.

**Recommendation:** (b) now, (a) as a companion ticket. Do not choose (c) until Concern 3 is settled.

## Concern 1 — A preset fallback is invisible to every system downstream of Nova

Nova's completed-event descriptor spreads the inbound payload verbatim into the outbound event, so `videoTranscodeValue` on the completed event is always the value that was *requested*, never the preset that was *applied*. The contract has no field for the latter. If Nova substitutes Standard for an unrecognised value, Callisto persists the original selection, Atlas renders it, and no downstream consumer can distinguish an honoured selection from a substituted one.

The `warn` log added by PRDV-16398 is therefore the **only** channel through which a fallback is observable — and Nova is a one-shot Fargate task with no user present (`video-conversion-task.handler.ts` — `onModuleInit` → `process.exit`), so there is no interactive surface where it could surface instead.

- **Evidence (verified 2026-07-28):** `nova-back-end/src/video-conversion/infrastructure/outbox/assemblers/video-conversion-outbox-writer-assembler/video-job-to-completed-outbox-descriptor.converter.ts:16-24` — `forwardedPayload` spread into `completedData`, only `transcodedbucketName` / `transcodedfilePath` overridden. Contract shape: `@planetdepos/orbital-docking-protocol@1.0.5` `NovaProceedingFileVideoTranscodeCompletedV1Data` — carries `videoTranscodeValue` and `videoTranscodeId`, no applied-preset field.
- **What would resolve it:** option (a) above — an optional `appliedVideoTranscodeValue` on the completed event, written from `ResolvedPreset.presetValue`, persisted by Callisto. Smallest interim step: option (b), a CloudWatch alarm on the fallback `warn`.
- **Cross-reference:** investigation report §8 (A7), §10 (D2).

## Concern 2 — The vocabulary contract is enforced by one test, and the authority can change without notice

Nova's registry keys must mirror the exact string values in `callisto.video_transcodes`. Nothing structural enforces that mirror: the wire contract types `videoTranscodeValue` as a bare `string` rather than a union, so the compiler cannot help, and the values are **database rows** rather than code — Atlas fetches the dropdown options at runtime, so a new or renamed row becomes selectable with no code change in any repo.

PRDV-16398's contract-guard spec (registry keys equal exactly `['Standard', 'Video Mix']`) catches a **rename** at CI time in Nova. It does **not** catch an **addition**: a new row plus a widened Callisto gate produces a value Nova has never heard of, which falls back to Standard and — per Concern 1 — reports itself as honoured.

- **Evidence (verified 2026-07-28):** `callisto-back-end/src/shared/shared-entities/entities/proceedings/video-transcode.entity.ts:5-12` (six values, DB-backed, `@Unique` on `value`); `is-video-transcode-selection-eligible-for-outbox.ts:12-16` (gate admits two); `atlas-front-end/.../useJobSubmissionOptions.ts:35-40,118-122` (runtime fetch, 2-minute `staleTime`); contract field typed `videoTranscodeValue: string`. Migration `1773945357657-alter__rename_video_job_options_to_video_transcodes` shows the table itself has already been renamed once.
- **What would resolve it:** a stable machine token (`presetKey`) on the contract, decoupled from both the primary key and the display label — considered and rejected for PRDV-16398 (report §6) because it spans three repos, carries a deploy-ordering constraint, and does not remove the value-keyed path for replayed historical messages. Revisit when a rename or a new preset is actually proposed. Interim: the guard test plus Concern 1's alarm.
- **Not a blocker.** Value-keying is strictly better than the id-keying alternative, which is provably unstable (migration `1754574059506` renumbered every row).

## Concern 3 — A second producer may already make the fallback path reachable in production

PRDV-16398 builds the unknown-value fallback while documenting it as currently unreachable, because Callisto's eligibility gate admits only `Standard` and `Video Mix`. That claim is **conditional on Callisto being the only emitter of this event.** The ClickUp activity on PRDV-16398 records Shaye Lankford linking "Transcode video files uploaded through AJSF" — a second upload path. If AJSF emits `callisto.proceeding.file.video-transcode-requested.v1` without passing through `IsVideoTranscodeSelectionEligibleForOutbox`, the fallback becomes live production behaviour rather than defensive code, and Concern 1's invisibility becomes an active rather than theoretical exposure.

This was not resolvable from the codebase: the AJSF producer does not appear in `nova-back-end`, `nova-orbital-back-end`, `callisto-back-end`, or `atlas-front-end` as read on 2026-07-28. It is a lookup against the linked ticket, not against code.

- **Evidence (verified 2026-07-28):** gate is the only emitter found — `callisto-back-end/src/proceeding-job-submission/domain/transaction-scripts/submit-job-submission-form-ts/is-video-transcode-selection-eligible-for-outbox.ts:12-16`; no other write site for this event type across the four repos. Linked item recorded in `PRDV-16398-original-ticket.md` → Activity And Comments.
- **What would resolve it:** read the AJSF ticket and confirm whether it emits this event and whether it applies the same gate. If it does not, raise the priority of Concern 1 option (a).
- **Cross-reference:** report §8 (A3, *confirmed conditional*), §10 (D5).

## Concern 4 — CLOSED, not a concern (ruled by Dustin, 2026-07-28)

**Resolution: deinterlacing is out of scope and not a risk. No follow-up required.**

Dustin ruled on the empirical question this concern hinged on: Nova always ingests `.mp4`, and where raw formats occur they are `1080p`, not `1080i`. Interlaced sources therefore do not reach this pipeline. HandBrake's `decomb` is a no-op on progressive input, so the ffmpeg translation omitting it produces the same result as the HandBrake preset for every source Nova actually receives.

`vid-mix.preset.ts` ships without a deinterlace filter, matching `standard-depo.preset.ts` and every file Nova has produced to date. **This entry is retained only as a record that the question was raised and answered — it is not an open item, and the material below is historical.**

---

### Historical detail (superseded by the ruling above)

The original concern and its correction, kept for provenance:

`Planet Depos Vid Mix v2.json` sets `PictureDeinterlaceFilter: "decomb"` with `PictureDeinterlacePreset: "default"` and `PictureCombDetectPreset: "default"`. That is HandBrake's comb-detect-then-deinterlace filter, and it is **active**. It stands out because every other picture filter in the same preset is explicitly disabled — `PictureDenoiseFilter: "off"`, `PictureSharpenFilter: "off"`, `PictureDetelecine: "off"`, `PictureDeblockPreset: "off"`, `PictureColorspacePreset: "off"`, `PictureChromaSmoothPreset: "off"` — which reads as deliberate rather than a default left untouched.

`vid-mix.preset.ts` **does not** translate it.

**Correction to an earlier framing in this document (2026-07-28).** This concern was first written as though ffmpeg could not do what HandBrake's decomb does. That was wrong, and Dustin challenged it correctly. The vendored `bin/ffmpeg` exposes **seven** deinterlacers — verified with `ffmpeg -filters`: `bwdif`, `yadif`, `idet`, `nnedi`, `estdif`, `w3fdif`, `kerndeint`. The functional equivalent is a single argument, e.g. `-vf "yadif=deint=interlaced,scale=1280:720"`. The accurate, narrower statement: HandBrake uses ffmpeg's libraries for decode/encode but ships **its own** filter implementations, so `decomb` is HandBrake code rather than ffmpeg's `yadif`; bit-identical output is not achievable, equivalent behaviour is. Capability was never the issue.

**The real question is whether deinterlacing belongs here at all — and the evidence says probably not.**

`template1` has never contained a deinterlace filter, and it has been the **only** preset in production since PRDV-14800 shipped. Every file Nova has ever delivered was therefore produced without deinterlacing. If interlaced masters were arriving in meaningful volume and the artifacts mattered visually, that would already be a standing complaint about Standard deliverables rather than a novel Video Mix question. Supporting datapoint: the local test clip reports `field_order="progressive"`, on which decomb is a no-op in HandBrake too.

Adding decomb to Video Mix **alone** would make it the only output Nova has ever produced that deinterlaces — a larger behavioural change than omitting it, and one that would make the two presets diverge on an axis unrelated to this ticket.

- **Evidence (verified 2026-07-28):** `Planet Depos Vid Mix v2.json` lines 40–59 (decomb active, every other filter `"off"`); `presets/vid-mix.preset.ts` and `presets/standard-depo.preset.ts` (neither carries a deinterlace argument); `ffmpeg -filters` inside the image (seven deinterlacers present); `ffprobe` on the local test output (`field_order="progressive"`); `scripts/win/run-local-job.ps1:14` (a commented-out `.MTS` test input — AVCHD, a format that *can* be interlaced, which is what raised the question).
- **Recommendation:** **leave it out**, matching current production behaviour for every file Nova has shipped.
- **What would resolve it properly:** ask ops / Lit Tech (a) whether interlaced masters actually reach Nova and (b) whether Vid Mix deliverables are expected to be deinterlaced. If both are yes, it is a change to **both** presets and belongs in its own ticket — altering Standard's output is precisely what LD-001 ruled out of scope here.
- **Two smaller translation notes, recorded for the same reader:** (1) `force-cfr=1` is in `vid-mix.preset.ts` but **not** in the preset's `VideoOptionExtra`; it was added so both presets pin the timebase identically, since HandBrake enforces CFR in its own pipeline rather than via that field. (2) The `-af afade…areverse` 5 ms click-suppression chain is carried over from Standard and has no counterpart in the HandBrake preset, which offers no audio-fade option. Both are deliberate and commented in the file. (3) `VideoQualitySlider: 22` is inert because `VideoQualityType: 1` selects average-bitrate mode, so `VideoAvgBitrate: 2000` governs.

## Decision history

- **2026-07-28** — PRDV-14800 identified as the origin: Callisto's producer half shipped; Nova's consumer was built against a different vocabulary (`PRDV-16398-investigation.md` §1, §5).
- **2026-07-28** — Larry Adams' spec (`larry-adams/systems/nebula/video-transcode/PRDV-16398-nova-applies-selected-transcode-preset.md`) proposes value-keying and explicitly rejects a contract-level `presetKey` as requiring coordinated three-repo change. Recorded as `active` in `docs/nova/PRDV-16398-changelog.md` → Plans.
- **2026-07-28** — Independent investigation confirms the value-keying decision and the `nova-back-end`-only scope by trace rather than assumption, and **reframes the problem class** to a contract vocabulary mismatch (report §1). Concerns 1 and 3 surface as findings not present in the coworker spec; Concern 2 is a sharpening of a risk that spec had identified.
- **2026-07-28** — Concerns 1–3 scoped **out** of PRDV-16398 and recorded here rather than expanding a hot-fix into a cross-repo contract change (report §3 Non-goals, §7 Adjacent issues).

## Open questions to settle

1. Contract change vs. alarm vs. accept — options (a)/(b)/(c) in the executive summary — owner: Dustin, with the `orbital-docking-protocol` contract owner.
2. Does the AJSF path emit this event, and does it apply Callisto's eligibility gate? (Concern 3) — owner: Dustin / Shaye Lankford.
3. Should unrecognised values be normalised (case, surrounding whitespace) before resolution, or matched exactly? Exact matching is the current design; normalising trades a narrower fallback surface for a looser contract. — owner: Dustin (Phase 3 grill-me).
4. Is a CloudWatch alarm on the fallback `warn` in scope for this ticket or a companion? — owner: Dustin.
