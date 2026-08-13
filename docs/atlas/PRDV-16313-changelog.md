# PRDV-16313 — Emit callisto.client-access.file.renamed.v1 on deliverable file rename

## Ticket

- **ClickUp:** [PRDV-16313](https://app.clickup.com/t/43227262/PRDV-16313)
- **Repo:** `callisto-back-end`
- **Branch:** `PRDV-16313`
- **PR:** _(link when opened)_

---

## Requirements (verbatim)

_Paste from ClickUp, spec, or the user's first description. Do not paraphrase on first capture._

Captured verbatim in [`PRDV-16313/PRDV-16313-original-ticket.md`](./PRDV-16313/PRDV-16313-original-ticket.md) (ClickUp browser capture, 2026-08-11). Reproduced here unchanged:

> **Parent:** PRDV-15736 — Make Atlas metadata available to Planet Portal
>
> **Prerequisites:**
>
> - PRDV-16293 (outbox + dispatcher foundation) merged
>
> ## Summary
>
> When an ops user renames a deliverable file via `PATCH /file/:fileId`, emit `callisto.client-access.file.renamed.v1`. Dione uses this to keep the displayed filename in sync with Callisto.
>
> ## Acceptance Criteria
>
> - When `PATCH /file/:fileId` succeeds for a client deliverable file, an outbox row is written with routekey `callisto.client-access.file.renamed.v1`
> - Payload matches `CallistoClientAccessFileRenamedV1Data`
> - Only emitted for files that have the `CLIENT_DELIVERABLE` tag (non-deliverable file renames do not emit)
> - Unit tests prove outbox write occurs with correct payload
>
> ## Wiki
>
> `systems/neptune/callisto/granting-client-acess/emit-grant-events/PRDV-16313-endpoint-file-renamed.md`
>
> Dev Note: RabbitMQ Config

**Note on the Wiki path above:** it is stale as written. The file lives at `systems/neptune/callisto/granting-client-acess/epic-PRDV-15736-make-atlas-metadata-available-to-planet-portal/PRDV-16313-endpoint-file-renamed.md` — the `emit-grant-events/` folder was renamed. Same defect PRDV-16312 recorded. The verbatim text above is preserved as-is.

---

## Context

_Optional: related tickets, environment, files to avoid, spec paths, team decisions._

- **Orchestrated ticket.** Run through the seven-phase `orchestrate` lifecycle. Phase state, artifacts and waivers live in [`PRDV-16313/orchestration.md`](./PRDV-16313/orchestration.md) — that ledger is the resumable state, this file is the cross-session narrative.
- **Epic:** PRDV-15736 — Make Atlas metadata available to Planet Portal. This is one of ten sibling endpoint tickets under `epic-PRDV-15736-.../` in `larry-adams`.
- **Sibling ticket with a shipped body of work in the same space: PRDV-16312** (`POST /upload-complete` → `file.created.v1`). See [`PRDV-16312-changelog.md`](./PRDV-16312-changelog.md) and `PRDV-16312/orchestration.md`. Same outbox mechanism, same design doc, same reviewer.
- **Authority on scope is the wiki spec, not the ClickUp text.** Design doc `dione-file-access-event-design.md` Q25 records the convention: *"ClickUp stays wiki-pointer."* PRDV-16312 was misled by taking the ClickUp description as the specification.
- **Epic-level scope change already applied: RabbitMQ is descoped** (upstream `318bd0a`, "PRDV-15736: remove rabbitMQ work from scope of epic"). A producer ticket's obligation ends at a correctly shaped `outbox_events` row; there is no dev-queue observation criterion.
- **Environment hazard carried from PRDV-16312:** `callisto-back-end/node_modules` was emptied by that run (`npm ci` → E401) and left unrestored, which blocked its verification gates. Resolve before this ticket needs audit/lint/tests.
- **Prerequisite to verify, not assume:** PRDV-16293 (outbox + dispatcher foundation) merged. PRDV-16312 confirmed it at commit `43ad3dea` / PR #399.

---

## Plans

_Lives in **dustin-thomason** only. Reference plans here so future agents do not repeat abandoned approaches. **Larry-adams** paths are **read-only links** to coworker specs — never create or push changelog/plan files there._

**This ticket keeps no Plans rows, deliberately.** It is orchestrated, and the `orchestrate` skill's **No status bookkeeping** rule replaces the Plans state machine with the ledger: an artifact either exists or it does not. Phase plans for this ticket are files on disk —

| Plan artifact | Where |
| ------------- | ----- |
| Recon-and-plan (Phase 1, frozen once written) | `PRDV-16313/investigations/PRDV-16313-recon-and-plan.md` |
| Implementation plan (Phase 4, frozen once written) | `PRDV-16313/PRDV-16313-implementation-plan.md` |
| Phase state, waivers, overrides | `PRDV-16313/orchestration.md` |

Read the ledger before proposing a new approach; superseded artifacts move to `PRDV-16313/dnu/` rather than being restatused.

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-08-11T23:15:00Z — callisto-back-end (Phases 4–5 — implemented; blocked at the audit gate)

- **Summary:** Phase 4 plan approved and frozen; Phase 5 code, specs and docs complete. **Blocked before commit by a pre-existing audit failure.** Nothing committed, nothing pushed.
- **Plan used:** `PRDV-16313/PRDV-16313-implementation-plan.md` (approved, saved verbatim, frozen). No deviation from its ordered steps except as noted below.
- **Files (all under `src/granting-client-access/`):** new `domain/assemblers/rename-deliverable-file-assembler/` — `rename-deliverable-file.assembler.ts`, `rename-deliverable-file-assembler.provider.ts`, `rename-deliverable-file.params.ts`, `rename-deliverable-file.projection.ts`, `file-renamed-outbox-converter/{file-renamed-outbox-converter.input.ts, file-renamed-to-outbox-data.converter.ts}`, plus two `__specs__`. Modified: `validators/proceeding-file-must-be-deliverable.validator.ts` (+ its spec), `domain/services/deliverable-rename-service/deliverable-rename.service.ts` (+ its spec), `registries/transaction-script.registry.ts`, `granting-client-access.module.ts`.
- **Commits:** **none — blocked.**
- **Verification gates (final post-change state):**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| typecheck | `npx tsc --noEmit` | whole repo | **pass** | — |
| architecture | `npm run test:architecture` | whole repo | **pass** | **Closes assumption A6** — the assembler shape is legal by execution, not just by reading the rules |
| lint | `npm run lint` | whole repo | **pass** | `--fix` changed nothing in this ticket's files |
| **audit** | `npm audit --audit-level=high` | `callisto-back-end` | **FAIL (exit 1)** | **42 vulns, 6 high. Pre-existing.** Hard stop before commit per `git-commit-workflow` |
| tests | `npm test -- --runInBand` | whole repo | **pass — 364 suites / 1889 tests** | Includes the three neighbour suites passing **unmodified** |

- **Notes:**
  - **The audit failure is probably a rebase away from fixed, and the rebase is blocked by someone else's work.** The branch was cut from **stale `main` `71ce3cbf`** because `git pull --ff-only` aborted on a **pre-existing uncommitted `package-lock.json`**. `954f4adb PRDV-16391: npm audit fix` is among the six commits on `origin/main` `645de730`. Four working-tree items (`.swcrc`, `notification-template-preview.html`, `package-lock.json`, untracked `scripts/`) are **not this run's** and were deliberately left untouched — stashing or discarding them while the user was away was not mine to decide. **Same hazard, same file, that PRDV-16312's ledger already recorded.**
  - **Atomicity is UNPROVEN, and that is reported rather than inferred.** NP-3b (real-Postgres rollback) was not executed: `createRepositoryTestContext` is single-repository scoped, and the scenario needs the whole assembler→aggregator→TS→repository chain hand-wired plus a throwing outbox. NP-3a proves only propagation, which is a mocked suite's ceiling. **A plain class provider instead of `createTransactionalProxy` would lose atomicity and all 1889 tests would still pass** — exactly what NP-3b exists to catch. Cheapest proof: manual **M-5** (`REVOKE INSERT ON callisto.outbox_events`), and `callisto-postgres` is up.
  - **Self-review (`pr-review-patterns.md`) caught two things before any PR existed.** Class D — the two mirror validators diverged when one gained a return type, and midnjerry has flagged *that exact pair* before; resolved by a JSDoc note explaining why the mirror was deliberately left alone rather than widened into `src/proceedings`. Class F — fail-closed with no try/catch reads as a missing safety net, so the deliberate absence is now documented in the source.
  - **Deviation from the plan, recorded:** the plan had the assembler inject `@InjectLogger`. **Omitted** — it adds a DI failure mode, no criterion needs it, and the no-op path's real trace is `files.updated_at` staying unchanged.
  - **Plan step 9's wording was corrected by reality:** it said to add the converter "beside `FileCreatedToOutboxDataConverter`", which **is not on `origin/main`** (PRDV-16312's six commits are unmerged). Branching from `main` was still right — it carries PRDV-16293's port, writer and full seven-contract allow-list, which is all this ticket depends on, and stacking on an unmerged branch still under review would have been worse. **Merge-order coupling:** whichever of 16312 / 16313 merges second resolves the registry file.
  - **`P5.spec-approved` satisfied by WAIVER, not approval** — authorised explicitly by Dustin Thomason. Residual risk itemised in the ledger; **LD-019 (deliverability timing) is the expensive one** if Larry disagrees.
  - **`P3.spec-submit` remains held.** `larry-adams` verified clean on `main`, no `PRDV-16313` branch, addendum still a draft.

