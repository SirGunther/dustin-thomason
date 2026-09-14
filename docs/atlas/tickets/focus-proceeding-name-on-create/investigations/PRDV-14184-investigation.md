# Investigation Report: Focus the Proceeding Name field on create

> **What this is:** the delivered results of running the `investigate` method — findings and recommendation, plus the plan for what happens next.
> **What this is not:** a plan *to* investigate. The investigating is done.

## Metadata
- **Status:** done
- **Disposition:** proceed with conditions
- **Date:** 2026-09-11
- **Owner:** Dustin Thomason
- **Location:** `docs/atlas/tickets/focus-proceeding-name-on-create/investigations/PRDV-14184-investigation.md`
- **Ticket:** [PRDV-14184](https://app.clickup.com/t/43227262/PRDV-14184)
- **Domain:** software (frontend)
- **References / evidence:** `atlas-front-end@420c395a`, `callisto-back-end@d84a4628`; [recon-and-plan](./PRDV-14184-recon-and-plan.md); [coverage ledger](./PRDV-14184-coverage-ledger.md); [diagrams](./PRDV-14184-diagrams.md); [job story 01](../stories/PRDV-14184-job-story-01-focus-name-field.md)

---

## 0. Verdict (bottom line up front)

Proceed. This is a small, genuinely low-risk front-end change — but **not the one-line change it looks like**, and that is the whole value of having investigated. The obvious fix (add Quasar's `autofocus` attribute, copying the repo's seven existing precedents) works on one of the two create surfaces and silently does nothing on the other, because `NewProceedingsOverlay` lives inside a custom `Overlay` that hides with `v-show` and is mounted unconditionally — its input mounts once, hidden, at Job Detail page load, and never remounts when the overlay opens. The durable fix is an **event-driven imperative focus** (`ref` + `QInput.focus()`) fired from the two moments that already exist in code on both surfaces: the container becoming visible, and a row being appended.

- **Strongest path:** imperative focus on a collected per-row ref, applied uniformly to both surfaces, with the focus assertion carried by new specs — and confirmed by real browser observation before it ships, because focus landing correctly through a `v-show` + `<Transition>` is precisely the kind of thing a jsdom/happy-dom test can assert while the real UI still fails.
- **Not yet proven / not approved:** (a) **scope** — whether both surfaces ship under this ticket is an open product decision, not a fact; (b) whether `nextTick` alone is sufficient deferral on the overlay surface, or the repo's `setTimeout` precedent is needed; (c) the spec-level assertion mechanism, which has **no precedent anywhere in the repo**. None of the three blocks starting; all three must close before merge.

## 1. Problem class

- **Class the request assumed:** a missing UI affordance — the interface doesn't put the cursor where the user is obviously about to type.
- **Confirmed class:** **capability gap (UX affordance)** — same as assumed. Derived from the instances in §2 and re-checked against root cause in §5.
- **Reframed?** **No** — and the justification matters rather than being a formality. Three competing classes were tested and rejected: it is **not a defect** (no code ever set focus; nothing regressed — `git log -i --grep=focus` surfaces no prior attempt); it is **not a contract/permissions problem** (the name never crosses a trust boundary before the user types it — §5); and it is **not a knowledge/discoverability problem** (users find the control fine, they just pay an extra click after finding it). The request's framing survived contact with the evidence.
- **What the confirmed class implies:** the solution space is **entirely client-side presentation**. No DTO, no guard, no migration, no API contract. It also implies the bar for "done" is *observable behavior in a browser*, not a passing unit test — which is what drives the conditions in §0.

## 2. Problem statement (the raw facts)

- **Named instances:** Ops Atlas users creating proceedings — the requesting stakeholder is **Ops** (ticket field *Primary Stakeholder: Ops*, *Owning Team: NASA*, *Modules: Atlas Proceedings*). The ticket is written first-person by an Ops user describing their own repeated task. **Caveat, stated plainly:** no individual person is named and no specific blocked task is cited. By the method's own standard ("no named instance = no confirmed problem; say so") this is a **role-level instance, not a named one** — sufficient for a UX affordance whose cost is measured in clicks, and it would not be sufficient for a defect claim.
- **One sentence:** *Creating a proceeding in Atlas requires a second click into the name box before the user can type its name.*
- **Distinct problems:** (1) the extra click when the create surface first opens; (2) the extra click again for every additional proceeding added in the same sitting; (3) **underneath both** — the same affordance is missing in two independently-written surfaces that duplicate each other's repeater and validation logic, so the gap is structurally positioned to be half-fixed.
- **Urgency:** low and continuous, not event-triggered. It bites on every proceeding creation. The ticket carries *late sprint addition* and 1 sprint point, and status moved to **In Progress** on 2026-09-11; there is no external deadline forcing a date.
- **Wedge:** *when a container presenting an empty proceeding-name input becomes visible, or a new empty row is appended, that input takes focus.* Reusable because it is stated in terms of the two lifecycle moments that already exist in both components — not in terms of either component's specifics — so it transfers unchanged to any future proceeding-entry surface.

### Problem Check

- **Asked:** put keyboard focus on the Proceeding Name input at creation time — *evidence:* "I want the focus to be on the Proceeding Name field after Create".
- **Answered:** the same thing. No drift between what the ticket asks and what it works on — *evidence:* the AC restates the identical outcome, "the proceeding name field is highlighted by default so users don't have to first click into the field to begin typing".
- **Should-ask:** the asked question is the right one, but it is **under-specified in one respect the ticket never confronts**: *on which surface?* The request says "after Create" as though there were a single create flow; there are two (§5). That is the question that actually decides the size of this ticket.
- **Conflation:** **nothing here** — the two AC bullets are genuinely two moments of one behavior, not two problems wearing one name. Solving the first does not solve the second (they fire from different code paths), but neither can be solved without the other being trivially reachable — *evidence:* "When users create a new Proceeding …" vs "When uses add an additional proceeding, the following proceeding name field is also highlighted".
- **Thin:** **yes — one term.** "**highlighted by default**" is undefined and has two plausible readings in a text input: receives focus, or receives focus *and* selects its existing contents. Resolved by evidence in §8 (A1) rather than left thin — *evidence:* "the proceeding name field is **highlighted** by default".
- **Off:** **nothing here** — no internal contradiction. The one wobble is a typo, not a contradiction ("When **uses** add an additional proceeding"), and the sentence's meaning is unambiguous.

## 3. The contract

### Acceptance criteria

Source of truth is [job story 01](../stories/PRDV-14184-job-story-01-focus-name-field.md); the ticket's own AC is its input. Status is assessed against *what exists today*.

| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| AC-1 — Creating a new Proceeding leaves the user able to type the name immediately, with no extra click | gap | Focus row 0 when the create container becomes visible. Must be proven on **each** in-scope surface separately — the mechanism differs (§5) |
| AC-2 — Adding an additional proceeding leaves the user able to type that name immediately, with no extra click | gap | Focus the appended row after the `push('')` handler, once the DOM has it |
| (implicit) Neither behavior disturbs existing validation, duplicate detection, save/cancel, or row removal | needs-proof | Neighbor assertions per §9; these paths share the same components and must be shown unchanged |

### Non-goals / out of scope

- **Any backend change.** `callisto-back-end` is named in the ticket's repository scope but has nothing to do (§5, contract alignment). Explicitly recorded so the scope line isn't re-litigated.
- **Selecting or pre-filling text.** Ruled out on evidence (§8 A1), not preference.
- **Fixing the index-keyed `v-for`** in either component, or **de-duplicating** the two near-identical proceeding forms. Both are real and both are visible from here; both are §7 adjacent issues, not this ticket.
- **A repo-wide focus utility / design-system input wrapper.** Tempting given §5's finding that neither exists; overreach for two call sites (§7 Generalization).
- **Focus behavior on the proceeding *rename* flow**, which already works (`RenameDialog.vue:80`).

## 4. What changed since the request was created

- **Shifted from:** "add autofocus to the proceeding name field" → **to:** "fire focus from two lifecycle moments, on two surfaces, one of which cannot use the declarative attribute at all."
- **What that buys us:** it prevents the most likely failure mode of this ticket — shipping a change that demos correctly on whichever surface the tester opens first and does nothing on the other. It also converts a vague "highlighted" into a decided, evidence-backed meaning.
- **What it still needs to prove:** that the imperative focus actually lands through `v-show` + `<Transition>` in a real browser, and that the in-scope surface decision is made deliberately rather than by default.

## 5. Why it exists

- **Origin traced to:** not a regression — an **absence**. The affordance was never implemented on either create surface. Both `q-input`s were written without a `ref` and without `autofocus`:
  - `src/callisto/.../NewProceedingsOverlay/NewProceedingsOverlay.vue:147-159` (rows appended by `addProceeding()` `:93-98`; initial row from `ref([''])` `:29`)
  - `src/callisto/.../FileUploadSection/AddProceedingForm/AddProceedingForm.vue:138-151` (rows appended by `addProceedingField()` `:86-91`; initial row `:26`)

- **The structural reason the obvious fix fails (the load-bearing finding):** `src/globalComponents/Overlay/Overlay.vue` hides its content with **`v-show`** (`:80`, `:92`), and `AddNewProceeding.vue:53-57` mounts `NewProceedingsOverlay` with **no `v-if`**. So the overlay's row-0 input is mounted **once, at Job Detail page load, while hidden**, and is never remounted on open — `resetProceedings()` (`:107-110`) only reassigns the string array. A declarative `autofocus` there fires once into a hidden field at page load and never again. The seven existing `autofocus` precedents in the repo all sit inside lazily-mounted `q-dialog`s (including `RenameDialog.vue:80`, the nearest-looking neighbor), which is exactly why copying the precedent would mislead.

  By contrast `AddProceedingForm`'s card is `v-if="showAddForm"` (`:127`), so it *does* mount fresh on reveal. **The two surfaces fail the naive fix differently** — one silently, one not at all — which is the single most important thing for the implementer to carry forward.

- **Contract / source-of-truth alignment (software lens):** the authority for a proceeding's name is the `proceedings.value` column — required `varchar`, no DB default, unique per job case-insensitively (`proceeding.entity.ts:17,22-23`). Both create endpoints require **client-supplied** names (`create-proceedings.request.dto.ts:14-19`; `create-job-submission-proceedings.request.dto.ts:9-13`) and `CreateProceedingsTS.apply` maps them straight through with no defaulting branch. The name is typed in the UI *before* any request exists. **There is no authority for this layer to mirror and nothing to drift from** — the behavior is wholly owned by the component. This is what rules callisto out, and it is also why the usual re-drift risk does not apply here.

- **Detection gap (software lens):** nothing "missed" a defect, since there was none. The gap that matters is in the **net available to prove the fix**: no spec anywhere in the repo asserts focus (`toHaveFocus` / `activeElement` return nothing across all `__specs__`), `@testing-library/jest-dom` is installed but never imported and not registered in `test/vitest/setup-file.ts` (so `toHaveFocus()` is unavailable as-is), `AddProceedingForm.vue` has **no spec file at all**, and `NewProceedingsOverlay.spec.ts` **stubs `q-input`** with a bare div+input (`:73-86`) that drops `autofocus` and exposes no `focus()`. Any focus test must first extend that stub or mount real Quasar. This directly shapes the test work in §9.

- **Class re-check:** **held.** The root-cause evidence is an absence of presentation code with no authority behind it — precisely a capability gap. Nothing in the trace suggested a defect or a contract problem, so the wedge and acceptance criteria stand as written.

## 6. Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| Add Quasar's `autofocus` attribute to both `q-input`s (copy `RenameDialog.vue:80`) | Cannot work on the overlay surface: `v-show` + unconditional mount means it fires once at page load into a hidden input and never on open (§5). Half-lands, and *looks* correct in review. |
| `autofocus` on every row of the `v-for` | Would fire for appended rows (a new `QInput` does mount at the new index), so AC-2 would appear to work — but it re-fires on the overlay's row 0 at page load, and encodes the behavior implicitly in mount timing rather than in the events that actually mean "created" and "added". Fragile and unreadable. |
| Add `v-if` to `Overlay`/`AddNewProceeding` so content mounts lazily, then use `autofocus` | Changes a **shared global component** used well beyond this ticket, to make a one-line attribute viable. Far larger blast radius than the behavior being added, and would need its own regression pass across every `Overlay` consumer. |
| Extract a shared `useAutoFocus` composable / design-system input wrapper | Overreach at two call sites, and the repo has deliberately not done this anywhere (§5 — no directive, no focus composable, no input wrapper). Kept as a Phase 3 decision rather than a foregone conclusion, since the duplication is real. |
| Use `@vueuse/core`'s `useFocus` (already a dependency) | Adds an abstraction over a two-line native call; `useFocus` is reactive-state-oriented, while the need here is a one-shot imperative nudge at a specific moment. Worse fit than `QInput.focus()`. |
| Do nothing / close as won't-fix | The cost is small but paid on every single proceeding creation by the requesting team, and the change is genuinely cheap. No argument for declining. |

## 7. Solution & stress-test

- **Proposed solution:** collect a per-row ref to each name `q-input` (the repo's existing callback-ref-into-a-map idiom — `CaseFilesTable.vue:413`, `ClientDeliverablesTable.vue:921-923`), and call `QInput.focus()` from the two moments that already exist in code on each surface: **(a)** the container becoming visible — `watch` on `modelValue` for the overlay, the `showAddForm = true` reveal for the inline form; **(b)** immediately after the append handlers `addProceeding()` / `addProceedingField()`, deferred until the new row is in the DOM. `QInput` exposes `focus()` and `nativeEl` (Quasar 2.18.6), so no native-element spelunking is needed.
- **Solves the confirmed class?** Yes, and at the wedge rather than the occurrence: the trigger is *"an empty name input has just become available to the user"*, expressed through each surface's own lifecycle. A third create surface added later would adopt the same two hooks.
- **Scale:** trivial. Both forms cap at 20 rows (`canAddMore`), and focus is a single call at a discrete user-initiated moment — no loops, no watchers over collections, no per-render cost.
- **Generalization:** deliberately *not* abstracted. Two call sites do not justify the repo's first focus composable, and §5 shows the codebase has consistently chosen inline focus (4 one-off `.focus()` sites, none extracted, including two byte-identical `Delete*Dialog` copies). Left as an explicit Phase 3 decision so the reviewer can overrule; the argument for extraction is the near-duplicate pair of components, not the focus code itself.
- **Fit:** uses Quasar's own API and the repo's own two idioms (`ref` + `.focus()`, callback refs for `v-for` rows). Introduces no dependency, no directive, no global. The one place it deviates from the dominant idiom (`autofocus`) is precisely where that idiom provably does not work, and the deviation is explained by §5.
- **Adjacent issues** — three surfaced; **all recommended as follow-ups, none folded in**:
  1. **`:key="index"` on both repeaters.** With `splice`-based removal (`NewProceedingsOverlay.vue:100-105`), index keys make Vue patch rows in place rather than move them; combined with per-row refs this is a latent correctness trap for anything that binds identity to a row. Fixing it means giving rows stable ids, which touches the validation-error arrays that are index-aligned — a bigger change than this ticket, with its own regression surface. **Follow-up.**
  2. **Two near-duplicate proceeding forms whose duplicate-detection disagrees — and a DB constraint whose name lies.** The overlay's check is case-**sensitive** (`NewProceedingsOverlay.vue:65-67`); the form's is case-**insensitive** (`AddProceedingForm.vue:51-55`). Checking which one matches the authority refuted my first reading: the constraint is *named* `UQ_proceeding_value_per_job_case_insensitive` but is implemented as a plain `UNIQUE ("value", "job_id")` (`1766801287907-alter__add_unique_value_job_id__proceedings_table.ts:13`), which in Postgres is case-**sensitive**. The sibling `records` table implements real case-insensitivity the correct way — `CREATE UNIQUE INDEX … ON records (LOWER("value"), "job_id")` (`1758811836915:16-19`) — so the pattern is known and the later proceedings migration copied the *name* without the mechanism. Net: the DB allows "Deposition" alongside "deposition"; the overlay agrees with it; the job-submission form is stricter than the database. Real latent defect, **not this ticket** — folding it in would smuggle a behavior change into a focus ticket. **Follow-up — recorded in [future-development-concerns](../PRDV-14184-future-development-concerns.md).**
  3. **No focus assertions anywhere in the test suite**, and `jest-dom` unregistered. Whoever writes the first focus spec pays the setup cost. In scope only to the extent this ticket needs it; registering `jest-dom` globally is a shared-config decision (§10).
- **Sufficiency:** covers the whole pain that convened this — both moments, on whichever surfaces are ruled in scope. It does not reduce the *other* clicks in proceeding creation (opening the control, saving), which were never in the complaint.
- **Feedback speed:** immediate and unambiguous. A human opens the surface and either types or doesn't. The risk is not slow feedback but **false-positive feedback from tests** — a happy-dom spec can assert `activeElement` while the real browser fails on transition timing, which is exactly why §9 requires browser observation as well as specs.
- **Happy-path story (30 seconds):** An Ops user on a job opens **New Proceeding**. The overlay slides in with the cursor already blinking in the first name box; they type "Deposition of J. Smith", hit **Add another proceeding**, and the cursor is already in the new box; they type the second name and click **Save**. They never touched the mouse between opening the overlay and saving — *without* the two deliberate clicks into text boxes they make today.

## 8. Assumptions ledger

- **A1 — "Highlighted by default" means receives focus, not focus-plus-text-selection.**
  - **Status:** **confirmed**
  - **Confirm/revise by:** resolved by evidence, not discussion. Every new row is an empty string (`ref([''])` / `push('')` on both surfaces) and no server-side default name can exist (§5 contract alignment), so there is never text to select. `QInput.select()` is therefore inapplicable.
- **A2 — There are exactly two surfaces that render an empty proceeding-name input.**
  - **Status:** **confirmed**
  - **Confirm/revise by:** grep of the two i18n keys labelling such an input across all `src/**/*.vue` returns exactly these two files; corroborated by `proceedings.push` / `addProceeding` / `createProceeding` greps and by confirming all proceeding UI lives under `src/callisto`. Re-runnable as a completeness check.
- **A3 — The overlay's name input is mounted once at page load and never remounts on open.**
  - **Status:** **confirmed**
  - **Confirm/revise by:** `Overlay.vue:80,92` use `v-show`; `AddNewProceeding.vue:53-57` has no `v-if`; `resetProceedings()` (`:107-110`) reassigns data only. Directly readable.
- **A4 — With an index-keyed `v-for`, an *appended* row mounts a fresh `QInput` (so Quasar's `autofocus` would fire on append).**
  - **Status:** **open** — the two recon passes disagreed; resolved by reasoning (keys `0..n-1` patch and reuse, key `n` is new → mount), not yet by observation.
  - **Confirm/revise by:** a spec that appends a row and asserts a fresh mount, or an `onMounted` probe. **Not load-bearing** — the chosen solution is imperative and correct either way; this only governs whether the rejected `autofocus`-on-every-row alternative would have worked.
- **A5 — `nextTick` is sufficient deferral for focusing through `v-show` + `<Transition>` on the overlay.**
  - **Status:** **open** — `v-show` clears `display:none` within the same DOM update, which argues yes; but a `<Transition>` is also running and `Overlay` exposes `after-leave` but **no `after-enter`** hook to attach to, and the repo's own precedent (`SearchBar.vue:53-63`) chose `setTimeout`.
  - **Confirm/revise by:** browser observation under the browser-loop guardrails. **If `setTimeout` proves necessary, the deferral must carry a comment naming the real constraint (transition/paint timing) — not an unexplained magic delay**, and iteration is capped at three attempts before escalating rather than tuning.
- **A6 — Focusing the name input is safe with respect to global keyboard shortcuts.**
  - **Status:** **confirmed directionally**
  - **Confirm/revise by:** `useActiveElement()` guards in `KeyboardShortcuts.vue:28-33` and both `SearchBar`s suppress magic keys (e.g. `/`) while an input holds focus. That is the *intended* consequence of focusing a text field, and matches what already happens when the user clicks in manually — but it does mean the `/` shortcut stops working the moment the create surface opens. Worth a conscious nod in review; not a blocker.
- **A7 — No neighbor behavior on these components depends on the name input *not* holding focus.**
  - **Status:** **open**
  - **Confirm/revise by:** the neighbor assertions in §9. The repo demonstrably *does* reason about focus-vs-Enter on destructive actions (`DeleteLinkDialog.vue:31-34`: "Keep focus off the confirm button so Enter does not commit the delete"), so the mirror-image risk — focus making **Enter** do something unintended — must be checked on both surfaces rather than assumed away. Neither create surface currently binds `@keydown.enter`, which is the evidence pointing to "safe"; the check confirms it.

## 9. Validation plan

**Happy path**
1. Open a job's **Job Detail** page → click **New Proceeding** → overlay opens with the cursor in the first name box; type without clicking.
2. Click **Add another proceeding** → cursor is in the newly added box; type without clicking.
3. Save → proceedings persist with the typed names; re-open the overlay → cursor is again in the first (reset, empty) box. *(This step is the one that catches an `autofocus`-shaped fix: it passes on first open and fails on re-open.)*
4. Repeat 1–3 on the **Job Submission** surface (`AddProceedingForm`) via both the Pending and Submitted routes.

**Negative paths** — what must fail *visibly* rather than corrupt silently
- **Focus must not be stolen at page load.** Loading Job Detail with the overlay closed must leave focus where the browser put it — the regression this ticket's naive fix would introduce. Assert the hidden input is not `document.activeElement` on mount.
- **Neighbors unchanged (protect-the-neighbors):** per-row validation and error messages, duplicate detection, the max-20 cap and its hint, row removal via the delete button (and the disabled state at one row), Save enable/disable via `isValid`, and Cancel's reset-and-close. Each has existing coverage in `NewProceedingsOverlay.spec.ts` that must stay green; `AddProceedingForm` has **none today**, so its equivalents must be written alongside.
- **Enter key:** with focus now in the name box by default, confirm Enter does not submit or commit anything unintended on either surface (per A7).
- **Row removal:** after deleting a row, focus must not be left pointing at a detached element, and no error should be thrown by a stale ref. Index-keyed rows plus `splice` make this the most likely place for a ref-related fault.
- **Permission-gated paths:** when the create control is disabled (`canCreateProceedings` false on the overlay; `canUploadJobSubmissionProceedings` false on the form), nothing focuses because nothing opens.
- **Timing bound:** focus must land within the same interaction — no visible delay where the user could begin typing into nowhere and lose keystrokes. This is the specific failure `nextTick`-vs-`setTimeout` (A5) decides.

**Red→green regression test (software lens).** The test that encodes the defect: *on the overlay surface, open → close → re-open, then assert the first name input holds focus.* It fails before the change **and also fails against the tempting `autofocus`-only fix**, which is exactly what makes it worth writing. Its counterpart for AC-2: append a row, then assert the appended input holds focus.

**Reproduction recipe / preconditions.** Role: an Ops user with `canCreateProceedings` (Job Detail surface) or `canUploadJobSubmissionProceedings` (Job Submission surface). Data: any job reachable at `/callisto-stuff/job/:id`; for the second surface, a job submission in an editable state (`AddProceedingForm` renders only under `v-if="editing"`). No feature flag gates either surface. Observe by opening the create control and pressing a letter key without clicking.

## 10. Decisions, recommendation & open variables

- **Decisions (settled by evidence):** "highlighted" = focus, not select (A1); `callisto-back-end` is out of scope (§5); the declarative `autofocus` approach is rejected for the overlay surface (§6); the fix is imperative focus on collected refs (§7).
- **Recommendation, in order:**
  1. Close the scope decision (both surfaces or one) — it sizes everything downstream.
  2. Decide extraction (shared helper vs. inline twice) and the spec assertion mechanism.
  3. Write the spec, then the refined test plan, **then** the code.
  4. Implement the overlay surface first — it is the one that disproves the naive fix, so it derisks fastest.
  5. Confirm in a real browser before the PR, including the open→close→re-open path.
- **Sequencing & gates:** do not write product code until the Phase 3 decisions are locked and the spec has gone to its reviewer. Do not call the change done on green specs alone — browser confirmation of A5 is a merge gate, because the test environment cannot faithfully reproduce `v-show` + `<Transition>` timing.

### Open variables to collect

- [ ] **Do both create surfaces ship under this ticket, or only the Job Detail overlay?** The ticket names the module but no surface; the code cannot decide a scope question. — owner: **user / product**
- [ ] **Extract a shared focus helper across the two surfaces, or inline it twice?** No precedent either way (§5); the duplication is real but so is the repo's consistent choice not to extract. — owner: **user / reviewer**
- [ ] **Assert focus via `document.activeElement` under happy-dom, or register `@testing-library/jest-dom` for `toHaveFocus()`?** The latter edits `test/vitest/setup-file.ts`, a shared config affecting every spec in the repo — a change to the current structure, hence a decision rather than a lookup. — owner: **user / reviewer**
- [ ] **Does `AddProceedingForm` get a full spec file** (it has none today) as part of this ticket, or only the focus assertions it needs? — owner: **user / reviewer**

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Lock the four open variables above | user (Phase 3 grill-me) | Each appears as an `LD-###` row in `specs/PRDV-14184-locked-decisions.md` with a source and a spec destination |
| Accept job story 01 | agent | Index row reads `accepted`; its remaining open question is closed or carried with a named owner |
| Write and submit the spec | agent → reviewer | Spec exists at `specs/PRDV-14184-spec.md` and has been delivered to its reviewer through the surface that team reviews on |
| Refine the test plan against locked decisions | agent | Every scenario names the acceptance criterion it proves; status `refined`; written **before** any product code |
| Implement + prove | agent | Both AC hold in a real browser on every in-scope surface, including open→close→re-open; specs green; `npm run lint` and `npx vitest run --maxWorkers 1` pass |
| Record the case-sensitivity mismatch as a follow-up | agent | An entry exists in `PRDV-14184-future-development-concerns.md` naming the two call sites and the DB constraint |

### Checklist
#### Investigation
- [x] This report (Sections 0–10)

#### Project Spec
- [ ] Draft open questions / unknowns
- [ ] Create project spec

#### Development
- [ ] Create new branch
- [ ] Begin implementation

#### Testing & Validation
- [ ] Test and validate implementation locally

#### Deploy & PR
- [ ] Push to GitHub
- [ ] Deploy to sandbox + verify there
- [ ] Open PR
- [ ] Address feedback / wait for approval
- [ ] Merge to main
- [ ] Deploy to test

#### Ticket Closeout
- [ ] Update ClickUp: merged to test
- [ ] Set ticket to Ready for QA
- [ ] (If bug) Document root cause / why it slipped through — *N/A, not a bug (§1)*

---

## 12. Definition of done (investigation gate)
- [x] Class derived from instances, re-confirmed against root cause; "reframed?" answered with justification (§1)
- [x] Problem Check pass recorded (§2) with trimmed quotes, including an explicit "nothing here" on Conflation and Off
- [x] Problem in one plain sentence (§2)
- [x] Named blocked instance — **role-level only; the limitation is stated rather than papered over** (§2)
- [x] Date it bites next — continuous, no forcing date; stated as such (§2)
- [x] Wedge + why it's reusable within the confirmed class (§2)
- [x] Acceptance criteria + non-goals locked before the solution was proposed (§3)
- [x] Alternatives recorded with rejection reasons (§6)
- [x] 30-second happy-path story (§7)
- [x] Metric that proves it works + how fast it arrives (§7 Feedback speed — a human types without clicking; immediate)
- [x] Verdict + disposition stated (§0)
- [x] Every open question reconciled — facts resolved in §8, only genuine decisions in §10, each with an owner
- [x] Tracked action with a falsifiable done-when (§11)
