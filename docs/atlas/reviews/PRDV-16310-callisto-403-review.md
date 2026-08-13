# Review — callisto-back-end #403 (PRDV-16310)

**PR:** [PRDV-16310: Emit grants.replaced.v1 on Access Manager grant save](https://github.com/planetdepos/callisto-back-end/pull/403)
**Author:** midnjerry (Jerry Balderas)
**Branch:** `PRDV-16310-endpoint-grants-replaced` → `main`
**Head reviewed:** `860cef6e9cb63db54734ef4badd279631371948a`
**Size:** 13 files, +550 / −13, 3 commits
**Review date:** 2026-08-11
**Prior review activity:** none — no reviews, no inline comments, no requested changes at time of review.

**Verdict: approve with non-blocking cleanups.** The change is correct, well-tested, and consumes the
PRDV-16293 outbox foundation rather than inventing a mechanism. Nothing here is a bug. F1 is the one
I'd want in before merge, and the reason is not severity — it's that this PR is the **first** emitter
on this port, so its converter is the template, and PR #410 has already copied the defect twice.

---

## Baseline — what actually exists on `main`

Establishing this first, because it determines what "follows the pattern" can even mean.

On `origin/main`, `CLIENT_ACCESS_OUTBOX` appears in exactly two places: the port definition and the
module that binds it. **Nothing calls `write` on it.** The PRDV-16293 foundation shipped the pipe;
no emitter has ever been merged through it.

```
git grep -n "clientAccessOutbox.write" origin/main -- 'src/**/*.ts'
→ no matches
```

So **#403 is the first emitter on this port.** It is not following a house pattern — it *is* the house
pattern from the moment it merges. #410's own description confirms this reading: *"Both follow the
existing converter-plus-outbox shape established by `grants.replaced.v1`."*

That reframes the whole review. Findings below are weighted by *what propagates*, not just by what's
wrong in isolation.

> **Correction, recorded deliberately.** An earlier draft of this review compared #403 against
> `RenameDeliverableFileAssembler` / `FileRenamedToOutboxDataConverter`, describing them as the
> "already-shipped reference implementation on this port." That was wrong. Those classes exist on no
> branch — they are uncommitted local PRDV-16313 work in the callisto working tree. The error came from
> reading that file out of the working directory instead of out of a branch ref. Three findings were
> grounded in that false comparison and have been rewritten or dropped. Comparisons in this document
> now cite `origin/main` or a named PR branch only.

---

## Pass 1 — Documentation

### What the PR claims

After Access Manager replaces a contact's deliverable-type grants for a proceeding, write a
`callisto.client-access.grants.replaced.v1` outbox row so Dione can project the full grant set.

- Maps HTTP `contactId` → `principalType: Contact` / `principalId`
- Emits on empty selections (full revoke) with `grants: []`
- Publishing to RabbitMQ stays with the existing `OutboxRelayPoller` under `OUTBOX_ENABLED`
- Gated on a new per-user Cognito flag `IS_CLIENT_ACCESS_OUTBOX_ENABLED`; with the flag off the grant
  save still persists and only the outbox write is skipped

### Constraints it has to satisfy

| Source of truth | Where | What it constrains |
| --- | --- | --- |
| Event contract | `@planetdepos/orbital-docking-protocol` | `CallistoClientAccessGrantsReplacedV1Data` — `principalType`, `principalId`, `proceedingId`, `grants[]`, `replacedAt`, `replacedUserIdentity` |
| Route registry | `client-access-outbox-event.registry.ts` | Route key already registered; the writer rejects unknown keys outright |
| Outbox port | `client-access-outbox.port.ts` | `write(params)` where `payload: Record<string, unknown>` |
| Flag precedent | `ProceedingService`, `CaseMergeService` (both on `main`) | Resolve the flag at the service layer from `AuthUser`, thread a boolean into the TS |
| Type placement | `.cursor/rules/type-colocation.mdc`, `type-files.mdc` | `.command.ts` for service input, `.param.ts` for TS input, one type per file |
| Converter placement | `.cursor/rules/architecture-patterns.mdc` | "within transaction script folders or as high up as its highest consumer" |

There is **no in-repo precedent for an emitter** on this port. The flag precedent is real and on `main`;
the emitter shape is not.

---

## Pass 2 — Implementation

### Gates run

Run against the PR head in an isolated worktree, not a merged approximation. (The PR body claims tests
pass but records no commands; these are the commands and results.)

| Gate | Command | Scope | Result |
| --- | --- | --- | --- |
| tests | `npx jest --config jest-e2e.json --runInBand src/granting-client-access` | `src/granting-client-access` | **pass** — 75 suites, 361 tests |
| typecheck | `npx tsc --noEmit` | whole project | **pass** — exit 0 |

### The flow, as implemented

```
POST /contacts/deliverable-type-grants
  → SaveContactDeliverableTypeGrantsAction        passes the whole AuthUser now, not just userId
  → ContactsService                                resolves IS_CLIENT_ACCESS_OUTBOX_ENABLED
  → SaveContactDeliverableTypeGrantsTS  @Transactional()   (pre-existing, not added here)
      validate contact / proceeding
      dedupe selections
      replaceForContactAndProceeding(...)
      findByContactAndProceeding(...)              ← re-read
      if (flag) converter.apply(...) → clientAccessOutbox.write(...)
```

### What's right

Worth naming, because several are easy to get wrong and were not gotten wrong — and because as the
first emitter, each of these becomes precedent too.

1. **The event carries persisted state, not request state.** The TS re-reads via
   `findByContactAndProceeding` after the replace and hands *that* to the converter. Dedupe and any
   repository normalization are reflected in what Dione receives. Emitting `params.selections` was the
   obvious shortcut and would have been subtly wrong.

2. **Atomicity is real, not nominal.** `@Transactional()` was already on this TS, and Callisto binds the
   outbox repository resolver globally, so the insert joins the ambient transaction. A failed write rolls
   the grant save back with it.

3. **Validation failures emit nothing.** Contact-not-found and proceeding-not-found both short-circuit
   before the write, and the specs assert *both* the converter and the writer were never called — not
   merely that it threw.

4. **Full revoke is covered explicitly.** Empty selections still emit, with `grants: []`. The case most
   likely to be missed, since "nothing selected" reads like "nothing happened" — and it's exactly when
   Dione most needs to hear.

5. **Flag-off is tested as behavior, not assumed.** Grants persist, repository called, neither converter
   nor writer runs.

6. **Flag resolution matches the real precedent on `main`.** Identical in shape to `ProceedingService`
   (`IS_PROCEEDING_OUTBOX_ENABLED`) and `CaseMergeService` (`IS_CASE_MERGE_OUTBOX_ENABLED`): resolve at the
   service layer from `AuthUser`, thread a boolean down, keep the writer a dumb sink with no user context.

7. **Test doubles use the repo's typed helpers** — `createApplyMock<T>()` / `createMock<T>()` throughout,
   zero hand-rolled casts. Pattern 3 already internalized on the test side.

8. **New coverage where there was none.** `ContactsService` had no spec before this PR.

9. **The converter extraction was proactive.** Commit `58db09b9` pulled payload construction into its own
   testable unit before any reviewer asked, with a commit message explaining why. Class E self-applied.

10. **A `Command` type was introduced at the service boundary.** `SaveContactDeliverableTypeGrantsCommand`
    stops the action from assembling TS params directly, and matches `type-colocation.mdc`'s `.command.ts`
    convention for service input.

---

## Findings

Ranked. Blocking calls explicit.

### F1 — `as unknown as Record<string, unknown>` erases the contract typing declared two lines above it

**Non-blocking as a defect; recommend pre-merge because it is the template. One line.**

`contact-deliverable-type-grants-to-replaced-outbox.converter.ts:40`

```ts
const payload: CallistoClientAccessGrantsReplacedV1Data = { ... };
return {
    routeKey: CALLISTO_CLIENT_ACCESS_GRANTS_REPLACED_V1.eventType,
    payload: payload as unknown as Record<string, unknown>,   // ← this
    ...
};
```

Line 27 pins the payload to the docking-protocol contract. Line 40 erases it with `as unknown as` — the
strongest cast TypeScript has, the one that switches off assignability checking entirely.

Today it's a no-op. The cost is later: when ODP changes the contract — adds a required field, renames one,
turns `principalId` into a string — this line is what stops the compiler from saying so. The annotation
above it still *looks* like protection while providing none.

**The cast isn't needed.** Verified rather than reasoned about, two ways:

- In isolation under `--strict`, all three client-access payload types (`GrantsReplaced`,
  `CollectionDeleted`, `FileUnapproved`) assign to `Record<string, unknown>` with no cast — they are `type`
  aliases, so TypeScript grants them an implicit index signature. `tsc` exit 0.
- In the real project, on this branch: removed the cast, ran `npx tsc --noEmit` across the whole repo.
  **Exit 0.**

**Why it matters more than a one-line nit.** This is the first emitter on the port, so this converter is
what the next one gets modelled on — and that already happened. PR #410 carries the identical cast in
**both** of its converters:

```
git grep -n "as unknown as Record" PRDV-16315-emit-file-unapproved-and-collection-deleted
→ delete-dynamic-collection-ts/collection-deleted-to-outbox-data.converter.ts:30
→ unapprove-deliverable-files-ts/file-unapproved-to-outbox-data.converter.ts:41
```

Three instances, two PRs, one shape. Fixing it here fixes the template; leaving it sets the convention
for every emitter that follows.

**Class C** (`pr-review-patterns` Pattern 3) — the same mechanism midnjerry himself flagged on
[#340](https://github.com/planetdepos/callisto-back-end/pull/340): *"`as never` will mask a real type error
if `ProceedingFileRenameProjection` grows a required field."* Identical failure mode, production side
rather than spec side.

**Fix:** delete the cast. `payload,` shorthand works. Same edit in #410's two converters.

---

### F2 — The atomicity decision is the design's whole argument and it's undocumented

**Non-blocking.**

`save-contact-deliverable-type-grants.transaction.script.ts:71–79`

The write is deliberately *not* wrapped in try/catch, because a failed outbox write has to roll the grant
save back with it. That is the entire reason the `@Transactional()` boundary matters here — and it's
invisible. It reads as an unguarded `await` in the middle of a transaction script.

The concrete risk isn't a reviewer's confusion, it's the next edit: someone adding a try/catch to "make it
safer" would silently convert a real guarantee into a nominal one, and **every existing test would still
pass** (see F3). Since this is the first emitter, whatever this file does or doesn't say is what the next
three emitters inherit — #410 already inherited the shape without the rationale.

**Fix:** two or three lines above the `if (params.isClientAccessOutboxEnabled)` block, stating that the
write is intentionally unguarded so the error reaches the transaction boundary.

---

### F3 — Nothing tests the atomicity the design depends on

**Non-blocking, coverage gap.**

Every test mocks `clientAccessOutbox.write` to resolve. The failure direction — the one `@Transactional()`
exists for — is untested. There's no case where `write` rejects and the TS is asserted to propagate rather
than swallow.

Full rollback proof needs a real transaction and is fairly read as out of scope for a unit suite. The
*propagation* half is cheap and it's what pins F2's undocumented decision as a behavior instead of a
convention:

```ts
clientAccessOutboxMock.write.mockRejectedValue(new Error('outbox down'));
await expect(target.apply({ ...params, isClientAccessOutboxEnabled: true }))
    .rejects.toThrow('outbox down');
```

Six lines. F2 and F3 are the same gap approached from documentation and from test — either alone helps,
both together close it.

---

### F4 — Route key and aggregate literals hand-typed in the transaction-script spec

**Non-blocking, test-only.**

`__specs__/save-contact-deliverable-type-grants.transaction.script.spec.ts`

`'callisto.client-access.grants.replaced.v1'` is written out five times, alongside `'ClientAccessGrant'`
and `'Contact:42:7'`. The *converter* spec in the same PR does this correctly —
`CALLISTO_CLIENT_ACCESS_GRANTS_REPLACED_V1.eventType` — so the two specs disagree on where the route key
comes from.

Low severity, but the cost is real: if the route key changes in ODP, these five literals stay green while
the contract has moved underneath them.

**Fix:** import the ODP constant in the TS spec too, matching the converter spec beside it.

**Class B.**

---

### F5 — The converter is impure, so its spec needs fake timers

**Non-blocking. Preference, not precedent — flagged as such.**

`contact-deliverable-type-grants-to-replaced-outbox.converter.ts:28, 42`

```ts
const replacedAt = new Date().toISOString();
...
rowUpdatedAt: new Date(replacedAt),
```

Calling `new Date()` inside the converter makes it a function of wall-clock rather than of its input, so
the spec has to reach for `jest.useFakeTimers()` / `setSystemTime` to assert anything about the output.
Taking `replacedAt: Date` as an input field instead would make the converter a pure transform and drop the
timer control from its spec.

The string round-trip (`toISOString()` then `new Date(...)`) keeping the payload field and `rowUpdatedAt` in
sync is **correct** — ISO 8601 preserves milliseconds and the event id only hashes `getTime()` — but it's an
implicit mechanism where a single `Date` used twice would be self-evident.

I'm marking this a preference rather than a finding: there is no merged emitter on this port to be
inconsistent *with*, and the current code is not wrong. Worth deciding now only because it's the template.

---

### F6 — Event id is derived from wall-clock, not row state

**Not charged to this PR. A question for the PRDV-16293 foundation.**

`DeterministicEventIdHelper` computes `uuidv5(runner|aggregateType|aggregateId|epochMillis|eventType)`. Here
`aggregateId` is `Contact:{contactId}:{proceedingId}` and the millis come from `new Date()` at emit time:

- A **retried** save produces a different id — the "deterministic" id doesn't dedupe retries, and Dione
  receives two events.
- Two saves for the same contact + proceeding within the **same millisecond** produce the same id, and one
  collides.

Both are mitigated by the payload being a full-state snapshot rather than a delta: replaying or dropping one
still converges on the correct grant set. This is a property of the shared helper, not of this PR.

Raised so it's settled deliberately at the foundation rather than rediscovered per-emitter — especially since
#410's events are revocations, where a dropped event is security-relevant rather than merely stale.

---

### F7 — The unflagged-actor gap isn't stated in this PR's description

**Non-blocking, description only, no code change.**

Companion PR [#410](https://github.com/planetdepos/callisto-back-end/pull/410) states it plainly in its own
body: because the flag is per user, an unflagged operator's action leaves Dione's view stale, and *nothing
re-emits later to correct it*. Its mitigation — grant the flag to the whole Atlas operator group in one step
rather than piloting on a subset — is just as applicable here.

#403 doesn't mention it, and whoever runs the rollout will likely read one PR, not both.

---

## Two notes for the author, not findings

- **The merge collision with #410 is already flagged** in #403's body — both touch the same two lines in
  `FEATURE_FLAG_NAMES` and `GrantingClientAccessModule.imports`. Whichever lands second rebases. Good to have
  called out proactively.
- **Test evidence here is the weaker of the two PRs.** #410 lists exact commands and counts. #403 says
  "passing" without commands. The work was done — I re-ran it and it passes — but the body doesn't let a
  reader verify that without repeating the exercise.

---

## Pass 3 — `pr-review-patterns` checklist

Every class walked. Clean results recorded, not omitted.

| Class | Verdict | Detail |
| --- | --- | --- |
| **A** — i18n externalization | **n/a** | Backend service; no user-facing strings. The only literals are route keys and aggregate type names — protocol identifiers, not copy. |
| **B** — named constants over magic literals | **hit, minor** | Production code is clean: `CLIENT_ACCESS_GRANT_AGGREGATE_TYPE` is extracted and the route key comes from the ODP constant. The TS spec hand-types the route key 5× — **F4**. |
| **C** — typed helpers over hand-rolled casts | **hit** | Test doubles are exemplary — zero hand-rolled casts. The type-erasing cast is in **production** code instead — **F1**. Same class, opposite side of the codebase from where Pattern 3 was first logged. |
| **D** — mirror-implementation coverage symmetry | **clean** | No mirror pair introduced. The emitter arrives with a converter spec, a TS spec, and a new service spec. |
| **E** — extract dense logic into named helpers | **clean, and better** | Commit `58db09b9` extracted payload construction into its own converter unprompted, with a commit message explaining why — the pattern self-applied before review. |
| **F** — justify intentional removal of defensive code | **hit** | Read forward rather than backward: the deliberately-unguarded write is the load-bearing decision and nothing states it — **F2**, with **F3** as its test-side twin. |
| **G** — editorial cleanup before review | **clean** | No leftover scratch comments, no commented-out code, no stale TODOs in the diff. |
| **H** — escalate cross-cutting architecture decisions | **clean** | The opposite of the anti-pattern: this PR *consumes* the PRDV-16293 foundation instead of inventing a mechanism, and reuses the existing per-user flag shape rather than introducing a new gating concept. **F6** is the one cross-cutting question and it belongs to the foundation, not this branch. |

### Pattern promotion — this one qualifies now

`pr-review-patterns.md` promotes on 2+ independent instances. **Pattern 3 should widen its scope**, and the
evidence is in hand:

| Instance | PR | Location | Cast |
| --- | --- | --- | --- |
| 1 | #403 | `contact-deliverable-type-grants-to-replaced-outbox.converter.ts:40` | `as unknown as Record<string, unknown>` |
| 2 | #410 | `collection-deleted-to-outbox-data.converter.ts:30` | same |
| 3 | #410 | `file-unapproved-to-outbox-data.converter.ts:41` | same |

Pattern 3 is currently written as a **test-mock** concern ("hand-rolled test-mock casts should use the repo's
typed factory helpers"). These three are the same mechanism — a cast that disables drift detection — in
**production code at a contract boundary**. Recommend rewording Pattern 3's scope from "test mocks" to *"any
cast that erases a contract or projection type, in test or production code,"* and adding these three rows,
once #403 merges.

---

## Recommendation

**Approve.** Correct, well-covered, and it consumes the foundation instead of reinventing it. The unusual
thing about this PR is not its risk but its reach: it is the first emitter through the client-access outbox,
so its converter shape becomes the house shape, and #410 has already inherited it.

- **F1** — fix before merge. One-line deletion, verified `tsc --noEmit` exit 0, and it stops the cast
  propagating to #410's two converters.
- **F2 / F3** — cheap follow-ups, ideally the same commit; together they close the atomicity gap from both
  the documentation and the test side.
- **F4** — test-side tidy.
- **F5** — decide now because it's the template; not wrong as written.
- **F6** — belongs to PRDV-16293, not here.
- **F7** — description edit.
