# Test plan — atlas/PRDV-16313

> Seeded from [PRDV-16313-investigation.md](../investigations/PRDV-16313-investigation.md) §9 on 2026-08-11. **Refined 2026-08-11 (Phase 3)** against [the spec](../specs/PRDV-16313-spec.md) and [the locked decisions](../specs/PRDV-16313-locked-decisions.md).

Status: **refined**

**Criterion keys.** `AC1`–`AC4` = the wiki spec's acceptance criteria (mechanism constraints). `S1.n` / `S2.n` = job story 01 / 02 criterion *n* (what done means — both stories now `accepted`). `LD-###` = a locked decision this scenario pins.

**What the refine changed.** Story 01's six criteria were **all rewritten at Phase 3** (LD-017), so every `S1.n` reference below was remapped rather than left pointing at superseded wording. Two consequences:

- **`S1.1` narrowed** to the ops deliverables workflow, so EC-4 stops being "a gap against a criterion" and becomes "a gap against the ticket's stated purpose" — still measured, but no longer a criterion failure.
- **`S1.3` strengthened** from *"the client keeps seeing the previous name"* to *"nothing is sent"*, which made NP-3 the direct proof of a criterion rather than an inference from one. That is why NP-3 is now the load-bearing negative path.

Story 02's five criteria are **unchanged**, so its references stand as seeded.

## Scope and surfaces under test

- **The behaviour being proven:** a successful rename of a client-deliverable file writes exactly one `callisto.client-access.file.renamed.v1` row to `outbox_events`, in the same transaction as the name change, with a payload matching `CallistoClientAccessFileRenamedV1Data`; and nothing is written for a non-deliverable rename, a no-op rename, or a failed rename.
- **Surfaces:**
  - `PATCH /granting-client-access/file/:fileId` — the only route whose behaviour changes.
  - `callisto.outbox_events` — where **all** evidence of the change lives.
  - `callisto.files` — must show the renamed row, unchanged in every other respect.
  - **Neighbour surfaces that must not move:** `PATCH /proceedings/file/:fileId` and `PATCH /<ajsf>/file/:fileId`, plus the existing audit-event dispatch on the deliverable route.

## Happy path

- [ ] **HP-1** (`AC1`, `AC2`, `S1.1`) — Given a client-deliverable file named `transcript-draft.pdf`, when it is renamed to `transcript-final` via `PATCH /granting-client-access/file/:fileId`, then exactly one `outbox_events` row exists with `event_type = 'callisto.client-access.file.renamed.v1'`, `aggregate_type = 'File'`, `aggregate_id = <fileId>`, and a five-field payload whose `fileName` is `transcript-final.pdf` (extension preserved by existing behaviour).
- [ ] **HP-2** (`AC2`) — The payload carries **exactly** `fileId`, `proceedingId`, `fileName`, `renamedUserIdentity`, `renamedAt` — no extra keys, no `previousFileName`. `renamedAt` is ISO-8601 with a `Z`.
- [ ] **HP-3** (`AC2`, `LD-012` — pins a decision, no criterion) — `payload.renamedAt` and the `Date` used to derive the event id are the **same instant** (`toBe` identity, not equality). Locks the single-`Date` decision so a later edit cannot desync the payload from the event id. Concern C4.
- [ ] **HP-4** (`AC1`, `S1.2`) — The outbox write happens **after** the rename, never before, and exactly once. Asserted by call ordering, not by inspection. This is also `S1.2`'s proof: one record per rename means there is never an old and a new name in flight together.
- [ ] **HP-5** (`S1.5`) — The existing audit event still dispatches, on a byte-identical payload, **after** the transaction commits. Two things at once: the refactor preserved neighbour behaviour, and the SQS send stayed **outside** the boundary per `LD-005`.
- [ ] **HP-6** (`S1.4`, `S2.2`) — Two successive renames of the same file produce **two distinct** outbox rows with distinct ids, each naming the same `fileId`. That last part is `S1.4`'s proof: the record names the same file the client already had, so a rename is never mistaken for a new document.

