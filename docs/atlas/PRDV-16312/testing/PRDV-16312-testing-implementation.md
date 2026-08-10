# Testing implementation — PRDV-16312

Scenario-first record of what was actually stress-tested, why each situation matters, and any code change hung off the scenario that forced it. This is the assembled block for the PR comment.

**Change in one line:** `POST /upload-complete` now writes one `callisto.client-access.file.created.v1` outbox row inside its existing transaction, carrying the file's identity, placement, and its collection's name inline — so Planet Portal can project the file and upsert the collection without a second event.

---

## Scenario 1 — A file uploaded into a brand-new collection

**Why it matters.** This is the headline case: an ops user types a collection name that has never existed, and the client must end up seeing the file under that grouping. It is also the case that proves the whole ticket, because on `main` nothing at all was emitted.

**Held?** Yes. Exactly one outbox write, routekey `callisto.client-access.file.created.v1`, `aggregateType: 'File'`, `aggregateId` the new file id, `rowUpdatedAt` the file's `updatedAt`, and the payload carrying both the new collection's id and its name.

**Change this forced.** The emission itself — `ClientAccessOutboxPort` injected into `UploadCompleteDeliverableFileTransactionScript`, called after the file persists. Plus a new `FileCreatedToOutboxDataConverter` that builds the payload.

*Files:* `upload-complete-deliverable-file.transaction.script.ts`, `file-created-outbox-converter/file-created-to-outbox-data.converter.ts`, `file-created-outbox-converter.input.ts`

---

## Scenario 2 — A file uploaded into a collection that already exists, selected by id

**Why it matters — this one was newly uncovered and is the most consequential finding of implementation.** The spec says `deliverableCollectionValue` is populated *"whether the collection was just created or already existed"*. But the transaction script only consults the find-or-create assembler when a **pending name** is supplied. When the client instead passes an existing `deliverableCollectionId`, the code never learned that collection's name — so the field would have been emitted as `null` and the client would have seen a file whose grouping had no name.

**Observed → expected → fix.**
- **Observed** (reading the code, before any change): `resolvedDeliverableCollectionId` was derived as `(await assembler.apply(…)).id` on one branch and `params.deliverableCollectionId ?? null` on the other. The assembler's returned `value` was discarded, and the by-id branch had no name at all.
- **Expected:** the collection's name accompanies the file on both branches.
- **Fix:** extracted `resolveDeliverableCollection`, which returns `{id, value}`. On the by-name branch it keeps the assembler's `value` instead of throwing it away; on the by-id branch it reads the collection via the **existing** `DeliverableCollectionRepository.findById`.

**Held?** Yes — the by-id test asserts `findById` is called and the name reaches the payload, and that the assembler is **not** called on that path.

*Files:* `upload-complete-deliverable-file.transaction.script.ts`, `upload-complete-deliverable-file-ts.provider.ts`

**Note for review:** no change to `DynamicCollectionProjection` or to the assembler. The projection already returned `value`; the caller was discarding it.

---

## Scenario 3 — A file uploaded into a *static* collection

**Why it matters — also newly uncovered.** `deliverable_collections` distinguishes static from dynamic via `collection_kind`, and both kinds carry a `value`. The contract comment covers only "dynamic" and "no collection", leaving static unspecified. Static collection rows are seeded by Dione's own migrations.

**Held?** Yes — the name is emitted for a static collection too; `collection_kind` is not consulted.

**Risk consciously accepted, flagged for the reviewer.** Callisto now sends a name for a row Dione owns. This is inert **if** Dione's upsert is keyed on id and writes the name only on insert. If it overwrites, a routine upload could rename a seeded collection for every client. Not verifiable from this repo, and the RabbitMQ descope removed the step that would have surfaced it. Gating on `collection_kind = 'dynamic'` is a one-line fix if that turns out to be the case.

---

## Scenario 4 — A track with no collections at all (Exhibits, MVC)

**Why it matters.** These tracks legitimately have no collection. A payload that invented `0` or an empty string here would put the file somewhere the client would not think to look.

**Held?** Yes — `deliverableCollectionId` and `deliverableCollectionValue` are both `null`, and **no** collection read is issued (asserted, so the read cannot creep onto a path that does not need it).

---

## Scenario 5 — The upload is rejected, or the insert fails

**Why it matters.** The worst failure mode for this feature is not "no event" — it is an event for a file that does not exist. A client shown a file they cannot open is worse than a client shown nothing.

**Held?** Yes, two ways. A validator rejection and a failed `create` each leave the writer uncalled. And because the transaction script is `@Transactional()` and the outbox row is written inside the same transaction, a rollback takes both writes with it.

**Change this forced.** Ordering: the emission sits **after** `deliverableFileRepository.create(file)`. A dedicated test asserts the actual call order (`['create', 'write']`) rather than merely that both happened — otherwise a later refactor could hoist the emission above the persist and both failure tests would still pass.

---

## Scenario 6 — Two concurrent uploads naming the same new collection

