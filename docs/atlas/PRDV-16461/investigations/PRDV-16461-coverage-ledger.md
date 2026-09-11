# Coverage ledger — atlas/PRDV-16461

Investigation question: **why is no collection pre-selected for Transcript and Video files in the client-deliverables upload flow, what is the complete set of surfaces where a default would have to apply, and can a front-end-only mapping satisfy the acceptance criteria?**

Repo(s): `atlas-front-end` (change site), `callisto-back-end` (evidence only, no changes) · Baseline commits: `atlas-front-end` `main` **`eb113e3b`**; `callisto-back-end` `main` **`d84a4628`** · Started: 2026-09-03

## Consulted

Searched `docs/atlas/*/investigations/*-coverage-ledger.md` and `docs/*/tickets/*/investigations/*-coverage-ledger.md` for "collection", "deliverable", "DeliverableFileUpload", "DTM", "track", "upload form". **Twelve ledgers found; four read; one substantively reusable.**

- **`PRDV-16403` — found, reused as convention ground.** The only prior ledger with real `atlas-front-end` GCA front-end coverage. Reused **without re-deriving**: Vue Query `staleTime`/`gcTime` conventions, `useFeatureFlags` / `useGrantingClientAccessFlag`, `src/callisto/api/constants.ts`, `queryKey.ts`, and Atlas `__specs__` conventions. Its own subject (the Access Manager RB-warnings panel) is a different surface with no behavioral overlap, so nothing about the upload form was inherited.
- **`PRDV-16312`, `PRDV-16313`, `PRDV-16402` — found, not reopened.** All three are `callisto-back-end` outbox / event-emission investigations (client-access outbox writer, `file.renamed.v1`, transcode-request emission). They match on the words "collection" and "deliverable" but in an event-contract context, not the DTM collection-selection UI. This ticket declares no backend scope, so none of their findings are load-bearing. Noted for one narrow reason: `PRDV-16312`'s area 2 (the event registry) is where a `collection.*` contract would live **if** default-collection choice ever became backend-driven — explicitly out of scope under Option A.
- **`PRDV-14055`, `PRDV-16192`, and all non-atlas ledgers — no match.**
- **`docs/atlas/reviews/` — searched separately and it paid off.** The ledger glob misses this folder entirely (flagged previously by `PRDV-16403`, still unfixed). `PRDV-16315-callisto-410-review.md:118` surfaced the `DeleteDynamicCollectionTS` test list including *"static collection rejected; sentinel rejected"*, which is what opened the static/dynamic + `*DYNAMIC*` sentinel thread that closed the Problem Check "Thin" flag. **Recommendation, second time of asking: add `docs/atlas/reviews/` to the consult glob permanently.**
- **`docs/atlas/PRDV-16461/` prior artifacts:** the Phase 0 capture, two job stories, the ledger, and a decision-support prototype HTML from a pre-orchestration session (2026-09-02). No prior investigation.
- **No frontier item in any ledger is this ticket.** Virgin ground for the DTM collection-selection surface.
- `dnu/` folders excluded throughout.

## Areas examined

### 1. `atlas-front-end` — `useDeliverableFileUploadForm.ts` (the change site)

| Field | Value |
| --- | --- |
| Inspected | `resolveInitialPickValue()` in full; both watchers that call it; `selectedPickValue` / `selectedOption`; `currentMode` / `isRecategorizeMode`; `trackCollectionOptions`; the dynamic-collection clearing watchers; `refreshPerFileSelections()` and its watcher; the deliverable-types query gate |
| Findings | **The pivotal finding of this pass.** `resolveInitialPickValue()` (`:386-415`) already auto-selects when a track has exactly one non-dynamic pick (`:407-414`); it returns `null` for Transcript and Video only because each carries two statics. The work therefore **widens an existing rule** rather than adding one. Its two callers watch `isOpen` (`:419-429`, also nulls on close ⇒ non-stickiness is free) and `trackCollectionOptions` (`:431-440`, backfills only when nothing is selected ⇒ never clobbers a user choice) — **neither observes a track change**, which is why selected-track state alone would produce nothing. `isRecategorizeMode` is available at `:354` for the guard. Type pre-fill cascades automatically: `selectedOption` is a dependency of the pre-fill watcher (`:735-746`) |
| Status | fully-inspected |
| Commit | `eb113e3b` · 2026-09-03 |
| Evidence | `:354, :386-415, :419-440, :446-455, :571-583, :643-657, :689-746` |
| Notes | The singleton filter at `:407-412` also admits the `t-<id>-none` sentinel for collectionless tracks — which is why resolver **ordering** is load-bearing and why a blanket recategorize guard would break Exhibits/MVC |

