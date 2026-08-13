---
ticket: PRDV-16313
tags: [callisto, granting-client-access, outbox, file-renamed, concerns]
author: Dustin Thomason
created: 2026-08-11
modified: 2026-08-11
---

# PRDV-16313 — Future-development concerns (deliverable rename event emission)

> **Context:** PRDV-16313 adds `callisto.client-access.file.renamed.v1` to the deliverable rename path. The investigation found two latent defects, one architectural constraint worth naming, and one epic-level process gap — none of which are being fixed in scope.
> **Purpose of this document:** a dated, code-verified record that these risks were identified and raised — for team discussion and, where needed, escalation.
> **Constructive path forward:** C1 and C5 are the two that need someone else's decision; both have a named smallest change. C2 is an independent bug ticket. C3, C4, C6 and C7 are recorded so a future reader does not mistake a deliberate tradeoff for an oversight.

## Executive summary (for escalation)

**Two things here deserve someone's attention beyond this ticket.**

**First — a client-deliverable file can be renamed through a route that has no authenticated user, no deliverable check, and no audit trail.** `PATCH /<ajsf>/file/:fileId` reaches the shared rename transaction script directly. Renaming a client deliverable through it changes what the client is entitled to see, records **nobody** as having done it, and (after this ticket ships) emits **no event** — so Planet Portal keeps the old name indefinitely with no trace on either side. The fallout is not "an event is missed": it is that a client-facing document can be renamed with no attribution and no notification, and nothing anywhere would show it happened. Probability is low — the workflow is not believed to produce it (see C1's decision history) — but the failure is silent and unbounded in time, which is why it is written down rather than assumed away.

**Second — the design doc's event-coverage audit only examined one of the three modules that can perform these writes.** That audit is why surface C above is absent from this ticket's spec. **Five more events in this epic are still unbuilt** (approve, unapprove, recategorize, collection-deleted, grants-replaced), and each will be specced from the same audit. If the audit missed a rename surface, it plausibly missed an approve or delete surface too — and a missed *delete* surface means a client keeps seeing a file that was withdrawn, which is materially worse than a stale name.

**Decision requested — from the epic owner (Larry Adams), on the second point:**
(a) re-run the coverage audit across `proceedings` and `proceeding-job-submission` before the next sibling ticket is specced — recommended, and cheapest now;
(b) audit per-ticket as each sibling is picked up, accepting that each spec starts from a known-incomplete source;
(c) accept the gap and handle misses reactively when Dione reports divergence.

**On the first point, a decision has already been taken by Dustin Thomason (2026-08-11) — recorded in C1 — to leave it out of scope.** It is surfaced here as a caution, not reopened.

---

## Concern 1 — the AJSF rename route can rename a client deliverable with no user, no validator, and no audit

`PATCH /<ajsf>/file/:fileId` → `RenameAjsfProceedingFileAction` → `JobSubmissionService.renameProceedingFile(fileId, newName)` → `ProceedingAggregator.renameProceedingFile` → the shared `RenameProceedingFileTS`.

Compare the two sibling routes, both of which do the right thing:

| | `granting-client-access` (A) | `proceedings` (B) | **AJSF (C)** |
| --- | --- | --- | --- |
| Deliverable/submission validator | `ProceedingFileMustBeDeliverableValidator` | `ProceedingFileMustBeSubmissionValidator` | **none** |
| Authenticated user captured | `@VerifiedUserDecorator()` | `@VerifiedUserDecorator()` | **none** |
| Audit event dispatched | yes | yes | **none** |
| Emits `file.renamed.v1` after this ticket | yes | n/a (not a deliverable) | **no** |

**Why this ticket makes it worth recording rather than merely noting.** Before PRDV-16313, no rename route emitted anything, so surface C was simply one of three equally silent paths. After it, A announces and C does not — the inconsistency becomes load-bearing, because Dione will now trust that a filename it holds is current unless told otherwise. A rename via C makes that trust wrong.

It also means **job story 01 criterion 1 is knowingly not fully met** (*"when someone changes the name of a file the client has been given, the client sees the new name"*). That is recorded in the story rather than reworded to fit the build.

- **Evidence (verified 2026-08-11):**
  - `src/proceeding-job-submission/application/controllers/actions/rename-ajsf-proceeding-file-action/rename-ajsf-proceeding-file.action.ts:14-24` — guard is `AjsfSubmissionProceedingFilesUpdateAuthGuard` only; the `apply` signature takes `fileId` and `dto` and **no** `@VerifiedUserDecorator()`.
  - `src/proceeding-job-submission/domain/services/job-submission-service/job-submission.service.ts:163-171` — `renameProceedingFile(fileId, newName)` calls the aggregator directly; no validator, no audit dispatch.
  - `src/proceedings/domain/aggregators/proceeding.aggregator.ts:129-144` — the shared entry point.
  - `src/granting-client-access/validators/proceeding-file-must-be-deliverable.validator.ts:16-27` and `src/proceedings/validators/proceeding-file-must-be-submission.validator.ts:22` — the guards the other two routes have.
  - `src/proceedings/infrastructure/repositories/proceeding-file.repository.ts:170-197` — the query has no tag filter, so it returns deliverables happily with `isDeliverable: true`.
- **What would resolve it:** the smallest change is ~6 lines and boundary-legal — add `renameSubmissionProceedingFile(fileId, newName)` to `ProceedingAggregator` (validator, then the existing rename) and call it from `JobSubmissionService:163`. `proceeding-job-submission` already imports `ProceedingsModule` and injects the aggregator, and `*.aggregator.ts` is an allowed cross-module target, so no new import boundary is crossed. A direct import of the validator from `proceeding-job-submission` **would** violate the domain-boundary rule — do not do that. Effect: an AJSF rename of a deliverable returns 403 instead of silently desyncing. Airtight even for dual-tagged files, since the submission validator rejects on `isDeliverable === true` rather than asserting the submission tag.
  Fully closing it (rather than blocking it) additionally needs `@VerifiedUserDecorator()` on the action, the missing `dispatchFileAuditRenamedEvent`, and then routing C through the emit path. That is a ticket, not a line — `renamedUserIdentity` is non-nullable in the contract and that route has no identity to supply, so inventing a `'system'` sentinel would write a falsehood into a field the consumer surfaces.
- **Interim exposure if nothing is done:** any principal holding `AJSF_SUBMISSION_PROCEEDING_FILES:UPDATE` can rename a client deliverable; Planet Portal holds the old name indefinitely; no audit row exists to show who did it or when.

## Concern 2 — a file with no extension gets its entire old filename appended on rename

`RenameProceedingFileTS` preserves the extension by slicing from the last dot:

```
const lastDotIndex = fileName.lastIndexOf('.');
const newFileName = `${newName}${fileName.substring(lastDotIndex)}`;
```

When the current filename contains **no dot**, `lastIndexOf('.')` returns `-1`, and `String.prototype.substring` clamps a negative argument to `0` — so `fileName.substring(-1)` returns the **whole** filename. Renaming a file called `transcript` to `final` produces `finaltranscript`.

**This is pre-existing and this ticket does not cause it.** It is recorded here because this ticket **makes it visible to the client**: the mangled name is what lands in the event payload's `fileName` and therefore what Planet Portal displays. Today the damage stops at Atlas.

- **Evidence (verified 2026-08-11):** `src/proceedings/domain/transaction-scripts/rename-proceeding-file-ts/rename-proceeding-file.transaction.script.ts:37-38`. Affects all three rename surfaces (A, B, C) since they share this script.
- **Unverified aspect, labelled as such:** how reachable this is in practice was **not** investigated — whether any upload path can produce an extensionless `files.file_name`, and whether real data contains any. That is the first thing a fix ticket should establish, because it decides severity.
- **What would resolve it:** a separate bug ticket. The fix is one line (`lastDotIndex === -1 ? '' : fileName.substring(lastDotIndex)`) plus a spec case, but it changes rename behaviour for three surfaces and therefore does not belong inside an emission ticket — see the class boundary in report §1.

## Concern 3 — the emitting class is an assembler that is really a transaction script

The class that owns the transaction and orchestrates the command is named `*.assembler.ts`, which is not what an assembler is for. This is **forced, not chosen**.

- **Evidence (verified 2026-08-11):**
  - `fitness-functions-rules/architecture-rules/transaction-scripts.rules.ts:26-44` — `transaction-scripts-no-aggregators`, `severity: 'error'`: a `*.transaction.script.ts` may not import `.*aggregator.*`. So a correctly-named `RenameDeliverableFileTS` delegating to `ProceedingAggregator` fails `npm run test:architecture`.
  - `fitness-functions-rules/architecture-rules/services.rules.ts:31-36` — `services-no-converters`, `severity: 'error'`: so the service cannot hold the payload converter either.
  - `fitness-functions-rules/architecture-rules/assemblers.rules.ts:11-43` — forbids assembler → assembler / transaction-script / service / mapper, and nothing else. Assembler → aggregator, → converter, → port are all permitted.
  - `src/proceedings/providers/persist-video-transcode-derivative-mapper.provider.ts` — precedent for wrapping a non-transaction-script in `createTransactionalProxy`.
- **The risk being recorded:** a future maintainer reads the class, correctly identifies it as a mis-named transaction script, "fixes" the name, and the build breaks — or worse, they route around the rule by re-implementing the rename inside a real TS, forking the extension-preservation, lineage and duplicate-name rules into a second writer of `files.file_name`. Mitigated in-ticket by a header comment naming the constraint, but a comment is weaker than the rule that caused it.
- **What would resolve it:** either a fitness-rule amendment permitting a narrow transaction-script → aggregator case, or a sanctioned suffix for "transaction-owning orchestrator that delegates across modules". Worth raising with whoever owns the architecture rules; not this ticket's call.

## Concern 4 — `renamedAt` is a few milliseconds later than the row's `updated_at`

The payload's `renamedAt` and the outbox event id's `rowUpdatedAt` are one `Date` generated at the emit site. They agree with each other by construction; neither equals the `files.updated_at` value actually persisted, because `updateFileName` mints its own `new Date()` internally and returns nothing.

- **Evidence (verified 2026-08-11):** `src/proceedings/infrastructure/repositories/proceeding-file.repository.ts:133-138` — `repo.update(id, { fileName, updatedAt: new Date() })`, no return value. Event id derivation: `src/generic/outbox-projector/domain/deterministic-event-id.helper.ts` — uuidv5 over `runnerName|aggregateType|aggregateId|rowUpdatedAt.getTime()|eventType`.
- **Why it is acceptable today:** both values are reads of the **same process clock**, not a DB `now()` — so there is no source-of-truth difference being surrendered, only a few ms of precision. Nothing re-derives the event id from the row: design Q5 rules projection-driven emission an antipattern for this epic, and no `File`-aggregate projector runner exists. Ids are also namespaced by `runnerName = 'granting-client-access-command'`, so a future projector could not collide with these rows even if one were added.
- **Decision:** taken by Dustin Thomason on 2026-08-11, explicitly on minimal-blast-radius grounds. The alternative — threading the persisted instant out of `updateFileName` — ripples into `src/proceedings` (repository signature, projection type, transaction script, ~13 mechanical spec edits) and widens what the AJSF endpoint returns in its response body.
- **What would resolve it, if it ever matters:** it matters only if someone adds a backfill or reconciler that recomputes ids from `files.updated_at` — such a job would duplicate rather than dedupe against these rows. At that point, thread the instant out. Verified feasible: TypeORM does not overwrite an explicitly-set `@UpdateDateColumn`, so `updateFileName` can safely accept and return the caller's `Date`.

## Concern 5 — the epic's event-coverage audit examined only one of three modules

The design doc's coverage decision for this event rests on an audit titled *"full audit of `granting-client-access` write operations"* — and that is literally its scope. It enumerated seven `granting-client-access` endpoints and mapped each to an event. It never examined `proceedings` or `proceeding-job-submission`, which is precisely why surface C (C1 above) is absent from this ticket's spec despite being able to perform the same write.

**Five sibling events remain unbuilt** and will each be specced from the same audit: `file.approved`, `file.unapproved`, `file.recategorized`, `collection.deleted`, `grants.replaced`. A missed *delete* or *unapprove* surface is worse than a missed rename — a client continuing to see a withdrawn file is a disclosure problem, not a cosmetic one.

- **Evidence (verified 2026-08-11):** `larry-adams/.../dione-file-access-event-design.md:1380-1440` — the audit table and its "File rename coverage" decision; the design's own Q22 answer says *"I would also take another run through the granting-client-access module's actions"*, scoping the re-examination to that one module. Surface enumeration for rename in this repo found four routes across three modules (report §7).
- **What would resolve it:** re-run the audit across `proceedings` and `proceeding-job-submission` for every write that touches a `CLIENT_DELIVERABLE`-tagged file, before the next sibling ticket is specced. The method is already proven — grep every writer of the relevant column, then check each HTTP surface that reaches it for a validator, a user, and an audit dispatch.
- **Escalation:** this is the item in the executive summary needing the epic owner's decision.

## Concern 6 — `fetchProceedingFileForRename` runs twice per rename request

The validator calls it and discards the projection (returns `void`); `RenameProceedingFileTS` calls it again and uses part of the result. Two identical queries per request.

- **Evidence (verified 2026-08-11):** `src/granting-client-access/validators/proceeding-file-must-be-deliverable.validator.ts:16-27` (loads, then returns `void`); `src/proceedings/domain/transaction-scripts/rename-proceeding-file-ts/rename-proceeding-file.transaction.script.ts:26-34` (loads again). Each call additionally performs a nested `checkFileAttachmentHasTag` query (`proceeding-file.repository.ts:219-244`).
- **Pre-existing, and this ticket does not worsen it.** It arguably makes it marginally more defensible: the design consumes the first read's previously-discarded result to obtain `proceedingId`, so no *third* read is introduced. Rename is a low-frequency ops action, so the cost is not the point — the duplication is.
- **What would resolve it:** collapse the two reads by having the validator return its context and the transaction script accept it. That is a behaviour-neutral refactor of `proceedings` internals shared by three surfaces, so it belongs in its own ticket. Note the ordering constraint any such refactor must preserve: the deliverable check must stay **before** the write, or a 403 becomes a rename-then-403.

## Concern 7 — the collision argument depends on the payload having no `previousFileName`

A duplicate deterministic event id does not raise — it **silently UPDATEs** the existing outbox row, overwriting `data`, resetting `status` to `PENDING` and `attempts` to `0`, with no exception and no log. Two genuine renames of the same file inside the same millisecond therefore collapse to one event.

That is tolerable **only** because `CallistoClientAccessFileRenamedV1Data` is a state snapshot: it carries `fileName` and no `previousFileName`, so last-writer-wins converges on the correct final name and the client ends up right. **If a `v2` ever adds `previousFileName`, or any delta-shaped field, the overwrite becomes lossy** and this reasoning silently stops holding.

Two corollaries worth recording so nobody "improves" this in the wrong direction:

- **`ON CONFLICT DO NOTHING` would be worse, not better.** It preserves the *first*, stale payload; the current `save()` behaviour preserves the later, correct one.
- **A wall-clock step backwards** (NTP correction, or two pods with skewed clocks) could in principle let a stale payload survive. Window is one millisecond per file. The airtight fix — folding a monotonic discriminator into `DeterministicEventIdHelper` — would change id derivation shared with the already-shipped `file.created.v1` and the `proceedings-command` runner, so it is firmly out of scope.

- **Evidence (verified 2026-08-11, from source — NOT observed):** `node_modules/@planetdepos/orbital-relay-pkg/dist/outbox/domain/entities/outbox-event.entity.js` — `id` is `@PrimaryColumn({type:'uuid'})`, not generated; `.../infrastructure/repositories/outbox-event.repository.js` — `create()` ends in `repo.save(outboxEvent)`. TypeORM sets `mustBeInserted` false when a database entity loads by primary key. Contract shape: ODP 1.0.7 `dist/callisto/client-access/file/renamed/v1/`.
- **Labelled unverified:** this is report assumption **A3, confirmed directionally only**. It is read from library and TypeORM source and has **not** been demonstrated against a real database. It must not be asserted as fact in the PR body until it has been.
- **What would resolve it:** a comment on the converter recording the snapshot dependency (in-ticket), plus a note on the ODP contract so a future `v2` author sees the constraint before adding a delta field. Also worth flagging to whoever owns `orbital-relay-pkg`: a silent overwrite on a deterministic-id collision is surprising behaviour for an outbox, and a log line would cost nothing.

## Concern 8 — fail-closed means a client-facing concern can block an ops user's rename

**Cited by LD-010.** A failed outbox write rolls back the rename: the ops user gets a 500 and the filename is unchanged, even though the rename itself was perfectly valid. The thing that failed was the *announcement*, and the user is denied the *action*.

This was chosen deliberately over fail-open, and the reasoning holds — but it is a real accepted cost, not a free win, so it is recorded rather than presented as obviously correct.

**Why fail-closed anyway:**

- Fail-open reintroduces the exact defect this ticket exists to remove — renamed, no event, client stale indefinitely — and design Q5 forbids the projection-driven reconciler that would repair it. There is no backstop.
- It matches the only existing producer: **no try/catch** around the `file.created.v1` write, and **zero catch blocks** in either outbox infrastructure tree. Fail-open here would be the codebase's only swallowed outbox write, i.e. two rules in one module.

**What it costs, plainly:** any outage that breaks the outbox `INSERT` also breaks renaming for deliverable files. The blast radius of an outbox problem grows from "events stop flowing" to "ops users cannot rename." Renaming is low-frequency, so the practical exposure is small — but it is wider than before this ticket, and that is new.

> **Correction 2026-08-11.** Earlier artifacts described the *non-transactional* failure as "silent." **It is not.** The outbox error propagates and the caller receives a 500. The accurate statement of the defect is: **the request reports failure after the filename has already committed, and no event exists** — an inconsistency reported as a failure, not a silent one. That is worse in one respect (the caller may retry a rename that already succeeded) and better in another (something is observable). Fail-closed with a transaction removes the inconsistency; it does not remove the 500.

- **Evidence (verified 2026-08-11):** `src/granting-client-access/domain/transaction-scripts/upload-complete-deliverable-file-ts/upload-complete-deliverable-file.transaction.script.ts:50-115` — the `apply` body has no `try`/`catch`; the outbox `write` sits bare after `deliverableFileRepository.create`. `grep -rn "catch" src/proceedings/infrastructure/outbox src/granting-client-access/infrastructure/outbox` → no non-spec matches. Transaction boundary: `src/typeorm/infrastructure/factories/transactional-proxy.factory.ts`.
- **Decision:** grilled and confirmed by Dustin Thomason, 2026-08-11, in the narrowed form the `P3.reconcile` pass produced ("precedent is fail-closed — deviate or match?").
- **What would resolve it, if it ever bites:** the escape hatch is not fail-open. It is making the outbox `INSERT` unable to fail for ordinary reasons — which it largely already is, being a local `INSERT` inside a transaction that is already open. If it does start failing in practice, the correct response is to find out why rather than to start swallowing it. A middle path exists but is worse than both: catching and re-queueing to a local retry table reinvents the outbox inside the outbox.

## Concern 9 — story 01's criteria assert something this ticket cannot observe, and were restated rather than proven

**Cited by LD-015 and LD-017.** Story 01's user is the **client** (grilled and confirmed), so its criteria are written in terms of what a client sees. This ticket's boundary ends at an `outbox_events` row: RabbitMQ is descoped epic-wide, and Dione's consumer is another team's codebase. **No surface in this repo can witness a client's view.**

Two distinct honesty problems fell out of that, both recorded rather than papered over:

1. **Criterion 1 claimed more coverage than the ticket delivers.** *"When someone on the deposition team changes the name of a file the client has been given, the client sees the new name"* is false via the AJSF route (C1). It has been **narrowed to the ops deliverables workflow**, with the gap named in the story's own Story log and index.
2. **Criteria 1–4 are not end-to-end verifiable here.** They were restated to what is falsifiable inside the ticket, following the sibling's precedent (PRDV-16312's LD-007 did exactly this to one criterion in each of its two stories after the same descope).

