---
ticket: INT-138
tags: [atlas, callisto, europa, audit, concerns]
author: Dustin Thomason
created: 2026-09-23
modified: 2026-09-23
---

# INT-138 — Future-development concerns (Categorize audit events)

> **Context:** INT-138 adds a Categorize audit event from Callisto's categorization write paths, and registers it on the Europa audit page in Atlas. While tracing that path, the recon found six risks next to it that this ticket will **not** fix.
> **Purpose of this document:** a dated, code-verified record that these risks were identified and raised, for team discussion and, where needed, escalation.
> **Constructive path forward:** none is proposed inside INT-138. Each concern names the smallest follow-up that would close it.

## Executive summary (for escalation)

The audit log is treated as the "who, what, when" record for Client Access. Three of these concerns weaken that promise quietly:

- **C1:** anyone with an Atlas login can read, and delete, the audit log through Europa's API, because Europa checks tokens but not roles.
- **C2:** if the queue send fails, the audit record is lost with only a log line, while the user's action succeeds.
- **C3:** deleting a collection or deliverable type silently clears it from files, with no audit at all.

None blocks INT-138. The decision requested from someone who owns the audit posture: (a) accept these as-is; (b) open follow-up tickets for C1 and C2; or (c) fold C2 into INT-138's spec, which would widen scope.

## Concern C1 — Europa's audit API has no role checks

The Atlas route requires `AUDIT` + `READ`, but Europa's own API enforces authentication only. A caller with any valid Atlas token can query `GET /europa/audit-events/search-paginated` directly. `DELETE /audit-events` is also unguarded, despite the README calling it "admin".

- **Evidence (verified 2026-09-23, europa `1082fdad`):** `src/generic/auth/auth.module.ts:48-73` (middleware only); `application/middlewares/auth.middleware.ts:27-51` (roles only logged, `:45`); no `UseGuards`, `CanActivate` or `APP_GUARD` anywhere in `src`. Atlas route guard: `atlas-front-end` `src/globalRouter/routes.ts:35-52`. PRDV-16192's ledger had already listed this as out of scope.
- **What would resolve it:** a role guard on the Europa audit controller mirroring `AUDIT` + `READ` (and an admin check for delete). That is a separate ticket.

## Concern C2 — A failed audit send is silently lost

`SQSAuditEventProducer.apply` catches send failures, logs them and returns `false`. Callers await it but don't act on `false`. The user's action succeeds and Europa never gets the record. INT-138's new event will behave the same way (a parity choice).

- **Evidence (verified 2026-09-23, callisto `59b1abd3`):** `SQSAuditEventProducer.apply:19-35`; the dispatch is awaited after the TS in `deliverable-upload.service.ts:112-115` and `approve-deliverable-files-v2.service.ts:140-146`. The producer also sends to the fixed name `SQS_AUDIT_EVENT_URL_OUTBOUND`, which matches the registered producer only when `AUDIT_EVENT_QUEUE_NAME` is unset or equal to it (`audits.module.ts:13-25`). A misconfiguration there would drop **every** audit silently.
- **What would resolve it:** route audits through the transactional outbox already used for Dione, or at least alert on `false`. That is a separate ticket.

## Concern C3 — Deleting a collection or type clears categorization with no audit

Both foreign keys on `file_attachments` are `ON DELETE SET NULL`. Deleting a collection is blocked while active files use it, but soft-deleted files are still nulled. Nothing emits an audit for that change, so a file's categorization can change with no Categorize record.

- **Evidence (verified 2026-09-23, callisto `59b1abd3`):** migrations `1775761245349` and `1781121204473`.
- **What would resolve it:** audit collection and type deletion as its own event, or restrict the FK. A separate ticket.

## Concern C4 — Atlas's event-type list is hand-copied from Callisto's and can drift

Atlas's `eventTypes` duplicates Callisto's `AUDIT_EVENT_TYPE` by hand. It already disagrees with it (Atlas lists `MOVED` and `UPDATED`, which Callisto never sends). Europa's filter is an exact, case-sensitive match, so any mismatch makes that filter option return nothing, and nothing reports the error.

- **Evidence (verified 2026-09-23):** `atlas-front-end` `src/europa/utils/constants.ts:3-15`; `callisto-back-end` `src/audits/constants.ts:10-19`; `europa-back-end` `search-params-to-mongo-query.converter.ts:38-40`.
- **What would resolve it:** INT-138's test plan adds a literal-equality test for the new entry (NP-6). A shared constants package, or a Europa endpoint that lists distinct types, would close the whole class. That is a separate ticket.

## Concern C5 — Unapprove clears a file's categorization without a Categorize record

