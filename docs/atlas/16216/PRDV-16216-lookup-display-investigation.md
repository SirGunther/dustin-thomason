# Investigation Report: PRDV-16216 — Lookup-display pivot + duration-validation companion ticket

> Delivered results of the `investigation` method, re-run 2026-07-14 after the principal-dev (Larry Adams) direction change. **Supersedes the recommendation of** `PRDV-16216-transcoded-media-duration.md` (2026-07-13) — that report's evidence (path traces, entity/serve-path findings) remains valid and is cited here; its *solution* (protocol field + Nova emission + Callisto persist) is superseded.

## Metadata
- **Status:** planned
- **Disposition:** proceed (16216); proceed with conditions (companion ticket — needs product buy-in)
- **Date:** 2026-07-14
- **Owner:** Dustin Thomason
- **Location:** `docs/atlas/16216/PRDV-16216-lookup-display-investigation.md`
- **Ticket:** https://app.clickup.com/t/43227262/PRDV-16216 (verbatim: `PRDV-16216-original-ticket.md`)
- **Domain:** software
- **References / evidence:** file/line citations inline; prior report `PRDV-16216-transcoded-media-duration.md`; principal-dev conversation 2026-07-14 (relayed by Dustin)

---

## 0. Verdict (bottom line up front)

Split the work in two, per the principal-dev direction. **PRDV-16216 becomes a Callisto-only, read-time change:** when serving the proceeding file list, a transcoded (derived) file whose `length` is null falls back to its source file's `length`, resolved through the existing `file_derivations` ID linkage — the value the UI then displays in the already-existing Length placeholder. The serve path **already fetches the full source `File` row (including `length`) and discards it**, so this is an in-memory change at ~4 edit points: no SQL change, no schema change, no protocol change, no Atlas change — and it covers **all historical transcoded files immediately**, dissolving the backfill ticket. **A new companion ticket (product buy-in required)** moves the integrity concern upstream: Nova compares the input duration (already probed today, currently only logged) against the transcoded output's duration (one new probe) and, on mismatch, fails the job through the **existing, fully-built failure pipeline** (failed event + failure-notification email; no output delivered). Once that lands, "completed transcode ⇒ durations matched" is an enforced invariant, which is exactly what makes 16216's displayed lookup value trustworthy. **Neither ticket requires the `orbital-docking-protocol` contract change** — the previous plan's heaviest dependency falls away entirely.

- **Strongest path:** ship 16216 (Callisto read-time fallback) now; draft the companion validation ticket for product sign-off in parallel.
- **Not yet proven / not approved:** product buy-in on the companion ticket's failure semantics (mismatch = failed job + email) and template choice; tolerance threshold; acceptance that until the companion lands, the displayed value is an assumption rather than a validated invariant; the source-null residual gap (below) is a display limitation product must accept.

## 1. Problem class

- **Class the previous report confirmed:** cross-service data-propagation gap (protocol → Nova → Callisto).
- **Class after the principal-dev ruling — reframed again, deliberately:** two separable classes:
  1. **16216 — a read-time presentation fallback** (single repo, `callisto-back-end`): the display value is *derivable from data Callisto already loads*; nothing needs to move through the pipeline for the ticket's stated goal.
  2. **Companion ticket — a pipeline integrity invariant** (single repo, `nova-back-end`): validation of transcode completeness belongs at transcode time, inside Nova, using the failure machinery that already exists — not in a human's eyeball comparison downstream.
- **Reframed?** Yes — from *one cross-service propagation change* to *presentation fallback + upstream validation invariant*, triggered by the principal-dev decision to keep 16216 minimal and to convert the integrity check from "human compares two displayed numbers" into "Nova enforces it and errors loudly."
- **What the split implies:** each ticket is single-repo, independently shippable, and the external-package dependency (contract field, version pin, release choreography) disappears from both. The integrity requirement from the earlier ruling is *strengthened*, not dropped: an enforced pipeline invariant catches a bad transcode every time, where the two-row visual comparison relied on someone looking.

