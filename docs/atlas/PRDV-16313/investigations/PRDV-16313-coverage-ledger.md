# Coverage ledger — atlas/PRDV-16313

Investigation question: **where can a `file.renamed.v1` event legally and safely be emitted for a client-deliverable rename, and what does the current rename path fail to guarantee?**
Repo(s): `callisto-back-end`, `larry-adams` (spec source) · Baseline: branch `PRDV-16312`, working tree dirty only in `.swcrc`, `notification-template-preview.html`, `package-lock.json`, untracked `scripts/` — none on the rename path · Started: 2026-08-11

## Consulted

Searched `docs/**/investigations/*-coverage-ledger.md` for the subsystems in play — "rename", "outbox", "client-access", "file_tag", "CLIENT_DELIVERABLE", "deliverable", "routekey", "callisto", "dione", "transaction". **Eight ledgers found; one matched substantively, two matched marginally.**

- **`docs/atlas/PRDV-16312/investigations/PRDV-16312-coverage-ledger.md` — found, heavily reused, one reopen.** The direct sibling: same epic, same outbox, same module, same authority documents. Reused **without re-deriving**:
  - its **area 1** (the `ClientAccessOutboxWriter` mechanism — `write()` params, `BadRequestException` on unknown routekey, runner name `'granting-client-access-command'`, id via `DeterministicEventIdHelper`, payload passed through with no shape validation);
  - its **area 2** (the event registry — all seven contracts pre-registered, keyed by `contract.eventType`; it explicitly noted `FILE_RENAMED` present, which is why this ticket needs no registry change);
  - its **area 3** (the port as the domain/infrastructure seam and why the Symbol-token indirection exists);
  - its **area 8** (`larry-adams` as the authority; design Q5 command-driven, Q18 eventual-consistency/seconds/no-ordering, Q25 *"ClickUp stays wiki-pointer"*);
  - its **area 10** (the spec/test conventions — `createMock`/`createApplyMock` from `src/test-utils`, Symbol-token override, `given:/when:/then:`, the `callOrder` ordering test).
  - **Reopened its area 9 (dependency state) under condition 2 — *the underlying state changed since inspection*.** That ledger records `callisto-back-end/node_modules` as "emptied by this run and not restored", blocking all its Phase 5 gates. **Verified false now:** `node_modules` is fully populated (823 entries) and `@planetdepos/orbital-docking-protocol@1.0.7` is present and readable on disk. Correction recorded; the sibling's note is stale, not wrong-at-the-time.
  - **Also inherited as a process fix, not a finding:** that ledger's own note *"`larry-adams` must be a Phase 1 input when the ticket names a wiki path."* Applied — the wiki spec was read at Phase 1 here (area 8 below), which is what surfaced the three Technical Design defects.
- **`docs/atlas/PRDV-16402/investigations/PRDV-16402-coverage-ledger.md` — found, not reopened.** Matched on "file_tag" (its area on `file-attachments-file-tags.repository.ts` naming precedents) and on the outbox writer pattern, but that content reaches this ticket second-hand through PRDV-16312's reuse of it. Its own open item — `orbital-relay-pkg` duplicate-id semantics, which PRDV-16312 reopened and also left open — **is closed in this pass** (area 3 below). Nothing else reusable.
- **`docs/atlas/PRDV-16192/investigations/PRDV-16192-coverage-ledger.md` — found, not reopened.** Matched only on "deliverable"/"callisto" in an RBAC resource-key context. `CLIENT_DELIVERABLE_PROCEEDING_FILES_*` are resource keys, not file tags — a name collision, different subsystem. Nothing reused, nothing re-derived.
- **`docs/atlas/PRDV-14055/`, `docs/nova/**`, `docs/Jaimie/**`, `docs/ClickUpWideLayout/**` — no match.**
- **`docs/atlas/PRDV-16313/` prior artifacts:** the Phase 0 capture, ledger and two job stories only. No prior investigation.

## Areas examined

### 1. `callisto-back-end` — the rename HTTP surface and its service (the candidate emit site)

