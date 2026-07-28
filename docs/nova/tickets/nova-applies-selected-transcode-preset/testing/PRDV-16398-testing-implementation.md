# Testing implementation — PRDV-16398

> Scenario-first record of what was actually stress-tested and why. This is the staging ground for the **PR comment** — it is never copied into the source as a code comment.
> Branch `PRDV-16398` off `ef816e9`. Results log: [PRDV-16398-test-plan.md](./PRDV-16398-test-plan.md).

## Scenario 1 — A customer selects Video Mix and gets a Video Mix file

**Why it matters:** this is the ticket. A production job (`fileId: 666549`) selected Video Mix and came back Standard.

**What the code did before:** `TranscodeStep.apply` took two arguments — input path and output path. There was no third parameter, no conditional, and no lookup. Line 25 called `template1(...)` unconditionally. The selection was read out of the event into `VideoJob.template` and then never read by anything.

**How it was proven, not assumed:** the pre-fix step was restored from `ef816e9` and run against the new spec twice.

- Passing a preset to it **would not compile** — `TS2554: Expected 2 arguments, but got 3`, eight times. There was no seam.
- Forcing the value through with a cast, it called the transcoder with **Standard's argument array** while the job asked for Video Mix, and logged no applied preset at all. Two assertions failed exactly as designed.

Both scratch artefacts (a git worktree and a `src/__redgreen__/` folder) were removed and `git status` verified clean.

**Change it forced:**

- `transcode.step.ts` — `apply` gains a third `transcodeValue` parameter and resolves it through the registry.
- `transcode-preset.registry.ts` *(new)* — `resolveTranscodePreset` returns `{ presetValue, buildArgs, isFallback }`.
- `presets/vid-mix.preset.ts` *(new)* — **arguments not yet supplied.**
- `video-conversion.service.ts` — passes `job.transcodeValue` as the third argument.

**Status: incomplete.** The mechanism works and is tested. The Video Mix *encode* cannot be produced until the HandBrake arguments arrive, so `vidMixPreset` currently throws.

## Scenario 2 — A Standard job must come out exactly as it does today

**Why it matters:** the refactor moves a 50-line ffmpeg argument array. Nothing in it is logic; everything in it is a value that changes the output file. A dropped `keyint=12` changes seek granularity on a deposition video. A mangled `-af afade=...areverse` chain loses the 5 ms click-suppression fades. Both produce a file that plays fine and is quietly wrong.

**What the code did before:** one array in `ffmpeg.template.ts`, exercised by a spec that computed its own expected value by calling `template1` — so it could not detect a transcription error.

**How it was proven:** two independent checks.

- **Source level, before formatting:** the argument arrays of old `template1` and new `standardDepoPreset` were extracted with `awk` and diffed — **byte-identical, 52 lines.**
- **Runtime, durable:** a new assertion in `standard-depo.preset.spec.ts` compares the builder's output against a **frozen literal array** written out by hand. Deliberately not computed from the code under test — an expectation derived from the code it is testing cannot catch a typo in that code.

The ffmpeg binary is vendored in the repo (`bin/ffmpeg`, copied to `/usr/local/bin/ffmpeg` in the Dockerfile) and `FfmpegAdapter` spawns that exact path. Identical arguments plus a pinned encoder means an identical output file — so the argument assertion is the *cause* of output parity, not a proxy for it.

**Change it forced:** `presets/standard-depo.preset.ts` *(new)* — `template1` verbatim; `ffmpeg.template.ts` deleted; its spec migrated to `standard-depo.preset.spec.ts`.

**Decision recorded:** the ticket's developer note also asked to check `template1` against the HandBrake Standard preset and fix any drift. **Dustin ruled that out** — nothing has changed, so this is a migration only. Standard's output is unchanged, full stop.

## Scenario 3 — An unrecognised value arrives and must not fail silently

**Why it matters:** the selectable options are **database rows**, not code. Atlas fetches them from Callisto at runtime, so a new row becomes selectable with no code change in any repo. Callisto's gate admits only two values today, which makes this path currently unreachable — but "currently unreachable" is a property of a gate someone can widen, not a guarantee.

