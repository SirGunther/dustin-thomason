# Testing implementation — atlas/PRDV-16313

> **Scenario-first.** Each real situation stress-tested, why it matters, whether it held, and any code change hung off the scenario that forced it. This is the staging ground for the PR comment — it is **never** copied into the source as a code comment.
>
> Status 2026-08-11: automated suites green; **atomicity and every manual scenario unexecuted**. The gap is stated per scenario, not summarised away.

## Scenarios stress-tested

### 1. An ops user renames a client-deliverable file to a genuinely new name

**Why it matters:** the ticket exists for this path. If it does not emit, nothing else matters.

**Held?** **Yes, at unit level.** One `write` call, routekey `callisto.client-access.file.renamed.v1`, `aggregateType: 'File'`, `aggregateId: String(fileId)`, and the converter receives the **new** filename plus the `proceedingId` handed down from the validator's context.

**Deliberate test choice worth flagging:** the routekey is asserted as a **string literal** in the spec while the source uses `CALLISTO_CLIENT_ACCESS_FILE_RENAMED_V1.eventType`. That is the sibling's convention and it is intentional — if the contract constant changed value, the source would follow it silently and the test would catch it.

### 2. The same file renamed twice in a row

**Why it matters:** rename is the epic's **first repeatable event on aggregate `File`**. `file.created.v1` could never exercise a second event for one aggregate, so this is new ground.

**Held?** **Not verified.** This is manual scenario M-2 and it was not run. Two distinct event ids are expected because the deterministic id includes a millisecond timestamp — but see scenario 7.

### 3. A rename that resolves to the filename the file already has

**Why it matters:** this is the quietest failure mode in the ticket. The request **succeeds** while the database is never written, so a naive implementation emits an event asserting a write that did not happen. Nothing downstream would flag it — Dione would simply take a redundant update.

**Held?** **Yes.** No `write`, no converter call, and the caller still gets its message.

**Change this scenario forced** — `rename-deliverable-file.assembler.ts`:
- **Observed:** `RenameProceedingFileTS.apply` returns early when the recomputed name equals the current one and issues **no `UPDATE`**, returning `previousFileName === fileName`.
- **Expected:** nothing emitted, because no rename occurred.
- **Fix:** guard on `projection.fileName === projection.previousFileName` before the emit, with a comment recording that this is coupled to that early-return branch.

**Open behavioural question this exposed** — and it is the reason **AC1 cannot be claimed as literally met**: AC1 says a successful `PATCH` writes a row. A successful no-op writes none. Recommendation is not to emit; the amended wording is question 1 for Larry (**LD-018**).

### 4. Renaming a file that is not a client deliverable

**Why it matters:** the boundary this ticket must not cross — an internal file's name reaching the client-facing system.

**Held?** **Yes, and it needed no new code.** `ProceedingFileMustBeDeliverableValidator` already 403s non-deliverables and runs first, so nothing after it can be a non-deliverable. Asserted by the service spec: validator rejects → the assembler is never called → no audit dispatch.

**What this scenario disproved:** the wiki spec justifies its tag guard with *"the rename endpoint may serve non-deliverable files as well."* It does not, and has not since commit `4d284978` (which **predates** the spec). No explicit re-check was added because it would be an unreachable branch.

**Its unresolved half** — the validator runs **outside** the new transaction and the tag is mutable both ways, so this proves deliverability **at request entry**, not at commit time. Question 2 for Larry (**LD-019**, concern **C10**).

### 5. The outbox write fails

**Why it matters:** **the ticket's main added correctness property.** Without a transaction, the filename commits, the caller gets a 500, and no event exists — so Callisto and Dione diverge with no reconciler (design Q5 forbids one).

**Held?** **Partially — and the gap is the most important line in this document.**
- **Proven:** the assembler **propagates** the error rather than swallowing it (NP-3a). That is the ceiling of a suite with a mocked aggregator and a mocked port.
- **NOT proven:** that a real `files.file_name` UPDATE and a real `outbox_events` INSERT roll back together. **NP-3b was not executed.**
- **Why the gap is dangerous:** replacing `createTransactionalProxy` with a plain class provider would silently lose atomicity and **all 1889 tests would still pass.**
- **Cheapest proof, not yet run:** manual **M-5** — `REVOKE INSERT ON callisto.outbox_events`, attempt a real rename, confirm `files.file_name` unchanged, `GRANT` back. `callisto-postgres` is up.

**Change this scenario forced** — `rename-deliverable-file-assembler.provider.ts` and a comment in the assembler:
- **Observed:** the rename path had **no transaction at all** — `RenameProceedingFileTS` is not `@Transactional()` and had no provider.
- **Expected:** rename and emit commit together or not at all.
- **Fix:** register the assembler through a `useFactory` wrapped in `createTransactionalProxy`, and record in the source that the missing try/catch is deliberate so the error can reach the boundary.

