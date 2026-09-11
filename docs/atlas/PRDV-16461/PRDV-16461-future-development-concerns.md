# Future development concerns — atlas/PRDV-16461

> Dated, code-verified concerns surfaced during this ticket and shipped **out of scope**. Each names what was observed, why it was not fixed here, and what would close it. Not a TODO list — a risk record for whoever meets this code next.

## C1 — `'MP4 Video'` is also a MIME-type display label (name collision)

- **Observed:** `atlas-front-end/src/globalUtils/fileTypeLabel.ts:67,149` maps `'video/mp4' → 'MP4 Video'` and `mp4 → 'MP4 Video'`. This is a file-icon label map, entirely unrelated to the deliverable collection that happens to share the string.
- **Risk:** an implementer or reviewer grepping `'MP4 Video'` finds this map first. Reusing or "consolidating" it into the collection mapping would couple two unrelated concepts, and a change to the icon labels would silently move the upload default.
- **Why not fixed here:** nothing is wrong with either map. The collision is in the strings, not the code.
- **Closes it:** the collection mapping lives in its own clearly-named constant with a comment stating the collision explicitly. Verified at review by confirming the two constants are never imported into the same module.
- **Date:** 2026-09-03

## C2 — the collections API omits `collection_kind`, forcing string matching

- **Observed:** `deliverable_collections.collection_kind` exists in Callisto (`deliverable-collection.entity.ts:52-53`) with values `'static'`/`'dynamic'`, but `fetch-deliverable-collections.response.dto.ts` exposes only `{ id, value, eligibleTypes }` per collection plus `hasDynamicCollections` per track. The kind never reaches the front end.
- **Risk:** the default has to be matched by the collection's display string. A rename of `'Full Transcript'` or `'MP4 Video'` in production data silently disables the default — no error, no test failure, the feature just stops working. The AC's graceful fallback means this fails *quietly* by design.
- **Why not fixed here:** surfacing `collection_kind` is a backend contract change, explicitly out of scope under the ticket's Option A. It also would not fully solve the problem, since `Redacted` and `MPEG Video` are *also* static — a kind flag narrows the candidates but still does not name the winner.
- **Closes it:** either a stable identifier for base-case collections on the API (a `isDefaultForTrack` flag or a slug distinct from the display name), or a monitored assertion that the mapped values still resolve. Worth raising if a collection is ever renamed.
- **Date:** 2026-09-03

## C3 — `DeliverableFileUploadForm.vue` has no spec, and that is why this gap was invisible

- **Observed:** the component has no `__specs__` entry. Neither does `DeliverableFileUploadTrackSelectField.vue` or `trackCollectionOptionLabels.ts`. The composable is well covered (~1986 lines of spec); the component boundary is not covered at all.
- **Risk:** this is the **detection gap** that let the drag-and-drop finding survive to human review. The existing composable specs assert `null` for a multi-collection track and are *correct today*, so nothing failed. No test could observe that the flow had no track-selection moment, because no test renders the component.
- **Why not fully fixed here:** this ticket adds the **first** component spec, covering the drag-and-drop interaction it introduces. The select field and the label helper remain uncovered, and back-filling coverage for the component's existing behavior is a larger piece of work than this ticket should absorb.
- **Closes it:** a component spec covering the form's existing modes (approve, recategorize, locked-track upload) beyond the new interaction. Candidate follow-up ticket.
- **Date:** 2026-09-03

## C4 — recategorize singleton auto-select is a pre-existing defect

- **Observed:** `resolveInitialPickValue()`'s singleton fallback (`:407-414`) fires in recategorize too. On a track with exactly one static collection, a recategorize opened with a null or ambiguous initial collection auto-selects that collection — contrary to "recategorize preserves the existing track/collection unless the user manually changes it." The existing test at `spec:1481` misses it because it only exercises a *multi*-collection track.
- **Risk:** as shipped today, a recategorize can change a file's collection without the user choosing it. Low blast radius currently (both dynamic-capable tracks carry two statics), but it becomes reachable the moment a track is reduced to one static collection.
- **Why it is being fixed here rather than deferred:** the guard this ticket writes for the new mapping is the same guard. Widening it to cover the fallback costs one condition and one test; a separate ticket would cost a full cycle. **This is recorded as a concern anyway** so the PR can attribute it correctly — it pre-dates this ticket and is not a regression introduced by it.
- **Closes it:** the recategorize guard covering both the mapping and the singleton fallback, plus the single-static-collection recategorize test named in the test plan.
- **Date:** 2026-09-03

## C4b — a disabled track in the DnD selector is a dead end, by design

- **Observed:** per LD-004, the new drag-and-drop track control shows tracks the user lacks CREATE permission on as **disabled with a tooltip**, following `useTrackSelectorForm.ts:53-63` and `TrackSelectorForm.vue:118-129`.
- **Risk:** a user with permission on neither Transcript nor Video sees a track control where every relevant option is disabled. They learn *why* (the tooltip), which is the intended improvement over silently hiding options, but the modal still cannot be completed. That is correct behavior — they genuinely cannot upload — though it is worth knowing the flow ends there rather than in an error.
- **Why not changed here:** it matches the precedent exactly, and blocking modal entry on permission is a broader access-control change well outside this ticket.
- **Closes it:** nothing required. Recorded so a future reader does not mistake the dead end for a defect introduced by this ticket.
- **Date:** 2026-09-03

## C5 — `eligibleTypes` is optional on the front end, always populated on the back end

- **Observed:** `DeliverableCollectionItem.eligibleTypes?: DeliverableType[]` (`types/deliverable-collections.ts:6`) is declared optional, though the Callisto projection always populates it.
- **Risk:** minor. Consumers must handle an absent value that never actually arrives, and a future backend change that *did* omit it would type-check silently.
- **Why not fixed here:** unrelated to this ticket's behavior, and tightening a shared type touches consumers outside this surface.
- **Closes it:** make the field required and fix any resulting consumer errors, once someone confirms no path returns a collection without it.
- **Date:** 2026-09-03

## C6 — `docs/atlas/reviews/` is missed by the coverage-ledger consult glob

- **Observed:** the standard consult pattern globs `docs/**/investigations/*-coverage-ledger.md`. The PR-review notes in `docs/atlas/reviews/` are not ledger-formatted and are therefore invisible to it. In this pass, `PRDV-16315-callisto-410-review.md:118` is what surfaced the static/dynamic + sentinel vocabulary that closed a Problem Check flag.
- **Risk:** a workflow gap, not a code one. Prior review knowledge stays unfindable by the process meant to find it. `PRDV-16403` flagged this previously and it is still unfixed — **twice now**.
- **Why not fixed here:** it is a change to the `investigation` skill's consult protocol, outside this ticket entirely.
- **Closes it:** add `docs/atlas/reviews/` (or a general `docs/**/reviews/`) to the consult protocol in `investigation-coverage-ledger.md`.
- **Date:** 2026-09-03
