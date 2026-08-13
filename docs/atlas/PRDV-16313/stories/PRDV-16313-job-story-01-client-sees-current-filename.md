# Job story 01 — The client sees the name the file actually has now

| Field | Value |
| --- | --- |
| Ticket | PRDV-16313 |
| Project | atlas (implementation: `callisto-back-end`) |
| Drafted | 2026-08-11 (Phase 0) · Accepted 2026-08-11 (Phase 3) |
| Status | **`accepted`** |
| Source | [PRDV-16313-original-ticket.md](../PRDV-16313-original-ticket.md) — verbatim request only |
| User type | Client (Planet Portal) — **see `01.Q1`** |

Built from the verbatim request alone. No investigation existed when this was written; nothing here was resolved by inference.

---

## Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | A client doesn't want to be looking at a filename that no longer matches what the file is actually called. |
| Context + Intent | *While [context], they want to [action].* | While going through the documents shared with them on a proceeding, they want to grab the right one by its name. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that Planet Portal's file list keeps displaying whatever filename came through on the original upload event, so they want the portal to consume a rename event and refresh that column. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to feel confident the names they see are current. |

## Revision Matrix

The story must be agnostic to system design. No design words — portal, list, column, event, consume, endpoint, payload, tag.

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| **Obstacle + Desired Action** (always revised) | Except that Planet Portal's file list keeps displaying whatever filename came through on the original upload event, so they want the portal to consume a rename event and refresh that column. | **Solution-speak** — "Planet Portal's file list", "column", "original upload event", "consume a rename event" all name system design. It also states *how* the fix works instead of what the client needs. | Except that the name they see is the one the file had when it was first shared with them, so they want the name to keep up when their deposition team changes it. |
| Resolution | Now they'll be able to feel confident the names they see are current. | **Emotional abstraction** — "feel confident" is not observable. | Now they'll be able to find a document by the name it currently has. |
| Motivation | A client doesn't want to be looking at a filename that no longer matches what the file is actually called. | **Vague phrasing** — "what the file is actually called" does not say according to whom. | A client doesn't want to be looking at a filename their deposition team has already changed. |
| Context + Intent | *(no design words — unchanged)* | — | While going through the documents shared with them on a proceeding, they want to grab the right one by its name. |

## Delivery Acceptance Statement (DAS)

> *We know this story is considered complete when:*
> - When someone on the deposition team changes the name of a file the client has been given, the client sees the new name rather than the old one.
> - The client never sees two different names for the same document at the same time.
> - A rename that fails part-way leaves the client seeing the name that is really on the file, not a name that was never saved.
> - Renaming a file the client already has does not make it look like a brand-new document, and does not make the one they had disappear.
> - The change reaches the client without anyone having to go do something by hand afterwards.
> - We can show, on demand, that a rename the client should have seen actually went out.

## Concatenated Story

