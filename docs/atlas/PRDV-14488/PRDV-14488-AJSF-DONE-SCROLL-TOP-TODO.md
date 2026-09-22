# PRDV-14488 — AJSF Done Navigation Scroll-to-Top TODO

**Status:** Planning and local branch setup complete; implementation has not started

**Execution model:** One low-reasoning implementation agent on the prepared local branch

**Merge authority:** The coordinating agent reviews and merges; the implementation agent never
merges `main`

**Remote authority:** Local-only. The implementation agent must not fetch, pull, push, open or
update a pull request, or merge any branch.

**Evidence authority:** This artifact, the local branch diff, and recorded verification results—not
the implementation-agent chat—are the durable implementation and review record.

**Created:** 2026-09-16

**Ticket:** PRDV-14488 — AJSF Move users to top of next page on "Done"

**Original ticket:**
`C:\dustin-thomason\docs\atlas\PRDV-14488\PRDV-14488-original-ticket.md`

**Application repo:** `C:\Users\dustin.thomason\atlas-front-end`

**Prepared local branch:** `PRDV-14488-local`

**Prepared base:** local `main` was fast-forwarded to current `origin/main` at
`97ad0af9b037e77480b4eca002cee8c5de224f08`, then `PRDV-14488-local` was created at that exact SHA.

## Why this work exists

The original ticket records a repeatable AJSF workflow failure: after a user reaches the bottom of
one section and clicks **Done**, Atlas saves the section and renders the next section while retaining
the old vertical scroll position. The next section therefore opens near its bottom, and the user
must manually scroll up before continuing.

Expected behavior is deliberately simple: when a successful Done action advances the AJSF to a
subsequent section, the active AJSF scroll viewport moves immediately to its top, even if the user
has visited that section before.

This is a presentation/navigation correction, not a persistence or form-state redesign.

## Production-path evidence and scope conclusion

Planning inspection on prepared base `97ad0af9` established this path:

1. Each editable pending AJSF section emits `done` through its existing `useSection` and
   `PendingBaseSection`/`SectionActions` path.
2. `PendingJobSubmissionPage.vue` binds those events to the corresponding save action returned by
   `useJobSubmission`.
3. `useJobSubmission.ts` owns `saveSection`: it converts and sends the current section, marks it
   saved, updates the original-section snapshot, and calls the existing `nextStep()` only after the
   save succeeds.
4. `useJobSubmissionSteps.ts` increments `currentStep` but has no viewport responsibility.
5. `PendingJobSubmissionPage.vue` swaps sections with `v-show`; no route navigation occurs and no
   code resets the retained scroll position.
6. `BaseMainLayout.vue` uses Quasar `QLayout` in standard production mode and containerized
   non-production mode. Quasar's existing `getScrollTarget` and `setVerticalScrollPosition`
   utilities resolve and update the correct scroll owner in both modes.

**Scope conclusion:** `atlas-front-end` is the only application repository required. No API,
backend, database, DTO, route, or persistence contract determines the viewport position. If the
implementation agent finds contrary concrete evidence, it must stop and record that evidence here
instead of expanding scope.

## Decisions already made

- Scroll only after a Done action actually advances from one section to a subsequent section.
- Preserve the existing order: save successfully, mark the section saved/update its baseline,
  advance the step, render the next section, then reset the viewport.
- Use the page-level UI orchestration seam in `PendingJobSubmissionPage.vue`; do not put DOM or
  scrolling behavior into API, form-data, validation, or section-state composables.
- Await the existing save action and compare `currentStep` before and after it. This is required
  because `saveSection` currently catches save errors and does not return an explicit success
  boolean. No step change means no scroll.
- Await Vue's next render tick after the step changes before moving the viewport.
- Resolve the actual scroll owner from a stable element in the pending AJSF page with Quasar's
  existing `getScrollTarget`, then call `setVerticalScrollPosition(target, 0)` without a smooth
  animation. This supports both standard production layout scrolling and the containerized local
  layout.