### 2026-08-11T21:40:00Z — dustin-thomason (Phase 3 — spec comparison reviewed and corrected; addendum drafted)

- **Summary:** The spec comparison was reviewed by Dustin and **withheld from submission**. Six findings raised, **all six upheld — two were factual errors in the agent's own analysis, not framing preferences.** Artifacts corrected, then the addendum drafted from dictated input as an *implementation and risk* addendum rather than a competing spec. **Nothing pushed to `larry-adams`** — verified clean on `main`, no `PRDV-16313` branch.
- **Files:** `specs/PRDV-16313-spec-comparison.md` (revision 2, with a correction log), `specs/PRDV-16313-addendum-draft.md` (new, DRAFT), `specs/PRDV-16313-locked-decisions.md` (LD-002 corrected, LD-004 scope narrowed, **LD-018** and **LD-019** added), `PRDV-16313-future-development-concerns.md` (**C10** added, C8 corrected), `testing/PRDV-16313-test-plan.md` (NP-3 split, M-5 added, test map updated), `PRDV-16313/orchestration.md`.
- **Commits:** none.
- **Notes — the two analytical errors, recorded because they are the reusable lesson:**
  - **A consequence of our own design was filed as a defect in Larry's spec.** The comparison claimed the specified payload could not be built at the specified site because `proceedingId` was missing. **Wrong** — `RenameProceedingFileTS` reads `proceedingId` internally, as this ticket's *own coverage ledger already recorded*. It needs plumbing only because our assembler emits outside that script. The genuinely absent value there is authenticated-user identity. **The evidence to catch this was already in our own artifacts and was not cross-checked when writing the assessment.**
  - **Self-contradictory chronology.** The comparison's prose noted commit `4d284978` predates the spec; its weighting table said the code moved "underneath a maintained document." Both cannot be true. Corrected to an unchecked assumption at authoring time. Also imprecise: a rename transaction script *does* exist behind the endpoint — what does not exist is a *dedicated deliverable* boundary.
