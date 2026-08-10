# Coverage ledger — atlas/PRDV-16312

Investigation question: **what must be emitted when a file is uploaded straight into client deliverables, from where, and does the event the ticket asks for actually exist?**
Repo(s): `callisto-back-end`, `larry-adams` (read-only spec source) · Baseline commit: `71ce3cbf` (callisto `main`, 2026-08-03) · Started: 2026-08-05

## Consulted

- `docs/*/tickets/*/investigations/*-coverage-ledger.md` + `docs/atlas/PRDV-*/investigations/*-coverage-ledger.md` for "outbox", "dispatcher", "upload-complete", "client-access", "collection", "deliverable", "rabbit", "routekey", "callisto", "dione" — **seven ledgers found; two matched.**
  - `docs/atlas/PRDV-16402/investigations/PRDV-16402-coverage-ledger.md` — **found + reused, plus one reopen.** Reused **without re-reading the code**: the outbox writer/port/converter pattern and `DeterministicEventIdHelper` (its area 5); `OutboxFacade.writeOutboxEvent` taking no manager, transaction participation ambient via ALS (area 5); architecture rules — TS→TS forbidden at `severity: error`, TS→service forbidden, `writers/` **not** path-exempt from `domain-no-infrastructure` hence the port-token indirection (area 9); the `createTransactionalProxy` provider template and module-wiring shape (area 10). **Reopened its area 12** (`orbital-relay-pkg` duplicate-id semantics) under condition 3 — *prior inspection was `partial` for the aspect now in question*: it was read from library + TypeORM source and never observed, and it becomes load-bearing here because this ticket is the outbox's **first** producer. Not closed in this pass either; carried to the frontier.
  - `docs/atlas/PRDV-16192/investigations/PRDV-16192-coverage-ledger.md` — **found, not reopened.** Matched only on "dispatcher"/"deliverable"/"callisto" in an audit-events context (Europa audit projection). Different subsystem and different behavior; nothing reusable, nothing re-derived.
- `docs/atlas/PRDV-16312/` for prior artifacts — only the Phase 0 capture and an unfilled `RABBITMQ_CONFIG_REQUEST_TEMPLATE.md`. No prior investigation.
- **Not consulted at Phase 1, and it should have been:** `larry-adams` — the ticket's own `## Wiki` path. Opened at Phase 2 only after the user asked. It answered the pass's largest open question outright (area 8). Recorded as a process miss in the why-log.

## Areas examined

### 1. `callisto-back-end` — the client-access outbox writer (the emission mechanism)

| Field | Value |
| --- | --- |
| Inspected | `ClientAccessOutboxWriter` in full (49 lines): ctor deps, `write()`, routekey resolution, id derivation, facade call |
| Findings | `write({routeKey, payload, aggregateType, aggregateId, rowUpdatedAt})` resolves the routekey in `CLIENT_ACCESS_EVENT_CONTRACT_BY_ROUTE_KEY` and **throws `BadRequestException` on an unknown key** — so an unregistered routekey is a hard failure, not a silent drop. Runner name `'granting-client-access-command'`. Event id = `DeterministicEventIdHelper.apply({runnerName, aggregateType, aggregateId, rowUpdatedAt, eventType})`. Passes `payload` straight through as `data` — **no shape validation** |
| Status | fully-inspected |
| Commit | `71ce3cbf` · 2026-08-05 |
| Evidence | `src/granting-client-access/infrastructure/outbox/writers/client-access-outbox/client-access-outbox.writer.ts:13, 23-48` |
| Notes | `rowUpdatedAt` is load-bearing for id determinism — same lesson as PRDV-16402 area 5's `fileUpdatedAt` |

### 2. `callisto-back-end` — the event registry (**where `collection.created` is missing**)

| Field | Value |
| --- | --- |
| Inspected | `client-access-outbox-event.registry.ts` in full — import list, array, map construction; then `git log`/`git show` on the file's history |
| Findings | **Seven** contracts registered: `GRANTS_REPLACED`, `FILE_CREATED`, `FILE_APPROVED`, `FILE_RENAMED`, `FILE_RECATEGORIZED`, `FILE_UNAPPROVED`, `COLLECTION_DELETED`. **No `COLLECTION_CREATED`** — the `DELETED`-without-`CREATED` asymmetry is the fingerprint. History shows it was imported and registered, then removed by commit `31c81db4` whose body reads *"Remove collection.created; derive grants aggregate from principalType/principalId."* Map is keyed by `contract.eventType` |
| Status | contributing — **the pivotal finding** |
| Commit | `71ce3cbf` · 2026-08-05 |
| Evidence | `…/client-access-outbox-event.registry.ts:1-30`; `git show 31c81db4 -- '*client-access-outbox-event.registry.ts'` |
| Notes | `FILE_CREATED` **is** registered, so this ticket's actual scope needs no registry change |

