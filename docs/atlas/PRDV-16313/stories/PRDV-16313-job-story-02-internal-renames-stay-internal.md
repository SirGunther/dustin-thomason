# Job story 02 — Names given to internal files stay internal

| Field | Value |
| --- | --- |
| Ticket | PRDV-16313 |
| Project | atlas (implementation: `callisto-back-end`) |
| Drafted | 2026-08-11 (Phase 0) · Accepted 2026-08-11 (Phase 3) |
| Status | **`accepted`** |
| Source | [PRDV-16313-original-ticket.md](../PRDV-16313-original-ticket.md) — verbatim request only |
| User type | Ops user working a proceeding — **see `02.Q1`** |

Built from the verbatim request alone. This story exists because the request's third acceptance criterion — *"Only emitted for files that have the `CLIENT_DELIVERABLE` tag (non-deliverable file renames do not emit)"* — describes an outcome that is **separately falsifiable** from the sync outcome in story 01. A rename can reach the client correctly (01 satisfied) while an internal rename also leaks (02 violated), and vice versa. Folding them would let one pass under cover of the other.

---

## Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | An ops user doesn't want the names they give to their own working files leaving the internal system. |
| Context + Intent | *While [context], they want to [action].* | While getting a proceeding's files in order, they want to name their own working copies however is useful to them. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the new rename event fires from the same `PATCH /file/:fileId` handler regardless of whether the file carries the `CLIENT_DELIVERABLE` tag, so they want the emit guarded on that tag. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to feel safe renaming internal files. |

## Revision Matrix

The story must be agnostic to system design. No design words — event, fires, handler, endpoint, tag, emit, guard, payload.

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| **Obstacle + Desired Action** (always revised) | Except that the new rename event fires from the same `PATCH /file/:fileId` handler regardless of whether the file carries the `CLIENT_DELIVERABLE` tag, so they want the emit guarded on that tag. | **Solution-speak** — "rename event", "fires", "handler", "`PATCH /file/:fileId`", "`CLIENT_DELIVERABLE` tag", "emit guarded" are all system design. It also describes the implementation instead of the user's need. | Except that renaming any file on the proceeding would now push that name out to the client's side, so they want only the files actually handed to the client to carry their names outward. |
| Resolution | Now they'll be able to feel safe renaming internal files. | **Emotional abstraction** — "feel safe" is not observable. | Now they'll be able to rename their own working files without any of those names reaching the client. |
| Motivation | An ops user doesn't want the names they give to their own working files leaving the internal system. | **Solution-speak** — "the internal system" names a system boundary rather than a person's concern. | An ops user doesn't want the names they give to their own working files reaching the client. |
| Context + Intent | *(no design words — unchanged)* | — | While getting a proceeding's files in order, they want to name their own working copies however is useful to them. |

## Delivery Acceptance Statement (DAS)

> *We know this story is considered complete when:*
> - Renaming a file that was never handed to the client sends nothing to the client's side.
> - Renaming a file that *was* handed to the client still sends the new name, so the guard does not silently break story 01.
> - Whether a file counts as handed to the client is decided from the file's own record at the moment of the rename, not from anything the person renaming it has to remember to set.
> - A file that becomes a client file after being renamed does not retroactively push its earlier internal names to the client.
> - We can tell afterwards, for any rename, whether anything was sent and why.

## Concatenated Story

An ops user doesn't want the names they give to their own working files reaching the client. While getting a proceeding's files in order, they want to name their own working copies however is useful to them. Except that renaming any file on the proceeding would now push that name out to the client's side, so they want only the files actually handed to the client to carry their names outward. Now they'll be able to rename their own working files without any of those names reaching the client.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| An ops user doesn't want the names they give to their own working files reaching the client. | Observable and concrete; no issue. | An ops user doesn't want the names they give to their own working files reaching the client. |
| While getting a proceeding's files in order, they want to name their own working copies however is useful to them. | **Wordiness** — "however is useful to them" is loose. Everyday register preferred. | While sorting out a proceeding's files, they want to name their own working copies whatever makes sense to them. |
| Except that renaming any file on the proceeding would now push that name out to the client's side, so they want only the files actually handed to the client to carry their names outward. | **Vague phrasing** — "the client's side" and "carry their names outward" are both fuzzy; "would now" leaks the fact that this is a new mechanism being added. | Except that renaming any file on the proceeding would send that name to the client, so they want only the files actually handed to the client to send theirs. |
| Now they'll be able to rename their own working files without any of those names reaching the client. | Observable; no issue. | Now they'll be able to rename their own working files without any of those names reaching the client. |
| **DAS 1** — Renaming a file that was never handed to the client sends nothing to the client's side. | **Vague phrasing** — "the client's side"; "nothing" needs to be checkable. | Renaming a file that was never handed to the client sends nothing at all. |
| **DAS 2** — Renaming a file that *was* handed to the client still sends the new name, so the guard does not silently break story 01. | **Solution-speak** — "the guard". The cross-reference is worth keeping but belongs in prose, not in the criterion. | Renaming a file that was handed to the client still sends the new name. |
| **DAS 3** — Whether a file counts as handed to the client is decided from the file's own record at the moment of the rename, not from anything the person renaming it has to remember to set. | **Wordiness**, and "the file's own record" is design-adjacent. The real point is that it is not the renamer's job to get it right. | Whether a file counts as handed to the client is worked out at the moment of the rename, not left to the person doing the renaming to get right. |
| **DAS 4** — A file that becomes a client file after being renamed does not retroactively push its earlier internal names to the client. | **Wordiness**; "retroactively push" is jargon. | If a file only becomes a client file later, the names it had beforehand are never sent. |
| **DAS 5** — We can tell afterwards, for any rename, whether anything was sent and why. | **Vague phrasing** — "and why" is unfalsifiable as written. | For any rename, we can check afterwards whether anything was sent, and which of the two outcomes was correct for that file. |

