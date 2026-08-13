# Agent Workflow Sync — Open Decisions

Status: **no blocking decisions. Three confirmations and two spike questions remain.**
Last updated: 2026-08-12T00:00:00Z
Parent: [`001` decisions](./001-agent-workflow-sync-decisions.md) · [`003` work breakdown](./003-agent-workflow-sync-work-breakdown.md) · [`006` validation](./006-job-story-validation.md)

## Purpose

Every unresolved decision across the seven specs, in one place. Nothing here needs code to answer — every code-discoverable question was traced and resolved while the specs were written.

## Scope boundary, restated

**This effort is about the card the agent is given an id for. Nothing beyond that boundary.**

Two earlier entries in this document have been removed because they lived outside it:

- **"Two copies of one value versus the criterion that forbids it"** — gone. It existed because workflow values were going to be made queryable across all tickets, which was never asked for. Nothing needs to be queryable, so nothing needs a second copy, so there is no tension to resolve. The story that produced it is retired to `stories/dnu/`.
- **W9** (`queryable-workflow-mirror-properties`) — gone with it.

---

## Decided this session, on your direction

### Card templates — settled, and now a feature rather than a mechanism

**Approved 2026-08-12 on the user's direction.** A **Card Template** defines a whole ticket — its card body and an ordered list of notes — authored in a new **Card Templates** tab in the existing settings dialog. A setting names which template the agent creates from. `POST /api/cards/from-template` creates the card and its notes and **returns the new card's id**.

This replaces the duplicate-a-card approach. Duplication returned the id, which worked; it could not say what the shape *should* be, only copy whatever an existing card had, drift included.

Recorded in [W3](../../tickets/workflow-checklist-template-registry/specs/workflow-checklist-template-registry-spec.md) → *Part 2 — Card Templates*, [W2](../../tickets/single-card-read-and-id-handoff/specs/single-card-read-and-id-handoff-spec.md) → *Path B*, and [job story 05](../../tickets/agent-workflow-sync/stories/agent-workflow-sync-job-story-05-tickets-start-pre-built.md).

### `currentStep` at phase start — settled

**Approved 2026-08-12.** `currentStep` is written when a phase **starts**; checklist rows and `nextUp` on completion. Costs one extra small request per phase and stops the field being reliably one phase stale. Plan-mode phases defer their write to the next Working phase, so during a Plan phase the card names the previous one — unavoidable, and narrower than the problem it fixes. Closes criterion 1.4. Recorded in [W6](../../tickets/agent-workflow-writer/specs/agent-workflow-writer-spec.md) → *Phase-start write*.

### Notify on a guard stop — settled

**Approved 2026-08-12.** Any guard firing, and any second `409`, calls `notify-agent-complete.ps1` with the phase and the guard named. **A skip is not a stop** — a board write failing because the server is down is recorded in the ledger with no notification, and the phase still completes. That distinction is what keeps this from becoming noise. Closes criteria 1.5 and 4.5. Recorded in [W6](../../tickets/agent-workflow-writer/specs/agent-workflow-writer-spec.md) → *Every stop notifies*.

---

## Confirmations wanted — none blocking

### 1. What is the feature called in the UI?

`Card Templates` is the recommendation, matching the flat literal naming of `Models`, `Statuses`, `Prompts`. Alternatives considered: `Ticket Templates`, `Card Blueprints`. Carried on story 05.

### 2. Is starting a ticket from a template agent-only at first, or also an in-app action?

You raised agent-only as acceptable to start. The settings tab earns its place either way — it is where templates are authored. If agent-only, story 05's last criterion is only exercised through the agent until a board-level action exists.

### 3. May the agent un-mark a row?

Currently permitted with a recorded reason, and a re-run over a completed phase is a no-op. Confirm you want the capability rather than inheriting it from the schema.

### 4. Which note, when a card has two checklist-shaped notes?

The note patch takes a `noteId` in its path, so the agent names one. Probably a non-issue; confirm rather than assume.

## Affects the spike only

### 5. Do you run WorkLists from more than one machine against the same synced folder?

Traced: `data/todos-OfficeComputer1.json` and `data/boards-PDLP-D362HS3.json` are referenced by nothing — absent from `SECTIONS`, and no `os.hostname()` call exists anywhere in the app. Inert files.

If you do not work from two machines against this folder, drop the cross-machine measurements and **W7 shrinks by more than half.**

### 6. Is moving `data/` outside OneDrive on the table?

It would eliminate the spike entirely — no sync, no conflict copies, no `EBUSY` retries. If yes, that is a better thing to spec than the spike.

---

## Decisions already made, recorded so they are not reopened by accident

| Decision | Where |
| --- | --- |
| The effort is bounded to the card the agent is given an id for | This document, `stories/dnu/README.md` |
| Path A: you supply the id. Path B: the agent creates from the designated Card Template and reports the new id | W2, W3, W6 |
| A Card Template defines a whole ticket — card body plus ordered notes — authored in settings | W3, story 05 |
| `currentStep` is written at phase start; rows and `nextUp` at completion | W6 |
| Every guard stop notifies; a skip does not | W6 |
| The card id is never searched for | `001` → D1 |
| Patch the resource; actions get endpoints, field updates do not | `001` → API shape principle |
| The checklist **format** is the contract, not a template | `001` → D3 note, W3 |
| Row addressing is exact text as just read, made safe by the precondition | W4 |
| The agent's core duty is judgement, not lookup | W6 |
| Additive only now; replacement is the eventual destination | `001` → Governing constraint |
| Existing DAL callers migrate onto record access later, as a separate change | `001` → What this constraint defers |
| A workflow card is identified by structure, not by carrying a ticket id | `001` |
| The agent never moves cards between columns | W6 |
| The agent never adds or removes checklist rows | W6 |
| A missing fact leaves a detail line blank, never fabricated | W6 |