| Field | Value |
| --- | --- |
| Inspected | `rename-deliverable-file.action.ts` in full (31 lines); `rename-deliverable-file.request.dto.ts`; `update-deliverable-file-auth.guard.ts`; `deliverable-file-authorize-role.ts`; `deliverable-rename.service.ts` in full (40 lines); `deliverable-rename.command.ts`; module registration |
| Findings | Route is `PATCH /granting-client-access/file/:fileId`, guard `UpdateDeliverableFileAuthGuard`, `@VerifiedUserDecorator() user: AuthUser`. **Body carries `trackTypeId` beyond the new name — consumed *only* by the guard off `request.body.trackTypeId`, never entering the command**; the transaction script reads the real `trackTypeId` from the DB instead. Service order is validator → aggregator → audit dispatch → return. Registered as a **plain provider** (`granting-client-access.module.ts:76`) — no `useFactory`, **no transactional proxy** |
| Status | fully-inspected |
| Commit | branch `PRDV-16312` · 2026-08-11 |
| Evidence | `…/rename-deliverable-file-action/rename-deliverable-file.action.ts:17-30`; `…/rename-deliverable-file.request.dto.ts:22,31`; `…/guards/update-deliverable-file-auth.guard.ts:18-21`; `…/deliverable-rename-service/deliverable-rename.service.ts:10-39`; `granting-client-access.module.ts:76` |
| Notes | A client-supplied `trackTypeId` driving the permission check without being cross-checked against the file's actual track is a pre-existing smell. **Not this ticket's and not a payload concern** — noted so a later reader does not mistake it for a finding of this pass |

### 2. `callisto-back-end` — `RenameProceedingFileTS` (where the write happens; **not** where the emit can go)

| Field | Value |
| --- | --- |
| Inspected | `rename-proceeding-file.transaction.script.ts` in full (72 lines); `rename-proceeding-file.projection.ts`; `proceeding.aggregator.ts:129-144`; `proceeding-file.repository.ts:133-138`; directory listing of the TS folder |
| Findings | **The spec's named emit site does not exist in `granting-client-access`** — the only rename TS lives in `proceedings`. It is **not `@Transactional()`** and has **no `.provider.ts`**, so the single `UPDATE` autocommits. Its projection is four fields (`bucket`, `filePath`, `fileName`, `previousFileName`) — **no `fileId`, no `proceedingId`, no `updatedAt`** — even though it reads `proceedingId` internally at `:33` and discards it. **Early-return no-op branch at `:39-46`**: when the recomputed name equals the current one it returns with `previousFileName === fileName` and never writes |
| Status | contributing — **the pivotal finding of this pass** |
| Commit | branch `PRDV-16312` · 2026-08-11 |
| Evidence | `…/rename-proceeding-file-ts/rename-proceeding-file.transaction.script.ts:21-71` (no-op `:39-46`, extension logic `:37-38`, discard `:33`); `rename-proceeding-file.projection.ts` in full; `proceeding.aggregator.ts:129-144`; `proceeding-file.repository.ts:133-138`; `ls` of the TS dir shows only `__specs__/`, the projection and the script |
| Notes | Pre-existing defect at `:37-38`: with no dot in the filename `lastIndexOf('.')` is `-1` and `substring(-1)` clamps to `0`, so the **whole old filename is appended** to the new name. This ticket makes it *visible to Dione* without causing it → concern C2 |

### 3. `callisto-back-end` + `orbital-relay-pkg` — the outbox write path and the **deterministic-id collision** (closes a question two prior ledgers left open)

| Field | Value |
| --- | --- |
| Inspected | `client-access-outbox.port.ts` in full; `client-access-outbox.writer.ts` in full; `deterministic-event-id.helper.ts`; `node_modules/@planetdepos/orbital-relay-pkg/dist/.../outbox-event.repository.js` (`activeRepoForCreate`, `create`); `outbox-event.entity.js`/`.d.ts`; `outbox-facade.port.d.ts`; migration `1772165619858-create__outbox_events_table.ts`; `src/typeorm/outbox-transaction-context.module.ts` in full |
| Findings | Two findings, both load-bearing. **(a) The outbox write enlists in our transaction.** `OutboxEventRepository.activeRepoForCreate()` calls `TYPEORM_OUTBOX_REPOSITORY_RESOLVER`, and `outbox-transaction-context.module.ts` is `@Global` and binds that token to our `TransactionContext` — so one boundary opened upstream covers the pre-read, the `UPDATE` and the outbox `INSERT`. **(b) A duplicate deterministic id is a silent UPDATE, not an error.** `OutboxEvent.id` is `@PrimaryColumn({type:'uuid'})` — **not generated** — and `create` ends in `repo.save()`, so TypeORM loads the existing row by PK and updates it, resetting `status`→`PENDING` and `attempts`→`0`, with no exception and no log. The id is uuidv5 over `runnerName\|aggregateType\|aggregateId\|rowUpdatedAt.getTime()\|eventType`, so **`rowUpdatedAt` is the only discriminator between two events for one aggregate** |
| Status | contributing — **closes PRDV-16402 area 12 / PRDV-16312's reopen of it**, both of which left duplicate-id semantics open |
| Commit | branch `PRDV-16312` · ODP/relay from `node_modules` · 2026-08-11 |
| Evidence | `…/domain/ports/client-access-outbox.port.ts:1-13`; `…/writers/client-access-outbox/client-access-outbox.writer.ts:23-48`; `src/typeorm/outbox-transaction-context.module.ts:7-24`; `node_modules/@planetdepos/orbital-relay-pkg/dist/outbox/infrastructure/repositories/outbox-event.repository.js` (`activeRepoForCreate`, `create` → `repo.save`); `dist/outbox/domain/entities/outbox-event.entity.js` |
| Notes | **`file.created.v1` never exercised (b)** — a file is created once. **Rename is the first repeatable event on aggregate `File`**, so this ticket is where the hazard first becomes reachable. Status is *confirmed directionally*: read from library source, **not observed**. Owes a real-Postgres demonstration → report A3, concern C7 |

