# Investigation Report: Duplicate Card Option in Card Menu

## Metadata
- **Status:** grilled / ready for spec
- **Disposition:** proceed with conditions
- **Date:** 2026-07-16
- **Owner:** Dustin / WorkLists; implementation owner TBD
- **Location:** `c:\dustin-thomason\docs\WorkLists\tickets\duplicate-card-option\investigations\duplicate-card-option-investigation.md`
- **Ticket:** duplicate-card-option
- **Domain:** software
- **References / evidence:** `public/cardActions.js`, `public/todolist2.js`, `public/apiService.js`, `server.js`, `dal.js`, `openapi.js`, `tests/card-actions.test.js`, `tests/api.test.js`, `tests/openapi.test.js`, canonical changelog `c:\dustin-thomason\docs\WorkLists\worklists-app-changelog.md`

---

## 0. Verdict (bottom line up front - written last, read first)
Proceed with conditions. The request is viable, but it is not just a menu-label change: WorkLists has clipboard copy actions, card move actions, note actions, and card creation paths, but no authoritative clone command that creates a new card identity while preserving the source card's structure. The strongest path is a dedicated backend endpoint, `POST /todos/{id}/duplicate`, called from a new `Duplicate Card` item in the shared card action menu, with the response carrying the created todo and updated column/order data needed for immediate UI refresh. Phase 3 now locks note-copy semantics, completion-state semantics, sorted/unsorted placement, and notes-pane parity; implementation still needs proof through tests and manual scroll/reveal validation.

- **Strongest path:** backend-owned duplicate endpoint plus menu/client wiring, tested at API, OpenAPI, and card-action UI contract levels.
- **Still to prove in implementation:** API/DAL atomicity, UI refresh, active focus/reveal, sorted-column behavior, and notes-pane switching.

## 1. Problem class

- **Class the request assumed:** UI affordance gap: add a `Duplicate Card` option to the existing card ellipsis menu.
- **Confirmed class:** identity-safe card instantiation parity: clone one existing card into a new todo record, update ordering and refresh UI through the same persistence/render lifecycle as other card creation or movement flows.
- **Reframed?** yes - from **menu affordance** to **backend-owned structural clone with UI refresh**, triggered by Step 4 evidence that existing `Copy` and `Copy All` actions are clipboard operations, while order-changing card actions such as `Move` use dedicated backend/data-layer flows.
- **What the confirmed class implies:** the fix should not synthesize a duplicate purely in the browser and hope later refresh reconciles it. It needs an authoritative write path that creates a new id, touches timestamps, updates `column.taskIds`, and returns enough data for the board to render the new card without collisions.

## 2. Problem statement (the raw facts - collected before classification)

- **Named instances:** Dustin, acting as WorkLists owner/user, requested a direct card-template duplication path on 2026-07-16. No separate named end user or live blocked task was supplied; independent user validation remains an open variable.
- **One sentence:** A WorkLists user cannot duplicate one existing card from the card ellipsis menu into a new structurally equivalent card because current card-menu copy actions copy text to the clipboard and current create/move paths do not expose a clone operation.
- **Distinct problems:**
  - Missing visible card-menu command for duplicate.
  - Missing backend/data-layer clone command that remaps unique identifiers and updates column order atomically.
  - Undefined child-association behavior, especially whether card notes should be copied.
  - Undefined sorted-column placement behavior after duplicating a card.
  - Shared card action menu is used by both board cards and the notes-pane card-text menu, so a global action definition could affect more than one menu surface.
- **Urgency:** next bite is the next spec/implementation phase for this feature after this report on 2026-07-16; no external production deadline was provided.
- **Wedge:** duplicate one card in its current column through an identity-safe backend endpoint, with explicit v1 note behavior, then render it immediately via the existing board refresh/instantiation lifecycle.

### Problem Check

## The question

