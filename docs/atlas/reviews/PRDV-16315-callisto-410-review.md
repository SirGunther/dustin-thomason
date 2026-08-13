# Review — callisto-back-end #410 (PRDV-16315 / PRDV-16316)

**PR:** [PRDV-16315 / PRDV-16316: Emit file.unapproved.v1 and collection.deleted.v1](https://github.com/planetdepos/callisto-back-end/pull/410)
**Author:** midnjerry (Jerry Balderas)
**Branch:** `PRDV-16315-emit-file-unapproved-and-collection-deleted` → `main`
**Size:** 21 files, +1103 / −42, 4 commits
**Review date:** 2026-08-11
**Prior review activity:** none — no reviews, no inline comments at time of review.
**Companion:** [#403](PRDV-16310-callisto-403-review.md) (PRDV-16310), reviewed separately.

**Verdict: approve with cleanups.** Stronger than #403 on test coverage and on documenting its own
reasoning, and the PR body discloses its behavior changes proactively. One item wants fixing before merge:
**G1** (the cast, shared with #403 — three sites across the two PRs, fix together). Everything else is
convention, coverage, or a forward-looking question.

---

## Method note — how this one was read

Everything below was read out of branch refs (`git show <ref>:<path>`, `git diff origin/main..<ref>`,
`git grep <ref>`). Nothing was checked out and no working tree was touched.

**Gates were not run for this PR**, and that's a real gap in the evidence, so it's stated rather than
glossed. Running the suite needs either a checkout over uncommitted local work or a worktree outside the
repo, and neither was available under this session's constraints. What that means in practice:

- Every **structural** claim below (what the code does, what changed vs `main`, what the specs cover) is
  verified by reading the branch and is as reliable as the #403 review.
- The **executable** claim in G1 — that removing the cast typechecks — was already proven during the #403
  review, and that check deliberately covered all three payload types including both of this PR's:
  `CallistoClientAccessCollectionDeletedV1Data` and `CallistoClientAccessFileUnapprovedV1Data` assign to
  `Record<string, unknown>` with no cast under `--strict`, `tsc` exit 0.
- **Not independently verified:** the PR body's own gate results (364 suites / 1880 tests, `test:conventions`,
  `tsc --noEmit`, `eslint`). To #410's credit it reports exact commands, which is more than #403 does.

---

## Baseline

Same as #403: on `origin/main` the `CLIENT_ACCESS_OUTBOX` port is bound but **nothing calls `write` on it**.
#403 is the first emitter; #410 is the second and third, and its body says so — *"Both follow the existing
converter-plus-outbox shape established by `grants.replaced.v1`."*

That inheritance is literal, including the defect: **both** of #410's converters carry #403's cast verbatim.

Both contracts (`CALLISTO_CLIENT_ACCESS_FILE_UNAPPROVED_V1`, `CALLISTO_CLIENT_ACCESS_COLLECTION_DELETED_V1`)
already exist in ODP and are already registered in `client-access-outbox-event.registry.ts`. Nothing was
emitting them. This PR wires the emitters only.

---

## Pass 1 — Documentation

### What it claims

| Event | Trigger | Behavior |
| --- | --- | --- |
| `file.unapproved.v1` (PRDV-16315) | `UnapproveDeliverableFilesTS` | One outbox row per file *actually* unapproved. Files already unapproved produce no event. |
| `collection.deleted.v1` (PRDV-16316) | `DeleteDynamicCollectionTS` | One row after the collection is removed. |

Three things the PR body flags about itself, unprompted — all accurate, and worth crediting:

1. **Both transaction scripts are now `@Transactional()`.** Neither was before. Side effect: batch unapproval
   moves from per-file atomicity to all-or-nothing.
2. **`proceedingId` comes from the attachment, not the file.** `File` has no proceeding reference; it lives on
   `FileAttachment.attachedToId` when `attachedToType` is `Proceeding`. Attachments owned by a Job or Case are
   deliberately excluded rather than reported under the wrong proceeding.
3. **Per-user flag rollout has a hole for revocations.** An unflagged operator can revoke in Callisto while
   Dione keeps serving, and nothing re-emits to correct it. Mitigation stated: grant the flag to the whole
   operator group at once.

Disclosing all three, especially the third, is the behavior the `pr-review-patterns` Class H item is trying to
produce. Noted as a positive, not a finding.

### Not in scope

PRDV-16317 (`proceeding.file.deleted.v1`) — blocked, contract not yet in ODP. Stated in the body.

---

## Pass 2 — Implementation

### What's right

1. **`@Transactional()` is wired, not just decorated.** The decorator alone is inert — it needs
   `createTransactionalProxy`. Both scripts got new provider files
   (`unapprove-deliverable-files-ts.provider.ts`, `delete-dynamic-collection-ts.provider.ts`) and both were
   **removed from `transactionScriptRegistry`** with a comment matching the existing `RecategorizeDeliverableFilesTS`
   precedent. Decorating without rewiring is the classic silent-no-op here, and every unit test would still
   have passed. It was done correctly.

2. **The proceeding lookup is batched and uses the ORM, not raw SQL.** `findProceedingIdsByIds` uses TypeORM
   `In()` with a `select` projection, guards the empty-array case, returns a `Map`, and rides along in the
   existing `Promise.all` beside the tag lookups — so no N+1 and no extra round trip. It also carries a doc
   comment explaining *why* `proceedingId` has to come from the attachment. This is the "avoid brittle SQL"
   guardrail satisfied without commentary needed.

3. **The flag-off path skips the extra query, and a test asserts it.** `params.isClientAccessOutboxEnabled ? … :
   Promise.resolve(new Map())` matches the body's claim that "an unflagged caller pays no extra query" — and
   `'then: should unapprove without resolving proceedings or emitting'` proves it rather than asserting it.

4. **The atomicity rationale is documented in the code.** `emitUnapprovedEvents` carries:

   > *"Emits inside the transaction so a file cannot stay unapproved in Callisto while Dione keeps serving it.
   > Skipped files are left alone because their deliverable status never changed."*

   This is exactly what #403 is missing (its F2). Good, and it should be the pattern.

5. **Skipped files produce no event, and that's tested.** A file that was already unapproved never had its
   deliverable status change, so emitting would assert a state transition that didn't happen. Covered by
   `'when: file is not tagged as deliverable'` and `'when: file is tagged deliverable but not submission'`.

6. **Coverage is genuinely broad** — materially better than #403:

   | Script | Scenarios covered |
   | --- | --- |
   | `UnapproveDeliverableFilesTS` | happy path; one row per file; flag off (no lookup, no emit); batch → one row per processed file; processed file with no proceeding attachment → no event; not-tagged-deliverable skip; deliverable-but-not-submission skip; validator rejection short-circuits |
   | `DeleteDynamicCollectionTS` | happy path; emits row; flag off; not-found; static collection rejected; sentinel rejected; collection-still-has-files rejected |

7. **Batch shares one timestamp, and the converter says why.**
   `FileUnapprovedToOutboxDataConverter` hoists `unapprovedAt` outside the `map` so a batch reads as one act,
   while `aggregateId: String(file.fileId)` keeps the deterministic event ids distinct. Both facts are in a doc
   comment. That's the non-obvious interaction between batch semantics and the id helper, written down.

8. **`userId` threading is minimal and correct.** `DeleteDynamicCollectionAction` gains
   `@VerifiedUserDecorator()`; the unapprove path already had `AuthUser` at the service layer so only the params
   type widened. Flag resolution in both services matches the `ProceedingService` / `CaseMergeService` shape on
   `main`.

9. **New spec for `GrantingClientAccessService`** where none existed.

---

## Findings

### G1 — The `as unknown as Record<string, unknown>` cast, inherited twice

**Fix alongside #403's F1 — same one-line edit, three sites total.**

| File | Line |
| --- | --- |
| `delete-dynamic-collection-ts/collection-deleted-to-outbox-data.converter.ts` | 30 |
| `unapprove-deliverable-files-ts/file-unapproved-to-outbox-data.converter.ts` | 41 |

Identical to [#403 F1](PRDV-16310-callisto-403-review.md): each converter declares its payload as the ODP
contract type, then erases that declaration with the strongest cast TypeScript has. When ODP changes the
contract shape, these lines are what stop the compiler from saying so.

Already proven removable — the isolated `--strict` check run during the #403 review deliberately covered both
of this PR's payload types, and both assign to `Record<string, unknown>` with no cast (`tsc` exit 0).

This is the propagation #403's review predicted: the first emitter set the shape, the second copied it twice.
Three instances across two PRs. **Fixing #403 alone leaves two behind** — they need the same edit.

**Class C.**

---

### G2 — `@Transactional()` puts five existing `Promise.all` sites onto one connection

**Downgraded to a note after re-checking. Precedent exists; no action needed.**

> **Correction.** This finding originally claimed #410 "creates the first instance of
> fan-out-inside-a-transaction" because no other `@Transactional()` transaction script contained
> `Promise.all`. That search was wrong: `createTransactionalProxy` wraps **any method named `apply`**,
> decorator or not (`const shouldWrap = Boolean(isTransactional) || prop === 'apply'`), so searching for
> the decorator missed every script that is transactional by virtue of its provider. Searching all
> proxied classes instead finds `RecategorizeDeliverableFilesTS` — already on `main`, already
> transactional, already running `Promise.all` over **per-file writes**
> (`fileAttachmentRepository.setTrackCollectionAndType`). Parallel writes on a transactional connection
> is established, shipped practice in this module. The finding below is what survives.

`unapprove-deliverable-files.transaction.script.ts`

The PR body discloses one consequence of adding `@Transactional()` — batch unapproval becomes all-or-nothing —
and argues for it well ("a partial revoke is a security-relevant half-state"). Agreed. But there's a second
consequence that isn't mentioned.

This script already used `Promise.all` in **five** places before the change:

| Site | What runs in parallel |
| --- | --- |
| 1 | 2 tag lookups + file fetch (reads) |
| 2 | 2 tag-attachment lookups + the new proceeding lookup (reads) |
| 3 | `fetchedFiles.map(processFile)` — fans out per file |
| 4 | inside `processFile`: tag delete + 2 attachment updates (**writes**) |
| 5 | `writeParamsList.map(write)` — the new outbox writes (**writes**) |

Before this PR, those drew independent connections from the pool. Now, all of it runs inside
`transactionContext.runTransactional()`, and the outbox repository resolves through the same
`TransactionContext` (`TYPEORM_OUTBOX_REPOSITORY_RESOLVER` in `outbox-transaction-context.module.ts`) — so
every query shares one transactional connection. For a batch of N files that's **3N writes plus N outbox
writes** serializing on a single connection where they previously parallelized.

Precedent, correctly searched: `RecategorizeDeliverableFilesTS` is provided via `createTransactionalProxy`
on `main` and already runs `Promise.all` over per-file writes. So the pattern is shipped and working — the
pg driver queues per client, parallel queries on one connection serialize rather than corrupt, and this
module has been relying on that.

What remains is a difference of **degree, not kind**: recategorize has one such site, this script has five,
and the per-file fan-out means a batch of N files now issues roughly `3N` writes plus `N` outbox writes on
one connection where they previously spread across the pool. Whether that's material depends on realistic
batch size, which I can't determine from the diff.

**Not worth a PR comment on its own.** Recording it here so that if batch unapproval ever shows up as slow,
the cause is already written down. If anything is worth saying to the author, it's a half-sentence in the
body noting the batch now serializes — not a code change.

---

### G3 — `deleteDynamicCollection` takes an inline object type instead of a `.command.ts`

**Non-blocking, convention.**

`granting-client-access.service.ts`

```ts
async deleteDynamicCollection(params: {
    readonly collectionId: number;
    readonly user: AuthUser;
}): Promise<DeleteDynamicCollectionProjection>
```

`type-colocation.mdc` names service input a `Command`, in its own `{action}.command.ts` file, and
`type-files.mdc` adds "each Command… must be in its own file." The same module already has **six** of them:

```
approve-deliverable-files.command.ts      deliverable-upload-complete.command.ts
deliverable-rename.command.ts             deliverable-upload-start.command.ts
recategorize-deliverable-files.command.ts unapprove-deliverable-files.command.ts
```

Including `unapprove-deliverable-files.command.ts` — the sibling path this very PR also touches.

Most directly: **#403 does this correctly.** That PR introduced
`save-contact-deliverable-type-grants.command.ts` for precisely this situation — a service signature growing
from a scalar to a shape carrying `AuthUser`. Same author, same week, same refactor, two different answers.

**Fix:** `delete-dynamic-collection.command.ts` exporting `DeleteDynamicCollectionCommand`.

---

### G4 — No test that a failing outbox write rolls the change back

**Non-blocking, coverage gap — but higher stakes here than in #403.**

Both scripts' specs mock `clientAccessOutbox.write` to resolve. Nothing exercises the rejection path.

This matters more on #410 than on #403 because the transaction *is* this PR's headline argument — the body
opens by explaining that without `@Transactional()` "the state change could commit and the outbox write could
fail, leaving Dione permanently believing a revoked file is still available." That claim currently has no test
behind it. The regression it invites is someone later wrapping `emitUnapprovedEvents` in a try/catch to stop
outbox trouble from failing user-facing unapprovals — which would reintroduce exactly the drift the PR exists
to prevent, with every existing test still green.

```ts
clientAccessOutboxMock.write.mockRejectedValue(new Error('outbox down'));
await expect(target.apply({ ...params, isClientAccessOutboxEnabled: true }))
    .rejects.toThrow('outbox down');
```

Worth one on each script.

---

### G5 — The two converters are asymmetric in documentation and timestamp handling

**Non-blocking, minor.**

`FileUnapprovedToOutboxDataConverter` carries a doc comment explaining the shared batch timestamp and the
distinct aggregate ids, and hoists `unapprovedAt` / `rowUpdatedAt` above the `map` so the pair is derived once.
`CollectionDeletedToOutboxDataConverter`, added in the same PR, has **no comment** and computes
`rowUpdatedAt: new Date(deletedAt)` inline at the return.

Both are correct. The single-row case genuinely needs less explanation than the batch case. But they sit side by
side as the two exemplars the next emitter will be modelled on, and right now they disagree about how much of
this is worth writing down. Cheap to make them match.

This is `pr-review-patterns` **Class D** applied to documentation rather than to tests — two parallel
implementations landing in one PR with asymmetric treatment.

---

### G6 — Silently skipped non-proceeding attachments need a matching rule on the approve side

**Non-blocking. A question worth answering before the sibling emitters land.**

When an unapproved file's attachment isn't owned by a `Proceeding`, `emitUnapprovedEvents` logs a `warn` and
emits nothing. The body's reasoning is sound — *"Emitting a wrong `proceedingId` would corrupt Dione's view, so
silence is the safer failure mode"* — and I agree that's the right call in isolation.

The forward-looking risk is asymmetry. `file.approved.v1` and `file.created.v1` are registered contracts with no
emitter yet. If whichever PR adds them resolves `proceedingId` by a different rule — or emits for attachments
this path skips — then a file can be **announced approved and never announced unapproved**, and Dione keeps
serving it. That is the precise drift this PR exists to close, relocated to the seam between two emitters.

Two small things that would help:

- **Say the rule once, where both sides will find it.** The `findProceedingIdsByIds` doc comment is the natural
  home and already half says it; making it explicit that *every* client-access emitter must resolve
  `proceedingId` this way turns it into shared law rather than local behavior.
- **Assert the `warn`.** The `'when: a processed file has no proceeding attachment'` test asserts no event is
  emitted, but not that anything was logged. Since the log is the only trace that a file drifted, it's the part
  most worth pinning.

Also worth knowing, and I couldn't determine it from the diff: **can a client-deliverable file be attached to a
Job or Case in practice?** If not, the branch is unreachable and could be an error rather than a warn. If yes,
those files drift silently and someone should own that.

---

### G7 — An outbox failure gets logged under a misleading message

**Non-blocking, cosmetic — but it's the string someone greps during an incident.**

`emitUnapprovedEvents` runs inside the pre-existing try/catch, so a failed outbox write surfaces as:

```
'Error unapproving deliverable files'
```

The files *were* unapproved; the outbox write is what failed, and the transaction is about to roll both back.
The message points an on-call reader at the file-tag logic rather than at the relay.

---

## Pass 3 — `pr-review-patterns` checklist

| Class | Verdict | Detail |
| --- | --- | --- |
| **A** — i18n externalization | **n/a** | Backend service; no user-facing strings. Exception messages (`'Only dynamic collections can be deleted.'`) are pre-existing on `main`, not introduced here. |
| **B** — named constants over magic literals | **clean** | Both converters extract their aggregate type (`FILE_AGGREGATE_TYPE`, `DELIVERABLE_COLLECTION_AGGREGATE_TYPE`) and take route keys from ODP constants. `FILE_TAGS` and `ATTACHED_TO_TYPES` used rather than string literals. Better than #403, whose TS spec hand-typed the route key. |
| **C** — typed helpers over hand-rolled casts | **hit** | **G1** — the cast, twice. Test doubles themselves are clean. |
| **D** — mirror-implementation coverage symmetry | **hit, minor** | Two converters land together with asymmetric documentation and timestamp handling — **G5**. Test coverage across the two scripts is symmetric and good. |
| **E** — extract dense logic into named helpers | **clean** | `emitUnapprovedEvents`, `processFile`, `toProjection` are separate named methods; payload construction lives in converters. `apply` reads as orchestration. |
| **F** — justify intentional removal / absence of defensive code | **clean** | The load-bearing decision — emitting inside the transaction — is documented at `emitUnapprovedEvents`. This is what #403 was missing. |
| **G** — editorial cleanup before review | **clean** | No stray comments or commented-out code. The two registry comments explaining why the scripts moved to proxy providers are load-bearing, not leftovers, and match existing precedent. |
| **H** — escalate cross-cutting architecture decisions | **clean, actively good** | Consumes the PRDV-16293 foundation, reuses the existing flag shape, and — unusually — the body volunteers its own behavior change, its own rollout hole, and the blocked sibling ticket. Nothing cross-cutting was decided quietly here. |

### Pattern promotion — now evidenced

`pr-review-patterns.md` promotes on 2+ independent instances. Pattern 3 (Class C) currently reads as a
**test-mock** concern. There are now three production instances of the same mechanism across two PRs:

| # | PR | File | Line |
| --- | --- | --- | --- |
| 1 | #403 | `contact-deliverable-type-grants-to-replaced-outbox.converter.ts` | 40 |
| 2 | #410 | `collection-deleted-to-outbox-data.converter.ts` | 30 |
| 3 | #410 | `file-unapproved-to-outbox-data.converter.ts` | 41 |

Recommend rewording Pattern 3's scope from "hand-rolled test-mock casts" to *"any cast that erases a contract or
projection type, in test or production code,"* and adding these rows once the PRs merge.

Worth noting as context: the reflog on `PRDV-16312` shows commits titled *"Replace remaining spec mock casts
with a typed factory"* and *"Build spec fixtures from typed helpers, drop shape casts."* The same class of change
is being worked in parallel on the test side — which is an argument that widening Pattern 3's scope reflects
something already happening rather than inventing a rule.

---

## Recommendation

**Approve with cleanups.** This is the more mature of the two PRs: broader coverage, correct transactional
wiring, an ORM-based batched lookup instead of raw SQL, and a body that volunteers its own behavior changes and
rollout risk rather than waiting to be asked.

- **G1** — fix together with #403's F1. Three sites, one edit each; fixing #403 alone leaves two behind.
- **G2** — no action. Downgraded to a note after finding the precedent I originally missed.
- **G3** — add the `.command.ts`; #403 already shows the shape.
- **G4** — one rejection test per script; it's the PR's headline claim.
- **G5 / G7** — small tidies.
- **G6** — worth settling before the `file.approved.v1` / `file.created.v1` emitters land, not necessarily here.

**Merge order:** #403 and #410 collide on `FEATURE_FLAG_NAMES` and `GrantingClientAccessModule.imports`;
whichever lands second rebases those two lines. Already flagged by the author on #403.