A client doesn't want to be looking at a filename their deposition team has already changed. While going through the documents shared with them on a proceeding, they want to grab the right one by its name. Except that the name they see is the one the file had when it was first shared with them, so they want the name to keep up when their deposition team changes it. Now they'll be able to find a document by the name it currently has.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A client doesn't want to be looking at a filename their deposition team has already changed. | **Wordiness** — "to be looking at" is loose where "see" is exact. | A client doesn't want to see a filename their deposition team has already changed. |
| While going through the documents shared with them on a proceeding, they want to grab the right one by its name. | Everyday register already ("going through", "grab"); no issue. | While going through the documents shared with them on a proceeding, they want to grab the right one by its name. |
| Except that the name they see is the one the file had when it was first shared with them, so they want the name to keep up when their deposition team changes it. | **Wordiness** — two clauses saying "when it was first shared". Tighten without losing the staleness point. | Except that they only ever see the name the file had when it was first shared, so they want it to keep up when their deposition team changes it. |
| Now they'll be able to find a document by the name it currently has. | Observable; no issue. | Now they'll be able to find a document by the name it currently has. |
| **DAS 1** — When someone on the deposition team changes the name of a file the client has been given, the client sees the new name rather than the old one. | Observable and specific; no issue. | When someone on the deposition team changes the name of a file the client has been given, the client sees the new name rather than the old one. |
| **DAS 2** — The client never sees two different names for the same document at the same time. | **Non-observable outcome as written** — "at the same time" is untestable without saying where the two names would appear. | Wherever the client can see a document's name, they see one name for it, not the old and the new side by side. |
| **DAS 3** — A rename that fails part-way leaves the client seeing the name that is really on the file, not a name that was never saved. | **Wordiness**; "really on the file" is vague about the authority. | If a rename does not go through, the client keeps seeing the file's previous name — never a name that was never saved. |
| **DAS 4** — Renaming a file the client already has does not make it look like a brand-new document, and does not make the one they had disappear. | Two thoughts in one line, but they are one outcome (identity is preserved) and splitting them would let one pass while the other fails. Kept together, tightened. | A renamed file stays the same document to the client — it does not show up as a new one, and the one they had does not vanish. |
| **DAS 5** — The change reaches the client without anyone having to go do something by hand afterwards. | **Wordiness** — "go do something by hand" is loose. | No one has to do anything by hand for the new name to reach the client. |
| **DAS 6** — We can show, on demand, that a rename the client should have seen actually went out. | **Vague phrasing** — "went out" does not say what is checkable, and "on demand" is filler. | For any rename the client should have seen, we can check afterwards that it was in fact sent, and what name was sent. |

## User Story

A client doesn't want to see a filename their deposition team has already changed. While going through the documents shared with them on a proceeding, they want to grab the right one by its name. Except that they only ever see the name the file had when it was first shared, so they want it to keep up when their deposition team changes it. Now they'll be able to find a document by the name it currently has.

## Acceptance Criteria

**Revised at Phase 3 per LD-017.** The originals are preserved verbatim in the Final Review Matrix above and the reasons for each change are in the Story log below. Two decisions bounded the scope *before* any code existed — the epic owner's RabbitMQ descope, and the user's ruling on the AJSF route — and these criteria follow that bounding. They were **not** narrowed to fit an implementation.

1. When a deliverable file is renamed through the ops deliverables workflow, Callisto sends out a complete record naming that file, its proceeding, and the name it now has.
2. Only one record goes out per rename, so there is never an old name and a new name in flight for the same file at once.
3. If the rename does not go through, nothing is sent — the client is never told about a name that was never saved.
4. The record names the same file the client already had, so a rename is never mistaken for a new document.
5. No one has to do anything by hand for the record to go out.
6. For any rename, we can check afterwards whether a record went out and what name it carried.

**What these deliberately no longer claim.** Criteria 1–4 previously asserted what the client *sees*. Nothing in this repo can witness a client's view — RabbitMQ is descoped epic-wide and Dione's consumer is another team's codebase — so asserting it would have been unfalsifiable here. Criterion 1 also previously covered *any* rename by *anyone*, which is false via the AJSF route. Both gaps are recorded in the Story log, the index, and concerns C1 and C9 rather than quietly dropped.

---

## Open Questions

Carried, not decided. Each names who or what can answer it. **Five of the original nine closed at Phase 1 by code evidence** — see the Story log.

**One carried forward, deliberately.** Accepting a story with an open question is allowed when the question is not Callisto's to answer; the alternative — holding the story in `draft` on another team's behalf — would block the spec on Dione's epic.

| # | Question | Why it is open | Who / what answers it |
| --- | --- | --- | --- |
| `01.Q3` | What does the client see **today**, and what will they see once Dione consumes — does Dione re-read the name from any other source? | Half answered by evidence: no Callisto path emits anything on rename, so nothing on this side refreshes it. The rest is consumer-side. **Structural proof it cannot be answered here:** Dione's consumer is not in this workspace, and the RabbitMQ descope removed the observation step that would have shown it. | **Dione team** |

### Closed at Phase 3

