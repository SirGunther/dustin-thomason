# PRDV-16313 — Recon and plan (orchestrate Phase 1)

**Ticket:** atlas/PRDV-16313 — emit `callisto.client-access.file.renamed.v1` on deliverable file rename
**Implementation repo:** `callisto-back-end` (branch to cut: `PRDV-16313`)
**Authority:** `larry-adams/systems/neptune/callisto/granting-client-acess/epic-PRDV-15736-.../PRDV-16313-endpoint-file-renamed.md` + `dione-file-access-event-design.md`
**Phase 1 status:** recon complete; this document is the approved plan, saved verbatim to `docs/atlas/PRDV-16313/investigations/PRDV-16313-recon-and-plan.md` at Phase 2's first action and frozen thereafter.

---

## Context — why this change is being made

Ops users rename client-deliverable files in Callisto via `PATCH /granting-client-access/file/:fileId`. Dione (Planet Portal) holds its own copy of the filename, populated when the file was first shared. Nothing tells Dione the name changed, so the client keeps seeing the name the file had at share time — indefinitely, with no error anywhere. This ticket closes that by writing a `callisto.client-access.file.renamed.v1` row to Callisto's outbox on a successful deliverable rename; a separate dispatcher (shipped by PRDV-16293) publishes it.

**Problem class: a missing event on an existing write path.** Not a logic bug, not a data-model gap — the write happens correctly and simply announces nothing. That class matters because it sets where the work goes (a new emission at an existing seam, not a change to rename behavior) and what the risks are (emitting on the wrong path, emitting when nothing was written, and the emission being lost after the write commits).

This is the second of ten sibling endpoint tickets under epic PRDV-15736. The first, PRDV-16312 (`file.created.v1`), shipped the house pattern this follows.

**Verdict: proceed.** No blockers. The ODP contract and the routekey allow-list already exist, so the change is confined to one module.

---

## What the spec gets right, and the three places it is wrong

The user's stated intent is to build to the authored spec exactly and surface any reason not to. All four acceptance criteria are correct and are met literally. The **Technical Design** section rests on one false premise and two silences.

### Wrong 1 — the emit site the spec names does not exist, and cannot be wired as instructed

The spec says: *"Inject `CLIENT_ACCESS_OUTBOX` port into the rename transaction script"* and *"Trigger: `RenameDeliverableFileAction` / its transaction script."*

There is no rename transaction script in `granting-client-access`. The actual chain:

```
RenameDeliverableFileAction              granting-client-access/application/.../rename-deliverable-file.action.ts:17
  → DeliverableRenameService.rename      granting-client-access/domain/services/deliverable-rename-service/
      → ProceedingFileMustBeDeliverableValidator.apply   (403s non-deliverables — runs FIRST)
      → ProceedingAggregator.renameProceedingFile        proceedings/domain/aggregators/proceeding.aggregator.ts:129
          → RenameProceedingFileTS.apply                 proceedings/domain/transaction-scripts/rename-proceeding-file-ts/
              → ProceedingFileRepository.updateFileName  proceedings/infrastructure/repositories/proceeding-file.repository.ts:133
      → ProceedingFileAuditAggregator.dispatchFileAuditRenamedEvent   (SQS, after the write)
```

Three independent blockers on the literal instruction:

1. **Module cycle.** `CLIENT_ACCESS_OUTBOX` is declared and provided by `GrantingClientAccessModule`, which already imports `ProceedingsModule`. `proceedings.module.ts` does not import back. Injecting the port into `RenameProceedingFileTS` inverts the epic's dependency direction.
2. **The payload cannot be built there.** `apply(fileId, newValue)` has no user, and `renamedUserIdentity` is non-nullable in the contract.
3. **Blast radius.** `RenameProceedingFileTS` is shared by three HTTP surfaces, so emitting there fires for submission files too.