## Negative paths

- [ ] **NP-1** (`AC3`, `S2.1`) — Renaming a **non-deliverable** proceeding file via the deliverable route returns 403 and writes **no** outbox row, and the rename is not attempted. This is AC3's proof.
- [ ] **NP-2** (`S2.2`) — Renaming a **deliverable** file still emits. Deliberately the inverse of NP-1: a change that suppressed *every* emission would pass NP-1 and fail here. This is the regression guard on the cheap wrong fix.
- [ ] **NP-3a — unit** (`LD-010`) — When the outbox write rejects, the assembler **propagates** the error rather than swallowing it, and does not return a message. **This is all a unit test can prove.** With the aggregator and the port both mocked, it establishes error propagation and call ordering — **not** database rollback and **not** repository enlistment.
- [ ] **NP-3b — real Postgres, REQUIRED** (`S1.3`, `LD-005`) — With a real database and a **real** rename, force the outbox insert to fail and assert that **`files.file_name` is unchanged** afterwards and no `outbox_events` row exists. **This is the load-bearing scenario of the entire ticket** and the only thing that actually proves atomicity — that a real file update and a real outbox insert participate in the same transaction.

  > **Corrected 2026-08-11 after review.** This was originally a single `NP-3` assigned to the assembler unit suite, which **could not prove what it claimed**. Atomicity is the main correctness property being added beyond the authored spec, so it cannot rest on a suite where both collaborators are mocked. Split into 3a (unit, ordering + propagation) and 3b (integration, actual rollback). **If 3b cannot be run, atomicity is unproven and must be reported as such** — not inferred from 3a passing. Fault-injection options, cheapest first: point the outbox writer at an unknown routekey so `ClientAccessOutboxWriter` throws `BadRequestException` inside the boundary; or provide a stub `CLIENT_ACCESS_OUTBOX` that throws after the rename; or revoke `INSERT` on `callisto.outbox_events` for the test role. The first requires no production change and exercises the real transaction.
- [ ] **NP-4** (`S1.3`) — When the rename itself fails (duplicate name, file not found), the error propagates and **no** outbox row is written.
- [ ] **NP-5** (coverage — no criterion) — An unauthorised caller is rejected by `UpdateDeliverableFileAuthGuard` before any of this runs; no emission.

## Edge cases

- [ ] **EC-1** (`S1.3`, `AC1`, `LD-011`) — **No-op rename.** Renaming a file to the name it already has (including a value that recomputes to the same name after extension preservation) returns success with its message and writes **nothing**. The existing early-return branch issues no `UPDATE`, so an emission here would assert a database write that never occurred. Also assert `files.updated_at` is unchanged — that is the independent evidence no write happened.
- [ ] **EC-2** (`AC2`, `LD-013`) — `AuthUser.identity` absent → `renamedUserIdentity` falls back to `sub`. The non-nullable contract field never receives `undefined` or an empty string.
- [ ] **EC-3** (`S2.1`) — Neighbour: renaming a **submission** file via `PATCH /proceedings/file/:fileId` succeeds and writes **zero** client-access outbox rows.
- [ ] **EC-4** (**not a criterion failure — measures a known scope gap**) — Renaming a client-deliverable file via `PATCH /<ajsf>/file/:fileId` writes **no** outbox row. **Documented current behaviour, not a bug being introduced.** Refine note: since `S1.1` was narrowed to the ops deliverables workflow (LD-017), this no longer fails a criterion — but it *is* still a shortfall against the ticket's stated purpose, so it stays in the plan to be **measured rather than assumed**. Concern C1 · LD-014.
- [ ] **EC-5** — **BLOCKED at seed.** Two genuine renames of one file inside the same millisecond collide on the deterministic event id, and the second `save()` silently overwrites the first. Reason blocked: reproducing a sub-millisecond interleaving reliably is not practical in a unit or manual test. Residual risk: one event instead of two, carrying the correct final name (benign only because the payload is a state snapshot). Follow-up: concern C7 — and report assumption **A3** owes a real-Postgres demonstration that a duplicate id UPDATEs rather than raises, which is the falsifiable half of this and *is* executable.

