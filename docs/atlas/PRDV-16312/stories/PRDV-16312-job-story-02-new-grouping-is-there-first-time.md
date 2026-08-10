# Job story 02 — a brand-new grouping is there the first time a file lands in it

| Field | Value |
| --- | --- |
| Ticket | PRDV-16312 |
| Project | atlas (implementation: `callisto-back-end`) |
| Drafted | 2026-08-05 |
| Status | **`accepted`** (Phase 3, 2026-08-05) |
| Source | [PRDV-16312-original-ticket.md](../PRDV-16312-original-ticket.md) → Original Request |

**The ticket's own acceptance criteria were read as input, not copied as output.** Two of them concern this story — one requiring an extra emission when a new dynamic collection was created, one requiring silence when find-or-create returned an existing row. Both are stated in mechanism terms; both are rebuilt below as outcomes someone can observe.

**Why this story is separate from story 01** — the request carries two motivations, which is the signal to split. Story 01's is *I cannot find the file at all*. This one's is *the place the file belongs does not exist for me yet, or exists twice*. The conditions differ too: story 01's guarantee is unconditional, this one's fires only on first creation and carries a matching negative — nothing extra happens when the grouping was already there.

---

## 1. Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | A client doesn't want a deliverable to turn up somewhere that makes no sense to them. |
| Context + Intent | *While [context], they want to [action].* | While checking a case for what they've been given, they want each file to sit under the right track, collection, and deliverable type in the hierarchy. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that when a file arrives in a grouping that never existed before, no record of the new grouping is sent to the portal, so they want the portal to be told about the grouping as well as the file. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to find the file in its proper place the first time, with each grouping listed once. |

## 2. Revision Matrix

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that when a file arrives in a grouping that never existed before, no record of the new grouping is sent to the portal, so they want the portal to be told about the grouping as well as the file. | Names the receiving system and the sending of records — solution-speak. It also states the fix (send a second record) inside the obstacle, which pre-commits the design. | Except that a file can be the first thing ever filed under a grouping, and that grouping is missing for them, so they want the grouping to be there the moment the first file lands in it. |
| Context + Intent | While checking a case for what they've been given, they want each file to sit under the right track, collection, and deliverable type in the hierarchy. | Borrows the system's structural vocabulary ("collection", "hierarchy") rather than what the client is doing. | While checking a case for what they've been given, they want each file to sit under the grouping it belongs to. |

## 3. Delivery Acceptance Statement (DAS)

> *We know this story is considered complete when:*
> - When an upload files a deliverable under a grouping the client has never had before, the client can see that grouping as soon as the file lands in it.
> - When the upload files under a grouping the client already has, that grouping is not listed a second time.
> - A new grouping shows up under the correct track, so the client is not hunting for it elsewhere.
> - Both cases — a first-time grouping and an already-existing one — can be watched happening in a shared test environment.

## 4. Concatenated Story

A client doesn't want a deliverable to turn up somewhere that makes no sense to them. While checking a case for what they've been given, they want each file to sit under the grouping it belongs to. Except that a file can be the first thing ever filed under a grouping, and that grouping is missing for them, so they want the grouping to be there the moment the first file lands in it. Now they'll be able to find the file in its proper place the first time, with each grouping listed once.

