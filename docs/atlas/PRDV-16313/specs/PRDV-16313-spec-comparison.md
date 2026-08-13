# PRDV-16313 — Spec comparison: was the authored spec fully considered?

> **What this is:** a section-by-section assessment of Larry Adams' wiki spec against [this ticket's spec](./PRDV-16313-spec.md) and the code evidence behind it, written *after* both existed so the comparison is real rather than anticipated.
> **What it answers:** was the authored spec fully thought out, and is there any reason to go against it?
> **Sources:** `larry-adams/.../epic-PRDV-15736-.../PRDV-16313-endpoint-file-renamed.md` (93 lines, created 2026-07-16, modified 2026-07-20, author Larry Adams) and `dione-file-access-event-design.md`. Code read at `callisto-back-end` branch `PRDV-16312`, 2026-08-11.

> ## Revision 2 — 2026-08-11, after review by Dustin Thomason
>
> **Revision 1 of this document was withheld from submission and corrected. Six findings were raised against it; all six were upheld.** Two were factual errors in the analysis, not matters of framing:
>
> 1. **`proceedingId` was wrongly reported as unavailable at Larry's named site.** It is available — `RenameProceedingFileTS` reads it from `fetchProceedingFileForRename` before returning (coverage ledger area 2). It needs plumbing only because **our** design moves emission out of that script. Revision 1 filed a consequence of our own design choice as a defect in the spec. **Corrected in finding 3.**
> 2. **The chronology was self-contradictory.** Revision 1's own text noted that commit `4d284978` *predates* the spec, then its weighting table described the code as having moved "underneath a maintained document." Both cannot be true. **Corrected throughout: this is an unchecked assumption at authoring time, not a post-authoring restructure.**
> 3. **"The named site does not exist" was imprecise.** A rename transaction script *does* exist behind that endpoint. What does not exist is a **dedicated deliverable-file** rename boundary. **Reworded.**
> 4. **The tag-guard question was framed too narrowly.** Re-checking the *same returned value* would be dead code; a **fresh in-transaction check** answers a different question — whether deliverability still holds when the event commits. The validator sits *outside* the new transaction and the tag is mutable both ways, so this is a live timing question, not a dead branch. **Reframed in finding 2; it is now one of two questions for Larry.**
> 5. **"All four ACs are met literally" was false.** AC1 says a successful `PATCH` writes a row; a successful **no-op** `PATCH` writes nothing. **Corrected — this is now the other question for Larry.**
> 6. **Two claims overreached.** A non-transactional outbox failure is not "silent" (the error propagates; the caller gets a 500 — the real defect is that the filename commits while the response reports failure and no event exists). And the deterministic-id behaviour is **not "closed"** — it is source-inspected and unobserved, with EC-5 blocked. **Both softened.**
>
> A seventh finding was raised against the **test plan**, not this document: NP-3 cannot prove database rollback from a suite with mocked aggregator and outbox. Addressed in the test plan, not here.

## Bottom line

**No reason to go against *what* the spec asks for. The implementation must be placed at a different boundary, atomicity must be added, and two behavioural details need Larry's confirmation.**

The spec is **right about every externally-visible commitment** — routekey, payload shape, consumer semantics, the deliverable-only requirement, prerequisites, and the substance of all four acceptance criteria. Those are the parts other teams depend on and the parts most likely to drift, and they are correct to the field. Build them exactly.

Its **Technical Design** assumes a code structure that the repository does not have. The causes are not uniform, and separating them matters more than counting them:

| Cause | Findings | Fair to call it a miss? |
| --- | --- | --- |
| **Unchecked assumption** — the code shape was verifiable at authoring time and was not verified | 1, 2, 4 | **Yes** — but it is an authoring-time gap, not neglect of a maintained document |
| **Genuine omission, reasonably foreseeable** | 5 (atomicity), 6 (no-op) | **Yes** — atomicity is established by the epic's own shipped sibling; the no-op branch is nine lines into the method the spec names |
| **Genuine omission, not reasonably foreseeable** | 7 (deterministic id) | **No** — unreachable before this ticket, and left open by two prior investigations |
| **Internal inconsistency between the author's own documents** | 8 | Minor, but the same drift class the sibling ticket hit |
| **Inherited from the design audit's scope** | 9 | Not this spec's error; it is the epic's to fix |

**Two questions require Larry's decision** (revision 1 asked only one, and it was the wrong one):

1. **Does a successful no-op rename emit?** We recommend no. But AC1 as written says yes, so this cannot be resolved by the investigation alone.
2. **Must deliverability hold at request-entry validation, or inside the rename/outbox transaction?** The tag is mutable both ways and the validator currently sits outside the transaction, so these are materially different guarantees.

Everything else is either **forced** by constraints outside the spec's visibility, **additive** correctness, or a **recorded risk / follow-up** the team may knowingly accept.

---

## What the spec got right, and it is the majority

Worth stating first and in detail, because a defect list read alone would misrepresent the document.

| Element | Assessment | Evidence |
| --- | --- | --- |
| **The payload type** | **Correct, field for field.** The spec's inline `CallistoClientAccessFileRenamedV1Data` — `fileId`, `proceedingId`, `fileName`, `renamedUserIdentity`, `renamedAt` — matches shipped `@planetdepos/orbital-docking-protocol@1.0.7` **exactly**. This is the single most drift-prone thing in the document and it is right. | ODP `dist/callisto/client-access/file/renamed/v1/callisto-client-access-file-renamed.v1.d.ts:36-42` vs wiki spec `:44-52` |
| **The routekey** | Correct, and already allow-listed. No registry work needed. | `client-access-outbox-event.registry.ts` — all seven contracts pre-registered by PRDV-16293 |
| **The four acceptance criteria** | **Correct, and met literally** by the implementation. Also **identical to the ClickUp text** — unlike the sibling PRDV-16312, where the two conflicted and the ClickUp version was stale. Nothing to reconcile. | wiki `:29-32` vs the captured ClickUp text |
| **The semantics line** | Correct and genuinely useful: *"File display name changed — Dione should update the filename on its file metadata row."* Tells the consumer exactly what to do, which is more than a routekey does. | wiki `:42` |
| **The prerequisite** | Correct. PRDV-16293 merged, PR #399 `43ad3dea`. | verified as an ancestor of the working branch |
| **The guard as a requirement** | **Right instinct.** A rename emission genuinely must be deliverable-gated. The justification and the layer are wrong (below), but the requirement is not. | — |
| **`renamedAt` = current ISO timestamp** | Correct, and correctly *not* over-specified as the row's `updated_at`. Our implementation does exactly this. | LD-012 |
| **The `if not already loaded` hedge on tags** | **The right thing to flag**, and the answer turned out more interesting than the hedge implies: tags are *structurally unloadable* on the entity (no inverse relation on `File` or `FileAttachment`), yet the flag is already computed **twice** per request. So no new read is needed — for a reason the spec did not have. | wiki `:79`; `file-attachment.entity.ts:32-85`; `proceeding-file.repository.ts:170-197` |
| **The three testing bullets** | The right three, and the manual one is **post-descope current**: *"confirm an outbox row is written with the expected routekey + payload"* rather than a dev-queue observation. Somebody maintained this after the RabbitMQ descope. | wiki `:83-87`; descope commit `318bd0a` |

**That last row deserves emphasis.** The RabbitMQ descope rewrote the manual verification step across nine sibling specs, and this one reflects it. The document has been maintained, not written once and abandoned — which makes the staleness below more specifically about the *code* moving than about neglect.

---

## Where it breaks, with the cause named

### 1. The rename transaction script is shared, not dedicated — **UNCHECKED ASSUMPTION**