### 4. `callisto-back-end` — the `file.created.v1` producer (the house pattern to mirror)

| Field | Value |
| --- | --- |
| Inspected | `upload-complete-deliverable-file.transaction.script.ts:29, 42-44, 49, 96-110`; `upload-complete-deliverable-file-ts.provider.ts` in full; `file-created-to-outbox-data.converter.ts` in full (34 lines); `file-created-outbox-converter.input.ts` in full (21 lines); directory shape |
| Findings | `const FILE_AGGREGATE_TYPE = 'File'` as a **private local const** (not exported). Port injected by Symbol. `@Transactional()` on `apply`, so the outbox `INSERT` shares the file-insert transaction. The write sits **immediately after** the repository create, with `rowUpdatedAt: file.updatedAt`. **Routekey is never a string literal in source** — always `<CONTRACT>.eventType`. A dedicated `@Injectable()` converter returns the ODP type **explicitly**, taking a narrow structural input type from a sibling `.input.ts` rather than the TypeORM entity. Provider is a manual `useFactory` with positional ctor args wrapped in `createTransactionalProxy`, registered directly in the module rather than via the registry |
| Status | fully-inspected |
| Commit | `1ec89a83` (`PRDV-16312: Emit file.created.v1 on client deliverable upload`) · 2026-08-11 |
| Evidence | paths + lines above; `git log` shows `1ec89a83`, `e8c149ae`, `0f174f6d`, `d341814c`, `68ff5e03`, `f1d1f6d5` all committed on the branch |
| Notes | The explicit ODP return type is what makes AC2 a **compile-time** guarantee rather than a test assertion. `FILE_AGGREGATE_TYPE` being private means a second producer must duplicate the literal — a drift would silently split the aggregate stream → concern noted in report §7 |

### 5. `callisto-back-end` — architecture fitness rules (**what makes the obvious fix illegal**)

| Field | Value |
| --- | --- |
| Inspected | `fitness-functions-rules/architecture-rules/transaction-scripts.rules.ts` in full; `assemblers.rules.ts` in full; `services.rules.ts` (the converter/mapper/service rules); directory listing of `architecture-rules/` |
| Findings | **`transaction-scripts-no-aggregators` at `severity: 'error'`** — a `*.transaction.script.ts` may not import `.*aggregator.*` (only `.port` excluded). So a new `RenameDeliverableFileTS` delegating to `ProceedingAggregator` **fails `test:architecture`**. **`services-no-converters` at `severity: 'error'`** — a `*.service.ts` may not import `.*\.converter\.ts`, so the service cannot hold the payload converter. `assemblers.rules.ts` forbids **only** assembler → assembler / transaction-script / service / mapper — leaving assembler → **aggregator**, → **converter**, → **port** all permitted |
| Status | contributing — **this is what selected the design** |
| Commit | branch `PRDV-16312` · 2026-08-11 |
| Evidence | `transaction-scripts.rules.ts:26-44` (`transaction-scripts-no-aggregators`); `services.rules.ts:31-36` (`services-no-converters`); `assemblers.rules.ts:11-43` (all four rules) |
| Notes | Found by **verifying a subagent's claim rather than accepting it** — the claim inverted the recommendation of a competing plan, so it was checked against source before being relied on. Reading the rules is not executing them → report A6 owes an `npm run test:architecture` run |

### 6. `callisto-back-end` — transaction machinery and module dependency direction

