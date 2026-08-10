# Future development concerns — PRDV-16312

Dated, code-verified concerns surfaced during this ticket and shipped **out of scope**. Each names what was observed, why it is being left, and what would resolve it. Nothing here is a blocker for PRDV-16312.

---

## C1 — Case-variant duplicate dynamic collections (pre-existing)

**Date:** 2026-08-05 · **Severity:** medium · **Status:** out of scope, pre-existing, acknowledged in the code itself

**Observed.** `FindOrCreateDynamicCollectionAssembler` looks a collection up **case-insensitively** but relies on a **case-sensitive** unique index to catch races. Its own comment says so:

> `// Case-variant duplicates remain a known limitation while the`
> `// existing unique index is case-sensitive; tracked separately.`

So two concurrent creations of `"Volume III"` and `"volume iii"` both miss the case-insensitive lookup for the other, both insert, and neither trips `23505`. Two collections then exist differing only in case.

**Why it matters here.** It bears directly on job story 02 criterion 2 — *"Filing into a grouping that already exists does not make that grouping show up twice for the client."* Under this ticket's inline design, each file event carries its own `deliverableCollectionId` + `deliverableCollectionValue`, so Dione would upsert **two** collection rows and the client would see two groupings whose names differ only in capitalisation.

**Why out of scope.** Pre-existing on `main`, independent of emission, and the fix is a schema change — a case-insensitive unique index (or a normalised column) on `deliverable_collections`, plus a decision about existing duplicate rows. That is a migration with a data-cleanup question attached, not a line in this ticket.

**Resolves when:** a migration makes the uniqueness constraint case-insensitive and existing case-variant duplicates are reconciled. Worth its own ticket; story 02's criterion should cite it so the criterion is not quietly read as already guaranteed.

**Evidence:** `src/granting-client-access/domain/transaction-scripts/upload-complete-deliverable-file-ts/find-or-create-dynamic-collection-assembler/find-or-create-dynamic-collection.assembler.ts:29-36, 46-58`

---

## C2 — The design doc's Status checklist contradicts its own resolved bodies

**Date:** 2026-08-05 · **Severity:** medium (documentation) · **Status:** out of scope for code; **should be reported to Larry Adams** (design lead)

**Observed.** In `larry-adams/.../dione-file-access-event-design.md`, two Status-checklist lines disagree with the bodies of the very questions they summarise:

| Status line | The body of that question |
| --- | --- |
| L1581 — *"Q15 — Resolved (Option C: proactive emission; confirmed **2 outbox writes** at upload-complete)"* | Q15 (L932-952): *"this transaction writes **1 outbox row**"* and *"No separate `collection.created.v1` event is needed"* |
| L1588 — *"Q22 — Resolved (**9 events** total: … file.unapproved, **collection.created**, collection.deleted + proceeding.file.deleted…)"* | Q22's table (L1203-1215) lists **11** events and does **not** include `collection.created`; Q21 strikes it as *"Removed."* |

Separately, L1586's description for Q20 (*"defense-in-depth: `callisto.proceeding.file.deleted.v1`…"*) does not describe Q20's actual subject, which is "Revised file event payloads" — suggesting the checklist drifted from the bodies more than once.

**Why it matters.** This is not cosmetic — **it already caused a bad ticket.** PRDV-16312's ClickUp description asks for two events including `collection.created.v1`, matching those stale lines almost word for word. A developer working from the ClickUp text alone would build a routekey the writer rejects at runtime with `BadRequestException`, or would reverse a deliberate design decision. The epic has five more emission tickets that could inherit the same wrong framing.

**Why out of scope.** It is someone else's document, in a read-only repo (`larry-adams` is never a push target), and the correct fix is editorial by the author. The code and this ticket follow the **bodies**, which are internally consistent.

**Resolves when:** L1581 reads 1 outbox write, L1588's count and event list match Q22's table, and L1586 describes Q20's actual subject. Cheap to fix, high leverage.

**Also worth noting:** Diagram 5's `file.created.v1` field list is likewise stale (`filePath`/`bucket`/`mimeType`, missing `fileAttachmentId`, `attachedToType`, `deliverableCollectionValue`). Q16 does explicitly mark itself superseded by Q20, so the supersession is at least signposted — unlike the Status lines.

