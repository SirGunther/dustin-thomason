# Why these changes — atlas/focus-proceeding-name-on-create (PRDV-14184)

> The living "Why" of this ticket. Created Phase 1, updated every phase, finalized at close. High-level — scenarios live in the testing-implementation doc; point-in-time classification lives in the investigation report.

## Problem class (the core — what are we actually solving?)

**A capability gap — a missing UI affordance.** Nothing is broken and nothing regressed: the Proceeding create surfaces simply never implemented keyboard focus on the name input. Every time an Ops user creates a proceeding they pay an extra click that the interface could have spent for them, and they pay it again for each additional proceeding in the same sitting.

The request's own framing ("I want the focus to be on the Proceeding Name field after Create") assumes this class, and recon confirmed it — no reclassification. See the investigation report §1/§2.

The reusable wedge underneath both acceptance criteria: *when a user asks for an empty proceeding-name field — by opening a create surface or adding another row — that field takes focus.*

> **Revised 2026-09-13 (review round 2).** This wedge originally read "when a container … **becomes visible**." That framing was the source of two wrong turns: it made visibility the trigger, which on S2 is an unbounded set of ancestor gates, and it implied focusing during navigation. The wedge is now stated in terms of the **user's request**, which is both narrower and stable. See the Phase 3 round-2 why-log entry.

## The code at the root (what/where is the problem)

Not one defect but **two matching absences**, plus one container behavior that makes the obvious fix wrong:

- `src/callisto/pages/JobProceedingPages/JobDetailPage/components/NewProceedingsOverlay/NewProceedingsOverlay.vue` — the `q-input` at L147-159 carries no `ref` and no `autofocus`; rows are appended by `addProceeding()` L93-98.
- `src/callisto/pages/JobSubmissionPages/sections/FileUploadSection/AddProceedingForm/AddProceedingForm.vue` — the `q-input` at L138-151, same absence; rows appended by `addProceedingField()` L86-91.
- `src/globalComponents/Overlay/Overlay.vue` — hides with **`v-show`** (L80, L92), and `AddNewProceeding.vue:53-57` mounts the overlay with **no `v-if`**. This is why the root cause is not simply "nobody typed `autofocus`": on that surface the attribute would fire once at page load into a hidden field and never again.

Full root-cause trace: investigation report §5.

## The problems we're solving

1. **Creating a proceeding costs an extra click** before the user can begin typing its name (AC-1).
2. **Adding each additional proceeding costs the same extra click** again (AC-2).
3. **Underneath both:** the same affordance is missing in two independently-written surfaces that duplicate each other's validation and repeater logic — so the gap was always going to be fixed twice or half-fixed once.

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-09-11 — [NEW UNDERSTANDING]

- **Obvious:** the ask is a one-line `autofocus` on a text input. The repo already does exactly that in 7 places, including a proceeding **rename** dialog (`RenameDialog.vue:80`), so there is a ready-made precedent to copy.
- **Not obvious (the finding that justified investigating at all):** that precedent does **not** transfer to the main create surface. `RenameDialog` works only because it lives inside a lazily-mounted `q-dialog`; `NewProceedingsOverlay` lives inside a custom `Overlay` that hides with `v-show` and is mounted unconditionally, so its input mounts **once, hidden, at Job Detail page load** and never remounts when the overlay opens. Copying the precedent would produce a fix that works on the job-submission surface and silently does nothing on the job-detail one — passing a casual manual check on whichever surface the tester happened to open.
- **Also not obvious:** there are exactly **two** surfaces, not one. AC-1 and AC-2 are not two components; each surface has both moments (an initial `ref([''])` row and a `push('')` append). So "both criteria" and "both surfaces" are independent axes — four moments in total.
- **Assumptions logged:** (a) with index-keyed `v-for`, an *appended* row does mount a fresh `QInput`, so Quasar's `autofocus` would fire on append — recorded because the two recon passes disagreed about it, and resolved in favor of "it fires"; it does not change the recommendation, since the imperative approach is correct on both surfaces regardless. (b) `nextTick` may not be sufficient for the overlay case given the running `<Transition>` and `v-show`; the repo's own precedent (`SearchBar.vue:53-63`) defers with `setTimeout`. To be settled by browser observation under the browser-loop guardrails, not by tuning.
- **What got us toward the solution:** Quasar's `QInput` exposes `focus()` and `nativeEl` alongside the `autofocus` prop, and the repo already has a callback-ref-into-a-map idiom for per-row refs (`CaseFilesTable.vue:413`). An event-driven imperative focus therefore needs no new abstraction and works identically on both surfaces.
- **What was noise:** `callisto-back-end`, named in the ticket's repository scope. The proceeding name is client-supplied on both create DTOs with no server-side default, so there is no backend contract to change. Ruled out on evidence rather than assumption.
- **What this ruled out as a non-question:** whether "highlighted" means *select the existing text*. It cannot — new rows are always empty strings and no default name is ever generated.

