# Test plan — nova/nova-applies-selected-transcode-preset

> Seeded from [PRDV-16398-investigation.md](../investigations/PRDV-16398-investigation.md) §9 on 2026-07-28. Refined by spec: pending (Phase 3).

Status: **seeded**

## Scope and surfaces under test

- **Behaviour proven:** the `videoTranscodeValue` Nova receives determines the FFmpeg arguments it encodes with, and an unrecognised value falls back to Standard *visibly*.
- **Surfaces:** `TranscodeStep.apply` (the defect site), the new resolution boundary, `VideoConversionService.runPipeline`'s call to that step, and the five vocabulary sites that seed local runs. Nova is a one-shot ECS task with no HTTP surface, so there is no request/route surface to exercise.
- **Critical constraint on this plan:** mocked unit tests prove **wiring**, never **encoding**. A `jest.Mocked<TranscoderPort>` records an arg array; it does not run FFmpeg. Acceptance criteria 1 and 2 are therefore *not closeable* by unit tests alone — only HP-6/HP-7 (real encode + `ffprobe`) close them. This is recorded here so a green suite is never mistaken for a proven encode.

## Happy path

- [ ] **HP-1** — Registry resolves a known value: given `'Standard'` → `resolveTranscodePreset` returns `{ presetValue: 'Standard', isFallback: false }` and the Standard builder; given `'Video Mix'` → the Video Mix builder, `isFallback: false`.
- [ ] **HP-2** — Standard parity (AC 2): the Standard builder's output array is **byte-identical** to `02b56c0`'s `template1(src, out)`. Asserted against a literal expected array, **not** by calling the production builder — see NP-5 for why.
- [ ] **HP-3** — Step applies the selected preset: `TranscodeStep.apply(in, out, 'Video Mix')` → `transcoder.transcode` receives the Video Mix args; with `'Standard'` → Standard args. Uses `toHaveBeenNthCalledWith` per repo convention.
- [ ] **HP-4** — Distinctness (AC 5): the args produced for `'Video Mix'` **do not equal** those for `'Standard'`. This is the assertion whose absence caused the defect.
- [ ] **HP-5** — Service passes the value through: `VideoConversionService` invokes `TranscodeStep.apply` with `job.transcodeValue` as the third argument. Replaces the current `expect.any(Array)` assertion at `video-conversion.service.spec.ts:203-208`.
- [ ] **HP-6** — **Local E2E, Video Mix** (closes AC 1): `scripts/run-local-transcode.sh <clip.mp4> local-NNN` with the seeded value `'Video Mix'`; download from `s3-nova-local-outputs`; `ffprobe` the output and confirm its parameters match the Video Mix preset **and differ** from an HP-7 Standard run of the same input clip.
- [ ] **HP-7** — **Local E2E, Standard** (closes AC 2): same clip and command with `'Standard'`; `ffprobe` output matches a **pre-change baseline run** of the same clip captured on `02b56c0`. Capture the baseline *before* implementing, or the comparison has no reference.
- [ ] **HP-8** — Applied-preset logging (AC 3): `info` on start and on completion each carry the **resolved** `appliedPreset`, not the requested value.

## Negative paths