### 2. `atlas-front-end` — `buildPickOptions()` and the option type

| Field | Value |
| --- | --- |
| Inspected | `DeliverableTrackCollectionPickOption` type; `buildPickOptions()` in full; `orderTrackTypesForDeliverables`; `applyLockedTrackDisable`; `applyRecategorizeDestinationPermissions` |
| Findings | Option carries `trackTypeId`, `deliverableCollectionId`, `isDynamic`, `hasPermission`, `disable` — so "never default a dynamic option" is enforceable with an existing field. **Track group headers are emitted `disable: true` (`:162-173`)**, so a track is not selectable on its own; only collection rows are. Value grammar: `t-<id>-c-<collectionId>` for a static pick, `t-<id>-none` for a collectionless track, `t-<id>-dynamic` for the synthesized dynamic pick. Track order comes from `clientDeliverablesTrackTypeOrder` and drops anything not listed |
| Status | fully-inspected |
| Commit | `eb113e3b` · 2026-09-03 |
| Evidence | `:39-56, :63-78, :80-191, :193-226` |
| Notes | The disabled group header is the structural reason generic drag-and-drop has no track-selection moment — the second half of the confirmed problem class |

### 3. `atlas-front-end` — `DeliverableFileUploadForm.vue` (mode derivation and entry wiring)

| Field | Value |
| --- | --- |
| Inspected | `isRecategorizeMode` / `isApprovalMode` / `formMode`; `recategorizeSharedCollectionId`; `resolvedInitialTrackTypeId` / `resolvedLockedTrackTypeId` / `resolvedInitialCollectionId`; the composable call site; directory listing for a spec |
| Findings | `formMode` is **derived** (`:127-131`), not a prop — inferred from which file array is populated, precedence recategorize > approve > upload. `resolvedInitialCollectionId` (`:168-171`) supplies the existing collection **only** in recategorize and `null` everywhere else. `recategorizeSharedCollectionId` returns `null` when rows disagree or have no collection (`:136-144`) — **this is what lets recategorize reach the modified branch**, refuting an earlier structural inference that it was excluded for free. **The component has no spec file at all** |
| Status | fully-inspected |
| Commit | `eb113e3b` · 2026-09-03 |
| Evidence | `:118-131, :136-144, :153-171, :202-229`; `ls` of the component dir shows no `__specs__` entry for the `.vue` |
| Notes | The missing component spec is the detection gap (report §5) — it is why the drag-and-drop interaction gap was invisible to the suite |

### 4. `atlas-front-end` — the four entry paths (surface enumeration)

| Field | Value |
| --- | --- |
| Inspected | `ProceedingDetailPage.vue` DnD handlers and both form mounts; `useApproveFlow.ts` in full; `useRecategorizeFlow.ts` in full; `buildRecategorizeRows.ts`; repo-wide grep for `isGcaEnabled` |
| Findings | **Generic DnD** mounts the form with `locked-track-type-id="dndInitialTrackTypeId"`, left `null` by `handleFilesValidated` (`:305-312`), under `useDeliverableDndFlow` = `activeTab === 'client-deliverables' && isGcaEnabled` (`:216-219`) — the ticket's exact in-scope flow. **Direct upload** sets that same ref to a real track id (`:314-320`) via `ClientDeliverablesTable.vue:350`. **Approval** locks the track from `filesToApprove[0]` (`useApproveFlow.ts:54`) and short-circuits to a no-collection mutate when GCA is off (`:55-62`). **Recategorize** passes existing per-file rows built by `buildRecategorizeRows` |
| Status | fully-inspected — the entry-point list is complete |
| Commit | `eb113e3b` · 2026-09-03 |
| Evidence | `ProceedingDetailPage.vue:216-219, 305-320, 322-333, 762-775, 776-786`; `useApproveFlow.ts:49-65`; `useRecategorizeFlow.ts:57-65`; `buildRecategorizeRows.ts:4-14` |
| Notes | **Completeness claim:** all four converge on one composable whose only initial-selection writer is `resolveInitialPickValue()`, called from exactly two watchers. Generic DnD and direct upload are indistinguishable by `mode` alone (both `'upload'`); `lockedTrackTypeId == null` is the discriminator |