### Asked
|  |  |
|---|---|
| **finding** | Add a `Duplicate Card` option to the existing card ellipsis menu. |
| **evidence** | "Add a \"Duplicate Card\" option" |

### Answered
|  |  |
|---|---|
| **finding** | Define and implement a structural clone path for a todo/card record. |
| **drift** | "add a menu option" -> "clone card object, remap identifiers, update state" |
| **evidence** | "clone the card object" / "unique identifiers" |

### Should-ask
|  |  |
|---|---|
| **finding** | Which card-owned fields and child records are part of duplicate-card structure? |
| **why** | It decides completion-state handling, notes behavior, and whether the duplicate is a pure template or an exact state clone. |

## Flags

### Conflation
|  |  |
|---|---|
| **finding** | Clipboard copy, card clone, and note/child association clone are treated as one capability. |
| **consequence** | Solving menu-level duplication will not automatically decide notes or hierarchy semantics. |
| **evidence** | "copy functions" / "child associations" |

### Thin
|  |  |
|---|---|
| **finding** | `exact layout and structure` does not define completion, timestamps, notes, or sort placement. |
| **evidence** | "exact layout and structure" |

### Off
|  |  |
|---|---|
| **finding** | Nothing internally contradicts the request; external code evidence revises the copy/deep-copy premise. |
| **consequence** | The report treats existing card-menu copy as clipboard-only unless later evidence finds another hierarchy copy path. |
| **evidence** | "copying content" / `copyTaskContent(textSpan)` |

## 3. The contract (locked before any solutioning)

### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| Card ellipsis menu exposes `Duplicate Card` in the intended card-menu surface. | needs-proof | Add action definition or context action with `card-actions.test.js` coverage. |
| Selecting duplicate creates a new card record, not clipboard text. | needs-proof | API test proving a distinct todo id is persisted. |
| Duplicate preserves source card structure agreed in the spec. | needs-proof | Lock field list: text/markdown, tag, secondary tags, status, completion state, dates. |
| Unique identifiers and timestamps do not collide. | needs-proof | Data-layer test for new todo id, creation timestamp, and `lastModified`; if notes are copied, new `noteId`s and new `eventId`s. |
| Column ordering updates correctly and atomically. | needs-proof | API test for `column.taskIds` insertion and no partial write on failure. |
| UI renders the new card immediately without full page reload. | needs-proof | Client contract test around handler call and refresh path; manual browser pass later. |
| Existing card actions remain unchanged. | needs-proof | Focused regression tests for Copy, Copy All, Move, Edit Notes, Delete, and notes-pane menu behavior. |
| OpenAPI documents any new endpoint. | needs-proof | `tests/openapi.test.js` expected path/schema assertions. |

### Non-goals / out of scope
- Cross-board duplicate in v1; destination selection belongs to a later expansion if needed.
- Batch duplicate or duplicate-all behavior.
- Reworking clipboard `Copy` / `Copy All` behavior.
- Deep-copying arbitrary hierarchies unless Phase 3 explicitly defines which child records are included.
- Canvas/topology-specific card placement behavior; this investigation is for the WorkLists board card menu.
- Refactoring the full todo creation lifecycle beyond what duplicate-card requires.

## 4. What changed since the request was created

- **Shifted from:** menu affordance only -> **to:** authoritative card clone command plus menu/client refresh integration.
- **What that buys us:** avoids id collisions and source/client drift, preserves existing persistence conventions, and makes failure modes testable at the API layer.
- **What it still needs to prove:** exact field-copy contract, note behavior, notes-pane menu behavior, sorted-column placement, and local/manual refresh expectations.

## 5. Why it exists

