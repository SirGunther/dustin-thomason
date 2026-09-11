# Locked decisions — atlas/PRDV-16461

> Per [qa-to-spec-traceability](../../../../agents/docs/qa-to-spec-traceability.md). A locked decision is no longer an open design option. Where later material conflicts, the latest explicit user correction wins unless the user reopens it.
>
> Companion to [PRDV-16461-spec.md](./PRDV-16461-spec.md), which links here rather than restating the table.

## Question gates resolved before asking

The traceability workflow requires each question to pass a gate: *is this a decision only the user can make, and is it not already answered?* These candidates **failed the gate** and were resolved from evidence instead of being asked — recorded so nobody re-opens them as if they were open.

| Candidate question | Why it was not asked | Resolved by |
| --- | --- | --- |
| What shape should the new DnD track control take? | Already answered by precedent | `TrackSelectorForm.vue:104-131` — a single `q-select` over an ordered track list, bound to `selectedTrackId` |
| Are `Full Transcript` / `MP4 Video` the real production values? | Code-discoverable fact, not a decision | Callisto seed `1775761245238:22,32` |
| Do those collections have eligible types configured? | Code-discoverable fact | Callisto seed `1782200000003:23-268` |
| How is generic DnD distinguished from direct upload? | Existing discriminator suffices | `mode === 'upload' && lockedTrackTypeId == null` |
| Does defaulting narrow a previously-broader type catalog? | Code-discoverable; the premise was wrong | Type query is gated on `selectedOption != null` (`:643-646`) — no collection means no query at all |
| Must the default be permission-guarded inside the resolver? | Answered structurally | A disabled option cannot be selected; see LD-004 |
| Should the ticket be re-estimated? | Not a Phase 3 decision | Deferred to Phase 4 by process |

## Locked decisions