## 5. Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A client doesn't want a deliverable to turn up somewhere that makes no sense to them. | Vague phrasing — "makes no sense" is not something anyone can check. | A client doesn't want a deliverable to turn up in a spot they wouldn't think to look. |
| While checking a case for what they've been given, they want each file to sit under the grouping it belongs to. | Observation: already concrete, everyday, and free of design words — no change. | While checking a case for what they've been given, they want each file to sit under the grouping it belongs to. |
| Except that a file can be the first thing ever filed under a grouping, and that grouping is missing for them, so they want the grouping to be there the moment the first file lands in it. | Wordiness — the grouping is named three times. | Except that a file can be the first thing ever filed under a grouping, and that grouping isn't there for them, so they want it in place the moment the first file lands. |
| Now they'll be able to find the file in its proper place the first time, with each grouping listed once. | Everyday phrasing reads truer than "find". | Now they'll be able to spot the file in its proper place the first time, with each grouping listed once. |
| When an upload files a deliverable under a grouping the client has never had before, the client can see that grouping as soon as the file lands in it. | Wordiness. | A client can see a brand-new grouping as soon as the first file is filed under it. |
| When the upload files under a grouping the client already has, that grouping is not listed a second time. | Wordiness. | Filing into a grouping the client already has does not make that grouping show up twice. |
| A new grouping shows up under the correct track, so the client is not hunting for it elsewhere. | Observation: concrete and checkable; tightened only for register. | A brand-new grouping shows up under the correct track, not somewhere the client has to hunt for it. |
| Both cases — a first-time grouping and an already-existing one — can be watched happening in a shared test environment. | Vague phrasing — does not say who does the watching. | Someone can watch both cases in a shared test environment: a first-time grouping, and one that already existed. |

## User Story

A client doesn't want a deliverable to turn up in a spot they wouldn't think to look. While checking a case for what they've been given, they want each file to sit under the grouping it belongs to. Except that a file can be the first thing ever filed under a grouping, and that grouping isn't there for them, so they want it in place the moment the first file lands. Now they'll be able to spot the file in its proper place the first time, with each grouping listed once.

## Acceptance Criteria

- A client can see a brand-new grouping as soon as the first file is filed under it.
- Filing into a grouping that already exists does not make that grouping show up twice for the client.
- A brand-new grouping shows up under the correct track, not somewhere the client has to hunt for it.
- Someone can watch both cases produce a record naming the grouping: a first-time grouping, and one that already existed.

## Open Questions

Carried, not decided. Each names whether it is a fact the code can settle or a decision someone owns.

| # | Question | Fact or decision | Notes |
| --- | --- | --- | --- |
| 02.Q1 | Is "collection" a word the client actually sees, or internal vocabulary? | Decision | **Still open.** The criteria say "grouping" deliberately, to avoid asserting client-facing language no source establishes. Dione owns the client-facing label; the design doc does not settle it. |
| 02.Q2 | If the grouping's arrival is known but the file's is not — or the reverse — what should the client see: nothing, or an empty grouping? | ~~Decision~~ | **CLOSED at Phase 2 — the question is void.** There is only ever **one** event, carrying both the file and its collection inline (design Q15/Q21). There is no state in which one arrived and the other did not. |
| 02.Q3 | Must the grouping be visible before the file, or is the same moment acceptable in either order? | ~~Decision~~ | **CLOSED at Phase 2 — void for the same reason.** No two events, so no ordering between them. Design Q18 separately accepts eventual consistency and requires no ordering guarantees. |
| 02.Q4 | Can a grouping be created by a path other than this direct upload, and does that path owe the client the same guarantee? | Fact — code-discoverable | **CLOSED at Phase 2 by evidence.** Three call sites create dynamic collections (`saveDynamic` → one caller, the assembler → three callers): upload-complete, recategorize, approve-v2. Each is owned by its own epic sibling — **PRDV-16311** (approve-v2 → `file.approved.v1`) and **PRDV-16314** (recategorize → `file.recategorized.v1`), both carrying the same inline collection fields (design Q20). The class is covered; not by this ticket. |
| 02.Q5 | When the grouping already exists, does anything about it still need refreshing if the upload changed something? | Fact | **CLOSED at Phase 2.** `deliverableCollectionValue` is sent on every file event regardless of created-or-existed, and Dione **upserts** from it (Q21). An existing grouping is therefore refreshed by every file event that references it. |
| 02.Q6 | What makes a grouping "the client's" — is a grouping visible to one client, to a case, or to an organization? | Fact — code-discoverable | **CLOSED at Phase 2.** A dynamic collection is scoped to `proceedingId` + `trackTypeId`, not to a client. Client visibility is resolved separately, at query time in Dione, by joining grants (`principalType`/`principalId` + `proceedingId` + `deliverableTypeId`, with a null collection meaning a track-level grant) — design "How Dione resolves file visibility with nulls". **Criteria 1 and 2 are reworded below** to drop the incorrect "the client already has" phrasing. |