- **Notes — four overclaims corrected:**
  - **"All four ACs met literally" was false.** A successful **no-op** `PATCH` writes nothing, and AC1 covers a successful `PATCH`. Now question 1 for Larry with suggested wording (LD-018).
  - **The tag question was the wrong question.** Re-reading the same `isDeliverable` value is dead code — but the validator runs **outside** the new transaction and the tag is **mutable both ways**, so a *fresh in-transaction* check is a different guarantee. Now question 2 (LD-019, concern C10). Asking "do you want a dead branch?" would have wasted the reviewer's attention on the wrong axis.
  - **NP-3 could not prove atomicity.** It was assigned to a unit suite with both collaborators mocked. Split into **NP-3a** (unit: ordering + propagation) and **NP-3b** (real Postgres: actual rollback), plus manual **M-5** fault injection. Atomicity is the main property added beyond the spec, so it cannot rest on mocks — **and if NP-3b cannot run, atomicity is reported unproven rather than assumed.**
  - **"Silent" and "closed" both overstated.** A non-transactional outbox failure propagates a 500; the defect is that the filename commits while the response reports failure. And A3 is source-inspected and unobserved with EC-5 blocked — an evidence-backed hypothesis, not a closed finding.
- **`P3.spec-submit` remains HELD** at Dustin's instruction. The addendum is a draft for his reading; no push, no PR.
- **Verification gates:** none — docs-only in `dustin-thomason`, which has no `package.json`. **Not applicable to this session's scope.**

