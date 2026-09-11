# PRDV-16461 — Phase 1 Recon and Plan

**Ticket:** [Default collections for client deliverables](https://app.clickup.com/t/43227262/PRDV-16461)
**Phase:** 1 (Recon and plan) — `orchestrate` skill · approval of this plan is the 1→2 handoff
**Repos:** `atlas-front-end` (change site, on `main`), `callisto-back-end` (evidence only — no changes)

---

## Context

Ops Atlas users adding files to the Client Deliverables set must pick a collection manually every time, though nearly all files fall into one of two base cases: a Transcript-track file belongs in "Full Transcript," a Video-track file in "MP4 Video." The ticket asks for those to be pre-selected so the common path needs no interaction, while leaving the user free to override.

Product settled the behavioral edges across three QA rounds in the ClickUp thread (Anastasiya Savchuk → Shaye Lankford, Aug 5–18): recategorize excluded, deliverable-type pre-fill composes with the collection default, default never sticky. A separate UX thread (Aug 27–present) asks that a pre-selected collection be distinguishable from a user's own choice — agreed in principle, mechanism unnamed. **Per this session's direction that decision is deferred to just before implementation and does not gate the spec** (tracked as job story 02).

Scope is front-end only (the ticket's "Option A"): no backend or DTM configuration, and no new endpoint (F7). Within the front end the change is in two parts: a track → default-collection mapping, and an explicit track-selection state for generic drag-and-drop so that mapping has something to react to (F6a). The second part is an interaction change, not just a constant — it is what takes the work past a pure mapping, and it is bounded by the out-of-scope list in F6a.

---

## Consult log (prior coverage ledgers)

Searched `docs/atlas/*/investigations/*-coverage-ledger.md` and `docs/*/tickets/*/investigations/*-coverage-ledger.md` for "collection", "deliverable", "DeliverableFileUpload", "DTM", "track", "upload form". **Twelve ledgers found; four read; one substantively reusable.**

- **`PRDV-16403`** — *found, reused as convention ground.* The only prior ledger with real `atlas-front-end` GCA coverage: Vue Query `staleTime`/`gcTime` conventions, `useFeatureFlags`/`useGrantingClientAccessFlag`, `src/callisto/api/constants.ts`, `queryKey.ts`, Atlas `__specs__` conventions. Its own subject (Access Manager RB panel) is a different surface — no behavioral overlap.
- **`PRDV-16312`, `PRDV-16313`, `PRDV-16402`** — *found, not reopened.* All are `callisto-back-end` outbox/event-emission investigations. They match on the words "collection"/"deliverable" but in an event-contract context, not the DTM selection UI. This ticket declares no backend scope, so none are load-bearing.
- **`docs/atlas/reviews/`** — searched separately (the ledger glob misses it, as `PRDV-16403` flagged). `PRDV-16315-callisto-410-review.md:118` surfaced the static/dynamic + sentinel vocabulary that opened finding **F2**. **Recommend adding this folder to the consult glob permanently.**
- **No frontier item in any ledger is this ticket.** Virgin ground for the DTM collection-selection surface.

---

## Problem Check (method Step 1 lens)

## In brief

The ticket asks for two collections to be pre-selected based on a file's track so the common upload path needs no manual choice. Product answered three clarifying questions in August that pinned the edges — recategorize excluded, type pre-fill composes, default never sticky. A later thread raised whether users should be able to tell a pre-selected collection from one they chose; agreed in principle, no mechanism yet.

# The question
---
### Asked
|  |  |
|---|---|
| **finding** | Pre-select the base-case collection for Transcript and Video files so users stop setting it manually |
| **evidence** | "so that I don't have to manually set collections for the most common, base-case workflows" |

### Answered
|  |  |
|---|---|
| **finding** | Same question, plus a second one about signaling that a value was pre-chosen |
| **drift** | "make the right collection appear automatically" → "make it appear automatically *and* make clear it was automatic" |
| **evidence** | "someway notating that the collection was chosen for them" |

### Should-ask
|  |  |
|---|---|
| **finding** | In generic drag-and-drop, what event is a "track selection" that a collection default could react to? |
| **why** | The AC assumes a track-selection moment exists in that flow. It does not (F6a): the combined list has disabled group headers and only collection rows are selectable. Answering this early is what separates a one-function mapping change from an interaction change, and it determines whether the AC is implementable as written |

# Flags
---
### Conflation
|  |  |
|---|---|
| **finding** | Two problems: (a) the collection is not pre-selected, (b) a pre-selected value is indistinguishable from a chosen one |
| **consequence** | Solving (a) does not touch (b) — and (a) is what *creates* (b); (a) is fully specified, (b) has no confirmed mechanism |
| **evidence** | "I agree, do you have a suggestion for how you'd prefer to handle this" |

### Thin
|  |  |
|---|---|
| **finding** | "Static" vs "dynamic" collection is load-bearing in the AC but never defined in the ticket |
| **evidence** | "never a dynamic collection (Excerpt / Trial Edit)" |

### Off
|  |  |
|---|---|
| **finding** | AC says match the collection "by its known value" while also flagging those values are unverified |
| **consequence** | Resolved by F1 — the values are real; the fallback path is a genuine edge case, not the default outcome |
| **evidence** | "they currently appear only in test fixtures on the FE side" |

---

## Recon findings

### F1 — Both of the ticket's "open items to confirm" are RESOLVED by evidence

Both were code-discoverable facts, so per method Step 7 neither may be carried to the user as a question.

**`Full Transcript` and `MP4 Video` are real seeded production values.**
`callisto-back-end/src/typeorm/migrations/1775761245238-seed__deliverable_collections__table.ts:22,32` inserts both with `collection_kind = 'static'`, `proceeding_id = NULL`, joined to `tt.value = 'Transcript'` / `'Video'`.

**Both have eligible deliverable types configured.**
`1782200000003-seed__deliverable_type_deliverable_collections__table.ts:23-268` — `FULL_TRANSCRIPT` is a member of ~19 type rows, `MP4_VIDEO` of ~11. Five types (`Errata Sheet - Signed/Blank`, `Certificate/Filing Notice`, `Index Pages`, `PDF with Exhibits`) are eligible for **Full Transcript only**, showing the config was authored per-collection deliberately.

The ticket's worry was **right about Atlas and wrong about the system**: Atlas correctly hardcodes nothing and renders `collection.value` from the API. Corroborated by `1781001967151`'s `down()` whitelist naming all four production statics.

> **F1a — hazard.** `atlas-front-end/src/globalUtils/fileTypeLabel.ts:67,149` maps `'video/mp4' → 'MP4 Video'` as a **MIME-type display label**, unrelated to the collection of the same name. An implementer grepping the string could wire to the wrong thing. The mapping must be a new, separately-named constant.

> **F1b — residual.** `1775761245238:11-16` short-circuits if any `proceeding_id IS NULL` row already existed, so the code alone can't prove the rows exist in a given environment. Mitigating evidence: the junction seed **throws** if either collection is missing (`1782200000003:306-311`), so any successfully-migrated environment necessarily has them. Closable with one `SELECT` against the target env — carried as a validation step, not a blocker.

### F2 — "Static vs dynamic" is a real, enforced schema concept (closes the *Thin* flag)

- `deliverable_collections.collection_kind`; `COLLECTION_KIND = { STATIC, DYNAMIC }` — `deliverable-collection.entity.ts:25-31,52-53`
- A `'*DYNAMIC*'` sentinel row per track is a **template** carrying type-eligibility for future Excerpt/Trial Edit instances — `deliverable-collection.constants.ts:8`; seeded by `1782200000002`
- Only Transcript and Video support dynamic collections — `deliverable-collection.constants.ts:3-6`

**Dynamic collections are structurally un-defaultable, on three independent levels:** the repository's `fetchStaticCollections()` filters to `'static'` so the sentinel never enters `staticCollections`; real Excerpt/Trial Edit instances have `proceeding_id != NULL` and load from a separate endpoint; and the FE's dynamic pick is a synthesized option with `isDynamic: true, deliverableCollectionId: null`. The AC's "never a dynamic collection" is therefore **already guaranteed** — the new code needs `!option.isDynamic` for correctness of intent, not as the sole defense.

> **F2a — the ticket's framing is incomplete.** `Redacted` (Transcript) and `MPEG Video` (Video) are **also `static`** — `1780604349327:16,32`. So "static" alone does not identify the default, and a "just pick the static one" shortcut is wrong. This is what makes Option A's named mapping necessary.

### F3 — The change site already contains a partial default (most important finding)

`useDeliverableFileUploadForm.ts:407-414`, inside `resolveInitialPickValue()`:

```ts
const matches = trackCollectionOptions.value.filter(
  (o) => o.rowKind === 'pick' && o.trackTypeId === trackId && !o.isDynamic,
);
if (matches.length !== 1) return null;   // ← why nothing pre-selects today
return matches[0].value;
```

A track with **exactly one** non-dynamic collection already auto-selects. Transcript and Video each have two statics (F2a), so this bails.

**This reframes the work:** not "add defaulting," but **"extend an existing defaulting rule to name a winner when there is more than one candidate."** The `length === 1` rule stays as the fallback for other tracks. The spec should say so — otherwise a reviewer reads the change as new behavior rather than a widened existing one.

### F4 — Recategorize needs an explicit guard (a structural inference, corrected)

`DeliverableFileUploadForm.vue:168-171` passes the existing collection only in recategorize and `null` in every other mode, which *suggested* the guardrail was free. **The code trace disproves that.** Recategorize reaches `resolveInitialPickValue()` with a null `initialDeliverableCollectionId` whenever the selected files have no collection or disagree (`recategorizeSharedCollectionId` returns `null`, `:136-144`), falling through to the same branch F3 would modify.

An existing test pins exactly this: *"then: selectedPickValue is null (ambiguous — same as approve/upload)"* with `mode: () => 'recategorize'` and `initialDeliverableCollectionId: () => null` (spec `:1481-1490`).

**So the default must be guarded by `!isRecategorizeMode.value`** — already available in the composable at `:354`. Recorded because the wrong inference was cheap to make and would have silently broken the AC's one explicit guardrail.

> **F4a — the guard is wider than the new mapping (second review).** The pre-existing `matches.length === 1` fallback (`:407-414`) also violates recategorize's "change nothing on its own" rule: a recategorize on a track with **exactly one** static collection and a null initial collection auto-selects that collection today. The existing test at `spec:1481` misses this because it only exercises a *multi*-collection track.
>
> Two consequences for the spec:
> - The recategorize guard must cover **both** the new mapped default and the existing singleton fallback, not just the code this ticket adds. Note this makes it a **pre-existing defect** that the ticket surfaces rather than causes — worth stating plainly in the PR so it does not read as a regression introduced here.
> - The guard must **not** be a blanket "return null in recategorize." Collectionless tracks (Exhibits, MVC) rely on the same path to select their track-only sentinel `t-<id>-none` (`:147-160`), and blocking it would leave those recategorize flows unable to select anything. The guard belongs on the *collection-bearing* branches, leaving the sentinel branch intact.

### F5 — Surface enumeration, and how completeness was established

| AC path | Mode | Entry evidence |
| --- | --- | --- |
| Drag-and-drop | `'upload'`, `lockedTrackTypeId = null` | `ProceedingDetailPage.vue:305-312`, mounted `:762-775` |
| Direct / per-track upload | `'upload'`, `lockedTrackTypeId` set | `ProceedingDetailPage.vue:314-320` ← `ClientDeliverablesTable.vue:350` |
| File approval | `'approve'`, track locked from `filesToApprove[0]` | `useApproveFlow.ts:49-65`; mounted `SubmissionFilesTable.vue:869-881` |
| **Recategorize (excluded)** | `'recategorize'` | `useRecategorizeFlow.ts:57-65`; `buildRecategorizeRows.ts:4-14`; mounted `ClientDeliverablesTable.vue:1224-1237` |

**Completeness claim:** all four converge on the single `useDeliverableFileUploadForm` composable, whose only initial-selection writer is `resolveInitialPickValue()`, called from exactly two watchers (`:419-440`).

> **F5a — the upload mode splits in two (consequence of F6a).** Generic DnD and direct/per-track upload are both `'upload'` at composable level, distinguished only by `lockedTrackTypeId` being `null` or set. I originally wrote this was "fine for this ticket: both want the same default." **That no longer holds.** They now want different *interactions*: direct upload has its track already and defaults on open, while generic DnD needs a track-selection state first. The spec must state how the two are told apart. **Closed by F6c (third review): `mode === 'upload' && lockedTrackTypeId == null` identifies generic DnD, and no fourth `DeliverableFileUploadFormMode` value is added.** The spec states this explicitly rather than leaving it to be inferred.

### F6 — Non-sticky is satisfied; generic drag-and-drop is NOT (corrected by team review)

**Satisfied by existing structure:**
- `:419-429` — watcher on `isOpen` resolves on open and **nulls on close** ⇒ the "not sticky, re-applies every open" AC needs no new code.
- `:431-440` — watcher on `trackCollectionOptions` backfills when the async query resolves, guarded by `selectedPickValue !== null` so it **never overwrites a user's choice**.

> **F6a — RETRACTED. My original claim was wrong.** I wrote that in drag-and-drop "choosing a track *is* choosing a collection," so no default work was needed. The code refutes this:
>
> - Generic DnD renders `DeliverableFileUploadForm` with `:locked-track-type-id="dndInitialTrackTypeId"`, and `handleFilesValidated` leaves that **`null`** — `ProceedingDetailPage.vue:305-312, 762-775`. (The `useDeliverableDndFlow` gate is `activeTab === 'client-deliverables' && isGcaEnabled` at `:216-219`, so this is exactly the ticket's in-scope flow.)
> - With no track, `resolveInitialPickValue()` returns `null` at its **first line** (`:387-388`) and never reaches the branch this ticket modifies.
> - Track group headers are **`disable: true`** (`buildPickOptions`, `:162-173`). They are not selectable, so there is no track-only selection event to react to. The only selectable rows are individual collection picks (`:174-187`).
>
> **Consequence:** a generic-DnD user still manually picks "Full Transcript" or "MP4 Video," which is the exact manual step the ticket exists to remove. The AC requiring the default to "auto-populate reactively once the user selects a track" (`PRDV-16461-original-ticket.md:260`) is **not met** by a change confined to `resolveInitialPickValue()`.

**Resolution (user direction, 2026-09-03) — no AC revision, no grill-me deferral.**

The AC already defines the intended behavior: the user chooses the track inside the generic DnD modal, and the corresponding collection defaults reactively (Transcript → Full Transcript, Video → MP4 Video). The AC is not revised to preserve the current implementation. **The spec must account for a minimal front-end change giving generic DnD an explicit track-selection state before the collection default resolves.** A dedicated track selection is preferred over making structural group headers selectable.

**Explicitly out of scope** (the change stays tightly bounded — none of these move): how the app determines whether the user chose the correct track; one-track-per-upload-batch behavior; file-type inference or validation; support for mixed-track batches; drop locations or track-specific drop zones; existing track behavior after upload; non-GCA upload behavior.

**Target workflows to specify:**

*Generic drag-and-drop* — modal opens with no track or collection selected → user chooses the batch's track → the app immediately looks up that track's static default → the collection selector shows it and stays editable → the defaulted collection drives the existing eligible-type query and per-file type pre-fill → user may override before submitting. All files still take the one track selected for the batch; no mixed-track or inference behavior is introduced. If the track has no configured mapping, or the mapped collection is absent from the available collections, the collection stays blank with no error.

*Direct / per-track upload* — track stays locked as today; on open, Transcript preselects Full Transcript and Video preselects MP4 Video; type pre-fill runs immediately; override allowed before submit.

*File approval* — track continues to come from the selected submission files; mixed-track selections stay blocked by existing behavior; modal opens with the inherited track locked; the appropriate collection preselects; type pre-fill runs immediately; override allowed before approving.

*Recategorize* — unchanged. Preserve existing track and collection, apply neither default, do not fill a blank or ambiguous collection with the mapped default. Only deliberate user action changes the collection.

**Additional required semantics:** defaults apply only to the GCA-enabled flow; match exact static collection values and never select Excerpt, Trial Edit, or any dynamic collection; Exhibits and MVC unaffected; defaults are not sticky, so every new upload or approval starts from the mapped base-case value; a manual override must not be overwritten during the current modal session; if collection data loads asynchronously the default may backfill once available, provided the user has not already selected; changing the collection continues to reload eligible types and re-evaluate pre-fill; an unmatched deliverable type stays blank, which is expected. The separate visual "this was defaulted" indicator remains its own unresolved Product/UX decision (job story 02) and is not conflated with this interaction change.

**F6a's conclusion is therefore replaced with:** *generic DnD requires explicit track-selection state so the existing AC can be implemented; all batch, validation, and track-assignment semantics otherwise remain unchanged.*

> **F6b — the reactive wiring must be specified, not assumed (second review).** Adding selected-track state does not by itself produce a default. `resolveInitialPickValue()` reads the track, but its two callers watch **`isOpen`** and **`trackCollectionOptions`** only (`:419-440`) — neither reacts to a track change. Without new wiring the user selects a track and nothing happens.
>
> The spec must require, explicitly:
> 1. A watcher on the **effective selected track** (the new DnD state, plus `lockedTrackTypeId` where it applies).
> 2. On track change: clear the prior collection, dynamic-collection, and per-file type selections, then apply the new track's mapped default immediately. Partial precedent exists — the watcher at `:571-583` already clears `selectedDynamicCollectionId`, `pendingDynamicCollectionName` and `dynamicCollectionSelectModel` whenever `selectedPickValue` changes, so the dynamic half is largely handled once the pick moves. The **per-file type** map (`perFileTypeByKey`) refreshes off `selectedOption` at `:735-746`. The spec should state which of these is reused versus newly written rather than leaving an implementer to discover the overlap.
> 3. Preserve a manual override **only while the track is unchanged** — a deliberate track change is a reset, not an override to protect. This is a real ordering constraint against the existing "never overwrite a user's choice" guard at `:434-435`, which would otherwise block the new default.
> 4. **A component-level test of the interaction**, not composable tests alone. `DeliverableFileUploadForm.vue` currently has **no spec at all** (F5 frontier), so the new UI state would otherwise ship untested at the component boundary.
>
> **F6b.1 — narrow the watcher to mutable DnD track changes (third review).** My wording above said "effective selected track, plus `lockedTrackTypeId` where it applies." That is too broad and should be narrowed in the spec. Direct upload and approval have **locked** tracks that already initialize correctly through the existing `isOpen` and `trackCollectionOptions` watchers; routing them through a new reset transition adds initialization-ordering risk for no behavioral gain. Recategorize must **never** run the transition. So the reset/default sequence fires on one trigger only:
>
> ```text
> User changes the generic-DnD track
>   → clear the previous collection
>   → clear dynamic-collection state
>   → clear per-file deliverable-type state
>   → resolve the mapped default for the new track
>   → let the existing type-query / pre-fill behavior run
> ```

### F6c — the generic-DnD interaction contract (third review)

The form stores track and collection together in one `selectedPickValue`, and track group headers are `disable: true`. "Select a track, then default the collection" is therefore a concrete interaction change, and the spec must state its contract rather than leave the component structure implicit:

- Generic DnD opens with **no track and no collection** selected.
- Generic DnD offers an explicit, **mutable** track selection.
- **Only tracks the user has CREATE permission on are selectable** — this is how A8 is resolved (see the assumptions ledger): keeping unpermitted tracks out of the selector means the default never lands on a pick the user cannot submit, so no permission guard is needed inside `resolveInitialPickValue()`.
- After track selection, collection choices are **scoped to that track**.
- Transcript defaults to Full Transcript; Video defaults to MP4 Video; the defaulted collection stays editable.
- **Exhibits and MVC keep their internal no-collection selection** (`t-<id>-none`) and do **not** gain a collection field.
- Direct upload and approval keep their locked-track behavior unchanged.
- Recategorize does not use the mutable track-selection/default transition.

**Preferred implementation:** a dedicated Track control followed by a track-scoped Collection control. If the team prefers a different interaction, the final spec names it explicitly.

**Discriminator:** `mode === 'upload' && lockedTrackTypeId == null` is sufficient to identify generic DnD. **This closes F5a** — no fourth `DeliverableFileUploadFormMode` value is needed, and the spec should say so rather than leaving it an open design choice.

### F6d — resolver precedence must be ordered explicitly (third review)

The mapped default and the existing singleton fallback can conflict, and the current code's ordering does not express the AC. `resolveInitialPickValue()`'s fallback filter (`:407-412`) selects any lone non-dynamic pick for the track — and because that filter also admits the `t-<id>-none` sentinel emitted for collectionless tracks (`:147-160`), ordering is load-bearing rather than cosmetic. The spec must fix this order:

1. **Recategorize:** preserve a valid existing collection.
2. **Collectionless tracks** (Exhibits, MVC): preserve the internal `t-<id>-none` selection.
3. **Outside recategorize, track has a configured default:** select the exact matching static collection. **If that named collection is absent, return `null`** — and specifically do **not** fall through to selecting a different collection merely because it is the only remaining static pick.
4. **Unmapped collection-bearing track:** retain the existing singleton fallback when exactly one eligible static pick exists.
5. **Never** auto-select a dynamic or disabled option.

Step 3's "return `null` rather than fall through" is the rule that actually delivers the AC's mapped-but-missing-stays-blank requirement. Without the explicit ordering, a mapped track that had lost one of its two statics would silently auto-select the survivor — the opposite of what the AC asks for.

### F7 — Contract alignment (backend authority the FE must mirror)

`ResolveEffectiveDeliverableCollectionAssembler:33-46` validates a submitted collection belongs to the track and 404s on unknown ids, so an off-track default would be server-rejected. The mapping must resolve within the track's own `staticCollections` — which is how the option list is already built, so this is satisfied by construction.

`DeliverableTrackTypeItem.staticCollections[].value` is on the wire (`types/deliverable-collections.ts:3-14`) ⇒ **no new endpoint, no backend change**, exactly as Option A specifies.

> **F7a — the API omits `collection_kind`.** `fetch-deliverable-collections.response.dto.ts` exposes only `{ id, value, eligibleTypes }` per static collection. The FE therefore **must match by `value` string** — there is no kind flag to key on. This is the concrete reason Option A is string-matching rather than flag-driven, and it belongs in the spec as a constraint, not an implementation whim.

### F8 — Type pre-fill fires earlier; the catalog is not newly narrowed (downgraded after review)

`isDeliverableTypesQueryEnabled = isOpen && isGcaEnabled && selectedOption != null` (`:643-646`); the query is keyed on `collectionId` (`:655`).

**The accurate statement:** today the query does not run until a collection is selected, and once it does it is **already scoped to that collection**. Defaulting changes *when* it runs (immediately on open rather than after a click), not *how narrow* the catalog is for a given collection. A user who manually picks "Full Transcript" today gets exactly the catalog a defaulted "Full Transcript" produces.

> **F8a — my original framing was wrong.** I wrote that a filename rule could "yield `null` where a broader catalog would have matched." There is no broader catalog: no collection means no query at all, not an unfiltered query. Corrected per team review.

**What remains true and worth testing:** `refreshPerFileSelections()` (`:689-733`) runs `resolveDeliverableTypeForFile(fileName, trackValue, catalog)` with rules keyed on track only (`deliverable-type-auto-select-rules.ts`), so for any given collection a filename can still resolve to no eligible type and leave the field blank. The AC explicitly expects a blank, not an error.

**Status: ordinary test coverage, not a gating risk.** Cover matched and unmatched type pre-fill against a defaulted collection. Removed from the verdict's conditions.

---

## Assumptions ledger

| # | Claim | Status | How confirmed / what would refute |
| --- | --- | --- | --- |
| A1 | `Full Transcript` / `MP4 Video` exist in production as static, global collections | confirmed | Seed `1775761245238:22,32`; refuted by a prod `SELECT` returning neither |
| A2 | Both have eligible types configured | confirmed | Junction seed `1782200000003`; the seed throws if absent |
| A3 | Those rows exist in *every* target environment | confirmed directionally (F1b) | **Downgraded per review: not a spec gate.** The AC already requires graceful fallback when the mapped collection is absent, and that fallback is covered by a test. Migration evidence plus the fallback test are sufficient for implementation; a QA smoke check confirms deployed data. A `SELECT` remains available if an environment behaves unexpectedly |
| A4 | Nothing pre-selects today only because both tracks have 2 statics | confirmed | `:407-414` + F2a; refuted if a track had exactly one |
| A5 | Dynamic collections cannot be defaulted | confirmed | Three independent mechanisms (F2) |
| A6 | Recategorize can reach the modified branch | confirmed | `:136-144` + pinning test `:1481-1490` |
| A7 | Defaulting cascades into type pre-fill with no extra wiring | confirmed | `selectedOption` is a dep of the pre-fill watcher `:735-746` |
| A8 | A disabled (no-permission) pick must not be defaulted | **closed — no guard needed** | Originally refuted (per-track upload is permission-gated before the form opens, `ClientDeliverablesTable.vue:586-587`; approval locks the track to files the user just acted on, `useApproveFlow.ts:54`), then reopened when the new DnD track-selection step created a path to selecting an unpermitted track. **Closed by F6c (third review):** the DnD track selector exposes **only tracks the user has CREATE permission on**, so a default can never land on a pick the user cannot submit, and `resolveInitialPickValue()` needs no permission condition. Refuted if the selector is later specified to list unpermitted tracks |

---

## Review response — status of this plan

Three review passes, all recorded in the Phase 2 report's Alternatives/Addendum section.

### Third review (advance with three clarifications — all accepted)

Verdict: implementation scope is appropriate, no feature scope removed, advance with the clarifications folded into the spec. Accepted in full.

| Finding | Disposition |
| --- | --- |
| Define the generic-DnD interaction contract | **Accepted → F6c.** The contract is now stated rather than implicit: opens with nothing selected, explicit mutable track selection, permitted tracks only, track-scoped collections, the two defaults, editable result, Exhibits/MVC keep `t-<id>-none` with no collection field, locked flows unchanged, recategorize excluded. Preferred shape (a Track control then a track-scoped Collection control) named, with the option for the team to name a different one. **Also closes F5a and A8** — `mode === 'upload' && lockedTrackTypeId == null` is the discriminator (no fourth mode value), and permitted-tracks-only removes the need for any permission guard in the resolver |
| Scope the reactive transition to mutable DnD track changes | **Accepted → F6b.1.** My "effective selected track, plus `lockedTrackTypeId`" was too broad. Locked flows already initialize correctly through the existing watchers, and routing them through a new reset adds ordering risk for no gain. The transition now fires on the mutable DnD track change only, with recategorize explicitly never running it |
| Define resolver precedence explicitly | **Accepted → F6d, and it caught a real bug in my plan.** Verified at `:407-412`: the singleton filter admits any lone non-dynamic pick for the track, including the `t-<id>-none` sentinel. Without an explicit order, a mapped track that had lost one of its two statics would auto-select the survivor — precisely the opposite of the AC's mapped-but-missing-stays-blank rule. The five-step order is now in the plan, with step 3's "return `null` rather than fall through" called out as the rule that actually delivers that AC |

### Second review (all findings accepted; verified against code before accepting)

| Finding | Severity | Disposition |
| --- | --- | --- |
| Reactive DnD wiring under-specified | High | **Accepted → F6b.** Confirmed: the two callers of `resolveInitialPickValue()` watch `isOpen` and `trackCollectionOptions` only (`:419-440`); neither reacts to a track change, so selected-track state alone produces nothing. Spec now requires the watcher, the reset-on-track-change, the override-only-while-track-unchanged ordering, and a component-level test. Added the detail that `:571-583` already clears dynamic state off `selectedPickValue`, so the spec says what is reused rather than rebuilt |
| Test plan contradicts the target workflow | Medium | **Accepted — my error.** I wrote that `spec:445` should "flip to a default" while three sections earlier specifying that generic DnD opens with **no** selection. Read the test: it asserts exactly the target state. Corrected — keep that assertion, add a second for reactive defaulting after track selection |
| Recategorize guard has a singleton hole | Medium | **Accepted → F4a.** Confirmed: `spec:1481` only covers a multi-collection track, so a recategorize on a single-static-collection track with a null initial collection would hit `matches.length === 1` and auto-select. Also captured the reviewer's Exhibits/MVC caveat: the guard must not blanket-return-null, since collectionless tracks depend on the same path for their `t-<id>-none` sentinel. Flagged as a pre-existing defect surfaced by this ticket, not caused by it |
| Artifact package overbuilt | Medium | Noted; excluded from this pass per your instruction. Full package stands as mandated |

### First review

| Finding | Severity | Disposition |
| --- | --- | --- |
| Drag-and-drop not actually satisfied | High | **Accepted, plan corrected, and resolved.** F6a retracted and rewritten; verified against `ProceedingDetailPage.vue:216-219, 305-312, 762-775` and `buildPickOptions:162-173`. User direction: implement the AC rather than revise it — generic DnD gets an explicit track-selection state, bounded by F6a's out-of-scope list. No longer an open question; nothing pending with Product on this point |
| F8 overstates the type-prefill risk | Medium | **Accepted, plan corrected.** F8a added; downgraded from a gating condition to ordinary test coverage |
| Environment `SELECT` should not gate the spec | Low | **Accepted.** A3 downgraded; fallback test carries it |
| Phase 2 artifact package is overbuilt | Medium | **Escalated; user chose the full package.** See below |

**On the artifact package.** The nine outputs are mandated by `orchestrate/SKILL.md:8` ("do **not** scale the ceremony down because the ticket looks small") and `:337`. Since the same lines make invocation the user's call, the question was put to them rather than trimmed unilaterally. **Decision: run the full package as mandated.** The emission list below stands unchanged.

**On the DnD finding.** The review identified a real unmet AC; the user's resolution is to implement the AC rather than revise it. The spec now carries a minimal track-selection change for generic DnD, with an explicit out-of-scope list bounding it. This grows the change beyond "a front-end mapping," and the 3-point estimate should be revisited at Phase 4 — flagged, not silently absorbed.

## Emission todos for Phase 2

1. **Investigation report** → `docs/atlas/PRDV-16461/investigations/PRDV-16461-investigation.md`, per the report template. Verdict: **proceed** — no open questions and nothing blocked pending an external answer. The two items that were previously carried as spec-time decisions are both **closed** by the third review: **A8** (permission) by F6c's permitted-tracks-only selector, and **F5a** (mode discrimination) by `mode === 'upload' && lockedTrackTypeId == null`. Lead the verdict with F6a's resolution (generic DnD needs explicit track-selection state; the AC is implemented, not revised), then F3's reframing (a rule that already exists, widened) and F1's resolution of both ticket-flagged unknowns. Record under Alternatives considered: revising the AC to match current behavior (**rejected by the user** — the AC defines the required future behavior); making group headers selectable (**rejected** — a dedicated track selection is preferred over overloading structural rows). Record the retracted claims F6a/F8a with what refuted each, and A8's full arc (refuted → reopened by the new track-selection step → closed by permitted-tracks-only) as a worked example of an assumption that moved twice. Carry **F6c** (interaction contract), **F6b.1** (transition scoped to mutable DnD track changes) and **F6d** (resolver precedence) into the spec verbatim — they are the implementation-safety clarifications the third review asked for. Note the estimate risk: the change now exceeds a pure mapping, so the 3-point sizing is revisited at Phase 4.
2. **Coverage ledger** → `investigations/PRDV-16461-coverage-ledger.md`. Consulted line first (incl. the `docs/atlas/reviews/` recommendation), then areas: upload-form composable; form component modes; approve flow; recategorize flow; collections API + types; Callisto seed migrations; Callisto collection entity/assembler; existing spec suite. Frontier: `DeliverableFileUploadForm.vue` and the select field have **no specs at all**.
3. **Diagrams** → `investigations/PRDV-16461-diagrams.md`. Current-vs-target of `resolveInitialPickValue()`; **current-vs-target of the generic-DnD interaction** (today: one combined list with disabled group headers → target: explicit track selection, then reactive collection default), which is now the most load-bearing diagram; a flow for the four entry paths converging on one composable; a sequence for open → track chosen → default → type-query → pre-fill. N/A lines for kinds skipped.
4. **Test-plan seed** → `testing/PRDV-16461-test-plan.md`, each scenario naming the criterion it exercises:
   - **Generic DnD:** modal opens with **no track and no collection** (this is the target state, not a regression — see the correction below); choosing Transcript then reactively defaults Full Transcript; choosing Video reactively defaults MP4 Video; changing the track again clears the prior collection/dynamic/type selections and applies the new default; the default stays editable; a manual override survives while the track is unchanged and is discarded on a deliberate track change; all files in the batch take the one chosen track; a track with no mapping (or a mapped collection absent from the available list) leaves the collection blank with no error.
   - **Direct / per-track upload:** Transcript preselects Full Transcript, Video preselects MP4 Video on open with the track locked; override allowed.
   - **Approval:** inherited track locked, correct collection preselected, type pre-fill runs immediately; mixed-track selections still blocked.
   - **Recategorize:** existing collection preserved; stays blank when files disagree; no default applied to a blank or ambiguous collection; **and — the singleton hole — a recategorize on a track with exactly one static collection and a null initial collection must stay blank**, which the current `matches.length === 1` fallback (`:407-414`) would otherwise auto-select. The existing recategorize test at `spec:1481` only covers a *multi*-collection track, so this case is uncovered today.
   - **Cross-cutting:** non-stickiness across close/reopen; async backfill only when nothing selected; changing collection reloads eligible types and re-evaluates pre-fill; unmatched type stays blank; **Exhibits/MVC keep working** — the track-only sentinel (`t-<id>-none`, emitted at `:147-160` for collectionless tracks) must still auto-select, so any recategorize guard must not blanket-disable the singleton path; dynamic collections never selected; non-GCA flow unchanged; the `matches.length === 1` fallback still firing for unmapped tracks outside recategorize.
   - **Component-level (F5 frontier / F6b.4):** the DnD test must prove the **whole interaction**, not merely that the composable's state changed — the track can be selected; only permitted tracks are offered; collection choices are scoped to the chosen track; the correct default becomes **visible**; a manual override survives while the track is unchanged; changing the track clears the override and applies the new default; and recategorize, including the singleton-collection case, stays unchanged unless the user acts. `DeliverableFileUploadForm.vue` has no spec today.
   - **Existing specs — corrected disposition.** `spec:418` (multi-collection track with an initial track id) flips to a default. **`spec:445` does NOT flip** — it asserts generic DnD opens with no pre-selection, which the target workflow still requires; keep that assertion and *add* a second one covering reactive defaulting after track selection. `spec:1481` must stay null under recategorize.
5. **Why doc** → `PRDV-16461-why-these-changes.md` with the Phase 1 why-log: class of problem = *a default that exists in code but never fires because its trigger condition is too narrow*. What was obvious (add a mapping); what was not (F3 — the rule already exists and only needs widening); what was **discarded, and why it matters** — three claims I made and then had to withdraw: F4's structural-exclusion inference (corrected by code trace), F6a's "selecting a track is selecting a collection" (corrected by team review; the most consequential, since it hid an unmet AC), and F8a's "narrower catalog" (corrected by team review). The pattern in all three: a plausible structural inference asserted without tracing the specific path. Worth logging as a method note, not just an outcome.
6. **Job-story reconcile** → close story 01's two open questions against F1/F2 with a Phase 1 Story log entry on each story touched; story 02 unchanged (its questions remain genuine product decisions).
7. **Concerns** → `PRDV-16461-future-development-concerns.md` on first concern: F1a (MIME-label name collision), F7a (API omits `collection_kind`, forcing string matching), and the `DeliverableFileUploadForm.vue` spec gap.
8. **PR draft shell** → `PRDV-16461-pr-draft.md`, headings and empty placeholders only.
9. **Ledger + changelog** — Phase 1 `done`, Phase 2 `in-progress`; save this plan verbatim to `investigations/PRDV-16461-recon-and-plan.md` (frozen thereafter); append the Phase 2 changelog session entry.

---

## Carry-forward rule for downstream artifacts

**This plan keeps its retraction scar tissue on purpose. The spec must not.**

Phase 1's job is to show the reasoning, so F6a, F8a, F4's original inference, F5a and A8's two-step arc are all recorded here as withdrawn claims with their correction history. That is what makes the recon auditable and what lets a later reader see *why* a conclusion is trusted. It also means a reader must parse three superseded positions to reach the current one, which is the wrong shape for a document people build from.

So, for `specs/PRDV-16461-spec.md` and every downstream artifact:

- **State only the resolved position.** The spec says what the behavior is, not what an earlier draft thought it was. No "originally I concluded," no retraction markers, no correction arcs.
- **Where a rejected alternative genuinely informs a decision, name it once**, in the spec's Alternatives Considered section, as a flat statement of what was rejected and why — not as a narrative of how the conclusion changed.
- **The full arc stays retrievable** in this frozen plan and in the Phase 2 report's addenda. Nothing is lost by keeping it out of the spec; it is one link away.

The resolved positions to carry forward are: F6c (interaction contract), F6b.1 (transition scoped to mutable DnD track changes), F6d (resolver precedence), F4a's guard covering both the mapped default and the singleton fallback, F3's widened-existing-rule framing, F1/F2's confirmed values and kinds, F7a's match-by-value constraint, and the corrected test dispositions. Each is stated in this plan as a current fact and needs no reconstruction.

---

## Verification (how Phase 2's outputs get checked)

- `scripts/check-steps.ps1 -TicketFolder docs/atlas/PRDV-16461 -ThroughPhase 2` — artifacts landed.
- Every finding above cites a path + line; a reviewer can re-derive each without re-running the recon.
- No code changes in this phase or Phase 2 — the implementation-repo gate stays closed until Phase 5.
- **Spec hygiene (Phase 3):** `specs/PRDV-16461-spec.md` contains no retraction markers, no superseded positions, and no correction narrative — checked against the carry-forward rule above before the spec is submitted for review.