**And the obvious adaptation — a new `RenameDeliverableFileTS` in `granting-client-access` that delegates to the aggregator — is also illegal.** `fitness-functions-rules/architecture-rules/transaction-scripts.rules.ts` enforces `transaction-scripts-no-aggregators` at **`severity: 'error'`**: a `*.transaction.script.ts` may not import `.*aggregator.*`. It would fail `test:architecture`. `services.rules.ts` likewise enforces `services-no-converters`, so the service cannot hold the payload converter either.

**The one legal shape is an assembler.** `assemblers.rules.ts` forbids assembler → assembler / transaction-script / service / mapper, and nothing else. Assembler → aggregator, → converter, → port are all permitted. `src/granting-client-access/domain/assemblers/` already exists, and `createTransactionalProxy` on a non-transaction-script has precedent (`src/proceedings/providers/persist-video-transcode-derivative-mapper.provider.ts`).

> Honest cost: an assembler that owns a transaction and orchestrates a command is a transaction script wearing a different suffix. That is forced by the fitness rules, not chosen. The alternative — a real TS that forks the rename rules (extension preservation, lineage, duplicate-name validation) — is strictly worse: two writers of `files.file_name` with two copies of the rule. A header comment must name the constraint so the next reader does not "fix" it into a TS.

### Wrong 2 — the spec is silent on atomicity, and the rename path has none

`RenameProceedingFileTS` is not `@Transactional()` and has no provider; `DeliverableRenameService` is a plain provider. The single `UPDATE` autocommits. Emit naively and the failure mode is: **rename commits, outbox write throws, the client's filename is stale forever, no error is recorded, and design Q5 forbids the projection-driven reconciler that would repair it.** That is the exact defect this ticket exists to fix, reintroduced by the fix.

The shipped sibling does not have this problem — `file.created.v1` is written inside the file-insert transaction under `@Transactional()`.

Verified that the transaction actually reaches the outbox: `OutboxEventRepository.activeRepoForCreate()` calls `TYPEORM_OUTBOX_REPOSITORY_RESOLVER`, which `src/typeorm/outbox-transaction-context.module.ts` binds `@Global` to our `TransactionContext`. All file repositories resolve through the same context. So one boundary opened on the assembler covers the pre-read, the `UPDATE`, and the outbox `INSERT`.

### Wrong 3 — the spec is silent on the deterministic event id, and a collision is a silent overwrite

`ClientAccessOutboxWriter` derives the outbox PK as uuidv5 over `runnerName|aggregateType|aggregateId|rowUpdatedAt.getTime()|eventType`. `OutboxEvent.id` is `@PrimaryColumn({type:'uuid'})` — **not generated** — and `OutboxEventRepository.create` ends in `repo.save()`. TypeORM loads by PK, finds the row, and **UPDATEs** it: no exception, no log. `file.created.v1` never exercised this because a file is created once. **Rename is the first repeatable event on aggregate `File`.**

Why this is tolerable rather than a blocker: `CallistoClientAccessFileRenamedV1Data` is a **state snapshot** (`fileName`, no `previousFileName`), so last-writer-wins converges on the correct final name, and both writes land far inside the relay poll interval so nothing was published. Two things must be written down rather than assumed: the snapshot nature is what makes the argument hold (a future `v2` adding `previousFileName` breaks it), and `ON CONFLICT DO NOTHING` would be **worse**, keeping the stale first payload.

---

## Decisions taken from the user this phase

**The AJSF surface is recorded as a concern, not fixed here.** `PATCH /<ajsf>/file/:fileId` (`rename-ajsf-proceeding-file.action.ts` → `JobSubmissionService.renameProceedingFile`) reaches the shared rename TS with **no `@VerifiedUserDecorator()`, no deliverable/submission validator, and no audit dispatch**, so it can rename a `CLIENT_DELIVERABLE` file with no event and no audit trail. The design doc's coverage audit only enumerated `granting-client-access` writes, which is why the spec does not mention it.

User's ruling: *"There should be no circumstance where a file from the user could be renamed once it is submitted… Once it is declared a client deliverable, there would be no reason for a user to ever change the name."* So the workflow does not produce this, and it is surfaced as a caution/possible defect rather than bundled into this ticket. → concerns artifact + follow-up, and an epic-level note to re-run the coverage audit across `proceedings` and `proceeding-job-submission` before the remaining five events ship, since the same hole class likely repeats.

