# Why these changes — atlas/PRDV-16461

> The living "Why" of this ticket. Created Phase 1, updated every phase, finalized at close. High-level — scenarios live in the testing-implementation doc; point-in-time classification lives in the investigation report.

## Problem class (the core — what are we actually solving?)

**A default that already exists in the code but never fires, because its trigger condition is too narrow — compounded by a flow that has no moment for it to fire at.**

This is not "add a defaulting feature." The upload form already auto-selects a collection when a track has exactly one non-dynamic option. The two tracks users care about each have two static collections, so the rule silently declines every time. The ticket's request is to name a winner when there is more than one candidate.

The second half of the class emerged only under review: in generic drag-and-drop there is no track-selection event at all, so even a correct mapping has nothing to react to. A default needs both a *rule* and a *moment*. This ticket supplies both.

## The code at the root (what/where is the problem)

`atlas-front-end/src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/composables/useDeliverableFileUploadForm.ts`

- **`resolveInitialPickValue()` (`:386-415`)** — the sole initial-selection writer. Its terminal branch (`:407-414`) returns `null` unless exactly one non-dynamic pick matches the track. This is why nothing pre-selects for Transcript or Video today.
- **Its two callers (`:419-440`)** — watchers on `isOpen` and `trackCollectionOptions`. Neither reacts to a track change, which is why selected-track state alone would produce nothing.
- **`buildPickOptions()` (`:162-173`)** — emits track group headers as `disable: true`, so a track is not selectable on its own. This is the structural reason generic DnD has no track-selection moment.

Full trace: investigation report §5.

## The problems we're solving

1. **Ops users set the same collection by hand on nearly every file.** Transcript files belong in Full Transcript; Video files in MP4 Video. The system knows the track and could know the collection, and doesn't say so.
2. **Generic drag-and-drop has no track-selection state**, so the pre-selection the AC asks for has no trigger. (Surfaced at review, not at first read.)
3. **A pre-selected value is indistinguishable from a chosen one.** Split out as job story 02 — agreed in principle by Product, mechanism unnamed, explicitly deferred to just before implementation and not gating this work.

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-09-03

- **Obvious:** the ticket reads as "add a track → collection mapping." Front-end only, no backend, Option A as written.
- **Not obvious (the reframing):** the mapping rule already exists at `:407-414` and only declines because both target tracks have two statics. The work widens an existing rule rather than adding a new one — which changes how a reviewer should read the diff, and means the `matches.length === 1` fallback must survive for other tracks.
- **Not obvious (resolved by evidence):** the ticket flagged that `Full Transcript` / `MP4 Video` "appear only in test fixtures." Both are seeded production rows with `collection_kind = 'static'` and eligible types configured (Callisto migrations `1775761245238`, `1782200000003`). Right about Atlas, wrong about the system — Atlas correctly hardcodes nothing. Both of the ticket's stated open items closed without asking anyone.
- **Not obvious (schema):** "static vs dynamic" is a real enforced concept (`collection_kind`, plus a `*DYNAMIC*` sentinel template row), and dynamic collections are structurally un-defaultable on three independent levels. Also: `Redacted` and `MPEG Video` are *also* static, so "pick the static one" would have been wrong.
- **Assumptions logged:** A1–A8 in the recon-and-plan's assumptions ledger. A3 (rows exist in every environment) is confirmed directionally only; the junction seed throws if either collection is missing, so any migrated environment necessarily has them.

### Phase 1 (review pass 1) — 2026-09-03 — [COURSE CHANGE]

- **What changed after learning more:** I claimed generic DnD needed no work, reasoning that choosing a track *is* choosing a collection in a combined picker. The code refutes it: the form opens with `lockedTrackTypeId = null`, `resolveInitialPickValue()` returns at its first line, and group headers are `disable: true`. **The headline AC was unmet by the plan.**
- **Why this changes the solution:** the ticket stops being a pure mapping change. Generic DnD needs an explicit track-selection state for the default to have a trigger.
- **Decision (user):** implement the AC, do not revise it to match current behavior. Bounded by an explicit out-of-scope list so it does not become a DnD redesign.
- **What was noise / discarded:** an earlier structural inference that recategorize was excluded "for free" by the mode shape. It is not — recategorize reaches the same branch when files have no collection or disagree, so an explicit guard is required.

### Phase 1 (review pass 2) — 2026-09-03 — [COURSE CHANGE]

- **What changed after learning more:** three defects in my own plan. (a) The reactive wiring was named but not specified — the existing watchers do not observe track changes, so "add selected-track state" would have produced nothing. (b) My test plan said the DnD spec at `:445` should "flip to a default" while my workflow section three pages earlier said DnD opens with *no* selection; the test asserts exactly the target state. (c) The recategorize guard covered only my new mapping, missing that the pre-existing singleton fallback also auto-selects on a one-static-collection track.
- **Why this changes the solution:** (c) makes part of this work a **pre-existing defect the ticket surfaces rather than causes** — worth saying plainly in the PR so it does not read as a regression introduced here.
- **What was noise / discarded:** my claim that defaulting would narrow a previously-broader type catalog. There is no broader catalog — no collection means no query at all. Downgraded from a gating risk to ordinary coverage.