### 5. `atlas-front-end` — permission gating on the entry paths

| Field | Value |
| --- | --- |
| Inspected | `hasUploadProceedingFilePermission` and its use; `singleProceedingFileAuth` call sites in `ClientDeliverablesTable.vue`; `canSubmit` in the composable |
| Findings | Per-track upload is permission-gated **before** the form opens (`:586-587`); approval locks the track to files the user just acted on. In the current combined list a no-permission pick renders `disable: true` and is unclickable. So no existing path can default a disabled pick — **but the new DnD track selector would create one** unless it exposes only permitted tracks, which is how the spec resolves it |
| Status | fully-inspected |
| Commit | `eb113e3b` · 2026-09-03 |
| Evidence | `ClientDeliverablesTable.vue:586-590`; composable `canSubmit` requires `hasPermission` |
| Notes | Source of the assumption that moved twice — refuted, reopened by the interaction change, then closed by design |

### 6. `atlas-front-end` — collections data source and types

| Field | Value |
| --- | --- |
| Inspected | `types/deliverable-collections.ts` in full; `useDeliverableCollections.ts`; `api/constants.ts` collections URL; `useDeliverableCollectionLabels.ts` kind-resolution helper |
| Findings | `DeliverableTrackTypeItem = { id, value, staticCollections[], hasDynamicCollections }`; `DeliverableCollectionItem = { id, value, eligibleTypes? }`. **The `value` string and eligible types are already on the wire**, so matching by value needs no new endpoint and no backend change. `eligibleTypes` is declared **optional** on the FE though Callisto always populates it — a minor contract looseness. Sibling precedent: `useDeliverableCollectionLabels.ts:78-90` infers `'static' \| 'dynamic'` by membership in `staticCollections`, the same technique available here |
| Status | fully-inspected |
| Commit | `eb113e3b` · 2026-09-03 |
| Evidence | `types/deliverable-collections.ts:3-27`; `useDeliverableCollections.ts`; `api/constants.ts:164` |
| Notes | Confirms Option A is buildable exactly as the ticket specifies |

### 7. `atlas-front-end` — existing spec suite for the composable

| Field | Value |
| --- | --- |
| Inspected | `__specs__/useDeliverableFileUploadForm.spec.ts` — describe structure, the three pre-selection tests, mocking conventions |
| Findings | ~1986 lines, 7 describes. **Three tests change meaning:** `:418` (multi-collection track with an initial track id → currently `null`, will become a default); `:445` (**generic DnD opens with no pre-selection — this must NOT change**, it asserts the target state); `:1481` (recategorize with a null collection on a *multi*-collection track → must stay `null`). Convention is module-mock + module-scoped reactive refs (`mockTrackTypes`, `mockDeliverableTypes`), not `createComposableMock`; `given:/when:/then:` naming; composable invoked directly with getter params, no `mount` |
| Status | fully-inspected |
| Commit | `eb113e3b` · 2026-09-03 |
| Evidence | `spec:98-1986`; specifically `:414-422, :441-450, :1476-1499` |
| Notes | **Gap found here:** `:1481` covers only a *multi*-collection recategorize. A recategorize on a **single**-static-collection track with a null initial collection is uncovered and would auto-select via the singleton fallback — the pre-existing defect |