| # | Closed how |
| --- | --- |
| `01.Q1` | **The client** (Planet Portal). Grilled and confirmed — LD-015. The Motivation row stands; no re-run needed. Consequence accepted: the criteria stay client-oriented, so the observability gap below had to be resolved by restating criteria rather than by changing who the user is. |
| `01.Q2` | **Nowhere — and that is now settled rather than pending.** No surface in this repo can witness a client's view. Resolved by LD-017: criteria 1–4 restated to what is falsifiable inside the ticket, following the sibling's LD-007 precedent after the same descope. Recorded as concern C9. |
| `01.Q7` | **Nothing states the latency** — LD-016. Seconds-scale needs no announcement, and a stated bound would create a target nobody measures. The question was originally mis-framed as a UX one; it was really "does criterion 5 need a time bound?" — answer: no. Residual recorded in C9. |

### Closed at Phase 1

| # | Closed how |
| --- | --- |
| `01.Q4` | The endpoint mutates **only** `files.file_name` and `files.updated_at` — `ProceedingFileRepository.updateFileName:133-138`, a single-row `repo.update`. The request body's extra `trackTypeId` is consumed by the auth guard and never enters the command. So criteria 2 and 4 are not understating anything. |
| `01.Q5` | `CallistoClientAccessFileRenamedV1Data` carries exactly five non-nullable fields: `fileId`, `proceedingId`, `fileName` (the new name), `renamedUserIdentity`, `renamedAt`. Sufficient for criterion 6 — the sent name is recoverable from the row. |
| `01.Q6` | Merged. PRDV-16293 landed in PR #399 (`43ad3dea`), verified as an ancestor of the working branch. Re-verified rather than inherited from the sibling. |
| `01.Q8` | **The code already decides this.** `RenameProceedingFileTS.apply:39-46` returns early when the recomputed name equals the current one and never issues an `UPDATE`. So a no-op rename is not a rename, and emitting would assert something that did not happen. Criterion 6 stays checkable: nothing was sent because nothing changed. |
| `01.Q9` | **No — there are four rename surfaces, and this matters to criterion 1.** Three funnel through one shared transaction script: the deliverable endpoint, the submission endpoint (`PATCH /proceedings/file/:fileId`), and the AJSF endpoint (`PATCH /<ajsf>/file/:fileId`); a fourth writes case files through a separate repository. Completeness established by enumerating both writers of `files.file_name` and confirming no bulk-rename endpoint exists. **The AJSF route can rename a client-deliverable file with no authenticated user, no deliverable validator and no audit event** — so criterion 1 is satisfied for the deliverable endpoint and *not* for that route. Recorded as concern C1; the user ruled it a latent workflow defect rather than this ticket's work. |

---

## Story log

Newest first. One entry per phase in which the story moved.

### 2026-08-11 (Phase 3) — ACCEPTED. Three questions closed; all six criteria revised

**Status `draft` → `accepted`,** with `01.Q3` carried forward to the Dione team. Revised in place rather than superseded, because the story was still `draft` when the changes landed.

**Closed:** `01.Q1` (the user is the **client** — LD-015, grilled), `01.Q2` (nowhere is observable here — LD-017), `01.Q7` (nothing states the latency — LD-016).

**All six criteria were revised, and this is the entry that has to justify it** — restating a criterion to match what can be proven is one letter away from reinterpreting it to match what was built, which the job-story rule names as a specific failure.

The distinction is **ordering**. Two decisions bounded the scope *before any code existed*:

1. **The epic owner descoped RabbitMQ** (upstream `318bd0a`), which removed the only path by which a client's view could have been observed from this ticket.
2. **The user ruled the AJSF rename route out of scope** (LD-014), on the workflow grounds that a submitted client deliverable has no legitimate reason to be renamed there.

So the criteria followed a scope that had already moved — they were not bent to fit a diff. Nothing has been implemented yet.

**What changed, criterion by criterion:**