### Phase 1 (review pass 3) — 2026-09-03 — [COURSE CHANGE]

- **What changed after learning more:** resolver precedence was unstated, and the omission hid a real bug. The singleton filter at `:407-412` admits any lone non-dynamic pick — including the `t-<id>-none` sentinel for collectionless tracks. Without an explicit order, a mapped track that had lost one of its two statics would auto-select the survivor, which is the exact opposite of the AC's "mapped-but-missing stays blank."
- **Why this changes the solution:** the spec now carries a five-step ordered resolution rule, with "return `null` rather than fall through" as the step that actually delivers that AC.
- **Also settled:** the DnD track selector exposes only tracks the user has CREATE permission on, which closes the permission question (A8) without any guard in the resolver; and `mode === 'upload' && lockedTrackTypeId == null` identifies generic DnD, closing F5a without a new form mode.
- **Narrowed:** the reset/default transition fires on the mutable DnD track change only. Locked flows (direct upload, approval) already initialize correctly through existing watchers; routing them through a new reset would add ordering risk for no gain.

### Phase 2 — 2026-09-03

- **Nothing moved.** Phase 2 emitted the report, coverage ledger, diagrams, test-plan seed and concerns from the Phase 1 findings as approved. No new understanding, no course change, no discarded path.
- **Method note (carried into the finalized review):** three review passes each found a real defect in Phase 1's output — an unmet AC, a self-contradicting test plan, and a resolver-ordering bug. The common cause in all three was asserting a structural conclusion without tracing the specific code path, then stating it with more confidence than the evidence supported. Recorded because the pattern is more useful to the next ticket than any individual fix.

### Phase 5 — 2026-09-03 — [COURSE CHANGE]

- **What changed after learning more:** the generic-drag-and-drop discriminator locked at Phase 3 (LD-003) was **insufficient**, and the code found it immediately. `mode === 'upload' && lockedTrackTypeId == null` misclassifies direct per-track upload, which supplies `initialTrackTypeId` without necessarily locking it. Twelve existing tests failed, four of them on the Exhibits/MVC collectionless sentinel — precisely the breakage the plan had flagged as the most likely way to get this wrong, arriving from an unexpected direction.
- **Code change + why:** the discriminator gained a third condition (`initialTrackTypeId == null`). Not a bug fix in product behavior — it is a **correction to a decision that was wrong on paper**, caught before it could ship.
- **Why this changes the solution:** it doesn't change *what* the feature does. It changes what the spec asserts, and that assertion was load-bearing for every downstream step that keys off "is this generic DnD."
- **What this says about the method:** all three Phase 1–3 reviews reasoned about the discriminator from the component's mount sites, where the two-part check *looks* correct because generic DnD does pass a null locked track. The insufficiency is only visible from inside the composable, where `initialTrackTypeId` is a separate parameter direct upload also fills. Three careful readings agreed on something one test run refuted. That is the argument for the spec-then-implement sequence, not against it: the cost of being wrong here was twenty minutes and an amended ledger row, rather than a shipped regression.
- **Not noise:** the failure was loud, specific, and pointed straight at the cause. A silent misclassification — defaulting the wrong collection rather than none — would have been far worse.

## Changes made — categorized (filled as implementation locks; subject to update)

> Populated at Phase 5. Anticipated shape from the approved plan — **not yet implemented, not yet verified.**

Anticipated count: 1 requested change · 1 capability gap · 1 bug fix

### Track → default collection mapping — requested change
- **Before:** _(to fill at Phase 5)_
- **After:** _(to fill)_
- **Why:** _(to fill)_

### Generic-DnD track-selection state — capability gap
- **Before:** _(to fill)_
- **After:** _(to fill)_
- **Why:** _(to fill)_

### Recategorize singleton auto-select — bug fix (pre-existing)
- **Before:** _(to fill)_
- **After:** _(to fill)_
- **Why:** _(to fill)_

## Why it shipped together

_(to fill at Phase 6, tied to the acceptance criteria)_

## Scope

**Confined to:** `atlas-front-end`, the deliverable file upload form and its composable. No backend change, no new endpoint, no DTM configuration — the collection catalog already carries everything needed on the wire.

**Explicitly not moving:** how the app decides whether the user chose the correct track; one-track-per-upload-batch behavior; file-type inference or validation; mixed-track batch support; drop locations or track-specific drop zones; post-upload track behavior; non-GCA upload behavior.

**Spun off:** job story 02 (visual indicator that a value was defaulted) — Product decision, deferred to just before implementation.

**Estimate risk:** the change exceeds a pure mapping. The 3-point sizing is revisited at Phase 4.

## Verified

_(to fill at Phase 6 — gates + PR link)_