| Field | Value |
| --- | --- |
| Inspected | `src/typeorm/domain/contexts/transaction-context.ts`; `src/typeorm/infrastructure/services/transaction-context.service.ts:17-25`; `src/typeorm/infrastructure/factories/transactional-proxy.factory.ts:9-47`; `granting-client-access.module.ts` imports/providers/exports; `proceedings.module.ts` imports; every `createTransactionalProxy` call site |
| Findings | ALS-based ambient transactions; `runTransactional` is **re-entrant** (joins an existing context rather than nesting); `createTransactionalProxy` wraps `@Transactional()`-marked methods **or any method literally named `apply`**. All file repositories resolve through `TransactionContext.resolveRepository`, so they **auto-enlist** once a context exists. **`granting-client-access.module.ts` imports `ProceedingsModule` and exports `CLIENT_ACCESS_OUTBOX`; `proceedings.module.ts` has no reciprocal import** — so injecting the port into a `proceedings` provider is a cycle. Eleven `createTransactionalProxy` call sites: ten transaction-script providers **plus `src/proceedings/providers/persist-video-transcode-derivative-mapper.provider.ts`** — precedent for proxying a non-transaction-script |
| Status | fully-inspected |
| Commit | branch `PRDV-16312` · 2026-08-11 |
| Evidence | `transaction-context.service.ts:17-25`; `transactional-proxy.factory.ts:34` (`prop === 'apply'`); `granting-client-access.module.ts:67,99-104`; `proceedings.module.ts:80-99`; `grep -rln createTransactionalProxy` → 11 files |
| Notes | The mapper-provider precedent is what makes a proxied **assembler** a house-consistent shape rather than an invention |

### 7. `callisto-back-end` — the `CLIENT_DELIVERABLE` tag mechanism and the deliverable gate

