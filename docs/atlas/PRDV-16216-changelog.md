# PRDV-16216 — Add media duration to transcoded files

## Ticket

- **ClickUp:** [PRDV-16216](https://app.clickup.com/t/43227262/PRDV-16216)
- **Repo:** `callisto-back-end`
- **Branch:** `PRDV-16216`
- **PR:** https://github.com/planetdepos/callisto-back-end/pull/383

---

## Requirements (verbatim)

_Paste from ClickUp, spec, or the user's first description. Do not paraphrase on first capture._

> **Description**
> As an Atlas user, I want Nova-transcoded video files to also display their media duration just like all other video files added to Atlas, so that I can review the media duration without having to open the files
>
> **Acceptance Criteria**
> Nova-transcoded video files display their media duration just like all other video files added to Atlas

(Source: `docs/atlas/16216/PRDV-16216-original-ticket.md`, captured verbatim.)

---

## Context

- **Reclassified during investigation:** filed as an Atlas display story, but the confirmed class is a **cross-service data-propagation gap** — `orbital-docking-protocol` (external contract) → `nova-back-end` → `callisto-back-end`; **zero Atlas code change** for display (path proven merged: PRDV-9756 UI + PRDV-15875 `files.length`).
- **Parity requirement (Dustin):** ops video experts compare source vs transcoded runtime → Nova must probe the **output** independently; copying source length is disqualified.
- **Backfill:** separate ticket (decided). Copy-based backfill is display-only, not parity-grade.
- Canonical findings: `docs/investigations/PRDV-16216-transcoded-media-duration.md` (data-path trace current vs target in §5; test map in §9; open variables in §10).

---

## Plans

_Lives in **dustin-thomason** only. Reference plans here so future agents do not repeat abandoned approaches. **Larry-adams** paths are **read-only links** to coworker specs — never create or push changelog/plan files there._

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-07-13 | `docs/atlas/16216/dnu/PRDV-16216-transcoded-media-duration.md` | `superseded` | Contract field (additive optional `duration`) → Nova probes OUTPUT + emits → Callisto persists to derived `File.length`. Superseded by the 2026-07-15 browser-probe direction (Nova + protocol frozen). **Moved to `dnu/`.** |
| 2026-07-13 | `docs/atlas/16216/PRDV-16216-nova-spec.md` (deleted) | `superseded` | First Nova spec draft in personal P→R→S format — superseded same day by the larry-adams-format rewrite below (wrong format for specs handed to others; write-spec/grill-me skills not applied) |
| 2026-07-13 | `docs/atlas/16216/dnu/PRDV-16216-nova-emits-transcoded-output-duration.md` + `dnu/PRDV-16216-dev-note.md` | `superseded` | Larry-format Nova story spec + dev note (output probe + protocol field + emission). **Moved to `dnu/`** — Nova/protocol frozen per 2026-07-15 rulings. |
| 2026-07-14 | `docs/atlas/16216/dnu/PRDV-16216-lookup-display-investigation.md` | `superseded` | Pivot per principal dev: Callisto read-time lookup + separate Nova validation ticket. Superseded by the 2026-07-15 browser-probe direction. **Moved to `dnu/`.** |
| 2026-07-14 | `docs/atlas/16216/dnu/PRDV-16216-callisto-lookup-display-spec.md` | `superseded` | Read-time lookup story spec (4 in-memory Callisto edit points, CONVERTED-branch fallback). Superseded by browser-probe direction. **Moved to `dnu/` — do not hand to implementation.** |
| 2026-07-14 | `docs/atlas/16216/PRDV-16216-companion-nova-duration-validation-spec.md` | `active` | Companion story spec (ticket TBD): new ValidateOutputDurationStep (one reuse-call of ProbeDurationStep on output — output duration NOT already in hand, verified), compare + log like other steps, throw pre-persist into existing failure/notification flow; 5 open questions for product/principal dev; Small–Medium (2–3 pts) |
| 2026-07-15 | `docs/atlas/16216/PRDV-16216-future-development-concerns.md` | `active` | Concerns record vs Larry's PR #24 write-time copy (larry-adams PR rewriting the spec): provenance, no-validation risk, reliance surface (Leah's display request), FFmpeg-silent-truncation chain verified in code; escalation-ready exec summary; erratum applied (never-copied ruling was Dustin's, not principal dev's) |
| 2026-07-15 | `docs/atlas/16216/PRDV-16216-measured-write-investigation.md` (first pass — Nova emission) | `superseded` | First pass proposed Nova probing output + protocol `duration` field + Callisto persist — **overwritten same day**: violated the user's locked constraints (Nova frozen, orbital package frozen, under any circumstances at this point). Nova-emission remains a possible *future* handling only |
| 2026-07-15 | `docs/atlas/16216/PRDV-16216-measured-write-investigation.md` (overwritten — **browser-probe write-back**) | `superseded` | Browser-probe write-back: Atlas auto-probes converted rows on first view, writes back via new Callisto update-length endpoint. **Killed 2026-07-16 by user ruling:** probing requires the viewer to download the ENTIRE file (no range support on the download endpoint) — unacceptable for low-bandwidth users. Callisto endpoint was fully built + tested before the ruling; preserved as `docs/atlas/16216/artifacts/PRDV-16216-update-length-endpoint.patch` |
| 2026-07-16 | PR #24 persist-time copy (Larry's approach) — implemented directly, no separate spec | `implemented` | **Shipped direction (user decision 2026-07-16, accepting documented risks):** copy `originalFile.length` onto the derived row at creation (param + service + mapper, 3 edit points). Copied value, NOT a measurement — risks recorded in `PRDV-16216-future-development-concerns.md`. Historical NULL rows not covered (no backfill — user declined). |
| 2026-07-16 | **Fast-follow (not yet ticketed): Callisto-side measured length via ffprobe** | `active` | The measured-value replacement: Callisto measures the transcoded file itself with ffprobe (`ffprobe-static`) at event time — S3 ranged reads, zero user bandwidth, Callisto-only. Fixes the copy's provenance gap and covers browser-unmeasurable sources. Also the pattern for a historical-row sweep. |

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-07-17T03:52:00Z — callisto-back-end: strip mapper risk comment; rewrite commit

