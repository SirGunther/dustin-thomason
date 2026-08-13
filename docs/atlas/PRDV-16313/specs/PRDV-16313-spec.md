# PRDV-16313 — Spec: emit `callisto.client-access.file.renamed.v1` on deliverable rename

| Field | Value |
| --- | --- |
| Parent epic | PRDV-15736 — Make Atlas metadata available to Planet Portal |
| Repo | `callisto-back-end` · branch `PRDV-16313` |
| Authority | `larry-adams/.../epic-PRDV-15736-.../PRDV-16313-endpoint-file-renamed.md` + `dione-file-access-event-design.md` |
| Yardstick | [job stories](../stories/PRDV-16313-job-stories-index.md) (both `accepted`) |
| Decisions | [PRDV-16313-locked-decisions.md](./PRDV-16313-locked-decisions.md) |
| Report | [PRDV-16313-investigation.md](../investigations/PRDV-16313-investigation.md) |
| Concerns | [PRDV-16313-future-development-concerns.md](../PRDV-16313-future-development-concerns.md) |
| Prerequisite | PRDV-16293 (outbox + dispatcher foundation) — **merged**, PR #399 `43ad3dea` |
| Feature flags | **None.** `granting-client-access` does not gate its outbox writes and the shipped `file.created.v1` is unflagged (LD-008 rationale in the ledger) |

## Sources — and one thing to read before the design

The wiki spec is authoritative and its **four acceptance criteria are correct and identical to the ClickUp text** (verified — unlike the sibling PRDV-16312, there is no criteria-level conflict here). **Its *Technical Design* section, however, is wrong on three counts**, and this spec departs from it deliberately in each case. A reviewer holding the wiki spec should read §Deviations first, or every departure will read as an error. Those three items are also the substance of the addendum submitted for review.

---

## Problem → Requirement → Solution

**Problem.** When an ops user renames a client-deliverable file, Callisto updates `files.file_name` and tells nobody. Dione holds its own copy of the filename, populated when the file was first shared, so the client keeps seeing the pre-rename name — indefinitely, with no error recorded anywhere. Callisto had no outbox at all in this module until PRDV-16293, so this is an absence rather than a regression.

**Requirement.** A successful rename of a client-deliverable file must produce exactly one durable, correctly shaped record of that rename — naming the file, its proceeding, the new name, who did it and when — and must produce **nothing** when the file is not a client deliverable, when no rename actually occurred, or when the rename did not commit. The record must not be able to exist for a rename that did not happen, and a rename must not be able to commit without it.

**Solution.** A transaction-owning **assembler** in `granting-client-access` delegates the domain write to the unchanged `ProceedingAggregator`, then writes a `callisto.client-access.file.renamed.v1` row through the existing `CLIENT_ACCESS_OUTBOX` port **inside the same database transaction**. The deliverable guarantee is supplied by the validator that already runs first; the payload is built by a dedicated converter typed against the shipped ODP contract. Every file touched is under `src/granting-client-access/`.

---

## 1. Folder hierarchy

New paths under `callisto-back-end/src/`:

```text
granting-client-access/
├── domain/
│   └── assemblers/
│       └── rename-deliverable-file-assembler/                    NEW
│           ├── __specs__/
│           │   └── rename-deliverable-file.assembler.spec.ts     NEW
│           ├── file-renamed-outbox-converter/                    NEW
│           │   ├── __specs__/
│           │   │   └── file-renamed-to-outbox-data.converter.spec.ts   NEW
│           │   ├── file-renamed-outbox-converter.input.ts        NEW
│           │   └── file-renamed-to-outbox-data.converter.ts      NEW
│           ├── rename-deliverable-file.params.ts                 NEW
│           ├── rename-deliverable-file.projection.ts             NEW
│           ├── rename-deliverable-file.assembler.ts              NEW
│           └── rename-deliverable-file-assembler.provider.ts     NEW
```

Mirrors the shipped `upload-complete-deliverable-file-ts/` + `file-created-outbox-converter/` shape, which is the module's one existing outbox producer.

Modified (no new paths): `validators/proceeding-file-must-be-deliverable.validator.ts`, `domain/services/deliverable-rename-service/deliverable-rename.service.ts`, `registries/transaction-script.registry.ts`, `granting-client-access.module.ts`.

**No paths under `src/proceedings/` or `src/proceeding-job-submission/`** — see §Regression.

## 2. New classes

