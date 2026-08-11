# Test plan — atlas/PRDV-16312

| Field | Value |
| --- | --- |
| Status | **refined** (Phase 3, 2026-08-05) — executed at Phase 5. **In place before any code is written**, so the tests are not shaped by the implementation. |
| Decisions folded in | [PRDV-16312-locked-decisions.md](../specs/PRDV-16312-locked-decisions.md) — LD-007 (AC6 withdrawn), LD-011 (by-id collection read), LD-012 (static + dynamic), LD-013 (ODP-typed converter) |
| Seeded from | [PRDV-16312-investigation.md](../investigations/PRDV-16312-investigation.md) §9 |
| Criteria source | [stories/](../stories/PRDV-16312-job-stories-index.md) (what done means) + wiki spec AC1–AC6 (mechanism constraints) |
| Repo | `callisto-back-end` · baseline `71ce3cbf` |
| Serial run command | `npm test -- --runInBand src/granting-client-access` |
| Environment | **Unblocked** (2026-08-05) — user ran `npm ci`; ODP 1.0.7 present. Concern C6 resolved. **Nothing below has been run yet.** |
| Scope change | **AC6 withdrawn** — RabbitMQ removed from the epic by Derrick; the producer's obligation ends at a correctly shaped `outbox_events` row. See report §13.1. |

**Criterion keys.** `AC1`–`AC6` = wiki spec acceptance criteria. `S1.n` / `S2.n` = job story 01 / 02 criterion *n*.

---

## Unit — `UploadCompleteDeliverableFileTransactionScript`

Existing spec file: `…/upload-complete-deliverable-file-ts/__specs__/upload-complete-deliverable-file.transaction.script.spec.ts` — extend it; no new harness needed.

| # | Scenario | Asserts | Criterion | Status |
| --- | --- | --- | --- | --- |
| U1 | **Red→green.** Upload into a newly created dynamic collection | `ClientAccessOutboxPort.write` called **exactly once**, `routeKey` = `callisto.client-access.file.created.v1`, `deliverableCollectionValue` = trimmed collection name, `deliverableCollectionId` = the assembler's id | AC1, AC3, S1.1, S2.1 | pending |
| U2 | Upload into a dynamic collection that **already existed**, resolved **by name** | Still **exactly one** write; `deliverableCollectionValue` **still populated** (not null, not omitted) | AC3, S2.2 | pending |
| U2b | Upload into an existing collection supplied **by `deliverableCollectionId`**, no `pendingDynamicCollectionName` | `deliverableCollectionValue` **populated from the by-id repository read** — this is the branch that returned nothing before LD-011, and the criterion it satisfies is invisible without this test | AC3, S2.1, LD-011 | pending |
| U2c | Upload into a **static** collection | `deliverableCollectionValue` populated (not gated on `collection_kind`) | LD-012, S2.1 | pending |
| U3 | Upload on a track without collections (Exhibits / MVC) | One write; `deliverableCollectionId` **and** `deliverableCollectionValue` both `null` | AC4, S1.2 | pending |
| U4 | Full payload shape on the happy path | All 17 fields of `CallistoClientAccessFileCreatedV1Data` present with correct sourcing — `key` ← `file.filePath`, `bucketName` ← `file.bucket`, `fileType` ← `file.fileType`, `fileAttachmentId` ← `fileAttachment.id`, `createdUserIdentity` ← `params.userId` | AC2, AC5, S1.3 | pending |
| U5 | Legacy file with no deliverable type | `deliverableTypeId: null` passed through — **not** coerced to `0` or omitted | AC2 | pending |
| U6 | A validator rejects (duplicate filename / type-collection mismatch / collection-proceeding mismatch) | `write` **never called**; the throw propagates | S1.5 | pending |
| U7 | `deliverableFileRepository.create` rejects | `write` **never called** — emission is ordered after persistence | S1.5 | pending |
| U8 | Emission ordering | `write` is called **after** `create`, verified by mock call order — not merely that both happened | S1.5 | pending |

**Why U6–U8 exist.** They are the negative half of story 01 criterion 5 (*"the client is not shown a file that isn't really there"*). U8 in particular guards the property that makes U6/U7 hold structurally rather than incidentally.

## Unit — `FileCreatedToOutboxDataConverter` (new)

New spec: `…/file-created-outbox-converter/__specs__/file-created-to-outbox-data.converter.spec.ts`. Pure transform, no I/O — the cheapest place to pin the contract.

