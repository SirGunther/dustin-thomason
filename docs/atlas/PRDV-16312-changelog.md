# PRDV-16312 — [BE] endpoint-upload-complete-file-created

## Ticket

- **ClickUp:** [PRDV-16312](https://app.clickup.com/t/43227262/PRDV-16312)
- **Repo:** `callisto-back-end`
- **Branch:** `PRDV-16312` _(not created yet — Phase 4 plans the branch step)_
- **PR:** _(link when opened)_
- **Ticket folder:** `docs/atlas/PRDV-16312/`
- **Orchestration ledger:** `docs/atlas/PRDV-16312/orchestration.md`

---

## Requirements (verbatim)

_Captured from the active ClickUp page on 2026-08-05 into `docs/atlas/PRDV-16312/PRDV-16312-original-ticket.md` → Original Request. Reproduced verbatim below; the original ticket artifact is the immutable capture._

> **Parent:** PRDV-15736 — Make Atlas metadata available to Planet Portal
>
> **Prerequisites:**
>
> - PRDV-16293 (outbox + dispatcher foundation) merged
>
> ## Summary
>
> When a file is uploaded directly into client deliverables via `POST /upload-complete`, emit:
>
> - `callisto.client-access.collection.created.v1` — if a new dynamic collection was created (find-or-create returns a new row)
> - `callisto.client-access.file.created.v1` — always, representing the new deliverable file
>
> This gives Dione the data it needs to display the file under the correct track → collection → deliverable type hierarchy.
>
> ## Acceptance Criteria
>
> - When `POST /upload-complete` succeeds for a client deliverable file, an outbox row is written with routekey `callisto.client-access.file.created.v1`
> - Payload matches `CallistoClientAccessFileCreatedV1Data`
> - If a new dynamic collection was created during the flow, an additional outbox row is written with routekey `callisto.client-access.collection.created.v1`
> - If the dynamic collection already existed (find-or-create returned existing), no `collection.created.v1` event is emitted
> - Unit tests on the transaction script prove both outbox writes occur in the 2-event case
> - Messages visible in the dev RabbitMQ queue
>
> ## Wiki
>
> `systems/neptune/callisto/granting-client-acess/emit-grant-events/PRDV-16312-endpoint-upload-complete-file-created.md`
>
> Dev Note: RabbitMQ Config

---

## Context

- **Parent epic:** PRDV-15736 — Make Atlas metadata available to Planet Portal. No changelog exists for the parent in this repo.
- **Prerequisite:** PRDV-16293 (outbox + dispatcher foundation) must be merged. No changelog exists for it in this repo; merge state is unverified as of Phase 0 and is a Phase 1 recon item.
- **Consumer:** Dione — reads the emitted events to render the track → collection → deliverable type hierarchy.
- **Infra dependency:** the ticket names a RabbitMQ config dev note. `docs/atlas/PRDV-16312/RABBITMQ_CONFIG_REQUEST_TEMPLATE.md` is the unfilled reference template; the filled request is expected output of a later phase.
- **Ticket memory location:** no `docs/callisto/` exists in this repo — all PlanetDepos ticket memory lives under `docs/atlas/`, including backend-only tickets (precedent: PRDV-16216).

---

## Plans

_Per the `orchestrate` skill's **No status bookkeeping** section, this lifecycle does not add or restatus a Plans row. Phase 1 emits `investigations/PRDV-16312-recon-and-plan.md` and Phase 4 emits `PRDV-16312-implementation-plan.md`; both are recorded in the orchestration ledger's Artifacts column, which is the single place phase state lives._

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-08-07T16:20:00Z — callisto-back-end + larry-adams — Correct a deviation from the spec; withdraw the spec review

- **Summary:** two corrections, both stemming from the same mistake — treating a clear spec as ambiguous.
- **Code fix (`e8c149ae`, pushed):** `deliverableCollectionValue` is now gated on `collection_kind` and sent for **dynamic collections only**. The previous commit sent it for static collections too. **The spec was never ambiguous** — it scopes the field to dynamic in five places, including the field-sourcing step (*"sourced from the dynamic collection entity's `value` field"*). Static collections are seeded consumer-side, so sending their name risked overwriting a label the consumer owns. LD-012 superseded by **LD-016**; concern **C7 retired** — the risk it described no longer exists.
- **`larry-adams` PR #34 closed.** It should never have been a review ask. Of the three "decisions beyond the spec": the by-id read is simply how the spec's own criterion gets satisfied; the converter typing is internal style; and the static-collection question was invented by not re-reading the spec. Closed with that explanation, the spec left **untouched** (`modified_by: Larry Adams`, no addendum link), and the repo restored to `main`.
- **Agent error, recorded:** an authoritative spec was escalated for review when nothing in it needed to change, and implementation details were framed as spec questions. That created a review gate that blocked nothing and put the agent's name on a request for the principal dev's time. The corrective is to re-read the spec before declaring it silent.
- **PR #406 updated** — the "awaiting Larry" framing removed, the dynamic-only behavior described, commit hash refreshed. Still a **draft**, still no reviewers.
- **Verification (final post-change state):**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto-back-end | **fail (exit 1)** | Unchanged and pre-existing — 3 high advisories, clean `main` fails identically. Waived to preserve work; blocks leaving draft |
| lint | `npm run lint` | callisto-back-end | pass | — |
| tests (unit) | `npm test -- --runInBand src/granting-client-access` | granting-client-access | pass — 74 suites, 367 tests | includes the reworked static-collection assertion |
| tests (integration) | `npm run test:integration` | whole repo | pass — 8 suites, 91 tests | via the `pre-push` hook |
| types | `npx tsc --noEmit -p tsconfig.json` | whole repo | pass | — |

- **Still open:** the audit advisories; end-to-end verification (needs AWS); `pg_trgm` is missing from migrations so a DB reset re-breaks local boot (concern to file); `dustin-thomason` docs uncommitted.

### 2026-08-07T02:05:00Z — callisto-back-end — Commit the emission as UNTESTED-END-TO-END

- **Summary:** committing the implementation to branch `PRDV-16312` to preserve the work. Unit and integration verification are complete and green; **the end-to-end path is deliberately unverified** and the commit body says so.
- **Why it stops here:** a real `POST /upload-complete` cannot be exercised without AWS. The action delegates to `file-objects`' `UploadCompleteTS`, which calls `s3ObjectRepository.uploadComplete()` — a genuine S3 `CompleteMultipartUpload` over real parts with real ETags — **before** any granting-client-access code runs. A synthetic `uploadId` is rejected with `404 "Upload session … not found"` (observed). So AC6-style live proof needs refreshed AWS credentials and a real multipart upload, which the user will do on a later pass.
- **Agent error worth recording:** I told the user AWS was not needed. That was wrong. I verified `DeliverableFileExistsValidator` hits the DB rather than S3 and stopped there, without checking the multipart completion sitting in front of it. Cost the user a round of setup.
- **What *was* proven locally** (real Postgres, Docker `callisto-postgres`): migrations ran (52 tables), dev dataset seeded (4 cases / 4 jobs / 5 proceedings), the route and Cognito auth both work (the 404 was application-level, not routing), and a new integration spec exercises a real `save()` round-trip.
- **Real defect caught by that integration spec:** `files.file_size` is a `bigint`, and TypeORM returns it as a **`string`** on read while the entity declares `number`. Without the converter's `Number(...)` the payload would have shipped `"9007199254"` where the contract declares a number. Recorded as concern **C8** — the entity's type is wrong for every reader of that column, not just this one.
- **Correction to the test plan:** `outbox_events` has **no `schema_uri` / `schema_version` columns**. The writer passes them to the facade but they are not persisted; the relay applies them at publish time. The verifiable row fields are `event_type`, `aggregate_type`, `aggregate_id`, and `data`.
- **Verification (final pre-commit state):**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto-back-end | **fail (exit 1)** | **WAIVED by the user** to preserve the work. 3 high advisories — `brace-expansion`, `fast-uri`, `ip-address`, all `fixAvailable`. **Pre-existing:** clean `main` also exits 1; no dependency added by this branch. Normally a hard stop per `git-commit-workflow`; must be triaged before any PR |
| lint | `npm run lint` | callisto-back-end | pass | `eslint --fix` mutated nothing |
| tests (unit) | `npm test -- --runInBand src/granting-client-access` | granting-client-access | pass — 74 suites, 367 tests | `pretest` conventions + architecture gates green |
| tests (integration) | `npm run test:integration -- file-created-to-outbox-data` | new converter integration spec | pass — 4 tests | requires Docker `callisto-postgres` |
| types | `npx tsc --noEmit -p tsconfig.json` | whole repo | pass | — |

- **Still open:** AC2's persistence half (no `outbox_events` row ever observed); `larry-adams` PR #34 unreviewed (proceeding under the earlier recorded waiver); the audit advisories.

### 2026-08-05T20:55:00Z — callisto-back-end — Phase 5 implementation (UNCOMMITTED — audit gate blocks commit)

- **Summary:** emission implemented on branch `PRDV-16312`. `POST /upload-complete` now writes one `callisto.client-access.file.created.v1` outbox row inside the existing `@Transactional()` boundary, with the collection's name carried inline. All tests green. **Not committed** — `npm audit --audit-level=high` exits 1, which is a hard stop before commit per `git-commit-workflow`.
- **Plan used:** `PRDV-16312-implementation-plan.md` (frozen). Followed as written; two deviations recorded below.
- **Files (callisto-back-end, branch `PRDV-16312`, uncommitted):**
  - NEW `…/upload-complete-deliverable-file-ts/file-created-outbox-converter/` — `file-created-to-outbox-data.converter.ts`, `file-created-outbox-converter.input.ts`, `__specs__/file-created-to-outbox-data.converter.spec.ts`
  - `…/upload-complete-deliverable-file.transaction.script.ts` — injected the port, converter and collection repository; extracted `resolveDeliverableCollection`; emit after persist
  - `…/upload-complete-deliverable-file-ts.provider.ts` — three new ctor args + `inject` entries
  - `src/granting-client-access/registries/transaction-script.registry.ts` — registered the converter
  - `…/__specs__/upload-complete-deliverable-file.transaction.script.spec.ts` — 7 new tests + harness for the new deps
- **Deviations from the plan, both minor and both toward repo convention:** the converter is registered in `transaction-script.registry.ts` (the actual house pattern) rather than the module's `providers` as the spec guessed; and the plan named the provider factory `createUploadCompleteDeliverableFileTSProvider` when it is `uploadCompleteDeliverableFileTSProvider`.
- **Two design corrections found during implementation, neither in the spec nor the design doc** (both now in the addendum on PR #34): the by-id branch never learned the collection's `value`, so AC3 was unsatisfiable there (fixed by reusing `DeliverableCollectionRepository.findById`); and `FileCreatedOutboxConverterFile` was initially declared as `File & {…}`, which collided with the branded `FileAttachmentId` — redeclared as an explicit structural subset, which is better design anyway since the converter now states exactly what it reads.
- **Red→green proven, not claimed:** with the emission temporarily disabled via an env guard, exactly the 5 positive emission tests failed while the 9 pre-existing and 2 negative tests passed. Guard removed; `grep __RED_GREEN_PROOF src` clean.
- **Self-review (`pr-review-patterns.md`) caught two Class C issues in my own tests** — hand-rolled `as unknown as jest.Mocked<…>` and four `as unknown as DeliverableCollection` casts. Replaced with `createMock<T>()` and local typed factories. Two `as never` casts remain, matching the file's own established pattern across its 9 pre-existing tests.
- **Verification (final post-change state):**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto-back-end | **fail (exit 1)** | **BLOCKS COMMIT.** 3 high: `brace-expansion`, `fast-uri`, `ip-address` — all `fixAvailable`. **Pre-existing** — clean `main` also exits 1; no dependency added here. Needs triage or a waiver |
| lint | `npm run lint` | callisto-back-end | pass | `eslint --fix` mutated nothing |
| tests | `npm test -- --runInBand src/granting-client-access` | granting-client-access | pass — 74 suites, 367 tests | `pretest` conventions + architecture gates green, which validates the domain→port layering |
| types | `npx tsc --noEmit -p tsconfig.json` | whole repo | pass (exit 0) | — |
| neighbours | `npx jest --config jest-e2e.json --runInBand find-or-create-dynamic-collection recategorize-deliverable-files approve-deliverable-files-v2` | assembler + 2 other callers | pass — 10 suites, 51 tests | specs **unmodified**; this is the regression boundary, not an "isolated" claim |

- **Not proven:** test-plan **M2 was not run** — no real `outbox_events` row was inspected, so **AC2 is `needs proof`, not covered**. Needs a local Callisto + DB. Nothing downstream of the outbox row is exercised at all (RabbitMQ descoped, Dione consumer doesn't exist yet).
- **Notes:** `P5.spec-approved` satisfied by **waiver**, not approval — PR #34 remains unreviewed; residual risk itemised in the ledger, with LD-012/concern C7 the material one.

### 2026-08-05T19:40:00Z — dustin-thomason + larry-adams — Phase 4 + spec-approval gate

- **Summary:** Phase 4 implementation plan staged (17 ordered steps). Then the user caught that **the orchestrate skill had no spec-approval gate at all** — fixed the skill, and satisfied the new gate for this ticket by submitting an addendum to Larry Adams as `larry-adams` **PR #34**. Phase 5 is now **blocked** on his response.
- **Skill fix (`dustin-thomason`):** `steps.csv` had **zero** human approval steps across all 49 — the only approvals were the two plan-mode ones, which approve *plans*, not the spec. Added participant `REV` plus `P3.spec-submit` (seq 65) and `P5.spec-approved` (seq 20 — the hard gate immediately before `P5.code`); wired into `SKILL.md`'s phase map, Phase 3/5 Do lists, and Do-not list. `verb` is a validated closed set, so existing verbs were reused. Verified: `render-sequence.ps1 -Check` → 51 steps / 22 participants; `validate-workflows.ps1` → 0 errors; `sync-rules.ps1 -Check` clean under 5.1.
- **Spec submission (`larry-adams` PR #34):** Larry already authored this ticket's spec, so the submission is an **addendum**, not a competing spec — `PRDV-16312-implementation-decisions-addendum.md`. Contents: LD-011 (by-id collection read), LD-012 (static collections **+ risk C7**, the item most needing his confirmation), LD-013 (typing against ODP, a deliberate deviation from the `ContactOutboxEvent` precedent), two payload hazards (`bigint`→string, `timestamp`-without-tz vs `.toISOString()`), and four documentation defects. Wired into the vault per `AGENT.md`; **no content of his spec changed**; **no reviewer requested**.
- **Files:** `larry-adams` — new addendum, `systems/README.md` index entry, reciprocal link + frontmatter bump on Larry's spec (commit `18dc178`, branch `PRDV-16312`). `dustin-thomason` — `agents/skills/orchestrate/steps.csv`, `SKILL.md`, regenerated mirrors, `orchestration.md`, this changelog.
- **Rebase hazard caught before committing:** `git pull --ff-only` aborted on uncommitted edits, so the branch was cut from stale `main`. Upstream `318bd0a` ("PRDV-15736: remove rabbitMQ work from scope of epic") had **already applied** Derrick's descope to nine specs including this one — removing the dev-queue AC and replacing the manual step with *"confirm an outbox row is written with the expected routekey + payload"*. **Independent confirmation of LD-007 and of test-plan M2.** Rebased onto `318bd0a`; addendum §6 rewritten to reference the applied change rather than announce it.
- **Correction to earlier artifacts:** this run's coverage ledger and concern C2 called `larry-adams` "read-only / never a push target". Wrong and too broad — verified squash-merged spec PRs (`#7`, `#8`), a review cycle (`af5680c … Remove polling spec per review`), and 12 prior commits by the user. The real restriction is changelog/workflow files only.
- **Commits:** `larry-adams` `18dc178` (specs only). No `callisto-back-end` code — blocked by design on the new gate.
- **Notes:** vault defect flagged not fixed — `systems/README.md` links all 10 epic specs under the pre-rename `emit-grant-events/` path (`R100` renames), which is also why the ClickUp ticket's `## Wiki` path is dead. Kept out of the review diff; offered as a separate PR.

### 2026-08-05T19:05:00Z — dustin-thomason (docs only) — Phase 3

- **Summary:** Decisions locked, both job stories **accepted**, spec written, test plan **refined**. 15 locked decisions — **12 settled by evidence** (never put to the user) and **3 grilled**. Two external inputs from Derrick (principal dev) reshaped scope, and `P3.reconcile` found two gaps that neither the ticket nor the design doc addressed.
- **Plan used:** the approved Phase 1 recon-and-plan, plus its §13 investigation addendum. No new plan.
- **Files:** `specs/PRDV-16312-locked-decisions.md` (new), `specs/PRDV-16312-spec.md` (new), `investigations/PRDV-16312-investigation.md` (§13 addendum appended — verdict **not** rewritten), `testing/PRDV-16312-test-plan.md` (refined, +4 scenarios), `PRDV-16312-future-development-concerns.md` (C7 added, C6 resolved, C3 addendum), both stories `accepted` + index, `orchestration.md`.
- **Commits:** none — still no `callisto-back-end` code. Implementation is Phase 5.
- **Scope changes from Derrick:**
  - **RabbitMQ removed from the epic** — *"We are only concerned with getting these items to the outbox with the correct contract shape… The RabbitMQ queue creation will be handled when the consumer (Planet Portal) is dev-ready to consume it."* → wiki **AC6 withdrawn** (LD-007), OV-4 closed, `RABBITMQ_CONFIG_REQUEST_TEMPLATE.md` deliberately left unfilled, test-plan M1 descoped. **This made the slow-feedback risk worse**, not better: it removed the only step that would have exercised a real consumer path.
  - **Callisto-only confirmed** (LD-008). His ODP caveat resolved as **unnecessary** — ODP 1.0.7 verified on disk with a complete 17-field `CallistoClientAccessFileCreatedV1Data` including `deliverableCollectionValue`, and `COLLECTION_CREATED` is **not exported at all**, confirming the removal at the contract level (LD-006).
- **Two gaps found by `P3.reconcile`, both needing a decision rather than more tracing:**
  1. **`deliverableCollectionValue` was unreachable on one branch.** The TS only calls the assembler when `pendingDynamicCollectionName` is non-empty; on the by-id branch it never learns the collection's `value`, so AC3's *"or already existed"* could not be met. → **LD-011**: read the collection by id. Distinct from the projection-widening wrongly proposed at Phase 1 — the projection already returns `value`; the TS discards it.
  2. **Static collections were unspecified.** `collection_kind` distinguishes static from dynamic and both carry `value`; the contract comment covers only "dynamic" and "no collection". → **LD-012**: populate for both. **Risk accepted** — Dione owns static rows via its own migrations, so this depends on its upsert being id-keyed, which is unverifiable from this repo and no longer observable after LD-007. Recorded as concern **C7**, cited by the LD row.
- **Deliberate deviation from precedent (LD-013):** the new converter returns ODP's `CallistoClientAccessFileCreatedV1Data` directly. Every existing producer hand-declares a parallel type — `ContactOutboxEvent` does **not** alias `CallistoContactCreatedV1Data` — which is the drift risk in concern C3. Typing against the exported contract costs nothing and, after LD-007, is the only mechanism that fails loudly on drift.
- **Stories accepted with four questions carried,** each with a named owner: story 01 `Q1`/`Q3`/`Q8`, story 02 `Q1`. All consumer-side or product; none changes the payload. One criterion in **each** story was reworded because LD-007 made "watch it reach the client's view in a shared test environment" unobservable here — originals preserved, both logged. Neither was reinterpreted to fit an implementation; the scope boundary moved before any code existed.
- **Notes:** `node_modules` restored by the user, so ODP was read first-hand rather than inferred. Still nothing built, linted, or tested — no artifact claims otherwise.

### 2026-08-05T18:30:00Z — dustin-thomason (docs only) — Phases 1–2

- **Summary:** Recon (Phase 1, approved plan) and the full investigation-report set (Phase 2). **Scope corrected from two outbox events to one.** The ClickUp description asks for `collection.created.v1`, which was deliberately removed — design doc Q21 (*"Removed"*) and enacted in prerequisite PRDV-16293 commit `31c81db4` (*"Remove collection.created"*). Collection identity travels **inline** on `file.created.v1` via `deliverableCollectionId` + `deliverableCollectionValue`, which Dione upserts from. Verdict: **proceed** — one emission, no cross-repo or infra dependency.
- **Plan used:** `investigations/PRDV-16312-recon-and-plan.md` (approved, frozen). Deviated from on two points, both recorded as a why-log course change rather than edits to the frozen plan: story 02 is not "gated on a decision" (the design had already decided it), and the proposed `DynamicCollectionProjection` widening for a created-vs-found flag is **unnecessary** (the value is sent regardless).
- **Files:**
  - `docs/atlas/PRDV-16312/investigations/` — `PRDV-16312-recon-and-plan.md`, `PRDV-16312-investigation.md`, `PRDV-16312-coverage-ledger.md`, `PRDV-16312-diagrams.md`
  - `docs/atlas/PRDV-16312/` — `PRDV-16312-why-these-changes.md`, `PRDV-16312-future-development-concerns.md`, `PRDV-16312-pr-draft.md` (unfilled shell), `orchestration.md`
  - `docs/atlas/PRDV-16312/testing/PRDV-16312-test-plan.md` (seeded)
  - `docs/atlas/PRDV-16312/stories/` — both stories reconciled + index updated
  - **Also, outside this ticket:** `agents/skills/orchestrate/steps.csv` + `scripts/check-steps.ps1` — fixed at the user's instruction so `check-steps.ps1` can see a PRDV-prefixed `original-ticket.md` (`TICKET` path is now `<prefix>original-ticket.md`). Mirrors regenerated with `sync-rules.ps1`. Uncommitted.
- **Commits:** none — no `callisto-back-end` code written. Implementation begins at Phase 5.
- **Key finding worth carrying:** the drift has a traceable cause. The design doc's **Status checklist** contradicts its own resolved bodies — line 1581 says Q15 "confirmed **2 outbox writes**" (body: 1) and line 1588 says Q22 has "**9 events** … collection.created" (its table lists 11 and omits it). The ClickUp text matches those stale lines. Reported as concern C2 for Larry; five sibling emission tickets could inherit the same wrong framing.
- **Notes / blockers:** `callisto-back-end/node_modules` is **empty** — an `npm ci` during this session cleared it then failed E401 (repo `.npmrc` uses `${GITHUB_TOKEN}`, unset in the agent shell; `gh` lacks `read:packages`). Nothing was built, linted, or tested, and no such claim is made anywhere in the artifacts. Must be restored before Phase 5 (concern C6). Also resolved a standing question in the orchestrate skill: Bash **does** run inside Claude Code Plan mode; only writes are blocked.

### 2026-08-05T17:42:37Z — dustin-thomason (docs only)

- **Summary:** Phase 0 (Capture) of the orchestrated lifecycle. Ledger reconstructed from disk for a pre-skill ticket folder that already held the ClickUp capture; changelog created with requirements verbatim; job stories drafted from the verbatim request alone.
- **Plan used:** none — Phase 0 precedes any plan.
- **Files:**
  - `docs/atlas/PRDV-16312-changelog.md` (new)
  - `docs/atlas/PRDV-16312/orchestration.md` (new)
  - `docs/atlas/PRDV-16312/stories/` (new — index + drafted stories)
- **Commits:** none yet.
- **Notes:** No prior Current state, Plans, or Attempt history existed to align against — this is the first entry for the ticket. No implementation-repo file touched. `PRDV-16312-original-ticket.md` left untouched (immutable once captured).

---

## Root cause analysis

_Not applicable — this is new emission behavior, not a defect._

---

## Attempt history

_None yet._

---

## Key technical learnings

1. _None recorded yet._

---

## Current state (as of 2026-08-05)

Docs-only, through **Phase 2 of orchestration**. No `callisto-back-end` code written, no branch created. Next: Phase 3 (probe & spec, Working mode).

**Scope, corrected and settled by evidence:** **one** outbox emission — `callisto.client-access.file.created.v1` from `UploadCompleteDeliverableFileTransactionScript`, carrying the 17 fields of `CallistoClientAccessFileCreatedV1Data` including `deliverableCollectionId` + `deliverableCollectionValue` inline. **`collection.created.v1` is a non-goal** — removed by design (Q21), so the ClickUp description's two-event framing is stale. The `larry-adams` wiki spec + design doc are authoritative over the ClickUp text (design Q25: *"ClickUp stays wiki-pointer"*).

**Confirmed:** PRDV-16293 merged (`43ad3dea`, PR #399). `CALLISTO_CLIENT_ACCESS_FILE_CREATED_V1` already registered — no registry, ODP, or RabbitMQ change needed for the event itself. The TS is `@Transactional()`, so the outbox row joins the domain write atomically. `CLIENT_ACCESS_OUTBOX` has **zero** production consumers, making this the foundation's first producer. Dynamic collections are created at three call sites; the other two belong to siblings PRDV-16311 and PRDV-16314.

**Phase 3 complete — spec written, both stories accepted, 15 decisions locked.** Ready for Phase 4 (implementation plan, Plan mode).

**Additional scope settled at Phase 3:** RabbitMQ is **out of the epic** (Derrick) — AC6 withdrawn, no topology request, the producer's obligation ends at a correctly shaped `outbox_events` row (LD-007). **No ODP change needed** — 1.0.7 verified on disk with the complete 17-field contract; `COLLECTION_CREATED` is not exported at all (LD-006). Payload assembly goes in a dedicated converter typed to ODP's `CallistoClientAccessFileCreatedV1Data` (LD-013, LD-014). The by-id branch gets a collection read so `deliverableCollectionValue` is populated either way (LD-011); it is sent for static and dynamic collections alike (LD-012, risk-accepted per concern C7).

**Carried into Phase 5, with owners:** four consumer-side/product story questions (locked-decisions *Carried forward* table); concern **C7** (Dione's static-collection upsert, unverifiable here); concern **C3** (no producer in the repo aliases its ODP type — LD-013 fixes it for this event only).

**Environment:** `node_modules` restored by the user; ODP 1.0.7 present. Concern C6 resolved. **Nothing has been built, linted, or tested** — no artifact claims otherwise, and the refined test plan is deliberately in place before any code is written.

---

## New code introduced

_None yet._
