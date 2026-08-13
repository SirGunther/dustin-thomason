# Draft PR comments — callisto #403 and #410

**Status: DRAFT — nothing posted to GitHub.** Staging ground only. Comment text below is written to be
pasted as-is once approved.

Source reviews: [#403](PRDV-16310-callisto-403-review.md) · [#410](PRDV-16315-callisto-410-review.md)

---

## Is anything incorrect?

**In the PRs — no.** Across both, I found **no functional defect**. Nothing computes a wrong value, emits a
wrong payload, skips a case it should handle, or leaves the database in a bad state. Everything below is
type-safety risk, convention, coverage, documentation, or a forward-looking question — not a bug.

Candidates I chased and **killed**, so they don't get re-raised later:

| Suspected defect | Why it isn't one |
| --- | --- |
| #410: duplicate file ids in a batch → duplicate outbox rows → deterministic-event-id collision → whole transaction rolls back | `fetchFilesByIds` uses `where: { id: In(ids) }`. SQL `IN` returns each row once, so `fetchedFiles` is already deduped and `processedFiles` cannot contain the same file twice. Not reachable. |
| #410: DI breaks when the two scripts leave `transactionScriptRegistry` | Both proxy providers use the class as the token (`provide: DeleteDynamicCollectionTS`, `provide: UnapproveDeliverableFilesTS`), so existing constructor injection resolves unchanged. Correctly wired. |
| #410: adding `processedFiles: File[]` to the projection changes a public contract | `git diff origin/main` on the projection file is **empty**. The field already existed on `main`. No contract change. |
| #403/#410: `rowUpdatedAt` round-tripping through an ISO string loses precision vs the payload timestamp | ISO 8601 preserves milliseconds and `DeterministicEventIdHelper` only hashes `getTime()`. The two cannot disagree. Stylistic only. |

**In my own review — yes, one thing, now corrected.** My #410 finding G2 claimed the PR "creates the first
instance of fan-out-inside-a-transaction" because no other `@Transactional()` script contained `Promise.all`.
That search was wrong: `createTransactionalProxy` wraps **any method named `apply`**, decorator or not, so
searching for the decorator missed every script that is transactional via its provider.
`RecategorizeDeliverableFilesTS` is on `main`, is transactional, and already runs `Promise.all` over per-file
writes. Precedent exists; G2 is downgraded to a note and **should not be raised on the PR**.

---

## Comments by category

Ordered by category, then by whether they need action. **Blocking** means I'd want it resolved before merge.

---

### ARCHITECTURE

#### A1 · Type erasure at the contract boundary — `Blocking` · #403 + #410 (3 sites)

> **Category:** Architecture (contract safety) — presents as a one-line code change, but the thing at stake
> is whether the ODP contract is actually load-bearing.

**Files:**
- #403 — `contact-deliverable-type-grants-to-replaced-outbox.converter.ts:40`
- #410 — `collection-deleted-to-outbox-data.converter.ts:30`
- #410 — `file-unapproved-to-outbox-data.converter.ts:41`

**Draft comment:**

> Each of these converters declares its payload as the ODP contract type and then erases that declaration on
> the next line:
>
> ```ts
> const payload: CallistoClientAccessGrantsReplacedV1Data = { … };
> return { …, payload: payload as unknown as Record<string, unknown>, … };
> ```
>
> `as unknown as` is the strongest cast TypeScript has — it switches off assignability checking entirely.
> Today it's a no-op, so nothing is broken. The cost lands later: when ODP changes the contract (adds a
> required field, renames one, changes `principalId`'s type), this line is what stops the compiler from
> telling us. The annotation above it still *looks* like protection while providing none.
>
> The cast isn't needed. All three client-access payload types are `type` aliases, so TypeScript gives them an
> implicit index signature and they assign to `Record<string, unknown>` directly. I removed the cast and ran
> `npx tsc --noEmit` across the project — exit 0.
>
> Suggested: drop the cast and use the `payload,` shorthand. Same edit in all three converters.
>
> Flagging it as architecture rather than style because these three files are the first emitters through
> `CLIENT_ACCESS_OUTBOX` and are already being copied — #403's converter set the shape and #410's two
> inherited the cast verbatim. Whatever these look like is what `file.approved.v1`, `file.created.v1` and
> `proceeding.file.deleted.v1` will look like.

**Note for us, not the PR:** this is the same mechanism midnjerry flagged on #340 (`as never` masking a
projection gaining a required field). Worth citing that precedent in the comment if we want it to land softly —
it's his own argument.

---

#### A2 · One proceeding-resolution rule for all client-access emitters — `Question` · #410

> **Category:** Architecture (cross-emitter consistency). Not a change to this PR — a decision to pin before
> the sibling emitters land.

**File:** `file-attachment.repository.ts` → `findProceedingIdsByIds`, and
`unapprove-deliverable-files.transaction.script.ts` → `emitUnapprovedEvents`

**Draft comment:**