---

## C3 — Nothing enforces that the outbox payload matches its ODP contract

**Date:** 2026-08-05 · **Severity:** medium · **Status:** decision deferred to Phase 3 (report OV-2); flagged here because it outlives this ticket

**Observed.** `ClientAccessOutboxPort.write` takes `payload: Record<string, unknown>`. The registry validates the **routekey** (unknown keys throw), but the **payload shape** is unchecked at every layer: the port accepts anything, the writer passes it straight through as `data`, and no converter stands between the caller and the wire.

**Why it matters.** The authority for the shape is `@planetdepos/orbital-docking-protocol` (design Q13). A field renamed or retyped there will not fail Callisto's build, will not fail Callisto's tests, and will surface only when Dione fails to project — a consumer in a **different epic that does not exist yet**. That is the slow-feedback risk in report §7, and it multiplies across the five sibling emission tickets that will use the same port.

**Why deferred rather than fixed here.** The port was written contract-agnostic deliberately in PRDV-16293, so tightening it is a change to the foundation's design, not to this ticket. There are several defensible answers — type the port generically per routekey, type the call site against `CallistoClientAccessFileCreatedV1Data`, or introduce a typed converter matching the `job-submission-file-to-video-transcode-requested-descriptor` pattern already used elsewhere in the repo.

**Resolves when:** Phase 3 locks OV-2 and the chosen seam gives a **compile-time** failure on a contract mismatch. If Phase 3 chooses to leave the port loose, that is a risk-accepted decision and this entry is the record of it.

**Evidence:** `src/granting-client-access/domain/ports/client-access-outbox.port.ts:3-13`; `…/client-access-outbox.writer.ts:39-47`

### C3 addendum (2026-08-05) — the repo-wide precedent has the same gap, and it is worse now

Two developments sharpen this, both after the concern was first written.

**1. The house pattern does not enforce the contract either.** Derrick pointed at `contact-to-outbox-descriptor.assembler.ts` as the reference for contract-shaped outbox payloads. It imports `CALLISTO_CONTACT_CREATED_V1` and uses it for `eventType` / `schemaUri` / `schemaVersion` — but delegates `data` to `ContactToOutboxDataConverter`, which returns **`ContactOutboxEvent`, an independently declared local type** (`contact-outbox.event.ts:1-18`) that does **not** alias `CallistoContactCreatedV1Data`. So the payload shape is hand-maintained in parallel with ODP across the repo. Rename a field in the protocol and nothing in Callisto fails to compile — the drift this concern describes is the established pattern, not a local oversight.

**2. The safety net that would have caught it downstream is gone.** RabbitMQ was removed from the epic (report §13.1), so there is no dev-queue observation and no consumer exercising the payload until Planet Portal is dev-ready. Typing is now the *only* thing standing between a wrong field name and a silent failure weeks later.

**Cheap fix available, and it is a deviation worth making.** ODP already exports `CallistoClientAccessFileCreatedV1Data`, from the same package the registry already imports. Typing the new converter's return as that type directly — instead of declaring a local twin — costs nothing and turns silent drift into a compile error. Phase 3 decision (report OV-2 / §13.4).

**Scope note:** fixing the *contacts* runner to alias its ODP type is a separate, mechanical improvement across every existing producer. Out of scope here; worth a ticket if the pattern is endorsed.

---

## C4 — Two collection-creating surfaces stay silent after this ticket

**Date:** 2026-08-05 · **Severity:** low · **Status:** out of scope by design — owned by sibling tickets

**Observed.** Dynamic collections are created at **three** call sites, not one: upload-complete (this ticket), `recategorize-deliverable-files.transaction.script.ts:46`, and `approve-deliverable-files-v2.service.ts:59` (via a passthrough TS). Completeness is closed by construction — `saveDynamic` has exactly one caller (the assembler) and the assembler has exactly three.

**Why it matters.** Until the siblings land, a client can be shown a grouping created by upload-complete but not one created by a recategorize or an approve — the same underlying gap this ticket closes, at a different write site.

