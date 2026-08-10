# PRDV-16312 — Phase 4 Implementation Plan

> Replaces the Phase 1 recon-and-plan that previously occupied this file. That document is **not lost** — it was saved verbatim and frozen at `docs/atlas/PRDV-16312/investigations/PRDV-16312-recon-and-plan.md` at Phase 2's first action, miss and all.
>
> Planned **from the artifacts only** — no re-investigation. Sources: `specs/PRDV-16312-spec.md`, `specs/PRDV-16312-locked-decisions.md`, `testing/PRDV-16312-test-plan.md`, `investigations/PRDV-16312-investigation.md` §11 + §13. Saved verbatim to `PRDV-16312-implementation-plan.md` at Phase 5's first action, then frozen.

## Context

`POST /upload-complete` persists a client-deliverable file and tells nothing downstream. `CLIENT_ACCESS_OUTBOX` has zero production consumers, so no client has ever seen a directly uploaded deliverable in Planet Portal via this path. PRDV-16293 built the carrier; this ticket is its **first producer**.

**Problem → Requirement → Solution.** *Problem:* the write is invisible outside Callisto. *Requirement:* every successful upload-complete must leave a durable, correctly shaped record of the file — track, collection, deliverable type, and the collection's name — committed atomically with the file itself, so a consumer can project it without a second event or ordering assumptions. *Solution:* one `file.created.v1` outbox row, written inside the existing `@Transactional()` transaction script, with the payload built by a converter typed to the ODP contract.

**One event, not two.** The ClickUp description asks for `collection.created.v1`; it was deliberately removed and is not exported by ODP at all (LD-001, LD-006). Collection identity travels inline.

## Shipping obligations, named up front

Per `build-implementation-guardrails` §5, stated before writing code rather than discovered at the end:

| Obligation | Commitment |
| --- | --- |
| **Tests added** | New converter spec (test-plan C1–C5); extended TS spec (U1–U8, U2b, U2c). Red→green: U1 fails on `main`. |
| **Tests run** | `npm test -- --runInBand src/granting-client-access`, serial. Exact command + scope + result reported in a table. |
| **Regression** | Not "isolated" as a bare claim — the boundary is the **assembler's signature and return type, unchanged** (LD-004). Proven by N1–N3 passing **unmodified**. |
| **API docs** | Not relevant — no HTTP contract change. Surfaces to check and confirm unchanged: route decorator/path on the action, request + response DTOs, `upload-complete-deliverable-file.action.swagger.ts`. |
| **Gates** | `npm audit --audit-level=high` → `npm run lint` → tests, in that order, tests last against the post-lint tree. |
| **Changelog** | Session log entry in `docs/atlas/PRDV-16312-changelog.md` **before** the commit. |
| **Out of scope** | AC6 / RabbitMQ (LD-007); ODP changes (LD-006); recategorize + approve-v2 (LD-009); concerns C1, C3-retrofit, C7. |

## Ordered steps

Each step traces to its source artifact **and** to the acceptance criterion it serves.

