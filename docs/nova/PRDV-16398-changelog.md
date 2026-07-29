# PRDV-16398 — Nova applies selected video transcode preset (Video Mix)

## Ticket

- **ClickUp:** [PRDV-16398](https://app.clickup.com/t/43227262/PRDV-16398)
- **Repo:** `nova-back-end`
- **Branch:** `PRDV-16398` _(not created yet — Phase 4/5)_
- **PR:** _(link when opened)_
- **Orchestration:** `docs/nova/tickets/nova-applies-selected-transcode-preset/orchestration.md`

---

## Requirements (verbatim)

_Captured verbatim in the original-ticket artifact: `docs/nova/tickets/nova-applies-selected-transcode-preset/PRDV-16398-original-ticket.md` → Original Request. Reproduced here verbatim from that capture; do not paraphrase._

> ## Summary
>
> Product selected **Video Mix** in production; the returned file was encoded as ** Standard**.
>
> Callisto is correct — the outbox event carries `videoTranscodeValue: "Video Mix"` (and `videoTranscodeId: 3`). Nova receives that value into `VideoJob.template` via `VideoJobAssembler`, but **never uses it**. `TranscodeStep` hardcodes `template1` (Standard) for every job. Nova has never had a second preset.
>
> **Root cause:** Callisto half of PRDV-14800 shipped; Nova consumer half was never built.
>
> **Fix scope:** `nova-back-end` only — preset registry keyed on `videoTranscodeValue`, wire `job.template` / `transcodeValue` into `TranscodeStep`, add Standard + Video Mix FFmpeg presets. No Callisto, docking-protocol, or infra changes.
>
> **Spec:** PRDV-16398-nova-applies-selected-transcode-preset.md
>
> **Origin:** PRDV-14800
>
> ## Developer note
>
> Video Mix FFmpeg args are not in the codebase. Look up the existing HandBrake **Video Mix** preset (ops / Lit Tech) and translate into `vid-mix.preset.ts`. While there, confirm current `template1` still matches HandBrake ** Standard**; fix in the same PR if it drifts.
>
> Key on `videoTranscodeValue` (display label), **not** `videoTranscodeId` — IDs were renumbered historically and are not a stable contract.
>
> Unknown / empty values: fall back to Standard + `warn` log with `requestedValue` and `appliedPreset`.
>
> ## Acceptance criteria
>
> - Given a `callisto.proceeding.file.video-transcode-requested.v1` event with `videoTranscodeValue: "Video Mix"`, Nova encodes with the Video Mix FFmpeg preset (not Standard).
> - Given the same event type with `videoTranscodeValue: "Standard"`, Nova encodes with the Standard FFmpeg preset and output matches today's `template1` behaviour (no regression).
> - Structured logs for every job include the applied preset value on start and completion.
> - Given an unrecognised or empty `videoTranscodeValue`, Nova falls back to Standard and emits a `warn` log with both `requestedValue` and `appliedPreset`.
> - Unit tests assert that `'Video Mix'` and `'Standard'` resolve to distinct preset arg builders, and that the registry keys are exactly `['Standard', 'Video Mix']` (rename without Nova update fails CI).
> - No Callisto, docking-protocol, or infrastructure changes are required for this fix.
>
> ## Verification
>
> After deploy, re-process / replay the known prod case (`fileId: 666549`, `jobId: 644345`) and confirm with Product the output matches Video Mix expectations.

---

## Context

- **First ticket recorded under `docs/nova/`.** No prior Nova changelog existed in this repo; `scripts/new-ticket-changelog.ps1` cannot target `docs/nova/` (its `-System` ValidateSet is `atlas|callisto|europa|triton|other`), so this file was created by hand from `docs/_templates/TICKET-changelog.template.md`.
- **Coworker spec (read-only input):** `larry-adams/systems/nebula/video-transcode/PRDV-16398-nova-applies-selected-transcode-preset.md` by Larry Adams, 2026-07-28. Compared against in Phase 3, not adopted wholesale.
- **Origin ticket:** [PRDV-14800](https://app.clickup.com/t/43227262/PRDV-14800) — shipped the Callisto producer half (dropdown, table, outbox event field).
- **Linked in ClickUp activity** by Shaye Lankford: "Transcode video files uploaded through AJSF" — a second potential producer of this event; relevant to which values can reach Nova.
- **Named source-truth blocker:** the HandBrake **Video Mix** preset (ops / Lit Tech) is not present in any workspace repo. Encode parameters will not be inferred.
- **Repos read during capture:** `nova-back-end`, `nova-orbital-back-end`, `callisto-back-end`, `atlas-front-end`.

---

## Plans

_Lives in **dustin-thomason** only. **Larry-adams** paths are **read-only links** to coworker specs — never create or push changelog/plan files there._

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-07-28 | `larry-adams/systems/nebula/video-transcode/PRDV-16398-nova-applies-selected-transcode-preset.md` (read-only, Larry Adams) | `active` | Value-keyed preset registry in `nova-back-end` only: `TRANSCODE_PRESETS` const + `resolveTranscodePreset` with Standard fallback; `TranscodeStep.apply` gains a third `transcodeValue` param; `template1` moves verbatim to `standard-depo.preset.ts`; new `vid-mix.preset.ts`; rename `VideoJob.template` → `transcodeValue`; contract-guard spec on registry keys. |

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-07-28T19:45:00Z — nova-back-end (branch `PRDV-16398`) — committed and pushed

- **Summary:** Implemented the preset resolution per Larry's spec, integrated the HandBrake "Planet Depos MP4 Vid Mix 080222" preset, and verified **all four acceptance criteria live** in the local Docker harness. Committing at Dustin's direction with the audit exception recorded below.
- **Gates:** lint `0`, type-check `0`, tests `17/17 suites, 87/87`. **audit `1`** — 10 vulnerabilities / 8 high, **all pre-existing**; `package.json` and `package-lock.json` untouched by this change (verified by `git diff HEAD --stat`). Six have `fixAvailable: false`, arriving via `pathfinder-observability-pkg` → `@opentelemetry/*`; `brace-expansion` and `js-yaml` are fixable. **Exception:** the `git-commit-workflow` audit gate was raised twice and Dustin directed the push; residual risk is unchanged from `main`, since this branch introduces no dependency.
- **Live E2E evidence:** `std-002` Standard — arguments byte-identical to the former `template1`, output 10,600,047 B. `fb-001` `"Site Survey"` — one `warn` with `requestedValue`/`appliedPreset`, Standard applied, job still delivered. `mix-001` Video Mix — x264 echoed `bitrate=2000 vbv_maxrate=2000 vbv_bufsize=4000` vs Standard's `950/950/1900`, output 15,335,687 B.
- **Deinterlacing:** Dustin ruled sources are always `.mp4` and raw is `1080p` not `1080i`, then ruled to include the filter anyway for parity with the HandBrake preset. `yadif=deint=interlaced` runs ahead of `scale`; a no-op on progressive input. Concern 4 closed, not deferred.
- **Plan used:** Larry Adams' spec (Plans row, `active`) — adopted as the implementation shape per LD-000; the investigation found no drift from the code, so no competing spec was written.
- **Files (17):** new `transcode-preset.registry.ts`, `presets/standard-depo.preset.ts` (verbatim `template1`), `presets/vid-mix.preset.ts` (throws pending args), `__specs__/transcode-preset.registry.spec.ts`; deleted `ffmpeg.template.ts`; `ffmpeg.spec.ts` → `standard-depo.preset.spec.ts` (+ AC-2 frozen-literal parity test); modified `transcode.step.ts`, `video-conversion.service.ts`, `video-job.ts` (`template` → `transcodeValue`), `video-job.assembler.ts`, `test-utils.ts`, three specs; vocabulary convergence in `scripts/win/run-local-job.ps1`, `scripts/run-local-transcode.sh`, `scripts/run-local-failure-notification-test.sh`, `docs/local-docker-transcode.md`, `payload-local.json`, `payload-s3.json`.
- **Commits:** none — blocked on audit.
- **Notes / corrections worth carrying forward:**
  - **Eight vocabulary sites, not five.** The report catalogued five; implementation found `test-utils.ts`, `run-local-failure-notification-test.sh`, and — most importantly — `scripts/win/run-local-job.ps1`. The first sweep used `grep --include="*.sh|*.md|*.json"` and so skipped `.ps1`, missing the **Windows** harness, i.e. the one actually used on this machine. Had it stayed, verifying the fix locally would have exercised the fallback and looked like a pass.
  - **Hash comparison of output is invalid for this pipeline.** x264 runs with `threads=22`; two runs of identical code produced 10,599,657 vs 10,596,571 bytes. AC 2 is proven by argument identity plus a pinned vendored ffmpeg binary, not by comparing files.
  - **Always gate on image freshness before an E2E run.** A full verification cycle was wasted against April's image; `docker build` had populated BuildKit's cache but failed to tag. Gate: `docker run --rm --entrypoint sh ffmpeg-worker -c "grep -c resolveTranscodePreset dist/.../transcode.step.js"` must return ≥ 1.
  - **`.npmrc` now reads `${GITHUB_TOKEN}`** (Dustin's request) instead of a hardcoded, expired PAT. File is gitignored and was never tracked.
  - **Agent overstep, corrected.** Six scope decisions were briefly locked as "agent default" without approval. Dustin reverted that and set a standing rule: no changes or decisions without explicit approval. Recorded in `specs/PRDV-16398-locked-decisions.md`.

### 2026-07-28T00:00:00Z — dustin-thomason (docs only)

- **Summary:** Orchestration Phase 0 (Capture). Established the canonical ticket folder under `docs/nova/`, relocated the pre-existing ClickUp capture into it without altering the Original Request, scaffolded the orchestration ledger, and created this changelog. Read-only survey of the transcode pipeline across four repos to scope Phase 1; no implementation-repo file touched.
- **Plan used:** none yet — Larry's spec logged in **Plans** as `active` input, to be compared against in Phase 3.
- **Files:**
  - `docs/nova/tickets/nova-applies-selected-transcode-preset/PRDV-16398-original-ticket.md` (moved from `docs/atlas/`, metadata + constraints + context sections filled)
  - `docs/nova/tickets/nova-applies-selected-transcode-preset/orchestration.md` (new)
  - `docs/nova/PRDV-16398-changelog.md` (new)
- **Commits:** none yet
- **Notes:** No code changed. Phase 5 carries a named blocker: HandBrake Video Mix preset args are absent from the workspace and will not be inferred.

---

## Why each non-obvious value is what it is

_Moved out of source comments per `pr-review-patterns` Pattern 7 (reviewer derrickdso: "lets clear out these unnecessary comments"). Code carries no explanatory comments; this section is the record._

| Decision | Why |
| --- | --- |
| Registry keyed on `videoTranscodeValue`, never `videoTranscodeId` | Migration `1754574059506` renumbered every row in `video_transcodes` (`5→6, 4→5, 3→4, 2→3, 1→2`) to free id 1 for the empty value. Nothing broke only because nothing consumed the id. A hardcoded id in Nova would silently repoint at the wrong preset on the next such migration. |
| Registry keys asserted as exactly `['Standard', 'Video Mix']` | Those are the only two values Callisto's `IsVideoTranscodeSelectionEligibleForOutbox` gate emits. Callisto owns the vocabulary; Nova mirrors it. The assertion turns an upstream rename into a CI failure instead of a silent production downgrade. |
| `resolveTranscodePreset` returns `isFallback` rather than throwing | Keeps the return type honest about whether a substitution happened, and leaves the logging to `TranscodeStep`, which owns the logger. Throwing would deny the customer a usable deliverable over a preset mismatch. |
| Exact string matching — no trimming, no case folding | Keeps the registry a byte-exact mirror of the Callisto authority, which is what makes the contract-guard assertion mean anything. `video_transcodes.value` is a unique-constrained column, so casing variance is not an observed risk. |
| `nal-hrd=cbr` on **both** presets | YesLaw, the transcript-to-video sync application these deliverables play through, only stays in sync on a genuinely constant bitrate. Without it x264 ran `nal_hrd=none filler=0`, treating the rate as a ceiling and settling wherever the content landed — a static source at Video Mix's 2000k target came out at 1572k. With it x264 pads with filler NAL units and holds the rate exactly. Confirmed locally: 2 000 kb/s flat, MediaInfo bit-rate mode `Constant`, no visible quality change, file 18.0 → 22.5 MiB. |
| `-minrate` on Video Mix (not in the HandBrake preset) | MediaInfo on pipeline output showed Standard holding 950 exactly while Video Mix undershot to 1572 on the same source. Standard sets the floor as an ffmpeg flag; Video Mix carried its VBV only inside `-x264-params`. Mirroring Standard's shape removed the asymmetry. |
| `force-cfr=1` on Video Mix (not in the HandBrake preset) | Consistency with the Standard preset, so both pin the timebase the same way rather than differing by accident. HandBrake enforces CFR in its own pipeline via `VideoFramerateMode` rather than through that field. |
| `-af afade…areverse` on Video Mix (not in the HandBrake preset) | Consistency with Standard, which uses a 5 ms fade in/out to suppress start and end clicks. HandBrake offers no audio-fade option. |
| `yadif=deint=interlaced` on Video Mix | Covers the HandBrake preset's `PictureDeinterlaceFilter: "decomb"`. `deint=interlaced` only touches frames flagged interlaced, so progressive sources — which is all Nova ingests — pass through untouched. Runs before `scale` so fields are separated before any vertical resampling. Not bit-identical to HandBrake's own decomb filter, and deliberately not chased. |
| Standard's arg list otherwise verbatim from `template1` | AC 2. The parity spec asserts a hand-written literal rather than calling the production builder, because an expectation derived from the code under test cannot catch a transcription error in that code. |
| `payload-local.json` / `payload-s3.json` left untouched | Dropped from the PR — stale fixtures that appear unused. Not worth carrying in a hot-fix diff. |

---

## Root cause analysis

_Provisional, from the Phase 0 read-only survey; the authoritative account lands in the Phase 2 investigation report._

`nova-back-end`'s `VideoJobAssembler.apply` reads `payload.videoTranscodeValue` into `VideoJob.template` ([video-job.assembler.ts:66](../../../Users/dustin.thomason/nova-back-end/src/video-conversion/domain/services/video-conversion-service/video-job.assembler.ts)), but `TranscodeStep.apply(localInputPath, localOutputPath)` takes no preset parameter and calls `template1(...)` unconditionally ([transcode.step.ts:25](../../../Users/dustin.thomason/nova-back-end/src/video-conversion/domain/steps/transcode-step/transcode.step.ts)). `ffmpeg.template.ts` exports exactly one builder. So the selection is carried into the domain object and then dropped — a producer/consumer contract where only the producer half shipped.

---

## Attempt history

_None yet._

---

## Key technical learnings

1. **The value set is data, not code.** Atlas fetches the dropdown options from Callisto at runtime (`fetchVideoTranscodes` → `FETCH_VIDEO_TRANSCODES_URL`, `useJobSubmissionOptions.ts`), and the options are rows in `callisto.video_transcodes`. A new row can therefore appear in the UI with no code change in any repo — which is exactly why Nova needs an explicit fallback rather than an exhaustive match.
2. **`videoTranscodeId` is provably unstable.** Migration `1754574059506-update__add_empty_value__video_job_options_table` shifts every id (`5→6, 4→5, 3→4, 2→3, 1→2`) to free id 1 for `''`. Post-shift, `videoTranscodeId: 3` is `Video Mix` — matching the production event. Keying on the id would silently repoint on the next such migration.
3. **Callisto's gate currently admits only two values.** `IsVideoTranscodeSelectionEligibleForOutbox.apply` returns true only for `VIDEO_TRANSCODES.STANDARD` and `VIDEO_TRANSCODES.VIDEO_MIX`, though `VIDEO_TRANSCODES` defines six (`Standard`, `Video Mix`, `Site Survey`, `Day in the Life`, `Other`, `''`).
4. **The wire contract types the field as a bare `string`.** `CallistoProceedingFileVideoTranscodeRequestedV1Data.videoTranscodeValue: string` in `@planetdepos/orbital-docking-protocol` — no union, so the type system provides no exhaustiveness help on Nova's side.
5. **Local `node_modules` skew in `nova-back-end`.** It declares `@planetdepos/orbital-docking-protocol: ^1.0.5` but has `0.2.13` installed; `callisto-back-end` has `1.0.5`. The 0.2.13 payload type still shows `createdBy`/`updatedBy` where 1.0.5 has `createdUserIdentity`/`modifiedUserIdentity`/`createdUserEmail`/`createdUserName`. This is a stale local install, not a proven production mismatch — flagged for Phase 1 to resolve rather than assume.

---

## Current state (as of 2026-07-28)

Phase 0 complete, docs only. No branch, no code changes, no commits. Next: Phase 1 investigation in Plan mode.

---

## New code introduced

_None yet._