> *"The transaction script behind `PATCH /file/:fileId` — after the file entity is updated with the new name."* · *"Trigger: `RenameDeliverableFileAction` / its transaction script."*

**A rename transaction script does exist behind that endpoint.** What does not exist is a *dedicated deliverable-file* one. The chain is action → `DeliverableRenameService` → `ProceedingAggregator` → `RenameProceedingFileTS`, and that last class lives in the **`proceedings`** module and is **shared by the deliverable, submission and AJSF rename paths**. The spec's phrase "its transaction script" implies a boundary owned by this workflow; the real one is owned by three.

**Cause: an unchecked assumption at authoring time — *not* a post-authoring code change.** Commit `4d284978` (*"PRDV-15776: Split proceeding file rename by deliverable vs submission"*) **predates the spec**. So the split had already happened and the Technical Design does not reflect it. The fair description is that the spec appears to have been written from an older understanding of the rename path, and the current structure was not verified during authoring. It should not be excused as a later restructure — and equally, it does not touch the parts of the spec that are correct.

**Reason to depart: yes, and it is forced.** Emitting from the shared script would make unrelated rename paths emit client-facing events, and it creates a module dependency problem (`granting-client-access` already imports `ProceedingsModule`; there is no reciprocal import). **And the natural adaptation — a new `RenameDeliverableFileTS` in the right module that delegates to the aggregator — is forbidden by `transaction-scripts-no-aggregators` at `severity: 'error'`.** That constraint is not discoverable from the spec or the design doc; only from `fitness-functions-rules/`.

**The requested event is unchanged. Only the implementation location changes.**

### 2. The deliverable check: the guard's justification is false, and its *timing* is an open question — **UNCHECKED ASSUMPTION + a live decision**

> *"The rename endpoint may serve non-deliverable files as well. Before emitting, check that the file has the `CLIENT_DELIVERABLE` file tag. If it doesn't, skip emission."*

The endpoint cannot serve non-deliverable files. `ProceedingFileMustBeDeliverableValidator` throws `ForbiddenException('Only client deliverable files can be renamed via this endpoint')` and runs **first** — introduced by the same pre-dating commit `4d284978`, with a symmetric validator guarding the submission endpoint. So the *requirement* survives; its stated *reasoning* does not.

**But the interesting question is not whether to repeat the check — it is when deliverability must be true.** Two facts make this live rather than academic:

- **The validator runs *outside* the new transaction.** It is the HTTP 403 gate, ahead of the rename/outbox boundary.
- **The `CLIENT_DELIVERABLE` tag is mutable in both directions** — added on approve (`approve-deliverable-files.transaction.script.ts:157-161`), removed on unapprove (`unapprove-deliverable-files.transaction.script.ts:119-131`, `remove-deliverable-tag.transaction.script.ts:104-107`).

So there is a window between the validation read and the transaction that renames the file and writes the event.

**Re-reading the same returned `isDeliverable` value would be dead code — that much is true.** But a **fresh check inside the transaction** is a different thing entirely: it establishes deliverability *at the moment the event commits*. Revision 1 conflated the two and consequently asked the wrong question.

**The question for Larry is therefore:** does AC3 mean the file must be deliverable **when the request is validated**, or **still deliverable inside the rename/outbox transaction**? If the stronger reading is required, a fresh in-transaction check with appropriate locking is needed. If request-entry validation is sufficient, the timing window must be documented as an accepted risk — and it must **not** be claimed that the current design proves the stronger invariant.

**Our default while awaiting the answer:** retain the existing endpoint validator (lower blast radius) and disclose the concurrency window.

### 3. The authenticated user is unavailable at the assumed site — **UNCHECKED ASSUMPTION**

> *"`renamedUserIdentity` from authenticated user context"* · *"3. `renamedUserIdentity` from authenticated user context"*