**Why it matters.** The find-or-create assembler has a real race: both callers miss the lookup, one insert wins, the loser catches a Postgres `23505` and re-selects. Under the two-event design this was where a duplicate or missing `collection.created` would have come from.

**Held? Partially — and stated honestly.** The assembler's three paths (found / created / race-loser) all return `{id, value}`, so both uploads emit the same collection id and name and Dione converges on one row via upsert. That is verified at the unit level by the assembler's own **unmodified** spec plus the by-id/by-name tests. **A true concurrent integration test was not run** — no two-process race was executed.

---

## Scenario 7 — The neighbours on the shared code path

**Why it matters.** The assembler has three callers: this endpoint, recategorize, and approve-v2 (via a passthrough TS). A signature change here would silently alter two other features.

**Held?** Yes, and this is the concrete regression evidence rather than an "isolated change" claim: **the assembler's contract was not changed at all**, and all three neighbour specs pass **unmodified** — 10 suites, 51 tests. `git status` confirms none of those spec files is modified.

---

## Scenario 8 — Two silent-corruption hazards the type system cannot catch

**Why it matters.** Both would satisfy `Record<string, unknown>` at the port and reach a consumer malformed rather than raising anything.

| Hazard | Handling | Held? |
| --- | --- | --- |
| `files.file_size` is a `bigint`; TypeORM may surface it as a **string** while the contract declares `number` | Explicit `Number(...)` coercion in the converter | **Yes — and the hazard was real, confirmed against a live database.** See below |
| `created_at` is `timestamp` **without** time zone; `.toISOString()` stamps a `Z` | Follows the existing `contact.createdAt.toISOString()` precedent | Format verified against real Postgres. **Timezone semantics still unresolved** — see below |

### The bigint hazard was not hypothetical

A unit test alone could not have answered this, and it is worth being precise about why: the converter calls `Number(...)`, so a mock-based test passes **whether or not** the driver returns a string. The assertion proves the mapping, not the hazard.

So an integration test against real Postgres now pins the driver's actual behaviour — and it turned out to matter:

- After `repository.save()`, the in-memory entity keeps the `number` that was assigned.
- On a **fresh read** (`findOneByOrFail`), TypeORM returns `file_size` as a **`string`**.
- The `File` entity declares `fileSize: number`, so **TypeScript reports nothing wrong.**

Without the coercion, the payload would have shipped `"9007199254"` — a string where the contract declares a number — past a `Record<string, unknown>` port into a consumer expecting a number. The test asserts both the coerced output **and** `typeof reread.fileSize === 'string'`, so if the driver's behaviour ever changes, the test says so instead of silently going green.

**Wider implication, raised as concern C8:** the entity's declared type is wrong for **every** read of `files.file_size` in the repo, not just this path. Anything summing sizes or comparing against a limit is working with a string. Out of scope here; worth a `transformer` on the column, which would fix all consumers at once.

*File:* `file-created-outbox-converter/__specs__/file-created-to-outbox-data.converter.integration.spec.ts` (new)

---

## What is not proven

Stated plainly rather than left for a reviewer to discover.

- **No real `outbox_events` row has been inspected** (test-plan M2). The data-shape half is now closed by the integration test above — `fileSize` and `createdAt` *do* survive a real TypeORM round-trip. What remains unproven is that the row **persists** with the contract's `schema_uri`/`schema_version` and that the write participates correctly in the ambient transaction at runtime. That needs a booted local Callisto with a seeded dataset and an authenticated `POST /upload-complete`. **AC2 remains `needs proof`.**
- **Nothing downstream of the outbox row is exercised.** RabbitMQ was descoped from the epic, and Dione's consumer does not exist yet, so contract correctness has slow feedback. That is why the converter is typed against ODP's `CallistoClientAccessFileCreatedV1Data` directly — a deliberate deviation from every existing producer, which hand-declares a parallel type.
- **`created_at` timezone semantics are unresolved.** The column is timezone-naive and `.toISOString()` asserts UTC. Consistent with the repo's precedent, but if the DB stores local time the emitted instant is wrong by the offset. Not introduced by this change; worth confirming against a real row when M2 runs.
- **The concurrent race was reasoned about and unit-covered, not executed** (Scenario 6).

## Verification commands

| Gate | Command | Scope | Result |
| --- | --- | --- | --- |
| audit | `npm audit --audit-level=high` | `callisto-back-end` | **fail (exit 1)** — 3 high advisories (`brace-expansion`, `fast-uri`, `ip-address`), all `fixAvailable`. **Pre-existing:** clean `main` also exits 1; no dependency was added by this change |
| lint | `npm run lint` | `callisto-back-end` | pass (exit 0); `eslint --fix` mutated nothing |
| tests | `npm test -- --runInBand src/granting-client-access` | `granting-client-access` | pass — 74 suites, 367 tests; `pretest` conventions/architecture gates green |
| types | `npx tsc --noEmit -p tsconfig.json` | whole repo | pass (exit 0) |