## Story log

_Newest first. One entry per phase or session in which this story moved._

### 2026-08-05 — Phase 3 (Probe & spec) — **accepted**; criterion 4 reworded by LD-007; two decisions made this story implementable

Criterion 4 reworded for the same reason as story 01's: RabbitMQ was descoped (LD-007), so the observable end-state within this ticket is the record naming the grouping, not a client-visible render in a shared environment. Original wording preserved above in the Final Review Matrix.

**Two Phase 3 decisions were needed specifically to make this story's criteria reachable**, and both came out of reconciling the payload against the code rather than from the ticket:

- **LD-011** — the code could not satisfy criterion 1 on one branch. When a file is filed into an **existing** collection by id, the TS never calls the assembler and so never learns the collection's `value`; a repository read by id was added. Without it, a client filing into an existing grouping would have got `null` and the grouping would not have been named at all.
- **LD-012** — `deliverableCollectionValue` is populated for **static** collections too, not only dynamic. Carries an accepted risk (concern **C7**): Dione owns static collection rows via its own migrations, and whether receiving their names is inert depends on an upsert this repo cannot read.

- **Still carried:** `02.Q1` (is "collection" the client-facing word — Dione/UX). Labeling only; does not affect the payload.
- **Relevant decisions:** LD-001, LD-003, LD-004, LD-011, LD-012.
- Status → **`accepted`**.

### 2026-08-05 — Phase 2 (Report) — five of six questions closed; mechanism corrected; one criterion reworded

**The criteria did not change on what done means. The mechanism behind them did.**

The story was drafted expecting a second event (`collection.created.v1`). There is no second event: it was removed by design (Q21), and the grouping's name travels **inline** on `file.created.v1` as `deliverableCollectionValue`, which Dione upserts from — sent whether the collection was just created or already existed. So this story is **not** superseded and does **not** move to `dnu/`: a client still needs the grouping to be there the first time and not to appear twice, which is exactly what the criteria say. Only the *how* moved, and per the job-story rules a decision wins on *how* while the criterion keeps owning *what*.

- **Closed by evidence:** `02.Q2` and `02.Q3` are **void** — one event means no partial-arrival state and no inter-event ordering. `02.Q4` closed: three creation sites exist, and the other two belong to siblings PRDV-16311 and PRDV-16314. `02.Q5` closed: every file event refreshes the grouping via upsert. `02.Q6` closed: collections are scoped to `proceedingId` + `trackTypeId`, not to a client.
- **Criterion reworded:** criterion 2 said *"a grouping the client already has"*, which asserted client-scoped groupings — factually wrong per `02.Q6`. Now *"a grouping that already exists … twice for the client"*, keeping the observable outcome while dropping the false premise. This is a Final Review Matrix failure caught late, not a reinterpretation to match an implementation.
- **Still open:** `02.Q1` only (is "collection" the client-facing word — Dione's call).
- Status stays `draft`; acceptance is Phase 3.

### 2026-08-05 — Phase 0 (Capture) — created as `draft`

Split out of the verbatim request alongside story 01, on the compound-motivation rule: the request carries both "the file is unfindable" and "the place it belongs does not exist yet". The ticket's negative criterion (no emission when find-or-create returned an existing row) was rebuilt as an observable outcome — the grouping does not show up twice — rather than restated as a mechanism. The partial-failure behavior of the two emissions was left as an open question rather than folded into a criterion, since the request does not decide it. Six open questions carried; none answered by inference.
