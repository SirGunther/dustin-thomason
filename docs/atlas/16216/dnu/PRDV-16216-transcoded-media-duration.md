# Investigation Report: PRDV-16216 — Media duration for Nova-transcoded files

> **SUPERSEDED (recommendation only), 2026-07-14** — after principal-dev review, the solution direction changed: see `PRDV-16216-lookup-display-investigation.md` (Callisto read-time lookup for 16216 + separate Nova duration-validation ticket; no protocol change). The evidence and path traces in this report remain valid and are cited by the new report.

> Delivered results of the `investigation` method run on 2026-07-13. Source of truth for the spec that follows.

## Metadata
- **Status:** investigating → planned
- **Disposition:** proceed with conditions
- **Date:** 2026-07-13
- **Owner:** Dustin Thomason
- **Location:** `docs/investigations/PRDV-16216-transcoded-media-duration.md`
- **Ticket:** https://app.clickup.com/t/43227262/PRDV-16216 (verbatim capture: `docs/atlas/16216/PRDV-16216-original-ticket.md`)
- **Domain:** software (cross-service backend data flow)
- **References / evidence:** file/line citations inline throughout; repos `atlas-front-end`, `callisto-back-end`, `nova-back-end`, `nova-orbital-back-end`, external `github.com/PlanetDepos/orbital-docking-protocol`

---

## 0. Verdict (bottom line up front)

The ticket is viable and small in code terms, but it is **not an Atlas ticket**. The display half already shipped (PRDV-9756 UI + PRDV-15875 `files.length` column, both on `main`); the entire gap is that the duration value Nova already measures is discarded instead of being carried to the derived file's row. The strongest path is a three-part backend change — add an optional `duration` field to the Nova completed event (external contract package), have Nova probe the **transcoded output** and emit it, and have Callisto persist it onto the derived `File.length` — after which the existing UI displays it with **zero front-end change**. Per the user's parity requirement, the output must be probed independently (never copied from the source), so the source row and converted row become two independently measured values an operations video expert can compare visually.

- **Strongest path:** contract field (additive, optional) → Nova output-probe + emit → Callisto persist → existing serve/display path untouched.
- **Not yet proven / not approved:** this is not a spec (next artifact), not an approved contract change (external repo, owner unconfirmed), not a backfill commitment (separate ticket), and not a parity-indicator UI (explicitly future work).

## 1. Problem class

- **Class the request assumed:** single Atlas front-end display story ("As an Atlas user… display their media duration").
- **Confirmed class:** **cross-service data-propagation gap** spanning `orbital-docking-protocol` (external contract) → `nova-back-end` → `callisto-back-end`, with zero Atlas code change for display.
- **Reframed?** **Yes** — from *FE display feature* to *backend data-propagation gap*. Triggered at Step 4 (root-cause trace): the display path was proven complete and merged (see §5 evidence), and the only defect found was that the measured value never reaches the database. Hardened when the contract dependency surfaced (the event type lives in an external published package).
- **What the confirmed class implies:** the solution space is event/contract + persistence, not UI. Delivery requires coordination across at least three repos and an external package release — it cannot ship as one `atlas-front-end` ticket. This is the message for product and the principal dev.
- **Parity dimension (added by user during investigation):** an operations video expert uses duration to validate that transcoded runtime matches the source. This ticket *creates* that capability by populating the converted row with an **independently probed output duration** — compared visually against the source row via the existing original/converted nesting. No comparison widget in scope.

## 2. Problem statement

- **Named instances:** every Nova-transcoded video in Atlas today — deterministically, by construction: the derivative persist path never sets `length`, so 100% of derived rows are `NULL` and render the "unavailable" string. (No individually named user in the ticket — open variable for product; the ops video-expert parity use case was supplied by Dustin during this investigation.)
- **One sentence:** A Nova-transcoded video's row in the Atlas proceeding file tables shows "unavailable" in the Length column because its `files.length` value is never populated, while normally uploaded videos show their duration.
- **Distinct problems (kept separate — see Problem Check below):**
  1. **Forward propagation gap** (core): duration measured in Nova is discarded; derived row persists with `length = NULL`.
  2. **Contract evolution:** the completed event type has no duration field and lives in an external published package with no v2 precedent.
  3. **Historical backfill:** already-transcoded rows are `NULL` forever unless remediated — **separate ticket** (decided).
  4. **Duration semantics / parity:** source vs output duration — **decided: probe the output** so parity comparison is meaningful.
  5. **Dead contract type (discovered):** sibling event `NovaProceedingFileVideoTranscodedV1Data` is neither emitted by Nova nor consumed by Callisto in-workspace.
