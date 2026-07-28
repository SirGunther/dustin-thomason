---
ticket: PRDV-16192
tags: [atlas, europa, callisto, audit, permissions, concerns]
author: Dustin Thomason
created: 2026-07-27
modified: 2026-07-27
---

# PRDV-16192 — Future-development concerns (permissions audit trail)

> **Context:** investigating why `PERMISSIONS_UPDATED` audit entries are unreadable surfaced six adjacent risks that are **not** in this ticket's scope. Five are pre-existing; one is a scope decision this ticket must make deliberately.
> **Purpose of this document:** a dated, code-verified record that these risks were identified and raised — for team discussion and, where needed, escalation.
> **Constructive path forward:** Concern 1 is cheap to fold into this ticket (see OV-5 in the [investigation report](./investigations/PRDV-16192-investigation.md) §10). Concerns 2 and 3 undermine the audit log's reliability and warrant their own ticket. Concerns 4–6 are hygiene items for the permissions subsystem.

## Executive summary (for escalation)

Two of these concerns are about **the audit log being wrong or absent without anyone noticing** — which is the one failure mode an audit log cannot tolerate, regardless of how rarely it fires.

**(a) Audit events can be silently lost.** A permissions change is committed to the database *before* the audit event is dispatched, and the dispatch is not awaited — a queue failure logs to the server console and returns success to the user. The permission change lands with no audit record, and nothing surfaces that.

**(b) Concurrent saves produce a factually wrong audit trail.** The "before" state used to build the diff is read outside the transaction that replaces the permissions. Two administrators saving the same role in overlapping requests both read the same baseline, so the second event reports a prior state that never existed at the time it ran. The final permission state is correct; the *record of how it got there* is not.

Neither is introduced by this ticket, and neither is caused by the defect being fixed. But this ticket is the first time the permissions audit path has been read end to end, and if these are not recorded now they will surface as "was this known?" during a compliance review.