> The call to exclude non-`Proceeding` attachments rather than report them under a proceeding they don't
> belong to is the right one, and the `warn`-and-skip is the safer failure mode. No argument there.
>
> The thing I'd like pinned before the other emitters land: this establishes a rule — *`proceedingId` comes
> from `FileAttachment.attachedToId` when `attachedToType` is `Proceeding`, and files that don't satisfy that
> emit nothing.* If `file.approved.v1` or `file.created.v1` resolves it differently, or emits for attachments
> this path skips, a file can be announced approved and never announced unapproved — Dione keeps serving it.
> That's the exact drift this PR closes, relocated to the seam between two emitters.
>
> Two small things that would make the rule stick:
> - State it once in the `findProceedingIdsByIds` doc comment as applying to *every* client-access emitter, not
>   just this one. It already half says this.
> - Assert the `warn` in the `'no proceeding attachment'` test. The log is the only trace that a file drifted,
>   so it's the part most worth pinning.
>
> Also, genuinely asking because I couldn't tell from the diff: **can a client-deliverable file be attached to
> a Job or Case in practice?** If it can't, that branch is unreachable and might be better as an error. If it
> can, those files drift silently and someone should own that.

---

#### A3 · Deterministic event id is derived from wall-clock — `Question, not for these PRs`

> **Category:** Architecture (shared outbox foundation, PRDV-16293). **Do not post on #403 or #410** — neither
> introduces it and both merely inherit it. Raise with whoever owns the foundation.

**Draft (for a foundation ticket or a Slack thread, not a PR comment):**

> `DeterministicEventIdHelper` hashes `runner|aggregateType|aggregateId|epochMillis|eventType`, and every
> client-access emitter supplies `epochMillis` from `new Date()` at emit time rather than from a row's
> `updated_at`. Two consequences worth a deliberate answer at the foundation level rather than per-emitter:
>
> - A **retried** operation produces a *different* event id, so the deterministic id doesn't dedupe retries —
>   Dione receives two events.
> - Two operations on the same aggregate within the **same millisecond** produce the *same* id, and one
>   collides.
>
> Both are convergent while payloads are full-state snapshots. It matters more now that #410 adds
> **revocations**, where a dropped event is security-relevant rather than merely stale.

---

### CODE

#### C1 · Service input should be a `Command` type — `Non-blocking` · #410

> **Category:** Code / repo convention. Cheap, and it's a rule the module already follows six times.

**File:** `granting-client-access.service.ts` → `deleteDynamicCollection`

**Draft comment:**

> ```ts
> async deleteDynamicCollection(params: {
>     readonly collectionId: number;
>     readonly user: AuthUser;
> }): Promise<DeleteDynamicCollectionProjection>
> ```
>
> `type-colocation.mdc` names service input a `Command` in its own `{action}.command.ts`, and `type-files.mdc`
> adds that each one lives in a separate file. This module already has six —
> `approve-deliverable-files.command.ts`, `recategorize-deliverable-files.command.ts`,
> `unapprove-deliverable-files.command.ts`, the two upload ones, and `deliverable-rename.command.ts`.
>
> #403 handles the identical situation correctly: it adds
> `save-contact-deliverable-type-grants.command.ts` when that signature grows from a scalar to a shape carrying
> `AuthUser`. Same refactor, two different answers across the two PRs.
>
> Suggested: `delete-dynamic-collection.command.ts` exporting `DeleteDynamicCollectionCommand`.

---

#### C2 · Converter pair is asymmetric — `Non-blocking, minor` · #410

> **Category:** Code (consistency between two things shipped together). `pr-review-patterns` Class D applied to
> documentation rather than tests.

**Files:** `file-unapproved-to-outbox-data.converter.ts` vs `collection-deleted-to-outbox-data.converter.ts`

**Draft comment:**

> These two land in the same PR and will be the two exemplars the next emitter is modelled on, but they treat
> the same concerns differently:
>
> - `FileUnapprovedToOutboxDataConverter` hoists `unapprovedAt` / `rowUpdatedAt` above the `map` so the batch
>   shares one instant, and carries a doc comment explaining that plus why `aggregateId` stays per-file.
> - `CollectionDeletedToOutboxDataConverter` has no comment and derives `rowUpdatedAt: new Date(deletedAt)`
>   inline at the return.
>
> Both are correct, and the single-row case genuinely needs less explanation than the batch case. Mostly noting
> that right now they disagree about how much of this is worth writing down.

---

#### C3 · Outbox failure logs under a misleading message — `Non-blocking, cosmetic` · #410

> **Category:** Code (observability).

**File:** `unapprove-deliverable-files.transaction.script.ts` — the `catch` around `apply`

**Draft comment:**

> `emitUnapprovedEvents` runs inside the existing try/catch, so a failed outbox write surfaces as
> `'Error unapproving deliverable files'`. The files *were* unapproved — the relay write is what failed, and
> the transaction is about to roll both back. Minor, but it's the string someone greps at 2am, and it points at
> the file-tag logic instead of the outbox.

---

#### C4 · Route key hand-typed in the spec — `Non-blocking, minor` · #403

> **Category:** Code (test-side magic literals). `pr-review-patterns` Class B.

