# Test plan — atlas/PRDV-14184 (PRDV-14184)

> Seeded from [PRDV-14184-investigation.md](../investigations/PRDV-14184-investigation.md) §9 on 2026-09-11. Refined 2026-09-11 (Phase 3) against the spec (`atlas-front-end/docs/specs/atlas-maintenance/proceedings/PRDV-14184-focus-proceeding-name-on-create.md`) and [the locked decisions](../specs/PRDV-14184-locked-decisions.md).

Status: **refined**

**This plan is in place before any product code is written**, so the assertions are shaped by the criteria rather than by the implementation.

Acceptance criteria are owned by [job story 01](../stories/PRDV-14184-job-story-01-focus-name-field.md):
- **AC-1** — Creating a new Proceeding leaves the user able to type the name immediately, with no extra click.
- **AC-2** — Adding an additional proceeding leaves the user able to type that name immediately, with no extra click.

## Scope and surfaces under test

The behavior proven is **keyboard focus landing on an empty proceeding-name input at two moments**, on the surfaces Product confirms (**scope reopened 2026-09-13 — LD-012**; scenarios are written for both and the S2 ones are struck if scope narrows):

| Surface | Component | Routes it reaches users on |
| --- | --- | --- |
| **S1** | `NewProceedingsOverlay.vue` (inside `Overlay`, `v-show`-hidden, mounted unconditionally) | Job Detail page → **New Proceeding** |
| **S2** | `AddProceedingForm.vue` (**two** visibility gates: `v-if="editing"` wrapper **and** `q-card` behind `v-if="showAddForm"`) | Job Submission — **Pending** and **Submitted** routes, both via `FileUploadSectionCore` |

**Not under test:** any backend behavior (no contract change — report §5), the proceeding *rename* flow (already focuses), and the duplicate-name/case-sensitivity divergence recorded in [future-development-concerns](../PRDV-14184-future-development-concerns.md).

## Happy path

- [ ] **HP-1 (AC-1, S1)** — On a job's Job Detail page with the overlay closed → click **New Proceeding** → the first name input holds focus; typing a letter enters it without any click.
- [ ] **HP-2 (AC-2, S1)** — With the overlay open and row 1 filled → click **Add another proceeding** → the newly added (last) input holds focus; typing enters it without any click.
- [ ] **HP-3 (AC-1, S1 — the load-bearing scenario)** — Open the overlay → **close it** → **re-open it** → the first input (now reset and empty) holds focus again. *This is the scenario that distinguishes the real fix from the tempting `autofocus`-only one, which passes HP-1 and fails here.*
- [ ] **HP-4 (AC-1, S2)** — On a Job Submission page in editing state → click **Add Proceeding** → the form appears with the first name input focused.
- [ ] **HP-5 (AC-2, S2)** — Click **Add Another Proceeding** → the appended input holds focus.
- [ ] **HP-6 (AC-1, S2)** — Save or cancel the form, then re-open it → the first input is focused again against the reset state.
- [ ] **HP-7 (S2 parity)** — Repeat HP-4 on the **other** job-submission route (Pending vs Submitted) → identical behavior; confirms the shared `FileUploadSectionCore` mount is not route-dependent.
- [ ] **HP-8 (S2 — re-entry must NOT steal focus; inverted at review round 2)** — open the Add Proceeding form, type a partial name, leave editing mode (or navigate off step 5 and back on the Pending route) and return **without** clicking Add Proceeding. The form reappears as the user left it and **must not** take focus. *Round 1 treated this as a missing-focus defect; round 2 established the opposite — focus follows the request for an empty field, not visibility, and grabbing focus on navigation is worse than the bug being fixed.*

## Negative paths

- [ ] **NP-1 — focus must not be stolen at page load.** Load the Job Detail page **without** opening the overlay → `document.activeElement` is not the hidden proceeding-name input, and the page does not scroll to it. *(This is the regression the naive fix introduces on S1; it must fail visibly if reintroduced.)*
- [ ] **NP-2 — Enter does not commit anything unintended.** With focus defaulted into the name input on each surface, press **Enter** → no save, no close, no submit, no navigation. Neither surface binds `@keydown.enter` today; this proves the new default focus did not make an existing handler reachable.
- [ ] **NP-3 — removal does not corrupt the ref array (S1).** Add three rows → delete the middle row → no console error and no exception from a stale ref. **Removal asserts nothing about where focus goes** — the design gives removal no focus behavior (LD-007), so the row that had focus losing it is expected, not a defect. What this scenario protects is the *next* append (see AV-2).
- [ ] **NP-4 — permission-gated: nothing opens, nothing focuses.** With `canCreateProceedings` false (S1) / `canUploadJobSubmissionProceedings` false (S2) → the create control is disabled, no container opens, no focus call occurs and no error is thrown.
- [ ] **NP-5 — neighbors unchanged (protect-the-neighbors).** Every existing behavior on these components still holds: per-row validation messages (required / too short / too long / invalid characters), duplicate detection, the 20-row cap and its hint, row removal and the disabled delete at one row, Save enable/disable via `isValid`, Cancel resets and closes. On S1 these already have coverage that must stay green; **on S2 no spec exists today**; only the neighbors focus can actually disturb are asserted here (ref lifecycle across close/reopen, permission gating). That component's missing validation characterization is a real gap, spun out as a follow-up rather than folded into a focus ticket.