### 3. `callisto-back-end` — the outbox port (contract-alignment seam)

| Field | Value |
| --- | --- |
| Inspected | `client-access-outbox.port.ts` in full (13 lines) |
| Findings | `CLIENT_ACCESS_OUTBOX` symbol token; `WriteClientAccessOutboxParams` carries `payload: Record<string, unknown>` and `routeKey: string`. **Deliberately contract-agnostic** — the typed ODP contract is the authority but the port mirrors none of it, so AC "payload matches `CallistoClientAccessFileCreatedV1Data`" has no compile-time guard |
| Status | contributing |
| Commit | `71ce3cbf` · 2026-08-05 |
| Evidence | `src/granting-client-access/domain/ports/client-access-outbox.port.ts:1-13` |
| Notes | Drives report OV-2. Port-token indirection is required because `writers/` is not exempt from `domain-no-infrastructure` (reused, PRDV-16402 area 9) |

### 4. `callisto-back-end` — producers of the client-access outbox (**none**)

| Field | Value |
| --- | --- |
| Inspected | Repo-wide grep for `CLIENT_ACCESS_OUTBOX`, `ClientAccessOutboxWriter`, `ClientAccessOutboxPort`, excluding `__specs__` |
| Findings | **Zero production consumers.** Every hit is the port declaration, the module registration/export, or the writer's own `implements`. Provided as `{provide: CLIENT_ACCESS_OUTBOX, useClass: ClientAccessOutboxWriter}` and exported, but nothing injects it. This ticket is the foundation's **first producer** |
| Status | fully-inspected |
| Commit | `71ce3cbf` · 2026-08-05 |
| Evidence | `granting-client-access.module.ts:47-48, 100-101, 104`; grep clean otherwise |
| Notes | Completeness: the token is a `Symbol`, so injection is only possible via `@Inject(CLIENT_ACCESS_OUTBOX)` — the grep is exhaustive by construction |

### 5. `callisto-back-end` — `UploadCompleteDeliverableFileTransactionScript` (the change site)

| Field | Value |
| --- | --- |
| Inspected | Whole TS (93 lines): all 8 ctor deps, `@Transactional()`, the full `apply` sequence, return shape; plus its params and projection types |
| Findings | Order: resolve collection (find-or-create **only** when `pendingDynamicCollectionName` is non-empty, else `params.deliverableCollectionId ?? null`) → 4 validators → deleted-file lookup → mapper → `deliverableFileRepository.create(file)` → return `{...file, fileTag}`. **`@Transactional()`**, so an emission here joins the domain write atomically. **No outbox port injected.** `resolvedDeliverableCollectionId` and `params.deliverableTypeId` are in scope at the end — payload assembly needs no new query. `UploadCompleteDeliverableFileProjection` exposes `id`, `filePath`, `fileName`, `bucket`, `fileSize`, `fileAttachment{id, trackType{value}, trackTypeId, attachedToType, attachedToId}` but **not** collection or type ids |
| Status | contributing — the emission point |
| Commit | `71ce3cbf` · 2026-08-05 |
| Evidence | `…/upload-complete-deliverable-file-ts/upload-complete-deliverable-file.transaction.script.ts:32-92`; `…param.ts:1-17`; `…projection.ts:18-37` |
| Notes | The TS takes only `.id` off the assembler result — it never learns created-vs-found (area 6) |

### 6. `callisto-back-end` — `FindOrCreateDynamicCollectionAssembler` (the discarded signal)

| Field | Value |
| --- | --- |
| Inspected | Whole assembler (77 lines): all three return paths, the `23505` catch, its input and projection types |
| Findings | Three outcomes, all returning `{id, value}`: **found** (`:37-39`), **created** (`:47-49`), **race-loser-found** after a Postgres unique violation `23505` (`:59-72`). `DynamicCollectionProjection = {id, value}` — the created-vs-found distinction is computed and **discarded**. Because `value` is returned on **every** path, the inline-payload design needs no change here. Carries a documented known limitation: lookup is case-**insensitive** while the unique index is case-**sensitive**, so case-variant duplicates are possible (`:51-53`, "tracked separately") |
| Status | contributing |
| Commit | `71ce3cbf` · 2026-08-05 |
| Evidence | `…/find-or-create-dynamic-collection-assembler/find-or-create-dynamic-collection.assembler.ts:9, 19-76`; `…/dynamic-collection.projection.ts:1-4` |
| Notes | The Phase 1 plan proposed widening this projection; area 8 made that unnecessary. Case-variant limitation → concerns artifact |