### 2026-08-11T20:05:00Z — dustin-thomason (Phase 3 — Probe & spec)

- **Summary:** Seventeen decisions locked, both job stories **accepted**, spec written, test plan **refined**. `P3.spec-submit` is the one step outstanding — it publishes to a shared repo and is held for explicit confirmation.
- **Plan used:** the frozen Phase 1 recon-and-plan; no deviation.
- **Files:** `PRDV-16313/specs/PRDV-16313-locked-decisions.md`, `PRDV-16313/specs/PRDV-16313-spec.md` (new); `PRDV-16313/stories/` — both stories **accepted** + index rewritten; `PRDV-16313/PRDV-16313-future-development-concerns.md` (C8, C9 appended); `PRDV-16313/testing/PRDV-16313-test-plan.md` (refined).
- **Commits:** none — docs only.
- **Notes:**
  - **`P3.reconcile` kept three questions away from the user.** The fail-open/fail-closed question had a discoverable half: the shipped producer has **no try/catch** and there are **zero catch blocks** in either outbox infrastructure tree, so the precedent is unambiguously fail-closed. That reduced the ask from *"what should happen?"* to *"deviate or match?"*. The literal-tag-check question is Larry's, not Dustin's, so it went to the addendum. Dione's behaviour is unanswerable in this workspace and was carried with an owner.
  - **Grilled and locked:** both user types confirmed as drafted (story 01 = client, story 02 = ops user), and **fail closed** — a failed outbox write rolls back the rename.
  - **Latency question was mis-framed and was corrected rather than defended.** It was posed as "should a surface state the latency", a UX question. It was really *"does story 01 criterion 5 need a time bound?"* — answer no, closed as an agent call with the residual recorded (an ops user who tells a client to refresh inside the seconds-scale window may get the old name reported as a bug).
  - **All six of story 01's criteria were rewritten; none of story 02's.** That asymmetry is the useful finding: story 02's criteria were drafted about what Callisto does at its own boundary — inside this ticket's observable range — while story 01's were about what a client *sees*, which nothing in this repo can witness. Same drafting discipline, one survivor.
  - **The rewrite is scope-following, not build-following, and the ordering is the defence.** Two decisions bounded scope before any code existed: the epic owner's RabbitMQ descope (`318bd0a`) and the user's AJSF ruling. Nothing is implemented. Recorded as concern **C9** precisely because restating a criterion to match what can be proven is one letter from reinterpreting it to match what was built.
  - **Two concerns added.** C8 — fail-closed means an outbox failure now also blocks renaming, so a client-facing concern can deny an ops user a valid action. C9 — this ticket proves the *producer* and asserts nothing about the client's view; a payload correctly shaped but semantically wrong would pass everything here.
  - **Both stories accepted with one open question each, both Dione's,** and both carrying structural proof Callisto cannot answer them. Holding either in `draft` would have blocked the spec on another team's epic.
  - **Verification gates:** none run. Docs-only in `dustin-thomason`, which has **no `package.json`** — audit/lint/test are **not applicable to this session's scope**. Owed at Phase 5, including `npm run test:architecture`, which closes report assumption A6.

### 2026-08-11T18:20:00Z — dustin-thomason (Phases 1–2 — Recon, plan, and investigation report)