**Decision requested**, from whoever owns audit-log reliability (IT / Larry Adams / Kat Giangiulio per the ticket's own "may need to be discussed with IT" note):

- **(a)** Fold Concern 1 (`MERGED` truncation) into this ticket — same line of code, near-zero extra cost — and spin Concerns 2 and 3 into a companion ticket on audit-dispatch reliability.
- **(b)** Fix only PRDV-16192 as scoped; log Concerns 1–3 as backlog items.
- **(c)** Treat Concerns 2 and 3 as blocking for any compliance use of the audit log, and prioritise the companion ticket ahead of further audit-display work.

The investigation's recommendation is **(a)**.

## Concern 1 — `MERGED` audit entries are already truncated in production

The same line that causes this ticket's defect is already hiding data for a different event type. Europa's paginated read collapses an event's resources to the first one; `MERGED` events carry **one resource per merged file**. A case merge of ten files therefore renders one grid row describing one file, with the other nine silently absent — today, in prod, unrelated to permissions.

This is the strongest evidence that the problem class is the audit read path and not a permissions display bug. It is also the cheapest fix in this list: it is fixed automatically by whatever change resolves this ticket's AC1, provided the fix is made generically rather than special-cased to `PERMISSIONS_UPDATED`.

- **Evidence (verified 2026-07-27):** `europa-back-end/src/audits-event/domain/transaction-scripts/search-audit-events-paginated-TS/search-audit-events-paginated.transaction.script.ts:55` (`event.auditEventResources?.[0]`) · `callisto-back-end/src/cases/domain/sub-domains/audit/infrastructure/dispatchers/case-merge-to-audit-event-assembler/case-merge-to-audit-event.assembler.ts:24` (`auditEventResources: input.sourceFiles.map(...)`) · no Europa spec feeds a multi-resource event, so nothing detects it.
- **What would resolve it:** fix the projection generically in this ticket (OV-5 = "fix now"), and add a multi-resource `MERGED` assertion to the projection spec.

## Concern 2 — Audit dispatch is fire-and-forget, so an audit record can be silently lost

The permissions change is persisted first, then the audit event is dispatched **without being awaited**, with failures swallowed into `console.error`. If SQS is unavailable, misconfigured, or rejects the message, the user sees a successful save and no audit event is ever written. Nothing retries, nothing alerts, and there is no outbox — the record is simply gone.

An audit log whose writes can fail silently cannot be relied on to prove absence of change. Note the failure is also invisible to the existing tests: Callisto's spec explicitly asserts that a dispatch rejection does **not** throw (`permissions-matrix.service.spec.ts:205-227`) — the swallowing is codified as intended behavior.

See the sequence diagram in [PRDV-16192-diagrams.md](./investigations/PRDV-16192-diagrams.md) § Sequences 1.

- **Evidence (verified 2026-07-27):** `callisto-back-end/src/generic/auth/domain/services/permissions-matrix-service/permissions-matrix.service.ts:41-53` — dispatch after persist, `.catch((err) => console.error(...))`, not awaited.
- **What would resolve it:** a transactional outbox for audit events, or at minimum a dead-letter path plus an alert on dispatch failure. Companion ticket; applies to **every** Callisto audit dispatcher, not just permissions.

## Concern 3 — Concurrent saves on the same role produce an internally inconsistent audit trail

The diff baseline (`getCurrentAllowedCells`) is read in the service, **outside** the transaction that `replaceRolePermissions` opens. Nothing serialises two saves against the same role. If administrator B snapshots before administrator A commits, B's audit event reports an `oldActions` set that was already stale when B ran — the trail reads as though A's change never happened.

The final permission state is still correct (last write wins on a delete-then-insert), so this corrupts only the *history*, which is precisely what the audit log exists to preserve. Low probability, high consequence, and undetectable after the fact.

See the sequence diagram in [PRDV-16192-diagrams.md](./investigations/PRDV-16192-diagrams.md) § Sequences 2.

- **Evidence (verified 2026-07-27):** `permissions-matrix.service.ts:27-38` — `getCurrentAllowedCells` at `:27-28` precedes `updatePermissionsMatrixTS.apply` at `:34`; the transaction begins only inside `permission.repository.ts:102` (`this.dataSource.transaction(...)`). The snapshot is not inside it.
- **What would resolve it:** move the snapshot and the diff inside the same transaction as the replace, or take a row-level lock on the role for the duration. Same companion ticket as Concern 2.

## Concern 4 — Permissions save destroys `DENY` rows and rows for keys the matrix does not display

`replaceRolePermissions` deletes **all** permission rows for the role — unfiltered by `effect` — and then inserts only what the client sent. Two consequences: (i) any `DENY` row is destroyed, even though the Permissions Manager never models `DENY` and cannot restore it; (ii) `PERMISSIONS_MATRIX_SECTIONS` omits `K_DRIVE`, `V_DRIVE`, `R_DRIVE`, `T_DRIVE`, `H_DRIVE` and `NOTIFICATIONS`, so any grant on those keys is deleted by a save from the page and never re-inserted.

Since the audit diff is computed against `getCurrentAllowedCells` (ALLOW only), a destroyed `DENY` row is not even recorded in the audit event — the deletion happens with no trail at all, which ties this back to Concerns 2 and 3.

- **Evidence (verified 2026-07-27):** `callisto-back-end/src/generic/auth/domain/infrastructure/repositories/permission.repository.ts:102-146` — `DELETE FROM "callisto"."permissions" WHERE "roles_id" = $1` with no `effect` predicate · `.../fetch-permissions-matrix.response.dto.ts:71-212` — the section metadata omits the drive keys and `NOTIFICATIONS` · `.../permission.repository.ts:81-94` — the snapshot filters `effect = ALLOW`.
- **What would resolve it:** scope the `DELETE` to `effect = ALLOW` **and** to the resource keys the client actually manages; or make the matrix authoritative over every key it will delete. Needs a product call on whether `DENY` is a supported concept at all.

## Concern 5 — The resource-key list and its labels exist in four hand-maintained places

`RESOURCE_KEY_TYPES` is duplicated between Callisto and Atlas with no shared package; the short-label map lives in a Callisto response DTO; the description map lives in an Atlas i18n file; and the authoritative rows live in the `resource_keys` table, populated by seed migrations. Nothing keeps the four in sync. The Atlas i18n map already carries stale pre-rename `*_RECORD_*` keys that match no current row, and a key present in the section metadata but absent from i18n silently renders with no tooltip.

This is what blocks the "just show a friendly label" answer for this ticket (OV-3): the only short-label map is **section-scoped and collides** — `SUBMISSION_PROCEEDING_FILES_TRANSCRIPT` and `CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT` are both `"Transcript Track"`, distinguishable only by their enclosing category. A standalone label for an audit row is therefore ambiguous today.

- **Evidence (verified 2026-07-27):** `callisto .../domain/entities/resource-key.entity.ts:5-48` · `atlas .../src/auth/utils/permissions.ts:1-63` · `callisto .../fetch-permissions-matrix.response.dto.ts:71-212` (colliding labels) · `atlas .../src/i18n/en-US/permissionsManager.json:44-77` (stale `*_RECORD_*` keys) · `atlas .../usePermissionsMatrixQuery.ts:32-40` (client-side `AUDIT` action override that contradicts the backend's declared actions).
- **What would resolve it:** a single source of truth for resource keys and their display metadata — ideally served from the backend, since the section metadata comment already states that is the intent ("Lives here (server-side) so new resource keys added by migration are picked up by the FE without a frontend deploy") — and unique labels independent of section.

## Concern 6 — Europa's audit API is not authorization-enforced

The `AUDIT` resource key gates the Europa page in Atlas, but not Europa's own endpoints. Atlas's own product copy says so. **Authentication is enforced** — a Cognito JWT middleware is applied to all routes — but **authorization by resource key is not**: any authenticated user who reaches the API directly can read the full audit log, including these permission-change records, regardless of whether their role holds `AUDIT`.

- **Evidence (verified 2026-07-27):** `atlas-front-end/src/i18n/en-US/permissionsManager.json` — `"AUDIT": "Access to the Europa audit log. Note: not yet enforced by Europa's API — changes here do not currently restrict direct API access."` · `europa-back-end/src/generic/auth/auth.module.ts:67-72` applies `AuthMiddleware` to `{ path: '*', method: RequestMethod.ALL }` (authn present) · `europa-back-end/src/audits-event/application/controllers/audit-events.controller.ts` carries only `ApiBearerAuth('JWT-auth')`, a Swagger annotation, and a grep for `UseGuards` / `CanActivate` / `APP_GUARD` across `europa-back-end/src` returns **no** authorization guard anywhere (authz absent).
- **What would resolve it:** enforce the `AUDIT` resource key in Europa. Explicitly a **non-goal** of this ticket (report §3), recorded here because this ticket makes the audit log more informative, which raises the value of reading it without authorization.

## Decision history

- **2026-07-02** — PRDV-16192 created by Anastasiya Savchuk as a future improvement to PRDV-15840 (already deployed to prod).
- **2026-07-16** — Kat Giangiulio: "The solution may need to be discussed with IT." Unresolved; carried as OV-6.
- **2026-07-27** — Investigation (Phase 1–2) reclassified the ticket from three display defects to a contract/shape mismatch in the audit read path, and surfaced Concerns 1–6. Concerns 2 and 3 are the first documented review of the permissions audit dispatch path end to end. Recommendation recorded: fold Concern 1 in, spin Concerns 2–3 into a companion ticket.

## Open questions to settle

1. Does Concern 1 (`MERGED`) ride along in this ticket or spin off? — owner: **user** (= OV-5)
2. Do Concerns 2 and 3 warrant a companion ticket now, and who owns audit-dispatch reliability? — owner: **user / IT**
3. Is `DENY` a supported concept in the permissions model, or dead weight that should be removed outright? (Concern 4) — owner: **user / IT**
4. Is there appetite for a single source of truth for resource keys and labels, or does OV-3 ship raw keys for now? — owner: **user**
5. Is Europa's unauthenticated audit API a known accepted risk, or does it need routing to security? (Concern 6) — owner: **user / IT**