**How it was proven:** parameterised assertions over `'Site Survey'`, `'Day in the Life'`, `''`, `'template1'`, `'video mix'`, `' Video Mix '` — each resolves to Standard with `isFallback: true`, and the step emits exactly one `warn` carrying both `requestedValue` and `appliedPreset`. The `warn` call itself is asserted, not just the resulting arguments: a silent fallback is the failure mode this design exists to prevent.

Matching is exact — case and whitespace variants deliberately fall back rather than being normalised, so the registry stays a byte-exact mirror of the Callisto authority and the contract-guard test means something.

**Change it forced:** the `isFallback` flag on `ResolvedPreset`, and the `warn` in `transcode.step.ts`. `resolveTranscodePreset` returns the fallback rather than throwing, so the caller — which owns the logger — is responsible for surfacing it.

## Scenario 4 — Someone renames a preset in Callisto and forgets Nova

**Why it matters:** Nova's keys must mirror `callisto.video_transcodes` exactly, and the wire contract types the field as a bare `string`, so the compiler cannot enforce the mirror.

**How it was proven:** a contract-guard assertion that the registry's key set equals exactly `['Standard', 'Video Mix']`. A rename upstream fails CI here rather than silently downgrading production encodes.

**Known limit, stated plainly:** this catches a **rename**, not an **addition**. A new row plus a widened Callisto gate yields a value Nova has never heard of, which falls back to Standard — and because Nova's completed event forwards the *requested* value verbatim, nothing downstream can tell. Recorded in `PRDV-16398-future-development-concerns.md` Concern 1.

## Scenario 5 — Someone tests this locally and gets a false pass

**Why it matters — this is the scenario the original spec missed.** Nova's own local harness seeded `videoTranscodeValue: "template1"`, and its runbook documented `template1` as *the* value to use. That string is not a preset name after this change: it lands on the unknown-value fallback. Anyone verifying this fix by running the documented local procedure would have exercised the **fallback branch**, watched a Standard file come out, and concluded it worked.

This is why the problem was reclassified from "the consumer was never built" to "the consumer was built against the wrong vocabulary." Nova's field name, script, runbook, and test fixtures all treated this field as an ffmpeg template identifier.

**How it was proven — and the first attempt was unsound.** The initial sweep used `grep --include="*.sh" --include="*.md" --include="*.json"`, which silently excluded `.ps1` files, and reported "seven sites converged." That was wrong. A re-run with no file-type filter found an **8th**: `scripts/win/run-local-job.ps1:25`, `$videoTranscodeValue = "template1"`.

That miss mattered more than the others. `run-local-job.ps1` is the **Windows** harness — the bash script's own prerequisite note says `brew install jq`, so on this machine the PowerShell script is the one that would actually have been used. The false-pass risk in this scenario was therefore live, not hypothetical: the exact script someone would reach for to verify this fix was seeding the fallback value. A filtered grep is how the sweep meant to catch that nearly reproduced it.

Post-fix the unfiltered grep returns zero uses of `template1` as a *value*; every surviving match is an explanatory comment or deliberate fallback test data. **Total: 8 sites.**

**Change it forced:**

- `scripts/win/run-local-job.ps1` — **the Windows harness, and the one actually used here.** `$videoTranscodeValue` now defaults to `"Standard"` and honours `$env:TRANSCODE_VALUE`. Needs no jq (it builds the event with `ConvertTo-Json`) and already targeted the correct Docker network.
- `scripts/run-local-transcode.sh` — now `TRANSCODE_VALUE="${TRANSCODE_VALUE:-Standard}"`, threaded into the jq event body. Both shell scripts syntax-checked with `bash -n`.
- `docs/local-docker-transcode.md` — corrected seed value and reference table, plus a new "Choosing a transcode preset" section warning that a near-miss string silently exercises the fallback and telling the reader to check `appliedPreset` in the log.
- `src/test-utils/test-utils.ts`, `video-job.assembler.spec.ts` — fixtures now use real Callisto values.
- `payload-local.json`, `payload-s3.json` — `"template": "template1"` → `"transcodeValue": "Standard"`.
- `video-job.ts` — `template` → `transcodeValue`, the field name being the vocabulary bug in miniature.