- **Summary:** Phase 1 recon complete and its plan approved; Phase 2 emitted the full artifact set. Verdict **proceed**, problem class **not reframed** — *a missing event on an existing write path*. **The spec's four acceptance criteria are correct and identical to the ClickUp text; its Technical Design is wrong on three counts.** No `callisto-back-end` file was created, edited or run, and no branch was cut.
- **Plan used:** `PRDV-16313/investigations/PRDV-16313-recon-and-plan.md` (approved, saved verbatim, frozen).
- **Files:** `PRDV-16313/investigations/PRDV-16313-recon-and-plan.md`, `PRDV-16313-investigation.md`, `PRDV-16313-coverage-ledger.md`, `PRDV-16313-diagrams.md` (new); `PRDV-16313/PRDV-16313-why-these-changes.md`, `PRDV-16313-future-development-concerns.md`, `PRDV-16313-pr-draft.md` (new); `PRDV-16313/testing/PRDV-16313-test-plan.md` (new, seeded); `PRDV-16313/stories/` — both stories + index reconciled; `PRDV-16313/orchestration.md` (updated).
- **Commits:** none — docs only, in `dustin-thomason`.
- **Notes:**
  - **The three spec defects, because they are what the next session most needs.** (1) *"Inject `CLIENT_ACCESS_OUTBOX` into the rename transaction script"* — there is no rename transaction script in `granting-client-access`; the only one lives in `proceedings`, is shared by three HTTP surfaces, has no `AuthUser`, and would create a module cycle. **The obvious adaptation is illegal too:** `transaction-scripts-no-aggregators` at `severity: 'error'` blocks a new TS from importing `ProceedingAggregator`, and `services-no-converters` blocks the service holding the converter. Only an **assembler** is legal. (2) Silent on **atomicity** — the rename path has no transaction at all, so a naive emit yields "renamed, no event, forever, silently," and design Q5 forbids the reconciler that would repair it. (3) Silent on the **deterministic event id**, whose collision mode is a silent row overwrite rather than an error.
  - **The spec's own justification for its tag guard is false.** It says *"the rename endpoint may serve non-deliverable files as well"* — it cannot, since commit `4d284978` (PRDV-15776) split rename by deliverable vs submission and `ProceedingFileMustBeDeliverableValidator` 403s them first. So AC3 is met structurally and no new tag check is added. This is the one item a reviewer may reasonably overrule (locked decision D3).
  - **Reading the wiki spec at Phase 1 is the process fix inherited from PRDV-16312, and it paid off.** That run read it only at Phase 2 and reached a wrong disposition on half the ticket. Here the criteria turned out fine; the value came from tracing the spec's *instructions* into code that had moved underneath them.
  - **Two user decisions narrowed scope, and together they made neighbour protection provable.** The AJSF rename hole → concern C1, recorded not fixed. The timestamp → generated at the emit site. Result: **zero files under `src/proceedings/**` or `src/proceeding-job-submission/**`**.
  - **Closed a question two prior ledgers left open:** a duplicate deterministic outbox id **silently UPDATEs** the prior row (non-generated uuid PK + `repo.save()`), resetting status and attempts, with no exception and no log. `file.created.v1` never hit it because a file is created once — **rename is the first repeatable event on aggregate `File`**. Confirmed *directionally*; owes a real-Postgres demonstration (report A3).
  - **Corrected a stale sibling finding:** PRDV-16312 recorded `node_modules` as emptied and unrestored; verified populated (823 entries). Re-check before `P5.gates` regardless.
  - **Two acceptance criteria are knowingly not met and were deliberately NOT reworded** — story 01 criterion 1 (false via the AJSF route, C1) and story 01 criteria 1–4 (client-observable, but the boundary ends at an outbox row given the RabbitMQ descope). Both are Phase 3 open variables.
  - **Seven concerns recorded (C1–C7),** two of which need someone else's decision: C1 (the AJSF hole) and C5 (the epic's coverage audit examined only one of three modules — five sibling events are still unbuilt and will be specced from the same incomplete source; a missed *delete* surface would be materially worse than a missed rename).
  - **Verification-gate reporting:** none run this session. No code was touched, so audit/lint/test gates are **not applicable — the work was docs-only in `dustin-thomason`, which has no `package.json`**. Gates are owed at Phase 5, including `npm run test:architecture`, which is not boilerplate here: it is what turns report assumption A6 from *confirmed directionally* into confirmed.

### 2026-08-11T00:00:00Z — dustin-thomason (Phase 0 — Capture)