| # | Step | Source | Criterion |
| --- | --- | --- | --- |
| **1** | Save this plan verbatim as `PRDV-16312-implementation-plan.md`; update the ledger (Phase 4 `done`, Phase 5 `in-progress`); fire the deferred Phase 4 notification. | orchestrate Phase 5 | — (process) |
| **2** | **Branch.** `git checkout main && git pull origin main && git checkout -b PRDV-16312`; confirm with `git branch --show-current`. Branch name is the ticket number only. | `new-branch-get-started.md` | — (process) |
| **2b** | **HARD GATE — confirm Larry responded to the spec addendum before any product code.** Addendum submitted as `larry-adams` PR **#34**. Record the response in the ledger with its form and date (merge, comment, or explicit go-ahead). **If it has not arrived, stop and say so** — do not implement on the assumption it will be fine. Proceeding regardless needs a waiver naming who authorised it and the risk. Phase 4's plan approval is **not** this approval: it approves sequencing, not a design Larry owns. Three items specifically await him — LD-011, LD-012 (+ risk C7, the one he most needs to confirm), LD-013's deviation from the `ContactOutboxEvent` precedent. | `P5.spec-approved`, spec-writing rule | all |
| **3** | **Confirm the test plan is in place before any code.** It was refined at Phase 3 and is **not** revised here (orchestrate Phase 5 step 2) — the tests must not be shaped by what gets built. | test plan (`refined`) | all |
| **4** | **Write the converter** `FileCreatedToOutboxDataConverter` + its input type, at `…/upload-complete-deliverable-file-ts/file-created-outbox-converter/`. `apply(input): CallistoClientAccessFileCreatedV1Data` — pure transform, no I/O, return type imported from `@planetdepos/orbital-docking-protocol`. | spec §2, LD-013, LD-014 | AC2, S1.3 |
| **5** | **Write the converter spec** — all 17 fields; `fileSize` coerced to a JS `number` (`file_size` is `bigint`, TypeORM often yields a string); `createdAt` an ISO string not a `Date`; null branches for collection id/value, `deliverableTypeId`, `length`. | test plan C1–C5 | AC2, AC4, S1.2 |
| **6** | **Capture the assembler's whole result** in the TS — it currently does `(await …apply(…)).id` and discards `value`. Keep both. | spec §Implementation steps, LD-011 | AC3, S2.1 |
| **7** | **Add the by-id collection read.** On the branch where `params.deliverableCollectionId` is used, call the **existing** `DeliverableCollectionRepository.findById(id)` to obtain `value`. Both `id` and `value` are `null` when there is no collection. **Reuse, do not add a repository method.** | LD-011, LD-012 | AC3, S2.1, S2.2 |
| **8** | **Inject and emit.** Add `@Inject(CLIENT_ACCESS_OUTBOX) clientAccessOutbox: ClientAccessOutboxPort`, the converter, and `DeliverableCollectionRepository` to the TS. **After** `await deliverableFileRepository.create(file)`, call `write({routeKey: CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1.eventType, payload, aggregateType: 'File', aggregateId: String(file.id), rowUpdatedAt: file.updatedAt})`. Reference the constant, never a string literal. | spec §Where to emit, LD-005 | AC1, S1.1, S1.5 |
| **9** | **Wire the module.** Add the converter to `granting-client-access.module.ts` providers; extend `createUploadCompleteDeliverableFileTSProvider`'s `useFactory` args **and** `inject` array with all three new constructor deps — the TS is wrapped in `createTransactionalProxy`, so the provider must move in step with the constructor or DI fails at boot. | spec §Registries | AC1 |
| **10** | **Extend the TS spec** — U1 (red→green), U2/U2b/U2c (by-name existing, by-id existing, static), U3 (no-collection nulls), U4 (full shape), U5 (legacy null type), U6/U7 (no write on validator or persist failure), U8 (write ordered after `create`, asserted by call order). | test plan U1–U8 | AC1–AC5, S1.1–S1.5, S2.1–S2.3 |
| **11** | **Self-review the diff** against `docs/reviewers/pr-review-patterns.md` — after the code, before the tests are finalised, so any refactor it prompts happens while the tests are not yet shaped around the current shape. | orchestrate Phase 5 step 3b | — (quality) |
| **12** | **Prove the neighbors unchanged.** Run N1–N3: the assembler spec, the recategorize spec, and the approve-v2 spec must pass **without modification**. If any needs editing, stop — the change is wider than the spec describes and that is a finding, not a test to fix. | test plan N1–N3 | regression |
| **13** | **Execute the test plan**, recording exact command + scope + observed result per scenario. No expectations, no "should pass". | test plan | all |
| **14** | **M2 manual verification** — upload into a new dynamic collection locally, then inspect the persisted `outbox_events` row: `event_type`, `schema_uri`, `schema_version` against the contract, and `data` against U4's shape with `deliverableCollectionValue` populated. This is now the **terminal** verification, since M1 was descoped. | test plan M2, LD-007 | AC2, S1.4, S2.4 |
| **15** | **Write the testing-implementation doc** `testing/PRDV-16312-testing-implementation.md` — scenario-first: each real situation stress-tested, whether it held, newly-uncovered ones flagged, and any change hung off the scenario that forced it. PR-comment content, never a source comment. | `testing-implementation-artifact.md`, guardrails §7 | all |
| **16** | **Changelog session log**, then gates in order: `npm audit --audit-level=high` → `npm run lint` (re-`git add` if `--fix` mutates files) → `npm test -- --runInBand src/granting-client-access`. Then `git add` → commit `PRDV-16312: Emit file.created.v1 on deliverable upload` → push. | `git-commit-workflow`, `ticket-changelog` | — (process) |
| **17** | **Fill the PR draft shell** and open the PR per `pull-request-workflow.md`. State explicitly in the Description that **one** event ships and why, so a reviewer comparing against ClickUp does not read it as incomplete. **No reviewer requested.** | spec, C2 | — (process) |