Unapprove sets the file's collection and type to null and emits `UNAPPROVED`. Whether that counts as a categorization action is part of decision D1. If D1 excludes it (the current recommendation), the log will show a Categorize record setting a type and no Categorize record clearing it.

- **Evidence (verified 2026-09-23, callisto `59b1abd3`):** `unapprove-deliverable-files.transaction.script.ts:152-159`.
- **What would resolve it:** D1 names unapprove explicitly, either way, so the gap is a decision on the record rather than something nobody noticed.

## Concern C6 — The recategorize request DTO describes the wrong kind of id

The recategorize request DTO documents `files[].id` as a "file attachment" id, but the code treats it as a file id. The swagger is misleading to callers.

- **Evidence (verified 2026-09-23, callisto `59b1abd3`):** `recategorize-batch-files.converter.ts:17-27` and the recategorize request DTO's `files[].id` description.
- **What would resolve it:** correct the description. This is a one-line fix and could be folded into INT-138 if the spec touches that DTO; otherwise it is a follow-up.

## Concern C7 — Categorizations made before release are not in the log (LD-011)

There is no backfill. The log starts on the release date, so an Ops review of a file categorized earlier shows no Categorize record. A backfill would have to invent the who and the when: `file_attachments` keeps only the current ids and no modified-by identity, and recategorize never audited.

- **Evidence (verified 2026-09-23, callisto `59b1abd3`):** `file-attachment.entity.ts:39-54`; `recategorize-deliverable-files.service.ts:24-44`; PRDV-16313 coverage ledger area 10.
- **What would resolve it:** nothing honest. Communicate the start date with the release, so an empty history before it is read correctly.

## Concern C8 — Planet Summary records for summaries requested before release name no user (LD-012)

The requester's identity is captured when a summary is requested. A summary requested before the release completes afterward with no stored identity. Its Categorize record then carries only the user id, which Europa stores but doesn't display, so User Email and User Name are blank for that row.

- **Evidence (verified 2026-09-25):** `MercuryProceedingFileTranscriptSummaryCompletedV1Data` carries only `createdUserIdentity`; `file-derivation-job.entity.ts` has no requester email/name columns; Callisto has no user lookup by id; Europa's projection returns `userEmail`/`userName` but not `userId` (`search-audit-events-paginated.transaction.script.ts:88-103`).
- **What would resolve it:** it resolves itself once in-flight summaries complete (minutes to hours). No action unless Ops reviews that window.

## Concern C9 — The v1 approve DTO says the type is ignored, but the code writes it

`approve-files-for-delivery.request.dto.ts:38-46` documents `deliverableTypeId` as "Optional on the v1 endpoint and ignored there". The shared TS writes it anyway (`approve-deliverable-files.transaction.script.ts:152`, `:369-372`). INT-138 follows the code, so v1 emits a Categorize record whenever it sets a type or collection. The misleading Swagger text stays as it is.

- **Evidence (verified 2026-09-25, callisto `59b1abd3`):** as cited above (spec Part B Notes).
- **What would resolve it:** a one-line doc fix on the DTO, or removing the v1 type write if "ignored" was the intent. The code owner decides which.

## Concern C10 — Planet Summary derived files may be attributed to the transcript's creator, not the requester

Callisto sends Mercury `createdUserIdentity: file.createdUserIdentity`, which is the transcript's creator. The completion handler then uses the echoed value for the derived `File` and `FileDerivation` rows. So those rows likely name the transcript's creator as their creator, even when someone else requested the summary. INT-138's audit record avoids this by using `pendingJob.createdUserIdentity`, the requester.

- **Evidence (verified 2026-09-25):** `create-summary.transaction.script.ts:90, 122-124`; `transcript-summary-requested.dispatcher.ts:44`; `persist-transcript-summary-derivatives.mapper.ts:132-133,152-153`; `process-proceeding-transcript-summary-completed.service.ts:115`. What Mercury actually echoes back is unverified, because Mercury isn't in this workspace.
- **What would resolve it:** attribute the derived rows from `pendingJob.createdUserIdentity`. That is a separate ticket.

## Concern C11 — Concurrent completions for one summary job can create duplicate derived files

`findPendingByFileIdAndProcessType` doesn't lock, and `markCompleted` is an unconditional update. Two completion envelopes for the same job, processed concurrently or reclaimed after a lock timeout, can both persist derived files. Each would get its own Categorize record, so the audit still matches the data, but the data is duplicated.

