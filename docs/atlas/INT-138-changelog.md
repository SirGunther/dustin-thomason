# INT-138 — Audit log entries for deliverable type categorization

_Working title. The ticket was supplied as request text only, and the ClickUp title was not captured._

## Ticket

- **Ticket:** INT-138
- **Repo:** `atlas-front-end`, `europa-back-end`, `callisto-back-end` (the scope given at kickoff). Phase 1 recon will show which of them actually change.
- **Branch:** _(not cut yet; the branch step belongs to Phase 4/5)_
- **PR:** _(link when opened)_
- **Artifacts:** [INT-138/](INT-138/). This is an orchestrated ticket, and the ledger is [INT-138/orchestration.md](INT-138/orchestration.md)
- **WorkLists card:** `todo-1790172671871-1461f0f9` (supplied by the user)

---

## Requirements (verbatim)

> As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.
>
> * * *
>
> ## Acceptance Criteria
>
> -   Ops can view a log in Europa for **deliverable type categorization**
> -   The log displays the following details:
>     -   file path
>     -   user info
>     -   date/time
>     -   **categorization** actions taken
> -   A new Event Type is created for this action: **Categorize**
>     -   This event type is added to the Event Type drop down in Europa
> -   Resource Type for this action is: **File**
> -   Path format:
>     -   Filepath: \[file path\]
>     -   Deliverable Type: \[deliverable type\]
>     -   Collection: if applicable, \[collection\], if not, "N/A"

---

## Context

- The ticket is run under the `orchestrate` skill (`agents/skills/orchestrate/SKILL.md`). All artifacts live under `docs/atlas/INT-138/`, which is the atlas per-ticket folder convention, not the skill's default `tickets/<slug>/`.
- At kickoff (2026-09-23), all three repos were put on `main` and fast-forwarded from `origin`. Only Europa had uncommitted work, and it was stashed. See the ledger's Kickoff record for SHAs and stash names.
- Prior tickets that touch deliverable types and collections have coverage ledgers Phase 1 must consult first: PRDV-16312, PRDV-16313, PRDV-16461. There is also `PRDV-16939` (track/collection consolidation) and the domain note `docs/system-architecture/domain-knowledge-system/domains/audit-log.md`.

---

## Plans

_No rows. The `orchestrate` skill does not keep Plans rows. The approved plans are saved in the ticket folder: `investigations/INT-138-recon-and-plan.md` at Phase 2 and `INT-138-implementation-plan.md` at Phase 5._

---

## Session log

_Newest first._

### 2026-09-23T18:55:00Z — dustin-thomason (Phase 1 Recon + Phase 2 Report)

- **Summary:** Phase 1 recon was approved without edits. Phase 2 emitted the investigation package.
  - **The ticket is reclassified.** It is not a new Europa log. It is a gap in the audit events sent from existing write paths:
    - Callisto's recategorize path sends no audit at all.
    - Approve and upload send `APPROVED`/`CREATED` without the deliverable type or collection.
    - Europa's backend needs no change, because it stores and filters any type string (exact, case-sensitive match).
    - The Event Type dropdown is a hand-maintained list in `atlas-front-end`.
    - Each file needs its own event, because Europa shows only the first resource.
  - **Disposition: proceed with conditions.** D1 (which paths emit) and D2 (the literal and label) gate the spec. D3–D8 are open with owners.
  - **Story 01:** 3 questions closed by evidence, 3 split into fact and decision, OQ-10 added, and criterion 7 added (each file gets its own record).
- **Plan used:** `INT-138/investigations/INT-138-recon-and-plan.md` (approved, frozen).
- **Files:** `INT-138/investigations/` (`INT-138-recon-and-plan.md`, `-investigation.md`, `-coverage-ledger.md`, `-diagrams.md`); `INT-138/testing/INT-138-test-plan.md` (seeded); `INT-138/INT-138-why-these-changes.md`; `INT-138/INT-138-future-development-concerns.md` (C1–C6); `INT-138/INT-138-pr-draft.md` (shell); `INT-138/stories/` (reconciled); `INT-138/orchestration.md`.
- **Commits:** none. No implementation-repo file was touched. All three repos are still clean on `main`.
- **Notes:**
  - The WorkLists board is still blocked by the ticket-id guard. The card title is `# Ticket Template`, not INT-138, and nothing was written.
  - The Mermaid diagrams are hand-checked, not machine-rendered, because no renderer is installed here.

### 2026-09-23T18:05:00Z — dustin-thomason (Phase 0 Capture)

- **Summary:** Captured INT-138 under orchestration. I rewrote the user-supplied `INT-138-original-ticket.md` into the original-ticket artifact shape, with the request embedded byte-for-byte (checked with `cmp`). I drafted job story 01 (Categorization audit: 6 criteria, 9 open questions), scaffolded this changelog and the orchestration ledger, and recorded the WorkLists card id. I also put atlas-front-end, europa-back-end and callisto-back-end on `main` as instructed at kickoff.
- **Plan used:** none. Phase 0 is capture only.
- **Files:** `docs/atlas/INT-138/INT-138-original-ticket.md`, `docs/atlas/INT-138/orchestration.md`, `docs/atlas/INT-138/stories/INT-138-job-stories-index.md`, `docs/atlas/INT-138/stories/INT-138-job-story-01-categorization-audit.md`, this changelog.
- **Commits:** none.
- **Notes:** The WorkLists board write was **not made**. The ticket-id guard fired because the card title reads `Ticket Template`, not `INT-138`. `scripts/new-ticket-changelog.ps1` rejects `INT-` ids (`ValidatePattern '^PRDV-\d+$'`), so I copied this file from the template by hand.

---

## Attempt history

_None yet._

---

## Key technical learnings

1. Europa's audit backend accepts any event `type` string. There is no enum, the filter is an exact, case-sensitive match, and `newState.path` is passed through for every type except `PERMISSIONS_UPDATED`. A new audit event type needs no Europa change, but the Callisto and Atlas literals must match byte for byte.
2. Europa shows only `auditEventResources[0]` of a multi-resource event, so a batch action must send one event per file to be visible per file.
3. Callisto's recategorize path (`recategorize-deliverable-files.service.ts`) sends no audit to Europa. It writes only the Dione outbox.
4. The Europa page's Event Type options are `atlas-front-end` `src/europa/utils/constants.ts` `eventTypes`. They are raw strings with no label map. The only multi-line Path render is for `PERMISSIONS_UPDATED`.

---

## Current state (as of 2026-09-23)

Phases 0–2 are done, and Phase 3 (probe and spec) is next, in Working mode. Nothing has been built, branched or committed in any app repo, and all three repos are on `main` and clean. The investigation verdict is **proceed with conditions**: Product must settle D1 (which write paths emit Categorize) and D2 (the event literal and its label) before the spec is locked. The recommended shape is a Callisto emit per file after commit, plus the Atlas literal and path render, with Europa unchanged.