| ID | Decision | Source | Supersedes / rejects | Spec destination |
| --- | --- | --- | --- | --- |
| **LD-001** | Implement the drag-and-drop acceptance criterion; do **not** revise it to match current behavior. The criterion defines required future behavior. | User, 2026-09-03 (review 1) | Rejects: revising the AC so the default applies only where the track is already known | §3 Generic drag-and-drop |
| **LD-002** | Generic DnD gains a **dedicated track control**, not selectable group headers. | User direction + review 3 | Rejects: making `groupHeader` rows selectable (overloads a structural row and changes an existing element's meaning) | §3, §4.1 |
| **LD-003** | Generic DnD is identified by **`mode === 'upload' && lockedTrackTypeId == null && initialTrackTypeId == null`**. **No fourth form mode is added.** | Review 3, **amended at Phase 5** against implementation evidence | Rejects: a new `DeliverableFileUploadFormMode` value. **Supersedes** the original two-part condition (`mode` + `lockedTrackTypeId` only), which was insufficient — see the amendment note below | §4.1, §4.5 |
| **LD-004** | Unpermitted tracks are **shown, disabled, with the existing `noTrackPermission` tooltip** — not hidden. | User, 2026-09-03 (Phase 3) | **Supersedes** the Phase 1 plan's "permitted tracks only" wording. Precedent: `useTrackSelectorForm.ts:53-63` and `TrackSelectorForm.vue:118-129` both disable rather than omit, sharing the i18n key `common.callisto.dragDrop.noTrackPermission` already used by `DeliverableFileUploadTrackSelectField.vue:23` | §4.2, §6 |
| **LD-005** | A defaulted collection is **immediately a valid selection**. The user need not open, focus, or acknowledge the collection field before submitting. No `hasAcknowledgedDefault` state is introduced. Existing validation still applies — e.g. an unresolved deliverable type must still be chosen before submit enables. | User, 2026-09-03 (Phase 3) | Rejects: requiring explicit acknowledgement of a defaulted value | §3, §5 |
| **LD-006** | Resolver precedence is **explicitly ordered** (five steps, §4.3). A mapped-but-absent collection returns `null` and must **not** fall through to the singleton fallback. | Review 3 | Rejects: leaving order implicit — which would auto-select a *different* static collection when the mapped one is missing, contradicting the AC | §4.3 |
| **LD-007** | The recategorize guard covers **both** the new mapping **and** the pre-existing singleton fallback, and must **not** blanket-return `null` — collectionless tracks keep their `t-<id>-none` sentinel. | Review 2 + review 3 | Rejects: guarding only the new code; rejects a blanket recategorize short-circuit that would break Exhibits/MVC | §4.3, §4.4 |
| **LD-008** | The recategorize singleton auto-select is fixed **in this ticket** and attributed in the PR as a **pre-existing defect**, not a regression introduced here. | Review 2, accepted | Rejects: deferring it to a follow-up (same guard, one extra condition and test) | §4.4, §8 |
| **LD-009** | The reset/default transition fires on the **mutable DnD track change only**. Locked-track flows keep their existing initialization; recategorize never runs it. | Review 3 | **Supersedes** the earlier "watch the effective selected track including `lockedTrackTypeId`" wording, which added ordering risk for no behavioral gain | §4.5 |
| **LD-010** | A manual override is preserved **only while the track is unchanged**. A deliberate track change is a reset, not an override to protect. | Review 2 | Rejects: treating the existing "never overwrite a user's choice" backfill guard as absolute | §4.5 |
| **LD-011** | The mapping lives in a **new, separately-named front-end constant**. It must not reuse or be merged with `fileTypeLabel.ts`'s MIME-label map, which coincidentally contains the string `'MP4 Video'`. | Phase 1 (F1a) | Rejects: consolidating the two same-string maps | §4.2, concern C1 |
| **LD-012** | Matching is by **collection `value` string** within the track's own `staticCollections`. | Phase 1 (F7a) | Forced, not chosen: the API omits `collection_kind` (`fetch-deliverable-collections.response.dto.ts`), and `Redacted`/`MPEG Video` are also static, so a kind flag would not identify the winner anyway | §4.2, concern C2 |
| **LD-013** | Front-end only. No backend change, no new endpoint, no DTM configuration. | Ticket (Option A), confirmed by Phase 1 | Rejects: backend- or DTM-configured defaults | §1, §7 |
| ~~**LD-014**~~ | ~~The visual "this was defaulted" indicator is **out of scope**, tracked as job story 02.~~ **Superseded by LD-016.** The constraint it carried — the indicator must not affect validity or submission — survives and is restated there. | User, 2026-09-02 and 2026-09-03 | — | — |
| **LD-016** | The indicator **is in scope** and ships with this ticket: a **badge**, shown **only until the user changes the collection**. Closed field carries an emphasised pill; menu rows carry a quiet marker on the base-case collection. Recategorize shows neither. It must **not** affect validity or submission (carried forward from LD-014). | **Product (Ops) decision relayed by the user, 2026-09-08**, with a Figma mockup. Supersedes LD-014 | Rejects: deferring the indicator to a later ticket; rejects an always-on marker independent of selection history (the changelog's Plan B) | §3, §4.7 |
| **LD-015** | A **component-level spec** for `DeliverableFileUploadForm.vue` is part of this ticket's definition of done, covering the DnD interaction end to end. | Review 2 | Rejects: composable-only coverage — the component has no spec today, which is why the DnD gap was invisible | §8, test plan |

## Amendments

A locked decision changes only on the record. Two have.

### LD-014 — superseded 2026-09-08 by LD-016 (Product decision)

**Was:** the visual "this was defaulted" indicator is out of scope, tracked as job story 02.
**Now:** in scope, shipping with this ticket — see LD-016.

**Why it changed.** LD-014 recorded scope, not a preference: the indicator was excluded *because Product had agreed in principle but named no mechanism*, and story 02's criteria could not be made falsifiable without one. On 2026-09-08 Ops supplied the mechanism — *"I like badge and only until changed"* — relayed by the user with a Figma mockup. The reason for the exclusion no longer held.

**What "only until changed" resolves.** It selects **Plan A** from the ticket changelog (a session-scoped marker that clears on a deliberate selection) over **Plan B** (an always-on property of the option). Both had sat as `active` candidates since 2026-09-02 with neither confirmed.

**What survived unchanged.** LD-014's constraint that the indicator must not affect validity or submission. It is restated in LD-016 rather than dropped, because it interacts with LD-005 — a defaulted collection is already immediately valid, and the badge communicates provenance only.

**Process note.** The implementation landed before this record was updated; a reviewer correctly flagged the code as contradicting the approved scope. The decision existed, the record did not. Corrected here, in story 02, and in the repository spec.

### LD-003 — amended 2026-09-03 (Phase 5, implementation evidence)

**Was:** `mode === 'upload' && lockedTrackTypeId == null`
**Now:** `mode === 'upload' && lockedTrackTypeId == null && initialTrackTypeId == null`

**Why it changed.** The two-part condition is wrong, and the code proved it within minutes of being written. Direct per-track upload supplies `initialTrackTypeId` **without necessarily locking it** — `resolvedLockedTrackTypeId` returns `props.lockedTrackTypeId ?? null` while `resolvedInitialTrackTypeId` falls through to `props.initialTrackTypeId`, so the two are independent. A check on `lockedTrackTypeId` alone therefore classified those calls as generic drag-and-drop and discarded the track the caller had supplied.

**How it surfaced.** Implementing the two-part form failed **12 existing tests** in `useDeliverableFileUploadForm.spec.ts`, including four asserting the collectionless-track sentinel (`t-4-none`, Exhibits) and the single-static-collection auto-select. Correcting to the three-part condition took the same suite to 85/85.

**Why the reviews missed it.** All three Phase 1–3 reviews reasoned about the discriminator from the *component's* mount sites, where generic DnD does pass `locked-track-type-id="dndInitialTrackTypeId"` as `null`. The insufficiency only appears from inside the composable, where `initialTrackTypeId` is a separate parameter that direct upload also populates. Reading the call sites was not enough; running the code was.

**Where corrected:** spec §4.5 (both the identifier line and a note stating all three conditions are required), this ledger, and the implementation. The distinguishing fact is now stated positively — generic drag-and-drop is the only flow where the caller supplies **no track at all**.

**Nothing else in LD-003 changed:** no new form-mode value is introduced, and the alternative of adding one stays rejected.

## Risk-accepted decisions

One decision accepts a residual risk and therefore carries a concern entry.

| ID | Risk accepted | Concern |
| --- | --- | --- |
| **LD-012** | Matching on a display string means a production rename of `Full Transcript` or `MP4 Video` silently disables the default — no error, no failing test, because the AC's graceful fallback makes it fail *quietly* by design. | [C2](../PRDV-16461-future-development-concerns.md#c2--the-collections-api-omits-collection_kind-forcing-string-matching) |
| **LD-011** | The mapping constant and the MIME-label map share a string. A future reader may still conflate them. | [C1](../PRDV-16461-future-development-concerns.md#c1--mp4-video-is-also-a-mime-type-display-label-name-collision) |
| **LD-015** | Only the new interaction gets component coverage; the form's pre-existing modes stay uncovered at the component boundary. | [C3](../PRDV-16461-future-development-concerns.md#c3--deliverablefileuploadformvue-has-no-spec-and-that-is-why-this-gap-was-invisible) |
