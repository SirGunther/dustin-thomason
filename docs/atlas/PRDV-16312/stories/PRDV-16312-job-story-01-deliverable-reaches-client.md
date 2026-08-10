# Job story 01 — a newly uploaded deliverable reaches the client

| Field | Value |
| --- | --- |
| Ticket | PRDV-16312 |
| Project | atlas (implementation: `callisto-back-end`) |
| Drafted | 2026-08-05 |
| Status | **`accepted`** (Phase 3, 2026-08-05) |
| Source | [PRDV-16312-original-ticket.md](../PRDV-16312-original-ticket.md) → Original Request |

**The ticket's own acceptance criteria were read as input, not copied as output.** They are stated in mechanism terms (outbox rows, routekeys, payload types, queue visibility). Those are design constraints and belong to the spec; this story rebuilds them as outcomes someone can observe without knowing how the system is put together.

**Why this story is believed** — the request's Summary says the emission exists so "Dione the data it needs to display the file under the correct track → collection → deliverable type hierarchy." The party who is short of something is therefore the person looking at that display, and what they are short of is the file itself. That pairing — the question *who is missing what* and the reason for believing it — is what the criteria below are answerable against.

---

## 1. Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | A client doesn't want to be told a deliverable is ready and then not be able to find it. |
| Context + Intent | *While [context], they want to [action].* | While looking through what they've been given on a case, they want to open the file that was just added for them. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that a file added straight into their deliverables is never announced to the portal, so they want the portal to be told about the file as soon as it is added. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to open a newly added deliverable themselves, without anyone re-sending it. |

## 2. Revision Matrix

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that a file added straight into their deliverables is never announced to the portal, so they want the portal to be told about the file as soon as it is added. | Names the receiving system and the act of announcing to it — solution-speak. The story must hold whether the mechanism is messaging, polling, or a shared read. | Except that a file added straight into their deliverables does not show up for them at all, so they want it to appear alongside the rest as soon as it lands. |
| Context + Intent | While looking through their case's deliverable hierarchy, they want to open the file that was just added for them. | "Deliverable hierarchy" borrows the system's structural vocabulary rather than what the client is doing. | While looking through what they've been given on a case, they want to open the file that was just added for them. |

## 3. Delivery Acceptance Statement (DAS)

> *We know this story is considered complete when:*
> - A file uploaded straight into a client's deliverables becomes reachable by that client without anyone re-uploading or re-sending it.
> - The file appears under the same track, grouping, and deliverable type it was filed under, not in a default or fallback spot.
> - What the client sees for that file — its name, type, and placement — matches what was uploaded.
> - The arrival is confirmed to travel end to end in a shared test environment, not only on a developer machine.
> - A failed upload leaves nothing for the client to find.

## 4. Concatenated Story

A client doesn't want to be told a deliverable is ready and then not be able to find it. While looking through what they've been given on a case, they want to open the file that was just added for them. Except that a file added straight into their deliverables does not show up for them at all, so they want it to appear alongside the rest as soon as it lands. Now they'll be able to open a newly added deliverable themselves, without anyone re-sending it.

## 5. Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A client doesn't want to be told a deliverable is ready and then not be able to find it. | Vague phrasing — "be told" leaves the situation unspecific. | A client doesn't want to hear that a deliverable is ready and then come up empty when they go looking for it. |
| While looking through what they've been given on a case, they want to open the file that was just added for them. | Wordiness; formal register in "looking through". | While checking what they've been given on a case, they want to pull up the file that was just added for them. |
| Except that a file added straight into their deliverables does not show up for them at all, so they want it to appear alongside the rest as soon as it lands. | Wordiness. | Except that a file added straight into their deliverables never shows up for them, so they want it to sit alongside the rest as soon as it lands. |
| Now they'll be able to open a newly added deliverable themselves, without anyone re-sending it. | Everyday phrasing reads truer than "open". | Now they'll be able to pull up a newly added deliverable themselves, without anyone re-sending it. |
| A file uploaded straight into a client's deliverables becomes reachable by that client without anyone re-uploading or re-sending it. | Vague phrasing — "becomes reachable" is not something you watch happen. | A client can pull up a file that was uploaded straight into their deliverables, without anyone re-uploading or re-sending it. |
| The file appears under the same track, grouping, and deliverable type it was filed under, not in a default or fallback spot. | Wordiness. | The file sits under the same track, grouping, and deliverable type it was filed under — not in a catch-all spot. |
| What the client sees for that file — its name, type, and placement — matches what was uploaded. | Non-observable outcome — "matches" does not say what a failure would look like. | What the client sees for the file — its name, its type, and where it sits — matches what was uploaded, with nothing blank or unnamed. |
| The arrival is confirmed to travel end to end in a shared test environment, not only on a developer machine. | Solution-speak — "travel end to end" describes the plumbing rather than the outcome. | Someone can watch a real upload reach the client's view in a shared test environment, not only on a developer machine. |
| A failed upload leaves nothing for the client to find. | Non-observable outcome — proving "nothing" as written is not checkable. | When an upload does not finish successfully, the client is not shown a file that isn't really there. |

## User Story

A client doesn't want to hear that a deliverable is ready and then come up empty when they go looking for it. While checking what they've been given on a case, they want to pull up the file that was just added for them. Except that a file added straight into their deliverables never shows up for them, so they want it to sit alongside the rest as soon as it lands. Now they'll be able to pull up a newly added deliverable themselves, without anyone re-sending it.

## Acceptance Criteria