**Why this is a concern and not just bookkeeping.** Restating a criterion to match what can be proven is one letter away from reinterpreting it to match what was built — which the job-story rule names as a specific failure. The distinction here is that the *scope* was bounded first, by two decisions taken before any code existed (the RabbitMQ descope by the epic owner; C1 by the user), and the criteria followed. But a future reader cannot see that ordering unless it is written down, which is what this entry is for.

**The residual risk is a real one:** a payload that is correctly *shaped* but semantically wrong — the right five keys with the wrong `proceedingId` — passes every test in this ticket. Nothing here proves the client ends up seeing the right thing about the right file. Test plan M-1's `proceedingId` check is the only guard, and it is a spot check by a human.

- **Evidence (verified 2026-08-11):** RabbitMQ descope — upstream commit `318bd0a`, *"PRDV-15736: remove rabbitMQ work from scope of epic"*, applied across nine sibling specs. Sibling precedent — `docs/atlas/PRDV-16312/specs/PRDV-16312-locked-decisions.md` LD-007 and both story Story logs. Design Q18 — eventual consistency, seconds-scale, no ordering guarantees.
- **What would resolve it:** end-to-end verification requires Dione's consumer, which arrives on the epic's schedule, not this ticket's. Until then the honest statement is that this ticket proves the **producer** correct and asserts nothing about the client's view. Worth a follow-up once Dione consumes: walk story 01's original criteria 1–4 against real client behaviour and confirm the restated versions were sufficient.
- **Minor residual, folded in from LD-016:** an ops user who fixes a filename and immediately tells the client to refresh may hit the seconds-scale window and have the old name reported as a bug. Recorded rather than designed around; no criterion carries a time bound.