- **Origin traced to:** WorkLists has a centralized card action menu and several card operations, but no duplicate action or clone endpoint.
- **Evidence (primary-source pointers):**
  - `public/cardActions.js:14`, `:20`, `:38`, `:44` define `copy`, `copy-all`, `move`, and `edit-notes`, with no `duplicate` action.
  - `public/cardActions.js:70` dispatches actions by id through the handlers map; a duplicate action needs a handler on every menu surface where it appears.
  - `public/todolist2.js:12757-12763` wires board-card handlers for copy, copy-all, refine, voice, move, edit-notes, and delete; no duplicate handler exists.
  - `public/todolist2.js:4212-4224` uses the same shared card action definitions for the notes-pane card menu, so a new global definition will appear there unless hidden or handled.
  - `public/todolist2.js:1340-1415` creates a new todo client-side and posts it through `ApiService.addTodo`; this is a creation path, not a source-card clone path.
  - `server.js:3025` exposes `POST /todos`; `server.js:3055` exposes `POST /todos/:id/move`; there is no `POST /todos/:id/duplicate` route.
  - `dal.js:1881` has `addTodo`; `dal.js:2192` has atomic-style move logic via `moveTodoToColumn`; there is no clone helper.
  - `openapi.js:545`, `:680`, `:689`, `:2545`, `:2556` document create and move contracts, but not duplicate.
- **Changelog evidence:**
  - `c:\dustin-thomason\docs\WorkLists\worklists-app-changelog.md:3621` records card-level copy/delete consolidation into one ellipsis menu; this is the correct user-facing home for duplicate.
  - `...\worklists-app-changelog.md:3591` and `:3578` record Move Card and cross-board move work as dedicated endpoint/API/OpenAPI/test slices; duplicate should follow that pattern for data mutation.
  - `...\worklists-app-changelog.md:3544` records card copy-to-clipboard toast feedback, confirming the existing copy action is content copy, not structural clone.
  - `...\worklists-app-changelog.md:3189` and `:3169` record notes API and Edit Notes menu integration; notes are separate records attached by `eventId`, not embedded card fields.
  - `...\worklists-app-changelog.md:3129` records note cleanup on card delete; if duplicate copies notes, it must intentionally remap child notes instead of inheriting references.
  - `...\worklists-app-changelog.md:100-115` records `extraActions` for notes-pane-only menu items and verifies board-card menus are unchanged when extras are absent; this is a precedent for context-sensitive menu behavior.
- **Class re-check:** held. Root-cause evidence confirms the issue is not missing display text alone; it is missing identity-safe clone behavior across data, API, and UI refresh layers.

## 6. Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| Frontend-only clone using existing `POST /todos` | It would duplicate clone semantics in the browser, rely on client id generation, and make atomic order/field behavior harder to test. |
| Reuse `Copy` / `Copy All` | Those actions are clipboard content operations and have existing user-visible toast behavior; changing them would regress established meaning. |
| Implement duplicate as `extraActions` only | `extraActions` are intended for context-specific additions, currently notes-pane-only; duplicate is a core card action if approved. |
| Add a full duplicate dialog with board/column destination | Overreach for the wedge; Move already handles destination selection, and this request asks for quick single-card template cloning. |
| Copy notes by default | Notes are separate child records with their own ids and lifecycle. Silent note copying is a second feature unless Phase 3 explicitly requires it. |
| Deep-copy hierarchies | No hierarchy clone path was found in the audited card surfaces, and the request is for a single card template. |

## 7. Solution & stress-test

