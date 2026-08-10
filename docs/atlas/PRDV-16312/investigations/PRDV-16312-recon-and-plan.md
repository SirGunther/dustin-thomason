# PRDV-16312 — Phase 1 Recon and Plan

> Orchestration Phase 1 output. This document is the **durable carrier** of the recon: it records the findings this pass reached, then the todos to emit them. It is saved verbatim as `docs/atlas/PRDV-16312/investigations/PRDV-16312-recon-and-plan.md` at Phase 2's first action and **frozen** thereafter. Later deviation goes in the coverage ledger's reopen reason or the why-log — never by editing this file.

## Context

`POST /upload-complete` creates a client-deliverable file in Callisto, but nothing tells Planet Portal (Dione) that it happened — so a file handed to a client is not reachable by that client. PRDV-16293 landed an outbox + dispatcher foundation to carry such events. This ticket asks for two emissions from that endpoint: `file.created.v1` always, and `collection.created.v1` when the flow created a new dynamic collection.

**The recon found that the second half of that request was deliberately deleted by its own prerequisite.** That is the load-bearing finding and it changes the shape of the ticket.

---

## Findings

### F1 — `collection.created.v1` was removed on purpose, by this ticket's prerequisite (**blocker-grade**)

`callisto.client-access.collection.created.v1` is **not registered** and therefore **cannot be emitted**: `ClientAccessOutboxWriter.write` looks the routeKey up in `CLIENT_ACCESS_EVENT_CONTRACT_BY_ROUTE_KEY` and throws `BadRequestException` when absent.

It was there and was taken out. Commit `31c81db4` (PRDV-16293) message, verbatim:

> PRDV-16293: Align outbox contracts with less-granular event catalog
> Remove collection.created; derive grants aggregate from principalType/principalId.

The registry now holds seven contracts — `GRANTS_REPLACED`, `FILE_CREATED`, `FILE_APPROVED`, `FILE_RENAMED`, `FILE_RECATEGORIZED`, `FILE_UNAPPROVED`, `COLLECTION_DELETED`. The `COLLECTION_DELETED` / no-`COLLECTION_CREATED` asymmetry is the visible fingerprint of that removal.

So the ticket asks for an event its stated prerequisite deliberately dropped. This is not a wiring gap; it is a **conflict with a decision already on the record**.

- Evidence: `…/client-access-outbox.writer.ts:24-31`; `…/client-access-outbox-event.registry.ts:1-20`; `git show 31c81db4`.

### F2 — whether the contract still exists in the catalog is **not discoverable on this machine** (proven, not assumed)

Resolving F1 needs docking 1.0.7's export list. It cannot be read here:

- `package.json` declares `^1.0.7`; **installed is 1.0.5**, which exports no client-access contracts at all.
- 1.0.7 **is** published — `package-lock.json` pins it with an integrity hash resolved from `npm.pkg.github.com`. So `node_modules` is merely stale; this is an environment fact, **not** a ticket blocker.
- No other repo in the workspace has 1.0.7 (`callisto` and `nova` both hold 1.0.5).

An `npm ci` (a write, unavailable in Plan mode) or the docking repo settles it. Until then, "does `CALLISTO_CLIENT_ACCESS_COLLECTION_CREATED_V1` still exist in 1.0.7?" is a **fact to discover at Phase 2**, not a decision — and not something to infer.

### F3 — the created-vs-found signal exists but is discarded at the return boundary

`FindOrCreateDynamicCollectionAssembler.apply` has three internal outcomes — **found** (`:37-39`), **created** (`:47-49`), and **race-loser-found** after a `23505` unique violation (`:59-72`) — but returns `DynamicCollectionProjection = { id, value }`. The created flag is thrown away.

Two things follow. First, story 02's conditional criterion is *implementable* — the signal is real and already correct, including treating the race loser as a found (so two concurrent uploads of the same collection name yield exactly one create). Second, it needs the return type widened; the caller cannot currently tell.

- Evidence: `…/find-or-create-dynamic-collection.assembler.ts:19-76`; `…/dynamic-collection.projection.ts:38-41`.

### F4 — surface enumeration: file creation is single-surface, collection creation is **not**

| Behavior | Surfaces | Completeness established by |
| --- | --- | --- |
| Deliverable **file** created | **1** — `UploadCompleteDeliverableFileTransactionScript:87` | `deliverableFileRepository.create` has exactly one production caller |
| Dynamic **collection** created | **3** — upload-complete (`…upload-complete…script.ts:41`), recategorize (`…recategorize-deliverable-files.transaction.script.ts:46`), approve-v2 (`approve-deliverable-files-v2.service.ts:59` → passthrough `FindOrCreateDynamicCollectionTS:23`) | `saveDynamic` has exactly one caller (the assembler); the assembler has exactly three |

This answers story `02.Q4` by evidence. Scoping a collection emission to upload-complete alone leaves **two** other creation paths silent — so the ticket's scope is narrower than the class of problem it describes.

