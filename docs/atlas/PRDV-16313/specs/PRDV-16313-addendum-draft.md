---
ticket: PRDV-16313
tags: [neptune, granting-client-access, outbox, file-renamed, implementation-addendum]
author: Dustin Thomason
created: 2026-08-11
status: DRAFT — not submitted. Awaiting explicit authorization before anything is pushed to larry-adams.
---

# PRDV-16313 — Implementation and risk addendum

> **This is an addendum, not a replacement specification.** [[PRDV-16313-endpoint-file-renamed]] remains the authoritative statement of what this ticket delivers. The routekey, the payload, the deliverable-only behaviour, the consumer semantics and the requirement to write an outbox event are all correct and unchanged.
>
> **What this document does:** explains where the current code does not match the code structure the original spec assumes, what could go wrong, and how we propose handling each item.
>
> **Two things need your confirmation** (§Questions). Everything else is either an implementation constraint, an additive correctness requirement, or a recorded risk the team may knowingly accept.
>
> **We intend to proceed on the recommended defaults while you review**, accepting possible rework. Every unresolved choice and accepted risk is recorded below and in the ticket's concerns file.

---

## What the spec got right

Worth stating plainly and first, because the rest of this document is about gaps and would misrepresent the spec if read alone.

| Element | Status |
| --- | --- |
| **Routekey** `callisto.client-access.file.renamed.v1` | Correct, and already allow-listed by PRDV-16293 — no registry work needed |
| **Payload** — `fileId`, `proceedingId`, `fileName`, `renamedUserIdentity`, `renamedAt` | **Correct field for field** against shipped `@planetdepos/orbital-docking-protocol@1.0.7`. This is the most drift-prone item in the document and it needed no correction |
| **Consumer semantics** — *"Dione should update the filename on its file metadata row"* | Correct and genuinely useful; tells the consumer what to do, which a routekey alone does not |
| **Deliverable-only requirement** | Correct. Only its stated justification and its timing are in question (§2) |
| **Acceptance criteria** | Correct in substance, and **identical to the ClickUp text** — unlike PRDV-16312, where the two conflicted. One needs a wording amendment (§Question 1) |
| **Prerequisite** — PRDV-16293 merged | Correct; verified at PR #399 / `43ad3dea` |
| **Testing direction** | The right three cases, and **maintained through the RabbitMQ descope** — the manual step already reads "confirm an outbox row is written" rather than a dev-queue check |

**The requested behaviour is unchanged by anything below.** What changes is where it is implemented, plus atomicity to make it reliable.

---

## Questions requiring your confirmation

### Question 1 — should a successful no-op rename emit?

**AC1 as written:** *"When `PATCH /file/:fileId` succeeds for a client deliverable file, an outbox row is written…"*

**What the code does:** if the requested name resolves to the filename the file already has, `RenameProceedingFileTS.apply:39-46` returns early and performs **no database update**. The request still returns success.

**The conflict:** read literally, AC1 says that successful request should emit. We think it should not — no rename occurred, so an event would assert a database write that never happened.

**We cannot claim AC1 is met literally without your clarification**, and we would rather say so than quietly redefine "succeeds."

**Suggested wording:**

> *"When `PATCH /file/:fileId` succeeds **and changes the persisted filename** of a client-deliverable file, an outbox row is written."*

**Our recommendation:** do not emit when the persisted filename did not change.
**Our default while you review:** no emission on a no-op, recorded as an assumption. If you want every successful `PATCH` represented, this is a small change — but it inverts a test expectation, so we would rather know.

### Question 2 — when must deliverability be true?

**Current implementation:** a validator checks the file is a client deliverable at request entry, **before** the rename starts. Our design keeps that validator **outside** the rename/outbox transaction.

**Why that may not be sufficient:** the `CLIENT_DELIVERABLE` tag is **mutable in both directions** — added on approve, removed on unapprove. So there is a window between the validation read and the transaction that renames the file and writes the event. An unapprove landing in that window would emit a client-access event for a file that is no longer a client deliverable.

**A distinction worth drawing, because we initially got it wrong ourselves:** re-reading the *same already-returned* `isDeliverable` value inside the transaction would be dead code. A **fresh read inside the transaction** is a different thing — it establishes deliverability at the moment the event commits. Only the second addresses the window.

**The question:** does AC3 mean the file must be deliverable **when the request is validated**, or **still deliverable inside the rename/outbox transaction**?

- If the stronger reading is required: a fresh in-transaction deliverability read with appropriate row locking, plus a decision about what to do when the answer flips mid-request (fail the rename, or rename without emitting).
- If request-entry validation is sufficient: we document the timing window as an accepted risk.