| # | Scenario | Asserts | Criterion | Status |
| --- | --- | --- | --- | --- |
| C1 | Full happy-path input | All 17 fields present and correctly mapped, including the renames `key` ← `filePath` and `bucketName` ← `bucket` | AC2, LD-013 | pending |
| C2 | `fileSize` type | Returned as a JS **`number`**, not a string — `file_size` is a `bigint` column and TypeORM commonly surfaces those as strings | AC2 | pending |
| C3 | `createdAt` serialisation | ISO 8601 string, not a `Date` object | AC2 | pending |
| C4 | No collection | `deliverableCollectionId` **and** `deliverableCollectionValue` both `null` | AC4, S1.2 | pending |
| C5 | Null-tolerant fields | `deliverableTypeId: null` and `length: null` pass through — **not** coerced to `0` | AC2 | pending |

**Why C2 and C3 exist.** Both are silent-corruption risks rather than crashes: a stringified `fileSize` or a `Date`-valued `createdAt` satisfies `Record<string, unknown>` at the port and would reach a consumer malformed. LD-013's ODP typing catches shape drift at compile time but **not** a runtime type that TypeScript believes is a `number`.

## Unit — `FindOrCreateDynamicCollectionAssembler` (neighbors — must not change)

| # | Scenario | Asserts | Criterion | Status |
| --- | --- | --- | --- | --- |
| N1 | Existing assembler spec passes **unmodified** | The assembler's contract is untouched by this ticket — no created-vs-found flag was added | regression | pending |
| N2 | `recategorize-deliverable-files` spec passes **unmodified** | Neighbor caller unaffected | regression | pending |
| N3 | `approve-deliverable-files-v2` spec passes **unmodified** | Neighbor caller unaffected (via the passthrough TS) | regression | pending |

**Protect-the-neighbors note.** N1–N3 are the concrete surfaces behind the "absence of change" claim. If any of the three specs needs editing to pass, the change is broader than designed and that is a finding, not a fix-the-test situation.

## Unit — writer (already covered, confirm unbroken)

| # | Scenario | Asserts | Criterion | Status |
| --- | --- | --- | --- | --- |
| W1 | `client-access-outbox.writer.spec.ts` passes unmodified | The foundation's writer is unchanged by this ticket | regression | pending |
| W2 | Unknown routekey | `BadRequestException` thrown — typo guard; confirms an unregistered key cannot write a malformed row | AC1 | pending |

## Integration / concurrency

| # | Scenario | Asserts | Criterion | Status |
| --- | --- | --- | --- | --- |
| I1 | Two concurrent uploads, **same** new collection name | Two files, **one** collection row, **two** `file.created` events both carrying the same `deliverableCollectionId` and `value`; the `23505` race-loser path produces no second collection | S2.2, AC3 | pending |
| I2 | Outbox row and file row commit together | Both present after commit; after a forced rollback, **neither** | S1.5 | pending |

**I1 is the highest-value scenario in this plan.** It is the timing edge case where a created-vs-found conditional would have failed, and it is the one place the inline design's advantage is observable rather than argued.

## Manual / environment

