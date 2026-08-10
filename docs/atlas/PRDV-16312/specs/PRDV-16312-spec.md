# PRDV-16312 — Story spec: emit `file.created.v1` on client-deliverable upload-complete

| Field | Value |
| --- | --- |
| Ticket | PRDV-16312 · parent epic PRDV-15736 |
| Repo | `callisto-back-end` only (LD-008) |
| Baseline | `71ce3cbf` (`main`) |
| Written | 2026-08-05 (Phase 3) |
| Acceptance criteria | Owned by [stories/](../stories/PRDV-16312-job-stories-index.md) — both `accepted`. This spec **cites** them; it does not restate or amend them. |
| Decisions | [PRDV-16312-locked-decisions.md](./PRDV-16312-locked-decisions.md) |
| Investigation | [PRDV-16312-investigation.md](../investigations/PRDV-16312-investigation.md) (+ §13 addendum) |
| Test plan | [PRDV-16312-test-plan.md](../testing/PRDV-16312-test-plan.md) |

## Sources

The `larry-adams` wiki spec and `dione-file-access-event-design.md` are **authoritative**; the ClickUp description is a stale pointer that asks for two events (LD-001, LD-002).

---

## Problem → Requirement → Solution

**Problem.** `POST /upload-complete` persists a client-deliverable file and tells nothing downstream. `CLIENT_ACCESS_OUTBOX` has zero production consumers, so no client has ever seen a directly uploaded deliverable in Planet Portal via this path.

**Requirement.** Every successful upload-complete into client deliverables must leave a durable, correctly shaped record of the new file — including which track, collection, and deliverable type it belongs to, and the collection's name — committed atomically with the file itself, so a consumer can project it without a second event and without ordering assumptions.

**Solution.** Inject `CLIENT_ACCESS_OUTBOX` into `UploadCompleteDeliverableFileTransactionScript`; after the file persists, a dedicated converter builds a `CallistoClientAccessFileCreatedV1Data` payload and the port writes one outbox row inside the existing transaction.

---

## Locked Decisions From Q and A

Full ledger with sources: **[PRDV-16312-locked-decisions.md](./PRDV-16312-locked-decisions.md)**.

| # | Decision |
| --- | --- |
| LD-001 | One event only; `collection.created.v1` is a non-goal |
| LD-003 | Collection identity travels inline; Dione upserts |
| LD-005 | Emit inside the `@Transactional()` TS, after persistence |
| LD-007 | AC6 / RabbitMQ withdrawn from scope |
| LD-011 | Read the collection by id when no pending name was supplied |
| LD-012 | Populate `deliverableCollectionValue` for static **and** dynamic (risk: concern C7) |
| LD-013 | Converter returns ODP's `CallistoClientAccessFileCreatedV1Data` directly |
| LD-014 | Assembly in a dedicated converter, not inline |

---

## 1. Folder hierarchy

New paths under `callisto-back-end/src/`:

```text
granting-client-access/
  domain/transaction-scripts/upload-complete-deliverable-file-ts/
    file-created-outbox-converter/
      file-created-to-outbox-data.converter.ts            NEW
      __specs__/
        file-created-to-outbox-data.converter.spec.ts      NEW
```

Everything else is a modification. The converter is colocated with the TS that owns it, matching the sibling `create-deliverable-file-mapper/` and `find-or-create-dynamic-collection-assembler/` folders already in that directory.

## 2. New classes

| Class | Path |
| --- | --- |
| `FileCreatedToOutboxDataConverter` | `…/upload-complete-deliverable-file-ts/file-created-outbox-converter/file-created-to-outbox-data.converter.ts` |

`apply(input): CallistoClientAccessFileCreatedV1Data` — pure transform, no I/O. The return type is imported from `@planetdepos/orbital-docking-protocol` (LD-013), so a contract change becomes a compile error.

## 3. New entities

**N/A** — no new table. `outbox_events` was created by PRDV-16293.

## 4. Modified entities

**N/A** — no entity column changes. `File`, `FileAttachment`, and `DeliverableCollection` are read as-is.

## 5. New migrations

**N/A** — no schema change.

## 6. New migration classes

**N/A** — see §5.

