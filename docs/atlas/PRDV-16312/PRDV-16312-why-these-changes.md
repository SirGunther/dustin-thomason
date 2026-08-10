# Why these changes — PRDV-16312

## The class of problem

**Callisto is the writer of record for client deliverables, but nothing downstream is told when one appears.** A file uploaded straight into client deliverables exists in Callisto and is invisible to Planet Portal (Dione), so a client who was given a deliverable cannot reach it.

The class is **replication of a write Callisto owns into a consumer that must project it** — not a bug, not a UI gap. PRDV-16293 built the carrier (command-driven outbox + dispatcher); this ticket is the **first producer to use it**. Every sibling in epic PRDV-15736 (16310 grants, 16311 approve, 16313 rename, 16314 recategorize, 16315 unapprove) is the same class at a different write site, which is why getting the shape right here matters more than the one endpoint suggests.

## Why one event and not two

The request asked for two emissions. The design says one.

`callisto.client-access.collection.created.v1` **does not exist by decision.** Design doc Q21: *"Removed. Dynamic collection creation is communicated inline via `deliverableCollectionId` + `deliverableCollectionValue` fields on `file.created.v1` … Dione upserts the collection record from these fields."* Q15 reaches the same conclusion from the transaction's own shape: find-or-create plus file-create in one `@Transactional()` writes **1 outbox row**.

The consequence that matters for correctness: because the value is carried inline **whether the collection was just created or already existed**, there is no created-vs-found branch to get wrong, no ordering dependency between two events, and no partial-failure state where a client sees a grouping with no file in it. The less-granular catalog removed a whole class of failure rather than merely saving a row.

## Why-log

### Phase 2 — course change (2026-08-05)

**Course change — the ticket asks for an event that was deliberately removed; the wiki spec, not the ClickUp text, is authoritative.**

Phase 1 correctly found that `collection.created` was gone (registry omission + PRDV-16293 commit `31c81db4` "Remove collection.created"). It reached the **wrong disposition**: it carried story 02 as "gated on decision D1 — inline vs restore the event," and staged a change to widen `DynamicCollectionProjection` with a created-vs-found flag.

Both were wrong, and the evidence that says so was available at Phase 1: the ticket text names its wiki spec under `## Wiki`, that path was captured verbatim in `PRDV-16312-original-ticket.md`, and Phase 1 did not follow it. **Reading the ticket's own cited source would have answered D1 outright.** Recorded as a course change rather than edited into the frozen recon-and-plan.

What the wiki settled, all of it evidence rather than judgment:

| Phase 1 said | Corrected |
| --- | --- |
| D1 open: inline vs restore the event | **Decided — inline** (Q21, Q15) |
| F3: widen the projection for created-vs-found | **Unnecessary** — value carried regardless of created-or-existed |
| D2: docking publish + RabbitMQ for a new routekey | **Evaporates** — `FILE_CREATED` is already registered |
| D3: the other two collection-creating surfaces | **Answered** — approve-v2 is PRDV-16311, recategorize is PRDV-16314 |
| D4: partial failure between two events | **Evaporates** — one event |
| "Thin: the data it needs is never enumerated" | **Enumerated** — 17 typed fields (Q20) |

**Discarded path:** treating the ClickUp description as the specification. Q25 records the standing convention — *"ClickUp stays wiki-pointer"* — so the ticket text is a pointer, and the wiki is the spec.

**New understanding — the drift has a traceable cause, and it is worth reporting upstream.** The design doc's Status checklist contradicts its own resolved bodies:

- Line 1581: *"Q15 — Resolved (Option C: proactive emission; confirmed **2 outbox writes** at upload-complete)"* — while Q15's body concludes **1 outbox row**.
- Line 1588: *"Q22 — Resolved (**9 events** total: … **collection.created**, collection.deleted …)"* — while Q22's table lists **11** events and omits `collection.created` entirely.

The ClickUp ticket's two-event framing matches those stale lines almost word for word. The bodies are internally consistent and are being followed; the **checklist** is stale. Flagged for Larry (design lead) as a documentation defect, not a design disagreement.

### Phase 1 — initial understanding (2026-08-05)

- **Class established:** replication of a Callisto-owned write into a consumer projection; this ticket is the outbox foundation's first producer.
- **Obvious going in:** two emissions, one conditional, from a known endpoint.
- **Not obvious:** `collection.created` had been deliberately deleted by the prerequisite; the created-vs-found signal is computed inside the assembler then discarded at its return type; collection creation has three call sites while file creation has one; `CLIENT_ACCESS_OUTBOX` had zero production consumers.
- **Assumption logged:** that docking 1.0.7 still exported a collection-created contract. Superseded at Phase 2 — the question was moot.
- **Noise, in hindsight:** the local `node_modules` staleness (installed docking 1.0.5 vs lockfile 1.0.7) read as possibly load-bearing during recon. It was an environment fact throughout and never bore on the design.