## Anti-vacuity assertions (added Phase 3 — these are what stop a focus test proving nothing)

A focus assertion can pass for reasons unrelated to the change. Each of these is paired with the scenario it protects.

- [ ] **AV-1 (pairs with HP-1/HP-4)** — before the create container is opened, `document.activeElement` is `document.body`. Without this, HP-1 could be passing on ambient state.
- [ ] **AV-2 (pairs with NP-3) — remove, then append, and assert identity.** After deleting a row and appending a new one, `document.activeElement` **is** the newly appended input element. This is an AC-2 assertion applied after the array mutates, which is the real risk: `removeProceeding` splices while rows are keyed positionally, so a stale index would focus the wrong row. **Do not assert `isConnected` as the proof** — `document.body.isConnected` is `true`, and focus falls back to `<body>` when the focused node is removed, so that check passes in exactly the failure it was meant to catch. Identity against the expected element is the assertion; `isConnected` may accompany it, never replace it.
- [ ] **AV-3 (harness precondition, both specs)** — mounts use `attachTo: document.body`, and `afterEach` calls `wrapper.unmount()` **before** clearing `document.body.innerHTML`; clearing innerHTML alone leaves component instances and their watchers alive across tests. `@vue/test-utils` appends its host element to the document *only* when `attachTo` is set, and happy-dom's `focus()` bails on a disconnected node, so omitting it makes every focus assertion fail — **closed (red), not vacuously green**. Paired with `afterEach(() => { document.body.innerHTML = ''; })` so focus state cannot leak between tests.
- [ ] **AV-4 (harness precondition, S1)** — the real `q-input` is mounted, **not** stubbed (LD-005). The previous stub had no `focus()` method, so `proceedingInputs[i]?.focus()` would have silently no-opped and the test would have passed while proving nothing.
- [ ] **AV-6 (pairs with HP-8)** — in the re-entry case, assert the card is rendered **and** that `document.activeElement` is *not* one of its inputs. Asserting only "not focused" would pass trivially if the card never rendered.
- [ ] **AV-5 (flush ordering)** — every focus test awaits an explicit `nextTick()` after the action. `setProps()` chains its own `nextTick` *before* the component's watcher registers one, so `await target.setProps(...)` alone is insufficient and would produce a false red.

## Edge cases

- [ ] **EC-1 — max rows.** Add rows to the 20-row cap → the add control disables and the max hint shows; the last successfully added row was focused, and no focus call fires against a row that was never added.
- [ ] **EC-2 — rapid repeat.** Click **Add another proceeding** several times quickly → focus ends on the final appended row, not an intermediate one, and no error is thrown.
- [ ] **EC-3 — single row.** With only one row present, the delete control stays disabled (existing behavior) and focus remains on that row.
- [ ] **EC-4 — open, type, cancel, re-open.** Typed text is discarded by reset **and** focus returns to the now-empty first input — proves focus and state reset are both wired to re-open, not just one.

## Manual verification

Written so someone who did not build the change can execute it without a follow-up question.

**Before / after**

| | Before | After |
| --- | --- | --- |
| Job Detail → **New Proceeding** overlay | Overlay opens; **no cursor** in the name box; user must click it before typing | Overlay opens with the cursor already blinking in the first name box |
| **Add another proceeding** (both surfaces) | New empty row appears; **no cursor** in it; user must click it | Cursor is already in the newly added row |
| Job Submission → **Add Proceeding** form | Form appears; **no cursor** in the name box | Cursor already in the first name box |
| Page load with the overlay **closed** | Focus wherever the browser put it | **Identical — must not change.** This is the thing NP-1 protects |
| Saved proceeding names, validation messages, row limits | — | **Identical.** No data or validation behavior changes |

> The change is entirely visible in the UI — there is no database or log evidence to collect, and nothing to query. Evidence is a screenshot or screen recording showing a text cursor in the name field immediately on open, and the operator typing **without clicking first**. A still screenshot is weak evidence here (a cursor may not render in frame); prefer a short recording, or capture the field's focus ring.

**Preconditions**
- Atlas front end running locally against a Callisto environment; signed in as a user with `canCreateProceedings` (S1) and, for S2, `canUploadJobSubmissionProceedings` on a job submission in an editable state.
- A job reachable at `/callisto-stuff/job/:id`, and for S2 a submission reachable from **My Jobs**.
- Baseline reading to take **before** the change: perform HP-1 and HP-3 on `main` and confirm the cursor is absent — so the after-state is a contrast, not an assertion.