## Manual verification

Written so someone who did not build the change can execute it without asking a follow-up question.

**Before / after** — what changes and, just as importantly, what does not:

| | Before | After |
| --- | --- | --- |
| Atlas UI — the rename dialog and the file list | Rename succeeds, new name appears | **Byte-for-byte identical.** No visual change whatsoever |
| HTTP response from `PATCH /granting-client-access/file/:fileId` | `{ message: 'Proceeding file successfully renamed to "…"' }` | **Identical** |
| `callisto.files` row | `file_name` and `updated_at` change | **Identical** — same two columns, same values |
| Audit event (SQS) | Dispatched after the rename | **Identical** payload and timing |
| **`callisto.outbox_events`** | **No row is written on rename** | **One new row** per successful deliverable rename — `event_type = 'callisto.client-access.file.renamed.v1'` |

> **Nothing changes in the UI. Do not screenshot the Atlas screen — it is identical before and after, and a screenshot of it proves nothing.** The only evidence of this change is a row in `callisto.outbox_events`. If a reviewer expects a screenshot, what belongs in frame is the **SQL result grid** showing that row and its `data` payload, not the application.

**Preconditions**

1. Callisto running locally against the local Postgres (`docker` container `callisto-postgres`); migrations applied. Runbook: `docs/atlas/local/callisto-local.mdc`.
2. `callisto-back-end/node_modules` populated — **check this explicitly.** The sibling ticket PRDV-16312 left it emptied by a failed `npm ci` and only discovered it at the gate. Verified populated 2026-08-11, but re-check.
3. A proceeding with **at least one client-deliverable file** (a file whose `file_attachments` row has the `Client Deliverable` tag) **and at least one submission file** on the same proceeding — the second is needed for EC-3.
4. An Atlas login holding `CLIENT_DELIVERABLE_PROCEEDING_FILES_<TRACK>:UPDATE` for that track.
5. **Baseline reading, before acting** — run the evidence query below and record the row count. Every assertion afterwards is a delta against it.

**Steps**

1. Note the target file's `id`, `file_name`, `updated_at`, and its proceeding's id.
2. **M-1** — In Atlas, on that proceeding's deliverables, rename the file to a genuinely different name (e.g. `qa-rename-<timestamp>`). Note which track it is on.
3. **M-2** — Rename the **same** file again, to a second different name. (Tests HP-6 — two distinct ids.)
4. **M-3** — Rename the same file to the name it **already has**. (Tests EC-1 — no emission.) **Also record what the API returns**, because this is the behaviour Larry is being asked to confirm: a success response with no event written. If he rules that every successful `PATCH` must emit, this step's expected result inverts.
5. **M-4** — On the same proceeding, rename a **submission** (non-deliverable) file via the proceedings surface. (Tests EC-3 — zero rows.)
6. **M-5 — fault injection, REQUIRED** (backs NP-3b). Make the outbox insert fail during a real rename, then confirm the filename did **not** change. Easiest reliable method without touching production code: temporarily `REVOKE INSERT ON callisto.outbox_events FROM <app_role>;`, attempt a rename, observe the 500, verify `files.file_name` is unchanged and no row was written, then `GRANT` it back. **Do not skip this and infer atomicity from the unit suite** — a mocked suite cannot see a transaction. If it cannot be run, report atomicity as **unproven** rather than assumed.

**Evidence** — paste-ready:

```sql
-- Primary evidence: the rename events, newest first.
select id,
       event_type,
       aggregate_type,
       aggregate_id,
       status,
       occurred_at,
       data
  from callisto.outbox_events
 where event_type = 'callisto.client-access.file.renamed.v1'
 order by created_at desc
 limit 10;

-- Payload field-by-field for the newest row (readable form).
select data->>'fileId'              as file_id,
       data->>'proceedingId'        as proceeding_id,
       data->>'fileName'            as file_name,
       data->>'renamedUserIdentity' as renamed_user_identity,
       data->>'renamedAt'           as renamed_at,
       jsonb_object_keys(data)      as present_keys
  from callisto.outbox_events
 where event_type = 'callisto.client-access.file.renamed.v1'
 order by created_at desc
 limit 1;

-- Corroborate against the file row, and confirm nothing else moved.
select id, file_name, updated_at, created_user_identity, modified_user_identity
  from callisto.files
 where id = <fileId>;

-- Neighbour proof: no client-access rows at all for the submission rename.
select count(*) as should_be_zero_for_submission_rename
  from callisto.outbox_events
 where event_type like 'callisto.client-access.file.renamed%'
   and aggregate_id = '<submissionFileId>';
```

**Pass / fail** — per step:

| Step | Passes | Fails |
| --- | --- | --- |
| M-1 | Exactly **one** new row. `aggregate_type = 'File'`, `aggregate_id` = the file id, `status = 'pending'`. `data` has exactly the five keys; `fileName` is the new name **with the original extension preserved**; `proceedingId` matches the file's proceeding; `renamedUserIdentity` is your directory user id; `renamedAt` parses as ISO-8601. | **Zero rows** → the emission never fired (wrong emit site, or the no-op guard is inverted). **`fileName` is the OLD name** → the projection is being read before the rename. **`proceedingId` null or wrong** → the validator's returned context is not wired through. **More than five keys** → the converter is not returning the ODP type. **Two rows for one rename** → the write is being called twice. |
| M-2 | A **second** row with a **different `id`** from M-1's. Two rows total for this file. | **Still one row, with M-1's payload replaced** → the deterministic-id collision (concern C7) fired; the two renames landed in the same millisecond. Retry with a deliberate pause. **Still one row, unchanged** → the second rename did not emit. |
| M-3 | **No new row.** Row count unchanged from M-2. `files.updated_at` also unchanged (the existing early return issues no `UPDATE`). | **A third row appears** → the no-op guard is missing or wrong, and the system is announcing a rename that never happened. *(Note: if Larry rules that every successful `PATCH` must emit, this expectation inverts — the behaviour is under review, not settled.)* |
| M-4 | **Zero** client-access rows for the submission file. The submission rename itself still succeeds. | **Any row** → the emission leaked onto the shared transaction script and is firing for non-deliverables. |
| **M-5** | Request returns 500. **`files.file_name` is UNCHANGED** and no `outbox_events` row exists. | **`file_name` changed while no row was written** → **there is no transaction.** The rename and the event are not atomic, and the ticket's main added correctness property does not hold. This is the single most important negative observation in the plan. |
| — | `callisto.files` shows only `file_name` / `updated_at` changed. `modified_user_identity` is untouched (pre-existing gap, report §5). | Any other column changed → the change reached beyond its scope. |

**Load-bearing steps, and why:**

- **M-5 is the load-bearing step of the whole plan.** Atomicity is the main correctness property this ticket adds beyond the authored spec, and M-5 is the only step that can prove it. Everything else can pass while atomicity is absent — a plain class provider instead of the transactional proxy loses it, and **every unit test still passes.**
- **M-1 is load-bearing for the feature.** If it fails, the ticket does not work at all.
- **M-3 is load-bearing for correctness**, and its failure mode is the quietest here — a spurious event asserting a database write that never occurred. Nothing downstream would flag it; Dione would take a redundant update.
- **M-4 is load-bearing for the neighbours.** Its failure means the emission landed on the shared script and every submission-file rename is now announcing itself to a client-facing consumer.

