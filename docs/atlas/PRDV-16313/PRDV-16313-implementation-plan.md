# PRDV-16313 — Implementation plan (orchestrate Phase 4)

**Ticket:** atlas/PRDV-16313 — emit `callisto.client-access.file.renamed.v1` on deliverable rename
**Repo:** `callisto-back-end` · branch to cut: `PRDV-16313` (from fresh `main`)
**Planned from artifacts only. No re-investigation.**

> This file previously held the **Phase 1 recon-and-plan**. That document was approved, saved verbatim to `docs/atlas/PRDV-16313/investigations/PRDV-16313-recon-and-plan.md`, and frozen — it is not lost by this overwrite. This is the Phase 4 implementation plan, and it will be saved verbatim to `docs/atlas/PRDV-16313/PRDV-16313-implementation-plan.md` at Phase 5's first action, then frozen.

## Context — why this change is being made

Ops users rename client-deliverable files via `PATCH /granting-client-access/file/:fileId`. Callisto updates `files.file_name` and tells nobody. Dione (Planet Portal) holds its own copy of the filename from when the file was first shared, so the client keeps seeing the pre-rename name — indefinitely, with no error anywhere. This is the second of ten sibling producer tickets under epic PRDV-15736; the first (PRDV-16312, `file.created.v1`) shipped the pattern this follows.

**Problem class:** a missing event on an existing write path. The write is correct; only the announcement is absent. So the work is a new emission at an existing seam, and **rename behaviour must not change**.

**Requirement:** a successful rename of a client-deliverable file must produce exactly one durable, correctly shaped record — and **nothing** when the file is not a deliverable, when no rename actually occurred, or when the rename did not commit. The record must not exist for a rename that did not happen, and a rename must not commit without it.

**Solution:** a transaction-owning assembler in `granting-client-access` delegates the rename to the unchanged `ProceedingAggregator`, then writes the outbox row through the existing `CLIENT_ACCESS_OUTBOX` port **inside the same transaction**.

## Two gates to record before any code

1. **`P5.spec-approved` is WAIVED** — authorised by Dustin Thomason, explicitly, 2026-08-11. Larry Adams has not reviewed the addendum; `specs/PRDV-16313-addendum-draft.md` is unsubmitted and nothing is pushed to `larry-adams`. Record the waiver in the ledger at Phase 5 step 1 with its authoriser, date, and the residual risk below.
2. **Two behaviours ship as recorded assumptions, not settled facts:**

| Assumption | If Larry disagrees | Cost |
| --- | --- | --- |
| **LD-018** — a successful **no-op** rename emits nothing (AC1 literally says it should) | The no-op guard inverts | Small: delete one guard, flip EC-1's expectation |
| **LD-019** — deliverability checked at **request entry** only, not re-established inside the transaction | Add a fresh in-transaction read + row locking + a decision on what happens when the answer flips mid-request | **The more expensive one.** New query inside the boundary, new branch, new tests |

Also live: **PRDV-16312 is still gated on Larry's `larry-adams` PR #34.** If that response changes payload conventions, decisions here are affected.

## Ordered steps

Each step names its artifact source and the criterion it serves. Nothing here re-derives a decision.