### F5 — nothing constrains the payload to the contract (contract-alignment risk)

`ClientAccessOutboxPort.write` takes `payload: Record<string, unknown>` and `routeKey: string`. The typed contract is the authority, but the port mirrors nothing, so the AC "Payload matches `CallistoClientAccessFileCreatedV1Data`" is **not** enforced by any seam that exists today. Whatever satisfies it must be enforced where the payload is built, or by typing the call site.

Also relevant: `UploadCompleteDeliverableFileProjection` carries no `deliverableCollectionId` / `deliverableTypeId`, though both are in scope as locals in the TS — so payload assembly is possible without changing the projection.

- Evidence: `…/ports/client-access-outbox.port.ts:1-13`; `…/upload-complete-deliverable-file.projection.ts:30-37`; `…param.ts:1-17`.

### F6 — this ticket is the foundation's first producer

`CLIENT_ACCESS_OUTBOX` is provided and exported by `granting-client-access.module.ts:100-104` and has **zero production consumers**. Framing consequence: this is not "one more emission alongside others" — it is the first real use of PRDV-16293's foundation, so its ambient-transaction and dispatcher behavior gets exercised in anger for the first time here.

### F7 — detection gap and where the red→green test goes

A TS spec already exists (`__specs__/upload-complete-deliverable-file.transaction.script.spec.ts`), so the ticket's AC "unit tests on the transaction script prove both outbox writes occur" has a home and needs no new harness. Nothing asserts emission today because there is nothing to assert — no writer is injected. The assembler spec exists too, which is where the created-vs-found widening gets pinned.

### F8 — pre-existing adjacent issue, surfaced not adopted

The assembler carries a documented known limitation: the lookup is case-insensitive while the unique index is case-sensitive, so case-variant duplicates can be created (`:51-53`, "tracked separately"). That bears directly on story 02's criterion *"does not make that grouping show up twice"* — a client could see two groupings differing only in case. Pre-existing, out of scope, belongs in the concerns artifact.

### Reused, not re-derived (consult protocol)

From `docs/atlas/PRDV-16402/investigations/PRDV-16402-coverage-ledger.md`: the outbox writer/port/converter pattern and `DeterministicEventIdHelper` (area 5); `OutboxFacade.writeOutboxEvent` taking no manager, participation ambient via ALS (area 5); architecture rules — TS→TS forbidden at `error`, TS→service forbidden, `writers/` not exempt from `domain-no-infrastructure` hence the port token (area 9); module wiring and the `createTransactionalProxy` provider template (area 10); `orbital-relay-pkg` duplicate-id UPDATE-and-republish semantics, status `partial` (area 12). **Reopened:** area 12 stays `partial` and is now load-bearing here (F6 — first producer), so its frontier item is inherited rather than closed.

---

## Problem Check (ticket framing, grounded in its words)

| Flag | Finding |
| --- | --- |
| **Asked** | *"emit: collection.created.v1 … file.created.v1"* — two emissions from one endpoint, with a conditional on the first. |
| **Answered** | The ticket answers *what* and *when* for `file.created`. It does **not** answer whether `collection.created` is emittable, and its AC presumes it is. |
| **Should-ask** | *"If the dynamic collection already existed … no collection.created.v1 event is emitted"* — never asks about the **other two** collection-creation surfaces (F4), nor what the client should see if one emission lands and the other does not. |
| **Conflation** | *"emit: collection.created … file.created"* bundles two distinct problems — the file being unfindable, and the grouping being absent — as one deliverable. Already split at Phase 0 into stories 01 / 02. |
| **Thin** | *"the data it needs to display the file under the correct track → collection → deliverable type hierarchy"* — "the data it needs" is never enumerated, and the port accepts `Record<string, unknown>` (F5), so nothing constrains it. |
| **Off** | *"callisto.client-access.collection.created.v1"* directly contradicts the prerequisite it names: PRDV-16293's *"Remove collection.created"*. The ticket and its own stated dependency disagree. |

## Problem class

- **Assumed class:** capability gap — add two emissions to an existing endpoint. Straightforward wiring.
- **Confirmed class:** **contract-catalog misalignment.** Half the request was invalidated by a decision inside its own prerequisite. The durable problem is *how collection identity reaches Dione in a deliberately less-granular catalog* — not "add the second event."
- **Where it flipped:** during the code trace (method Step 4), on reading `31c81db4`. Not visible from the ticket text.
- **Wedge:** the `file.created` emission from upload-complete — the smallest change that forces the space open, is reusable by the five other already-registered routekeys, and does not depend on resolving F1.

## Open — genuine decisions (not facts I skipped)