**Not manually verifiable, stated plainly:** whether the client actually sees the new name. RabbitMQ is descoped epic-wide and Dione's consumer is another team's, so the proof ends at the `outbox_events` row. A payload that is correctly *shaped* but semantically wrong — say the right five keys with the wrong `proceedingId` — would pass everything here. That is the slow-feedback risk in report §7, and M-1's `proceedingId` check is the only guard against it.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| `callisto-back-end` | `…/rename-deliverable-file-assembler/__specs__/rename-deliverable-file.assembler.spec.ts` (new) | HP-1, HP-3, HP-4, NP-2, **NP-3a**, NP-4, EC-1 — the primary suite. Includes the **red→green** case: fails before the emission exists, passes after. **Cannot prove NP-3b** — both collaborators are mocked |
| `callisto-back-end` | `…/rename-deliverable-file-assembler/__specs__/rename-deliverable-file.assembler.integration.spec.ts` (**new — REQUIRED, added after review**) | **NP-3b — the actual atomicity proof.** Real Postgres via `createRepositoryTestContext` + `createPostgresTestDataSourceOptions` (same harness as the sibling's converter integration spec, which carries the `// Requires Postgres on localhost:5432` precondition comment). Persists a real `File` + `FileAttachment`, runs a real rename with the outbox insert forced to fail, asserts `files.file_name` unchanged and zero `outbox_events` rows |
| `callisto-back-end` | `…/file-renamed-outbox-converter/__specs__/file-renamed-to-outbox-data.converter.spec.ts` (new) | HP-2 — exactly five contract fields, ISO-8601 `renamedAt`, id coercion. **No integration spec for the converter**: the sibling's exists only for the `files.file_size` bigint-as-string hazard, and every numeric here is an `integer` column. That reasoning is about the *converter* and does not extend to the assembler — see the row above |
| `callisto-back-end` | `…/deliverable-rename-service/__specs__/deliverable-rename.service.spec.ts` (modify) | HP-5, EC-2, NP-1 — delegation, audit payload **unchanged** (existing assertions stay byte-identical), identity fallback, audit dispatched after the assembler returns |
| `callisto-back-end` | `…/validators/__specs__/proceeding-file-must-be-deliverable.validator.spec.ts` (modify) | Returns the loaded context; existing 404/403 tests stay **byte-identical** — that sameness is the evidence the guard did not move |
| `callisto-back-end` | `…/rename-proceeding-file-ts/__specs__/rename-proceeding-file.transaction.script.spec.ts` (**unmodified**) | Neighbour proof — must pass with **no edits** |
| `callisto-back-end` | `…/proceeding-service/__specs__/proceeding.service.spec.ts` (**unmodified**) | Neighbour proof for surface B |
| `callisto-back-end` | `…/job-submission-service/__specs__/job-submission.service.spec.ts` (**unmodified**) | Neighbour proof for surface C |

**Structural neighbour proof, in addition to the suites:** `git diff --name-only` must show **zero** files under `src/proceedings/**` and `src/proceeding-job-submission/**`. That is stronger than any assertion — the shared transaction script keeps its four dependencies and no outbox port, so those routes are *incapable* of emitting.

## Gates

Run in this order, from `callisto-back-end`. Serial, per the `git-commit-workflow` rule.

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` |
| lint | `npm run lint` |
| **architecture** | `npm run test:architecture` |
| tests | `npm test -- --runInBand` |

**`test:architecture` is not optional here and is not the usual boilerplate.** This design was *selected* by two `severity: 'error'` dependency-cruiser rules (`transaction-scripts-no-aggregators`, `services-no-converters`), and the chosen shape — an assembler injecting an aggregator, a converter and a port — is legal by **reading** all four assembler rules, not by executing them. This gate is what turns report assumption **A6** from *confirmed directionally* into confirmed.

## Results log (filled at execution)

Status: **partially executed — automated suites green; atomicity and all manual scenarios NOT executed.**

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| 2026-08-11 | typecheck | `npx tsc --noEmit` | whole repo | **pass** (exit 0) | — |
| 2026-08-11 | **architecture** | `npm run test:architecture` | whole repo | **pass** (1 suite, 1 test) | **Closes assumption A6** — the assembler shape is legal by execution, not just by reading the rules |
| 2026-08-11 | lint | `npm run lint` | whole repo (`eslint . --fix`) | **pass** (exit 0) | `--fix` made no changes to this ticket's files; `git status` unchanged after |
| 2026-08-11 | **audit** | `npm audit --audit-level=high` | `callisto-back-end` | **FAIL — exit 1** | **42 vulnerabilities (6 high).** Pre-existing, not introduced here. **Hard stop before commit** per `git-commit-workflow`. Branch is on **stale `main` `71ce3cbf`**; `954f4adb PRDV-16391: npm audit fix` is among the 6 unmerged commits, so a rebase may clear it |
| 2026-08-11 | tests (full) | `npm test -- --runInBand` | whole repo | **pass — 364 suites / 1889 tests** | Includes the three neighbour suites passing **unmodified** |
| 2026-08-11 | HP-1, HP-4, NP-2, NP-3a, NP-4, EC-1 | `npm test -- --runInBand --testPathPattern "rename-deliverable-file\|deliverable-rename\|proceeding-file-must-be-deliverable"` | 4 suites / 22 tests | **pass** | — |
| 2026-08-11 | HP-2 (converter) | same command | `file-renamed-to-outbox-data.converter.spec.ts` | **pass** | Includes the five-keys-exactly assertion guarding against the stale Diagram ④ |
| 2026-08-11 | HP-3 (single `Date`) | same command | assembler spec | **pass** | `toBe` identity between `payload.renamedAt` and `rowUpdatedAt` |
| 2026-08-11 | HP-5, EC-2, NP-1 | same command | service spec | **pass** | Audit payload assertions kept byte-identical; `callOrder` proves audit fires after the assembler |
| 2026-08-11 | Neighbour proof (structural) | `git status --short` | `src/proceedings/**`, `src/proceeding-job-submission/**` | **pass — zero files** | 6 modified + 1 new dir, all under `src/granting-client-access/` |
| — | **NP-3b — real-Postgres atomicity proof** | — | — | **NOT RUN — blocked** | **The load-bearing scenario.** See the blocker note below |
| — | HP-6, M-1…M-5 (manual) | — | — | **NOT RUN** | Requires a running local Callisto against `callisto-postgres` (container is up) |
| — | EC-4 (AJSF gap measurement) | — | — | **NOT RUN** | Manual |
| — | EC-5 / assumption **A3** | — | — | **NOT RUN — blocked at seed** | Sub-millisecond interleaving not practically reproducible; A3 remains source-inspected and **unobserved** |

### Blocker — NP-3b was not executed, so atomicity is UNPROVEN

**Stated plainly because the plan required it to be:** *"If NP-3b cannot be run, atomicity is unproven and must be reported as such — not inferred from NP-3a passing."*

- **What NP-3a does prove:** the assembler propagates an outbox failure instead of swallowing it, and emits only after the rename. With a mocked aggregator and a mocked port, that is the ceiling.
- **What remains unproven:** that a **real** `files.file_name` UPDATE and a **real** `outbox_events` INSERT participate in one transaction and roll back together. The mechanism is verified by reading (`createTransactionalProxy` on the provider; `OutboxEventRepository.activeRepoForCreate()` → `TYPEORM_OUTBOX_REPOSITORY_RESOLVER`, bound `@Global`), and the provider is wired correctly — but reading is not observing.
- **Why it was not written:** `createRepositoryTestContext` is scoped to a single repository class. NP-3b needs the whole chain hand-wired — `ProceedingAggregator` (many injected transaction scripts), `RenameProceedingFileTS`, `ProceedingFileRepository`, `DuplicateProceedingFileNameValidator`, `RelatedFilesLineageMapper`, `TransactionContext` + `TransactionContextService`, the converter, and a throwing outbox stub — plus seeded `files` / `file_attachments` / `file_tags` / join rows.
- **The cheap path that does prove it, and should be run first:** **manual step M-5.** `REVOKE INSERT ON callisto.outbox_events FROM <app_role>`, attempt a real rename, confirm `files.file_name` is **unchanged**, then `GRANT` back. `callisto-postgres` is already up. That single observation is worth more than the rest of the manual plan.
- **Risk if it is never run:** a plain class provider instead of `createTransactionalProxy` would lose atomicity and **every one of the 1889 tests would still pass.** That is precisely the failure this scenario exists to catch.