**Steps**
1. Open `/callisto-stuff/job/:id` → observe focus **before** touching anything (NP-1).
2. Click **New Proceeding** → without touching the mouse, type `Test Proceeding A` → confirm it lands in row 1 (HP-1).
3. Click **Add another proceeding** → type `Test Proceeding B` without clicking → confirm it lands in row 2 (HP-2).
4. Press **Escape** or **Cancel** to close, then click **New Proceeding** again → type immediately (HP-3, EC-4).
5. Add three rows, delete the middle one, watch the console (NP-3).
6. Navigate to a job submission in editing state → click **Add Proceeding** → type immediately (HP-4) → **Add Another Proceeding** → type immediately (HP-5).
7. Repeat step 6 on the other submission route (HP-7).

**Evidence** — no command produces this; the evidence is behavioral. For the automated half:

```bash
# from atlas-front-end, serial per repo convention
npx vitest run --maxWorkers 1 src/callisto/pages/JobProceedingPages/JobDetailPage/components/NewProceedingsOverlay
npx vitest run --maxWorkers 1 src/callisto/pages/JobSubmissionPages/sections/FileUploadSection
```

**Pass / fail**

| Step | Passes | Fails |
| --- | --- | --- |
| HP-1 | First keystroke appears in the name box | Keystroke goes nowhere (or triggers a shortcut) — focus never landed |
| **HP-3** | Cursor is in the empty first box on **re-open** | Cursor absent on re-open while HP-1 passed — **the `autofocus`-shaped half-fix; the defect is back** |
| HP-2 / HP-5 | Keystroke appears in the newly added row | Keystroke lands in a *previous* row — the ref targeted the wrong index |
| NP-1 | Nothing focused on page load | Page jumps/scrolls, or the hidden input holds focus — a new regression |
| NP-2 | Enter does nothing | Enter saves, closes, or navigates |
| NP-3 | No console error after deleting a row | Error from a stale ref |
| AV-2 | After remove-then-append, the active element **is** the new last input | Focus on a different row (stale index), or on `<body>` (ref lost) |

**Load-bearing step: HP-3.** Its failure means the change reduced to the naive fix that works only on first mount — the exact failure this ticket's investigation exists to prevent. NP-1 is second: it is the only scenario that catches the change actively making something worse.

> **This manual pass is a merge gate, not a nicety (Phase 3).** happy-dom's `focus()` checks only `isConnected`, `disabled`, and `inert` — it **never** evaluates `display` or `visibility`. So no unit test in this repo can catch a `display:none` silent no-op on S1, which is precisely the failure mode the `v-show` container creates. The `nextTick` choice (LD-006) is sound by construction from the Vue and Quasar sources, but **the browser is the only available witness.** If HP-3 fails here, do not tune: take the spec's fallback ladder in order (`@after-enter` emit on `Overlay`, then one `requestAnimationFrame`, then a zero-delay `setTimeout` carrying a comment naming the constraint), and stop after three attempts per the browser-loop guardrails.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| `atlas-front-end` | `.../NewProceedingsOverlay/__specs__/NewProceedingsOverlay.spec.ts` (**exists — extend**) | AC-1 on open and **re-open**, AC-2 on append, NP-1 not-focused-while-closed, NP-3 removal safety, AV-2 remove-then-append identity; existing validation/save/cancel assertions stay green |
| `atlas-front-end` | `.../AddProceedingForm/__specs__/AddProceedingForm.spec.ts` (**new; CONDITIONAL on LD-012**) | AC-1 on the open action, AC-2 on append, ref lifecycle across close/reopen, re-entry **without** focus, and permission gating. **Not** the existing validation/duplicate/hint rules - focus does not influence them (LD-004 revised) |

> **Harness gap — now closed by decision (was open at seed time).** No spec in the repo asserts focus today. Resolved: **LD-003** — assert with `document.activeElement` and plain Vitest `expect`; do **not** register `@testing-library/jest-dom` (no repo rule sanctions it, and it would edit shared setup every spec inherits). **LD-005** — drop the `q-input` stub and mount real Quasar, rather than giving the stub a hand-written `focus()`.
>
> **S1 spec migration cost (verified, not estimated):** the existing `.q-input input` selectors **survive** — a real `QInput` root does carry class `q-input` (`QInput.js:389-392`). Two deltas: the stub-only `.error-message` becomes `[role="alert"]` (5 sites), and one existing test that calls `setValue('')` on an already-empty input becomes `setValue('abc')` then `setValue('')`, because real Quasar short-circuits on unchanged values while the stub emitted unconditionally. **That test has been passing for the wrong reason.**
>
> **Run the S1 spec on `main` before touching production code** to confirm it is green to begin with — the design was derived by reading installed sources, not by executing the suite.

## Gates

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` |
| lint | `npm run lint` (must exit 0; `npm run lint:fix` available) |
| tests | `npx vitest run --maxWorkers 1` |

Run and report in order **audit → lint → tests**, tests against the post-lint tree, final post-change state only.

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| _pending_ | | | | | |