### Phase 2 — 2026-09-11 — [COURSE CHANGE — a claim I made was refuted]

- **What changed after learning more:** while writing up the adjacent issues, I asserted that the proceedings uniqueness constraint was case-insensitive (on the strength of its name, `UQ_proceeding_value_per_job_case_insensitive`) and therefore that the overlay's case-sensitive duplicate check was the one out of step. Reading migration `1766801287907` **refuted it**: the constraint is a plain `UNIQUE ("value", "job_id")` — case-**sensitive** — and the sibling `records` table implements real case-insensitivity correctly eight timestamps earlier. The conclusion reverses: the overlay agrees with the database, and the job-submission form is stricter than it. Corrected in report §7 and coverage-ledger area 9, and raised in [future-development-concerns](./PRDV-14184-future-development-concerns.md).
- **Why this changes the solution:** it does not — the focus change is untouched by any of it. What it changes is the **scope discipline**: this is now a known, documented latent defect sitting in the exact files this ticket edits, which makes it tempting to "just fix while I'm in there." It stays out. Folding a validation behavior change into a focus ticket would make the diff un-reviewable against the acceptance criteria.
- **What was noise:** nothing new this phase.
- **Worth keeping as a lesson:** a constraint **name** is not evidence of what the constraint does. The only thing that settled it was reading the migration.

### Phase 3 — 2026-09-11 — [NEW UNDERSTANDING — a deferred risk closed early]

