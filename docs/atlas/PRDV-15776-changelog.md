# PRDV-15776 — Decouple client-deliverable rename authorization (validation)

## Ticket

- **ClickUp:** [PRDV-15776](https://app.clickup.com/t/43227262/PRDV-15776)
- **Repo:** `callisto-back-end + atlas-front-end`
- **Branch:** `PRDV-15776`
- **PR:** _(link when opened)_

---

## Validation verdict (2026-06-05)

**PASS — Xavier's implementation correctly fixes the bug and matches the agreed heavy split.** Validated by code review, Callisto unit specs + fitness functions, runtime route mapping, and a browser E2E with screenshot-grade evidence (below). The decoupling is proven in both directions: the spoofed deliverable-only role renames a client-deliverable transcript via the **new** `/granting-client-access` endpoint (200), and the **same** role is denied (403) when renaming a submission transcript via the old `/proceedings/file` endpoint.

**One open item (not a defect in the fix):** the front-end **nested-original rename regression** — see "Review finding" below. Needs a product/behavior decision from Xavier; not blocking the core fix.

---

## Requirements (verbatim)

_Paste from ClickUp, spec, or the user's first description. Do not paraphrase on first capture._

> Actual result: despite update access Facilities role can't rename files in Client deliverable transcript
>
> Expected result: with update access Facilities role can rename files
>
> **Investigation Report:**
> Neptune_Facilities has UPDATE on CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT, and the frontend correctly authorizes rename against that resource. The rename API (PATCH /callisto/proceedings/file/:fileId) uses UpdateProceedingFileAuthGuard, which only checks SUBMISSION_PROCEEDING_FILES_* and ignores isDeliverable—causing 403 for Facilities users.
>
> We determined that the best course of action for resolving the permission discrepancy in callisto is to split the renaming action for Client Deliverables and Submission files, into two separate services. This aligns with the split of client deliverables and submission file uploads, established in "Set Track and Collection on drag-and-drop upload" (released to prod).
>
> Agreed approach (060126 meeting): implement the "heavy" architectural split — dedicated `UpdateDeliverableFile` guard, `UpdateDeliverableFileAction`, and `DeliverableFileService` in the granting-client-access domain. Do not attempt a "light" patch (conditional `is_deliverable` checks on the shared guard).

---

## Context

_Optional: related tickets, environment, files to avoid, spec paths, team decisions._

- **Task type:** Validation/review of an engineering handoff. Implementation authored by **Xavier Messado** across two repos; this session validates correctness, not net-new feature work.
- **Branches:** both `callisto-back-end` and `atlas-front-end` are on `PRDV-15776` (we intentionally stay here rather than the docs' usual "backends on main" default).
- **Handoff docs:** `dustin-thomason/docs/atlas/15776/` (original ticket + 060126 meeting; 060326 meeting file is empty).
- **Local setup:** Callisto + Atlas run locally; Triton + Europa point at SB (`atlas-front-end/.env.local` → `TRITON_API_URL`/`EUROPA_API_URL` = `https://atlas-sb.planetdepos.com`). GCA UI path enabled via `CALLISTO_DEV_FEATURE_FLAG_OVERRIDES=IS_GRANTING_CLIENT_ACCESS_ENABLED`.
- **Xavier's commits:** Callisto `4d284978` (+ lint `ecdc488a`); Atlas `348c5dd8`.

---

## Plans

_Lives in **dustin-thomason** only. Reference plans here so future agents do not repeat abandoned approaches. **Larry-adams** paths are **read-only links** to coworker specs — never create or push changelog/plan files there._

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-06-04 | `.cursor/plans/validate_prdv-15776_deliverable_rename_split_23a4a71e.plan.md` | `active` | Boot Callisto + Atlas locally, validate Xavier's heavy-split via code review + Callisto test/fitness suites + browser E2E (DBeaver permission spoofing + fabricated deliverable file), record findings here. |

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-06-05T15:00:00Z — evidence capture + final verdict (validation session)

- **Summary:** Captured reproducible, screenshot-grade evidence for the E2E pass and finalized the verdict (**PASS**, with the nested-original item flagged). No app code changed.
- **Evidence artifacts produced (three, each a single screenshot):**
  1. **Permission-config proof (DBeaver):** query of the logged-in role's transcript permissions returns exactly two rows — `CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT update = ALLOW` and `SUBMISSION_PROCEEDING_FILES_TRANSCRIPT update = DENY`. This proves the spoof is the Facilities profile. Query is in **Manual Reproduction Steps** below.
  2. **Behavior proof (browser DevTools Console):** a paste-in script reads the Cognito tokens from `localStorage` (`*.idToken` / `*.accessToken`), then prints (a) the runtime allowed-permission effects, (b) `PATCH /callisto/granting-client-access/file/9604` → **200** (deliverable rename works), and (c) `PATCH /callisto/proceedings/file/25` → **403** (same role blocked on a submission transcript via the old endpoint). One console screenshot shows success **and** the negative case. Script in **Manual Reproduction Steps**.
  3. **UI/Network proof (optional):** rename in the Client Deliverables tab with DevTools → Network filtered to `granting`; the row's **Name** column shows only the file id (e.g. `9604`), **Method** `PATCH`, **Status** `200`. Full `.../granting-client-access/file/9604` URL appears under **Headers → Request URL**.
- **Negative-case decision:** the UI itself can't easily produce a 403 (the front-end already routes deliverable renames to the new endpoint), so the decoupling's failure direction is shown by calling the **old** `/proceedings/file/:fileId` endpoint on a submission transcript (file 25) with the spoofed role → 403. Auth guards run before body validation in Nest, so the 403 is the guard's, independent of payload.
- **Evidence file IDs (proceeding 3001 / job 112233):** `9604` = `smith_deposition_transcript_deliverable.pdf` (deliverable transcript, track 2) for the success call; `25` = `Screenshot_92.txt` (submission transcript, track 2, proceeding 2) for the 403 call.
- **DB spoof still in place at session end.** Backup table `callisto.permissions_backup_15776` exists. **Restore when done:** `TRUNCATE callisto.permissions; INSERT INTO callisto.permissions SELECT * FROM callisto.permissions_backup_15776;` (or drop the local DB).
- **Commits:** none (validation only).

### 2026-06-04T22:10:00Z — callisto-back-end + atlas-front-end (validation session)

- **Summary:** Stood up the local stack and validated Xavier's heavy split. Code review complete; Callisto unit specs and fitness functions green; both apps boot; both rename routes mapped at runtime. Identified one front-end regression (nested-original rename). E2E (browser) still pending — needs the user logged in with a deliverable-update-but-not-submission role.
- **Plan used:** `.cursor/plans/validate_prdv-15776_deliverable_rename_split_23a4a71e.plan.md`
- **Environment fixes required to boot (not Xavier's code):**
  - `callisto-back-end` `node_modules` had to be reinstalled (`mjml` + `@planetdepos` events pkg were stale/missing). NOTE: `.npmrc` uses `_authToken=${GITHUB_TOKEN}`; the env var must be set in-shell before `npm ci` (a bare `npm ci` sends an empty token → `401`).
  - Local Postgres lacked the `uuid-ossp` extension required by the `notifications` migrations (`uuid_generate_v4()`). Fixed: created `public` schema and `CREATE EXTENSION "uuid-ossp" WITH SCHEMA public` (default `search_path` is `"$user", public`, so the unqualified call now resolves). These should be added to the local-setup runbook.
- **Verification (Callisto):**

| Gate | Command | Scope | Result | Notes |
| ---- | ------- | ----- | ------ | ----- |
| unit tests | `npx jest --config jest-e2e.json <5 spec patterns> --runInBand` | guard, authorize-role, deliverable-rename svc, must-be-submission validator, proceeding.service | pass | 6 suites / 35 tests |
| conventions | `npm run test:conventions` | architecture + naming + dto/type structure + migration naming + no-util-files | pass | new GCA/validator files conform |
| runtime wiring | nest startup log | route mapping + DI | pass | `PATCH /callisto/granting-client-access/file/:fileId` and `PATCH /callisto/proceedings/file/:fileId` both mapped; RabbitMQ `nova`+`callisto` connected; health `status:ok` |

- **E2E fixtures located (no fabrication needed):** client-deliverable transcript files exist in proceedings **3001** (`file_id` 9603/9604/9702, job 112233) and **3002** (9609/9705). Role `Neptune_Facilities` (id 14) is already seeded as the bug scenario: resource_key 12 `CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT` `update=ALLOW`, resource_key 7 `SUBMISSION_PROCEEDING_FILES_TRANSCRIPT` `update=DENY`. Permission actions are lowercase (`update`), effects uppercase (`ALLOW`/`DENY`).
- **Permission spoof (local only, reversible):** the tester logs in as `Neptune_Delete_Investigator` (a seeded role), not Facilities. Since Callisto resolves permissions per-request from the token's `custom:roles` against the DB, we copied Facilities' (role 14) full permission set onto all 23 other roles so any login reproduces the scenario. Backup table `callisto.permissions_backup_15776` (1388 rows) created first. **To restore:** `TRUNCATE callisto.permissions; INSERT INTO callisto.permissions SELECT * FROM callisto.permissions_backup_15776;` (or just drop the local DB).
- **E2E RESULT — PASS (2026-06-05):** Logged-in role `Neptune_Delete_Investigator` (spoofed → deliverable-transcript `update=ALLOW`, submission-transcript `update=DENY`). Renamed `smith_deposition_transcript_deliverable.docx` (file 9603) in the Client Deliverables UI → **success**. Confirmed:
  - DB `files.file_name` for 9603 changed to `smith_deposition_transcript_deliverable_RENAMED.docx` (also 9702 renamed).
  - Request routed through the **new** endpoint: `PATCH /callisto/granting-client-access/file/9603` (200). The old `/proceedings/file/:fileId` path was not used.
  - **Decoupling proven:** the rename succeeded despite the role having submission-transcript `update=DENY`. Pre-fix this same UI action targeted `/proceedings/file/:fileId` and 403'd via `UpdateProceedingFileAuthGuard`.
  - Front-end gating confirmed correct: row resolved to `{isDeliverable:true, trackTypeId:2}` → `CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT`, `canRenameProceedingFiles=true`.
- **Gotcha for future testers:** the Atlas Vite dev server proxies `/callisto/*` to local Callisto; when Callisto restarts (e.g. on a watch recompile) the deliverables list silently fails to load (`ECONNREFUSED` in the Atlas terminal) and the row actions appear empty/disabled. This is a transient backend-restart symptom, not a permissions issue — hard-refresh once Callisto is back.
- **Temporary diagnostics (added then reverted, no diff remains):** a `console.log` in `ClientDeliverablesTable.vue` `hasPermissionForSelectedFiles` and a `console.log` of resolved roles/permissions in `id-token-to-auth-user.assembler.ts` were used to capture the tester's role + FE gating, then removed.
- **Commits:** none (validation only; no code changed in app repos).
- **Open item (front-end regression, separate from this fix):** rename of a **nested original** file in `ClientDeliverablesTable` now routes to the deliverable-only endpoint and would 403 if the original lacks the `CLIENT_DELIVERABLE` tag (the old `isDeliverable:false` demotion path was removed for the rename mutation URL). Not exercised in this E2E because the seeded docx/pdf deliverables have no transcode lineage (no nested originals). Flag to Xavier for confirmation.

---

## Root cause analysis

**Original bug:** `PATCH /callisto/proceedings/file/:fileId` was guarded by `UpdateProceedingFileAuthGuard`, which only evaluates `SUBMISSION_PROCEEDING_FILES_*` permissions and ignores `isDeliverable`. A Neptune Facilities user with `UPDATE` on `CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT` (but not on submission files) therefore gets a false-negative `403` when renaming a client deliverable.

**Fix shipped by Xavier (heavy split):**
- New route `PATCH /granting-client-access/file/:fileId` → `RenameDeliverableFileAction` → `DeliverableRenameService`.
- `UpdateDeliverableFileAuthGuard` authorizes via `DeliverableFileAuthorizeRole` against `CLIENT_DELIVERABLE_PROCEEDING_FILES_<trackType>` + `UPDATE`.
- Two lane-keeping validators backed by `ProceedingFileRepository.fetchProceedingFileForRename().isDeliverable`: `ProceedingFileMustBeDeliverableValidator` (new GCA endpoint rejects non-deliverables) and `ProceedingFileMustBeSubmissionValidator` (old `/proceedings` endpoint now rejects deliverables).
- Atlas `ClientDeliverablesTable.vue` now posts `{ value, trackTypeId }` to `RENAME_DELIVERABLE_FILE_URL`.

**How authorization actually resolves (traced):** `AuthMiddleware` runs per request → `getAllowedPermissionsByRoleTypes(roleTypes)`, where `roleTypes` come from the id-token `custom:roles` claim and permissions are a DB lookup over `permissions ⋈ roles ⋈ resource_keys` filtered to `effect='ALLOW'`. Role is fixed by the token; the permissions a role maps to are DB-editable and re-read each request.

---

## Attempt history

_Optional — one subsection per failed or partial approach._

### Attempt 1 — short label (commit `abc1234` optional)

**What:**

**Result:**

---

## Key technical learnings

1. **Callisto permissions are DB-derived, re-read per request.** Token `custom:roles` → `permissions ⋈ roles ⋈ resource_keys` (`effect='ALLOW'`). Editing the local `permissions` table in DBeaver lets you grant your logged-in role the deliverable `UPDATE` permission and reproduce the Facilities scenario with no re-login (next request picks it up). Token verification uses Cognito public keys, not AWS creds.
2. **The rename itself is DB-only.** `RenameProceedingFileTS` updates `file.fileName` after a duplicate-name check — no S3 object rename. A DBeaver-fabricated client-deliverable file (no real S3 object) renames cleanly; the only side effect is the audit event dispatched to the RabbitMQ outbox.
3. **A client deliverable is defined by data:** a `files` row + `file_attachments` (`attached_to_type=PROCEEDING`, non-null `track_type_id`) + a `CLIENT_DELIVERABLE` tag via `file_attachments_file_tags`.
4. **Guard `throw new Error('Authentication required')` (→ 500) is a pre-existing house pattern**, copied faithfully from `CreateDeliverableFileAuthGuard`; not a regression introduced here.

### Review finding — front-end nested-original rename regression (NEEDS DECISION)

`ClientDeliverablesTable.vue` exposes the rename action on **two** rows: the converted deliverable (`row.file`) and its **nested original** (`row.file.originalFile`), both wired to `handleRename`. Every other handler (`handleDownload`, delete, preview) still demotes nested originals via `isNestedOriginal = lookup?.isConvertedFile === false; isDeliverable = isNestedOriginal ? false : true`. Xavier removed exactly that branch from `handleRename`, so **all** renames now post to the deliverable-only endpoint. For a nested original that lacks the `CLIENT_DELIVERABLE` tag, `ProceedingFileMustBeDeliverableValidator` throws `ForbiddenException` (403) — whereas before it routed to the submission endpoint (`isDeliverable:false`) and succeeded. Confirm in E2E whether nested originals shown in this table lack the tag; if so this is a behavioral regression for renaming originals and needs a fix or product decision.

---

## Current state (as of 2026-06-05)

_What is merged / on branch / reverted / still pending._

- **Validation COMPLETE — verdict PASS.** Code review, Callisto unit specs (6 suites / 35 tests), `test:conventions`, runtime route mapping, and browser E2E all green. Evidence captured (see Session log 2026-06-05 + Manual Reproduction Steps).
- **Open item carried forward:** nested-original rename regression (front-end) — flagged for Xavier; product/behavior decision, not blocking.
- **Local env still in test state:** Facilities permission profile is spoofed onto all roles; backup table `callisto.permissions_backup_15776` exists. Restore (or drop DB) before doing unrelated local work. Files `9603`/`9604`/`9702` in proceeding 3001 were renamed during testing.
- **No app code changed** in either repo; all temporary diagnostics reverted.

---

## Manual Reproduction Steps

_Starting state: full stack already running locally (see `docs/atlas/local/full-stack-local-setup.md` and `dev-testing-prerequisites.md`). Callisto on `:3003`, Atlas on `:9000`, logged in as any seeded role. Assumes the PRDV-15776 branch on both repos._

### 1. Prerequisites that must already be true

- Docker `callisto-postgres` + `callisto-rabbitmq` running; `callisto` schema seeded (roles, resource_keys, permissions).
- Postgres has the `uuid-ossp` + `pgcrypto` extensions (migrations fail without them — see setup doc).
- `callisto-back-end` deps installed with a **valid, non-expired** GitHub PAT exported in-shell (`$env:GITHUB_TOKEN`) before `npm ci`.
- AWS Neptune SB session creds fresh (Cognito token verification + Triton S3).
- You are logged into Atlas in the browser (Cognito tokens present in `localStorage`).

### 2. Spoof the Facilities profile onto your role (DBeaver, local only, reversible)

Callisto resolves permissions per request from the token's roles against the DB, so editing the `permissions` table reproduces the scenario with no re-login. Copy role 14 (`Neptune_Facilities`) onto all other roles, after backing up:

```sql
-- backup first
DROP TABLE IF EXISTS callisto.permissions_backup_15776;
CREATE TABLE callisto.permissions_backup_15776 AS SELECT * FROM callisto.permissions;

-- copy Facilities (role 14) permission set onto every other role
DELETE FROM callisto.permissions WHERE roles_id <> 14;
INSERT INTO callisto.permissions (roles_id, resource_keys_id, action, effect, created_at, updated_at)
SELECT r.id, p.resource_keys_id, p.action, p.effect, now(), now()
FROM callisto.roles r
CROSS JOIN callisto.permissions p
WHERE p.roles_id = 14 AND r.id <> 14;
```

### 3. Capture Evidence #1 — permission-config proof (DBeaver screenshot)

Replace the role with your logged-in role (server logs print `authorized roles:` on login):

```sql
SELECT r.type AS role, rk.key AS resource_key, p.action, p.effect
FROM callisto.permissions p
JOIN callisto.roles r          ON r.id  = p.roles_id
JOIN callisto.resource_keys rk ON rk.id = p.resource_keys_id
WHERE r.type = 'Neptune_Delete_Investigator'
  AND rk.key IN (
    'CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT',
    'SUBMISSION_PROCEEDING_FILES_TRANSCRIPT'
  )
  AND p.action = 'update'
ORDER BY rk.key;
```

**Expected (success indicator):** two rows — deliverable `ALLOW`, submission `DENY`. Screenshot the result grid.

### 4. Capture Evidence #2 — behavior proof (browser Console screenshot)

In the Atlas tab → DevTools → Console, paste and run:

```javascript
(async () => {
  const e = Object.entries(localStorage);
  const idToken = (e.find(([k]) => k.endsWith('.idToken')) || [])[1];
  const accessToken = (e.find(([k]) => k.endsWith('.accessToken')) || [])[1];
  if (!idToken || !accessToken) { console.error('Not logged in — no Cognito tokens found.'); return; }
  const H = { 'Content-Type': 'application/json', idToken, Authorization: 'Bearer ' + accessToken };

  const DELIVERABLE_FILE_ID = 9604; // deliverable transcript (proceeding 3001)
  const SUBMISSION_FILE_ID  = 25;   // submission transcript (proceeding 2)
  const TRANSCRIPT = 2;

  console.log('%c===== PRDV-15776 E2E EVIDENCE =====', 'font-weight:bold;font-size:14px');

  const perms = await fetch('/callisto/permissions', { headers: H }).then(r => r.json());
  const deliv = perms.find(p => p.resourceKey === 'CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT' && p.action === 'update');
  const sub   = perms.find(p => p.resourceKey === 'SUBMISSION_PROCEEDING_FILES_TRANSCRIPT' && p.action === 'update');
  console.log('Role(s):', [...new Set(perms.map(p => p.roleType))].join(', '));
  console.log('deliverable-transcript update :', deliv ? deliv.effect + ' (allowed)' : 'NOT ALLOWED');
  console.log('submission-transcript  update :', sub ? sub.effect : 'NOT ALLOWED (denied)');

  const newName = 'PRDV15776-EVIDENCE-' + Date.now() + '.pdf';
  const r1 = await fetch('/callisto/granting-client-access/file/' + DELIVERABLE_FILE_ID, {
    method: 'PATCH', headers: H, body: JSON.stringify({ value: newName, trackTypeId: TRANSCRIPT }),
  });
  console.log('TEST 1  PATCH /callisto/granting-client-access/file/' + DELIVERABLE_FILE_ID,
    '->', r1.status, r1.status === 200 ? 'SUCCESS — deliverable rename works' : 'unexpected');

  const r2 = await fetch('/callisto/proceedings/file/' + SUBMISSION_FILE_ID, {
    method: 'PATCH', headers: H, body: JSON.stringify({ value: 'SHOULD-NOT-APPLY.txt', trackTypeId: TRANSCRIPT }),
  });
  console.log('TEST 2  PATCH /callisto/proceedings/file/' + SUBMISSION_FILE_ID,
    '->', r2.status, r2.status === 403 ? 'BLOCKED (403) — decoupling proven' : 'expected 403');

  console.log('%c===== RESULT: ' + (r1.status === 200 && r2.status === 403 ? 'PASS' : 'CHECK ABOVE') + ' =====',
    'font-weight:bold;font-size:14px');
})();
```

**Expected (success indicators):** role line shows the deliverable effect `ALLOW` and submission `NOT ALLOWED (denied)`; `TEST 1 -> 200 SUCCESS`; `TEST 2 -> 403 BLOCKED`; `RESULT: PASS`. Screenshot the console output.

**Common failure points:**
- `Not logged in — no Cognito tokens found.` → you aren't authenticated in this tab, or Amplify cleared the session. Re-login.
- `TEST 1 -> 401` → idToken expired mid-session; refresh the page (Amplify re-issues) and re-run.
- `TEST 1 -> 403` → the spoof didn't apply for your role; re-check Evidence #1 query.
- `TEST 2 -> 200` → submission `DENY` is missing for your role (spoof incomplete); re-run Step 2.

### 5. Capture Evidence #3 — UI + Network (optional)

Open DevTools → Network → filter `granting` → rename a deliverable in the Client Deliverables tab. The new row's **Name** is the file id, **Method** `PATCH`, **Status** `200`; full URL under **Headers**. Screenshot toast + request.

### 6. Cleanup

```sql
TRUNCATE callisto.permissions;
INSERT INTO callisto.permissions SELECT * FROM callisto.permissions_backup_15776;
DROP TABLE callisto.permissions_backup_15776;
```

(Or drop/recreate the local `callisto` DB.) Renamed test files (9603/9604/9702) can be left as-is or reset from a fresh seed.

---

## New code introduced

_Optional — new modules, composables, endpoints._