| Field | Value |
| --- | --- |
| Inspected | `file-tag.entity.ts`; `file-attachments-file-tags.entity.ts`; `file.entity.ts` in full (54 lines); `file-attachment.entity.ts` relations; `proceeding-file.repository.ts:170-197` (`fetchProceedingFileForRename`) and `:219-244` (`checkFileAttachmentHasTag`); `proceeding-file-must-be-deliverable.validator.ts` in full; `proceeding-file-must-be-submission.validator.ts`; every tag add/remove site; migrations `1757427359505`, `1757427626852`, `1757429101594` |
| Findings | `FILE_TAGS.CLIENT_DELIVERABLE = 'Client Deliverable'`, resolved **by string value at runtime, never a hardcoded id**. Tags attach to the **`file_attachments`** row via a join table, and **there is no inverse relation on either `File` or `FileAttachment`** — so `relations: ['fileAttachment']` can never load tags; every check is a separate query. **The endpoint is already deliverable-only**, but by a domain validator (`ForbiddenException` on `!isDeliverable`), *not* by the guard and *not* by any WHERE clause — so **the spec's premise "the rename endpoint may serve non-deliverable files as well" is false**. `fetchProceedingFileForRename` precomputes `isDeliverable` — and **runs twice per request**: once in the validator, which discards the projection and returns `void`, once inside the TS, which destructures it and does not return it. Tag is **mutable both ways** (added on approve, removed on unapprove, removal requiring a co-existing `Submission File` tag) |
| Status | fully-inspected |
| Commit | split introduced by `4d284978` (`PRDV-15776: Split proceeding file rename by deliverable vs submission`) · read at branch `PRDV-16312` |
| Evidence | `file-tag.entity.ts:5-14`; `file-attachments-file-tags.entity.ts:26-46`; `file.entity.ts:20-54`; `proceeding-file.repository.ts:170-197, 219-244`; `proceeding-file-must-be-deliverable.validator.ts:16-27`; `proceeding-file-must-be-submission.validator.ts:22`; `approve-deliverable-files.transaction.script.ts:157-161`; `unapprove-deliverable-files.transaction.script.ts:119-131`; `remove-deliverable-tag.transaction.script.ts:104-107` |
| Notes | The duplicate read is pre-existing and **not** worsened by this design (which consumes the first read's discarded result) → concern C6. Mutability is why deliverable status must be read at rename time, never cached |

### 8. `larry-adams` — the ticket's wiki spec and the design doc (**the authority**, read at Phase 1 this time)

| Field | Value |
| --- | --- |
| Inspected | `PRDV-16313-endpoint-file-renamed.md` in full (93 lines); `dione-file-access-event-design.md` — Q19/Q22 catalog, the `granting-client-access` write-operation audit and its "File rename coverage" decision, Diagram ④ (`:740-747`), the payload sketches at `:1110-1118` and `:1289-1296`, Q5/Q18/Q25, the Status checklist |
| Findings | Frontmatter: authored by Larry Adams, created 2026-07-16, modified 2026-07-20. **The wiki's four acceptance criteria are identical to the ClickUp text** — unlike the sibling ticket, there is no criteria-level conflict. The payload block matches shipped ODP 1.0.7 exactly (five fields). **But the Technical Design is wrong on three counts:** it names a transaction script that does not exist; it justifies its tag guard with a claim the code contradicts; and it is silent on both atomicity and the deterministic event id. Design Q22's coverage audit enumerated **only `granting-client-access` write operations** — never `proceedings` or `proceeding-job-submission` — which is exactly why the AJSF surface is absent from the spec. **Diagram ④ is stale**: it sketches `previousFileName` + `newFileName` where the shipped contract has a single `fileName` |
| Status | fully-inspected |
| Commit | `larry-adams` `main` · 2026-08-11 |
| Evidence | wiki spec `:1-93` (AC `:29-32`, payload `:44-52`, design `:58-79`, testing `:83-87`, `[[dione-file-access-event-design]]` Q22 `:93`); design `:1380-1440` (audit + rename coverage), `:740-747` (Diagram ④), `:1110-1118`, `:1289-1296`, `:1199-1208` (Q22 catalog) |
| Notes | **The ticket's printed `## Wiki` path is dead** — `emit-grant-events/` was renamed to `epic-PRDV-15736-…`; resolved via `git ls-files`. Same defect PRDV-16312 recorded as a vault issue (10 broken links from `systems/README.md`), deliberately unfixed there. Reading this at Phase 1 rather than Phase 2 is the inherited process fix, and it is what surfaced all three Technical Design defects |

### 9. `callisto-back-end` — exhaustive rename-surface enumeration (blast radius)

| Field | Value |
| --- | --- |
| Inspected | `grep -ri "rename"` repo-wide (100 files, migrations and specs excluded); every `updateFileName` definition and call site; every `renameProceedingFile` reference; `.save(`/`.set(` sites touching `fileName`; all `@Patch`/`@Put`/`@Post` in `granting-client-access` actions; `recategorize-deliverable-files.transaction.script.ts`; `merge-case-ts`; bulk/batch rename greps; `rename-ajsf-proceeding-file.action.ts` in full; `job-submission.service.ts:163-171` |
| Findings | **Four HTTP surfaces; three funnel through the single `RenameProceedingFileTS`.** A = the deliverable endpoint (validated, has user, audits). B = `PATCH /proceedings/file/:fileId` (submission-validated, has user, audits). **C = `PATCH /<ajsf>/file/:fileId` — no `@VerifiedUserDecorator()` at all, no deliverable/submission validator, no audit dispatch; can rename a client-deliverable file, bypassing A entirely.** D = `PATCH /cases/file/:fileId`, a separate `CaseFileRepository.updateFileName`, different aggregate. **Completeness:** exactly **two** DB writers of `files.file_name`; **no** bulk/batch rename endpoint exists; recategorize reads `fileName` at `:86` for duplicate validation but never writes it; case-merge computes new names and uses them only as S3 keys |
| Status | fully-inspected |
| Commit | branch `PRDV-16312` · 2026-08-11 |
| Evidence | `rename-ajsf-proceeding-file.action.ts:14-24` (no user decorator); `job-submission.service.ts:163-171`; `rename-proceeding-file.action.ts:16`; `proceeding.service.ts:122-145`; `rename-case-file.action.ts:16`; `case-file.repository.ts:325-333`; `proceeding-file.repository.ts:133`; `recategorize-deliverable-files.transaction.script.ts:86` |
| Notes | Surface C is why **job story 01 criterion 1 is knowingly not fully met** → concern C1, user-ruled out of scope. Also the evidence for concern C5 (the epic's audit never covered two modules) |

### 10. `callisto-back-end` — actor identity and the audit-column gap

| Field | Value |
| --- | --- |
| Inspected | `src/generic/auth/constants.ts:29-45` (`AuthUser`); every `identity?.userId` / `identity.userId` site (20 hits); `base-audit.entity.ts` in full; `proceeding.repository.ts:119`; `proceeding-to-updated-outbox-descriptor.converter.ts:33-37` |
| Findings | `AuthUser.identity` is **optional**; `sub` is always present. **Two conventions coexist:** bare `user.identity.userId` (most sites) and defensive `user.identity?.userId ?? user.sub` — the latter used by the **two most recent same-module siblings** (`approve-deliverable-files-v2.service.ts:65`, `recategorize-deliverable-files.service.ts:27`). Separately: **`File extends BaseAuditEntity`, which declares non-nullable `modified_user_identity`, and `updateFileName` writes neither identity column** — so the row does not record who renamed it, though `proceeding.repository.ts:119` shows updates elsewhere do write it. A parallel fallback pattern exists for update events: `proceeding.modifiedUserIdentity ?? proceeding.createdUserIdentity` |
| Status | fully-inspected |
| Commit | branch `PRDV-16312` · 2026-08-11 |
| Evidence | paths + lines above |
| Notes | The audit-column gap is **why `renamedUserIdentity` must come from request context rather than the row** — a materially useful consequence, not just an observation. The defensive form is chosen because the contract field is non-nullable |

### 11. `callisto-back-end` — spec/test conventions for outbox producers

| Field | Value |
| --- | --- |
| Inspected | `upload-complete-deliverable-file.transaction.script.spec.ts` (745 lines — mock setup, provider overrides, payload fixture factory, the outbox `describe` block, the three negative tests); `client-access-outbox.writer.spec.ts`; both `file-created-to-outbox-data.converter` specs (unit + integration); `src/test-utils/test-utils.ts:76,85`; `rename-proceeding-file.transaction.script.spec.ts:65` |
| Findings | `createMock<ClientAccessOutboxPort>({write: jest.fn()})` and `createApplyMock<Converter>()` from `src/test-utils/test-utils`; port overridden on the **Symbol** token; logger via `getLoggerToken(...)`/string token + `createMockLoggerPort()`; typed payload fixture factory returning the ODP type; `given:/when:/then:` with Arrange/Act/Assert. **The routekey is asserted as a literal in the spec while the source uses the constant** — deliberate, so a constant change cannot silently pass. Three negative tests to mirror: `callOrder` ordering (`['create','write']`), no-emit-when-validator-rejects, no-emit-when-persist-fails. **Converter specs come in pairs** (unit + real-Postgres integration) — but the integration spec exists specifically for the `files.file_size` **bigint-as-string** hazard |
| Status | fully-inspected |
| Commit | branch `PRDV-16312` · 2026-08-11 |
| Evidence | spec `:36,49,101-121,168-172,214-221,529-591,688-741`; `test-utils.ts:76,85`; converter integration spec `:1` (the Postgres precondition comment) |
| Notes | **No integration spec is planned here** — this payload's numerics are `files.id` and `file_attachments.attached_to_id`, both `integer`, so there is no bigint hazard to reproduce. A deliberate departure from the pair convention, recorded so it does not read as an omission |

## Not yet inspected (frontier)

- **Dione's consumer.** Not in this workspace. What it does with an event for a file it has no record of (story `02.Q2`) is unanswerable here, and the RabbitMQ descope removed the observation step that would have shown it. Decides whether concern C1 is a **leak** or merely **noise**.
- **The duplicate-id overwrite, observed rather than read.** Area 3 finding (b) is *confirmed directionally* from library and TypeORM source. A real-Postgres demonstration is owed before it is asserted as fact in the PR → report A3.
- **`npm run test:architecture` actually run.** The assembler shape is legal by reading all four rules; not executed → report A6.
- **`RenameProceedingFileProjection` widening vs the AJSF response body** (report A5). Agent-reported that `JobSubmissionService` declares `Promise<{message}>` but returns `{message, projection}`. **Moot under the chosen design**; verify only if the documented fallback is taken.
- **The relay/dispatcher side.** Poll interval, retry and `FAILED` handling read only as far as needed to argue that a same-millisecond overwrite happens before publication. Not traced end to end — out of scope for a producer ticket.
- **The extensionless-filename defect's blast radius** (C2). Confirmed by reading `:37-38`; not traced to how often real filenames lack an extension, nor whether any upload path can produce one.
- **`trackTypeId` guard mismatch.** Noted in area 1 that the guard authorizes on a client-supplied `trackTypeId` never cross-checked against the file's actual track. Not investigated — pre-existing, unrelated to emission, and deliberately left alone.
- **The other five unbuilt epic events.** Their write paths (approve, unapprove, recategorize, collection-deleted, grants-replaced) were not traced. Concern C5 recommends the coverage audit be re-run across `proceedings` and `proceeding-job-submission` before they ship, since the surface-C hole class likely repeats.
