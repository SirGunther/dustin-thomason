# Locked decisions — atlas/PRDV-14055

> Q-and-A traceability ledger for Phase 3 (probe & spec). Each row is a decision no longer open for design.
> Source of truth per the `source-truth` rule: decisions cite the artifact/quote that settled them. Populated
> one answer at a time (grill-me under qa-to-spec-traceability); rejected paths recorded so they don't return.
> The spec (`PRDV-14055-upload-manager-count-up.md`, wiki-bound) carries a summary Locked-decisions table; this file is the full ledger.

## Question gates

### Q1 (OV-1) — failed/cancelled-after-start treatment in the first number

- **Proposed question:** when a file errors/cancels after starting, does the first number stay or drop?
- **Existing answer check:** AC silent on failures; investigation §15 OV-1 showed code cannot supply the AC author's intent → genuine decision.
- **Current behavior evidence:** all sibling signals treat a failed/cancelled file as progressed/terminal — `totalProgress` +100 ([uploadManagerStore.ts:62-65](../investigations/PRDV-14055-investigation.md)), remaining-count drops it like a completion ([:43-48]), `allUploadsComplete` includes it ([:50-57]).
- **Recommendation:** stay counted (mirror existing behavior).
- **Resolved:** yes → LD-001.

### Q2 (OV-2) — scope: which app(s)

- **Proposed question:** Callisto, Triton, or both?
- **Existing answer check:** investigation §15 OV-2 showed code proves both live/defective but cannot map "Ops Atlas user" → app → genuine decision.
- **Current behavior evidence:** Callisto manager mounted app-wide (`isCallistoRoute`, App.vue:34); Triton manager in TritonAppContainer; both identically broken.
- **Recommendation:** both.
- **Resolved:** yes → LD-002 (user chose Callisto only; Triton deferred).

### Q3 (OV-3) — Triton i18n now vs defer

- **Existing answer check:** contingent on Q2. Q2 = Callisto only → Triton not touched this ticket.
- **Resolved:** N/A for this ticket → LD-003 (rolled into the Triton follow-up).

## Locked-decision ledger

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 | A file **stays counted** in the first number once it is terminal (complete/error/cancelled) or actively transferring — the number **never drops back**. Formula `isComplete \|\| error \|\| isCancelled \|\| percentCompleted > 0` (bar-consistent — `totalProgress` already treats terminal files as 100%). **Refined 2026-07-21 after review (midnjerry):** the earlier `isComplete \|\| percentCompleted > 0` form missed errored-at-0% files; the terminal flags are now counted explicitly, so a 0-byte file rejected at upload-start (`error` set) is counted. (Failures that never mark the queue item terminal are now also fixed here — LD-004.) | **Product (ClickUp), 2026-07-21:** *"I don't think it should drop back. The number should stay the same."* + **PR #26 review (midnjerry):** count error files incl. 0-byte. | **Rejects** the "exclude failures (literal AC)" option **and** the `percentCompleted > 0`-only form (missed 0% terminal files). | Spec §Approach + §Implementation Details (Zero-byte files) + Acceptance criteria 5. |
| LD-004 | **~~Deferred~~ → REVERSED, folded in (2026-07-21).** Failures that never mark the queue item terminal (0-byte at upload-complete, mid-upload / network failures set only a component-local `isFailed`) **are fixed in this ticket**: `useUploadItem` sets `fileToUpload.error` on failure, so failures are counted, toasted, and resolve the batch. Initial lean was to defer; reversed on the PR because it is a feature that makes errors known/testable. | **PR #26:** *"NVM, folding it in, because it's a feature and will make errors known/testable."* (supersedes the earlier defer lean). | **Reverses** the earlier "defer to its own ticket" position. | Spec §Approach + §Implementation Details (Failure is terminal) + Acceptance criteria 3–5. |
| LD-005 | **Offline / interrupted upload = fail gracefully, not retry.** On network loss mid-batch, files that can't finish are marked failed → counted, toasted, and the batch resolves to a terminal title; the manager must not hang. Automatic retry/resume/offline-detection is explicitly **not** built here. | **PR #26 (midnjerry):** requested AC for offline mid-upload; expected behavior is baseline UX (resolve + surface), confirmed no external decision needed. | Scopes offline handling to graceful-failure; **rejects** building retry/resume in this ticket. | Spec Acceptance criterion 5 + Scope boundaries + `useUploadItem` failure test. |
| LD-002 | **Scope = Callisto only.** Fix the count in the Callisto store + title only. The Triton upload manager's **identical count-down defect** (and its hardcoded/non-i18n label) are **deferred to a follow-up ticket** — not touched here. | **User direction, 2026-07-21:** *"We're going to focus on Callisto ONLY at this time. Triton should be noted as a follow up ticket."* | **Rejects** "both" and "Triton only"; **narrows** the investigation report §7 "both" recommendation to Callisto-only. | Spec §Non-goals + §Scope; test plan Scope (Callisto surfaces only); Triton → `PRDV-14055-future-development-concerns.md` Concern 2. |
| LD-003 | **Triton i18n conversion is out of scope** for this ticket (moot — Triton not touched, per LD-002). Rolls into the Triton follow-up ticket alongside Triton's count fix. | Follows from **LD-002** (user direction, 2026-07-21). | — (contingent question retired, not a reversal) | `PRDV-14055-future-development-concerns.md` Concern 2 (follow-up scope). |

## Related future note

- Product added: *"In the future we might add additional context, like this"* (the referenced example was not included in the pasted response). Recorded as a future enhancement in `PRDV-14055-future-development-concerns.md` — **out of scope** for this ticket.