- **1** — was *"…the client sees the new name rather than the old one"* for a rename by *anyone*. Now scoped to **the ops deliverables workflow**, and phrased as Callisto sending a complete record. Two reasons: the "anyone" claim is false via the AJSF route, and "the client sees" is unfalsifiable here.
- **2** — was *"they see one name for it, not the old and the new side by side"*. Now **one record per rename**, which is the same guarantee expressed where it can actually be checked.
- **3** — was *"the client keeps seeing the file's previous name"*. Now **nothing is sent** when the rename does not go through. Strengthened rather than weakened: this is exactly what LD-005's transaction and LD-011's no-op guard exist to deliver, and it is directly testable (test plan NP-3, EC-1).
- **4** — was *"does not show up as a new one, and the one they had does not vanish"*. Now the record **names the same file**, which is what makes the identity claim checkable (the payload carries `fileId`).
- **5** — unchanged in substance; "the new name" → "the record". **No time bound added**, per LD-016.
- **6** — near-unchanged; "any rename the client should have seen" → "any rename", since the qualifier depended on the coverage claim criterion 1 no longer makes.

**What the story now deliberately does not claim,** stated in the criteria themselves so no reader has to infer it: that the client sees anything. This ticket proves the **producer** correct and asserts nothing about the client's view. Recorded as concern **C9**, with a follow-up to walk the original criteria 1–4 against real client behaviour once Dione consumes.

**Not reinterpreted, and worth being explicit:** the AJSF gap was **not** absorbed by softening criterion 1 into vagueness. It is named in the criterion's scope, in the index, and in concern C1, and it remains a known shortfall against the ticket's stated purpose.

### 2026-08-11 (Phase 1) — five questions closed by evidence; one criterion put under pressure

**Closed:** `01.Q4`, `01.Q5`, `01.Q6`, `01.Q8`, `01.Q9` — all against code or repo evidence, none by decision or inference. Details in the table above.

**Sharpened rather than closed:** `01.Q2`. The RabbitMQ descope (epic-wide, upstream commit `318bd0a`) means nothing client-visible can be observed from inside Callisto. That does not answer the question, it narrows it to a Phase 3 decision.

**Criterion 1 is now known to be broader than what this ticket delivers.** It reads *"when someone on the deposition team changes the name of a file the client has been given, the client sees the new name rather than the old one."* Given `01.Q9`, that is true via the deliverable endpoint and false via the AJSF route. **No criterion is being reworded here to match what is being built** — the gap is recorded and carried to Phase 3, where the criterion gets rewritten to what is actually observable, or the story is superseded. The temptation to quietly narrow it to "renamed via the deliverable endpoint" is exactly what the job-story rule forbids.

**Criteria 1–4 face the same pressure from a different direction** (`01.Q2`): they are written as client-observable, and this ticket's boundary ends at an outbox row. The sibling ticket had to reword one criterion in each of its two stories for precisely this reason. Deferred to Phase 3 rather than pre-empted.

**No criterion changed. No question was answered by inference.** Four remain open, and two of them (`01.Q3`, `01.Q7`) are consumer-side or product — not Callisto's to settle.

### 2026-08-11 (Phase 0) — drafted

Written from the verbatim ClickUp request alone, before any investigation existed. The full matrix sequence was run: the Obstacle row was stripped of four design terms ("Planet Portal's file list", "column", "original upload event", "consume a rename event"), the Resolution row's *"feel confident"* was replaced with a findable outcome, and two DAS lines (2 and 6) were rewritten in the Final Review Matrix for being unobservable as first written.

The request's own four acceptance criteria were treated as **input, not output** — all four describe the mechanism (an outbox row, a payload type, a tag condition, unit tests). None of them says what a client experiences, so none was carried across verbatim. Criterion 6 is the closest descendant, reframed from *"unit tests prove the outbox write"* to what a person can check about a real rename.

Nine open questions carried. Six are code- or repo-discoverable and belong to Phase 1's evidence pass, not to the user. `01.Q1` is the dangerous one: if the user type resolves to the ops user, this story is re-run from Motivation.