### 6. The acting user has no `identity` on their token

**Why it matters:** `AuthUser.identity` is optional; `renamedUserIdentity` is non-nullable in the contract. The obvious `user.identity.userId` would put `undefined` into a required field.

**Held?** **Yes.** Falls back to `user.sub`, asserted directly.

### 7. Two genuine renames of one file inside the same millisecond — **newly uncovered**

**Why it matters:** the outbox PK is uuidv5 over `…|rowUpdatedAt.getTime()|…`, and `OutboxEvent.id` is a **non-generated** uuid primary key whose repository ends in `repo.save()`. So a duplicate id would be a **silent UPDATE** — data overwritten, `status` reset to `PENDING`, no exception, no log.

**Held?** **Unknown, and honestly unknowable from what was run.** Assumption **A3** is source-inspected and **unobserved**; test EC-5 is **blocked at seed** because a sub-millisecond interleaving is not practically reproducible.

**Not a scenario this ticket created**, but the first one able to reach it. Tolerable only because the payload is a **current-state snapshot** — the surviving row still names the correct final filename. **That reasoning breaks if a future `v2` adds `previousFileName`.** Concern **C7**.

**Do not "fix" it with `ON CONFLICT DO NOTHING`** — that would keep the *first, stale* payload where `save()` keeps the later, correct one.

### 8. The existing audit event must keep working, unchanged — **neighbour**

**Why it matters:** the service was refactored around it. A silent change to the audit contract would be a regression in a path this ticket has no business touching.

**Held?** **Yes.** The existing audit-payload assertions were kept **byte-identical**, and a `callOrder` test proves the dispatch fires **after** the assembler returns — i.e. the SQS send stayed outside the transaction, so an audit outage cannot roll back a valid rename.

### 9. Submission and AJSF renames must not start emitting — **neighbour**

**Why it matters:** all three routes share one transaction script. Emitting there would make every submission-file rename announce itself to a client-facing consumer.

**Held?** **Yes, structurally rather than by assertion.** The change set contains **zero files** under `src/proceedings/**` or `src/proceeding-job-submission/**`, so the shared script keeps its four dependencies and no outbox port and is *incapable* of emitting. `rename-proceeding-file.transaction.script.spec.ts`, `proceeding.service.spec.ts` and `job-submission.service.spec.ts` all passed **unmodified** inside the full 364-suite run.

### 10. Mirror validators drifting apart — **newly uncovered by self-review**

**Why it matters:** `ProceedingFileMustBeDeliverableValidator` and `ProceedingFileMustBeSubmissionValidator` are mirrors, and this ticket changed one's return type. A reviewer (midnjerry) has flagged **this exact pair** before for coverage asymmetry.

**Held?** **Yes, by disclosure rather than by symmetry.**

**Change this scenario forced** — a JSDoc note on the deliverable validator:
- **Observed:** only the deliverable validator now returns its loaded context; its mirror still returns `void`.
- **Expected:** a reader should not have to wonder which side is correct.
- **Fix:** comment naming the mirror and why it was deliberately left alone — only the deliverable lane has a caller needing `proceedingId`, and widening the mirror would push this change into `src/proceedings`.

## Changes made, indexed by the scenario that forced them

| Change | File | Forced by |
| --- | --- | --- |
| No-op emission guard | `rename-deliverable-file.assembler.ts` | Scenario 3 |
| Transactional proxy provider | `rename-deliverable-file-assembler.provider.ts` | Scenario 5 |
| Deliberate absence of try/catch, documented | `rename-deliverable-file.assembler.ts` | Scenario 5 |
| `identity?.userId ?? sub` | `deliverable-rename.service.ts` | Scenario 6 |
| Snapshot-payload comment on the converter | `file-renamed-to-outbox-data.converter.ts` | Scenario 7 |
| Audit dispatch kept last and outside the transaction | `deliverable-rename.service.ts` | Scenario 8 |
| Mirror-divergence JSDoc | `proceeding-file-must-be-deliverable.validator.ts` | Scenario 10 |
| Validator returns its loaded context | `proceeding-file-must-be-deliverable.validator.ts` | Scenario 1 (payload needs `proceedingId`) |

## What is not proven, in one place

1. **Atomicity** (scenario 5) — the ticket's main added property. NP-3b unrun; manual M-5 is the cheap path.
2. **The client sees anything** — RabbitMQ is descoped and Dione's consumer is another team's. A payload correctly *shaped* but semantically wrong would pass everything here.
3. **Repeatability** (scenarios 2, 7) — no manual run, and the collision case is untestable.
4. **AC1 literally** (scenario 3) — the no-op behaviour is a recommendation awaiting Larry.
5. **Every manual scenario** — M-1 through M-5 unrun.