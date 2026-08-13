# Investigation Report: PRDV-16313 — emit `file.renamed.v1` on deliverable rename

> Delivered results of running the `investigate` method inside `orchestrate` Phase 1. The investigating is done.
> Location overridden per the orchestrate layout: this lives in the ticket folder, not `docs/investigations/`.

## Metadata

- **Status:** done
- **Disposition:** **proceed**
- **Date:** 2026-08-11
- **Owner:** Dustin Thomason
- **Location:** `docs/atlas/PRDV-16313/investigations/PRDV-16313-investigation.md`
- **Ticket:** [PRDV-16313](https://app.clickup.com/t/43227262/PRDV-16313) · epic PRDV-15736
- **Domain:** software (backend, NestJS/DDD)
- **References / evidence:**
  - Authority: `larry-adams/systems/neptune/callisto/granting-client-acess/epic-PRDV-15736-make-atlas-metadata-available-to-planet-portal/PRDV-16313-endpoint-file-renamed.md` + `dione-file-access-event-design.md` (Q5, Q18, Q19, Q22)
  - Code: `callisto-back-end` @ branch `PRDV-16312` (outbox foundation PR #399 `43ad3dea` is an ancestor)
  - Contract: `@planetdepos/orbital-docking-protocol@1.0.7`
  - Sibling: `docs/atlas/PRDV-16312/` (coverage ledger areas 1/2/3/8/9/10 reused — see the [coverage ledger](./PRDV-16313-coverage-ledger.md))
  - Frozen plan: [`PRDV-16313-recon-and-plan.md`](./PRDV-16313-recon-and-plan.md)

---

## 0. Verdict

**Proceed.** The ticket is well-scoped and unblocked: the ODP contract (`CallistoClientAccessFileRenamedV1Data`) and the routekey allow-list entry both already ship, so this is a producer-only change confined to one module — no contract negotiation, no migration, no registry edit. All four of the spec's acceptance criteria are correct and are met literally by the recommended design.

**The spec's *Technical Design* section, however, is wrong on three counts**, and following it literally would produce either a build failure or a silently-broken result. Its named emit site does not exist (the premise was true before PRDV-15776 split rename by deliverable vs submission); the obvious adaptation is forbidden by a `severity: 'error'` architecture fitness rule; and it is silent on both atomicity and the deterministic event id, whose collision mode is a **silent row overwrite**, not an error. Each is addressed in the recommendation, and each is a spec-review item rather than a reason to stop.

- **Strongest path:** a transaction-owning **assembler** in `granting-client-access` that delegates the domain write to the unchanged `ProceedingAggregator` and writes the outbox row inside the same transaction. Every file touched is under `src/granting-client-access/`; zero under `src/proceedings/` or `src/proceeding-job-submission/`.
- **Not yet proven / not approved:**
  - **The spec has not been reviewed by its author** against these three findings. Phase 3 owes an addendum PR; Phase 5's `P5.spec-approved` gate owes Larry's response before any product code.
  - **A3 is confirmed directionally only** — the silent-overwrite behaviour is read from `repo.save()` on a non-generated uuid PK. It owes a real-Postgres demonstration before being asserted as fact in the PR body.
  - **A6 owes an actual `npm run test:architecture` run.** The assembler shape is legal by reading all four assembler rules; it has not been executed.
  - **Job story 01 criterion 1 is knowingly broader than what ships** (see §3). It has *not* been reworded to fit — that is Phase 3's, on the record.

---

## 1. Problem class

- **Class the request assumed:** a missing event emission — "emit `callisto.client-access.file.renamed.v1`". Framed as an additive wiring task.
- **Confirmed class:** **a missing event on an existing write path.** Effectively the same class the request assumed, sharpened by one word — *existing*. The write is correct and complete; only the announcement is absent.
- **Reframed?** **No.** The assumed class held, and it is worth saying why rather than treating a non-reframing as a non-finding. The instances (§2) show a write path that mutates client-visible state correctly and emits nothing; the root-cause trace (§5) confirms the absence is an absence, not a symptom of a broken rename. Nothing in the evidence pointed at a different class — not a permissions problem, not a data-model gap, not a consumer bug. **The reframing pressure this ticket produced landed on the *solution*, not the class**: three of the spec's design instructions are unfollowable, which changes *how* the class is served without changing what the class is.
- **What the confirmed class implies:**
  - **Where the work goes:** a new emission at an existing seam. Rename behaviour must not change. Any diff that alters how renaming works is out of class — which is what rules out re-implementing the rename inside a new transaction script (§6).
  - **What can go wrong is specific to adding an announcement, not to renaming.** Three failure modes, all of which the design must answer: emitting on the wrong path (the transaction script is shared by three surfaces); emitting when nothing was written (the no-op branch); and the announcement being lost after the write commits (no transaction on this path).
  - **The class is repeatable across the epic.** Eight sibling tickets emit events from other existing write paths. Findings here that are about the *mechanism* — the deterministic-id collision, the coverage-audit gap — generalise to them.

---

## 2. Problem statement

- **Named instances:** no individual client is named as blocked, and that is stated rather than papered over. The ticket is one of ten pre-planned epic tickets, written by Larry Adams 2026-07-20, not filed off a support escalation. The concrete instance is structural and verifiable: **any deliverable file renamed after being shared shows the client its pre-rename name, permanently.** Reproducible on demand (§9), and the absence of a complaint is explained by Dione not yet consuming these events in production — the epic is building the pipe.
- **One sentence:** when an ops user renames a client-deliverable file in Callisto, nothing tells Planet Portal, so the client keeps seeing the old filename indefinitely.
- **Distinct problems** (not merged):
  1. The client sees a stale filename after a rename. → job story 01.
  2. Names given to non-deliverable files must not travel to the client. → job story 02. Separately falsifiable: the cheapest way to satisfy (2) is to emit nothing at all, which satisfies (1) vacuously — only two criteria catch that.
- **Urgency:** no external date. The trigger is epic sequencing — Dione cannot keep filenames in sync until the producer exists, and eight sibling tickets queue behind the same outbox foundation. Bites when Dione's consumer ships.
- **Wedge:** the **second** producer on the client-access outbox. `file.created.v1` proved the mechanism for a *create*; this proves it for an **update on a shared write path** — which is where the reusable findings live (the repeatable-event id collision, the shared-transaction-script constraint, the fitness-rule shape). The remaining five unbuilt events are all updates or deletes on existing paths, so they inherit this ticket's answers, not the sibling's.

### Problem Check

- **Asked:** emit an event when a deliverable file is renamed — *evidence:* "When an ops user renames a deliverable file via `PATCH /file/:fileId`, emit `callisto.client-access.file.renamed.v1`."
- **Answered:** the same thing. No drift between what the request says it is working on and what it is working on — *evidence:* the four acceptance criteria are all about the emission ("an outbox row is written with routekey…", "Payload matches…", "Only emitted for files that have the `CLIENT_DELIVERABLE` tag", "Unit tests prove outbox write occurs"). The drift is entirely inside the **Technical Design** section, which describes a code structure that no longer exists.
- **Should-ask:** the asked question is the right one, with one addition the request does not make: **"which paths can rename a deliverable file?"** — *why:* the request assumes one endpoint. There are four rename surfaces, three sharing a single transaction script, and one of those three can rename a deliverable with no authenticated user and no validator. That decides whether the acceptance criteria as written are actually achievable (§3, concern C1).
- **Conflation:** **nothing here at the criteria level** — the four criteria are cleanly separable. But there is a mild conflation in the Technical Design: it treats "where the rename happens" and "where the deliverable guarantee holds" as one place — *evidence:* "Inject `CLIENT_ACCESS_OUTBOX` port into the rename transaction script" followed by "check that the file has the `CLIENT_DELIVERABLE` file tag." Those are two different layers in the real code, which is what makes the instruction unfollowable.
- **Thin:** two terms. *"the rename transaction script"* — *evidence:* "The transaction script behind `PATCH /file/:fileId` — after the file entity is updated with the new name." There is no such thing in this module; the referent is ambiguous between a class that does not exist and one that lives in another module and serves three routes. And *"if not already loaded"* — *evidence:* "May need to load file tags to check deliverable status (if not already loaded)" — a hedge standing in for an unanswered question; the answer is that tags are structurally unloadable on the entity (no inverse relation) but the flag is already computed twice per request.
- **Off:** one internal contradiction, and it is load-bearing — *evidence:* "The rename endpoint may serve non-deliverable files as well" → contradicted by the code the same document points at, `ProceedingFileMustBeDeliverableValidator` throwing `ForbiddenException('Only client deliverable files can be renamed via this endpoint')` since commit `4d284978` (PRDV-15776). The spec's justification for its own guard is false at the endpoint it names. The guard is still needed one layer down, which is why the contradiction is easy to miss.

---

## 3. The contract

### Acceptance criteria

The spec's four criteria (identical in the wiki and the ClickUp text — verified, unlike the sibling ticket where they conflicted).

| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| AC1 — on a successful deliverable rename, an outbox row is written with routekey `callisto.client-access.file.renamed.v1` | **needs-proof** | Assembler spec asserting one `write` with the routekey from `<CONTRACT>.eventType`, `aggregateType: 'File'`, `aggregateId: String(fileId)`. Plus the manual `outbox_events` query. |
| AC2 — payload matches `CallistoClientAccessFileRenamedV1Data` | **covered by construction** | The converter declares the ODP type as its explicit return type, so a mismatch is a compile error. Converter spec pins the five fields and the ISO-8601 `renamedAt`. |
| AC3 — only emitted for files with the `CLIENT_DELIVERABLE` tag | **covered, structurally** | Already guaranteed: `ProceedingFileMustBeDeliverableValidator` runs first and 403s non-deliverables. Proven by a spec asserting no emit when the validator rejects. **Mechanism differs from the spec's instruction** — see §7 and §10 D3. |
| AC4 — unit tests prove the outbox write with correct payload | **needs-proof** | The spec files in §9. |

**Two criteria beyond the spec's four, from the job stories, are knowingly not fully met — recorded, not reinterpreted:**

| Story criterion | Status | Why |
|-----------------|--------|-----|
| Story 01 criterion 1 — *"when someone changes the name of a file the client has been given, the client sees the new name"* | **gap** | True via the deliverable endpoint; **false via the AJSF route** (concern C1). The user ruled that a latent workflow defect, out of scope. Phase 3 rewrites the criterion to what ships, or supersedes story 01. **It has not been narrowed here to fit the build.** |
| Story 01 criteria 1–4 (client-observable wording) | **gap in observability, not behaviour** | RabbitMQ is descoped epic-wide, so nothing client-visible is observable from Callisto. The sibling had to reword one criterion in each of its two stories for the same reason. Phase 3. |

### Non-goals / out of scope

- **Changing rename behaviour.** Extension preservation, duplicate-name validation, lineage resolution and the no-op early return all stay exactly as they are.
- **The AJSF rename hole (C1).** Explicit user decision. Recorded as a caution with a follow-up, on the ruling that a submitted client-deliverable file has no legitimate reason to be renamed through that route.
- **The extensionless-filename defect (C2).** Pre-existing; this ticket makes it *visible to Dione* without causing it.
- **Making the rename path transactional beyond this emission.** The boundary opened here covers surface A only. Surfaces B and C keep their current autocommit behaviour — deliberately, since giving them a transaction is a change to neighbours this ticket must not touch.
- **RabbitMQ topology / dev-queue verification.** Descoped epic-wide (upstream `318bd0a`). The producer's obligation ends at a correctly shaped `outbox_events` row.
- **Collapsing the duplicate `fetchProceedingFileForRename` read** (C6). Behaviour-neutral refactor of `proceedings` internals; its own ticket.
- **Any ODP, migration, registry, action, DTO or guard change.** None needed.

---

## 4. What changed since the request was created

- **Shifted from:** "inject the outbox port into the rename transaction script and check the tag" → **to:** "add a transaction-owning assembler in the client-access module; the tag check already exists one layer up; the transaction is the part nobody specified."
- **The class did not change** (§1). The shift is entirely in the solution, and it has a datable cause: the spec was authored 2026-07-16/20, and commit `4d284978` (PRDV-15776, *"Split proceeding file rename by deliverable vs submission"*) restructured the rename path into a service + a shared cross-module transaction script with symmetric validators. The spec describes the pre-split world.
- **What that buys us:** the deliverable guarantee is now free — enforced by an existing validator rather than a new check — and the correct emit site is unambiguous once the fitness rules are read. It also surfaced two hazards the spec could not have known about (the repeatable-event id collision; the absent transaction).
- **What it still needs to prove:** that an assembler owning a transaction passes `test:architecture` (A6), and that the silent-overwrite behaviour is real rather than inferred (A3).

---

## 5. Why it exists

- **Origin traced to:** the epic itself. Callisto had **no outbox or dispatcher infrastructure at all** in `granting-client-access` until PRDV-16293 — the design doc says so in its own words: *"No outbox/dispatcher infrastructure exists in `granting-client-access` today — only audit events via `ProceedingFileAuditAggregator`. Outbox wiring is net-new work."* So this is not a regression and nothing broke. The rename path has never announced anything to a client-facing consumer because there was no channel to announce on, and no consumer asking. Dione's need created the requirement.
- **Evidence:**
  - Chain: `rename-deliverable-file.action.ts:17` → `deliverable-rename.service.ts:20-39` → `proceeding.aggregator.ts:129-144` → `rename-proceeding-file.transaction.script.ts:25-71` → `proceeding-file.repository.ts:133-138`.
  - The only side effect beyond the `UPDATE` is `ProceedingFileAuditAggregator.dispatchFileAuditRenamedEvent` — an **SQS** send, after the write, outside any transaction.
  - The write itself: `repo.update(id, { fileName, updatedAt: new Date() })`. Two columns. Note `File extends BaseAuditEntity`, which declares non-nullable `modified_user_identity` — and the rename **does not write it**, though `proceeding.repository.ts:119` shows the precedent that updates elsewhere do. So the row does not record who renamed it. Not this ticket's to fix, but it is why `renamedUserIdentity` must come from the request context rather than the row.
  - Restructure: commit `4d284978` (PRDV-15776).
- **Class re-check:** **held.** The root-cause evidence is that the channel never existed — which is the definition of a missing event on an existing write path, not a symptom of something else. No reclassification.
- **Detection gap (software lens):** **nothing could have caught this, and that is the honest answer.** There is no test that fails when a path does not emit an event it was never designed to emit — no type demands it, no contract test asserts producer coverage, and the ODP package declaring `CallistoClientAccessFileRenamedV1Data` with **zero references in repo source** is not an error condition anywhere. The nearest thing to a detection net is the design doc's manual coverage audit (Q22), and **that audit is exactly what missed the AJSF surface** because it enumerated only `granting-client-access` write operations. So the detection gap is a *process* gap, not a test gap — which is why C5 recommends re-running the audit across the other two modules rather than adding a test. The red→green test this ticket does add (§9) closes the narrower question: it fails before the emission exists and passes after.

---

## 6. Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| **Inject `CLIENT_ACCESS_OUTBOX` into `RenameProceedingFileTS`** — the spec's literal instruction | Three independent blockers. (1) Module cycle: `GrantingClientAccessModule` already imports `ProceedingsModule` and provides the port; `proceedings` does not import back. (2) The payload cannot be built — `apply(fileId, newValue)` has no user, and `renamedUserIdentity` is non-nullable; surface C has no authenticated user at all, so there is nothing to thread. (3) It fires for all three surfaces, including submission renames. |
| **A new `RenameDeliverableFileTS` in `granting-client-access` delegating to the aggregator** — the natural adaptation, and what a reasonable implementer would reach for | **Illegal.** `transaction-scripts-no-aggregators` at `severity: 'error'` forbids a `*.transaction.script.ts` importing `.*aggregator.*`. It would fail `npm run test:architecture`. |
| **A new `RenameDeliverableFileTS` that re-implements the rename against `ProceedingFileRepository` directly** — the way to keep the TS suffix legally | Forks the rename rules. Extension preservation, `RelatedFilesLineageMapper` lineage, `DuplicateProceedingFileNameValidator` and the no-op branch would all exist twice, giving two writers of `files.file_name` with two copies of the duplicate-name rule. Drift would surface as a duplicate client-visible filename, not a test failure. Also out of class (§1) — it changes rename behaviour. |
| **Emit inline in `DeliverableRenameService`** | Two problems. `services-no-converters` (`severity: 'error'`) forbids the service importing the payload converter. And there is **no transactional-proxied service anywhere in the repo** — every boundary is opened by `createTransactionalProxy` in a provider for a transaction script or mapper — so making it atomic would invent a pattern while costing the same wiring as the assembler. |
| **Emit from `ProceedingFileAuditAggregator`'s renamed path** — reuse an existing "after rename" hook | Same module cycle as the first row, shared with surface B, and it runs *after* the commit. Strictly worse than emitting in the service. |
| **Emit from a projection-driven runner over `files.updated_at`** | Design Q5 explicitly calls projection-driven emission an antipattern for this epic and mandates command-driven. No `File`-aggregate runner exists. |
| **Widen `RenameProceedingFileProjection` to carry `proceedingId`** — arguably the more honest home for the data | Ripples into `src/proceedings` (projection type, transaction script, ~13 mechanical spec edits) and widens what the AJSF endpoint returns (A5). The user explicitly ruled for minimal blast radius. Chosen instead: have the validator return the context it already loads and currently discards. Kept as the documented fallback if a reviewer rejects that. |
| **Thread the persisted `updated_at` out of `updateFileName`** for the event id | Same `src/proceedings` ripple. And the two values are reads of the *same process clock* milliseconds apart — `updateFileName` mints `new Date()` in app code, not a DB `now()` — so there is no source-of-truth difference being surrendered, and Q5 forbids the path that would ever re-derive the id from the row. Recorded as C4. |
| **`ON CONFLICT DO NOTHING` on the outbox insert** to make the id collision safe | **Worse.** It would preserve the *first*, stale payload; the current `save()` overwrite preserves the later, correct one. Recorded so nobody "fixes" it in that direction. |
| **Feature-flag the emission** | `granting-client-access` does not gate its outbox writes and the shipped `file.created.v1` is unflagged. Flagging one of seven events and not the other is worse than flagging none. |

---

## 7. Solution & stress-test

- **Proposed solution:** a `@Injectable` **assembler** at `src/granting-client-access/domain/assemblers/rename-deliverable-file-assembler/`, registered through a provider that wraps it in `createTransactionalProxy`. It injects `ProceedingAggregator`, a dedicated `FileRenamedToOutboxDataConverter`, and `CLIENT_ACCESS_OUTBOX`. Its `apply` delegates the rename to the unchanged aggregator, skips when the projection shows a no-op, then writes the outbox row inside the same transaction. `DeliverableRenameService` keeps the deliverable validator first (now capturing its returned context for `proceedingId`) and the audit dispatch last and outside. Full steps in the [frozen plan](./PRDV-16313-recon-and-plan.md).

- **Solves the confirmed class?** Yes, and at the right altitude. It adds an announcement at an existing seam without touching rename behaviour, and it answers all three class-specific failure modes: wrong path (emits only where the deliverable guarantee holds), nothing written (the no-op guard), announcement lost (the transaction boundary).

- **Contract alignment (software lens):** the authority is `@planetdepos/orbital-docking-protocol@1.0.7`, and the mirror is exact by construction — the converter's declared return type *is* `CallistoClientAccessFileRenamedV1Data`, so drift is a compile error rather than a runtime surprise. The routekey comes from `CALLISTO_CLIENT_ACCESS_FILE_RENAMED_V1.eventType`, never a literal, and the writer independently rejects unregistered routekeys with `BadRequestException`. **Re-drift risk:** the design doc's Diagram ④ (`:740-747`) sketches `previousFileName` + `newFileName`, which the shipped contract does not have. The package wins and the diagram is stale; recorded as a documentation defect for the addendum so a later reader does not "restore" the diagram's shape.

- **Surface enumeration (software lens) — four rename surfaces, and how completeness was established:**
  - A. `PATCH /granting-client-access/file/:fileId` → deliverable-validated, has user, audits. **The target.**
  - B. `PATCH /proceedings/file/:fileId` → submission-validated (rejects deliverables), has user, audits.
  - C. `PATCH /<ajsf>/file/:fileId` → **no validator, no user, no audit.** Can rename a deliverable. Concern C1.
  - D. `PATCH /cases/file/:fileId` → separate `CaseFileRepository.updateFileName`, different aggregate.
  - A, B and C funnel through the single `RenameProceedingFileTS`. **Completeness claim:** exactly two DB writers of `files.file_name` (`ProceedingFileRepository.updateFileName:133`, `CaseFileRepository.updateFileName:325`) — established by grepping every `updateFileName` definition and call site and every `.save(`/`.set(` touching `fileName`; no bulk/batch rename endpoint exists; recategorize reads `fileName` at `:86` for duplicate validation but never writes it; case-merge computes new names but writes them only as S3 keys, never to `files.file_name`.

- **Protect-the-neighbors (software lens):** the neighbours on the shared path are surfaces B and C, and the proof they did not move is **structural rather than asserted** — the change set contains zero files under `src/proceedings/**` or `src/proceeding-job-submission/**`, so `RenameProceedingFileTS` keeps its four dependencies and no outbox port and is *incapable* of emitting, and `RenameProceedingFileProjection` is unchanged so neither response body shifts. Verification: `git diff --name-only` shows nothing in those trees, and `rename-proceeding-file.transaction.script.spec.ts`, `proceeding.service.spec.ts` and `job-submission.service.spec.ts` all pass **unmodified**. A second neighbour is the audit dispatch, which must keep firing on exactly the same payload — pinned by leaving the existing service-spec assertions byte-identical.

- **Scale:** one extra `INSERT` inside an existing request, no new query, no fan-out. The relay already polls with `FOR UPDATE SKIP LOCKED`. Renames are a low-frequency ops action. Nothing here scales badly.

- **Generalization:** deliberately not abstracted. The converter and assembler are single-event, mirroring the sibling's single-event converter, because the five remaining unbuilt events have different payloads and different guard conditions — a shared "outbox emitter" abstraction over seven events with nothing yet in common would be overreach. The one thing worth promoting is `FILE_AGGREGATE_TYPE`, currently a private local const in the sibling's transaction script: two producers writing to the same aggregate should not each own a private copy of the string, since a drift would silently split the aggregate stream. Recorded rather than done, to keep the diff inside this ticket's class.

- **Fit:** follows the module's shipped pattern for `file.created.v1` on every point that transfers — dedicated converter returning the ODP type, narrow structural input type in a sibling `.input.ts`, port injected by Symbol, provider wrapped in `createTransactionalProxy`, routekey via the contract constant. Two deliberate deviations from convention, both stated rather than slipped in: the class is an **assembler** rather than a transaction script (forced by `transaction-scripts-no-aggregators`, C3), and a **validator returns its loaded context** where all ~17 others return `void` (chosen over the `src/proceedings` ripple, with the fallback documented).

- **Adjacent issues:** four surfaced, none fixed, all recorded — C1 (AJSF hole, user-ruled out of scope), C2 (extensionless-filename mangling, pre-existing), C5 (the epic's coverage audit never covered two modules), C6 (duplicate read per request). The tradeoff on C1 specifically: the in-ticket guard would have been ~6 lines, but it touches two other modules and would start 403ing a route on a workflow claim rather than on evidence about real usage — so recording it is the cheaper *and* safer call.

- **Sufficiency:** covers the pain that convened this for the endpoint the epic cares about. It does **not** cover every route that can rename a deliverable (C1) — stated plainly rather than claimed, because story 01 criterion 1 as written would otherwise read as met.

- **Feedback speed:** **fast for the mechanism, slow for the outcome.** The outbox row is observable immediately in dev, so a wrong payload or a missing emission surfaces in minutes. But whether Dione does the right thing with the event is unobservable from here — RabbitMQ is descoped, and the consumer is another team's. So this ticket's proof ends at the row, and the client-visible half arrives only when Dione's consumer ships. Flagged as slow-feedback: a payload that is *shaped* right but *semantically* wrong (say the wrong `proceedingId`) would not be caught here.

- **Actor / action / moment:** an ops user, renaming a client-deliverable file, on `PATCH /granting-client-access/file/:fileId`, after the file has been approved or uploaded as a deliverable. That is the only moment this emits.

- **Happy-path story (30 seconds):** an ops user fixes a typo in a deliverable's filename in Atlas. The request passes the deliverable guard, the name updates, and in the same transaction a `file.renamed.v1` row lands in `outbox_events` carrying the file id, its proceeding, the new name, who did it and when. The relay picks it up seconds later; Dione updates its filename; the client refreshes and sees the corrected name. **Without whom:** nobody re-notifies anyone, no ops user re-shares the file, and no support ticket gets filed about a name that does not match.

---

## 8. Assumptions ledger

- **Claim:** Emitting from `RenameProceedingFileTS` is impossible, not merely inadvisable.
  - **Status:** **confirmed**
  - **Confirm/revise by:** `granting-client-access.module.ts` imports `ProceedingsModule` and provides/exports `CLIENT_ACCESS_OUTBOX`; `proceedings.module.ts` has no reciprocal import. Plus `transaction-scripts.rules.ts` → `transaction-scripts-no-aggregators`, `severity: 'error'`.
- **Claim:** A new transaction script in `granting-client-access` may not call `ProceedingAggregator`.
  - **Status:** **confirmed**
  - **Confirm/revise by:** read `transaction-scripts.rules.ts` in full — the rule's `to.path` is `.*aggregator.*` with only `.port` excluded.
- **Claim:** An assembler may legally inject an aggregator, a converter and a port.
  - **Status:** **confirmed directionally** (A6)
  - **Confirm/revise by:** all four rules in `assemblers.rules.ts` forbid only assembler → assembler / transaction-script / service / mapper. **Owes an actual `npm run test:architecture` run** — reading the rules is not executing them.
- **Claim:** The outbox write enlists in our ALS transaction, so the boundary is real.
  - **Status:** **confirmed**
  - **Confirm/revise by:** `OutboxEventRepository.activeRepoForCreate()` calls `TYPEORM_OUTBOX_REPOSITORY_RESOLVER`; `src/typeorm/outbox-transaction-context.module.ts` is `@Global` and binds that token to our `TransactionContext`. Every file repository resolves through the same context.
- **Claim:** A duplicate deterministic event id silently UPDATEs the prior row rather than raising.
  - **Status:** **confirmed directionally** (A3)
  - **Confirm/revise by:** `OutboxEvent.id` is `@PrimaryColumn({type:'uuid'})` (not generated) and `OutboxEventRepository.create` ends in `repo.save()`; TypeORM's `Subject.mustBeInserted` is false when a database entity loads by PK. **Owes a real-Postgres demonstration** before being asserted as fact in the PR.
- **Claim:** `projection.fileName === projection.previousFileName` is an exact no-op signal, not a coincidence.
  - **Status:** **confirmed**
  - **Confirm/revise by:** it is literally the transaction script's own early-return condition (`:39-46`), which returns `previousFileName: fileName` and issues no `UPDATE`; the success path returns a differing pair by construction. Fragility, not correctness, is the residual — recorded as a comment plus a test.
- **Claim:** `CLIENT_DELIVERABLE` is the sole condition for "handed to the client" on this endpoint.
  - **Status:** **confirmed**
  - **Confirm/revise by:** `ProceedingFileMustBeDeliverableValidator:22` gates on `isDeliverable` alone; the symmetric submission validator rejects on `isDeliverable === true`, so dual-tagged files are handled. No approved/shared/withdrawn condition layered on.
- **Claim:** `proceedingId` is obtainable without a new query.
  - **Status:** **confirmed**
  - **Confirm/revise by:** `fetchProceedingFileForRename` returns `{file, proceedingId, trackTypeId, isDeliverable}` and the validator already calls it, then discards the result and returns `void`.
- **Claim:** The prerequisite PRDV-16293 is merged.
  - **Status:** **confirmed**
  - **Confirm/revise by:** PR #399, commit `43ad3dea`, verified as an ancestor of the working branch. Re-verified rather than inherited from the sibling ticket.
- **Claim:** `CallistoClientAccessFileRenamedV1Data` and the routekey allow-list entry already exist, so no contract or registry work is needed.
  - **Status:** **confirmed**
  - **Confirm/revise by:** ODP 1.0.7 `dist/callisto/client-access/file/renamed/v1/` exports both; `client-access-outbox-event.registry.ts` lists all seven contracts including `FILE_RENAMED`. The type has zero references in repo source today.
- **Claim:** `AuthUser.identity` is genuinely optional, so `renamedUserIdentity` needs a fallback.
  - **Status:** **confirmed**
  - **Confirm/revise by:** `src/generic/auth/constants.ts:29` declares `identity?`. Two conventions coexist in the repo; the two most recent same-module siblings use `identity?.userId ?? sub`.
- **Claim:** Widening `RenameProceedingFileProjection` would widen the AJSF endpoint's response body.
  - **Status:** **open** (A5)
  - **Confirm/revise by:** agent-reported — `JobSubmissionService.renameProceedingFile` declares `Promise<{message: string}>` but returns the aggregator's `{message, projection}`. Moot under the chosen design; verify only if the documented fallback is taken.
- **Claim:** The rename does not record who performed it on the row.
  - **Status:** **confirmed**
  - **Confirm/revise by:** `File extends BaseAuditEntity` (non-nullable `modified_user_identity`); `updateFileName` writes only `fileName` and `updatedAt`. Out of scope, but it is why the actor must come from request context.

---

## 9. Validation plan

**Happy path**

1. Rename a client-deliverable file via `PATCH /granting-client-access/file/:fileId` with a genuinely new name.
2. The deliverable validator passes and returns its loaded context.
3. The aggregator renames; the projection comes back with `fileName !== previousFileName`.
4. One outbox row is written **in the same transaction** — routekey `callisto.client-access.file.renamed.v1`, `aggregate_type = 'File'`, `aggregate_id = <fileId>`, five payload fields, `renamedAt` equal to the `Date` used for the event id.
5. The audit event dispatches **after** the transaction commits, on an unchanged payload.
6. `select … from outbox_events where event_type = 'callisto.client-access.file.renamed.v1' order by created_at desc limit 2;` shows the row. Rename again → **two distinct ids**.

**Negative paths — what must fail visibly rather than corrupt silently**

- **Non-deliverable rename:** 403 from the validator, and **no emit** and no rename attempt. This is AC3's proof.
- **Submission rename via `PATCH /proceedings/file/:fileId`:** succeeds, and writes **zero** client-access rows. Neighbour proof for surface B.
- **No-op rename** (same name, or a name that recomputes to the same value): the request succeeds and returns its message, and **nothing is emitted** — no row asserting a rename that never happened.
- **Outbox write fails:** the error **propagates and is not swallowed**, so the proxy rolls the `UPDATE` back. The caller sees a 500 and the filename is unchanged — a clean retry rather than a permanent silent divergence. This is the failure mode the whole transaction decision exists for.
- **Rename fails (duplicate name, file not found):** error propagates, no emit.
- **Emission ordering:** the write happens **after** the rename, never before — pinned by a `callOrder` array asserting `['rename','write']`.
- **`AuthUser.identity` absent:** `renamedUserIdentity` falls back to `sub`; the non-nullable contract field never receives `undefined`.
- **Timing / id derivation:** `payload.renamedAt` and the event id's `rowUpdatedAt` are the **same instant** (`toBe` identity), so a later edit cannot desync the payload from the event id.
- **Repeatability (the collision case):** two renames of the same file produce two distinct ids. **Known limitation, accepted and recorded (C7):** two renames inside the same millisecond derive the same id and the second `save()` overwrites the first. Benign only because the payload is a state snapshot — last-writer-wins converges on the correct final name, and nothing was published yet. A future `v2` adding `previousFileName` breaks that argument.

**Removed dependencies proven non-required:** no ODP change, no migration, no registry edit, no action/DTO/guard change — each asserted by the diff containing none of those files.

**Metric that proves it works, and how fast:** one `outbox_events` row per genuine deliverable rename, zero per non-deliverable or no-op rename — observable in dev within seconds of the request. The client-visible half is **not** measurable from here (RabbitMQ descoped, consumer is Dione's), which is the slow-feedback flag in §7.

---

## 10. Decisions, recommendation & open variables

**Decisions (settled this phase)**

- **D1** — Emit from a transaction-owning **assembler** in `granting-client-access`, not from the shared transaction script and not from the service. Forced by the module direction plus two `severity: 'error'` fitness rules. *(Evidence, not preference.)*
- **D2** — The outbox write goes **inside the same transaction** as the `UPDATE`; the audit SQS dispatch stays **outside**. Preserves the epic's atomicity property and avoids newly making an SQS outage roll back renames.
- **D3** — **No explicit tag re-check** at the emit site. `ProceedingFileMustBeDeliverableValidator` already guarantees it; a second check would be a provably unreachable branch. AC3 is met behaviourally. **This is the one place a reviewer may reasonably overrule** — the literal form would be `if (!context.isDeliverable) return;` using the free flag, at the cost of a dead branch.
- **D4** — `proceedingId` comes from the validator's returned context. No new query; no `src/proceedings` change. Documented fallback: widen the shared projection.
- **D5** — **User decision.** The AJSF hole is recorded as C1, not fixed. Ruling: a submitted client-deliverable file has no legitimate reason to be renamed via that route.
- **D6** — **User decision.** One `Date` generated at the emit site serves both `renamedAt` and `rowUpdatedAt`. Minimal blast radius; both are reads of the same process clock, so no source of truth is surrendered. Recorded as C4.
- **D7** — Skip the no-op branch using `fileName === previousFileName`, the transaction script's own early-return condition.
- **D8** — No feature flag, matching the module and the shipped sibling.

**Recommendation, in order**

1. Phase 3: run grill-me on the seven genuine open variables below; lock decisions; write the spec.
2. Phase 3: **submit an addendum to Larry's wiki spec** — it must carry the three Technical Design corrections (non-existent emit site, absent atomicity, the deterministic-id overwrite), the stale Diagram ④ payload, the C1 surface gap, and the C5 epic-level audit recommendation. Larry authored the spec, so this is an addendum, not a competing document. **No reviewer requested** on the PR.
3. Phase 4: implementation plan from the artifacts. No re-investigation.
4. Phase 5: **gate on Larry's response before any product code** (`P5.spec-approved`). Then implement, run all four gates, execute the test plan.

**Sequencing & gates**

- **Do not write product code until the spec response arrives.** Phase 4's plan approval is not a spec approval — it approves sequencing, not a design Larry owns. The sibling PRDV-16312 shipped on a waiver here and is *still* gated on that response; do not let this ticket inherit the same open loop by default.
- **Do not assert A3 (the silent overwrite) as fact in the PR** until demonstrated against real Postgres.
- **Do not mark the assembler shape settled** until `npm run test:architecture` has actually run.
- **Before `P5.gates`:** confirm `callisto-back-end/node_modules` is usable. The sibling's ledger records it emptied by a failed `npm ci`; verified populated (823 entries) at this phase, but re-check rather than discover it at the gate.
- **Check PRDV-16312's ledger before Phase 3 locks decisions** — if Larry's response there changes payload conventions, decisions here are affected.

### Open variables to collect

Only genuine decisions remain; every code-discoverable fact was resolved in §8.

- [ ] **The two user types.** Is story 01's user the client reading a name, or the ops user expecting their rename to land? Is story 02's the ops user protecting internal names, or the client? Neither is stated in the request, and either resolving the other way invalidates every row below Motivation in that story. — *owner:* Dustin / product
- [ ] **What replaces story 01's client-observable criteria 1–4** now that nothing client-visible is observable from Callisto (RabbitMQ descoped). *Structural evidence that this is a decision, not a lookup:* the producer's only observable output is an `outbox_events` row; there is no seam in this repo that can witness a client's view. — *owner:* Dustin
- [ ] **How story 01 criterion 1 is reworded** given C1 — it currently claims coverage this ticket does not deliver. Rewrite to what ships, or supersede story 01. **Not to be narrowed silently.** — *owner:* Dustin
- [ ] **Does any client-facing surface need to state the sync latency?** Design Q18 bounds the mechanism at seconds with no ordering guarantees; whether that must be *communicated* is a product call. — *owner:* product
- [ ] **`02.Q6` — should a failed tag/context read block the rename?** With the transaction, it currently does. An ops user blocked from renaming because a client-facing concern could not be evaluated may be worse than the leak. *Structural evidence:* the read is inside the boundary by construction, so "fail open" would require deliberately moving it out. — *owner:* Dustin
- [ ] **D3 — does the reviewer want the literal tag re-check** despite it being unreachable? — *owner:* Larry Adams
- [ ] **What the client's side does today with an event for a file it has no record of** (story `02.Q2`). *Structural evidence that Callisto cannot answer it:* the consumer is Dione's codebase, not in this workspace, and the RabbitMQ descope removed the observation step that would have shown it. Decides whether C1 is a leak or merely noise. — *owner:* Dione team

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Grill the seven open variables; lock decisions | Agent + Dustin | `specs/PRDV-16313-locked-decisions.md` exists with an `LD-###` row per variable, each citing source and spec destination |
| Accept both job stories | Agent | Index rows read `accepted`; story 01 criterion 1 either reworded on the record or story 01 in `dnu/` with a successor |
| Write the spec | Agent | `specs/PRDV-16313-spec.md` exists, all `spec-writing` sections present or N/A'd |
| Submit the spec addendum to `larry-adams` | Agent | A PR exists on `larry-adams` carrying the three Technical Design corrections + Diagram ④ + C1 + C5. No reviewer requested |
| Refine the test plan | Agent | Every scenario maps to a named criterion; status `refined` |
| Receive the reviewer's response | Larry Adams | Recorded in the ledger with form and date. **Blocks `P5.code`** |
| Implement | Agent | Diff confined to `src/granting-client-access/**`; `git diff --name-only` shows nothing under the other two module trees |
| Demonstrate A3 against real Postgres | Agent | A recorded observation showing a duplicate deterministic id UPDATEs rather than raises |
| Run all four gates | Agent | audit → lint → `test:architecture` → `npm test -- --runInBand`, each with exact command, scope, result |
| Manual outbox verification | Agent | Two renames → two distinct ids; submission rename → zero rows |

### Checklist

#### Investigation
- [x] This report (Sections 0–10)
- [x] Coverage ledger, diagrams, concerns, test-plan seed

#### Project Spec
- [ ] Grill the open variables → locked decisions
- [ ] Create project spec
- [ ] Submit addendum to the spec's author

#### Development
- [ ] Reviewer response received (**hard gate**)
- [ ] Create branch `PRDV-16313`
- [ ] Begin implementation

#### Testing & Validation
- [ ] Execute the test plan locally
- [ ] audit → lint → `test:architecture` → tests

#### Deploy & PR
- [ ] Push
- [ ] Open PR (no reviewer requested)
- [ ] Address feedback / await approval
- [ ] Merge · deploy to test

#### Ticket Closeout
- [ ] ClickUp: merged to test
- [ ] Ready for QA
- [ ] Not a bug — no root-cause writeup owed. Two *found* defects (C1, C2) recorded as follow-ups instead.

---

## 12. Definition of done (investigation gate)

- [x] Class derived from instances, re-confirmed against root cause; "reframed?" answered **no** with the justification argued (§1)
- [x] Problem Check recorded with trimmed quotes per flag, including two explicit findings and one "nothing here" (§2)
- [x] Problem in one plain sentence (§2)
- [x] Named instance — structural and reproducible, with the absence of a human complaint explained rather than hidden (§2)
- [x] Date it bites next — epic sequencing, no external date, stated as such (§2)
- [x] Wedge + why reusable within the class — second producer, first *update* on a shared path (§2)
- [x] Acceptance criteria + non-goals locked before the solution was proposed (§3)
- [x] Alternatives recorded with rejection reasons — ten, including the two a reasonable implementer would try first (§6)
- [x] 30-second happy-path story (§7)
- [x] Metric + how fast it arrives, with the slow-feedback half flagged (§9)
- [x] Verdict + disposition (§0)
- [x] Every open question reconciled — 8 of 15 story questions closed by evidence in §8; only genuine decisions in §10, each with an owner and, where the structure cannot answer it, the evidence proving so
- [x] Tracked actions with falsifiable done-whens (§11)