**Our default while you review:** retain the existing endpoint validator — the lower-blast-radius choice — and **disclose the window rather than claim the stronger invariant holds.**

---

## Implementation constraints — where the code does not match the assumed structure

### 1. The rename transaction script is shared

**What the spec expects:** write the event from the transaction script behind the deliverable-file rename endpoint.

**What the code does:** a rename transaction script *does* exist behind that endpoint — but it is **not dedicated to deliverable-file renames.** `RenameProceedingFileTS` lives in the **`proceedings`** module and is shared by the **deliverable, submission and AJSF** rename paths.

**Why that is a problem:** writing the client-access event directly into that shared script would make unrelated rename paths emit client-facing events, and it introduces a module dependency problem — `granting-client-access` already imports `ProceedingsModule`, and there is no reciprocal import.

**What we propose:** keep the requested behaviour exactly, and place the deliverable-specific orchestration in `granting-client-access`. A transaction-owning **assembler** calls the existing rename logic and writes the outbox row **only for the deliverable workflow**.

**Note on chronology, for the record:** commit `4d284978` (*"PRDV-15776: Split proceeding file rename by deliverable vs submission"*) **predates** this spec. So the split had already happened when the Technical Design was written. The fair reading is that the spec was written from an older understanding of the rename path and the current structure was not verified — not that the code moved afterwards. It does not affect the parts of the spec that are correct.

**One constraint that is not visible from the spec or the design doc:** the obvious adaptation — a new `RenameDeliverableFileTS` in the right module that delegates to `ProceedingAggregator` — is **forbidden by `transaction-scripts-no-aggregators` at `severity: 'error'`** in `fitness-functions-rules/architecture-rules/`. `services-no-converters` likewise prevents holding the payload converter in the service. An assembler is the only legal shape. We are not happy about the naming and have recorded it (concern C3) so nobody later "corrects" it into a transaction script and breaks the build.

**The requested event is unchanged. Only the implementation location changes.**

### 2. The authenticated user is not available in the shared script

**What the spec expects:** `renamedUserIdentity` from the authenticated user.

**What the code does:** the deliverable **endpoint and service** have it (`@VerifiedUserDecorator() user: AuthUser`). The shared rename transaction script does **not** — its signature is `apply(fileId, newValue)`.

**Why that is a problem:** the event cannot be completed inside the shared script without changing its API and deciding what the other callers supply — including the AJSF caller, which has **no authenticated user at all**.

**What we propose:** resolve it in the deliverable service as `user.identity?.userId ?? user.sub` (the fallback used by the two most recent siblings in this module — `AuthUser.identity` is optional while the contract field is not), and pass it into the deliverable-specific assembler.

**An implementation consequence, not a defect in your spec:** our payload also needs `proceedingId`, and because we emit *outside* the shared script, it has to be plumbed out. **`proceedingId` is available inside that script** — it reads it from `fetchProceedingFileForRename` — it is simply not returned. We get it by having the deliverable validator return the context it already loads and currently discards, which costs **no additional query**. That is a **deviation from repo convention** (all ~17 validators return `void`), so we are flagging it; the fallback is to widen the shared projection instead, at the cost of touching `proceedings` and widening what the AJSF endpoint returns.

### 3. Rename and outbox write must succeed or fail together — additive

**What the spec says:** write the outbox row after a successful rename.

**What the current path does:** the rename commits **without a surrounding transaction** — `RenameProceedingFileTS` is not `@Transactional()` and has no provider, so the single `UPDATE` autocommits.

**Why that is a problem:** if the outbox write is added afterwards and fails, **the filename has already committed while the request reports failure and no event exists.** Callisto and Dione diverge, and design Q5 forbids the projection-driven reconciler that would repair it. *(To be precise: this failure is not silent — the error propagates and the caller gets a 500. The problem is the inconsistency, and that a caller may retry a rename that already succeeded.)*

**What we propose:** run the rename and the outbox write in the **same database transaction**. If the rename fails, no event. If the outbox write fails, the rename rolls back. **Keep the existing audit SQS dispatch outside that transaction** — it is not rollbackable, it would hold a DB transaction across a network hop, and pulling it in would newly let an audit outage roll back a valid rename.

**Atomicity is an additive correctness constraint the original spec did not state.** It does not change the requested behaviour; it makes that behaviour reliable. It is the most important item in this document.

**And it needs a real test.** A unit test with mocked rename and outbox collaborators can prove call ordering and error propagation — **it cannot prove that a real file update and a real outbox insert share a transaction.** We are adding a real-Postgres integration test (and a manual fault-injection step) that forces the outbox insert to fail and asserts `files.file_name` is unchanged. Until that runs, **we will report atomicity as unproven rather than assumed.**