## Concern 10 — deliverability is established outside the transaction that emits, and the tag is mutable

**Cited by LD-019.** `ProceedingFileMustBeDeliverableValidator` runs at request entry, **outside** the rename/outbox transaction. The `CLIENT_DELIVERABLE` tag can be added *and* removed after file creation. So there is a window between "we checked this file is a client deliverable" and "we renamed it and told the client's system about it."

**Why the earlier framing was wrong, recorded because it matters.** This was originally written up as settled — a re-check would be "a provably unreachable branch," therefore AC3 is met. That conflates two different things:

- **Re-reading the same returned `isDeliverable` value** inside the transaction — genuinely dead code, and correctly rejected.
- **A fresh in-transaction read** — a different guarantee entirely. It answers whether the file is *still* deliverable at the moment the event commits.

The first was analysed; the second was not, and the conclusion "AC3 is met structurally" was stated more strongly than the evidence supports. It is met **at request entry**. It is **not** established as a transaction-time invariant.

**What could actually go wrong:** an unapprove lands between validation and commit. The rename proceeds and emits a client-access event for a file that is, by then, no longer a client deliverable. Dione updates a filename for something that should no longer be visible. Narrow window, real semantics.

- **Evidence (verified 2026-08-11):** validator at `src/granting-client-access/validators/proceeding-file-must-be-deliverable.validator.ts:16-27`, called first in `deliverable-rename.service.ts:20` — **before** the assembler's transactional boundary. Tag added at `approve-deliverable-files.transaction.script.ts:157-161`; removed at `unapprove-deliverable-files.transaction.script.ts:119-131` and `remove-deliverable-tag.transaction.script.ts:104-107`. No inverse relation exists on `File`/`FileAttachment`, so every tag read is its own query.
- **Status: open — question 2 for the reviewer.** Does AC3 mean deliverable at request validation, or deliverable inside the rename/outbox transaction?
- **Default while awaiting an answer:** retain the existing endpoint validator — the lower-blast-radius choice — and **disclose this window as an accepted risk rather than claiming the stronger invariant holds.**
- **What would resolve it:** if strict transaction-time enforcement is required, perform a fresh deliverability read inside the transaction with appropriate row locking. That is a small change but it is not free: it adds a query inside the boundary and needs a decision about what to do when the answer flips mid-request (fail the rename, or rename without emitting?).

