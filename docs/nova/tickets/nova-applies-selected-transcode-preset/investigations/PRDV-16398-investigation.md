# Investigation Report: Nova applies the selected video transcode preset

> **What this is:** the delivered results of running the `investigate` method — findings and recommendation, plus the plan for what happens next.
> **What this is not:** a plan *to* investigate. The investigating is done.

## Metadata

- **Status:** planned
- **Disposition:** proceed with conditions
- **Date:** 2026-07-28
- **Owner:** Dustin Thomason
- **Location:** `docs/nova/tickets/nova-applies-selected-transcode-preset/investigations/PRDV-16398-investigation.md`
- **Ticket:** [PRDV-16398](https://app.clickup.com/t/43227262/PRDV-16398) · **Origin:** [PRDV-14800](https://app.clickup.com/t/43227262/PRDV-14800)
- **Domain:** software
- **Baseline:** `nova-back-end` @ `02b56c0` (branch `main`, clean tree)
- **References / evidence:** four repos read — `nova-back-end`, `nova-orbital-back-end`, `callisto-back-end`, `atlas-front-end`. Coworker spec (read-only input, not adopted): `larry-adams/systems/nebula/video-transcode/PRDV-16398-nova-applies-selected-transcode-preset.md`. Coverage: `PRDV-16398-coverage-ledger.md`. Diagrams: `PRDV-16398-diagrams.md`.

---

## 0. Verdict (bottom line up front — written last, read first)

The defect is real, fully traced, and the ticket's constraint that the fix is `nova-back-end`-only is **confirmed, not merely assumed** — Callisto emits the selection correctly and the value arrives in Nova's domain object intact. Larry Adams' spec is accurate on every Nova-side claim and its code design is sound; this investigation adopts its structural shape. What the investigation changes is the **problem class**, and that reclassification adds four items the spec does not carry: the value's vocabulary is wrong in five places inside Nova, the test suite's detection failure is three-layered rather than one, the completed outbox event can never report a fallback, and the acceptance criteria contradict themselves. Proceeding is correct; proceeding *as specified* would ship a fix whose own local verification silently exercises the fallback path.

- **Strongest path:** value-keyed resolver in `nova-back-end` (Larry's `ResolvedPreset` shape), **plus** convergence of the five vocabulary sites, **plus** a red→green assertion that Video Mix and Standard produce *different* args — verified end-to-end through the existing local Docker harness with `ffprobe` on the real output, not through mocks.
- **Not yet proven / not approved:** the Video Mix encode parameters do not exist in any repo and **will not be inferred** (`source-truth`). Everything except `vid-mix.preset.ts`'s arg values is implementable now; the preset values are gated on the HandBrake artifact. Also unresolved: whether AC 2's "no regression" or the developer note's "fix Standard if it drifted" governs, and whether the AJSF producer widens the reachable value set.

## 1. Problem class

- **Class the request assumed:** Requirements & change management — the producer half of PRDV-14800 shipped and the consumer half was never built.
- **Confirmed class:** **Contract vocabulary mismatch across a service boundary.** Both halves shipped. Nova's consumer reads the field, names it, carries it into the domain object, and asserts it in tests — it simply consumes a *different vocabulary* than the producer emits. Callisto sends a human display label; Nova was built expecting an ffmpeg template identifier.
- **Reframed?** **Yes** → from *"consumer half never built"* to *"consumer built against the wrong vocabulary."* Triggered at **Step 1 (raw facts)** and confirmed at the **Step 4 checkpoint**, by five independent artifacts inside Nova that spell this field's value as `template1`:

  | Site | Value it encodes | Evidence |
  | --- | --- | --- |
  | Domain field name | `template: string` | `src/video-conversion/domain/video-job.ts:8` |
  | Local runner script | `videoTranscodeValue: "template1"` | `scripts/run-local-transcode.sh:116` |
  | Local runbook (seed + reference table) | `"template1"`, `videoTranscodeValue │ template1 (720p H.264 ~950k)` | `docs/local-docker-transcode.md:148`, `:299` |
  | Assembler spec fixture | `videoTranscodeValue: 'template-1'` → `template: 'template-1'` | `__specs__/video-job.assembler.spec.ts:49,95` |
  | Root payload fixtures | `"template": "template1"` | `payload-local.json`, `payload-s3.json` |

- **What the confirmed class implies:** under the assumed class the solution space is "build the missing consumer" — a code-only change. Under the confirmed class the solution must **converge the vocabulary wherever it appears**, because the mismatch lives in the test and verification surface too. Concretely: once a resolver exists, Nova's *own documented local value* `"template1"` becomes an unrecognised value that falls back to Standard, so every local verification run would exercise the fallback while appearing to pass. The assumed class cannot see that failure mode; the confirmed class makes it the first thing to fix.

## 2. Problem statement (the raw facts — collected before classification)

- **Named instances:** one production job, named in the ticket — `fileId: 666549`, `jobId: 644345`. Product selected Video Mix; the delivered file was Standard. Blocked party: Product, on a real deliverable. Every job Nova has processed since PRDV-14800 shipped is also affected, but this is the one instance confirmed and named.
- **One sentence:** Nova receives the customer's transcode selection and encodes with the Standard preset regardless of what was selected.
- **Distinct problems** (deliberately not merged):
  1. **Wiring** — the selection reaches `VideoJob.template` and nothing downstream reads it. Fixable today.
  2. **Capability** — Nova has one preset and has never had a second. Blocked on an external artifact, not on code.
  3. **Vocabulary** — five sites inside Nova encode the wrong meaning for the field (§1). Survives a wiring-only fix.
  4. **Detection** — three layers of the test suite could each have caught this and none *could* fail (§5).
- **Urgency:** already biting — a wrong deliverable has shipped to Product. Sprint 2026-15 (7/22–8/4), tagged `hot fix sprint addition`, priority High. Every Video Mix selection between now and deploy produces a wrong encode.
- **Wedge:** make the applied preset a **function of the received value, with an explicit resolution result** (`{ presetValue, buildArgs, isFallback }`). Reusable within the confirmed class because it forces the vocabulary to be named in one place, makes the mismatch a testable value rather than an invisible assumption, and gives any future preset a single insertion point. A registry of two entries is not the point; the resolution boundary is.

### Problem Check

- **Asked:** build a preset registry in Nova keyed on the received label — *evidence:* "**Fix scope:** `nova-back-end` only — preset registry keyed on `videoTranscodeValue`, wire `job.template` / `transcodeValue` into `TranscodeStep`, add Standard + Video Mix FFmpeg presets."
- **Answered:** the same thing, but the request states a *solution* as the scope. The underlying requirement is "the preset the customer selected must be the preset applied" — *evidence:* "Product selected **Video Mix** in production; the returned file was encoded as ** Standard**." Registry is one implementation of that requirement, not the requirement itself. Naming the requirement separately is what makes the vocabulary sites (§1) visibly in-scope: they defeat the requirement without violating the stated solution.
- **Should-ask:** *"Where else does Nova encode an assumption about what this field means?"* — this decides whether the fix holds or is quietly undone by Nova's own verification path. The asked question, taken literally, does not reach it.
- **Conflation:** **present.** — *evidence:* "**Root cause:** Callisto half of PRDV-14800 shipped; Nova consumer half was never built." One sentence merges the wiring gap and the capability gap. They separate cleanly and must: the wiring gap is provable and fixable now; the capability gap is **blocked** on an artifact outside the codebase. Solving the wiring gap does not touch the capability gap, and shipping the wiring alone with a single preset would satisfy nothing. Keeping them merged is what would let "blocked on HandBrake" read as "the whole ticket is blocked," when in fact all four problems except the preset arg values are actionable today.
- **Thin:** **present, two counts.** — *evidence:* "the returned file was encoded as ** Standard**" and "confirm current `template1` still matches HandBrake ** Standard**". The doubled space before "Standard" recurs in both places, suggesting an elided qualifier in the original text (a product-specific preset name). Separately, "Standard" is used for two different things — the Callisto label `'Standard'` and the HandBrake preset name — which are not guaranteed to be the same string. The registry key must be the Callisto label; the HandBrake name is only the source of the *arguments*.
- **Off:** **present.** — *evidence:* "output matches today's `template1` behaviour (**no regression**)" → contradicted by "confirm current `template1` still matches HandBrake ** Standard**; **fix in the same PR if it drifts**." If `template1` has drifted and the drift is corrected, output does **not** match today's behaviour; AC 2 fails by construction. One of the two must yield, and which one is a decision (§10, D4).

## 3. The contract (locked before any solutioning)

### Acceptance criteria

Ticket criteria 1–6, verbatim in intent, plus the criteria the confirmed class adds (7–8).

| Criterion | Status | What's needed to close it |
| --- | --- | --- |
| 1. `videoTranscodeValue: "Video Mix"` → encodes with the Video Mix preset | **gap** | The preset must exist. Blocked on the HandBrake artifact for arg values; the resolution path is implementable now. |
| 2. `"Standard"` → Standard preset, output matches today's `template1` (no regression) | **needs-proof** | `template1` body moved **verbatim**; byte-identical arg array asserted. Conflicts with the drift instruction — see D4. |
| 3. Structured logs include the applied preset on start and completion | covered by design | Log the resolved `presetValue`, not the requested value, on both messages. |
| 4. Unrecognised/empty → fallback to Standard + `warn` with `requestedValue` and `appliedPreset` | covered by design | `ResolvedPreset.isFallback` drives the `warn`; caller owns the logging. |
| 5. Unit tests assert `'Video Mix'` and `'Standard'` resolve to **distinct** builders, and registry keys are exactly `['Standard', 'Video Mix']` | **needs-proof** | Distinctness assertion must not be tautological (§5). Contract-guard test on the key set. |
| 6. No Callisto, docking-protocol, or infrastructure change required | **covered — verified** | Confirmed by trace, not assumed: the value arrives intact in `VideoJob`; nothing upstream needs to move. |
| 7. *(added)* No site in Nova still encodes `template1` as a `videoTranscodeValue` | **gap** | Converge all five sites in §1, or local verification exercises the fallback while appearing to pass. |
| 8. *(added)* The regression test fails against `02b56c0` and passes after | **gap** | Red→green proof; the existing three assertions cannot fail (§5). |

### Non-goals / out of scope

- **Callisto, `orbital-docking-protocol`, infrastructure.** Verified unnecessary, not assumed so.
- **Adding a stable `presetKey` to the wire contract** — better long-term design, rejected for this ticket (§6).
- **Reporting the *applied* preset on the completed outbox event** — a contract change; the blind spot is real (§8, A7) and becomes a future-development concern rather than scope here.
- **Widening Callisto's eligibility gate** to emit the other four values. Unrelated to this defect.
- **Presets for `Site Survey`, `Day in the Life`, `Other`, `''`** — Callisto does not emit them.
- **Backfilling or re-encoding historical jobs** beyond the one named verification case.

## 4. What changed since the request was created

- **Shifted from:** "the Nova consumer was never built — build it" → **to:** "the Nova consumer was built against the wrong vocabulary — converge it." Lead finding; see §1.
- **What that buys us:** three items that were invisible under the original framing — the five vocabulary sites, the reason local verification would lie, and the fact that the detection failure is structural in three places rather than a single missing test. It also converts "blocked on HandBrake" from a whole-ticket blocker into a single-file blocker.
- **What it still needs to prove:** that the Video Mix args, once supplied, produce a materially different encode from Standard — provable only by running the real encoder (§9), not by unit tests.

## 5. Why it exists

- **Origin traced to:** PRDV-14800 delivered Callisto's producer side (dropdown, `video_job_options` table, outbox event field). Nova's `VideoJobAssembler` was written to receive the field — `video-job.assembler.ts:66` maps `payload.videoTranscodeValue` → `VideoJob.template` — but `TranscodeStep.apply(localInputPath, localOutputPath)` was never given a parameter to receive it, and `transcode.step.ts:25` calls `template1(...)` unconditionally. The value is carried the full length of the pipeline and dropped at the final step.
- **Not a regression.** `template1` is the only preset that has ever existed: five references repo-wide (one definition, one production consumer, three specs). No `template2`, no second builder, at any point.
- **Contract alignment (software lens, candidate 1).** The **authority** for this vocabulary is Callisto: rows in `callisto.video_transcodes` (six values — `Standard`, `Video Mix`, `Site Survey`, `Day in the Life`, `Other`, `''`) as declared in `video-transcode.entity.ts:5-12`, narrowed by the emission gate `is-video-transcode-selection-eligible-for-outbox.ts:12-16` to exactly `Standard` and `Video Mix`. Nova currently mirrors **none** of it. The wire contract offers no help: `CallistoProceedingFileVideoTranscodeRequestedV1Data.videoTranscodeValue` is typed `string`, not a union, so the type system cannot enforce the mirror. **Re-drift risks:** (a) a row is renamed in `video_transcodes` — mitigated by the contract-guard test on the key set; (b) a row is *added* and the gate widened — Nova's fallback keeps it safe but silently, and only the `warn` log reveals it; (c) the id-based path — `videoTranscodeId` is provably unstable (§8, A4) and must not be keyed on.
- **Detection gap (software lens, candidate 4) — three layers, each structurally incapable of failing:**
  1. **Tautological.** `transcode.step.spec.ts:25` builds its expected args by calling `template1` itself, then asserts the transcoder received them. The assertion is true for *any* implementation that calls `template1`, which is precisely the bug.
  2. **Permissive seam.** `video-conversion.service.spec.ts:203-208` asserts the args argument is `expect.any(Array)` — no constraint on content at all.
  3. **Fixture vocabulary.** `video-job.assembler.spec.ts:49,95` asserts the value is *carried* (`'template-1'` → `template`) and never that it is *applied*; and the fixture string is a fake template id, so no real Callisto label ever appears in any test. The test data itself concealed the mismatch.

  This designs the fix's test: assert Video Mix args are **not equal** to Standard args, with expectations that do not call the production builder to compute themselves.
- **Class re-check:** **held after flipping.** The root-cause trace confirms the Step 1 reclassification rather than reverting it — the consumer exists at `video-job.assembler.ts:66` and is simply misaligned. Wedge and acceptance criteria were redone against the confirmed class (criteria 7 and 8 in §3 are the result).

## 6. Alternatives considered

| Alternative | Rejected because |
| --- | --- |
| Key the registry on `videoTranscodeId` | Provably unstable. Migration `1754574059506` shifted every id (`5→6, 4→5, 3→4, 2→3, 1→2`) to free id 1 for `''`. Nothing broke only because nothing consumed the id. A hardcoded id in Nova would silently repoint at the wrong preset on the next such migration, and Callisto has no reason to know Nova cares. |
| Add a stable machine token (`presetKey`) to the wire contract | Better durable design, and genuinely tempting — but it spans three repos (contract, Callisto writer, Nova resolver) with a deploy-ordering constraint, and it does **not** remove the value-keyed path: replayed and in-flight historical messages carry no `presetKey`, so Nova needs the value fallback regardless. Value-keying is a strict subset of that work, not a detour away from it. Revisit if renames become a real operational concern. |
| Type `videoTranscodeValue` as a union in the docking protocol | Would give compile-time exhaustiveness, but it is a contract change (out of scope), and it would break replay of any historical message carrying a since-removed value. The runtime resolver with an explicit fallback is the correct shape for a queue consumer reading arbitrary historical payloads. |
| Throw on an unrecognised value instead of falling back | Fails the job and emits a failure notification for what is, from the customer's view, a still-deliverable file. A wrong-but-usable encode with a `warn` is the better failure mode for a one-shot worker. The contract-guard test, not a runtime throw, is what protects against renames. |
| Keep one `ffmpeg.template.ts` and branch inside `TranscodeStep` | Puts preset selection inside the step that should only apply it, and gives the contract-guard test nothing to assert against. The resolution boundary is the reusable part of the wedge (§2). |
| Fix the wiring only; leave the vocabulary sites for a follow-up | This is the shape Larry's spec implies. Rejected: it leaves Nova's own documented local value resolving to the fallback, so the ticket's own verification path would exercise the wrong branch and still look green. The convergence is what makes the verification trustworthy, not a tidy-up. |
| Report the applied preset on the completed outbox event | Correct instinct — the blind spot is real (§8, A7) — but it is a contract change, explicitly out of scope. Recorded as a future-development concern. |

## 7. Solution & stress-test

- **Proposed solution:** a value-keyed resolution boundary in `nova-back-end`. `resolveTranscodePreset(value: string): { presetValue, buildArgs, isFallback }` over a two-entry registry keyed on the exact Callisto labels; `TranscodeStep.apply` gains the received value and logs the *resolved* preset on start and completion, plus a `warn` carrying `requestedValue` and `appliedPreset` when `isFallback`. `template1`'s body moves **verbatim** to the Standard preset. `VideoJob.template` → `transcodeValue`. All five vocabulary sites converge on real Callisto labels. Larry's `ResolvedPreset` descriptor is adopted as-is: returning the fallback rather than throwing keeps the return type honest and leaves logging with the caller that has the logger.
- **Solves the confirmed class?** Yes, and this is the test that matters. A wiring-only fix solves the *occurrence*. Solving the **vocabulary mismatch** class requires that no site in Nova still asserts the old meaning — hence criterion 7, and hence the five-site convergence. The resolution boundary additionally makes the mismatch a *value* that a test can assert on, which is what stops the class recurring silently.
- **Scale:** two entries today; the reachable set is bounded by Callisto's gate, not by Nova. Adding a third preset is one registry row plus one file. The registry is a compile-time `Record<TranscodePresetValue, PresetArgsBuilder>`, so a key added without a builder fails the build. No runtime cost — a plain object lookup per one-shot job.
- **Generalization:** appropriately sized, deliberately not more. Rejected as overreach: a plugin/discovery mechanism, config-driven presets, or a preset-versioning scheme. Rejected as *too* simple: an inline ternary in `TranscodeStep`, which would leave nothing for the contract-guard test to hold and put selection inside the applying step.
- **Fit:** follows the folder's existing conventions rather than importing new ones. `TranscodeStep` is not `@Injectable()` — it is constructed inline in `VideoConversionService.runPipeline` — and the existing preset module is a plain function export, so the new code stays plain modules. No DI, no Nest provider registry, no `*.module.ts` change. Specs go in the sibling `__specs__/` folder, and `toHaveBeenNthCalledWith` matches repo convention.
- **Adjacent issues:**
  - *Completed-event blind spot (A7)* — **follow-up.** Fixing it means a contract change across repos; the effort is disproportionate to this hot-fix and the `warn` log covers detection in the interim. Tradeoff: until then, a fallback is invisible to Callisto, Atlas, and Product.
  - *The tautological/permissive test assertions (§5)* — **fix now.** They are the reason this shipped, they live in the exact files being edited, and criterion 8 cannot be met without repairing them. Deferring them would leave the fix unprotected.
  - *`omitUpdatedAuditFields` destructuring `updatedBy`*, a field absent from contract 1.0.5 — **follow-up.** Harmless (untyped `Record` passthrough), unrelated to preset selection. Frontier entry.
  - *`scripts/new-ticket-changelog.ps1` cannot target `docs/nova/`* — **cruft candidate**, Phase 6, outside this repo's change.
- **Sufficiency:** covers the pain that convened this — a Video Mix selection produces a Video Mix encode — provided the HandBrake arg values arrive. Without them, everything but one file's contents is deliverable, and the gap is a named blocker rather than a silent shortfall.
- **Feedback speed:** **fast for the mechanism, slow for the values.** The resolution path and the fallback are proven in seconds by unit tests; that Video Mix *matches Product's expectation* is only knowable after a real encode is inspected — locally in minutes via `ffprobe`, or in production only when Product reviews a deliverable. The local Docker harness is what converts this from slow to fast feedback, and is the reason the validation plan insists on it rather than accepting mocked assertions.
- **Actor / action / moment:** the LTR (job submitter) selects Video Mix on the job submission form at submission time; Nova acts on it once, minutes-to-hours later, in a one-shot Fargate task, with no user present. There is no interactive surface — which is exactly why the `warn` log is the only channel through which a fallback can ever be noticed.
- **Happy-path story (30 seconds):** an LTR submits a job and picks Video Mix. Callisto records it and emits the event. nova-orbital lands it in Nova's inbox. Nova's task starts, resolves `"Video Mix"` to the Video Mix arg builder, logs `appliedPreset: "Video Mix"`, encodes with those args, uploads, and exits 0. Product opens the deliverable and it looks like a Video Mix. **Without whom:** no one — no operator, no ops ticket, no manual re-encode request, and no engineer reading a log to discover the wrong preset was used.

## 8. Assumptions ledger

Every claim below is falsifiable, was logged as it was made, and was resolved during Phase 1. Nothing discoverable was carried into §10.

- **A1 — Nothing in production reads `job.template`; the value is dropped.**
  - **Status:** confirmed
  - **Confirm/revise by:** `grep '\.template\b'` across `nova-back-end/src` → zero production reads (only `template1` identifier matches). Refutable by a single reader; none exists.
- **A2 — `template1` is the only preset that has ever existed.**
  - **Status:** confirmed
  - **Confirm/revise by:** five references repo-wide — `ffmpeg.template.ts:1` (definition), `transcode.step.ts:2,25` (only production consumer), and three spec files. Completeness established by the grep being exhaustive over `src/`.
- **A3 — Only `'Standard'` and `'Video Mix'` can reach Nova today.**
  - **Status:** confirmed, **conditional** — holds only while Callisto's gate is the sole producer
  - **Confirm/revise by:** `is-video-transcode-selection-eligible-for-outbox.ts:12-16` admits exactly two of the six `VIDEO_TRANSCODES` values. Refutable by a second producer — see D5 (AJSF), which is precisely why the fallback path is built even though it is currently unreachable.
- **A4 — `videoTranscodeId` is unstable; the label is the safer key.**
  - **Status:** confirmed
  - **Confirm/revise by:** migration `1754574059506-update__add_empty_value__video_job_options_table` shifts `5→6, 4→5, 3→4, 2→3, 1→2`. Cross-check: seed `1751600004000` gave `Video Mix` id 2; post-shift it is 3, matching the production event's `videoTranscodeId: 3`. The renumbering is confirmed by the prod payload itself.
- **A5 — The docking-protocol version skew is a stale local install, not a deploy defect.** *(Phase 0 flag — closed)*
  - **Status:** confirmed
  - **Confirm/revise by:** `package-lock.json:4129` pins `1.0.5`; `node_modules` holds `0.2.13`. `npm ci` reconciles. The 0.2.13 payload type shows `createdBy`/`updatedBy` where 1.0.5 has `createdUserIdentity`/`modifiedUserIdentity`/`createdUserEmail`/`createdUserName`, which is what made the skew visible. No production impact.
- **A6 — The option list is data, not code: a new selectable value needs no code change anywhere.**
  - **Status:** confirmed
  - **Confirm/revise by:** Atlas fetches at runtime (`useJobSubmissionOptions.ts:35-40`, `fetchVideoTranscodes` → `FETCH_VIDEO_TRANSCODES_URL`, 2-minute `staleTime`); values are rows in `callisto.video_transcodes`. This is the load-bearing reason the fallback must exist rather than being defensive padding.
- **A7 — The completed outbox event reports the *requested* value, never the *applied* preset.**
  - **Status:** confirmed — **not covered by Larry's spec**
  - **Confirm/revise by:** `video-job-to-completed-outbox-descriptor.converter.ts:16-24` spreads `job.sourcePayload` verbatim (minus `updatedAt`/`updatedBy`) into the completed event, so `videoTranscodeValue` is echoed as received. If Nova falls back, nothing downstream can distinguish it. → future-development concern.
- **A8 — Nova is a one-shot ECS/Fargate task with no HTTP surface and one job per invocation.**
  - **Status:** confirmed
  - **Confirm/revise by:** `video-conversion-task.handler.ts` — `onModuleInit` → `apply(...)` → `process.exit(0|1)`; `docs/local-docker-transcode.md:5` states it explicitly. Consequence: no concurrency or race surface to model (§9), and no interactive channel for surfacing a fallback.
- **A9 — Jest enforces 80% global coverage with `collectCoverage` always on.**
  - **Status:** confirmed
  - **Confirm/revise by:** `jest.config.json` — `coverageThreshold.global` at 80% for branches/functions/lines/statements. New `.preset.ts` / `.registry.ts` files are **not** in the `collectCoverageFrom` exclusion list, so untested new files can fail the suite. Tests are a gate here, not a preference.
- **A10 — A working local end-to-end harness already exists and can prove the real encode.**
  - **Status:** confirmed
  - **Confirm/revise by:** `docs/local-docker-transcode.md` (LocalStack S3 + DynamoDB Local + `ffmpeg-worker` container), `scripts/run-local-transcode.sh`, and the precedent `scripts/run-local-failure-notification-test.sh`. Output is downloadable from `s3-nova-local-outputs`, so `ffprobe` can compare encodes directly. **Caveat found:** the runner hardcodes `videoTranscodeValue: "template1"` at line 116 and is not parameterised — it must be changed for either preset to be exercised.

## 9. Validation plan

**Happy path**

1. Unit: `resolveTranscodePreset('Standard')` → `{ presetValue: 'Standard', buildArgs: standard, isFallback: false }`; `resolveTranscodePreset('Video Mix')` → the Video Mix builder, `isFallback: false`.
2. Unit: Standard's arg array is **byte-identical** to `02b56c0`'s `template1` output — the AC 2 no-regression proof, asserted against a literal fixture, not against the production builder.
3. Unit: `TranscodeStep.apply(in, out, 'Video Mix')` passes Video Mix args to `TranscoderPort.transcode`; with `'Standard'`, Standard args. **Distinctness asserted directly** (Video Mix args ≠ Standard args) so the assertion cannot pass tautologically.
4. Unit: `VideoConversionService` passes `job.transcodeValue` through as the third argument to `TranscodeStep.apply`.
5. Contract guard: the registry's key set equals exactly `['Standard', 'Video Mix']` — a Callisto rename fails CI.
6. **Red→green (criterion 8):** run the new step spec against `02b56c0`'s `TranscodeStep` and confirm it **fails**; after the change it passes. Without this, the suite's history of un-failable assertions repeats.
7. **Local E2E, the only proof of the real encode:** `scripts/run-local-transcode.sh <clip.mp4> local-NNN` with the seed value set to `'Video Mix'`; download from `s3-nova-local-outputs`; `ffprobe` the output and confirm its parameters match the Video Mix preset and **differ** from a Standard run of the same input. Then repeat with `'Standard'` and confirm parity with a pre-change baseline run of the same clip.
8. Gates: `npm audit --audit-level=high` → `npm run lint` → `npm test -- --runInBand`.

**Negative paths**

- **Must fail visibly, not corrupt silently:** an unrecognised value (`'Site Survey'`) and an empty value (`''`) each encode with Standard **and** emit exactly one `warn` carrying both `requestedValue` and `appliedPreset`. Assert the `warn` call, not merely the args — a silent fallback is the failure mode this whole design exists to prevent.
- **The vocabulary trap (criterion 7):** grep the repo for `template1` as a *`videoTranscodeValue`* after the change; expect zero. Specifically re-check `scripts/run-local-transcode.sh:116`, `docs/local-docker-transcode.md:148,299`, `payload-local.json`, `payload-s3.json`, `video-job.assembler.spec.ts:49,95`. This is a negative path because its failure mode is a *passing* test run against the wrong branch.
- **Neighbours unchanged (protect-the-neighbors):** `MaterializeInputStep`, `ValidateInputStep`, `ProbeDurationStep`, `PersistOutputStep` and the completed / failed / notification outbox writers share `runPipeline`. Verified by: their existing specs stay green **unmodified**, and the failed-path transaction spec (`commitFailedOutboxAndInbox` — failed event + notification + `markFailed` in one DynamoDB transaction) still asserts the same behaviour. The transcode step's error propagation must remain unchanged so pipeline failure handling is untouched.
- **Contract untouched:** `CallistoProceedingFileVideoTranscodeRequestedV1Data` and the completed/failed/notification descriptors are unchanged — the concrete surface for criterion 6. Assert by diff, not by intent.
- **Removed dependency proven non-required:** `ffmpeg.template.ts` is deleted; its three importers (`transcode.step.ts`, `transcode.step.spec.ts`, `ffmpeg.spec.ts`) are the complete set (A2), so no unreferenced import can remain — the build proves it.
- **Timing / limits:** none applicable. Nova is one-shot and single-job (A8), so no concurrency, ordering, or latency bound is at risk. Recorded explicitly rather than omitted.

## 10. Decisions, recommendation & open variables

- **Decisions (settled by evidence during this investigation):**
  - Key on `videoTranscodeValue`, never `videoTranscodeId` (A4, §6).
  - Fall back to Standard with a `warn`; do not throw (§6).
  - `nova-back-end`-only scope — **verified**, not assumed (criterion 6, A1).
  - The fallback path ships even though currently unreachable, because the option list is data (A6) and a second producer may exist (D5).
  - Adopt Larry's `ResolvedPreset { presetValue, buildArgs, isFallback }` shape (§7, Fit).
  - The Phase 0 docking-protocol skew is closed as a local-install artifact (A5).

- **Recommendation (in order):**
  1. Converge the five vocabulary sites (§1) — first, so every later verification runs against the right branch.
  2. Add the resolver + registry + Standard preset (`template1` body verbatim).
  3. Wire `TranscodeStep.apply`'s third parameter and the resolved-preset logging; rename `VideoJob.template` → `transcodeValue`.
  4. Repair the three detection-gap assertions and add the contract guard; prove red→green against `02b56c0`.
  5. Add `vid-mix.preset.ts` **once the HandBrake args are in hand**; verify Standard against HandBrake Standard in the same pass.
  6. Local E2E with `ffprobe` on both presets; then the gates.

- **Sequencing & gates:**
  - Steps 1–4 proceed now; they are complete and testable without the HandBrake artifact.
  - **Step 5 is gated on the HandBrake Video Mix preset.** Do not infer, approximate, or derive the arg values (`source-truth`). Until it lands, `vid-mix.preset.ts` is the single named blocker.
  - **Do not claim AC 1 or AC 2 closed on unit tests alone.** Both are gated on the local E2E `ffprobe` comparison (step 7 of §9) — mocked assertions prove wiring, never encoding.
  - **D4 must be ruled on before AC 2 is written as a test**, since the two readings demand different assertions.

### Open variables to collect

Only genuine decisions remain — each requires someone to choose, not something to find. Owner is Dustin unless noted.

- [ ] **D1 — Do the five vocabulary sites converge in this PR?** Recommend **yes, in scope**. *Why this is a decision, not a lookup:* the code fully answers *what* is wrong at each site; whether a hot-fix PR absorbs doc/script/fixture changes is a scope call. — owner: Dustin
- [ ] **D2 — Should the applied preset reach Callisto, or logs only?** Recommend **logs only** here, plus a future-development-concern entry. *Structural evidence that this cannot be looked up:* `video-job-to-completed-outbox-descriptor.converter.ts:16-24` forwards `sourcePayload` verbatim and the contract type has **no field** for an applied preset — there is no seam to read, so surfacing it requires adding one across three repos. That is a change, not a discovery. — owner: Dustin (+ contract owner if pursued)
- [ ] **D3 — Rename `VideoJob.template` → `transcodeValue` now?** Recommend **yes** — three references, and the name is the vocabulary bug in miniature. Scope call. — owner: Dustin
- [ ] **D4 — AC 2 "no regression" vs. the note's "fix Standard if it drifted."** Needs a ruling; they are mutually exclusive (§2, Off). Recommend: assert byte-identical parity with `02b56c0` as the AC-2 test, and if HandBrake comparison reveals drift, treat the correction as a **separate, explicitly-called-out change** with its own before/after evidence rather than silently redefining AC 2. — owner: Dustin (with Product/ops for the drift call)
- [ ] **D5 — Does the AJSF producer widen the reachable value set?** *Structural evidence this cannot be answered here:* Callisto's gate (`is-video-transcode-selection-eligible-for-outbox.ts:12-16`) is the only emitter present in these four repos; an AJSF path emitting the same event would not appear in any code read for this ticket. The linked ClickUp item ("Transcode video files uploaded through AJSF") is the source. If AJSF bypasses the gate, the fallback becomes reachable in production and D2 gains urgency. — owner: Dustin / Shaye Lankford
- [ ] **D6 — HandBrake Video Mix arg values, and whether Standard has drifted.** Blocked artifact, external source (ops / Lit Tech). — owner: Dustin

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done-when (falsifiable) |
| --- | --- | --- |
| Rule on D1–D4 via Phase 3 grill-me | Dustin | Each has an `LD-###` row in `specs/PRDV-16398-locked-decisions.md` with source and spec destination |
| Answer D5 from the AJSF ticket | Dustin / Shaye | The ticket is read and A3's conditional status is either confirmed or revised in this report via a dated addendum |
| Supply the HandBrake Video Mix preset | Dustin | The arg values are in hand as a source artifact; `vid-mix.preset.ts` is written from it, not inferred |
| Write the spec | agent | `specs/PRDV-16398-spec.md` exists, satisfies `spec-writing` sections, and its locked-decisions section links the ledger |
| Implement steps 1–4 of §10 | agent | New step spec **fails** on `02b56c0` and passes after; registry contract guard green; five vocabulary sites grep clean |
| Prove the encode end-to-end | agent + Dustin | `ffprobe` output for a Video Mix run differs from a Standard run of the same clip, and the Standard run matches a pre-change baseline |
| Ship | agent | `npm audit --audit-level=high` → `npm run lint` → `npm test -- --runInBand` reported as a table; session log written before commit |

### Checklist

#### Investigation

- [x] This report (Sections 0–10)
- [x] Coverage ledger (`PRDV-16398-coverage-ledger.md`)
- [x] Diagrams (`PRDV-16398-diagrams.md`)
- [x] Test plan seeded (`testing/PRDV-16398-test-plan.md`)
- [x] Future-development concerns recorded (A7)

#### Project Spec

- [ ] Rule on D1–D6 (Phase 3 grill-me under qa-to-spec-traceability)
- [ ] Locked-decision ledger
- [ ] Create project spec

#### Development

- [ ] Create branch `PRDV-16398`
- [ ] Begin implementation

#### Testing & Validation

- [ ] Unit + contract-guard suites green; red→green proven
- [ ] Local Docker E2E with `ffprobe` on both presets

#### Deploy & PR

- [ ] Push to GitHub
- [ ] Deploy to sandbox + verify there
- [ ] Open PR
- [ ] Address feedback / wait for approval
- [ ] Merge to main
- [ ] Deploy to test

#### Ticket Closeout

- [ ] Update ClickUp: merged to test
- [ ] Set ticket to Ready for QA
- [ ] Document root cause / why it slipped through — the three-layer detection gap (§5)
- [ ] Re-process the prod case (`fileId: 666549`, `jobId: 644345`) and confirm with Product

---

## 12. Definition of done (investigation gate)

- [x] **Class derived from instances, re-confirmed against root cause — "reframed?" answered with justification (§1)** — yes, flipped at Step 1, held at the Step 4 checkpoint
- [x] Problem Check pass recorded (§2) — all six flags grounded in trimmed ticket quotes; three findings present, none manufactured
- [x] Problem in one plain sentence (§2)
- [x] Named blocked instance — `fileId: 666549`, `jobId: 644345`, Product
- [x] Date it bites next — already biting; Sprint 2026-15, every Video Mix selection until deploy
- [x] Wedge + why it's reusable within the confirmed class (§2)
- [x] Acceptance criteria + non-goals locked **before** the solution was proposed (§3 precedes §7)
- [x] Alternatives recorded with rejection reasons (§6 — seven, including the shape Larry's spec implies)
- [x] 30-second happy-path story (§7)
- [x] Metric that proves it works + how fast it arrives (§7, Feedback speed — `ffprobe` parity/difference, minutes locally)
- [x] Verdict + disposition stated (§0 — proceed with conditions)
- [x] Every open question reconciled (Step 7) — A1–A10 resolved by evidence in §8; §10 holds only decisions, each with an owner; D2 and D5 carry the structural evidence proving they are not lookups
- [x] Tracked action with a falsifiable done-when (§11)