| Class | Path |
| --- | --- |
| `RenameDeliverableFileAssembler` | `granting-client-access/domain/assemblers/rename-deliverable-file-assembler/rename-deliverable-file.assembler.ts` |
| `FileRenamedToOutboxDataConverter` | `.../rename-deliverable-file-assembler/file-renamed-outbox-converter/file-renamed-to-outbox-data.converter.ts` |
| `renameDeliverableFileAssemblerProvider` (factory fn, not a class) | `.../rename-deliverable-file-assembler/rename-deliverable-file-assembler.provider.ts` |

**Why an assembler and not a transaction script — LD-003.** This is the load-bearing structural decision and it was reached by elimination, not preference:

| Candidate | Blocked by |
| --- | --- |
| Inject the port into `RenameProceedingFileTS` (the wiki spec's literal instruction) | Module cycle (`granting-client-access` → `proceedings`, no reciprocal); no `AuthUser` at that layer, and `renamedUserIdentity` is non-nullable; fires for all three surfaces sharing that script |
| A new `RenameDeliverableFileTS` delegating to `ProceedingAggregator` | **`transaction-scripts-no-aggregators`, `severity: 'error'`** — fails `npm run test:architecture` |
| A new `RenameDeliverableFileTS` re-implementing the rename | Forks extension preservation, lineage and duplicate-name validation into a second writer of `files.file_name` |
| Emit inline in `DeliverableRenameService` | **`services-no-converters`, `severity: 'error'`**; and no transactional-proxied service exists anywhere in the repo |
| **An assembler** | Nothing. `assemblers.rules.ts` forbids only assembler → assembler / transaction-script / service / mapper. Assembler → aggregator, → converter, → port are all permitted |

> **Note for the next reader, and for the source header comment:** this class is a transaction script wearing a different suffix. That is **forced** by `transaction-scripts-no-aggregators`, not chosen. Do not "fix" the name — the build breaks, and routing around the rule means forking the rename rules. Recorded as concern C3.

## 3. New entities

**N/A** — no new tables. The event's transport row is `outbox_events`, whose entity ships inside `@planetdepos/orbital-relay-pkg` and already exists.

## 4. Modified entities

**N/A** — no entity changes. `File`, `FileAttachment`, `FileTag` and `FileAttachmentsFileTags` are all untouched.

> Related finding, deliberately **not** acted on: `File extends BaseAuditEntity`, which declares non-nullable `modified_user_identity`, and `updateFileName` writes neither identity column — so the row does not record who renamed it. That is why `renamedUserIdentity` comes from request context (LD-013) rather than the row. Out of scope; not a change this ticket makes.

## 5. New migrations

**N/A** — no DDL and no seed. `outbox_events` was created by `1772165619858-create__outbox_events_table.ts` (PRDV-16293) and needs no per-event migration.

## 6. New migration classes

**N/A** — see §5.

## 7. New DTOs

**N/A** — no HTTP surface change. `RenameDeliverableFileRequestDTO` and `RenameDeliverableFileResponseDTO` are unchanged; the route, method, params, body, status codes and auth decorators are all untouched.

## 8. New projections and domain inputs

| Type | Path | Shape |
| --- | --- | --- |
| `RenameDeliverableFileParams` | `.../rename-deliverable-file.params.ts` | `{ readonly fileId: number; readonly proceedingId: number; readonly value: string; readonly renamedUserIdentity: string }` |
| `RenameDeliverableFileProjection` | `.../rename-deliverable-file.projection.ts` | `{ readonly message: string; readonly projection: RenameProceedingFileProjection }` — passes the inner projection straight through, because the service still needs `fileName` / `filePath` / `bucket` / `previousFileName` for the unchanged audit dispatch |
| `FileRenamedOutboxConverterInput` | `.../file-renamed-outbox-converter/file-renamed-outbox-converter.input.ts` | `{ readonly fileId: number; readonly proceedingId: number; readonly fileName: string; readonly renamedUserIdentity: string; readonly renamedAt: Date }` |

Named without `Dto`, per the domain-layer convention. The converter input is a **narrow structural type, not the TypeORM entity** — mirroring `file-created-outbox-converter.input.ts`.

**Modified projection — and what is deliberately *not* modified.** `ProceedingFileMustBeDeliverableValidator.apply` changes from `Promise<void>` to `Promise<ProceedingFileRenameProjection>`, returning the context it already loads and currently discards (LD-009). **`RenameProceedingFileProjection` is NOT widened** — that would touch `src/proceedings`, force ~13 mechanical spec edits, and widen what the AJSF endpoint returns in its response body.

> Convention drift, stated rather than slipped in: all ~17 validators in the repo return `void`. Accepted because the alternative is exactly the blast radius the user ruled against. **Documented fallback if a reviewer rejects it:** widen the shared projection instead.

---

## Solution detail

### The emission

```
RenameDeliverableFileAssembler.apply({ fileId, proceedingId, value, renamedUserIdentity }):
  1. const { message, projection } = await proceedingAggregator.renameProceedingFile(fileId, value)
  2. if (projection.fileName === projection.previousFileName) return { message, projection }   // no-op — nothing was written
  3. const renamedAt = new Date()
  4. await clientAccessOutbox.write({
       routeKey: CALLISTO_CLIENT_ACCESS_FILE_RENAMED_V1.eventType,   // never a string literal
       payload: fileRenamedToOutboxDataConverter.apply({ fileId, proceedingId, fileName: projection.fileName, renamedUserIdentity, renamedAt }),
       aggregateType: FILE_AGGREGATE_TYPE,   // 'File'
       aggregateId: String(fileId),
       rowUpdatedAt: renamedAt,
     })
  5. return { message, projection }
```

**Step 2 is not optional.** `RenameProceedingFileTS.apply:39-46` returns early when the recomputed name equals the current one and **issues no `UPDATE`**. Emitting there would assert a database write that never occurred. `fileName === previousFileName` is exact rather than coincidental — it is literally that branch's own condition — but the coupling must carry a source comment and a test (LD-011).

**Step 3 — one `Date` for both** `renamedAt` and `rowUpdatedAt`, so payload and event id agree by construction (LD-012). It is a few ms later than the `files.updated_at` actually persisted, because `updateFileName` mints its own `new Date()` internally and returns nothing. Both are reads of the same process clock, and design Q5 forbids the projection-driven path that would ever re-derive the id from the row. Concern C4.

### Atomicity — LD-005

The provider wraps the assembler in `createTransactionalProxy`, which wraps any method named `apply`. Inside the boundary: the pre-read, `RenameProceedingFileTS`'s reads and its `UPDATE` (repositories auto-enlist via `TransactionContext.resolveRepository`), and the outbox `INSERT` (enlists via `TYPEORM_OUTBOX_REPOSITORY_RESOLVER`, bound `@Global` in `outbox-transaction-context.module.ts`). `runTransactional` is re-entrant, so nothing double-opens.

**Outside the boundary, deliberately:** the deliverable validator (a read, and the HTTP 403 gate) and `dispatchFileAuditRenamedEvent`. The audit dispatch is an **SQS send** — not rollbackable, would hold a DB transaction across a network hop, and pulling it in would newly let an SQS outage roll back renames. That is a behaviour regression on a path this ticket must not change.

| Failure | Before | After |
| --- | --- | --- |
| Domain write fails | no event (fine) | no event, no row (fine) |
| **Outbox write fails** | **would leave the file renamed with no event — silently, permanently** | **rollback → 500, filename unchanged, clean retry** |
| Audit SQS fails | rename stands, no audit | rename + event stand, no audit (**unchanged**) |

**Fail closed is confirmed, not assumed (LD-010).** Precedent established by evidence first: the shipped producer has **no try/catch**, and there are **zero catch blocks** in either outbox infrastructure tree. Cost accepted and recorded as concern **C8** — an outbox failure now also blocks renaming.

### The deliverable guard — LD-004

**No explicit tag re-check.** `ProceedingFileMustBeDeliverableValidator` throws `ForbiddenException('Only client deliverable files can be renamed via this endpoint')` on `!isDeliverable` and runs **first**, so everything after it is unconditionally a client deliverable and a second check would be a provably unreachable branch. AC3 is met behaviourally and proven by test.

This contradicts the wiki spec's step 2, whose justification — *"the rename endpoint may serve non-deliverable files as well"* — has been false since commit `4d284978` (PRDV-15776) split rename by deliverable vs submission. **This is the one item a reviewer may reasonably overrule**; the literal form is one line using the `isDeliverable` flag already on the returned context, at the cost of a dead branch. Carried to Larry in the addendum.

### Payload — LD-006, LD-007, LD-008

`CallistoClientAccessFileRenamedV1Data` from `@planetdepos/orbital-docking-protocol@1.0.7`: `fileId`, `proceedingId`, `fileName` (the **new** name), `renamedUserIdentity`, `renamedAt` (ISO-8601). Five fields, none nullable.

The converter declares that type as its **explicit return type**, which makes AC2 a **compile-time** guarantee rather than a test assertion.

> **Do not add `previousFileName`.** The design doc's Diagram ④ (`:740-747`) sketches `previousFileName` + `newFileName`; the shipped contract has a single `fileName` and the ticket annotates it "the new name". The package wins; the diagram is stale (LD-008, addendum item). This also matters for concern **C7**: the payload being a *state snapshot* is precisely what makes a deterministic-id overwrite converge on the correct final name. A `v2` adding a delta field silently breaks that reasoning.

`renamedUserIdentity` = `user.identity?.userId ?? user.sub` (LD-013) — the defensive form used by the two most recent same-module siblings. `AuthUser.identity` is optional and the contract field is not.

---

## Locked Decisions From Q and A

Summary only. **Full ledger with sources, supersessions and question gates: [PRDV-16313-locked-decisions.md](./PRDV-16313-locked-decisions.md).**

| ID | Decision | Source |
| --- | --- | --- |
| LD-001 / LD-002 | Wiki spec authoritative; its four ACs are correct — only its Technical Design is wrong | evidence |
| **LD-003** | Emit from a transaction-owning **assembler**; every alternative is blocked | evidence |
| **LD-004** | No explicit tag re-check — the validator already guarantees it | evidence |
| **LD-005** | Outbox write **inside** the rename transaction; audit dispatch outside | evidence |
| LD-006 | No ODP, registry, or migration change | evidence |
| LD-007 / LD-008 | Dedicated converter typed against the ODP contract; single `fileName`, no `previousFileName` | precedent / evidence |
| LD-009 | `proceedingId` from the validator's returned context — no new query | evidence |
| **LD-010** | **Fail closed** — a failed outbox write rolls back the rename | **grilled** (after evidence narrowed the question) |
| LD-011 | Skip the emission on the no-op branch | evidence |
| LD-012 | One `Date` at the emit site for both `renamedAt` and `rowUpdatedAt` | **user ruling** |
| LD-013 | `identity?.userId ?? sub` | precedent |
| **LD-014** | **AJSF rename hole recorded, not fixed** | **user ruling** |
| LD-015 | Story 01's user is the client; story 02's the ops user | **grilled** |
| LD-016 | Nothing states the sync latency | agent call |
| LD-017 | Story 01's criteria restated to what is falsifiable here | precedent (sibling LD-007) |

**Three questions never reached the user** because `P3.reconcile` resolved them by evidence: the fail-open/fail-closed precedent, the literal-tag-check question (Larry's, not Dustin's), and Dione's behaviour (unanswerable in this workspace). Gate table in the ledger.

---

## Deviations from the wiki spec

The list a reviewer needs. Each is also an addendum item.

| Wiki spec says | This spec does | Why |
| --- | --- | --- |
| *"Inject `CLIENT_ACCESS_OUTBOX` port into the rename transaction script"* / *"the transaction script behind `PATCH /file/:fileId`"* | A new **assembler** in `granting-client-access` | **No such transaction script exists in this module.** The only rename TS lives in `proceedings`, is shared by three routes, has no `AuthUser`, and would be a module cycle. **And the natural adaptation is illegal:** `transaction-scripts-no-aggregators` at `severity: 'error'`. |
| *"check if file has `CLIENT_DELIVERABLE` tag; if no: skip"*, justified by *"the rename endpoint may serve non-deliverable files as well"* | No explicit check — the existing validator supplies it | **The justification is false** since PRDV-15776. A second check is provably unreachable. AC3 still met behaviourally. **Reviewer may overrule.** |
| *(silent on transactions)* | Outbox write inside the rename transaction | Without it, a failed write leaves the file renamed with no event, permanently and silently, and Q5 forbids the reconciler that would repair it — the exact defect this ticket removes. |
| *(silent on the deterministic event id)* | Documented, tested, and a residual recorded | A duplicate id **silently UPDATEs** rather than raising (non-generated uuid PK + `repo.save()`). `file.created.v1` never hit it — a file is created once. **Rename is the first repeatable event on aggregate `File`.** |
| *(silent on other rename surfaces)* | Recorded as concern C1, not fixed | The design's coverage audit enumerated only `granting-client-access` writes, so the AJSF route was never examined. User-ruled out of scope on workflow grounds. |
| Design Diagram ④ shows `previousFileName` + `newFileName` | Single `fileName` | Shipped ODP contract wins; the diagram is stale. |
| *"Files to modify: the rename deliverable file transaction script"* | Also the validator, the service, the registry and the module | Consequence of the above; the service must resolve `renamedUserIdentity` from `AuthUser` because the domain layer must not touch HTTP auth types. |
| Converter specs come in unit + real-Postgres pairs (repo convention) | Unit spec only | The sibling's integration spec exists for the `files.file_size` **bigint-as-string** hazard. Every numeric here is an `integer` column, so a Postgres round-trip proves nothing. |

---

## Optional callouts

**HTTP surface** — **no change.** `PATCH /granting-client-access/file/:fileId` keeps its path, method, guard, request DTO, response DTO and status codes. Checked explicitly: route decorator, `@UseGuards(UpdateDeliverableFileAuthGuard)`, both DTOs, and the response shape — all unchanged.

**API docs / Swagger** — **not relevant.** No HTTP contract change (surface named above). `RenameDeliverableFileSwagger()` is untouched. The event contract lives in ODP and already ships.

**Registries and module wiring** —
- `registries/transaction-script.registry.ts`: add `FileRenamedToOutboxDataConverter` beside `FileCreatedToOutboxDataConverter`, plus the existing "provided via a transactional proxy in the module's providers section" comment convention for the assembler.
- `granting-client-access.module.ts`: add `renameDeliverableFileAssemblerProvider()` to `providers`. **Do not also list the assembler class plainly — that shadows the proxy and silently loses atomicity.** No `imports` change (`ProceedingsModule` already present), no `exports` change.

**Ports** — none new. Reuses `CLIENT_ACCESS_OUTBOX` (`ClientAccessOutboxPort.write`), provided and exported by this module.

**Domain events / dispatchers / outbox** — one new **producer**, no new event type, no new dispatcher, no new runner. Routekey `callisto.client-access.file.renamed.v1` was pre-registered in `client-access-outbox-event.registry.ts` by PRDV-16293. Command-driven per design Q5. **No projection-driven runner** for aggregate `File`, and none is to be added.

**Domain exceptions** — none new. `NotFoundException` / `ForbiddenException` from the existing validator are unchanged, as are their messages.

**Authorization** — **no change.** `UpdateDeliverableFileAuthGuard` and `DeliverableFileAuthorizeRole` are untouched. (Noted and *not* acted on: the guard authorizes on a client-supplied `request.body.trackTypeId` never cross-checked against the file's actual track. Pre-existing, unrelated to emission, deliberately left alone.)

**Spec tests** — `__specs__/rename-deliverable-file.assembler.spec.ts` (new), `__specs__/file-renamed-to-outbox-data.converter.spec.ts` (new), `deliverable-rename.service.spec.ts` (modify), `proceeding-file-must-be-deliverable.validator.spec.ts` (modify). Full mapping in [the test plan](../testing/PRDV-16313-test-plan.md).

**Regression / neighbour protection** — **the isolating boundary is the module.** Zero files under `src/proceedings/**` or `src/proceeding-job-submission/**`, so `RenameProceedingFileTS` keeps its four dependencies and no outbox port and is **structurally incapable** of emitting; `RenameProceedingFileProjection` is unchanged so no response body shifts. Verified by `git diff --name-only` plus these passing **unmodified**: `rename-proceeding-file.transaction.script.spec.ts`, `proceeding.service.spec.ts`, `job-submission.service.spec.ts`. The audit dispatch is protected by leaving its existing service-spec assertions byte-identical.

**Companion / sibling tickets** — PRDV-16310 (grants replaced), PRDV-16311 (approve v2), PRDV-16312 (`file.created.v1`, **shipped — the pattern this follows**), PRDV-16314 (recategorize), PRDV-16315 (unapprove), PRDV-16316 (collection deleted retrofit), PRDV-16317 (delete proceeding file). **Dependency worth flagging:** PRDV-16312 shipped under a spec-approval waiver and remains gated on Larry's response to `larry-adams` PR #34; if that response changes payload conventions, decisions here are affected.

**Gates** — audit → lint → **`npm run test:architecture`** → tests, serial. The architecture gate is not boilerplate here: two `severity: 'error'` rules *selected* this design, and the assembler shape is legal by **reading** the rules rather than executing them (report assumption A6).

## What this spec knowingly does not deliver

| Shortfall | Where recorded |
| --- | --- |
| A rename via the AJSF route still emits nothing, with no user and no audit trail | C1 · LD-014 |
| Nothing proves the client actually sees the new name — this ticket proves the producer, not the outcome | C9 |
| Extensionless filenames get the old name appended, and this ticket makes that **visible to Dione** without causing it | C2 |
| Two genuine renames inside one millisecond collapse to one event | C7 · test plan EC-5 (blocked) |
| `fetchProceedingFileForRename` still runs twice per request | C6 |