### 7. `callisto-back-end` — surface enumeration (file vs collection creation)

| Field | Value |
| --- | --- |
| Inspected | Callers of `deliverableFileRepository.create`, `saveDynamic`, `FindOrCreateDynamicCollectionAssembler`, `FindOrCreateDynamicCollectionTS` — repo-wide, `__specs__` excluded |
| Findings | Deliverable **file** creation: **1** production site (`…upload-complete…script.ts:87`). Dynamic **collection** creation: **3** sites — upload-complete (`:41`), recategorize (`recategorize-deliverable-files.transaction.script.ts:46`), and approve-v2 (`approve-deliverable-files-v2.service.ts:59` → thin passthrough `FindOrCreateDynamicCollectionTS:23` → the same assembler). The passthrough TS exists because service→TS is allowed while TS→TS is forbidden |
| Status | fully-inspected — the surface list is complete |
| Commit | `71ce3cbf` · 2026-08-05 |
| Evidence | greps above; `find-or-create-dynamic-collection.transaction.script.ts:23`; `find-or-create-dynamic-collection-ts.provider.ts:6, 14-25` |
| Notes | **Completeness claim:** `saveDynamic` has exactly one caller (the assembler), and the assembler has exactly three — so the three-site list is closed by construction. The two non-upload sites are the protect-the-neighbors set for any assembler signature change |

### 8. `larry-adams` — the ticket's wiki spec and the design doc (**the authority**)

| Field | Value |
| --- | --- |
| Inspected | `PRDV-16312-endpoint-upload-complete-file-created.md` in full; `dione-file-access-event-design.md` — full section map plus Q4–Q8, Diagram 5, Diagram 6, Q9, Q15, Q16, Q17, Q18, Q19, Q20, Q21, Q22, the nullability/hierarchy analysis, and the Status checklist; sibling ticket filenames in the epic folder |
| Findings | Spec title is `POST /upload-complete → file.created.v1` — **singular**; modified **2026-07-31** (ClickUp task created 07-20). Q21: *"`collection.created.v1`: **Removed.** Dynamic collection creation is communicated inline via `deliverableCollectionId` + `deliverableCollectionValue`… Dione upserts"*. Q15 body: *"this transaction writes **1 outbox row**"*, and `deliverableCollectionValue` is populated *"whether the collection was just created or already existed"*. Q20 gives the authoritative 17-field `CallistoClientAccessFileCreatedV1Data`. Q16 marks its own proposal superseded by Q20; **Diagram 5's `file.created` fields are stale** (`filePath`/`bucket`/`mimeType`, no `fileAttachmentId`/`attachedToType`/`deliverableCollectionValue`). Q5 = command-driven outbox (projection-driven called an antipattern). Q18 = eventual consistency, seconds, no ordering guarantees. Q25 = *"ClickUp stays wiki-pointer."* Siblings confirmed by filename: 16310 grants, 16311 approve-v2, 16313 rename, 16314 recategorize, 16315 unapprove, 16316 collection-deleted retrofit, 16317 delete-proceeding-file |
| Status | contributing — **resolved the pass's largest question** |
| Commit | n/a (docs repo, read-only) · 2026-08-05 |
| Evidence | wiki spec `:10, 23, 29-37, 50-68, 75-91`; design `:932-952 (Q15)`, `:958-962, 984-986 (Q16)`, `:1012-1021 (Q18)`, `:1027-1055 (Q19)`, `:1063-1084 (Q20)`, `:1178-1197 (Q21)`, `:1199-1217 (Q22)`, `:695-811 (Diagram 5)`, `:813-835 (Diagram 6)`, `:1508-1556`, `:1564-1592 (Status)` |
| Notes | **Internal contradiction found in the design doc's Status checklist** — L1581 says Q15 "confirmed **2 outbox writes**" (body says 1) and L1588 says Q22 has "**9 events** … collection.created" (its table lists 11 and omits it). The ClickUp text matches these stale lines. → concerns artifact |

### 9. `callisto-back-end` — dependency state and the prerequisite