- **Summary:** Orchestration opened on PRDV-16313. Resume protocol case 3 — the ticket folder already held `PRDV-16313-original-ticket.md` (ClickUp capture, 2026-08-11) and nothing else, so ledger state was reconstructed from disk. Phase 0 closed: ledger scaffolded, this changelog created with the request captured verbatim, and two job stories drafted from the verbatim request alone.
- **Plan used:** none — Phase 0 is capture only. The Phase 1 recon plan does not exist yet.
- **Files:** `docs/atlas/PRDV-16313/orchestration.md` (new), `docs/atlas/PRDV-16313-changelog.md` (new), `docs/atlas/PRDV-16313/stories/PRDV-16313-job-stories-index.md` (new), `docs/atlas/PRDV-16313/stories/PRDV-16313-job-story-01-client-sees-current-filename.md` (new), `docs/atlas/PRDV-16313/stories/PRDV-16313-job-story-02-internal-renames-stay-internal.md` (new).
- **Commits:** none yet.
- **Notes:**
  - **Two stories, not one.** The request states a single motivation (keep the client's displayed filename in sync) but its third acceptance criterion describes a second, separately falsifiable outcome — a non-deliverable file's rename must not reach the client-facing system at all. Split rather than folded, per the job-story rule on distinct problems.
  - **12 open questions carried, none answered by inference.** Several are code-discoverable (payload shape, whether the PATCH handler already knows the file's tags, what else the endpoint mutates) and are Phase 1's to resolve by evidence, not the user's to decide.
  - **No `callisto-back-end` file was created, edited or run.** The orchestrate entry check forbids touching the implementation repo until Phases 0 and 1 both read `done`.
  - **Prior-coverage lead recorded for Phase 1:** PRDV-16312's coverage ledger, locked decisions and concerns cover the outbox mechanism, the ODP contract (1.0.7) and the design doc. Consult before reopening any of it.

---

## Root cause analysis

_Optional — fill when debugging._

---

## Attempt history

_Optional — one subsection per failed or partial approach._

### Attempt 1 — short label (commit `abc1234` optional)

**What:**

**Result:**

---

## Key technical learnings

1. 

---

## Current state (as of 2026-08-11)

_What is merged / on branch / reverted / still pending._

- **Nothing implemented. No branch cut, no code touched, no commits.** `callisto-back-end` is untouched by this ticket.
- **Phases 0, 1 and 2 are `done`.** Original ticket captured; recon complete with its plan approved and frozen; full investigation artifact set emitted. Verdict **proceed**; problem class **not reframed** — *a missing event on an existing write path*.
- **The design is settled and evidence-backed:** a transaction-owning **assembler** at `src/granting-client-access/domain/assemblers/rename-deliverable-file-assembler/`, registered through a provider wrapped in `createTransactionalProxy`, delegating the rename to the unchanged `ProceedingAggregator` and writing the outbox row inside the same transaction. **Every file touched is under `src/granting-client-access/`; zero under `src/proceedings/` or `src/proceeding-job-submission/`** — which is the neighbour-protection proof rather than a claim.
- **No ODP change, no migration, no registry edit, no action/DTO/guard change.** `CallistoClientAccessFileRenamedV1Data` and the routekey allow-list entry both already ship (ODP 1.0.7; PRDV-16293 pre-registered all seven contracts).
- **The spec's Technical Design is wrong three times over** (non-existent emit site; silent on atomicity; silent on the deterministic event id, whose collision is a silent overwrite). Its four acceptance criteria are correct. **Phase 3 owes an addendum PR to `larry-adams` carrying all three**, plus the stale Diagram ④ payload, concern C1 and concern C5.
- **Next: Phase 3 — Probe & spec, in Working mode.** Seven genuine open variables to grill (the two user types are the highest-consequence pair), then the locked-decision ledger, story acceptance, the spec, and the addendum submission.
- **Two blocking-ish dependencies to respect at Phase 5:**
  - **`P5.spec-approved` is a hard gate.** Do not write product code before Larry responds to the addendum. Phase 4's plan approval is *not* a spec approval — the sibling PRDV-16312 shipped on a waiver here and is **still** gated on Larry's response to `larry-adams` PR #34. Do not let this ticket inherit the same open loop by default. If that response changes payload conventions, decisions locked here are affected — check its ledger before Phase 3 locks anything.
  - **`callisto-back-end/node_modules`** — PRDV-16312's ledger records it emptied by a failed `npm ci`. Verified populated (823 entries) on 2026-08-11, but re-check before the gates rather than discovering it there.
- **Two assumptions still owe proof:** A3 (a duplicate deterministic outbox id silently UPDATEs — read from library source, not observed) and A6 (the assembler shape passes every fitness rule — read, not executed). Neither blocks Phase 3; both must close before the PR asserts them.

---

## New code introduced

_Optional — new modules, composables, endpoints._