- [ ] **NP-1** — Unrecognised value (AC 4): `'Site Survey'` → encodes with Standard **and** emits exactly one `warn` carrying both `requestedValue: 'Site Survey'` and `appliedPreset: 'Standard'`. Assert the `warn` call itself, not merely the args — a silent fallback is the exact failure mode the design exists to prevent.
- [ ] **NP-2** — Empty value (AC 4): `''` → same as NP-1 with `requestedValue: ''`. Covers Callisto's `VIDEO_TRANSCODES.NONE`.
- [ ] **NP-3** — Contract guard (AC 5): the registry's key set equals **exactly** `['Standard', 'Video Mix']`. A rename in `callisto.video_transcodes` without a matching Nova update fails CI rather than silently downgrading production encodes.
- [ ] **NP-4** — **The vocabulary trap** (AC 7): after the change, grep the repo for `template1` used as a `videoTranscodeValue` → expect **zero** hits. Re-check specifically `scripts/run-local-transcode.sh:116`, `docs/local-docker-transcode.md:148` and `:299`, `payload-local.json`, `payload-s3.json`, `video-job.assembler.spec.ts:49,95`. This is a negative path because its failure mode is a **passing** local run against the wrong branch.
- [ ] **NP-5** — **Red→green proof** (AC 8): the new step spec must **fail** when run against `02b56c0`'s `TranscodeStep`, and pass after. Without this the suite repeats its own history — the three existing assertions (tautological expected-args, `expect.any(Array)`, carried-not-used) are all structurally incapable of failing.
- [ ] **NP-6** — Neighbours unchanged (regression): `MaterializeInputStep`, `ValidateInputStep`, `ProbeDurationStep`, `PersistOutputStep` and the completed / failed / notification outbox writers share `runPipeline`. Their existing specs stay green **unmodified**; the failed-path transaction (failed event + notification + `markFailed` in one DynamoDB transaction) still asserts the same behaviour; `TranscodeStep`'s error propagation is unchanged so pipeline failure handling is untouched.
- [ ] **NP-7** — Contract untouched (AC 6): `CallistoProceedingFileVideoTranscodeRequestedV1Data` and the completed/failed/notification descriptors are unchanged. Verify **by diff**, not by intent — the concrete surface named for the "no contract change" claim.
- [ ] **NP-8** — Removed dependency proven non-required: `ffmpeg.template.ts` is deleted and its three importers (`transcode.step.ts`, `transcode.step.spec.ts`, `ffmpeg.spec.ts`) are the complete set. `npm run type-check` proves no dangling import survives.

## Edge cases

- [ ] **EC-1** — Case and whitespace: `'video mix'`, `'VIDEO MIX'`, `' Video Mix '` → currently fall to the fallback. Assert the chosen behaviour explicitly once D-normalisation is ruled on in Phase 3; do not leave it implicit.
- [ ] **EC-2** — Historical replay: a payload whose `videoTranscodeValue` is a since-removed row value → Standard + `warn`, no throw. The production case (`fileId: 666549`) is itself a replay per the ticket's verification step.
- [ ] **EC-3** — Coverage gate: `jest.config.json` enforces 80% global with `collectCoverage` always on, and new `.preset.ts` / `.registry.ts` files are **not** in the exclusion list. Untested new files fail the suite — so this is a gate, not a preference.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| `nova-back-end` | `domain/steps/transcode-step/__specs__/transcode-preset.registry.spec.ts` *(new)* | HP-1, HP-2, NP-1, NP-2, NP-3 |
| `nova-back-end` | `domain/steps/transcode-step/__specs__/transcode.step.spec.ts` *(modified — repairs the tautological assertion)* | HP-3, HP-4, HP-8, NP-1, NP-5 |
| `nova-back-end` | `domain/services/video-conversion-service/__specs__/video-conversion.service.spec.ts` *(modified — replaces `expect.any(Array)`)* | HP-5, NP-6 |
| `nova-back-end` | `domain/services/video-conversion-service/__specs__/video-job.assembler.spec.ts` *(modified — real Callisto labels)* | NP-4 |
| `nova-back-end` | `domain/steps/transcode-step/__specs__/ffmpeg.spec.ts` *(relocated with the builder)* | HP-2 |
| `nova-back-end` | Local Docker harness — `scripts/run-local-transcode.sh` + `ffprobe` | HP-6, HP-7, EC-2 |
| `nova-back-end` | `npm run type-check` | NP-8 |
| — | `git diff` review | NP-7 |