- **Urgency:** live now — the Length column shipped for all files (PRDV-15875 migration dated Jul 9; PRDV-9756 display), so every transcode completion since then produces a visible "unavailable" against neighbors that show durations. Bites on every new transcode.
- **Wedge:** populate `files.length` for one Nova-transcoded video end-to-end. Reusable because (a) it lights up the whole already-merged serve/display path unchanged, and (b) it establishes the contract-threading pattern (Nova pipeline → event field → Callisto persist) for any future transcode metadata (bitrate, resolution, checksums).

### Problem Check findings (thin terms, conflation, drift)
- **Thin: "display"** — implies FE rendering work; the actual gap is data population. The display ships unchanged.
- **Thin: "just like all other video files"** — hides the baseline's semantics: other files' duration is *client-measured at upload* (browser `video.duration`), not server-probed.
- **Thin: "media duration"** — unqualified source-vs-output; resolved to **output** (independent measurement = real parity).
- **Conflation:** the one-sentence AC merges the five distinct problems enumerated above; each is scoped separately in this report.
- **Asked-vs-answered drift:** the ticket asks for a display change; the answer is a pipeline change. Flagged loudly as the §1 reclassification.
- **Contradiction ("off"):** filed as an Atlas story; contains zero Atlas work. Filed under `docs/atlas/`; implementation lands in nova/callisto/protocol.

## 3. The contract

### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| Newly Nova-transcoded video files have `files.length` set to the **output's** duration in whole seconds | gap | Contract field + Nova emit + Callisto persist (§7) |
| Atlas displays that duration in the existing Length column with no FE change | covered (pending data) | Proven merged path (§5); needs only the data to exist |
| Source vs output remain independently measured (parity is real, not copied) | gap → by design | Nova probes `localOutputPath`, never copies source value |
| Failure to obtain duration degrades gracefully (row renders, shows "unavailable") | covered | Existing `lengthUnavailable` branch — assert in specs, don't rebuild |
| Duration format matches all other files ("Xh XXm") | covered | Same `formatMediaDuration` util, same seconds unit |

### Non-goals / out of scope
- **No Atlas front-end changes** — no new column, widget, or format.
- **No explicit parity/mismatch indicator UI** — future story if product wants it; parity here = visual comparison of two rows.
- **No backfill of historical derived rows** — separate ticket (see §10); copy-based backfill is display-only, not parity-grade.
- **No change to the normal-upload capture path** (client-measured `length` stays as is).
- **No audio scope** — Nova's request event is video-specific (`video-transcode-requested`); confirm with Nova owner (ledger #5).

## 4. What changed since the request was created

- **Shifted from:** "make Atlas display duration for transcoded files" → **to:** "carry the duration Nova already measures through the completed event into the derived row's existing `length` column; probe the *output* so the value doubles as parity evidence."
- The **class reframe** (§1) is the headline shift. Second shift: **parity became an explicit requirement** (user, during investigation) — it forces output-probing and rules out the cheapest fix (copying source length).
- **What that buys us:** near-zero UI risk; smallest possible surface (three thin edits per repo); a reusable contract pattern.
- **What it still needs to prove:** contract-change approval and release choreography for the external package; sequencing decision (contract-first vs Callisto loose-read).

## 5. Why it exists — with the data-path trace (current vs target)

**Origin traced to:** the Nova transcode feature shipped its pipeline with duration probing used only for logging, and the Callisto derivative persist path was written before `files.length` existed (PRDV-15875 added the column for the upload path only). Nobody closed the loop for derivatives. Not a regression — a never-built seam between two recently-shipped features (PRDV-9756 display + PRDV-15875 column vs the Nova transcode flow).

