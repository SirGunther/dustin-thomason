# Job stories — atlas/PRDV-16312

Source: [PRDV-16312-original-ticket.md](../PRDV-16312-original-ticket.md) (ClickUp capture — **pointer only**, see below)
Authority on scope: `larry-adams/systems/neptune/callisto/granting-client-acess/epic-PRDV-15736-.../PRDV-16312-endpoint-upload-complete-file-created.md` and its design reference `dione-file-access-event-design.md`

| # | Story | User type | Criteria | Open questions | Status | File |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | A newly uploaded deliverable reaches the client | Client (Planet Portal) | 5 | 3 carried (owners named) | **accepted** | [file](./PRDV-16312-job-story-01-deliverable-reaches-client.md) |
| 02 | A brand-new grouping is there the first time a file lands in it | Client (Planet Portal) | 4 | 1 carried (owner named) | **accepted** | [file](./PRDV-16312-job-story-02-new-grouping-is-there-first-time.md) |

Status vocabulary: `draft` / `accepted` / `superseded (see dnu/)`.

Accepted at Phase 3 on 2026-08-05. Decisions: [PRDV-16312-locked-decisions.md](../specs/PRDV-16312-locked-decisions.md).

**Both accepted with open questions carried, deliberately.** Four questions remain — story 01's `Q1` (user type), `Q3` (surface count), `Q8` (stated latency) and story 02's `Q1` (client-facing word for "collection"). Every one is **consumer-side or product**, none changes the payload or the emission, and each has a named owner in the locked-decision ledger's *Carried forward* table. Holding both stories in `draft` for questions Callisto cannot answer would have blocked the spec on another team's epic.

**One criterion moved in each story, both for the same reason.** LD-007 withdrew RabbitMQ from the epic, so "watch it reach the client's view in a shared test environment" became unobservable within this ticket. Both were reworded to what is actually falsifiable here — a complete, correctly shaped record naming the file and its grouping. The originals are preserved in each story's Final Review Matrix and the change is logged in both Story logs. **Neither was reinterpreted to fit an implementation** — the scope boundary was moved by the epic owner, before any code was written.

## Why two stories — still two, on one event

The request carried two motivations, which is why it split: the file cannot be found at all (01), and the place it belongs does not exist yet or exists twice (02). At Phase 2 the **mechanism** collapsed to a single emission — `file.created.v1` carries `deliverableCollectionId` + `deliverableCollectionValue` inline, and Dione upserts the collection from them (design Q21).

**One event does not merge the stories.** They are distinct client outcomes, separately observable and separately falsifiable: a file can arrive correctly while its grouping renders in the wrong track, and a grouping can duplicate without any file being lost. Story 02 therefore stays live, its criteria intact, with the mechanism corrected in its Story log. Neither story moved to `dnu/`.

## Phase 2 reconcile — what closed

Nine of the original thirteen open questions closed, all against evidence rather than by decision:

| Closed | How |
| --- | --- |
| `01.Q4` payload sufficiency | Design Q20 — 17 typed fields covering name, type, placement |
| `01.Q5` prerequisite merged | Commit `43ad3dea`, PR #399 |
| `01.Q6` failed upload shows nothing | Outbox row is in the same DB transaction as the domain write (Diagram 6) |
| `01.Q7` / `02.Q2` partial arrival | **Void** — one event |
| `02.Q3` ordering between events | **Void** — one event; Q18 needs no ordering guarantees |
| `02.Q4` other creation surfaces | Three sites; the other two are siblings PRDV-16311 / PRDV-16314 |
| `02.Q5` refreshing an existing grouping | Inline value on every file event; Dione upserts |
| `02.Q6` grouping scope | Scoped to `proceedingId` + `trackTypeId`, not to a client — **forced a criterion reword** |

Remaining for Phase 3: `01.Q1` (user type), `01.Q3` (surface count), `01.Q8` (does any surface need to state the latency), `02.Q1` (client-facing word for "collection").

## The ClickUp text is a pointer, not the spec

The captured ClickUp description asks for **two** events, including `collection.created.v1`. That contradicts the wiki spec and the design doc, which specify **one**. Design Q25 records the convention — *"ClickUp stays wiki-pointer"* — so the wiki wins. The ClickUp wording traces to two **stale Status-checklist lines** in the design doc (line 1581 "confirmed 2 outbox writes"; line 1588 "9 events … collection.created") that contradict those questions' own resolved bodies. Reported as a documentation defect; see the concerns artifact.

A talking points list (UI/UX, Backend, Frontend) is available on request.