- A client can pull up a file that was uploaded straight into their deliverables, without anyone re-uploading or re-sending it.
- The file sits under the same track, grouping, and deliverable type it was filed under — not in a catch-all spot.
- What the client sees for the file — its name, its type, and where it sits — matches what was uploaded, with nothing blank or unnamed.
- Someone can watch a real upload produce a complete, correctly shaped record of that file — its name, type, and placement — ready for the client's view, without hand-editing anything.
- When an upload does not finish successfully, the client is not shown a file that isn't really there.

## Open Questions

Carried, not decided. Each names whether it is a fact the code can settle or a decision someone owns.

| # | Question | Fact or decision | Notes |
| --- | --- | --- | --- |
| 01.Q1 | Is the client the right user type, or is it the internal person who uploads and needs to confirm the client received it? | Decision | Per the job-story revisit rules, a wrong user type invalidates every row below Motivation — so this is asked first, not last. The request's Summary points at the display, which points at the client. |
| 01.Q2 | How soon must the file be reachable — same second, next page load, within some window? | Decision | The request states no promptness expectation at all. Affects whether criterion 1 needs a time bound. |
| 01.Q3 | Does the file have to be reachable everywhere the client can see deliverables, or is one surface enough? | Decision | The request says "display the file under the correct track → collection → deliverable type hierarchy" and names no surface count. |
| 01.Q4 | Does the shape the request names (`CallistoClientAccessFileCreatedV1Data`) already carry everything the client needs to recognize the file — name, type, placement? | Fact — code-discoverable | **CLOSED at Phase 2 — yes.** Design Q20 specifies 17 fields, covering name (`fileName`), type (`fileType`, `deliverableTypeId`), and placement (`trackTypeId`, `deliverableCollectionId`, `deliverableCollectionValue`). Criterion 3 is satisfiable. Note the shape is **not** enforced by the port, which takes `Record<string, unknown>` — the spec owns how it is enforced. |
| 01.Q5 | Is the prerequisite (PRDV-16293, outbox + dispatcher foundation) actually merged? | Fact — code-discoverable | **CLOSED at Phase 1 — yes.** Merge commit `43ad3dea`, PR #399. |
| 01.Q6 | What counts as "an upload that does not finish successfully" — and is the client-visible guarantee already provided by existing behavior, or does this story add it? | Fact — code-discoverable | **CLOSED at Phase 2.** The TS is `@Transactional()` and the outbox row is written in the same DB transaction as the domain rows (design Diagram 6: "Domain write + outbox row are in the same DB transaction"). A validator throw or failed persist rolls both back, so no event escapes for a file that does not exist. Criterion 5 is a **regression guard** on existing atomicity, not new work. |
| 01.Q7 | If the file's arrival is known but its grouping's is not (see story 02), what should the client see? | ~~Decision~~ | **CLOSED at Phase 2 — void.** One event carries both; there is no divergent-arrival state. |
| 01.Q8 | How soon is "as soon as it lands" in practice? | Decision — bounded by design | **Partly closed.** Design Q18: no ordering guarantees needed, "RabbitMQ delivers in seconds", brief inconsistency during races acceptable, "distributed reliability > immediate consistency". So seconds-scale, asynchronous. Supersedes `01.Q2`'s framing; what remains is whether any client-facing surface needs to *state* that latency. |

## Story log

_Newest first. One entry per phase or session in which this story moved._

### 2026-08-05 — Phase 3 (Probe & spec) — **accepted**; criterion 4 reworded by LD-007

**Criteria unchanged except one, and that one was forced by a scope change, not by an implementation.**

Criterion 4 read *"Someone can watch a real upload reach the client's view in a shared test environment."* RabbitMQ was removed from the epic (LD-007, Derrick: *"The RabbitMQ queue creation will be handled when the consumer (Planet Portal) is dev-ready to consume it"*), so no shared-environment client-visible observation is possible within this ticket. Reworded to state what **is** observable and falsifiable now — the correctly shaped record Callisto is responsible for producing. The original wording is preserved here rather than quietly replaced.

This is the one criterion the ticket cannot fully prove, and saying so is the point: the client-visible half genuinely depends on a consumer that does not exist yet. It was **not** reinterpreted to match what got built — the scope boundary moved, on the record, by someone with the authority to move it.

- **Carried forward with owners, not dropped:** `01.Q1` (user type — Product/Larry), `01.Q3` (surface count — Dione team), `01.Q8` (stated latency — Product). None changes the payload or the emission; each is recorded in the locked-decision ledger's *Carried forward* table.
- **Relevant decisions:** LD-001, LD-003, LD-005, LD-007, LD-010, LD-013, LD-015.
- Status → **`accepted`**.

### 2026-08-05 — Phase 2 (Report) — five questions closed, criteria unchanged

The wiki spec and design doc closed `01.Q4` (17-field payload specified), `01.Q6` (atomicity already guarantees no event for a failed upload — criterion 5 is a regression guard), and `01.Q7` (void — one event). `01.Q5` closed at Phase 1 (prerequisite merged). `01.Q2` is superseded by new `01.Q8`, which bounds latency at seconds-scale per design Q18.

**No criterion changed.** Every one survived contact with the design, which is the outcome to want — the story was written from the client's vantage point and the design happened to serve it. `01.Q1` (is the client the right user type) and `01.Q3` (how many surfaces) remain open for Phase 3, along with `01.Q8`'s remainder. Status stays `draft`.

### 2026-08-05 — Phase 0 (Capture) — created as `draft`

Drafted from the verbatim request alone, before any investigation exists. The request's two distinct problems were split: this story owns the file being findable at all; story 02 owns the grouping it lands in. The ticket's mechanism-level acceptance criteria were read as input and rebuilt as observable outcomes — no criterion here names an outbox row, a routekey, a payload type, or a queue. Seven open questions carried; none answered by inference.