**Timestamp is generated at the emit site** — one `Date`, used for both `renamedAt` and `rowUpdatedAt`, so they agree with each other by construction. Rationale: minimal blast radius. Threading the persisted instant out of `updateFileName` would ripple into `src/proceedings` (repository signature, projection, TS, ~13 spec edits) and widen what the AJSF endpoint returns. Both values are reads of the *same process clock* a few milliseconds apart — `updateFileName` mints `new Date()` in app code, not a DB `now()` — so there is no source-of-truth difference to preserve, only a few ms of precision on a field nothing recomputes. Design Q5 forbids the projection-driven path that would ever re-derive the id from the row.

---

## The plan

**Every file touched is under `src/granting-client-access/`. Zero files under `src/proceedings/` or `src/proceeding-job-submission/`.** That is the neighbor-protection proof for surfaces B and C: `RenameProceedingFileTS` keeps its four dependencies and no outbox port, so those routes remain structurally incapable of emitting, and `RenameProceedingFileProjection` is unchanged so no response body shifts.

### Step 1 — `proceeding-file-must-be-deliverable.validator.ts` (modify)

`src/granting-client-access/validators/proceeding-file-must-be-deliverable.validator.ts`

Change `apply(fileId): Promise<void>` → `Promise<ProceedingFileRenameProjection>` and `return fileContext;`. Guards, exception types, messages and order untouched.

This is how `proceedingId` reaches the payload **without any new query**. The validator already loads the projection (`{file, proceedingId, trackTypeId, isDeliverable}`) via `fetchProceedingFileForRename` and currently throws it away. The type comes from the file the validator already imports. JSDoc the return so callers know not to re-read.

> Convention drift, stated: every other validator in the repo returns `void`. Accepted because the alternative (widening the shared `proceedings` projection) is exactly the blast radius the user ruled against. Fallback if a reviewer rejects it: extend `RenameProceedingFileProjection` instead.

### Step 2 — payload converter (new, 2 files)

`src/granting-client-access/domain/assemblers/rename-deliverable-file-assembler/file-renamed-outbox-converter/`

- `file-renamed-outbox-converter.input.ts` — narrow structural type, **not** the TypeORM entity: `{fileId, proceedingId, fileName, renamedUserIdentity, renamedAt: Date}`, all `readonly`.
- `file-renamed-to-outbox-data.converter.ts` — `@Injectable()`, `apply(input): CallistoClientAccessFileRenamedV1Data` with the ODP type as the **explicit** return type. That is what makes AC2 a compile-time guarantee. `Number()` the ids (parity with the created converter); `renamedAt: input.renamedAt.toISOString()`. Comment recording that the payload is a state snapshot and that this is what makes deterministic-id overwrite convergent.

Mirrors `.../upload-complete-deliverable-file-ts/file-created-outbox-converter/` exactly.

> The design doc's Diagram ④ (`:740-747`) sketches `previousFileName` + `newFileName`. The shipped ODP contract has a single `fileName` and the ticket annotates it "the new name". **The package wins; the diagram is stale.** Do not add `previousFileName`.

### Step 3 — the assembler (new)

`.../rename-deliverable-file-assembler/rename-deliverable-file.assembler.ts`

Injects `ProceedingAggregator`, `FileRenamedToOutboxDataConverter`, `@Inject(CLIENT_ACCESS_OUTBOX) ClientAccessOutboxPort`, `@InjectLogger`. Method named `apply` so the proxy wraps it.