### Path A — baseline (normally uploaded video) — WORKS today
1. **Capture (browser):** `atlas-front-end/src/callisto/composables/useMediaDurationParser.ts` — hidden `<video>` element, `loadedmetadata`, `Math.round(video.duration)` → whole seconds.
2. **Send:** `FileUploadWrapper.vue` includes `length` in the upload-complete request (`upload-complete-submission-file.request.dto.ts:102`).
3. **Persist:** `callisto-back-end/src/proceedings/domain/transaction-scripts/upload-complete-proceeding-file-ts/create-proceeding-file-mapper/create-proceeding-file.mapper.ts:29` — `file.length = params.length ?? null` → **`files.length`** (`src/shared/shared-entities/entities/files/file.entity.ts:35-36`, integer, nullable; migration `1780607116489-alter__add_length__files_table.ts`, on `main` via PRDV-15875).
4. **Serve:** `GET /:proceedingId/files` — `fetch-files-by-proceeding-id.action.ts` → `file-attachment-to-proceeding-files-projection.converter.ts:25` (`length: file.length ?? null`) → `ProceedingFileDTO.length`.
5. **Display:** `atlas-front-end` `useProceedingFiles.ts` (vue-query) → `ProceedingFileTableDataRow.vue:99-120` — extension check via `getLengthDisplayKind` (`fileUtils.ts:112-128`; `.mp4` ∈ `MEDIA_EXTENSIONS`) + `length > 0` → `formatMediaDuration(length)` → "Xh XXm". This is the **only** consumer of the duration display in all of Atlas (full-src grep).

### Path B — CURRENT transcoded-file path — where the value dies
1. Callisto emits `callisto.proceeding.file.video-transcode-requested.v1`.
2. `nova-orbital-back-end` listens (`video-conversion-requested.listener.ts` → `.handler.ts`) and launches a Fargate ECS task (`fargate-task.runner.ts`, `RunTaskCommand`).
3. `nova-back-end` pipeline — `video-conversion.service.ts` `runPipeline()` (~93–155): materialize input from S3 → validate → **`ProbeDurationStep` (ffprobe) on the INPUT** (`probe-duration.step.ts` → `ffprobe.adapter.ts:35`, `format=duration`) → `videoDurationSeconds` (line ~113) → ⛔ **passed only to `logger.info` (~134–137), then DISCARDED** → `TranscodeStep` (ffmpeg, `ffmpeg.adapter.ts`) → output size → `PersistOutputStep` (S3) → outbox completed event.
4. Event `nova.proceeding.file.video-transcode-completed.v1` — payload `NovaProceedingFileVideoTranscodeCompletedV1Data` (`@planetdepos/orbital-docking-protocol` `dist/nova/proceeding/file/video-transcode-completed/v1/…d.ts:11-30`) — ⛔ **no duration field exists** (grep of entire `dist/nova/` tree: zero matches). Built by `video-job-to-completed-outbox-descriptor.converter.ts:11-24`, which only adds `transcodedbucketName`/`transcodedfilePath` to the forwarded request payload.
5. Callisto consumes: `nova-proceeding-file-video-transcode-completed.listener.ts` → `proceeding-video-transcode-completed-inbox.handler.ts` → payload parser (`REQUIRED_FIELDS`, loose `candidate[key]` reads) → `process-proceeding-video-transcode-completed.service.ts` (lines 51–62) → assembler (derivative name is **always `*.mp4`**: `resolve-video-transcode-processing-context.assembler.ts:23,146-150`) → `persist-video-transcode-derivative.mapper.ts` `buildDerivativeFile()` (88–104) sets bucket/filePath/fileName/fileSize/fileType — ⛔ **never `file.length` → row persists NULL**.
6. Serve path (identical to A4) returns `length: null`.
7. Display (identical to A5): `.mp4` → `'media'`, `length == null` → renders `common.callisto.files.lengthUnavailable`.