## User Story

An ops user doesn't want the names they give to their own working files reaching the client. While sorting out a proceeding's files, they want to name their own working copies whatever makes sense to them. Except that renaming any file on the proceeding would send that name to the client, so they want only the files actually handed to the client to send theirs. Now they'll be able to rename their own working files without any of those names reaching the client.

## Acceptance Criteria

1. Renaming a file that was never handed to the client sends nothing at all.
2. Renaming a file that was handed to the client still sends the new name.
3. Whether a file counts as handed to the client is worked out at the moment of the rename, not left to the person doing the renaming to get right.
4. If a file only becomes a client file later, the names it had beforehand are never sent.
5. For any rename, we can check afterwards whether anything was sent, and which of the two outcomes was correct for that file.

**Criterion 2 is deliberately the inverse of criterion 1, and it is not a duplicate of story 01.** Story 01 asks whether the client ends up seeing the current name; this asks whether the boundary condition was drawn in the right place. A change that suppressed *every* rename would satisfy criterion 1 completely and fail criterion 2 — which is exactly the regression this criterion exists to catch.

---

## Open Questions

Carried, not decided. Each names who or what can answer it.

**One carried forward, deliberately** — it is not Callisto's to answer, and holding the story in `draft` on Dione's behalf would block the spec on another team's epic.

| # | Question | Why it is open | Who / what answers it |
| --- | --- | --- | --- |
| `02.Q2` | What actually happens on the client's side if a name arrives for a file the client was never given — is it ignored, or does it create something visible? | Decides whether criterion 1 prevents a **leak** or merely **noise**, which changes how serious concern C1 is. **Structural proof it cannot be answered here:** the consumer is not in this workspace, and the RabbitMQ descope removed the observation step that would have shown it. | **Dione team** |

### Closed at Phase 3

| # | Closed how |
| --- | --- |
| `02.Q1` | **The ops user** — LD-015, grilled and confirmed. The story keeps its Motivation row and its user type stays distinct from story 01's client, which is part of why the split is real rather than cosmetic. No re-run needed. |
| `02.Q6` | **The rename does not succeed — fail closed** — LD-010. Resolved in two steps: `P3.reconcile` first established by evidence that the house precedent is unambiguously fail-closed (the shipped producer has **no try/catch**; **zero catch blocks** in either outbox infrastructure tree), which narrowed the question from "what should happen?" to "do you want to deviate?" — then grilled in that form and confirmed. Criterion 3 is unaffected: whether the deliverable determination is *made* at rename time is independent of what happens when the read fails. Cost recorded as concern **C8**: an outbox failure now also blocks renaming. |
| `02.Q6` | If the tag check fails or the tag data cannot be read, does the rename **still succeed** for the ops user? | The request says nothing about degradation. An ops user losing the ability to rename because a client-facing concern could not be evaluated would be a worse outcome than the leak. **Phase 1 sharpened this:** the tag read now sits inside a transaction with the rename, so a failed read fails the whole request — meaning the answer today is "no, the rename does not succeed." Whether that is the wanted behaviour is still a decision. | Phase 3 (decision) |

### Closed at Phase 1

| # | Closed how |
| --- | --- |
| `02.Q3` | **Yes — the tag is the sole condition, and it is already enforced.** `ProceedingFileMustBeDeliverableValidator:22` throws `ForbiddenException('Only client deliverable files can be renamed via this endpoint')` on `!isDeliverable`, and it runs *first* in the rename service. There is no additional approved/shared/withdrawn condition layered on it. The symmetric `ProceedingFileMustBeSubmissionValidator` guards the other endpoint by rejecting when `isDeliverable` is true — airtight even for dual-tagged files. The split was deliberate: commit `4d284978`, PRDV-15776. |
| `02.Q4` | **The tag is not on the entity, and no extra read is needed anyway.** There is no inverse relation for tags on either `File` or `FileAttachment`, so `relations: ['fileAttachment']` can never load them — every tag check is a separate query (`ProceedingFileRepository.checkFileAttachmentHasTag`). But `fetchProceedingFileForRename` already computes `isDeliverable` into its projection, and **that query already runs twice per request** (once in the validator, which discards the result, once inside the transaction script). So criterion 3 is satisfiable by using a value already in hand. The sibling's LD-011 problem does not repeat here. |
| `02.Q5` | **Yes, removable — but asymmetrically, and it makes criterion 4 the right shape.** The tag is added on approve (`approve-deliverable-files.transaction.script.ts:157-161`) and removed on unapprove (`unapprove-deliverable-files.transaction.script.ts:119-131`, `remove-deliverable-tag.transaction.script.ts:104-107`), both requiring a co-existing `Submission File` tag. So an upload-born deliverable can never lose the tag, while an approved-then-unapproved submission file can flip both ways. Consequence: deliverable status **must be read at rename time, never cached** — which the design does. What the client sees after a tag *removal* is the sibling ticket PRDV-16315's (`file.unapproved.v1`) concern, not this one's. |

