# Investigation Report: Default collections for client deliverables

> Delivered results of running the `investigate` method under `orchestrate` Phase 1–2. The investigating is done; this is the shared reference for the spec that follows.

## Metadata
- **Status:** done
- **Disposition:** proceed
- **Date:** 2026-09-03
- **Owner:** Dustin Thomason
- **Location:** `docs/atlas/PRDV-16461/investigations/PRDV-16461-investigation.md`
- **Ticket:** [PRDV-16461](https://app.clickup.com/t/43227262/PRDV-16461)
- **Domain:** software (front-end interaction + a front-end/back-end data contract)
- **References / evidence:** `atlas-front-end` `main`; `callisto-back-end` `main` (read-only, evidence only). Approved recon: [PRDV-16461-recon-and-plan.md](./PRDV-16461-recon-and-plan.md). Coverage: [PRDV-16461-coverage-ledger.md](./PRDV-16461-coverage-ledger.md). Diagrams: [PRDV-16461-diagrams.md](./PRDV-16461-diagrams.md).

---

## 0. Verdict (bottom line up front)

**Proceed.** The ticket is buildable front-end-only with no backend change, no new endpoint, and no DTM configuration — the collection catalog already carries the collection `value` and its eligible types on the wire. Both unknowns the ticket flagged before dev turned out to be answerable from code and are closed: `Full Transcript` and `MP4 Video` are real seeded production rows with eligible deliverable types configured. The work is smaller than it looks in one respect and larger in another. Smaller: a defaulting rule **already exists** in the upload form and simply declines when a track has more than one static collection, so this widens an existing rule rather than adding a new mechanism. Larger: generic drag-and-drop currently has **no track-selection moment at all**, so a mapping alone cannot satisfy the ticket's headline behavior — that flow needs an explicit, mutable track selection for the default to have a trigger.

- **Strongest path:** add a named track → collection mapping consulted inside `resolveInitialPickValue()` ahead of the existing single-option fallback, guarded out of recategorize; give generic drag-and-drop an explicit track-selection state that resets and re-defaults on change; leave locked-track flows (direct upload, approval) on their existing initialization path.
- **Not yet proven / not approved:** nothing is implemented or executed. No code has been written and no test has been run. The 3-point sizing predates the drag-and-drop finding and is not re-estimated here — that is Phase 4's call. The visual "this was defaulted" indicator is a separate, still-unresolved Product decision (job story 02) and is deliberately excluded.

## 1. Problem class

- **Class the request assumed:** a missing configuration/mapping — "there is no default, so add one."
- **Confirmed class:** **a default that already exists in code but never fires, because its trigger condition is too narrow — and, in the flow the ticket cares most about, because there is no trigger moment at all.** A default needs both a *rule* and a *moment*; this ticket supplies both.
- **Reframed?** **Yes**, twice, and both matter.
  1. From "add a defaulting feature" to "widen an existing defaulting rule" — triggered at Step 4 (root-cause trace) on reading `resolveInitialPickValue()`'s terminal branch (`:407-414`), which already auto-selects when a track has exactly one non-dynamic option.
  2. From "a front-end mapping change" to "a mapping change **plus** an interaction change" — triggered during plan review, when tracing generic drag-and-drop showed the form opens with no track and track group headers are non-selectable.
- **What the confirmed class implies:** the diff must be read as a widened rule, not new behavior, so the existing single-option fallback has to survive for tracks outside the mapping. And because the rule's *reachability* is part of the problem, resolver **ordering** becomes load-bearing rather than incidental — an unordered fix can satisfy the mapping and still violate the "mapped-but-missing stays blank" criterion.

## 2. Problem statement

- **Named instances:** Ops Atlas users adding files to the Client Deliverables set on the GCA-enabled flow — every Transcript upload and every Video upload. Not blocked (the manual path works), but paying a per-file cost on the highest-volume path. Ticket assigned to Dustin Thomason, moved Ready For Work → In Progress 2026-09-02, in Sprint 2026-18 (9/2–9/15).
- **One sentence:** when adding Transcript or Video files to client deliverables, the collection is never pre-selected, so the user sets the same value by hand on nearly every file.
- **Distinct problems** (kept apart):
  1. The collection is not pre-selected for the two base-case tracks.
  2. Generic drag-and-drop has no track-selection state, so there is nothing for a pre-selection to key off.
  3. A pre-selected value is visually indistinguishable from one the user chose. → job story 02, deferred by user direction, not in this scope.
- **Urgency:** in the current sprint (9/2–9/15). Shaye Lankford recorded it as "a win, but **not a requirement**" for the 9/30 body of work, so it is schedule-sensitive rather than date-critical.
- **Wedge:** the named mapping consulted inside `resolveInitialPickValue()`. It is the smallest change that makes the existing rule fire for a multi-collection track, and it stays reusable — any future track/collection default is one entry in the same map.

### Problem Check

- **Asked:** pre-select the base-case collection for Transcript and Video so users stop setting it manually — *evidence:* "so that I don't have to manually set collections for the most common, base-case workflows"
- **Answered:** the same question plus a second one about signalling that a value was pre-chosen; drift is *"make the right collection appear automatically"* → *"make it appear automatically **and** make clear it was automatic"* — *evidence:* "someway notating that the collection was chosen for them"
- **Should-ask:** in generic drag-and-drop, what event is a "track selection" that a collection default could react to? — *why:* the criterion assumes such a moment exists; it does not, and the answer separates a one-function change from an interaction change.
- **Conflation:** two distinct problems treated as one — (a) the collection is not pre-selected, (b) a pre-selected value is indistinguishable from a chosen one. Solving (a) does not touch (b); (a) is what *creates* (b). (a) is fully specified, (b) has no confirmed mechanism — *evidence:* "I agree, do you have a suggestion for how you'd prefer to handle this"
- **Thin:** "static" vs "dynamic" collection is load-bearing in the criteria but never defined in the ticket — *evidence:* "never a dynamic collection (Excerpt / Trial Edit)". Closed in §5: it is a real enforced schema concept.
- **Off:** the criteria say to match the collection "by its known value" while the same ticket flags those values as unverified — *evidence:* "they currently appear only in test fixtures on the FE side". Resolved in §8/A1: the values are real, so the fallback path is a genuine edge case rather than the expected outcome.

## 3. The contract

### Acceptance criteria

Authority is [job story 01](../stories/PRDV-16461-job-story-01-default-collection.md); this table tracks coverage, it does not restate or amend the criteria.

| Criterion | Status | What's needed to close it |
|---|---|---|
| Transcript file → Full Transcript pre-selected | covered | Mapping + resolver step 3 |
| Video file → MP4 Video pre-selected | covered | Mapping + resolver step 3 |
| Always the fixed base-case value, never situational | covered | Named mapping, not "the only static one" (§5, F2a) |
| User can override before submitting | covered | Existing `q-select` behavior; unchanged |
| Mapped collection absent → nothing selected, no error | **needs-proof** | Resolver step 3 must return `null` **instead of** falling through to the singleton fallback — the ordering rule in §7 |
| Applies to drag-and-drop, direct upload, and approval | **needs-proof** | Direct upload and approval are covered by the mapping alone; **drag-and-drop additionally requires the new track-selection state** |
| Drag-and-drop: user is asked the track, default appears on answer | **gap → closed by design** | No such moment exists today; the spec introduces it (§7) |
| Every add action re-applies the default (not sticky) | covered | Existing `isOpen` watcher already nulls on close (`:419-429`) |
| Recategorize unaffected | **needs-proof** | Guard must cover **both** the new mapping and the pre-existing singleton fallback (§5) |
| Type pre-fill composes with the defaulted collection | covered | `selectedOption` is already a dependency of the pre-fill watcher (`:735-746`) |
| GCA-enabled flow only | covered | `isGcaEnabled` already gates the surrounding flow |

### Non-goals / out of scope

- Any backend, DTM, or configuration change — the mapping is front-end per the ticket's Option A.
- The visual indicator that a value was defaulted — job story 02, unresolved Product decision, deferred by user direction.
- How the app determines whether the user chose the *correct* track; one-track-per-upload-batch semantics; file-type inference or validation; mixed-track batch support; drop locations or track-specific drop zones; post-upload track behavior; non-GCA upload behavior.
- Re-estimating the ticket. Flagged for Phase 4, not decided here.

## 4. What changed since the request was created

- **Shifted from:** "define a front-end track → default-collection mapping" → **to:** "widen an existing defaulting rule **and** give generic drag-and-drop a track-selection moment for it to fire in." The class change is the headline — see §1.
- **What that buys us:** the criteria become implementable as written rather than partially satisfiable. Without the second half, direct upload and approval would default correctly while the flow the story leads with would still require a manual pick — a feature that appears to work and does not.
- **What it still needs to prove:** that the new interaction stays inside its scope fence (§3 non-goals) and does not become a drag-and-drop redesign; and that the resolver ordering actually produces a blank for mapped-but-missing rather than a silent fall-through.

## 5. Why it exists

- **Origin traced to:** `useDeliverableFileUploadForm.ts:407-414`. The terminal branch of `resolveInitialPickValue()` auto-selects only when exactly one non-dynamic pick matches the track:

  ```ts
  const matches = trackCollectionOptions.value.filter(
    (o) => o.rowKind === 'pick' && o.trackTypeId === trackId && !o.isDynamic,
  );
  if (matches.length !== 1) return null;
  return matches[0].value;
  ```

  Transcript carries two statics (`Full Transcript`, `Redacted`) and Video carries two (`MP4 Video`, `MPEG Video`), so the count is 2 and the rule declines. The behavior is not missing; it is unreachable for exactly the tracks that matter.

- **Second origin (the drag-and-drop half):** `buildPickOptions()` emits track group headers with `disable: true` (`:162-173`), so a track cannot be selected on its own — only a specific collection row can. Generic drag-and-drop mounts the form with `lockedTrackTypeId` left `null` (`ProceedingDetailPage.vue:305-312, 762-775`, gated by `useDeliverableDndFlow` = `activeTab === 'client-deliverables' && isGcaEnabled` at `:216-219`), and `resolveInitialPickValue()` returns at its first line without a track (`:387-388`). There is therefore no track-selection event in that flow at all.

- **Evidence (primary sources):**
  - Seeded production values: `callisto-back-end/src/typeorm/migrations/1775761245238-seed__deliverable_collections__table.ts:22,32` — `'Full Transcript'`/Transcript and `'MP4 Video'`/Video, both `collection_kind = 'static'`, `proceeding_id = NULL`. Corroborated by `1781001967151`'s `down()` whitelist naming all four production statics.
  - Eligible types seeded: `1782200000003-seed__deliverable_type_deliverable_collections__table.ts:23-268` — ~19 types for Full Transcript, ~11 for MP4 Video; five are Full-Transcript-only, showing per-collection authorship rather than a copied list.
  - Static/dynamic is a real schema concept: `collection_kind` column with `COLLECTION_KIND = { STATIC, DYNAMIC }` (`deliverable-collection.entity.ts:25-31,52-53`), plus a `'*DYNAMIC*'` sentinel template row per dynamic-capable track (`deliverable-collection.constants.ts:8`, seeded by `1782200000002`). This closes the Problem Check "Thin" flag.
  - Contract the front end must mirror: `ResolveEffectiveDeliverableCollectionAssembler:33-46` validates that a submitted collection belongs to the track and 404s on unknown ids.

- **Detection gap (why nothing caught this):** the two existing specs that assert `null` for a multi-collection track (`spec:418`, `:445`) read as *correct* today, because ambiguity genuinely was the right answer before a mapping existed. They pin the current behavior rather than the intended behavior, so nothing failed. Separately, `DeliverableFileUploadForm.vue` has **no spec at all**, which is why the drag-and-drop interaction gap was invisible to the test suite and surfaced only under human review.

- **Class re-check:** **flipped, twice** — see §1. Both flips were confirmed against code, not inference, and the wedge and acceptance criteria were redone after each.

## 6. Alternatives considered

| Alternative | Rejected because |
|---|---|
| Match on `collection_kind === 'static'` instead of a named value | `Redacted` and `MPEG Video` are also `static` (`1780604349327:16,32`), so "the static one" is ambiguous on both target tracks. The API also omits `collection_kind` entirely (`fetch-deliverable-collections.response.dto.ts` exposes only `{ id, value, eligibleTypes }`), so no kind flag is even available client-side. |
| Revise the drag-and-drop criterion so the default applies only where the track is already known | Rejected by the user: the criterion defines the required future behavior, and the AC should not be rewritten to preserve the current implementation. |
| Make track group headers selectable in the combined list | Rejected in favor of a dedicated track control. Overloading a structural row with selection semantics is a less clear interaction and would change the meaning of an existing element rather than adding a new one. |
| Add a fourth `DeliverableFileUploadFormMode` value for generic drag-and-drop | Unnecessary. `mode === 'upload' && lockedTrackTypeId == null` already identifies it uniquely. |
| Guard the default on `hasPermission` inside the resolver | Unnecessary once the new track selector exposes only tracks the user can create on — the default can then never land on an unsubmittable pick. Adding the condition anyway would create a branch no test could reach. |
| Backend or DTM-configured defaults | Out of scope by the ticket's Option A, and unnecessary — the FE already receives `staticCollections[].value` and `eligibleTypes`. |

## 7. Solution & stress-test

- **Proposed solution — three parts:**
  1. **A named mapping** (Transcript → `Full Transcript`, Video → `MP4 Video`) as a new, separately-named front-end constant, consulted inside `resolveInitialPickValue()` ahead of the existing single-option fallback.
  2. **An ordered resolution rule**, so the mapping and the pre-existing fallback cannot conflict: (1) in recategorize, preserve a valid existing collection; (2) for collectionless tracks, preserve the internal `t-<id>-none` selection; (3) outside recategorize, if the track is mapped, select that exact static collection — **and if it is absent, return `null` rather than falling through**; (4) for an unmapped collection-bearing track, keep the existing singleton fallback; (5) never auto-select a dynamic or disabled option.
  3. **An explicit, mutable track-selection state for generic drag-and-drop**, exposing only tracks the user has CREATE permission on, with collection choices scoped to the chosen track. Changing the track clears the previous collection, dynamic-collection and per-file type state, then applies the new track's default.

- **Solves the confirmed class?** Yes, both halves. Part 1+2 make the existing rule fire and fire correctly; part 3 gives it a moment to fire in. Step 3's "return `null` rather than fall through" is what converts the mapped-but-missing criterion from an aspiration into a guarantee.

- **Scale:** a new default is one map entry. The mapping is keyed on track value and matched against `staticCollections[].value`, both of which already arrive per-track, so adding a track later requires no structural change. Nothing here is per-proceeding or per-user, so there is no growth surface.

- **Generalization:** deliberately not abstracted. No configuration layer, no precedence engine, no backend-driven rules — the ticket asks for two defaults and the codebase gets two defaults. The ordered resolver is the only "general" piece, and it exists because ordering is required for correctness, not for future flexibility.

- **Fit:** the change lands inside the function that already owns initial selection, reuses `isDynamic` and `hasPermission` fields already on the option type, and preserves the existing fallback for other tracks. The one genuinely new thing is the drag-and-drop track control, which follows the pre-GCA `TrackSelectorForm` shape rather than inventing an interaction.

- **Adjacent issues:** the recategorize singleton hole is a **pre-existing defect** — a recategorize on a track with exactly one static collection and a null initial collection auto-selects today, contrary to "recategorize changes nothing on its own." Fixing it now is materially cheaper than a follow-up, because the guard being written for the new mapping is the same guard; the only cost is widening it to cover the fallback and adding one test. Recommend fixing now and stating plainly in the PR that it pre-dates this ticket.

- **Sufficiency:** covers the pain that convened the ticket — the per-file manual pick on the two highest-volume tracks, across all three add paths. It does **not** cover the "was this chosen for me?" question (job story 02), which the user has deferred by decision.

- **Feedback speed:** fast. Unit tests exercise every resolver branch in seconds; the drag-and-drop interaction is observable manually in one upload. The slowest signal is whether users actually stop overriding the default, which is a post-release observation and not a gate.

- **Happy-path story (30 seconds):** an Ops user drags four transcript PDFs onto the Client Deliverables tab. The modal asks which track — they pick Transcript. Full Transcript fills in immediately, and each file's deliverable type resolves from its filename against that collection's eligible types. They glance at it, change nothing, and submit. No collection was ever chosen by hand, and nobody had to configure anything for that to be true.

## 8. Assumptions ledger

- **Claim:** `Full Transcript` and `MP4 Video` exist in production as static, global collections on Transcript and Video.
  - **Status:** confirmed
  - **Confirm/revise by:** seed `1775761245238:22,32`. Refuted by a production `SELECT` returning neither.
- **Claim:** Both have eligible deliverable types configured, so type pre-fill resolves.
  - **Status:** confirmed
  - **Confirm/revise by:** junction seed `1782200000003:23-268`; the seed throws if either collection is absent (`:306-311`).
- **Claim:** Those rows exist in *every* target environment.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** `1775761245238:11-16` short-circuits if any global row already existed, so code alone cannot prove it per-environment. Mitigated: the junction seed throws on a missing collection, so a successfully-migrated environment necessarily has them. **Not a gate** — the mapped-but-missing fallback is a required criterion with its own test, and a QA smoke check confirms deployed data.
- **Claim:** Nothing pre-selects today *only* because both tracks carry two statics.
  - **Status:** confirmed
  - **Confirm/revise by:** `:407-414` plus the four seeded statics. Refuted if a target track ever had exactly one.
- **Claim:** Dynamic collections cannot be defaulted.
  - **Status:** confirmed
  - **Confirm/revise by:** three independent mechanisms — `fetchStaticCollections()` filters to `'static'` so the sentinel never reaches `staticCollections`; real dynamic instances carry `proceeding_id != NULL` and load from a separate endpoint; the FE's dynamic pick is synthesized with `isDynamic: true, deliverableCollectionId: null`.
- **Claim:** Recategorize can reach the branch this ticket modifies.
  - **Status:** confirmed
  - **Confirm/revise by:** `recategorizeSharedCollectionId` returns `null` when files have no collection or disagree (`DeliverableFileUploadForm.vue:136-144`); pinned by `spec:1481-1490`.
- **Claim:** Defaulting cascades into type pre-fill with no extra wiring.
  - **Status:** confirmed
  - **Confirm/revise by:** `selectedOption` is a dependency of the pre-fill watcher (`:735-746`).
- **Claim:** Defaulting does not narrow a previously-broader type catalog.
  - **Status:** revised (an earlier claim that it did was wrong)
  - **Confirm/revise by:** the type query is gated on `selectedOption != null` (`:643-646`) and keyed on `collectionId` (`:655`). With no collection there is no query at all, not an unfiltered one. Defaulting changes *when* the query runs, not how narrow it is.
- **Claim:** A no-permission pick can never be defaulted.
  - **Status:** confirmed (via design)
  - **Confirm/revise by:** locked flows are permission-gated before the form opens (`ClientDeliverablesTable.vue:586-587`; `useApproveFlow.ts:54`), and the new drag-and-drop selector exposes only permitted tracks. Refuted if the selector is later specified to list unpermitted tracks.

## 9. Validation plan

**Happy path**
1. GCA enabled, Client Deliverables tab. Drag in transcript files → modal opens with no track and no collection.
2. Choose Transcript → `Full Transcript` appears immediately, editable; per-file types resolve against its eligible-type catalog.
3. Submit → files land with the defaulted collection.
4. Repeat with a video file and Video → `MP4 Video`.
5. Per-track Upload on Transcript → modal opens with the track locked and `Full Transcript` already selected.
6. Approve a submission video file → modal opens with the track inherited and `MP4 Video` already selected.

**Negative paths**
- **Mapped collection absent for a track** → nothing selected, no error, no fall-through to a different static collection. This is the ordering rule's proof and must fail visibly in test rather than silently pick a neighbor.
- **Recategorize, blank/ambiguous collection, single-static-collection track** → stays blank. Covers the pre-existing singleton hole.
- **Recategorize, existing collection** → preserved unchanged.
- **Collectionless tracks (Exhibits, MVC)** → still auto-select their `t-<id>-none` sentinel; the recategorize guard must not blanket-block that path.
- **Track changed in drag-and-drop after a manual override** → previous collection, dynamic state and per-file types are cleared and the new track's default applied; the discarded override does not survive.
- **Manual override with the track unchanged** → survives; the async-options backfill must not overwrite it (`:434-435`).
- **Unmapped collection-bearing track** → existing single-option fallback still fires.
- **Dynamic pick (Excerpt / Trial Edit)** → never auto-selected.
- **Non-GCA flow** → unchanged; no collection sent.
- **Filename matching no auto-select rule** → deliverable type left blank, which is expected, not an error.

## 10. Decisions, recommendation & open variables

- **Decisions (settled):**
  - Implement the drag-and-drop criterion; do not revise it to match current behavior. *(User, 2026-09-03.)*
  - A dedicated track control, not selectable group headers.
  - `mode === 'upload' && lockedTrackTypeId == null` discriminates generic drag-and-drop; no new form mode.
  - The track selector exposes only tracks the user has CREATE permission on; no permission guard inside the resolver.
  - The reset/default transition fires on the mutable drag-and-drop track change only; locked flows keep their existing initialization.
  - Fix the recategorize singleton hole in this ticket, and attribute it in the PR as pre-existing.
  - Full orchestrate artifact package retained. *(User, 2026-09-03.)*

- **Recommendation (in order):** (1) mapping constant; (2) ordered resolver with the recategorize guard covering both the mapping and the fallback; (3) drag-and-drop track-selection state and its reset transition; (4) unit tests per §9; (5) the first component spec for `DeliverableFileUploadForm.vue`, covering the drag-and-drop interaction end to end.

- **Sequencing & gates:** items 1–2 are independently testable and can land before any interaction work. Item 3 depends on the spec settling the control's shape. Item 5 is not optional — without it the new interaction ships with no component-level coverage, which is the same blind spot that hid the gap in the first place.

### Open variables to collect

**None.** Every question this investigation surfaced resolved by evidence or by a recorded decision. Two items that were open during Phase 1 closed before emission: the permission question (by the permitted-tracks-only selector) and the mode-discrimination question (by the existing `lockedTrackTypeId` check). The one genuinely deferred item — the visual "defaulted" indicator — is tracked as [job story 02](../stories/PRDV-16461-job-story-02-default-indicator.md) and is out of this ticket's scope by user direction, not an unresolved variable within it.

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done-when (falsifiable) |
|---|---|---|
| Write the spec (Phase 3) | Agent | `specs/PRDV-16461-spec.md` exists, carries the ordered resolver and the drag-and-drop contract, and states resolved positions only per the recon's carry-forward rule |
| Submit the spec to its reviewer | Dustin | Spec delivered through the team's review surface; the response is recorded in the ledger before any product code |
| Re-estimate | Phase 4 | Sizing revisited against the interaction change; 3 points confirmed or changed on the record |
| Implement + test | Phase 5 | All §9 paths pass; `DeliverableFileUploadForm.vue` has a component spec covering the drag-and-drop interaction |
| Resolve the indicator | Shaye Lankford / Product | Job story 02's mechanism named; tracked separately, does not gate this ticket |

### Checklist

#### Investigation
- [x] This report (Sections 0–10)
- [x] Coverage ledger
- [x] Diagrams
- [x] Test-plan seed

#### Project Spec
- [ ] Locked decisions ledger
- [ ] Accepted job stories
- [ ] Spec written
- [ ] Spec submitted for review

## 12. Definition of done (investigation gate)

- [x] Confirmed problem class stated, with both reframings and the step each flipped at
- [x] Problem in one sentence; named instances; urgency
- [x] Wedge identified and argued reusable
- [x] Acceptance criteria mapped to coverage status; non-goals fenced
- [x] Root cause traced to specific code with primary-source evidence
- [x] Detection gap named
- [x] Alternatives recorded with reasons
- [x] Assumptions ledger falsifiable, with one claim explicitly revised
- [x] Validation plan with happy and negative paths
- [x] Open variables reconciled — none remain; deferred item tracked as its own story