### Path C — TARGET path (deltas marked ➕; everything else unchanged)
3′. ➕ After `TranscodeStep`, probe the **OUTPUT** (`materialized.localOutputPath`) with the existing, path-agnostic `ProbeDurationStep`/`getDuration` — a one-call addition, not structural. ➕ Thread the value: `video-conversion.service.ts` → `commitCompletedOutboxAndInbox(job, workerId, durationSeconds)` → `video-conversion-outbox-writer.port.ts` `writeCompletedEvent` → `video-conversion-outbox-writer.assembler.ts` → `video-job-to-completed-outbox-descriptor.converter.ts` adds `duration` to `completedData`. (Keep the existing input probe/log for ops telemetry — independent values stay independent.)
4′. ➕ **Contract:** add optional `duration?: number` (integer whole seconds — same unit as `files.length`) to `NovaProceedingFileVideoTranscodeCompletedV1Data` in `github.com/PlanetDepos/orbital-docking-protocol`; publish; bump in `nova-back-end` and `callisto-back-end`. Additive-optional recommended (no v2 precedent exists in the package — every event is v1-only).
5′. ➕ **Callisto:** parser passes `duration` through (do **not** add to `REQUIRED_FIELDS` — must stay optional) → service passes `length: command.duration ?? null` into `persistDerivativeTS.apply({...})` (mirrors how `command.fileSize` is read) → `persist-video-transcode-derivative.param.ts` gains `length?: number | null` → mapper `buildDerivativeFile()` sets `file.length = params.length ?? null` (mirrors `create-proceeding-file.mapper.ts:29`).
6′–7′. **Unchanged** — the existing serve and display paths render the value automatically; source row (client-measured) and converted row (output-probed) are now independently comparable.

- **Class re-check:** **held** — the root-cause evidence (value discarded at B3, contract missing field at B4, persist skipping `length` at B5) is entirely backend/contract. Wedge and AC unchanged.

## 6. Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| Callisto copies `sourceFile.length` → derived row (no Nova/contract change) | **Rejected — legal-deliverable integrity (principal-dev ruling).** A copied value equals the source by construction, so it *asserts* the deliverable matches the source without ever *verifying* it. In a legal videography pipeline a truncated/incomplete transcode = lost evidence = potential lost client; the length must be independently measurable, not assumed. Cheapest path (one line, source `File` already loaded in the handler) but non-negotiably insufficient. |
| Callisto probes the transcoded file itself (S3 download + ffprobe in Callisto) | Gives Callisto a media-tooling responsibility it doesn't have; Nova already has ffprobe *and* the file on local disk at the exact moment — zero marginal cost there. |
| Atlas computes duration at display/preview time | Requires fetching media to the client to read metadata; expensive, wrong layer, breaks for restricted files. |
| New `v2` event instead of additive field | No v2 precedent anywhere in the package (19 v1 dirs, zero v2); additive-optional is backward compatible and doesn't force simultaneous consumer upgrades. Gate: protocol owner sign-off. |
| Dedicated parity indicator (expected-vs-actual + mismatch badge) | Real FE + schema work; separable. Parity *data* is created by this ticket; the *indicator* is a future story if product wants it. |
| Emit on the unused sibling `video-transcoded` event | Dead in-workspace (never emitted/consumed); building on it adds risk and clarifies nothing. |

## 7. Solution & stress-test

- **Proposed solution:** Path C above — contract field (additive optional) + Nova output-probe & emit + Callisto persist; Atlas untouched.
- **Solves the confirmed class?** Yes — it closes the propagation seam itself (pipeline → contract → persist), not just this symptom; the same threading serves future transcode metadata.
- **Scale:** one integer per transcode event; no volume concern. Probe adds one ffprobe invocation per job (~ms against a transcode measured in minutes).
- **Generalization:** field named `duration` scoped to this event; no premature abstraction. The threading pattern is the reusable part.
- **Fit:** mirrors existing conventions exactly — mapper mirrors `create-proceeding-file.mapper.ts:29`; probe reuses `ProbeDurationStep`; parser stays loose-optional like existing undeclared-field reads (`createdUserIdentity` precedent).
- **Adjacent issues:** (a) backfill — spin off (§10); (b) dead `video-transcoded` contract type — report to protocol owner, don't touch; (c) package version anomaly `^1.0.5` declared vs `0.2.13` installed — must be resolved before pinning a new version (ledger #7).
- **Sufficiency:** covers the ticket's AC fully and creates the parity capability that motivated it; only historical rows remain (deliberately, as a separate ticket).
- **Feedback speed:** fast — first post-deploy transcode proves it end-to-end (DB query + one glance at the UI). Metric: % of newly created derived rows with non-null `length` (target 100% of successful transcodes), queryable immediately via `file_derivations` (`processType='transcode'`, `producerSystem='Nova'`) joined to `files`.
- **Happy-path story (30s):** An ops video specialist opens a proceeding in Atlas. The converted `interview.mp4` row reads "1h 02m". They click *Show original*: `interview.mov` also reads "1h 02m" — content runtime verified, no file opened, no other person involved. If the converted row ever reads "1h 01m" against the source's "1h 02m", that visible difference *is* the parity signal and they flag the transcode.