- **Proposed solution:** add a `Duplicate Card` menu action and a dedicated `POST /todos/{id}/duplicate` backend route. The data layer clones the source todo into a new todo with a new id and timestamps, inserts it into the source column order, touches affected entities, writes atomically, and returns `{ message, todo, column }` plus any additional board/order metadata the UI needs.
- **Solves the confirmed class?** yes, if the endpoint owns identifier remapping and column order updates, and the client treats the server response as the authoritative new card.
- **Scale:** one-card duplication is cheap over current JSON-backed data. If notes are later included, note cloning scales with note count and needs explicit bounds or progress only if large note sets become common.
- **Generalization:** do not abstract into a generic hierarchy clone now. Add a focused data-layer helper for todos, with a future-compatible option boundary for notes if needed.
- **Fit:** matches prior Move Card work: menu item -> ApiService method -> Express route -> DAL helper -> OpenAPI/test coverage. It also preserves established `Copy` semantics.
- **Adjacent issues:** notes duplication and cross-board duplicate are lower-risk follow-ups. Sorted-column placement should be decided now because it affects immediate user perception.
- **Sufficiency:** sufficient for quick card-as-template use if fields and notes behavior are made explicit before implementation. Insufficient for deep hierarchy cloning.
- **Feedback speed:** API and source-contract tests give immediate feedback; visual refresh and sorted-column behavior need manual/browser validation after implementation.
- **Happy-path story:** Dustin opens a card's ellipsis menu, selects `Duplicate Card`, and sees a new card appear in the same column with the agreed structure and a distinct identity; no clipboard step, no manual paste, no page reload.

### Acceptance-criteria coverage
| Criterion | Coverage | Closing proof |
|-----------|----------|---------------|
| Menu entry | covered by approach | `card-actions.test.js` definition/order and handler assertions. |
| Structural clone | covered directionally | API test for field list and id/timestamp changes. |
| UI refresh | needs proof | Client test and manual browser check. |
| Notes/children | covered by Phase 3 addendum/spec | API test for copied notes with new ids/eventId and preserved text/order. |
| Sorted placement | covered by Phase 3 addendum/spec | Tests/manual validation for unsorted bottom append and active-sort persistence. |
| Existing actions unchanged | covered directionally | Existing focused tests plus new regression assertions. |
| API docs | covered by approach | `openapi.test.js` path/schema assertions. |

### Affected surfaces and completeness claim
- **Shared action definition:** `public/cardActions.js` action list and dispatcher.
- **Board-card handler:** `public/todolist2.js` `createTask` menu handler map.
- **Notes-pane card menu:** `public/todolist2.js` `getNotesPaneCardActionHandlers` / `getNotesPaneCardActionState`; must hide or implement duplicate intentionally.
- **Client API:** `public/apiService.js`, new duplicate method following `moveTodo` style error handling.
- **Server/API/DAL:** `server.js`, `dal.js`, `openapi.js`.
- **Tests:** `tests/card-actions.test.js`, `tests/api.test.js`, `tests/openapi.test.js`, plus any focused UI contract test if behavior is split from existing card actions.
- **Completeness established by:** grep for card action definitions/handlers, `POST /todos` and `POST /todos/:id/move` routes, and existing focused test coverage around card action, todo create/move, and OpenAPI expected paths.

### Unchanged neighbors to protect
- `Copy` keeps copying card markdown/content to clipboard.
- `Copy All` keeps copying card plus notes text to clipboard.
- `Move` keeps using the move dialog and move endpoint.
- `Edit Notes` keeps opening/focusing the notes pane.
- `Delete` keeps deleting cards and cleaning up associated notes.
- Notes-pane menu `extraActions` keep remaining contextual and absent from ordinary board-card definitions.

### Detection gap
Duplicate-card has no existing regression test because no action, client method, route, OpenAPI path, or DAL helper exists. The red-green test should first assert the desired duplicate endpoint/menu behavior, then implementation should make it pass.

## 8. Assumptions ledger

- **Claim:** Existing card-menu `Copy` / `Copy All` are clipboard operations, not record clone operations.
  - **Status:** confirmed
  - **Confirm/revise by:** `public/todolist2.js:12757-12758`; changelog `:3544`.
- **Claim:** A dedicated backend endpoint is a better fit than frontend-only clone.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** compare with `Move` route/DAL/OpenAPI pattern and API tests.
- **Claim:** Duplicate should start in the source card's current column.
  - **Status:** resolved / confirmed
  - **Confirm/revise by:** Phase 3 locked same-column duplication; cross-board duplicate is out of scope.
