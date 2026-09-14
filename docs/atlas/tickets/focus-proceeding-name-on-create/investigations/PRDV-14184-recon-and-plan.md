# PRDV-14184 — Recon and plan (orchestrate Phase 1)

## Context

**Why this ticket exists.** An Ops Atlas user creating a Proceeding has to click twice before they can type its name: once on the "add new" control, then again into the text box. The ticket asks for the Proceeding Name input to already hold keyboard focus, in two moments — when a new Proceeding is created, and when an additional proceeding is added.

**What this plan is.** This is orchestrate **Phase 1 (Recon and plan)** — the looking is already done. Approving this approves a set of *findings* plus the plan to write them down. It is **not** the implementation design; the spec and the locked decisions are Phase 3, and the implementation plan is Phase 4. This document is saved verbatim as `investigations/PRDV-14184-recon-and-plan.md` at Phase 2's first action and frozen thereafter.

**Ticket artifacts:** `C:\dustin-thomason\docs\atlas\tickets\focus-proceeding-name-on-create\`
**Repos:** `atlas-front-end` (the change) · `callisto-back-end` (named in ticket scope; recon says **not touched** — see F5)

---

## Findings

### F1 — Problem class: a missing UI affordance, not a defect

Nothing is broken. No code sets focus and none ever did; the create surfaces simply never implemented the affordance. Class = **capability gap (UX affordance)**, matching the request's own framing. No reclassification.

The wedge is narrow and reusable: *"when a container presenting an empty name input becomes visible, or a new empty row is appended, that input takes focus."* Both acceptance criteria are instances of it.

### F2 — Exactly two surfaces render an empty Proceeding Name input

Completeness established by grep of the two i18n keys that label a proceeding-name input across all `*.vue` in `src/` — exactly 2 hits; corroborated by `proceedings.push`/`addProceeding`/`createProceeding` greps returning only these files, and by confirming all proceeding UI lives under `src/callisto`.

| # | Surface | File | Container visibility | Name input |
| --- | --- | --- | --- | --- |
| S1 | "New Proceeding" overlay (Job Detail page) | `src/callisto/pages/JobProceedingPages/JobDetailPage/components/NewProceedingsOverlay/NewProceedingsOverlay.vue` | `v-show` (stays mounted) | `q-input` L147–159 |
| S2 | "Add Proceeding" inline form (Job Submission) | `src/callisto/pages/JobSubmissionPages/sections/FileUploadSection/AddProceedingForm/AddProceedingForm.vue` | `v-if="showAddForm"` (mounts on reveal) | `q-input` L138–151 |

S2 reaches users on **two routes** — `PendingFileUploadSection.vue:179` and `SubmittedFileUploadSection.vue:159` — both rendering the same `FileUploadSectionCore.vue:307-311`.

Both are the **same repeater shape**: index 0 comes from `ref([''])`; later rows from a `push('')` handler (`NewProceedingsOverlay.vue:93-98`, `AddProceedingForm.vue:86-91`). So **AC-1 = focus row 0 when the container becomes visible**, **AC-2 = focus the appended row**. Both use raw `<q-input>` with **no ref and no autofocus**, and both key the `v-for` by **positional index**.

### F3 — S1 and S2 fail a naive fix differently (the load-bearing finding)

`Overlay.vue` hides with **`v-show`** (L80, L92) and `AddNewProceeding.vue:53-57` mounts `NewProceedingsOverlay` with **no `v-if`**. So S1's row-0 input mounts **once, at Job Detail page load, while hidden**, and is never remounted on open/close — `resetProceedings()` (L107-110) only reassigns the string array.

Consequence: a plain `autofocus` attribute on S1 fires **once at page load into a hidden field** and **never on overlay open**. On S2 it would work, because `v-if` mounts the card fresh. A fix that copies the `RenameDialog.vue:80` precedent therefore half-lands — and `RenameDialog` only works because it sits inside a lazily-mounted `q-dialog`.

> **Recon conflict, resolved.** One recon pass claimed `autofocus` cannot fire for appended rows under index keys. That is **incorrect for an append**: keys `0..n-1` are patched and reused, key `n` is new, so Vue mounts a fresh `QInput` and Quasar's `autofocus` runs in `onMounted`. The real disqualifier for S1 is the `v-show` container above, not the key strategy. Recorded as an assumption to confirm with the red→green test (it does not change the recommendation, since the imperative approach is correct either way).

### F4 — No focus utility exists to reuse; the idiom is Quasar-native

- **No** focus directive, **no** focus composable, **no** `directives/` folder, **no** shared text-input wrapper. `<q-input>` is used raw in 24 files. `@vueuse/core` is installed and `useFocus` is available but never used for this.
- Established idioms, both one-off: `autofocus` attribute (7 sites, all inside lazily-mounted dialogs) and template ref + `.focus()` (`MainLayout/SearchBar.vue:53-63` — note it defers with `setTimeout(...)`, and types the `q-input` ref as `HTMLElement`, a type lie that works because `QInput` exposes `focus()`).
- `QInput` (Quasar 2.18.6) exposes **`autofocus` prop**, **`focus()`**, **`select()`**, and **`nativeEl`**. A `ref` on `<q-input>` yields the component instance — `.focus()` on it is the supported route.
- Dynamic per-row refs have precedent as callback refs into a map: `CaseFilesTable.vue:413`, `ClientDeliverablesTable.vue:921-923`, `SubmissionFilesTable.vue:702-704`.

**Implication:** the change writes the first event-driven focus code on these surfaces. Whether to extract a shared helper across S1/S2 or inline it twice is a **Phase 3 decision**, not settled here.

### F5 — Contract alignment: callisto is out of scope

The proceeding name is the `value` column — required `varchar`, no DB default, unique per job (`proceeding.entity.ts:17,22-23`). Both create endpoints require **client-supplied** `values: string[]` (`create-proceedings.request.dto.ts:14-19`, `create-job-submission-proceedings.request.dto.ts:9-13`) and `CreateProceedingsTS.apply` maps them straight through with no defaulting. The name is typed in the UI *before* any request is sent.

So: **no server-generated default name exists**, and this change touches no HTTP contract, DTO, guard, or Swagger surface. `callisto-back-end` is named in the ticket's repository scope but recon finds nothing for it to do.

### F6 — Detection gap (why nothing caught it)

Not a regression, so nothing "missed" it — but the relevant gap for the *fix* is: **no spec in the entire repo asserts focus** (`toHaveFocus`/`activeElement` greps are empty across all `__specs__`). `@testing-library/jest-dom` is in devDependencies but never imported and not registered in `test/vitest/setup-file.ts`, so `toHaveFocus()` is **not currently available**. `AddProceedingForm.vue` has **no spec file at all**; `NewProceedingsOverlay.spec.ts` exists but **stubs `q-input`** with a bare div+input that drops `autofocus` and exposes no `focus()`.

This shapes the test work: the stub must be extended (or real Quasar mounted), and the assertion style — `document.activeElement` under happy-dom vs. importing jest-dom — is a decision with no precedent either way.

---

## Open questions reconciled (Step 7 — facts resolved, decisions isolated)

| Question | Type | Resolution |
| --- | --- | --- |
| Does "highlighted by default" mean focus, or focus **plus** selecting existing text? | **Fact — resolved** | Focus only. Every new row is an empty string (`ref([''])`, `push('')`) and F5 proves no server-side default name exists, so there is never text to select. Story open question closes. |
| Which entry points does "add an additional proceeding" cover? | **Fact — resolved** | Exactly the two surfaces in F2, each with an initial row and an append handler. |
| Are **both** surfaces in scope, or only the Job Detail overlay? | **Decision — stays open** | The ticket names the module ("Atlas Proceedings") but no surface. Owner: user/product. → Phase 3 grill-me. |
| Extract a shared focus helper across S1/S2, or inline twice? | **Decision — stays open** | No precedent either way (F4); two near-duplicate components. Owner: user/reviewer. → Phase 3. |
| Assert focus via `document.activeElement` or register `@testing-library/jest-dom`? | **Decision — stays open** | Registering jest-dom is a shared-config change (`setup-file.ts`) affecting every spec. Owner: user/reviewer. → Phase 3. |

Deferred-but-provable at implementation: whether `nextTick` is sufficient for S1 (the element leaves `display:none` in the same DOM update, but a `<Transition>` is also running, and `Overlay` emits `after-leave` but **no** `after-enter` hook to attach to). `SearchBar`'s precedent uses `setTimeout`. Resolve by browser observation under the browser-loop guardrails, not by tuning.

---

## Staged writes (materialize at Phase 2's first action)

**Coverage ledger** — `investigations/PRDV-14184-coverage-ledger.md`, baseline `atlas-front-end@420c395a` / `callisto-back-end@main`:

- `Consulted: docs/*/tickets/*/investigations/*-coverage-ledger.md for "proceeding" — found PRDV-16461/16313/16403/16192 ledgers, all covering proceeding *files*/deliverables/audit; none covers the proceeding **create** surface. No reuse available; no reopen needed.`
- Areas: S1 `NewProceedingsOverlay` + `Overlay`/`AddNewProceeding` mount chain (`contributing`) · S2 `AddProceedingForm` + `FileUploadSectionCore` mounts (`contributing`) · repo-wide focus-idiom sweep (`fully-inspected`) · Quasar `QInput` API (`fully-inspected`) · callisto create-proceeding path (`ruled-out`) · existing specs + test harness (`fully-inspected`).
- Frontier: `Overlay.vue` transition timing vs. focus; whether `FormField.vue`'s `$attrs` fallthrough is a third latent surface (checked — display-only, excluded).

**Why-log Phase 1 entry** — `PRDV-14184-why-these-changes.md` (created Phase 2): problem class = capability gap; code at the root = the two `q-input` blocks with no ref/autofocus plus `Overlay`'s `v-show`; obvious = "add autofocus"; **not obvious** = that the one-line fix works on S2 and silently fails on S1; noise = the callisto repo scope.

**Job-story reconcile** — close both of story 01's open questions against the facts above; add a Phase 1 Story log entry; story stays `draft` (the in-scope-surfaces decision is still open).

---

## Phase 2 emission todos (what approving this authorizes)

1. Save this plan verbatim → `investigations/PRDV-14184-recon-and-plan.md`; update ledger (P1 `done`, P2 `in-progress`); fire deferred P1 notification.
2. Create `PRDV-14184-why-these-changes.md` with the Phase 1 why-log entry.
3. Apply the staged job-story reconcile + Story log entry.
4. Write `investigations/PRDV-14184-investigation.md` from the investigation-report template, reconciled against every point of the software lens (contract alignment F5, surface enumeration F2, protect-the-neighbors, detection gap F6, red→green test, repro recipe).
5. Materialize `investigations/PRDV-14184-coverage-ledger.md` (Consulted line first, then areas, then frontier).
6. Produce `investigations/PRDV-14184-diagrams.md` — current-vs-target for both surfaces; N/A lines for kinds skipped.
7. Seed `testing/PRDV-14184-test-plan.md` from report §9, each scenario naming the criterion it exercises.
8. Stage `PRDV-14184-pr-draft.md` — **shell only**, headings and empty placeholders.
9. Changelog session log entry; then auto-advance to Phase 3.

**Not in this phase:** no product code, no spec, no locked decisions, no branch. Nothing in `atlas-front-end` or `callisto-back-end` is modified.

---

## Verification

Phase 1 has no runtime artifact to verify. What proves this recon is sound, checkable now:

- **Surface completeness** — re-run the i18n-key grep for `enterProceedingName|enterNewProceedingName` across `src/**/*.vue`; must return exactly the two files in F2.
- **S1's mount claim** — `Overlay.vue:80,92` use `v-show`; `AddNewProceeding.vue:53-57` has no `v-if`. Both readable now.
- **Backend non-involvement** — both create DTOs require `values: string[]`; `CreateProceedingsTS.apply` has no defaulting branch.
- **Detection gap** — `grep -ri "toHaveFocus\|activeElement" src/**/__specs__/` returns nothing; `test/vitest/setup-file.ts` registers no matchers.

The behavioral proof (focus actually lands in both surfaces, on both AC moments, in a real browser) belongs to Phase 5 under the browser-loop guardrails, against the Phase 3 test plan.