**Why out of scope.** Each is separately ticketed with its own event carrying the same inline collection fields: **PRDV-16311** (approve-v2 → `file.approved.v1`) and **PRDV-16314** (recategorize → `file.recategorized.v1`), per design Q20/Q22. Folding them in would duplicate their scope.

**Resolves when:** PRDV-16311 and PRDV-16314 ship. Recorded so the partial coverage between now and then is a known state rather than a surprise.

---

## C5 — `orbital-relay-pkg` duplicate-event-id behavior is unobserved, and this is the first producer

**Date:** 2026-08-05 · **Severity:** low-to-medium, unquantified · **Status:** inherited frontier; not opened by this ticket

**Observed.** Carried from `docs/atlas/PRDV-16402/investigations/PRDV-16402-coverage-ledger.md` area 12, status `partial`: `create()` builds the outbox entity with an **explicit PK** then calls `repo.save()`, so if the row already exists TypeORM issues an **UPDATE**, resetting `status` to `PENDING` and `attempts` to 0 — i.e. **re-publishing an already-published event** — while leaving `published_at`/`locked_at`/`last_error` stale. The migration defines a PK with no unique constraint, and no `ON CONFLICT` handling exists. Neither command-driven writer guards with `existsById`.

**Why it matters here.** PRDV-16312 is the outbox foundation's **first production consumer** (`CLIENT_ACCESS_OUTBOX` has zero callers today), so this path stops being theoretical the moment this ships. Event ids are deterministic over `rowUpdatedAt`, so a retried upload-complete against an unchanged file row would derive the same id and take this branch.

**Why out of scope.** It is library behavior shared by every outbox producer, not something this ticket introduces or can fix locally. Design Q18 also accepts at-least-once delivery and brief inconsistency, so a re-publish is not obviously a defect — Dione's handlers are specified to upsert.

**Resolves when:** an integration test observes the actual post-duplicate-write column set, converting the mechanism from *read-from-source* to *confirmed*. That closes report A8 and the matching frontier line in both ledgers.

---

## C8 — `files.file_size` comes back from Postgres as a **string**, repo-wide

**Date:** 2026-08-06 · **Severity:** medium · **Status:** handled for this ticket; **unaudited elsewhere**

**Observed, empirically.** An integration test against real Postgres pins it: after `repository.save()` the in-memory entity keeps the `number` we assigned, but on a **fresh read** (`findOneByOrFail`) TypeORM returns `file_size` as a **`string`** — because `files.file_size` is a `bigint` column and the `pg` driver does not coerce bigint to a JS number (it can exceed `Number.MAX_SAFE_INTEGER`). The `File` entity nonetheless declares `fileSize: number`, so **TypeScript believes it is a number and every reader is silently mistyped.**

**Why it matters here.** `CallistoClientAccessFileCreatedV1Data.fileSize` is declared `number`. Without coercion the outbox payload would have shipped `"9007199254"` — a string on the wire, past a `Record<string, unknown>` port, into a consumer expecting a number. The converter's explicit `Number(file.fileSize)` is therefore **load-bearing on any read path**, not defensive styling. It is pinned by an assertion that fails if the driver's behaviour ever changes.

**The wider concern, out of scope.** This ticket's path is safe: the converter runs on the post-`save()` entity and coerces regardless. But the entity's type is wrong for **every** read of `files.file_size` in the repo, and any other code doing arithmetic or comparison on it is working with a string. Candidates worth auditing: anything summing file sizes, comparing against a limit, or serialising a file to an API response.

**Resolves when:** either the entity declares a TypeORM `transformer` on `fileSize` that coerces on read (fixing every consumer at once), or an audit confirms no other reader depends on it being numeric. The transformer is the better fix and is a small, isolated change — worth its own ticket.

**Evidence:** `…/file-created-outbox-converter/__specs__/file-created-to-outbox-data.converter.integration.spec.ts` — *"then: fileSize is still a number when the row is re-read from Postgres"*, which asserts both the coerced output **and** `typeof reread.fileSize === 'string'`; `file.entity.ts:33` (`@Column({name: 'file_size', type: 'bigint'})` typed `fileSize!: number`).