- **Claim:** Duplicate should be inserted adjacent to the source card.
  - **Status:** resolved / rejected
  - **Confirm/revise by:** Phase 3 locked unsorted bottom append and active-sort persistence; adjacency is not required.
- **Claim:** Duplicate should not copy notes in v1.
  - **Status:** resolved / rejected
  - **Confirm/revise by:** Phase 3 locked notes copying as foundational.
- **Claim:** Completion state should reset for template usefulness.
  - **Status:** resolved / confirmed
  - **Confirm/revise by:** Phase 3 locked `completed: false` and blank `completedDate`.
- **Claim:** Adding a shared action definition affects notes-pane card menus too.
  - **Status:** confirmed
  - **Confirm/revise by:** `getNotesPaneCardActionHandlers` uses the same `CardActions` definitions and must either handle or hide duplicate.
- **Claim:** OpenAPI must change if a new endpoint is added.
  - **Status:** confirmed
  - **Confirm/revise by:** existing `tests/openapi.test.js` expected path assertions.

## 9. Validation plan

**Happy path**
- Open a board with a card containing multiline markdown, primary tags, secondary tags, and a status.
- Open the card ellipsis menu.
- Select `Duplicate Card`.
- Menu closes and a new card appears in the same column without full page reload.
- New card has a new id/timestamps and the agreed structural fields.
- Refresh the page; duplicate persists in the same expected order.

**Negative paths**
- Duplicate a missing todo id -> 404 and no column/order mutation.
- Duplicate into a missing or inconsistent source column -> visible API error and no partial write.
- Duplicate when source has notes -> copied notes preserve text/order, get new `noteId`s, and get new `eventId`s pointing at the duplicate.
- Duplicate in an actively sorted column -> behavior matches spec and does not leave client/server order divergent.
- Duplicate while notes-pane menu is open -> action is handled intentionally; the pane switches to the duplicate after existing unsaved draft guards allow the switch.
- Copy, Copy All, Move, Edit Notes, Delete, status/tag rendering, active search/filter rendering, and note cleanup still pass focused regressions.

**Software validation gates**
- Red-green API test in `tests/api.test.js` for `POST /todos/:id/duplicate`.
- Red-green card action test in `tests/card-actions.test.js` for definition/handler/menu behavior.
- OpenAPI test in `tests/openapi.test.js` for path/schema coverage.
- Syntax checks for touched JS files.
- Manual browser check for immediate render and placement after implementation.

## 10. Decisions, recommendation & open variables

- **Decisions (settled):**
  - Use the existing card ellipsis menu as the entry point.
  - Do not modify the shared investigation template.
  - Treat the canonical WorkLists changelog as the changelog evidence source.
  - Keep existing `Copy` and `Copy All` semantics unchanged.
  - Prefer a dedicated backend duplicate endpoint over frontend-only cloning.
- **Recommendation (what to do, in order):**
  - Phase 3 locked field-copy, notes, completion-state, sorted placement, and notes-pane menu decisions.
  - Implement `POST /todos/{id}/duplicate` in DAL/server/OpenAPI/API client.
  - Add `Duplicate Card` to the shared action definitions with notes-pane parity.
  - Wire board-card handler to call the client method and refresh/reinsert through existing render lifecycle.
  - Add focused API, OpenAPI, and card-action tests before broader manual validation.
- **Sequencing & gates:** Phase 3 is resolved. Do not start implementation until the ticketed spec is reviewed for Phase 4 planning.

### Open variables to collect

- [x] Does `child associations` include card notes? - resolved: yes, copy notes with new ids/eventId.
- [x] Should completed state and `completedDate` copy, or should duplicates reset to incomplete? - resolved: reset to incomplete and blank completion date.
- [x] Should the duplicate appear immediately after the source card, at end of column, or according to active sort? - resolved: unsorted bottom append; sorted columns keep active sort.
- [x] Should `Duplicate Card` appear in the notes-pane card-text ellipsis menu? - resolved: yes, parity with board card menu.
- [x] What user-visible toast copy should success/failure use? - resolved: `Card duplicated.` / `Card could not be duplicated.`
- [ ] Is the Dustin owner/user request sufficient as the named instance, or is another named blocked user/task needed? - owner: Dustin