- **What changed after learning more:** Phase 2 left assumption **A5** open — whether `nextTick` is sufficient deferral through the overlay's `v-show` + `<Transition>`, or whether the repo's `setTimeout` precedent is needed — and routed it to browser observation. It closed here instead, on source evidence: `Overlay.module.scss:18-36` animates the **panel** by `transform` only (the *backdrop* is what fades, and holds no inputs), so the panel is focusable from the first frame; and Vue's `vShow.updated` clears `display` synchronously in a post-render hook that flushes before `nextTick` resolves. **LD-006** supersedes A5. This matters because it keeps a tuned magic delay out of the diff entirely.
- **What we learned that we did not expect:** the test harness could have hidden the whole feature failing. The existing S1 spec stubs `q-input` with a bare `div`+`input` that has **no `focus()` method**, so production code calling `proceedingInputs[i]?.focus()` would have silently no-opped and the test would have **passed while proving nothing**. Hence LD-005 — mount real Quasar rather than teach the fake to succeed. A related find: one existing test in that spec has been passing for the wrong reason (`setValue('')` on an already-empty input, which real Quasar short-circuits and the stub did not).
- **The honest limit we are shipping with:** happy-dom never evaluates `display` or `visibility` in `focus()`, so **no unit test in this repo can catch the exact `display:none` no-op** that S1's container makes possible. That is why the manual browser pass is written into the test plan as a merge gate rather than a nicety.
- **What was noise:** the four questions drafted for grill-me. Three were answerable from artifacts I already had (the criteria, the repo rules, and the user's own standing test obligations), and one — the coverage-depth question — was governed by a rule before it was ever drafted. Escalating them would have spent the reviewer's attention on work already done. Recorded because the failure pattern is worth not repeating: *wanting confirmation* was being treated as *requiring a decision-maker*.
- **Code change + why:** none yet; no product code is written in Phase 3.

### Phase 3 — 2026-09-13 — [COURSE CHANGE — spec review found a real hole and four errors]

The spec went out for review on PR #572 and came back **not approved as written**. The technical direction held; the details did not. Logged in full because the pattern matters more than the individual fixes.

- **The one that changes the design (P2):** S2's AC-1 trigger was wrong. I hung focus on the **Add Proceeding click**, but the rows are gated by *two* independent conditions — `v-if="editing"` on the wrapper and `v-if="showAddForm"` on the card. A user can open the form, leave editing mode, and re-enter: the subtree remounts with `showAddForm` still `true`, so the inputs reappear **with no click and no focus**. The trigger is now a `watch` on `props.editing && showAddForm.value` (LD-009), which covers both paths with one condition and makes S2 structurally symmetric with S1. **Why I missed it:** I read `AddProceedingForm.vue` for where rows are *created* and treated `v-if="editing"` as an outer wrapper rather than as a second visibility gate whose prop can change at runtime. I never traced `editing` back to `FileUploadSectionCore.vue:308` to ask whether it moves. It does.
- **The one I should not have written (P2):** I claimed focus "runs only after a container the user was already permitted to open has opened." False. `AddNewProceeding.vue` binds its `disabled` computed to `:class` only (L46) — never to the button's `disable` prop — and the click handler checks `canCreateProceedings` alone (L48), so `hasRestrictionActionAccess` governs styling and nothing else. I asserted a security property from the *existence* of a computed rather than from its *binding*. Now corrected in the spec and raised as Concern 4; **not fixed here**, because a focus ticket is the wrong vehicle for changing an authorization gate.
- **Two factual errors (P3):** I said the S1 spec had 9 tests; it has **14** (counted on the base commit, both files unchanged). And the justification for using a plain array — that Vue would proxy component public instances stored in a deep `ref` — is simply **wrong**: `PublicInstanceProxyHandlers.get` returns `true` for `__v_skip` (`runtime-core.cjs.js:3282-3283`), so `reactive()` skips them. The plain array stays because nothing renders from it; the bogus rationale is gone.
- **The structural one (P1):** the spec declared private, unreachable files authoritative. A reviewer on the PR could not open the investigation, the locked decisions, or the job story, which made the acceptance criteria unverifiable from the PR itself. The criteria are now reproduced verbatim **in** the spec, and the private artifacts are demoted to a provenance footnote. **The lesson generalizes:** an artifact's audience determines what it may cite. Everything the orchestration produced lives in a repo the reviewer has no access to, and I linked to it as though the reviewer shared my filesystem.
- **What was noise:** nothing. Every finding was valid and I verified each against the code rather than accepting it — including the `__v_skip` claim, which is the one I would have been most tempted to defend, since it came from my own design pass.

### Phase 3 — 2026-09-13 — [COURSE CHANGE — the scope argument was invalid, and I defended it once]

Review round 2. Five findings, all valid. Two matter beyond their fixes.

**1. The scope reasoning was a logical error, and I had already been challenged on it.** I argued that because neither acceptance criterion names a screen, both surfaces are *logically mandated* — that shipping one would require "rewriting the criteria." That does not follow. Screen-neutral wording is simply how criteria are written; silence about screens is not an assertion of universality. **I treated the absence of a constraint as the presence of its negation.**

What makes this worse than a reasoning slip: the ticket **demonstrably carries UI context nobody has read**, and I recorded it myself at Phase 0. The capture notes a comment from Kat Giangiulio (10:23 am) with "1 attachment/media item(s) omitted" — exactly where a screenshot establishes which screen. I had that fact in my own artifact and built an argument from the text's silence anyway.

And earlier in this ticket the user asked me directly whether a second party was genuinely required, or whether I simply had not reasoned it through. I answered that no second party was needed and that the criteria settled it. **That answer was wrong.** The scope question is now reopened with Product as owner (LD-012), story 01 is retired to `dnu/`, and story 02 carries the question. The lesson is not "ask more" — the earlier critique was right that three of four questions were mine to close. It is narrower: *a question is only closed by evidence when the evidence is complete, and I knew mine was not.*

**2. Chasing visibility was the wrong shape of fix.** Round 1 found that S2's click-based trigger missed the editing re-entry path, and I widened the trigger to watch `editing && showAddForm`. Round 2 showed the chain is longer and route-dependent — `v-show="currentStep === 5"` on Pending, `v-if="form"` on Submitted, above the two gates I already knew about. Widening again would have been the third guess at an unbounded set. The stable rule is **focus follows the user asking for an empty field, not visibility** (LD-011): opening the create surface and appending a row. Under it, round 1's "hole" is correct behavior — returning to a form you left open should *not* grab focus, because that is focus-stealing during navigation. The test plan now asserts the absence rather than leaving it unstated.

**3. Three smaller corrections.** The spec claimed to be self-contained while its backend claims cite `callisto-back-end`, which no reviewer on this PR can open — now labelled background, not verified here. Test cleanup cleared `document.body.innerHTML` without unmounting wrappers, leaving instances and watchers alive between tests — now `wrapper.unmount()` first. Frontmatter still said `modified: 2026-09-11` after a material 09-13 change.

**What was noise:** nothing. Every finding held on verification.

## Changes made — categorized (filled as implementation locks; subject to update)

_Not yet — no code written. Populated at Phase 5._

## Why it shipped together

_Pending — written once the in-scope surfaces are locked at Phase 3._

## Scope

Front-end only, confined to the Proceeding create surfaces in `atlas-front-end`. `callisto-back-end` carries no change (see report §5 contract alignment). Whether both surfaces ship together is an open decision for Phase 3.

## Net

_Pending close._

## Verified

_Pending — gates and manual browser evidence land at Phase 5._