- **Evidence (verified 2026-09-25):** `file-derivation-job.repository.ts:65-76,150-166`; inbox claims use `FOR UPDATE SKIP LOCKED` (`orbital-receiver-pkg/.../inbox-event.repository.js:80`). This predates INT-138.
- **What would resolve it:** make `markCompleted` conditional on `status = 'pending'` and throw on 0 affected rows, so the losing transaction rolls back. That is a separate ticket.

## Concern C12 — On Windows, callisto's `test:conventions` reports success without scanning

Several convention checks (`check-domain-naming`, `check-dto-structure`, `check-domain-type-structure`, `check-no-util-files`, `check-exchange-ownership`) shell out to `find`. On Windows, Node runs that through `cmd.exe`, which resolves `find` to Windows `find.exe`. That prints "The system cannot find the path specified", and the scripts swallow the error and report success. The pre-commit hook runs these checks, so on a Windows machine it passes naming and type-structure violations without flagging them.

- **Evidence (observed 2026-09-25, callisto `59b1abd3`, INT-138 Part A implementation):** a plain `npm run test:conventions` printed the path error and exited 0. The same scripts run with `COMSPEC` pointed at Git Bash scanned the new files for real.
- **What would resolve it:** use a Node file walk (`fs.readdirSync` recursion or `fast-glob`) instead of shelling out to `find`, or fail loudly when the `find` command errors. That is a separate ticket.

## Concern C13 — The CATEGORIZE display string is written into `path` at write time (a three-repo convention)

- **Callisto writes** the finished display string (`Filepath: … | Deliverable Type: … | Collection: …`) into `oldState.path` / `newState.path` when the event is created.
- **Europa passes it through** unchanged.
- **Atlas parses** it, using `MULTI_PART_PATH_TYPES` and the `' | '` / `': '` separators.

The sibling multi-part type, `PERMISSIONS_UPDATED`, works differently: Europa composes its string at read time. So INT-138 sets a new convention that spans three repos, and it reuses a field named `path` to hold non-path text. Once written, the labels can't be changed or localized for stored events.

- **Evidence (verified 2026-09-25):**
  - callisto `proceeding-file-categorization-to-audit.converter.ts` (`toCategorizationPath`);
  - europa `search-audit-events-paginated.transaction.script.ts:62-72` (PERMISSIONS_UPDATED built at read time);
  - atlas `src/europa/utils/constants.ts` `MULTI_PART_PATH_TYPES`.
- **Why it shipped this way:** Europa doesn't know type or collection names, and extra state keys aren't returned in its projection. See report §6 and LD-007.
- **What would resolve it:** the Europa owner decides whether audit events should carry structured display fields that Europa renders. That is a separate ticket, flagged for the PR reviewer.

## Concern C14 — System-actor attribution and a PII snapshot column set a precedent for asynchronous audit events

- **New precedent:** INT-138 is the first audit event created outside a user request. Its record names the requester from a snapshot, uses `'system'` as the IP address and user agent, and uses `unknown` / `Unknown Requester` placeholders.
- **New column:** it adds a jsonb `requester_identity` column holding email, first name and last name to `file_derivation_jobs`.
- **Why it matters:** any later asynchronous audit event will copy this pattern.
- **Evidence:** the migration `1790377497027-alter__add_requester_identity__file_derivation_jobs_table.ts`; `FileDerivationJobToAuditUserConverter` (after the review fixes).
- **What would resolve it:** confirm the pattern and the PII column with the audit owner and data policy. This is flagged in the PR description.

## Concern C15 — The commit-message rule doesn't cover Jira `INT-` tickets

- **The conflict:** `git-commit-messages.mdc` in both callisto and atlas says subjects "must start with a ticket number in the format `PRDV-X: <message>`", with X numeric. INT-138 comes from Jira and has no PRDV id, so every INT-138 commit is `INT-138: …`.
- **Evidence:**
  - Neither repo enforces the rule with a hook.
  - callisto `origin/main` has no `INT-` subjects.
  - atlas has 1357 `PRDV-` and 2 `PEDV-` subjects.
- **What would resolve it:** the rule owner amends the rule to accept `(PRDV|INT)-X:`, or names a PRDV ticket to squash-merge under. That is a decision for the user or team.

## Decision history

- **2026-09-23 (Phase 1 recon):** all six found while tracing the categorization write paths and the audit read path, and routed here rather than into scope. See [recon-and-plan](./investigations/INT-138-recon-and-plan.md), Step 5 "Adjacent issues".

## Open questions to settle

1. Accept C1 and C2 as-is, or open follow-up tickets? — owner: principal dev / whoever owns the audit posture
2. Does D1 include unapprove (C5)? — owner: Product
3. Should the C6 description fix ride with INT-138? — owner: principal dev