## 8. Assumptions ledger

1. **"Atlas needs no code change for display."** — **confirmed.** Full-src grep: `formatMediaDuration`/`getLengthDisplayKind` consumed by exactly one display component (`ProceedingFileTableDataRow.vue:99-120,236-238`, shared by SubmissionFiles + ClientDeliverables tables); no transcode/lineage conditional exists; derivative fileName always `.mp4` (assembler :23,146-150) so the extension gate passes; column + serve path merged on `main` (PRDV-15875 `8bce8a93`/`3f5e5c07`; PRDV-9756 `d6e5448a`).
2. **"Nova measures duration but discards it."** — **confirmed.** `video-conversion.service.ts` ~113–137: probed into a local, passed only to `logger.info`.
3. **"The completed event has no duration field."** — **confirmed.** Type fields enumerated (`…v1.d.ts:11-30`); grep of `dist/nova/` for duration: zero.
4. **"Transcoded and uploaded files share the `files` table/serve path."** — **confirmed.** `file-derivation.entity.ts` links two `files` rows; same projection serves both.
5. **"Nova transcodes video only (audio out of scope)."** — **confirmed directionally.** Request event is video-specific; not exhaustively verified across Nova. Confirm/revise by: ask Nova owner.
6. **"Sibling `video-transcoded` event is unused."** — **confirmed in-workspace** (no emit in `nova-back-end/src`, no consume in `callisto-back-end/src`); **open** outside workspace. Confirm/revise by: protocol owner / org-wide search.
7. **"Package version `^1.0.5` (declared) vs `0.2.13` (installed) is an anomaly needing resolution."** — **open.** Confirm/revise by: check the package registry + `orbital-docking-protocol` repo tags before pinning the new version.
8. **"Callisto's loose parser allows reading `duration` before the typed package lands."** — **confirmed** (`candidate[key]` reads; undeclared `createdUserIdentity` precedent). Whether to *rely* on it is a sequencing decision, not a necessity.
9. **"Backfill via source→derived copy is feasible where source `length` is non-null."** — **confirmed mechanically**; **parity-grade: refuted** (copied values are display-only by definition). Product decision pending.
10. **"Output duration ≈ source duration for our transcodes."** — **open** (and deliberately *not assumed by the design* — that's the point of measuring both). Reality answers it post-deploy.

## 9. Validation plan

**Happy path**
1. Upload a video (source row `length` populated by browser measurement).
2. Request transcode → nova-orbital launches the Fargate task → Nova transcodes, probes the **output**, emits `duration` on the completed event.
3. Callisto persists the derived `File` with `length` = emitted seconds. Verify in DB: derived row via `file_derivations` join has non-null `length` approximating the output's runtime.
4. `GET /:proceedingId/files` returns `length` on the derived row.
5. Atlas converted `.mp4` row renders "Xh XXm"; *Show original* exposes the source row's duration for visual parity.

**Negative paths**
- **Probe fails / returns ≤ 0:** Nova must still complete the transcode and emit the event with `duration` absent/null — duration is enrichment, never a failure gate. Derived row persists NULL → Atlas shows "unavailable" (existing branch). Must fail visibly in Nova logs, not block delivery.
- **Event without `duration`** (old Nova version, mid-rollout): Callisto parser must not reject (field NOT in `REQUIRED_FIELDS`); persists NULL; no crash. Proves rollout-order independence.
- **Source ≠ output duration:** the difference must **surface** (two rows show their own values) — never be masked or reconciled.
- **Contract mismatch:** consumers on the old package version must be unaffected by the additive field (assert additive-only in the protocol PR).
- **Non-media/PDF rows:** unchanged behavior (extension gate) — covered by existing FE specs.

### Test map (where each change is proven)
| Repo | Suite (existing) | What to assert |
|------|------------------|----------------|
| nova-back-end | `video-conversion-service/__specs__/video-conversion.service.spec.ts` | output probe invoked post-transcode; duration threaded to outbox commit; probe failure → event still emitted |
| nova-back-end | `steps/__specs__/probe-duration.step.spec.ts` | existing; extend only if step wrapper changes |
| nova-back-end | `…/__specs__/video-job-to-completed-outbox-descriptor.converter.spec.ts` | payload includes `duration`; omitted → absent, not `NaN` |
| nova-back-end | `…/__specs__/video-conversion-outbox-writer.assembler.spec.ts` + `src/test-utils/test-utils.ts` (`createMockVideoJob`) | signature threading; shared factory update ripples to all above |
| callisto-back-end | `…payload-parser.converter.spec.ts` | `duration` optional: parses when present, passes when absent |
| callisto-back-end | `…process-proceeding-video-transcode-completed.service.spec.ts` | `length: command.duration ?? null` reaches TS params |
| callisto-back-end | **`…persist-video-transcode-derivative.mapper.spec.ts`** (primary) | sets `file.length`; defaults null when absent — mirror pattern `create-proceeding-file.mapper.spec.ts:705-812` |
| callisto-back-end | `…transaction.script.spec.ts`, inbox handler/listener specs | touch only if signatures change |
| atlas-front-end | **no changes** — existing coverage cited: `__specs__/formatMediaDuration.spec.ts`, `ProceedingFileTableDataRow/__specs__/ProceedingFileTableDataRow.spec.ts`, `SubmissionFilesTable/__specs__/SubmissionFilesTable.spec.ts` | already assert media/pdf/none + unavailable branches |
| orbital-docking-protocol | external repo — conventions unknown from workspace | **open variable** (owner to confirm test expectations) |

Gate commands: Jest backends `npm test -- --runInBand`; Atlas `npx vitest run --maxWorkers 1` (per git-commit-workflow; report exact command + scope + result at ship time).

## 10. Decisions, recommendation & open variables

- **Decisions (settled this investigation):**
  1. Reuse the existing `length` → `formatMediaDuration` path; no new UI/format/column.
  2. Nova probes and emits the **output** duration **only**; the stored source `File.length` is the established reference (Nova does not re-communicate it). Independent measurement is a **legal-deliverable-integrity non-negotiable** (dustin ruling): the deliverable length must be *verifiable* against the source, never copied/assumed.
  3. Verification = visual comparison of the stored source length vs the converted length in the existing two-row (original/converted) view — no Atlas change.
  4. Backfill = separate ticket, with the copy≠parity caveat recorded.
  5. Contract change = additive optional `duration` (integer seconds) on the completed event, pending protocol-owner approval.
- **Recommendation (in order):**
  1. Resolve open variables #1–3 below (protocol ownership/versioning, sequencing) with principal dev.
  2. Write the spec (`write-spec` skill) from this report: sections for protocol, nova-back-end, callisto-back-end; Atlas section = explicit N/A with the §5 proof.
  3. Communicate the reclassification to product: the ticket's goal is reachable, but not within one Atlas ticket — proposed decomposition: **(1) contract field → (2) Nova emit → (3) Callisto persist → (4) Atlas: none → (5) backfill (separate/optional)**.
- **Sequencing & gates:** contract-first is the clean order (1 → 2, 3). A pragmatic alternative exists — Callisto's loose parser could read `duration` before the typed package lands — but do **not** start implementation until the protocol owner rules on additive-vs-v2; do not commit to backfill until product accepts the source-null residual gap and the display-only caveat.

### Open variables to collect
- [ ] Protocol package owner + additive-field vs v2 policy — owner: principal dev / protocol owner
- [ ] Sequencing: contract-first vs loose-read interim — owner: principal dev
- [ ] Version anomaly `^1.0.5` declared vs `0.2.13` installed — owner: Nova dev(s) / dev-ops
- [ ] Is `video-transcoded` (sibling event) consumed by any system outside this workspace? — owner: protocol owner
- [ ] Named requesting user / ops group for the parity use case — owner: product
- [ ] **Source-reference coverage** — comparison relies on the stored source `File.length`, which the investigation found is captured **only** browser-side (null for non-web formats: `.mts`/AVCHD, `.mkv`, `.avi`, `.wmv`…, common in legal video). Larry indicates capture happens "through other means" not found in the investigation. Confirm a non-browser source capture exists; if not, the verification has a blind spot for exactly those formats (output measured, source blank → nothing to compare). — owner: Dustin / Larry
- [ ] Backfill: wanted? residual-gap + display-only caveat accepted? — owner: product
- [ ] Explicit parity-indicator UI as a future story? — owner: product
- [ ] Confirm Nova is video-only (audio N/A) — owner: Nova dev(s)
- [ ] Protocol repo test conventions — owner: protocol owner

---

## 11. Plan — Next steps

### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Confirm protocol ownership + additive-vs-v2 ruling | Dustin → principal dev | Written answer recorded in changelog; open variables #1–2 closed |
| Draft spec from this report (`write-spec`) | Dustin | Spec exists covering protocol/nova/callisto sections + Atlas N/A with proof; reviewed against §3 AC table |
| Present reclassification + decomposition to product | Dustin | Product acknowledges multi-repo scope; ticket updated or split in ClickUp |
| Backfill decision | Product | Yes/no recorded; if yes, separate ticket created with residual-gap caveat verbatim |
| Version-anomaly check | Nova dev | Declared range and published versions reconciled; safe target version named |

### Checklist
#### Investigation
- [x] This report (Sections 0–10)

#### Project Spec
- [ ] Draft open questions / unknowns (→ §10 open variables)
- [ ] Create project spec

#### Development
- [ ] Create new branch(es) — per decomposition, not in atlas-front-end
- [ ] Begin implementation

#### Testing & Validation
- [ ] Test and validate per §9 test map

#### Deploy & PR
- [ ] Push / sandbox verify / PR / merge / deploy-to-test (per repo)

#### Ticket Closeout
- [ ] Update ClickUp with reclassification outcome; Ready for QA when the §9 happy path passes in test

---

## 12. Definition of done (investigation gate)
- [x] Class derived from instances, re-confirmed against root cause; reframed **yes**, at Step 4, with justification (§1)
- [x] Problem in one plain sentence (§2)
- [x] Named blocked instance (§2 — deterministic instance class; individual name = open variable for product)
- [x] Date it bites next (§2 — live now, every transcode)
- [x] Wedge + why reusable (§2)
- [x] AC + non-goals locked before solutioning (§3)
- [x] Alternatives with rejection reasons (§6)
- [x] 30-second happy-path story (§7)
- [x] Metric + arrival speed (§7 — non-null-length rate on new derived rows; first post-deploy transcode)
- [x] Verdict + disposition (§0 — proceed with conditions)
- [x] Open variables each have an owner (§10)
- [x] Tracked actions with falsifiable done-whens (§11)

---

## Appendix — process notes for the `investigation` skill (user-requested)
1. **Run investigations in plan mode** — add to the skill preamble.
2. **State the purpose up front:** an investigation determines the spec to be written, what must be collected/asked of product and other devs, and ultimately supports presenting the spec + rationale to the principal dev. It is not a handoff.
3. **Add a "test map" question:** every software investigation should answer *where each proposed change gets tested* (existing suites, per repo) before the spec is written.
4. **Discipline gap observed this run:** the Problem Check lens was applied once at Step 2 but not re-run as new evidence arrived, and the assumptions ledger wasn't surfaced in-conversation until challenged. Consider requiring the ledger to be shown at each checkpoint.