---

## 11. Plan - Next steps

### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Run Phase 3 probe/spec with grill-me skill | Codex + Dustin | Done: ticketed spec answers notes, completion, placement, and notes-pane menu variables. |
| Draft implementation spec from this report | Codex | Spec names endpoint, response shape, field-copy rules, UI surfaces, and tests. |
| Implement duplicate endpoint and UI | Codex | Focused tests pass and manual browser check shows duplicate renders immediately. |
| Update changelog after implementation | Codex | Canonical changelog has dated entry with files, tests, regression impact, and API docs note. |

### Checklist
#### Investigation
- [x] This report (Sections 0-10)
- [x] Reconciled `agents/skills/investigation/SKILL.md`: Steps 1-7 are answered or carried as open variables.
- [x] Reconciled `agents/docs/problem-check.md`: Asked, Answered, Should-ask, Conflation, Thin, and Off are recorded.
- [x] Reconciled `agents/docs/investigation-question-coverage.md`: class, scale, abstraction, fit, adjacent issues, frontend lens, acceptance criteria, and validation are covered.
- [x] Reconciled `agents/docs/investigation-software-gaps.md`: contract alignment, surface enumeration, neighbor protection, detection gap, red-green test, and reproduction/preconditions are covered.

#### Project Spec
- [x] Draft open questions / unknowns
- [x] Create project spec

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
- [ ] Document root cause / why it slipped through if later treated as a bug

---

## 12. Definition of done (investigation gate)
- [x] **Class derived from instances, re-confirmed against root cause - and "reframed?" answered with a justification either way (Section 1)**
- [x] Problem in one plain sentence
- [x] Named blocked instance, with limitation noted
- [x] Date it bites next
- [x] Wedge + why it is reusable within the confirmed class
- [x] Acceptance criteria + non-goals locked before the solution was proposed
- [x] Alternatives recorded with rejection reasons
- [x] 30-second happy-path story
- [x] Metric that proves it works + how fast it arrives
- [x] Verdict + disposition stated
- [x] Open variables each have an owner
- [x] Tracked action with a falsifiable done-when
---

## 13. Phase 3 Grill-Me Addendum

### Locked Decisions