| # | Step | Files | Traces to |
| --- | --- | --- | --- |
| **0** | **Pre-flight.** `git fetch && git checkout main && git pull --ff-only`, then `git checkout -b PRDV-16313`. Confirm `node_modules` is usable (`npm ls @planetdepos/orbital-docking-protocol` → expect `1.0.7`) — PRDV-16312 left it emptied once and only found out at the gate. | — | `new-branch-get-started.md`; ledger hazard note |
| **1** | Save this plan verbatim to `docs/atlas/PRDV-16313/PRDV-16313-implementation-plan.md`; freeze it. Update the ledger: Phase 4 `done`, Phase 5 `in-progress`, **plus the `P5.spec-approved` waiver record.** | ticket folder | orchestrate `P5.plan-saved`, `P5.spec-approved` |
| **2** | **Validator returns its context.** `apply(fileId): Promise<void>` → `Promise<ProceedingFileRenameProjection>`, add `return fileContext;`. Guards, exception types, messages and order untouched. JSDoc the return so callers know not to re-read. | `granting-client-access/validators/proceeding-file-must-be-deliverable.validator.ts` | LD-009 · spec §8 |
| **3** | **Converter input type.** `{ fileId, proceedingId, fileName, renamedUserIdentity, renamedAt: Date }`, all `readonly`. Narrow structural type — **not** the TypeORM entity. | `.../rename-deliverable-file-assembler/file-renamed-outbox-converter/file-renamed-outbox-converter.input.ts` | LD-007 · spec §8 |
| **4** | **Converter.** `@Injectable()`, `apply(input): CallistoClientAccessFileRenamedV1Data` with the ODP type as the **explicit** return type — that is what makes AC2 a compile-time guarantee. `Number()` the ids; `renamedAt.toISOString()`. Comment: payload is a **state snapshot**, which is what makes a deterministic-id overwrite converge (C7). | `.../file-renamed-to-outbox-data.converter.ts` | **AC2** · LD-007, LD-008, C7 |
| **5** | **Params + projection types.** Params `{ fileId, proceedingId, value, renamedUserIdentity }`. Projection `{ message, projection: RenameProceedingFileProjection }` — passes the inner projection through, because the service still needs it for the unchanged audit dispatch. | `.../rename-deliverable-file.params.ts`, `.../rename-deliverable-file.projection.ts` | spec §8 |
| **6** | **The assembler.** Injects `ProceedingAggregator`, the converter, `@Inject(CLIENT_ACCESS_OUTBOX)`, `@InjectLogger`. Method named `apply` so the proxy wraps it. Body: rename → **no-op guard** → one `Date` → `write(...)` with `routeKey: CALLISTO_CLIENT_ACCESS_FILE_RENAMED_V1.eventType` (never a literal), `aggregateType: 'File'`, `aggregateId: String(fileId)`, `rowUpdatedAt` = the same `Date`. **Header comment naming `transaction-scripts-no-aggregators` as why this is an assembler** — so nobody "fixes" it into a TS. | `.../rename-deliverable-file.assembler.ts` | **AC1** · LD-003, LD-011, LD-012 |
| **7** | **Provider — this is the atomicity guarantee.** `useFactory` mirroring `upload-complete-deliverable-file-ts.provider.ts`: construct by hand, `return createTransactionalProxy(instance, transactionContext)`, `inject: [TRANSACTION_CONTEXT_TOKEN, ProceedingAggregator, FileRenamedToOutboxDataConverter, CLIENT_ACCESS_OUTBOX, getLoggerToken(...)]`. **A plain class provider silently loses atomicity and every unit test still passes.** | `.../rename-deliverable-file-assembler.provider.ts` | **LD-005** |
| **8** | **Service delegates.** Swap `ProceedingAggregator` for the assembler. Keep the validator call **first**, now capturing its context for `proceedingId`. Keep `dispatchFileAuditRenamedEvent` **last and outside** the transaction. `renamedUserIdentity: user.identity?.userId ?? user.sub`. | `granting-client-access/domain/services/deliverable-rename-service/deliverable-rename.service.ts` | LD-005, LD-013 |
| **9** | **Wiring.** Registry: add the converter beside `FileCreatedToOutboxDataConverter` + the existing "provided via a transactional proxy" comment for the assembler. Module: add `renameDeliverableFileAssemblerProvider()` to `providers`. **Do not also list the assembler class plainly — that shadows the proxy.** No `imports`/`exports` change. | `registries/transaction-script.registry.ts`, `granting-client-access.module.ts` | spec §Optional callouts |
| **10** | **Self-review against the diff — after the code, before the tests.** Run the checklist in `dustin-thomason/docs/reviewers/pr-review-patterns.md`; any refactor it prompts happens now, while the tests have not yet been shaped around the current code. | — | orchestrate `P5.self-review` |
| **11** | **Tests.** Below. | see test map | AC4 |
| **12** | **Testing-implementation doc** — scenario-first, each change hung off the scenario that forced it (file + observed → expected → fix). PR-comment content, **never** a source comment. | `docs/atlas/PRDV-16313/testing/PRDV-16313-testing-implementation.md` | guardrails §7 |
| **13** | **Changelog session log → gates → commit → push.** Gates in order below. | changelog, then git | `git-commit-workflow` |
| **14** | **Fill the PR draft shell** and open the PR. **No reviewer requested.** | `PRDV-16313-pr-draft.md` | `pull-request-workflow.md` |