| Field | Value |
| --- | --- |
| Inspected | `git log` for PRDV-16293; `package.json` + `package-lock.json` + installed `node_modules` version for `@planetdepos/orbital-docking-protocol`; sibling repos' installed versions; `.npmrc` (repo + user); token env vars; `gh auth status` scopes |
| Findings | PRDV-16293 **merged** — `43ad3dea` (PR #399), 8 commits, adding the port, writer, registry, writer spec, module wiring, and `docs/runbooks/local-rabbitmq-ssm-tunnel.md`. `package.json` declares `^1.0.7`; lockfile pins **1.0.7** with a `npm.pkg.github.com` integrity hash (so it **is** published); **installed was 1.0.5**, which exports no client-access contracts; `nova-back-end` also holds 1.0.5. Repo `.npmrc` sets `//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}`, **overriding** the real token in `~/.npmrc` for that registry; `GITHUB_TOKEN` is unset in the agent shell → `npm ci` failed **E401** and left `node_modules` **empty**. `gh` is authenticated but its token lacks `read:packages`, so it cannot substitute |
| Status | contributing (environment) |
| Commit | `71ce3cbf` · 2026-08-05 |
| Evidence | `git show --stat 43ad3dea`; `package-lock.json` node_modules/@planetdepos/orbital-docking-protocol block; `.npmrc:6-7`; `gh auth status` scope list |
| Notes | **Repo left in a broken state by this investigation** — `node_modules` is empty and must be restored before Phase 5. Report OV-1 / A6 |

### 10. `callisto-back-end` — existing test surface (where the red→green test lands)

| Field | Value |
| --- | --- |
| Inspected | `__specs__` contents of the upload-complete TS folder and the assembler folder; the PRDV-16293 writer spec's existence |
| Findings | Five specs already exist beside the change site, including `upload-complete-deliverable-file.transaction.script.spec.ts` and `find-or-create-dynamic-collection.assembler.spec.ts`. So the ticket's AC "unit tests on the transaction script" needs **no new harness**. `client-access-outbox.writer.spec.ts` (127 lines) shipped with the foundation. Nothing asserts emission from the TS today — there is nothing to assert, since no writer is injected |
| Status | fully-inspected — **not** run |
| Commit | `71ce3cbf` · 2026-08-05 |
| Evidence | `…/upload-complete-deliverable-file-ts/__specs__/` (5 spec files); `git show --stat 43ad3dea` (writer spec) |
| Notes | **Not executed** — `node_modules` is empty (area 9). File presence only; no pass/fail claim is made anywhere in this investigation |

## Not yet inspected (frontier)

- **The installed ODP 1.0.7 export list** — whether `CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1` (and its `EventContract` shape: `eventType`, `schemaUri`, `schemaVersion`) resolves as the registry expects. Blocked on area 9's E401. Report A7. **Highest-value next inspection** — it is the last unproven link in the happy path.
- **`orbital-relay-pkg` duplicate-deterministic-id runtime behavior** — inherited `partial` from PRDV-16402 area 12 and reopened here without closing. The UPDATE-and-republish mechanism was read from source, never observed. Now load-bearing because this is the first producer: a retried upload-complete with the same `rowUpdatedAt` would exercise it.
- **RabbitMQ topology for `callisto.client-access.file.created.v1`** — whether the dev queue binds `callisto.client-access.#` (needs nothing) or per-routekey (needs a request). Decides whether AC6 is reachable. Design Q22's checklist raises exactly this. `RABBITMQ_CONFIG_REQUEST_TEMPLATE.md` sits unfilled in the ticket folder. Report OV-4.
- **`params.userId` provenance** — identity string vs numeric id, for `createdUserIdentity`. Not traced back through the action/DTO to the auth context. Report A9/OV-5.
- **Exhibits / MVC track configuration in Callisto** — the design's nullability table asserts these tracks carry no collection; not verified against Callisto's track config, so AC4's null branch is asserted from the design rather than from code. Report A10.
- **`CreateDeliverableFileMapper`** — whether the created `file` carries a DB `createdAt` at return time (Q20 wants "File entity's DB timestamp") or whether it must be re-read after insert. Read only by name this pass.
- **Dione's consumer expectations** — out of scope for this repo, but the reason payload correctness has slow feedback (report §7).
- **The `file_tag` / `fileTag` return value** on the TS — noted in the return shape, never traced; irrelevant to emission unless the payload needs it (it does not per Q20).
