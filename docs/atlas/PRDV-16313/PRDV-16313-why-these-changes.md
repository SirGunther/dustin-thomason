# Why these changes — atlas/PRDV-16313

> The living "Why" of this ticket. Created Phase 1 (materialized at Phase 2's first action), updated every phase, finalized at close. High-level — scenarios live in the testing-implementation doc; point-in-time classification lives in [the investigation report](./investigations/PRDV-16313-investigation.md).

## Problem class (the core — what are we actually solving?)

**A missing event on an existing write path.**

Not a logic bug, not a data-model gap, not a permissions problem. The rename works correctly today: an ops user changes a deliverable file's name, the row updates, an audit event fires. The defect is that the write **announces nothing to the system that needs to know**. Dione (Planet Portal) keeps its own copy of the filename, populated when the file was first shared, and nothing ever tells it that copy went stale.

Why the class matters — it decides both where the work goes and what can go wrong:

- **Where:** a new emission at an existing seam. Rename behavior itself must not change. Any diff that alters how renaming works is out of class.
- **What can go wrong:** three failure modes specific to *adding an announcement*, none of which are about renaming. Emitting on the wrong path (the shared transaction script serves submission files too). Emitting when nothing was actually written (the no-op branch). The announcement being lost after the write has already committed (no transaction on this path).

Second of ten sibling endpoint tickets under epic PRDV-15736. The first, PRDV-16312 (`file.created.v1`), established the house pattern; this follows it.

## The code at the root (what/where is the problem)

The root is an **absence**, so it is pinned by where the emission has to go rather than by a faulty line:

- `src/granting-client-access/domain/services/deliverable-rename-service/deliverable-rename.service.ts` — orchestrates the rename and dispatches an audit event. **This is the last place that holds everything the payload needs** (the acting user, the file id) and the first place after the deliverable gate. It writes nothing to the outbox.
- `src/proceedings/domain/transaction-scripts/rename-proceeding-file-ts/rename-proceeding-file.transaction.script.ts` — where the name actually changes. **Shared by three HTTP surfaces**, which is why it cannot be the emit site.
- `src/proceedings/infrastructure/repositories/proceeding-file.repository.ts:133-138` — `updateFileName`, the single `UPDATE`. Autocommits; no transaction wraps it.

Full trace in report §5.

## The problems we're solving

1. **The client sees a filename their deposition team already changed.** The name Dione shows is the one the file had when it was first shared. There is no path that refreshes it, and no error anywhere — the divergence is silent and permanent. → job story 01.
2. **Names given to internal working files must not reach the client.** The rename surface is not universally deliverable-only, so an announcement added carelessly would carry non-deliverable file names outward. → job story 02.

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-08-11 — recon and plan

**Obvious:**
- A write path that changes client-visible state and emits nothing. The class was legible from the ticket's first sentence and did not move.
- The ODP contract and the routekey allow-list already exist (`@planetdepos/orbital-docking-protocol@1.0.7`; all seven client-access contracts pre-registered by PRDV-16293). So this is a producer-only change — no contract negotiation, no migration.
- The house pattern to copy is `file.created.v1` from the sibling ticket: dedicated converter returning the ODP type explicitly, port injected by Symbol, routekey via `<CONTRACT>.eventType` and never a literal.

**Not obvious — three findings, each of which would have produced a wrong or silently-broken result if the spec had been followed literally:**

1. **The spec's named emit site does not exist.** It says *"inject `CLIENT_ACCESS_OUTBOX` into the rename transaction script."* There is no rename transaction script in `granting-client-access` — the chain runs service → `ProceedingAggregator` → `RenameProceedingFileTS`, which lives in `proceedings`. The spec's premise was true before commit `4d284978` (PRDV-15776) split rename by deliverable vs submission; both halves of its Technical Design fall out of that one stale assumption, including the tag guard, which the spec justifies with *"the rename endpoint may serve non-deliverable files as well"* — it cannot, `ProceedingFileMustBeDeliverableValidator` 403s first.
2. **The obvious adaptation is forbidden by an architecture fitness rule.** A new `RenameDeliverableFileTS` in the right module that delegates to the aggregator is the natural fix — and `transaction-scripts-no-aggregators` blocks it at **`severity: 'error'`**. `services-no-converters` blocks holding the converter in the service. The one legal shape is an assembler. This was not visible from the spec, the design doc, or the sibling ticket; only from `fitness-functions-rules/architecture-rules/`.
3. **A duplicate outbox event id is a silent overwrite, not an error.** `OutboxEvent.id` is a non-generated uuid PK and `OutboxEventRepository.create` ends in `repo.save()`, so TypeORM finds the row and UPDATEs it — resetting `status` to `PENDING` and `attempts` to `0`, with no exception and no log. `file.created.v1` never exercised this because a file is created once. **Rename is the first repeatable event on aggregate `File`**, so this ticket is where the hazard first becomes reachable.

**Assumptions logged** (full ledger in report §8): that emitting from the shared TS is impossible rather than merely inadvisable (**confirmed** — module direction plus the fitness rule); that the outbox write enlists in our transaction (**confirmed** — `activeRepoForCreate()` → `TYPEORM_OUTBOX_REPOSITORY_RESOLVER`, bound `@Global`); that a duplicate id silently UPDATEs (**confirmed directionally** — read from `repo.save()` on a non-generated PK, owes a real-Postgres demonstration); that an assembler owning a transaction passes every fitness rule (**confirmed directionally** — owes an actual `test:architecture` run).

**What was noise:** the `trackTypeId` on the rename request body looked like it might matter to the payload. It does not — it is consumed only by the auth guard, never enters the command, and the transaction script reads the real `trackTypeId` from the database instead. (Worth noting separately that a client-supplied `trackTypeId` driving the permission check without being cross-checked against the file's actual track is a pre-existing smell, but it is not this ticket's and not a payload concern.)

**What got us to the plan:** reading the ticket's own cited wiki spec **at Phase 1 rather than Phase 2**. That is a process fix carried in from PRDV-16312, where reading it late produced a wrong disposition on half the ticket. Here it paid off immediately in the opposite direction: the spec was mostly right, and the parts that were wrong were only discoverable by tracing its instructions into code that had moved underneath them.

**Two user decisions taken this phase** (both narrowed scope):

- **The AJSF hole is recorded, not fixed.** `PATCH /<ajsf>/file/:fileId` reaches the shared rename TS with no authenticated user, no deliverable/submission validator, and no audit dispatch — so it can rename a `CLIENT_DELIVERABLE` file invisibly. The user's ruling was a workflow claim, not a risk acceptance: *"There should be no circumstance where a file from the user could be renamed once it is submitted… Once it is declared a client deliverable, there would be no reason for a user to ever change the name."* So the exposure is a latent defect to surface as a caution rather than work to bundle here. → concern C1.
- **The timestamp is generated at the emit site**, one `Date` used for both `renamedAt` and `rowUpdatedAt`, on minimal-blast-radius grounds. The alternative — threading the persisted instant out of `updateFileName` — would ripple into `src/proceedings`. Both are reads of the same process clock milliseconds apart (`updateFileName` mints `new Date()` in app code, not a DB `now()`), so there is no source-of-truth difference being given up. → concern C4.

Together those two decisions are what keep the diff inside a single module, which is also what makes neighbor protection provable rather than argued.

## Changes made — categorized (filled as implementation locks; subject to update)

_Not yet implemented — Phase 5 fills this. The plan's shape anticipates: 1 requested change (the emission itself), 1 capability gap (no transaction on the rename path), and 1 convention drift accepted deliberately (a validator that returns its loaded context). No bug fixes: the two defects found (C1, C2) are both being recorded rather than fixed._

## Why it shipped together

_Pending implementation. The bundle to justify: the emission (the request), the transaction boundary that makes the emission survivable, and the validator return that supplies `proceedingId` without a third database read. The second and third are not scope creep — without the transaction the fix reintroduces the silent staleness it exists to remove, and without `proceedingId` the contract's payload cannot be built at all._

## Scope

Confined to `src/granting-client-access/`. **Zero files under `src/proceedings/` or `src/proceeding-job-submission/`** — which is simultaneously the scope statement and the neighbor-protection proof: the shared rename transaction script keeps its four dependencies and no outbox port, so the submission and AJSF routes remain structurally incapable of emitting.

Follow-ups spun off: C1 (AJSF rename of a deliverable — missing user, validator, audit), C2 (extensionless-filename mangling), C5 (re-run the epic's coverage audit across `proceedings` and `proceeding-job-submission` before the remaining five events ship).

## Net

_Pending close. Provisionally: a five-field event emitted at the one seam that holds both the acting user and the deliverable guarantee, made atomic with the rename, with the spec's Technical Design corrected on three counts and two latent defects recorded rather than fixed._

## Verified

_Pending Phase 5. Gates required: `npm audit --audit-level=high` → `npm run lint` → `npm run test:architecture` (the enforcement for the fitness rules this design turns on) → `npm test -- --runInBand`. Plus the manual outbox-row check. PR link on open._