## Files

**New** — `src/granting-client-access/domain/transaction-scripts/upload-complete-deliverable-file-ts/file-created-outbox-converter/`
- `file-created-to-outbox-data.converter.ts`, its input type, and `__specs__/file-created-to-outbox-data.converter.spec.ts`

**Modified**
- `…/upload-complete-deliverable-file-ts/upload-complete-deliverable-file.transaction.script.ts` — steps 6, 7, 8
- `…/upload-complete-deliverable-file-ts/upload-complete-deliverable-file-ts.provider.ts` — step 9
- `src/granting-client-access/granting-client-access.module.ts` — step 9
- `…/upload-complete-deliverable-file-ts/__specs__/upload-complete-deliverable-file.transaction.script.spec.ts` — step 10

**Reused, not written**
- `DeliverableCollectionRepository.findById` (`…/infrastructure/repositories/deliverable-collection.repository.ts:36-40`) — already exists; step 7 depends on it
- `CLIENT_ACCESS_OUTBOX` + `ClientAccessOutboxPort` (`…/domain/ports/client-access-outbox.port.ts`) — already provided and exported at `granting-client-access.module.ts:100-104`
- `CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1` + `CallistoClientAccessFileCreatedV1Data` from `@planetdepos/orbital-docking-protocol` (1.0.7, verified on disk)
- `FindOrCreateDynamicCollectionAssembler` — call site changes, the class does **not**
- `createTransactionalProxy` provider pattern — existing template in the same provider file

**Deliberately untouched:** `DynamicCollectionProjection` (LD-004), the assembler itself, all DTOs/routes/guards, `RABBITMQ_CONFIG_REQUEST_TEMPLATE.md`.

## Verification

**Red→green proof.** U1 must fail on `main` and pass on the branch: *given a successful upload-complete into a newly created dynamic collection, `ClientAccessOutboxPort.write` is called exactly once with routeKey `callisto.client-access.file.created.v1` and `deliverableCollectionValue` equal to the trimmed collection name.* It fails today because no writer is injected.

**Suite.** `npm test -- --runInBand src/granting-client-access` — serial, per the personal rule.

**Gates.** audit → lint → tests, reported as a table with exact command, scope, result, and any exception.

**End-to-end.** Step 14's M2: a real local upload producing a correctly shaped `outbox_events` row. Nothing downstream of that row is proven by this ticket — LD-007 removed the queue observation, so no consumer path is exercised. That limit gets stated in the PR, not glossed.

**Two silent-corruption risks the type system will not catch** — both are why steps 5 and 14 exist rather than trusting LD-013 alone: `fileSize` arriving as a string from a `bigint` column, and `created_at` being `timestamp` *without* time zone while `.toISOString()` stamps a `Z`. TypeScript believes both are fine. Assert the first; observe the second at step 14 and report any discrepancy rather than assuming the precedent is right.

## Stop conditions

Halt and report rather than working around, per the browser-loop/bounded-iteration discipline:

- **Larry has not responded to PR #34** → step 2b is unanswered. This is the expected state at the moment of writing, and it is a legitimate park, not a failure: review latency is asynchronous and can outlast a session. Do not start step 4.

- Any of N1–N3 requires modification → the change is wider than designed.
- DI fails at boot → provider/constructor mismatch in step 9; fix the wiring, do not bypass the transactional proxy.
- `npm audit --audit-level=high` exits non-zero → stop before commit, report for triage.
- The emitted `data` disagrees with `CallistoClientAccessFileCreatedV1Data` in a way that tempts a cast → that is contract drift; report it, do not `as unknown as` past it.