---

## Decision history

- **2026-07-16 / 2026-07-20** — Larry Adams authors the wiki spec for PRDV-16313. Its Technical Design names "the rename transaction script" and justifies its tag guard with *"the rename endpoint may serve non-deliverable files as well."* Both were true of the pre-split code.
- **(earlier) commit `4d284978`** — PRDV-15776, *"Split proceeding file rename by deliverable vs submission"*, restructures the rename path into a service plus a shared cross-module transaction script with symmetric validators. This is what makes the spec's premise stale, and it predates the spec — so the spec was written against code that had already moved.
- **2026-08-11, Phase 1 recon** — the three Technical Design defects are found by tracing the spec's instructions into code. Surface C is found by exhaustive rename-surface enumeration; it was not in the spec because the design's coverage audit never examined its module (C5).
- **2026-08-11** — **Dustin Thomason rules C1 out of scope**, on the workflow grounds that a submitted client deliverable has no legitimate reason to be renamed: *"There should be no circumstance where a file from the user could be renamed once it is submitted… Once it is declared a client deliverable, there would be no reason for a user to ever change the name."* Recorded as a caution with a follow-up rather than bundled in. The agent had offered an in-ticket guard as the recommended option; the ruling was to record instead.
- **2026-08-11** — **Dustin Thomason rules on the timestamp source** (C4): generate at the emit site, on minimal-blast-radius grounds, rather than threading the persisted instant out of `updateFileName` and rippling into `src/proceedings`.
- **2026-08-11** — the assembler shape (C3) is selected by *elimination*, not preference: the module dependency direction rules out the shared transaction script, `transaction-scripts-no-aggregators` rules out a new transaction script, and `services-no-converters` rules out the service.

## Open questions to settle

1. **Re-run the epic's coverage audit across `proceedings` and `proceeding-job-submission` before the next sibling ticket?** (C5 — the escalation item) — owner: Larry Adams / epic owner
2. **Does C1 warrant its own ticket now, or does the workflow ruling close it?** The ruling makes it unlikely, not impossible, and the failure is silent. — owner: Dustin Thomason
3. **Is the extensionless-filename case reachable with real data?** (C2) Decides whether it is a latent curiosity or a live bug. — owner: whoever picks up the bug ticket
4. **Is a fitness-rule amendment wanted for the transaction-script → aggregator case**, or is the assembler workaround the accepted house answer? (C3) — owner: architecture-rules owner
5. **Should `orbital-relay-pkg` log or reject a deterministic-id collision** instead of silently overwriting? (C7) — owner: `orbital-relay-pkg` maintainer
6. **Does the reviewer want the literal tag re-check** at the emit site despite it being provably unreachable? — owner: Larry Adams