```
apply({ fileId, proceedingId, value, renamedUserIdentity }):
  1. const { message, projection } = await aggregator.renameProceedingFile(fileId, value)
  2. if (projection.fileName === projection.previousFileName) return { message, projection }   // no-op: nothing was written
  3. const renamedAt = new Date()
  4. await clientAccessOutbox.write({
       routeKey: CALLISTO_CLIENT_ACCESS_FILE_RENAMED_V1.eventType,   // never a literal
       payload: converter.apply({ fileId, proceedingId, fileName: projection.fileName, renamedUserIdentity, renamedAt }),
       aggregateType: FILE_AGGREGATE_TYPE,
       aggregateId: String(fileId),
       rowUpdatedAt: renamedAt,
     })
  5. return { message, projection }
```

**Step 2 is the no-op guard and it is not optional.** `RenameProceedingFileTS.apply:39-46` recomputes `newFileName` and, when it equals the current name, returns early **without issuing an `UPDATE`**. Emitting there would assert a rename that did not happen, with an id built from a stale timestamp. `fileName === previousFileName` is exact, not coincidental — it is literally the TS's early-return condition. Comment it as coupled to that branch and pin it with a test.

### Step 4 — provider (new)

`.../rename-deliverable-file-assembler/rename-deliverable-file-assembler.provider.ts`

`useFactory` mirroring `upload-complete-deliverable-file-ts.provider.ts`: construct by hand, `return createTransactionalProxy(instance, transactionContext)`, `inject: [TRANSACTION_CONTEXT_TOKEN, ProceedingAggregator, FileRenamedToOutboxDataConverter, CLIENT_ACCESS_OUTBOX, getLoggerToken(...)]`.

**The proxy is the atomicity guarantee.** A plain class provider silently loses it and every test still passes.

### Step 5 — `deliverable-rename.service.ts` (modify)

Swap `ProceedingAggregator` for `RenameDeliverableFileAssembler`. Keep the validator call **first** (it is the HTTP 403 gate and the tag guard), now capturing its returned context for `proceedingId`. Keep `dispatchFileAuditRenamedEvent` **last and outside** the assembler's transaction.

`renamedUserIdentity: user.identity?.userId ?? user.sub` — the defensive form used by the two most recent same-module siblings (`approve-deliverable-files-v2.service.ts:65`, `recategorize-deliverable-files.service.ts:27`). `AuthUser.identity` is genuinely optional and the contract field is non-nullable; `sub` is always present.

The audit dispatch stays outside deliberately: `ProceedingFileAuditDispatcher` is an **SQS send**, not rollbackable. Pulling it in would hold a DB transaction across a network round trip and would newly make an SQS outage roll back renames — a behavior regression on a path this ticket must not change.

### Step 6 — wiring (modify, 2 files)

- `src/granting-client-access/registries/transaction-script.registry.ts` — add `FileRenamedToOutboxDataConverter` beside `FileCreatedToOutboxDataConverter`, with the existing "provided via a transactional proxy in the module's providers section" comment convention for the assembler.
- `src/granting-client-access/granting-client-access.module.ts` — add `renameDeliverableFileAssemblerProvider()` to `providers`. **Do not** also list the assembler class plainly; that would shadow the proxy. No `imports` change (`ProceedingsModule` already there), no `exports` change.

### Explicitly not changed

No ODP change (contract ships in `@planetdepos/orbital-docking-protocol@1.0.7`). No registry allow-list change (`CALLISTO_CLIENT_ACCESS_FILE_RENAMED_V1` pre-registered by PRDV-16293). No migration. No action / DTO / guard change. No feature flag — `granting-client-access` does not gate its outbox writes and the shipped `file.created.v1` is unflagged; flagging one of seven events and not the other is worse than flagging none.

---

## Verification

**Tests** — `src/test-utils/test-utils` helpers (`createMock`, `createApplyMock`), port overridden on the `CLIENT_ACCESS_OUTBOX` Symbol, logger via `getLoggerToken(...)` + `createMockLoggerPort()`, `describe('given:')` / `describe('when:')` / `test('then:')`.

