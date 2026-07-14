# PRDV-16216 — Add media duration to transcoded files

## Ticket

- **ClickUp:** [PRDV-16216](https://app.clickup.com/t/43227262/PRDV-16216)
- **Repo:** `atlas-front-end`
- **Branch:** `PRDV-16216`
- **PR:** _(link when opened)_

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
| 2026-07-13 | `docs/investigations/PRDV-16216-transcoded-media-duration.md` | `active` | Contract field (additive optional `duration`) → Nova probes OUTPUT + emits → Callisto persists to derived `File.length`; Atlas untouched; backfill = separate ticket |
| 2026-07-13 | `docs/atlas/16216/PRDV-16216-nova-spec.md` (deleted) | `superseded` | First Nova spec draft in personal P→R→S format — superseded same day by the larry-adams-format rewrite below (wrong format for specs handed to others; write-spec/grill-me skills not applied) |
| 2026-07-13 | `docs/atlas/16216/PRDV-16216-nova-emits-transcoded-output-duration.md` + `PRDV-16216-dev-note.md` | `superseded` | Larry-format Nova story spec + dev note (output probe + protocol field + emission) — superseded 2026-07-14 by principal-dev direction; retained as raw material for the validation companion ticket |
| 2026-07-14 | `docs/atlas/16216/PRDV-16216-lookup-display-investigation.md` | `active` | Pivot per principal dev: 16216 = Callisto read-time lookup (`derived.length ?? source.length` via file_derivations; source row already fetched — ~4 in-memory edit points, covers historical rows, no protocol/schema/FE change) + separate Nova validation ticket (output probe + compare + fail via existing failure pipeline; product buy-in needed) |
| 2026-07-14 | `docs/atlas/16216/PRDV-16216-callisto-lookup-display-spec.md` | `active` | Main story spec (larry-adams format): 4 in-memory Callisto edit points, fallback in CONVERTED branch, no schema/SQL/FE change, Small (1–2 pts) |
| 2026-07-14 | `docs/atlas/16216/PRDV-16216-companion-nova-duration-validation-spec.md` | `active` | Companion story spec (ticket TBD): new ValidateOutputDurationStep (one reuse-call of ProbeDurationStep on output — output duration NOT already in hand, verified), compare + log like other steps, throw pre-persist into existing failure/notification flow; 5 open questions for product/principal dev; Small–Medium (2–3 pts) |

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

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

## Current state (as of 2026-07-14)

- **Direction pivoted per principal dev (Larry).** Canonical report: `docs/atlas/16216/PRDV-16216-lookup-display-investigation.md` — disposition: **proceed** (16216), **proceed with conditions** (companion ticket).
- **16216 scope:** `callisto-back-end` only — read-time fallback `derived.length ?? source.length` through the existing lineage map (~4 in-memory edit points, §5 of the report). No protocol/schema/Nova/Atlas change. Covers historical rows (backfill dissolved). Spec not yet written (next artifact).
- **Companion ticket (not yet created):** Nova input-vs-output duration validation, fail via existing failure pipeline; draft ticket text in report §10; awaiting product buy-in (blocking semantics, template choice, source-null residual acceptance).
- Prior plan (protocol `duration` field + Nova emission + Callisto persist) and its spec/dev note: **superseded**, banners in place.
- No implementation started; no branches created.

---

## New code introduced

_Optional — new modules, composables, endpoints._