## 2. Problem statement

- **One sentence (16216):** a transcoded video's row shows "unavailable" in the Length column even though the system knows, via `file_derivations`, exactly which source file it came from and that source's stored duration.
- **One sentence (companion):** nothing in the pipeline verifies that a transcode produced output of the same duration as its input, so an incomplete conversion would complete silently.
- **Terminology note:** the discussion used "file size" loosely; the quantity throughout is **media duration** (`files.length`, integer whole seconds). `fileSize` (bytes) is already captured for derivatives and is not at issue.
- **Named instance:** every Nova-transcoded video row (derived `files.length` is never written — prior report §5, still true).
- **Urgency:** live now, every transcode. The companion's urgency is the legal-deliverable integrity risk: an undetected short transcode in a proceeding deliverable is lost evidence.
- **Wedge (16216):** thread `sourceFile.length` through the already-existing lineage map into the converted row's serve-time projection. Reusable: same mechanism serves any future source-derived display fallback, and it exercises the one code path both file-list endpoints share.

## 3. The contract

### Acceptance criteria — PRDV-16216
| Criterion | Status | What closes it |
|-----------|--------|----------------|
| A transcoded file's row displays a duration in the existing Length placeholder | gap | Callisto read-time fallback (§5 target path) |
| The displayed value equals the source file's stored duration, resolved by ID linkage (never by name) | gap | `file_derivations` lookup — IDs only; rename-proof (prior session verification) |
| Works for already-existing transcoded files, not just new ones | gap → free | Read-time fallback applies to every historical row; **no backfill ticket needed** |
| No Atlas front-end change; existing format ("Xh XXm" / HH:MM:SS per PRDV-16231) | covered | FE renders whatever `length` the API returns (prior report §5, assumption #1) |
| Source with no stored duration → row still renders, shows "unavailable" | covered | Fallback yields null → existing `lengthUnavailable` branch (residual gap, §7) |

### Acceptance criteria — companion ticket (draft, for product)
| Criterion | Status | What closes it |
|-----------|--------|----------------|
| Nova measures the transcoded output's duration after `TranscodeStep` | gap | One new `ProbeDurationStep` call on `localOutputPath` (input probe already exists) |
| Input vs output durations compared within a defined tolerance | gap | Comparison in `runPipeline`; tolerance TBD (open variable) |
| Mismatch fails the job through the existing failure flow — no output persisted, no completed event, failure notification sent | gap | Throw before `PersistOutputStep`; existing catch → `writeFailedEvent` + `writeNotificationRequestedEvent` + `markFailed` handles it unchanged (§5 evidence) |
| Failure reason identifiable (not a generic message) | gap | `errorCode` slot exists on the failed event (currently hardcoded `null`) and/or a distinct notification template — product/template decision (open variable) |

### Non-goals
- **16216:** no schema change; no persisted copy of the source value (DB stays honest: null = never measured); no protocol change; no Atlas change; no Nova change.
- **Companion:** no protocol change (comparison is internal to Nova; failure events already exist); no persistence of measured durations to the database (possible future enhancement — open variable); no new UI.
- **Both:** no backfill ticket — dissolved by the read-time approach.

## 4. What changed since the prior report (the superseded decisions)

| Prior decision (2026-07-13) | Status now | Why |
|---|---|---|
| Add `duration` to the completed event (`orbital-docking-protocol`) + Nova emits + Callisto persists | **Superseded** | Principal-dev direction: keep 16216 minimal; validation moves inside Nova where both numbers exist locally — no contract change needed anywhere |
| "Copy rejected — non-negotiable" (integrity ruling) | **Revised, intent preserved** | The integrity requirement stands but is satisfied *upstream*: once Nova errors on mismatch, "completed ⇒ matched" is enforced, so displaying the source's value for a completed transcode is no longer an unverified assumption — it's the invariant's consequence. Until the companion ships, it *is* an assumption; product must accept the interim (open variable) |
| Verification = human compares two rows visually | **Superseded (strengthened)** | Automated pipeline check replaces eyeball QC as the primary control; the two-row view remains as secondary transparency |
| Backfill = separate ticket | **Dissolved** | Read-time fallback covers all historical rows with zero migration |
| Nova story spec + dev note (`PRDV-16216-nova-emits-transcoded-output-duration.md`) | **Superseded for 16216** | Raw material for the companion ticket's spec — but note the companion differs: probe + compare + fail, **no emission, no protocol field** |
| "No Atlas work" | **Unchanged — still true** | Confirmed again: FE renders the API's `length`; fallback happens server-side |

## 5. Why it exists + data paths (current vs target), grounded

### The lookup is nearly free — key evidence (verified 2026-07-14)
The file-list serve path (`GET /proceedings/:proceedingId/files`, shared by the job-submission endpoint via `ProceedingAggregator` → same `FetchFilesByProceedingIdTS`) already:
1. Runs a second query for lineage: `file-derivation.repository.ts:109-161` — `fetchCompletedTranscodeDerivationsByFileIds` with **`innerJoinAndSelect('derivation.sourceFile', 'sourceFile')`** → the **entire source `File` row, `length` included, is already hydrated**.
2. Then discards it: `transcode-lineage-map.assembler.ts:16-37` keeps only `{derivationId, sourceFileId, derivedFileId}` (its own doc comment: *"it never reads the full source/derived file metadata, so we don't project them here"*).
3. Tags rows: `pair-original-and-processed.converter.ts:29-54` — the `CONVERTED` branch (lines 35-41) spreads `...file`, keeping the derived row's null `length`. **This branch is the fallback's landing spot.**

### Target path — PRDV-16216 (all in-memory, `callisto-back-end` only)
| # | Edit point | Change |
|---|---|---|
| 1 | `proceeding-files.projection.ts:28-32` (`TranscodeLineageEntry`) | Add `sourceLength: number \| null` |
| 2 | `transcode-lineage-map.assembler.ts:28-32` | Populate it from `derivation.sourceFile.length` (already in memory) |
| 3 | `pair-original-and-processed.converter.ts:35-41` (CONVERTED branch) | `length: file.length ?? derivedEntry.sourceLength ?? null` |
| 4 | `fetch-files-by-proceeding-id.response.dto.ts:32-37` | Update the `length` `@ApiPropertyOptional` description (semantic: "for converted files, falls back to the source file's length") |

Notes: derivation query already matches `derived_file_id IN fileIds` (repo line 137), so the source row is fetched even when the source itself isn't in the filtered view — the fallback works on the deliverables view too. Both endpoints inherit the change (they converge on this TS). Historical rows covered automatically.

### Target path — companion ticket (`nova-back-end` only)
`video-conversion.service.ts` `runPipeline` order (verified): materialize → validate → **`ProbeDurationStep` on INPUT** (:113-116, logged only at :134-137) → `TranscodeStep` (:118-121) → fileSize (:123-125) → `PersistOutputStep` (:127-130) → completed commit (:132). Single catch at :138-154 → `commitFailedOutboxAndInbox` (:176-201) → **transactionally**: `writeFailedEvent(job, errorMessage)` + `writeNotificationRequestedEvent(job)` + `inbox.markFailed`; rethrow; ECS task exits 1.

Change: after `TranscodeStep`, probe **output** (`localOutputPath`) — **the secondary probe is required** (nothing probes the output today; the existing probe is input-side, pre-transcode) — compare to the input value within tolerance; on mismatch **throw**. Everything downstream is already built:
- Failed event `nova.proceeding.file.video-transcode-failed.v1` — payload has `errorMessage: string` **and `errorCode: string | null`** (currently hardcoded `null` at `video-job-to-failed-outbox-descriptor.converter.ts:28`) — a `DURATION_MISMATCH` code slots in naturally.
- Failure email — the existing `VIDEO_TRANSCODE_FAILED` notification: event code + MJML template + seed config (`callisto-back-end/src/notifications/…`; recipients: initiator + videosubmissions@ + LitTechMgmt@; subject "Action Required: Manual File Conversion Needed – Job #…"). **The current template has no reason slot** — its copy says "unable to automatically convert." Product/template decision: reuse as-is (mismatch email reads like any other failure) vs. add a distinct "Duration Mismatch" event code + template (the notifications module has a documented "Adding a new template" recipe: new MJML + key + registry + typed data + seed migration).
- Because the throw happens **before** `PersistOutputStep`: no S3 output, no completed event, no derivative row — so 16216's lookup never displays a value for a failed transcode at all. The two tickets compose: **completed ⇒ validated ⇒ displayed value is trustworthy.**

## 6. Alternatives considered

| Alternative | Rejected because |
|---|---|
| **Persist-time copy** (`buildDerivativeFile` sets `file.length = originalFile.length`; context already loads the source) | Writes an *assumed* value into the DB indistinguishable from a measured one (provenance); needs a separate backfill for historical rows; rows persisted before the companion ships would carry permanently unvalidated copies. Read-time fallback keeps the DB honest (null = never measured) and covers history for free. |
| **Atlas FE lookup** (converted row falls back to `allFiles.find(sourceFileId).length`) | Feasible (FE already receives source rows) but must be duplicated across both tables and any future consumer; API consumers other than the tables (e.g. the PRDV-16229 combined-duration FAB summing `length`) would disagree with what rows display. Server-side fallback keeps every consumer consistent, still with zero FE change. |
| **Prior plan: protocol field + Nova emission + Callisto persist** (2026-07-13 report/spec) | Works, and captures the *output's true* duration — but heaviest path: external package publish, version-anomaly resolution, 3-repo choreography. Superseded by principal-dev direction; its integrity goal is preserved more cheaply by the companion's internal comparison. Revisit only if a future consumer needs the measured output duration *as data* (open variable). |
| **Validation via human two-row comparison** (prior design) | Relies on QC looking; the companion's automated check catches every mismatch and blocks delivery — strictly stronger for the legal-integrity requirement. |
| **Do nothing on validation** | Leaves the lookup permanently an assumption; contradicts the integrity ruling that motivated this whole discussion. |

## 7. Solution & stress-test

- **Solves the confirmed classes?** Yes — 16216 fixes presentation with data already in hand; the companion enforces the invariant at the only place both measurements exist (inside Nova, file on local disk).
- **Scale:** fallback is O(existing lineage map) — no new queries; probe adds ~ms to a minutes-long transcode.
- **Fit:** fallback threads through the existing lineage-map pattern; companion rides the existing step/catch/outbox pattern; template addition (if chosen) follows the module's documented recipe.
- **Residual gap (product must accept):** when the **source** has no stored duration (browser-unmeasurable formats: `.mts`/AVCHD, `.mkv`, `.avi`, `.wmv`…), the fallback yields null and the transcoded row still shows "unavailable." The lookup cannot manufacture a value that was never captured. (The prior "Larry says captured through other means" open variable remains — no non-browser capture path exists in code.)
- **Interim window:** if 16216 ships before the companion, displayed values are assumptions until validation lands. Sequencing/acceptance is product's call.
- **Feedback speed:** 16216 — immediate (existing transcoded files light up on deploy; one API call verifies). Companion — first mismatch in the wild, or a deliberately truncated test file in sandbox.
- **Happy-path story (30s):** an ops specialist opens a proceeding; the converted `deposition.mp4` row shows "2h 14m" — same as its original, because Callisto resolved it through the derivation link. Months later a transcode drops the last 3 minutes; Nova's output probe catches the delta, the job fails, no bad deliverable is created, and the videographer gets the failure email naming the file and job. Nobody QC-eyeballs durations to catch it.

## 8. Assumptions ledger (new/changed items; prior report items #1–#8 unchanged)

1. **"Source `File` row incl. `length` is already fetched by the serve path."** — **confirmed** (`file-derivation.repository.ts:118`; assembler doc comment admits discarding it).
2. **"Both file-list endpoints converge on one TS, so one change covers all surfaces."** — **confirmed** (`proceeding.aggregator.ts:111-119`; no client-deliverables variant exists; response is not serialization-stripped — no `ClassSerializerInterceptor` in src).
3. **"A mismatch throw after TranscodeStep rides the existing failure flow with no other changes."** — **confirmed** (catch wraps all steps; failed commit is transactional; completed/failed mutually exclusive; throw precedes S3 persist).
4. **"The failed event supports a reason code."** — **confirmed** (`errorCode: string | null` on `NovaProceedingFileVideoTranscodeFailedV1Data`; currently hardcoded null; no enumeration exists yet).
5. **"The notification email cannot carry a reason today."** — **confirmed** (template data = `{ltrName, fileName, jobNumber}`; the failed event's `errorMessage` never reaches the email — separate events).
6. **"Output probe does not exist."** — **confirmed** (single `ProbeDurationStep` call, input-side only) — the companion's secondary probe is genuinely new.
7. **"Read-time fallback covers historical rows."** — **confirmed by construction** (no persisted state involved).
8. **"ffprobe-vs-ffprobe comparison permits a tight tolerance."** — **open** (same tool both sides removes browser-rounding skew; container timestamp variance may still produce sub-second deltas; threshold TBD — open variable).

## 9. Validation plan

**16216 happy path:** existing transcoded proceeding → deploy → `GET /proceedings/:id/files` → converted row's `length` equals its source's `length` → Atlas shows it in the Length column. Verify one historical and one fresh transcode.

**16216 negative paths:**
- Source `length` null → converted row `length` null → "unavailable" (assert in converter spec — the fallback must not invent values).
- Derived row later gets its own `length` (future) → own value wins over fallback (`file.length ?? sourceLength` ordering asserted).
- Original-only and non-transcode files → untouched (lineageRole null / ORIGINAL branches unchanged).
- Deliverables view (`isDeliverable=true`) where the source row isn't in view → fallback still resolves (derivation query fetches source regardless — assert with the existing "derived in list, source not" spec scenario).

**Companion happy/negative:** normal transcode → durations within tolerance → completes exactly as today. Truncated output (test fixture) → throw before persist → failed event with `DURATION_MISMATCH` (or chosen code), notification email, inbox markFailed, ECS exit 1, **no S3 object, no derivative row**. Probe failure on output → decision needed: treat as mismatch (fail) or as unknown (complete + warn) — open variable for product/principal dev.

### Test map
| Ticket | Suite | Assert |
|---|---|---|
| 16216 | `transcode-lineage-map.assembler.spec.ts` | entry carries `sourceLength` |
| 16216 | `pair-original-and-processed.converter.spec.ts` (8 scenarios exist; incl. "derived in list, source not" at :215) | CONVERTED fallback; null-source; own-value-wins |
| 16216 | `fetch-files-by-proceeding-id.transaction.script.spec.ts` + `transcode-lineage.test-utils.ts` factories | lineage map forwarding with lengths |
| 16216 | `file-attachment-to-proceeding-files-projection.converter.spec.ts` | unchanged `length` mapping for non-derived files |
| Companion | `video-conversion.service.spec.ts` | output probe invoked; tolerance compare; mismatch → failed commit, no persist/completed |
| Companion | `video-job-to-failed-outbox-descriptor.converter.spec.ts` | `errorCode` populated (currently asserts null at :47) |
| Companion | notification template specs (if new template chosen) | per the module's recipe |

Gates: `npm audit --audit-level=high` → `npm run lint` → `npm test -- --runInBand` (callisto / nova respectively).

## 10. Decisions, recommendation & open variables

- **Decisions (this session, per principal dev):**
  1. 16216 = Callisto read-time lookup/fallback via `file_derivations` IDs; display in the existing placeholder; single repo; no schema/protocol/FE change.
  2. Integrity validation = separate new ticket, inside Nova, using the existing failure pipeline; requires product buy-in.
  3. Prior protocol+emission plan superseded; backfill ticket dissolved.
- **Recommendation (in order):**
  1. Confirm with product: companion-ticket semantics (mismatch = failed job + failure email; no deliverable), template choice (reuse vs distinct), and the source-null residual gap on 16216's display.
  2. Write the 16216 Callisto story spec (larry-adams format) from §5's four edit points; supersede the Nova emission spec.
  3. Draft the companion ticket (text below) and put it through refinement.
- **Sequencing:** 16216 can ship immediately and independently; companion follows product sign-off. Product should explicitly accept the interim window where displayed values are unvalidated assumptions.

### Draft companion-ticket text (for ClickUp, product-facing)
> **Validate transcoded video duration in Nova**
> When Nova transcodes a video, verify the converted file's duration matches the original's before delivering it. Nova already measures the original's duration during the job; add a measurement of the converted output and compare the two. If they don't match (within a small tolerance), fail the job through the existing failure flow — the converted file is not delivered, and the existing failure-notification email alerts the videography team, so an incomplete conversion can never silently reach a proceeding deliverable. Decisions needed from product: (1) should the mismatch email be the existing "unable to convert" notice or a distinct "conversion came out the wrong length" notice; (2) confirm a mismatch should block delivery rather than deliver-with-warning.

### Open variables
- [ ] Companion buy-in: mismatch blocks delivery (fail) vs deliver+warn — owner: product
- [ ] Notification: reuse `VIDEO_TRANSCODE_FAILED` template vs new "Duration Mismatch" event code + template — owner: product (+ template recipe exists)
- [ ] Tolerance threshold (recommend: round both to whole seconds, allow ≤1s delta; confirm with ops) — owner: principal dev / ops
- [ ] Output-probe failure semantics: treat as mismatch or complete+warn — owner: principal dev
- [ ] `errorCode` enumeration (introduce `DURATION_MISMATCH` as first code?) — owner: principal dev
- [ ] Source-null residual: transcodes of browser-unmeasurable formats still display "unavailable" — accept, or fund source-duration capture later — owner: product
- [ ] Prior open variable retained: does any non-browser source-duration capture exist ("other means")? None found in code — owner: Dustin / Larry
- [ ] Future: persist measured output duration as data (would reopen protocol/persist design; only if a consumer needs it) — owner: backlog

## 11. Plan — next steps

| Action | Owner | Done-when (falsifiable) |
|---|---|---|
| Product confirmation on companion semantics + template + residual gap | Dustin → product | Answers recorded in changelog; companion ticket created in ClickUp |
| 16216 Callisto story spec (larry-adams format) | Dustin | Spec exists covering §5's four edit points + §9 tests; Nova emission spec marked superseded |
| Supersede banners on prior report/spec/dev-note | Dustin | Each file carries a pointer to this report |
| Companion ticket spec (after buy-in) | Dustin | Spec covers probe+compare+fail + template decision; refinement-ready |

## 12. Definition of done (investigation gate)
- [x] Class re-derived and reframed (split into two single-repo classes; §1)
- [x] Problem in one plain sentence per ticket (§2)
- [x] Named instance + urgency (§2)
- [x] Wedge + reusability (§2)
- [x] AC + non-goals locked per ticket (§3)
- [x] Alternatives with rejection reasons, incl. the superseded prior plan (§6)
- [x] 30-second happy-path story (§7)
- [x] Metric + feedback speed (§7)
- [x] Verdict + disposition (§0)
- [x] Open variables with owners (§10)
- [x] Tracked actions with falsifiable done-whens (§11)