---

## Story log

Newest first. One entry per phase in which the story moved.

### 2026-08-11 (Phase 3) — ACCEPTED. Two questions closed; no criterion changed

**Status `draft` → `accepted`,** with `02.Q2` carried forward to the Dione team. Revised in place; the story was still `draft`.

**Closed:** `02.Q1` (the user is the **ops user** — LD-015), `02.Q6` (fail closed — LD-010).

**No criterion changed, and that is the notable thing about this entry.** Story 01 needed all six of its criteria revised; this story needed none. The reason is worth recording: story 02's criteria were written about **what Callisto does at the boundary**, which is entirely inside this ticket's observable range, whereas story 01's were written about **what a client sees**, which is not. The same drafting discipline produced one story that survived contact with the scope and one that did not.

**Criterion 3 was checked against LD-010 specifically and left alone.** It says the deliverable determination is *"worked out at the moment of the rename, not left to the person doing the renaming to get right."* Fail-closed changes what happens when that determination cannot be made; it does not change whether the determination is made at rename time. Different claim, so no rewrite.

**Criterion 2 is now load-bearing in a way it was not at drafting.** LD-004 established that the deliverable guard already exists, so criterion 1 holds structurally before any code is written — which means criterion 2 (a deliverable rename *still* sends) is the only one of the five that can actually fail on the emission path. It is the regression guard against the cheapest wrong implementation: suppress everything, pass criterion 1 vacuously. Test plan NP-2 exists for exactly this.

**Cost accepted, recorded rather than absorbed:** fail-closed means an outbox failure now also blocks renaming — a client-facing concern denying an ops user a valid action. Concern **C8**.

### 2026-08-11 (Phase 1) — three questions closed; the story's premise partly overturned and partly vindicated

**Closed:** `02.Q3`, `02.Q4`, `02.Q5` — all against code evidence. Details above.

**The story's stated obstacle turned out to be already solved at this endpoint, and that is worth being precise about rather than quietly dropping.** The story was drafted from the request's third criterion, which justifies its guard with *"the rename endpoint may serve non-deliverable files as well."* It does not — `ProceedingFileMustBeDeliverableValidator` has 403'd non-deliverables since PRDV-15776. So at the deliverable endpoint, criterion 1 ("renaming a file that was never handed to the client sends nothing at all") holds *structurally*, before any code is written.

**That does not make the story redundant, for two reasons.** First, criterion 2 (the inverse — a deliverable rename still sends) is the one that catches the cheap wrong fix of suppressing everything, and it is unaffected. Second, `01.Q9` found the boundary genuinely *is* violable — just not where the request said. The AJSF route reaches the shared rename path with no deliverable validator at all. The story's underlying worry was real; the request pointed it at the wrong endpoint.

**No criterion changed.** Criterion 3 ("worked out at the moment of the rename, not left to the person doing the renaming") is now known to be satisfied by existing code plus the mutability finding in `02.Q5`, and it stays as written because it remains the thing that must be true.

**`02.Q6` sharpened rather than closed.** Putting the outbox write in a transaction with the rename means a failed tag read now fails the rename. That is a real behavioural answer, but whether it is the *wanted* answer is a decision — an ops user blocked from renaming because a client-facing concern could not be evaluated may be worse than the leak. Carried to Phase 3.

**User ruling recorded, and it bounds this story's real-world risk:** *"Once it is declared a client deliverable, there would be no reason for a user to ever change the name."* That is why the AJSF exposure is a recorded caution (C1) rather than in-scope work — the workflow is not expected to produce it.

### 2026-08-11 (Phase 0) — drafted

Split out from the request's third acceptance criterion rather than folded into story 01. The request states one motivation — keeping the client's displayed filename in sync — so the split is a judgement, and it is recorded as one: the two outcomes fail independently (a correct sync with a leak; a leak-free change that suppresses everything), and a single story could be reported green while one half was broken.

The user type is **the ops user**, which is a different user type from story 01's client. That is additional support for the split being real rather than cosmetic, and it is also the story's biggest risk — `02.Q1` carries it.

The Obstacle row was stripped of six design terms, and the Resolution row's *"feel safe"* was replaced with an observable outcome. DAS 2 lost its cross-reference to story 01 ("so the guard does not silently break story 01") from the criterion itself; the reasoning was kept in prose beneath the criteria, where it does not weaken the criterion's own falsifiability.

Six open questions carried. `02.Q2` is not answerable inside Callisto at all and is flagged as consumer-side from the start.