| # | Scenario | Asserts | Criterion | Status |
| --- | --- | --- | --- | --- |
| ~~M1~~ | ~~Message visible in the dev RabbitMQ queue~~ | — | ~~AC6~~ | **descoped** — see below |
| M2a | Upload into a **new** dynamic collection (type the name) | One row; `event_type` = `callisto.client-access.file.created.v1`; `data.deliverableCollectionValue` = the typed name | AC1, AC2, AC3 · **S1.4, S2.1, S2.4** | pending |
| M2b | Upload into that **same** collection (select it, don't type) | A **second** row; same `data.deliverableCollectionId`; `data.deliverableCollectionValue` **still populated** | AC3 · **S1.4, S2.2, S2.4** | pending |
| M2c | *(optional)* Upload on an **Exhibits** track | `deliverableCollectionId` and `deliverableCollectionValue` both `null` | AC4 · **S1.2** | optional |
| M2d | Full-payload inspection on any of the above | 17 fields present; `fileName`, `fileType`, `trackTypeId`, `deliverableTypeId` match what was uploaded; nothing blank or unnamed | AC2 · **S1.3** | pending |

**Correction:** an earlier version of this row expected `schema_uri` and `schema_version` **in the table**. Those columns do not exist — `outbox_events` holds `id, aggregate_type, aggregate_id, event_type, data, occurred_at, status, locked_at, locked_by, attempts, last_error, published_at, created_at`. The writer passes the schema fields to the facade; the relay applies them at publish time. Verify `event_type` and `data`.

### M2 — how to run it, and what you should see

**Read this before running it: there is nothing to see in the UI.** This change is backend-only. The upload behaves and looks exactly as it did before, and the file appears in Atlas exactly as before. Screenshotting Atlas would be screenshotting something that did not change.

| | Before this change | After this change |
| --- | --- | --- |
| Upload into client deliverables | works | works — identical |
| File visible in Atlas | yes | yes — identical |
| `callisto.outbox_events` | **empty** | **one row per upload** |

**The evidence is the database row.** That is what to capture for the PR.

**Preconditions**

- `callisto-postgres` running; `pg_trgm` installed in the `callisto` database (**not** created by any migration — a DB reset removes it and Callisto will fail to boot)
- Callisto healthy: `curl.exe -s http://localhost:3004/callisto/health` → `{"status":"ok"...}`
- Dev dataset seeded: `SELECT count(*) FROM callisto.cases` returns > 0
- AWS credentials exported — the endpoint performs a real S3 `CompleteMultipartUpload` before any of this ticket's code runs, so a fabricated `uploadId` returns `404 "Upload session not found"`
- Baseline: `SELECT count(*) FROM callisto.outbox_events` → `0`

**Steps**

1. Open `http://localhost:9000/callisto-stuff/job/112233/proceeding/3001` (the **proceeding** page — the job page has no upload surface).
2. Upload any small file to the **Transcript** track, typing a new collection name, e.g. `PRDV-16312 Volume III`. Transcript or Video only — Exhibits and MVC have no collections.
3. Upload a second file to the same track, **selecting** that collection instead of typing it.

**Evidence query** — this result grid is the PR screenshot:

```sql
SELECT
  event_type,
  aggregate_id                        AS file_id,
  data->>'deliverableCollectionId'    AS collection_id,
  data->>'deliverableCollectionValue' AS collection_name,
  data->>'fileName'                   AS file_name,
  created_at
FROM callisto.outbox_events
ORDER BY created_at;
```

And one full payload, to evidence the contract shape:

```sql
SELECT jsonb_pretty(data) FROM callisto.outbox_events ORDER BY created_at LIMIT 1;
```

**Pass / fail**

| Upload | Passes | Fails |
| --- | --- | --- |
| M2a | row exists, `collection_name` = the typed name | no row, or empty `collection_name` |
| M2b | second row, **same** `collection_id`, `collection_name` **still filled** | `collection_name` empty — the by-id defect reappearing |

**M2b is the one that matters.** Before LD-011 the by-id path never looked the collection up, so it would have emitted an empty name and the consumer would have had a file with no grouping to attach it to. Row 2 carrying a name is the proof that fix works.

In the full payload also confirm: 17 fields present; `fileSize` an unquoted number (a quoted string means the `bigint` coercion regressed — see concern C8); `trackTypeId` = 2; `createdAt` an ISO timestamp string.

**M1 is descoped, not skipped.** Derrick removed RabbitMQ from the epic: *"We are only concerned with getting these items to the outbox with the correct contract shape… The RabbitMQ queue creation will be handled when the consumer (Planet Portal) is dev-ready."* AC6 is therefore withdrawn as a requirement, and OV-4 (queue binding) is closed. Recorded as a **scope change**, so nobody later reads a missing queue observation as an untested gap.

**M2 is now the terminal manual verification and carries more weight than it did.** Descoping M1 removes the only step that would have exercised a real consumer path, so nothing downstream of the outbox row is proven by this ticket at all. M2 plus U4's typed assertion are the whole of the contract-correctness evidence — which is why report §13.4 recommends typing the converter against ODP's `CallistoClientAccessFileCreatedV1Data` directly instead of a hand-maintained local twin.

---

## Coverage with no criterion behind it

None. Every scenario above maps to a wiki AC or a story criterion.

## Story-criterion coverage — every criterion accounted for

The job stories own what done means; this table is the audit that each one is either covered or explicitly bounded. Story text is in [stories/](../stories/PRDV-16312-job-stories-index.md).

| # | Criterion (abbreviated) | Covered by | Notes |
| --- | --- | --- | --- |
| S1.1 | Client can pull up the file without anyone re-sending it | U1, M2a | **Callisto's half only.** The record is produced; a client actually *pulling it up* needs Dione's consumer, which does not exist yet (different epic). Bounded, not skipped. |
| S1.2 | File sits under the same track, grouping and type — not a catch-all | U3, U4, M2c | `trackTypeId`, `deliverableCollectionId`, `deliverableTypeId` carried as filed; M2c proves the no-collection tracks get `null` rather than a fallback. |
| S1.3 | Name, type and placement match what was uploaded; nothing blank | U4, C1, **M2d** | Unit-asserted per field; M2d confirms it survives a real upload. |
| S1.4 | Someone can watch a real upload produce a complete, correctly shaped record | **M2a, M2b** | This is the criterion M2 exists for. Was unmapped until 2026-08-07. |
| S1.5 | A failed upload leaves no file for the client to find | U6, U7, U8, I2 | Validator rejection and insert failure both emit nothing; U8 pins the ordering that makes it structural. |
| S2.1 | Client can see a brand-new grouping as soon as the first file lands | U1, M2a | Record names the new grouping so the consumer can create it. Same Dione boundary as S1.1. |
| S2.2 | Filing into an existing grouping does not make it show up twice | U2, U2b, **M2b**, I1 | Both uploads carry the **same** `deliverableCollectionId`, so the consumer upserts one grouping rather than adding a second. |
| S2.3 | A brand-new grouping shows up under the correct track | U1, U4 | `trackTypeId` asserted on the record. *Rendering* under that track is Dione's projection — outside this repo. |
| S2.4 | Someone can watch **both** cases produce a record naming the grouping | **M2a + M2b together** | Neither alone satisfies it; the pair does. Was unmapped until 2026-08-07. |

**Bounded, not unproven:** S1.1, S2.1 and S2.3 each stop at Callisto's boundary because the client-visible half needs Dione's consumer. That limit is a property of the epic, not a gap in this ticket — and it is why LD-016 keeps the payload conservative (`deliverableCollectionValue` for dynamic collections only), so the consumer is handed only what it cannot already seed for itself.

**Mapping error corrected 2026-08-07:** rewriting M2 into M2a–M2c switched the criterion column to spec `AC` keys and dropped the story keys, leaving **S1.4 and S2.4 with no coverage at all** even though M2 was written precisely to satisfy them. Restored, and M2d added for S1.3.

## Results log

_Empty until Phase 5. Each entry records the exact command, its scope, and the observed result — never an expectation._

Status: **executed** (2026-08-05). Every row below is an observed result. Commands were run with the repo's real config — note `npx jest` alone picks up the wrong config block in `package.json`; the unit config is `jest-e2e.json`, which is what `npm test` uses.

| Date | Scenario(s) | Command | Scope | Result |
| --- | --- | --- | --- | --- |
| 2026-08-05 | C1–C5 (converter) | `npx jest --config jest-e2e.json --runInBand file-created-to-outbox-data` | new converter spec | **pass** — 6 tests |
| 2026-08-05 | U1, U2b, U2c, U3, U6, U7, U8 + the 9 pre-existing | `npx jest --config jest-e2e.json --runInBand upload-complete-deliverable-file.transaction.script` | TS spec | **pass** — 16 tests (9 pre-existing unchanged + 7 new) |
| 2026-08-05 | **Red→green proof** | same command with `__RED_GREEN_PROOF=1` temporarily disabling the emission | TS spec | **5 failed / 11 passed** — exactly the 5 positive emission assertions failed; the 9 pre-existing and the 2 negative (`not.toHaveBeenCalled`) tests still passed. Guard removed afterwards; `grep __RED_GREEN_PROOF src` → clean |
| 2026-08-05 | N1, N2, N3 (neighbours) | `npx jest --config jest-e2e.json --runInBand find-or-create-dynamic-collection recategorize-deliverable-files approve-deliverable-files-v2` | assembler + its 2 other callers | **pass** — 10 suites, 51 tests, **specs unmodified** (`git status` confirmed none of the three appears as changed) |
| 2026-08-05 | Whole module | `npm test -- --runInBand src/granting-client-access` | `granting-client-access` | **pass** — 74 suites, 367 tests. `pretest` ran `test:conventions` (architecture, naming, dto-structure, type-structure, migration-naming, no-util-files) — all green, which is what validates the domain→port layering |
| 2026-08-05 | Type check | `npx tsc --noEmit -p tsconfig.json` | whole repo | **pass** — exit 0 |
| 2026-08-06 | **I3 (new)** — real Postgres round-trip of a `File` through the production repository, then the real converter | `npm run test:integration -- file-created-to-outbox-data` | new integration spec, Docker `callisto-postgres` | **pass** — 4 tests. **Found a real defect risk:** `typeof reread.fileSize === 'string'` — see below |
| 2026-08-06 | Integration regression | `npm run test:integration` | whole repo | **pass** — 8 suites, 91 tests (the glob `schemaEntities` shares `callisto_test`, so this confirms no disturbance to the 7 pre-existing suites) |
| 2026-08-10 | **M2a-equivalent** — real upload into Client Deliverables (Transcript), then inspect the persisted row | DBeaver against `callisto` on localhost:5432 | live local stack | **PASS.** One row, `type` = `callisto.client-access.file.created.v1`, `aggregate_type` = `File`, `aggregate_id` = 2. Payload carried all 16 fields: `fileName` = `larry-file-2 copy 2.pdf`, `fileSize` = `3460219` **unquoted**, `fileType` = `application/pdf`, `trackTypeId` = 2, `proceedingId` = 3001, `attachedToType` = `Proceeding`, `key`, `bucketName`, `length` = 17, `createdUserIdentity`, `createdAt` ISO. Envelope carried `schema.uri` and `schema.version`. `deliverableCollectionId` / `deliverableCollectionValue` **null** — no collection was selected. **Screenshot captured.** |

### M2 is now the spec's own mandated manual test

Verified 2026-08-06 against `larry-adams` `origin/main` (`318bd0a`): the spec's Manual test now reads *"Upload a file in dev, **confirm an outbox row is written with the expected routekey + payload**"* — reworded from "observe messages in dev queue". So M2 stopped being my chosen substitute for the descoped queue check and became the verification the spec explicitly asks for. That raises its weight rather than lowering it.

### I3 closed the data-shape half of M2 — and caught a real defect risk

Added 2026-08-06. This is the check that could not be faked with mocks, and it earned its place: **`files.file_size` comes back from Postgres as a `string`** on a fresh read, because the column is `bigint` and the `pg` driver will not narrow it — while the `File` entity declares `fileSize: number`, so TypeScript reports no problem. Without the converter's explicit `Number(...)`, the payload would have shipped `"9007199254"` where the contract declares a number, straight through the `Record<string, unknown>` port.

The test asserts **both** the coerced output *and* the raw driver type. That distinction matters: asserting only the converter's output cannot tell "the driver returned a number" from "the driver returned a string and `Number()` rescued it" — which is the entire question the coercion exists to answer. Recorded as concern **C8**, since the entity's type is wrong for every reader of that column, not just this one.

`createdAt` round-tripped to a well-formed ISO 8601 string. The timezone question (the column is `timestamp` *without* time zone) is **not** settled by this — the format is right; whether the instant is right depends on what the DB stores, which needs a real seeded upload.

### Evidence query — use this one

The payload is nested one level deeper than the earlier queries in this file assumed. `data->>'fileName'` returns null; the correct path is `data->'data'`:

```sql
SELECT data->>'type'          AS event_type,
       jsonb_pretty(data->'data') AS payload
FROM callisto.outbox_events
ORDER BY created_at;
```

Click the `payload` cell so DBeaver's Value panel renders it, then screenshot grid and panel together. That single image evidences AC1 and AC2.

### Status of the manual criteria

| Criterion | State |
| --- | --- |
| AC1 — row written with the correct routekey | **demonstrated** 2026-08-10 |
| AC2 — payload matches `CallistoClientAccessFileCreatedV1Data` | **demonstrated** 2026-08-10 |
| AC3 — `deliverableCollectionValue` populated, new **and** existing collection | **not demonstrated** — blocked on the GCA feature flag |
| AC4 — null for tracks without collections (Exhibits, MVC) | **not demonstrated** — but **not blocked**: Exhibits has no collections, so the picker never appears and the flag is irrelevant. One upload to the Exhibits section demonstrates it. |

**AC3's blocker:** `IS_GRANTING_CLIENT_ACCESS_ENABLED` is absent from the local Cognito user's `custom:feature-flags`. Without it Atlas takes the legacy upload branch and never shows the collection picker, so no collection can be attached. The attribute exists on the pool schema and is mutable; it is **not** in the SAML attribute mapping, so it is settable per user. Setting it did not survive a re-login in the attempt made — unresolved.

### Prior note, now superseded

The remaining half of M2 is unverified: **no `outbox_events` row has been inspected.** I3 proves the payload's data shape survives a real database; it does **not** prove the row persists with the contract's `schema_uri` / `schema_version`, nor that the write participates correctly in the ambient transaction at runtime. That needs a booted local Callisto with a seeded dataset and an authenticated `POST /upload-complete`.

**AC2 remains `needs proof`.** The data-shape risk is now closed; the persistence-and-envelope risk is not. No claim is made that it passes.