The deliverable **endpoint and service** have the authenticated user (`@VerifiedUserDecorator() user: AuthUser`). The **shared rename transaction script does not** — its signature is `apply(fileId: number, newValue: string)`. So "from authenticated user context" is unsatisfiable at the layer the spec names, and it cannot be made satisfiable there without changing that script's API and deciding what the *other* callers supply — including the AJSF caller, which has **no authenticated user at all**.

Two further details unstated: `AuthUser.identity` is **optional** (`identity?`) while the contract field is non-nullable, so the obvious `user.identity.userId` can put `undefined` into a required field.

**Resolution:** resolve `renamedUserIdentity` in the deliverable service as `user.identity?.userId ?? user.sub` (LD-013), matching the two most recent same-module siblings, and pass it into the deliverable-specific assembler.

> **Correction to revision 1 — this matters for fairness to the spec.** Revision 1 claimed the specified payload *could not be built* at the specified site because `proceedingId` was missing from the returned projection. **That was wrong.** `RenameProceedingFileTS` reads `proceedingId` from `fetchProceedingFileForRename` and has it in scope (coverage ledger area 2); it is simply not *returned*. So at the transaction-script site both `fileId` and `proceedingId` are available.
>
> **`proceedingId` needs plumbing only because our design deliberately emits outside that shared script.** That is a consequence of our own boundary choice, not a defect in Larry's. It is still worth telling him about — the validator now returns the context it already loads and discards (LD-009), which is a **deviation from repo convention** (all ~17 validators return `void`), with the fallback named: widen the shared projection instead, at the cost of touching `proceedings` and widening the AJSF response body. But it belongs in the addendum as an **implementation consequence**, not as a criticism.
>
> **The genuinely missing value at the shared site is authenticated-user identity.** That one stands.

### 5. Silent on atomicity — **GENUINE OMISSION, foreseeable**

The spec says *"after successful file rename… write outbox row"* and never says whether the two are atomic. **The rename path has no transaction at all** — `RenameProceedingFileTS` is not `@Transactional()` and has no provider, so the `UPDATE` autocommits.