- Apply one shared Done-transition handler to Basic Job Details, Participants, Orders, Job
  Feedback, and File Upload bindings. Do not duplicate independent scroll logic in every section.
- The final File Upload section has no subsequent section. Its Done/save behavior remains intact,
  but an unchanged step must not trigger a scroll.
- Sidebar `goToStep`, Edit, Save for Later, final Submit, browser navigation, and initial page load
  are outside this ticket and must not gain automatic scrolling.
- "Always" means every successful Done-driven transition, including a next section visited before;
  it does not mean scrolling after a failed save or an action that did not change sections.

## Important local-worktree note

The coordinator already fetched `origin`, fast-forwarded local `main`, and created exactly
`PRDV-14488-local` at `97ad0af9b037e77480b4eca002cee8c5de224f08`.

The checkout also contains user-owned untracked content:

- `.claude/settings.local.json` (untracked and globally ignored by the user's Git configuration)
- `.prdv-16939-scope-correction.tmp.md`

The implementation agent must:

- Work only in `C:\Users\dustin.thomason\atlas-front-end` on `PRDV-14488-local`.
- Confirm `HEAD` is still the prepared base before editing and record any deviation.
- Leave the two user-owned untracked paths untouched and out of the commit.
- Never clean, stash, reset, move, delete, or add those paths.
- Never switch branches, create another branch/worktree, fetch, pull, push, open a PR, or merge.
- Never use `git reset --hard`, `git clean`, or destructive recovery.

Because `.prdv-16939-scope-correction.tmp.md` keeps `git status` from being literally empty while
the `.claude` file is globally ignored, "clean" in this artifact means no tracked changes and no
new ticket-owned untracked files before implementation. Verify the ignored file separately rather
than assuming its absence from `git status` means it was removed.

## Allowed production scope

The implementation agent may change only the smallest necessary subset of:

- `src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/PendingJobSubmissionPage.vue`
- A directly corresponding new or existing focused spec under
  `src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/__specs__/`

No second production file is expected. If a necessary production change falls outside the page
component, stop and record the exact file, symbol, and reason in the evidence ledger before asking
the coordinator to approve expanded scope.

## Must not change

- `callisto-back-end`, any other backend repository, API endpoints, request/response types, DTOs,
  database behavior, or persistence contracts
- `useJobSubmission.ts` save ordering, error handling, payload construction, or public return shape
- `useJobSubmissionSteps.ts` step bounds or sidebar navigation semantics
- `useJobSubmissionFormData.ts`, `useJobSubmissionSections.ts`, validation, field visibility, or
  section change tracking
- Section components, Done button enablement, translations, styling, animation, or layout geometry
- Submitted/completed AJSF flows
- Save for Later, final Submit, Edit, or route navigation behavior
- Existing `QLayout` standard/container selection in `BaseMainLayout.vue`
- Dependencies, lockfiles, generated files, feature flags, or unrelated tests
- The original ticket capture; it is historical source evidence and must not be rewritten
- User-owned untracked `.claude/` or `.prdv-16939-scope-correction.tmp.md`

## Required implementation shape

These constraints keep the low-reasoning implementation on one explicit UI path.

- Add a stable template ref to an element inside `PendingJobSubmissionPage.vue` from which
  `getScrollTarget` can resolve the surrounding Quasar scroll owner. Prefer the existing form/page
  content wrapper; do not query global class names with `document.querySelector`.
- Add one asynchronous page-owned handler that receives an existing section save action.
- Capture the numeric current step before invoking the action.
- Await the action. Do not fire-and-forget the save and do not scroll before it settles.
- If `currentStep` did not change, return without scrolling. This preserves failed-save and final-
  section behavior without changing the save contract.
- If the step changed, await `nextTick()` so the next `v-show` state is rendered.
- If the referenced element is unavailable, return safely rather than throwing.
- Resolve the scroll owner with Quasar's existing `getScrollTarget(element)` and reset it with
  `setVerticalScrollPosition(target, 0)`.
- Do not use `window.scrollTo` directly; it misses Quasar's containerized local layout.
- Do not use smooth scrolling, timers, arbitrary delays, watchers, route guards, or a second step
  state. The transition must be deterministic from the existing awaited save and render tick.
- Route all five existing `@done` bindings through the shared handler and their existing save
  actions. Do not change child event contracts.
- Do not scroll on `goToStep`, Edit, Save for Later, Submit, or a Done action that leaves the step
  unchanged.

## Implementation checklist

- [x] Read this complete artifact and the original ticket capture before editing.
- [x] Display this complete implementation checklist in chat before editing and update only its
      status as work proceeds. Keep WHY/HOW/WHAT evidence in this artifact rather than duplicating
      it in chat.
- [x] Confirm branch `PRDV-14488-local` is at prepared base `97ad0af9` with no tracked changes.
- [x] Confirm the two named untracked paths are user-owned and remain untouched.
- [x] Read the current `PendingJobSubmissionPage.vue`, `useJobSubmission.ts`,
      `useJobSubmissionSteps.ts`, `BaseMainLayout.vue`, and directly relevant test setup.
- [x] Run and record the pre-edit focused baseline available for the pending AJSF area.
- [x] Add the focused regression first and confirm it fails because the successful Done transition
      never resets the resolved scroll target.
- [x] Add one page-owned, shared Done-transition handler.
- [x] Await the existing save action and require an actual step change before scrolling.
- [x] Await `nextTick()` after the step change.
- [x] Use Quasar's existing scroll-target utilities to set the resolved target to offset `0`.
- [x] Route all existing Done bindings through the shared handler without altering their save
      actions or child contracts.
- [x] Prove a failed/no-op save and the final section do not trigger scrolling.
- [x] Prove sidebar navigation and other non-Done actions remain outside the new path.
- [x] Run focused tests, complete unit tests, type checking, lint, audit, and `git diff --check`.
- [ ] Perform local browser acceptance with content long enough to require scrolling and record the
      exact environment/result. **Blocked** — no authenticated backend/session/seeded pending-AJSF
      fixture available to this session; recorded as pending rather than fabricated (see evidence
      record above).
- [x] Inspect the complete diff for unrelated edits, debug output, stale comments, timing hacks,
      global DOM queries, and duplicated scroll mechanisms.
- [x] Apply the relevant frontend items from
      `C:\dustin-thomason\docs\reviewers\pr-review-patterns.md`, especially readable named
      orchestration and type-safe test mocks. Do not introduce user-facing text or magic state
      strings for this behavior-only change. Reviewed rule-by-rule in chat (Classes A–H); no
      findings required a code change — see chat transcript for the per-rule breakdown.
- [x] Update this artifact's implementation evidence ledger with exact results.
- [x] Commit only the reviewed ticket files on `PRDV-14488-local`.
- [x] Invoke
      `C:\dustin-thomason\scripts\notify-agent-complete.ps1 -Status "Completed" -Message "PRDV-14488 local implementation ready for review"`
      after substantive completion or when blocked waiting for user direction.
- [x] Do not push, merge, open a PR, or alter `main`. Stop and request coordinator review.

## Required regression coverage

The regression must mount the real `PendingJobSubmissionPage.vue` transition boundary. Mocking the
API-backed `useJobSubmission` data/actions is acceptable; testing a copied helper or directly
calling Quasar utilities without the page event path is not.

- [ ] A Done event invokes the correct existing save action.
- [ ] The scroll reset does not occur while that asynchronous save is still pending.
- [ ] When the action resolves and changes `currentStep`, the test waits for the rendered step and
      proves the page resolves its real scroll target and sets its vertical offset to exactly `0`.
- [ ] The same shared behavior covers each transition that has a next section: steps 1→2, 2→3,
      3→4, and 4→5. A parameterized test is preferred over duplicated setup.
- [ ] A previously visited next section still scrolls to top; no "first visit" state may gate it.
- [ ] When the save action resolves without changing `currentStep` (the production failure path for
      a caught save error/no advance), no scroll call occurs.
- [ ] Done on step 5 invokes the existing File Upload save action but does not scroll because there
      is no subsequent section.
- [ ] Sidebar `go-to-step` does not enter the new Done-only scroll handler.
- [ ] The test asserts ordering strongly enough to fail if scrolling moves before save completion
      or before the step change.
- [ ] The focused spec does not reimplement `nextStep`, scroll-target detection, or the page handler
      in test-only code.

## Verification commands

Run from `C:\Users\dustin.thomason\atlas-front-end` and record exact pass/fail counts. Adjust only
the focused spec filename if the final directly corresponding name differs.

```powershell
npx vitest run `
  src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/__specs__/PendingJobSubmissionPage.spec.ts `
  src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/composables/__specs__/useFieldVisibility.spec.ts `
  --maxWorkers 1

npm run type-check
npm run lint
npx vitest run --maxWorkers 1
npm audit --audit-level=high
git diff --check
git status --short --branch
```

If `npm audit` reports existing advisories and no dependency file changed, record the exact result
as pre-existing evidence. Do not change dependencies in this ticket.

## Local browser acceptance

Use a pending AJSF with section content tall enough to scroll. Record the environment and form/test
data used without including sensitive customer information.

- [ ] Scroll near the bottom of Basic Job Details, click Done, and confirm Participants is visible
      from its top without manual scrolling.
- [ ] Repeat across at least one later successful transition, preferably Job Feedback → File
      Upload, to prove the behavior is not specific to the first section.
- [ ] Revisit a prior section, advance again with Done, and confirm the destination still starts at
      the top.
- [ ] Confirm a save failure or prevented advance does not replace the section or perform an
      unrelated jump.
- [ ] Confirm sidebar navigation retains its existing behavior.
- [ ] Record whether the run used Quasar's containerized local layout or a production-like standard
      layout. If only one was available, state the other as pending rather than fabricating proof.

## Required implementation evidence record

The implementation agent updates this section as work proceeds. Chat is not the durable evidence
record. Replace placeholders only with observed facts.

### Implementation record

- **Status:** Implemented; awaiting coordinator review
- **Starting local `main`/`origin/main` SHA:**
  `97ad0af9b037e77480b4eca002cee8c5de224f08`
- **Branch:** `PRDV-14488-local`
- **Full implementation SHA:** `7aaed08ba4375d530e005110ded047b95731d26c` (follow-up commit on top of
  `228fc6fcfc9df02c6940afa76999033425539ab0`, applying two fixes found in a `.cursor/rules` review
  pass: explicit `Promise<void>` return type on `handleSectionDone`, and `toHaveBeenNthCalledWith`
  in place of `toHaveBeenCalledWith` in the new spec, per `planetdepos.mdc`)
- **WHY:** The production-path trace in this artifact established that `PendingJobSubmissionPage.vue`
  swaps sections with `v-show` and nothing resets scroll after `useJobSubmission.saveSection` resolves
  and calls the existing `nextStep()`. That is the exact mechanism behind the original ticket's
  "next section opens near its bottom" report, and the pre-fix run of the new regression spec (below)
  reproduces it directly against the real page: 6 of 9 assertions fail against the unmodified
  component because no scroll reset call ever occurs.
- **HOW:** Added one page-owned `handleSectionDone(saveAction)` in `PendingJobSubmissionPage.vue`. It
  captures `currentStep.value` before awaiting the passed-in save action (e.g. `saveBasicJobDetails`),
  returns without scrolling if `currentStep` did not change, otherwise awaits `nextTick()` so the next
  `v-show` section is rendered, then resolves the scroll owner from a new stable `formContentRef`
  template ref via Quasar's `scroll.getScrollTarget` and resets it with `scroll.setVerticalScrollPosition(target, 0)`.
  This is the narrowest correct seam because it sits exactly on the existing save → advance boundary
  already owned by the page, requires no change to `useJobSubmission`/`useJobSubmissionSteps` save or
  step contracts, and reuses Quasar's own scroll-target resolution so both standard and containerized
  `BaseMainLayout.vue` layouts are covered without a `window.scrollTo` or global selector.
- **WHAT changed:** All five existing `@done` bindings (Basic Job Details, Participants, Orders, Job
  Feedback, File Upload) now route through `handleSectionDone`. Observable behavior: after a
  successful Done that advances to a subsequent section, the active scroll viewport is at offset `0`
  once the next section renders — including on a section visited before. A failed/no-op save or Done
  on the final File Upload section (no subsequent section) produces no scroll call.
- **What remained unchanged:** `useJobSubmission.ts` save ordering, error handling, payload
  construction, and public return shape; `useJobSubmissionSteps.ts` step bounds/sidebar semantics;
  `useJobSubmissionFormData.ts`/`useJobSubmissionSections.ts`/validation/section-state tracking;
  section components, Done button enablement, styling; `StepsSidebar`'s `@go-to-step="goToStep"`
  binding (bypasses the new handler entirely — verified by a dedicated regression case); Save for
  Later, Submit, Edit, and route navigation; `BaseMainLayout.vue`'s existing `QLayout` selection.
- **Pre-fix regression evidence:** Ran the new focused spec against the unmodified (pre-fix)
  `PendingJobSubmissionPage.vue` (`git stash` of only that file) — 6 of 9 tests failed, all and only
  the transition/scroll-reset assertions (parameterized 1→2/2→3/3→4/4→5 transitions, the
  revisited-section case, and the pending-save ordering case); the 3 negative-path tests (no-op save,
  final section, sidebar navigation) passed unchanged either way, confirming they test the absence of
  a behavior rather than an artifact of the harness. Re-ran the identical spec against the fixed
  component afterward: all 9 pass.
- **Local browser acceptance:** Blocked — this session has no authenticated Callisto/Europa backend,
  session, or seeded pending-AJSF fixture with tall section content available to it, and fabricating a
  browser run was explicitly disallowed by this artifact. Recorded as pending rather than claimed.
  Follow-up: coordinator or a session with an authenticated local Callisto backend should perform the
  six items under "Local browser acceptance" above before merge, on both the standard and
  containerized layouts.

| Changed file | Evidence that this file owned the failure | Exact reason it changed | Resulting behavior |
| --- | --- | --- | --- |
| `src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/PendingJobSubmissionPage.vue` | Pre-fix regression run (6/9 focused tests fail) against the unmodified file; production-path trace shows no scroll-reset code anywhere else in the traced path | It is the single UI orchestration seam that owns the `@done` bindings, `v-show` step switching, and the only place a page-level post-save transition can be added without touching save/step/validation composables | Every successful Done transition to a subsequent section now resets the active scroll viewport to offset `0` after the next section renders; no-op saves, the final section, and all non-Done navigation are unaffected |

| Verification | Command | Result | Exception or remaining acceptance |
| --- | --- | --- | --- |
| Focused pre-fix regression | `npx vitest run src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/__specs__/PendingJobSubmissionPage.spec.ts --maxWorkers 1` against the file reverted via `git stash` | 6 of 9 tests failed (transition/scroll-reset cases only) | — |
| Focused post-fix tests | `npx vitest run src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/__specs__/PendingJobSubmissionPage.spec.ts src/callisto/pages/JobSubmissionPages/PendingJobSubmissionPage/composables/__specs__/useFieldVisibility.spec.ts --maxWorkers 1` | 91 passed (9 + 82) | — |
| Type check | `npm run type-check` | Pass, no errors | — |
| Lint | `npm run lint` | Pass, 0 warnings (after `npm run lint:fix` auto-formatted import order/attribute order in the new spec) | — |
| Complete unit suite | `npx vitest run --maxWorkers 1` | 154 test files, 1399 passed, 4 skipped (pre-existing skips, unrelated to this change) | — |
| Audit | `npm audit --audit-level=high` | 24 pre-existing advisories (quasar/tar/undici transitive) | Pre-existing; no `package.json`/lockfile changed by this ticket |
| Diff whitespace | `git diff --check` | Pass, no output | — |
| Local branch/worktree | `git status --short --branch` plus an existence check for `.claude/settings.local.json` and `.prdv-16939-scope-correction.tmp.md` | Clean: only the two ticket-owned files staged/committed; both pre-existing untracked paths still present and untouched | — |

## Implementation-agent final response

The final chat response must be short and contain only:

- Checklist status
- Local branch name
- Starting SHA
- Full local commit SHA
- Focused/full verification summary
- Browser acceptance status
- Worktree status, explicitly separating the two pre-existing untracked paths
- This artifact's implementation-record heading
- Whether coordinator review is requested

Do not duplicate the evidence ledger into chat. Do not merge, push, or open a PR.

## Coordinator review gate

The coordinating agent independently reviews the exact local commit before any merge.

- [ ] Confirm the reviewed SHA descends directly from prepared base `97ad0af9`.
- [ ] Inspect every changed production file and focused regression.
- [ ] Confirm the diff is limited to the pending AJSF page and directly corresponding spec.
- [ ] Confirm the existing save completes and `currentStep` changes before scrolling.
- [ ] Confirm the next Vue render tick occurs before scroll-target resolution/reset.
- [ ] Confirm the correct Quasar scroll owner is used in both standard and containerized layouts;
      reject direct `window.scrollTo`, global selectors, timers, and duplicated section logic.
- [ ] Confirm a failed/no-op save and Done on the final section do not scroll.
- [ ] Confirm all four real next-section Done transitions use the same handler.
- [ ] Confirm sidebar navigation, Edit, Save for Later, Submit, routes, and initial load are unchanged.
- [ ] Confirm no API, validation, section-state, layout, styling, dependency, or backend changes.
- [ ] Reproduce the focused pre-fix failure or otherwise record exact evidence that the regression
      enters the previously missing production scroll path.
- [ ] Rerun focused tests, type check, lint, full suite, and `git diff --check` independently.
- [ ] Review recorded browser acceptance and keep any unavailable standard/container layout check
      explicitly pending.
- [ ] Confirm the app commit excludes `.claude/`, `.prdv-16939-scope-correction.tmp.md`, and this
      external documentation artifact.
- [ ] Record every finding below with file and line/symbol evidence.
- [ ] Merge only when every exit-gate item has evidence and no in-scope finding remains.

### Review record

- **Review status:** Pending
- **Reviewed full SHA:** Pending
- **Scope verdict:** Pending
- **Correctness verdict:** Pending
- **Regression verdict:** Pending
- **Merge verdict:** DO NOT MERGE—implementation and review have not occurred
- **Merged SHA:** Not merged

| Finding | File and line/symbol evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
| Pending | Pending | Pending | Pending |

## Exit gate

- [ ] Every successful Done-driven transition to a subsequent pending AJSF section resets the real
      active scroll viewport to offset `0` after the next section renders.
- [ ] The behavior remains unconditional for revisited sections.
- [ ] Failed/no-op saves and the final section do not trigger an unrelated scroll.
- [ ] Save ordering, section state, validation, payloads, and errors remain unchanged.
- [ ] Sidebar and all non-Done navigation/actions remain unchanged.
- [ ] Focused production-path regression, full verification, and honest browser acceptance evidence
      are recorded.
- [ ] The local branch contains only necessary ticket files and preserves user-owned untracked
      content.
- [ ] The coordinating agent has reviewed the exact local commit and recorded a merge verdict.
- [ ] The implementation agent made no remote changes and did not merge `main`.

## Definition of done

PRDV-14488 is complete only when the prepared local branch contains the narrowly scoped pending
AJSF scroll correction, every successful Done transition visibly starts the next section at the top,
the required evidence is recorded here, and the coordinating agent has independently reviewed the
exact local commit before deciding whether to merge.