## Gates

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` |
| lint | `npm run lint` |
| tests | `npm test -- --runInBand` |
| types | `npm run type-check` |

Order is fixed: **audit → lint → tests**, tests against the post-lint tree.

## Blocked items (named, not dropped)

- **HP-6 is blocked on the HandBrake Video Mix preset.** The arg values do not exist in any repo and will not be inferred (`source-truth`). Residual risk: AC 1 cannot be closed until they arrive. Follow-up: retrieve from ops / Lit Tech — owner Dustin (report §10, D6).
- **HP-7 needs its baseline captured before implementation begins.** If the `02b56c0` run is not captured first, "matches today's behaviour" has no reference and AC 2 degrades to an unfalsifiable claim.

## Results log

Baseline for all runs: `nova-back-end` @ `ef816e9` (main moved from `02b56c0` during Phase 5; the two intervening commits touched `devops/` only — verified by `git diff --stat 02b56c0..ef816e9 -- src/ scripts/ docs/ package.json`, empty).

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| 2026-07-28 | audit | `npm audit --audit-level=high` | nova-back-end | **FAIL (exit 1)** | 10 vulns / 8 high, **all pre-existing** — `package.json` and `package-lock.json` untouched by this change (verified by `git diff HEAD --stat`). 6 have `fixAvailable: false` (opentelemetry chain via `pathfinder-observability-pkg`); `brace-expansion` and `js-yaml` are fixable. **Blocks commit per `git-commit-workflow`** — awaiting triage. |
| 2026-07-28 | lint | `npm run lint` | nova-back-end (`eslint .`) | pass (exit 0) | — |
| 2026-07-28 | format | `npx prettier --write` on the 17 changed files | changed files only | pass | Repo-wide `npm run prettier` fails on **65 files at the base commit** — pre-existing. Deliberately did **not** run `--write .`, which would have reformatted 63 unrelated files and buried the diff. |
| 2026-07-28 | tests | `npm test -- --runInBand` | nova-back-end, full suite | **59 passed, 0 failed**; 4 suites failed to compile | The same 4 suites fail identically at base `ef816e9` (37 passed there → **+22 net new tests**). Cause: stale local `node_modules` — see the blocked row below. |
| 2026-07-28 | tests (scoped) | `npx jest --runInBand --coverage=false --testPathPatterns "transcode"` | transcode-step suites | **30 passed, 3 suites** | HP-1..HP-4, HP-8, NP-1, NP-2, NP-3, EC-1 |
| 2026-07-28 | HP-2 parity (AC 2) | included in the run above | `standard-depo.preset.spec.ts` | pass | Also verified at source level before Prettier reformatting: `awk`-extracted argument arrays of old `template1` and new `standardDepoPreset` diffed **byte-identical (52 lines)**. The runtime assertion is the durable guarantee. |
| 2026-07-28 | **NP-5 red→green (AC 8)** | see the two sub-runs below | `transcode.step.spec.ts` | **pass — red proven, then green** | This is the assertion the defect's absence-of-detection required. |
| 2026-07-28 | NP-5a — red, type level | new spec vs pre-fix `TranscodeStep` restored from `ef816e9` | `transcode.step.spec.ts` | **failed to compile, 8× `TS2554: Expected 2 arguments, but got 3`** | Proves the pre-fix implementation had **no parameter at all** through which a preset could arrive. |
| 2026-07-28 | NP-5b — red, behavioural | throwaway spec against a verbatim copy of the pre-fix step, preset passed via cast | `src/__redgreen__/` (deleted after the run) | **2 failed as designed** | Requesting `'Video Mix'`, the pre-fix step called `transcode` with **Standard's** argument array (`Number of calls: 1`), and logged **no** `appliedPreset`. The defect reproduced as an assertion failure, not just a compile error. Worktree and throwaway folder removed; `git status` verified clean of scratch files. |
| 2026-07-28 | NP-4 vocabulary sweep (AC 7) — **first attempt, INCOMPLETE** | `grep -rn ... --include="*.sh" --include="*.md" --include="*.json"` | filtered by file type | **unsound** | The `--include` filters excluded `.ps1`, so `scripts/win/run-local-job.ps1` was never examined. Reported as "seven sites converged" — that claim was wrong. Recorded rather than quietly replaced. |
| 2026-07-28 | NP-4 vocabulary sweep (AC 7) — **re-run, complete** | `grep -rn "template1\|template-1" . --exclude-dir={node_modules,dist,coverage,.git} --exclude=package-lock.json` (no `--include` filter) | whole repo, every file type | pass | Found an **8th** site: `scripts/win/run-local-job.ps1:25` — `$videoTranscodeValue = "template1"`. This is the **Windows** harness, i.e. the script that would actually have been used on this machine, so the false-pass risk was live rather than theoretical. Fixed and parameterised via `$env:TRANSCODE_VALUE`. Post-fix, zero remaining uses as a *value*; all surviving matches are explanatory comments or deliberate fallback test data. **Total: 8 sites.** |
| 2026-07-28 | NP-6 neighbours | full-suite run above | Materialize / Validate / ProbeDuration / PersistOutput + outbox writers | pass | Their specs were **not modified** and stayed green. |
| 2026-07-28 | NP-7 contract untouched | `git diff HEAD --stat -- package.json package-lock.json` | dependency + contract surface | pass | Empty output — no dependency or contract change. `orbital-docking-protocol` not touched. |
| 2026-07-28 | NP-8 dangling import | `npm run type-check` | whole repo | **inconclusive** | `ffmpeg.template.ts` deletion produced **no** new error, and the 3 importers were all updated — but the pre-existing stale-dependency errors mean type-check cannot exit 0, so this cannot be asserted cleanly. See blocked row. |
| 2026-07-28 | **HP-5 service passes the value** | `npx jest --testPathPatterns "video-conversion.service.spec"` | `video-conversion.service.spec.ts` | **BLOCKED — written but never executed** | The suite fails to compile at line 3 on `DynamoDbTransactionContextService`, absent from the **installed** `orbital-relay-pkg@0.3.21` (lock pins `1.0.3`). Pre-existing and identical at base. **Residual risk: the assertion that `job.transcodeValue` reaches `TranscodeStep.apply` as the third argument is unverified by execution.** Reviewed by reading the call site instead — a weaker check. Resolved by repairing `node_modules`; see below. |
| 2026-07-28 | HP-7 attempt 1 — **INVALID TEST, and ran the wrong binary** | `Get-FileHash` on baseline vs post-change output | Docker E2E | **void** | Two compounding errors, both mine. **(a) The test was invalid:** x264 output here is **not byte-reproducible**. Proven by running Standard twice on the *identical* image — 10,599,657 vs 10,596,571 bytes, ~3.1 KB apart, versus the ~3.7 KB baseline↔after gap. A file hash can never demonstrate encode parity for this pipeline. **(b) The binary was stale:** `docker image inspect` shows the image is still `2026-04-17`; it contains `ffmpeg.template.js`, no `presets/` directory, and `grep -c resolveTranscodePreset dist/.../transcode.step.js` returns **0**. The absent `appliedPreset` field in the run logs was the tell. Both compared files were produced by pre-fix code. |
| 2026-07-28 | HP-7 attempt 1 — supporting evidence gathered | `ffprobe -show_entries stream=...` on both files | Docker E2E | informative | Structurally identical: h264 High, 1280×720, `2997/100` fps, **2664 frames**, aac LC 48000 stereo, audio bitrate **127804 exactly equal**. Only video bitrate varied (823130 vs 823472, 0.04%). Encoder tags identical in both — `Lavc61.9.100 libx264` / `Lavf61.4.100` — and `bin/ffmpeg` is unchanged since 2026-03-25 and clean in the working tree, so the same encoder build produced both. |
| 2026-07-28 | Docker rebuild | `docker build --build-arg NODE_AUTH_TOKEN=...` | nova-back-end image | **failed / not performed** | Image tag still points at the April build. Root cause is almost certainly registry auth during `npm ci`: `gh auth token` yields a `gho_` OAuth token that returns **403 "does not match expected scopes"** — it lacks `read:packages`. Only Dustin's PAT works. |

### HP-7 redesigned — what "Standard is unchanged" can actually be proven by

The original HP-7 assumed byte-reproducible output. It is not. Replaced with:

1. **Argument identity (primary, and the real guarantee).** The Standard builder's output array is asserted byte-identical to `ef816e9`'s `template1` against a frozen literal — `standard-depo.preset.spec.ts`, passing. Because the ffmpeg binary is **vendored and pinned** (`bin/ffmpeg` → `/usr/local/bin/ffmpeg`, spawned by exact path), identical arguments plus an identical encoder *is* the encode recipe. This assertion is the proof; it is not a proxy for one.
2. **Parameter identity (E2E confirmation).** `ffprobe` stream parameters for a Standard run must match the pre-change run: codec, profile, dimensions, frame rate, frame count, audio codec/rate/channels/bitrate. Bitstream size and hash are explicitly **excluded** as non-reproducible.
3. **Applied-preset log.** The run must log `appliedPreset: "Standard"` — which doubles as the check that the image under test is not stale.

**Process gap this exposed, recorded so it is not repeated:** the step list handed over had no gate confirming the rebuild had taken effect. Any E2E result is meaningless without first proving which code is inside the image. The verification command is now mandatory before any E2E run:

```powershell
docker run --rm --entrypoint sh ffmpeg-worker -c "grep -c resolveTranscodePreset dist/video-conversion/domain/steps/transcode-step/transcode.step.js"
```

Must return `1` or more. `0` means the image predates the fix and any result is void.

| 2026-07-28 | Docker rebuild — **succeeded on retry** | `docker build --build-arg NODE_AUTH_TOKEN="$env:GITHUB_TOKEN" -t ffmpeg-worker .` | nova-back-end image | pass | Completed in 1.2s with all layers `CACHED`, which read as suspicious but was correct: the earlier attempt had compiled the builder stages and populated BuildKit's layer cache before failing to tag. This run reused them and completed the export. Image stamped `2026-07-28T18:10:58Z`. |
| 2026-07-28 | **Stale-image gate** | `docker run --rm --entrypoint sh ffmpeg-worker -c "grep -c resolveTranscodePreset dist/.../transcode.step.js"` | image under test | pass — returned `1` | `presets/` and `transcode-preset.registry.js` present in `dist`; `ffmpeg.template.js` gone. Confirms the E2E runs below exercised the fix, not April's build. |
| 2026-07-28 | **HP-3 / HP-8 / AC 2 / AC 3 — Standard, live E2E** | `.\scripts\win\run-local-job.ps1`, `$eventId = std-002` | full pipeline, real ffmpeg | **pass** | `transcodeValue:"Standard"` carried into the job (proves the rename end-to-end). `appliedPreset:"Standard"` on **both** the `Transcoding media` and `Transcoding completed` logs (**AC 3**). No fallback warn. `Video conversion completed successfully`. |
| 2026-07-28 | **AC 2 — argument identity proven at runtime, not just in a unit test** | `FfmpegAdapter` debug log, run `std-002` | live ffmpeg invocation | **pass** | The adapter logs the exact `args` array. Compared element-by-element against `ef816e9`'s `template1`: **every element matches** — `-preset fast`, `950k` on `-b:v`/`-minrate`/`-maxrate`, `-bufsize 1900k`, `-r 29.97`, `-vsync cfr`, the full `-x264-params` chain (`force-cfr=1:keyint=12:min-keyint=1:ref=1:bframes=0:qcomp=0.8:aq-strength=0.5:dct-decimate=0:fast-pskip=0:deblock=-2,-2`), `-vf scale=1280:720`, `aac`/`128k`/`48000`/`2`, and the double `afade…areverse` audio chain. x264's own echo confirms they were honoured rather than ignored: `keyint=12 keyint_min=1 bframes=0 qcomp=0.80 aq=1:0.50 decimate=0 fast_pskip=0 deblock=1:-2:-2 rc=cbr bitrate=950 vbv_maxrate=950 vbv_bufsize=1900`. Output: **2664 frames**, 1280×720, 29.97 fps, `kb/s:822.96`, aac 48000 stereo — matching the pre-change baseline's ffprobe read (2664 frames, 823130). **AC 2 is closed.** |
| 2026-07-28 | **NP-1 / AC 4 — fallback, live E2E** | `$env:TRANSCODE_VALUE = "Site Survey"`, `$eventId = fb-001` | full pipeline, real ffmpeg | **pass** | Exactly one `level:40` warn from `TranscodeStep`: `"Unrecognised transcode value; applying fallback"` with `requestedValue:"Site Survey"` and `appliedPreset:"Standard"` — both fields, as AC 4 requires. Emitted **before** the ffmpeg invocation. Standard's argument array then applied, byte-identical to `std-002`. Job **completed successfully** (`videoFileSizeTranscoded: 10592894`, output persisted) rather than failing — the LD-004 behaviour: a substituted preset still yields a deliverable. Output `kb/s:822.31`, 2664 frames. **AC 4 is closed.** |
| 2026-07-28 | Non-determinism — root cause identified | x264 options echo in the run logs | libx264 | informative | `threads=22 lookahead_threads=3 sliced_threads=0`. Frame-threading across 22 threads is why byte-level output varies run to run, confirming the discarded hash test could never have worked at any point. |
| 2026-07-28 | **HP-6 / AC 1 — Video Mix, live E2E** | `$env:TRANSCODE_VALUE = "Video Mix"`, `$eventId = mix-001`, rebuilt image | full pipeline, real ffmpeg | **pass — AC 1 CLOSED** | `transcodeValue:"Video Mix"` in the job; `appliedPreset:"Video Mix"` on start and completion; no fallback warn. Applied args carried `-b:v 2000k` and `-vf yadif=deint=interlaced,scale=1280:720`. **x264 echoed `bitrate=2000 vbv_maxrate=2000 vbv_bufsize=4000`** against Standard's `950 / 950 / 1900` — the encoder's own confirmation that a different preset was applied. Output **15,335,687 bytes** vs Standard's 10,600,047 on the same input: a materially different deliverable, which is the whole point of the ticket. Same 2664 frames, 1280×720, 29.97, aac 48000/stereo/128k as Standard, so only rate control and the deinterlace filter differ, as designed. |

**All four acceptance criteria are now verified in the real pipeline.** AC 1 (mix-001), AC 2 (std-002 argument identity), AC 3 (both runs' logs), AC 4 (fb-001 fallback warn). AC 5 by unit test, AC 6 by diff.

### Final gate run — after the Vid Mix preset was integrated and dependencies repaired (2026-07-28)

Dustin repaired `node_modules` (all four `@planetdepos` packages now match the lock exactly), which unblocked the four suites that could not compile.

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| audit | `npm audit --audit-level=high` | nova-back-end | **FAIL (exit 1)** | 10 vulns / 8 high, unchanged and **all pre-existing** — `package.json` and `package-lock.json` untouched by this change. **Still blocks commit per `git-commit-workflow`.** |
| lint | `npm run lint` | nova-back-end (`eslint .`) | **pass (exit 0)** | — |
| types | `npm run type-check` | whole repo | **pass (exit 0)** | Clean, no errors. Previously impossible; also closes **NP-8** (no dangling `ffmpeg.template.ts` import survives). |
| tests | `npm test -- --runInBand` | nova-back-end, full suite | **pass (exit 0) — 17/17 suites, 87/87 tests** | Up from 12/16 suites and 59 tests. Zero failures, zero non-compiling suites. |
| tests (scoped) | `npx jest --runInBand --coverage=false --testPathPatterns "transcode|preset"` | 4 preset/step suites | **39 passed** | HP-1..HP-4, HP-8, NP-1..NP-3, EC-1, plus the new Vid Mix argument suite. |
| **HP-5 — now executed** | `npx jest --runInBand --testPathPatterns "video-conversion.service.spec"` | service spec | **pass — 5 tests** | Previously *written but unexecuted*. The assertion that `job.transcodeValue` reaches `TranscodeStep.apply` as the third argument now genuinely runs. **The last residual risk from the stale-dependency blocker is closed.** |

### Vid Mix preset integration (2026-07-28)

Source artifact: `Planet Depos Vid Mix v2.json` → `PresetList[0]`, "Planet Depos MP4 Vid Mix 080222". Translated per `source-truth`; nothing inferred.

| HandBrake field | Value | ffmpeg translation |
| --- | --- | --- |
| `VideoQualityType` | `1` (average bitrate) | `-b:v` governs; `VideoQualitySlider: 22` is **inert** |
| `VideoAvgBitrate` | `2000` | `-b:v 2000k` — **vs Standard's 950k** |
| `VideoOptionExtra` | `…vbv-bufsize=4000:vbv-maxrate=2000` | carried inside `-x264-params`, preset's own order |
| rate-control shape | no `minrate` | ABR under a VBV ceiling, **not** Standard's strict CBR |
| `VideoPreset` / `VideoFramerate` / `VideoFramerateMode` | fast / 29.97 / cfr | `-preset fast -r 29.97 -vsync cfr` (same as Standard) |
| `PictureWidth` × `PictureHeight` | 1280 × 720 | `-vf scale=1280:720` (same as Standard) |
| `AudioList[0]` | av_aac / 128 / "48" / stereo | `-c:a aac -b:a 128k -ar 48000 -ac 2` (same as Standard) |

New suite `__specs__/vid-mix.preset.spec.ts` asserts each of the above, and iterates every `VideoOptionExtra` token so a dropped option fails CI. `transcode-preset.registry.spec.ts` gained an assertion on the *shape* of the Standard↔Video Mix difference (bitrate differs, `-minrate` present only on Standard, everything else equal) — so a future edit that accidentally converges the two presets fails rather than passing quietly.

**Three translation decisions are deliberate and recorded, not silent:** `force-cfr=1` added for parity with Standard's timebase handling though absent from `VideoOptionExtra`; the `-af` click-suppression chain carried from Standard with no HandBrake counterpart; and **`PictureDeinterlaceFilter: "decomb"` NOT translated** — see `PRDV-16398-future-development-concerns.md` Concern 4, which is the one item needing Dustin's ruling.

### Superseded — local `node_modules` was stale against the lock file (resolved 2026-07-28)

Four packages installed do not match `package-lock.json`, which is why 4 suites cannot compile and `type-check` cannot pass:

| Package | Declared | Locked | Installed |
| --- | --- | --- | --- |
| `orbital-docking-protocol` | `^1.0.5` | 1.0.5 | **0.2.13** |
| `orbital-relay-pkg` | `1.0.3` | 1.0.3 | **0.3.21** |
| `orbital-receiver-pkg` | `1.1.3` | 1.1.3 | **0.3.9** |
| `pathfinder-observability-pkg` | `^0.2.13` | 0.2.13 | **0.2.9** |

`npm ci` is the fix, but the PAT in `.npmrc` is expired — `npm view @planetdepos/orbital-docking-protocol version` returns **401 unauthenticated**. `.npmrc` is gitignored, so no credential is in git history. A fresh token (`gh auth token` works) would unblock it. **Not attempted** — reinstalling dependencies is an environment change awaiting Dustin's approval.

**Residual risk while blocked:** HP-5 unexecuted, NP-8 unasserted. Neither touches the preset-resolution logic itself, which is covered by the 30 passing transcode-step tests.