## 7. New DTOs

**N/A** — no HTTP contract change. The request DTO, response DTO, route, method, status codes, and guards are all untouched.

## 8. New projections and domain inputs

| Type | Path | Note |
| --- | --- | --- |
| `FileCreatedOutboxConverterInput` | beside the converter | The converter's input: the persisted `File` (carrying `id`, `createdAt`, `createdUserIdentity`, `fileAttachment`), the resolved `deliverableCollectionId`, the resolved collection `value`, and `deliverableTypeId`. Keeps `Dto` out of the domain layer. |

**Modified:** `DynamicCollectionProjection` is **unchanged** (LD-004) — it already returns `value`; the TS simply stops discarding it.

---

## Field sourcing

All 17 fields of `CallistoClientAccessFileCreatedV1Data`, each traced to an existing value — no new query beyond LD-011's collection read.

| Field | Source |
| --- | --- |
| `fileId` | `file.id` — populated by `repo.save()` (LD-015) |
| `fileAttachmentId` | `file.fileAttachment.id` |
| `proceedingId` | `params.proceedingId` |
| `trackTypeId` | `params.trackTypeId` |
| `deliverableCollectionId` | `resolvedDeliverableCollectionId` (already computed) |
| `deliverableCollectionValue` | assembler's returned `value` on the by-name branch; **collection read by id** on the other (LD-011); `null` when there is no collection |
| `deliverableTypeId` | `params.deliverableTypeId ?? null` |
| `attachedToType` | `'Proceeding'` — `file.fileAttachment.attachedToType` is typed to that literal |
| `fileName` | `file.fileName` |
| `key` | `file.filePath` — **note the rename** |
| `bucketName` | `file.bucket` — **note the rename** |
| `fileSize` | `file.fileSize` — column is `bigint`; ensure a JS `number`, not a string |
| `fileType` | `file.fileType` |
| `length` | `file.length ?? null` |
| `createdUserIdentity` | `file.createdUserIdentity`, already set from `params.userId` (LD-010) |
| `createdAt` | `file.createdAt` (`BaseEntity.@CreateDateColumn`) serialised ISO 8601 (LD-015) |

Two sourcing hazards worth naming for the implementer, both cheap to get wrong:

- **`fileSize` is a `bigint` column.** TypeORM commonly surfaces `bigint` as a **string**. The contract declares `number`. Coerce explicitly and assert it in the converter spec.
- **`created_at` is `timestamp` *without* time zone** (per `BaseEntity`'s own doc comment). `.toISOString()` will stamp a `Z` on a value that may not be UTC. Follow the existing precedent (`contact.createdAt.toISOString()`) for consistency, but flag any discrepancy observed at implementation rather than assuming it is correct.

## Where to emit

Inside `UploadCompleteDeliverableFileTransactionScript.apply`, **after** `await this.deliverableFileRepository.create(file)` and before the return (LD-005). Ordering is load-bearing: placed after persistence, a validator throw or a failed insert can never reach the emission, and `@Transactional()` rolls both writes back together (story 01 criterion 5).

## Implementation steps

1. Capture the **whole** assembler result, not just `.id` — the TS currently does `(await …apply(…)).id` and discards `value`.
2. On the branch where `params.deliverableCollectionId` is used instead, **read the collection by id** to obtain `value` (LD-011). Return `null` for both id and value when there is no collection.
3. Inject `@Inject(CLIENT_ACCESS_OUTBOX) private readonly clientAccessOutbox: ClientAccessOutboxPort` into the TS, and the new converter.
4. After `create`, build the payload via the converter and call `write({routeKey: CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1.eventType, payload, aggregateType: 'File', aggregateId: String(file.id), rowUpdatedAt: file.updatedAt})`.
5. Register the converter in the module and add both new constructor args to `createUploadCompleteDeliverableFileTSProvider`'s `useFactory` and `inject` arrays — the TS is wrapped in `createTransactionalProxy`, so the provider must be updated in step with the constructor.

Use the routekey via `CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1.eventType` rather than a string literal: the writer throws `BadRequestException` on an unregistered key, and referencing the constant makes a typo impossible.

## Registries and module wiring

`granting-client-access.module.ts` — add `FileCreatedToOutboxDataConverter` to `providers`; extend the upload-complete TS provider factory. `CLIENT_ACCESS_OUTBOX` is **already** provided and exported (`:100-104`), and `OutboxProjectorModule` wiring came with PRDV-16293. Nothing new to export.

## Ports

**No new port.** `ClientAccessOutboxPort` + `CLIENT_ACCESS_OUTBOX` already exist. The port-token indirection is required because `writers/` is not path-exempt from the `domain-no-infrastructure` architecture rule — a domain TS may depend on the port, never on `ClientAccessOutboxWriter`.

## Contract enforcement

The port accepts `payload: Record<string, unknown>`, so it provides no guarantee (concern C3). Enforcement lives in the converter's **return type**, `CallistoClientAccessFileCreatedV1Data` imported from ODP (LD-013). This deliberately deviates from the `ContactOutboxEvent` precedent, which hand-declares a parallel shape; the deviation is stated in the decision ledger. After LD-007 removed the queue-observation step, this is the only mechanism that fails loudly on contract drift.

## Domain events / dispatchers / outbox

One new emission point. The dispatcher and projector engine are unchanged — PRDV-16293 built them, and this is their **first production producer**. Deterministic event id derives from `runnerName` + `aggregateType` + `aggregateId` + `rowUpdatedAt` + `eventType`, so `rowUpdatedAt` (`file.updatedAt`) is load-bearing for idempotency.

## Domain exceptions

**N/A** — no new thrown types. Existing validators are untouched; `BadRequestException` on an unknown routekey is pre-existing writer behavior.

## Authorization

**N/A** — no guard, role, or policy change. The action's existing decorators and `AuthUser` resolution are untouched.

## HTTP surface

**N/A** — no route, method, path, body, status, or auth change. Purely additive side effect within an existing endpoint.

## API / Swagger docs

**Not relevant — no contract change.** Surfaces checked and confirmed unchanged: the route decorator and path on `upload-complete-deliverable-file.action.ts`, its request and response DTOs, and `upload-complete-deliverable-file.action.swagger.ts`. The event contract is documented in `orbital-docking-protocol`, not in this repo's Swagger.

## Spec tests

| Spec | Purpose |
| --- | --- |
| `…/file-created-outbox-converter/__specs__/file-created-to-outbox-data.converter.spec.ts` | NEW — all 17 fields; `fileSize` is a number; null branches for collection id/value, `deliverableTypeId`, `length` |
| `…/upload-complete-deliverable-file-ts/__specs__/upload-complete-deliverable-file.transaction.script.spec.ts` | EXTEND — test-plan U1–U8: one write on success, none on validator/persist failure, ordering after `create`, value populated on both branches |
| `find-or-create-dynamic-collection.assembler.spec.ts` | **UNCHANGED** — must pass unmodified (test-plan N1) |
| recategorize + approve-v2 specs | **UNCHANGED** — must pass unmodified (N2, N3): the assembler's neighbors |

Full scenario list and criterion mapping in the test plan. Serial run: `npm test -- --runInBand src/granting-client-access`.

## Regression surface

The only shared code touched is the assembler's **call site**, not the assembler. Its signature and return type are unchanged (LD-004), which is what keeps its other two callers — recategorize and approve-v2 — inert. That claim is proven concretely by N1–N3 passing **without modification**; if any of those specs needs editing, the change is broader than this spec describes and that is a finding, not a test to fix.

## Non-goals

- `collection.created.v1` (LD-001) — removed at the design and contract level.
- Dev RabbitMQ queue visibility / topology (LD-007). `RABBITMQ_CONFIG_REQUEST_TEMPLATE.md` stays deliberately unfilled.
- Any `orbital-docking-protocol` change (LD-006) — the contract already exists, complete.
- Emission from recategorize or approve-v2 (LD-009) — PRDV-16314 and PRDV-16311.
- A created-vs-found flag on `DynamicCollectionProjection` (LD-004).
- Fixing the case-variant duplicate-collection limitation (concern C1) or retrofitting existing producers to alias their ODP types (concern C3).
- Dione's consumer, and the Atlas front end.