| Decision | Outcome | Baked-in check |
|---|---|---|
| Notes | Duplicate copies notes. This is foundational to the feature. Copied notes preserve text exactly, keep note order, receive new `noteId`s, point `eventId` at the duplicate card id, and receive fresh `createdAt` / `lastModified` timestamps. | Notes API and note-card association by `eventId` already exist; duplicate-specific note cloning does not. |
| Card structure | Duplicate preserves reusable card setup: text/markdown structure exactly, primary tag(s), secondary tags, project status, and other card factors that make the card useful as a template. | Todo fields, tags, secondary tags, status, and markdown rendering already exist; duplicate field-copy rules do not. |
| Workflow state | Duplicate resets completion workflow state: `completed: false`, `completedDate: ""`, and no scheduler membership. | New-card defaults and scheduler sequence already exist; duplicate reset rules do not. |
| Timestamps | Duplicate uses one fresh mutation timestamp for the new card, copied notes, touched source column, and affected board(s); source card remains untouched. | `addTodo` and note mutations already set/touch timestamps; clone-wide timestamp parity is new. |
| Placement | In unsorted columns, all new cards, including duplicates, appear at the bottom. In sorted columns, existing sort persists and the duplicate lands according to the active sort. | `addTodo` appends to `column.taskIds`; sorted rendering exists separately. Duplicate-specific placement is new. |
| Focus/reveal | After successful duplicate, the UI gives active focus to the new card. Board-menu duplicate reveals/focuses the card without opening the notes pane. Notes-pane duplicate switches the open pane to the new duplicate and loads copied notes. | `TaskVisibility.revealTaskCard` exists; duplicate-specific reveal/focus and notes-pane switching do not. |
| Search/filter | Duplicate is allowed while search/filter is active. Preserve current search/filter state. Reveal/focus the duplicate only when it is present in the currently rendered DOM; otherwise show success toast only. | Search/filter rendering exists; duplicate interaction with it is not currently encoded. |
| Notes-pane parity | `Duplicate Card` appears in the notes-pane card action menu as well as the board card menu. | Shared `CardActions` definitions already drive both surfaces; duplicate parity and handlers are new. |
| API contract | Use `POST /todos/{id}/duplicate` with no request body and a `201 Created` response containing `{ message, todo, column, notes, sourceTodoId, destinationIndex }`. | Todo create and move endpoints exist; duplicate endpoint does not. |
| IDs | Server/DAL owns duplicate ids. Todo ids follow the existing `todo-${Date.now()}-${randomSuffix}` style; copied notes use fresh UUIDs. | Server-side UUID usage exists in other paths; duplicate ids are new. |
| Atomicity | Duplicate is all-or-nothing for card, column insertion, copied notes, and touches. If note copy fails, no card is left behind. | DAL read/write locking and move-style mutation patterns exist; duplicate atomicity is new. |
| Optimism | No optimistic UI for duplicate. Wait for server `201`, then refresh/update/reveal/focus. | Existing creation has optimistic behavior; duplicate intentionally does not reuse that aspect. |
| Double-submit | Prevent duplicate double-submit for the same source while the request is in flight. Close menu on trigger, mark the action in-flight if reopened, and clear after success/failure. | Action-state hooks exist; duplicate in-flight state is new. |
| Toast | Success toast is `Card duplicated.`; failure toast is `Card could not be duplicated.` No undo action in v1. | Toast infrastructure exists; duplicate copy/no-undo rule is new. |
| Menu identity | Add `id: "duplicate"`, label `Duplicate Card`, icon `fa-clone`, placed after `Copy All` and before `Refine with Gemma`. | Menu definition and Font Awesome use are baked in; duplicate identity/placement is new. |
| OpenAPI | Document path and `TodoDuplicateResponse` with `201`, `404`, `409`, and `500`. | OpenAPI and tests exist; duplicate path/schema are new. |
| Artifact organization | Move artifacts into `docs/WorkLists/tickets/duplicate-card-option/`, with artifact-type subfolders and filenames naming the artifact type. Remove the old standalone investigation copy. | Existing WorkLists docs had feature/investigation folders; ticket-scoped artifact organization is new. |

### Supplemental Scroll / Reveal Investigation

This feature is blocked on a focused scroll/reveal audit because duplicate placement intentionally follows the new-card rule rather than adjacency to the source card.

- Existing behavior found: `TaskVisibility.revealTaskCard` already provides a route to reveal a task, account for filtered visibility, and scroll the task container.
- Existing behavior found: new-card visibility scheduling exists through `scheduleNewTaskVisibility` / `newTaskVisibilityTracker` in `public/todolist2.js`.
- Gap: duplicate has no dedicated reveal call path after a server-created card returns from `POST /todos/{id}/duplicate`.
- Gap: sorted columns may render the duplicate far from the source; the duplicate should still receive focus/reveal if it is present under the current search/filter state.
- Gap: notes-pane-origin duplication must switch the open pane to the duplicate after copied notes are available, while respecting existing unsaved draft guards before switching focus.
- Spec requirement: implementation must either reuse `TaskVisibility.revealTaskCard` directly or introduce a narrow wrapper that preserves existing reveal semantics for all new cards. The wrapper must not alter sorting or search/filter state.
- Validation requirement: test or manually verify unsorted bottom append, sorted placement by active sort, filtered-hidden duplicate success toast without forced filter clearing, and notes-pane duplicate focus switch.



