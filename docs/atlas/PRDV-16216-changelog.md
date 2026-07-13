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

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

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

## Current state (as of 2026-07-13)

- Investigation **complete**; report at `docs/investigations/PRDV-16216-transcoded-media-duration.md` — disposition: **proceed with conditions**.
- No implementation started; no branch created (work will land in `orbital-docking-protocol`, `nova-back-end`, `callisto-back-end` — **not** `atlas-front-end`).
- Gated on: protocol-owner ruling (additive vs v2), sequencing decision, product acks (reclassification, backfill, parity-indicator future story).

---

## New code introduced

_Optional — new modules, composables, endpoints._


