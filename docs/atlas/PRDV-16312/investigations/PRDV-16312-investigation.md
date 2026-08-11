# Investigation Report: emit `file.created.v1` when a file is uploaded straight into client deliverables

## Metadata

| Field | Value |
| --- | --- |
| Ticket | PRDV-16312 (parent epic PRDV-15736) |
| Project | atlas (implementation: `callisto-back-end`) |
| Repo baseline | `callisto-back-end` `71ce3cbf` (`main`, 2026-08-03) |
| Investigated | 2026-08-05 |
| Prerequisite | PRDV-16293 — **merged**, `43ad3dea` (PR #399) |
| Authority on scope | `larry-adams/.../PRDV-16312-endpoint-upload-complete-file-created.md` (modified 2026-07-31) + `dione-file-access-event-design.md` |
| Coverage ledger | [PRDV-16312-coverage-ledger.md](./PRDV-16312-coverage-ledger.md) |
| Diagrams | [PRDV-16312-diagrams.md](./PRDV-16312-diagrams.md) |
| Recon-and-plan (frozen) | [PRDV-16312-recon-and-plan.md](./PRDV-16312-recon-and-plan.md) |

---

## 0. Verdict (bottom line up front)

**Proceed.** Scope is **one** outbox emission, not two.

Inject `CLIENT_ACCESS_OUTBOX` into `UploadCompleteDeliverableFileTransactionScript` and, after the file persists, write one `callisto.client-access.file.created.v1` row carrying the 17 fields of `CallistoClientAccessFileCreatedV1Data` — including `deliverableCollectionId` and `deliverableCollectionValue` inline, so Dione upserts the dynamic collection without a second event. Everything needed already exists: the contract is registered, the writer is provided and exported, the TS is `@Transactional()`, and the values are all in scope at the emission point.

**The ticket's ClickUp description asks for a second event that does not exist by design.** `collection.created.v1` was deliberately removed (design Q21; enacted in PRDV-16293 commit `31c81db4`). Building it would reverse a decision, require a cross-repo docking publish, and require new RabbitMQ topology. Do not build it.

**What this is not:** not a licence to widen `DynamicCollectionProjection` with a created-vs-found flag (the design explicitly makes that unnecessary), and not verified end-to-end — no message has been observed in a dev queue, and `callisto-back-end/node_modules` is currently empty, so nothing has been built or tested (see §8 A6, §10 OV-1).

---

## 1. Problem class

| | |
| --- | --- |
| **Assumed class** | Capability gap — "add two emissions to an endpoint." Straightforward wiring. |
| **Confirmed class** | **Replication of a Callisto-owned write into a consumer projection.** Callisto is writer of record for client deliverables; Dione must project them to render track → collection → deliverable type. This ticket is the **first producer** on the PRDV-16293 outbox foundation. |
| **Reframed?** | Yes, twice. At the code trace (Step 4), on finding `collection.created` deleted — which looked like a blocker. Then again on reading the ticket's own cited wiki spec, which showed the deletion was the *answer*, not an obstacle: the ticket text was stale, and the design had already resolved it. |
| **Implication for the solution space** | The shape set here is reused by five epic siblings (16310, 16311, 16313, 16314, 16315) hitting the same outbox from different write sites. Getting the payload assembly and the contract-enforcement seam right matters more than one endpoint implies. |
| **Wedge** | This emission. Smallest change that puts the foundation into production use, and the template every sibling copies. |

---

## 2. Problem statement (raw facts, collected before classification)

**In one sentence a stranger could confirm or deny:** when an ops user uploads a file directly into a proceeding's client deliverables, Callisto stores it and tells nothing downstream, so the client granted access to that deliverable type cannot see the file in Planet Portal.

**Named instance:** no individual client is named as blocked. The blocked party is structural and total — **every** client of **every** proceeding, because `CLIENT_ACCESS_OUTBOX` has zero production consumers (`grep` for the token yields only the port, the module registration, and the writer itself). Nothing has ever been emitted. Recorded honestly: this is a **capability that has never worked**, not a regression someone reported.

**Urgency / trigger:** epic PRDV-15736 is mid-flight and this is one of six emission tickets; PRDV-16293 (the carrier) merged on the current `main`. Sprint 2026-16 (8/5–8/18), 3 points, priority High, status IN PROGRESS.

**Distinct problems (kept separate):**
1. The file itself is unknown downstream → job story 01.
2. The grouping the file lands in is unknown, or would duplicate → job story 02.

### Problem Check

Run against the **ClickUp** text (the capture in `PRDV-16312-original-ticket.md`).

| Flag | Finding (grounded in the ticket's words) |
| --- | --- |
| **Asked** | *"emit: `callisto.client-access.collection.created.v1` … `callisto.client-access.file.created.v1` — always"* — two emissions, one conditional. |
| **Answered** | *What* and *when* are answered for `file.created`. Whether `collection.created` is emittable is never asked, and the AC presumes it is. |
| **Should-ask** | *"If the dynamic collection already existed (find-or-create returned existing), no `collection.created.v1` event is emitted"* — never asks whether the event exists, nor about the other two collection-creating call sites, nor what a client sees if one of two emissions fails. |
| **Conflation** | *"emit: collection.created … file.created"* bundles two client problems as one deliverable. Split at Phase 0 into stories 01/02, before the investigation could define them. |
| **Thin** | *"the data it needs to display the file under the correct track → collection → deliverable type hierarchy"* — "the data it needs" is unenumerated in the ticket. Resolved by design Q20 (17 fields), **not** by the ticket. |
| **Off** | *"callisto.client-access.collection.created.v1"* contradicts the prerequisite the same ticket names: PRDV-16293's *"Remove collection.created"*. **The most consequential finding in this report.** |

---

## 3. The contract

### Acceptance criteria

Owned by the job stories; the wiki spec's AC are the mechanism-level constraints. Mapping in §7.

From the wiki spec (authoritative):
1. Outbox row written with routekey `callisto.client-access.file.created.v1` on successful upload-complete for a client deliverable.
2. Payload matches `CallistoClientAccessFileCreatedV1Data`.
3. `deliverableCollectionValue` populated for files in dynamic collections — **whether just created or already existing**.
4. `deliverableCollectionValue` null for tracks without collections (Exhibits, MVC).
5. Unit tests on the transaction script prove the write occurs with the correct payload shape.
6. Messages visible in the dev RabbitMQ queue.

### Non-goals / out of scope

- `collection.created.v1` — removed by design (Q21). **Explicitly not built.**
- Emission from **approve-v2** (PRDV-16311) or **recategorize** (PRDV-16314), though both also create dynamic collections.
- Any `orbital-docking-protocol` change — `CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1` is already registered.
- The case-variant duplicate-collection limitation (pre-existing; see concerns).
- Dione's consumer side, and von-neumann-back-end presign resolution.
- Widening `DynamicCollectionProjection` with a created-vs-found flag.

---

## 4. What changed since the request was created

**The ticket text is stale relative to its own spec, and the drift is traceable.**

ClickUp description written 2026-07-20 (task created by Larry Adams Jul 20). Wiki spec last modified **2026-07-31**, titled `POST /upload-complete → file.created.v1` — singular — with `collection.created` absent from its AC entirely.

The ClickUp two-event framing matches two **stale Status-checklist lines** in the design doc that contradict those questions' own resolved bodies:

| Design doc Status line | The body of that same question |
| --- | --- |
| L1581 *"Q15 — Resolved (… confirmed **2 outbox writes** at upload-complete)"* | Q15: *"this transaction writes **1 outbox row**"*; *"No separate `collection.created.v1` event is needed"* |
| L1588 *"Q22 — Resolved (**9 events** total: … **collection.created**, collection.deleted …)"* | Q22's table lists **11** events and omits `collection.created`; Q21 strikes it through as *"Removed."* |

Design Q25 records the governing convention: *"ClickUp stays wiki-pointer."* So the wiki is the spec and the ClickUp text is a pointer that was not updated. Filed as a documentation defect, not a design disagreement.

---

## 5. Why it exists

The capability was never built — PRDV-16293 delivered the carrier and stopped there, by design (it is titled "infra outbox dispatcher foundation"). Emission was decomposed into six per-write-site tickets; this is one.

**Contract alignment (software lens 1).** Authority for the payload is `@planetdepos/orbital-docking-protocol` (design Q13). Callisto mirrors it **loosely**: `ClientAccessOutboxPort.write` takes `payload: Record<string, unknown>` and `routeKey: string`. The registry (`CLIENT_ACCESS_EVENT_CONTRACT_BY_ROUTE_KEY`) enforces the *routekey* — unknown keys throw `BadRequestException` — but **nothing enforces the payload shape**. Re-drift risk is structural and permanent: a field renamed in ODP will not fail Callisto's build. Where enforcement lands is a spec decision (§10 OV-2).

**Detection gap (software lens 4).** Not applicable as a bug post-mortem — nothing regressed. The *test* gap is real though: no spec asserts emission from this TS because there is nothing to assert yet. `__specs__/upload-complete-deliverable-file.transaction.script.spec.ts` already exists, so the red→green test has a home and needs no new harness.

**Class re-check (Step 4 checkpoint).** Confirmed. The class survived both reframings — it was always "replicate a Callisto write into Dione's projection." What flipped was the *scope* of the mechanism (two events → one), not the class.

---

## 6. Alternatives considered

| Alternative | Rejected because |
| --- | --- |
| **Build both events as the ClickUp text asks** | `collection.created` was deliberately removed (Q21). Requires reversing a design decision, an ODP publish, and new RabbitMQ topology. The ticket text is a stale pointer (§4). |
| **Widen `DynamicCollectionProjection` with `wasCreated`** to drive a conditional second emission | Unnecessary under the inline design — the value is sent regardless of created-or-existed (Q15/Q21). This was in the approved Phase 1 plan and is withdrawn; recorded in the why-log. |
| **Emit from the action or a service instead of the TS** | The outbox row must be in the **same DB transaction** as the domain write (design Diagram 6). Only the `@Transactional()` TS is inside that boundary. |
| **Single `file.upserted.v1` with a `status` discriminator** | Considered and rejected in the design itself (Q16 option B): breaks ODP convention, less explicit intent, worse observability. |
| **Projection-driven outbox** (poll the table) | Design Q5: *"Command-driven outbox. That is the pattern… It would be an antipattern if we tried to use projection-driven."* |
| **Emit from all three collection-creating sites now** | Each is a separate epic sibling with its own event (16311 `file.approved`, 16314 `file.recategorized`). Folding them in duplicates their scope. |

---

## 7. Solution & stress-test

**Solution.** Inject `CLIENT_ACCESS_OUTBOX` into `UploadCompleteDeliverableFileTransactionScript`; after `deliverableFileRepository.create(file)` succeeds, assemble the payload and call `write()` once with `routeKey` = `callisto.client-access.file.created.v1`, `aggregateType` = the file aggregate, `aggregateId` = the file id, `rowUpdatedAt` = the file's timestamp. Field sourcing per the wiki spec: `key` ← `file.filePath`, `bucketName` ← `file.bucket`, `fileType` ← `file.fileType`, `createdUserIdentity` ← `params.userId`, `deliverableCollectionValue` ← the assembler's returned `value`.

### Acceptance-criteria coverage

| Criterion | Status | What closes it |
| --- | --- | --- |
| AC1 routekey written on success | **covered** | Contract already registered; writer resolves it |
| AC2 payload matches the type | **demonstrated 2026-08-10** — all 16 fields observed in a live `outbox_events` row from a real upload. The port remains `Record<string, unknown>` with no compile-time guard, so the converter's ODP return type (LD-013) is what holds the shape going forward | — |
| AC3 `deliverableCollectionValue` populated created-or-existing | **covered** | Assembler returns `value` on all three paths (found / created / race-loser) |
| AC4 null for Exhibits/MVC | **needs proof** | Those tracks pass no collection; assert the null branch explicitly |
| AC5 unit tests on the TS | **covered** | Existing spec file; add emission assertions |
| AC6 visible in dev queue | **gap** | Requires a working build + dev env. Blocked today (§8 A6) |
| Story 01 criteria 1–3, 5 | **covered / needs proof** | Payload carries name, type, placement; atomicity covers the failed-upload case |
| Story 02 criteria 1–3 | **covered** | Inline collection fields + Dione upsert |

**Confirmed class.** Solves the class at this write site and establishes the template for five siblings. It does **not** solve the class at the other two collection-creating sites — deliberate, and owned by 16311/16314.

**Scale.** One extra INSERT per upload inside an existing transaction. Uploads are human-paced. The `OneToMany` row-multiplication problem that afflicts the AJSF projection query does not arise — no new query is added.

**Generalization.** Correctly sized: no abstraction invented, the existing port/writer/registry is used as-is. Resisting the created-vs-found widening keeps it minimal. The one thing arguably under-abstracted is payload assembly (inline in the TS vs a converter) — a Phase 3 decision (OV-2), and the sibling tickets are the reason to care.

**Fit.** Matches the sanctioned shape: command-driven (Q5), emission inside `@Transactional()` (Diagram 6), domain depends on a port not the writer (satisfies `domain-no-infrastructure`, since `writers/` is not path-exempt — reused from PRDV-16402 ledger area 9).

**Adjacent issues.** (a) Case-variant duplicate collections — pre-existing, bears on story 02 criterion 2, spin off. (b) The stale design-doc Status lines — cheap to fix, prevents the next ticket inheriting the same wrong framing; report to Larry. (c) Two silent collection-creating surfaces — already ticketed.

**Sufficiency.** Covers the pain that convened it: the file becomes reachable, in the right place, without a second event. Does not by itself make Dione render anything — the consumer is out of scope.

**Feedback speed.** **Slow, and this is the main risk.** Unit tests give fast feedback on the write; correctness of the *payload contract* is only proven when Dione consumes it, which is a different epic. An untyped `Record<string, unknown>` (§5) plus a consumer that does not exist yet means a wrong field name could sit undetected for weeks. Mitigation: dev-queue observation (AC6) and choosing a compile-time enforcement seam (OV-2).

**Actor / action / moment.** An ops user completes an upload into a proceeding's client deliverables → Callisto commits file + outbox row atomically → the dispatcher publishes within seconds → Dione projects it → a client with a matching grant sees the file. Without the emission, the last two steps never happen.

**The flip side (30 seconds in the solved world).** An ops user drops a transcript into a new "Volume III" collection on the Transcript track and closes the tab. Within seconds the client, who holds a grant on Full Size PDF for that proceeding, refreshes Planet Portal and sees Volume III listed with the file under it — without anyone emailing it, and without an ops user telling the client it is ready. Nobody had to touch Dione, and no second event had to arrive first.

---

## 8. Assumptions ledger

| # | Claim (falsifiable) | Status | How confirmed / what would refute it |
| --- | --- | --- | --- |
| A1 | `collection.created.v1` cannot be emitted today | **confirmed** | Absent from `CLIENT_ACCESS_EVENT_CONTRACT_BY_ROUTE_KEY`; writer throws on unknown key (`client-access-outbox.writer.ts:24-31`) |
| A2 | Its removal was deliberate, not an oversight | **confirmed** | Commit `31c81db4` body: *"Remove collection.created"*; design Q21 *"Removed."* |
| A3 | PRDV-16293 is merged | **confirmed** | `43ad3dea`, PR #399 |
| A4 | The outbox row joins the domain write atomically | **confirmed directionally** | TS is `@Transactional()`; design Diagram 6 asserts same-transaction; `OutboxFacade.writeOutboxEvent` takes no manager and participates via ALS (PRDV-16402 ledger area 5). **Not observed at runtime.** |
| A5 | The assembler returns the collection `value` on every path | **confirmed** | Three returns, all carrying `value` (`:38`, `:49`, `:68-71`) |
| A6 | The change is buildable and testable locally | **refuted — currently false** | `npm ci` failed E401 (repo `.npmrc` uses `${GITHUB_TOKEN}`, unset in the agent shell) and left `node_modules` empty. Must be restored before Phase 5. |
| A7 | `CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1` exists in the installed ODP | **open** | Present in the registry's import list and lockfile-pinned at 1.0.7, but installed was 1.0.5 and `node_modules` is now empty. Confirm after A6 is fixed. |
| A8 | A duplicate deterministic event id UPDATEs and re-publishes rather than being ignored | **partial — inherited** | Read from `orbital-relay-pkg` + TypeORM source in PRDV-16402 ledger area 12; never observed. Now load-bearing because this is the first producer. |
| A9 | `params.userId` is the right source for `createdUserIdentity` | **confirmed directionally** | Wiki spec step 3 says so and `userId: string` is on the params type. Whether it is an identity string vs a numeric id is unverified. |
| A10 | Exhibits/MVC uploads pass no collection, so the null branch is reachable | **open** | Design nullability table asserts it; not traced in Callisto's track config this pass |

---

## 9. Validation plan

**Happy path**
1. Ops user completes an upload into client deliverables on a collection-bearing track, supplying `pendingDynamicCollectionName` for a name that does not yet exist.
2. TS find-or-creates the collection, validators pass, file persists.
3. One outbox row is written with routekey `callisto.client-access.file.created.v1`, `deliverableCollectionId` set and `deliverableCollectionValue` = the new name.
4. Transaction commits; dispatcher publishes; the message is visible in the dev queue.

**Negative / inferred paths — must fail visibly, not corrupt silently**
- **Validator rejection** (collection/proceeding mismatch, duplicate filename, type mismatch): no file row **and no outbox row**. Proves atomicity; guards story 01 criterion 5.
- **Existing collection**: exactly **one** event, `deliverableCollectionValue` still populated. Proves AC3 and that no created-vs-found branch crept in.
- **Concurrent same-name uploads**: two files, **one** collection, two `file.created` events both carrying the same collection id/value; the race loser must not produce a different collection. Proves the `23505` path.
- **Exhibits / MVC track**: one event with `deliverableCollectionId` **and** `deliverableCollectionValue` both null (AC4).
- **Legacy file with no deliverable type**: `deliverableTypeId: null` accepted, not coerced to 0.
- **Unknown routekey** (typo guard): writer throws `BadRequestException` rather than writing a malformed row.
- **Neighbors unchanged** (protect-the-neighbors): the assembler's other two callers — `recategorize-deliverable-files.transaction.script.ts:46` and `find-or-create-dynamic-collection.transaction.script.ts:23` — emit nothing and behave identically. Verified by their existing specs staying green **without modification**.

**Red→green test.** Fails before / passes after: *"given a successful upload-complete into a newly created dynamic collection, `ClientAccessOutboxPort.write` is called exactly once with routeKey `callisto.client-access.file.created.v1` and `deliverableCollectionValue` equal to the trimmed collection name."* Fails today because no writer is injected.

**Reproduction recipe / preconditions.** Ops role with client-deliverable upload permission; a proceeding with a collection-bearing track (Transcript/Video); no feature flag gates this path (none found); local Callisto per `docs/atlas/local/callisto-local.mdc`; dev RabbitMQ per `docs/runbooks/local-rabbitmq-ssm-tunnel.md` (added by PRDV-16293). **Blocked until A6 is resolved.**

---

## 10. Decisions, recommendation & open variables

**Decisions settled by this investigation** — all by evidence, none needing an owner:
1. One event, not two. `collection.created` is a non-goal.
2. The wiki spec + design doc are authoritative over the ClickUp text (Q25).
3. No created-vs-found projection change.
4. Emission belongs in the `@Transactional()` TS.
5. The other two collection-creating surfaces stay out of scope (16311/16314).

**Recommendation, in order.** (1) Restore `node_modules` — gates everything. (2) Phase 3: settle OV-2 (payload enforcement seam) and OV-3 (assemble inline vs converter), since five siblings inherit the answer. (3) Implement + red→green test. (4) Dev-queue observation for AC6, **gated on** a working env. (5) Report the stale Status lines to Larry.

### Open variables to collect

| # | Variable | Owner | Why it is a decision, not a lookup |
| --- | --- | --- | --- |
| OV-1 | Restore `callisto-back-end/node_modules` (E401 on `${GITHUB_TOKEN}`) | Dustin | Needs a credential the agent shell does not hold. Gates build, tests, and AC6. |
| OV-2 | Where is payload/contract conformance enforced, given the port takes `Record<string, unknown>`? | Dustin / Larry | The port was deliberately kept contract-agnostic; tightening it, typing the call site, or adding a typed converter are all defensible. Sets precedent for five siblings. |
| OV-3 | Assemble the payload inline in the TS or in a dedicated converter? | Dustin | Wiki spec says "inject the port, write the row" and names no converter; PRDV-16402 area 5 shows a converter is the house pattern for the video-transcode writer. |
| OV-4 | Is the dev RabbitMQ topology already bound for `callisto.client-access.file.created.v1`? | Ops / Dustin | Design Q22's checklist notes a queue bound to `callisto.client-access.#` needs nothing, but a per-routekey queue does. `RABBITMQ_CONFIG_REQUEST_TEMPLATE.md` sits unfilled in the ticket folder. Decides whether AC6 needs an infra request. |
| OV-5 | Is `params.userId` an identity string or a numeric id (A9)? | Dustin | Trace at implementation; becomes a lookup once the repo builds. |
| OV-6 | Report the design doc's stale Status lines (L1581, L1588) | Dustin → Larry | Editorial call on someone else's doc. |
| OV-7 | `01.Q1` user type, `01.Q3` surface count, `01.Q8` stated latency, `02.Q1` client-facing word for "collection" | Product / Larry | Carried from the job stories for Phase 3 grilling. |

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done when |
| --- | --- | --- |
| Restore `node_modules` with a valid `GITHUB_TOKEN` | Dustin | `npm ls @planetdepos/orbital-docking-protocol` shows 1.0.7 and `npm test` runs |
| Confirm A7 (`FILE_CREATED` exported by installed ODP) | Agent | `grep CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1` hits in `node_modules` |
| Settle OV-2 + OV-3 | Phase 3 grill | Both appear as `LD-###` rows in the locked-decision ledger |
| Write the spec | Phase 3 | `specs/PRDV-16312-spec.md` cites story criteria, links locked decisions |
| Implement + red→green test | Phase 5 | The §9 red→green assertion fails on `main`, passes on the branch |
| Prove the three assembler callers unchanged | Phase 5 | Their existing specs pass unmodified |
| Observe the dev-queue message (AC6) | Phase 5 | A `file.created.v1` message with a populated `deliverableCollectionValue` is seen in the dev queue |
| Answer OV-4 before claiming AC6 | Dustin / Ops | Binding confirmed present, or a filled RabbitMQ request submitted |
| Report stale Status lines | Dustin → Larry | Larry acknowledges or the doc is corrected |

---

## 12. Definition of done (investigation gate)

| Question | Answer |
| --- | --- |
| Confirmed problem class | Replication of a Callisto-owned write into a consumer projection; first producer on the PRDV-16293 outbox |
| Reframing + step | Twice at Step 4 — "blocked by a deleted event" → "the deletion *is* the answer; the ticket text is stale" |
| Problem in one sentence | §2 |
| Named blocked instance | Structural, not individual — zero producers exist, so no client has ever seen an uploaded deliverable via this path |
| When it bites next | Sprint 2026-16 (8/5–8/18); epic PRDV-15736 mid-flight |
| Wedge and reusability | This emission; the template for five siblings |
| Acceptance criteria + non-goals | §3 |
| 30-second happy path | §7 |
| Metric proving it works, and how fast | A `file.created.v1` row in `outbox_events` then a dev-queue message (seconds per Q18). Unit tests are fast; **contract correctness is slow feedback** — §7 |
| Verdict + disposition | **Proceed** — one event, not two |
| Owners for open variables | §10 |
| Tracked action with falsifiable done-when | §11 |

---

## 13. Post-Investigation Addendum — Derrick's direction + ODP verified on disk (2026-08-05)

Appended, not rewritten. **The §0 verdict is unchanged — proceed, one event.** This addendum closes four open items and sharpens a fifth. Source: two Slack messages from Derrick relayed by the user, plus first-hand inspection of ODP 1.0.7 now that `node_modules` is restored.

### 13.1 RabbitMQ is out of scope for this epic — **AC6 is withdrawn**

Derrick, verbatim:

> I am removing the RabbitMQ requirements from the Atlas metadata -> PP epic. We are only concerned with getting these items to the outbox with the correct contract shape from the orbital-docking-protocol as the event producer. The RabbitMQ queue creation will be handled when the consumer (Planet Portal) is dev-ready to consume it.

**Effect.** Wiki AC6 (*"Messages visible in the dev RabbitMQ queue"*) is **no longer in scope**. The producer's obligation ends at a correctly shaped `outbox_events` row.

- §7's coverage table listed AC6 as a **gap** blocked on environment. That gap is **withdrawn, not closed** — it stopped being a requirement.
- **OV-4 (dev queue binding) is closed** — no topology request, and `RABBITMQ_CONFIG_REQUEST_TEMPLATE.md` stays unfilled deliberately.
- Test-plan **M1 is descoped**; **M2** (inspect the `outbox_events` row) becomes the terminal manual verification and is now load-bearing.
- **This makes the slow-feedback risk in §7 worse, not better.** Dropping the queue observation removes the only step that would have exercised a real consumer path. Correctness of the payload contract now rests entirely on typing and unit assertions until Planet Portal is dev-ready. That raises the value of 13.3.

### 13.2 Callisto-only, confirmed by the principal dev

Derrick, on scope:

> this is almost all Callisto work but also you might need to update the orbital-docking-protocol if the contract doesn't already exist for sending the collection or file

Callisto-only is confirmed. The ODP caveat is **resolved as unnecessary** — see 13.3.

### 13.3 ODP 1.0.7 inspected first-hand: the contract exists and is complete — **A7 confirmed, no ODP change needed**

`node_modules` restored by the user (`npm ci` on their side), so the last unproven link in the happy path is now proven rather than inferred.

`node_modules/@planetdepos/orbital-docking-protocol/dist/callisto/client-access/file/created/v1/callisto-client-access-file-created.v1.d.ts`:

- `CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1` = `{eventType: 'callisto.client-access.file.created.v1', schemaUri: 'schema://callisto/client-access/file/created.v1.json', schemaVersion: 1, source: 'callisto'}` — exactly the `EventContract` shape the registry expects.
- `CallistoClientAccessFileCreatedV1Data` declares **all 17 fields**, matching design Q20 field-for-field, **including `deliverableCollectionValue: string | null`**.
- The contract's own doc comment (`:4-5`) states: *"Dynamic collection creation is communicated inline via deliverableCollectionId + deliverableCollectionValue (no separate collection.created event)."*

**So no `orbital-docking-protocol` change is required**, and Derrick's local-linking workflow for interlaced ODP PRs is not needed for this ticket.

**Also confirmed — `collection.created` is removed at the contract level, not merely from Callisto's registry.** `COLLECTION_CREATED` is **not exported anywhere** in ODP 1.0.7's `callisto/index.d.ts`. Building it would require an ODP change *and* reversing a design decision *and* new topology. §0's non-goal is now settled at every layer. **A1/A2 upgraded to `confirmed` at the contract level.**

Incidental: the contract's example payload shows `createdUserIdentity` as a **UUID** (`"a1b2c3d4-…"`), so it is an identity GUID string, not a numeric id — **A9/OV-5 resolved directionally in favour of passing `params.userId` through unchanged.** Confirm the actual runtime value at implementation.

### 13.4 The house pattern for payload assembly — **OV-3 answered, OV-2 sharpened**

Derrick pointed at `src/contacts/domain/runners/contacts-to-outbox.runner/assemblers/contact-to-outbox-descriptor-assembler/contact-to-outbox-descriptor.assembler.ts` as the reference. Read, along with its converter and event type.

**The pattern is: assembler picks the contract and builds the descriptor; a dedicated converter shapes `data`.**

```
ContactToOutboxDescriptorAssembler  →  imports CALLISTO_CONTACT_CREATED_V1
                                       spreads contract.eventType / schemaUri / schemaVersion
                                       delegates data to ↓
ContactToOutboxDataConverter        →  apply(contact): ContactOutboxEvent
ContactOutboxEvent                  →  a LOCALLY DECLARED type
```

**OV-3 answered:** use a dedicated converter, not inline assembly in the TS. That matches both this precedent and the `job-submission-file-to-video-transcode-requested-descriptor` converter (PRDV-16402 ledger area 5). Note one structural difference: that runner is **projection-driven** and builds an `OutboxEventDescriptor` itself, whereas `ClientAccessOutboxWriter` is **command-driven** and already resolves the contract internally from the routekey. So only the *converter* half of the pattern transfers — the descriptor-assembly half is already done for us.

**OV-2 sharpened, and it is now a real decision with a cheap right answer.** `ContactOutboxEvent` (`contact-outbox.event.ts:1-18`) is an **independently declared duplicate** of the payload shape — it does **not** alias `CallistoContactCreatedV1Data`. The ODP constant is used only for `eventType`/`schemaUri`/`schemaVersion`; **the `data` type is hand-maintained in parallel.** So the repo-wide precedent carries exactly the drift risk recorded in concern C3: rename a field in ODP and nothing in Callisto fails to compile.

**Recommendation for Phase 3:** type the new converter's return as ODP's `CallistoClientAccessFileCreatedV1Data` **directly**, rather than re-declaring a local twin. It is strictly stricter than the precedent, costs nothing (the type is already exported and imported from the same package the registry already imports), and converts a silent-drift risk into a compile error. Given 13.1 removed the queue-observation safety net, this is the cheapest remaining defence of contract correctness. **It does mean deviating from the contacts precedent** — a deliberate, stated deviation, and the one genuine design call left in this ticket.

### 13.5 Ledger deltas

| Item | Before | After |
| --- | --- | --- |
| A6 / concern C6 (`node_modules` empty) | refuted / active blocker | **resolved** — user ran `npm ci`; ODP 1.0.7 present |
| A7 (`FILE_CREATED` exported) | open | **confirmed** — read on disk |
| A1/A2 (`collection.created` removed) | confirmed in Callisto's registry | **confirmed at the ODP contract level** — not exported at all |
| A9 / OV-5 (`createdUserIdentity` source) | open | **confirmed directionally** — identity GUID per the contract's example |
| OV-4 (dev queue binding) | open, owner Ops | **closed — out of scope** (13.1) |
| OV-3 (inline vs converter) | open decision | **answered — converter** (13.4) |
| OV-2 (contract enforcement seam) | open decision | **still a decision**, now with a recommended answer and a named precedent to deviate from (13.4) |
| AC6 (dev queue visibility) | gap | **withdrawn from scope** (13.1) |
| §7 feedback speed | slow | **slower** — the queue-observation step is gone (13.1) |