| # | Decision | Owner | Why it is not a lookup |
| --- | --- | --- | --- |
| D1 | Given F1, does collection identity travel **inside** `file.created`'s payload, or does `collection.created` get restored to the catalog? | Larry Adams / whoever owns the event catalog | Both are viable; the catalog was made less granular on purpose, so restoring it reverses a deliberate call. F2's fact narrows but does not decide this. |
| D2 | If D1 restores the event: who publishes docking, and does RabbitMQ topology need the new queue/binding (the ticket's "Dev Note: RabbitMQ Config")? | Ops / infra | Cross-repo + infra; `RABBITMQ_CONFIG_REQUEST_TEMPLATE.md` in the ticket folder is the unfilled request. |
| D3 | Do recategorize and approve-v2 (F4) owe the client the same guarantee, now or as follow-ups? | Product / Larry | The ticket scopes to one surface; the class spans three. Scoping down is legitimate but should be on the record. |
| D4 | Story `01.Q7` / `02.Q2` — if one emission lands and the other does not, what should the client see? | Product | Unanswerable from code: both writes are ambient in one transaction, but consumer-side ordering is not Callisto's to decide. |

**Facts resolved by evidence this pass, not carried as questions:** PRDV-16293 is merged (`43ad3dea`, PR #399) → story `01.Q5` closed. Collection creation has three surfaces → `02.Q4` closed. The created-vs-found signal exists → story 02 is implementable. Docking 1.0.7 is published and lockfile-pinned → not a blocker.

---

## Phase 2 emission todos

1. **Save this document verbatim** as `investigations/PRDV-16312-recon-and-plan.md`; freeze it.
2. **Resolve F2 first** — run `npm ci` in `callisto-back-end`, then grep the installed 1.0.7 for `CALLISTO_CLIENT_ACCESS_COLLECTION_CREATED_V1`. This is a fact, and it sharpens D1 before anyone debates it. Record the result in the coverage ledger.
3. **Write the investigation report** to `investigations/PRDV-16312-investigation.md` from the template. Verdict must lead with F1: **proceed with conditions** — story 01 is unblocked and shippable; story 02 is gated on D1. Reconcile every software-lens point: contract alignment (F5), surface enumeration (F4), protect-the-neighbors (the three assembler callers must not change behavior when the return type widens), detection gap (F7), red→green test, repro recipe.
4. **Materialize the coverage ledger** — Consulted line first (PRDV-16402 reused, area 12 reopened as `partial`; PRDV-16192 dispatcher context), then one area row per F1–F8, then the frontier: docking 1.0.7 export list (until step 2 runs), `orbital-relay-pkg` duplicate-id runtime behavior (inherited `partial`), RabbitMQ topology state for the new routekeys, and Dione's consumer expectations.
5. **Produce the diagrams artifact** — current-vs-target for the emission path; a sequence diagram for the concurrent same-name-collection race (F3), since that is where the conditional can go wrong; N/A lines for kinds skipped.
6. **Seed the test plan** from report §9, each scenario naming the acceptance criterion it exercises: file.created on success; no emission on a failed upload; collection.created on first creation; **no** collection.created when found; **no** collection.created for the race loser; the three-caller neighbors unchanged.
7. **Record concerns** in `PRDV-16312-future-development-concerns.md` — F8 (case-variant duplicate collections vs story 02's "not twice"), and F4's two silent surfaces if D3 scopes them out.
8. **Stage the PR draft shell** — headings only, unfilled.
9. **Ledger + changelog** — Phase 1 `done`, Phase 2 `in-progress`; note that Bash **is** permitted in Plan mode (resolves the skill's open assumption); UTC session-log entry.

## Staged why-log entry (Phase 1)

- **Class of problem:** contract-catalog misalignment between a ticket and its own prerequisite — not a wiring gap.
- **Obvious going in:** two emissions, one conditional, from a known endpoint.
- **Not obvious:** `collection.created` was deliberately deleted by PRDV-16293; the created-vs-found signal is computed then discarded; collection creation has three surfaces while file creation has one; the outbox foundation has no producer yet, so this ticket is its first live exercise.
- **Assumptions to test:** that docking 1.0.7 still exports the collection-created contract (F2, unresolved on this machine).
- **Discarded path:** treating the ticket's AC as the specification. It cannot be met as written for `collection.created`.

## Staged story reconcile (Phase 1)

- **Story 01** — close `01.Q5` (prerequisite merged, `43ad3dea`). Criteria unchanged; `01.Q4` sharpened by F5: the payload shape is unenforced by any current seam, so the criterion stands but the spec owns how it is enforced.
- **Story 02** — close `02.Q4` (three creation surfaces; the ticket scopes to one — becomes D3). Add a Story log entry recording that the story is **gated on D1**, because its acceptance criteria cannot be satisfied while the routekey is unregistered. Do **not** rewrite its criteria: they still state correctly what done means for the client; it is the mechanism that is in doubt. `02.Q2` stays open, promoted to D4.
- Both stay `draft`. Neither is accepted until Phase 3.

## Verification

The recon itself is verified by: `git show 31c81db4` (F1), `package-lock.json` + installed `package.json` version (F2), the three assembler return paths at named lines (F3), single-caller greps on `deliverableFileRepository.create` and `saveDynamic` (F4). Phase 2 step 2 is the one open verification and it runs first.