## Scenario 6 — The neighbours on the shared pipeline must not move

**Why it matters:** `runPipeline` runs Materialize → Validate → ProbeDuration → Transcode → PersistOutput, and the failed path writes a failed event, a notification, and `markFailed` in one DynamoDB transaction. Only one of those five steps was supposed to change.

**How it was proven:** their specs were **not modified** and stayed green. `TranscodeStep`'s error propagation is unchanged, so pipeline failure handling is untouched. `git diff --stat` on `package.json` and `package-lock.json` is empty — no dependency or contract change, which is the concrete surface behind the ticket's "no docking-protocol change" criterion.

## Verified in the real pipeline (2026-07-28)

Two end-to-end runs against the rebuilt image, real ffmpeg, real S3 and DynamoDB. A stale-image gate was run first (`grep -c resolveTranscodePreset` inside `dist` → `1`) because an earlier attempt had unknowingly tested April's build.

**Standard (`std-002`) — closes AC 2 and AC 3.** `transcodeValue:"Standard"` arrived in the job, proving the rename end-to-end. `appliedPreset:"Standard"` appeared on both the start and completion logs. No fallback warn. Critically, the `FfmpegAdapter` debug line logs the **actual argument array**, which was compared element-by-element against `ef816e9`'s `template1` and matched on every element. x264's own options echo confirms they were honoured, not silently dropped: `keyint=12 keyint_min=1 bframes=0 qcomp=0.80 aq=1:0.50 decimate=0 fast_pskip=0 deblock=1:-2:-2 rc=cbr bitrate=950 vbv_maxrate=950 vbv_bufsize=1900`. Output: 2664 frames, 1280×720, 29.97 fps, `kb/s:822.96`, aac 48000 stereo — matching the pre-change baseline. Scenario 2's claim is therefore proven at runtime, not only by unit test.

**Fallback (`fb-001`, `Site Survey`) — closes AC 4.** Exactly one warn: `"Unrecognised transcode value; applying fallback"` carrying `requestedValue:"Site Survey"` and `appliedPreset:"Standard"`, emitted before the encode. Standard's arguments then applied, byte-identical to `std-002`. The job **completed successfully** rather than failing — the deliberate behaviour from LD-004: a substituted preset still produces a usable file, and the warn is the record.

**Also settled:** the byte-level output variance that derailed the first verification attempt is x264 frame-threading — `threads=22 lookahead_threads=3`. No file-hash comparison of this pipeline can ever be valid.

## What is not proven

Stated so no one reads the green suite as more than it is.

1. **The Video Mix encode does not exist — AC 1 is the only open criterion.** `vidMixPreset` throws until the HandBrake arguments are supplied. It throws rather than returning Standard's arguments on purpose: silently encoding Standard while reporting Video Mix is the defect being fixed. Everything downstream of the arguments — resolution, wiring, logging, the harness, the image, the gate — is now proven working, so this is a paste-and-rerun.
2. **`job.transcodeValue` reaching `TranscodeStep.apply` is asserted in a spec that never executes.** `video-conversion.service.spec.ts` cannot compile because the installed `orbital-relay-pkg` is `0.3.21` while the lock pins `1.0.3`; the same four suites fail identically at base `ef816e9`. **Mitigated by the E2E runs above** — `appliedPreset:"Standard"` and `appliedPreset:"Standard"` on a `"Site Survey"` request could only appear if the service passed the value through. The unit assertion remains unexecuted; the behaviour it asserts is now demonstrated.
3. **`npm audit --audit-level=high` exits 1** — 10 vulnerabilities, 8 high, all pre-existing and untouched by this change (`package.json` and `package-lock.json` unmodified). This blocks commit under `git-commit-workflow` until triaged.