- **Summary:** Removed the inline trade-off/risk comment from `persist-video-transcode-derivative.mapper.ts`. Soft-reset the prior PR commit and force-pushed a single replacement commit so the commented version is no longer on the branch.
- **Plan used:** Plans row 2026-07-16 (PR #24 copy).
- **Files:** mapper only (comment removal); branch history rewrite on `PRDV-16216`.
- **Commits:** `8743948b` replaced `ea24e827` via `--force-with-lease`.
- **Notes / checklist:** Tests run — not re-run full suite this pass (comment-only deletion; behavior unchanged). Lint/audit deferred same reason. Residual risk: none beyond prior copy-length trade-off (unchanged).

### 2026-07-17T03:45:00Z — callisto-back-end: commit, push, open PR

- **Summary:** Committed the persist-time source-length copy (5 files), pushed `PRDV-16216`, opened GitHub PR using the Atlas PR template sections only. Excluded untracked `scripts/` local tooling. PR description summarizes ticket AC; Testing and Verification left for Dustin's screenshot.
- **Plan used:** Plans row 2026-07-16 (PR #24 copy).
- **Files:** param/service/mapper + 2 specs; changelog metadata (repo → callisto-back-end).
- **Commits:** superseded — rewritten as `8743948b` (comment stripped)
- **PR:** https://github.com/planetdepos/callisto-back-end/pull/383
- **Notes / checklist:**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto-back-end | pass (exit 0; moderate-only) | — |
| lint | `npm run lint` | callisto-back-end | pass | — |
| tests | `npm test -- --runInBand src/proceedings/domain/transaction-scripts/persist-proceeding-video-transcode-derivative-ts src/proceedings/domain/services/process-proceeding-video-transcode-completed-service` | transcode persist path | pass (4 suites, 25 tests) | — |

Tests added/updated: mapper + service specs (already on branch). Regression — isolated: transcode-completed persist path only. API docs — not relevant: no HTTP surface change. Conflicts/exceptions: none this session.

### 2026-07-16T21:30:00Z — callisto-back-end: pivot to PR #24 persist-time copy (implemented)

- **Summary:** Three decisions in one session, all Dustin's rulings. **(1) Browser-probe design killed:** established that the Atlas probe requires the viewer to download the entire file (download endpoint streams whole objects, no range support) — unacceptable on low bandwidth. **(2) Measured Callisto-only alternative identified** (ffprobe at event time, S3 ranged reads, zero user bandwidth) — deferred to fast-follow. **(3) Shipped Larry's PR #24 copy** to close the ticket now, explicitly accepting the documented provenance risks ("we'll note this is a terrible idea for the stated reasons and let them deal with it" — risk record: `PRDV-16216-future-development-concerns.md`; copied-not-measured comment placed in the mapper itself). **Implementation (5 files):** `persist-video-transcode-derivative.param.ts` (+`sourceLength: number | null`), `process-proceeding-video-transcode-completed.service.ts` (passes `context.originalFile.length ?? null`), `persist-video-transcode-derivative.mapper.ts` (`file.length = params.sourceLength` + risk comment), mapper spec (+copied-length assertion, +null-source case), service spec (+`sourceLength` assertion). **No backfill migration** (user declined — historical rows stay NULL). **Endpoint work reverted** from the branch; preserved as `docs/atlas/16216/artifacts/PRDV-16216-update-length-endpoint.patch` (937 lines: action/DTOs/swagger/guard/TS/repo/registries/specs, 46 tests were green). Also this session: local-env docs created (`docs/atlas/local/callisto-local-quickstart.md` + `callisto-local-teardown.md`) after a day of environment failures (root causes documented in each: `.env` vs `.env.local` APP_PORT precedence, SSO-unauthorized PAT, missing dev deps, EADDRINUSE zombies, quasar child-process locks, RabbitMQ `.erlang.cookie` eacces, stale `orbital-docking-protocol@0.2.15` vs lockfile `1.0.5`).
- **Plan used:** Plans row 2026-07-16 (PR #24 copy).
- **Files:** the 5 callisto files above; changelog; local-env docs; endpoint patch artifact. Nova + orbital-docking-protocol untouched (constraint held).
- **Commits:** none yet — awaiting Dustin's local sandbox test, then commit/push per git workflow.
- **Notes / checklist:** Tests run: `npm audit --audit-level=high` (pass, exit 0) → `npm run lint` (pass, no mutations) → `npm test -- --runInBand src/proceedings/domain/transaction-scripts/persist-proceeding-video-transcode-derivative-ts src/proceedings/domain/services/process-proceeding-video-transcode-completed-service` (4 suites, 25 tests, all pass). Tests added/updated: mapper spec (copied length + null source), service spec (sourceLength delegation). Regression impact — isolated: change confined to the transcode-completed persist path (param/service/mapper); no shared infrastructure touched; upload path, fetch path, and rename path unchanged (their suites untouched). API docs — not relevant: no HTTP surface change (inbox event handler internals only; route/DTO/status surface checked, unchanged). Tooling gates: table above. Conflicts/exceptions: **this ships a copied value, reversing the 07-13/07-15 measured-only rulings — done at Dustin's explicit direction with the concerns doc as the standing risk record.** Fast-follow (ffprobe measured) captured in Plans.

### 2026-07-15T14:44:00Z — investigation overwritten: browser-probe write-back under locked constraints (docs-only)

- **Summary:** User ruled the first-pass investigation **not accurate/not correct** for the actual requirement and locked constraints: **Nova will not be changed under any circumstances at this point; `orbital-docking-protocol` will not be changed under any circumstances at this point**; the requirement is to **leverage the same method that collects the original file's duration** (the browser probe) for the transcoded file; trigger = **"probe automatically, always."** Overwrote `PRDV-16216-measured-write-investigation.md` (full `investigation` method re-run, all 7 steps + question-coverage reconciliation pass). **Design:** Atlas auto-detects converted rows with `length == null` + media extension (DTO already carries `lineageRole`/`length`/`fileName` — verified) → fetches bytes via the EXISTING guarded download endpoint (`POST /callisto/proceedings/downloads`, pattern proven by `useProceedingFilePreview`) → measures with the EXISTING `resolveMediaDuration` composable unchanged (serial queue built in) → writes the measured seconds back via ONE new Callisto update-length action (pattern: `rename-proceeding-file-action/`; validated DTO; update-only-when-null; guards ≥ download). Probe once per file ever; every later view reads the DB. **Properties:** genuine measurement of the transcoded file itself (never a copy — invariant holds); historical rows covered automatically on first view (no backfill); transcoded outputs of browser-unmeasurable sources (`.mts`/`.mkv` → `.mp4`) get real values; cost = one full-file download per unmeasured file (no range/presigned surface exists — verified; accepted by user ruling). Verified: `files.length` has exactly one writer today (upload path) — the endpoint becomes the second. Reconciliation pass: all 15 question-coverage items, 12 DoD items, 7 steps, constraint compliance (zero Nova/protocol references in the design), diagram syntax — clean. **Follow-up audit vs `investigation-software-gaps.md`** (user check): 3 gaps found and patched — contract-alignment line (§5: `files.length` authority = upload capture path; endpoint mirrors it; re-drift risk named), blast-radius enumeration (§7: Length renders in exactly 1 component / 2 tables, greps clean), shared-probe-queue neighbor (§7: `enqueueParse` is module-global — backfill and upload probes share one serial queue; mitigation = spec decision); candidate 4 (detection gap) N/A — feature, not a slipped bug. **Second follow-up (user check on Problem Check):** §2's Problem Check was a prose summary without the tool's evidence-citation rule — re-run per `problem-check.md`'s verbatim prompt against the live discussion (trimmed quotes, In brief + question/flag tables); key admission recorded: the session's own drift ("make this work with the current system" → recommending Nova/protocol changes) is exactly asked-vs-answered drift that went uncaught because the lens was aimed at Larry's TLDR instead of the user's asks. Process lesson: user-voiced constraints go verbatim into the Step-3 contract the moment they're said.
- **Plan used:** Plans row 2026-07-15 (browser-probe write-back).
- **Files:** `PRDV-16216-measured-write-investigation.md` (overwritten), concerns-doc pointer updated, this changelog. No product code touched.
- **Commits:** none yet (docs-only, dustin-thomason).
- **Notes:** Next artifact: story spec from report §7 (Atlas wiring + Callisto endpoint; Callisto first). Validation compare/fail stays a future companion (user decision; spec drafted). Checklist — Tests run: not applicable (docs-only; no gates in dustin-thomason). Tests added/updated: not applicable (no behavior changed). Regression impact: not relevant (documentation only; no app-repo file modified this session). API docs: not relevant (no HTTP surface in this repo; the future endpoint's swagger is specced in the report's §7). Tooling gates: not applicable (repo has no lint/test/audit scripts).

### 2026-07-15T14:17:00Z — PR #24 comparison, concerns record, Approach D investigation (docs-only)

- **Summary:** Three-phase session. **(1) PR #24 analysis:** Larry's [larry-adams PR #24](https://github.com/planetdepos/larry-adams/pull/24) rewrites the 16216 spec from read-time lookup to **persist-time copy** (`length: context.originalFile.length` through 3 Callisto edit points) — the alternative rejected in the 07-14 investigation §6, with the companion-validation reference removed. Verified his named classes exist and the mechanics are accurate (3 lines, not 1 — param/service/mapper). **(2) Concerns record** (`PRDV-16216-future-development-concerns.md`, escalation-ready): copied values are provenance-indistinguishable and defeat the source-vs-converted check *by construction*; **verified in code** that FFmpeg can exit 0 on truncated output, Nova checks exit code only and never probes the output, and Nova **already probes duration on every transcode and discards it** (`ProbeDurationStep` → log line). Leah's display request makes the Length column a de facto verification surface. **Erratum applied** (07-13 report line 180): the never-copied/assumed non-negotiable was **Dustin's ruling**, mislabeled as principal-dev's — corrected visibly in both files. **(3) Approach D investigation** (`PRDV-16216-measured-write-investigation.md`, full `investigation` method, all 7 steps + question-coverage reconciliation pass): confirmed class = **ingestion-time measurement gap** (invariant: every `files.length` today was measured from the file in its own row, by whoever held the bytes); Approach D = Nova probes output → optional `duration` on completed event → **PR #24's exact plumbing** fed the measured value. Key verifications: Callisto command = protocol type alias (zero type change after package bump); parser required-fields-only (optional field passes through); protocol pkg ships no JSON schemas (type = whole contract); version anomaly live with consumer drift (0.2.13 nova vs 0.2.15 callisto vs declared ^1.0.5); pre-existing `createdUserIdentity` type/payload drift found. Unique D property: ffprobe measures outputs of browser-unmeasurable sources (`.mts`/`.mkv`/`.avi`) — the only option producing a value there. Single embedded mermaid diagram (current vs target + method-exemplar lane). Scope per user: validation compare/fail = future companion; prober = **Nova** (user's "frontend probes it" phrasing corrected — method transfers, not actor).
- **Plan used:** Plans rows 2026-07-15 (both).
- **Files:** `PRDV-16216-future-development-concerns.md` (new), `PRDV-16216-measured-write-investigation.md` (new), erratum edit in `PRDV-16216-transcoded-media-duration.md` (user applied line-180 correction; report notes it), this changelog. No product code touched; no banner changes to prior reports (gated on principal-dev agreement).
- **Commits:** none yet (docs-only, dustin-thomason).
- **Notes:** Next action: present Approach D to Larry framed as "your plumbing, measured value." Gates: protocol publish before Nova PR; principal-dev agreement before any supersession; product owns the pre-ship-rows-stay-NULL decision. Checklist — Tests run: not applicable (docs-only; no package.json at dustin-thomason root, no runnable gate for markdown). Tests added/updated: not applicable (no behavior changed). Regression impact: not relevant (documentation only; no product surface touched — verified no app-repo file modified this session). API docs: not relevant (no HTTP surface in this repo). Tooling gates: not applicable (repo has no lint/test/audit scripts).

### 2026-07-14T20:15:00Z — implementation specs for main + companion (docs-only)

- **Summary:** Wrote both story specs in larry-adams house format. **Main** (`PRDV-16216-callisto-lookup-display-spec.md`): the 4 in-memory Callisto edit points (lineage projection `sourceLength` → assembler populate → pair-converter CONVERTED fallback `file.length ?? sourceLength ?? null` → DTO description), data-flow diagram, spec-test assertions incl. own-value-wins and source-null; Small (1–2 pts). **Companion** (`PRDV-16216-companion-nova-duration-validation-spec.md`, ticket TBD): verified the user's "we should have all the data" assumption — **refuted in one detail**: output duration is not in hand (TranscodeStep returns void; only input is probed), but it's one reuse-call of the existing path-agnostic ProbeDurationStep, keeping the implementation as easy as intended; new `ValidateOutputDurationStep` following the step pattern, logs input/output/delta like other steps, throws typed `DurationMismatchError` pre-persist into the unchanged failure flow; 5 open questions (tolerance, template reuse vs distinct, errorCode enum, probe-failure semantics, blocking confirmation); Small–Medium (2–3 pts).
- **Plan used:** Plans rows 2026-07-14 (both specs).
- **Files:** two new spec files; this changelog. No product code touched.
- **Commits:** none yet (docs-only, dustin-thomason).
- **Notes:** Both specs held locally in `docs/atlas/16216/` pending Larry's earlier wiki-placement ruling (still open) and the companion's ClickUp ticket creation after product answers.

### 2026-07-14T18:30:00Z — pivot per principal-dev conversation: lookup-display + validation split (docs-only)

- **Summary:** Dustin + Larry decided to split the work. **16216 (minimal, matches ticket spirit):** transcoded file's Length placeholder is filled by looking up the source file's duration via the `file_derivations` ID linkage. Investigated placement: the serve path **already fetches the full source `File` row (incl. `length`)** via `innerJoinAndSelect('derivation.sourceFile', …)` and discards it — so the fallback is **in-memory only, ~4 edit points in callisto-back-end** (lineage projection/assembler/pair-converter/DTO description), zero SQL/schema/FE change, both endpoints converge on the same TS, and **all historical transcoded rows are covered automatically → backfill ticket dissolved**. **New companion ticket (product buy-in):** Nova compares input duration (existing probe, currently logged) vs output duration (new secondary probe — confirmed required, nothing probes output today) and on mismatch **throws before `PersistOutputStep`**, riding the existing failure flow unchanged (failed event has an unused `errorCode` slot; `VIDEO_TRANSCODE_FAILED` notification template exists end-to-end; template has no reason slot — reuse-vs-new-template is a product decision). **Protocol change eliminated from both tickets.** New report: `docs/atlas/16216/PRDV-16216-lookup-display-investigation.md` (incl. draft companion-ticket text for product); superseded banners added to the 2026-07-13 report, Nova spec, and dev note.
- **Plan used:** Plans row 2026-07-14 (lookup-display pivot).
- **Files:** new report; banner edits to `PRDV-16216-transcoded-media-duration.md`, `PRDV-16216-nova-emits-transcoded-output-duration.md`, `PRDV-16216-dev-note.md`; this changelog. No product code touched.
- **Commits:** none yet (docs-only, dustin-thomason).
- **Notes:** Key retained caveats: source-null residual (browser-unmeasurable formats still show "unavailable" — product to accept); interim window where displayed values are unvalidated until the companion ships; "captured through other means" still unverified in code. Terminology: conversation said "file size" — the quantity is media duration (`files.length`, seconds); fileSize is separate and already captured.

### 2026-07-13T23:20:00Z — principal-dev (Larry) review: copy-vs-probe ruling (docs-only)

- **Summary:** Larry challenged whether Callisto could just copy the source file's duration onto the derived row (no Nova/protocol change). Investigated: (a) Callisto already loads the full source `File` (incl. `length`) in the completed-event handler, so copy is a one-liner; (b) source `length` is captured **only** browser-side and is null for non-web formats (`.mts`/AVCHD, `.mkv`, `.avi`…), which have **no source-format filter** on the transcode trigger and always output `.mp4`; (c) no server-side duration fallback exists. **Dustin's ruling (locked):** copy is rejected — this is a legal videography deliverable pipeline; a runtime that doesn't match the source is lost evidence, so the deliverable length must be *independently verifiable*, never assumed. Nova emits the **output** duration only; the already-stored source length is the reference (Nova does not re-emit it); verification is the existing two-row visual comparison (Atlas unchanged — already settled in the investigation). Recorded a residual: source-reference coverage is a **verification gap** for non-web formats if no non-browser source capture exists (Larry says captured "through other means" — unconfirmed in code).
- **Process note:** I over-reached by re-asking a UI question the investigation had already settled, and by initially under-ranking the parity/integrity driver — corrected both.
- **Files:** `docs/atlas/16216/PRDV-16216-transcoded-media-duration.md` (report — copy-rejection reason, decisions, open variable), `docs/atlas/16216/PRDV-16216-nova-emits-transcoded-output-duration.md` (spec — driver + Open Question #6). No product code touched.
- **Commits:** none yet (docs-only, dustin-thomason).
- **Notes:** Report was relocated by the user into `docs/atlas/16216/` (its Metadata `Location:` still reads `docs/investigations/` — cosmetic). Spec design unchanged by the ruling (output-probe only, as already written) — the "Nova emits both source+output" idea I floated in-chat is **dropped**.

### 2026-07-13T22:10:00Z — spec rewrite to larry-adams format (docs-only)

- **Summary:** Loaded `grill-me` + `write-spec` skills (missed on the first pass — process gap acknowledged). Followed the write-spec workflow: read `wiki-spec-authoring.md`, located the team wiki (`larry-adams/systems/`), modeled on the closest precedent **PRDV-15828** (same video-transcode event family, Larry-authored). Rewrote the Nova spec in house format (frontmatter, Summary→AC→Docking Protocol Contract→Modified classes→Data Flow diagram→Spec Tests→Scope boundaries→Cross-cutting→Open questions; personal P→R→S framing removed per project memory). Created companion dev note with Small–Medium (2–3 pts) estimate. Grill-me decisions: **wiki placement → ask Larry first** (spec held locally); **embed 15828-style contract section** (protocol change = publish gate "before or alongside this PR", not a blocked-by ticket); **companion dev note yes**.
- **Plan used:** Plans row 2026-07-13 (larry-adams-format rewrite).
- **Files:** `docs/atlas/16216/PRDV-16216-nova-emits-transcoded-output-duration.md` (new), `docs/atlas/16216/PRDV-16216-dev-note.md` (new), `docs/atlas/16216/PRDV-16216-nova-spec.md` (deleted — superseded), this changelog.
- **Commits:** none yet (docs-only, dustin-thomason).
- **Notes:** Discoveries: larry-adams **is** PR-writable for specs (memory `spec-review-gate-larry-adams`; changelogs still never go there); Nova-platform specs physically live under `systems/nebula/` though README wiki-links say `nova/...`; larry-adams checkout is currently on branch `PRDV-16047` — switch to `main` + pull before branching for the spec PR. Open before PR: Larry's placement ruling (Open Questions #1), then move spec+dev note into the chosen wiki path, convert prerequisite/dev-note links to full wiki-links, add `systems/README.md` index entries.

- **Summary:** Wrote the Nova-only story spec from the investigation report (§5 Path C / §7 / §9). Scope strictly `nova-back-end`: non-fatal output probe (`localOutputPath`, post-`TranscodeStep`, `Math.round` to whole seconds) threaded service → `VideoConversionOutboxWriterPort` → assembler → completed-event converter; input probe/log untouched; `VideoJob` deliberately not modified. Protocol/Callisto/Atlas/backfill referenced as out-of-scope companions only. Sections per `spec-writing` rule with N/A reasons (no ORM/HTTP/migrations in Nova).
- **Plan used:** Plans row 2026-07-13 (nova spec).
- **Files:** `docs/atlas/16216/PRDV-16216-nova-spec.md` (new), this changelog. No product code touched.
- **Commits:** none yet (docs-only, dustin-thomason).
- **Notes:** Spec is **blocked by** the protocol companion (typed `duration` field + version-anomaly resolution before pinning); **not** blocked by Callisto (field optional). AC includes byte-for-byte-unchanged input-probe logging and probe-failure → omitted-field degradation.

### 2026-07-13T20:30:00Z — investigation (read-only across repos)

- **Summary:** Ran the `investigation` skill end-to-end. Traced the full data path (current vs target), proved the Atlas display path is already merged and source-agnostic, found duration is probed in Nova but discarded, and that the completed-event contract lacks the field. Reclassified the ticket (Atlas display story → cross-service data-propagation gap). Locked decisions: output-probe for parity, reuse `length` display path, backfill separate. Emitted the Investigation Report.
- **Plan used:** Plans row 2026-07-13 (investigation report).
- **Files:** `docs/investigations/PRDV-16216-transcoded-media-duration.md` (new), this changelog (scaffolded + filled). No product code touched in any repo.
- **Commits:** none yet (docs-only, dustin-thomason).
- **Notes:** Open variables live in report §10 (protocol ownership/versioning, sequencing, version anomaly `^1.0.5` vs `0.2.13`, backfill decision, named ops user). Next artifact: spec via `write-spec` after principal-dev answers. Process notes for the `investigation` skill captured in the report appendix (plan mode; purpose statement; test-map question; ledger-at-checkpoints).

---

## Root cause analysis

_Optional — fill when debugging._

---

## Attempt history

_Optional — one subsection per failed or partial approach._

### Attempt 1 — short label (commit `abc1234` optional)

**What:**

**Result:**

---

## Key technical learnings

1. 

---

## Current state (as of 2026-07-16)

- **Shipped direction (user decision 2026-07-16): PR #24 persist-time copy** — `file.length = originalFile.length` stamped at derived-row creation in the transcode-completed flow (param + service + mapper). **Implemented on `callisto-back-end` branch `PRDV-16216`, uncommitted, gates green (25 tests), local server running with it on port 3004 — awaiting Dustin's sandbox test, then commit/PR.**
- **The value is a copy, not a measurement.** Risks accepted explicitly by Dustin; standing risk record: `docs/atlas/16216/PRDV-16216-future-development-concerns.md`; a copied-not-measured comment sits on the mapper line itself.
- **Browser-probe write-back: killed 2026-07-16** — the probe forces the viewer to download the whole file (no range support); unacceptable on low bandwidth. The finished Callisto update-length endpoint (46 green tests) is preserved at `docs/atlas/16216/artifacts/PRDV-16216-update-length-endpoint.patch`.
- **Fast-follow (active, not ticketed): Callisto-side ffprobe measurement** — measures the transcoded bytes server-side at event time (S3 ranged reads, zero user bandwidth, Callisto-only); replaces the copy with a real measurement and enables a historical-row sweep. This is the measured-value path that survives the bandwidth constraint.
- **Historical NULL rows: not covered** (no backfill; user declined). Constraints held: Nova + `orbital-docking-protocol` untouched. Atlas untouched (display path already works once the column has a value).
- **Local env:** canonical setup/teardown docs at `docs/atlas/local/callisto-local-quickstart.md` + `callisto-local-teardown.md` (port truth: `.env` `APP_PORT` wins, canonical 3004).
- **Companion ticket (unchanged, future):** input-vs-output duration validation (spec drafted).

---

## New code introduced

_Optional — new modules, composables, endpoints._