Follow the spec literally and the failure mode is: **the rename commits, the outbox write throws, the caller receives a 500 — and the filename has already changed with no event to tell Dione.** Design Q5 (Larry's own document) forbids the projection-driven reconciler that would repair it.

> **Correction to revision 1:** this was described as "silent," which is wrong. **The error propagates and the caller gets a 500.** The accurate defect is the *inconsistency*: the request reports failure after the filename has already committed, and no event exists. That is worse than silent in one respect — the caller may retry a rename that already succeeded — and better in another, since something is observable.

**Cause: genuine omission, and reasonably foreseeable** — because the epic's own shipped sibling establishes atomicity as the pattern. `file.created.v1` is written inside the file-insert transaction under `@Transactional()`. The property existed; it was simply never written down as a requirement, so a spec reader would not know to preserve it on a path that lacks it.

**Reason to go against it: nothing to go against — this is an addition, and the most important one in the ticket.**

### 6. The no-op branch — **GENUINE OMISSION, foreseeable, and it makes AC1 ambiguous**

> AC1: *"When `PATCH /file/:fileId` succeeds for a client deliverable file, an outbox row is written…"* · Design: *"After successful file rename: … write `file.renamed.v1` outbox row"*

"Succeeds" is doing unexamined work. `RenameProceedingFileTS.apply:39-46` returns early when the recomputed name equals the current one and **issues no `UPDATE`** — a **successful request that wrote nothing to the database.**

So the two readings genuinely conflict:

- **AC1 literally:** the request succeeded, therefore a row is written.
- **Our implementation:** no rename occurred, therefore nothing is written — emitting would assert a database write that never happened.

> **Correction to revision 1, and it is the one that most needed making.** Revision 1 asserted that **"all four acceptance criteria are correct and are met literally."** That is **false**, and this is why: a successful no-op `PATCH` writes no row, so AC1 as written is not satisfied by the recommended behaviour. Revision 1 treated the no-op skip purely as a correctness improvement and never noticed it put us outside AC1's literal text.

**We still recommend not emitting.** But that is a **behaviour decision the investigation cannot make on its own**, so it becomes the second question for Larry, with suggested wording:

> *"When `PATCH /file/:fileId` succeeds **and changes the persisted filename** of a client-deliverable file, an outbox row is written."*

**Cause: genuine omission, foreseeable** — the branch is nine lines into the method the spec points at. **Default while awaiting the answer:** no emission on a no-op, recorded as an assumption that may need reworking if Larry wants every successful `PATCH` represented.

### 7. Silent on the deterministic event id — **GENUINE OMISSION, not reasonably foreseeable**

The outbox PK is uuidv5 over `runnerName|aggregateType|aggregateId|rowUpdatedAt|eventType`. `OutboxEvent.id` is a **non-generated** uuid PK and `OutboxEventRepository.create` ends in `repo.save()` — so a duplicate id is a **silent UPDATE**: data overwritten, `status` reset to `PENDING`, `attempts` reset to `0`, **no exception and no log**.

`file.created.v1` never exercised this because a file is created once. **Rename is the epic's first repeatable event on aggregate `File`**, so this ticket is where the hazard first becomes reachable.

**Cause: genuine omission, but not fairly a miss.** The behaviour lives inside a third-party package's compiled output, it had never been reachable before, and two prior investigations (PRDV-16402, PRDV-16312) both flagged it as open and left it open.

> **Correction to revision 1:** it said we "closed it here." **We did not.** This is **source-inspected and unobserved** — assumption A3 is explicitly `confirmed directionally`, and test-plan EC-5 is **blocked** because a sub-millisecond interleaving is not practically reproducible. Present it as an **evidence-backed hypothesis and a recorded residual**, not a closed question, until the planned real-Postgres demonstration runs.

**What we propose:** record it as an explicit residual, run the Postgres demonstration, and **do not change the shared deterministic-id mechanism in this ticket** unless the observed behaviour or a reviewer decision requires it — that mechanism is shared with the already-shipped `file.created.v1` and the `proceedings-command` runner.

**The team may reasonably accept this risk** for this ticket: the payload is a current-state snapshot, so the surviving row carries the latest filename, and the collision window is one millisecond per file. **Stated without calling the behaviour harmless or guaranteed** — what is lost is the fact that two renames occurred, and the snapshot reasoning breaks if a future `v2` adds a delta field such as `previousFileName`.

### 8. His own two documents disagree on the payload — **INTERNAL INCONSISTENCY**

The spec's payload has a single `fileName`. The design doc's Diagram ④ (`:740-747`) sketches `previousFileName` + `newFileName`. The spec and shipped ODP win; the diagram is stale.

Low impact — but worth reporting, because it is the same *class* of defect the sibling ticket hit hard: PRDV-16312 found two Status-checklist lines in this design doc contradicting their own resolved question bodies. **The design doc's diagrams and checklists drift from its resolved decisions.** A reader trusting a diagram over a resolved question will implement the wrong thing.

### 9. The coverage claim is incomplete — **INHERITED FROM THE DESIGN'S AUDIT SCOPE**

The design doc's audit maps *"Rename deliverable file — `PATCH /file/:fileId` — Covered by `file.renamed`"*. But **four** routes can rename a proceeding file, three sharing one transaction script, and one of those — `PATCH /<ajsf>/file/:fileId` — renames a client deliverable with **no user, no deliverable validator, and no audit dispatch**.

**Cause: the audit's own scope.** It is titled *"full audit of `granting-client-access` write operations"* and that is literally what it examined. `proceeding-job-submission` was never in frame.

**This is the finding with the longest reach, and it is not really about this ticket.** Five sibling events remain unbuilt and will each be specced from the same audit. A missed *delete* or *unapprove* surface means a client keeps seeing a withdrawn file — a disclosure problem, not a cosmetic one. Recorded as concern C5.

---

## Verdict on the question asked

**Was the spec fully thought out?**

**At the contract level, yes — and better than the sibling's.** Payload correct to the field, routekey correct, consumer semantics useful, the deliverable-only requirement correct, prerequisites right, testing direction right and maintained through the RabbitMQ descope. Those are the commitments other teams build against, and they needed no correction.

**At the implementation level, no.** Its Technical Design assumes a dedicated deliverable rename boundary that does not exist (finding 1), assumes an authenticated user at a layer that has none (finding 3), assumes the endpoint serves non-deliverables when it has not since before the spec was written (finding 2), and is silent on the three properties that determine whether the change is *correct* rather than merely *present* (findings 5–7). The first three were all verifiable at authoring time.

**Is there reason to go against it? Precisely:**

| | Verdict |
| --- | --- |
| Payload, routekey, consumer semantics, prerequisites | **Build exactly. No change.** |
| The deliverable-only requirement | **Keep.** Only its stated justification and its *timing* are in question |
| AC2, AC3, AC4 | **Met.** No change needed |
| **AC1** | **Met for a real rename; NOT met literally for a successful no-op.** Needs amended wording — **question 1 for Larry** |
| Testing direction | Build exactly, **plus** the cases the spec does not ask for (no-op, ordering, real rollback proof, neighbour proof) |
| Where to emit | **Depart — forced.** The script is shared across three routes, has no authenticated user, and the natural adaptation is blocked by a `severity: 'error'` rule |
| **Timing of the deliverable check** | **Open — question 2 for Larry.** Request-entry validation, or a fresh check inside the rename/outbox transaction? |
| `proceedingId` plumbing | **An implementation consequence of our boundary choice, not a spec defect.** Disclose the validator-return convention drift |
| Atomicity | **Add.** Additive correctness the spec did not state; without it the requested behaviour is unreliable |
| No-op behaviour | **Add**, pending question 1 |
| Deterministic id | **Record as a residual + demonstrate.** Not closed |
| AJSF surface, stale diagram, epic audit scope | **Record as follow-ups.** Not reasons to reject the ticket |

**The honest summary for the addendum:** the spec's *what* is sound and needs no defending. Its *how* was written from an older understanding of the rename path, and the current structure was not verified during authoring. Most departures are forced by constraints outside the spec's visibility; **two behavioural details genuinely belong to its author.**

## What this changes about the submission

Revision 1's content was mostly right but its **weighting and two of its facts were not**. For the addendum:

1. **Lead with what was right**, in detail. A defect list opening cold misrepresents a document that got the whole contract correct.
2. **Do not claim "the code moved underneath a maintained document."** The restructuring commit predates the spec. Say the spec was written from an older understanding and the current structure was not verified — neither excusing it as a later change nor using it to dismiss the correct parts.
3. **Do not present `proceedingId` as a spec defect.** It is available at the spec's own named site; it needs plumbing because *our* design emits elsewhere. The genuinely absent value there is authenticated-user identity.
4. **Ask two questions, not one:** no-op semantics / AC1 wording, and the required timing strength of the deliverable check. Revision 1 asked one, and it was the wrong one — "do you want a dead branch?" instead of "when must deliverability be true?"
5. **Press finding 5 (atomicity)** as the most important additive item, and be precise that a non-transactional failure is an *inconsistency reported as a failure*, not a silent one.
6. **Do not overclaim finding 7.** Hypothesis and residual, not closed.
7. **Finding 9 (C5) goes to the epic owner**, not this ticket. It is the only item whose cost grows with every remaining sibling.
8. **Frame the rest as implementation constraints, recorded risks, or follow-ups the team may knowingly accept** — not as blockers. Only the no-op/AC1 conflict genuinely blocks a truthful claim of AC compliance.
