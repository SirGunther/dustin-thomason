# Locked decisions — atlas/PRDV-16312

Per `qa-to-spec-traceability`. Each row is settled and carries its source. **Evidence-settled** rows were resolved by tracing code or an authoritative doc and were never brought to the user as choices; **grilled** rows were genuine decisions the code could not answer.

Summary table lives in the spec's *Locked Decisions From Q and A* section and links here.

## Question gates resolved before grilling

| Gate | Outcome |
| --- | --- |
| Is the answer discoverable in code or an authoritative doc? | 12 of 15 items were — resolved by evidence (LD-001…LD-010, LD-014, LD-015) and **not** put to the user. |
| Does the item bundle a fact with a decision? | Yes for LD-011 and LD-012. The **fact** (the value is unreachable on the by-id branch; `collection_kind` exists) was traced; only the **choice** was grilled. |
| Is it a decision the user/design owner must make? | 3 items — LD-011, LD-012, LD-013. Grilled 2026-08-05. |

## Decision ledger

| # | Decision | Source | Supersedes / rejects | Spec destination |
| --- | --- | --- | --- | --- |
| **LD-001** | Emit **one** event, `callisto.client-access.file.created.v1`. `collection.created.v1` is a **non-goal**. | Evidence — design Q21 (*"Removed"*), Q15 (*"1 outbox row"*); ODP 1.0.7 does not export `COLLECTION_CREATED`; Callisto registry omits it; commit `31c81db4` | **Rejects** the ClickUp description's two-event framing | §Summary, §Non-goals |
| **LD-002** | The `larry-adams` wiki spec + design doc are authoritative over the ClickUp text. | Evidence — design Q25: *"ClickUp stays wiki-pointer"* | Rejects treating ClickUp AC as the specification | §Sources |
| **LD-003** | Collection identity travels **inline** on the file event via `deliverableCollectionId` + `deliverableCollectionValue`; Dione upserts from them. | Evidence — design Q21; ODP contract doc comment `:4-5` | — | §Event payload |
| **LD-004** | **No** created-vs-found flag is added to `DynamicCollectionProjection`. | Evidence — AC3 populates the value regardless of created-or-existed | **Supersedes** the approved Phase 1 plan's F3 proposal (recorded as a why-log course change) | §Non-goals |
| **LD-005** | Emission lives inside the `@Transactional()` transaction script, after `deliverableFileRepository.create`. | Evidence — design Diagram 6 (domain write + outbox row same transaction); Q5 (command-driven) | Rejects emitting from the action or a service; rejects projection-driven | §Where to emit |
| **LD-006** | **No** `orbital-docking-protocol` change is required. | Evidence — ODP 1.0.7 exports `CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1` and a complete 17-field `CallistoClientAccessFileCreatedV1Data` | Resolves Derrick's *"you might need to update the orbital-docking-protocol"* caveat as unnecessary | §Dependencies |
| **LD-007** | **AC6 (dev RabbitMQ queue visibility) is withdrawn from scope.** The producer's obligation ends at a correctly shaped `outbox_events` row. | Grilled — Derrick, 2026-08-05: *"I am removing the RabbitMQ requirements from the Atlas metadata -> PP epic… The RabbitMQ queue creation will be handled when the consumer (Planet Portal) is dev-ready"*. **Confirmed in the spec text itself** (verified 2026-08-06): commit `318bd0a` deletes that AC from all 9 epic specs and rewords each Manual test to *"confirm an outbox row is written with the expected routekey + payload"*; PRDV-16293 now states *"Queue creation is out of scope. This is the producer side — tickets end at writing to the outbox."* | **Supersedes** wiki AC6 — which is now literally deleted, not merely overridden; **closes** OV-4; leaves `RABBITMQ_CONFIG_REQUEST_TEMPLATE.md` deliberately unfilled | §Testing, §Non-goals |
| **LD-008** | Scope is **Callisto only**. | Grilled — Derrick: *"this is almost all Callisto work"* | Rejects pulling in Atlas FE or Dione work | §Scope |
| **LD-009** | The other two collection-creating sites (recategorize, approve-v2) stay **out of scope** — owned by PRDV-16314 and PRDV-16311. | Evidence — three-site enumeration (`saveDynamic` → 1 caller → 3 callers); design Q20/Q22 | Rejects folding sibling scope in | §Non-goals |
| **LD-010** | `createdUserIdentity` ← `params.userId`, passed through unchanged. | Evidence — the mapper already assigns `file.createdUserIdentity = params.userId`; ODP example shows a UUID identity string | Closes OV-5 / A9 | §Field sourcing |
| **LD-011** | When no `pendingDynamicCollectionName` is supplied, **read the collection by id** to obtain `value`. | **Grilled** 2026-08-05 — *"Repository read in that branch"* | Rejects sending `null` on the by-id branch (would break AC3's *"or already existed"*) and rejects always-read on both branches | §Field sourcing, §Implementation steps |
| **LD-012** | ~~Populate `deliverableCollectionValue` for static and dynamic alike.~~ **SUPERSEDED 2026-08-07 — see LD-016.** | Grilled 2026-08-05 | — | — |
| **LD-016** | Populate `deliverableCollectionValue` for **dynamic collections only**; `null` for static and for no collection. Gated on `collection_kind`. | Evidence — the spec scopes it to dynamic in **five** places: *"inline dynamic collection data"* (:23), *"populated for files in **dynamic** collections"* (:33), *"upsert the **dynamic** collection"* (:47), *"inline name for **dynamic** collections"* (:56), *"sourced from the **dynamic** collection entity's `value` field"* (:83) | **Supersedes LD-012**, which went beyond the spec. Retires concern **C7** — the risk it described no longer exists | §Event payload, §Field sourcing |

### Why LD-012 was wrong, recorded rather than quietly replaced

LD-012 was reached by treating the spec as *silent* on static collections and grilling the user for a decision. **The spec was not silent** — it says "dynamic" five times, including in the field-sourcing step. The gap was invented, the question should never have been asked, and the resulting code sent a collection name the consumer owns. Corrected in `callisto-back-end` `e8c149ae`.

The wider lesson, which is the actual finding: **an authoritative spec should be re-read before it is treated as ambiguous.** Two of the three "decisions beyond the spec" submitted for review at Phase 3 were not spec questions at all — the by-id read (LD-011) is simply how the spec's existing criterion gets satisfied, and the converter typing (LD-013) is internal style. Only LD-012 looked like a genuine gap, and it was not one. `larry-adams` PR #34 was closed for this reason and the spec was left untouched.
| **LD-013** | The new converter's return type is ODP's **`CallistoClientAccessFileCreatedV1Data`**, imported directly — not a hand-declared local twin. | **Grilled** 2026-08-05 — *"Type the converter as ODP's data type"* | **Deliberately deviates** from the `ContactOutboxEvent` precedent, which re-declares the shape locally. Rejects tightening the shared port (wider blast radius across five siblings). Closes OV-2 | §Contract enforcement |
| **LD-014** | Payload assembly lives in a **dedicated converter**, not inline in the TS. | Evidence — house pattern `ContactToOutboxDescriptorAssembler` + `ContactToOutboxDataConverter`; also the video-transcode descriptor converter | Closes OV-3; rejects inline assembly | §New classes |
| **LD-015** | `createdAt` ← `file.createdAt` (`BaseEntity.@CreateDateColumn`), serialised ISO 8601; `fileId` ← `file.id` and `fileAttachmentId` ← `file.fileAttachment.id`, both available after `save()`. | Evidence — `File extends BaseAuditEntity extends BaseEntity`; `repository.create` = `repo.save(file)`, which populates generated columns in place | — | §Field sourcing |

## Risk accepted

**LD-012** carries an accepted risk: Dione will receive `deliverableCollectionValue` for **static** collections whose rows its own migrations own and seed. The decision rests on Dione's handler being a genuine idempotent upsert — which is what design Q21 specifies (*"Dione upserts the collection record from these fields"*) but which **is not verifiable from this repo**, and the RabbitMQ descope (LD-007) removed the observation step that would have shown it. If Dione's upsert is keyed on id, this is a no-op; if it overwrites names, a static collection could be renamed by a file event. Recorded as concern **C7**; that entry is the standing record of this risk.

## Deliberate deviation from precedent

**LD-013** is the one place this ticket knowingly does something the repo does not do elsewhere. Stated plainly so a reviewer does not read it as an inconsistency: every existing outbox producer hand-declares its payload type in parallel with ODP (`ContactOutboxEvent` does not alias `CallistoContactCreatedV1Data`), which is exactly the drift risk in concern C3. Typing against the exported ODP type costs nothing, and after LD-007 removed the downstream safety net it is the only mechanism left that fails loudly on contract drift.

## Carried forward — not closed

These reached Phase 3 without an owner in Callisto because they are **consumer-side or product** questions. Each is carried with a named owner rather than silently dropped, and none blocks this ticket's producer work.

| Item | Owner | Why carried |
| --- | --- | --- |
| Story `01.Q1` — is the client the right user type, or the internal uploader? | Product / Larry | Does not change the payload or the emission; would only reword story 01's Motivation row. |
| Story `01.Q3` — must the file be reachable on every client-facing surface? | Dione team | Consumer rendering, outside Callisto. |
| Story `01.Q8` — does any surface need to state the seconds-scale latency? | Product | Design Q18 bounds it (*"RabbitMQ delivers in seconds"*, no ordering guarantees); whether to surface it is a UX call. |
| Story `02.Q1` — is "collection" the client-facing word? | Dione / UX | Labeling, consumer-side. |