**Explicitly not changed:** no ODP change, no migration, no registry allow-list change (`CALLISTO_CLIENT_ACCESS_FILE_RENAMED_V1` pre-registered by PRDV-16293), no action/DTO/guard change, no feature flag. **Zero files under `src/proceedings/**` or `src/proceeding-job-submission/**`.**

## Tests

| Spec file | Covers |
| --- | --- |
| `.../rename-deliverable-file-assembler/__specs__/rename-deliverable-file.assembler.spec.ts` (new) | HP-1, HP-3 (`toBe` identity on the single `Date`), HP-4 (`callOrder` → `['rename','write']`), NP-2, **NP-3a** (propagation only), NP-4, EC-1 (no-op) |
| `.../__specs__/rename-deliverable-file.assembler.integration.spec.ts` (**new — REQUIRED**) | **NP-3b — the only real proof of atomicity.** Real Postgres via `createRepositoryTestContext`. Force the outbox insert to fail, assert `files.file_name` **unchanged** and zero `outbox_events` rows. Cheapest injection: point the writer at an unknown routekey so `ClientAccessOutboxWriter` throws inside the boundary |
| `.../file-renamed-outbox-converter/__specs__/file-renamed-to-outbox-data.converter.spec.ts` (new) | HP-2 — exactly five contract fields, ISO-8601, id coercion. No converter integration spec (no bigint here) |
| `deliverable-rename.service.spec.ts` (modify) | HP-5 (audit payload assertions stay **byte-identical**), EC-2 (`sub` fallback), NP-1 (**AC3**) |
| `proceeding-file-must-be-deliverable.validator.spec.ts` (modify) | Returns the context; existing 404/403 tests stay byte-identical |
| **Unmodified, must pass** | `rename-proceeding-file.transaction.script.spec.ts`, `proceeding.service.spec.ts`, `job-submission.service.spec.ts` — the neighbour proof |

**NP-3b is the load-bearing test.** A mocked suite cannot see a transaction. **If it cannot be run, report atomicity as unproven — do not infer it from NP-3a passing.**

## Shipping-checklist obligations, named up front

- **Tests added** — the four spec files above; NP-3b is not optional.
- **Regression** — isolating boundary is the **module**: zero files outside `granting-client-access`, so the shared rename TS keeps four deps and no outbox port and is *incapable* of emitting. Verify with `git diff --name-only`.
- **API docs** — **not relevant**, and name the surface checked: route path/method, both DTOs, status codes, `@UseGuards`, and `RenameDeliverableFileSwagger()` — all unchanged.
- **Gates**, in order, from `callisto-back-end`: `npm audit --audit-level=high` → `npm run lint` → **`npm run test:architecture`** → `npm test -- --runInBand`. The architecture gate is not boilerplate — two `severity: 'error'` rules selected this design and it closes assumption **A6**.
- **Conflicts / exceptions** — the `P5.spec-approved` waiver, and LD-018/LD-019 shipping as assumptions.

## Verification (end to end)

1. Gates above, all four, reported with exact command + scope + result.
2. **Manual, per the test plan M-1…M-5** — start Callisto locally (`docs/atlas/local/callisto-local.mdc`), take a baseline row count, then: rename a deliverable (**M-1**, one row, five fields, extension preserved); rename again (**M-2**, two *distinct* ids); rename to the same name (**M-3**, **no** new row, `updated_at` unchanged); rename a submission file via `PATCH /proceedings/file/:fileId` (**M-4**, zero rows); **M-5 fault injection** — `REVOKE INSERT ON callisto.outbox_events`, attempt a rename, confirm **`file_name` did not change**, then `GRANT` back.
3. **Nothing changes in the Atlas UI.** Evidence is the SQL result grid, not a screenshot of the app.
4. **Demonstrate A3** (duplicate deterministic id → silent UPDATE) against real Postgres, or state in the PR that it remains source-inspected and unobserved. **Do not assert it as fact otherwise.**