`.../rename-deliverable-file-assembler/__specs__/rename-deliverable-file.assembler.spec.ts` (new — primary):
- one `write` with `{routeKey: 'callisto.client-access.file.renamed.v1', aggregateType: 'File', aggregateId: String(fileId), rowUpdatedAt: expect.any(Date)}` — **AC1**
- converter receives the **new** `fileName` and the `proceedingId` from the validator context — **AC4**
- `payload.renamedAt` and `rowUpdatedAt` are the **same instant** (`toBe`) — pins the single-`Date` decision so a later edit cannot desync payload from event id
- no emit when the name is unchanged — the no-op branch
- no emit when the aggregator rejects
- emit ordering via `callOrder` → `['rename','write']` (mirrors the created spec's `:688-711`)
- a failed `write` propagates and is not swallowed, so the proxy rolls the `UPDATE` back

`.../file-renamed-outbox-converter/__specs__/file-renamed-to-outbox-data.converter.spec.ts` (new): plain `new Converter()`, exactly the five contract fields, ISO-8601 `renamedAt`, id coercion. **No integration spec** — the sibling has one only because `files.file_size` is `bigint`; every numeric here is an `integer` column. Deliberate departure, stated so it does not read as an omission.

`.../deliverable-rename-service/__specs__/deliverable-rename.service.spec.ts` (modify): delegates to the assembler; audit payload assertions unchanged (behavior-preservation proof); identity falls back to `sub` when `identity` is absent; audit dispatched **after** the assembler returns; no emit when the validator rejects — **AC3**.

`.../validators/__specs__/proceeding-file-must-be-deliverable.validator.spec.ts` (modify): add "returns the loaded rename context"; existing 404/403 tests stay byte-identical.

**Neighbor protection:** `git diff --name-only` must show nothing under `src/proceedings/**` or `src/proceeding-job-submission/**`, and these pass unmodified — `rename-proceeding-file.transaction.script.spec.ts`, `proceeding.service.spec.ts`, `job-submission.service.spec.ts`.

**Gates** (per `git-commit-workflow`, in order, from `callisto-back-end`): `npm audit --audit-level=high` → `npm run lint` → `npm run test:architecture` (the enforcement for the fitness rules this design turns on) → `npm test -- --runInBand`.

**Manual:** rename a deliverable in dev, then
`select id, event_type, aggregate_type, aggregate_id, data from outbox_events where event_type = 'callisto.client-access.file.renamed.v1' order by created_at desc limit 2;`
Confirm five payload fields, `aggregate_type = 'File'`, `aggregate_id` = the file id. Rename again → **two distinct ids**. Rename a *submission* file via `PATCH /proceedings/file/:fileId` → **zero** new rows. (RabbitMQ is descoped epic-wide; the obligation ends at the row.)

---

## Phase 2 emission todos

1. Save this document verbatim to `investigations/PRDV-16313-recon-and-plan.md`; freeze it.
2. Write `investigations/PRDV-16313-investigation.md` from the report template — verdict **proceed**; problem class *missing event on an existing write path*, not reframed; the three spec defects as the load-bearing findings; assumptions ledger (below); software-lens reconcile (contract alignment = ODP 1.0.7 + the allow-list; surface enumeration = four routes, completeness established by two `files.file_name` writers and no bulk endpoint; protect-the-neighbors = zero files outside the module; detection gap = no test could have caught a missing emission on a path that never had one; red→green = the assembler spec's AC1 case; repro recipe = rename a deliverable in dev and query `outbox_events`).
3. Materialize `investigations/PRDV-16313-coverage-ledger.md` — Consulted line first (PRDV-16312 areas 1/2/3/8/9/10 reused: outbox writer, event registry, port, wiki+design authority, dependency state, test surface; **area 9 reopened and corrected** — 16312 recorded `node_modules` emptied, verified fully populated, 823 entries), then the ten new areas traversed this phase, then the frontier.
4. Produce `investigations/PRDV-16313-diagrams.md` — current-vs-target of the rename chain showing where the transaction boundary appears; a sequence for the collision/overwrite case; N/A for kinds skipped.
5. Create `PRDV-16313-why-these-changes.md` with the Phase 1 why-log entry (obvious: a write with no announcement. Not obvious: that the spec's named emit site does not exist, that the only obvious adaptation is forbidden by a fitness rule, and that a duplicate outbox id is a silent overwrite rather than an error).
6. Create `PRDV-16313-future-development-concerns.md` — C1 the AJSF hole with the user's workflow ruling; C2 the extensionless-filename defect (`rename-proceeding-file.transaction.script.ts:37-38`: `lastIndexOf('.')` returns `-1`, `substring(-1)` clamps to `0`, so the whole old filename is appended — this ticket makes it *visible to Dione* without causing it); C3 the assembler-as-transaction-script naming forced by the fitness rules; C4 the `renamedAt`-vs-`files.updated_at` few-ms drift; C5 the epic-level coverage-audit gap; C6 `fetchProceedingFileForRename` running twice per request; C7 the snapshot-payload dependency in the collision argument.
7. Seed `testing/PRDV-16313-test-plan.md` from report §9, each scenario naming the criterion it exercises.
8. Stage `PRDV-16313-pr-draft.md` — **shell only**, headings and empty placeholders.
9. Apply the staged story reconcile (below) with a Phase 1 Story log entry on each story touched.
10. Append a Phase 2 changelog session-log entry to `docs/atlas/PRDV-16313-changelog.md`.

## Staged story reconcile

**Closed by evidence:** `01.Q4` (rename mutates `file_name` + `updated_at` only — `updateFileName:133-138`); `01.Q5` (contract is 5 fields, sufficient for criterion 6); `01.Q6` (PRDV-16293 merged, PR #399 `43ad3dea`, ancestor of the current branch); `01.Q8` (a no-op rename writes nothing, so it must not emit — the code already decides this); `01.Q9` (**four** rename surfaces, three sharing one TS — story 01 criterion 1 is only partly satisfied by this ticket; see C1); `02.Q3` (`CLIENT_DELIVERABLE` is the sole condition, enforced by `ProceedingFileMustBeDeliverableValidator`); `02.Q4` (tags are **not** loaded on the entity — no inverse relation exists — but the flag is already computed twice per request, so no new read); `02.Q5` (tag is mutable both ways; removal requires a co-existing `Submission File` tag).

**Still open, genuinely:** `01.Q1` / `02.Q1` (user types), `01.Q2` (observability boundary — sharpened by the RabbitMQ descope), `01.Q3`, `01.Q7` (latency — design Q18 says seconds, no ordering), `02.Q2` (consumer-side, Dione's), `02.Q6` (degradation when the tag read fails).

**Criterion pressure to resolve at Phase 3:** story 01 criterion 1 says *"when someone changes the name of a file the client has been given, the client sees the new name."* Given C1, that is true for the deliverable endpoint and false for the AJSF route. The criterion needs rewording to what this ticket actually makes true — **without** reinterpreting it to match what was built.

## Assumptions to carry into the report

| # | Claim | Status | How to confirm/refute |
| --- | --- | --- | --- |
| A1 | Emitting from the shared TS is impossible, not merely inadvisable | **confirmed** | Module import direction + `transaction-scripts-no-aggregators` at `severity: 'error'` |
| A2 | The outbox write enlists in our transaction | **confirmed** | `activeRepoForCreate()` → `TYPEORM_OUTBOX_REPOSITORY_RESOLVER`, bound `@Global` in `outbox-transaction-context.module.ts` |
| A3 | A duplicate deterministic id silently UPDATEs | **confirmed directionally** | `repo.save()` on a non-generated uuid PK. Owes a real-Postgres demonstration before being asserted in the PR |
| A4 | `fileName === previousFileName` is an exact no-op signal | **confirmed** | It is the TS's own early-return condition (`:39-46`) |
| A5 | Widening `RenameProceedingFileProjection` would widen the AJSF response body | **open** | Agent-reported (`JobSubmissionService` declares `{message}` but returns `{message, projection}`). Moot under the chosen plan; verify only if the fallback is taken |
| A6 | An assembler owning a transaction passes every fitness rule | **confirmed directionally** | Read all four assembler rules. Owes an actual `npm run test:architecture` run |