### 8. `callisto-back-end` — collection entity, kinds, and the sentinel

| Field | Value |
| --- | --- |
| Inspected | `deliverable-collection.entity.ts` in full; `deliverable-collection.constants.ts`; `sync-static-deliverable-collections.transaction.script.ts`; `resolve-effective-deliverable-collection.assembler.ts` |
| Findings | Table `deliverable_collections` with `collection_kind` (`'static' \| 'dynamic'`), unique on `(value, proceeding_id, file_proceeding_track_type_id)`. `DYNAMIC_SENTINEL_COLLECTION_VALUE = '*DYNAMIC*'` is a per-track **template** row carrying type-eligibility for future dynamic instances; `TRACK_VALUES_WITH_DYNAMIC_COLLECTIONS` = Transcript + Video only. `ResolveEffectiveDeliverableCollectionAssembler:33-46` validates that a submitted collection belongs to its track and 404s on unknown ids — the authority the FE default must not violate |
| Status | fully-inspected |
| Commit | `d84a4628` · 2026-09-03 |
| Evidence | `deliverable-collection.entity.ts:25-31,33-38,52-53`; `deliverable-collection.constants.ts:3-8`; `sync-static-deliverable-collections.transaction.script.ts:19-35`; `resolve-effective-deliverable-collection.assembler.ts:33-46` |
| Notes | Closes the Problem Check "Thin" flag — static vs dynamic is a real enforced concept, not ticket shorthand |

### 9. `callisto-back-end` — seed migrations (the decisive evidence)

| Field | Value |
| --- | --- |
| Inspected | `1775761245238-seed__deliverable_collections__table.ts` in full; `1780604349327-seed__add_redacted_and_mpeg_video...` in full; `1782200000002-seed__dynamic_sentinel...`; `1782200000003-seed__deliverable_type_deliverable_collections__table.ts` in full |
| Findings | **`'Full Transcript'`/Transcript and `'MP4 Video'`/Video are seeded production rows**, `collection_kind = 'static'`, `proceeding_id = NULL` (`1775761245238:22,32`). `'Redacted'` and `'MPEG Video'` are **also static** (`1780604349327:16,32`) — so "static" alone does not identify the default, which is what makes a *named* mapping necessary. Eligible types are richly seeded: ~19 for Full Transcript, ~11 for MP4 Video, with five Full-Transcript-only types showing per-collection authorship (`1782200000003:23-268`) |
| Status | fully-inspected |
| Commit | `d84a4628` · 2026-09-03 |
| Evidence | `1775761245238:11-16, 22, 32, 43`; `1780604349327:16,32`; `1782200000003:7-12, 23-268, 306-311` |
| Notes | `1775761245238:11-16` short-circuits if any global row pre-existed, so code alone cannot prove per-environment presence — **but** `1782200000003:306-311` throws on a missing collection, so a migrated environment necessarily has them. Downgraded from a spec gate to a QA smoke check |

## Not-yet-inspected frontier

- **`DeliverableFileUploadForm.vue` has no spec**, and neither does `DeliverableFileUploadTrackSelectField.vue` or `trackCollectionOptionLabels.ts`. This is the detection gap that hid the drag-and-drop finding. Phase 5 writes the first component spec; the select field and label helper remain uncovered and are **not** in this ticket's scope.
- **The pre-GCA `TrackSelectorForm.vue`** was identified as the shape precedent for the new drag-and-drop track control but **was not read in depth**. Phase 3 should inspect it before specifying the control, to reuse rather than reinvent.
- **Production data confirmation** — no environment was queried. Carried as a QA smoke check, not a blocker (see area 9).
- **`eligibleTypes` optionality** — the FE declares it optional while Callisto always populates it. Not load-bearing for this ticket; recorded as a concern.
- **Deliverable-type auto-select rules** (`deliverable-type-auto-select-rules.ts`) were read only far enough to establish they key on **track**, not collection. Their 26 rules were not individually verified against the defaulted collections' eligible-type sets; the test plan covers matched and unmatched outcomes behaviorally instead.
