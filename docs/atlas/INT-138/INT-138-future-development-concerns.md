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

## Decision history

- **2026-09-23 (Phase 1 recon):** all six found while tracing the categorization write paths and the audit read path, and routed here rather than into scope. See [recon-and-plan](./investigations/INT-138-recon-and-plan.md), Step 5 "Adjacent issues".

## Open questions to settle

1. Accept C1 and C2 as-is, or open follow-up tickets? — owner: principal dev / whoever owns the audit posture
2. Does D1 include unapprove (C5)? — owner: Product
3. Should the C6 description fix ride with INT-138? — owner: principal dev