---

## C7 — Static collection names are sent to Dione, which owns them via its own migrations

**Date:** 2026-08-05 · **Severity:** low · **Status:** **RETIRED 2026-08-07 — the risk no longer exists.** LD-012 was superseded by **LD-016**: `deliverableCollectionValue` is now gated on `collection_kind` and sent for **dynamic collections only**, which is what the spec said all along ("populated for files in dynamic collections", five separate mentions). Static collection names are no longer sent, so there is nothing for the consumer's upsert to overwrite. Retained below as the record of a risk that was accepted and then removed by reading the spec properly. Fixed in `callisto-back-end` `e8c149ae`.

**The decision.** `deliverableCollectionValue` is populated whenever a collection exists, **static or dynamic** — not gated on `collection_kind = 'dynamic'`. Chosen for a single uniform code path and because the field's meaning stays constant ("the collection's name, or null when there is no collection") rather than varying by kind.

**The accepted risk.** Design Q21 says statics are *"Seeded in Dione migrations (static, rarely change)"* while dynamic collections arrive *"inline via `deliverableCollectionId` + `deliverableCollectionValue`"*. So for a static collection, Callisto now sends a name for a row Dione already owns. Whether that is inert depends entirely on how Dione's upsert is keyed:

- **Keyed on `deliverableCollectionId`, name written only on insert** → completely inert. Almost certainly the intent.
- **Upsert overwrites the name on every event** → a static collection's display name becomes whatever Callisto's `value` column holds. If the two ever diverge (a Dione migration using a friendlier label than Callisto's raw `value`), a routine file upload silently renames a seeded collection for every client.

**Why it is accepted rather than resolved.** Dione's consumer is in a different epic and does not exist yet, so its handler cannot be read. Design Q21 specifies *"Dione upserts the collection record from these fields"*, which is the basis for accepting — but that is a spec sentence, not observed behavior. **And LD-007 removed the step that would have caught it:** with RabbitMQ descoped, there is no queue observation and no consumer round-trip in this ticket, so the first real evidence arrives when Planet Portal goes dev-ready.

**The cheap alternative, for the record.** Gating on `collection_kind` is a one-line branch and `collection_kind` is already a column on `deliverable_collections`. If Dione's upsert turns out to overwrite names, that gate is the fix and it is nearly free.

**Resolves when:** Dione's collection-upsert handler is readable and confirmed to be id-keyed and insert-only on the name — or the `collection_kind` gate is added. Worth raising with the Dione consumer ticket rather than waiting to discover it.

**Evidence:** `deliverable-collection.entity.ts:27, 43-52` (`collection_kind` column, `DYNAMIC: 'dynamic'` const, `value` on the entity for both kinds); design doc Q21 and the nullability/hierarchy table.

---

## C6 — `callisto-back-end/node_modules` was left empty by this investigation

**Date:** 2026-08-05 · **Severity:** high but trivially reversible · **Status:** **RESOLVED 2026-08-05** — the user ran `npm ci` in a shell holding a valid `GITHUB_TOKEN`; ODP 1.0.7 verified present on disk. The lesson below is kept deliberately, since the cause is reusable.

**Observed.** An `npm ci` run during Phase 2 (to resolve the docking version question) cleared `node_modules` and then failed **E401**: the repo `.npmrc` sets `//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}`, which **overrides** the valid token in `~/.npmrc` for that registry, and `GITHUB_TOKEN` is not set in the agent's shell. `gh` is authenticated but its token lacks `read:packages`.

**Why it matters.** The repo cannot build, lint, or test until restored. Report AC6 (dev-queue observation), the red→green test, and every Phase 5 gate depend on it.

**Cause worth recording, since it is the reusable lesson:** `npm ci` is destructive — it removes `node_modules` **before** fetching. `npm install` would have failed the same way without emptying the tree. Prefer `npm install` when the only goal is inspecting a dependency, and confirm registry auth before either.

**Resolves when:** `npm ci` (or `npm install`) completes in a shell with a valid `GITHUB_TOKEN`, and `npm ls @planetdepos/orbital-docking-protocol` reports 1.0.7. Tracked as report OV-1 / A6.