**File:** `__specs__/save-contact-deliverable-type-grants.transaction.script.spec.ts`

**Draft comment:**

> `'callisto.client-access.grants.replaced.v1'` is written out five times here, alongside `'ClientAccessGrant'`
> and `'Contact:42:7'`. The converter spec next door does it right —
> `CALLISTO_CLIENT_ACCESS_GRANTS_REPLACED_V1.eventType` — so the two specs disagree about where the route key
> comes from. If the key ever changes in ODP these five stay green while the contract has moved.
>
> (#410's specs don't have this — worth matching them.)

---

### DOCUMENTATION IN CODE

#### D1 · Document the deliberately-unguarded outbox write — `Non-blocking` · #403

> **Category:** Documentation in code. `pr-review-patterns` Class F, read forward. **This is the single
> cheapest cross-PR win**, because #410 already wrote the comment and #403 can borrow it.

**File:** `save-contact-deliverable-type-grants.transaction.script.ts:71–79`

**Draft comment:**

> The write here is deliberately not wrapped in try/catch, because a failed outbox write has to roll the grant
> save back with it — that's the whole reason the `@Transactional()` boundary matters. But nothing in the file
> says so, and it reads as an unguarded `await` inside a transaction script.
>
> The risk isn't a reviewer's confusion, it's the next edit: someone adding a try/catch to stop outbox trouble
> from failing user-facing saves would silently turn a real guarantee into a nominal one, and **every existing
> test would still pass**.
>
> #410 already solved this — `emitUnapprovedEvents` carries exactly the right comment:
>
> > *"Emits inside the transaction so a file cannot stay unapproved in Callisto while Dione keeps serving it."*
>
> Two or three lines in the same spirit above the `if (params.isClientAccessOutboxEnabled)` block would do it.

---

### TESTS

#### T1 · No test that a failing outbox write rolls the change back — `Non-blocking` · #403 + #410

> **Category:** Tests (coverage of the load-bearing guarantee). Same gap on all three transaction scripts.
> Pairs with **D1** — one documents the decision, the other pins it.

**Draft comment:**

> All the specs mock `clientAccessOutbox.write` to resolve, so the rejection path — the one `@Transactional()`
> exists for — is never exercised. On #410 especially, this is the PR's headline argument: the body opens by
> explaining that without the transaction "the state change could commit and the outbox write could fail,
> leaving Dione permanently believing a revoked file is still available." That claim currently has no test
> behind it.
>
> Full rollback proof needs a real transaction and is fair to call out of scope for a unit suite. The
> propagation half is cheap and catches the regression that matters — someone later swallowing the error:
>
> ```ts
> clientAccessOutboxMock.write.mockRejectedValue(new Error('outbox down'));
> await expect(target.apply({ ...params, isClientAccessOutboxEnabled: true }))
>     .rejects.toThrow('outbox down');
> ```

---

### PROCESS / ROLLOUT

#### P1 · Mirror #410's rollout caveat into #403 — `Non-blocking, description only` · #403

> **Category:** Process (PR description). No code change.

**Draft comment:**

> #410's body states the per-user flag hole plainly — an unflagged operator acts, Dione's view goes stale, and
> nothing re-emits later to correct it — along with the mitigation (grant the flag to the whole operator group
> in one step rather than piloting on a subset).
>
> The same hole exists here, and whoever runs the rollout will likely read one PR, not both. Worth a short
> paragraph in this description too.

---

#### P2 · Record the gate commands in #403's description — `Non-blocking, description only` · #403

> **Category:** Process (evidence). Optional; raise only if we're already commenting.

**Draft comment:**

> #410's test plan lists exact commands and counts. #403's "Test Evidence" says "passing" without the commands,
> so a reader can't verify without redoing the work. I re-ran `npx jest --config jest-e2e.json --runInBand
> src/granting-client-access` at `860cef6e` — 75 suites / 361 tests pass, and `npx tsc --noEmit` is clean —
> so the work is done; it's just not written down.

---

## What I would actually post

If we want a light touch rather than eleven comments, this is the minimum that carries the value:

| Priority | Comment | PR | Why it makes the cut |
| --- | --- | --- | --- |
| 1 | **A1** — the cast | both | Only item with a compile-time consequence; already propagating; one-line fix. |
| 2 | **D1** — document the unguarded write | #403 | Borrows #410's own comment; protects the guarantee from the next edit. |
| 3 | **T1** — rejection test | both | Six lines; pins the PR's headline claim. |
| 4 | **A2** — proceeding-resolution rule | #410 | The only item with consequences beyond these two PRs. |
| 5 | **C1** — the `.command.ts` | #410 | Cheap, and #403 already shows the shape. |

**Hold back:** C2, C3, C4, P2 (nits — fine to fold in if we're commenting anyway, not worth a round trip on
their own), G2 (withdrawn), A3 (belongs to the foundation, not these PRs).

**Tone note:** both PRs are good, and the review reads better if that's said rather than implied — #410's
coverage and self-disclosure and #403's proactive converter extraction are genuinely above the bar, and A1 is
the only thing standing between them and a clean approve.