---

## Recorded risks and follow-ups — not reasons to reject the ticket

### 4. Deterministic event IDs can collide — residual, evidence-backed hypothesis

The outbox event id is derived from aggregate information plus a **millisecond** timestamp. Two genuine renames of the same file within the same millisecond may derive the same id, and source inspection indicates the second `save()` would **update the first row rather than insert another** — `OutboxEvent.id` is a non-generated uuid primary key.

**Effect:** two real renames could leave one outbox row. The surviving payload should carry the latest filename, but the fact that two events occurred would be lost.

**Evidence level — stated honestly:** this is **source inspection, not observation.** It has not been demonstrated against real Postgres, and the sub-millisecond interleaving is not practically reproducible in a test. We are running the Postgres demonstration; until then this is a hypothesis with evidence behind it, **not a closed finding.**

**What we propose:** record it as an explicit residual and **do not change the shared deterministic-id mechanism in this ticket** — it is shared with the already-shipped `file.created.v1` and the `proceedings-command` runner.

**Risk decision available to the team:** this may reasonably be accepted for this ticket, because the payload is a current-state snapshot (so the surviving row carries the correct final filename) and the window is one millisecond per file. Stating that reasoning without calling the behaviour harmless or guaranteed — and noting that the snapshot argument **stops holding** if a future `v2` adds a delta field such as `previousFileName`.

### 5. Another route can rename a client-deliverable file without emitting

`PATCH /<ajsf>/file/:fileId` reaches the shared rename logic with **no deliverable validator, no authenticated user, no audit dispatch** — and, after this ticket, no client-access event. A client-deliverable file renamed through it would leave Dione showing the previous filename with no trace on either side.

**What we propose for this ticket:** do not expand scope. The deliverable endpoint stays the only changed route, and this is recorded as a known coverage gap.

**Risk decision:** the current workflow is believed not to rename client-deliverable files through AJSF, and the team may accept that operational assumption. If accepted, a follow-up should exist rather than this ticket's blast radius growing. *(This is Dustin's ruling, recorded: once a file is declared a client deliverable there is no reason for a user to rename it.)*

### 6. Your two documents show different payloads

The event spec and the shipped ODP contract both have a single `fileName` (the new name). The design doc's Diagram ④ shows `previousFileName` **and** `newFileName`.

**Why it matters:** a future implementer following the diagram would produce a payload that does not match the shipped contract.

**What we propose:** follow the shipped contract and your event spec — one `fileName`, no `previousFileName` — and flag the diagram for later correction. (Related: the `## Wiki` path printed in the ClickUp ticket is also dead; `emit-grant-events/` was renamed to `epic-PRDV-15736-…`.)

### 7. The epic coverage audit was narrower than its conclusion suggests — for the epic owner

The design doc's audit is titled *"full audit of `granting-client-access` write operations"*, and that is what it examined. Related writes and rename surfaces also exist in **`proceedings`** and **`proceeding-job-submission`** — which is why the AJSF route above is absent from this spec.

**Why it matters beyond this ticket:** the rename gap may not be unique, and **five sibling events remain unbuilt** and will each be specced from the same audit. A missed **delete, unapprove or withdrawal** path is more serious than a missed rename — a client could keep seeing a file that should no longer be available.

**What we propose:** do not add those surfaces to PRDV-16313. **Re-run or extend the coverage audit across the other modules before the remaining sibling events are implemented.** This is the only item here whose cost grows with every remaining ticket.

---

## Summary

**Here is the behaviour you requested. We can deliver it.** The current code requires us to place it at a different boundary — the rename transaction script is shared across three routes and has no authenticated user — and to make the rename and the event atomic so the requested behaviour is reliable rather than merely present.

**Two details need your confirmation:** whether a successful no-op emits, and exactly when deliverability must be true.

**The remaining findings are known risks and coverage gaps** that can either be accepted for this ticket or handled as follow-up work. None of them is a reason to reject it.

## Cross-references

| Artifact | Contents |
| --- | --- |
| `PRDV-16313-investigation.md` | Full investigation report — verdict, problem class, surface enumeration, assumptions ledger |
| `PRDV-16313-spec.md` | Our implementation spec (subordinate to yours) |
| `PRDV-16313-locked-decisions.md` | All 19 decisions with sources; LD-018 and LD-019 are the two questions above |
| `PRDV-16313-spec-comparison.md` | The section-by-section assessment this addendum is drawn from, including its own correction log |
| `PRDV-16313-future-development-concerns.md` | Concerns C1–C10, each dated and code-verified |
| `testing/PRDV-16313-test-plan.md` | Test plan, including NP-3b — the real-Postgres atomicity proof |
